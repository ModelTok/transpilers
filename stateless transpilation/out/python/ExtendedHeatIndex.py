# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (from EnergyPlus.Data.EnergyPlusData): state object
# - solve_root (from EnergyPlus.General): root finding with signature
#   solve_root(state, tol, max_iter, func, lower, upper) -> (sol_fla, solution)

from enum import IntEnum
import math
from typing import Protocol, Callable, Tuple


class RootAlgo(IntEnum):
    ShortBisectionThenRegulaFalsi = 0


class DataRootFinder(Protocol):
    rootAlgo: RootAlgo


class EnergyPlusData(Protocol):
    dataRootFinder: DataRootFinder


class EqvarName(IntEnum):
    Invalid = -1
    Phi = 0
    Rf = 1
    Rs = 2
    DTcdt = 3
    Num = 4


def solve_root(
    state: EnergyPlusData,
    tol: float,
    max_iter: int,
    func: Callable[[float], float],
    lower: float,
    upper: float,
) -> Tuple[int, float]:
    raise NotImplementedError("solve_root must be wired from EnergyPlus.General")


tol = 1e-5
max_iter = 100


def pvstar(T: float) -> float:
    Ttrip = 273.16
    ptrip = 611.65
    E0v = 2.3740e6
    E0s = 0.3337e6
    rgasv = 461.0
    cvv = 1418.0
    cvl = 4119.0
    cvs = 1861.0
    cpv = cvv + rgasv

    if T == 0.0:
        return 0.0
    if T < Ttrip:
        return ptrip * math.pow(T / Ttrip, (cpv - cvs) / rgasv) * math.exp(
            (E0v + E0s - (cvv - cvs) * Ttrip) / rgasv * (1.0 / Ttrip - 1.0 / T)
        )
    return ptrip * math.pow(T / Ttrip, (cpv - cvl) / rgasv) * math.exp(
        (E0v - (cvv - cvl) * Ttrip) / rgasv * (1.0 / Ttrip - 1.0 / T)
    )


def Le(T: float) -> float:
    Ttrip = 273.16
    E0v = 2.3740e6
    rgasv = 461.0
    cvv = 1418.0
    cvl = 4119.0
    return E0v + (cvv - cvl) * (T - Ttrip) + rgasv * T


def Qv(Ta: float, Pa: float) -> float:
    Q = 180.0
    phi_salt = 0.9
    Tc = 310.0
    Pc = phi_salt * pvstar(Tc)
    eta = 1.43e-6
    L = Le(310.0)
    p = 1.013e5
    rgasa = 287.04
    rgasv = 461.0
    cva = 719.0
    cpa = cva + rgasa

    return eta * Q * (cpa * (Tc - Ta) + L * rgasa / (p * rgasv) * (Pc - Pa))


def Zs(Rs: float) -> float:
    return 52.1 if Rs == 0.0387 else 6.0e8 * math.pow(Rs, 5)


def Ra(Ts: float, Ta: float) -> float:
    sigma = 5.67e-8
    epsilon = 0.97
    hc = 17.4
    phi_rad = 0.85
    hr = epsilon * phi_rad * sigma * (math.pow(Ts, 2) + math.pow(Ta, 2)) * (Ts + Ta)
    return 1.0 / (hc + hr)


def Ra_bar(Tf: float, Ta: float) -> float:
    sigma = 5.67e-8
    epsilon = 0.97
    hc = 11.6
    phi_rad = 0.79
    hr = epsilon * phi_rad * sigma * (math.pow(Tf, 2) + math.pow(Ta, 2)) * (Tf + Ta)
    return 1.0 / (hc + hr)


def Ra_un(Ts: float, Ta: float) -> float:
    sigma = 5.67e-8
    epsilon = 0.97
    hc = 12.3
    phi_rad = 0.80
    hr = epsilon * phi_rad * sigma * (math.pow(Ts, 2) + math.pow(Ta, 2)) * (Ts + Ta)
    return 1.0 / (hc + hr)


