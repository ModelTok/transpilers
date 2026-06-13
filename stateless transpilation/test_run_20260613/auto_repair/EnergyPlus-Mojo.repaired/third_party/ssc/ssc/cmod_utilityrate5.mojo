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
from core import (
    compute_module,
    var_table,
    var_data,
    exec_error,
    SSC_INPUT,
    SSC_INOUT,
    SSC_OUTPUT,
    SSC_NUMBER,
    SSC_ARRAY,
    SSC_MATRIX,
    SSC_NOTICE,
    var_info,
    util,
)
from lib_utility_rate_equations import (
    rate_data,
    ur_month,
    ur_calc,
    ur_calc_timestep,
    ur_update_ec_monthly,
    scalefactors,
)
from common import (
    # assume common functions are available; adapt as needed
)

alias ssc_number_t = Float64

struct VarInfo:
    var vartype: Int32
    var datatype: Int32
    var name: String
    var label: String
    var units: String
    var meta: String
    var group: String
    var required_if: String
    var constraints: String
    var ui_hints: String
    def __init__(self, vartype: Int32, datatype: Int32, name: String, label: String, units: String, meta: String, group: String, required_if: String, constraints: String, ui_hints: String):
        self.vartype = vartype
        self.datatype = datatype
        self.name = name
        self.label = label
        self.units = units
        self.meta = meta
        self.group = group
        self.required_if = required_if
        self.constraints = constraints
        self.ui_hints = ui_hints

# Need to define var_info_invalid constant (likely a sentinel)
var var_info_invalid = VarInfo(0, 0, "", "", "", "", "", "", "", "")

