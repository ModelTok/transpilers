from DataGlobals import *
from TARCOGArgs import *
from TARCOGCommon import *
from TARCOGGasses90 import *
from TARCOGGassesParams import *
from TARCOGOutput import *
from TARCOGParams import *
from ThermalEN673Calc import *
from memory import memset_zero
from math import abs, pow, sqrt
from sys import exit

def Calc_EN673(
    inout state: EnergyPlusData,
    inout files: TARCOGOutput.Files,
    standard: TARCOGGassesParams.Stdrd,
    nlayer: Int,
    tout: Float64,
    tind: Float64,
    inout gap: Array1D[Float64],
    inout thick: Array1D[Float64],
    inout scon: Array1D[Float64],
    emis: Array1D[Float64],
    totsol: Float64,
    tilt: Float64,
    dir: Float64,
    asol: Array1D[Float64],
    presure: Array1D[Float64],
    inout iprop: Array2A_int,
    inout frct: Array2A[Float64],
    nmix: Array1D_int,
    inout xgcon: Array2A[Float64],
    inout xgvis: Array2A[Float64],
    inout xgcp: Array2A[Float64],
    xwght: Array1D[Float64],
    inout theta: Array1D[Float64],
    inout ufactor: Float64,
    inout hcin: Float64,
    inout hin: Float64,
    inout hout: Float64,
    inout shgc: Float64,
    inout nperr: Int,
    inout ErrorMessage: String,
    ibc: Array1D_int,
    inout hg: Array1D[Float64],
    inout hr: Array1D[Float64],
    inout hs: Array1D[Float64],
    inout Ra: Array1D[Float64],
    inout Nu: Array1D[Float64]
):
    using TARCOGArgs.GoAhead
    using TARCOGOutput
    EP_SIZE_CHECK(gap, MaxGap)
    EP_SIZE_CHECK(thick, maxlay)
    EP_SIZE_CHECK(scon, maxlay)
    EP_SIZE_CHECK(emis, maxlay2)
    EP_SIZE_CHECK(asol, maxlay)
    EP_SIZE_CHECK(presure, maxlay1)
    iprop.dim(maxgas, maxlay1)
    frct.dim(maxgas, maxlay1)
    EP_SIZE_CHECK(nmix, maxlay1)
    xgcon.dim(3, maxgas)
    xgvis.dim(3, maxgas)
    xgcp.dim(3, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)
    EP_SIZE_CHECK(theta, maxlay2)
    EP_SIZE_CHECK(ibc, 2)
    EP_SIZE_CHECK(hg, maxlay)
    EP_SIZE_CHECK(hr, maxlay)
    EP_SIZE_CHECK(hs, maxlay)
    EP_SIZE_CHECK(Ra, maxlay)
    EP_SIZE_CHECK(Nu, maxlay)
    var rs: Array1D[Float64] = Array1D[Float64](maxlay3)
    var rtot: Float64
    var sft: Float64
    rtot = 0.0
    sft = 0.0
    if GoAhead(nperr):
        EN673ISO10292(
            state,
            nlayer,
            tout,
            tind,
            emis,
            gap,
            thick,
            scon,
            tilt,
            iprop,
            frct,
            xgcon,
            xgvis,
            xgcp,
            xwght,
            presure,
            nmix,
            theta,
            standard,
            hg,
            hr,
            hs,
            hin,
            hout,
            hcin,
            ibc,
            rs,
            ufactor,
            Ra,
            Nu,
            nperr,
            ErrorMessage
        )
        if GoAhead(nperr):
            rtot = 1.0 / ufactor
            solar_EN673(dir, totsol, rtot, rs, nlayer, asol, sft, standard, nperr, ErrorMessage)
            if GoAhead(nperr):
                shgc = sft
                if files.WriteDebugOutput:
                    WriteOutputEN673(files.DebugOutputFile, files.DBGD, nlayer, ufactor, hout, hin, Ra, Nu, hg, hr, hs, nperr)


