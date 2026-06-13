from cmod_csp_common_eqns import Nameplate, Q_pb_design, Q_rec_des, Tshours_sf, Land_max_calc, N_hel, Csp_pt_sf_heliostat_area, Land_min_calc, Csp_pt_sf_total_land_area, A_sf_UI, Helio_area_tot, Csp_pt_sf_tower_height, C_atm_info, Error_equiv, Is_optimize, Field_model_type, Q_design, Dni_des_calc, Opt_algorithm, Opt_flux_penalty, Csp_pt_rec_htf_t_avg, Csp_pt_rec_htf_c_avg, Csp_pt_rec_max_flow_to_rec, Csp_pt_rec_cav_ap_height, Rec_aspect, Piping_length, Piping_loss_tot, Csp_pt_par_calc_bop, Csp_pt_par_calc_aux, Disp_wlim_max, Wlim_series, Csp_pt_cost_receiver_area, Csp_pt_cost_storage_mwht, Csp_pt_cost_power_block_mwe, TowerTypes
from vartab import var_table
from sscapi import ssc_data_t
from memory import memset_zero
from math import is_nan, nan, inf

def MSPT_System_Design_Equations(data: ssc_data_t) raises:
    var vt = __type_of(data)
    if not vt:
        raise Error("ssc_data_t data invalid")
    
    var P_ref: F64
    var gross_net_conversion_factor: F64
    var nameplate: F64
    var design_eff: F64
    var solarm: F64
    var q_pb_design: F64
    var q_rec_des: F64
    var tshours: F64
    var tshours_sf: F64
    
    ssc_data_t_get_number(data, "P_ref", P_ref)
    ssc_data_t_get_number(data, "gross_net_conversion_factor", gross_net_conversion_factor)
    nameplate = Nameplate(P_ref, gross_net_conversion_factor)
    ssc_data_t_set_number(data, "nameplate", nameplate)
    ssc_data_t_get_number(data, "P_ref", P_ref)
    ssc_data_t_get_number(data, "design_eff", design_eff)
    q_pb_design = Q_pb_design(P_ref, design_eff)
    ssc_data_t_set_number(data, "q_pb_design", q_pb_design)
    ssc_data_t_get_number(data, "solarm", solarm)
    ssc_data_t_get_number(data, "q_pb_design", q_pb_design)
    q_rec_des = Q_rec_des(solarm, q_pb_design)
    ssc_data_t_set_number(data, "q_rec_des", q_rec_des)
    ssc_data_t_get_number(data, "tshours", tshours)
    ssc_data_t_get_number(data, "solarm", solarm)
    tshours_sf = Tshours_sf(tshours, solarm)
    ssc_data_t_set_number(data, "tshours_sf", tshours_sf)