def find_eqvar_phi(state: EnergyPlusData, Ta: float, RH: float) -> float:
    Q = 180.0
    phi_salt = 0.9
    Tc = 310.0
    Pc = phi_salt * pvstar(Tc)
    Za = 60.6 / 17.4

    phi = 0.84
    Pa = RH * pvstar(Ta)
    Rs = 0.0387
    ZsRs = Zs(Rs)
    m = (Pc - Pa) / (ZsRs + Za)

    def eqn(Ts: float) -> float:
        return (Ts - Ta) / Ra(Ts, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts) / Rs

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        eqn,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )
    flux1 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    if flux1 <= 0.0:
        phi = 1.0 - (Q - Qv(Ta, Pa)) * Rs / (Tc - Ts)
    return phi


def find_eqvar_Rf(state: EnergyPlusData, Ta: float, RH: float) -> float:
    Q = 180.0
    phi_salt = 0.9
    Tc = 310.0
    Pc = phi_salt * pvstar(Tc)
    r = 124.0
    Za = 60.6 / 17.4
    Za_bar = 60.6 / 11.6

    Pa = RH * pvstar(Ta)
    Rs = 0.0387
    phi = 0.84
    ZsRs = Zs(Rs)
    m_bar = (Pc - Pa) / (ZsRs + Za_bar)
    m = (Pc - Pa) / (ZsRs + Za)

    def eqn_s(Ts: float) -> float:
        return (Ts - Ta) / Ra(Ts, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts) / Rs

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        eqn_s,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )

    def eqn_f(Tf: float) -> float:
        return (Tf - Ta) / Ra_bar(Tf, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf) / Rs

    sol_fla, Tf = solve_root(
        state,
        tol,
        max_iter,
        eqn_f,
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar),
    )
    flux1 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    flux2 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    
    if flux1 <= 0.0:
        Rf = float('inf')
    elif flux2 <= 0.0:
        Ts_bar = Tc - (Q - Qv(Ta, Pa)) * Rs / phi + (1.0 / phi - 1.0) * (Tc - Ts)

        def eqn_f_bar(Tf: float) -> float:
            return (Tf - Ta) / Ra_bar(Tf, Ta) + (Pc - Pa) * (Tf - Ta) / (
                (ZsRs + Za_bar) * (Tf - Ta) + r * Ra_bar(Tf, Ta) * (Ts_bar - Tf)
            ) - (Tc - Ts_bar) / Rs

        sol_fla, Tf = solve_root(state, tol, max_iter, eqn_f_bar, Ta, Ts_bar)
        Rf = Ra_bar(Tf, Ta) * (Ts_bar - Tf) / (Tf - Ta)
    else:
        Rf = 0.0
    
    return Rf


def find_eqvar_rs(state: EnergyPlusData, Ta: float, RH: float) -> float:
    Q = 180.0
    phi_salt = 0.9
    Tc = 310.0
    Pc = phi_salt * pvstar(Tc)
    Za = 60.6 / 17.4
    Za_bar = 60.6 / 11.6
    Za_un = 60.6 / 12.3

    Pa = RH * pvstar(Ta)
    phi = 0.84
    Rs = 0.0387
    ZsRs = Zs(Rs)
    m = (Pc - Pa) / (ZsRs + Za)
    m_bar = (Pc - Pa) / (ZsRs + Za_bar)

    def eqn_s(Ts: float) -> float:
        return (Ts - Ta) / Ra(Ts, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts) / Rs

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        eqn_s,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )

    def eqn_f(Tf: float) -> float:
        return (Tf - Ta) / Ra_bar(Tf, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf) / Rs

    sol_fla, Tf = solve_root(
        state,
        tol,
        max_iter,
        eqn_f,
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar),
    )
    flux1 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    flux2 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    flux3 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un
    
    if flux1 > 0 and flux2 > 0:
        if flux3 < 0.0:
            def eqn_un(Ts: float) -> float:
                return (Ts - Ta) / Ra_un(Ts, Ta) + (Pc - Pa) / (
                    Zs((Tc - Ts) / (Q - Qv(Ta, Pa))) + Za_un
                ) - (Q - Qv(Ta, Pa))

            sol_fla, Ts = solve_root(state, tol, max_iter, eqn_un, 0.0, Tc)
            Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
            ZsRs = Zs(Rs)
            Ps = Pc - (Pc - Pa) * ZsRs / (ZsRs + Za_un)
            
            if Ps > phi_salt * pvstar(Ts):
                def eqn_un2(Ts: float) -> float:
                    return (
                        (Ts - Ta) / Ra_un(Ts, Ta)
                        + (phi_salt * pvstar(Ts) - Pa) / Za_un
                        - (Q - Qv(Ta, Pa))
                    )

                sol_fla, Ts = solve_root(state, tol, max_iter, eqn_un2, 0.0, Tc)
                Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
        else:
            Rs = 0.0
    
    return Rs