def EN673ISO10292(
    inout state: EnergyPlusData,
    nlayer: Int,
    tout: Float64,
    tind: Float64,
    emis: Array1D[Float64],
    gap: Array1D[Float64],
    thick: Array1D[Float64],
    scon: Array1D[Float64],
    tilt: Float64,
    inout iprop: Array2A_int,
    inout frct: Array2A[Float64],
    inout xgcon: Array2A[Float64],
    inout xgvis: Array2A[Float64],
    inout xgcp: Array2A[Float64],
    xwght: Array1D[Float64],
    presure: Array1D[Float64],
    nmix: Array1D_int,
    inout theta: Array1D[Float64],
    standard: TARCOGGassesParams.Stdrd,
    inout hg: Array1D[Float64],
    inout hr: Array1D[Float64],
    inout hs: Array1D[Float64],
    inout hin: Float64,
    hout: Float64,
    inout hcin: Float64,
    ibc: Array1D_int,
    inout rs: Array1D[Float64],
    inout ufactor: Float64,
    inout Ra: Array1D[Float64],
    inout Nu: Array1D[Float64],
    inout nperr: Int,
    inout ErrorMessage: String
):
    EP_SIZE_CHECK(emis, maxlay2)
    EP_SIZE_CHECK(gap, MaxGap)
    EP_SIZE_CHECK(thick, maxlay)
    EP_SIZE_CHECK(scon, maxlay)
    iprop.dim(maxgas, maxlay1)
    frct.dim(maxgas, maxlay1)
    xgcon.dim(3, maxgas)
    xgvis.dim(3, maxgas)
    xgcp.dim(3, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)
    EP_SIZE_CHECK(presure, maxlay1)
    EP_SIZE_CHECK(nmix, maxlay1)
    EP_SIZE_CHECK(theta, maxlay2)
    EP_SIZE_CHECK(hg, maxlay)
    EP_SIZE_CHECK(hr, maxlay)
    EP_SIZE_CHECK(hs, maxlay)
    EP_SIZE_CHECK(ibc, 2)
    EP_SIZE_CHECK(rs, maxlay3)
    EP_SIZE_CHECK(Ra, maxlay)
    EP_SIZE_CHECK(Nu, maxlay)
    var Tm: Float64
    var diff: Float64
    var Rg: Float64
    var dT: Array1D[Float64] = Array1D[Float64](maxlay1)
    var i: Int
    var j: Int
    var iter: Int
    var dens: Float64
    var visc: Float64
    var con: Float64
    var cp: Float64
    var pr: Float64
    var Gr: Array1D[Float64] = Array1D[Float64](maxlay)
    var A: Float64
    var n: Float64
    var hrin: Float64
    var sumRs: Float64
    var sumRsold: Float64
    var eps: Float64 = 1.0e-4
    var frctg: Array1D[Float64] = Array1D[Float64](maxgas)
    var ipropg: Array1D_int = Array1D_int(maxgas)
    if (emis[2 * nlayer - 1] < 0.85) and (emis[2 * nlayer - 1] > 0.83):
        hrin = 4.4
    else:
        hrin = 4.4 * emis[2 * nlayer - 1] / 0.837
    if ibc[0] != 1:
        nperr = 38
        ErrorMessage = "Boundary conditions for EN673 can be combined hout for outdoor and either convective (hcin) or combined (hin) for indoor.  Others are not supported currently."
        return
    if ibc[1] == 1:

    elif ibc[1] == 2:
        hcin = hin
        hin = hcin + hrin
    else:
        nperr = 39
        ErrorMessage = "CSM and SCW thermal models cannot be used for outdoor and indoor SD layers."
        return
    rs[0] = 1.0 / hout
    rs[2 * nlayer] = 1.0 / hin
    Tm = 283.0
    iter = 1
    sumRs = 0.0
    Rg = 0.0
    Gr = 0.0
    Nu = 0.0
    Ra = 0.0
    con = 0.0
    for i in range(1, nlayer + 1):
        rs[2 * i - 1] = thick[i - 1] / scon[i - 1]
        Rg += rs[2 * i - 1]
    if nlayer == 1:
        ufactor = 1.0 / (1.0 / hin + 1.0 / hout + Rg)
        theta[0] = ufactor * (tind - tout) / hout + tout
        theta[1] = tind - ufactor * (tind - tout) / hin
        return
    if tind > tout:
        if tilt == 0.0:
            A = 0.16
            n = 0.28
        elif (tilt > 0.0) and (tilt < 45.0):
            linint(0.0, 45.0, 0.16, 0.1, tilt, A)
            linint(0.0, 45.0, 0.28, 0.31, tilt, n)
        elif tilt == 45.0:
            A = 0.10
            n = 0.31
        elif (tilt > 45.0) and (tilt < 90.0):
            linint(45.0, 90.0, 0.1, 0.035, tilt, A)
            linint(45.0, 90.0, 0.31, 0.38, tilt, n)
        elif tilt == 90:
            A = 0.035
            n = 0.38
        for i in range(1, nlayer):
            dT[i - 1] = 15.0 / (nlayer - 1)
            for j in range(1, nmix[i] + 1):
                ipropg[j - 1] = iprop[i, j - 1]
                frctg[j - 1] = frct[i, j - 1]
            GASSES90(
                state,
                Tm,
                ipropg,
                frctg,
                presure[i],
                nmix[i],
                xwght,
                xgcon,
                xgvis,
                xgcp,
                con,
                visc,
                dens,
                cp,
                pr,
                standard,
                nperr,
                ErrorMessage
            )
            Gr[i - 1] = (Constant.Gravity * pow_3(gap[i - 1]) * dT[i - 1] * pow_2(dens)) / (Tm * pow_2(visc))
            Ra[i - 1] = Gr[i - 1] * pr
            Nu[i - 1] = A * pow(Ra[i - 1], n)
            if Nu[i - 1] < 1.0:
                Nu[i - 1] = 1.0
            hg[i - 1] = Nu[i - 1] * con / gap[i - 1]
    else:
        for i in range(1, nlayer):
            Nu[i - 1] = 1.0
            hg[i - 1] = Nu[i - 1] * con / gap[i - 1]
    for i in range(1, nlayer):
        hr[i - 1] = 4.0 * Constant.StefanBoltzmann * pow(1.0 / emis[2 * i - 1] + 1.0 / emis[2 * i] - 1.0, -1.0) * pow_3(Tm)
        hs[i - 1] = hg[i - 1] + hr[i - 1]
        rs[2 * i] = 1.0 / hs[i - 1]
        sumRs += rs[2 * i]
    ufactor = 1.0 / (1.0 / hin + 1.0 / hout + sumRs + Rg)
    theta[0] = ufactor * (tind - tout) / hout + tout
    theta[2 * nlayer - 1] = tind - ufactor * (tind - tout) / hin
    for i in range(2, nlayer + 1):
        theta[2 * i - 3] = ufactor * (tind - tout) * thick[0] / scon[0] + theta[2 * i - 4]
        theta[2 * i - 2] = ufactor * (tind - tout) / hs[i - 2] + theta[2 * i - 3]
    while True:
        sumRsold = sumRs
        sumRs = 0.0
        if (standard == TARCOGGassesParams.Stdrd.EN673) and (nlayer == 2):
            return
        if tind > tout:
            for i in range(1, nlayer):
                dT[i - 1] = 15.0 * (1.0 / hs[i - 1]) / sumRsold
                if standard == TARCOGGassesParams.Stdrd.EN673:
                    Tm = 283.0
                else:
                    Tm = (theta[2 * i - 1] + theta[2 * i]) / 2.0
                for j in range(1, nmix[i] + 1):
                    ipropg[j - 1] = iprop[i, j - 1]
                    frctg[j - 1] = frct[i, j - 1]
                GASSES90(
                    state,
                    Tm,
                    ipropg,
                    frctg,
                    presure[i],
                    nmix[i],
                    xwght,
                    xgcon,
                    xgvis,
                    xgcp,
                    con,
                    visc,
                    dens,
                    cp,
                    pr,
                    standard,
                    nperr,
                    ErrorMessage
                )
                Gr[i - 1] = (Constant.Gravity * pow_3(gap[i - 1]) * dT[i - 1] * pow_2(dens)) / (Tm * pow_2(visc))
                Ra[i - 1] = Gr[i - 1] * pr
                Nu[i - 1] = A * pow(Ra[i - 1], n)
                if Nu[i - 1] < 1.0:
                    Nu[i - 1] = 1.0
                hg[i - 1] = Nu[i - 1] * con / gap[i - 1]
        else:
            for i in range(1, nlayer):
                Nu[i - 1] = 1.0
                hg[i - 1] = Nu[i - 1] * con / gap[i - 1]
        for i in range(1, nlayer):
            hs[i - 1] = hg[i - 1] + hr[i - 1]
            rs[2 * i] = 1.0 / hs[i - 1]
            sumRs += rs[2 * i]
        ufactor = 1.0 / (1.0 / hin + 1.0 / hout + sumRs + Rg)
        theta[0] = ufactor * (tind - tout) / hout + tout
        theta[2 * nlayer - 1] = tind - ufactor * (tind - tout) / hin
        for i in range(2, nlayer + 1):
            theta[2 * i - 3] = ufactor * (tind - tout) * thick[0] / scon[0] + theta[2 * i - 4]
            theta[2 * i - 2] = ufactor * (tind - tout) / hs[i - 2] + theta[2 * i - 3]
        iter += 1
        diff = abs(sumRs - sumRsold)
        if diff < eps:
            break


