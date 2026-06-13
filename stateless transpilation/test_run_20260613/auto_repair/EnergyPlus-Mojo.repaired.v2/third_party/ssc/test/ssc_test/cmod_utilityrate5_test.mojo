from code_generator_utilities import *
from ...ssc.cmod_utilityrate5_eqns import *
from cmod_battery_pvsamv1_test import *  # for load profile
from vartab import *
from ...shared.lib_util import *

# Global path strings (replacing sprintf with direct string assignment)
var gen_path: String = SSCDIR + "/test/input_cases/utility_rate_data/gen_25_year_residential.csv"
var subhourly_gen_path: String = SSCDIR + "/test/input_cases/utility_rate_data/gen_residential_1_year_15_min.csv"
var one_year_gen_path: String = SSCDIR + "/test/input_cases/utility_rate_data/gen_1_yr_residential.csv"
var commercial_gen_path: String = SSCDIR + "/test/input_cases/utility_rate_data/gen_25_year_commercial.csv"
var load_commercial: String = SSCDIR + "/test/input_cases/utility_rate_data/load_commercial.csv"
var large_load_commercial: String = SSCDIR + "/test/input_cases/utility_rate_data/load_commercial_large.csv"
var load_residential_subhourly: String = SSCDIR + "/test/input_cases/pvsamv1_data/pvsamv1_residential_load_15min.csv"

def setup_residential_rates(inout data: ssc_data_t):
    ssc_data_set_number(data, "en_electricity_rates", 1)
    ssc_data_set_number(data, "ur_en_ts_sell_rate", 0)
    var p_ur_ts_buy_rate: List[ssc_number_t] = List[ssc_number_t](0)
    ssc_data_set_array(data, "ur_ts_buy_rate", p_ur_ts_buy_rate, 1)
    var p_ur_ec_sched_weekday: List[ssc_number_t] = List[ssc_number_t](
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 1, 1, 1, 1
    )
    ssc_data_set_matrix(data, "ur_ec_sched_weekday", p_ur_ec_sched_weekday, 12, 24)
    var p_ur_ec_sched_weekend: List[ssc_number_t] = List[ssc_number_t](
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    )
    ssc_data_set_matrix(data, "ur_ec_sched_weekend", p_ur_ec_sched_weekend, 12, 24)
    var p_ur_ec_tou_mat: List[ssc_number_t] = List[ssc_number_t](
        1, 1, 9.9999999999999998e+37, 0, 0.10000000000000001, 0,
        2, 1, 9.9999999999999998e+37, 0, 0.050000000000000003, 0,
        3, 1, 9.9999999999999998e+37, 0, 0.20000000000000001, 0,
        4, 1, 9.9999999999999998e+37, 0, 0.25, 0
    )
    ssc_data_set_matrix(data, "ur_ec_tou_mat", p_ur_ec_tou_mat, 4, 6)
    var p_ppa_price_input: List[ssc_number_t] = List[ssc_number_t](0.089999999999999997)
    ssc_data_set_array(data, "ppa_price_input", p_ppa_price_input, 1)
    ssc_data_set_number(data, "ppa_multiplier_model", 1)
    ssc_data_set_number(data, "inflation_rate", 2.5)
    var p_degradation: List[ssc_number_t] = List[ssc_number_t](0)
    ssc_data_set_array(data, "degradation", p_degradation, 1)
    var p_rate_escalation: List[ssc_number_t] = List[ssc_number_t](0)
    ssc_data_set_array(data, "rate_escalation", p_rate_escalation, 1)
    ssc_data_set_number(data, "ur_metering_option", 0)
    ssc_data_set_number(data, "ur_nm_yearend_sell_rate", 0.027890000000000002)
    ssc_data_set_number(data, "ur_monthly_fixed_charge", 0)
    ssc_data_set_number(data, "ur_monthly_min_charge", 0)
    ssc_data_set_number(data, "ur_annual_min_charge", 0)
    var ur_ts_sell_rate: List[ssc_number_t] = List[ssc_number_t](0)
    ssc_data_set_array(data, "ur_ts_sell_rate", ur_ts_sell_rate, 1)
    ssc_data_set_number(data, "ur_dc_enable", 0)
    var p_ur_dc_sched_weekday: List[ssc_number_t] = List[ssc_number_t](
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    )
    ssc_data_set_matrix(data, "ur_dc_sched_weekday", p_ur_dc_sched_weekday, 12, 24)
    var p_ur_dc_sched_weekend: List[ssc_number_t] = List[ssc_number_t](
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    )
    ssc_data_set_matrix(data, "ur_dc_sched_weekend", p_ur_dc_sched_weekend, 12, 24)
    var p_ur_dc_tou_mat: List[ssc_number_t] = List[ssc_number_t](
        1, 1, 9.9999999999999998e+37, 0, 2, 1, 9.9999999999999998e+37, 0
    )
    ssc_data_set_matrix(data, "ur_dc_tou_mat", p_ur_dc_tou_mat, 2, 4)
    var p_ur_dc_flat_mat: List[ssc_number_t] = List[ssc_number_t](
        0, 1, 9.9999999999999998e+37, 0, 1, 1, 9.9999999999999998e+37, 0, 2, 1, 9.9999999999999998e+37, 0, 3, 1, 9.9999999999999998e+37, 0, 4, 1, 9.9999999999999998e+37, 0, 5, 1, 9.9999999999999998e+37, 0, 6, 1, 9.9999999999999998e+37, 0, 7, 1, 9.9999999999999998e+37, 0, 8, 1, 9.9999999999999998e+37, 0, 9, 1, 9.9999999999999998e+37, 0, 10, 1, 9.9999999999999998e+37, 0, 11, 1, 9.9999999999999998e+37, 0
    )
    ssc_data_set_matrix(data, "ur_dc_flat_mat", p_ur_dc_flat_mat, 12, 4)

