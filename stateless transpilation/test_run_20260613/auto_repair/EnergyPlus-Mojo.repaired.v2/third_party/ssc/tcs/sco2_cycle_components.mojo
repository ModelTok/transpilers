from sco2_cycle_components import (
    calculate_turbomachinery_outlet_1,
    isen_eta_from_poly_eta,
    calc_turbomachinery_eta_isen,
    Ts_data_over_linear_dP_ds,
    Ph_data_over_turbomachinery,
    sco2_cycle_plot_data_TS,
    sco2_cycle_plot_data_PH,
    Ts_arrays_over_constP,
    Ph_arrays_over_constT,
    Ts_dome,
    Ts_full_dome,
    Ph_dome,
    C_MEQ_CO2_props_at_2phase_P,
    C_HeatExchanger,
    C_turbine,
    C_comp__psi_eta_vs_phi,
    C_comp__snl_radial_via_Dyreby,
    C_comp__compA__PT_map_template,
    C_comp_multi_stage,
)
from CO2_properties import (
    CO2_state,
    CO2_TP,
    CO2_PS,
    CO2_PH,
    CO2_TD,
    CO2_HS,
    CO2_TQ,
    CO2_info,
    get_CO2_info,
)
from numeric_solvers import (
    C_monotonic_equation,
    C_monotonic_eq_solver,
)
from csp_solver_core import (
    C_csp_exception,
)
from sco2_cycle_templates import (
    C_sco2_cycle_core,
)
from interpolation_routines import (
    Linear_Interp,
)
import math
from memory import new
from pointer import Pointer

def calculate_turbomachinery_outlet_1(T_in: F64, P_in: F64, P_out: F64, eta_isen: F64, is_comp: Bool, error_code: Pointer[Int], spec_work: Pointer[F64]):
    var enth_in: F64
    var entr_in: F64
    var dens_in: F64
    var temp_out: F64
    var enth_out: F64
    var entr_out: F64
    var dens_out: F64
    calculate_turbomachinery_outlet_1(T_in, P_in, P_out, eta_isen, is_comp, error_code, enth_in, entr_in, dens_in, temp_out, enth_out, entr_out, dens_out, spec_work)

def calculate_turbomachinery_outlet_1_impl(T_in: F64, P_in: F64, P_out: F64, eta_isen: F64, is_comp: Bool, error_code: Pointer[Int], enth_in: Pointer[F64], entr_in: Pointer[F64], dens_in: Pointer[F64], temp_out: Pointer[F64], enth_out: Pointer[F64], entr_out: Pointer[F64], dens_out: Pointer[F64], spec_work: Pointer[F64]):
    var co2_props: CO2_state
    error_code[] = 0
    var prop_error_code: Int = CO2_TP(T_in, P_in, co2_props)
    if prop_error_code != 0:
        error_code[] = prop_error_code
        return
    var h_in: F64 = co2_props.enth
    var s_in: F64 = co2_props.entr
    dens_in[] = co2_props.dens
    prop_error_code = CO2_PS(P_out, s_in, co2_props)
    if prop_error_code != 0:
        error_code[] = prop_error_code
        return
    var h_s_out: F64 = co2_props.enth
    var w_s: F64 = h_in - h_s_out
    var w: F64 = 0.0
    if is_comp:
        w = w_s / eta_isen
    else:
        w = w_s * eta_isen
    var h_out: F64 = h_in - w
    prop_error_code = CO2_PH(P_out, h_out, co2_props)
    if prop_error_code != 0:
        error_code[] = prop_error_code
        return
    enth_in[] = h_in
    entr_in[] = s_in
    temp_out[] = co2_props.temp
    enth_out[] = h_out
    entr_out[] = co2_props.entr
    dens_out[] = co2_props.dens
    spec_work[] = w
    return

def isen_eta_from_poly_eta(T_in: F64, P_in: F64, P_out: F64, poly_eta: F64, is_comp: Bool, error_code: Pointer[Int], isen_eta: Pointer[F64]):
    var co2_props: CO2_state
    var prop_error_code: Int = CO2_TP(T_in, P_in, co2_props)
    if prop_error_code != 0:
        error_code[] = prop_error_code
        return
    var h_in: F64 = co2_props.enth
    var s_in: F64 = co2_props.entr
    prop_error_code = CO2_PS(P_out, s_in, co2_props)
    if prop_error_code != 0:
        error_code[] = prop_error_code
        return
    var h_s_out: F64 = co2_props.enth
    var stage_P_in: F64 = P_in
    var stage_h_in: F64 = h_in
    var stage_s_in: F64 = s_in
    var N_stages: Int = 200
    var stage_DP: F64 = (P_out - P_in) / F64(N_stages)
    var stage_P_out: F64 = -999.9
    var stage_h_out: F64 = -999.9
    for i in range(1, N_stages + 1):
        stage_P_out = stage_P_in + stage_DP
        prop_error_code = CO2_PS(stage_P_out, stage_s_in, co2_props)
        if prop_error_code != 0:
            error_code[] = prop_error_code
            return
        var stage_h_s_out: F64 = co2_props.enth
        var w_s: F64 = stage_h_in - stage_h_s_out
        var w: F64 = math.nan
        if is_comp:
            w = w_s / poly_eta
        else:
            w = w_s * poly_eta
        stage_h_out = stage_h_in - w
        stage_P_in = stage_P_out
        stage_h_in = stage_h_out
        prop_error_code = CO2_PH(stage_P_in, stage_h_in, co2_props)
        if prop_error_code != 0:
            error_code[] = prop_error_code
            return
        stage_s_in = co2_props.entr
    if is_comp:
        isen_eta[] = (h_s_out - h_in) / (stage_h_out - h_in)
    else:
        isen_eta[] = (stage_h_out - h_in) / (h_s_out - h_in)

def calc_turbomachinery_eta_isen(T_in: F64, P_in: F64, T_out: F64, P_out: F64, eta_isen: Pointer[F64]) -> Int:
    var co2_props: CO2_state
    var prop_error_code: Int = CO2_TP(T_in, P_in, co2_props)
    if prop_error_code != 0:
        return prop_error_code
    var h_in: F64 = co2_props.enth
    var s_in: F64 = co2_props.entr
    prop_error_code = CO2_TP(T_out, P_out, co2_props)
    if prop_error_code != 0:
        return prop_error_code
    var h_out: F64 = co2_props.enth
    prop_error_code = CO2_PS(P_out, s_in, co2_props)
    if prop_error_code != 0:
        return prop_error_code
    var h_s_out: F64 = co2_props.enth
    if P_out > P_in:
        eta_isen[] = (h_s_out - h_in) / (h_out - h_in)
    else:
        eta_isen[] = (h_out - h_in) / (h_s_out - h_in)
    if eta_isen[] > 1.00001:
        return -2
    return 0

def Ts_data_over_linear_dP_ds(P_in: F64, s_in: F64, P_out: F64, s_out: F64, T_data: Pointer[F64], s_data: Pointer[F64], N_points: Int = 30) -> Int:
    var co2_props: CO2_state
    var err_code: Int = 0
    var deltaP: F64 = (P_in - P_out) / F64(N_points - 1)
    var deltas: F64 = (s_in - s_out) / F64(N_points - 1)
    T_data.reserve(N_points)
    s_data.reserve(N_points)
    var P_local: F64 = math.nan
    var s_local: F64 = math.nan
    for i in range(N_points):
        s_local = s_in - deltas * F64(i)
        P_local = P_in - deltaP * F64(i)
        err_code = CO2_PS(P_local, s_local, co2_props)
        if err_code != 0:
            return err_code
        T_data.append(co2_props.temp - 273.15)
        s_data.append(co2_props.entr)
    return 0

def Ph_data_over_turbomachinery(T_in: F64, P_in: F64, T_out: F64, P_out: F64, P_data: Pointer[F64], h_data: Pointer[F64], N_points: Int = 30) -> Int:
    var co2_props: CO2_state
    var err_code: Int = 0
    var eta_isen: F64 = math.nan
    err_code = calc_turbomachinery_eta_isen(T_in, P_in, T_out, P_out, eta_isen)
    if err_code != 0:
        return err_code
    P_data.reserve(N_points)
    h_data.reserve(N_points)
    err_code = CO2_TP(T_in, P_in, co2_props)
    if err_code != 0:
        return err_code
    P_data.append(P_in / 1.0e3)
    h_data.append(co2_props.enth)
    var deltaP: F64 = (P_in - P_out) / F64(N_points - 1)
    var is_comp: Bool = False
    if deltaP < 0.0:
        is_comp = True
    var P_local: F64 = math.nan
    var h_in_local: F64 = math.nan
    var s_in_local: F64 = math.nan
    var rho_in_local: F64 = math.nan
    var T_out_local: F64 = math.nan
    var h_out_local: F64 = math.nan
    var s_out_local: F64 = math.nan
    var rho_out_local: F64 = math.nan
    var spec_work_local: F64 = math.nan
    for i in range(1, N_points):
        P_local = P_in - deltaP * F64(i)
        calculate_turbomachinery_outlet_1(T_in, P_in, P_local, eta_isen, is_comp, err_code, h_in_local, s_in_local, rho_in_local, T_out_local, h_out_local, s_out_local, rho_out_local, spec_work_local)
        if err_code != 0:
            return err_code
        P_data.append(P_local / 1.0e3)
        h_data.append(h_out_local)
    return 0

