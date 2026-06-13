/**
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
from lib_battery import battery_t, BatteryPower, BatteryPowerFlow
from lib_battery_powerflow import BatteryPowerFlow as BatteryPowerFlowImpl
from lib_shared_inverter import SharedInverter
from memory import Pointer, alloc, free
from math import abs, max, min, round
from builtin import Int, Float64, Bool, List, String

const tolerance: Float64 = 1e-7
const low_tolerance: Float64 = 1e-7
const SIZE_MAX: Int = (1 << 63) - 1

# Forward declarations
struct grid_point:
    var _grid: Float64
    var _hour: Int
    var _step: Int
    var _cost: Float64
    var _marginal_cost: Float64

    def __init__(inout self, grid: Float64 = 0.0, hour: Int = 0, step: Int = 0, cost: Float64 = 0.0, marginal_cost: Float64 = 0.0):
        self._grid = grid
        self._hour = hour
        self._step = step
        self._cost = cost
        self._marginal_cost = marginal_cost

    def Grid(self) -> Float64:
        return self._grid

    def Hour(self) -> Int:
        return self._hour

    def Step(self) -> Int:
        return self._step

    def Cost(self) -> Float64:
        return self._cost

    def MarginalCost(self) -> Float64:
        return self._marginal_cost

struct byGrid:
    def __call__(self, a: grid_point, b: grid_point) -> Bool:
        return a.Grid() > b.Grid()

struct byCost:
    def __call__(self, a: grid_point, b: grid_point) -> Bool:
        if a.Cost() == b.Cost():
            return a.Grid() > b.Grid()
        return a.Cost() > b.Cost()

struct byLowestMarginalCost:
    def __call__(self, a: grid_point, b: grid_point) -> Bool:
        if abs(a.MarginalCost() - b.MarginalCost()) < 1e-7:
            if abs(a.Grid()) < 1e-7 or abs(b.Grid()) < 1e-7:
                return a.Grid() < b.Grid()
            elif abs((a.Cost() / a.Grid()) - (b.Cost() / b.Grid())) < 1e-7:
                return a.Grid() < b.Grid()
            return (a.Cost() / a.Grid()) < (b.Cost() / b.Grid())
        return a.MarginalCost() < b.MarginalCost()

type grid_vec = List[grid_point]

# Dispatch type enum for dynamic_cast replacement
enum DispatchType:
    BASE
    AUTOMATIC

# Dispatch base class
struct dispatch_t:
    enum FOM_MODES: FOM_LOOK_AHEAD = 0, FOM_LOOK_BEHIND = 1, FOM_FORECAST = 2, FOM_CUSTOM_DISPATCH = 3, FOM_MANUAL = 4
    enum BTM_MODES: LOOK_AHEAD = 0, LOOK_BEHIND = 1, MAINTAIN_TARGET = 2, CUSTOM_DISPATCH = 3, MANUAL = 4, FORECAST = 5
    enum METERING: BEHIND = 0, FRONT = 1
    enum PV_PRIORITY: MEET_LOAD = 0, CHARGE_BATTERY = 1
    enum CURRENT_CHOICE: RESTRICT_POWER = 0, RESTRICT_CURRENT = 1, RESTRICT_BOTH = 2
    enum FOM_CYCLE_COST: MODEL_CYCLE_COST = 0, INPUT_CYCLE_COST = 1
    enum CONNECTION: DC_CONNECTED = 0, AC_CONNECTED = 1

    var _Battery: Pointer[battery_t]
    var _Battery_initial: Pointer[battery_t]
    var _dt_hour: Float64
    var _mode: Int
    var m_batteryPowerFlow: Pointer[BatteryPowerFlow]
    var m_batteryPower: Pointer[BatteryPower]
    var _current_choice: Int
    var _t_min: Float64
    var _e_max: Float64
    var _P_target: Float64
    var _t_at_mode: Int
    var _charging: Bool
    var _prev_charging: Bool
    var _grid_recharge: Bool
    var _type: DispatchType  # for dynamic_cast

    def __init__(inout self, Battery: Pointer[battery_t], dt_hour: Float64, SOC_min: Float64, SOC_max: Float64,
                current_choice: Int, Ic_max: Float64, Id_max: Float64,
                Pc_max_kwdc: Float64, Pd_max_kwdc: Float64, Pc_max_kwac: Float64, Pd_max_kwac: Float64,
                t_min: Float64, mode: Int, battMeterPosition: Int):
        self._type = DispatchType.BASE
        var tmp = Pointer[BatteryPowerFlow].alloc()
        tmp[] = BatteryPowerFlow(dt_hour)
        self.m_batteryPowerFlow = tmp
        self.m_batteryPower = self.m_batteryPowerFlow[].getBatteryPower()
        self.m_batteryPower[].currentChargeMax = Ic_max
        self.m_batteryPower[].currentDischargeMax = Id_max
        self.m_batteryPower[].stateOfChargeMax = SOC_max
        self.m_batteryPower[].stateOfChargeMin = SOC_min
        self.m_batteryPower[].depthOfDischargeMax = SOC_max - SOC_min
        self.m_batteryPower[].powerBatteryChargeMaxDC = Pc_max_kwdc
        self.m_batteryPower[].powerBatteryDischargeMaxDC = Pd_max_kwdc
        self.m_batteryPower[].powerBatteryChargeMaxAC = Pc_max_kwac
        self.m_batteryPower[].powerBatteryDischargeMaxAC = Pd_max_kwac
        self.m_batteryPower[].meterPosition = battMeterPosition
        self._Battery = Battery
        self._Battery_initial = Pointer[battery_t].alloc()
        self._Battery_initial[] = battery_t(self._Battery[])  # copy constructor
        self.init(self._Battery, dt_hour, current_choice, t_min, mode)

    def init(inout self, Battery: Pointer[battery_t], dt_hour: Float64, current_choice: Int, t_min: Float64, mode: Int):
        self._dt_hour = dt_hour
        self._current_choice = current_choice
        self._t_min = t_min
        self._mode = mode
        self._t_at_mode = 1000
        self._prev_charging = False
        self._charging = False
        self._e_max = Battery[].V() * Battery[].charge_maximum_lifetime() * 0.001 * 0.01 * (self.m_batteryPower[].stateOfChargeMax - self.m_batteryPower[].stateOfChargeMin)
        self._grid_recharge = False
        self.m_batteryPower[].canClipCharge = False
        self.m_batteryPower[].canSystemCharge = False
        self.m_batteryPower[].canGridCharge = False
        self.m_batteryPower[].canDischarge = False

    def __copyinit__(inout self, other: Self):
        self._type = other._type
        var tmp = Pointer[BatteryPowerFlow].alloc()
        tmp[] = BatteryPowerFlow(other.m_batteryPowerFlow[])  # copy
        self.m_batteryPowerFlow = tmp
        self.m_batteryPower = self.m_batteryPowerFlow[].getBatteryPower()
        self._Battery = Pointer[battery_t].alloc()
        self._Battery[] = battery_t(other._Battery[])  # copy
        self._Battery_initial = Pointer[battery_t].alloc()
        self._Battery_initial[] = battery_t(other._Battery_initial[])  # copy
        self.init(self._Battery, other._dt_hour, other._current_choice, other._t_min, other._mode)

    def copy(inout self, dispatch: Pointer[dispatch_t]):
        self._Battery[].set_state(dispatch[]._Battery[].get_state())
        self._Battery_initial[].set_state(dispatch[]._Battery_initial[].get_state())
        self.init(self._Battery, dispatch[]._dt_hour, dispatch[]._current_choice, dispatch[]._t_min, dispatch[]._mode)
        var tmp = Pointer[BatteryPowerFlow].alloc()
        tmp[] = BatteryPowerFlow(dispatch[].m_batteryPowerFlow[])  # copy
        self.m_batteryPowerFlow = tmp
        self.m_batteryPower = self.m_batteryPowerFlow[].getBatteryPower()

    def delete_clone(inout self):
        if self._Battery:
            free(self._Battery)
        if self._Battery_initial:
            free(self._Battery_initial)
            self._Battery_initial = Pointer[battery_t]()  # null

    def __del__(owned self):
        free(self._Battery_initial)
        free(self.m_batteryPowerFlow)

    def finalize(inout self, idx: Int, I: Float64):
        self._Battery[].set_state(self._Battery_initial[].get_state())
        self.m_batteryPower[].powerBatteryDC = 0.0
        self.m_batteryPower[].powerBatteryAC = 0.0
        self.m_batteryPower[].powerGridToBattery = 0.0
        self.m_batteryPower[].powerBatteryToGrid = 0.0
        self.m_batteryPower[].powerSystemToGrid = 0.0
        self._Battery[].run(idx, I)

    def check_constraints(inout self, I: Float64, count: Int) -> Bool:
        var iterate: Bool
        var I_initial: Float64 = I
        var current_iterate: Bool = False
        var power_iterate: Bool = False
        if self.restrict_current(I):
            current_iterate = True
        elif self.restrict_power(I):
            power_iterate = True
        if I > 0.0 and self._Battery[].SOC() < self.m_batteryPower[].stateOfChargeMin - tolerance:
            self.m_batteryPower[].powerBatteryTarget = self._Battery_initial[].calculate_max_discharge_kw(I)
        elif I < 0.0 and self._Battery[].SOC() > self.m_batteryPower[].stateOfChargeMax + tolerance:
            self.m_batteryPower[].powerBatteryTarget = self._Battery_initial[].calculate_max_charge_kw(I)
        if not self.m_batteryPower[].canGridCharge and I < 0.0 and self.m_batteryPower[].powerGridToBattery > tolerance:
            self.m_batteryPower[].powerBatteryTarget += self.m_batteryPower[].powerGridToBattery
            I = self._Battery[].calculate_current_for_power_kw(self.m_batteryPower[].powerBatteryTarget)
            self.m_batteryPower[].powerGridToBattery = 0.0
        elif self.m_batteryPower[].connectionMode == dispatch_t.CONNECTION.DC_CONNECTED and self.m_batteryPower[].powerGridToBattery > 0.0 and (self.m_batteryPower[].powerSystemToGrid > 0.0 or self.m_batteryPower[].powerSystemToLoad > 0.0):
            self.m_batteryPower[].powerBatteryTarget += self.m_batteryPower[].powerGridToBattery
            I = self._Battery[].calculate_current_for_power_kw(self.m_batteryPower[].powerBatteryTarget)
        var power_to_batt: Float64 = self.m_batteryPower[].powerBatteryDC
        if self.m_batteryPower[].connectionMode == dispatch_t.CONNECTION.DC_CONNECTED:
            power_to_batt = -(self.m_batteryPower[].powerSystemToBattery + self.m_batteryPower[].powerFuelCellToBattery)
            if self.m_batteryPower[].sharedInverter[].powerDC_kW < 0.0:
                power_to_batt += self.m_batteryPower[].sharedInverter[].powerDC_kW
            power_to_batt *= self.m_batteryPower[].singlePointEfficiencyDCToDC
        else:
            power_to_batt = -(self.m_batteryPower[].powerSystemToBattery + self.m_batteryPower[].powerGridToBattery + self.m_batteryPower[].powerFuelCellToBattery)
            power_to_batt *= self.m_batteryPower[].singlePointEfficiencyACToDC
        if self.m_batteryPower[].powerBatteryTarget < 0.0 and abs(power_to_batt - self.m_batteryPower[].powerBatteryTarget) > 0.005 * abs(power_to_batt):
            self.m_batteryPower[].powerBatteryTarget = power_to_batt
            self.m_batteryPower[].powerBatteryDC = self.m_batteryPower[].powerBatteryTarget
            I = self._Battery_initial[].calculate_current_for_power_kw(self.m_batteryPower[].powerBatteryTarget)
        if self.m_batteryPower[].connectionMode == dispatch_t.CONNECTION.DC_CONNECTED and self.m_batteryPower[].sharedInverter[].efficiencyAC < self.m_batteryPower[].inverterEfficiencyCutoff:
            var powerBatterykWdc: Float64 = self._Battery[].I() * self._Battery[].V() * 0.001
            if self.m_batteryPower[].powerBatteryDC > 0.0:
                if powerBatterykWdc + self.m_batteryPower[].powerSystem > self.m_batteryPower[].sharedInverter[].getACNameplateCapacitykW():
                    powerBatterykWdc = self.m_batteryPower[].sharedInverter[].getACNameplateCapacitykW() - self.m_batteryPower[].powerSystem
                    powerBatterykWdc = max(powerBatterykWdc, 0.0)
                    self.m_batteryPower[].powerBatteryTarget = powerBatterykWdc
                    I = self._Battery[].calculate_current_for_power_kw(self.m_batteryPower[].powerBatteryTarget)
            elif self.m_batteryPower[].powerBatteryDC < 0.0 and self.m_batteryPower[].powerGridToBattery > 0.0:
                I *= max(1.0 - abs(self.m_batteryPower[].powerGridToBattery * self.m_batteryPower[].sharedInverter[].efficiencyAC * 0.01 / self.m_batteryPower[].powerBatteryDC), 0.0)
                self.m_batteryPower[].powerBatteryTarget = self._Battery[].calculate_voltage_for_current(I) * I * 0.001
        iterate = abs(I_initial - I) > tolerance
        if not current_iterate:
            current_iterate = self.restrict_current(I)
        if not power_iterate:
            power_iterate = self.restrict_power(I)
        if iterate or current_iterate or power_iterate:
            iterate = True
        if count > 10:  # battery_dispatch::constraintCount = 10
            iterate = False
        if abs(I) > tolerance and (I_initial / I) < 0.0:
            I = 0.0
            iterate = False
        if iterate:
            self._Battery[].set_state(self._Battery_initial[].get_state())
            self.m_batteryPowerFlow[].calculate()
        return iterate

    def SOC_controller(inout self):
        self._charging = self._prev_charging
        if self.m_batteryPower[].powerBatteryDC > 0.0:
            if self._Battery[].SOC() <= self.m_batteryPower[].stateOfChargeMin + tolerance:
                self.m_batteryPower[].powerBatteryDC = 0.0
            else:
                self._charging = False
        elif self.m_batteryPower[].powerBatteryDC < 0.0:
            if self._Battery[].SOC() >= self.m_batteryPower[].stateOfChargeMax - tolerance:
                self.m_batteryPower[].powerBatteryDC = 0.0
            else:
                self._charging = True

    def switch_controller(inout self):
        if self._charging != self._prev_charging:
            if self._t_at_mode <= self._t_min:
                self.m_batteryPower[].powerBatteryDC = 0.0
                self._charging = self._prev_charging
            else:
                self._t_at_mode = 0
        self._t_at_mode += Int(round(self._dt_hour * 60.0))  # util::hour_to_min = 60

    def current_controller(inout self, power_kw: Float64) -> Float64:
        var I: Float64 = self._Battery[].calculate_current_for_power_kw(power_kw)
        self.restrict_current(I)
        return I

    def restrict_current(inout self, I: Float64) -> Bool:
        var iterate: Bool = False
        if self._current_choice == dispatch_t.CURRENT_CHOICE.RESTRICT_CURRENT or self._current_choice == dispatch_t.CURRENT_CHOICE.RESTRICT_BOTH:
            if I < 0.0:
                if abs(I) > self.m_batteryPower[].currentChargeMax:
                    I = -self.m_batteryPower[].currentChargeMax
                    iterate = True
            else:
                if I > self.m_batteryPower[].currentDischargeMax:
                    I = self.m_batteryPower[].currentDischargeMax
                    iterate = True
        return iterate

    def restrict_power(inout self, I: Float64) -> Bool:
        var iterate: Bool = False
        if self._current_choice == dispatch_t.CURRENT_CHOICE.RESTRICT_POWER or self._current_choice == dispatch_t.CURRENT_CHOICE.RESTRICT_BOTH:
            var powerBattery: Float64 = I * self._Battery[].V() * 0.001
            var powerBatteryAC: Float64 = powerBattery
            if powerBattery < 0.0:
                powerBatteryAC = powerBattery / self.m_batteryPower[].singlePointEfficiencyACToDC
            elif powerBattery > 0.0:
                powerBatteryAC = powerBattery * self.m_batteryPower[].singlePointEfficiencyDCToAC
            var dP: Float64 = 0.0
            if powerBattery < 0.0:
                if abs(powerBattery) > self.m_batteryPower[].powerBatteryChargeMaxDC * (1.0 + low_tolerance):
                    dP = abs(self.m_batteryPower[].powerBatteryChargeMaxDC - abs(powerBattery))
                    I -= (dP / abs(powerBattery)) * I
                    iterate = True
                elif self.m_batteryPower[].connectionMode == self.m_batteryPower[].AC_CONNECTED and abs(powerBatteryAC) > self.m_batteryPower[].powerBatteryChargeMaxAC * (1.0 + low_tolerance):
                    dP = abs(self.m_batteryPower[].powerBatteryChargeMaxAC - abs(powerBatteryAC))
                    I -= (dP / abs(powerBattery)) * I
                    iterate = True
                elif self.m_batteryPower[].connectionMode == self.m_batteryPower[].DC_CONNECTED and abs(powerBatteryAC) > self.m_batteryPower[].powerBatteryChargeMaxAC * (1.0 + low_tolerance):
                    dP = abs(self.m_batteryPower[].powerBatteryChargeMaxAC - abs(powerBatteryAC))
                    I -= (dP / abs(powerBattery)) * I
                    iterate = True
            else:
                if abs(powerBattery) > self.m_batteryPower[].powerBatteryDischargeMaxDC * (1.0 + low_tolerance):
                    dP = abs(self.m_batteryPower[].powerBatteryDischargeMaxDC - powerBattery)
                    I -= (dP / abs(powerBattery)) * I
                    iterate = True
                elif abs(powerBatteryAC) > self.m_batteryPower[].powerBatteryDischargeMaxAC * (1.0 + low_tolerance):
                    dP = abs(self.m_batteryPower[].powerBatteryDischargeMaxAC - powerBatteryAC)
                    I -= (dP / abs(powerBattery)) * I
                    iterate = True
        return iterate

    def runDispatch(inout self, year: Int, hour_of_year: Int, step: Int):
        self.SOC_controller()
        self.switch_controller()
        var I: Float64 = self.current_controller(self.m_batteryPower[].powerBatteryDC)
        self._Battery_initial[].set_state(self._Battery[].get_state())
        var iterate: Bool = True
        var count: Int = 0
        var lifetimeIndex: Int = Int(1.0 / self._dt_hour)  # util::lifetimeIndex simplified
        # Note: original uses util::lifetimeIndex(year, hour_of_year, step, steps_per_hour)
        # We'll compute steps_per_hour = 1/dt_hour
        var steps_per_hour: Int = Int(1.0 / self._dt_hour)
        lifetimeIndex = year * 8760 * steps_per_hour + hour_of_year * steps_per_hour + step
        while iterate:
            self.m_batteryPower[].powerBatteryDC = self._Battery[].run(lifetimeIndex, I)
            self.m_batteryPower[].powerSystemLoss = self._Battery[].getLoss()
            self.m_batteryPowerFlow[].calculate()
            iterate = self.check_constraints(I, count)
            if not iterate:
                self.finalize(lifetimeIndex, I)
                self.m_batteryPower[].powerBatteryDC = I * self._Battery[].V() * 0.001
            else:
                self._Battery[].set_state(self._Battery_initial[].get_state())
            count += 1
        self.m_batteryPowerFlow[].calculate()
        self._prev_charging = self._charging

    def power_tofrom_battery(self) -> Float64:
        return self.m_batteryPower[].powerBatteryAC

    def power_tofrom_grid(self) -> Float64:
        return self.m_batteryPower[].powerGrid

    def power_gen(self) -> Float64:
        return self.m_batteryPower[].powerGeneratedBySystem

    def power_pv_to_load(self) -> Float64:
        return self.m_batteryPower[].powerSystemToLoad

    def power_battery_to_load(self) -> Float64:
        return self.m_batteryPower[].powerBatteryToLoad

    def power_grid_to_load(self) -> Float64:
        return self.m_batteryPower[].powerGridToLoad

    def power_fuelcell_to_load(self) -> Float64:
        return self.m_batteryPower[].powerFuelCellToLoad

    def power_pv_to_batt(self) -> Float64:
        return self.m_batteryPower[].powerSystemToBattery

    def power_grid_to_batt(self) -> Float64:
        return self.m_batteryPower[].powerGridToBattery

    def power_fuelcell_to_batt(self) -> Float64:
        return self.m_batteryPower[].powerFuelCellToBattery

    def power_pv_to_grid(self) -> Float64:
        return self.m_batteryPower[].powerSystemToGrid

    def power_battery_to_grid(self) -> Float64:
        return self.m_batteryPower[].powerBatteryToGrid

    def power_fuelcell_to_grid(self) -> Float64:
        return self.m_batteryPower[].powerFuelCellToGrid

    def power_conversion_loss(self) -> Float64:
        return self.m_batteryPower[].powerConversionLoss

    def power_system_loss(self) -> Float64:
        return self.m_batteryPower[].powerSystemLoss

    def power_grid_target(self) -> Float64:
        return 0.0

    def power_batt_target(self) -> Float64:
        return 0.0

    def cost_to_cycle(self) -> Float64:
        return 0.0

    def cost_to_cycle_per_kwh(self) -> Float64:
        return 0.0

    def battery_power_to_fill(self) -> Float64:
        return self._Battery[].power_to_fill(self.m_batteryPower[].stateOfChargeMax)

    def battery_soc(self) -> Float64:
        return self._Battery[].SOC()

    def getBatteryPower(self) -> Pointer[BatteryPower]:
        return self.m_batteryPower

    def getBatteryPowerFlow(self) -> Pointer[BatteryPowerFlow]:
        return self.m_batteryPowerFlow

    def battery_model(self) -> Pointer[battery_t]:
        return self._Battery

# dispatch_automatic_t
struct dispatch_automatic_t:
    var base: dispatch_t
    var _P_pv_ac: List[Float64]
    var _P_cliploss_dc: List[Float64]
    var _day_index: Int
    var _month: Int
    var _num_steps: Int
    var _P_battery_use: List[Float64]
    var _hour_last_updated: Int
    var _dt_hour: Float64
    var _dt_hour_update: Float64
    var _steps_per_hour: Int
    var _nyears: Int
    var curr_year: Int
    var _mode: Int
    var _safety_factor: Float64
    var _forecast_hours: Int
    var m_battReplacementCostPerKWH: List[Float64]
    var m_battCycleCostChoice: Int
    var cycle_costs_by_year: List[Float64]
    var m_cycleCost: Float64

    def __init__(inout self, Battery: Pointer[battery_t], dt_hour: Float64, SOC_min: Float64, SOC_max: Float64,
                current_choice: Int, Ic_max: Float64, Id_max: Float64,
                Pc_max_kwdc: Float64, Pd_max_kwdc: Float64, Pc_max_kwac: Float64, Pd_max_kwac: Float64,
                t_min: Float64, dispatch_mode: Int, pv_dispatch: Int,
                nyears: Int, look_ahead_hours: Int, dispatch_update_frequency_hours: Float64,
                can_charge: Bool, can_clip_charge: Bool, can_grid_charge: Bool, can_fuelcell_charge: Bool,
                battReplacementCostPerkWh: List[Float64], battCycleCostChoice: Int, battCycleCost: List[Float64]):
        self.base = dispatch_t(Battery, dt_hour, SOC_min, SOC_max, current_choice, Ic_max, Id_max,
                               Pc_max_kwdc, Pd_max_kwdc, Pc_max_kwac, Pd_max_kwac,
                               t_min, dispatch_mode, pv_dispatch)
        self.base._type = DispatchType.AUTOMATIC
        self._dt_hour = dt_hour
        self._dt_hour_update = dispatch_update_frequency_hours
        self._hour_last_updated = SIZE_MAX
        self._forecast_hours = look_ahead_hours
        self._steps_per_hour = Int(1.0 / dt_hour)
        self._num_steps = 24 * self._steps_per_hour
        self._day_index = 0
        self._month = 1
        self._nyears = nyears
        self.curr_year = 0
        self._mode = dispatch_mode
        self._safety_factor = 0.03
        self.base.m_batteryPower[].canClipCharge = can_clip_charge
        self.base.m_batteryPower[].canSystemCharge = can_charge
        self.base.m_batteryPower[].canGridCharge = can_grid_charge
        self.base.m_batteryPower[].canFuelCellCharge = can_fuelcell_charge
        self.base.m_batteryPower[].canDischarge = True
        self.m_battReplacementCostPerKWH = battReplacementCostPerkWh
        self.m_battCycleCostChoice = battCycleCostChoice
        self.cycle_costs_by_year = battCycleCost
        self.m_cycleCost = 0.0

    def init_with_pointer(inout self, tmp: Pointer[dispatch_automatic_t]):
        self._day_index = tmp[]._day_index
        self._month = tmp[]._month
        self._num_steps = tmp[]._num_steps
        self._hour_last_updated = tmp[]._hour_last_updated
        self._dt_hour = tmp[]._dt_hour
        self._dt_hour_update = tmp[]._dt_hour_update
        self._steps_per_hour = tmp[]._steps_per_hour
        self._nyears = tmp[]._nyears
        self.curr_year = tmp[].curr_year
        self._mode = tmp[]._mode
        self._safety_factor = tmp[]._safety_factor
        self._forecast_hours = tmp[]._forecast_hours
        self.m_battReplacementCostPerKWH = tmp[].m_battReplacementCostPerKWH
        self.m_battCycleCostChoice = tmp[].m_battCycleCostChoice
        self.m_cycleCost = tmp[].m_cycleCost
        self.cycle_costs_by_year = tmp[].cycle_costs_by_year

    def __copyinit__(inout self, other: Self):
        self.base = dispatch_t(other.base)  # copy base
        self.base._type = DispatchType.AUTOMATIC
        # dynamic_cast equivalent: we assume other is dispatch_automatic_t
        var tmp: Pointer[dispatch_automatic_t] = Pointer[dispatch_automatic_t].address_of(other)
        self.init_with_pointer(tmp)

    def copy(inout self, dispatch: Pointer[dispatch_t]):
        self.base.copy(dispatch)
        # dynamic_cast
        var tmp: Pointer[dispatch_automatic_t] = Pointer[dispatch_automatic_t]()
        if dispatch[]._type == DispatchType.AUTOMATIC:
            tmp = Pointer[dispatch_automatic_t].address_of(dispatch[])  # unsafe cast
        self.init_with_pointer(tmp)

    def update_pv_data(inout self, P_pv_ac: List[Float64]):
        self._P_pv_ac = P_pv_ac

    def update_cliploss_data(inout self, P_cliploss: List[Float64]):
        self._P_cliploss_dc = P_cliploss
        for i in range(self._forecast_hours * self._steps_per_hour):
            self._P_cliploss_dc.append(P_cliploss[i])

    def set_custom_dispatch(inout self, P_batt_dc: List[Float64]):
        self._P_battery_use = P_batt_dc

    def get_mode(self) -> Int:
        return self._mode

    def power_batt_target(self) -> Float64:
        return self.base.m_batteryPower[].powerBatteryTarget

    def dispatch(inout self, year: Int, hour_of_year: Int, step: Int):
        self.base.runDispatch(year, hour_of_year, step)

    def check_constraints(inout self, I: Float64, count: Int) -> Bool:
        var iterate: Bool = self.base.check_constraints(I, count)
        if not iterate:
            var I_initial: Float64 = I
            var P_battery: Float64 = I * self.base._Battery[].V() * 0.001
            var P_target: Float64 = self.base.m_batteryPower[].powerBatteryTarget
            iterate = True
            if self.base.m_batteryPower[].connectionMode == dispatch_t.CONNECTION.DC_CONNECTED and self.base.m_batteryPower[].sharedInverter[].efficiencyAC <= self.base.m_batteryPower[].inverterEfficiencyCutoff and P_target < 0.0:
                iterate = False
            elif P_battery > P_target + tolerance or P_battery < P_target - tolerance:
                var dP: Float64 = P_battery - self.base.m_batteryPower[].powerBatteryTarget
                var SOC: Float64 = self.base._Battery[].SOC()
                if P_battery <= 0.0 and dP > 0.0:
                    if not self.base.m_batteryPower[].canGridCharge:
                        iterate = False
                    if SOC > self.base.m_batteryPower[].stateOfChargeMax - tolerance:
                        iterate = False
                    if I > self.base.m_batteryPower[].currentChargeMax - tolerance or abs(P_battery) > self.base.m_batteryPower[].powerBatteryChargeMaxDC - tolerance or abs(self.base.m_batteryPower[].powerBatteryAC) > self.base.m_batteryPower[].powerBatteryChargeMaxAC - tolerance:
                        iterate = False
                    else:
                        var dP_max: Float64 = min(min(dP, self.base.m_batteryPower[].powerBatteryChargeMaxDC - abs(P_battery)), self.base.m_batteryPower[].powerBatteryChargeMaxAC - abs(self.base.m_batteryPower[].powerBatteryAC))
                        dP = max(dP_max, 0.0)
                elif P_battery > 0.0 and dP < 0.0:
                    if SOC < self.base.m_batteryPower[].stateOfChargeMin + tolerance:
                        iterate = False
                    if I > self.base.m_batteryPower[].currentDischargeMax - tolerance or P_battery > self.base.m_batteryPower[].powerBatteryDischargeMaxDC - tolerance or self.base.m_batteryPower[].powerBatteryAC > self.base.m_batteryPower[].powerBatteryDischargeMaxAC - tolerance:
                        iterate = False
                    else:
                        var dP_max: Float64 = max(max(dP, P_battery - self.base.m_batteryPower[].powerBatteryDischargeMaxDC), self.base.m_batteryPower[].powerBatteryAC - self.base.m_batteryPower[].powerBatteryChargeMaxAC)
                        dP = min(dP_max, 0.0)
                var dQ: Float64 = dP * self._dt_hour * 1000.0 / self.base._Battery[].V()
                var dSOC: Float64 = 100.0 * dQ / self.base._Battery[].charge_maximum_lifetime()
                if iterate:
                    var dI: Float64 = dP * 1000.0 / self.base._Battery[].V()
                    if SOC + dSOC > self.base.m_batteryPower[].stateOfChargeMax + tolerance:
                        var dSOC_use: Float64 = (self.base.m_batteryPower[].stateOfChargeMax - SOC)
                        var dQ_use: Float64 = dSOC_use * 0.01 * self.base._Battery[].charge_maximum_lifetime()
                        dI = dQ_use / self._dt_hour
                    elif SOC + dSOC < self.base.m_batteryPower[].stateOfChargeMin - tolerance:
                        var dSOC_use: Float64 = (self.base.m_batteryPower[].stateOfChargeMin - SOC)
                        var dQ_use: Float64 = dSOC_use * 0.01 * self.base._Battery[].charge_maximum_lifetime()
                        dI = dQ_use / self._dt_hour
                    I -= dI
            if self.base.m_batteryPower[].meterPosition == dispatch_t.METERING.BEHIND:
                if self._mode != dispatch_t.BTM_MODES.CUSTOM_DISPATCH and self.base.m_batteryPower[].powerSystemToGrid > tolerance and self.base.m_batteryPower[].canSystemCharge and self.base._Battery[].SOC() < self.base.m_batteryPower[].stateOfChargeMax - tolerance and abs(I) < abs(self.base.m_batteryPower[].currentChargeMax):
                    if abs(self.base.m_batteryPower[].powerBatteryAC) < tolerance:
                        I -= (self.base.m_batteryPower[].powerSystemToGrid * 1000.0 / self.base._Battery[].V())
                    else:
                        I -= (self.base.m_batteryPower[].powerSystemToGrid / abs(self.base.m_batteryPower[].powerBatteryAC)) * abs(I)
                elif self.base.m_batteryPower[].powerBatteryToGrid > tolerance:
                    if abs(self.base.m_batteryPower[].powerBatteryAC) < tolerance:
                        I -= (self.base.m_batteryPower[].powerBatteryToGrid * 1000.0 / self.base._Battery[].V())
                    else:
                        I -= (self.base.m_batteryPower[].powerBatteryToGrid / abs(self.base.m_batteryPower[].powerBatteryAC)) * abs(I)
                    self.base.m_batteryPower[].powerBatteryTarget -= self.base.m_batteryPower[].powerBatteryToGrid
                    self.base.m_batteryPower[].powerBatteryAC -= self.base.m_batteryPower[].powerBatteryToGrid
                else:
                    iterate = False
            else:
                iterate = False
            var current_iterate: Bool = self.base.restrict_current(I)
            var power_iterate: Bool = self.base.restrict_power(I)
            if iterate or current_iterate or power_iterate:
                iterate = True
            if count > 10:  # battery_dispatch::constraintCount
                iterate = False
            if (I_initial / I) < 0.0:
                I = 0.0
            if iterate:
                self.base._Battery[].set_state(self.base._Battery_initial[].get_state())
        return iterate

    def cost_to_cycle(self) -> Float64:
        return self.m_cycleCost

    def cost_to_cycle_per_kwh(self) -> Float64:
        return self.cost_to_cycle()

# battery_metrics_t
struct battery_metrics_t:
    var _e_charge_accumulated: Float64
    var _e_discharge_accumulated: Float64
    var _e_charge_from_pv: Float64
    var _e_charge_from_grid: Float64
    var _e_loss_system: Float64
    var _average_efficiency: Float64
    var _average_roundtrip_efficiency: Float64
    var _pv_charge_percent: Float64
    var _e_charge_from_pv_annual: Float64
    var _e_charge_from_grid_annual: Float64
    var _e_loss_system_annual: Float64
    var _e_charge_annual: Float64
    var _e_discharge_annual: Float64
    var _e_grid_import_annual: Float64
    var _e_grid_export_annual: Float64
    var _e_loss_annual: Float64
    var _dt_hour: Float64

    def __init__(inout self, dt_hour: Float64):
        self._dt_hour = dt_hour
        self._e_charge_accumulated = 0.0
        self._e_charge_from_pv = 0.0
        self._e_charge_from_grid = self._e_charge_accumulated
        self._e_discharge_accumulated = 0.0
        self._e_loss_system = 0.0
        self._average_efficiency = 100.0
        self._average_roundtrip_efficiency = 100.0
        self._pv_charge_percent = 0.0
        self._e_charge_from_pv_annual = 0.0
        self._e_charge_from_grid_annual = self._e_charge_from_grid
        self._e_charge_annual = self._e_charge_accumulated
        self._e_discharge_annual = 0.0
        self._e_loss_system_annual = self._e_loss_system
        self._e_grid_import_annual = 0.0
        self._e_grid_export_annual = 0.0
        self._e_loss_annual = 0.0

    def average_battery_conversion_efficiency(self) -> Float64:
        return self._average_efficiency

    def average_battery_roundtrip_efficiency(self) -> Float64:
        return self._average_roundtrip_efficiency

    def pv_charge_percent(self) -> Float64:
        return self._pv_charge_percent

    def energy_pv_charge_annual(self) -> Float64:
        return self._e_charge_from_pv_annual

    def energy_grid_charge_annual(self) -> Float64:
        return self._e_charge_from_grid_annual

    def energy_charge_annual(self) -> Float64:
        return self._e_charge_annual

    def energy_discharge_annual(self) -> Float64:
        return self._e_discharge_annual

    def energy_grid_import_annual(self) -> Float64:
        return self._e_grid_import_annual

    def energy_grid_export_annual(self) -> Float64:
        return self._e_grid_export_annual

    def energy_loss_annual(self) -> Float64:
        return self._e_loss_annual

    def energy_system_loss_annual(self) -> Float64:
        return self._e_loss_system_annual

    def compute_metrics_ac(inout self, batteryPower: Pointer[BatteryPower]):
        self.accumulate_grid_annual(batteryPower[].powerGrid)
        self.accumulate_battery_charge_components(batteryPower[].powerBatteryAC, batteryPower[].powerSystemToBattery, batteryPower[].powerGridToBattery)
        self.accumulate_energy_charge(batteryPower[].powerBatteryAC)
        self.accumulate_energy_discharge(batteryPower[].powerBatteryAC)
        self.accumulate_energy_system_loss(batteryPower[].powerSystemLoss)
        self.compute_annual_loss()

    def compute_annual_loss(inout self):
        var e_conversion_loss: Float64 = 0.0
        if self._e_charge_annual > self._e_discharge_annual:
            e_conversion_loss = self._e_charge_annual - self._e_discharge_annual
        self._e_loss_annual = e_conversion_loss + self._e_loss_system_annual

    def accumulate_energy_charge(inout self, P_tofrom_batt: Float64):
        if P_tofrom_batt < 0.0:
            self._e_charge_accumulated += (-P_tofrom_batt) * self._dt_hour
            self._e_charge_annual += (-P_tofrom_batt) * self._dt_hour

    def accumulate_energy_discharge(inout self, P_tofrom_batt: Float64):
        if P_tofrom_batt > 0.0:
            self._e_discharge_accumulated += P_tofrom_batt * self._dt_hour
            self._e_discharge_annual += P_tofrom_batt * self._dt_hour

    def accumulate_energy_system_loss(inout self, P_system_loss: Float64):
        self._e_loss_system += P_system_loss * self._dt_hour
        self._e_loss_system_annual += P_system_loss * self._dt_hour

    def accumulate_battery_charge_components(inout self, P_tofrom_batt: Float64, P_pv_to_batt: Float64, P_grid_to_batt: Float64):
        if P_tofrom_batt < 0.0:
            self._e_charge_from_pv += P_pv_to_batt * self._dt_hour
            self._e_charge_from_pv_annual += P_pv_to_batt * self._dt_hour
            self._e_charge_from_grid += P_grid_to_batt * self._dt_hour
            self._e_charge_from_grid_annual += P_grid_to_batt * self._dt_hour
        self._average_efficiency = 100.0 * (self._e_discharge_accumulated / self._e_charge_accumulated)
        self._average_roundtrip_efficiency = 100.0 * (self._e_discharge_accumulated / (self._e_charge_accumulated + self._e_loss_system))
        self._pv_charge_percent = 100.0 * (self._e_charge_from_pv / self._e_charge_accumulated)

    def accumulate_grid_annual(inout self, P_tofrom_grid: Float64):
        if P_tofrom_grid > 0.0:
            self._e_grid_export_annual += P_tofrom_grid * self._dt_hour
        else:
            self._e_grid_import_annual += (-P_tofrom_grid) * self._dt_hour

    def new_year(inout self):
        self._e_charge_from_pv_annual = 0.0
        self._e_charge_from_grid_annual = 0.0
        self._e_charge_annual = 0.0
        self._e_discharge_annual = 0.0
        self._e_grid_import_annual = 0.0
        self._e_grid_export_annual = 0.0
        self._e_loss_system_annual = 0.0