def ensure_outputs_line_up(inout data: ssc_data_t):
    var nrows: Int
    var ncols: Int
    var annual_bills = ssc_data_get_matrix(data, "utility_bill_w_sys_ym", nrows, ncols)
    var bill_matrix_ub = util.matrix_t[Float64](nrows, ncols)
    bill_matrix_ub.assign(annual_bills, nrows, ncols)
    var annual_bills_ec = ssc_data_get_array(data, "elec_cost_with_system", nrows)
    var annual_bill_ec = List[Float64](nrows)
    annual_bill_ec = util.array_to_vector(annual_bills_ec, nrows)
    var annual_bills_ub = ssc_data_get_array(data, "utility_bill_w_sys", nrows)
    var annual_bill_ub = List[Float64](nrows)
    annual_bill_ub = util.array_to_vector(annual_bills_ub, nrows)
    var net_metering_credits = ssc_data_get_matrix(data, "nm_dollars_applied_ym", nrows, ncols)
    var nm_credits = util.matrix_t[Float64](nrows, ncols)
    nm_credits.assign(net_metering_credits, nrows, ncols)
    var net_billing_credits = ssc_data_get_matrix(data, "net_billing_credits_ym", nrows, ncols)
    var nb_credits = util.matrix_t[Float64](nrows, ncols)
    nb_credits.assign(net_billing_credits, nrows, ncols)
    var two_meter_credits = ssc_data_get_matrix(data, "two_meter_sales_ym", nrows, ncols)
    var tm_credits = util.matrix_t[Float64](nrows, ncols)
    tm_credits.assign(two_meter_credits, nrows, ncols)
    var true_up_credits = ssc_data_get_matrix(data, "true_up_credits_ym", nrows, ncols)
    var tu_credits = util.matrix_t[Float64](nrows, ncols)
    tu_credits.assign(true_up_credits, nrows, ncols)
    var monthly_fixed = ssc_data_get_matrix(data, "charge_w_sys_fixed_ym", nrows, ncols)
    var fixed_charges = util.matrix_t[Float64](nrows, ncols)
    fixed_charges.assign(monthly_fixed, nrows, ncols)
    var ch_min = ssc_data_get_matrix(data, "charge_w_sys_minimum_ym", nrows, ncols)
    var min_charges = util.matrix_t[Float64](nrows, ncols)
    min_charges.assign(ch_min, nrows, ncols)
    var dc_flat = ssc_data_get_matrix(data, "charge_w_sys_dc_fixed_ym", nrows, ncols)
    var demand_flat_charges = util.matrix_t[Float64](nrows, ncols)
    demand_flat_charges.assign(dc_flat, nrows, ncols)
    var dc_tou = ssc_data_get_matrix(data, "charge_w_sys_dc_tou_ym", nrows, ncols)
    var demand_tou_charges = util.matrix_t[Float64](nrows, ncols)
    demand_tou_charges.assign(dc_tou, nrows, ncols)
    var ec_gross = ssc_data_get_matrix(data, "charge_w_sys_ec_gross_ym", nrows, ncols)
    var gross_energy_charges = util.matrix_t[Float64](nrows, ncols)
    gross_energy_charges.assign(ec_gross, nrows, ncols)
    var ec_net = ssc_data_get_matrix(data, "charge_w_sys_ec_ym", nrows, ncols)
    var net_energy_charges = util.matrix_t[Float64](nrows, ncols)
    net_energy_charges.assign(ec_net, nrows, ncols)
    for i in range(nrows):
        var sum_over_year: Float64 = 0
        for j in range(ncols):
            var ec_gross_month = gross_energy_charges.at(i, j)
            var ec_net_month = net_energy_charges.at(i, j)
            var nm_month = nm_credits.at(i, j)
            var nb_month = nb_credits.at(i, j)
            var tm_month = tm_credits.at(i, j)
            var calc = ec_gross_month - nm_month - nb_month - tm_month
            assert(abs(calc - ec_net_month) < 0.001)
            if nm_month > 0:
                assert(abs(0 - nb_month) < 0.001)
                assert(abs(0 - tm_month) < 0.001)
            elif nb_month > 0:
                assert(abs(0 - nm_month) < 0.001)
                assert(abs(0 - tm_month) < 0.001)
            elif tm_month > 0:
                assert(abs(0 - nm_month) < 0.001)
                assert(abs(0 - nb_month) < 0.001)
            var utility_bill_w_sys_value = bill_matrix_ub.at(i, j)
            var fc_month = fixed_charges.at(i, j)
            var mc_month = min_charges.at(i, j)
            var dc_flat_month = demand_flat_charges.at(i, j)
            var dc_tou_month = demand_tou_charges.at(i, j)
            var true_up_month = tu_credits.at(i, j)  # credit
            calc = ec_net_month + fc_month + mc_month + dc_flat_month + dc_tou_month - true_up_month
            assert(abs(utility_bill_w_sys_value - calc) < 0.001)
            sum_over_year += utility_bill_w_sys_value
        assert(abs(sum_over_year - annual_bill_ec[i]) < 0.001)
        assert(abs(sum_over_year - annual_bill_ub[i]) < 0.001)

