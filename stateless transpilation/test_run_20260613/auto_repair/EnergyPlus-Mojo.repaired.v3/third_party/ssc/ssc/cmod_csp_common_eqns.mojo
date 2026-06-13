from sscapi import ssc_data_get_number, ssc_data_set_number, ssc_data_get_array, ssc_data_set_array, ssc_data_t
from ...shared.lib_util import util
from htf_props import HTFProperties
from vartab import var_table, vt_get_matrix, var_data
from csp_system_costs import C_mspt_system_costs

@value
enum TowerTypes:
    kMoltenSalt = 0
    kDirectSteam = 1
    kIscc = 2

alias ssc_number_t = float
alias ssc_bool_t = bool

def ssc_data_t_get_number(p_data: ssc_data_t, name: StringRef, value: Pointer[ssc_number_t]) -> ssc_bool_t:
    var success = ssc_data_get_number(p_data, name, value)
    if not success:
        var str_name = String(name)
        var n_replaced = util.replace(str_name, ".", "_")
        if n_replaced > 0:
            success = ssc_data_get_number(p_data, str_name.c_str(), value)
    return success

def ssc_data_t_set_number(p_data: ssc_data_t, name: StringRef, value: ssc_number_t):
    ssc_data_set_number(p_data, name, value)
    var str_name = String(name)
    var n_replaced = util.replace(str_name, ".", "_")
    if n_replaced > 0:
        ssc_data_set_number(p_data, str_name.c_str(), value)

def ssc_data_t_get_array(p_data: ssc_data_t, name: StringRef, length: Pointer[Int]) -> Pointer[ssc_number_t]:
    var data: Pointer[ssc_number_t]
    data = ssc_data_get_array(p_data, name, length)
    if data.is_null():
        var str_name = String(name)
        var n_replaced = util.replace(str_name, ".", "_")
        if n_replaced > 0:
            data = ssc_data_get_array(p_data, str_name.c_str(), length)
    return data

def ssc_data_t_set_array(p_data: ssc_data_t, name: StringRef, pvalues: Pointer[ssc_number_t], length: Int):
    ssc_data_set_array(p_data, name, pvalues, length)
    var str_name = String(name)
    var n_replaced = util.replace(str_name, ".", "_")
    if n_replaced > 0:
        ssc_data_set_array(p_data, str_name.c_str(), pvalues, length)

def ssc_data_t_get_matrix(vt: Pointer[var_table], name: StringRef, matrix: ref[util.matrix_t[Float64]]):
    try:
        vt_get_matrix(vt, name, matrix)
    except:

    var str_name = String(name)
    var n_replaced = util.replace(str_name, ".", "_")
    if n_replaced > 0:
        vt_get_matrix(vt, name, matrix)

def ssc_data_t_set_matrix(data: ssc_data_t, name: StringRef, val: var_data):
    var vt = data.static_as[Pointer[var_table]]()
    if vt.is_null():
        raise Error("ssc_data_t data invalid")
    vt[].assign(name, val)
    var str_name = String(name)
    var n_replaced = util.replace(str_name, ".", "_")
    if n_replaced > 0:
        vt[].assign(str_name.c_str(), val)

def GetHtfProperties(fluid_number: Int, specified_fluid_properties: ref[util.matrix_t[Float64]]) -> HTFProperties:
    var htf_properties = HTFProperties()
    if fluid_number != HTFProperties.User_defined:
        if not htf_properties.SetFluid(fluid_number):
            raise Error("Fluid number is not recognized")
    elif fluid_number == HTFProperties.User_defined:
        var n_rows = specified_fluid_properties.nrows()
        var n_cols = specified_fluid_properties.ncols()
        if n_rows > 2 and n_cols == 7:
            if not htf_properties.SetUserDefinedFluid(specified_fluid_properties):
                var error_msg = util.format(htf_properties.UserFluidErrMessage(), n_rows, n_cols)
                raise Error(error_msg)
        else:
            var error_msg = util.format("The user defined fluid properties table must contain at least 3 rows and exactly 7 columns. The current table contains {} row(s) and {} column(s)", n_rows, n_cols)
            raise Error(error_msg)
    else:
        raise Error("Fluid code is not recognized")
    return htf_properties

def Nameplate(P_ref: Float64, gross_net_conversion_factor: Float64) -> Float64:
    return P_ref * gross_net_conversion_factor

def Q_pb_design(P_ref: Float64, design_eff: Float64) -> Float64:
    return P_ref / design_eff

def Q_rec_des(solarm: Float64, q_pb_design: Float64) -> Float64:
    return solarm * q_pb_design