def sco2_cycle_plot_data_TS(cycle_config: Int, pres: Pointer[F64], entr: Pointer[F64], T_LTR_HP: Pointer[F64], s_LTR_HP: Pointer[F64], T_HTR_HP: Pointer[F64], s_HTR_HP: Pointer[F64], T_PHX: Pointer[F64], s_PHX: Pointer[F64], T_HTR_LP: Pointer[F64], s_HTR_LP: Pointer[F64], T_LTR_LP: Pointer[F64], s_LTR_LP: Pointer[F64], T_main_cooler: Pointer[F64], s_main_cooler: Pointer[F64], T_pre_cooler: Pointer[F64], s_pre_cooler: Pointer[F64]) -> Int:
    var n_pres: Int = pres.size()
    var n_entr: Int = entr.size()
    var err_code: Int = Ts_data_over_linear_dP_ds(pres[C_sco2_cycle_core.MC_OUT], entr[C_sco2_cycle_core.MC_OUT], pres[C_sco2_cycle_core.LTR_HP_OUT], entr[C_sco2_cycle_core.LTR_HP_OUT], T_LTR_HP, s_LTR_HP, 25)
    if err_code != 0:
        return err_code
    err_code = Ts_data_over_linear_dP_ds(pres[C_sco2_cycle_core.MIXER_OUT], entr[C_sco2_cycle_core.MIXER_OUT], pres[C_sco2_cycle_core.HTR_HP_OUT], entr[C_sco2_cycle_core.HTR_HP_OUT], T_HTR_HP, s_HTR_HP, 25)
    if err_code != 0:
        return err_code
    err_code = Ts_data_over_linear_dP_ds(pres[C_sco2_cycle_core.HTR_HP_OUT], entr[C_sco2_cycle_core.HTR_HP_OUT], pres[C_sco2_cycle_core.TURB_IN], entr[C_sco2_cycle_core.TURB_IN], T_PHX, s_PHX, 25)
    if err_code != 0:
        return err_code
    err_code = Ts_data_over_linear_dP_ds(pres[C_sco2_cycle_core.TURB_OUT], entr[C_sco2_cycle_core.TURB_OUT], pres[C_sco2_cycle_core.HTR_LP_OUT], entr[C_sco2_cycle_core.HTR_LP_OUT], T_HTR_LP, s_HTR_LP, 25)
    if err_code != 0:
        return err_code
    err_code = Ts_data_over_linear_dP_ds(pres[C_sco2_cycle_core.HTR_LP_OUT], entr[C_sco2_cycle_core.HTR_LP_OUT], pres[C_sco2_cycle_core.LTR_LP_OUT], entr[C_sco2_cycle_core.LTR_LP_OUT], T_LTR_LP, s_LTR_LP, 25)
    if err_code != 0:
        return err_code
    if cycle_config != 2:
        if (n_pres < C_sco2_cycle_core.RC_OUT + 1) or (n_entr != n_pres):
            return -1
        err_code = Ts_data_over_linear_dP_ds(pres[C_sco2_cycle_core.LTR_LP_OUT], entr[C_sco2_cycle_core.LTR_LP_OUT], pres[C_sco2_cycle_core.MC_IN], entr[C_sco2_cycle_core.MC_IN], T_main_cooler, s_main_cooler, 25)
        if err_code != 0:
            return err_code
        T_pre_cooler.reserve(1)
        T_pre_cooler.append(T_main_cooler[0])
        s_pre_cooler.reserve(1)
        s_pre_cooler.append(s_main_cooler[0])
    else:
        if (n_pres < C_sco2_cycle_core.PC_OUT + 1) or (n_entr != n_pres):
            return -1
        err_code = Ts_data_over_linear_dP_ds(pres[C_sco2_cycle_core.LTR_LP_OUT], entr[C_sco2_cycle_core.LTR_LP_OUT], pres[C_sco2_cycle_core.PC_IN], entr[C_sco2_cycle_core.PC_IN], T_pre_cooler, s_pre_cooler, 25)
        if err_code != 0:
            return err_code
        err_code = Ts_data_over_linear_dP_ds(pres[C_sco2_cycle_core.PC_OUT], entr[C_sco2_cycle_core.PC_OUT], pres[C_sco2_cycle_core.MC_IN], entr[C_sco2_cycle_core.MC_IN], T_main_cooler, s_main_cooler, 25)
        if err_code != 0:
            return err_code
    return 0

def sco2_cycle_plot_data_PH(cycle_config: Int, temp: Pointer[F64], pres: Pointer[F64], P_t: Pointer[F64], h_t: Pointer[F64], P_mc: Pointer[F64], h_mc: Pointer[F64], P_rc: Pointer[F64], h_rc: Pointer[F64], P_pc: Pointer[F64], h_pc: Pointer[F64]) -> Int:
    var n_pres: Int = pres.size()
    var n_temp: Int = temp.size()
    var err_code: Int = Ph_data_over_turbomachinery(temp[C_sco2_cycle_core.TURB_IN], pres[C_sco2_cycle_core.TURB_IN], temp[C_sco2_cycle_core.TURB_OUT], pres[C_sco2_cycle_core.TURB_OUT], P_t, h_t, 25)
    if err_code != 0:
        return err_code
    err_code = Ph_data_over_turbomachinery(temp[C_sco2_cycle_core.MC_IN], pres[C_sco2_cycle_core.MC_IN], temp[C_sco2_cycle_core.MC_OUT], pres[C_sco2_cycle_core.MC_OUT], P_mc, h_mc, 25)
    if err_code != 0:
        return err_code
    if cycle_config != 2:
        if (n_pres < C_sco2_cycle_core.RC_OUT + 1) or (n_temp != n_pres):
            return -1
        err_code = Ph_data_over_turbomachinery(temp[C_sco2_cycle_core.LTR_LP_OUT], pres[C_sco2_cycle_core.LTR_LP_OUT], temp[C_sco2_cycle_core.RC_OUT], pres[C_sco2_cycle_core.RC_OUT], P_rc, h_rc, 25)
        if err_code != 0:
            return err_code
        P_pc.reserve(1)
        P_pc.append(P_mc[0])
        h_pc.reserve(1)
        h_pc.append(h_mc[0])
    else:
        if (n_pres < C_sco2_cycle_core.PC_OUT + 1) or (n_temp != n_pres):
            return -1
        err_code = Ph_data_over_turbomachinery(temp[C_sco2_cycle_core.PC_OUT], pres[C_sco2_cycle_core.PC_OUT], temp[C_sco2_cycle_core.RC_OUT], pres[C_sco2_cycle_core.RC_OUT], P_rc, h_rc, 25)
        if err_code != 0:
            return err_code
        err_code = Ph_data_over_turbomachinery(temp[C_sco2_cycle_core.PC_IN], pres[C_sco2_cycle_core.PC_IN], temp[C_sco2_cycle_core.PC_OUT], pres[C_sco2_cycle_core.PC_OUT], P_pc, h_pc, 25)
        if err_code != 0:
            return err_code
    return 0

def Ph_arrays_over_constT(P_low: F64, P_high: F64, T_consts: Pointer[F64], P_data: Pointer[Pointer[F64]], h_data: Pointer[Pointer[F64]]) -> Int:
    var t_co2_props: CO2_state
    var n_points: Int = 200
    P_low = P_low * 1.0e3
    P_high = P_high * 1.0e3
    var deltaP: F64 = (P_high - P_low) / F64(n_points - 1)
    var n_T: Int = T_consts.size()
    P_data.reserve(n_T)
    h_data.reserve(n_T)
    var P_i: F64 = math.nan
    var prop_err_code: Int = 0
    var is_2phase_calc: Bool = False
    var P_x1: F64 = math.nan
    var h_x1: F64 = math.nan
    for j in range(n_T):
        var inner_P: Pointer[F64] = Pointer[F64].alloc(n_points)
        var inner_h: Pointer[F64] = Pointer[F64].alloc(n_points)
        P_data.append(inner_P)
        h_data.append(inner_h)
        for i in range(n_points):
            P_i = P_low + deltaP * F64(i)
            prop_err_code = CO2_TP(T_consts[j] + 273.13, P_i, t_co2_props)
            if prop_err_code != 0:
                if prop_err_code == 205:
                    prop_err_code = CO2_TQ(T_consts[j] + 273.15, 0.0, t_co2_props)
                    if prop_err_code != 0:
                        return -1
                    elif not is_2phase_calc:
                        P_data[j][i] = t_co2_props.pres / 1.0e3
                        h_data[j][i] = t_co2_props.enth
                        prop_err_code = CO2_TQ(T_consts[j] + 273.15, 1.0, t_co2_props)
                        i += 1
                        P_x1 = t_co2_props.pres / 1.0e3
                        h_x1 = t_co2_props.enth
                        P_data[j][i] = P_x1
                        h_data[j][i] = h_x1
                        is_2phase_calc = True
                    else:
                        P_data[j][i] = P_x1
                        h_data[j][i] = h_x1
                else:
                    return -1
            else:
                P_data[j][i] = t_co2_props.pres / 1.0e3
                h_data[j][i] = t_co2_props.enth
    return 0

def Ts_arrays_over_constP(T_cold: F64, T_hot: F64, P_consts: Pointer[F64], T_data: Pointer[Pointer[F64]], s_data: Pointer[Pointer[F64]]) -> Int:
    var t_co2_props: CO2_state
    var n_points: Int = 200
    T_cold = T_cold + 273.15
    T_hot = T_hot + 273.15
    var n_P: Int = P_consts.size()
    T_data.reserve(n_P)
    s_data.reserve(n_P)
    for i in range(n_P):
        var co2_err: Int = CO2_TP(T_cold, P_consts[i], t_co2_props)
        if co2_err != 0:
            return co2_err
        var s_cold: F64 = t_co2_props.entr
        co2_err = CO2_TP(T_hot, P_consts[i], t_co2_props)
        if co2_err != 0:
            return co2_err
        var s_hot: F64 = t_co2_props.entr
        var inner_T: Pointer[F64] = Pointer[F64].alloc(n_points)
        var inner_s: Pointer[F64] = Pointer[F64].alloc(n_points)
        Ts_data_over_linear_dP_ds(P_consts[i], s_cold, P_consts[i], s_hot, inner_T, inner_s, n_points)
        T_data.append(inner_T)
        s_data.append(inner_s)
    return 0

def Ts_dome(T_cold: F64, T_data: Pointer[F64], s_data: Pointer[F64]) -> Int:
    var P_data: Pointer[F64] = Pointer[F64].alloc(0)
    var h_data: Pointer[F64] = Pointer[F64].alloc(0)
    return Ts_full_dome(T_cold, T_data, s_data, P_data, h_data)

