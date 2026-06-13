from testing import Test, assert_approx_equal, assert_equal
from lib_utility_rate import rate_data, UtilityRateForecast
from lib_utility_rate_equations import *
from shared_rate_data import (
    set_up_simple_demand_charge,
    set_up_default_commercial_rate_data,
    set_up_pge_residential_rate_data,
    set_up_time_series,
)

@Test
def test_copy():
    p_ur_ec_sched_weekday: List[Float64] = [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4]
    p_ur_ec_sched_weekend: List[Float64] = [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]
    p_ur_ec_tou_mat: List[Float64] = [1,1,9.9999999999999998e+37,0,0.050000000000000003,0,
        2,1,9.9999999999999998e+37,0,0.074999999999999997,0,
        3,1,9.9999999999999998e+37,0,0.059999999999999998,0,
        4,1,9.9999999999999998e+37,0,0.050000000000000003,0]
    tou_rows: Int = 4
    sell_eq_buy: Bool = False
    data = rate_data()
    data.init(8760)
    data.setup_energy_rates(p_ur_ec_sched_weekday, p_ur_ec_sched_weekend, tou_rows, p_ur_ec_tou_mat, sell_eq_buy)
    data.rate_scale.append(1.0)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [25,25,25,25,25,25]
    monthly_gen_forecast: List[Float64] = [0,0,0,0,0,0]
    monthly_avg_gross_load: List[Float64] = [25,25,25,25,25,25]
    rate_forecast_1 = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    rate_forecast_2 = UtilityRateForecast(rate_forecast_1)
    rate_forecast_1.compute_next_composite_tou(0, 0)
    rate_forecast_2.compute_next_composite_tou(4, 0)
    assert_approx_equal(0.060, rate_forecast_1.next_composite_buy_rates[0], 0.0001)
    assert_approx_equal(0.050, rate_forecast_1.next_composite_buy_rates[1], 0.0001)
    assert_approx_equal(0.050, rate_forecast_2.next_composite_buy_rates[0], 0.0001)
    assert_approx_equal(0.0750, rate_forecast_2.next_composite_buy_rates[1], 0.0001)

@Test
def test_tiered_tou_cost_estimates():
    var p_ur_ec_sched_weekday: List[Float64] = [1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,1,1,1,1]
    var p_ur_ec_sched_weekend: List[Float64] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    var p_ur_ec_tou_mat: List[Float64] = [1,1,8.3,0,0.03461,0,
        1,2,10.8,0,0.05140,0,
        1,3,16.6,0,0.14698,0,
        1,4,24.9,0,0.18727,0,
        1,5,9.9999999999999998e+37,0,0.18727,0,
        2,1,8.3,0,0.09132,0,
        2,2,10.8,0,0.10811,0,
        2,3,16.6,0,0.26397,0,
        2,4,24.9,0,0.3733,0,
        2,5,9.9999999999999998e+37,0,0.3733,0,
        3,1,8.3,0,0.27904,0,
        3,2,10.8,0,0.29583,0,
        3,3,16.6,0,0.45169,0,
        3,4,24.9,0,0.5611,0,
        3,5,9.9999999999999998e+37,0,0.5611,0]
    tou_rows: Int = 15
    sell_eq_buy: Bool = False
    data = rate_data()
    data.init(8760)
    data.setup_energy_rates(p_ur_ec_sched_weekday, p_ur_ec_sched_weekend, tou_rows, p_ur_ec_tou_mat, sell_eq_buy)
    data.rate_scale.append(1.0)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = []
    monthly_load_forecast.append(25)
    monthly_gen_forecast: List[Float64] = []
    monthly_gen_forecast.append(0)
    monthly_avg_gross_load: List[Float64] = []
    monthly_avg_gross_load.append(7)
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    rate_forecast.compute_next_composite_tou(0, 0)
    assert_equal(3, len(rate_forecast.next_composite_buy_rates))
    assert_approx_equal(0.11365, rate_forecast.next_composite_buy_rates[0], 0.0001)
    assert_approx_equal(0.22782, rate_forecast.next_composite_buy_rates[1], 0.0001)
    assert_approx_equal(0.41554, rate_forecast.next_composite_buy_rates[2], 0.0001)
    assert_equal(3, len(rate_forecast.next_composite_sell_rates))
    assert_approx_equal(0.0, rate_forecast.next_composite_sell_rates[0], 0.0001)
    assert_approx_equal(0.0, rate_forecast.next_composite_sell_rates[1], 0.0001)
    assert_approx_equal(0.0, rate_forecast.next_composite_sell_rates[2], 0.0001)