def Tower_SolarPilot_Solar_Field_Equations(data: ssc_data_t) raises:
    var vt = __type_of(data)
    if not vt:
        raise Error("ssc_data_t data invalid")
    
    var land_max: F64
    var h_tower: F64
    var land_max_calc: F64
    var helio_height: F64
    var helio_width: F64
    var dens_mirror: F64
    var csp_pt_sf_heliostat_area: F64
    var land_min: F64
    var land_min_calc: F64
    var csp_pt_sf_fixed_land_area: F64
    var land_area_base: F64
    var csp_pt_sf_land_overhead_factor: F64
    var csp_pt_sf_total_land_area: F64
    var a_sf_ui: F64
    var helio_area_tot: F64
    var csp_pt_sf_tower_height: F64
    var c_atm_0: F64
    var c_atm_1: F64
    var c_atm_2: F64
    var c_atm_3: F64
    var c_atm_info: F64
    var helio_optical_error_mrad: F64
    var error_equiv: F64
    var field_model_type: F64
    var q_rec_des: F64
    var q_design: F64
    var dni_des: F64
    var dni_des_calc: F64
    var opt_flux_penalty: F64
    var n_hel: F64
    var override_opt: F64
    var is_optimize: F64
    var override_layout: F64
    var opt_algorithm: F64
    var helio_positions = matrix[F64]()
    var success: Bool
    
    ssc_data_t_get_number(data, "land_max", land_max)
    ssc_data_t_get_number(data, "h_tower", h_tower)
    land_max_calc = Land_max_calc(land_max, h_tower)
    ssc_data_t_set_number(data, "land_max_calc", land_max_calc)
    ssc_data_t_get_matrix(vt, "helio_positions", helio_positions)
    n_hel = N_hel(helio_positions)
    ssc_data_t_set_number(data, "n_hel", n_hel)
    ssc_data_t_get_number(data, "helio_height", helio_height)
    ssc_data_t_get_number(data, "helio_width", helio_width)
    ssc_data_t_get_number(data, "dens_mirror", dens_mirror)
    csp_pt_sf_heliostat_area = Csp_pt_sf_heliostat_area(helio_height, helio_width, dens_mirror)
    ssc_data_t_set_number(data, "csp.pt.sf.heliostat_area", csp_pt_sf_heliostat_area)
    ssc_data_t_get_number(data, "land_min", land_min)
    ssc_data_t_get_number(data, "h_tower", h_tower)
    land_min_calc = Land_min_calc(land_min, h_tower)
    ssc_data_t_set_number(data, "land_min_calc", land_min_calc)
    ssc_data_t_get_number(data, "csp.pt.sf.fixed_land_area", csp_pt_sf_fixed_land_area)
    ssc_data_t_get_number(data, "land_area_base", land_area_base)
    ssc_data_t_get_number(data, "csp.pt.sf.land_overhead_factor", csp_pt_sf_land_overhead_factor)
    csp_pt_sf_total_land_area = Csp_pt_sf_total_land_area(csp_pt_sf_fixed_land_area, land_area_base, csp_pt_sf_land_overhead_factor)
    ssc_data_t_set_number(data, "csp.pt.sf.total_land_area", csp_pt_sf_total_land_area)
    ssc_data_t_get_number(data, "helio_width", helio_width)
    ssc_data_t_get_number(data, "helio_height", helio_height)
    ssc_data_t_get_number(data, "dens_mirror", dens_mirror)
    ssc_data_t_get_number(data, "n_hel", n_hel)
    a_sf_ui = A_sf_UI(helio_width, helio_height, dens_mirror, n_hel)
    ssc_data_t_set_number(data, "a_sf_ui", a_sf_ui)
    ssc_data_t_get_number(data, "a_sf_ui", a_sf_ui)
    helio_area_tot = Helio_area_tot(a_sf_ui)
    ssc_data_t_set_number(data, "helio_area_tot", helio_area_tot)
    ssc_data_t_get_number(data, "h_tower", h_tower)
    csp_pt_sf_tower_height = Csp_pt_sf_tower_height(h_tower)
    ssc_data_t_set_number(data, "csp.pt.sf.tower_height", csp_pt_sf_tower_height)
    ssc_data_t_get_number(data, "c_atm_0", c_atm_0)
    ssc_data_t_get_number(data, "c_atm_1", c_atm_1)
    ssc_data_t_get_number(data, "c_atm_2", c_atm_2)
    ssc_data_t_get_number(data, "c_atm_3", c_atm_3)
    ssc_data_t_get_number(data, "h_tower", h_tower)
    c_atm_info = C_atm_info(helio_positions, c_atm_0, c_atm_1, c_atm_2, c_atm_3, h_tower)
    ssc_data_t_set_number(data, "c_atm_info", c_atm_info)
    ssc_data_t_get_number(data, "helio_optical_error_mrad", helio_optical_error_mrad)
    error_equiv = Error_equiv(helio_optical_error_mrad)
    ssc_data_t_set_number(data, "error_equiv", error_equiv)
    success = ssc_data_t_get_number(data, "override_opt", override_opt)
    if not success:
        override_opt = 0.0
    is_optimize = Is_optimize(override_opt)
    ssc_data_t_set_number(data, "is_optimize", is_optimize)
    success = ssc_data_t_get_number(data, "is_optimize", is_optimize)
    if not success:
        is_optimize = 0.0
    success = ssc_data_t_get_number(data, "override_layout", override_layout)
    if not success:
        override_layout = 0.0
    var assigned_field_model_type: F64
    success = ssc_data_t_get_number(data, "field_model_type", assigned_field_model_type)
    if not success:
        assigned_field_model_type = -1.0
    field_model_type = Field_model_type(is_optimize, override_layout, int(assigned_field_model_type))
    ssc_data_t_set_number(data, "field_model_type", field_model_type)
    ssc_data_t_get_number(data, "q_rec_des", q_rec_des)
    q_design = Q_design(q_rec_des)
    ssc_data_t_set_number(data, "q_design", q_design)
    ssc_data_t_get_number(data, "dni_des", dni_des)
    dni_des_calc = Dni_des_calc(dni_des)
    ssc_data_t_set_number(data, "dni_des_calc", dni_des_calc)
    opt_algorithm = Opt_algorithm()
    ssc_data_t_set_number(data, "opt_algorithm", opt_algorithm)
    opt_flux_penalty = Opt_flux_penalty()
    ssc_data_t_set_number(data, "opt_flux_penalty", opt_flux_penalty)


