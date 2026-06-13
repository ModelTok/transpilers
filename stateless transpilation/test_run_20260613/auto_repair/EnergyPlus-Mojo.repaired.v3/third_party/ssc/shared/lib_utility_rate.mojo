from lib_util import matrix_t, month_hour, weekday, month_of, lifetimeIndex, yearOneIndex
from "lib_utility_rate_equations import rate_data, ur_month, ssc_number_t
from math import floor

struct UtilityRate:
    var m_useRealTimePrices: Bool
    var m_ecWeekday: matrix_t[Int]
    var m_ecWeekend: matrix_t[Int]
    var m_ecRatesMatrix: matrix_t[Float64]
    var m_energyTiersPerPeriod: Dict[Int, Int]
    var m_ecRealTimeBuy: List[Float64]

    def __init__(inout self, useRealTimePrices: Bool, ecWeekday: matrix_t[Int], ecWeekend: matrix_t[Int], ecRatesMatrix: matrix_t[Float64], ecRealTimeBuy: List[Float64]):
        self.m_useRealTimePrices = useRealTimePrices
        self.m_ecWeekday = ecWeekday
        self.m_ecWeekend = ecWeekend
        self.m_ecRatesMatrix = ecRatesMatrix
        self.m_ecRealTimeBuy = ecRealTimeBuy

    def __copy__(inout self, other: Self):
        self.m_useRealTimePrices = other.m_useRealTimePrices
        self.m_ecWeekday = other.m_ecWeekday
        self.m_ecWeekend = other.m_ecWeekend
        self.m_ecRatesMatrix = other.m_ecRatesMatrix
        for kv in other.m_energyTiersPerPeriod.items():
            self.m_energyTiersPerPeriod[kv[0]] = kv[1]
        self.m_ecRealTimeBuy = other.m_ecRealTimeBuy

struct UtilityRateCalculator(UtilityRate):
    var m_loadProfile: List[Float64]
    var m_electricBill: Float64
    var m_stepsPerHour: Int
    var m_energyUsagePerPeriod: List[Float64]

    def __init__(inout self, rate: Pointer[UtilityRate], stepsPerHour: Int):
        # copy base
        self.m_useRealTimePrices = rate[].m_useRealTimePrices
        self.m_ecWeekday = rate[].m_ecWeekday
        self.m_ecWeekend = rate[].m_ecWeekend
        self.m_ecRatesMatrix = rate[].m_ecRatesMatrix
        for kv in rate[].m_energyTiersPerPeriod.items():
            self.m_energyTiersPerPeriod[kv[0]] = kv[1]
        self.m_ecRealTimeBuy = rate[].m_ecRealTimeBuy
        self.m_stepsPerHour = stepsPerHour
        self.initializeRate()

    def __init__(inout self, rate: Pointer[UtilityRate], stepsPerHour: Int, loadProfile: List[Float64]):
        # copy base
        self.m_useRealTimePrices = rate[].m_useRealTimePrices
        self.m_ecWeekday = rate[].m_ecWeekday
        self.m_ecWeekend = rate[].m_ecWeekend
        self.m_ecRatesMatrix = rate[].m_ecRatesMatrix
        for kv in rate[].m_energyTiersPerPeriod.items():
            self.m_energyTiersPerPeriod[kv[0]] = kv[1]
        self.m_ecRealTimeBuy = rate[].m_ecRealTimeBuy
        self.m_stepsPerHour = stepsPerHour
        self.m_loadProfile = loadProfile
        self.initializeRate()

    def __copy__(inout self, other: Self):
        # copy base
        self.m_useRealTimePrices = other.m_useRealTimePrices
        self.m_ecWeekday = other.m_ecWeekday
        self.m_ecWeekend = other.m_ecWeekend
        self.m_ecRatesMatrix = other.m_ecRatesMatrix
        for kv in other.m_energyTiersPerPeriod.items():
            self.m_energyTiersPerPeriod[kv[0]] = kv[1]
        self.m_ecRealTimeBuy = other.m_ecRealTimeBuy
        self.m_electricBill = other.m_electricBill
        self.m_stepsPerHour = other.m_stepsPerHour
        for i in other.m_loadProfile:
            self.m_loadProfile.append(i)
        for i in other.m_energyUsagePerPeriod:
            self.m_energyUsagePerPeriod.append(i)

    def initializeRate(inout self):
        if not self.m_useRealTimePrices:
            for r in range(self.m_ecRatesMatrix.nrows()):
                period = Int(self.m_ecRatesMatrix[r][0])
                tier = Int(self.m_ecRatesMatrix[r][1])
                self.m_energyTiersPerPeriod[period] = tier
                if tier == 1:
                    self.m_energyUsagePerPeriod.append(0.0)

    def updateLoad(inout self, loadPower: Float64):
        self.m_loadProfile.append(loadPower)

    def calculateEnergyUsagePerPeriod(inout self):
        for idx in range(self.m_loadProfile.size()):
            hourOfYear = Int(floor(Float64(idx) / Float64(self.m_stepsPerHour)))
            period = Int(self.getEnergyPeriod(hourOfYear))
            self.m_energyUsagePerPeriod[period] += self.m_loadProfile[idx]

    def getEnergyRate(self, hourOfYear: Int) -> Float64:
        var rate: Float64 = 0.0
        if self.m_useRealTimePrices:
            rate = self.m_ecRealTimeBuy[hourOfYear]
        else:
            period = self.getEnergyPeriod(hourOfYear)
            rate = self.m_ecRatesMatrix[period - 1][4]
        return rate

    def getEnergyPeriod(self, hourOfYear: Int) -> Int:
        var period: Int
        var month: Int
        var hour: Int
        month_hour(hourOfYear, month, hour)
        if weekday(hourOfYear):
            if self.m_ecWeekday.nrows() == 1 and self.m_ecWeekday.ncols() == 1:
                period = Int(self.m_ecWeekday[0][0])
            else:
                period = Int(self.m_ecWeekday[month - 1][hour - 1])
        else:
            if self.m_ecWeekend.nrows() == 1 and self.m_ecWeekend.ncols() == 1:
                period = Int(self.m_ecWeekend[0][0])
            else:
                period = Int(self.m_ecWeekend[month - 1][hour - 1])
        return period

