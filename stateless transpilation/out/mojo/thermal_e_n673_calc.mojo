from math import pow, sqrt, fabs
import math

alias MaxGap = 10
alias maxlay = 10
alias maxlay1 = 11
alias maxlay2 = 22
alias maxlay3 = 23
alias maxgas = 6

struct Constant:
    var Gravity: Float64 = 9.81
    var StefanBoltzmann: Float64 = 5.67e-8

struct Stdrd:
    pass

struct Files:
    var WriteDebugOutput: Bool
    var DebugOutputFile: object
    var DBGD: object

struct EnergyPlusData:
    pass

fn pow_2(x: Float64) -> Float64:
    return x * x

fn pow_3(x: Float64) -> Float64:
    return x * x * x

fn GoAhead(nperr: Int32) -> Bool:
    return nperr == 0

fn GASSES90(state: EnergyPlusData, Tm: Float64, ipropg: DynamicVector[Int32],
            frctg: DynamicVector[Float64], presure: Float64, nmix: Int32,
            xwght: DynamicVector[Float64], xgcon: DynamicVector[DynamicVector[Float64]],
            xgvis: DynamicVector[DynamicVector[Float64]], xgcp: DynamicVector[DynamicVector[Float64]],
            con: DynamicVector[Float64], visc: DynamicVector[Float64],
            dens: DynamicVector[Float64], cp: DynamicVector[Float64], pr: DynamicVector[Float64],
            standard: Stdrd, nperr: DynamicVector[Int32],
            ErrorMessage: DynamicVector[String]) -> None:
    pass

fn WriteOutputEN673(file: object, dbgd: object, nlayer: Int32, ufactor: Float64,
                    hout: Float64, hin: Float64, Ra: DynamicVector[Float64],
                    Nu: DynamicVector[Float64], hg: DynamicVector[Float64],
                    hr: DynamicVector[Float64], hs: DynamicVector[Float64],
                    nperr: Int32) -> None:
    pass

fn Calc_EN673(state: EnergyPlusData, files: Files, standard: Stdrd, nlayer: Int32,
              tout: Float64, tind: Float64, gap: DynamicVector[Float64],
              thick: DynamicVector[Float64], scon: DynamicVector[Float64],
              emis: DynamicVector[Float64], totsol: Float64, tilt: Float64,
              dir: Float64, asol: DynamicVector[Float64],
              presure: DynamicVector[Float64], iprop: DynamicVector[DynamicVector[Int32]],
              frct: DynamicVector[DynamicVector[Float64]], nmix: DynamicVector[Int32],
              xgcon: DynamicVector[DynamicVector[Float64]],
              xgvis: DynamicVector[DynamicVector[Float64]],
              xgcp: DynamicVector[DynamicVector[Float64]],
              xwght: DynamicVector[Float64], theta: DynamicVector[Float64],
              ufactor: DynamicVector[Float64], hcin: DynamicVector[Float64],
              hin: DynamicVector[Float64], hout: DynamicVector[Float64],
              shgc: DynamicVector[Float64], nperr: DynamicVector[Int32],
              ErrorMessage: DynamicVector[String], ibc: DynamicVector[Int32],
              hg: DynamicVector[Float64], hr: DynamicVector[Float64],
              hs: DynamicVector[Float64], Ra: DynamicVector[Float64],
              Nu: DynamicVector[Float64]) -> None:
    var rs = DynamicVector[Float64](maxlay3)
    var rtot: Float64 = 0.0
    var sft: Float64 = 0.0

    for i in range(maxlay3):
        rs[i] = 0.0

    rtot = 0.0
    sft = 0.0

    if GoAhead(nperr[0]):
        EN673ISO10292(state, nlayer, tout, tind, emis, gap, thick, scon, tilt,
                      iprop, frct, xgcon, xgvis, xgcp, xwght, presure, nmix,
                      theta, standard, hg, hr, hs, hin, hout, hcin, ibc, rs,
                      ufactor, Ra, Nu, nperr, ErrorMessage)

        if GoAhead(nperr[0]):
            rtot = 1.0 / ufactor[0]
            solar_EN673(dir, totsol, rtot, rs, nlayer, asol, sft, standard, nperr, ErrorMessage)
            if GoAhead(nperr[0]):
                shgc[0] = sft
                if files.WriteDebugOutput:
                    WriteOutputEN673(files.DebugOutputFile, files.DBGD, nlayer,
                                   ufactor[0], hout[0], hin[0], Ra, Nu, hg, hr, hs,
                                   nperr[0])