var vtab_utility_rate5 = List[VarInfo](
    VarInfo(SSC_INPUT, SSC_NUMBER, "en_electricity_rates", "Optionally enable/disable electricity_rate", "years", "", "Electricity Rates", "", "INTEGER,MIN=0,MAX=1", ""),
    VarInfo(SSC_INPUT, SSC_NUMBER, "analysis_period", "Number of years in analysis", "years", "", "Lifetime", "*", "INTEGER,POSITIVE", ""),
    VarInfo(SSC_INPUT, SSC_NUMBER, "system_use_lifetime_output", "Lifetime hourly system outputs", "0/1", "0=hourly first year,1=hourly lifetime", "Lifetime", "*", "INTEGER,MIN=0,MAX=1", ""),
    VarInfo(SSC_INPUT, SSC_NUMBER, "TOU_demand_single_peak", "Use single monthly peak for TOU demand charge", "0/1", "0=use TOU peak,1=use flat peak", "Electricity Rates", "?=0", "INTEGER,MIN=0,MAX=1", ""),
    VarInfo(SSC_INPUT, SSC_ARRAY, "gen", "System power generated", "kW", "", "System Output", "*", "", ""),
    VarInfo(SSC_INOUT, SSC_ARRAY, "load", "Electricity load (year 1)", "kW", "", "Load", "", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "bill_load", "Bill load (year 1)", "kWh", "", "Load", "*", "", ""),
    VarInfo(SSC_INPUT, SSC_NUMBER, "inflation_rate", "Inflation rate", "%", "", "Lifetime", "*", "MIN=-99", ""),
    VarInfo(SSC_INPUT, SSC_ARRAY, "degradation", "Annual energy degradation", "%", "", "System Output", "*", "", ""),
    VarInfo(SSC_INPUT, SSC_ARRAY, "load_escalation", "Annual load escalation", "%/year", "", "Load", "?=0", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "annual_energy_value", "Energy value in each year", "$", "", "Annual", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "annual_electric_load", "Electricity load total in each year", "kWh", "", "Annual", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "elec_cost_with_system", "Electricity bill with system", "$/yr", "", "Annual", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "elec_cost_without_system", "Electricity bill without system", "$/yr", "", "Annual", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_NUMBER, "elec_cost_with_system_year1", "Electricity bill with system (year 1)", "$/yr", "", "Financial Metrics", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_NUMBER, "elec_cost_without_system_year1", "Electricity bill without system (year 1)", "$/yr", "", "Financial Metrics", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_NUMBER, "savings_year1", "Electricity bill savings with system (year 1)", "$/yr", "", "Financial Metrics", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_NUMBER, "year1_electric_load", "Electricity load total (year 1)", "kWh/yr", "", "Financial Metrics", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_e_tofromgrid", "Electricity to/from grid (year 1 hourly)", "kWh", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_e_togrid", "Electricity to grid (year 1 hourly)", "kWh", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_e_fromgrid", "Electricity from grid (year 1 hourly)", "kWh", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_system_to_load", "Electricity from system to load (year 1 hourly)", "kWh", "", "", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "lifetime_load", "Lifetime electricity load", "kW", "", "Time Series", "system_use_lifetime_output=1", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_p_tofromgrid", "Electricity to/from grid peak (year 1 hourly)", "kW", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_p_system_to_load", "Electricity peak from system to load (year 1 hourly)", "kW", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_salespurchases_with_system", "Electricity sales/purchases with system (year 1 hourly)", "$", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_salespurchases_without_system", "Electricity sales/purchases without system (year 1 hourly)", "$", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_ec_with_system", "Energy charge with system (year 1 hourly)", "$", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_ec_without_system", "Energy charge without system (year 1 hourly)", "$", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_dc_with_system", "Demand charge with system (year 1 hourly)", "$", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_dc_without_system", "Demand charge without system (year 1 hourly)", "$", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_ec_tou_schedule", "TOU period for energy charges (year 1 hourly)", "", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_dc_tou_schedule", "TOU period for demand charges (year 1 hourly)", "", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_dc_peak_per_period", "Electricity peak from grid per TOU period (year 1 hourly)", "kW", "", "Time Series", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_fixed_with_system", "Fixed monthly charge with system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_fixed_without_system", "Fixed monthly charge without system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_minimum_with_system", "Minimum charge with system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_minimum_without_system", "Minimum charge without system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_dc_fixed_with_system", "Demand charge (flat) with system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_dc_tou_with_system", "Demand charge (TOU) with system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_ec_charge_with_system", "Energy charge with system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_dc_fixed_without_system", "Demand charge (flat) without system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_dc_tou_without_system", "Demand charge (TOU) without system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_ec_charge_without_system", "Energy charge without system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_load", "Electricity load", "kWh/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_peak_w_system", "Demand peak with system", "kW/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_peak_wo_system", "Demand peak without system", "kW/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_use_w_system", "Electricity use with system", "kWh/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_use_wo_system", "Electricity use without system", "kWh/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_electricity_to_grid", "Electricity to/from grid", "kWh/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_cumulative_excess_generation", "Net metering cumulative credit for annual true-up", "kWh/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_utility_bill_w_sys", "Electricity bill with system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_utility_bill_wo_sys", "Electricity bill without system", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "utility_bill_w_sys_ym", "Electricity bill with system", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "utility_bill_wo_sys_ym", "Electricity bill without system", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_fixed_ym", "Fixed monthly charge with system", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_fixed_ym", "Fixed monthly charge without system", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_minimum_ym", "Minimum charge with system", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_minimum_ym", "Minimum charge without system", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_dc_fixed_ym", "Demand charge with system (flat)", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_dc_tou_ym", "Demand charge with system (TOU)", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_dc_fixed_ym", "Demand charge without system (flat)", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_dc_tou_ym", "Demand charge without system (TOU)", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_ym", "Energy charge with system", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_ym", "Energy charge without system", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "utility_bill_w_sys", "Electricity bill with system", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "utility_bill_wo_sys", "Electricity bill without system", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_w_sys_fixed", "Fixed monthly charge with system", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_wo_sys_fixed", "Fixed monthly charge without system", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_w_sys_minimum", "Minimum charge with system", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_wo_sys_minimum", "Minimum charge without system", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_w_sys_dc_fixed", "Demand charge with system (flat)", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_w_sys_dc_tou", "Demand charge with system (TOU)", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_wo_sys_dc_fixed", "Demand charge without system (flat)", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_wo_sys_dc_tou", "Demand charge without system (TOU)", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_w_sys_ec", "Energy charge with system", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "charge_wo_sys_ec", "Energy charge without system", "$", "", "Charges by Month", "*", "", ""),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_gross_ym", "Energy charge with system before credits", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "nm_dollars_applied_ym", "Net metering credit", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "excess_kwhs_earned_ym", "Excess generation", "kWh", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "net_billing_credits_ym", "Net billing credit", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "two_meter_sales_ym", "Buy all sell all electricity sales to grid", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "true_up_credits_ym", "Net annual true-up payments", "$", "", "Charges by Month", "*", "", "COL_LABEL=MONTHS,FORMAT_SPEC=CURRENCY,GROUP=UR_AM"),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_ec_charge_gross_with_system", "Energy charge with system before credits", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_nm_dollars_applied", "Net metering credit", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_excess_kwhs_earned", "Excess generation", "kWh/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_net_billing_credits", "Net billing credit", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_two_meter_sales", "Buy all sell all electricity sales to grid", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_ARRAY, "year1_true_up_credits", "Net annual true-up payments", "$/mo", "", "Monthly", "*", "LENGTH=12", ""),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_jan_tp", "Energy charge without system Jan", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_feb_tp", "Energy charge without system Feb", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_mar_tp", "Energy charge without system Mar", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_apr_tp", "Energy charge without system Apr", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_may_tp", "Energy charge without system May", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_jun_tp", "Energy charge without system Jun", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_jul_tp", "Energy charge without system Jul", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_aug_tp", "Energy charge without system Aug", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_sep_tp", "Energy charge without system Sep", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_oct_tp", "Energy charge without system Oct", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_nov_tp", "Energy charge without system Nov", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_wo_sys_ec_dec_tp", "Energy charge without system Dec", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_jan_tp", "Electricity usage without system Jan", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_feb_tp", "Electricity usage without system Feb", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_mar_tp", "Electricity usage without system Mar", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_apr_tp", "Electricity usage without system Apr", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_may_tp", "Electricity usage without system May", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_jun_tp", "Electricity usage without system Jun", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_jul_tp", "Electricity usage without system Jul", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_aug_tp", "Electricity usage without system Aug", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_sep_tp", "Electricity usage without system Sep", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_oct_tp", "Electricity usage without system Oct", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_nov_tp", "Electricity usage without system Nov", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_wo_sys_ec_dec_tp", "Electricity usage without system Dec", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_jan_tp", "Energy charge with system Jan", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_feb_tp", "Energy charge with system Feb", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_mar_tp", "Energy charge with system Mar", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_apr_tp", "Energy charge with system Apr", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_may_tp", "Energy charge with system May", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_jun_tp", "Energy charge with system Jun", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_jul_tp", "Energy charge with system Jul", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_aug_tp", "Energy charge with system Aug", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_sep_tp", "Energy charge with system Sep", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_oct_tp", "Energy charge with system Oct", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_nov_tp", "Energy charge with system Nov", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "charge_w_sys_ec_dec_tp", "Energy charge with system Dec", "$", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_jan_tp", "Electricity usage with system Jan", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_feb_tp", "Electricity usage with system Feb", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_mar_tp", "Electricity usage with system Mar", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_apr_tp", "Electricity usage with system Apr", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_may_tp", "Electricity usage with system May", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_jun_tp", "Electricity usage with system Jun", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_jul_tp", "Electricity usage with system Jul", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_aug_tp", "Electricity usage with system Aug", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_sep_tp", "Electricity usage with system Sep", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_oct_tp", "Electricity usage with system Oct", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_nov_tp", "Electricity usage with system Nov", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "energy_w_sys_ec_dec_tp", "Electricity usage with system Dec", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_jan_tp", "Electricity exports with system Jan", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_feb_tp", "Electricity exports with system Feb", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_mar_tp", "Electricity exports with system Mar", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_apr_tp", "Electricity exports with system Apr", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_may_tp", "Electricity exports with system May", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_jun_tp", "Electricity exports with system Jun", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_jul_tp", "Electricity exports with system Jul", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_aug_tp", "Electricity exports with system Aug", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_sep_tp", "Electricity exports with system Sep", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_oct_tp", "Electricity exports with system Oct", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_nov_tp", "Electricity exports with system Nov", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "surplus_w_sys_ec_dec_tp", "Electricity exports with system Dec", "kWh", "", "Charges by Month", "*", "", "ROW_LABEL=UR_PERIODNUMS,COL_LABEL=UR_TIERNUMS,FORMAT_SPEC=CURRENCY,GROUP=UR_MTP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "monthly_tou_demand_peak_w_sys", "Demand peak with system", "kW", "", "Charges by Month", "", "", "ROW_LABEL=MONTHS,COL_LABEL=UR_MONTH_TOU_DEMAND,FORMAT_SPEC=CURRENCY,GROUP=UR_DMP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "monthly_tou_demand_peak_wo_sys", "Demand peak without system", "kW", "", "Charges by Month", "", "", "ROW_LABEL=MONTHS,COL_LABEL=UR_MONTH_TOU_DEMAND,FORMAT_SPEC=CURRENCY,GROUP=UR_DMP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "monthly_tou_demand_charge_w_sys", "Demand peak charge with system", "$", "", "Charges by Month", "", "", "ROW_LABEL=MONTHS,COL_LABEL=UR_MONTH_TOU_DEMAND,FORMAT_SPEC=CURRENCY,GROUP=UR_DMP"),
    VarInfo(SSC_OUTPUT, SSC_MATRIX, "monthly_tou_demand_charge_wo_sys", "Demand peak charge without system", "$", "", "Charges by Month", "", "", "ROW_LABEL=MONTHS,COL_LABEL=UR_MONTH_TOU_DEMAND,FORMAT_SPEC=CURRENCY,GROUP=UR_DMP"),
    var_info_invalid,
)

