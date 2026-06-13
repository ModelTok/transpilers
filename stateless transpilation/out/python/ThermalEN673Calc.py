from typing import Protocol, List, Tuple
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus main module
# - TARCOGOutput.Files: file handling structure with WriteDebugOutput, DebugOutputFile, DBGD
# - TARCOGGassesParams.Stdrd: enum for thermal standard (EN673, EN673Design, etc.)
# - Constant.Gravity: gravitational constant = 9.81 m/s²
# - Constant.StefanBoltzmann: Stefan-Boltzmann constant = 5.67e-8 W/(m²·K⁴)
# - GASSES90(state, Tm, ipropg, frctg, presure, nmix, xwght, xgcon, xgvis, xgcp, con_out, visc_out, dens_out, cp_out, pr_out, standard, nperr, ErrorMessage)
# - WriteOutputEN673(file, dbgd, nlayer, ufactor, hout, hin, Ra, Nu, hg, hr, hs, nperr)
# - TARCOGArgs.GoAhead(nperr) -> bool

MaxGap = 10
maxlay = 10
maxlay1 = 11
maxlay2 = 22
maxlay3 = 23
maxgas = 6

class Constant:
    Gravity = 9.81
    StefanBoltzmann = 5.67e-8

class Stdrd(Protocol):
    pass

class Files(Protocol):
    WriteDebugOutput: bool
    DebugOutputFile: object
    DBGD: object

class EnergyPlusData(Protocol):
    pass

def pow_2(x: float) -> float:
    return x * x

def pow_3(x: float) -> float:
    return x * x * x

def GoAhead(nperr: int) -> bool:
    return nperr == 0

def GASSES90(state: EnergyPlusData, Tm: float, ipropg: List[int], frctg: List[float],
             presure: float, nmix: int, xwght: List[float], xgcon: List[List[float]],
             xgvis: List[List[float]], xgcp: List[List[float]], con: List[float],
             visc: List[float], dens: List[float], cp: List[float], pr: List[float],
             standard: Stdrd, nperr: List[int], ErrorMessage: List[str]) -> None:
    pass

def WriteOutputEN673(file: object, dbgd: object, nlayer: int, ufactor: float, hout: float,
                     hin: float, Ra: List[float], Nu: List[float], hg: List[float],
                     hr: List[float], hs: List[float], nperr: int) -> None:
    pass

def Calc_EN673(state: EnergyPlusData, files: Files, standard: Stdrd, nlayer: int,
               tout: float, tind: float, gap: List[float], thick: List[float],
               scon: List[float], emis: List[float], totsol: float, tilt: float,
               dir: float, asol: List[float], presure: List[float],
               iprop: List[List[int]], frct: List[List[float]],
               nmix: List[int], xgcon: List[List[float]], xgvis: List[List[float]],
               xgcp: List[List[float]], xwght: List[float], theta: List[float],
               ufactor: List[float], hcin: List[float], hin: List[float],
               hout: List[float], shgc: List[float], nperr: List[int],
               ErrorMessage: List[str], ibc: List[int], hg: List[float],
               hr: List[float], hs: List[float], Ra: List[float],
               Nu: List[float]) -> None:
    rs = [0.0] * maxlay3
    rtot = 0.0
    sft = 0.0

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
                    WriteOutputEN673(files.DebugOutputFile, files.DBGD, nlayer, ufactor[0],
                                   hout[0], hin[0], Ra, Nu, hg, hr, hs, nperr[0])