def Tshours_sf(tshours: Float64, solarm: Float64) -> Float64:
    return tshours / solarm

def Land_max_calc(land_max: Float64, h_tower: Float64) -> Float64:
    return land_max * h_tower

def N_hel(helio_positions: ref[util.matrix_t[ssc_number_t]]) -> Int:
    return helio_positions.nrows().to_int()

def Csp_pt_sf_heliostat_area(helio_height: Float64, helio_width: Float64, dens_mirror: Float64) -> Float64:
    return helio_height * helio_width * dens_mirror

def Csp_pt_sf_total_reflective_area(n_hel: Int, csp_pt_sf_heliostat_area: Float64) -> Float64:
    return n_hel.to_float64() * csp_pt_sf_heliostat_area

def Land_min_calc(land_min: Float64, h_tower: Float64) -> Float64:
    return land_min * h_tower

def Csp_pt_sf_total_land_area(csp_pt_sf_fixed_land_area: Float64, land_area_base: Float64,
    csp_pt_sf_land_overhead_factor: Float64) -> Float64:
    return csp_pt_sf_fixed_land_area + land_area_base * csp_pt_sf_land_overhead_factor

def A_sf_UI(helio_width: Float64, helio_height: Float64, dens_mirror: Float64, n_hel: Int) -> Float64:
    return helio_width * helio_height * dens_mirror * n_hel.to_float64()

def Helio_area_tot(A_sf_UI: Float64) -> Float64:
    return A_sf_UI

def Csp_pt_sf_tower_height(h_tower: Float64) -> Float64:
    return h_tower

def C_atm_info(helio_positions: ref[util.matrix_t[ssc_number_t]],
    c_atm_0: Float64, c_atm_1: Float64, c_atm_2: Float64, c_atm_3: Float64, h_tower: Float64) -> Float64:
    var tht2 = h_tower * h_tower
    var n_hel = helio_positions.nrows()
    var tot_att = 0.0
    for i in range(n_hel):
        var x = helio_positions.at(i, 0)
        var y = helio_positions.at(i, 1)
        var r = math.sqrt(x*x + y*y)
        var r2 = r*r
        var s = math.sqrt(tht2 + r2) * 0.001
        var s2 = s*s
        var s3 = s2*s
        tot_att += c_atm_0 + c_atm_1*s + c_atm_2*s2 + c_atm_3*s3
    return 100.0 * tot_att / n_hel.to_float64()

def Error_equiv(helio_optical_error_mrad: Float64) -> Float64:
    return math.sqrt(2.0 * helio_optical_error_mrad * 2.0 * helio_optical_error_mrad * 2.0)

def Is_optimize(override_opt: __bool) -> __bool:
    if override_opt:
        return True
    else:
        return False

def Field_model_type(is_optimize: __bool, override_layout: __bool, assigned_field_model_type: Int) -> Int:
    if is_optimize:
        return 0
    elif override_layout:
        return 1
    elif assigned_field_model_type >= 0:
        return assigned_field_model_type
    else:
        return 2

def Q_design(Q_rec_des: Float64) -> Float64:
    return Q_rec_des

def Dni_des_calc(dni_des: Float64) -> Float64:
    return dni_des

def Opt_algorithm() -> Int:
    return 1

def Opt_flux_penalty() -> Float64:
    return 0.25

def Csp_pt_rec_cav_lip_height() -> Float64:
    return 1.0

def Csp_pt_rec_cav_panel_height() -> Float64:
    return 1.1

def Csp_pt_rec_htf_t_avg(T_htf_cold_des: Float64, T_htf_hot_des: Float64) -> Float64:
    return (T_htf_cold_des + T_htf_hot_des) / 2.0

def Csp_pt_rec_htf_c_avg(csp_pt_rec_htf_t_avg: Float64, rec_htf: Int,
    field_fl_props: ref[util.matrix_t[ssc_number_t]]) -> Float64:
    var htf_properties = GetHtfProperties(rec_htf, field_fl_props)
    return htf_properties.Cp(csp_pt_rec_htf_t_avg + 273.15)

def Csp_pt_rec_max_flow_to_rec(csp_pt_rec_max_oper_frac: Float64, Q_rec_des: Float64,
    csp_pt_rec_htf_c_avg: Float64, T_htf_hot_des: Float64, T_htf_cold_des: Float64) -> Float64:
    return (csp_pt_rec_max_oper_frac * Q_rec_des * 1e6) / (csp_pt_rec_htf_c_avg * 1e3 * (T_htf_hot_des - T_htf_cold_des))