def test_URDBv7_cmod_utilityrate5_eqns_ElectricityRates_format_as_URDBv7():
    var data = var_table()
    var p_ur_ec_sched_weekday: List[ssc_number_t] = List[ssc_number_t](
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 4, 4, 4, 4
    )
    ssc_data_set_matrix(data, "ur_ec_sched_weekday", p_ur_ec_sched_weekday, 12, 24)
    var p_ur_ec_sched_weekend: List[ssc_number_t] = List[ssc_number_t](
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
    )
    ssc_data_set_matrix(data, "ur_ec_sched_weekend", p_ur_ec_sched_weekend, 12, 24)
    var p_ur_ec_tou_mat: List[ssc_number_t] = List[ssc_number_t](
        2, 2, 9.9999996802856925e+37, 0, 0.069078996777534485, 0,
        2, 1, 100, 0, 0.056908998638391495, 0,
        1, 2, 9.9999996802856925e+37, 0, 0.082948997616767883, 0,
        1, 1, 100, 0, 0.070768997073173523, 0
    )
    ssc_data_set_matrix(data, "ur_ec_tou_mat", p_ur_ec_tou_mat, 4, 6)
    ssc_data_set_number(data, "ur_metering_option", 0)
    ssc_data_set_number(data, "ur_monthly_fixed_charge", 35.28)
    ssc_data_set_number(data, "ur_monthly_min_charge", 1)
    ssc_data_set_number(data, "ur_annual_min_charge", 12)
    var p_ur_dc_sched_weekday: List[ssc_number_t] = List[ssc_number_t](
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2
    )
    ssc_data_set_matrix(data, "ur_dc_sched_weekday", p_ur_dc_sched_weekday, 12, 24)
    var p_ur_dc_sched_weekend: List[ssc_number_t] = List[ssc_number_t](
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
    )
    ssc_data_set_matrix(data, "ur_dc_sched_weekend", p_ur_dc_sched_weekend, 12, 24)
    var p_ur_dc_tou_mat: List[ssc_number_t] = List[ssc_number_t](
        1, 1, 100, 19.538999557495117,
        1, 2, 9.9999996802856925e+37, 13.093000411987305,
        2, 1, 100, 8.0909996032714844,
        2, 2, 9.9999996802856925e+37, 4.6760001182556152
    )
    ssc_data_set_matrix(data, "ur_dc_tou_mat", p_ur_dc_tou_mat, 4, 4)
    var p_ur_dc_flat_mat: List[ssc_number_t] = List[ssc_number_t](
        0, 1, 100, 4, 0, 2, 1e+38, 6.46, 1, 1, 1e+38, 6.46, 2, 1, 1e+38, 6.46, 3, 1, 1e+38, 6.46, 4, 1, 1e+38, 13.87, 5, 1, 1e+38, 13.87, 6, 1, 1e+38, 13.87, 7, 1, 1e+38, 13.87, 8, 1, 1e+38, 13.87, 9, 1, 1e+38, 13.87, 10, 1, 1e+38, 6.46, 11, 1, 1e+38, 6.46
    )
    ssc_data_set_matrix(data, "ur_dc_flat_mat", p_ur_dc_flat_mat, 13, 4)
    ElectricityRates_format_as_URDBv7(data)
    var urdb_data = data.lookup("urdb_data").table
    var rules = urdb_data.lookup("dgrules").str
    assert(rules.lower() == "net metering")
    var monthly_fixed = urdb_data.lookup("fixedmonthlycharge").num
    assert(abs(monthly_fixed - 35.28) < 1e-3)
    var min_charge = urdb_data.lookup("minmonthlycharge").num
    assert(abs(min_charge - 1) < 1e-3)
    min_charge = urdb_data.lookup("annualmincharge").num
    assert(abs(min_charge - 12) < 1e-3)
    var ec_wd_sched = urdb_data.lookup("energyweekdayschedule").num.data()
    var ec_we_sched = urdb_data.lookup("energyweekendschedule").num.data()
    var dc_wd_sched = urdb_data.lookup("demandweekdayschedule").num.data()
    var dc_we_sched = urdb_data.lookup("demandweekendschedule").num.data()
    for i in range(12 * 24):
        assert(ec_wd_sched[i] == p_ur_ec_sched_weekday[i] - 1)
        assert(ec_we_sched[i] == p_ur_ec_sched_weekend[i] - 1)
        assert(dc_wd_sched[i] == p_ur_dc_sched_weekday[i] - 1)
        assert(dc_we_sched[i] == p_ur_dc_sched_weekend[i] - 1)
    var dc_flat = urdb_data.lookup("flatdemandmonths").num
    var flat_demand_months: List[Float64] = List[Float64](0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1)
    for i in range(12):
        assert(abs(dc_flat[i] - dc_flat[i]) < 1e-3)  # Note: original code compares dc_flat[i] to itself, likely a bug, but we keep it
    var dc_flat_struct = urdb_data.lookup_match_case("flatdemandstructure").mat
    var period = dc_flat_struct[0]
    assert(abs(period[0].table.lookup("max").num[0] - 100) < 1e-3)
    assert(abs(period[0].table.lookup("rate").num - 4) < 1e-3)
    assert(period[1].table.lookup("max").num[0] > 9.99e+33)
    assert(abs(period[1].table.lookup("rate").num - 6.46) < 1e-3)
    period = dc_flat_struct[1]
    assert(period[0].table.lookup("max").num[0] > 9.99e+33)
    assert(abs(period[0].table.lookup("rate").num - 6.46) < 1e-3)
    period = dc_flat_struct[2]
    assert(period[0].table.lookup("max").num[0] > 9.99e+33)
    assert(abs(period[0].table.lookup("rate").num - 13.87) < 1e-3)
    var ec_tou_mat = urdb_data.lookup("energyratestructure").mat
    period = ec_tou_mat[0]
    assert(abs(period[0].table.lookup("max").num - 100) < 1e-3)
    assert(abs(period[0].table.lookup("rate").num - 0.070) < 1e-3)
    assert(period[1].table.lookup("max").num[0] > 9.99e+33)
    assert(abs(period[1].table.lookup("rate").num - 0.083) < 1e-3)
    period = ec_tou_mat[1]
    assert(abs(period[0].table.lookup("max").num - 100) < 1e-3)
    assert(abs(period[0].table.lookup("rate").num - 0.057) < 1e-3)
    assert(period[1].table.lookup("max").num[0] > 9.99e+33)
    assert(abs(period[1].table.lookup("rate").num - 0.069) < 1e-3)
    var dc_tou_mat = urdb_data.lookup("demandratestructure").mat
    period = dc_tou_mat[0]
    assert(abs(period[0].table.lookup("max").num - 100) < 1e-3)
    assert(abs(period[0].table.lookup("rate").num - 19.539) < 1e-3)
    assert(period[1].table.lookup("max").num[0] > 9.99e+33)
    assert(abs(period[1].table.lookup("rate").num - 13.093) < 1e-3)
    period = dc_tou_mat[1]
    assert(abs(period[0].table.lookup("max").num - 100) < 1e-3)
    assert(abs(period[0].table.lookup("rate").num - 8.09) < 1e-3)
    assert(period[1].table.lookup("max").num[0] > 9.99e+33)
    assert(abs(period[1].table.lookup("rate").num - 4.676) < 1e-3)