def find_eqvar_dTcdt(state: EnergyPlusData, Ta: float, RH: float) -> float:
    M = 83.6
    H = 1.69
    A = 0.202 * math.pow(M, 0.425) * math.pow(H, 0.725)
    cpc = 3492.0
    C = M * cpc / A
    
    Q = 180.0
    phi_salt = 0.9
    Tc = 310.0
    Pc = phi_salt * pvstar(Tc)
    Za = 60.6 / 17.4
    Za_bar = 60.6 / 11.6
    Za_un = 60.6 / 12.3

    dTcdt = 0.0
    Pa = RH * pvstar(Ta)
    Rs = 0.0387
    ZsRs = Zs(Rs)
    phi = 0.84
    m = (Pc - Pa) / (ZsRs + Za)
    m_bar = (Pc - Pa) / (ZsRs + Za_bar)

    def eqn_s(Ts: float) -> float:
        return (Ts - Ta) / Ra(Ts, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts) / Rs

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        eqn_s,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )

    def eqn_f(Tf: float) -> float:
        return (Tf - Ta) / Ra_bar(Tf, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf) / Rs

    sol_fla, Tf = solve_root(
        state,
        tol,
        max_iter,
        eqn_f,
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar),
    )
    flux1 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    flux2 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    flux3 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un
    
    if flux1 > 0.0 and flux2 > 0.0 and flux3 >= 0.0:
        dTcdt = (1.0 / C) * flux3
    
    return dTcdt