def Csp_pt_rec_cav_ap_height(rec_d_spec: Float64, csp_pt_rec_cav_ap_hw_ratio: Float64) -> Float64:
    return rec_d_spec * csp_pt_rec_cav_ap_hw_ratio

def Rec_aspect(D_rec: Float64, rec_height: Float64) -> Float64:
    var aspect: Float64
    if D_rec != 0.0:
        aspect = rec_height / D_rec
    else:
        aspect = 1.0
    return aspect

def Piping_length(h_tower: Float64, piping_length_mult: Float64, piping_length_const: Float64) -> Float64:
    return h_tower * piping_length_mult + piping_length_const

def Piping_loss_tot(piping_length: Float64, piping_loss: Float64) -> Float64:
    return piping_length * piping_loss / 1000.0

def Csp_pt_par_calc_bop(bop_par: Float64, bop_par_f: Float64, bop_par_0: Float64,
    bop_par_1: Float64, bop_par_2: Float64, p_ref: Float64) -> Float64:
    return bop_par * bop_par_f * (bop_par_0 + bop_par_1 + bop_par_2) * p_ref

def Csp_pt_par_calc_aux(aux_par: Float64, aux_par_f: Float64, aux_par_0: Float64,
    aux_par_1: Float64, aux_par_2: Float64, p_ref: Float64) -> Float64:
    return aux_par * aux_par_f * (aux_par_0 + aux_par_1 + aux_par_2) * p_ref

def Disp_wlim_max(disp_wlim_maxspec: Float64, constant: Float64) -> Float64:
    return disp_wlim_maxspec * (1.0 - constant / 100.0)

def Wlim_series(disp_wlim_max: Float64) -> util.matrix_t[Float64]:
    const kHoursInYear: Int = 8760
    var disp_wlim_max_kW = disp_wlim_max * 1000.0
    var wlim_series = util.matrix_t[Float64](1, kHoursInYear, disp_wlim_max_kW)
    return wlim_series

def Csp_pt_cost_receiver_area(tower_type: TowerTypes, d_rec: Float64, rec_height: Float64,
    receiver_type: Int, rec_d_spec: Float64, csp_pt_rec_cav_ap_height: Float64) -> Float64:
    var area = Float64(math.nan)
    if tower_type == TowerTypes.kMoltenSalt or tower_type == TowerTypes.kIscc:
        if receiver_type == 0:
            area = rec_height * d_rec * math.pi
        elif receiver_type == 1:
            area = rec_d_spec * csp_pt_rec_cav_ap_height
        else:
            raise Error("Receiver type not supported.")
    elif tower_type == TowerTypes.kDirectSteam:
        area = d_rec * rec_height * math.pi
    return area

def Csp_pt_cost_storage_mwht(tower_type: TowerTypes, p_ref: Float64, design_eff: Float64,
    tshours: Float64) -> Float64:
    var nameplate = Float64(math.nan)
    if tower_type == TowerTypes.kMoltenSalt:
        nameplate = p_ref / design_eff * tshours
    else:
        nameplate = 0.0
    return nameplate

def Csp_pt_cost_power_block_mwe(tower_type: TowerTypes, p_ref: Float64, demand_var: Float64) -> Float64:
    var pb = Float64(math.nan)
    if tower_type == TowerTypes.kMoltenSalt:
        pb = p_ref
    else:
        pb = demand_var
    return pb

