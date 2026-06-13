// Original C++: ExtendedHeatIndex.cc

from math import exp, pow, fabs
from .Data.EnergyPlusData import EnergyPlusData
from General import SolveRoot
from HVACSystemRootFindingAlgorithm import RootAlgo

@value
enum EqvarName:
    Invalid = -1
    Phi = 0
    Rf = 1
    Rs = 2
    DTcdt = 3
    Num = 4

def pvstar(T: Float64) -> Float64:
    #   saturation vapor pressure over liquid water and ice (Kirchhoff's formula)
    given by Iribarne and Godson (1973), formula (9.51)
    alias Ttrip: Float64 = 273.16  # Kelvin
    alias ptrip: Float64 = 611.65  # Pascals
    alias E0v: Float64 = 2.3740e6  # J/kg
    alias E0s: Float64 = 0.3337e6  # J/kg
    alias rgasv: Float64 = 461.    # J/(kg K)
    alias cvv: Float64 = 1418.     # J/(kg K)
    alias cvl: Float64 = 4119.     # J/(kg K)
    alias cvs: Float64 = 1861.     # J/(kg K)
    alias cpv: Float64 = cvv + rgasv

    if T == 0.0:
        return 0.0
    if T < Ttrip:
        return ptrip * pow(T / Ttrip, (cpv - cvs) / rgasv) * exp((E0v + E0s - (cvv - cvs) * Ttrip) / rgasv * (1.0 / Ttrip - 1.0 / T))
    return ptrip * pow(T / Ttrip, (cpv - cvl) / rgasv) * exp((E0v - (cvv - cvl) * Ttrip) / rgasv * (1.0 / Ttrip - 1.0 / T))

    return 0.0

def Le(T: Float64) -> Float64:
    #   latent heat of vaporization as a function of T
    alias Ttrip: Float64 = 273.16  # Kelvin
    alias E0v: Float64 = 2.3740e6  # J/kg
    alias rgasv: Float64 = 461.    # J/(kg K)
    alias cvv: Float64 = 1418.     # J/(kg K)
    alias cvl: Float64 = 4119.     # J/(kg K)
    return (E0v + (cvv - cvl) * (T - Ttrip) + rgasv * T)

def Qv(Ta: Float64, Pa: Float64) -> Float64:
    alias Q: Float64 = 180.        # W/m2
    alias phi_salt: Float64 = 0.9  # constant
    alias Tc: Float64 = 310.       # K
    var Pc: Float64 = phi_salt * pvstar(Tc)
    alias eta: Float64 = 1.43e-6   # m2/s
    var L: Float64 = Le(310.)      # J/kg
    alias p: Float64 = 1.013e5     # Pa
    alias rgasa: Float64 = 287.04  # J/(kg K)
    alias rgasv: Float64 = 461.    # J/(kg K)
    alias cva: Float64 = 719.      # J/(kg K)
    alias cpa: Float64 = cva + rgasa

    return eta * Q * (cpa * (Tc - Ta) + L * rgasa / (p * rgasv) * (Pc - Pa))

def Zs(Rs: Float64) -> Float64:
    return 52.1 if Rs == 0.0387 else 6.0e8 * pow(Rs, 5)

def Ra(Ts: Float64, Ta: Float64) -> Float64:
    alias sigma: Float64 = 5.67e-8  # Stefan-Boltzmann constant (W/m2K4)
    alias epsilon: Float64 = 0.97   # emissivity
    alias hc: Float64 = 17.4        # W/m2K
    alias phi_rad: Float64 = 0.85
    var hr: Float64 = epsilon * phi_rad * sigma * (pow(Ts, 2) + pow(Ta, 2)) * (Ts + Ta)
    return 1.0 / (hc + hr)

def Ra_bar(Tf: Float64, Ta: Float64) -> Float64:
    alias sigma: Float64 = 5.67e-8
    alias epsilon: Float64 = 0.97
    alias hc: Float64 = 11.6
    alias phi_rad: Float64 = 0.79
    var hr: Float64 = epsilon * phi_rad * sigma * (pow(Tf, 2) + pow(Ta, 2)) * (Tf + Ta)
    return 1.0 / (hc + hr)

def Ra_un(Ts: Float64, Ta: Float64) -> Float64:
    alias sigma: Float64 = 5.67e-8
    alias epsilon: Float64 = 0.97
    alias hc: Float64 = 12.3
    alias phi_rad: Float64 = 0.80
    var hr: Float64 = epsilon * phi_rad * sigma * (pow(Ts, 2) + pow(Ta, 2)) * (Ts + Ta)
    return 1.0 / (hc + hr)