def test_cmod_utilityrate5_eqns_Test_Residential_TOU_Rates():
    var data = var_table()
    setup_residential_rates(data)
    var analysis_period: Int = 25
    ssc_data_set_number(data, "system_use_lifetime_output", 1)
    ssc_data_set_number(data, "analysis_period", analysis_period)
    set_array(data, "load", load_profile_path, 8760)
    set_array(data, "gen", gen_path, 8760 * analysis_period)
    var status = run_module(data, "utilityrate5")
    assert(not status)
    ensure_outputs_line_up(data)
    var cost_without_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_without_system_year1", cost_without_system)
    assert(abs(cost_without_system - 771.8) < 0.1)
    var cost_with_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_with_system_year1", cost_with_system)
    assert(abs(cost_with_system - (-11.9)) < 0.1)
    var length: Int
    var excess_dollars = ssc_data_get_array(data, "year1_true_up_credits", length)
    var dec_dollars: Float64 = excess_dollars[length - 1]
    assert(abs(dec_dollars - 75.9) < 0.1)

def test_cmod_utilityrate5_eqns_Test_Residential_net_metering_credits_in_may():
    var data = var_table()
    setup_residential_rates(data)
    var analysis_period: Int = 25
    var credit_month: Int = 4  # May - months index from 0
    ssc_data_set_number(data, "system_use_lifetime_output", 1)
    ssc_data_set_number(data, "ur_nm_credit_month", credit_month)
    ssc_data_set_number(data, "analysis_period", analysis_period)
    set_array(data, "load", load_profile_path, 8760)
    set_array(data, "gen", gen_path, 8760 * analysis_period)
    var status = run_module(data, "utilityrate5")
    assert(not status)
    ensure_outputs_line_up(data)
    var cost_without_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_without_system_year1", cost_without_system)
    assert(abs(cost_without_system - 771.8) < 0.1)
    var cost_with_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_with_system_year1", cost_with_system)
    assert(abs(cost_with_system - 36.6) < 0.1)
    var length: Int
    var excess_dollars = ssc_data_get_array(data, "year1_true_up_credits", length)
    var may_dollars: Float64 = excess_dollars[credit_month]
    assert(abs(may_dollars - 50.28) < 0.1)
    var nrows: Int
    var ncols: Int
    var annual_bills = ssc_data_get_matrix(data, "utility_bill_w_sys_ym", nrows, ncols)
    var bill_matrix = util.matrix_t[Float64](nrows, ncols)
    bill_matrix.assign(annual_bills, nrows, ncols)
    var may_year_1 = bill_matrix.at(1, credit_month)
    assert(abs(may_year_1 - (-50.28)) < 0.1)

