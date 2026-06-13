# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (from EnergyPlus.Data.EnergyPlusData): state object
# - solve_root (from EnergyPlus.General): root finding with signature
#   solve_root(state, tol, max_iter, func, lower, upper) -> (sol_fla, solution)

from math import pow, exp
from enum import Enum


@value
struct RootAlgo:
    alias ShortBisectionThenRegulaFalsi = 0


struct DataRootFinder:
    var rootAlgo: Int


struct EnergyPlusData:
    var dataRootFinder: DataRootFinder


@value
@register_passable("trivial")
struct EqvarName:
    var value: Int
    
    @staticmethod
    fn Invalid() -> Self:
        return Self(-1)
    
    @staticmethod
    fn Phi() -> Self:
        return Self(0)
    
    @staticmethod
    fn Rf() -> Self:
        return Self(1)
    
    @staticmethod
    fn Rs() -> Self:
        return Self(2)
    
    @staticmethod
    fn DTcdt() -> Self:
        return Self(3)
    
    @staticmethod
    fn Num() -> Self:
        return Self(4)
    
    fn __eq__(self, other: EqvarName) -> Bool:
        return self.value == other.value
    
    fn __ne__(self, other: EqvarName) -> Bool:
        return self.value != other.value


fn solve_root(
    state: EnergyPlusData,
    tol: Float64,
    max_iter: Int,
    func: fn(Float64) -> Float64,
    lower: Float64,
    upper: Float64,
) -> Tuple[Int, Float64]:
    _ = state
    _ = tol
    _ = max_iter
    _ = func
    _ = lower
    _ = upper
    return (0, 0.0)


alias tol = 1e-5
alias max_iter = 100


fn pvstar(T: Float64) -> Float64:
    var Ttrip: Float64 = 273.16
    var ptrip: Float64 = 611.65
    var E0v: Float64 = 2.3740e6
    var E0s: Float64 = 0.3337e6
    var rgasv: Float64 = 461.0
    var cvv: Float64 = 1418.0
    var cvl: Float64 = 4119.0
    var cvs: Float64 = 1861.0
    var cpv: Float64 = cvv + rgasv

    if T == 0.0:
        return 0.0
    if T < Ttrip:
        return ptrip * pow(T / Ttrip, (cpv - cvs) / rgasv) * exp(
            (E0v + E0s - (cvv - cvs) * Ttrip) / rgasv * (1.0 / Ttrip - 1.0 / T)
        )
    return ptrip * pow(T / Ttrip, (cpv - cvl) / rgasv) * exp(
        (E0v - (cvv - cvl) * Ttrip) / rgasv * (1.0 / Ttrip - 1.0 / T)
    )


fn Le(T: Float64) -> Float64:
    var Ttrip: Float64 = 273.16
    var E0v: Float64 = 2.3740e6
    var rgasv: Float64 = 461.0
    var cvv: Float64 = 1418.0
    var cvl: Float64 = 4119.0
    return E0v + (cvv - cvl) * (T - Ttrip) + rgasv * T


fn Qv(Ta: Float64, Pa: Float64) -> Float64:
    var Q: Float64 = 180.0
    var phi_salt: Float64 = 0.9
    var Tc: Float64 = 310.0
    var Pc: Float64 = phi_salt * pvstar(Tc)
    var eta: Float64 = 1.43e-6
    var L: Float64 = Le(310.0)
    var p: Float64 = 1.013e5
    var rgasa: Float64 = 287.04
    var rgasv: Float64 = 461.0
    var cva: Float64 = 719.0
    var cpa: Float64 = cva + rgasa

    return eta * Q * (cpa * (Tc - Ta) + L * rgasa / (p * rgasv) * (Pc - Pa))


fn Zs(Rs: Float64) -> Float64:
    if Rs == 0.0387:
        return 52.1
    else:
        return 6.0e8 * pow(Rs, 5)