def MSPT_Receiver_Equations(data: ssc_data_t) raises:
    var vt = __type_of(data)
    if not vt:
        raise Error("ssc_data_t data invalid")
    
    var csp_pt_rec_max_oper_frac: F64
    var q_rec_des: F64
    var csp_pt_rec_htf_c_avg: F64
    var t_htf_hot_des: F64
    var t_htf_cold_des: F64
    var csp_pt_rec_max_flow_to_rec: F64
    var csp_pt_rec_htf_t_avg: F64
    var rec_d_spec: F64
    var csp_pt_rec_cav_ap_hw_ratio: F64
    var csp_pt_rec_cav_ap_height: F64
    var d_rec: F64
    var rec_height: F64
    var rec_aspect: F64
    var h_tower: F64
    var piping_length_mult: F64
    var piping_length_const: F64
    var piping_length: F64
    var piping_loss: F64
    var piping_loss_tot: F64
    var rec_htf: F64
    var field_fl_props = matrix[F64]()
    
    ssc_data_t_get_number(data, "t_htf_cold_des", t_htf_cold_des)
    ssc_data_t_get_number(data, "t_htf_hot_des", t_htf_hot_des)
    csp_pt_rec_htf_t_avg = Csp_pt_rec_htf_t_avg(t_htf_cold_des, t_htf_hot_des)
    ssc_data_t_set_number(data, "csp.pt.rec.htf_t_avg", csp_pt_rec_htf_t_avg)
    ssc_data_t_get_number(data, "csp.pt.rec.htf_t_avg", csp_pt_rec_htf_t_avg)
    ssc_data_t_get_number(data, "rec_htf", rec_htf)
    ssc_data_t_get_matrix(vt, "field_fl_props", field_fl_props)
    csp_pt_rec_htf_c_avg = Csp_pt_rec_htf_c_avg(csp_pt_rec_htf_t_avg, rec_htf, field_fl_props)
    ssc_data_t_set_number(data, "csp.pt.rec.htf_c_avg", csp_pt_rec_htf_c_avg)
    ssc_data_t_get_number(data, "csp.pt.rec.max_oper_frac", csp_pt_rec_max_oper_frac)
    ssc_data_t_get_number(data, "q_rec_des", q_rec_des)
    ssc_data_t_get_number(data, "csp.pt.rec.htf_c_avg", csp_pt_rec_htf_c_avg)
    ssc_data_t_get_number(data, "t_htf_hot_des", t_htf_hot_des)
    ssc_data_t_get_number(data, "t_htf_cold_des", t_htf_cold_des)
    csp_pt_rec_max_flow_to_rec = Csp_pt_rec_max_flow_to_rec(csp_pt_rec_max_oper_frac, q_rec_des, csp_pt_rec_htf_c_avg, t_htf_hot_des, t_htf_cold_des)
    ssc_data_t_set_number(data, "csp.pt.rec.max_flow_to_rec", csp_pt_rec_max_flow_to_rec)
    ssc_data_t_get_number(data, "rec_d_spec", rec_d_spec)
    ssc_data_t_get_number(data, "csp.pt.rec.cav_ap_hw_ratio", csp_pt_rec_cav_ap_hw_ratio)
    csp_pt_rec_cav_ap_height = Csp_pt_rec_cav_ap_height(rec_d_spec, csp_pt_rec_cav_ap_hw_ratio)
    ssc_data_t_set_number(data, "csp.pt.rec.cav_ap_height", csp_pt_rec_cav_ap_height)
    ssc_data_t_get_number(data, "d_rec", d_rec)
    ssc_data_t_get_number(data, "rec_height", rec_height)
    rec_aspect = Rec_aspect(d_rec, rec_height)
    ssc_data_t_set_number(data, "rec_aspect", rec_aspect)
    ssc_data_t_get_number(data, "h_tower", h_tower)
    ssc_data_t_get_number(data, "piping_length_mult", piping_length_mult)
    ssc_data_t_get_number(data, "piping_length_const", piping_length_const)
    piping_length = Piping_length(h_tower, piping_length_mult, piping_length_const)
    ssc_data_t_set_number(data, "piping_length", piping_length)
    ssc_data_t_get_number(data, "piping_length", piping_length)
    ssc_data_t_get_number(data, "piping_loss", piping_loss)
    piping_loss_tot = Piping_loss_tot(piping_length, piping_loss)
    ssc_data_t_set_number(data, "piping_loss_tot", piping_loss_tot)