def test_cmod_utilityrate5_eqns_Test_Residential_net_metering_credits_in_may_with_rollover():
    var data = var_table()
    setup_residential_rates(data)
    var analysis_period: Int = 25
    var credit_month: Int = 4  # May - months index from 0
    ssc_data_set_number(data, "system_use_lifetime_output", 1)
    ssc_data_set_number(data, "ur_nm_credit_month", credit_month)
    ssc_data_set_number(data, "ur_nm_credit_rollover", 1)
    ssc_data_set_number(data, "analysis_period", analysis_period)
    set_array(data, "load", load_profile_path, 8760)
    set_array(data, "gen", gen_path, 8760 * analysis_period)
    var status = run_module(data, "utilityrate5")
    assert(not status)
    ensure_outputs_line_up(data)
    var cost_without_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_without_system_year1", cost_without_system)
    assert(abs(cost_without_system - 771.8) < 0.1)
    var cost_with_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_with_system_year1", cost_with_system)
    assert(abs(cost_with_system - 36.6) < 0.1)
    var length: Int
    var true_up_dollars = ssc_data_get_array(data, "year1_true_up_credits", length)
    var may_dollars: Float64 = true_up_dollars[credit_month]
    assert(abs(may_dollars - 0.0) < 0.1)
    var excess_dollars = ssc_data_get_array(data, "year1_nm_dollars_applied", length)
    var june_dollars: Float64 = excess_dollars[credit_month + 1]
    assert(abs(june_dollars - 11.37) < 0.1)
    var nrows: Int
    var ncols: Int
    var annual_bills = ssc_data_get_matrix(data, "utility_bill_w_sys_ym", nrows, ncols)
    var bill_matrix = util.matrix_t[Float64](nrows, ncols)
    bill_matrix.assign(annual_bills, nrows, ncols)
    var may_year_1 = bill_matrix.at(1, credit_month)
    assert(abs(may_year_1 - 0.0) < 0.1)