struct rate_setup:
    @staticmethod
    def setup(vt: var_table, num_recs_yearly: Int, nyears: Int, rate: rate_data, cm_name: String):
        var dc_enabled = vt.as_boolean("ur_dc_enable")
        rate.en_ts_buy_rate = vt.as_boolean("ur_en_ts_buy_rate")
        rate.en_ts_sell_rate = vt.as_boolean("ur_en_ts_sell_rate")
        var cnt: Int = 0
        var nrows, ncols, i: Int
        var parr = ssc_number_t*(0)
        var ts_sr: ssc_number_t* = None
        var ts_br: ssc_number_t* = None
        rate.init(num_recs_yearly)
        var inflation_rate = vt.as_double("inflation_rate") * 0.01
        var rate_scale = List[ssc_number_t](nyears)
        parr = vt.as_array("rate_escalation", caddress(cnt))
        if cnt == 1:
            for i in range(nyears):
                rate_scale[i] = ssc_number_t(math.pow(Float64(inflation_rate + 1 + parr[0] * 0.01), Float64(i)))
        elif cnt < nyears:
            throw exec_error("utilityrate5", "rate_escalation must have 1 entry or length equal to analysis_period")
        else:
            for i in range(nyears):
                rate_scale[i] = ssc_number_t(1 + parr[i] * 0.01)
        rate.rate_scale = rate_scale
        if rate.en_ts_buy_rate:
            if not vt.is_assigned("ur_ts_buy_rate"):
                throw exec_error("utilityrate5", util.format("Error in ur_ts_buy_rate. Time step buy rate enabled but no time step buy rates specified."))
            else:
                ts_br = vt.as_array("ur_ts_buy_rate", caddress(cnt))
                var ts_step_per_hour = cnt / 8760
                if ts_step_per_hour < 1 or ts_step_per_hour > 60 or ts_step_per_hour * 8760 != cnt:
                    throw exec_error("utilityrate5", util.format("number of buy rate records (%d) must be equal to number of gen records (%d) or 8760 for each year", Int(cnt), Int(rate.m_num_rec_yearly)))
        if rate.en_ts_sell_rate:
            if not vt.is_assigned("ur_ts_sell_rate"):
                throw exec_error(cm_name, util.format("Error in ur_ts_sell_rate. Time step sell rate enabled but no time step sell rates specified."))
            else:
                ts_sr = vt.as_array("ur_ts_sell_rate", caddress(cnt))
                var ts_step_per_hour = cnt / 8760
                if ts_step_per_hour < 1 or ts_step_per_hour > 60 or ts_step_per_hour * 8760 != cnt:
                    throw exec_error(cm_name, util.format("invalid number of sell rate records (%d): must be an integer multiple of 8760", Int(cnt)))
        rate.setup_time_series(cnt, ts_sr, ts_br)
        var ec_weekday = vt.as_matrix("ur_ec_sched_weekday", caddress(nrows), caddress(ncols))
        if nrows != 12 or ncols != 24:
            var ss = String()
            ss += "The weekday TOU matrix for energy rates should have 12 rows and 24 columns. Instead it has "
            ss += str(nrows) + " rows and " + str(ncols) + " columns."
            throw exec_error(cm_name, ss)
        var ec_weekend = vt.as_matrix("ur_ec_sched_weekend", caddress(nrows), caddress(ncols))
        if nrows != 12 or ncols != 24:
            var ss = String()
            ss += "The weekend TOU matrix for energy rates should have 12 rows and 24 columns. Instead it has "
            ss += str(nrows) + " rows and " + str(ncols) + " columns."
            throw exec_error(cm_name, ss)
        var ec_tou_in = vt.as_matrix("ur_ec_tou_mat", caddress(nrows), caddress(ncols))
        if ncols != 6:
            var ss = String()
            ss += "The energy rate table must have 6 columns. Instead it has " + str(ncols) + " columns."
            throw exec_error(cm_name, ss)
        var tou_rows = nrows
        var sell_eq_buy = vt.as_boolean("ur_sell_eq_buy")
        rate.setup_energy_rates(ec_weekday, ec_weekend, tou_rows, ec_tou_in, sell_eq_buy)
        var dc_weekday: ssc_number_t* = None
        var dc_weekend: ssc_number_t* = None
        var dc_tou_in: ssc_number_t* = None
        var dc_flat_in: ssc_number_t* = None
        var dc_tier_rows: Int = 0
        var dc_flat_rows: Int = 0
        if dc_enabled:
            dc_weekday = vt.as_matrix("ur_dc_sched_weekday", caddress(nrows), caddress(ncols))
            if nrows != 12 or ncols != 24:
                var ss = String()
                ss += "The weekday TOU matrix for demand rates should have 12 rows and 24 columns. Instead it has "
                ss += str(nrows) + " rows and " + str(ncols) + " columns."
                throw exec_error(cm_name, ss)
            dc_weekend = vt.as_matrix("ur_dc_sched_weekend", caddress(nrows), caddress(ncols))
            if nrows != 12 or ncols != 24:
                var ss = String()
                ss += "The weekend TOU matrix for demand rates should have 12 rows and 24 columns. Instead it has "
                ss += str(nrows) + " rows and " + str(ncols) + " columns."
                throw exec_error(cm_name, ss)
            dc_tou_in = vt.as_matrix("ur_dc_tou_mat", caddress(nrows), caddress(ncols))
            if ncols != 4:
                var ss = String()
                ss += "The demand rate table for TOU periods, 'ur_dc_tou_mat', must have 4 columns. Instead, it has " + str(ncols) + "columns."
                throw exec_error(cm_name, ss)
            dc_tier_rows = nrows
            dc_flat_in = vt.as_matrix("ur_dc_flat_mat", caddress(nrows), caddress(ncols))
            if ncols != 4:
                var ss = String()
                ss += "The demand rate table, 'ur_dc_flat_mat', by month must have 4 columns. Instead it has " + str(ncols) + " columns"
                throw exec_error(cm_name, ss)
            dc_flat_rows = nrows
            rate.setup_demand_charges(dc_weekday, dc_weekend, dc_tier_rows, dc_tou_in, dc_flat_rows, dc_flat_in)
        var metering_option = vt.as_integer("ur_metering_option")
        rate.enable_nm = (metering_option == 0 or metering_option == 1)
        rate.nm_credits_w_rollover = (vt.as_integer("ur_metering_option") == 0)
        rate.net_metering_credit_month = Int(vt.as_number("ur_nm_credit_month"))
        rate.nm_credit_sell_rate = vt.as_number("ur_nm_yearend_sell_rate")
        rate.init_energy_rates(False)  # TODO: update if rate forecast needs to support two meter

