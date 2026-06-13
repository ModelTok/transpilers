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
from core import core, compute_module, var_info, var_info_invalid
from util import format, nday, pow
from stdlib import List, Float64, Int, UInt

alias ssc_number_t = Float64

var vtab_thermal_rate = {
/*   VARTYPE           DATATYPE         NAME                         LABEL                                           UNITS     META                      GROUP          REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	{ SSC_INPUT,        SSC_NUMBER,     "en_thermal_rates",           "Optionally enable/disable thermal_rate",                   "years",  "",                      "Thermal Rate",             "",                         "INTEGER,MIN=0,MAX=1",              "" },
	{ SSC_INPUT,        SSC_NUMBER,     "analysis_period",           "Number of years in analysis",                   "years",  "",                      "Lifetime",             "*",                         "INTEGER,POSITIVE",              "" },
	{ SSC_INPUT, SSC_NUMBER, "system_use_lifetime_output", "Lifetime hourly system outputs", "0/1", "0=hourly first year,1=hourly lifetime", "Lifetime", "*", "INTEGER,MIN=0,MAX=1", "" },
	{ SSC_INPUT, SSC_ARRAY, "fuelcell_power_thermal", "Fuel cell power generated", "kW-t", "", "Thermal Rate", "*", "", "" },
	{ SSC_INOUT, SSC_ARRAY, "thermal_load", "Thermal load (year 1)", "kW-t", "", "Thermal Rate", "", "", "" },
	{ SSC_INPUT, SSC_NUMBER, "inflation_rate", "Inflation rate", "%", "", "Lifetime", "*", "MIN=-99", "" },
	{ SSC_INPUT, SSC_ARRAY, "thermal_degradation", "Annual energy degradation", "%", "", "Thermal Rate", "?=0", "", "" },
	{ SSC_INPUT, SSC_ARRAY, "thermal_load_escalation", "Annual load escalation", "%/year", "", "Thermal Rate", "?=0", "", "" },
	{ SSC_INPUT,        SSC_ARRAY,      "thermal_rate_escalation",          "Annual thermal rate escalation",  "%/year", "",                      "Thermal Rate",             "?=0",                       "",                              "" },
	{ SSC_INPUT, SSC_NUMBER, "thermal_buy_rate_option", "Thermal buy rate option", "0/1", "0=flat,1=timestep", "Thermal Rate", "?=0", "INTEGER,MIN=0,MAX=1", "" },
	{ SSC_INPUT, SSC_ARRAY,  "thermal_buy_rate",          "Thermal buy rate",  "$/kW-t", "",                      "Thermal Rate",             "?=0",                       "",                              "" },
	{ SSC_INPUT, SSC_NUMBER, "thermal_buy_rate_flat",     "Thermal buy rate flat",  "$/kW-t", "",                      "Thermal Rate",             "?=0",                       "",                              "" },
	{ SSC_INPUT, SSC_NUMBER, "thermal_sell_rate_option", "Thermal sell rate option", "0/1", "0=flat,1=timestep", "Thermal Rate", "?=0", "INTEGER,MIN=0,MAX=1", "" },
	{ SSC_INPUT, SSC_ARRAY,  "thermal_sell_rate",          "Thermal sell rate",  "$/kW-t", "",                      "Thermal Rate",             "?=0",                       "",                              "" },
	{ SSC_INPUT, SSC_NUMBER, "thermal_sell_rate_flat",     "Thermal sell rate flat",  "$/kW-t", "",                      "Thermal Rate",             "?=0",                       "",                              "" },
	{ SSC_OUTPUT, SSC_ARRAY, "thermal_revenue_with_system", "Thermal revenue with system", "$", "", "Time Series", "*", "", "" },
	{ SSC_OUTPUT, SSC_ARRAY, "thermal_revenue_without_system", "Thermal revenue without system", "$", "", "Time Series", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "thermal_load_year1", "Thermal load (year 1)", "$", "", "", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "thermal_savings_year1", "Thermal savings (year 1)", "$", "", "", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "thermal_cost_with_system_year1", "Thermal cost with sytem (year 1)", "$", "", "", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "thermal_cost_without_system_year1", "Thermal cost without system (year 1)", "$", "", "", "*", "", "" }
}
struct tr_month:
    var thermal_net: ssc_number_t
    var thermal_load: ssc_number_t
    var thermal_gen: ssc_number_t
    var hours_per_month: Int
    var thermal_peak: ssc_number_t
    var thermal_peak_hour: Int
    var thermal_buy: ssc_number_t
    var thermal_sell: ssc_number_t

struct cm_thermalrate(compute_module):
    var m_num_rec_yearly: UInt
    var m_month: List[tr_month]

    def __init__(inout self):
        self.add_var_info(vtab_thermal_rate)

    def exec(self):
        if self.is_assigned("en_thermal_rates"):
            if not self.as_boolean("en_thermal_rates"):
                self.remove_var_info(vtab_thermal_rate)
                return
        var parr: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        var count: UInt = 0
        var i: UInt = 0
        var j: UInt = 0
        var nyears: UInt = UInt(self.as_integer("analysis_period"))
        var inflation_rate: Float64 = self.as_double("inflation_rate") * 0.01
        var sys_scale: List[ssc_number_t] = List[ssc_number_t](nyears)
        if self.as_integer("system_use_lifetime_output") == 1:
            for i in range(nyears):
                sys_scale[i] = 1.0
        else:
            parr = self.as_array("thermal_degradation", count)
            if count == 1:
                for i in range(nyears):
                    sys_scale[i] = ssc_number_t(pow(Float64(1 - parr[0] * 0.01), Float64(i)))
            else:
                for i in range(nyears):
                    if i < count:
                        sys_scale[i] = ssc_number_t(1.0 - parr[i] * 0.01)
                    else:
                        break
        var load_scale: List[ssc_number_t] = List[ssc_number_t](nyears)
        parr = self.as_array("thermal_load_escalation", count)
        if count == 1:
            for i in range(nyears):
                load_scale[i] = ssc_number_t(pow(Float64(1 + parr[0] * 0.01), Float64(i)))
        else:
            for i in range(nyears):
                load_scale[i] = ssc_number_t(1 + parr[i] * 0.01)
        var rate_scale: List[ssc_number_t] = List[ssc_number_t](nyears)
        parr = self.as_array("thermal_rate_escalation", count)
        if count == 1:
            for i in range(nyears):
                rate_scale[i] = ssc_number_t(pow(Float64(inflation_rate + 1 + parr[0] * 0.01), Float64(i)))
        else:
            for i in range(nyears):
                rate_scale[i] = ssc_number_t(1 + parr[i] * 0.01)
        var pload: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        var pgen: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        var pbuyrate: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        var psellrate: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        var nrec_load: UInt = 0
        var nrec_gen: UInt = 0
        var step_per_hour_gen: UInt = 1
        var step_per_hour_load: UInt = 1
        var bload: Bool = False
        pgen = self.as_array("fuelcell_power_thermal", nrec_gen)
        var nrec_gen_per_year: UInt = nrec_gen
        if self.as_integer("system_use_lifetime_output") == 1:
            nrec_gen_per_year = nrec_gen / nyears
        step_per_hour_gen = nrec_gen_per_year / 8760
        if step_per_hour_gen < 1 or step_per_hour_gen > 60 or step_per_hour_gen * 8760 != nrec_gen_per_year:
            raise Error("thermalrate: " + format("invalid number of thermal records (%d): must be an integer multiple of 8760", nrec_gen_per_year))
        var ts_hour_gen: ssc_number_t = 1.0 / step_per_hour_gen
        self.m_num_rec_yearly = nrec_gen_per_year
        if self.is_assigned("thermal_load"):
            bload = True
            pload = self.as_array("thermal_load", nrec_load)
            step_per_hour_load = nrec_load / 8760
            if step_per_hour_load < 1 or step_per_hour_load > 60 or step_per_hour_load * 8760 != nrec_load:
                raise Error("thermalrate: " + format("invalid number of load records (%d): must be an integer multiple of 8760", nrec_load))
            if (nrec_load != self.m_num_rec_yearly) and (nrec_load != 8760):
                raise Error("thermalrate: " + format("number of load records (%d) must be equal to number of gen records (%d) or 8760 for each year", nrec_load, self.m_num_rec_yearly))
        var e_sys_cy: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var p_sys_cy: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var p_load: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var p_buyrate: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var p_sellrate: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var e_grid_cy: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var p_grid_cy: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var e_load_cy: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var p_load_cy: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var idx: UInt = 0
        if self.as_integer("thermal_buy_rate_option") == 1:
            var nbuyrate: UInt = 0
            var step_per_hour_br: UInt = 0
            var br: ssc_number_t = 0.0
            pbuyrate = self.as_array("thermal_buy_rate", nbuyrate)
            step_per_hour_br = nbuyrate / 8760
            if step_per_hour_br < 1 or step_per_hour_br > 60 or step_per_hour_br * 8760 != nbuyrate:
                raise Error("thermalrate: " + format("invalid number of buy rate records (%d): must be an integer multiple of 8760", nbuyrate))
            if (nbuyrate != self.m_num_rec_yearly) and (nbuyrate != 8760):
                raise Error("thermalrate: " + format("number of buy rate  records (%d) must be equal to number of gen records (%d) or 8760 for each year", nbuyrate, self.m_num_rec_yearly))
            for i in range(8760):
                for ii in range(step_per_hour_gen):
                    var ndx: UInt = i * step_per_hour_gen + ii
                    br = pbuyrate[idx] if idx < nbuyrate else 0.0
                    p_buyrate[ndx] = br
                    if step_per_hour_gen == step_per_hour_br:
                        idx += 1
                    elif ii == (step_per_hour_gen - 1):
                        idx += 1
        else:
            var br: ssc_number_t = self.as_number("thermal_buy_rate_flat")
            for i in range(self.m_num_rec_yearly):
                p_buyrate[i] = br
        idx = 0
        if self.as_integer("thermal_sell_rate_option") == 1:
            var nsellrate: UInt = 0
            var step_per_hour_br: UInt = 0
            var br: ssc_number_t = 0.0
            psellrate = self.as_array("thermal_sell_rate", nsellrate)
            step_per_hour_br = nsellrate / 8760
            if step_per_hour_br < 1 or step_per_hour_br > 60 or step_per_hour_br * 8760 != nsellrate:
                raise Error("thermalrate: " + format("invalid number of sell rate records (%d): must be an integer multiple of 8760", nsellrate))
            if (nsellrate != self.m_num_rec_yearly) and (nsellrate != 8760):
                raise Error("thermalrate: " + format("number of sell rate  records (%d) must be equal to number of gen records (%d) or 8760 for each year", nsellrate, self.m_num_rec_yearly))
            for i in range(8760):
                for ii in range(step_per_hour_gen):
                    var ndx: UInt = i * step_per_hour_gen + ii
                    br = psellrate[idx] if idx < nsellrate else 0.0
                    p_sellrate[ndx] = br
                    if step_per_hour_gen == step_per_hour_br:
                        idx += 1
                    elif ii == (step_per_hour_gen - 1):
                        idx += 1
        else:
            var br: ssc_number_t = self.as_number("thermal_sell_rate_flat")
            for i in range(self.m_num_rec_yearly):
                p_sellrate[i] = br
        var ts_load: ssc_number_t = 0.0
        var year1_thermal_load: ssc_number_t = 0.0
        idx = 0
        for i in range(8760):
            for ii in range(step_per_hour_gen):
                var ndx: UInt = i * step_per_hour_gen + ii
                ts_load = pload[idx] if (bload and idx < nrec_load) else 0.0
                year1_thermal_load += ts_load
                p_load[ndx] = -ts_load
                if step_per_hour_gen == step_per_hour_load:
                    idx += 1
                elif ii == (step_per_hour_gen - 1):
                    idx += 1
        self.assign("thermal_load_year1", year1_thermal_load * ts_hour_gen)
        /* allocate intermediate data arrays */
        var revenue_w_sys: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var revenue_wo_sys: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var payment: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var income: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var thermal_charge_w_sys: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var thermal_charge_wo_sys: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var load: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var salespurchases: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
        var monthly_revenue_w_sys: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_revenue_wo_sys: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_thermal_charges: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_ec_rates: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_salespurchases: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_load: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_system_generation: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_bill: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_peak: List[ssc_number_t] = List[ssc_number_t](12)
        var monthly_test: List[ssc_number_t] = List[ssc_number_t](12)
        /* allocate outputs */
        var annual_net_revenue: Pointer[ssc_number_t] = self.allocate("annual_thermal_value", nyears + 1)
        var annual_thermal_load: Pointer[ssc_number_t] = self.allocate("annual_thermal_load", nyears + 1)
        var thermal_net: Pointer[ssc_number_t] = self.allocate("scaled_annual_thermal_energy", nyears + 1)
        var annual_revenue_w_sys: Pointer[ssc_number_t] = self.allocate("annual_thermal_revenue_with_system", nyears + 1)
        var annual_revenue_wo_sys: Pointer[ssc_number_t] = self.allocate("annual_thermal_revenue_without_system", nyears + 1)
        var annual_thermal_cost_w_sys: Pointer[ssc_number_t] = self.allocate("thermal_cost_with_system", nyears + 1)
        var annual_thermal_cost_wo_sys: Pointer[ssc_number_t] = self.allocate("thermal_cost_without_system", nyears + 1)
        var lifetime_load: Pointer[ssc_number_t] = self.allocate("lifetime_thermal_load", nrec_gen)
        idx = 0
        for i in range(nyears):
            for j in range(self.m_num_rec_yearly):
                /* for future implementation for lifetime loads
                if ((as_integer("system_use_lifetime_output") == 1) && (idx < nrec_load))
                {
                    e_load[j] = p_load[j] = 0.0;
                    for (size_t ii = 0; (ii < step_per_hour_load) && (idx < nrec_load); ii++)
                    {
                        ts_load = (bload ? pload[idx] : 0);
                        e_load[i] += ts_load * ts_hour_load;
                        p_load[i] = ((ts_load > p_load[i]) ? ts_load : p_load[i]);
                        idx++;
                    }
                    lifetime_hourly_load[i*8760 + j] = e_load[i];
                    e_load[i] = -e_load[i];
                    p_load[i] = -p_load[i];
                }
                */
                e_load_cy[j] = p_load[j] * load_scale[i] * ts_hour_gen
                p_load_cy[j] = p_load[j] * load_scale[i]
                if (self.as_integer("system_use_lifetime_output") == 1) and (idx < nrec_gen):
                    e_sys_cy[j] = pgen[idx] * ts_hour_gen
                    p_sys_cy[j] = pgen[idx]
                    lifetime_load[idx] = -e_load_cy[j]
                    idx += 1
                else:
                    e_sys_cy[j] = pgen[j] * ts_hour_gen
                    p_sys_cy[j] = pgen[j]
                e_sys_cy[j] *= sys_scale[i]
                p_sys_cy[j] *= sys_scale[i]
                e_grid_cy[j] = e_sys_cy[j] + e_load_cy[j]
                p_grid_cy[j] = p_sys_cy[j] + p_load_cy[j]
            self.tr_calc_timestep(e_load_cy, p_load_cy, p_buyrate, p_sellrate, revenue_wo_sys, payment, income, thermal_charge_wo_sys, rate_scale[i])
            if i == 0:
                self.assign("year1_hourly_charge_without_system", var_data(thermal_charge_wo_sys, self.m_num_rec_yearly))
                for ii in range(self.m_num_rec_yearly):
                    salespurchases[ii] = revenue_wo_sys[ii]
                var c: Int = 0
                for m in range(12):
                    monthly_salespurchases[m] = 0
                    for d in range(Int(nday[m])):
                        for h in range(24):
                            for s in range(step_per_hour_gen):
                                monthly_salespurchases[m] += salespurchases[c]
                                c += 1
                self.assign("thermal_revenue_without_system", var_data(revenue_wo_sys, Int(self.m_num_rec_yearly)))
                self.assign("year1_monthly_thermal_bill_wo_sys", var_data(monthly_salespurchases, 12))
            self.tr_calc_timestep(e_grid_cy, p_grid_cy, p_buyrate, p_sellrate, revenue_w_sys, payment, income, thermal_charge_w_sys, rate_scale[i])
            if i == 0:
                self.assign("year1_hourly_charge_with_system", var_data(thermal_charge_w_sys, Int(self.m_num_rec_yearly)))
                self.assign("thermal_revenue_with_system", var_data(revenue_w_sys, Int(self.m_num_rec_yearly)))
                self.assign("year1_monthly_load", var_data(monthly_load, 12))
                self.assign("year1_monthly_system_generation", var_data(monthly_system_generation, 12))
                self.assign("year1_monthly_thermal_bill_w_sys", var_data(monthly_bill, 12))
                var output: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
                var tdemand: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
                var pdemand: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
                var e_sys_to_grid: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
                var e_sys_to_load: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
                var p_sys_to_load: List[ssc_number_t] = List[ssc_number_t](self.m_num_rec_yearly)
                for j in range(self.m_num_rec_yearly):
                    output[j] = e_sys_cy[j]
                    tdemand[j] = -e_grid_cy[j] if e_grid_cy[j] < 0.0 else 0.0
                    pdemand[j] = -p_grid_cy[j] if p_grid_cy[j] < 0.0 else 0.0
                    var sys_e_net: ssc_number_t = output[j] + e_load_cy[j] // loads are assumed negative
                    e_sys_to_grid[j] = sys_e_net if sys_e_net > 0 else 0.0
                    e_sys_to_load[j] = -e_load_cy[j] if sys_e_net > 0 else output[j]
                    var sys_p_net: ssc_number_t = output[j] + p_load_cy[j] // loads are assumed negative
                    p_sys_to_load[j] = -p_load_cy[j] if sys_p_net > 0 else output[j]
                self.assign("year1_hourly_system_output", var_data(output, Int(self.m_num_rec_yearly)))
                self.assign("year1_hourly_t_demand", var_data(tdemand, Int(self.m_num_rec_yearly)))
                self.assign("year1_hourly_p_demand", var_data(pdemand, Int(self.m_num_rec_yearly)))
                self.assign("year1_hourly_system_to_load", var_data(e_sys_to_load, Int(self.m_num_rec_yearly)))
                self.assign("year1_hourly_p_system_to_load", var_data(p_sys_to_load, Int(self.m_num_rec_yearly)))
            annual_net_revenue[i + 1] = 0.0
            annual_thermal_load[i + 1] = 0.0
            thermal_net[i + 1] = 0.0
            annual_revenue_w_sys[i + 1] = 0.0
            annual_revenue_wo_sys[i + 1] = 0.0
            for j in range(self.m_num_rec_yearly):
                thermal_net[i + 1] += e_sys_cy[j]
                annual_thermal_load[i + 1] += -e_load_cy[j]
                annual_revenue_w_sys[i + 1] += revenue_w_sys[j]
                annual_revenue_wo_sys[i + 1] += revenue_wo_sys[j]
            annual_thermal_cost_w_sys[i + 1] = -annual_revenue_w_sys[i + 1]
            annual_thermal_cost_wo_sys[i + 1] = -annual_revenue_wo_sys[i + 1]
            annual_net_revenue[i + 1] = annual_thermal_cost_wo_sys[i + 1] - annual_thermal_cost_w_sys[i + 1]
        self.assign("thermal_cost_with_system_year1", annual_thermal_cost_w_sys[1])
        self.assign("thermal_cost_without_system_year1", annual_thermal_cost_wo_sys[1])
        self.assign("thermal_savings_year1", annual_thermal_cost_wo_sys[1] - annual_thermal_cost_w_sys[1])

    def monthly_outputs(self, e_load: Pointer[ssc_number_t], e_sys: Pointer[ssc_number_t], e_grid: Pointer[ssc_number_t], salespurchases: Pointer[ssc_number_t], monthly_load: Pointer[ssc_number_t], monthly_generation: Pointer[ssc_number_t], monthly_thermal_to_grid: Pointer[ssc_number_t], monthly_thermal_needed_from_grid: Pointer[ssc_number_t], monthly_salespurchases: Pointer[ssc_number_t]):
        var m: Int = 0
        var d: Int = 0
        var h: Int = 0
        var s: Int = 0
        var energy_use: Pointer[ssc_number_t] = Pointer[ssc_number_t](12) // 12 months
        var c: Int = 0
        var steps_per_hour: UInt = self.m_num_rec_yearly / 8760
        for m in range(12):
            energy_use[m] = 0
            monthly_load[m] = 0
            monthly_generation[m] = 0
            monthly_thermal_to_grid[m] = 0
            monthly_salespurchases[m] = 0
            for d in range(Int(nday[m])):
                for h in range(24):
                    for s in range(Int(steps_per_hour)):
                        if c < Int(self.m_num_rec_yearly):
                            energy_use[m] += e_grid[c]
                            monthly_load[m] -= e_load[c]
                            monthly_generation[m] += e_sys[c] // does not include first year sys_scale
                            monthly_thermal_to_grid[m] += e_grid[c]
                            monthly_salespurchases[m] += salespurchases[c]
                            c += 1
        for m in range(12):
            if monthly_thermal_to_grid[m] > 0:
                monthly_thermal_needed_from_grid[m] = monthly_thermal_to_grid[m]
            else:
                monthly_thermal_needed_from_grid[m] = 0

    def tr_calc_timestep(self, e_in: Pointer[ssc_number_t], p_in: Pointer[ssc_number_t], br_in: Pointer[ssc_number_t], sr_in: Pointer[ssc_number_t], revenue: Pointer[ssc_number_t], payment: Pointer[ssc_number_t], income: Pointer[ssc_number_t], thermal_charge: Pointer[ssc_number_t], rate_esc: ssc_number_t, bool param1: Bool = True, bool param2: Bool = True, bool param3: Bool = False):
        var i: Int = 0
        for i in range(Int(self.m_num_rec_yearly)):
            revenue[i] = 0.0
            payment[i] = 0.0
            income[i] = 0.0
            thermal_charge[i] = 0.0
        var steps_per_hour: UInt = self.m_num_rec_yearly / 8760
        var m: Int = 0
        var d: Int = 0
        var h: Int = 0
        var s: Int = 0
        var c: UInt = 0
        for m in range(Int(self.m_month.size)):
            self.m_month[m].thermal_net = 0
            self.m_month[m].hours_per_month = 0
            self.m_month[m].thermal_peak = 0
            self.m_month[m].thermal_peak_hour = 0
            for d in range(Int(nday[m])):
                for h in range(24):
                    for s in range(Int(steps_per_hour)):
                        if c < self.m_num_rec_yearly:
                            self.m_month[m].thermal_net += e_in[c] // -load and +gen
                            self.m_month[m].hours_per_month += 1
                            if p_in[c] < 0 and p_in[c] < -self.m_month[m].thermal_peak:
                                self.m_month[m].thermal_peak = -p_in[c]
                                self.m_month[m].thermal_peak_hour = Int(c)
                            c += 1
        c = 0 // hourly count
        for m in range(12):
            for d in range(Int(nday[m])):
                for h in range(24):
                    for s in range(Int(steps_per_hour)):
                        if c < self.m_num_rec_yearly:
                            if e_in[c] >= 0.0:
                                // calculate income or credit
                                var credit_amt: ssc_number_t = 0
                                var thermal_surplus: ssc_number_t = e_in[c]
                                credit_amt = thermal_surplus * sr_in[c] * rate_esc
                                income[c] = ssc_number_t(credit_amt)
                            else:
                                // calculate payment or charge
                                var charge_amt: ssc_number_t = 0
                                var thermal_deficit: ssc_number_t = -e_in[c]
                                charge_amt = thermal_deficit * br_in[c] * rate_esc
                                payment[c] = ssc_number_t(charge_amt)
                            revenue[c] = income[c] - payment[c]
                            c += 1
                        else:
                            break
                    else:
                        continue
                    break
                else:
                    continue
                break
            else:
                continue
            break
        // Note: the original loop structure uses multiple breaks; here we ensure we exit when c>=m_num_rec_yearly

// DEFINE_MODULE_ENTRY( thermalrate, "Thermal flat rate structure net revenue calculator", 1 );