def Ts_full_dome(T_cold: F64, T_data: Pointer[F64], s_data: Pointer[F64], P_data: Pointer[F64], h_data: Pointer[F64]) -> Int:
    var t_co2_props: CO2_state
    var n_x0: Int = 50
    var n_x1: Int = 50
    var t_co2_info: CO2_info
    get_CO2_info(t_co2_info)
    var T_crit: F64 = 0.999 * t_co2_info.T_critical
    T_data.reserve(n_x0 + n_x1)
    s_data.reserve(n_x0 + n_x1)
    P_data.reserve(n_x0 + n_x1)
    h_data.reserve(n_x0 + n_x1)
    T_cold = T_cold + 273.15
    var deltaT_x0: F64 = (T_crit - T_cold) / F64(n_x0 - 1)
    var prop_err: Int = 0
    var T_i: F64 = math.nan
    for i in range(n_x0):
        T_i = T_cold + deltaT_x0 * F64(i)
        prop_err = CO2_TQ(T_i, 0.0, t_co2_props)
        if prop_err != 0:
            return -1
        T_data.append(t_co2_props.temp - 273.15)
        s_data.append(t_co2_props.entr)
        P_data.append(t_co2_props.pres / 1.0e3)
        h_data.append(t_co2_props.enth)
    var deltaT_x1: F64 = (T_cold - T_crit) / F64(n_x1 - 1)
    for i in range(n_x1):
        T_i = T_crit + deltaT_x1 * F64(i)
        prop_err = CO2_TQ(T_i, 1.0, t_co2_props)
        if prop_err != 0:
            return -1
        T_data.append(t_co2_props.temp - 273.15)
        s_data.append(t_co2_props.entr)
        P_data.append(t_co2_props.pres / 1.0e3)
        h_data.append(t_co2_props.enth)

def Ph_dome(P_low: F64, P_data: Pointer[F64], h_data: Pointer[F64]) -> Int:
    var t_co2_info: CO2_info
    get_CO2_info(t_co2_info)
    var P_crit: F64 = 0.999 * t_co2_info.P_critical
    var T_crit: F64 = 0.999 * t_co2_info.T_critical
    var T_low_limit: F64 = 1.001 * t_co2_info.temp_lower_limit
    var P_x0_eq: C_MEQ_CO2_props_at_2phase_P = C_MEQ_CO2_props_at_2phase_P()
    var P_x0_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(P_x0_eq)
    P_x0_solver.settings(1.0e-3, 100, T_low_limit, T_crit, True)
    var T_P_target_solved: F64 = math.nan
    var tol_T_P_target_solved: F64 = math.nan
    var iter_T_P_target: Int = -1
    P_low *= 1.005
    var T_P_target_code: Int = P_x0_solver.solve(T_crit - 10.0, T_crit - 20.0, P_low * 1.0e3, T_P_target_solved, tol_T_P_target_solved, iter_T_P_target)
    if T_P_target_code != C_monotonic_eq_solver.CONVERGED:
        return T_P_target_code
    var T_data: Pointer[F64] = Pointer[F64].alloc(0)
    var s_data: Pointer[F64] = Pointer[F64].alloc(0)
    return Ts_full_dome(T_P_target_solved - 273.15, T_data, s_data, P_data, h_data)

@value
struct C_MEQ_CO2_props_at_2phase_P:
    var mc_co2_props: CO2_state

    def __init__(inout self):
        self.mc_co2_props = CO2_state()

    def __call__(inout self, T_co2: F64, P_calc: Pointer[F64]) -> Int:
        var prop_err_code: Int = CO2_TQ(T_co2, 0.0, self.mc_co2_props)
        if prop_err_code != 0:
            P_calc[] = math.nan
            return prop_err_code
        P_calc[] = self.mc_co2_props.pres
        return 0

@value
struct C_HeatExchanger:
    struct S_design_parameters:
        var m_N_sub: Int
        var m_m_dot_design: Pointer[F64]
        var m_DP_design: Pointer[F64]
        var m_UA_design: F64
        var m_Q_dot_design: F64
        var m_min_DT_design: F64
        var m_eff_design: F64

        def __init__(inout self):
            self.m_N_sub = -1
            self.m_m_dot_design = Pointer[F64].alloc(2)
            self.m_m_dot_design[0] = math.nan
            self.m_m_dot_design[1] = math.nan
            self.m_DP_design = Pointer[F64].alloc(2)
            self.m_DP_design[0] = math.nan
            self.m_DP_design[1] = math.nan
            self.m_UA_design = math.nan
            self.m_Q_dot_design = math.nan
            self.m_min_DT_design = math.nan
            self.m_eff_design = math.nan

    var ms_des_par: S_design_parameters

    def __init__(inout self):
        self.ms_des_par = S_design_parameters()

    def __del__(owned self):

    def initialize(inout self, des_par_in: S_design_parameters):
        self.ms_des_par = des_par_in
        return

    def hxr_pressure_drops(inout self, m_dots: Pointer[F64], hxr_deltaP: Pointer[F64]):
        var N: Int = m_dots.size()
        hxr_deltaP.reserve(N)
        for i in range(N):
            hxr_deltaP.append(self.ms_des_par.m_DP_design[i] * math.pow(m_dots[i] / self.ms_des_par.m_m_dot_design[i], 1.75))

    def hxr_conductance(inout self, m_dots: Pointer[F64], hxr_UA: Pointer[F64]):
        var m_dot_ratio: F64 = 0.5 * (m_dots[0] / self.ms_des_par.m_m_dot_design[0] + m_dots[1] / self.ms_des_par.m_m_dot_design[1])
        hxr_UA[] = self.ms_des_par.m_UA_design * math.pow(m_dot_ratio, 0.8)

@value
struct C_turbine:
    var m_r_W_dot_scale: F64
    var m_cost_model: Int
    enum E_CARLSON_17: Int

    struct S_design_parameters:
        var m_N_design: F64
        var m_N_comp_design_if_linked: F64
        var m_P_in: F64
        var m_T_in: F64
        var m_D_in: F64
        var m_h_in: F64
        var m_s_in: F64
        var m_P_out: F64
        var m_h_out: F64
        var m_m_dot: F64

        def __init__(inout self):
            self.m_N_design = math.nan
            self.m_N_comp_design_if_linked = math.nan
            self.m_P_in = math.nan
            self.m_T_in = math.nan
            self.m_D_in = math.nan
            self.m_h_in = math.nan
            self.m_s_in = math.nan
            self.m_P_out = math.nan
            self.m_h_out = math.nan
            self.m_m_dot = math.nan

    struct S_design_solved:
        var m_nu_design: F64
        var m_D_rotor: F64
        var m_A_nozzle: F64
        var m_w_tip_ratio: F64
        var m_eta: F64
        var m_N_design: F64
        var m_delta_h_isen: F64
        var m_rho_in: F64
        var m_W_dot: F64
        var m_cost: F64

        def __init__(inout self):
            self.m_nu_design = math.nan
            self.m_D_rotor = math.nan
            self.m_A_nozzle = math.nan
            self.m_w_tip_ratio = math.nan
            self.m_eta = math.nan
            self.m_N_design = math.nan
            self.m_delta_h_isen = math.nan
            self.m_rho_in = math.nan
            self.m_W_dot = math.nan
            self.m_cost = math.nan

    struct S_od_solved:
        var m_nu: F64
        var m_eta: F64
        var m_w_tip_ratio: F64
        var m_N: F64
        var m_m_dot: F64
        var m_delta_h_isen: F64
        var m_rho_in: F64
        var m_W_dot_out: F64

        def __init__(inout self):
            self.m_nu = math.nan
            self.m_eta = math.nan
            self.m_w_tip_ratio = math.nan
            self.m_N = math.nan
            self.m_m_dot = math.nan
            self.m_W_dot_out = math.nan

    var ms_des_par: S_design_parameters
    var ms_des_solved: S_design_solved
    var ms_od_solved: S_od_solved

    def __init__(inout self):
        self.m_r_W_dot_scale = 1.0
        self.m_cost_model = C_turbine.E_CARLSON_17
        self.ms_des_par = S_design_parameters()
        self.ms_des_solved = S_design_solved()
        self.ms_od_solved = S_od_solved()

    def __del__(owned self):

    @staticmethod
    def m_nu_design() -> F64:
        return 0.7476

    def get_design_solved(inout self) -> Pointer[S_design_solved]:
        return Pointer[S_design_solved].address_of(self.ms_des_solved)

    def get_od_solved(inout self) -> Pointer[S_od_solved]:
        return Pointer[S_od_solved].address_of(self.ms_od_solved)

    def calculate_cost(inout self, T_in: F64, P_in: F64, m_dot: F64, T_out: F64, P_out: F64, W_dot: F64) -> F64:
        if self.m_cost_model == C_turbine.E_CARLSON_17:
            return 7.79 * 1.0e-3 * math.pow(W_dot, 0.6842)
        else:
            return math.nan

    def turbine_sizing(inout self, des_par_in: S_design_parameters, error_code: Pointer[Int]):
        var co2_props: CO2_state
        self.ms_des_par = des_par_in
        if self.ms_des_par.m_N_design <= 0.0:
            self.ms_des_solved.m_N_design = self.ms_des_par.m_N_comp_design_if_linked
            if self.ms_des_par.m_N_design <= 0.0:
                error_code[] = 7
                return
        else:
            self.ms_des_solved.m_N_design = self.ms_des_par.m_N_design
        var prop_error_code: Int = CO2_TD(self.ms_des_par.m_T_in, self.ms_des_par.m_D_in, co2_props)
        if prop_error_code != 0:
            error_code[] = prop_error_code
            return
        var ssnd_in: F64 = co2_props.ssnd
        prop_error_code = CO2_PS(self.ms_des_par.m_P_out, self.ms_des_par.m_s_in, co2_props)
        if prop_error_code != 0:
            error_code[] = prop_error_code
            return
        var h_s_out: F64 = co2_props.enth
        var T_out: F64 = co2_props.temp
        self.ms_des_solved.m_nu_design = C_turbine.m_nu_design()
        var w_i: F64 = self.ms_des_par.m_h_in - h_s_out
        var C_s: F64 = math.sqrt(2.0 * w_i * 1000.0)
        var U_tip: F64 = self.ms_des_solved.m_nu_design * C_s
        self.ms_des_solved.m_D_rotor = U_tip / (0.5 * self.ms_des_solved.m_N_design * 0.104719755)
        self.ms_des_solved.m_A_nozzle = (self.ms_des_par.m_m_dot / self.m_r_W_dot_scale) / (C_s * self.ms_des_par.m_D_in)
        self.ms_des_solved.m_rho_in = self.ms_des_par.m_D_in
        self.ms_des_solved.m_delta_h_isen = w_i
        self.ms_des_solved.m_w_tip_ratio = U_tip / ssnd_in
        self.ms_des_solved.m_eta = (self.ms_des_par.m_h_in - self.ms_des_par.m_h_out) / w_i
        self.ms_des_solved.m_W_dot = self.ms_des_par.m_m_dot * (self.ms_des_par.m_h_in - self.ms_des_par.m_h_out)
        self.ms_des_solved.m_cost = self.calculate_cost(self.ms_des_par.m_T_in, self.ms_des_par.m_P_in, self.ms_des_par.m_m_dot, T_out, self.ms_des_par.m_P_out, self.ms_des_solved.m_W_dot)

    def off_design_turbine(inout self, T_in: F64, P_in: F64, P_out: F64, N: F64, error_code: Pointer[Int], m_dot_cycle: Pointer[F64], T_out: Pointer[F64]):
        var co2_props: CO2_state
        var prop_error_code: Int = CO2_TP(T_in, P_in, co2_props)
        if prop_error_code != 0:
            error_code[] = prop_error_code
            return
        var D_in: F64 = co2_props.dens
        var h_in: F64 = co2_props.enth
        var s_in: F64 = co2_props.entr
        var ssnd_in: F64 = co2_props.ssnd
        prop_error_code = CO2_PS(P_out, s_in, co2_props)
        if prop_error_code != 0:
            error_code[] = prop_error_code
            return
        var h_s_out: F64 = co2_props.enth
        var C_s: F64 = math.sqrt(2.0 * (h_in - h_s_out) * 1000.0)
        var U_tip: F64 = self.ms_des_solved.m_D_rotor * 0.5 * N * 0.104719755
        self.ms_od_solved.m_nu = U_tip / C_s
        var eta_0: F64 = (((1.0626 * self.ms_od_solved.m_nu - 3.0874) * self.ms_od_solved.m_nu + 1.3668) * self.ms_od_solved.m_nu + 1.3567) * self.ms_od_solved.m_nu + 0.179921180
        eta_0 = math.max(eta_0, 0.0)
        eta_0 = math.min(eta_0, 1.0)
        self.ms_od_solved.m_eta = eta_0 * self.ms_des_solved.m_eta
        var h_out: F64 = h_in - self.ms_od_solved.m_eta * (h_in - h_s_out)
        prop_error_code = CO2_PH(P_out, h_out, co2_props)
        if prop_error_code != 0:
            error_code[] = prop_error_code
            return
        T_out[] = co2_props.temp
        var m_dot_basis: F64 = C_s * self.ms_des_solved.m_A_nozzle * D_in
        self.ms_od_solved.m_w_tip_ratio = U_tip / ssnd_in
        self.ms_od_solved.m_N = N
        m_dot_cycle[] = m_dot_basis * self.m_r_W_dot_scale
        self.ms_od_solved.m_W_dot_out = m_dot_cycle[] * (h_in - h_out)
        self.ms_od_solved.m_m_dot = m_dot_cycle[]
        self.ms_od_solved.m_delta_h_isen = h_in - h_s_out
        self.ms_od_solved.m_rho_in = D_in

    def od_turbine_at_N_des(inout self, T_in: F64, P_in: F64, P_out: F64, error_code: Pointer[Int], m_dot_cycle: Pointer[F64], T_out: Pointer[F64]):
        var N: F64 = self.ms_des_solved.m_N_design
        self.off_design_turbine(T_in, P_in, P_out, N, error_code, m_dot_cycle, T_out)
        return

