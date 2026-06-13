from cmod_utilityrate5_eqns import ElectricityRates_format_as_URDBv7
from vartab import var_table, var_data, vt_get_number, vt_get_array_vec
from sscapi import ssc_data_t, SSCEXPORT, SSC_TABLE

def map_input(vt: var_table, sam_name: String, reopt_table: var_table, reopt_name: String, sum: Bool = False, to_ratio: Bool = False):
    var sam_input: Float64
    vt_get_number(vt, sam_name, &sam_input)
    if var_data* vd = reopt_table.lookup(reopt_name):
        if sum:
            if to_ratio:
                sam_input /= 100.0
            vd.num = vd.num + sam_input
        else:
            raise Error(reopt_name + " variable already exists in 'reopt_table'.")
    else:
        if to_ratio:
            reopt_table.assign(reopt_name, sam_input / 100.0)
        else:
            reopt_table.assign(reopt_name, sam_input)

def map_optional_input(vt: var_table, sam_name: String, reopt_table: var_table, reopt_name: String, def_val: Float64, to_ratio: Bool = False):
    var sam_input: Float64
    try:
        vt_get_number(vt, sam_name, &sam_input)
        if to_ratio:
            sam_input /= 100.0
    except:
        sam_input = def_val
    if reopt_table.lookup(reopt_name):
        raise Error(reopt_name + " variable already exists in 'reopt_table'.")
    reopt_table.assign(reopt_name, sam_input)