alias tol: Float64 = 1e-5
alias maxIter: Int = 100

def find_eqvar_phi(state: inout EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    alias Q: Float64 = 180.         # W/m2
    alias phi_salt: Float64 = 0.9   # constant
    alias Tc: Float64 = 310.        # K
    var Pc: Float64 = phi_salt * pvstar(Tc)
    alias Za: Float64 = 60.6 / 17.4

    var phi: Float64 = 0.84
    var Pa: Float64 = RH * pvstar(Ta)
    alias Rs: Float64 = 0.0387
    var ZsRs: Float64 = Zs(Rs)
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)
    var Ts: Float64
    var SolFla: Int
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Ts,
        fn(Ts_loc: Float64) -> Float64:
            return (Ts_loc - Ta) / Ra(Ts_loc, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m))
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    if flux1 <= 0.0:
        phi = 1.0 - (Q - Qv(Ta, Pa)) * Rs / (Tc - Ts)
    return phi

def find_eqvar_Rf(state: inout EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    alias Q: Float64 = 180.             # W/m2
    alias phi_salt: Float64 = 0.9       # constant
    alias Tc: Float64 = 310.            # K
    var Pc: Float64 = phi_salt * pvstar(Tc)
    alias r: Float64 = 124.             # s/m
    alias Za: Float64 = 60.6 / 17.4
    alias Za_bar: Float64 = 60.6 / 11.6

    var Pa: Float64 = RH * pvstar(Ta)
    alias Rs: Float64 = 0.0387
    alias phi: Float64 = 0.84
    var ZsRs: Float64 = Zs(Rs)
    var m_bar: Float64 = (Pc - Pa) / (ZsRs + Za_bar)
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)
    var Ts: Float64
    var SolFla: Int
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Ts,
        fn(Ts_loc: Float64) -> Float64:
            return (Ts_loc - Ta) / Ra(Ts_loc, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m))
    var Tf: Float64
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Tf,
        fn(Tf_loc: Float64) -> Float64:
            return (Tf_loc - Ta) / Ra_bar(Tf_loc, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar))
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    var flux2: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    var Rf: Float64
    if flux1 <= 0.0:
        Rf = inf[Float64]
    elif flux2 <= 0.0:
        var Ts_bar: Float64 = Tc - (Q - Qv(Ta, Pa)) * Rs / phi + (1.0 / phi - 1.0) * (Tc - Ts)
        SolveRoot(
            state,
            tol,
            maxIter,
            SolFla,
            Tf,
            fn(Tf_loc: Float64) -> Float64:
                return (Tf_loc - Ta) / Ra_bar(Tf_loc, Ta) + (Pc - Pa) * (Tf_loc - Ta) / ((ZsRs + Za_bar) * (Tf_loc - Ta) + r * Ra_bar(Tf_loc, Ta) * (Ts_bar - Tf_loc)) - (Tc - Ts_bar) / Rs,
            Ta,
            Ts_bar)
        Rf = Ra_bar(Tf, Ta) * (Ts_bar - Tf) / (Tf - Ta)
    else:
        Rf = 0.0
    return Rf

def find_eqvar_rs(state: inout EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    #
    #
    #
    #
    #
    alias Q: Float64 = 180.             # W/m2
    alias phi_salt: Float64 = 0.9       # constant
    alias Tc: Float64 = 310.            # K
    var Pc: Float64 = phi_salt * pvstar(Tc)
    alias Za: Float64 = 60.6 / 17.4
    alias Za_bar: Float64 = 60.6 / 11.6
    alias Za_un: Float64 = 60.6 / 12.3

    var Pa: Float64 = RH * pvstar(Ta)
    alias phi: Float64 = 0.84
    var Rs: Float64 = 0.0387
    var ZsRs: Float64 = Zs(Rs)
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)
    var m_bar: Float64 = (Pc - Pa) / (ZsRs + Za_bar)
    var Ts: Float64
    var SolFla: Int
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Ts,
        fn(Ts_loc: Float64) -> Float64:
            return (Ts_loc - Ta) / Ra(Ts_loc, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m))
    var Tf: Float64
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Tf,
        fn(Tf_loc: Float64) -> Float64:
            return (Tf_loc - Ta) / Ra_bar(Tf_loc, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar))
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    var flux2: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    var flux3: Float64 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un
    if flux1 > 0 and flux2 > 0:
        if flux3 < 0.0:
            SolveRoot(
                state,
                tol,
                maxIter,
                SolFla,
                Ts,
                fn(Ts_loc: Float64) -> Float64:
                    return (Ts_loc - Ta) / Ra_un(Ts_loc, Ta) + (Pc - Pa) / (Zs((Tc - Ts_loc) / (Q - Qv(Ta, Pa))) + Za_un) - (Q - Qv(Ta, Pa)),
                0.0,
                Tc)
            Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
            ZsRs = Zs(Rs)
            var Ps: Float64 = Pc - (Pc - Pa) * ZsRs / (ZsRs + Za_un)
            if Ps > phi_salt * pvstar(Ts):
                SolveRoot(
                    state,
                    tol,
                    maxIter,
                    SolFla,
                    Ts,
                    fn(Ts_loc: Float64) -> Float64:
                        return (Ts_loc - Ta) / Ra_un(Ts_loc, Ta) + (phi_salt * pvstar(Ts_loc) - Pa) / Za_un - (Q - Qv(Ta, Pa)),
                    0.0,
                    Tc)
                Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
        else:
            Rs = 0.0
    return Rs