fn EN673ISO10292(state: EnergyPlusData, nlayer: Int32, tout: Float64, tind: Float64,
                 emis: DynamicVector[Float64], gap: DynamicVector[Float64],
                 thick: DynamicVector[Float64], scon: DynamicVector[Float64],
                 tilt: Float64, iprop: DynamicVector[DynamicVector[Int32]],
                 frct: DynamicVector[DynamicVector[Float64]],
                 xgcon: DynamicVector[DynamicVector[Float64]],
                 xgvis: DynamicVector[DynamicVector[Float64]],
                 xgcp: DynamicVector[DynamicVector[Float64]],
                 xwght: DynamicVector[Float64], presure: DynamicVector[Float64],
                 nmix: DynamicVector[Int32], theta: DynamicVector[Float64],
                 standard: Stdrd, hg: DynamicVector[Float64],
                 hr: DynamicVector[Float64], hs: DynamicVector[Float64],
                 hin: DynamicVector[Float64], hout: DynamicVector[Float64],
                 hcin: DynamicVector[Float64], ibc: DynamicVector[Int32],
                 rs: DynamicVector[Float64], ufactor: DynamicVector[Float64],
                 Ra: DynamicVector[Float64], Nu: DynamicVector[Float64],
                 nperr: DynamicVector[Int32],
                 ErrorMessage: DynamicVector[String]) -> None:
    var Tm: Float64 = 0.0
    var diff: Float64 = 0.0
    var Rg: Float64 = 0.0
    var dT = DynamicVector[Float64](maxlay1)
    var dens: Float64 = 0.0
    var visc: Float64 = 0.0
    var con: Float64 = 0.0
    var cp: Float64 = 0.0
    var pr: Float64 = 0.0
    var Gr = DynamicVector[Float64](maxlay)
    var A: Float64 = 0.0
    var n: Float64 = 0.0
    var hrin: Float64 = 0.0
    var sumRs: Float64 = 0.0
    var sumRsold: Float64 = 0.0
    var eps: Float64 = 1.0e-4

    var frctg = DynamicVector[Float64](maxgas)
    var ipropg = DynamicVector[Int32](maxgas)

    for i in range(maxlay1):
        dT[i] = 0.0
    for i in range(maxlay):
        Gr[i] = 0.0
    for i in range(maxgas):
        frctg[i] = 0.0
        ipropg[i] = 0

    if (emis[2 * nlayer - 1] < 0.85) and (emis[2 * nlayer - 1] > 0.83):
        hrin = 4.4
    else:
        hrin = 4.4 * emis[2 * nlayer - 1] / 0.837

    if ibc[0] != 1:
        nperr[0] = 38
        ErrorMessage[0] = "Boundary conditions for EN673 can be combined hout for outdoor and either convective (hcin) or combined (hin) for indoor.  Others are not supported currently."
        return

    if ibc[1] == 1:
        pass
    elif ibc[1] == 2:
        hcin[0] = hin[0]
        hin[0] = hcin[0] + hrin
    else:
        nperr[0] = 39
        ErrorMessage[0] = "CSM and SCW thermal models cannot be used for outdoor and indoor SD layers."
        return

    rs[0] = 1.0 / hout[0]
    rs[2 * nlayer] = 1.0 / hin[0]

    Tm = 283.0
    var iter_count: Int32 = 1
    sumRs = 0.0
    Rg = 0.0

    for i in range(maxlay):
        Gr[i] = 0.0
        Nu[i] = 0.0
        Ra[i] = 0.0

    con = 0.0

    for i in range(nlayer):
        rs[2 * i + 1] = thick[i] / scon[i]
        Rg += rs[2 * i + 1]

    if nlayer == 1:
        ufactor[0] = 1.0 / (1.0 / hin[0] + 1.0 / hout[0] + Rg)
        theta[0] = ufactor[0] * (tind - tout) / hout[0] + tout
        theta[1] = tind - ufactor[0] * (tind - tout) / hin[0]
        return

    if tind > tout:
        if tilt == 0.0:
            A = 0.16
            n = 0.28
        elif (tilt > 0.0) and (tilt < 45.0):
            var A_out = DynamicVector[Float64](1)
            var n_out = DynamicVector[Float64](1)
            A_out[0] = A
            n_out[0] = n
            linint(0.0, 45.0, 0.16, 0.1, tilt, A_out)
            linint(0.0, 45.0, 0.28, 0.31, tilt, n_out)
            A = A_out[0]
            n = n_out[0]
        elif tilt == 45.0:
            A = 0.10
            n = 0.31
        elif (tilt > 45.0) and (tilt < 90.0):
            var A_out2 = DynamicVector[Float64](1)
            var n_out2 = DynamicVector[Float64](1)
            A_out2[0] = A
            n_out2[0] = n
            linint(45.0, 90.0, 0.1, 0.035, tilt, A_out2)
            linint(45.0, 90.0, 0.31, 0.38, tilt, n_out2)
            A = A_out2[0]
            n = n_out2[0]
        elif tilt == 90:
            A = 0.035
            n = 0.38

        for i in range(nlayer - 1):
            dT[i] = 15.0 / Float64(nlayer - 1)
            for j in range(nmix[i + 1]):
                ipropg[j] = iprop[i + 1][j]
                frctg[j] = frct[i + 1][j]

            var con_out = DynamicVector[Float64](1)
            var visc_out = DynamicVector[Float64](1)
            var dens_out = DynamicVector[Float64](1)
            var cp_out = DynamicVector[Float64](1)
            var pr_out = DynamicVector[Float64](1)
            con_out[0] = con
            visc_out[0] = visc
            dens_out[0] = dens
            cp_out[0] = cp
            pr_out[0] = pr

            GASSES90(state, Tm, ipropg, frctg, presure[i + 1], nmix[i + 1],
                     xwght, xgcon, xgvis, xgcp, con_out, visc_out, dens_out,
                     cp_out, pr_out, standard, nperr, ErrorMessage)

            con = con_out[0]
            visc = visc_out[0]
            dens = dens_out[0]
            cp = cp_out[0]
            pr = pr_out[0]

            Gr[i] = (Constant.Gravity * pow_3(gap[i]) * dT[i] * pow_2(dens)) / (Tm * pow_2(visc))
            Ra[i] = Gr[i] * pr
            Nu[i] = A * pow(Ra[i], n)
            if Nu[i] < 1.0:
                Nu[i] = 1.0
            hg[i] = Nu[i] * con / gap[i]
    else:
        for i in range(nlayer - 1):
            Nu[i] = 1.0
            hg[i] = Nu[i] * con / gap[i]

    for i in range(nlayer - 1):
        hr[i] = 4.0 * Constant.StefanBoltzmann * pow(1.0 / emis[2 * i] + 1.0 / emis[2 * i + 1] - 1.0, -1.0) * pow_3(Tm)
        hs[i] = hg[i] + hr[i]
        rs[2 * i + 2] = 1.0 / hs[i]
        sumRs += rs[2 * i + 2]

    ufactor[0] = 1.0 / (1.0 / hin[0] + 1.0 / hout[0] + sumRs + Rg)
    theta[0] = ufactor[0] * (tind - tout) / hout[0] + tout
    theta[2 * nlayer - 1] = tind - ufactor[0] * (tind - tout) / hin[0]
    for i in range(1, nlayer):
        theta[2 * i - 1] = ufactor[0] * (tind - tout) * thick[0] / scon[0] + theta[2 * i - 2]
        theta[2 * i] = ufactor[0] * (tind - tout) / hs[i - 1] + theta[2 * i - 1]

    while True:
        sumRsold = sumRs
        sumRs = 0.0

        if (standard == Stdrd()) and (nlayer == 2):
            return

        if tind > tout:
            for i in range(nlayer - 1):
                dT[i] = 15.0 * (1.0 / hs[i]) / sumRsold
                if standard == Stdrd():
                    Tm = 283.0
                else:
                    Tm = (theta[2 * i] + theta[2 * i + 1]) / 2.0
                for j in range(nmix[i + 1]):
                    ipropg[j] = iprop[i + 1][j]
                    frctg[j] = frct[i + 1][j]

                var con_out2 = DynamicVector[Float64](1)
                var visc_out2 = DynamicVector[Float64](1)
                var dens_out2 = DynamicVector[Float64](1)
                var cp_out2 = DynamicVector[Float64](1)
                var pr_out2 = DynamicVector[Float64](1)
                con_out2[0] = con
                visc_out2[0] = visc
                dens_out2[0] = dens
                cp_out2[0] = cp
                pr_out2[0] = pr

                GASSES90(state, Tm, ipropg, frctg, presure[i + 1], nmix[i + 1],
                         xwght, xgcon, xgvis, xgcp, con_out2, visc_out2, dens_out2,
                         cp_out2, pr_out2, standard, nperr, ErrorMessage)

                con = con_out2[0]
                visc = visc_out2[0]
                dens = dens_out2[0]
                cp = cp_out2[0]
                pr = pr_out2[0]

                Gr[i] = (Constant.Gravity * pow_3(gap[i]) * dT[i] * pow_2(dens)) / (Tm * pow_2(visc))
                Ra[i] = Gr[i] * pr
                Nu[i] = A * pow(Ra[i], n)
                if Nu[i] < 1.0:
                    Nu[i] = 1.0
                hg[i] = Nu[i] * con / gap[i]
        else:
            for i in range(nlayer - 1):
                Nu[i] = 1.0
                hg[i] = Nu[i] * con / gap[i]

        for i in range(nlayer - 1):
            hs[i] = hg[i] + hr[i]
            rs[2 * i + 2] = 1.0 / hs[i]
            sumRs += rs[2 * i + 2]

        ufactor[0] = 1.0 / (1.0 / hin[0] + 1.0 / hout[0] + sumRs + Rg)
        theta[0] = ufactor[0] * (tind - tout) / hout[0] + tout
        theta[2 * nlayer - 1] = tind - ufactor[0] * (tind - tout) / hin[0]
        for i in range(1, nlayer):
            theta[2 * i - 1] = ufactor[0] * (tind - tout) * thick[0] / scon[0] + theta[2 * i - 2]
            theta[2 * i] = ufactor[0] * (tind - tout) / hs[i - 1] + theta[2 * i - 1]

        iter_count += 1
        diff = fabs(sumRs - sumRsold)
        if diff < eps:
            break