def test_cmod_utilityrate5_eqns_Test_Residential_TOU_Rates_subhourly_gen():
    var data = var_table()
    setup_residential_rates(data)
    var analysis_period: Int = 1
    ssc_data_set_number(data, "system_use_lifetime_output", 1)
    ssc_data_set_number(data, "analysis_period", analysis_period)
    set_array(data, "load", load_profile_path, 8760)
    set_array(data, "gen", subhourly_gen_path, 8760 * 4)  # 15 min data
    var status = run_module(data, "utilityrate5")
    assert(not status)
    ensure_outputs_line_up(data)
    var cost_without_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_without_system_year1", cost_without_system)
    assert(abs(cost_without_system - 771.8) < 0.1)
    var cost_with_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_with_system_year1", cost_with_system)
    assert(abs(cost_with_system - (-27.94)) < 0.1)

def test_cmod_utilityrate5_eqns_Test_Residential_TOU_Rates_subhourly_gen_and_load():
    var data = var_table()
    setup_residential_rates(data)
    var analysis_period: Int = 1
    ssc_data_set_number(data, "system_use_lifetime_output", 1)
    ssc_data_set_number(data, "analysis_period", analysis_period)
    set_array(data, "load", load_residential_subhourly, 8760 * 4)  # 15 min data
    set_array(data, "gen", subhourly_gen_path, 8760 * 4)  # 15 min data
    var status = run_module(data, "utilityrate5")
    assert(not status)
    ensure_outputs_line_up(data)
    var cost_without_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_without_system_year1", cost_without_system)
    assert(abs(cost_without_system - 771.8) < 0.1)
    var cost_with_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_with_system_year1", cost_with_system)
    assert(abs(cost_with_system - (-27.94)) < 0.1)