def EN673ISO10292(state: EnergyPlusData, nlayer: int, tout: float, tind: float,
                  emis: List[float], gap: List[float], thick: List[float],
                  scon: List[float], tilt: float, iprop: List[List[int]],
                  frct: List[List[float]], xgcon: List[List[float]],
                  xgvis: List[List[float]], xgcp: List[List[float]],
                  xwght: List[float], presure: List[float], nmix: List[int],
                  theta: List[float], standard: Stdrd, hg: List[float],
                  hr: List[float], hs: List[float], hin: List[float],
                  hout: List[float], hcin: List[float], ibc: List[int],
                  rs: List[float], ufactor: List[float], Ra: List[float],
                  Nu: List[float], nperr: List[int],
                  ErrorMessage: List[str]) -> None:
    Tm = 0.0
    diff = 0.0
    Rg = 0.0
    dT = [0.0] * maxlay1
    dens = 0.0
    visc = 0.0
    con = 0.0
    cp = 0.0
    pr = 0.0
    Gr = [0.0] * maxlay
    A = 0.0
    n = 0.0
    hrin = 0.0
    sumRs = 0.0
    sumRsold = 0.0

    eps = 1.0e-4

    frctg = [0.0] * maxgas
    ipropg = [0] * maxgas

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
    iter_count = 1
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
            linint(0.0, 45.0, 0.16, 0.1, tilt, [A])
            linint(0.0, 45.0, 0.28, 0.31, tilt, [n])
        elif tilt == 45.0:
            A = 0.10
            n = 0.31
        elif (tilt > 45.0) and (tilt < 90.0):
            linint(45.0, 90.0, 0.1, 0.035, tilt, [A])
            linint(45.0, 90.0, 0.31, 0.38, tilt, [n])
        elif tilt == 90:
            A = 0.035
            n = 0.38

        for i in range(nlayer - 1):
            dT[i] = 15.0 / (nlayer - 1)
            for j in range(nmix[i + 1]):
                ipropg[j] = iprop[i + 1][j]
                frctg[j] = frct[i + 1][j]

            con_out = [con]
            visc_out = [visc]
            dens_out = [dens]
            cp_out = [cp]
            pr_out = [pr]
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
            Nu[i] = A * math.pow(Ra[i], n)
            if Nu[i] < 1.0:
                Nu[i] = 1.0
            hg[i] = Nu[i] * con / gap[i]
    else:
        for i in range(nlayer - 1):
            Nu[i] = 1.0
            hg[i] = Nu[i] * con / gap[i]

    for i in range(nlayer - 1):
        hr[i] = 4.0 * Constant.StefanBoltzmann * math.pow(1.0 / emis[2 * i] + 1.0 / emis[2 * i + 1] - 1.0, -1.0) * pow_3(Tm)
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

        if (standard == getattr(Stdrd, 'EN673', None)) and (nlayer == 2):
            return

        if tind > tout:
            for i in range(nlayer - 1):
                dT[i] = 15.0 * (1.0 / hs[i]) / sumRsold
                if standard == getattr(Stdrd, 'EN673', None):
                    Tm = 283.0
                else:
                    Tm = (theta[2 * i] + theta[2 * i + 1]) / 2.0
                for j in range(nmix[i + 1]):
                    ipropg[j] = iprop[i + 1][j]
                    frctg[j] = frct[i + 1][j]

                con_out = [con]
                visc_out = [visc]
                dens_out = [dens]
                cp_out = [cp]
                pr_out = [pr]
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
                Nu[i] = A * math.pow(Ra[i], n)
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
        diff = abs(sumRs - sumRsold)
        if diff < eps:
            break

def linint(x1: float, x2: float, y1: float, y2: float, x: float, y: List[float]) -> None:
    y[0] = (y2 - y1) / (x2 - x1) * (x - x1) + y1

def solar_EN673(dir: float, totsol: float, rtot: float, rs: List[float],
                nlayer: int, absol: List[float], sf: List[float],
                standard: Stdrd, nperr: List[int],
                ErrorMessage: List[str]) -> None:
    fract = 0.0
    flowin = 0.0

    fract = 0.0
    flowin = 0.0
    sf[0] = 0.0

    if (standard == getattr(Stdrd, 'EN673', None)) or (standard == getattr(Stdrd, 'EN673Design', None)):
        if nlayer == 1:
            fract = dir * absol[0] * (rs[0] * rs[2]) / (rs[0] * (rs[0] + rs[2]))
        else:
            flowin = (rs[0] + 0.5 * rs[1]) / rtot
            fract = dir * absol[0] * rs[9]
            for i in range(1, nlayer):
                j = 2 * i
                flowin += (0.5 * (rs[j - 2] + 0.5 * rs[j]) + rs[j - 1]) / rtot
                fract += absol[i] * flowin
            fract += dir * absol[nlayer - 1] * rs[2 * nlayer - 1] / 2.0
    else:
        nperr[0] = 28
        ErrorMessage[0] = "Invalid code for standard."
        return

    sf[0] = totsol + fract