fn Ra(Ts: Float64, Ta: Float64) -> Float64:
    var sigma: Float64 = 5.67e-8
    var epsilon: Float64 = 0.97
    var hc: Float64 = 17.4
    var phi_rad: Float64 = 0.85
    var hr: Float64 = epsilon * phi_rad * sigma * (pow(Ts, 2) + pow(Ta, 2)) * (Ts + Ta)
    return 1.0 / (hc + hr)


fn Ra_bar(Tf: Float64, Ta: Float64) -> Float64:
    var sigma: Float64 = 5.67e-8
    var epsilon: Float64 = 0.97
    var hc: Float64 = 11.6
    var phi_rad: Float64 = 0.79
    var hr: Float64 = epsilon * phi_rad * sigma * (pow(Tf, 2) + pow(Ta, 2)) * (Tf + Ta)
    return 1.0 / (hc + hr)


fn Ra_un(Ts: Float64, Ta: Float64) -> Float64:
    var sigma: Float64 = 5.67e-8
    var epsilon: Float64 = 0.97
    var hc: Float64 = 12.3
    var phi_rad: Float64 = 0.80
    var hr: Float64 = epsilon * phi_rad * sigma * (pow(Ts, 2) + pow(Ta, 2)) * (Ts + Ta)
    return 1.0 / (hc + hr)