@Test
def test_tiered_sell_rates():
    var p_ur_ec_sched_weekday: List[Float64] = [1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1,1]
    var p_ur_ec_sched_weekend: List[Float64] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    var p_ur_ec_tou_mat: List[Float64] = [1,1,8.2,0,0.03461,0.02,
        1,2,10.8,0,0.05140,0.02,
        1,3,9.9999999999999998e+37,0,0.18727,0.02,
        2,1,8.3,0,0.09132,0.03,
        2,2,10.8,0,0.10811,0.01,
        2,3,9.9999999999999998e+37,0,0.3733,0.01]
    tou_rows: Int = 6
    sell_eq_buy: Bool = False
    data = rate_data()
    data.init(8760)
    data.setup_energy_rates(p_ur_ec_sched_weekday, p_ur_ec_sched_weekend, tou_rows, p_ur_ec_tou_mat, sell_eq_buy)
    data.rate_scale.append(1.0)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = []
    monthly_load_forecast.append(0)
    monthly_gen_forecast: List[Float64] = []
    monthly_gen_forecast.append(10)
    monthly_avg_gross_load: List[Float64] = []
    monthly_avg_gross_load.append(7)
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    rate_forecast.compute_next_composite_tou(0, 0)
    assert_equal(2, len(rate_forecast.next_composite_buy_rates))
    assert_approx_equal(0.03461, rate_forecast.next_composite_buy_rates[0], 0.0001)
    assert_approx_equal(0.09132, rate_forecast.next_composite_buy_rates[1], 0.0001)
    assert_equal(2, len(rate_forecast.next_composite_sell_rates))
    assert_approx_equal(0.02, rate_forecast.next_composite_sell_rates[0], 0.0001)
    assert_approx_equal(0.0266, rate_forecast.next_composite_sell_rates[1], 0.0001)

@Test
def test_simple_demand_charges():
    data = rate_data()
    set_up_simple_demand_charge(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [31 * 24, 28 * 24]
    monthly_gen_forecast: List[Float64] = [0, 0]
    monthly_avg_gross_load: List[Float64] = [1, 1]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-1, -1, 0, -2]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 0
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(1.00, cost, 0.01)
    hour_of_year = 4
    cost = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(0.0, cost, 0.01)

@Test
def test_demand_charges_crossing_months():
    data = rate_data()
    set_up_default_commercial_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [0, 0]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -50, -50, -25]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 742
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(11.25, cost, 0.02)

@Test
def test_demand_charges_inaccurate_forecast():
    data = rate_data()
    set_up_default_commercial_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [0, 0]
    monthly_avg_gross_load: List[Float64] = [50, 0]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -50, -50, -25]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 742
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(1011.25, cost, 0.02)