def MSPT_System_Control_Equations(data: ssc_data_t) raises:
    var vt = __type_of(data)
    if not vt:
        raise Error("ssc_data_t data invalid")
    
    var bop_par: F64
    var bop_par_f: F64
    var bop_par_0: F64
    var bop_par_1: F64
    var bop_par_2: F64
    var p_ref: F64
    var csp_pt_par_calc_bop: F64
    var aux_par: F64
    var aux_par_f: F64
    var aux_par_0: F64
    var aux_par_1: F64
    var aux_par_2: F64
    var csp_pt_par_calc_aux: F64
    var disp_wlim_maxspec: F64
    var constant: F64
    var disp_wlim_max: F64
    var wlim_series = matrix[F64]()
    
    ssc_data_t_get_number(data, "bop_par", bop_par)
    ssc_data_t_get_number(data, "bop_par_f", bop_par_f)
    ssc_data_t_get_number(data, "bop_par_0", bop_par_0)
    ssc_data_t_get_number(data, "bop_par_1", bop_par_1)
    ssc_data_t_get_number(data, "bop_par_2", bop_par_2)
    ssc_data_t_get_number(data, "p_ref", p_ref)
    csp_pt_par_calc_bop = Csp_pt_par_calc_bop(bop_par, bop_par_f, bop_par_0, bop_par_1, bop_par_2, p_ref)
    ssc_data_t_set_number(data, "csp.pt.par.calc.bop", csp_pt_par_calc_bop)
    ssc_data_t_get_number(data, "aux_par", aux_par)
    ssc_data_t_get_number(data, "aux_par_f", aux_par_f)
    ssc_data_t_get_number(data, "aux_par_0", aux_par_0)
    ssc_data_t_get_number(data, "aux_par_1", aux_par_1)
    ssc_data_t_get_number(data, "aux_par_2", aux_par_2)
    ssc_data_t_get_number(data, "p_ref", p_ref)
    csp_pt_par_calc_aux = Csp_pt_par_calc_aux(aux_par, aux_par_f, aux_par_0, aux_par_1, aux_par_2, p_ref)
    ssc_data_t_set_number(data, "csp.pt.par.calc.aux", csp_pt_par_calc_aux)
    
    disp_wlim_maxspec = constant = nan(F64)
    ssc_data_t_get_number(data, "disp_wlim_maxspec", disp_wlim_maxspec)
    if is_nan(disp_wlim_maxspec):
        disp_wlim_maxspec = 1.0
    ssc_data_t_get_number(data, "constant", constant)
    if is_nan(constant):
        ssc_data_t_get_number(data, "adjust:constant", constant)
    disp_wlim_max = Disp_wlim_max(disp_wlim_maxspec, constant)
    ssc_data_t_set_number(data, "disp_wlim_max", disp_wlim_max)
    
    if not vt.is_assigned("wlim_series"):
        ssc_data_t_get_number(data, "disp_wlim_max", disp_wlim_max)
        ssc_data_t_get_number(data, "constant", constant)
        wlim_series = Wlim_series(disp_wlim_max)
        ssc_data_t_set_array(data, "wlim_series", wlim_series.data(), wlim_series.ncells())


