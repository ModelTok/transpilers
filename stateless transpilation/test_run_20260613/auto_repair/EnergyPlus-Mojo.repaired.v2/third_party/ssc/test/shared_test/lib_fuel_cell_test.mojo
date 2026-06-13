from testing import assert_equal, assert_almost_equal, assert_true, assert_false, assert_greater
from ...lib_fuel_cell import FuelCell
from ...lib_fuel_cell_dispatch import FuelCellDispatch
from ...lib_util import util

def EXPECT_EQ(a, b):
    assert_equal(a, b)

def EXPECT_NEAR(a, b, tol):
    assert_almost_equal(a, b, atol=tol)

def EXPECT_TRUE(cond):
    assert_true(cond)

def EXPECT_FALSE(cond):
    assert_false(cond)

def EXPECT_GT(a, b):
    assert_greater(a, b)

struct FuelCellProperties:
    var numberOfUnits: Int
    var unitPowerMax_kW: Float64
    var unitPowerMin_kW: Float64
    var startup_hours: Float64
    var is_started: Bool
    var shutdown_hours: Float64
    var dynamicResponseUp_kWperHour: Float64
    var dynamicResponseDown_kWperHour: Float64
    var degradation_kWperHour: Float64
    var degradationRestart_kW: Float64
    var replacementOption: Int
    var replacement_percent: Float64
    var replacementSchedule: List[Int]
    var shutdownTable: util.matrix_t[Int]
    var efficiencyChoice: Int
    var efficiencyTable: util.matrix_t[Float64]
    var lowerHeatingValue_BtuPerFt3: Float64
    var higherHeatingValue_BtuPerFt3: Float64
    var availableFuel_Mcf: Float64
    var shutdownOption: Int
    var dispatchOption: Int
    var dt_hour: Float64
    var fixed_percent: Float64
    var dispatchInput_kW: List[Float64]
    var canCharge: List[Bool]
    var canDischarge: List[Bool]
    var discharge_percent: Dict[Int, Float64]
    var discharge_units: Dict[Int, Int]
    var scheduleWeekday: util.matrix_t[Int]
    var scheduleWeekend: util.matrix_t[Int]

    def SetUp(inout self):
        self.numberOfUnits = 1
        self.unitPowerMax_kW = 100
        self.unitPowerMin_kW = 20
        self.startup_hours = 8
        self.is_started = False
        self.shutdown_hours = 8
        self.dynamicResponseUp_kWperHour = 20
        self.dynamicResponseDown_kWperHour = 10
        self.degradation_kWperHour = 0.01
        self.degradationRestart_kW = 5
        self.replacementOption = 0
        self.replacement_percent = 50
        self.replacementSchedule.append(0)
        var tmpValues = List[Float64](0, 0, 50, 16, 21, 50, 25, 25, 50, 34, 32, 50, 44, 37, 50, 53, 42, 50, 62, 47, 49, 72, 50, 48, 82, 52, 47, 90, 52, 46, 100, 51, 45)
        self.efficiencyTable.assign(tmpValues, 11, 3)
        self.efficiencyChoice = 1
        self.canCharge.append(1)
        self.canDischarge.append(1)
        self.discharge_percent[0] = 40
        self.discharge_units[0] = 1
        self.scheduleWeekday.resize_fill(12, 24, 1)
        self.scheduleWeekend.resize_fill(12, 24, 1)
        self.shutdownTable.resize_fill(1, 2, 0)
        for t in range(8760):
            self.dispatchInput_kW.append(50)