@Test
def test_changing_rates_crossing_months():
    data = rate_data()
    set_up_default_commercial_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [0, 0, 0, 150, 75]
    monthly_gen_forecast: List[Float64] = [0, 0, 0, 0, 0]
    monthly_avg_gross_load: List[Float64] = [0, 0, 0, 100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -50, -50, -25]
    rate_forecast.initializeMonth(3, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 2878
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(13.125, cost, 0.02)

@Test
def test_demand_charges_crossing_year():
    data = rate_data()
    set_up_default_commercial_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,150,75]
    monthly_gen_forecast: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,0,0]
    monthly_avg_gross_load: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,100,50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -50, -50, -25]
    rate_forecast.initializeMonth(11, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 8758
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(11.34, cost, 0.02)

@Test
def test_sell_rates():
    data = rate_data()
    var p_ur_ec_sched_weekday: List[Float64] = [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4]
    var p_ur_ec_sched_weekend: List[Float64] = [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]
    var p_ur_ec_tou_mat: List[Float64] = [1,1,9.9999999999999998e+37,0,0.050000000000000003,0.02,
        2,1,9.9999999999999998e+37,0,0.074999999999999997,0.02,
        3,1,9.9999999999999998e+37,0,0.059999999999999998,0.02,
        4,1,9.9999999999999998e+37,0,0.050000000000000003,0.02]
    tou_rows: Int = 4
    sell_eq_buy: Bool = False
    var p_ur_dc_sched_weekday: List[Float64] = [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2]
    var p_ur_dc_sched_weekend: List[Float64] = [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
    var p_ur_dc_tou_mat: List[Float64] = [1,1,100,20,
                                         1,2,9.9999999999999998e+37,15,
                                         2,1,100,10,
                                         2,2,9.9999999999999998e+37,5]
    var p_ur_dc_flat_mat: List[Float64] = [0,1,9.9999999999999998e+37,0,
                                        1,1,9.9999999999999998e+37,0,
                                        2,1,9.9999999999999998e+37,0,
                                        3,1,9.9999999999999998e+37,0,
                                        4,1,9.9999999999999998e+37,0,
                                        5,1,9.9999999999999998e+37,0,
                                        6,1,9.9999999999999998e+37,0,
                                        7,1,9.9999999999999998e+37,0,
                                        8,1,9.9999999999999998e+37,0,
                                        9,1,9.9999999999999998e+37,0,
                                        10,1,9.9999999999999998e+37,0,
                                        11,1,9.9999999999999998e+37,0]
    dc_flat_rows: Int = 12
    data.rate_scale = [1, 1.025]
    data.init(8760)
    data.setup_demand_charges(p_ur_dc_sched_weekday, p_ur_dc_sched_weekend, tou_rows, p_ur_dc_tou_mat, dc_flat_rows, p_ur_dc_flat_mat)
    data.setup_energy_rates(p_ur_ec_sched_weekday, p_ur_ec_sched_weekend, tou_rows, p_ur_ec_tou_mat, sell_eq_buy)
    data.init_energy_rates(False)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [0, 100]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -50, -50, -25, 25, 50, 25]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 742
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(9.25, cost, 0.02)

@Test
def test_net_metering_one_tou_period():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [0, 0]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -50, 50, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 1
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(0, cost, 0.001)
    hour_of_year += 4
    second_forecast: List[Float64] = [100, 50, -50, -100]
    cost = rate_forecast.forecastCost(second_forecast, 0, hour_of_year, 0)
    assert_approx_equal(0, cost, 0.001)

@Test
def test_net_metering_multiple_tou_periods():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [0, 0]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -50, 50, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 10
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(17.75, cost, 0.01)
    hour_of_year += 4
    second_forecast: List[Float64] = [100, 50, -50, -100]
    cost = rate_forecast.forecastCost(second_forecast, 0, hour_of_year, 0)
    assert_approx_equal(0.0, cost, 0.01)

@Test
def test_net_metering_end_of_month_carryover():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [0, 150]
    monthly_gen_forecast: List[Float64] = [150, 0]
    monthly_avg_gross_load: List[Float64] = [0, 100]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [100, 50, -50, -100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 742
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(0, cost, 0.001)

@Test
def test_net_metering_dollar_credits():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    data.nm_credits_w_rollover = False
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [0, 150]
    monthly_gen_forecast: List[Float64] = [150, 0]
    monthly_avg_gross_load: List[Float64] = [0, 100]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [100, 50, -50, -100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 742
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(17.75, cost, 0.01)

@Test
def test_net_metering_end_of_month_cashout():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    data.net_metering_credit_month = 0
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [0, 150]
    monthly_gen_forecast: List[Float64] = [150, 0]
    monthly_avg_gross_load: List[Float64] = [0, 100]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [100, 50, -50, -100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 742
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(17.75, cost, 0.01)

@Test
def test_net_metering_end_of_month_charges():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 0]
    monthly_gen_forecast: List[Float64] = [0, 150]
    monthly_avg_gross_load: List[Float64] = [100, 0]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -50, 50, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 742
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(17.75, cost, 0.01)

@Test
def test_net_metering_end_of_month_charges_subhourly():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 2
    monthly_load_forecast: List[Float64] = [150, 0]
    monthly_gen_forecast: List[Float64] = [0, 150]
    monthly_avg_gross_load: List[Float64] = [100, 0]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-100, -100, -50, -50, 50, 50, 100, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 742
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(17.75, cost, 0.01)

@Test
def test_net_metering_charges_crossing_year():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,25,25]
    monthly_gen_forecast: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,75,0]
    monthly_avg_gross_load: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,50,50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-25, 25, 50, -25, -25]
    rate_forecast.initializeMonth(11, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 8757
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(6.06, cost, 0.01)

@Test
def test_net_metering_charges_crossing_year_other_cash_out_month():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    data.net_metering_credit_month = 4
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,25,25]
    monthly_gen_forecast: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,75,0]
    monthly_avg_gross_load: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,50,50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [-25, 25, 50, -25, -25]
    rate_forecast.initializeMonth(11, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 8757
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(0, cost, 0.01)

@Test
def test_multiple_forecast_calls():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [100, 75]
    monthly_gen_forecast: List[Float64] = [175, 0]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [25, 25, 25, 25]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 1
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(0.0, cost, 0.001)
    hour_of_year += 4
    second_forecast: List[Float64] = [-100, 25, 25, 25]
    cost = rate_forecast.forecastCost(second_forecast, 0, hour_of_year, 0)
    assert_approx_equal(0.0, cost, 0.001)

@Test
def test_one_at_a_time_vs_full_vector():
    data = rate_data()
    set_up_default_commercial_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [50, 175]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [50, -100, -50, -50, -25, 25, 50, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    forecast_copy = UtilityRateForecast(rate_forecast)
    hour_of_year: Int = 741
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(11.25, cost, 0.02)
    cost = 0
    for i in range(len(forecast)):
        single_forecast: List[Float64] = [forecast[i]]
        cost += forecast_copy.forecastCost(single_forecast, 0, hour_of_year + i, 0)
    assert_approx_equal(11.25, cost, 0.02)

@Test
def test_one_at_a_time_vs_full_vector_nm_credits():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [50, 175]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [50, -100, -50, -50, -25, 25, 50, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    forecast_copy = UtilityRateForecast(rate_forecast)
    hour_of_year: Int = 741
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(11.83, cost, 0.02)
    cost = 0
    for i in range(len(forecast)):
        single_forecast: List[Float64] = [forecast[i]]
        cost += forecast_copy.forecastCost(single_forecast, 0, hour_of_year + i, 0)
    assert_approx_equal(11.83, cost, 0.02)

@Test
def test_one_at_a_time_vs_full_vector_nm_credits_subhourly():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    steps_per_hour: Int = 2
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [50, 175]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [50, 50, -100, -100, -50, -50, -50, -50, -25, -25, 25, 25, 50, 50, 100, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    forecast_copy = UtilityRateForecast(rate_forecast)
    hour_of_year: Int = 741
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(11.83, cost, 0.02)
    cost = 0
    for i in range(len(forecast) // 2):
        for j in range(2):
            single_forecast: List[Float64] = [forecast[i * 2 + j]]
            cost += forecast_copy.forecastCost(single_forecast, 0, hour_of_year + i, j)
    assert_approx_equal(11.83, cost, 0.02)

@Test
def test_end_of_analyis_period():
    data = rate_data()
    set_up_pge_residential_rate_data(data)
    data.net_metering_credit_month = 4
    data.rate_scale = [1]
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,25]
    monthly_gen_forecast: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,75]
    monthly_avg_gross_load: List[Float64] = [0,0,0,0,0,0,0,0,0,0,0,50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 1)
    forecast: List[Float64] = [-25, -25, 50]
    rate_forecast.initializeMonth(11, 0)
    rate_forecast.copyTOUForecast()
    hour_of_year: Int = 8757
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(0, cost, 0.01)

@Test
def test_one_at_a_time_vs_full_vector_buy_and_sell_rates():
    data = rate_data()
    set_up_time_series(data)
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [50, 175]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [50, -100, -50, -50, -25, 25, 50, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    forecast_copy = UtilityRateForecast(rate_forecast)
    hour_of_year: Int = 0
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(-75.0, cost, 0.02)
    cost = 0
    for i in range(len(forecast)):
        single_forecast: List[Float64] = [forecast[i]]
        cost += forecast_copy.forecastCost(single_forecast, 0, hour_of_year + i, 0)
    assert_approx_equal(-75.0, cost, 0.02)

@Test
def test_ts_buy_only():
    data = rate_data()
    set_up_time_series(data)
    data.en_ts_sell_rate = False
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [50, 175]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [50, -100, -50, -50, -25, 25, 50, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    forecast_copy = UtilityRateForecast(rate_forecast)
    hour_of_year: Int = 0
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(350.0, cost, 0.02)

@Test
def test_ts_sell_only():
    data = rate_data()
    set_up_time_series(data)
    data.en_ts_buy_rate = False
    steps_per_hour: Int = 1
    monthly_load_forecast: List[Float64] = [150, 75]
    monthly_gen_forecast: List[Float64] = [50, 175]
    monthly_avg_gross_load: List[Float64] = [100, 50]
    rate_forecast = UtilityRateForecast(data, steps_per_hour, monthly_load_forecast, monthly_gen_forecast, monthly_avg_gross_load, 2)
    forecast: List[Float64] = [50, -100, -50, -50, -25, 25, 50, 100]
    rate_forecast.initializeMonth(0, 0)
    rate_forecast.copyTOUForecast()
    forecast_copy = UtilityRateForecast(rate_forecast)
    hour_of_year: Int = 0
    cost: Float64 = rate_forecast.forecastCost(forecast, 0, hour_of_year, 0)
    assert_approx_equal(-402.50, cost, 0.02)