def Tower_SolarPilot_Capital_Costs_MSPT_Equations(data: ssc_data_t) raises:
    var vt = __type_of(data)
    if not vt:
        raise Error("ssc_data_t data invalid")
    
    var d_rec: F64
    var rec_height: F64
    var receiver_type_double: F64
    var rec_d_spec: F64
    var csp_pt_rec_cav_ap_height: F64
    var csp_pt_cost_receiver_area: F64
    var p_ref: F64
    var design_eff: F64
    var tshours: F64
    var csp_pt_cost_storage_mwht: F64
    var demand_var: F64
    var csp_pt_cost_power_block_mwe: F64
    var receiver_type: Int
    var tower_type = TowerTypes.kMoltenSalt
    
    receiver_type_double = nan(F64)
    ssc_data_t_get_number(data, "d_rec", d_rec)
    ssc_data_t_get_number(data, "rec_height", rec_height)
    ssc_data_t_get_number(data, "receiver_type", receiver_type_double)
    if is_nan(receiver_type_double):
        receiver_type = 0
    else:
        receiver_type = int(receiver_type_double)
    
    ssc_data_t_get_number(data, "rec_d_spec", rec_d_spec)
    ssc_data_t_get_number(data, "csp.pt.rec.cav_ap_height", csp_pt_rec_cav_ap_height)
    csp_pt_cost_receiver_area = Csp_pt_cost_receiver_area(tower_type, d_rec, rec_height,
        int(receiver_type), rec_d_spec, csp_pt_rec_cav_ap_height)
    ssc_data_t_set_number(data, "csp.pt.cost.receiver.area", csp_pt_cost_receiver_area)
    
    ssc_data_t_get_number(data, "p_ref", p_ref)
    ssc_data_t_get_number(data, "design_eff", design_eff)
    ssc_data_t_get_number(data, "tshours", tshours)
    csp_pt_cost_storage_mwht = Csp_pt_cost_storage_mwht(tower_type, p_ref, design_eff, tshours)
    ssc_data_t_set_number(data, "csp.pt.cost.storage_mwht", csp_pt_cost_storage_mwht)
    
    ssc_data_t_get_number(data, "p_ref", p_ref)
    demand_var = nan(F64)
    csp_pt_cost_power_block_mwe = Csp_pt_cost_power_block_mwe(tower_type, p_ref, demand_var)
    ssc_data_t_set_number(data, "csp.pt.cost.power_block_mwe", csp_pt_cost_power_block_mwe)
    
    Tower_SolarPilot_Capital_Costs_Equations(data)