@value
struct C_comp__psi_eta_vs_phi:
    enum E_comp_models:
        E_snl_radial_via_Dyreby

    struct S_des_solved:
        var m_T_in: F64
        var m_P_in: F64
        var m_D_in: F64
        var m_h_in: F64
        var m_s_in: F64
        var m_T_out: F64
        var m_P_out: F64
        var m_h_out: F64
        var m_D_out: F64
        var m_m_dot: F64
        var m_D_rotor: F64
        var m_N_design: F64
        var m_tip_ratio: F64
        var m_eta_design: F64
        var m_phi_des: F64
        var m_phi_surge: F64
        var m_phi_max: F64
        var m_psi_des: F64
        var m_psi_max_at_N_des: F64

        def __init__(inout self):
            self.m_T_in = math.nan
            self.m_P_in = math.nan
            self.m_D_in = math.nan
            self.m_h_in = math.nan
            self.m_s_in = math.nan
            self.m_T_out = math.nan
            self.m_P_out = math.nan
            self.m_h_out = math.nan
            self.m_D_out = math.nan
            self.m_m_dot = math.nan
            self.m_D_rotor = math.nan
            self.m_N_design = math.nan
            self.m_tip_ratio = math.nan
            self.m_eta_design = math.nan
            self.m_phi_des = math.nan
            self.m_phi_surge = math.nan
            self.m_phi_max = math.nan
            self.m_psi_des = math.nan
            self.m_psi_max_at_N_des = math.nan

    struct S_od_solved:
        var m_P_in: F64
        var m_h_in: F64
        var m_T_in: F64
        var m_s_in: F64
        var m_P_out: F64
        var m_h_out: F64
        var m_T_out: F64
        var m_s_out: F64
        var m_surge: Bool
        var m_eta: F64
        var m_phi: F64
        var m_psi: F64
        var m_w_tip_ratio: F64
        var m_N: F64
        var m_W_dot_in: F64
        var m_surge_safety: F64

        def __init__(inout self):
            self.m_P_in = math.nan
            self.m_h_in = math.nan
            self.m_T_in = math.nan
            self.m_s_in = math.nan
            self.m_P_out = math.nan
            self.m_h_out = math.nan
            self.m_T_out = math.nan
            self.m_s_out = math.nan
            self.m_surge = False
            self.m_eta = math.nan
            self.m_phi = math.nan
            self.m_psi = math.nan
            self.m_w_tip_ratio = math.nan
            self.m_N = math.nan
            self.m_W_dot_in = math.nan
            self.m_surge_safety = math.nan

    var ms_des_solved: S_des_solved
    var ms_od_solved: S_od_solved

    def __init__(inout self):
        self.ms_des_solved = S_des_solved()
        self.ms_od_solved = S_od_solved()

    def __del__(owned self):

    def design_given_shaft_speed(inout self, T_in: F64, P_in: F64, m_dot: F64, N_rpm: F64, eta_isen: F64, P_out: Pointer[F64], T_out: Pointer[F64], tip_ratio: Pointer[F64]) -> Int:
        var co2_props: CO2_state
        var prop_error_code: Int = CO2_TP(T_in, P_in, co2_props)
        if prop_error_code != 0:
            return prop_error_code
        var h_in: F64 = co2_props.enth
        var s_in: F64 = co2_props.entr
        var rho_in: F64 = co2_props.dens
        var N_rad_s: F64 = N_rpm / 9.549296590
        var phi_design: F64 = self.calc_phi_design(T_in, P_in)
        var D_rotor: F64 = math.pow(m_dot / (phi_design * rho_in * 0.5 * N_rad_s), 1.0 / 3.0)
        var psi_design: F64 = self.calc_psi_isen_design(T_in, P_in)
        var U_tip: F64 = 0.5 * D_rotor * N_rad_s
        var w_i: F64 = psi_design * math.pow(U_tip, 2) * 0.001
        var h_out_isen: F64 = h_in + w_i
        prop_error_code = CO2_HS(h_out_isen, s_in, co2_props)
        if prop_error_code != 0:
            return prop_error_code
        P_out[] = co2_props.pres
        var h_out: F64 = h_in + w_i / eta_isen
        prop_error_code = CO2_PH(P_out[], h_out, co2_props)
        if prop_error_code != 0:
            return prop_error_code
        T_out[] = co2_props.temp
        var ssnd_out: F64 = co2_props.ssnd
        tip_ratio[] = U_tip / ssnd_out
        self.ms_des_solved.m_T_in = T_in
        self.ms_des_solved.m_P_in = P_in
        self.ms_des_solved.m_D_in = rho_in
        self.ms_des_solved.m_h_in = h_in
        self.ms_des_solved.m_s_in = s_in
        self.ms_des_solved.m_T_out = T_out[]
        self.ms_des_solved.m_P_out = P_out[]
        self.ms_des_solved.m_h_out = h_out
        self.ms_des_solved.m_D_out = co2_props.dens
        self.ms_des_solved.m_m_dot = m_dot
        self.ms_des_solved.m_D_rotor = D_rotor
        self.ms_des_solved.m_N_design = N_rpm
        self.ms_des_solved.m_tip_ratio = tip_ratio[]
        self.ms_des_solved.m_eta_design = eta_isen
        self.ms_des_solved.m_phi_des = phi_design
        self.ms_des_solved.m_phi_surge = self.calc_phi_min(T_in, P_in)
        self.ms_des_solved.m_phi_max = self.calc_phi_max(T_in, P_in)
        self.set_design_solution(phi_design, T_in, P_in)
        self.ms_des_solved.m_psi_des = psi_design
        self.ms_des_solved.m_psi_max_at_N_des = self.calc_psi_isen(self.ms_des_solved.m_phi_surge, 1.0, T_in, P_in)
        return 0

    def design_given_performance(inout self, T_in: F64, P_in: F64, m_dot: F64, T_out: F64, P_out: F64) -> Int:
        var in_props: CO2_state
        var prop_err_code: Int = CO2_TP(T_in, P_in, in_props)
        if prop_err_code != 0:
            return -1
        var s_in: F64 = in_props.entr
        var h_in: F64 = in_props.enth
        var rho_in: F64 = in_props.dens
        var isen_out_props: CO2_state
        prop_err_code = CO2_PS(P_out, s_in, isen_out_props)
        if prop_err_code != 0:
            return -1
        var h_isen_out: F64 = isen_out_props.enth
        var out_props: CO2_state
        prop_err_code = CO2_TP(T_out, P_out, out_props)
        if prop_err_code != 0:
            return -1
        var h_out: F64 = out_props.enth
        var phi_design: F64 = self.calc_phi_design(T_in, P_in)
        var psi_design: F64 = self.calc_psi_isen_design(T_in, P_in)
        var w_i: F64 = h_isen_out - h_in
        var U_tip: F64 = math.sqrt(1000.0 * w_i / psi_design)
        var D_rotor: F64 = math.sqrt(m_dot / (phi_design * rho_in * U_tip))
        var N_rad_s: F64 = U_tip * 2.0 / D_rotor
        var ssnd_out: F64 = out_props.ssnd
        var tip_ratio: F64 = U_tip / ssnd_out
        self.ms_des_solved.m_T_in = T_in
        self.ms_des_solved.m_P_in = P_in
        self.ms_des_solved.m_D_in = rho_in
        self.ms_des_solved.m_h_in = h_in
        self.ms_des_solved.m_s_in = s_in
        self.ms_des_solved.m_T_out = T_out
        self.ms_des_solved.m_P_out = P_out
        self.ms_des_solved.m_h_out = h_out
        self.ms_des_solved.m_D_out = out_props.dens
        self.ms_des_solved.m_m_dot = m_dot
        self.ms_des_solved.m_D_rotor = D_rotor
        self.ms_des_solved.m_N_design = N_rad_s * 9.549296590
        self.ms_des_solved.m_tip_ratio = tip_ratio
        self.ms_des_solved.m_eta_design = (h_isen_out - h_in) / (h_out - h_in)
        self.ms_des_solved.m_phi_des = self.calc_phi_design(T_in, P_in)
        self.ms_des_solved.m_phi_surge = self.calc_phi_min(T_in, P_in)
        self.ms_des_solved.m_phi_max = self.calc_phi_max(T_in, P_in)
        self.set_design_solution(phi_design, T_in, P_in)
        self.ms_des_solved.m_psi_des = psi_design
        self.ms_des_solved.m_psi_max_at_N_des = self.calc_psi_isen(self.ms_des_solved.m_phi_surge, 1.0, T_in, P_in)
        return 0

    def off_design_given_N(inout self, T_in: F64, P_in: F64, m_dot: F64, N_rpm: F64, T_out: Pointer[F64], P_out: Pointer[F64]) -> Int:
        var co2_props: CO2_state
        self.ms_od_solved.m_N = N_rpm
        var prop_error_code: Int = CO2_TP(T_in, P_in, co2_props)
        if prop_error_code != 0:
            return prop_error_code
        var rho_in: F64 = co2_props.dens
        var h_in: F64 = co2_props.enth
        var s_in: F64 = co2_props.entr
        var U_tip: F64 = self.ms_des_solved.m_D_rotor * 0.5 * self.ms_od_solved.m_N * 0.104719755
        var phi: F64 = m_dot / (rho_in * U_tip * math.pow(self.ms_des_solved.m_D_rotor, 2))
        var phi_min: F64 = self.calc_phi_min(T_in, P_in)
        if phi < phi_min:
            self.ms_od_solved.m_surge = True
        else:
            self.ms_od_solved.m_surge = False
        var N_des_over_N_od: F64 = self.ms_des_solved.m_N_design / N_rpm
        var psi: F64 = self.calc_psi_isen(phi, N_des_over_N_od, T_in, P_in)
        var eta_ND_od: F64 = self.calc_eta_OD_normalized(phi, N_des_over_N_od, T_in, P_in)
        self.ms_od_solved.m_eta = math.max(eta_ND_od * self.ms_des_solved.m_eta_design, 0.0)
        if psi <= 0.0:
            return 1
        var dh_s: F64 = psi * math.pow(U_tip, 2.0) * 0.001
        var dh: F64 = dh_s / self.ms_od_solved.m_eta
        var h_s_out: F64 = h_in + dh_s
        var h_out: F64 = h_in + dh
        prop_error_code = CO2_HS(h_s_out, s_in, co2_props)
        if prop_error_code != 0:
            return 2
        P_out[] = co2_props.pres
        prop_error_code = CO2_PH(P_out[], h_out, co2_props)
        if prop_error_code != 0:
            return 2
        T_out[] = co2_props.temp
        var ssnd_out: F64 = co2_props.ssnd
        self.ms_od_solved.m_P_in = P_in
        self.ms_od_solved.m_h_in = h_in
        self.ms_od_solved.m_T_in = T_in
        self.ms_od_solved.m_s_in = s_in
        self.ms_od_solved.m_P_out = P_out[]
        self.ms_od_solved.m_h_out = h_out
        self.ms_od_solved.m_T_out = T_out[]
        self.ms_od_solved.m_s_out = co2_props.entr
        self.ms_od_solved.m_phi = phi
        self.ms_od_solved.m_psi = psi
        self.ms_od_solved.m_surge_safety = phi / phi_min
        self.ms_od_solved.m_w_tip_ratio = U_tip / ssnd_out
        self.ms_od_solved.m_W_dot_in = m_dot * (h_out - h_in)
        return 0

    def calc_N_from_phi(inout self, T_in: F64, P_in: F64, m_dot: F64, phi_in: F64, N_rpm: Pointer[F64]) -> Int:
        var co2_props: CO2_state
        var prop_error_code: Int = CO2_TP(T_in, P_in, co2_props)
        if prop_error_code != 0:
            return prop_error_code
        var rho_in: F64 = co2_props.dens
        var U_tip: F64 = m_dot / (phi_in * rho_in * math.pow(self.ms_des_solved.m_D_rotor, 2))
        N_rpm[] = (U_tip * 2.0 / self.ms_des_solved.m_D_rotor) * 9.549296590
        return 0

    def calc_m_dot__phi_des(inout self, T_in: F64, P_in: F64, N_rpm: F64, m_dot: Pointer[F64]) -> Int:
        var co2_props: CO2_state
        var prop_error_code: Int = CO2_TP(T_in, P_in, co2_props)
        if prop_error_code != 0:
            return prop_error_code
        var rho_in: F64 = co2_props.dens
        var h_in: F64 = co2_props.enth
        var s_in: F64 = co2_props.entr
        var U_tip: F64 = self.ms_des_solved.m_D_rotor * 0.5 * N_rpm * 0.104719755
        m_dot[] = self.ms_des_solved.m_phi_des * U_tip * rho_in * math.pow(self.ms_des_solved.m_D_rotor, 2)
        return 0

    @staticmethod
    def construct_derived_C_comp__psi_eta_vs_phi(comp_model_code: Int) -> C_comp__psi_eta_vs_phi:
        if comp_model_code == C_comp__psi_eta_vs_phi.E_comp_models.E_snl_radial_via_Dyreby:
            return C_comp__snl_radial_via_Dyreby()
        else:
            raise Error("C_comp__psi_eta_vs_phi::construct_derived_C_comp__psi_eta_vs_phi unrecognized compressor model code")

    def set_design_solution(inout self, phi: F64, T_comp_in_des: F64, P_comp_in: F64):

    def report_phi_psi_eta_vectors(inout self, phi: Pointer[F64], psi: Pointer[F64], eta: Pointer[F64], eta_norm_design: Pointer[F64]):

    def calc_phi_min(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return math.nan  # pure virtual, should be overridden

    def calc_phi_design(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return math.nan

    def calc_phi_max(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return math.nan

    def calc_psi_isen_design(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return math.nan

    def calc_psi_isen(inout self, phi: F64, N_des_over_N_od: F64, T_comp_in: F64, P_comp_in: F64) -> F64:
        return math.nan

    def calc_eta_OD_normalized(inout self, phi: F64, N_des_over_N_od: F64, T_comp_in: F64, P_comp_in: F64) -> F64:
        return math.nan

@value
struct C_comp__snl_radial_via_Dyreby(C_comp__psi_eta_vs_phi):
    var m_phi_design: F64
    var m_phi_min: F64
    var m_phi_max: F64

    def __init__(inout self):
        self.m_phi_design = 0.02971
        self.m_phi_min = 0.0225
        self.m_phi_max = 0.05
        self.ms_des_solved = C_comp__psi_eta_vs_phi.S_des_solved()
        self.ms_od_solved = C_comp__psi_eta_vs_phi.S_od_solved()

    def adjust_phi_for_N(inout self, phi: F64, N_des_over_N_od: F64) -> F64:
        return phi * math.pow(1.0 / N_des_over_N_od, 0.2)

    def set_design_solution(inout self, phi: F64, T_comp_in_des: F64, P_comp_in: F64):

    def report_phi_psi_eta_vectors(inout self, phi: Pointer[F64], psi: Pointer[F64], eta: Pointer[F64], eta_norm_design: Pointer[F64]):
        var T_comp_dummy: F64 = math.nan
        var P_comp_dummy: F64 = math.nan
        var phi_min: F64 = self.calc_phi_min(T_comp_dummy, P_comp_dummy)
        var phi_max: F64 = self.calc_phi_max(T_comp_dummy, P_comp_dummy)
        var n_phi: Int = 20
        phi.reserve(n_phi)
        psi.reserve(n_phi)
        eta.reserve(n_phi)
        var delta_phi: F64 = (phi_max - phi_min) / F64(n_phi - 1)
        var i_phi: F64 = 0.0
        for i in range(n_phi):
            i_phi = phi_min + F64(i) * delta_phi
            phi.append(i_phi)
            psi.append(self.calc_psi_isen(i_phi, 1.0, T_comp_dummy, P_comp_dummy))
            eta.append(self.calc_eta_OD_normalized(i_phi, 1.0, T_comp_dummy, P_comp_dummy))
        eta_norm_design[] = 1.0

    def calc_phi_min(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return self.m_phi_min

    def calc_phi_design(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return self.m_phi_design

    def calc_phi_max(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return self.m_phi_max

    def calc_psi_isen_design(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        var phi_design: F64 = self.calc_phi_design(T_comp_in, P_comp_in)
        return self.calc_psi_isen(phi_design, 1.0, T_comp_in, P_comp_in)

    def calc_psi_isen(inout self, phi_in: F64, N_des_over_N_od: F64, T_comp_in: F64, P_comp_in: F64) -> F64:
        var phi: F64 = self.adjust_phi_for_N(phi_in, N_des_over_N_od)
        var psi: F64 = math.nan
        if phi >= self.m_phi_min:
            psi = ((((-498626.0 * phi) + 53224.0) * phi - 2505.0) * phi + 54.6) * phi + 0.04049
        else:
            var psi_at_surge: F64 = ((((-498626.0 * self.m_phi_min) + 53224.0) * self.m_phi_min - 2505.0) * self.m_phi_min + 54.6) * self.m_phi_min + 0.04049
            psi = (1 + 0.5 * (self.m_phi_min - phi) / self.m_phi_min) * psi_at_surge
        return psi / math.pow(N_des_over_N_od, math.pow(20.0 * phi, 3.0))

    def calc_eta_OD_normalized(inout self, phi_in: F64, N_des_over_N_od: F64, T_comp_in: F64, P_comp_in: F64) -> F64:
        var phi: F64 = self.adjust_phi_for_N(phi_in, N_des_over_N_od)
        var eta_star: F64 = ((((-1.638e6 * phi) + 182725.0) * phi - 8089.0) * phi + 168.6) * phi - 0.7069
        return eta_star * 1.47528 / math.pow(N_des_over_N_od, math.pow(20.0 * phi, 5.0))

@value
struct C_comp__compA__PT_map_template(C_comp__psi_eta_vs_phi):
    var mc_data_at_PT: Linear_Interp
    var m_P_mc_in: F64
    var m_T_mc_in: F64
    var m_phi_design: F64
    var m_phi_min: F64
    var m_phi_max: F64
    var m_eta_isen_norm: F64

    def __init__(inout self):
        self.mc_data_at_PT = Linear_Interp()
        self.m_P_mc_in = math.nan
        self.m_T_mc_in = math.nan
        self.m_phi_design = math.nan
        self.m_phi_min = math.nan
        self.m_phi_max = math.nan
        self.m_eta_isen_norm = math.nan
        self.ms_des_solved = C_comp__psi_eta_vs_phi.S_des_solved()
        self.ms_od_solved = C_comp__psi_eta_vs_phi.S_od_solved()

    def set_design_solution(inout self, phi: F64, T_comp_in_des: F64, P_comp_in: F64):

    def report_phi_psi_eta_vectors(inout self, phi: Pointer[F64], psi: Pointer[F64], eta: Pointer[F64], eta_norm_design: Pointer[F64]):
        var phi_temp: Pointer[F64] = self.mc_data_at_PT.get_column_data(0)
        var n_pts: Int = phi_temp.size() - 1
        phi.reserve(n_pts)
        psi.reserve(n_pts)
        eta.reserve(n_pts)
        for i in range(1, n_pts + 1):
            phi.append(phi_temp[i])
            psi.append(self.mc_data_at_PT.get_column_data(1)[i])
            eta.append(self.mc_data_at_PT.get_column_data(2)[i])
        eta_norm_design[] = self.m_eta_isen_norm

    def calc_phi_min(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return self.m_phi_min

    def calc_phi_design(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return self.m_phi_design

    def calc_phi_max(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        return self.m_phi_max

    def calc_psi_isen_design(inout self, T_comp_in: F64, P_comp_in: F64) -> F64:
        var phi_design: F64 = self.calc_phi_design(T_comp_in, P_comp_in)
        return self.calc_psi_isen(phi_design, 1.0, T_comp_in, P_comp_in)

    def calc_psi_isen(inout self, phi: F64, N_des_over_N_od: F64, T_comp_in: F64, P_comp_in: F64) -> F64:
        return self.mc_data_at_PT.linear_1D_interp(0, 1, phi)

    def calc_eta_OD_normalized(inout self, phi: F64, N_des_over_N_od: F64, T_comp_in: F64, P_comp_in: F64) -> F64:
        return self.mc_data_at_PT.linear_1D_interp(0, 2, phi)

@value
struct C_comp_multi_stage:
    var mv_c_stages: Pointer[Pointer[C_comp__psi_eta_vs_phi]]  # dynamic array of unique_ptr-like
    var m_r_W_dot_scale: F64
    var m_cost_model: Int
    var m_compressor_model: Int
    enum E_CARLSON_17: Int

    struct S_des_solved:
        var m_T_in: F64
        var m_P_in: F64
        var m_D_in: F64
        var m_h_in: F64
        var m_s_in: F64
        var m_T_out: F64
        var m_P_out: F64
        var m_h_out: F64
        var m_D_out: F64
        var m_isen_spec_work: F64
        var m_m_dot: F64
        var m_W_dot: F64
        var m_cost: F64
        var m_n_stages: Int
        var m_tip_ratio_max: F64
        var m_N_design: F64
        var m_phi_des: F64
        var m_phi_surge: F64
        var m_psi_des: F64
        var m_psi_max_at_N_des: F64
        var mv_D: Pointer[F64]
        var mv_tip_speed_ratio: Pointer[F64]
        var mv_eta_stages: Pointer[F64]

        def __init__(inout self):
            self.m_n_stages = -1
            self.m_T_in = math.nan
            self.m_P_in = math.nan
            self.m_D_in = math.nan
            self.m_h_in = math.nan
            self.m_s_in = math.nan
            self.m_T_out = math.nan
            self.m_P_out = math.nan
            self.m_h_out = math.nan
            self.m_D_out = math.nan
            self.m_isen_spec_work = math.nan
            self.m_m_dot = math.nan
            self.m_W_dot = math.nan
            self.m_cost = math.nan
            self.m_tip_ratio_max = math.nan
            self.m_N_design = math.nan
            self.m_phi_des = math.nan
            self.m_psi_des = math.nan
            self.m_phi_surge = math.nan
            self.mv_D = Pointer[F64].alloc(0)
            self.mv_tip_speed_ratio = Pointer[F64].alloc(0)
            self.mv_eta_stages = Pointer[F64].alloc(0)

    struct S_od_solved:
        var m_P_in: F64
        var m_T_in: F64
        var m_P_out: F64
        var m_T_out: F64
        var m_m_dot: F64
        var m_isen_spec_work: F64
        var m_surge: Bool
        var m_eta: F64
        var m_phi_min: F64
        var m_tip_ratio_max: F64
        var m_N: F64
        var m_W_dot_in: F64
        var m_surge_safety: F64
        var mv_tip_speed_ratio: Pointer[F64]
        var mv_phi: Pointer[F64]
        var mv_psi: Pointer[F64]
        var mv_eta: Pointer[F64]

        def __init__(inout self):
            self.m_P_in = math.nan
            self.m_T_in = math.nan
            self.m_P_out = math.nan
            self.m_T_out = math.nan
            self.m_m_dot = math.nan
            self.m_isen_spec_work = math.nan
            self.m_surge = False
            self.m_eta = math.nan
            self.m_phi_min = math.nan
            self.m_tip_ratio_max = math.nan
            self.m_N = math.nan
            self.m_W_dot_in = math.nan
            self.m_surge_safety = math.nan
            self.mv_tip_speed_ratio = Pointer[F64].alloc(0)
            self.mv_phi = Pointer[F64].alloc(0)
            self.mv_psi = Pointer[F64].alloc(0)
            self.mv_eta = Pointer[F64].alloc(0)

    var ms_des_solved: S_des_solved
    var ms_od_solved: S_od_solved

    def __init__(inout self):
        self.mv_c_stages = Pointer[Pointer[C_comp__psi_eta_vs_phi]].alloc(0)
        self.m_r_W_dot_scale = 1.0
        self.m_cost_model = C_comp_multi_stage.E_CARLSON_17
        self.m_compressor_model = -1
        self.ms_des_solved = S_des_solved()
        self.ms_od_solved = S_od_solved()

    def __del__(owned self):

    def get_design_solved(inout self) -> Pointer[S_des_solved]:
        return Pointer[S_des_solved].address_of(self.ms_des_solved)

    def get_od_solved(inout self) -> Pointer[S_od_solved]:
        return Pointer[S_od_solved].address_of(self.ms_od_solved)

    @value
    struct C_MEQ_eta_isen__h_out(C_monotonic_equation):
        var mpc_multi_stage: Pointer[C_comp_multi_stage]
        var m_T_in: F64
        var m_P_in: F64
        var m_P_out: F64
        var m_m_dot_basis: F64
        var m_tol_in: F64

        def __init__(inout self, pc_multi_stage: Pointer[C_comp_multi_stage], T_in: F64, P_in: F64, P_out: F64, m_dot_basis: F64, tol: F64):
            self.mpc_multi_stage = pc_multi_stage
            self.m_T_in = T_in
            self.m_P_in = P_in
            self.m_P_out = P_out
            self.m_m_dot_basis = m_dot_basis
            self.m_tol_in = tol

        def __call__(inout self, eta_isen: F64, h_comp_out: Pointer[F64]) -> Int:
            var c_stages: C_comp_multi_stage.C_MEQ_N_rpm__P_out = C_comp_multi_stage.C_MEQ_N_rpm__P_out(self.mpc_multi_stage, self.m_T_in, self.m_P_in, self.m_m_dot_basis, eta_isen)
            var c_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_stages)
            var N_rpm_lower: F64 = 1.0e-4
            var N_rpm_upper: F64 = math.nan
            var N_rpm_guess_1: F64 = 3000.0
            var N_rpm_guess_2: F64 = 30000.0
            var tol: F64 = self.m_tol_in / 10.0
            c_solver.settings(tol, 50, N_rpm_lower, N_rpm_upper, True)
            var N_rpm_solved: F64 = math.nan
            var tol_solved: F64 = math.nan
            var iter_solved: Int = -1
            var N_rpm_code: Int = 0
            try:
                N_rpm_code = c_solver.solve(N_rpm_guess_1, N_rpm_guess_2, self.m_P_out, N_rpm_solved, tol_solved, iter_solved)
            except:
                raise Error("C_comp_multi_stage::C_MEQ_eta_isen__h_out threw an exception")
            if N_rpm_code != C_monotonic_eq_solver.CONVERGED:
                if not (N_rpm_code > C_monotonic_eq_solver.CONVERGED and math.fabs(tol_solved) < 0.01):
                    raise Error("C_comp_multi_stage::C_MEQ_eta_isen__h_out failed to converge within a reasonable tolerance")
            var n_stages: Int = self.mpc_multi_stage[].mv_c_stages.size()
            h_comp_out[] = self.mpc_multi_stage[].mv_c_stages[n_stages - 1][].ms_des_solved.m_h_out
            return 0

    @value
    struct C_MEQ_N_rpm__P_out(C_monotonic_equation):
        var mpc_multi_stage: Pointer[C_comp_multi_stage]
        var m_T_in: F64
        var m_P_in: F64
        var m_m_dot_basis: F64
        var m_eta_isen: F64

        def __init__(inout self, pc_multi_stage: Pointer[C_comp_multi_stage], T_in: F64, P_in: F64, m_dot_basis: F64, eta_isen: F64):
            self.mpc_multi_stage = pc_multi_stage
            self.m_T_in = T_in
            self.m_P_in = P_in
            self.m_m_dot_basis = m_dot_basis
            self.m_eta_isen = eta_isen

        def __call__(inout self, N_rpm: F64, P_comp_out: Pointer[F64]) -> Int:
            var n_stages: Int = self.mpc_multi_stage[].mv_c_stages.size()
            var T_in: F64 = self.m_T_in
            var P_in: F64 = self.m_P_in
            var P_out: F64 = math.nan
            var T_out: F64 = math.nan
            var tip_ratio: F64 = math.nan
            var comp_err_code: Int = 0
            for i in range(n_stages):
                if i > 0:
                    T_in = T_out
                    P_in = P_out
                var new_stage: C_comp__psi_eta_vs_phi = C_comp__psi_eta_vs_phi.construct_derived_C_comp__psi_eta_vs_phi(self.mpc_multi_stage[].m_compressor_model)
                self.mpc_multi_stage[].mv_c_stages[i] = Pointer[C_comp__psi_eta_vs_phi].address_of(new_stage)
                comp_err_code = self.mpc_multi_stage[].mv_c_stages[i][].design_given_shaft_speed(T_in, P_in, self.m_m_dot_basis, N_rpm, self.m_eta_isen, P_out, T_out, tip_ratio)
                if comp_err_code != 0:
                    P_comp_out[] = math.nan
                    return -1
            P_comp_out[] = P_out
            return 0

    struct C_MEQ_phi_od__P_out(C_monotonic_equation):
        var mpc_multi_stage: Pointer[C_comp_multi_stage]
        var m_T_in: F64
        var m_P_in: F64
        var m_m_dot_cycle: F64

        def __init__(inout self, pc_multi_stage: Pointer[C_comp_multi_stage], T_in: F64, P_in: F64, m_dot_cycle: F64):
            self.mpc_multi_stage = pc_multi_stage
            self.m_T_in = T_in
            self.m_P_in = P_in
            self.m_m_dot_cycle = m_dot_cycle

        def __call__(inout self, phi_od: F64, P_comp_out: Pointer[F64]) -> Int:
            var m_dot_basis: F64 = self.m_m_dot_cycle / self.mpc_multi_stage[].m_r_W_dot_scale
            var error_code: Int = 0
            var N_rpm: F64 = math.nan
            error_code = self.mpc_multi_stage[].mv_c_stages[0][].calc_N_from_phi(self.m_T_in, self.m_P_in, m_dot_basis, phi_od, N_rpm)
            if error_code != 0:
                P_comp_out[] = math.nan
                return error_code
            var T_out: F64 = math.nan
            error_code = 0
            self.mpc_multi_stage[].off_design_given_N(self.m_T_in, self.m_P_in, self.m_m_dot_cycle, N_rpm, error_code, T_out, P_comp_out[])
            if error_code != 0:
                P_comp_out[] = math.nan
                return error_code
            return 0

    def calculate_cost(inout self, T_in: F64, P_in: F64, m_dot: F64, T_out: F64, P_out: F64, W_dot: F64) -> F64:
        if self.m_cost_model == C_comp_multi_stage.E_CARLSON_17:
            return 6.898 * 1.0e-3 * math.pow(W_dot, 0.7865)
        else:
            return math.nan

    def design_given_outlet_state(inout self, comp_model_code: Int, T_in: F64, P_in: F64, m_dot_cycle: F64, T_out: F64, P_out: F64, tol: F64) -> Int:
        self.m_compressor_model = comp_model_code
        var m_dot_basis: F64 = m_dot_cycle / self.m_r_W_dot_scale
        self.mv_c_stages = Pointer[Pointer[C_comp__psi_eta_vs_phi]].alloc(1)
        var first_stage: C_comp__psi_eta_vs_phi = C_comp__psi_eta_vs_phi.construct_derived_C_comp__psi_eta_vs_phi(self.m_compressor_model)
        self.mv_c_stages[0] = Pointer[C_comp__psi_eta_vs_phi].address_of(first_stage)
        self.mv_c_stages[0][].design_given_performance(T_in, P_in, m_dot_basis, T_out, P_out)
        var max_calc_tip_speed: F64 = self.mv_c_stages[0][].ms_des_solved.m_tip_ratio
        var tip_speed_limit: F64 = 0.85
        var co2_props: CO2_state
        var h_in: F64 = self.mv_c_stages[0][].ms_des_solved.m_h_in
        var s_in: F64 = self.mv_c_stages[0][].ms_des_solved.m_s_in
        var prop_err_code: Int = CO2_PS(P_out, s_in, co2_props)
        if prop_err_code != 0:
            return -1
        var h_out_isen: F64 = co2_props.enth
        if self.mv_c_stages[0][].ms_des_solved.m_tip_ratio > tip_speed_limit:
            var h_out: F64 = self.mv_c_stages[0][].ms_des_solved.m_h_out
            var eta_isen_total: F64 = (h_out_isen - h_in) / (h_out - h_in)
            var is_add_stages: Bool = True
            var n_stages: Int = 1
            while is_add_stages:
                tip_speed_limit = 0.9
                n_stages += 1
                self.mv_c_stages = Pointer[Pointer[C_comp__psi_eta_vs_phi]].alloc(n_stages)
                var c_stages: C_comp_multi_stage.C_MEQ_eta_isen__h_out = C_comp_multi_stage.C_MEQ_eta_isen__h_out(Pointer[C_comp_multi_stage].address_of(self), T_in, P_in, P_out, m_dot_basis, tol)
                var c_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_stages)
                var eta_isen_lower: F64 = 0.1
                var eta_isen_upper: F64 = 1.0
                var eta_isen_guess_1: F64 = eta_isen_total
                var eta_isen_guess_2: F64 = 0.95 * eta_isen_total
                c_solver.settings(tol / 10.0, 50, eta_isen_lower, eta_isen_upper, True)
                var eta_isen_solved: F64 = math.nan
                var tol_solved: F64 = math.nan
                var iter_solved: Int = -1
                var eta_isen_code: Int = 0
                try:
                    eta_isen_code = c_solver.solve(eta_isen_guess_1, eta_isen_guess_2, h_out, eta_isen_solved, tol_solved, iter_solved)
                except:
                    raise Error("C_comp_multi_stage::design_given_outlet_state threw an exception")
                if eta_isen_code != C_monotonic_eq_solver.CONVERGED:
                    if not (eta_isen_code > C_monotonic_eq_solver.CONVERGED and math.fabs(tol_solved) < 0.01):
                        raise Error("C_comp_multi_stage::design_given_outlet_state failed to converge within a reasonable tolerance")
                max_calc_tip_speed = 0.0
                for i in range(n_stages):
                    max_calc_tip_speed = math.max(max_calc_tip_speed, self.mv_c_stages[i][].ms_des_solved.m_tip_ratio)
                if max_calc_tip_speed < tip_speed_limit:
                    is_add_stages = False
                if n_stages > 20:
                    return -1
        var n_stages_final: Int = self.mv_c_stages.size()
        self.ms_des_solved.m_T_in = T_in
        self.ms_des_solved.m_P_in = P_in
        self.ms_des_solved.m_D_in = self.mv_c_stages[0][].ms_des_solved.m_D_in
        self.ms_des_solved.m_s_in = self.mv_c_stages[0][].ms_des_solved.m_s_in
        self.ms_des_solved.m_h_in = self.mv_c_stages[0][].ms_des_solved.m_h_in
        self.ms_des_solved.m_T_out = self.mv_c_stages[n_stages_final - 1][].ms_des_solved.m_T_out
        self.ms_des_solved.m_P_out = self.mv_c_stages[n_stages_final - 1][].ms_des_solved.m_P_out
        self.ms_des_solved.m_h_out = self.mv_c_stages[n_stages_final - 1][].ms_des_solved.m_h_out
        self.ms_des_solved.m_D_out = self.mv_c_stages[n_stages_final - 1][].ms_des_solved.m_D_out
        self.ms_des_solved.m_isen_spec_work = h_out_isen - h_in
        self.ms_des_solved.m_m_dot = m_dot_cycle
        self.ms_des_solved.m_W_dot = self.ms_des_solved.m_m_dot * (self.ms_des_solved.m_h_out - self.ms_des_solved.m_h_in)
        self.ms_des_solved.m_N_design = self.mv_c_stages[n_stages_final - 1][].ms_des_solved.m_N_design
        self.ms_des_solved.m_phi_des = self.mv_c_stages[0][].ms_des_solved.m_phi_des
        self.ms_des_solved.m_psi_des = self.mv_c_stages[0][].ms_des_solved.m_psi_des
        self.ms_des_solved.m_tip_ratio_max = max_calc_tip_speed
        self.ms_des_solved.m_n_stages = n_stages_final
        self.ms_des_solved.m_phi_surge = self.mv_c_stages[0][].ms_des_solved.m_phi_surge
        self.ms_des_solved.m_psi_max_at_N_des = self.mv_c_stages[0][].ms_des_solved.m_psi_max_at_N_des
        self.ms_des_solved.mv_D = Pointer[F64].alloc(n_stages_final)
        self.ms_des_solved.mv_tip_speed_ratio = Pointer[F64].alloc(n_stages_final)
        self.ms_des_solved.mv_eta_stages = Pointer[F64].alloc(n_stages_final)
        for i in range(n_stages_final):
            self.ms_des_solved.mv_D[i] = self.mv_c_stages[i][].ms_des_solved.m_D_rotor
            self.ms_des_solved.mv_tip_speed_ratio[i] = self.mv_c_stages[i][].ms_des_solved.m_tip_ratio
            self.ms_des_solved.mv_eta_stages[i] = self.mv_c_stages[i][].ms_des_solved.m_eta_design
        self.ms_des_solved.m_cost = self.calculate_cost(self.ms_des_solved.m_T_in, self.ms_des_solved.m_P_in, self.ms_des_solved.m_m_dot, self.ms_des_solved.m_T_out, self.ms_des_solved.m_P_out, self.ms_des_solved.m_W_dot)
        self.ms_od_solved.mv_eta = Pointer[F64].alloc(n_stages_final)
        self.ms_od_solved.mv_phi = Pointer[F64].alloc(n_stages_final)
        self.ms_od_solved.mv_psi = Pointer[F64].alloc(n_stages_final)
        self.ms_od_solved.mv_tip_speed_ratio = Pointer[F64].alloc(n_stages_final)
        return 0

    def off_design_at_N_des(inout self, T_in: F64, P_in: F64, m_dot_cycle: F64, error_code: Pointer[Int], T_out: Pointer[F64], P_out: Pointer[F64]):
        var N: F64 = self.ms_des_solved.m_N_design
        self.off_design_given_N(T_in, P_in, m_dot_cycle, N, error_code, T_out, P_out)

    def calc_m_dot__N_des__phi_des_first_stage(inout self, T_in: F64, P_in: F64, m_dot_cycle: Pointer[F64]) -> Int:
        var N_des: F64 = self.mv_c_stages[0][].ms_des_solved.m_N_design
        var m_dot_basis: F64 = math.nan
        var stage_err_code: Int = self.mv_c_stages[0][].calc_m_dot__phi_des(T_in, P_in, N_des, m_dot_basis)
        m_dot_cycle[] = m_dot_basis * self.m_r_W_dot_scale
        return stage_err_code

    def off_design_given_N(inout self, T_in: F64, P_in: F64, m_dot_in: F64, N_rpm: F64, error_code: Pointer[Int], T_out: Pointer[F64], P_out: Pointer[F64]):
        var m_dot: F64 = m_dot_in / self.m_r_W_dot_scale
        var n_stages: Int = self.mv_c_stages.size()
        var T_stage_in: F64 = T_in
        var P_stage_in: F64 = P_in
        var T_stage_out: F64 = math.nan
        var P_stage_out: F64 = math.nan
        var tip_ratio_max: F64 = 0.0
        var is_surge: Bool = False
        var surge_safety_min: F64 = 10.0
        var phi_min: F64 = 10.0
        for i in range(n_stages):
            if i > 0:
                T_stage_in = T_stage_out
                P_stage_in = P_stage_out
            error_code[] = self.mv_c_stages[i][].off_design_given_N(T_stage_in, P_stage_in, m_dot, N_rpm, T_stage_out, P_stage_out)
            if error_code[] != 0:
                return
            if self.mv_c_stages[i][].ms_od_solved.m_w_tip_ratio > tip_ratio_max:
                tip_ratio_max = self.mv_c_stages[i][].ms_od_solved.m_w_tip_ratio
            if self.mv_c_stages[i][].ms_od_solved.m_surge:
                is_surge = True
            if self.mv_c_stages[i][].ms_od_solved.m_surge_safety < surge_safety_min:
                surge_safety_min = self.mv_c_stages[i][].ms_od_solved.m_surge_safety
            phi_min = math.min(phi_min, self.mv_c_stages[i][].ms_od_solved.m_phi)
        P_out[] = self.mv_c_stages[n_stages - 1][].ms_od_solved.m_P_out
        T_out[] = self.mv_c_stages[n_stages - 1][].ms_od_solved.m_T_out
        var h_in: F64 = self.mv_c_stages[0][].ms_od_solved.m_h_in
        var s_in: F64 = self.mv_c_stages[0][].ms_od_solved.m_s_in
        var co2_props: CO2_state
        var prop_err_code: Int = CO2_PS(P_out[], s_in, co2_props)
        if prop_err_code != 0:
            error_code[] = prop_err_code
            return
        var h_out_isen: F64 = co2_props.enth
        var h_out: F64 = self.mv_c_stages[n_stages - 1][].ms_od_solved.m_h_out
        self.ms_od_solved.m_P_in = P_in
        self.ms_od_solved.m_T_in = T_in
        self.ms_od_solved.m_P_out = P_out[]
        self.ms_od_solved.m_T_out = T_out[]
        self.ms_od_solved.m_m_dot = m_dot_in
        self.ms_od_solved.m_isen_spec_work = h_out_isen - h_in
        self.ms_od_solved.m_surge = is_surge
        self.ms_od_solved.m_eta = (h_out_isen - h_in) / (h_out - h_in)
        self.ms_od_solved.m_phi_min = phi_min
        self.ms_od_solved.m_tip_ratio_max = tip_ratio_max
        self.ms_od_solved.m_N = N_rpm
        self.ms_od_solved.m_W_dot_in = m_dot_in * (h_out - h_in)
        self.ms_od_solved.m_surge_safety = surge_safety_min
        for i in range(n_stages):
            self.ms_od_solved.mv_tip_speed_ratio[i] = self.mv_c_stages[i][].ms_od_solved.m_w_tip_ratio
            self.ms_od_solved.mv_phi[i] = self.mv_c_stages[i][].ms_od_solved.m_phi
            self.ms_od_solved.mv_psi[i] = self.mv_c_stages[i][].ms_od_solved.m_psi
            self.ms_od_solved.mv_eta[i] = self.mv_c_stages[i][].ms_od_solved.m_eta

    def off_design_given_P_out(inout self, T_in: F64, P_in: F64, m_dot_cycle: F64, P_out: F64, tol: F64, error_code: Pointer[Int], T_out: Pointer[F64]):
        var c_rc_od: C_comp_multi_stage.C_MEQ_phi_od__P_out = C_comp_multi_stage.C_MEQ_phi_od__P_out(Pointer[C_comp_multi_stage].address_of(self), T_in, P_in, m_dot_cycle)
        var c_rd_od_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_rc_od)
        var phi_upper: F64 = self.mv_c_stages[0][].ms_des_solved.m_phi_max
        var phi_lower: F64 = 0.001
        var phi_guess_lower: F64 = self.ms_des_solved.m_phi_des
        var P_solved_phi_guess_lower: F64 = math.nan
        var test_code: Int = c_rd_od_solver.test_member_function(phi_guess_lower, P_solved_phi_guess_lower)
        if test_code != 0:
            for i in range(1, 9):
                phi_guess_lower = self.ms_des_solved.m_phi_des * F64(10 - i) / 10.0 + self.mv_c_stages[0][].ms_des_solved.m_phi_max * F64(i) / 10.0
                test_code = c_rd_od_solver.test_member_function(phi_guess_lower, P_solved_phi_guess_lower)
                if test_code == 0:
                    break
        if test_code != 0:
            error_code[] = -20
            return
        var phi_pair_lower: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
        phi_pair_lower.x = phi_guess_lower
        phi_pair_lower.y = P_solved_phi_guess_lower
        var phi_guess_upper: F64 = phi_guess_lower * 0.5 + self.mv_c_stages[0][].ms_des_solved.m_phi_max * 0.5
        var P_solved_phi_guess_upper: F64 = math.nan
        test_code = c_rd_od_solver.test_member_function(phi_guess_upper, P_solved_phi_guess_upper)
        if test_code != 0:
            for i in range(6, 10):
                phi_guess_upper = phi_guess_lower * F64(i) / 10.0 + self.mv_c_stages[0][].ms_des_solved.m_phi_max * F64(10 - i) / 10.0
                test_code = c_rd_od_solver.test_member_function(phi_guess_upper, P_solved_phi_guess_upper)
                if test_code == 0:
                    break
            if test_code != 0 and phi_guess_lower == self.ms_des_solved.m_phi_des:
                for i in range(6, 10):
                    phi_guess_upper = phi_guess_lower * F64(i) / 10.0 + self.ms_des_solved.m_phi_surge * F64(10 - i) / 10.0
                    test_code = c_rd_od_solver.test_member_function(phi_guess_upper, P_solved_phi_guess_upper)
                    if test_code == 0:
                        break
        if test_code != 0:
            error_code[] = -20
            return
        var phi_pair_upper: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
        phi_pair_upper.x = phi_guess_upper
        phi_pair_upper.y = P_solved_phi_guess_upper
        c_rd_od_solver.settings(tol, 50, phi_lower, phi_upper, True)
        var phi_solved: F64 = math.nan
        var tol_solved: F64 = math.nan
        var iter_solved: Int = -1
        var phi_code: Int = 0
        try:
            phi_code = c_rd_od_solver.solve(phi_pair_lower, phi_pair_upper, P_out, phi_solved, tol_solved, iter_solved)
        except:
            error_code[] = -1
            return
        if phi_code != C_monotonic_eq_solver.CONVERGED:
            var n_call_history: Int = c_rd_od_solver.get_solver_call_history().size()
            if n_call_history > 0:
                error_code[] = -(c_rd_od_solver.get_solver_call_history()[n_call_history - 1].err_code)
            if error_code[] == 0:
                error_code[] = phi_code
            return
        T_out[] = self.ms_od_solved.m_T_out