struct FuelCellTest : FuelCellProperties:
    var fuelCell: UnsafePointer[FuelCell]
    var fuelCellDispatch: UnsafePointer[FuelCellDispatch]
    var fuelCellDispatchMultiple: UnsafePointer[FuelCellDispatch]
    var n_multipleFuelCells: Int = 4
    var dt_subHourly: Float64 = 0.25
    var fuelCellSubHourly: UnsafePointer[FuelCell]
    var fuelCellDispatchSubhourly: UnsafePointer[FuelCellDispatch]

    def SetUp(inout self):
        FuelCellProperties.SetUp(self)  # call base
        var fc = FuelCell(self.unitPowerMax_kW, self.unitPowerMin_kW, self.startup_hours, self.is_started, self.shutdown_hours,
            self.dynamicResponseUp_kWperHour, self.dynamicResponseDown_kWperHour,
            self.degradation_kWperHour, self.degradationRestart_kW,
            self.replacementOption, self.replacement_percent, self.replacementSchedule,
            self.shutdownTable, self.efficiencyChoice, self.efficiencyTable,
            self.lowerHeatingValue_BtuPerFt3, self.higherHeatingValue_BtuPerFt3, self.availableFuel_Mcf, self.shutdownOption, self.dt_hour)
        self.fuelCell = UnsafePointer[FuelCell].alloc()
        self.fuelCell[] = fc
        # fuelCellStarted omitted (commented out)
        var fcSub = FuelCell(self.unitPowerMax_kW, self.unitPowerMin_kW, self.startup_hours, self.is_started, self.shutdown_hours,
            self.dynamicResponseUp_kWperHour, self.dynamicResponseDown_kWperHour,
            self.degradation_kWperHour, self.degradationRestart_kW,
            self.replacementOption, self.replacement_percent, self.replacementSchedule,
            self.shutdownTable, self.efficiencyChoice, self.efficiencyTable,
            self.lowerHeatingValue_BtuPerFt3, self.higherHeatingValue_BtuPerFt3, self.availableFuel_Mcf, self.shutdownOption, self.dt_subHourly)
        self.fuelCellSubHourly = UnsafePointer[FuelCell].alloc()
        self.fuelCellSubHourly[] = fcSub
        # fuelCellDispatchStarted omitted
        var dispatch = FuelCellDispatch(self.fuelCell, self.numberOfUnits, self.dispatchOption, self.shutdownOption, self.dt_hour, self.fixed_percent,
            self.dispatchInput_kW, self.canCharge, self.canDischarge, self.discharge_percent, self.discharge_units, self.scheduleWeekday, self.scheduleWeekend)
        self.fuelCellDispatch = UnsafePointer[FuelCellDispatch].alloc()
        self.fuelCellDispatch[] = dispatch
        var dispatchSub = FuelCellDispatch(self.fuelCellSubHourly, self.numberOfUnits, self.dispatchOption, self.shutdownOption, self.dt_subHourly, self.fixed_percent,
            self.dispatchInput_kW, self.canCharge, self.canDischarge, self.discharge_percent, self.discharge_units, self.scheduleWeekday, self.scheduleWeekend)
        self.fuelCellDispatchSubhourly = UnsafePointer[FuelCellDispatch].alloc()
        self.fuelCellDispatchSubhourly[] = dispatchSub
        self.discharge_units[0] = self.n_multipleFuelCells
        var dispatchMulti = FuelCellDispatch(self.fuelCell, self.n_multipleFuelCells, self.dispatchOption, self.shutdownOption, self.dt_hour, self.fixed_percent,
            self.dispatchInput_kW, self.canCharge, self.canDischarge, self.discharge_percent, self.discharge_units, self.scheduleWeekday, self.scheduleWeekend)
        self.fuelCellDispatchMultiple = UnsafePointer[FuelCellDispatch].alloc()
        self.fuelCellDispatchMultiple[] = dispatchMulti
        # fuelCellDispatchMultipleStarted omitted

    def TearDown(inout self):
        if self.fuelCell:
            self.fuelCell.free()
            self.fuelCell = UnsafePointer[FuelCell]()
        if self.fuelCellDispatch:
            self.fuelCellDispatch.free()
            self.fuelCellDispatch = UnsafePointer[FuelCellDispatch]()
        if self.fuelCellDispatchMultiple:
            self.fuelCellDispatchMultiple.free()
            self.fuelCellDispatchMultiple = UnsafePointer[FuelCellDispatch]()
        # commented out cleanups remain
        if self.fuelCellSubHourly:
            self.fuelCellSubHourly.free()
            self.fuelCellSubHourly = UnsafePointer[FuelCell]()
        if self.fuelCellDispatchSubhourly:
            self.fuelCellDispatchSubhourly.free()
            self.fuelCellDispatchSubhourly = UnsafePointer[FuelCellDispatch]()

    # Test methods
    def UnitConversions_lib_fuel_cell(self):
        var lhv_btu_per_ft3: Float64 = 983
        EXPECT_NEAR(FuelCell.BTU_TO_MCF(1000000, lhv_btu_per_ft3), 1.017, 0.001)
        EXPECT_NEAR(FuelCell.MCF_TO_BTU(1, lhv_btu_per_ft3), 983000, 0.01)
        EXPECT_NEAR(FuelCell.MCF_TO_KWH(1, lhv_btu_per_ft3), 288.088, 0.01)

    def EfficiencyCurve_lib_fuel_cell(self):
        self.fuelCell[].calculateEfficiencyCurve(.16)
        EXPECT_EQ(self.fuelCell[].getElectricalEfficiency(), 0.21)
        EXPECT_EQ(self.fuelCell[].getHeatRecoveryEfficiency(), .50)

    def FuelConsumption_lib_fuel_cell(self):
        self.fuelCell[].calculateEfficiencyCurve(.16)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.251, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.25)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.330, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.30)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.341, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.34)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.351, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.44)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.393, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.53)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.417, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.62)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.436, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.72)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.476, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.82)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.521, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(.9)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.572, 0.01)
        self.fuelCell[].calculateEfficiencyCurve(1)
        EXPECT_NEAR(self.fuelCell[].getFuelConsumption(), 0.648, 0.01)

    def Initialize_lib_fuel_cell(self):
        EXPECT_EQ(self.fuelCell[].isRunning(), False)

    def Startup_lib_fuel_cell(self):
        for h in range(self.startup_hours):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_EQ(self.fuelCell[].getPower(), 0)
            EXPECT_FALSE(self.fuelCell[].isRunning())
        self.fuelCell[].runSingleTimeStep(20)
        EXPECT_EQ(self.fuelCell[].getPower(), 20)
        self.fuelCell[].runSingleTimeStep(self.unitPowerMin_kW - 10)
        EXPECT_EQ(self.fuelCell[].getPower(), self.unitPowerMin_kW)
        self.fuelCell[].runSingleTimeStep(100)
        EXPECT_EQ(self.fuelCell[].getPower(), self.unitPowerMin_kW + self.dynamicResponseUp_kWperHour)
        self.fuelCell[].runSingleTimeStep(100)
        self.fuelCell[].runSingleTimeStep(100)
        self.fuelCell[].runSingleTimeStep(100)
        self.fuelCell[].runSingleTimeStep(100)
        self.fuelCell[].runSingleTimeStep(self.unitPowerMax_kW + 10)
        EXPECT_EQ(self.fuelCell[].getPower(), self.fuelCell[].getMaxPower())
        self.fuelCell[].runSingleTimeStep(0)
        EXPECT_NEAR(self.fuelCell[].getPower(), self.fuelCell[].getMaxPower() - self.dynamicResponseDown_kWperHour, 0.1)

    def StartedUp_lib_fuel_cell(self):
        self.fuelCell[].setStartupHours(0, True)
        self.fuelCell[].runSingleTimeStep(self.dynamicResponseUp_kWperHour * 2)
        EXPECT_EQ(self.fuelCell[].getPower(), self.dynamicResponseUp_kWperHour * 2)

    def Shutdown_lib_fuel_cell(self):
        self.fuelCell[].setShutdownOption(FuelCell.FC_SHUTDOWN_OPTION.SHUTDOWN)
        for h in range(self.startup_hours):
            self.fuelCell[].runSingleTimeStep(20)
        for h in range(self.startup_hours, self.startup_hours + 5):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_TRUE(self.fuelCell[].isRunning())
        for h in range(self.shutdown_hours):
            self.fuelCell[].runSingleTimeStep(0)
            EXPECT_EQ(self.fuelCell[].getPower(), 0)
            EXPECT_GT(self.fuelCell[].getPowerThermal(), 0)
            EXPECT_FALSE(self.fuelCell[].isRunning())
        self.fuelCell[].runSingleTimeStep(0)
        EXPECT_EQ(self.fuelCell[].getPower(), 0)
        EXPECT_EQ(self.fuelCell[].getPowerThermal(), 0)
        EXPECT_FALSE(self.fuelCell[].isRunning())

    def Idle_lib_fuel_cell(self):
        self.fuelCell[].setShutdownOption(FuelCell.FC_SHUTDOWN_OPTION.IDLE)
        for h in range(self.startup_hours):
            self.fuelCell[].runSingleTimeStep(20)
        for h in range(self.startup_hours, self.startup_hours + 5):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_TRUE(self.fuelCell[].isRunning())
        for h in range(self.shutdown_hours):
            self.fuelCell[].runSingleTimeStep(0)
            EXPECT_EQ(self.fuelCell[].getPower(), self.fuelCell[].getMinPower())
            EXPECT_GT(self.fuelCell[].getPowerThermal(), 0)
            EXPECT_TRUE(self.fuelCell[].isRunning())

    def AvailableFuel_lib_fuel_cell(self):
        for h in range(self.startup_hours):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_EQ(self.fuelCell[].getAvailableFuel(), self.availableFuel_Mcf)
        var availableFuelTrack: Float64 = self.availableFuel_Mcf
        for h in range(self.startup_hours, self.startup_hours + 10):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_EQ(self.fuelCell[].getAvailableFuel(), availableFuelTrack - self.fuelCell[].getFuelConsumption())
            availableFuelTrack -= self.fuelCell[].getFuelConsumption()

    def HeatCalculation_lib_fuel_cell(self):
        for h in range(self.startup_hours):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_EQ(self.fuelCell[].getPowerThermal(), 0)
        for h in range(self.startup_hours, self.startup_hours + 10):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_EQ(self.fuelCell[].getPowerThermal(), 20 * self.fuelCell[].getHeatRecoveryEfficiency())

    def Replacements_lib_fuel_cell(self):
        self.fuelCell[].setStartupHours(1, False)
        self.fuelCell[].setDegradationkWPerHour(40)
        self.fuelCell[].setReplacementOption(FuelCell.FC_REPLACEMENT_OPTION.REPLACE_AT_CAPACITY)
        self.fuelCell[].setReplacementCapacity(50)
        for h in range(3):
            self.fuelCell[].runSingleTimeStep(20)
        EXPECT_EQ(self.fuelCell[].getTotalReplacements(), 1)

    def ScheduleRestarts_lib_fuel_cell(self):
        var shutdowns: util.matrix_t[Int]
        shutdowns.resize_fill(1, 2, 4)
        self.fuelCell[].setStartupHours(1, False)
        self.fuelCell[].setDegradationkWPerHour(0)
        self.fuelCell[].setDegradationRestartkW(1)
        self.fuelCell[].setScheduledShutdowns(shutdowns)
        for h in range(4):
            self.fuelCell[].runSingleTimeStep(20)
        for h in range(self.shutdown_hours + 1):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_EQ(self.fuelCell[].getPower(), 0)
        EXPECT_EQ(self.fuelCell[].getMaxPower(), self.fuelCell[].getMaxPowerOriginal() - 1.0)
        for h in range(1):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_EQ(self.fuelCell[].getPower(), 0)
        for h in range(4):
            self.fuelCell[].runSingleTimeStep(20)
            EXPECT_GT(self.fuelCell[].getPower(), 0)

    def DispatchFixedSubhourly_lib_fuel_cell_dispatch(self):
        var sh: Int = 1
        var stepsPerHour: Int = Int(1 / self.dt_subHourly)
        self.fuelCellSubHourly[].setSystemProperties(200, 60, 1, 24, 500, 500)
        self.fuelCellDispatchSubhourly[].setDispatchOption(FuelCellDispatch.FC_DISPATCH_OPTION.FIXED)
        self.fuelCellDispatchSubhourly[].setFixedDischargePercentage(95)
        var year_idx: Int = 0
        var h: Int = 0
        for hour in range(sh):
            for s in range(stepsPerHour):
                self.fuelCellDispatchSubhourly[].runSingleTimeStep(h, year_idx)
                year_idx += 1
                h += 1
            EXPECT_EQ(self.fuelCellSubHourly[].getPower(), 0)
        self.fuelCellDispatchSubhourly[].runSingleTimeStep(h, year_idx)
        h += 1
        year_idx += 1
        EXPECT_EQ(self.fuelCellSubHourly[].getPower(), 125)
        self.fuelCellDispatchSubhourly[].runSingleTimeStep(h, year_idx)
        h += 1
        year_idx += 1
        EXPECT_EQ(self.fuelCellSubHourly[].getPower(), 190)

    def DispatchFixedMultiple_lib_fuel_cell_dispatch(self):
        var sh: Int = Int(self.startup_hours)
        for h in range(sh):
            self.fuelCellDispatchMultiple[].runSingleTimeStep(h, h, 0, 0)
            EXPECT_EQ(self.fuelCell[].getPower(), 0)
        self.fuelCellDispatchMultiple[].runSingleTimeStep(sh, 0, 0)
        EXPECT_EQ(self.fuelCell[].getPower(), 20)
        for h in range(sh+1, sh+10):
            self.fuelCellDispatchMultiple[].runSingleTimeStep(h, h, 20, 10)
            EXPECT_EQ(self.fuelCell[].getPower(), self.unitPowerMax_kW * self.fixed_percent * 0.01)
            EXPECT_EQ(self.fuelCellDispatchMultiple[].getBatteryPower().powerFuelCellToLoad, 0)
            EXPECT_EQ(self.fuelCellDispatchMultiple[].getBatteryPower().powerFuelCellToGrid, self.n_multipleFuelCells * 40)
            EXPECT_EQ(self.fuelCellDispatchMultiple[].getBatteryPower().powerSystemToLoad, 10)
            EXPECT_EQ(self.fuelCellDispatchMultiple[].getBatteryPower().powerSystemToGrid, 10)

    def DispatchLoadFollow_lib_fuel_cell_dispatch(self):
        var sh: Int = Int(self.startup_hours)
        self.fuelCellDispatch[].setDispatchOption(FuelCellDispatch.FC_DISPATCH_OPTION.LOAD_FOLLOW)
        for h in range(sh):
            self.fuelCellDispatch[].runSingleTimeStep(h, h, 0, 20)
            EXPECT_EQ(self.fuelCell[].getPower(), 0)
        self.fuelCellDispatch[].runSingleTimeStep(sh, sh, 20, 40)
        EXPECT_EQ(self.fuelCell[].getPower(), 20)
        self.fuelCellDispatch[].runSingleTimeStep(sh+1, sh+1, 20, 80)
        EXPECT_EQ(self.fuelCell[].getPower(), 40)
        self.fuelCellDispatch[].runSingleTimeStep(sh+2, sh+2, 20, 80)
        EXPECT_EQ(self.fuelCell[].getPower(), 60)

    def DispatchManual_lib_fuel_cell_dispatch(self):
        var sh: Int = Int(self.startup_hours)
        var stepsPerHour: Int = Int(1 / self.dt_subHourly)
        self.fuelCellDispatchSubhourly[].setDispatchOption(FuelCellDispatch.FC_DISPATCH_OPTION.MANUAL)
        var year_idx: Int = 0
        for h in range(sh):
            for s in range(stepsPerHour):
                self.fuelCellDispatchSubhourly[].runSingleTimeStep(h, year_idx, 0, 20)
                year_idx += 1
            EXPECT_EQ(self.fuelCellSubHourly[].getPower(), 0)
        for s in range(stepsPerHour):
            self.fuelCellDispatchSubhourly[].runSingleTimeStep(sh, year_idx, 20, 40)
            year_idx += 1
        EXPECT_EQ(self.fuelCellSubHourly[].getPower(), 35)
        for s in range(stepsPerHour):
            self.fuelCellDispatchSubhourly[].runSingleTimeStep(sh+1, year_idx, 20, 80)
            EXPECT_EQ(self.fuelCellSubHourly[].getPower(), 40)
            year_idx += 1

    def DispatchManualUnits_lib_fuel_cell_dispatch(self):
        var sh: Int = 8
        self.discharge_units[0] = 3
        self.fuelCellDispatchMultiple[].setDispatchOption(FuelCellDispatch.FC_DISPATCH_OPTION.MANUAL)
        self.fuelCellDispatchMultiple[].setManualDispatchUnits(self.discharge_units)
        for h in range(sh):
            self.fuelCellDispatchMultiple[].runSingleTimeStep(h, h, 0, 20)
        EXPECT_NEAR(self.fuelCellDispatchMultiple[].getPower(), 0, 0.01)
        self.fuelCellDispatchMultiple[].runSingleTimeStep(sh, sh)
        self.fuelCellDispatchMultiple[].runSingleTimeStep(sh, sh)
        EXPECT_EQ(self.fuelCellDispatchMultiple[].getPower(), 3 * 40)

    def DispatchInput_lib_fuel_cell_dispatch(self):
        var sh: Int = Int(self.startup_hours)
        self.fuelCellDispatch[].setDispatchOption(FuelCellDispatch.FC_DISPATCH_OPTION.INPUT)
        for h in range(sh):
            self.fuelCellDispatch[].runSingleTimeStep(h, h, 0, 20)
            EXPECT_EQ(self.fuelCellDispatch[].getPower(), 0)
        self.fuelCellDispatch[].runSingleTimeStep(sh, sh, 0, 0)
        EXPECT_EQ(self.fuelCellDispatch[].getPower(), 20)
        self.fuelCellDispatch[].runSingleTimeStep(sh+1, sh+1, 0, 0)
        EXPECT_EQ(self.fuelCellDispatch[].getPower(), 40)
        for h in range(sh+2, 50):
            self.fuelCellDispatch[].runSingleTimeStep(h, h, 0, 0)
            EXPECT_EQ(self.fuelCellDispatch[].getPower(), 50)

// Note: The commented-out code from the original is preserved as comments.
// Additional fixture member cleanup:
// if fuelCellStarted, fuelCellDispatchStarted, fuelCellDispatchMultipleStarted would be freed.