@SSCEXPORT
def Reopt_size_battery_params(data: ssc_data_t):
    var vt = data
    if not vt:
        raise Error("ssc_data_t data invalid")
    var log: String
    var reopt_params = var_data()
    reopt_params.type = SSC_TABLE
    var reopt_table = &reopt_params.table
    var reopt_scenario: var_table
    var reopt_site: var_table
    var reopt_electric: var_table
    var reopt_utility: var_table
    var reopt_load: var_table
    var reopt_fin: var_table
    var reopt_pv: var_table
    var reopt_batt: var_table
    var reopt_wind: var_table
    reopt_wind.assign("max_kw", 0)
    map_input(vt, "lat", &reopt_site, "latitude")
    map_input(vt, "lon", &reopt_site, "longitude")
    map_input(vt, "system_capacity", &reopt_pv, "existing_kw")
    map_input(vt, "system_capacity", &reopt_pv, "max_kw")
    map_optional_input(vt, "degradation", &reopt_pv, "degradation_pct", 0.5, True)
    map_optional_input(vt, "module_type", &reopt_pv, "module_type", 1)
    var opt1: Int
    var opt2: Int
    var vd: var_data
    var vd2: var_data
    vd = vt.lookup("subarray1_track_mode")
    vd2 = vt.lookup("subarray1_backtrack")
    if vd and vd2:
        opt1 = int(vd.num[0])
        opt2 = int(vd2.num[0])
        if opt1 == 2 and opt2 == 1:
            opt1 = 3
        var opt_map = List[Int](0, 0, 2, 3, 4)
        reopt_pv.assign("array_type", opt_map[opt1])
    else:
        map_input(vt, "array_type", &reopt_pv, "array_type")
    var assign_matching_pv_vars = fn(vt: var_table, dest: var_table, pvwatts_var: String, pvsam_var: String, ratio: Bool = False):
        try:
            map_input(vt, pvsam_var, &dest, pvwatts_var, False, ratio)
        except:
            map_input(vt, pvwatts_var, &dest, pvwatts_var, False, ratio)
    assign_matching_pv_vars(vt, reopt_pv, "azimuth", "subarray1_azimuth")
    assign_matching_pv_vars(vt, reopt_pv, "tilt", "subarray1_tilt")
    assign_matching_pv_vars(vt, reopt_pv, "gcr", "subarray1_gcr")
    assign_matching_pv_vars(vt, reopt_pv, "losses", "annual_total_loss_percent", True)
    var inv_model: Int = 0
    var val1: Float64
    var val2: Float64
    var system_cap: Float64
    vt_get_number(vt, "system_capacity", &system_cap)
    vd = vt.lookup("inverter_model")
    if vd:
        var inv_eff_names = List[String]("inv_snl_eff_cec", "inv_ds_eff", "inv_pd_eff", "inv_cec_cg_eff")
        var eff: Float64
        inv_model = int(vd.num[0])
        if inv_model == 4:
            raise Error("Inverter Mermoud Lejeune Model not supported.")
        vt_get_number(vt, inv_eff_names[inv_model], &eff)
        eff /= 100.0
        reopt_pv.assign("inv_eff", eff)
        reopt_batt.assign("inverter_efficiency_pct", eff)
        var inv_power_names = List[String]("inv_snl_paco", "inv_ds_paco", "inv_pd_paco", "inv_cec_cg_paco")
        vt_get_number(vt, inv_power_names[inv_model], &val1)
        vt_get_number(vt, "inverter_count", &val2)
        reopt_pv.assign("dc_ac_ratio", system_cap * 1000.0 / (val2 * val1))
    else:
        map_input(vt, "inv_eff", &reopt_pv, "inv_eff", False, True)
        map_input(vt, "inv_eff", &reopt_batt, "inverter_efficiency_pct", False, True)
        map_input(vt, "dc_ac_ratio", &reopt_pv, "dc_ac_ratio")
    map_optional_input(vt, "itc_fed_percent", &reopt_pv, "federal_itc_pct", 0.0, True)
    map_optional_input(vt, "pbi_fed_amount", &reopt_pv, "pbi_us_dollars_per_kwh", 0.0)
    map_optional_input(vt, "pbi_fed_term", &reopt_pv, "pbi_years", 0.0)
    vd = reopt_pv.lookup("pbi_years")
    if vd.num[0] < 1:
        vd.num[0] = 1
    map_optional_input(vt, "ibi_sta_percent", &reopt_pv, "state_ibi_pct", 0.0, True)
    map_optional_input(vt, "ibi_sta_percent_maxvalue", &reopt_pv, "state_ibi_max_us_dollars", 10000000000)
    vd = reopt_pv.lookup("state_ibi_max_us_dollars")
    if vd.num[0] > 10000000000:
        vd.num[0] = 10000000000
    map_optional_input(vt, "ibi_uti_percent", &reopt_pv, "utility_ibi_pct", 0.0, True)
    map_optional_input(vt, "ibi_uti_percent_maxvalue", &reopt_pv, "utility_ibi_max_us_dollars", 10000000000)
    vd = reopt_pv.lookup("utility_ibi_max_us_dollars")
    if vd.num[0] > 10000000000:
        vd.num[0] = 10000000000
    vd = vt.lookup("om_fixed")
    vd2 = vt.lookup("om_production")
    if vd and not vd2:
        reopt_pv.assign("om_cost_us_dollars_per_kw", vd.num[0] / system_cap)
    elif not vd and vd2:
        reopt_pv.assign("om_cost_us_dollars_per_kw", vd2.num[0])
    elif vd and vd2:
        reopt_pv.assign("om_cost_us_dollars_per_kw", (vd.num[0] / system_cap) + vd2.num[0])
    vd = vt.lookup("total_installed_cost")
    if vd:
        reopt_pv.assign("installed_cost_us_dollars_per_kw", vd.num[0] / system_cap)
    vd = vt.lookup("depr_bonus_fed")
    if vd:
        reopt_pv.assign("macrs_bonus_pct", vd.num[0] / 100.0)
        reopt_batt.assign("macrs_bonus_pct", vd.num[0] / 100.0)
    vd = vt.lookup("depr_bonus_fed_macrs_5")
    if vd and vd.num[0] == 1:
        reopt_pv.assign("macrs_option_years", 5)
        reopt_batt.assign("macrs_option_years", 5)
    vd = vt.lookup("battery_per_kW")
    if vd:
        reopt_batt.assign("installed_cost_us_dollars_per_kw", vd.num[0])
    vd = vt.lookup("battery_per_kWh")
    if vd:
        reopt_batt.assign("installed_cost_us_dollars_per_kwh", vd.num[0])
    vd = vt.lookup("batt_dc_ac_efficiency")
    vd2 = vt.lookup("batt_ac_dc_efficiency")
    if vd and vd2:
        reopt_batt.assign("internal_efficiency_pct", (vd.num[0] + vd2.num[0]) / 200.0)
    elif vd and not vd2:
        reopt_batt.assign("internal_efficiency_pct", vd.num[0] / 100.0)
    elif not vd and vd2:
        reopt_batt.assign("internal_efficiency_pct", vd2.num[0] / 100.0)
    vd = vt.lookup("batt_initial_SOC")
    vd2 = vt.lookup("batt_minimum_SOC")
    if vd and vd2:
        reopt_batt.assign("soc_init_pct", vd.num[0] / 100.0)
        reopt_batt.assign("soc_min_pct", vd2.num[0] / 100.0)
    else:
        reopt_batt.assign("soc_init_pct", 0.5)
        reopt_batt.assign("soc_min_pct", 0.15)
    vd = vt.lookup("om_replacement_cost1")
    if vd:
        reopt_batt.assign("replace_cost_us_dollars_per_kwh", vd.num[0])
    var vec = List[Float64]()
    vd = vt.lookup("batt_replacement_schedule")
    if vd:
        vec = vd.arr_vector()
        if vec.size() > 1:
            log += "Warning: only first value of 'batt_replacement_schedule' array is used for the ReOpt input 'battery_replacement_year'.\n"
        reopt_batt.assign("battery_replacement_year", vec[0])
    ElectricityRates_format_as_URDBv7(vt)
    var urdb_data = vt.lookup("urdb_data")
    reopt_utility = urdb_data.table
    map_input(vt, "analysis_period", &reopt_fin, "analysis_years")
    map_input(vt, "rate_escalation", &reopt_fin, "escalation_pct", False, True)
    map_optional_input(vt, "value_of_lost_load", &reopt_fin, "value_of_lost_load_us_dollars_per_kwh", 0)
    reopt_fin.assign("microgrid_upgrade_cost_pct", 0)
    vd = vt.lookup("federal_tax_rate")
    vd2 = vt.lookup("state_tax_rate")
    if vd and vd2:
        reopt_fin.assign("offtaker_tax_pct", vd.num[0] / 100.0 + vd2.num[0] / 100.0)
    vt_get_number(vt, "inflation_rate", &val1)
    vd = vt.lookup("real_discount_rate")
    if vd:
        val2 = vd.num
    else:
        val2 = 6.4
    reopt_fin.assign("offtaker_discount_pct", (1 + val1 / 100.0) * (1 + val2 / 100.0) - 1)
    vd = vt.lookup("om_fixed_escal")
    vd2 = vt.lookup("om_production_escal")
    if vd and not vd2:
        reopt_pv.assign("om_cost_escalation_pct", vd.num[0] / system_cap)
    elif not vd and vd2:
        reopt_pv.assign("om_cost_escalation_pct", vd2.num[0])
    elif vd and vd2:
        reopt_pv.assign("om_cost_escalation_pct", (vd.num[0] / system_cap) + vd2.num[0])
    vt_get_array_vec(vt, "load", vec)
    var sim_len: Int = vec.size()
    if sim_len != 8760 and sim_len != 8760 * 2 and sim_len != 8760 * 4:
        raise Error("Load profile must be hourly, 30 min or 15 min data for a single year.")
    reopt_load.assign("loads_kw", var_data(&vec[0], sim_len))
    reopt_load.assign("loads_kw_is_net", False)
    vt_get_array_vec(vt, "crit_load", vec)
    if vec.size() != sim_len:
        raise Error("Critical load profile's length must be same as for load.")
    reopt_load.assign("critical_loads_kw", var_data(&vec[0], vec.size()))
    reopt_electric.assign_match_case("urdb_response", reopt_utility)
    reopt_site.assign_match_case("ElectricTariff", reopt_electric)
    reopt_site.assign_match_case("LoadProfile", reopt_load)
    reopt_site.assign_match_case("Financial", reopt_fin)
    reopt_site.assign_match_case("Storage", reopt_batt)
    reopt_site.assign_match_case("Wind", reopt_wind)
    reopt_site.assign_match_case("PV", reopt_pv)
    reopt_scenario.assign_match_case("Site", reopt_site)
    reopt_scenario.assign_match_case("time_steps_per_hour", var_data(int(sim_len / 8760)))
    reopt_table.assign_match_case("Scenario", reopt_scenario)
    vt.assign_match_case("reopt_scenario", reopt_params)
    vt.assign_match_case("log", log)