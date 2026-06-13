"""
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided
that the following conditions are met :
1. Redistributions of source code must retain the above copyright notice, this list of conditions
and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse
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

from vector import List
from ...ssc.core import ssc_number_t, general_error, exec_error
from lib_util import matrix_t, translate_schedule, nday

struct ur_month:
    var ec_periods: List[Int]
    var dc_periods: List[Int]
    var ec_rollover_periods: List[Int]
    var energy_net: ssc_number_t
    var hours_per_month: Int
    var ec_energy_use: matrix_t[ssc_number_t]
    var ec_periods_tiers: List[List[Int]]
    var ec_energy_surplus: matrix_t[ssc_number_t]
    var dc_tou_peak: List[ssc_number_t]
    var dc_tou_peak_hour: List[Int]
    var dc_flat_peak: ssc_number_t
    var dc_flat_peak_hour: Int
    var ec_tou_ub_init: matrix_t[ssc_number_t]
    var ec_tou_br_init: matrix_t[ssc_number_t]
    var ec_tou_sr_init: matrix_t[ssc_number_t]
    var ec_tou_ub: matrix_t[ssc_number_t]
    var ec_tou_br: matrix_t[ssc_number_t]
    var ec_tou_sr: matrix_t[ssc_number_t]
    var ec_tou_units: matrix_t[Int]
    var ec_charge: matrix_t[ssc_number_t]
    var dc_tou_ub: matrix_t[ssc_number_t]
    var dc_tou_ch: matrix_t[ssc_number_t]
    var dc_flat_ub: List[ssc_number_t]
    var dc_flat_ch: List[ssc_number_t]
    var dc_tou_charge: List[Float64]  # double
    var dc_flat_charge: ssc_number_t

    def __init__(self):
        self.ec_periods = List[Int]()
        self.dc_periods = List[Int]()
        self.ec_rollover_periods = List[Int]()
        self.energy_net = 0
        self.hours_per_month = 0
        self.ec_energy_use = matrix_t[ssc_number_t]()
        self.ec_periods_tiers = List[List[Int]]()
        self.ec_energy_surplus = matrix_t[ssc_number_t]()
        self.dc_tou_peak = List[ssc_number_t]()
        self.dc_tou_peak_hour = List[Int]()
        self.dc_flat_peak = 0
        self.dc_flat_peak_hour = 0
        self.ec_tou_ub_init = matrix_t[ssc_number_t]()
        self.ec_tou_br_init = matrix_t[ssc_number_t]()
        self.ec_tou_sr_init = matrix_t[ssc_number_t]()
        self.ec_tou_ub = matrix_t[ssc_number_t]()
        self.ec_tou_br = matrix_t[ssc_number_t]()
        self.ec_tou_sr = matrix_t[ssc_number_t]()
        self.ec_tou_units = matrix_t[Int]()
        self.ec_charge = matrix_t[ssc_number_t]()
        self.dc_tou_ub = matrix_t[ssc_number_t]()
        self.dc_tou_ch = matrix_t[ssc_number_t]()
        self.dc_flat_ub = List[ssc_number_t]()
        self.dc_flat_ch = List[ssc_number_t]()
        self.dc_tou_charge = List[Float64]()
        self.dc_flat_charge = 0

    def __init__(self, tmp: Self):
        self.ec_periods = tmp.ec_periods
        self.dc_periods = tmp.dc_periods
        self.ec_rollover_periods = tmp.ec_rollover_periods
        self.energy_net = tmp.energy_net
        self.hours_per_month = tmp.hours_per_month
        self.ec_energy_use = tmp.ec_energy_use
        self.ec_periods_tiers = tmp.ec_periods_tiers
        self.ec_energy_surplus = tmp.ec_energy_surplus
        self.dc_tou_peak = tmp.dc_tou_peak
        self.dc_tou_peak_hour = tmp.dc_tou_peak_hour
        self.dc_flat_peak = tmp.dc_flat_peak
        self.dc_flat_peak_hour = tmp.dc_flat_peak_hour
        self.ec_tou_ub_init = tmp.ec_tou_ub_init
        self.ec_tou_br_init = tmp.ec_tou_br_init
        self.ec_tou_sr_init = tmp.ec_tou_sr_init
        self.ec_tou_ub = tmp.ec_tou_ub
        self.ec_tou_br = tmp.ec_tou_br
        self.ec_tou_sr = tmp.ec_tou_sr
        self.ec_tou_units = tmp.ec_tou_units
        self.ec_charge = tmp.ec_charge
        self.dc_tou_ub = tmp.dc_tou_ub
        self.dc_tou_ch = tmp.dc_tou_ch
        self.dc_flat_ub = tmp.dc_flat_ub
        self.dc_flat_ch = tmp.dc_flat_ch
        self.dc_tou_charge = tmp.dc_tou_charge
        self.dc_flat_charge = tmp.dc_flat_charge

    def update_net_and_peak(self, energy: Float64, power: Float64, step: Int):
        self.energy_net += energy
        self.hours_per_month += 1
        if power < 0 and power < -self.dc_flat_peak:
            self.dc_flat_peak = -power
            self.dc_flat_peak_hour = step

    def reset(self):
        self.energy_net = 0
        self.hours_per_month = 0
        self.dc_flat_peak = 0
        self.dc_flat_peak_hour = 0
        var start_tier = 0
        var end_tier = self.ec_tou_ub.ncols() - 1
        var num_periods = self.ec_tou_ub.nrows()
        var num_tiers = end_tier - start_tier + 1
        self.ec_energy_surplus.resize_fill(num_periods, num_tiers, 0)
        self.ec_energy_use.resize_fill(num_periods, num_tiers, 0)
        self.ec_charge.resize_fill(num_periods, num_tiers, 0)

struct rate_data:
    var m_ec_tou_sched: List[Int]
    var m_dc_tou_sched: List[Int]
    var m_month: List[ur_month]
    var m_ec_periods: List[Int]
    var m_ec_ts_sell_rate: List[ssc_number_t]
    var m_ec_ts_buy_rate: List[ssc_number_t]
    var m_ec_periods_tiers_init: List[List[Int]]
    var m_dc_tou_periods: List[Int]
    var m_dc_tou_periods_tiers: List[List[Int]]
    var m_dc_flat_tiers: List[List[Int]]
    var m_num_rec_yearly: Int
    var rate_scale: List[ssc_number_t]
    var dc_hourly_peak: List[ssc_number_t]
    var monthly_dc_fixed: List[ssc_number_t]
    var monthly_dc_tou: List[ssc_number_t]
    var tou_demand_single_peak: Bool
    var enable_nm: Bool
    var nm_credits_w_rollover: Bool
    var net_metering_credit_month: Int
    var nm_credit_sell_rate: Float64
    var en_ts_buy_rate: Bool
    var en_ts_sell_rate: Bool

    def __init__(self):
        self.m_ec_tou_sched = List[Int]()
        self.m_dc_tou_sched = List[Int]()
        self.m_month = List[ur_month]()
        self.m_ec_periods = List[Int]()
        self.m_ec_ts_sell_rate = List[ssc_number_t]()
        self.m_ec_ts_buy_rate = List[ssc_number_t]()
        self.m_ec_periods_tiers_init = List[List[Int]]()
        self.m_dc_tou_periods = List[Int]()
        self.m_dc_tou_periods_tiers = List[List[Int]]()
        self.m_dc_flat_tiers = List[List[Int]]()
        self.m_num_rec_yearly = 0
        self.dc_hourly_peak = List[ssc_number_t]()
        self.monthly_dc_fixed = List[ssc_number_t](12)
        self.monthly_dc_tou = List[ssc_number_t](12)
        self.tou_demand_single_peak = False
        self.enable_nm = False
        self.nm_credits_w_rollover = False
        self.net_metering_credit_month = 11
        self.nm_credit_sell_rate = 0.0
        self.rate_scale = List[ssc_number_t]()
        self.en_ts_buy_rate = False
        self.en_ts_sell_rate = False

    def __init__(self, tmp: Self):
        self.m_ec_tou_sched = tmp.m_ec_tou_sched
        self.m_dc_tou_sched = tmp.m_dc_tou_sched
        self.m_month = tmp.m_month
        self.m_ec_periods = tmp.m_ec_periods
        self.m_ec_ts_sell_rate = tmp.m_ec_ts_sell_rate
        self.m_ec_ts_buy_rate = tmp.m_ec_ts_buy_rate
        self.m_ec_periods_tiers_init = tmp.m_ec_periods_tiers_init
        self.m_dc_tou_periods = tmp.m_dc_tou_periods
        self.m_dc_tou_periods_tiers = tmp.m_dc_tou_periods_tiers
        self.m_dc_flat_tiers = tmp.m_dc_flat_tiers
        self.m_num_rec_yearly = tmp.m_num_rec_yearly
        self.dc_hourly_peak = tmp.dc_hourly_peak
        self.monthly_dc_fixed = tmp.monthly_dc_fixed
        self.monthly_dc_tou = tmp.monthly_dc_tou
        self.tou_demand_single_peak = tmp.tou_demand_single_peak
        self.enable_nm = tmp.enable_nm
        self.nm_credits_w_rollover = tmp.nm_credits_w_rollover
        self.net_metering_credit_month = tmp.net_metering_credit_month
        self.nm_credit_sell_rate = tmp.nm_credit_sell_rate
        self.rate_scale = tmp.rate_scale
        self.en_ts_buy_rate = tmp.en_ts_buy_rate
        self.en_ts_sell_rate = tmp.en_ts_sell_rate

    def init(self, num_rec_yearly: Int):
        var i: Int
        var m: Int
        self.m_num_rec_yearly = num_rec_yearly
        i = 0
        while i < self.m_ec_periods_tiers_init.size():
            self.m_ec_periods_tiers_init[i].clear()
            i += 1
        self.m_ec_periods.clear()
        i = 0
        while i < self.m_dc_tou_periods_tiers.size():
            self.m_dc_tou_periods_tiers[i].clear()
            i += 1
        self.m_dc_tou_periods.clear()
        i = 0
        while i < self.m_dc_flat_tiers.size():
            self.m_dc_flat_tiers[i].clear()
            i += 1
        self.m_month.clear()
        m = 0
        while m < 12:
            var urm = ur_month()
            self.m_month.append(urm)
            m += 1
        self.m_ec_ts_sell_rate.clear()
        self.m_ec_ts_buy_rate.clear()
        self.dc_hourly_peak.clear()
        self.m_ec_tou_sched = List[Int](self.m_num_rec_yearly, 1)
        self.m_dc_tou_sched = List[Int](self.m_num_rec_yearly, 1)
        self.dc_hourly_peak = List[ssc_number_t](self.m_num_rec_yearly, 0)

    def check_for_kwh_per_kw_rate(self, units: Int) -> Bool:
        return (units == 1) or (units == 3)

    def init_energy_rates(self, gen_only: Bool):
        var m = 0
        while m < self.m_month.size():
            var num_periods = self.m_month[m].ec_tou_ub.nrows()
            var num_tiers = self.m_month[m].ec_tou_ub.ncols()
            if not gen_only:
                if (self.m_month[m].ec_tou_units.ncols() > 0 and self.m_month[m].ec_tou_units.nrows() > 0) and self.check_for_kwh_per_kw_rate(self.m_month[m].ec_tou_units.at(0, 0)):
                    var kWh_per_kW_tiers = List[Float64]()
                    var tier_numbers = List[Int]()
                    var tier_kwh = List[Float64]()
                    var flat_peak = self.m_month[m].dc_flat_peak
                    var i_tier = 0
                    while i_tier < self.m_month[m].ec_tou_units.ncols():
                        var units = self.m_month[m].ec_tou_units.at(0, i_tier)
                        if self.check_for_kwh_per_kw_rate(units):
                            var kwh_per_kw = self.m_month[m].ec_tou_ub_init.at(0, i_tier)
                            if kwh_per_kw > 1e37:
                                kWh_per_kW_tiers.append(kwh_per_kw)
                            else:
                                kWh_per_kW_tiers.append(kwh_per_kw * flat_peak)
                        i_tier += 1
                    var block: Int = 0
                    var total_tiers = self.m_month[m].ec_tou_units.ncols()
                    i_tier = 0
                    while i_tier < total_tiers:
                        var units = self.m_month[m].ec_tou_units.at(0, i_tier)
                        if self.check_for_kwh_per_kw_rate(units):
                            var kwh_per_kw = self.m_month[m].ec_tou_ub_init.at(0, i_tier)
                            if (block + 1 < kWh_per_kW_tiers.size()) and (kWh_per_kW_tiers[block] < kwh_per_kw * flat_peak):
                                block += 1
                            if i_tier + 1 < total_tiers:
                                var next_units = self.m_month[m].ec_tou_units.at(0, i_tier + 1)
                                if self.check_for_kwh_per_kw_rate(next_units):
                                    tier_numbers.append(i_tier)
                                    tier_kwh.append(kWh_per_kW_tiers[block])
                            else:
                                tier_numbers.append(i_tier)
                                tier_kwh.append(kWh_per_kW_tiers[block])
                        else:
                            var max_val = self.m_month[m].ec_tou_ub_init.at(0, i_tier)
                            if max_val < kWh_per_kW_tiers[block]:
                                tier_kwh.append(max_val)
                                tier_numbers.append(i_tier)
                            else:
                                if tier_kwh.size() == 0 or (tier_kwh[tier_kwh.size() - 1] < kWh_per_kW_tiers[block]):
                                    tier_kwh.append(kWh_per_kW_tiers[block])
                                    tier_numbers.append(i_tier)
                        i_tier += 1
                    num_tiers = tier_kwh.size()
                    var br = matrix_t[Float64](num_periods, num_tiers)
                    var sr = matrix_t[Float64](num_periods, num_tiers)
                    var ub = matrix_t[Float64](num_periods, num_tiers)
                    var period = 0
                    while period < num_periods:
                        var tier = 0
                        while tier < num_tiers:
                            br.at(period, tier) = self.m_month[m].ec_tou_br_init.at(period, tier_numbers[tier])
                            sr.at(period, tier) = self.m_month[m].ec_tou_sr_init.at(period, tier_numbers[tier])
                            ub.at(period, tier) = tier_kwh[tier]
                            self.m_month[m].ec_periods_tiers[period][tier] = self.m_ec_periods_tiers_init[period][tier_numbers[tier]]
                            tier += 1
                        period += 1
                    self.m_month[m].ec_tou_br = br
                    self.m_month[m].ec_tou_sr = sr
                    self.m_month[m].ec_tou_ub = ub
            self.m_month[m].ec_energy_surplus.resize_fill(num_periods, num_tiers, 0)
            self.m_month[m].ec_energy_use.resize_fill(num_periods, num_tiers, 0)
            self.m_month[m].ec_charge.resize_fill(num_periods, num_tiers, 0)
            m += 1

    def setup_time_series(self, cnt: Int, ts_sr: Pointer[ssc_number_t], ts_br: Pointer[ssc_number_t]):
        var i: Int
        var ts_step_per_hour = cnt / 8760
        var idx: Int = 0
        var sr: ssc_number_t = 0
        var br: ssc_number_t = 0
        var step_per_hour = self.m_num_rec_yearly / 8760
        idx = 0
        if ts_br != None:
            i = 0
            while i < 8760:
                var ii = 0
                while ii < step_per_hour:
                    br = ts_br[idx] if idx < cnt else 0
                    self.m_ec_ts_buy_rate.append(br)
                    if ii < ts_step_per_hour:
                        idx += 1
                    ii += 1
                i += 1
        idx = 0
        if ts_sr != None:
            i = 0
            while i < 8760:
                var ii = 0
                while ii < step_per_hour:
                    sr = ts_sr[idx] if idx < cnt else 0
                    self.m_ec_ts_sell_rate.append(sr)
                    if ii < ts_step_per_hour:
                        idx += 1
                    ii += 1
                i += 1

    def setup_energy_rates(self, ec_weekday: Pointer[ssc_number_t], ec_weekend: Pointer[ssc_number_t],
                          ec_tou_rows: Int, ec_tou_in: Pointer[ssc_number_t], sell_eq_buy: Bool):
        var nrows: Int = 12
        var ncols: Int = 24
        var steps_per_hour = self.m_num_rec_yearly / 8760
        var idx: Int = 0
        var ec_schedwkday = matrix_t[Float64](nrows, ncols)
        ec_schedwkday.assign(ec_weekday, nrows, ncols)
        var ec_schedwkend = matrix_t[Float64](nrows, ncols)
        ec_schedwkend.assign(ec_weekend, nrows, ncols)
        var ec_tod = List[Int](8760)
        if not translate_schedule(ec_tod, ec_schedwkday, ec_schedwkend, 1, 12):
            general_error("Could not translate weekday and weekend schedules for energy rates.")
        i = 0
        while i < 8760:
            var ii = 0
            while ii < steps_per_hour:
                if idx < self.m_num_rec_yearly:
                    self.m_ec_tou_sched[idx] = ec_tod[i]
                idx += 1
                ii += 1
            i += 1
        ncols = 6
        var ec_tou_mat = matrix_t[Float64](ec_tou_rows, ncols)
        ec_tou_mat.assign(ec_tou_in, ec_tou_rows, ncols)
        var r = 0
        while r < ec_tou_rows:
            var period = ec_tou_mat.at(r, 0) as Int
            if self.m_ec_periods.find(period) == -1:
                self.m_ec_periods.append(period)
            r += 1
        # sort (manual bubble or use sorting from list)
        self.m_ec_periods.sort()
        self.m_ec_periods_tiers_init = List[List[Int]](self.m_ec_periods.size())
        r = 0
        while r < ec_tou_rows:
            var period = ec_tou_mat.at(r, 0) as Int
            var tier = ec_tou_mat.at(r, 1) as Int
            var result = self.m_ec_periods.find(period)
            if result == -1:
                var ss = String("Energy rate Period ") + String(period) + String(" not found.")
                exec_error("lib_utility_rate_equations", ss)
            var ndx = result
            self.m_ec_periods_tiers_init[ndx].append(tier)
            r += 1
        r = 0
        while r < self.m_ec_periods_tiers_init.size():
            self.m_ec_periods_tiers_init[r].sort()
            r += 1
        var m = 0
        while m < self.m_month.size():
            var c = 0
            while c < ec_schedwkday.ncols():
                if self.m_month[m].ec_periods.find(ec_schedwkday.at(m, c) as Int) == -1:
                    self.m_month[m].ec_periods.append(ec_schedwkday.at(m, c) as Int)
                if (self.m_month[m].ec_rollover_periods.size() < 5) and (c == 0 or c == 5 or c == 11 or c == 17):
                    self.m_month[m].ec_rollover_periods.append(ec_schedwkday.at(m, c) as Int)
                c += 1
            c = 0
            while c < ec_schedwkend.ncols():
                if self.m_month[m].ec_periods.find(ec_schedwkend.at(m, c) as Int) == -1:
                    self.m_month[m].ec_periods.append(ec_schedwkend.at(m, c) as Int)
                c += 1
            self.m_month[m].ec_periods.sort()
            var pt_period = 0
            while pt_period < self.m_ec_periods_tiers_init.size():
                self.m_month[m].ec_periods_tiers.append(List[Int]())
                pt_period += 1
            pt_period = 0
            while pt_period < self.m_ec_periods_tiers_init.size():
                var pt_tier = 0
                while pt_tier < self.m_ec_periods_tiers_init[pt_period].size():
                    self.m_month[m].ec_periods_tiers[pt_period].append(self.m_ec_periods_tiers_init[pt_period][pt_tier])
                    pt_tier += 1
                pt_period += 1
            m += 1
        m = 0
        while m < self.m_month.size():
            var num_periods = 0
            var num_tiers = 0
            var i = 0
            while i < self.m_month[m].ec_periods.size():
                var per_num = self.m_ec_periods.find(self.m_month[m].ec_periods[i])
                if per_num == -1:
                    var ss = String("Period ") + String(self.m_month[m].ec_periods[i]) + String(" is in Month ") + String(m) + String(" but is not defined in the energy rate table. Rates for each period in the Weekday and Weekend schedules must be defined in the energy rate table.")
                    exec_error("lib_utility_rate_equations", ss)
                var period = self.m_ec_periods[per_num]
                var ndx = per_num
                num_tiers = self.m_ec_periods_tiers_init[ndx].size()
                if i == 0:
                    num_periods = self.m_month[m].ec_periods.size()
                    self.m_month[m].ec_tou_ub.resize_fill(num_periods, num_tiers, 1e38 as ssc_number_t)
                    self.m_month[m].ec_tou_units.resize_fill(num_periods, num_tiers, 0)
                    self.m_month[m].ec_tou_br.resize_fill(num_periods, num_tiers, 0)
                    self.m_month[m].ec_tou_sr.resize_fill(num_periods, num_tiers, 0)
                else:
                    if self.m_ec_periods_tiers_init[ndx].size() != num_tiers:
                        var ss = String("The number of tiers in the energy rate table, ") + String(self.m_ec_periods_tiers_init[ndx].size()) + String(", is incorrect for Month ") + String(m) + String(" and Period ") + String(self.m_month[m].ec_periods[i]) + String(". The correct number of tiers for that month and period is ") + String(num_tiers) + String(".")
                        exec_error("lib_utility_rate_equations", ss)
                var j = 0
                while j < self.m_ec_periods_tiers_init[ndx].size():
                    var tier = self.m_ec_periods_tiers_init[ndx][j]
                    var found = False
                    r = 0
                    while (r < ec_tou_rows) and not found:
                        if (period == ec_tou_mat.at(r, 0) as Int) and (tier == ec_tou_mat.at(r, 1) as Int):
                            self.m_month[m].ec_tou_ub.at(i, j) = ec_tou_mat.at(r, 2)
                            self.m_month[m].ec_tou_units.at(i, j) = ec_tou_mat.at(r, 3) as Int
                            if (self.m_month[m].ec_tou_units.at(i, j) == 2) or (self.m_month[m].ec_tou_units.at(i, j) == 3):
                                self.m_month[m].ec_tou_ub.at(i, j) *= nday[m]
                            self.m_month[m].ec_tou_br.at(i, j) = ec_tou_mat.at(r, 4)
                            var sell = ec_tou_mat.at(r, 5)
                            if sell_eq_buy:
                                sell = ec_tou_mat.at(r, 4)
                            self.m_month[m].ec_tou_sr.at(i, j) = sell
                            found = True
                        r += 1
                    j += 1
                self.m_month[m].ec_tou_ub_init = self.m_month[m].ec_tou_ub
                self.m_month[m].ec_tou_br_init = self.m_month[m].ec_tou_br
                self.m_month[m].ec_tou_sr_init = self.m_month[m].ec_tou_sr
                i += 1
            m += 1

    def setup_demand_charges(self, dc_weekday: Pointer[ssc_number_t], dc_weekend: Pointer[ssc_number_t],
                            dc_tou_rows: Int, dc_tou_in: Pointer[ssc_number_t],
                            dc_flat_rows: Int, dc_flat_in: Pointer[ssc_number_t]):
        var nrows: Int = 12
        var ncols: Int = 24
        var steps_per_hour = self.m_num_rec_yearly / 8760
        var idx: Int = 0
        var dc_schedwkday = matrix_t[Float64](nrows, ncols)
        dc_schedwkday.assign(dc_weekday, nrows, ncols)
        var dc_schedwkend = matrix_t[Float64](nrows, ncols)
        dc_schedwkend.assign(dc_weekend, nrows, ncols)
        var dc_tod = List[Int](8760)
        if not translate_schedule(dc_tod, dc_schedwkday, dc_schedwkend, 1, 12):
            general_error("Could not translate weekday and weekend schedules for demand charges")
        idx = 0
        var i = 0
        while i < 8760:
            var ii = 0
            while ii < steps_per_hour:
                if idx < self.m_num_rec_yearly:
                    self.m_dc_tou_sched[idx] = dc_tod[i]
                idx += 1
                ii += 1
            i += 1
        ncols = 4
        var dc_tou_mat = matrix_t[Float64](dc_tou_rows, ncols)
        dc_tou_mat.assign(dc_tou_in, dc_tou_rows, ncols)
        var m = 0
        while m < self.m_month.size():
            var c = 0
            while c < dc_schedwkday.ncols():
                if self.m_month[m].dc_periods.find(dc_schedwkday.at(m, c) as Int) == -1:
                    self.m_month[m].dc_periods.append(dc_schedwkday.at(m, c) as Int)
                c += 1
            c = 0
            while c < dc_schedwkend.ncols():
                if self.m_month[m].dc_periods.find(dc_schedwkend.at(m, c) as Int) == -1:
                    self.m_month[m].dc_periods.append(dc_schedwkend.at(m, c) as Int)
                c += 1
            self.m_month[m].dc_periods.sort()
            m += 1
        var r = 0
        while r < dc_tou_rows:
            var period = dc_tou_mat.at(r, 0) as Int
            if self.m_dc_tou_periods.find(period) == -1:
                self.m_dc_tou_periods.append(period)
            r += 1
        self.m_dc_tou_periods.sort()
        self.m_dc_tou_periods_tiers = List[List[Int]](self.m_dc_tou_periods.size())
        r = 0
        while r < dc_tou_rows:
            var period = dc_tou_mat.at(r, 0) as Int
            var tier = dc_tou_mat.at(r, 1) as Int
            var result = self.m_dc_tou_periods.find(period)
            if result == -1:
                var ss = String("Demand charge Period ") + String(period) + String(" not found.")
                exec_error("utilityrate5", ss)
            var ndx = result
            self.m_dc_tou_periods_tiers[ndx].append(tier)
            r += 1
        r = 0
        while r < self.m_dc_tou_periods_tiers.size():
            self.m_dc_tou_periods_tiers[r].sort()
            r += 1
        m = 0
        while m < self.m_month.size():
            var num_periods = self.m_month[m].dc_periods.size()
            var num_tiers = 0
            i = 0
            while i < self.m_month[m].dc_periods.size():
                var per_num = self.m_dc_tou_periods.find(self.m_month[m].dc_periods[i])
                if per_num == -1:
                    var ss = String("Period ") + String(self.m_month[m].dc_periods[i]) + String(" is in Month ") + String(m) + String(" but is not defined in the demand rate table.  Rates for each period in the Weekday and Weekend schedules must be defined in the demand rate table.")
                    exec_error("utilityrate5", ss)
                var ndx = per_num
                if self.m_dc_tou_periods_tiers[ndx].size() > num_tiers:
                    num_tiers = self.m_dc_tou_periods_tiers[ndx].size()
                i += 1
            self.m_month[m].dc_tou_ub.resize_fill(num_periods, num_tiers, 1e38 as ssc_number_t)
            self.m_month[m].dc_tou_ch.resize_fill(num_periods, num_tiers, 0)
            i = 0
            while i < self.m_month[m].dc_periods.size():
                var per_num = self.m_dc_tou_periods.find(self.m_month[m].dc_periods[i])
                var period = self.m_dc_tou_periods[per_num]
                var ndx = per_num
                var j = 0
                while j < self.m_dc_tou_periods_tiers[ndx].size():
                    var tier = self.m_dc_tou_periods_tiers[ndx][j]
                    var found = False
                    r = 0
                    while (r < dc_tou_rows) and not found:
                        if (period == dc_tou_mat.at(r, 0) as Int) and (tier == dc_tou_mat.at(r, 1) as Int):
                            self.m_month[m].dc_tou_ub.at(i, j) = dc_tou_mat.at(r, 2)
                            self.m_month[m].dc_tou_ch.at(i, j) = dc_tou_mat.at(r, 3)
                            found = True
                        r += 1
                    j += 1
                i += 1
            m += 1
        ncols = 4
        var dc_flat_mat = matrix_t[Float64](dc_flat_rows, ncols)
        dc_flat_mat.assign(dc_flat_in, dc_flat_rows, ncols)
        r = 0
        while r < self.m_month.size():
            self.m_dc_flat_tiers.append(List[Int]())
            r += 1
        r = 0
        while r < dc_flat_rows:
            var month = dc_flat_mat.at(r, 0) as Int
            var tier = dc_flat_mat.at(r, 1) as Int
            if (month < 0) or (month >= self.m_month.size()):
                var ss = String("Demand for Month ") + String(month) + String(" not found.")
                exec_error("utilityrate5", ss)
            self.m_dc_flat_tiers[month].append(tier)
            r += 1
        r = 0
        while r < self.m_dc_flat_tiers.size():
            self.m_dc_flat_tiers[r].sort()
            r += 1
        m = 0
        while m < self.m_month.size():
            self.m_month[m].dc_flat_ub.clear()
            self.m_month[m].dc_flat_ch.clear()
            j = 0
            while j < self.m_dc_flat_tiers[m].size():
                var tier = self.m_dc_flat_tiers[m][j]
                var found = False
                r = 0
                while (r < dc_flat_rows) and not found:
                    if (m == dc_flat_mat.at(r, 0) as Int) and (tier == dc_flat_mat.at(r, 1) as Int):
                        self.m_month[m].dc_flat_ub.append(dc_flat_mat.at(r, 2))
                        self.m_month[m].dc_flat_ch.append(dc_flat_mat.at(r, 3))
                        found = True
                    r += 1
                j += 1
            m += 1

    def sort_energy_to_periods(self, month: Int, energy: Float64, step: Int):
        var curr_month = self.m_month[month]
        var toup = self.m_ec_tou_sched[step]
        var per_num = curr_month.ec_periods.find(toup)
        if per_num == -1:
            var ss = String("Energy rate TOU Period ") + String(toup) + String(" not found for Month ") + String(util.schedule_int_to_month(month)) + String(".")
            exec_error("utilityrate5", ss)
        var row = per_num
        curr_month.ec_energy_use(row, 0) += energy

    def init_dc_peak_vectors(self, month: Int):
        var curr_month = self.m_month[month]
        curr_month.dc_tou_peak.clear()
        curr_month.dc_tou_peak_hour.clear()
        curr_month.dc_tou_peak = List[ssc_number_t](curr_month.dc_periods.size())
        curr_month.dc_tou_peak_hour = List[Int](curr_month.dc_periods.size())

    def find_dc_tou_peak(self, month: Int, power: Float64, step: Int):
        var curr_month = self.m_month[month]
        if curr_month.dc_periods.size() > 0:
            var todp = self.m_dc_tou_sched[step]
            var per_num = curr_month.dc_periods.find(todp)
            if per_num == -1:
                var ss = String("Demand charge Period ") + String(todp) + String(" not found for Month ") + String(month) + String(".")
                exec_error("lib_utility_rate_equations", ss)
            var row = per_num
            if power < 0 and power < -curr_month.dc_tou_peak[row]:
                curr_month.dc_tou_peak[row] = -power
                curr_month.dc_tou_peak_hour[row] = step

    def get_demand_charge(self, month: Int, year: Int) -> ssc_number_t:
        var tier: Int
        var period: Int
        var curr_month = self.m_month[month]
        var rate_esc = self.rate_scale[year]
        var charge: ssc_number_t = 0
        var d_lower: ssc_number_t = 0
        var total_charge: ssc_number_t = 0
        var demand = curr_month.dc_flat_peak
        var found = False
        tier = 0
        while tier < curr_month.dc_flat_ub.size() and not found:
            if demand < curr_month.dc_flat_ub[tier]:
                found = True
                charge += (demand - d_lower) * curr_month.dc_flat_ch[tier] * rate_esc
                curr_month.dc_flat_charge = charge
            else:
                charge += (curr_month.dc_flat_ub[tier] - d_lower) * curr_month.dc_flat_ch[tier] * rate_esc
                d_lower = curr_month.dc_flat_ub[tier]
            tier += 1
        self.dc_hourly_peak[curr_month.dc_flat_peak_hour] = curr_month.dc_flat_peak
        self.monthly_dc_fixed[month] = charge
        total_charge += charge
        demand = 0
        d_lower = 0
        var peak_hour = 0
        curr_month.dc_tou_charge.clear()
        period = 0
        while period < curr_month.dc_tou_ub.nrows():
            charge = 0
            d_lower = 0
            if self.tou_demand_single_peak:
                demand = curr_month.dc_flat_peak
                if curr_month.dc_flat_peak_hour != curr_month.dc_tou_peak_hour[period]:
                    period += 1
                    continue
            else:
                if period < curr_month.dc_periods.size():
                    demand = curr_month.dc_tou_peak[period]
                else:
                    demand = 0
            found = False
            tier = 0
            while tier < curr_month.dc_tou_ub.ncols() and not found:
                if demand < curr_month.dc_tou_ub.at(period, tier):
                    found = True
                    charge += (demand - d_lower) * curr_month.dc_tou_ch.at(period, tier) * rate_esc
                    curr_month.dc_tou_charge.append(charge)
                else:
                    if period < curr_month.dc_periods.size():
                        charge += (curr_month.dc_tou_ub.at(period, tier) - d_lower) * curr_month.dc_tou_ch.at(period, tier) * rate_esc
                        d_lower = curr_month.dc_tou_ub.at(period, tier)
                tier += 1
            self.dc_hourly_peak[peak_hour] = demand
            self.monthly_dc_tou[month] += charge
            total_charge += charge
            period += 1
            peak_hour += 1
        return total_charge

    def get_tou_row(self, year_one_index: Int, month: Int) -> Int:
        var period = self.m_ec_tou_sched[year_one_index]
        var curr_month = self.m_month[month]
        var per_num = curr_month.ec_periods.find(period)
        if per_num == -1:
            var ss = String("Energy rate Period ") + String(period) + String(" not found for Month ") + String(month) + String(".")
            exec_error("lib_utility_rate_equations", ss)
        return per_num

    def transfer_surplus(self, curr_month: ur_month, prev_month: ur_month) -> Int:
        var returnValue = 0
        var ir = 0
        while ir < prev_month.ec_energy_surplus.nrows():
            if prev_month.ec_energy_surplus.at(ir, 0) > 0:
                var toup_source = prev_month.ec_periods[ir]
                var source_per_num = prev_month.ec_rollover_periods.find(toup_source)
                if source_per_num == -1:
                    returnValue = 100 + toup_source
                else:
                    var extra: ssc_number_t = 0
                    var rollover_index = source_per_num
                    if rollover_index < curr_month.ec_rollover_periods.size():
                        var toup_target = curr_month.ec_rollover_periods[rollover_index]
                        var target_per_num = curr_month.ec_periods.find(toup_target)
                        if target_per_num == -1:
                            returnValue = 200 + toup_target
                        var target_row = target_per_num
                        var ic = 0
                        while ic < prev_month.ec_energy_surplus.ncols():
                            extra += prev_month.ec_energy_surplus.at(ir, ic)
                            ic += 1
                        curr_month.ec_energy_use(target_row, 0) += extra
            ir += 1
        return returnValue

    def compute_surplus(self, curr_month: ur_month):
        var ir = 0
        while ir < curr_month.ec_energy_use.nrows():
            if curr_month.ec_energy_use.at(ir, 0) > 0:
                curr_month.ec_energy_surplus.at(ir, 0) = curr_month.ec_energy_use.at(ir, 0)
                curr_month.ec_energy_use.at(ir, 0) = 0
            else:
                curr_month.ec_energy_use.at(ir, 0) = -curr_month.ec_energy_use.at(ir, 0)
            ir += 1