def linint(
    x1: Float64,
    x2: Float64,
    y1: Float64,
    y2: Float64,
    x: Float64,
    inout y: Float64
):
    y = (y2 - y1) / (x2 - x1) * (x - x1) + y1


def solar_EN673(
    dir: Float64,
    totsol: Float64,
    rtot: Float64,
    rs: Array1D[Float64],
    nlayer: Int,
    absol: Array1D[Float64],
    inout sf: Float64,
    standard: TARCOGGassesParams.Stdrd,
    inout nperr: Int,
    inout ErrorMessage: String
):
    EP_SIZE_CHECK(rs, maxlay3)
    EP_SIZE_CHECK(absol, maxlay)
    var fract: Float64
    var flowin: Float64
    fract = 0.0
    flowin = 0.0
    sf = 0.0
    if (standard == TARCOGGassesParams.Stdrd.EN673) or (standard == TARCOGGassesParams.Stdrd.EN673Design):
        if nlayer == 1:
            fract = dir * absol[0] * (rs[0] * rs[2]) / (rs[0] * (rs[0] + rs[2]))
        else:
            flowin = (rs[0] + 0.5 * rs[1]) / rtot
            fract = dir * absol[0] * rs[9]
            for i in range(2, nlayer + 1):
                var j: Int = 2 * i
                flowin += (0.5 * (rs[j - 3] + 0.5 * rs[j - 1]) + rs[j - 2]) / rtot
                fract += absol[i - 1] * flowin
            fract += dir * absol[nlayer - 1] * rs[2 * nlayer - 1] / 2.0
    else:
        nperr = 28
        ErrorMessage = "Invalid code for standard."
        return
    sf = totsol + fract