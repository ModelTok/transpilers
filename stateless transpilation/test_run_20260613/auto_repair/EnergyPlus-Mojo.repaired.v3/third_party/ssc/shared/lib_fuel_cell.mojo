from lib_util import util
from math import fabs, fmin, fmax, ceil, floor
from memory import Pointer
from utils import List, Dict, String

const BTU_PER_KWH: Float64 = 3412.14163
const MMBTU_PER_BTU: Float64 = 1000000
const BTU_PER_MMBTU: Float64 = 1.0 / MMBTU_PER_BTU
const FT3_PER_MCF: Float64 = 1000

def BTU_TO_MCF(BTU: Float64, LHV_BTU_PER_FT3: Float64) -> Float64:
    return BTU / (LHV_BTU_PER_FT3 * FT3_PER_MCF)

def MCF_TO_BTU(MCF: Float64, LHV_BTU_PER_FT3: Float64) -> Float64:
    return MCF * LHV_BTU_PER_FT3 * FT3_PER_MCF

def MCF_TO_KWH(MCF: Float64, LHV_BTU_PER_FT3: Float64) -> Float64:
    return MCF_TO_BTU(MCF, LHV_BTU_PER_FT3) / BTU_PER_KWH

@value
struct FuelCell:
    var dt_hour: Float64
    var m_unitPowerMax_kW: Float64
    var m_unitPowerMin_kW: Float64
    var m_startup_hours: Float64
    var m_is_started: Bool
    var m_shutdown_hours: Float64
    var m_dynamicResponseUp_kWperHour: Float64
    var m_dynamicResponseDown_kWperHour: Float64
    var m_degradation_kWperHour: Float64
    var m_degradationRestart_kW: Float64
    var m_scheduledShutdowns: util.matrix_t[UInt]
    var m_replacementOption: UInt
    var m_replacement_percent: Float64
    var m_replacementSchedule: List[UInt]
    var m_efficiencyChoice: UInt
    var m_efficiencyTable: util.matrix_t[Float64]
    var m_lowerHeatingValue_BtuPerFt3: Float64
    var m_higherHeatingValue_BtuPerFt3: Float64
    var m_availableFuel_MCf: Float64
    var m_shutdownOption: Int
    var m_initialized: Bool
    var m_startingUp: Bool
    var m_startedUp: Bool
    var m_shuttingDown: Bool
    var m_shutDown: Bool
    var m_hoursSinceStart: Float64
    var m_hoursSinceStop: Float64
    var m_hoursRampUp: Float64
    var m_powerMax_kW: Float64
    var m_powerThermal_kW: Float64
    var m_power_kW: Float64
    var m_powerMaxPercentOfOriginal_percent: Float64
    var m_powerLoad_percent: Float64
    var m_powerPrevious_kW: Float64
    var m_fuelConsumed_MCf: Float64
    var m_efficiency_percent: Float64
    var m_heatRecovery_percent: Float64
    var m_replacementCount: Int
    var m_fuelConsumptionMap_MCf: Dict[Float64, Float64]
    var m_efficiencyMap: Dict[Float64, Float64]
    var m_heatRecoveryMap: Dict[Float64, Float64]
    var m_hour: Float64
    var m_year: UInt

    def __init__(inout self):
        """Nothing to do"""

    def __init__(inout self, unitPowerMax_kW: Float64, unitPowerMin_kW: Float64, 
        startup_hours: Float64, is_started: Bool, shutdown_hours: Float64,
        dynamicResponseUp_kWperHour: Float64, dynamicResponseDown_kWperHour: Float64,
        degradation_kWperHour: Float64, degradationRestart_kW: Float64,
        replacementOption: UInt, replacement_percent: Float64, replacementSchedule: List[UInt],
        shutdownTable: util.matrix_t[UInt],
        efficiencyChoice: UInt, efficiencyTable: util.matrix_t[Float64],
        lowerHeatingValue_BtuPerFt3: Float64, higherHeatingValue_BtuPerFt3: Float64, availableFuel_Mcf: Float64,
        shutdownOption: Int, dt_hour: Float64):
        self.dt_hour = dt_hour
        self.m_unitPowerMax_kW = unitPowerMax_kW
        self.m_unitPowerMin_kW = unitPowerMin_kW
        self.m_startup_hours = startup_hours
        self.m_is_started = is_started
        self.m_shutdown_hours = shutdown_hours
        self.m_dynamicResponseUp_kWperHour = dynamicResponseUp_kWperHour
        self.m_dynamicResponseDown_kWperHour = dynamicResponseDown_kWperHour
        self.m_degradation_kWperHour = degradation_kWperHour
        self.m_degradationRestart_kW = degradationRestart_kW
        self.m_scheduledShutdowns = shutdownTable
        self.m_replacementOption = replacementOption
        self.m_replacement_percent = replacement_percent * 0.01
        self.m_replacementSchedule = replacementSchedule
        self.m_efficiencyChoice = efficiencyChoice
        self.m_efficiencyTable = efficiencyTable
        self.m_lowerHeatingValue_BtuPerFt3 = lowerHeatingValue_BtuPerFt3
        self.m_higherHeatingValue_BtuPerFt3 = higherHeatingValue_BtuPerFt3
        self.m_availableFuel_MCf = availableFuel_Mcf
        self.m_shutdownOption = shutdownOption
        self.m_powerMax_kW = unitPowerMax_kW
        self.m_power_kW = 0.0
        self.m_powerMaxPercentOfOriginal_percent = 0.0
        self.m_powerLoad_percent = 0.0
        self.m_powerPrevious_kW = 0.0
        self.m_replacementCount = 0
        self.m_fuelConsumptionMap_MCf = Dict[Float64, Float64]()
        self.m_efficiencyMap = Dict[Float64, Float64]()
        self.m_heatRecoveryMap = Dict[Float64, Float64]()
        self.m_hour = 0.0
        self.m_year = 0
        self.m_startingUp = False
        self.m_startedUp = False
        self.m_hoursSinceStart = 0.0
        self.m_shutDown = False
        self.m_shuttingDown = False
        self.m_hoursSinceStop = 0.0
        self.m_hoursRampUp = 0.0
        self.m_powerThermal_kW = 0.0
        self.m_fuelConsumed_MCf = 0.0
        self.m_efficiency_percent = 0.0
        self.m_heatRecovery_percent = 0.0
        self.m_initialized = True

        for r in range(self.m_efficiencyTable.nrows()):
            self.m_efficiencyTable[r][0] *= 0.01
            self.m_efficiencyTable[r][1] *= 0.01
            self.m_efficiencyTable[r][2] *= 0.01
            var fuelConsumption_Mcf: Float64 = 0.0
            if self.m_efficiencyTable[r][0] > 0 and self.m_efficiencyTable[r][1] > 0:
                var fuelConsumption_Btu: Float64 = BTU_PER_KWH * dt_hour * self.m_efficiencyTable[r][0] * self.m_unitPowerMax_kW / (self.m_efficiencyTable[r][1] * self.m_higherHeatingValue_BtuPerFt3 / self.m_lowerHeatingValue_BtuPerFt3)
                fuelConsumption_Mcf = BTU_TO_MCF(fuelConsumption_Btu, self.m_lowerHeatingValue_BtuPerFt3)
            self.m_fuelConsumptionMap_MCf[self.m_efficiencyTable[r][0]] = fuelConsumption_Mcf
            self.m_efficiencyMap[self.m_efficiencyTable[r][0]] = self.m_efficiencyTable[r][1]
            self.m_heatRecoveryMap[self.m_efficiencyTable[r][0]] = self.m_efficiencyTable[r][2]
        self.init()

    def __copyinit__(inout self, other: Self):
        self.dt_hour = other.dt_hour
        self.m_unitPowerMax_kW = other.m_unitPowerMax_kW
        self.m_unitPowerMin_kW = other.m_unitPowerMin_kW
        self.m_startup_hours = other.m_startup_hours
        self.m_is_started = other.m_is_started
        self.m_shutdown_hours = other.m_shutdown_hours
        self.m_dynamicResponseUp_kWperHour = other.m_dynamicResponseUp_kWperHour
        self.m_dynamicResponseDown_kWperHour = other.m_dynamicResponseDown_kWperHour
        self.m_degradation_kWperHour = other.m_degradation_kWperHour
        self.m_degradationRestart_kW = other.m_degradationRestart_kW
        self.m_scheduledShutdowns = other.m_scheduledShutdowns
        self.m_replacementOption = other.m_replacementOption
        self.m_replacement_percent = other.m_replacement_percent * 0.01
        self.m_replacementSchedule = other.m_replacementSchedule
        self.m_efficiencyChoice = other.m_efficiencyChoice
        self.m_efficiencyTable = other.m_efficiencyTable
        self.m_lowerHeatingValue_BtuPerFt3 = other.m_lowerHeatingValue_BtuPerFt3
        self.m_higherHeatingValue_BtuPerFt3 = other.m_higherHeatingValue_BtuPerFt3
        self.m_availableFuel_MCf = other.m_availableFuel_MCf
        self.m_shutdownOption = other.m_shutdownOption
        self.m_fuelConsumptionMap_MCf = Dict[Float64, Float64]()
        self.m_efficiencyMap = Dict[Float64, Float64]()
        self.m_heatRecoveryMap = Dict[Float64, Float64]()
        self.m_hour = 0.0
        self.m_year = 0
        self.m_startingUp = False
        self.m_startedUp = False
        self.m_hoursSinceStart = 0.0
        self.m_shutDown = False
        self.m_shuttingDown = False
        self.m_hoursSinceStop = 0.0
        self.m_hoursRampUp = 0.0
        self.m_powerMax_kW = 0.0
        self.m_powerThermal_kW = 0.0
        self.m_power_kW = 0.0
        self.m_powerPrevious_kW = 0.0
        self.m_fuelConsumed_MCf = 0.0
        self.m_replacementCount = 0
        self.m_powerMaxPercentOfOriginal_percent = 0.0
        self.m_powerLoad_percent = 0.0
        self.m_efficiency_percent = 0.0
        self.m_heatRecovery_percent = 0.0
        self.m_initialized = True
        self.init()

    def __moveinit__(inout self, owned other: Self):
        self = other

    def __del__(owned self):
        """Nothing to do"""

    def init(inout self):
        self.m_startingUp = False
        self.m_startedUp = False
        self.m_hoursSinceStart = 0.0
        self.m_shutDown = False
        self.m_shuttingDown = False
        self.m_hoursSinceStop = 0.0
        self.m_hoursRampUp = ceil(self.m_unitPowerMin_kW / self.m_dynamicResponseUp_kWperHour)
        self.m_powerMax_kW = self.m_unitPowerMax_kW
        self.m_powerThermal_kW = 0.0
        self.m_power_kW = 0.0
        self.m_powerPrevious_kW = 0.0
        self.m_fuelConsumed_MCf = 0.0
        self.m_replacementCount = 0
        self.m_hour = 0.0
        self.m_year = 0
        self.m_initialized = True
        if self.m_is_started:
            self.m_initialized = False

    def initializeHourZeroPower(inout self, power_kW: Float64):
        self.m_power_kW = power_kW

    def isInitialized(self) -> Bool:
        return self.m_initialized

    def isStarting(self) -> Bool:
        return self.m_startingUp

    def isRunning(self) -> Bool:
        return self.m_startedUp

    def isShutDown(self) -> Bool:
        return self.m_shutDown

    def isShuttingDown(self) -> Bool:
        return self.m_shuttingDown

    def interpolateMap(self, key: Float64, mapDouble: Dict[Float64, Float64]) -> Float64:
        var p1: Float64 = 0.0
        var p2: Float64 = 0.0
        var f1: Float64 = 0.0
        var f2: Float64 = 0.0
        var f: Float64 = 0.0
        var m: Float64 = 0.0
        var keys = List[Float64]()
        for k in mapDouble.keys():
            keys.append(k)
        keys.sort()
        for i in range(len(keys)):
            var fc_key = keys[i]
            var fc_val = mapDouble[fc_key]
            if i + 1 < len(keys):
                var fc_next_key = keys[i + 1]
                var fc_next_val = mapDouble[fc_next_key]
                if key == fc_key:
                    f = fc_val
                    break
                elif key == fc_next_key:
                    f = fc_next_val
                    break
                elif key > fc_key and key < fc_next_key:
                    p1 = fc_key
                    p2 = fc_next_key
                    f1 = fc_val
                    f2 = fc_next_val
                    if fabs(p2 - p1) > 0.0:
                        m = (f2 - f1) / (p2 - p1)
                        f = f1 + m * (key - p1)
                    break
            else:
                if key > fc_key:
                    f = fc_val
                    break
        return f

    def calculateEfficiencyCurve(inout self, fraction: Float64):
        if not self.isShutDown():
            self.m_fuelConsumed_MCf = self.interpolateMap(fraction, self.m_fuelConsumptionMap_MCf)
            self.m_efficiency_percent = self.interpolateMap(fraction, self.m_efficiencyMap)
            self.m_heatRecovery_percent = self.interpolateMap(fraction, self.m_heatRecoveryMap)
        else:
            self.m_fuelConsumed_MCf = 0.0
            self.m_efficiency_percent = 0.0
            self.m_heatRecovery_percent = 0.0

    def getPercentLoad(inout self) -> Float64:
        var power_max: Float64 = self.m_unitPowerMax_kW
        if self.m_efficiencyChoice == 1:  # DEGRADED_MAX
            power_max = self.m_powerMax_kW
        self.m_powerLoad_percent = 100.0 * self.m_power_kW / power_max
        return self.m_powerLoad_percent

    def getLoadFraction(inout self) -> Float64:
        return self.getPercentLoad() * 0.01

    def checkPowerResponse(inout self):
        var dP: Float64 = (self.m_power_kW - self.m_powerPrevious_kW) / self.dt_hour
        var dP_max: Float64 = 0.0
        if dP > 0.0:
            dP_max = fmin(fabs(dP), self.m_dynamicResponseUp_kWperHour)
        else:
            dP_max = fmin(fabs(dP), self.m_dynamicResponseDown_kWperHour)
        var sign: Float64 = 1.0
        if fabs(dP) > 0.0:
            sign = dP / fabs(dP)
        if sign > 0.0:
            self.m_power_kW = fmin(self.m_power_kW, (self.m_powerPrevious_kW + (dP_max * self.dt_hour * sign)))
        else:
            self.m_power_kW = fmax(self.m_power_kW, (self.m_powerPrevious_kW + (dP_max * self.dt_hour * sign)))

    def getPower(self) -> Float64:
        return self.m_power_kW

    def getPowerMaxPercent(self) -> Float64:
        return self.m_powerMaxPercentOfOriginal_percent

    def getPowerThermal(self) -> Float64:
        return self.m_powerThermal_kW

    def getMaxPowerOriginal(self) -> Float64:
        return self.m_unitPowerMax_kW

    def getMaxPower(self) -> Float64:
        return self.m_powerMax_kW

    def getMinPower(self) -> Float64:
        return self.m_unitPowerMin_kW

    def getFuelConsumption(self) -> Float64:
        return self.m_fuelConsumed_MCf

    def getAvailableFuel(self) -> Float64:
        return self.m_availableFuel_MCf

    def getElectricalEfficiency(self) -> Float64:
        return self.m_efficiency_percent

    def getHeatRecoveryEfficiency(self) -> Float64:
        return self.m_heatRecovery_percent

    def getTotalReplacements(self) -> Int:
        return self.m_replacementCount

    def resetReplacements(inout self):
        self.m_replacementCount = 0

    def setSystemProperties(inout self, nameplate_kW: Float64, min_kW: Float64, startup_hours: Float64, shutdown_hours: Float64,
        dynamicResponseUp_kWperHour: Float64, dynamicResponseDown_kWperHour: Float64):
        self.m_unitPowerMax_kW = nameplate_kW
        self.m_unitPowerMin_kW = min_kW
        self.m_startup_hours = startup_hours
        self.m_shutdown_hours = shutdown_hours
        self.m_dynamicResponseUp_kWperHour = dynamicResponseUp_kWperHour
        self.m_dynamicResponseDown_kWperHour = dynamicResponseDown_kWperHour
        self.m_powerMax_kW = self.m_unitPowerMax_kW

    def setReplacementOption(inout self, replacementOption: UInt):
        self.m_replacementOption = replacementOption

    def setReplacementCapacity(inout self, replacement_percent: Float64):
        self.m_replacement_percent = replacement_percent * 0.01

    def setDegradationkWPerHour(inout self, degradation_kWPerHour: Float64):
        self.m_degradation_kWperHour = degradation_kWPerHour

    def setDegradationRestartkW(inout self, degradation_kW: Float64):
        self.m_degradationRestart_kW = degradation_kW

    def setScheduledShutdowns(inout self, shutdowns: util.matrix_t[UInt]):
        self.m_scheduledShutdowns = shutdowns

    def setStartupHours(inout self, startup_hours: Float64, is_started: Bool):
        self.m_startup_hours = startup_hours
        if is_started:
            self.m_power_kW = self.m_unitPowerMin_kW

    def setShutdownOption(inout self, shutdownOption: Int):
        self.m_shutdownOption = shutdownOption

    def checkStatus(inout self, power_kW: Float64):
        if not self.isShuttingDown() and not self.isRunning() and \
            (power_kW > 0.0 or self.isStarting()) and self.m_availableFuel_MCf > 0.0 and self.m_powerMax_kW > self.m_unitPowerMin_kW:
            self.m_hoursSinceStart += self.dt_hour
            if (self.m_hoursSinceStart > self.m_startup_hours) or (self.m_hour <= self.m_startup_hours and self.m_is_started):
                self.m_startedUp = True
                self.m_startingUp = False
                self.m_power_kW = power_kW
            elif self.m_hoursSinceStart <= self.m_startup_hours:
                self.m_startingUp = True
                self.m_shuttingDown = False
                self.m_shutDown = False
                self.m_hoursSinceStop = 0.0
        elif self.isRunning():
            self.m_hoursSinceStart += self.dt_hour
            self.m_power_kW = power_kW
        self.checkMinTurndown()
        if self.isShuttingDown():
            self.m_power_kW = 0.0
            self.m_hoursSinceStop += self.dt_hour
        elif self.m_scheduledShutdowns.length() > 0 and not self.m_shutDown:
            for r in range(self.m_scheduledShutdowns.nrows()):
                var shutdown_hourOfYear: Float64 = Float64(self.m_scheduledShutdowns[r][0])
                var duration_hours: Float64 = Float64(self.m_scheduledShutdowns[r][1])
                if duration_hours > 0.0:
                    if self.m_hour == shutdown_hourOfYear:
                        self.m_shuttingDown = True
                        self.m_startingUp = False
                        self.m_startedUp = False
                        self.m_hoursSinceStart = 0.0
                        self.m_hoursSinceStop = 0.0
                    if self.m_hour >= shutdown_hourOfYear and self.m_hour < shutdown_hourOfYear + duration_hours:
                        self.m_power_kW = 0.0
                        self.m_hoursSinceStop += self.dt_hour
                        break
        if self.m_hoursSinceStop > self.m_shutdown_hours:
            self.m_shuttingDown = False
            self.m_shutDown = True

    def checkMinTurndown(inout self):
        if self.isStarting() or self.isShutDown():
            self.m_power_kW = 0.0
        elif self.m_power_kW < self.m_unitPowerMin_kW and self.m_hoursSinceStart > self.m_startup_hours + self.m_hoursRampUp:
            if self.m_shutdownOption == 0:  # IDLE
                self.m_power_kW = self.m_unitPowerMin_kW
            else:
                self.m_startedUp = False
                self.m_shuttingDown = True
                self.m_hoursSinceStart = 0.0
                self.m_power_kW = 0.0
        elif self.isRunning():
            self.m_power_kW = fmax(self.m_power_kW, self.m_unitPowerMin_kW)

    def checkMaxLimit(inout self):
        self.m_power_kW = fmin(self.m_power_kW, self.m_unitPowerMax_kW)

    def checkAvailableFuel(inout self):
        self.m_availableFuel_MCf -= self.m_fuelConsumed_MCf
        if self.m_availableFuel_MCf <= 0.0:
            self.m_startedUp = False
            self.m_shutDown = True
            self.m_shuttingDown = False
            self.m_startingUp = False
            self.m_hoursSinceStart = 0.0
            self.m_hoursSinceStop = 0.0

    def applyDegradation(inout self):
        if self.isRunning() and self.m_power_kW > 0.0:
            self.m_powerMax_kW -= self.m_degradation_kWperHour * self.dt_hour
            self.m_power_kW = fmin(self.m_power_kW, self.m_powerMax_kW)
        elif self.isShuttingDown() and self.m_hoursSinceStop == 1.0:
            self.m_powerMax_kW -= self.m_degradationRestart_kW
            if self.m_powerMax_kW < 0.0:
                self.m_powerMax_kW = 0.0
        if self.m_replacementOption == 1:  # REPLACE_AT_CAPACITY
            if self.m_powerMax_kW < self.m_unitPowerMax_kW * self.m_replacement_percent:
                self.m_powerMax_kW = self.m_unitPowerMax_kW
                self.m_replacementCount += 1
        elif self.m_replacementOption == 2:  # REPLACE_ON_SCHEDULE
            var hour: Int = Int(floor(self.m_hour))
            if hour % 8760 == 0 and self.m_replacementSchedule[self.m_year] > 0:
                self.m_powerMax_kW = self.m_unitPowerMax_kW
                self.m_replacementCount += 1
        if self.m_powerMax_kW <= self.m_unitPowerMin_kW:
            self.m_power_kW = 0.0
            self.m_startedUp = False
            self.m_shutDown = True
            self.m_shuttingDown = False
            self.m_hoursSinceStart = 0.0
            self.m_hoursSinceStop = 0.0
        self.m_powerMaxPercentOfOriginal_percent = 100.0 * self.m_powerMax_kW / self.m_unitPowerMax_kW

    def applyEfficiency(inout self):
        if self.isShuttingDown():
            self.calculateEfficiencyCurve(0.0)
            self.m_powerThermal_kW = self.m_powerMax_kW * self.m_heatRecovery_percent
        elif self.isShutDown():
            self.calculateEfficiencyCurve(0.0)
            self.m_powerThermal_kW = 0.0
            self.m_fuelConsumed_MCf = 0.0
        else:
            self.calculateEfficiencyCurve(self.getLoadFraction())
            self.m_powerThermal_kW = self.m_power_kW
            self.m_powerThermal_kW *= self.m_heatRecovery_percent

    def calculateTime(inout self):
        self.m_hour += self.dt_hour
        var hour: Int = Int(floor(self.m_hour))
        if hour % 8760 == 0:
            self.m_year += 1

    def runSingleTimeStep(inout self, power_kW: Float64):
        self.m_powerPrevious_kW = self.m_power_kW
        self.checkStatus(power_kW)
        if self.isRunning():
            self.checkPowerResponse()
        self.checkMinTurndown()
        self.checkMaxLimit()
        self.applyDegradation()
        self.applyEfficiency()
        self.checkAvailableFuel()
        self.calculateTime()