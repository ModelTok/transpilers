"""
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
"""
# header: lib_battery_dispatch_automatic_btm.h

from lib_battery_dispatch import dispatch_automatic_t, dispatch_t, grid_point, byGrid, byCost, byLowestMarginalCost
from lib_utility_rate import rate_data, UtilityRateForecast
from lib_battery_powerflow import battery_t, m_batteryPower
from lib_shared_inverter import AC_CONNECTED, DC_CONNECTED  # assume defined
from util import lifetimeIndex, hour_of_day, month_of, hours_in_month, kilowatt_to_watt, watt_to_kilowatt
from os import File, open, fprintf  # for file I/O

struct dispatch_plan:
    var plannedDispatch: List[Float64]
    var plannedGridUse: List[Float64]
    var cost: Float64
    var dispatch_hours: Int
    var num_cycles: Int
    var kWhRemaining: Float64
    var lowestMarginalCost: Float64

    def __init__(inout self):
        self.plannedDispatch = List[Float64]()
        self.plannedGridUse = List[Float64]()
        self.cost = 0.0
        self.dispatch_hours = 0
        self.num_cycles = 0
        self.kWhRemaining = 0.0
        self.lowestMarginalCost = 0.0

struct dispatch_automatic_behind_the_meter_t(dispatch_automatic_t):
    # enum BTM_TARGET_MODES
    enum BTM_TARGET_MODES:
        TARGET_SINGLE_MONTHLY = 0
        TARGET_TIME_SERIES = 1

    var _P_load_ac: List[Float64]
    var _P_target_input: List[Float64]
    var _P_target_use: List[Float64]
    var _P_target_month: Float64
    var _P_target_current: Float64
    var grid: List[grid_point]
    var sorted_grid: List[grid_point]
    var rate: Optional[Pointer[rate_data]]
    var rate_forecast: Optional[Pointer[UtilityRateForecast]]

    def __init__(
        inout self,
        Battery: Pointer[battery_t],
        dt_hour: Float64,
        SOC_min: Float64,
        SOC_max: Float64,
        current_choice: Int,
        Ic_max: Float64,
        Id_max: Float64,
        Pc_max_kwdc: Float64,
        Pd_max_kwdc: Float64,
        Pc_max_kwac: Float64,
        Pd_max_kwac: Float64,
        t_min: Float64,
        dispatch_mode: Int,
        pv_dispatch: Int,
        nyears: Int,
        look_ahead_hours: Int,
        dispatch_update_frequency_hours: Float64,
        can_charge: Bool,
        can_clip_charge: Bool,
        can_grid_charge: Bool,
        can_fuelcell_charge: Bool,
        util_rate: Optional[Pointer[rate_data]],
        battReplacementCostPerkWh: List[Float64],
        battCycleCostChoice: Int,
        battCycleCost: List[Float64]
    ):
        # call base constructor
        dispatch_automatic_t.__init__(
            self, Battery, dt_hour, SOC_min, SOC_max, current_choice, Ic_max, Id_max,
            Pc_max_kwdc, Pd_max_kwdc, Pc_max_kwac, Pd_max_kwac, t_min, dispatch_mode,
            pv_dispatch, nyears, look_ahead_hours, dispatch_update_frequency_hours,
            can_charge, can_clip_charge, can_grid_charge, can_fuelcell_charge,
            battReplacementCostPerkWh, battCycleCostChoice, battCycleCost
        )
        self._P_target_month = -1e16
        self._P_target_current = -1e16
        self._P_target_use.reserve(self._num_steps)
        self._P_battery_use.reserve(self._num_steps)
        self.grid.reserve(self._num_steps)
        self.sorted_grid.reserve(self._num_steps)
        for ii in range(self._num_steps):
            self.grid.push_back(grid_point(0.0, 0, 0))
            self.sorted_grid.push_back(self.grid[ii])
        if util_rate:
            self.rate = Pointer[rate_data](rate_data(*util_rate.value))
        self.costToCycle()

    def init_with_pointer(inout self, tmp: Pointer[dispatch_automatic_behind_the_meter_t]):
        self._P_target_input = tmp.value._P_target_input
        self._P_target_month = tmp.value._P_target_month
        self._P_target_current = tmp.value._P_target_current
        self.grid = tmp.value.grid
        self._P_load_ac = tmp.value._P_load_ac
        self._P_target_use = tmp.value._P_target_use
        self.sorted_grid = tmp.value.sorted_grid
        if tmp.value.rate:
            self.rate = Pointer[rate_data](rate_data(*tmp.value.rate.value))
            self.rate_forecast = Pointer[UtilityRateForecast](UtilityRateForecast(*tmp.value.rate_forecast.value))

    def __copyinit__(inout self, other: Self):
        # called for copy construction
        # In Mojo we need to implement copy semantics if needed; this is simplified
        self.init_with_pointer(Pointer[dispatch_automatic_behind_the_meter_t](other))

    def copy(inout self, dispatch: Pointer[dispatch_t]):
        dispatch_automatic_t.copy(self, dispatch)
        var tmp = dispatch.value.as_ptr_dispatch_automatic_behind_the_meter_t()
        self.init_with_pointer(tmp)

    def dispatch(inout self, year: Int, hour_of_year: Int, step: Int):
        self.curr_year = year
        var step_per_hour = Int(1.0 / self._dt_hour)
        var lifetimeIndex = lifetimeIndex(year, hour_of_year, step, step_per_hour)
        self.update_dispatch(year, hour_of_year, step, lifetimeIndex)
        dispatch_automatic_t.dispatch(self, year, hour_of_year, step)
        if self.rate_forecast:
            var actual_dispatch = List[Float64]([self.m_batteryPower.value.powerGrid])
            self.rate_forecast.value.forecastCost(actual_dispatch, year, hour_of_year, step)

    def update_load_data(inout self, P_load_ac: List[Float64]):
        self._P_load_ac = P_load_ac

    def set_target_power(inout self, P_target: List[Float64]):
        self._P_target_input = P_target

    def power_grid_target(self) -> Float64:
        return self._P_target_current

    def setup_rate_forecast(inout self):
        if self._mode == dispatch_t.FORECAST:
            var monthly_gross_load = List[Float64]()
            var monthly_gen = List[Float64]()
            var monthly_net_load = List[Float64]()
            var num_recs = util.hours_per_year * self._steps_per_hour * self._nyears
            var step = 0
            var hour_of_year = 0
            var curr_month = 1
            var load_during_month = 0.0
            var gen_during_month = 0.0
            var gross_load_during_month = 0.0
            var array_size = min(self._P_pv_ac.size(), self._P_load_ac.size())
            for idx in range(min(num_recs, array_size)):
                var grid_power = self._P_pv_ac[idx] - self._P_load_ac[idx]
                gross_load_during_month += self._P_load_ac[idx] * self._dt_hour
                if grid_power < 0:
                    load_during_month += grid_power * self._dt_hour
                else:
                    gen_during_month += grid_power * self._dt_hour
                step += 1
                if step == self._steps_per_hour:
                    step = 0
                    hour_of_year += 1
                    if hour_of_year >= 8760:
                        hour_of_year = 0
                if (month_of(Float64(hour_of_year)) != curr_month) or (idx == array_size - 1):
                    monthly_gross_load.push_back(gross_load_during_month / hours_in_month(curr_month))
                    monthly_net_load.push_back(-1.0 * load_during_month)
                    monthly_gen.push_back(gen_during_month)
                    gross_load_during_month = 0.0
                    load_during_month = 0.0
                    gen_during_month = 0.0
                    if curr_month < 12:
                        curr_month += 1
                    else:
                        curr_month = 1
            self.rate_forecast = Pointer[UtilityRateForecast](
                UtilityRateForecast(self.rate.value, self._steps_per_hour, monthly_net_load, monthly_gen, monthly_gross_load, self._nyears)
            )
            self.rate_forecast.value.initializeMonth(0, 0)
            self.rate_forecast.value.copyTOUForecast()

    def update_dispatch(inout self, year: Int, hour_of_year: Int, step: Int, idx: Int):
        var debug = False
        var p: Pointer[File] = Pointer[File]()
        self.check_debug(hour_of_year, idx, p, debug)
        var hour_of_day = hour_of_day(hour_of_year)
        self._day_index = (hour_of_day * self._steps_per_hour) + step
        var E_max = 0.0
        if self._mode == dispatch_t.FORECAST:
            if hour_of_year != self._hour_last_updated:
                self.costToCycle()
                var new_month = self.check_new_month(hour_of_year, step)
                if new_month:
                    self.rate_forecast.value.copyTOUForecast()
                self.initialize(hour_of_year, idx)
                var no_dispatch_cost = self.compute_costs(idx, year, hour_of_year, p, debug)
                self.compute_energy(E_max, p, debug)
                self.cost_based_target_power(idx, year, hour_of_year, no_dispatch_cost, E_max, p, debug)
                self.set_battery_power(idx, p, debug)
            self.m_batteryPower.value.powerBatteryTarget = self._P_battery_use[step]
        elif self._mode != dispatch_t.CUSTOM_DISPATCH:
            if (hour_of_day == 0) and (hour_of_year != self._hour_last_updated):
                self.check_new_month(hour_of_year, step)
                self.initialize(hour_of_year, idx)
                self.sort_grid(idx, p, debug)
                self.compute_energy(E_max, p, debug)
                self.target_power(E_max, idx, p, debug)
                self.set_battery_power(idx, p, debug)
            self._P_target_current = self._P_target_use[self._day_index]
            self.m_batteryPower.value.powerBatteryTarget = self._P_battery_use[self._day_index]
        else:
            self.m_batteryPower.value.powerBatteryTarget = self._P_battery_use[idx % (8760 * self._steps_per_hour)]
            var loss_kw = self._Battery.value.calculate_loss(self.m_batteryPower.value.powerBatteryTarget, idx)
            if self.m_batteryPower.value.connectionMode == AC_CONNECTED:
                self.m_batteryPower.value.powerBatteryTarget = self.m_batteryPower.value.adjustForACEfficiencies(self.m_batteryPower.value.powerBatteryTarget, loss_kw)
            elif self.m_batteryPower.value.powerBatteryTarget > 0:
                self.m_batteryPower.value.powerBatteryTarget += loss_kw
        self.m_batteryPower.value.powerBatteryDC = self.m_batteryPower.value.powerBatteryTarget
        if debug:
            p.value.close()

    def initialize(inout self, hour_of_year: Int, lifetimeIndex: Int):
        self._hour_last_updated = hour_of_year
        self._P_target_use.clear()
        self._P_battery_use.clear()
        self.m_batteryPower.value.powerBatteryDC = 0
        self.m_batteryPower.value.powerBatteryAC = 0
        self.m_batteryPower.value.powerBatteryTarget = 0
        var lifetimeMax = self._P_pv_ac.size()
        for ii in range(self._num_steps):
            if lifetimeIndex >= lifetimeMax:
                break
            self.grid[ii] = grid_point(0.0, 0, 0, 0.0, 0.0)
            self.sorted_grid[ii] = self.grid[ii]
            self._P_target_use.push_back(0.0)
            self._P_battery_use.push_back(0.0)
            lifetimeIndex += 1

    def check_new_month(inout self, hour_of_year: Int, step: Int) -> Bool:
        var ret_value = False
        var hours = 0
        for month in range(1, self._month + 1):
            hours += hours_in_month(month)
        if hours == 8760:
            hours = 0
        if (hour_of_year == hours) and (step == 0):
            self._P_target_month = -1e16
            if self._month < 12:
                self._month += 1
            else:
                self._month = 1
            ret_value = True
        return ret_value

    def check_debug(inout self, hour_of_year: Int, locus: Int, inout p: Pointer[File], inout debug: Bool):
        if (hour_of_year == 0) and (hour_of_year != self._hour_last_updated):
            if debug:
                p = open("dispatch.txt", "w")
                fprintf(p.value, "Hour of Year: %zu\t Hour Last Updated: %zu \t Steps per Hour: %zu\n", hour_of_year, self._hour_last_updated, self._steps_per_hour)
            if not p:
                debug = False

    def sort_grid(inout self, idx: Int, p: Pointer[File] = Pointer[File](), debug: Bool = False):
        if debug:
            fprintf(p.value, "Index\t P_load (kW)\t P_pv (kW)\t P_grid (kW)\n")
        var count = 0
        for hour in range(24):
            for step in range(self._steps_per_hour):
                self.grid[count] = grid_point(self._P_load_ac[idx] - self._P_pv_ac[idx], hour, step)
                self.sorted_grid[count] = self.grid[count]
                if debug:
                    fprintf(p.value, "%zu\t %.1f\t %.1f\t %.1f\n", count, self._P_load_ac[idx], self._P_pv_ac[idx], self._P_load_ac[idx] - self._P_pv_ac[idx])
                idx += 1
                count += 1
        self.sorted_grid.sort(key=byGrid())

    def compute_energy(inout self, inout E_max: Float64, p: Pointer[File] = Pointer[File](), debug: Bool = False):
        E_max = self._Battery.value.energy_max(self.m_batteryPower.value.stateOfChargeMax, self.m_batteryPower.value.stateOfChargeMin)
        if debug:
            fprintf(p.value, "Energy Max: %.3f\t", E_max)
            fprintf(p.value, "Battery Voltage: %.3f\n", self._Battery.value.V())

    def compute_available_energy(inout self, p: Pointer[File] = Pointer[File](), debug: Bool = False) -> Float64:
        var E_available = self._Battery.value.energy_available(self.m_batteryPower.value.stateOfChargeMin)
        if debug:
            fprintf(p.value, "Energy Available: %.3f\t", E_available)
            fprintf(p.value, "Battery Voltage: %.3f\n", self._Battery.value.V())
        return E_available

    def compute_costs(inout self, idx: Int, year: Int, hour_of_year: Int, p: Pointer[File] = Pointer[File](), debug: Bool = False) -> Float64:
        if debug:
            fprintf(p.value, "Index\t P_load (kW)\t P_pv (kW)\t P_grid (kW)\n")
        var noDispatchForecast = UtilityRateForecast(*self.rate_forecast.value)
        var marginalForecast = UtilityRateForecast(*self.rate_forecast.value)
        var no_dispatch_cost = 0.0
        var count = 0
        for hour in range(24):
            for step in range(self._steps_per_hour):
                if idx >= self._P_load_ac.size():
                    break
                var power = self._P_load_ac[idx] - self._P_pv_ac[idx]
                var forecast_power = List[Float64]([-power])
                var step_cost = noDispatchForecast.forecastCost(forecast_power, year, (hour_of_year + hour) % 8760, step)
                no_dispatch_cost += step_cost
                var marginal_power = List[Float64]([-1.0])
                var marginal_cost = marginalForecast.forecastCost(marginal_power, year, (hour_of_year + hour) % 8760, step)
                self.grid[count] = grid_point(power, hour, step, step_cost, marginal_cost)
                self.sorted_grid[count] = self.grid[count]
                if debug:
                    fprintf(p.value, "%zu\t %.1f\t %.1f\t %.1f\n", count, self._P_load_ac[idx], self._P_pv_ac[idx], power)
                idx += 1
                count += 1
        self.sorted_grid.sort(key=byCost())
        return no_dispatch_cost

    def target_power(inout self, E_useful: Float64, idx: Int, p: Pointer[File] = Pointer[File](), debug: Bool = False):
        if (idx < self._P_target_input.size()) and (self._P_target_input[idx] >= 0):
            var first = self._P_target_input.begin() + idx
            var last = self._P_target_input.begin() + idx + self._num_steps
            var tmp = List[Float64]()
            for i in range(first, last):
                tmp.push_back(i)
            self._P_target_use = tmp
        elif self.sorted_grid[0].Grid() < self._P_target_month:
            for i in range(self._num_steps):
                self._P_target_use[i] = self._P_target_month
        else:
            if debug:
                fprintf(p.value, "Index\tRecharge_target\t charge_energy\n")
            var P_target = self.sorted_grid[0].Grid()
            var P_target_min = 1e16
            var E_charge = 0.0
            var index = self._num_steps - 1
            var E_charge_vec = List[Float64]()
            for jj in range(self._num_steps - 1, -1, -1):
                E_charge = 0.0
                P_target_min = self.sorted_grid[index].Grid()
                for ii in range(self._num_steps - 1, -1, -1):
                    if self.sorted_grid[ii].Grid() > P_target_min:
                        break
                    E_charge += (P_target_min - self.sorted_grid[ii].Grid()) * self._dt_hour
                E_charge_vec.push_back(E_charge)
                if debug:
                    fprintf(p.value, "%u: index\t%.3f\t %.3f\n", index, P_target_min, E_charge)
                index -= 1
                if index < 0:
                    break
            reverse(E_charge_vec)
            var sorted_grid_diff = List[Float64]()
            sorted_grid_diff.reserve(self._num_steps - 1)
            for ii in range(self._num_steps - 1):
                sorted_grid_diff.push_back(self.sorted_grid[ii].Grid() - self.sorted_grid[ii + 1].Grid())
            P_target = self.sorted_grid[0].Grid()
            var sum = 0.0
            if debug:
                fprintf(p.value, "Step\tTarget_Power\tEnergy_Sum\tEnergy_charged\n")
            for ii in range(self._num_steps - 1):
                if self.sorted_grid[ii + 1].Grid() < 0:
                    break
                else:
                    P_target = self.sorted_grid[ii + 1].Grid()
                if debug:
                    fprintf(p.value, "%zu\t %.3f\t", ii, P_target)
                if sorted_grid_diff[ii] == 0:
                    if debug:
                        fprintf(p.value, "\n")
                    continue
                else:
                    sum += sorted_grid_diff[ii] * (ii + 1) * self._dt_hour
                if debug:
                    fprintf(p.value, "%.3f\t%.3f\n", sum, E_charge_vec[ii + 1])
                if sum < E_charge_vec[ii + 1] and sum < E_useful:
                    continue
                elif sum > E_charge_vec[ii + 1]:
                    P_target += (sum - E_charge_vec[ii]) / ((ii + 1) * self._dt_hour)
                    sum = E_charge_vec[ii]
                    if debug:
                        fprintf(p.value, "%zu\t %.3f\t%.3f\t%.3f\n", ii, P_target, sum, E_charge_vec[ii])
                    break
                elif sum > E_useful:
                    P_target += (sum - E_useful) / ((ii + 1) * self._dt_hour)
                    sum = E_useful
                    if debug:
                        fprintf(p.value, "%zu\t %.3f\t%.3f\t%.3f\n", ii, P_target, sum, E_charge_vec[ii])
                    break
            P_target *= (1.0 + self._safety_factor)
            if P_target < self._P_target_month:
                P_target = self._P_target_month
                if debug:
                    fprintf(p.value, "P_target exceeds monthly target, move to  %.3f\n", P_target)
            else:
                self._P_target_month = P_target
            for i in range(self._num_steps):
                self._P_target_use[i] = P_target
        for i in range(self._P_battery_use.size()):
            self._P_battery_use[i] = self.grid[i].Grid() - self._P_target_use[i]

    def cost_based_target_power(inout self, idx: Int, year: Int, hour_of_year: Int, no_dispatch_cost: Float64, E_max: Float64, p: Pointer[File] = Pointer[File](), debug: Bool = False):
        var startingEnergy = self.compute_available_energy(p, debug)
        var plans = List[dispatch_plan]()
        plans.reserve(self._num_steps // self._steps_per_hour // 2)
        for i in range(self._num_steps // self._steps_per_hour // 2):
            plans.push_back(dispatch_plan())
        plans[0].dispatch_hours = 0
        plans[0].plannedDispatch.resize(self._num_steps)
        plans[0].cost = no_dispatch_cost
        var lowest_cost = no_dispatch_cost
        var lowest_index = 0
        for i in range(1, plans.size()):
            plans[i].dispatch_hours = i
            plans[i].plannedDispatch.resize(self._num_steps)
            plans[i].plannedGridUse.clear()
            plans[i].plannedDispatch = List[Float64]([0.0] * plans[i].plannedDispatch.size())
            plans[i].num_cycles = 0
            self.plan_dispatch_for_cost(plans[i], idx, E_max, startingEnergy)
            var midDispatchForecast = UtilityRateForecast(*self.rate_forecast.value)
            plans[i].cost = midDispatchForecast.forecastCost(plans[i].plannedGridUse, year, hour_of_year, 0) + self.cost_to_cycle() * plans[i].num_cycles - plans[i].kWhRemaining * plans[i].lowestMarginalCost
            if plans[i].cost < lowest_cost:
                lowest_index = i
                lowest_cost = plans[i].cost
        self._P_battery_use = plans[lowest_index].plannedDispatch

    def plan_dispatch_for_cost(inout self, inout plan: dispatch_plan, idx: Int, E_max: Float64, startingEnergy: Float64):
        var i = 0
        var index = 0
        self.sorted_grid.sort(key=byCost())
        var costDuringDispatchHours = 0.0
        var costAtStep = 0.0
        for i in range(min(plan.dispatch_hours * self._steps_per_hour, self.sorted_grid.size())):
            costAtStep = self.sorted_grid[i].Cost()
            if costAtStep > 1e-7:
                costDuringDispatchHours += self.sorted_grid[i].Cost()
        var remainingEnergy = E_max
        var powerAtMaxCost = 0.0
        plan.lowestMarginalCost = self.sorted_grid[0].MarginalCost()
        for i in range(min(plan.dispatch_hours * self._steps_per_hour, self.sorted_grid.size())):
            costAtStep = self.sorted_grid[i].Cost()
            if costAtStep > 1e-7:
                var costPercent = costAtStep / costDuringDispatchHours
                var desiredPower = remainingEnergy * costPercent / self._dt_hour
                if desiredPower < powerAtMaxCost and self.sorted_grid[i].Grid() >= powerAtMaxCost:
                    desiredPower = powerAtMaxCost
                if desiredPower > self.sorted_grid[i].Grid():
                    desiredPower = self.sorted_grid[i].Grid()
                self.check_power_restrictions(desiredPower)
                remainingEnergy -= desiredPower * self._dt_hour
                costDuringDispatchHours -= costAtStep
                index = self.sorted_grid[i].Hour() * self._steps_per_hour + self.sorted_grid[i].Step()
                plan.plannedDispatch[index] = desiredPower
                if powerAtMaxCost == 0:
                    powerAtMaxCost = desiredPower
        for i in range(min(self._steps_per_hour, self.sorted_grid.size())):
            if self.sorted_grid[i].Cost() > 0:
                if self.sorted_grid[i].MarginalCost() < plan.lowestMarginalCost:
                    plan.lowestMarginalCost = self.sorted_grid[i].MarginalCost()
            else:
                break
        var chargeEnergy = E_max - remainingEnergy
        chargeEnergy = max(chargeEnergy, E_max / 2.0)
        var requiredEnergy = chargeEnergy / (self.m_batteryPower.value.singlePointEfficiencyACToDC * self.m_batteryPower.value.singlePointEfficiencyDCToAC)
        if (self._P_cliploss_dc.size() > 0) and self.m_batteryPower.value.canClipCharge:
            var idx_clip = idx
            for i in range(self._num_steps):
                if idx_clip >= self._P_cliploss_dc.size():
                    break
                var clippedPower = self._P_cliploss_dc[idx_clip]
                if clippedPower > 0:
                    clippedPower *= -1.0
                    self.check_power_restrictions(clippedPower)
                    plan.plannedDispatch[i] = clippedPower
                    requiredEnergy += clippedPower
                idx_clip += 1
        self.sorted_grid.sort(key=byGrid())
        var lookingForGridUse = True
        var peakDesiredGridUse = 0.0
        i = self._num_steps // 4
        while lookingForGridUse and i < self._num_steps:
            index = self.sorted_grid[i].Hour() * self._steps_per_hour + self.sorted_grid[i].Step()
            if plan.plannedDispatch[index] < 0:
                i += 1
            else:
                peakDesiredGridUse = self.sorted_grid[i].Grid() if self.sorted_grid[i].Grid() > 0 else 0.0
                lookingForGridUse = False
            if lookingForGridUse and self.sorted_grid[i].Grid() <= 0:
                lookingForGridUse = False
        self.sorted_grid.sort(key=byLowestMarginalCost())
        i = 0
        while requiredEnergy > 0 and i < self._num_steps:
            index = self.sorted_grid[i].Hour() * self._steps_per_hour + self.sorted_grid[i].Step()
            if plan.plannedDispatch[index] <= 0.0:
                var requiredPower = 0.0
                if self.m_batteryPower.value.canGridCharge:
                    if (idx + index < self._P_pv_ac.size()) and (self._P_pv_ac[idx + index] > 0):
                        requiredPower = -self._P_pv_ac[idx + index]
                    else:
                        requiredPower = -requiredEnergy / self._dt_hour
                elif self.m_batteryPower.value.canSystemCharge:
                    if self.m_batteryPower.value.connectionMode == AC_CONNECTED:
                        if self.sorted_grid[i].Grid() < 0:
                            requiredPower = self.sorted_grid[i].Grid()
                    else:
                        if (idx + index < self._P_pv_ac.size()) and (self._P_pv_ac[idx + index] > 0):
                            requiredPower = -self._P_pv_ac[idx + index]
                if requiredPower < 0:
                    self.check_power_restrictions(requiredPower)
                    var projectedGrid = self.sorted_grid[i].Grid() - requiredPower
                    if projectedGrid > peakDesiredGridUse:
                        requiredPower = -(peakDesiredGridUse - self.sorted_grid[i].Grid())
                        requiredPower = requiredPower if requiredPower < 0.0 else 0.0
                    requiredPower += plan.plannedDispatch[index]
                    self.check_power_restrictions(requiredPower)
                    requiredEnergy += (requiredPower - plan.plannedDispatch[index]) * self._dt_hour
                plan.plannedDispatch[index] = requiredPower
            i += 1
        var energy = startingEnergy
        var cycleState = 0
        var halfCycle = False
        for i in range(plan.plannedDispatch.size()):
            var projectedEnergy = energy - plan.plannedDispatch[i] * self._dt_hour
            if projectedEnergy < 0:
                plan.plannedDispatch[i] = energy / self._dt_hour
            elif projectedEnergy > E_max:
                plan.plannedDispatch[i] = (energy - E_max) / self._dt_hour
            energy -= plan.plannedDispatch[i] * self._dt_hour
            if abs(plan.plannedDispatch[i] - 0) < 1e-7:
                plan.plannedDispatch[i] = 0
            if plan.plannedDispatch[i] < 0:
                if cycleState != -1:
                    if halfCycle:
                        plan.num_cycles += 1
                        halfCycle = False
                    else:
                        halfCycle = True
                cycleState = -1
            if plan.plannedDispatch[i] > 0:
                if cycleState != 1:
                    if halfCycle:
                        plan.num_cycles += 1
                        halfCycle = False
                    else:
                        halfCycle = True
                cycleState = 1
            var projectedGrid = -self.grid[i].Grid() + plan.plannedDispatch[i]
            if (i + idx < self._P_cliploss_dc.size()) and (plan.plannedDispatch[i] <= 0):
                var clipLoss = -self._P_cliploss_dc[i + idx]
                if plan.plannedDispatch[i] <= clipLoss:
                    projectedGrid -= clipLoss
                else:
                    projectedGrid -= plan.plannedDispatch[i]
            plan.plannedGridUse.push_back(projectedGrid)
        plan.kWhRemaining = energy

    def check_power_restrictions(inout self, inout power: Float64):
        var desiredCurrent = power * kilowatt_to_watt / self._Battery.value.V()
        self.restrict_current(desiredCurrent)
        self.restrict_power(desiredCurrent)
        power = desiredCurrent * self._Battery.value.V() * watt_to_kilowatt

    def set_battery_power(inout self, idx: Int, p: Pointer[File] = Pointer[File](), debug: Bool = False):
        for i in range(self._P_target_use.size()):
            var loss_kw = self._Battery.value.calculate_loss(self._P_battery_use[i], idx + i)
            if self.m_batteryPower.value.connectionMode == AC_CONNECTED:
                self._P_battery_use[i] = self.m_batteryPower.value.adjustForACEfficiencies(self._P_battery_use[i], loss_kw)
            else:
                self._P_battery_use[i] = self.m_batteryPower.value.adjustForDCEfficiencies(self._P_battery_use[i], loss_kw)
        if debug:
            for i in range(self._P_target_use.size()):
                fprintf(p.value, "i=%zu  P_battery: %.2f\n", i, self._P_battery_use[i])

    def costToCycle(inout self):
        if self.m_battCycleCostChoice == dispatch_t.MODEL_CYCLE_COST:
            if self.curr_year < self.m_battReplacementCostPerKWH.size():
                var capacityPercentDamagePerCycle = self._Battery.value.estimateCycleDamage()
                self.m_cycleCost = 0.01 * capacityPercentDamagePerCycle * self.m_battReplacementCostPerKWH[self.curr_year] * self._Battery.value.get_params().nominal_energy
            else:
                self.m_cycleCost = 0.0
        elif self.m_battCycleCostChoice == dispatch_t.INPUT_CYCLE_COST:
            self.m_cycleCost = self.cycle_costs_by_year[self.curr_year] * self._Battery.value.get_params().nominal_energy

    def cost_to_cycle_per_kwh(self) -> Float64:
        return self.m_cycleCost / self._Battery.value.get_params().nominal_energy