def find_eqvar_name_and_value(
    state: EnergyPlusData, Ta: float, RH: float
) -> Tuple[EqvarName, float]:
    M = 83.6
    H = 1.69
    A = 0.202 * math.pow(M, 0.425) * math.pow(H, 0.725)
    cpc = 3492.0
    C = M * cpc / A
    
    Q = 180.0
    phi_salt = 0.9
    Tc = 310.0
    Pc = phi_salt * pvstar(Tc)
    r = 124.0
    Za = 60.6 / 17.4
    Za_bar = 60.6 / 11.6
    Za_un = 60.6 / 12.3

    Pa = RH * pvstar(Ta)
    Rs = 0.0387
    phi = 0.84
    dTcdt = 0.0
    ZsRs = Zs(Rs)
    m = (Pc - Pa) / (ZsRs + Za)
    m_bar = (Pc - Pa) / (ZsRs + Za_bar)

    def eqn_s(Ts: float) -> float:
        return (Ts - Ta) / Ra(Ts, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts) / Rs

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        eqn_s,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )

    def eqn_f(Tf: float) -> float:
        return (Tf - Ta) / Ra_bar(Tf, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf) / Rs

    sol_fla, Tf = solve_root(
        state,
        tol,
        max_iter,
        eqn_f,
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar),
    )
    flux1 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    flux2 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs

    if flux1 <= 0.0:
        varname = EqvarName.Phi
        phi = 1.0 - (Q - Qv(Ta, Pa)) * Rs / (Tc - Ts)
        return (varname, phi)
    
    if flux2 <= 0.0:
        varname = EqvarName.Rf
        Ts_bar = Tc - (Q - Qv(Ta, Pa)) * Rs / phi + (1.0 / phi - 1.0) * (Tc - Ts)

        def eqn_f_bar(Tf: float) -> float:
            return (Tf - Ta) / Ra_bar(Tf, Ta) + (Pc - Pa) * (Tf - Ta) / (
                (ZsRs + Za_bar) * (Tf - Ta) + r * Ra_bar(Tf, Ta) * (Ts_bar - Tf)
            ) - (Tc - Ts_bar) / Rs

        sol_fla, Tf = solve_root(state, tol, max_iter, eqn_f_bar, Ta, Ts_bar)
        Rf = Ra_bar(Tf, Ta) * (Ts_bar - Tf) / (Tf - Ta)
        return (varname, Rf)
    
    flux3 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un
    
    if flux3 < 0.0:
        varname = EqvarName.Rs

        def eqn_un(Ts: float) -> float:
            return (Ts - Ta) / Ra_un(Ts, Ta) + (Pc - Pa) / (
                Zs((Tc - Ts) / (Q - Qv(Ta, Pa))) + Za_un
            ) - (Q - Qv(Ta, Pa))

        sol_fla, Ts = solve_root(state, tol, max_iter, eqn_un, 0.0, Tc)
        Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
        ZsRs = Zs(Rs)
        Ps = Pc - (Pc - Pa) * ZsRs / (ZsRs + Za_un)
        
        if Ps > phi_salt * pvstar(Ts):
            def eqn_un2(Ts: float) -> float:
                return (
                    (Ts - Ta) / Ra_un(Ts, Ta)
                    + (phi_salt * pvstar(Ts) - Pa) / Za_un
                    - (Q - Qv(Ta, Pa))
                )

            sol_fla, Ts = solve_root(state, tol, max_iter, eqn_un2, 0.0, Tc)
            Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
        
        return (varname, Rs)
    
    varname = EqvarName.DTcdt
    Rs = 0.0
    dTcdt = (1.0 / C) * flux3
    return (varname, dTcdt)


def find_T(state: EnergyPlusData, eqvar_name: EqvarName, eqvar: float) -> float:
    T = 0.0
    Pa0 = 1.6e3

    def eqn_phi(T: float) -> float:
        return find_eqvar_phi(state, T, 1.0) - eqvar

    def eqn_rf(T: float) -> float:
        return find_eqvar_Rf(state, T, min(1.0, Pa0 / pvstar(T))) - eqvar

    def eqn_rs(T: float) -> float:
        return find_eqvar_rs(state, T, Pa0 / pvstar(T)) - eqvar

    def eqn_dtcdt(T: float) -> float:
        return find_eqvar_dTcdt(state, T, Pa0 / pvstar(T)) - eqvar

    if eqvar_name == EqvarName.Phi:
        sol_fla, T = solve_root(state, tol, max_iter, eqn_phi, 0.0, 240.0)
    elif eqvar_name == EqvarName.Rf:
        sol_fla, T = solve_root(state, tol, max_iter, eqn_rf, 230.0, 300.0)
    elif eqvar_name == EqvarName.Rs:
        sol_fla, T = solve_root(state, tol, max_iter, eqn_rs, 295.0, 350.0)
    else:
        sol_fla, T = solve_root(state, tol, max_iter, eqn_dtcdt, 340.0, 1000.0)

    return T


def heatindex(state: EnergyPlusData, Ta: float, RH: float) -> float:
    root_algo_backup = state.dataRootFinder.rootAlgo
    state.dataRootFinder.rootAlgo = RootAlgo.ShortBisectionThenRegulaFalsi
    
    eqvar_name, eqvar_value = find_eqvar_name_and_value(state, Ta, RH)
    T = find_T(state, eqvar_name, eqvar_value)

    if Ta == 0.0:
        T = 0.0

    state.dataRootFinder.rootAlgo = root_algo_backup
    return T