def find_eqvar_dTcdt(state: inout EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    alias M: Float64 = 83.6                        # kg
    alias H: Float64 = 1.69                        # m
    var A: Float64 = 0.202 * pow(M, 0.425) * pow(H, 0.725)  # m2
    alias cpc: Float64 = 3492.                     # J/(kg K)
    var C: Float64 = M * cpc / A                   # J/(K m2)
    alias Q: Float64 = 180.                        # W/m2
    alias phi_salt: Float64 = 0.9                  # constant
    alias Tc: Float64 = 310.                       # K
    var Pc: Float64 = phi_salt * pvstar(Tc)
    alias Za: Float64 = 60.6 / 17.4
    alias Za_bar: Float64 = 60.6 / 11.6
    alias Za_un: Float64 = 60.6 / 12.3

    var dTcdt: Float64 = 0.0
    var Pa: Float64 = RH * pvstar(Ta)
    alias Rs: Float64 = 0.0387
    var ZsRs: Float64 = Zs(Rs)
    alias phi: Float64 = 0.84
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)
    var m_bar: Float64 = (Pc - Pa) / (ZsRs + Za_bar)
    var Ts: Float64
    var SolFla: Int
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Ts,
        fn(Ts_loc: Float64) -> Float64:
            return (Ts_loc - Ta) / Ra(Ts_loc, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m))
    var Tf: Float64
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Tf,
        fn(Tf_loc: Float64) -> Float64:
            return (Tf_loc - Ta) / Ra_bar(Tf_loc, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar))
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    var flux2: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    var flux3: Float64 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un
    if flux1 > 0.0 and flux2 > 0.0 and flux3 >= 0.0:
        dTcdt = (1.0 / C) * flux3
    return dTcdt