fn linint(x1: Float64, x2: Float64, y1: Float64, y2: Float64, x: Float64,
          y: DynamicVector[Float64]) -> None:
    y[0] = (y2 - y1) / (x2 - x1) * (x - x1) + y1

fn solar_EN673(dir: Float64, totsol: Float64, rtot: Float64,
               rs: DynamicVector[Float64], nlayer: Int32,
               absol: DynamicVector[Float64], sf: DynamicVector[Float64],
               standard: Stdrd, nperr: DynamicVector[Int32],
               ErrorMessage: DynamicVector[String]) -> None:
    var fract: Float64 = 0.0
    var flowin: Float64 = 0.0

    fract = 0.0
    flowin = 0.0
    sf[0] = 0.0

    if (standard == Stdrd()) or (standard == Stdrd()):
        if nlayer == 1:
            fract = dir * absol[0] * (rs[0] * rs[2]) / (rs[0] * (rs[0] + rs[2]))
        else:
            flowin = (rs[0] + 0.5 * rs[1]) / rtot
            fract = dir * absol[0] * rs[9]
            for i in range(1, nlayer):
                var j: Int32 = 2 * i
                flowin += (0.5 * (rs[j - 2] + 0.5 * rs[j]) + rs[j - 1]) / rtot
                fract += absol[i] * flowin
            fract += dir * absol[nlayer - 1] * rs[2 * nlayer - 1] / 2.0
    else:
        nperr[0] = 28
        ErrorMessage[0] = "Invalid code for standard."
        return

    sf[0] = totsol + fract