def Tower_SolarPilot_Capital_Costs_DSPT_Equations(data: ssc_data_t) raises:
    var vt = __type_of(data)
    if not vt:
        raise Error("ssc_data_t data invalid")
    
    var d_rec: F64
    var rec_height: F64
    var receiver_type: F64
    var rec_d_spec: F64
    var csp_pt_rec_cav_ap_height: F64
    var csp_pt_cost_receiver_area: F64
    var p_ref: F64
    var design_eff: F64
    var tshours: F64
    var csp_pt_cost_storage_mwht: F64
    var demand_var: F64
    var csp_pt_cost_power_block_mwe: F64
    var tower_type = TowerTypes.kDirectSteam
    
    ssc_data_t_get_number(data, "d_rec", d_rec)
    ssc_data_t_get_number(data, "rec_height", rec_height)
    receiver_type = nan(F64)
    rec_d_spec = nan(F64)
    csp_pt_rec_cav_ap_height = nan(F64)
    csp_pt_cost_receiver_area = Csp_pt_cost_receiver_area(tower_type, d_rec, rec_height,
        int(receiver_type), rec_d_spec, csp_pt_rec_cav_ap_height)
    ssc_data_t_set_number(data, "csp.pt.cost.receiver_area", csp_pt_cost_receiver_area)
    
    p_ref = nan(F64)
    design_eff = nan(F64)
    tshours = nan(F64)
    csp_pt_cost_storage_mwht = Csp_pt_cost_storage_mwht(tower_type, p_ref, design_eff, tshours)
    ssc_data_t_set_number(data, "csp.pt.cost.storage_mwht", csp_pt_cost_storage_mwht)
    
    p_ref = nan(F64)
    ssc_data_t_get_number(data, "demand_var", demand_var)
    csp_pt_cost_power_block_mwe = Csp_pt_cost_power_block_mwe(tower_type, p_ref, demand_var)
    ssc_data_t_set_number(data, "csp.pt.cost.power_block_mwe", csp_pt_cost_power_block_mwe)
    
    Tower_SolarPilot_Capital_Costs_Equations(data)


def Tower_SolarPilot_Capital_Costs_ISCC_Equations(data: ssc_data_t) raises:
    var vt = __type_of(data)
    if not vt:
        raise Error("ssc_data_t data invalid")
    
    var d_rec: F64
    var rec_height: F64
    var receiver_type: F64
    var rec_d_spec: F64
    var csp_pt_rec_cav_ap_height: F64
    var csp_pt_cost_receiver_area: F64
    var p_ref: F64
    var design_eff: F64
    var tshours: F64
    var csp_pt_cost_storage_mwht: F64
    var demand_var: F64
    var csp_pt_cost_power_block_mwe: F64
    var tower_type = TowerTypes.kMoltenSalt
    
    ssc_data_t_get_number(data, "d_rec", d_rec)
    ssc_data_t_get_number(data, "rec_height", rec_height)
    ssc_data_t_get_number(data, "receiver_type", receiver_type)
    ssc_data_t_get_number(data, "rec_d_spec", rec_d_spec)
    ssc_data_t_get_number(data, "csp.pt.rec.cav_ap_height", csp_pt_rec_cav_ap_height)
    csp_pt_cost_receiver_area = Csp_pt_cost_receiver_area(tower_type, d_rec, rec_height,
        int(receiver_type), rec_d_spec, csp_pt_rec_cav_ap_height)
    ssc_data_t_set_number(data, "csp.pt.cost.receiver_area", csp_pt_cost_receiver_area)
    
    p_ref = nan(F64)
    design_eff = nan(F64)
    tshours = nan(F64)
    csp_pt_cost_storage_mwht = Csp_pt_cost_storage_mwht(tower_type, p_ref, design_eff, tshours)
    ssc_data_t_set_number(data, "csp.pt.cost.storage_mwht", csp_pt_cost_storage_mwht)
    
    p_ref = nan(F64)
    demand_var = nan(F64)
    csp_pt_cost_power_block_mwe = Csp_pt_cost_power_block_mwe(tower_type, p_ref, demand_var)
    ssc_data_t_set_number(data, "csp.pt.cost.power_block_mwe", csp_pt_cost_power_block_mwe)
    
    Tower_SolarPilot_Capital_Costs_Equations(data)