struct UtilityRateForecast:
    var rate: Pointer[rate_data]
    var steps_per_hour: Int
    var dt_hour: Float64
    var last_step: Int
    var last_month_init: Int
    var nyears: Int
    var m_monthly_load_forecast: List[Float64]
    var m_monthly_gen_forecast: List[Float64]
    var m_monthly_avg_load_forecast: List[Float64]
    var current_composite_sell_rates: List[Float64]
    var current_composite_buy_rates: List[Float64]
    var next_composite_sell_rates: List[Float64]
    var next_composite_buy_rates: List[Float64]

    def __init__(inout self, util_rate: Pointer[rate_data], stepsPerHour: Int, monthly_load_forecast: List[Float64], monthly_gen_forecast: List[Float64], monthly_avg_load_forecast: List[Float64], analysis_period: Int):
        self.steps_per_hour = stepsPerHour
        self.dt_hour = 1.0 / Float64(stepsPerHour)
        self.last_step = 0
        self.last_month_init = -1
        self.rate = new rate_data(util_rate[])
        self.m_monthly_load_forecast = monthly_load_forecast
        self.m_monthly_gen_forecast = monthly_gen_forecast
        self.m_monthly_avg_load_forecast = monthly_avg_load_forecast
        self.nyears = analysis_period
        self.current_composite_buy_rates = List[Float64]()
        self.current_composite_sell_rates = List[Float64]()
        self.next_composite_buy_rates = List[Float64]()
        self.next_composite_sell_rates = List[Float64]()

    def __copy__(inout self, other: Self):
        self.steps_per_hour = other.steps_per_hour
        self.dt_hour = other.dt_hour
        self.last_step = other.last_step
        self.m_monthly_load_forecast = other.m_monthly_load_forecast
        self.m_monthly_gen_forecast = other.m_monthly_gen_forecast
        self.m_monthly_avg_load_forecast = other.m_monthly_avg_load_forecast
        self.current_composite_buy_rates = other.current_composite_buy_rates
        self.current_composite_sell_rates = other.current_composite_sell_rates
        self.next_composite_buy_rates = other.next_composite_buy_rates
        self.next_composite_sell_rates = other.next_composite_sell_rates
        self.last_month_init = other.last_month_init
        self.nyears = other.nyears
        self.rate = new rate_data(other.rate[])

    def __del__(owned self):
        delete self.rate

    def forecastCost(inout self, predicted_loads: List[Float64], year: Int, hour_of_year: Int, step: Int) -> Float64:
        var cost: Float64 = 0.0
        var month: Int = month_of(Float64(hour_of_year)) - 1
        var lifeTimeIndex: Int = lifetimeIndex(year, hour_of_year, step, self.steps_per_hour)
        var n: Int = predicted_loads.size()
        var index_at_end: Int = yearOneIndex(self.dt_hour, lifeTimeIndex + n)
        var month_at_end: Int = month_of(Float64(index_at_end) / Float64(self.steps_per_hour)) - 1
        var crossing_month: Bool = month != month_at_end
        var year_at_end: Int = year
        if month_at_end < month:
            year_at_end += 1
        if year_at_end >= self.nyears:
            crossing_month = false
        var previousDemandCharge: Float64 = self.rate[].get_demand_charge(month, year)
        var previousEnergyCharge: Float64 = 0.0
        if self.rate[].enable_nm:
            previousEnergyCharge = self.getEnergyChargeNetMetering(month, self.current_composite_buy_rates, self.current_composite_sell_rates)
        if crossing_month:
            self.initializeMonth(month_at_end, year_at_end)
            previousDemandCharge += self.rate[].get_demand_charge(month_at_end, year_at_end)
        var newEnergyCharge: Float64 = 0.0
        var use_next_month: Bool = false
        var current_year: Int = year
        for i in range(n):
            var year_one_index: Int = yearOneIndex(self.dt_hour, lifeTimeIndex)
            var current_month: Int = month_of(Float64(hour_of_year)) - 1
            if current_month != month and not use_next_month:
                use_next_month = true
                if self.rate[].enable_nm:
                    newEnergyCharge += self.getEnergyChargeNetMetering(month, self.current_composite_buy_rates, self.current_composite_sell_rates)
                self.restartMonth(month, current_month, year_at_end)
                current_year = year_at_end
            var curr_month: ur_month = self.rate[].m_month[current_month]
            var power: Float64 = predicted_loads[i]
            var energy: Float64 = predicted_loads[i] * self.dt_hour
            curr_month.update_net_and_peak(energy, power, year_one_index)
            self.rate[].sort_energy_to_periods(current_month, energy, year_one_index)
            self.rate[].find_dc_tou_peak(current_month, power, year_one_index)
            cost += self.getEnergyChargeNetBillingOrTimeSeries(energy, year_one_index, current_month, current_year, use_next_month)
            step += 1
            lifeTimeIndex += 1
            if step == self.steps_per_hour:
                hour_of_year += 1
                if hour_of_year >= 8760:
                    hour_of_year = 0
                step = 0
        var newDemandCharge: Float64 = self.rate[].get_demand_charge(month, year)
        if crossing_month and n == 1:
            if self.rate[].enable_nm:
                newEnergyCharge += self.getEnergyChargeNetMetering(month, self.current_composite_buy_rates, self.current_composite_sell_rates)
            self.restartMonth(month, month_at_end, year_at_end)
            self.copyTOUForecast()
        if crossing_month:
            newDemandCharge += self.rate[].get_demand_charge(month_at_end, year_at_end)
            if self.rate[].enable_nm:
                newEnergyCharge += self.getEnergyChargeNetMetering(month_at_end, self.next_composite_buy_rates, self.next_composite_sell_rates)
        else:
            if self.rate[].enable_nm:
                newEnergyCharge += self.getEnergyChargeNetMetering(month, self.current_composite_buy_rates, self.current_composite_sell_rates)
        cost += newDemandCharge + newEnergyCharge - previousDemandCharge - previousEnergyCharge
        return cost

    def compute_next_composite_tou(inout self, month: Int, year: Int):
        var curr_month: ur_month = self.rate[].m_month[month]
        var expected_load: Float64 = self.m_monthly_load_forecast[year * 12 + month]
        var rate_esc: ssc_number_t = self.rate[].rate_scale[year]
        self.next_composite_buy_rates.clear()
        var num_per: ssc_number_t = ssc_number_t(curr_month.ec_tou_br.nrows())
        if expected_load > 0.0:
            for ir in range(num_per):
                var done: Bool = false
                var periodCost: Float64 = 0.0
                for ic in range(curr_month.ec_tou_ub.ncols()) and not done:
                    var ub_tier: ssc_number_t = curr_month.ec_tou_ub[ir][ic]
                    var prev_tier: ssc_number_t = 0.0
                    if ic > 0:
                        prev_tier = curr_month.ec_tou_ub[ir][ic - 1]
                    if expected_load > ub_tier:
                        periodCost += (ub_tier - prev_tier) / expected_load * curr_month.ec_tou_br[ir][ic] * rate_esc
                    else:
                        periodCost += (expected_load - prev_tier) / expected_load * curr_month.ec_tou_br[ir][ic] * rate_esc
                        done = true
                self.next_composite_buy_rates.append(periodCost)
        else:
            for ir in range(num_per):
                var periodBuyRate: Float64 = curr_month.ec_tou_br[ir][0] * rate_esc
                self.next_composite_buy_rates.append(periodBuyRate)
        var expected_gen: Float64 = self.m_monthly_gen_forecast[year * 12 + month]
        self.next_composite_sell_rates.clear()
        num_per = ssc_number_t(curr_month.ec_tou_sr.nrows())
        if expected_gen > 0.0:
            for ir in range(num_per):
                var done: Bool = false
                var periodSellRate: Float64 = 0.0
                if not self.rate[].nm_credits_w_rollover:
                    for ic in range(curr_month.ec_tou_ub.ncols()) and not done:
                        var ub_tier: ssc_number_t = curr_month.ec_tou_ub[ir][ic]
                        var prev_tier: ssc_number_t = 0.0
                        if ic > 0:
                            prev_tier = curr_month.ec_tou_ub[ir][ic - 1]
                        if expected_gen > ub_tier:
                            periodSellRate += (ub_tier - prev_tier) / expected_gen * curr_month.ec_tou_sr[ir][ic] * rate_esc
                        else:
                            periodSellRate += (expected_gen - prev_tier) / expected_gen * curr_month.ec_tou_sr[ir][ic] * rate_esc
                            done = true
                self.next_composite_sell_rates.append(periodSellRate)
        else:
            for ir in range(num_per):
                var periodSellRate: Float64 = 0.0
                if not self.rate[].nm_credits_w_rollover:
                    periodSellRate = curr_month.ec_tou_sr[ir][0] * rate_esc
                self.next_composite_sell_rates.append(periodSellRate)

    def initializeMonth(inout self, month: Int, year: Int):
        if self.last_month_init != month:
            self.rate[].init_dc_peak_vectors(month)
            self.compute_next_composite_tou(month, year)
            var avg_load: Float64 = self.m_monthly_avg_load_forecast[year * 12 + month]
            var curr_month: ur_month = self.rate[].m_month[month]
            curr_month.dc_flat_peak = avg_load
            for period in range(curr_month.dc_periods.size()):
                curr_month.dc_tou_peak[period] = avg_load
            self.last_month_init = month

    def copyTOUForecast(inout self):
        self.current_composite_buy_rates.clear()
        self.current_composite_sell_rates.clear()
        for val in self.next_composite_buy_rates:
            self.current_composite_buy_rates.append(val)
        for val in self.next_composite_sell_rates:
            self.current_composite_sell_rates.append(val)

    def restartMonth(inout self, prevMonth: Int, currentMonth: Int, year: Int):
        var prev_month: ur_month = self.rate[].m_month[prevMonth]
        var curr_month: ur_month = self.rate[].m_month[currentMonth]
        self.rate[].compute_surplus(prev_month)
        var skip_rollover: Bool = (currentMonth == 0 and year == 0) or (currentMonth == self.rate[].net_metering_credit_month + 1) or (currentMonth == 0 and self.rate[].net_metering_credit_month == 11)
        if not skip_rollover and self.rate[].nm_credits_w_rollover:
            self.rate[].transfer_surplus(curr_month, prev_month)
        prev_month.reset()

    def getEnergyChargeNetMetering(self, month: Int, buy_rates: List[Float64], sell_rates: List[Float64]) -> Float64:
        var cost: Float64 = 0.0
        var curr_month: ur_month = self.rate[].m_month[month]
        var num_per: ssc_number_t = ssc_number_t(curr_month.ec_energy_use.nrows())
        for ir in range(num_per):
            var per_energy: ssc_number_t = curr_month.ec_energy_use[ir][0]
            if per_energy < 0.0 and not self.rate[].en_ts_buy_rate:
                cost += buy_rates[ir] * -per_energy
            elif not self.rate[].en_ts_sell_rate:
                cost -= sell_rates[ir] * per_energy
        return cost

    def getEnergyChargeNetBillingOrTimeSeries(self, energy: Float64, year_one_index: Int, current_month: Int, year: Int, use_next_month: Bool) -> Float64:
        var cost: Float64 = 0.0
        if self.rate[].enable_nm and not self.rate[].en_ts_buy_rate and not self.rate[].en_ts_sell_rate:
            return cost
        var tou_period: Int = self.rate[].get_tou_row(year_one_index, current_month)
        var rate_index: Int = year if year < self.rate[].rate_scale.size() else self.rate[].rate_scale.size() - 1
        var rate_esc: ssc_number_t = self.rate[].rate_scale[rate_index]
        if energy < 0.0:
            if self.rate[].en_ts_buy_rate:
                cost += self.rate[].m_ec_ts_buy_rate[year_one_index] * -energy * rate_esc
            elif not self.rate[].enable_nm:
                if use_next_month:
                    cost += self.next_composite_buy_rates[tou_period] * -energy
                else:
                    cost += self.current_composite_buy_rates[tou_period] * -energy
        else:
            if self.rate[].en_ts_sell_rate:
                cost += self.rate[].m_ec_ts_sell_rate[year_one_index] * -energy * rate_esc
            elif not self.rate[].enable_nm:
                if use_next_month:
                    cost += self.next_composite_sell_rates[tou_period] * -energy
                else:
                    cost += self.current_composite_sell_rates[tou_period] * -energy
        return cost