fn find_eqvar_phi(state: EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    var Q: Float64 = 180.0
    var phi_salt: Float64 = 0.9
    var Tc: Float64 = 310.0
    var Pc: Float64 = phi_salt * pvstar(Tc)
    var Za: Float64 = 60.6 / 17.4

    var phi: Float64 = 0.84
    var Pa: Float64 = RH * pvstar(Ta)
    var Rs: Float64 = 0.0387
    var ZsRs: Float64 = Zs(Rs)
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)

    var sol_fla: Int
    var Ts: Float64

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        fn(Ts_val: Float64) -> Float64 {
            return (Ts_val - Ta) / Ra(Ts_val, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )
    
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    if flux1 <= 0.0:
        phi = 1.0 - (Q - Qv(Ta, Pa)) * Rs / (Tc - Ts)
    
    return phi


fn find_eqvar_Rf(state: EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    var Q: Float64 = 180.0
    var phi_salt: Float64 = 0.9
    var Tc: Float64 = 310.0
    var Pc: Float64 = phi_salt * pvstar(Tc)
    var r: Float64 = 124.0
    var Za: Float64 = 60.6 / 17.4
    var Za_bar: Float64 = 60.6 / 11.6

    var Pa: Float64 = RH * pvstar(Ta)
    var Rs: Float64 = 0.0387
    var phi: Float64 = 0.84
    var ZsRs: Float64 = Zs(Rs)
    var m_bar: Float64 = (Pc - Pa) / (ZsRs + Za_bar)
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)

    var sol_fla: Int
    var Ts: Float64
    var Tf: Float64

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        fn(Ts_val: Float64) -> Float64 {
            return (Ts_val - Ta) / Ra(Ts_val, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )

    sol_fla, Tf = solve_root(
        state,
        tol,
        max_iter,
        fn(Tf_val: Float64) -> Float64 {
            return (Tf_val - Ta) / Ra_bar(Tf_val, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar),
    )
    
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    var flux2: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    var Rf: Float64

    if flux1 <= 0.0:
        Rf = 1e308
    elif flux2 <= 0.0:
        var Ts_bar: Float64 = Tc - (Q - Qv(Ta, Pa)) * Rs / phi + (1.0 / phi - 1.0) * (Tc - Ts)

        sol_fla, Tf = solve_root(
            state,
            tol,
            max_iter,
            fn(Tf_val: Float64) -> Float64 {
                return (Tf_val - Ta) / Ra_bar(Tf_val, Ta) + (Pc - Pa) * (Tf_val - Ta) / (
                    (ZsRs + Za_bar) * (Tf_val - Ta) + r * Ra_bar(Tf_val, Ta) * (Ts_bar - Tf_val)
                ) - (Tc - Ts_bar) / Rs
            },
            Ta,
            Ts_bar,
        )
        Rf = Ra_bar(Tf, Ta) * (Ts_bar - Tf) / (Tf - Ta)
    else:
        Rf = 0.0

    return Rf


fn find_eqvar_rs(state: EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    var Q: Float64 = 180.0
    var phi_salt: Float64 = 0.9
    var Tc: Float64 = 310.0
    var Pc: Float64 = phi_salt * pvstar(Tc)
    var Za: Float64 = 60.6 / 17.4
    var Za_bar: Float64 = 60.6 / 11.6
    var Za_un: Float64 = 60.6 / 12.3

    var Pa: Float64 = RH * pvstar(Ta)
    var phi: Float64 = 0.84
    var Rs: Float64 = 0.0387
    var ZsRs: Float64 = Zs(Rs)
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)
    var m_bar: Float64 = (Pc - Pa) / (ZsRs + Za_bar)

    var sol_fla: Int
    var Ts: Float64
    var Tf: Float64

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        fn(Ts_val: Float64) -> Float64 {
            return (Ts_val - Ta) / Ra(Ts_val, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )

    sol_fla, Tf = solve_root(
        state,
        tol,
        max_iter,
        fn(Tf_val: Float64) -> Float64 {
            return (Tf_val - Ta) / Ra_bar(Tf_val, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar),
    )
    
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    var flux2: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    var flux3: Float64 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un

    if flux1 > 0 and flux2 > 0:
        if flux3 < 0.0:
            sol_fla, Ts = solve_root(
                state,
                tol,
                max_iter,
                fn(Ts_val: Float64) -> Float64 {
                    return (Ts_val - Ta) / Ra_un(Ts_val, Ta) + (Pc - Pa) / (
                        Zs((Tc - Ts_val) / (Q - Qv(Ta, Pa))) + Za_un
                    ) - (Q - Qv(Ta, Pa))
                },
                0.0,
                Tc,
            )
            Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
            ZsRs = Zs(Rs)
            var Ps: Float64 = Pc - (Pc - Pa) * ZsRs / (ZsRs + Za_un)

            if Ps > phi_salt * pvstar(Ts):
                sol_fla, Ts = solve_root(
                    state,
                    tol,
                    max_iter,
                    fn(Ts_val: Float64) -> Float64 {
                        return (
                            (Ts_val - Ta) / Ra_un(Ts_val, Ta)
                            + (phi_salt * pvstar(Ts_val) - Pa) / Za_un
                            - (Q - Qv(Ta, Pa))
                        )
                    },
                    0.0,
                    Tc,
                )
                Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
        else:
            Rs = 0.0

    return Rs


fn find_eqvar_dTcdt(state: EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    var M: Float64 = 83.6
    var H: Float64 = 1.69
    var A: Float64 = 0.202 * pow(M, 0.425) * pow(H, 0.725)
    var cpc: Float64 = 3492.0
    var C: Float64 = M * cpc / A

    var Q: Float64 = 180.0
    var phi_salt: Float64 = 0.9
    var Tc: Float64 = 310.0
    var Pc: Float64 = phi_salt * pvstar(Tc)
    var Za: Float64 = 60.6 / 17.4
    var Za_bar: Float64 = 60.6 / 11.6
    var Za_un: Float64 = 60.6 / 12.3

    var dTcdt: Float64 = 0.0
    var Pa: Float64 = RH * pvstar(Ta)
    var Rs: Float64 = 0.0387
    var ZsRs: Float64 = Zs(Rs)
    var phi: Float64 = 0.84
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)
    var m_bar: Float64 = (Pc - Pa) / (ZsRs + Za_bar)

    var sol_fla: Int
    var Ts: Float64
    var Tf: Float64

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        fn(Ts_val: Float64) -> Float64 {
            return (Ts_val - Ta) / Ra(Ts_val, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )

    sol_fla, Tf = solve_root(
        state,
        tol,
        max_iter,
        fn(Tf_val: Float64) -> Float64 {
            return (Tf_val - Ta) / Ra_bar(Tf_val, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar),
    )
    
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    var flux2: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs
    var flux3: Float64 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un

    if flux1 > 0.0 and flux2 > 0.0 and flux3 >= 0.0:
        dTcdt = (1.0 / C) * flux3

    return dTcdt


fn find_eqvar_name_and_value(
    state: EnergyPlusData, Ta: Float64, RH: Float64
) -> Tuple[EqvarName, Float64]:
    var M: Float64 = 83.6
    var H: Float64 = 1.69
    var A: Float64 = 0.202 * pow(M, 0.425) * pow(H, 0.725)
    var cpc: Float64 = 3492.0
    var C: Float64 = M * cpc / A

    var Q: Float64 = 180.0
    var phi_salt: Float64 = 0.9
    var Tc: Float64 = 310.0
    var Pc: Float64 = phi_salt * pvstar(Tc)
    var r: Float64 = 124.0
    var Za: Float64 = 60.6 / 17.4
    var Za_bar: Float64 = 60.6 / 11.6
    var Za_un: Float64 = 60.6 / 12.3

    var Pa: Float64 = RH * pvstar(Ta)
    var Rs: Float64 = 0.0387
    var phi: Float64 = 0.84
    var dTcdt: Float64 = 0.0
    var ZsRs: Float64 = Zs(Rs)
    var m: Float64 = (Pc - Pa) / (ZsRs + Za)
    var m_bar: Float64 = (Pc - Pa) / (ZsRs + Za_bar)

    var sol_fla: Int
    var Ts: Float64
    var Tf: Float64

    sol_fla, Ts = solve_root(
        state,
        tol,
        max_iter,
        fn(Ts_val: Float64) -> Float64 {
            return (Ts_val - Ta) / Ra(Ts_val, Ta) + (Pc - Pa) / (ZsRs + Za) - (Tc - Ts_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m)),
        max(Tc, Ta) + Rs * abs(m),
    )

    sol_fla, Tf = solve_root(
        state,
        tol,
        max_iter,
        fn(Tf_val: Float64) -> Float64 {
            return (Tf_val - Ta) / Ra_bar(Tf_val, Ta) + (Pc - Pa) / (ZsRs + Za_bar) - (Tc - Tf_val) / Rs
        },
        max(0.0, min(Tc, Ta) - Rs * abs(m_bar)),
        max(Tc, Ta) + Rs * abs(m_bar),
    )
    
    var flux1: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs
    var flux2: Float64 = Q - Qv(Ta, Pa) - (1.0 - phi) * (Tc - Ts) / Rs - phi * (Tc - Tf) / Rs

    if flux1 <= 0.0:
        var varname = EqvarName.Phi()
        phi = 1.0 - (Q - Qv(Ta, Pa)) * Rs / (Tc - Ts)
        return (varname, phi)

    if flux2 <= 0.0:
        var varname = EqvarName.Rf()
        var Ts_bar: Float64 = Tc - (Q - Qv(Ta, Pa)) * Rs / phi + (1.0 / phi - 1.0) * (Tc - Ts)

        sol_fla, Tf = solve_root(
            state,
            tol,
            max_iter,
            fn(Tf_val: Float64) -> Float64 {
                return (Tf_val - Ta) / Ra_bar(Tf_val, Ta) + (Pc - Pa) * (Tf_val - Ta) / (
                    (ZsRs + Za_bar) * (Tf_val - Ta) + r * Ra_bar(Tf_val, Ta) * (Ts_bar - Tf_val)
                ) - (Tc - Ts_bar) / Rs
            },
            Ta,
            Ts_bar,
        )
        var Rf: Float64 = Ra_bar(Tf, Ta) * (Ts_bar - Tf) / (Tf - Ta)
        return (varname, Rf)

    var flux3: Float64 = Q - Qv(Ta, Pa) - (Tc - Ta) / Ra_un(Tc, Ta) - (phi_salt * pvstar(Tc) - Pa) / Za_un

    if flux3 < 0.0:
        var varname = EqvarName.Rs()

        sol_fla, Ts = solve_root(
            state,
            tol,
            max_iter,
            fn(Ts_val: Float64) -> Float64 {
                return (Ts_val - Ta) / Ra_un(Ts_val, Ta) + (Pc - Pa) / (
                    Zs((Tc - Ts_val) / (Q - Qv(Ta, Pa))) + Za_un
                ) - (Q - Qv(Ta, Pa))
            },
            0.0,
            Tc,
        )
        Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))
        ZsRs = Zs(Rs)
        var Ps: Float64 = Pc - (Pc - Pa) * ZsRs / (ZsRs + Za_un)

        if Ps > phi_salt * pvstar(Ts):
            sol_fla, Ts = solve_root(
                state,
                tol,
                max_iter,
                fn(Ts_val: Float64) -> Float64 {
                    return (
                        (Ts_val - Ta) / Ra_un(Ts_val, Ta)
                        + (phi_salt * pvstar(Ts_val) - Pa) / Za_un
                        - (Q - Qv(Ta, Pa))
                    )
                },
                0.0,
                Tc,
            )
            Rs = (Tc - Ts) / (Q - Qv(Ta, Pa))

        return (varname, Rs)

    var varname = EqvarName.DTcdt()
    Rs = 0.0
    dTcdt = (1.0 / C) * flux3
    return (varname, dTcdt)


fn find_T(state: EnergyPlusData, eqvar_name: EqvarName, eqvar: Float64) -> Float64:
    var T: Float64 = 0.0
    var sol_fla: Int
    var Pa0: Float64 = 1.6e3

    if eqvar_name == EqvarName.Phi():
        sol_fla, T = solve_root(
            state,
            tol,
            max_iter,
            fn(T_val: Float64) -> Float64 {
                return find_eqvar_phi(state, T_val, 1.0) - eqvar
            },
            0.0,
            240.0,
        )
    elif eqvar_name == EqvarName.Rf():
        sol_fla, T = solve_root(
            state,
            tol,
            max_iter,
            fn(T_val: Float64) -> Float64 {
                return find_eqvar_Rf(state, T_val, min(1.0, Pa0 / pvstar(T_val))) - eqvar
            },
            230.0,
            300.0,
        )
    elif eqvar_name == EqvarName.Rs():
        sol_fla, T = solve_root(
            state,
            tol,
            max_iter,
            fn(T_val: Float64) -> Float64 {
                return find_eqvar_rs(state, T_val, Pa0 / pvstar(T_val)) - eqvar
            },
            295.0,
            350.0,
        )
    else:
        sol_fla, T = solve_root(
            state,
            tol,
            max_iter,
            fn(T_val: Float64) -> Float64 {
                return find_eqvar_dTcdt(state, T_val, Pa0 / pvstar(T_val)) - eqvar
            },
            340.0,
            1000.0,
        )

    return T


fn heatindex(state: EnergyPlusData, Ta: Float64, RH: Float64) -> Float64:
    var root_algo_backup: Int = state.dataRootFinder.rootAlgo
    var mutable_state = state
    mutable_state.dataRootFinder.rootAlgo = RootAlgo.ShortBisectionThenRegulaFalsi

    var eqvar_name: EqvarName
    var eqvar_value: Float64
    eqvar_name, eqvar_value = find_eqvar_name_and_value(mutable_state, Ta, RH)

    var T: Float64 = find_T(mutable_state, eqvar_name, eqvar_value)

    if Ta == 0.0:
        T = 0.0

    mutable_state.dataRootFinder.rootAlgo = root_algo_backup
    return T