def Tower_SolarPilot_Capital_Costs_Equations(data: ssc_data_t):
    var vt = data.static_as[Pointer[var_table]]()
    if vt.is_null():
        raise Error("ssc_data_t data invalid")
    var sys_costs = C_mspt_system_costs()
    ssc_data_t_get_number(data, "a_sf_ui", sys_costs.ms_par.A_sf_refl)
    ssc_data_t_get_number(data, "site_spec_cost", sys_costs.ms_par.site_improv_spec_cost)
    ssc_data_t_get_number(data, "heliostat_spec_cost", sys_costs.ms_par.heliostat_spec_cost)
    ssc_data_t_get_number(data, "cost_sf_fixed", sys_costs.ms_par.heliostat_fixed_cost)
    ssc_data_t_get_number(data, "h_tower", sys_costs.ms_par.h_tower)
    ssc_data_t_get_number(data, "rec_height", sys_costs.ms_par.h_rec)
    ssc_data_t_get_number(data, "helio_height", sys_costs.ms_par.h_helio)
    ssc_data_t_get_number(data, "tower_fixed_cost", sys_costs.ms_par.tower_fixed_cost)
    ssc_data_t_get_number(data, "tower_exp", sys_costs.ms_par.tower_cost_scaling_exp)
    ssc_data_t_get_number(data, "csp.pt.cost.receiver.area", sys_costs.ms_par.A_rec)
    ssc_data_t_get_number(data, "rec_ref_cost", sys_costs.ms_par.rec_ref_cost)
    ssc_data_t_get_number(data, "rec_ref_area", sys_costs.ms_par.A_rec_ref)
    ssc_data_t_get_number(data, "rec_cost_exp", sys_costs.ms_par.rec_cost_scaling_exp)
    ssc_data_t_get_number(data, "csp.pt.cost.storage_mwht", sys_costs.ms_par.Q_storage)
    ssc_data_t_get_number(data, "tes_spec_cost", sys_costs.ms_par.tes_spec_cost)
    ssc_data_t_get_number(data, "csp.pt.cost.power_block_mwe", sys_costs.ms_par.W_dot_design)
    ssc_data_t_get_number(data, "plant_spec_cost", sys_costs.ms_par.power_cycle_spec_cost)
    ssc_data_t_get_number(data, "bop_spec_cost", sys_costs.ms_par.bop_spec_cost)
    ssc_data_t_get_number(data, "fossil_spec_cost", sys_costs.ms_par.fossil_backup_spec_cost)
    ssc_data_t_get_number(data, "contingency_rate", sys_costs.ms_par.contingency_rate)
    ssc_data_t_get_number(data, "csp.pt.sf.total_land_area", sys_costs.ms_par.total_land_area)
    ssc_data_t_get_number(data, "nameplate", sys_costs.ms_par.plant_net_capacity)
    ssc_data_t_get_number(data, "csp.pt.cost.epc.per_acre", sys_costs.ms_par.EPC_land_spec_cost)
    ssc_data_t_get_number(data, "csp.pt.cost.epc.percent", sys_costs.ms_par.EPC_land_perc_direct_cost)
    ssc_data_t_get_number(data, "csp.pt.cost.epc.per_watt", sys_costs.ms_par.EPC_land_per_power_cost)
    ssc_data_t_get_number(data, "csp.pt.cost.epc.fixed", sys_costs.ms_par.EPC_land_fixed_cost)
    ssc_data_t_get_number(data, "land_spec_cost", sys_costs.ms_par.total_land_spec_cost)
    ssc_data_t_get_number(data, "csp.pt.cost.plm.percent", sys_costs.ms_par.total_land_perc_direct_cost)
    ssc_data_t_get_number(data, "csp.pt.cost.plm.per_watt", sys_costs.ms_par.total_land_per_power_cost)
    ssc_data_t_get_number(data, "csp.pt.cost.plm.fixed", sys_costs.ms_par.total_land_fixed_cost)
    ssc_data_t_get_number(data, "sales_tax_frac", sys_costs.ms_par.sales_tax_basis)
    ssc_data_t_get_number(data, "sales_tax_rate", sys_costs.ms_par.sales_tax_rate)
    try:
        sys_costs.calculate_costs()
    except:
        raise Error("MSPT system costs. System cost calculations failed. Check that all inputs are properly defined")
    ssc_data_t_set_number(data, "csp.pt.cost.site_improvements", sys_costs.ms_out.site_improvement_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.heliostats", sys_costs.ms_out.heliostat_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.tower", sys_costs.ms_out.tower_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.receiver", sys_costs.ms_out.receiver_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.storage", sys_costs.ms_out.tes_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.power_block", sys_costs.ms_out.power_cycle_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.bop", sys_costs.ms_out.bop_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.fossil", sys_costs.ms_out.fossil_backup_cost.to_float64())
    ssc_data_t_set_number(data, "ui_direct_subtotal", sys_costs.ms_out.direct_capital_precontingency_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.contingency", sys_costs.ms_out.contingency_cost.to_float64())
    ssc_data_t_set_number(data, "total_direct_cost", sys_costs.ms_out.total_direct_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.epc.total", sys_costs.ms_out.epc_and_owner_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.plm.total", sys_costs.ms_out.total_land_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.sales_tax.total", sys_costs.ms_out.sales_tax_cost.to_float64())
    ssc_data_t_set_number(data, "total_indirect_cost", sys_costs.ms_out.total_indirect_cost.to_float64())
    ssc_data_t_set_number(data, "total_installed_cost", sys_costs.ms_out.total_installed_cost.to_float64())
    ssc_data_t_set_number(data, "csp.pt.cost.installed_per_capacity", sys_costs.ms_out.estimated_installed_cost_per_cap.to_float64())