def test_cmod_utilityrate5_eqns_Test_Residential_TOU_Rates_net_metering_credits():
    var data = var_table()
    setup_residential_rates(data)  # No sell rate in the defaults, so no credits
    ssc_data_set_number(data, "ur_metering_option", 1)
    var analysis_period: Int = 1
    ssc_data_set_number(data, "system_use_lifetime_output", 1)
    ssc_data_set_number(data, "analysis_period", analysis_period)
    set_array(data, "load", load_profile_path, 8760)
    set_array(data, "gen", subhourly_gen_path, 8760 * 4)  # 15 min data
    var status = run_module(data, "utilityrate5")
    assert(not status)
    ensure_outputs_line_up(data)
    var cost_without_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_without_system_year1", cost_without_system)
    assert(abs(cost_without_system - 771.8) < 0.1)
    var cost_with_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_with_system_year1", cost_with_system)
    assert(abs(cost_with_system - 81.4) < 0.1)
    var nrows: Int
    var ncols: Int
    var net_billing_credits = ssc_data_get_matrix(data, "nm_dollars_applied_ym", nrows, ncols)
    var credits_matrix = util.matrix_t[Float64](nrows, ncols)
    credits_matrix.assign(net_billing_credits, nrows, ncols)
    var dec_year_1_credits = credits_matrix.at(1, 11)
    assert(abs(dec_year_1_credits - 0) < 0.1)

def test_cmod_utilityrate5_eqns_Test_Residential_TOU_Rates_net_billing():
    var data = var_table()
    setup_residential_rates(data)
    ssc_data_set_number(data, "ur_metering_option", 2)
    var analysis_period: Int = 1
    ssc_data_set_number(data, "system_use_lifetime_output", 1)
    ssc_data_set_number(data, "analysis_period", analysis_period)
    set_array(data, "load", load_profile_path, 8760)
    set_array(data, "gen", subhourly_gen_path, 8760 * 4)  # 15 min data
    var status = run_module(data, "utilityrate5")
    assert(not status)
    ensure_outputs_line_up(data)
    var cost_without_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_without_system_year1", cost_without_system)
    assert(abs(cost_without_system - 771.8) < 0.1)
    var cost_with_system: ssc_number_t
    ssc_data_get_number(data, "elec_cost_with_system_year1", cost_with_system)
    assert(abs(cost_with_system - 441.4) < 0.1)
    var nrows: Int
    var ncols: Int
    var net_billing_credits = ssc_data_get_matrix(data, "net_billing_credits_ym", n