def find_eqvar_name_and_value(state: inout EnergyPlusData, Ta: Float64, RH: Float64, varname: inout EqvarName) -> Float64:
    alias M: Float64 = 83.6                        # kg
    alias H: Float64 = 1.69                        # m
    var A: Float64 = 0.202 * pow(M, 0.425) * pow(H, 0.725)  # m2
    alias cpc: Float64 = 3492.                     # J/(kg K)
    var C: Float64 = M * cpc / A                   # J/(K m2)
    alias Q: Float64 = 180.                        # W/m2
    alias phi_salt: Float64 = 0.9                  # constant
    alias Tc: Float64 = 310.                       # K
    var Pc: Float64 = phi_salt * pvstar(Tc)
    alias r: Float64 = 124.                        # s/m
    alias Za: Float64 = 60.6 / 17.4
    alias Za_bar: Float64 = 60.6 / 11.6
    alias Za_un: Float64 = 60.6 / 12.3

    var Pa: Float64 = RH * pvstar(Ta)
    var Rs: Float64 = 0.0387
    var phi: Float64 = 0.84
    var dTcdt: Float64 = 0.0
    var ZsRs: Float64 = Zs(Rs)
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)
    var m_bar: Float64 = (Pc - Pa) / (ZsRs + Za_bar)

    var SolFla: Int
    var Ts: Float64
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Ts,
        fn(Ts_loc: Float64) -> Float64:
            return (Ts_loc - Ta) / Ra(Ts_loc, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m))

    var Tf: Float64
    SolveRoot(
        state,
        tol,
        maxIter,
        SolFla,
        Tf,
        fn(Tf_loc: Float64) -> Float64:
            return (Tf_loc - Ta) / Ra_bar(Tf_loc, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf_loc) / Rs,
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar))
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    var flux2: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    var Rf: Float64

    if flux1 <= 0.0:
        varname = EqvarName.Phi
        phi = 1.0 - (Q - Qv(Ta, Pa)) * Rs / (Tc - Ts)
        return phi
    if flux2 <= 0.0:
        varname = EqvarName.Rf
        var Ts_bar: Float64 = Tc - (Q - Qv(Ta, Pa)) * Rs / phi + (1.0 / phi - 1.0) * (Tc - Ts)
        SolveRoot(
            state,
            tol,
            maxIter,
            SolFla,
            Tf,
            fn(Tf_loc: Float64) -> Float64:
                return (Tf_loc - Ta) / Ra_bar(Tf_loc, Ta) + (Pc - Pa) * (Tf_loc - Ta) / ((ZsRs + Za_bar) * (Tf_loc - Ta) + r * Ra_bar(Tf_loc, Ta) * (Ts_bar - Tf_loc)) - (Tc - Ts_bar) / Rs,
            Ta,
            Ts_bar)
        Rf = Ra_bar(Tf, Ta) * (Ts_bar - Tf) / (Tf - Ta)
        return Rf
    var flux3: Float64 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un
    if flux3 < 0.0:
        varname = EqvarName.Rs
        SolveRoot(
            state,
            tol,
            maxIter,
            SolFla,
            Ts,
            fn(Ts_loc: Float64) -> Float64:
                return (Ts_loc - Ta) / Ra_un(Ts_loc, Ta) + (Pc - Pa) / (Zs((Tc - Ts_loc) / (Q - Qv(Ta, Pa))) + Za_un) - (Q - Qv(Ta, Pa)),
            0.0,
            Tc)
        Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
        ZsRs = Zs(Rs)
        var Ps: Float64 = Pc - (Pc - Pa) * ZsRs / (ZsRs + Za_un)
        if Ps > phi_salt * pvstar(Ts):
            SolveRoot(
                state,
                tol,
                maxIter,
                SolFla,
                Ts,
                fn(Ts_loc: Float64) -> Float64:
                    return (Ts_loc - Ta) / Ra_un(Ts_loc, Ta) + (phi_salt * pvstar(Ts_loc) - Pa) / Za_un - (Q - Qv(Ta, Pa)),
                0.0,
                Tc)
            Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
        return Rs
    varname = EqvarName.DTcdt
    Rs = 0.0
    dTcdt = (1.0 / C) * flux3
    return dTcdt

def find_T(state: inout EnergyPlusData, eqvar_name: EqvarName, eqvar: Float64) -> Float64:
    var T: Float64
    var SolFla: Int
    alias Pa0: Float64 = 1.6e3  # Pa

    if eqvar_name == EqvarName.Phi:
        SolveRoot(state, tol, maxIter, SolFla, T, fn(T_loc: Float64) -> Float64: return find_eqvar_phi(state, T_loc, 1.0) - eqvar, 0.0, 240.0)
    elif eqvar_name == EqvarName.Rf:
        SolveRoot(state, tol, maxIter, SolFla, T, fn(T_loc: Float64) -> Float64: return (find_eqvar_Rf(state, T_loc, min(1.0, Pa0 / pvstar(T_loc)))) - eqvar, 230.0, 300.0)
    elif eqvar_name == EqvarName.Rs:
        SolveRoot(state, tol, maxIter, SolFla, T, fn(T_loc: Float64) -> Float64: return find_eqvar_rs(state, T_loc, Pa0 / pvstar(T_loc)) - eqvar, 295.0, 350.0)
    else:
        SolveRoot(state, tol, maxIter, SolFla, T, fn(T_loc: Float64) -> Float64: return find_eqvar_dTcdt(state, T_loc, Pa0 / pvstar(T_loc)) - eqvar, 340.0, 1000.0)

    return T

def heatindex(state: inout EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    #
    #
    #
    #

    var rootAlgoBackup: RootAlgo = state.dataRootFinder.rootAlgo
    state.dataRootFinder.rootAlgo = RootAlgo.ShortBisectionThenRegulaFalsi
    var eqvar_name: EqvarName = EqvarName.Invalid
    var eqvar_value: Float64 = find_eqvar_name_and_value(state, Ta, RH, eqvar_name)

    var T: Float64 = find_T(state, eqvar_name, eqvar_value)

    if Ta == 0.0:
        T = 0.0

    state.dataRootFinder.rootAlgo = rootAlgoBackup
    return T