class cm_utilityrate5(compute_module):
    var rate: rate_data
    var m_num_rec_yearly: Int

    def __init__(self):
        self.rate = rate_data()
        self.m_num_rec_yearly = 8760  # will be overwritten
        self.add_var_info(vtab_utility_rate5)
        self.add_var_info(vtab_utility_rate_common)

    def exec(self):
        if self.is_assigned("en_electricity_rates"):
            if not self.as_boolean("en_electricity_rates"):
                self.remove_var_info(vtab_utility_rate5)
                return
        var parr: ssc_number_t* = 0
        var count, i, j: Int
        var nyears = Int(self.as_integer("analysis_period"))
        var scale_calculator = scalefactors(self.m_vartab)
        var sys_scale = List[ssc_number_t](nyears)
        if self.as_integer("system_use_lifetime_output") == 1:
            for i in range(nyears):
                sys_scale[i] = 1.0
        else:
            parr = self.as_array("degradation", caddress(count))
            if count == 1:
                for i in range(nyears):
                    sys_scale[i] = ssc_number_t(math.pow(Float64(1 - parr[0] * 0.01), Float64(i)))
            else:
                for i in range(min(nyears, count)):
                    sys_scale[i] = ssc_number_t(1.0 - parr[i] * 0.01)
        var load_scale = scale_calculator.get_factors("load_escalation")
        # Update all e_sys and e_load values based on new inputs...
        var pload: ssc_number_t* = None
        var pgen: ssc_number_t* = None
        var nrec_load: Int = 0
        var nrec_gen: Int = 0
        var step_per_hour_gen: Int = 1
        var step_per_hour_load: Int = 1
        var bload = False
        pgen = self.as_array("gen", caddress(nrec_gen))
        var nrec_gen_per_year = nrec_gen
        if self.as_integer("system_use_lifetime_output") == 1:
            nrec_gen_per_year = nrec_gen // nyears
        step_per_hour_gen = nrec_gen_per_year // 8760
        if step_per_hour_gen < 1 or step_per_hour_gen > 60 or step_per_hour_gen * 8760 != nrec_gen_per_year:
            throw exec_error("utilityrate5", util.format("invalid number of gen records (%d): must be an integer multiple of 8760", Int(nrec_gen_per_year)))
        var ts_hour_gen = 1.0 / step_per_hour_gen
        self.m_num_rec_yearly = nrec_gen_per_year
        if self.is_assigned("load"):
            bload = True
            pload = self.as_array("load", caddress(nrec_load))
            step_per_hour_load = nrec_load // 8760
            if step_per_hour_load < 1 or step_per_hour_load > 60 or step_per_hour_load * 8760 != nrec_load:
                throw exec_error("utilityrate5", util.format("invalid number of load records (%d): must be an integer multiple of 8760", Int(nrec_load)))
            if (nrec_load != self.m_num_rec_yearly) and (nrec_load != 8760):
                throw exec_error("utilityrate5", util.format("number of load records (%d) must be equal to number of gen records (%d) or 8760 for each year", Int(nrec_load), Int(self.m_num_rec_yearly)))
        var e_sys_cy = List[ssc_number_t](self.m_num_rec_yearly)
        var p_sys_cy = List[ssc_number_t](self.m_num_rec_yearly)
        var p_load = List[ssc_number_t](self.m_num_rec_yearly)
        var e_grid_cy = List[ssc_number_t](self.m_num_rec_yearly)
        var p_grid_cy = List[ssc_number_t](self.m_num_rec_yearly)
        var e_load_cy = List[ssc_number_t](self.m_num_rec_yearly)
        var p_load_cy = List[ssc_number_t](self.m_num_rec_yearly)
        var idx: Int = 0
        var ts_load: ssc_number_t = 0
        var year1_elec_load: ssc_number_t = 0
        idx = 0
        for i in range(8760):
            for ii in range(step_per_hour_gen):
                var ndx = i * step_per_hour_gen + ii
                ts_load = ssc_number_t(-pload[idx]) if bload and idx < nrec_load else 0.0
                year1_elec_load += ts_load
                p_load[ndx] = -ts_load
                if step_per_hour_gen == step_per_hour_load:
                    idx += 1
                elif ii == (step_per_hour_gen - 1):
                    idx += 1
        self.assign("year1_electric_load", year1_elec_load * ts_hour_gen)
        # allocate intermediate data arrays
        var revenue_w_sys = List[ssc_number_t](self.m_num_rec_yearly)
        var revenue_wo_sys = List[ssc_number_t](self.m_num_rec_yearly)
        var payment = List[ssc_number_t](self.m_num_rec_yearly)
        var income = List[ssc_number_t](self.m_num_rec_yearly)
        var demand_charge_w_sys = List[ssc_number_t](self.m_num_rec_yearly)
        var energy_charge_w_sys = List[ssc_number_t](self.m_num_rec_yearly)
        var energy_charge_gross_w_sys = List[ssc_number_t](self.m_num_rec_yearly)
        var demand_charge_wo_sys = List[ssc_number_t](self.m_num_rec_yearly)
        var energy_charge_wo_sys = List[ssc_number_t](self.m_num_rec_yearly)
        var ec_tou_sched = List[ssc_number_t](self.m_num_rec_yearly)
        var dc_tou_sched = List[ssc_number_t](self.m_num_rec_yearly)
        var load = List[ssc_number_t](self.m_num_rec_yearly)
        var e_tofromgrid = List[ssc_number_t](self.m_num_rec_yearly)
        var p_tofromgrid = List[ssc_number_t](self.m_num_rec_yearly)
        var salespurchases = List[ssc_number_t](self.m_num_rec_yearly)
        var monthly_revenue_w_sys = List[ssc_number_t](12)
        var monthly_revenue_wo_sys = List[ssc_number_t](12)
        var monthly_fixed_charges = List[ssc_number_t](12)
        var monthly_minimum_charges = List[ssc_number_t](12)
        var monthly_ec_charges = List[ssc_number_t](12)
        var monthly_ec_charges_gross = List[ssc_number_t](12)
        var monthly_nm_dollars_applied = List[ssc_number_t](12)
        var monthly_excess_dollars_earned = List[ssc_number_t](12)
        var monthly_excess_kwhs_earned = List[ssc_number_t](12)
        var monthly_net_billing_credits = List[ssc_number_t](12)
        var monthly_ec_rates = List[ssc_number_t](12)
        var monthly_salespurchases = List[ssc_number_t](12)
        var monthly_load = List[ssc_number_t](12)
        var monthly_system_generation = List[ssc_number_t](12)
        var monthly_elec_to_grid = List[ssc_number_t](12)
        var monthly_elec_needed_from_grid = List[ssc_number_t](12)
        var monthly_cumulative_excess_energy = List[ssc_number_t](12)
        var monthly_cumulative_excess_dollars = List[ssc_number_t](12)
        var monthly_bill = List[ssc_number_t](12)
        var monthly_peak = List[ssc_number_t](12)
        var monthly_test = List[ssc_number_t](12)
        var monthly_two_meter_sales = List[ssc_number_t](12)
        var monthly_true_up_credits = List[ssc_number_t](12)
        # allocate outputs
        var annual_net_revenue = self.allocate("annual_energy_value", nyears + 1)
        var annual_electric_load = self.allocate("annual_electric_load", nyears + 1)
        var energy_net = self.allocate("scaled_annual_energy", nyears + 1)
        var annual_revenue_w_sys = self.allocate("revenue_with_system", nyears + 1)
        var annual_revenue_wo_sys = self.allocate("revenue_without_system", nyears + 1)
        var annual_elec_cost_w_sys = self.allocate("elec_cost_with_system", nyears + 1)
        var annual_elec_cost_wo_sys = self.allocate("elec_cost_without_system", nyears + 1)
        var utility_bill_w_sys_ym = self.allocate("utility_bill_w_sys_ym", nyears + 1, 12)
        var utility_bill_wo_sys_ym = self.allocate("utility_bill_wo_sys_ym", nyears + 1, 12)
        var ch_w_sys_dc_fixed_ym = self.allocate("charge_w_sys_dc_fixed_ym", nyears + 1, 12)
        var ch_w_sys_dc_tou_ym = self.allocate("charge_w_sys_dc_tou_ym", nyears + 1, 12)
        var ch_w_sys_ec_ym = self.allocate("charge_w_sys_ec_ym", nyears + 1, 12)
        var ch_w_sys_ec_gross_ym = self.allocate("charge_w_sys_ec_gross_ym", nyears + 1, 12)
        var nm_dollars_applied_ym = self.allocate("nm_dollars_applied_ym", nyears + 1, 12)
        var excess_kwhs_earned_ym = self.allocate("excess_kwhs_earned_ym", nyears + 1, 12)
        var net_billing_credits_ym = self.allocate("net_billing_credits_ym", nyears + 1, 12)
        var two_meter_sales_ym = self.allocate("two_meter_sales_ym", nyears + 1, 12)
        var true_up_credits_ym = self.allocate("true_up_credits_ym", nyears + 1, 12)
        var ch_wo_sys_dc_fixed_ym = self.allocate("charge_wo_sys_dc_fixed_ym", nyears + 1, 12)
        var ch_wo_sys_dc_tou_ym = self.allocate("charge_wo_sys_dc_tou_ym", nyears + 1, 12)
        var ch_wo_sys_ec_ym = self.allocate("charge_wo_sys_ec_ym", nyears + 1, 12)
        var ch_w_sys_fixed_ym = self.allocate("charge_w_sys_fixed_ym", nyears + 1, 12)
        var ch_wo_sys_fixed_ym = self.allocate("charge_wo_sys_fixed_ym", nyears + 1, 12)
        var ch_w_sys_minimum_ym = self.allocate("charge_w_sys_minimum_ym", nyears + 1, 12)
        var ch_wo_sys_minimum_ym = self.allocate("charge_wo_sys_minimum_ym", nyears + 1, 12)
        var utility_bill_w_sys = self.allocate("utility_bill_w_sys", nyears + 1)
        var utility_bill_wo_sys = self.allocate("utility_bill_wo_sys", nyears + 1)
        var ch_w_sys_dc_fixed = self.allocate("charge_w_sys_dc_fixed", nyears + 1)
        var ch_w_sys_dc_tou = self.allocate("charge_w_sys_dc_tou", nyears + 1)
        var ch_w_sys_ec = self.allocate("charge_w_sys_ec", nyears + 1)
        var ch_wo_sys_dc_fixed = self.allocate("charge_wo_sys_dc_fixed", nyears + 1)
        var ch_wo_sys_dc_tou = self.allocate("charge_wo_sys_dc_tou", nyears + 1)
        var ch_wo_sys_ec = self.allocate("charge_wo_sys_ec", nyears + 1)
        var ch_w_sys_fixed = self.allocate("charge_w_sys_fixed", nyears + 1)
        var ch_wo_sys_fixed = self.allocate("charge_wo_sys_fixed", nyears + 1)
        var ch_w_sys_minimum = self.allocate("charge_w_sys_minimum", nyears + 1)
        var ch_wo_sys_minimum = self.allocate("charge_wo_sys_minimum", nyears + 1)
        var year1_hourly_e_togrid = self.allocate("year1_hourly_e_togrid", self.m_num_rec_yearly)
        var year1_hourly_e_fromgrid = self.allocate("year1_hourly_e_fromgrid", self.m_num_rec_yearly)
        rate_setup.setup(self.m_vartab, Int(self.m_num_rec_yearly), Int(nyears), self.rate, "utilityrate5")
        var jan_rows = self.rate.m_month[0].ec_charge.nrows() + 2
        var jan_cols = self.rate.m_month[0].ec_charge.ncols() + 2
        var feb_rows = self.rate.m_month[1].ec_charge.nrows() + 2
        var feb_cols = self.rate.m_month[1].ec_charge.ncols() + 2
        var mar_rows = self.rate.m_month[2].ec_charge.nrows() + 2
        var mar_cols = self.rate.m_month[2].ec_charge.ncols() + 2
        var apr_rows = self.rate.m_month[3].ec_charge.nrows() + 2
        var apr_cols = self.rate.m_month[3].ec_charge.n