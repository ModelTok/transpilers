from memory import pointer, address_of
from math import fmax
from lib_fuel_cell import FuelCell
from lib_battery_powerflow import BatteryPowerFlow
from lib_util import util, matrix_t
from lib_power_electronics import ChargeController

@value
struct FC_DISPATCH_OPTION:
    var FIXED: Int = 0
    var LOAD_FOLLOW: Int = 1
    var MANUAL: Int = 2
    var INPUT: Int = 3

@value
class FuelCellDispatch:
    var m_batteryPowerFlow: Pointer[BatteryPowerFlow]
    var m_batteryPower: Pointer[BatteryPower]
    var m_powerTotal_kW: Float64
    var m_loadAverage_percent: Float64
    var m_powerMaxPercentAverage_percent: Float64
    var m_efficiencyAverage_percent: Float64
    var m_powerThermalTotal_kW: Float64
    var m_fuelConsumedTotal_MCf: Float64
    var m_numberOfUnits: Int
    var m_dispatchOption: Int
    var m_shutdownOption: Int
    var dt_hour: Float64
    var m_fixed_percent: Float64
    var m_dispatchInput_kW: List[Float64]
    var m_fuelCellVector: List[Pointer[FuelCell]]
    var m_canCharge: List[Bool]
    var m_canDischarge: List[Bool]
    var m_discharge_percent: Dict[Int, Float64]
    var m_discharge_units: Dict[Int, Int]
    var m_scheduleWeekday: matrix_t[Int]
    var m_scheduleWeekend: matrix_t[Int]

    def __init__(inout self):

    def __init__(inout self, fuelCell: Pointer[FuelCell], numberOfUnits: Int, dispatchOption: Int, shutdownOption: Int, dt_hour: Float64,
        fixed_percent: Float64,
        dispatchInput_kW: List[Float64],
        canCharge: List[Bool],
        canDischarge: List[Bool],
        discharge_percent: Dict[Int, Float64], 
        discharge_units: Dict[Int, Int],
        scheduleWeekday: matrix_t[Int],
        scheduleWeekend: matrix_t[Int]):
        self.m_powerTotal_kW = 0.0
        self.m_numberOfUnits = numberOfUnits
        self.m_dispatchOption = dispatchOption
        self.m_shutdownOption = shutdownOption
        self.dt_hour = dt_hour
        self.m_fixed_percent = fixed_percent * 0.01
        self.m_dispatchInput_kW = dispatchInput_kW
        self.m_canCharge = canCharge
        self.m_canDischarge = canDischarge
        self.m_discharge_percent = discharge_percent
        self.m_discharge_units = discharge_units
        self.m_scheduleWeekday = scheduleWeekday
        self.m_scheduleWeekend = scheduleWeekend

        for percent in self.m_discharge_percent.items():
            self.m_discharge_percent[percent[].key] = percent[].value * 0.01

        if numberOfUnits > 0:
            self.m_fuelCellVector.append(fuelCell)

        for fc in range(1, numberOfUnits):
            self.m_fuelCellVector.append(Pointer[FuelCell].alloc(1))
            self.m_fuelCellVector[fc].init(*fuelCell)

        for fc in range(numberOfUnits):
            if not self.m_fuelCellVector[fc][].isInitialized():
                var power_kW: Float64 = 0.0
                if self.m_dispatchOption == FC_DISPATCH_OPTION.FIXED:
                    power_kW = self.m_fuelCellVector[fc][].getMaxPowerOriginal() * self.m_fixed_percent
                elif self.m_dispatchOption == FC_DISPATCH_OPTION.LOAD_FOLLOW:
                    power_kW = self.m_fuelCellVector[fc][].getMaxPowerOriginal()
                elif self.m_dispatchOption == FC_DISPATCH_OPTION.MANUAL:
                    var period: Int = self.m_scheduleWeekday[0, 0]
                    if not util.weekday(0):
                        period = self.m_scheduleWeekend[0, 0]
                    var discharge_percent_init: Float64 = 0.0
                    var canDischargeInit: Bool = self.m_canDischarge[period - 1]
                    var numberOfUnitsToRun: Int = 0
                    if canDischargeInit:
                        numberOfUnitsToRun = self.m_discharge_units[period - 1]
                        discharge_percent_init = self.m_discharge_percent[period - 1]
                        if numberOfUnitsToRun > self.m_numberOfUnits:
                            numberOfUnitsToRun = self.m_numberOfUnits
                    var on: Float64 = 1.0 if fc < numberOfUnitsToRun else 0.0
                    power_kW = on * discharge_percent_init * self.m_fuelCellVector[fc][].getMaxPowerOriginal()
                else:
                    power_kW = self.m_dispatchInput_kW[0]
                self.m_fuelCellVector[fc][].initializeHourZeroPower(power_kW)

        var tmp: Pointer[BatteryPowerFlow] = Pointer[BatteryPowerFlow].alloc(1)
        tmp.init(self.dt_hour)
        self.m_batteryPowerFlow = tmp
        self.m_batteryPower = self.m_batteryPowerFlow[].getBatteryPower()
        self.m_batteryPower[].connectionMode = ChargeController.AC_CONNECTED

    def __del__(owned self):
        for fc in range(1, self.m_numberOfUnits):
            if self.m_fuelCellVector[fc]:
                del self.m_fuelCellVector[fc][]
                self.m_fuelCellVector[fc] = Pointer[FuelCell]()
        for fc in range(self.m_fuelCellVector.size):
            if fc == 0:
                continue
            if self.m_fuelCellVector[fc]:
                del self.m_fuelCellVector[fc][]
                self.m_fuelCellVector[fc] = Pointer[FuelCell]()

    def runSingleTimeStep(inout self, hour_of_year: Int, year_idx: Int, powerSystem_kWac: Float64 = 0.0, powerLoad_kWac: Float64 = 0.0):
        self.m_powerTotal_kW = 0.0
        self.m_powerMaxPercentAverage_percent = 0.0
        self.m_loadAverage_percent = 0.0
        self.m_efficiencyAverage_percent = 0.0
        self.m_powerThermalTotal_kW = 0.0
        self.m_fuelConsumedTotal_MCf = 0.0

        if self.m_dispatchOption == FC_DISPATCH_OPTION.FIXED:
            for fc in range(self.m_fuelCellVector.size):
                var power_kW: Float64 = self.m_fuelCellVector[fc][].getMaxPowerOriginal() * self.m_fixed_percent
                self.m_fuelCellVector[fc][].runSingleTimeStep(power_kW)
                self.m_powerTotal_kW += self.m_fuelCellVector[fc][].getPower()
                self.m_powerMaxPercentAverage_percent += self.m_fuelCellVector[fc][].getPowerMaxPercent() / self.m_numberOfUnits
                self.m_loadAverage_percent += self.m_fuelCellVector[fc][].getPercentLoad() / self.m_numberOfUnits
                self.m_efficiencyAverage_percent += self.m_fuelCellVector[fc][].getElectricalEfficiency() * 100.0 / self.m_numberOfUnits
                self.m_powerThermalTotal_kW += self.m_fuelCellVector[fc][].getPowerThermal()
                self.m_fuelConsumedTotal_MCf += self.m_fuelCellVector[fc][].getFuelConsumption()

        elif self.m_dispatchOption == FC_DISPATCH_OPTION.LOAD_FOLLOW:
            for fc in range(self.m_fuelCellVector.size):
                var power_kW: Float64 = fmax(0.0, powerLoad_kWac - powerSystem_kWac)
                self.m_fuelCellVector[fc][].runSingleTimeStep(power_kW / self.m_fuelCellVector.size)
                self.m_powerTotal_kW += self.m_fuelCellVector[fc][].getPower()
                self.m_powerMaxPercentAverage_percent += self.m_fuelCellVector[fc][].getPowerMaxPercent() / self.m_numberOfUnits
                self.m_loadAverage_percent += self.m_fuelCellVector[fc][].getPercentLoad() / self.m_numberOfUnits
                self.m_efficiencyAverage_percent += self.m_fuelCellVector[fc][].getElectricalEfficiency() * 100.0 / self.m_numberOfUnits
                self.m_powerThermalTotal_kW += self.m_fuelCellVector[fc][].getPowerThermal()
                self.m_fuelConsumedTotal_MCf += self.m_fuelCellVector[fc][].getFuelConsumption()

        elif self.m_dispatchOption == FC_DISPATCH_OPTION.MANUAL:
            var month: Int = 0
            var hour: Int = 0
            util.month_hour(hour_of_year, month, hour)
            var period: Int = self.m_scheduleWeekday[month - 1, hour - 1]
            if not util.weekday(hour_of_year):
                period = self.m_scheduleWeekend[month - 1, hour - 1]
            var numberOfUnitsToRun: Int = 0
            var discharge_percent: Float64 = 0.0
            var canDischarge: Bool = self.m_canDischarge[period - 1]
            if canDischarge:
                numberOfUnitsToRun = self.m_discharge_units[period - 1]
                discharge_percent = self.m_discharge_percent[period - 1]
                if numberOfUnitsToRun > self.m_numberOfUnits:
                    numberOfUnitsToRun = self.m_numberOfUnits
            for fc in range(self.m_numberOfUnits):
                var on: Float64 = 1.0 if fc < numberOfUnitsToRun else 0.0
                var power_kW: Float64 = on * discharge_percent * self.m_fuelCellVector[fc][].getMaxPowerOriginal()
                self.m_fuelCellVector[fc][].runSingleTimeStep(power_kW)
                self.m_fuelConsumedTotal_MCf += self.m_fuelCellVector[fc][].getFuelConsumption()
                self.m_powerTotal_kW += self.m_fuelCellVector[fc][].getPower()
                self.m_powerMaxPercentAverage_percent += self.m_fuelCellVector[fc][].getPowerMaxPercent() / self.m_numberOfUnits
                self.m_loadAverage_percent += self.m_fuelCellVector[fc][].getPercentLoad() / self.m_numberOfUnits
                self.m_efficiencyAverage_percent += self.m_fuelCellVector[fc][].getElectricalEfficiency() * 100.0 / self.m_numberOfUnits

        else:
            for fc in range(self.m_fuelCellVector.size):
                var power_kW: Float64 = self.m_dispatchInput_kW[year_idx]
                self.m_fuelCellVector[fc][].runSingleTimeStep(power_kW)
                self.m_fuelConsumedTotal_MCf += self.m_fuelCellVector[fc][].getFuelConsumption()
                self.m_powerTotal_kW += self.m_fuelCellVector[fc][].getPower()
                self.m_powerMaxPercentAverage_percent += self.m_fuelCellVector[fc][].getPowerMaxPercent() / self.m_numberOfUnits
                self.m_loadAverage_percent += self.m_fuelCellVector[fc][].getPercentLoad() / self.m_numberOfUnits
                self.m_efficiencyAverage_percent += self.m_fuelCellVector[fc][].getElectricalEfficiency() * 100.0 / self.m_numberOfUnits
                self.m_powerThermalTotal_kW += self.m_fuelCellVector[fc][].getPowerThermal()

        self.m_batteryPower[].powerSystem = powerSystem_kWac
        self.m_batteryPower[].powerLoad = powerLoad_kWac
        self.m_batteryPower[].powerFuelCell = self.m_powerTotal_kW
        self.m_batteryPowerFlow[].calculate()

    def setDispatchOption(inout self, dispatchOption: Int):
        self.m_dispatchOption = dispatchOption

    def setFixedDischargePercentage(inout self, discharge_percent: Float64):
        self.m_fixed_percent = discharge_percent * 0.01

    def setManualDispatchUnits(inout self, unitsByPeriod: Dict[Int, Int]):
        if unitsByPeriod.size == self.m_discharge_units.size:
            self.m_discharge_units = unitsByPeriod

    def getPower(self) -> Float64:
        return self.m_powerTotal_kW

    def getPowerMaxPercent(self) -> Float64:
        return self.m_powerMaxPercentAverage_percent

    def getPercentLoad(self) -> Float64:
        return self.m_loadAverage_percent

    def getElectricalEfficiencyPercent(self) -> Float64:
        return self.m_efficiencyAverage_percent

    def getPowerThermal(self) -> Float64:
        return self.m_powerThermalTotal_kW

    def getFuelConsumption(self) -> Float64:
        return self.m_fuelConsumedTotal_MCf

    def getBatteryPower(self) -> Pointer[BatteryPower]:
        return self.m_batteryPower