from DataGlobals import *
from TARCOGCommon import *
from TARCOGGassesParams import *
from TARCOGOutput import *
from TARCOGParams import *
from  import EnergyPlusData, format, Real64, Array1D, Array2A_int, Array2A_Real64, Array1D_int
from TARCOGOutput import Files
from TARCOGGassesParams import Stdrd
from TARCOGParams import DeflectionCalculation, TARCOGThermalModel, TARCOGLayerType
from TARCOGCommon import IsShadingLayer, WriteInputArguments, WriteTARCOGInputFile, EP_SIZE_CHECK, maxlay, MaxGap, maxlay2, maxlay1, maxgas, C4_VENET_HORIZONTAL, C4_VENET_VERTICAL, MinStandard, MaxStandard
from Constant import Pi, StefanBoltzmann
from math import cos, sin, sqrt, pow, abs

def ArgCheck(
    state: EnergyPlusData,
    files: Files,
    nlayer: Int,
    iwd: Int,
    tout: Real64,
    tind: Real64,
    trmin: Real64,
    wso: Real64,
    wsi: Real64,
    dir: Real64,
    outir: Real64,
    isky: Int,
    tsky: Real64,
    esky: Real64,
    fclr: Real64,
    VacuumPressure: Real64,
    VacuumMaxGapThickness: Real64,
    CalcDeflection: DeflectionCalculation,
    Pa: Real64,
    Pini: Real64,
    Tini: Real64,
    gap: Array1D[Real64],
    GapDef: Array1D[Real64],
    thick: Array1D[Real64],
    scon: Array1D[Real64],
    YoungsMod: Array1D[Real64],
    PoissonsRat: Array1D[Real64],
    tir: Array1D[Real64],
    emis: Array1D[Real64],
    totsol: Real64,
    tilt: Real64,
    asol: Array1D[Real64],
    height: Real64,
    heightt: Real64,
    width: Real64,
    presure: Array1D[Real64],
    iprop: Array2A_int,
    frct: Array2A_Real64,
    xgcon: Array2A_Real64,
    xgvis: Array2A_Real64,
    xgcp: Array2A_Real64,
    xwght: Array1D[Real64],
    gama: Array1D[Real64],
    nmix: Array1D_int,
    SupportPillar: Array1D_int,
    PillarSpacing: Array1D[Real64],
    PillarRadius: Array1D[Real64],
    hin: Real64,
    hout: Real64,
    ibc: Array1D_int,
    Atop: Array1D[Real64],
    Abot: Array1D[Real64],
    Al: Array1D[Real64],
    Ar: Array1D[Real64],
    Ah: Array1D[Real64],
    SlatThick: Array1D[Real64],
    SlatWidth: Array1D[Real64],
    SlatAngle: Array1D[Real64],
    SlatCond: Array1D[Real64],
    SlatSpacing: Array1D[Real64],
    SlatCurve: Array1D[Real64],
    vvent: Array1D[Real64],
    tvent: Array1D[Real64],
    LayerType: Array1D[TARCOGLayerType],
    nslice: Array1D_int,
    LaminateA: Array1D[Real64],
    LaminateB: Array1D[Real64],
    sumsol: Array1D[Real64],
    standard: Stdrd,
    ThermalMod: TARCOGThermalModel,
    SDScalar: Real64,
    ErrorMessage: String,
) -> Int:
    var ArgCheck: Int
    EP_SIZE_CHECK(gap, maxlay)
    EP_SIZE_CHECK(GapDef, MaxGap)
    EP_SIZE_CHECK(thick, maxlay)
    EP_SIZE_CHECK(scon, maxlay)
    EP_SIZE_CHECK(YoungsMod, maxlay)
    EP_SIZE_CHECK(PoissonsRat, maxlay)
    EP_SIZE_CHECK(tir, maxlay2)
    EP_SIZE_CHECK(emis, maxlay2)
    EP_SIZE_CHECK(asol, maxlay)
    EP_SIZE_CHECK(presure, maxlay1)
    iprop.dim(maxgas, maxlay1)
    frct.dim(maxgas, maxlay1)
    xgcon.dim(3, maxgas)
    xgvis.dim(3, maxgas)
    xgcp.dim(3, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)
    EP_SIZE_CHECK(gama, maxgas)
    EP_SIZE_CHECK(nmix, maxlay1)
    EP_SIZE_CHECK(SupportPillar, maxlay)
    EP_SIZE_CHECK(PillarSpacing, maxlay)
    EP_SIZE_CHECK(PillarRadius, maxlay)
    EP_SIZE_CHECK(ibc, 2)
    EP_SIZE_CHECK(Atop, maxlay)
    EP_SIZE_CHECK(Abot, maxlay)
    EP_SIZE_CHECK(Al, maxlay)
    EP_SIZE_CHECK(Ar, maxlay)
    EP_SIZE_CHECK(Ah, maxlay)
    EP_SIZE_CHECK(SlatThick, maxlay)
    EP_SIZE_CHECK(SlatWidth, maxlay)
    EP_SIZE_CHECK(SlatAngle, maxlay)
    EP_SIZE_CHECK(SlatCond, maxlay)
    EP_SIZE_CHECK(SlatSpacing, maxlay)
    EP_SIZE_CHECK(SlatCurve, maxlay)
    EP_SIZE_CHECK(vvent, maxlay1)
    EP_SIZE_CHECK(tvent, maxlay1)
    EP_SIZE_CHECK(LayerType, maxlay)
    EP_SIZE_CHECK(nslice, maxlay)
    EP_SIZE_CHECK(LaminateA, maxlay)
    EP_SIZE_CHECK(LaminateB, maxlay)
    EP_SIZE_CHECK(sumsol, maxlay)
    if files.WriteDebugOutput:
        WriteInputArguments(
            state,
            files.DebugOutputFile,
            files.DBGD,
            tout,
            tind,
            trmin,
            wso,
            iwd,
            wsi,
            dir,
            outir,
            isky,
            tsky,
            esky,
            fclr,
            VacuumPressure,
            VacuumMaxGapThickness,
            ibc,
            hout,
            hin,
            standard,
            ThermalMod,
            SDScalar,
            height,
            heightt,
            width,
            tilt,
            totsol,
            nlayer,
            LayerType,
            thick,
            scon,
            asol,
            tir,
            emis,
            Atop,
            Abot,
            Al,
            Ar,
            Ah,
            SlatThick,
            SlatWidth,
            SlatAngle,
            SlatCond,
            SlatSpacing,
            SlatCurve,
            nslice,
            LaminateA,
            LaminateB,
            sumsol,
            gap,
            vvent,
            tvent,
            presure,
            nmix,
            iprop,
            frct,
            xgcon,
            xgvis,
            xgcp,
            xwght,
        )
        var VersionNumber: String = " 7.0.15.00 "
        WriteTARCOGInputFile(
            state,
            files,
            VersionNumber,
            tout,
            tind,
            trmin,
            wso,
            iwd,
            wsi,
            dir,
            outir,
            isky,
            tsky,
            esky,
            fclr,
            VacuumPressure,
            VacuumMaxGapThickness,
            CalcDeflection,
            Pa,
            Pini,
            Tini,
            ibc,
            hout,
            hin,
            standard,
            ThermalMod,
            SDScalar,
            height,
            heightt,
            width,
            tilt,
            totsol,
            nlayer,
            LayerType,
            thick,
            scon,
            YoungsMod,
            PoissonsRat,
            asol,
            tir,
            emis,
            Atop,
            Abot,
            Al,
            Ar,
            Ah,
            SupportPillar,
            PillarSpacing,
            PillarRadius,
            SlatThick,
            SlatWidth,
            SlatAngle,
            SlatCond,
            SlatSpacing,
            SlatCurve,
            nslice,
            gap,
            GapDef,
            vvent,
            tvent,
            presure,
            nmix,
            iprop,
            frct,
            xgcon,
            xgvis,
            xgcp,
            xwght,
            gama,
        )
    ArgCheck = 0
    if nlayer < 1:
        ArgCheck = 17
        ErrorMessage = "Number of layers must be >0."
        return ArgCheck
    if (Int(standard) < MinStandard) or (Int(standard) > MaxStandard):
        ArgCheck = 28
        ErrorMessage = "Invalid code for standard."
        return ArgCheck
    if (ThermalMod != TARCOGThermalModel.ISO15099) and (ThermalMod != TARCOGThermalModel.SCW) and (ThermalMod != TARCOGThermalModel.CSM):
        ArgCheck = 29
        ErrorMessage = "Invalid code for thermal mode."
        return ArgCheck
    if (iwd != 0) and (iwd != 1):
        ArgCheck = 18
        ErrorMessage = "Wind direction can be windward (=0) or leeward (=1)."
        return ArgCheck
    if (fclr < 0.0) or (fclr > 1.0):
        ArgCheck = 19
        ErrorMessage = "Fraction of sky that is clear can be in range between 0 and 1."
        return ArgCheck
    for i in range(1, nlayer):
        if gap[i - 1] <= 0.0:
            ArgCheck = 20
            ErrorMessage = format("Gap width is less than (or equal to) zero. Gap #{:3}", i)
            return ArgCheck
    for i in range(1, nlayer + 1):
        if thick[i - 1] <= 0.0:
            ArgCheck = 21
            ErrorMessage = format("Layer width is less than (or equal to) zero. Layer #{:3}", i)
            return ArgCheck
        if (i < nlayer) and IsShadingLayer(LayerType[i - 1]) and IsShadingLayer(LayerType[i]):
            ArgCheck = 37
            ErrorMessage = "Cannot handle two consecutive shading layers."
            return ArgCheck
        if (CalcDeflection != DeflectionCalculation.NONE) and (LayerType[i - 1] != TARCOGLayerType.SPECULAR):
            ArgCheck = 42
            ErrorMessage = "Cannot calculate deflection with IGU containing shading devices."
            return ArgCheck
    if height <= 0.0:
        ArgCheck = 23
        ErrorMessage = "IGU cavity height must be greater than zero."
        return ArgCheck
    if heightt <= 0.0:
        ArgCheck = 24
        ErrorMessage = "Total window height must be greater than zero."
        return ArgCheck
    if width <= 0.0:
        ArgCheck = 25
        ErrorMessage = "Window width must be greater than zero."
        return ArgCheck
    if (SDScalar < 0.0) or (SDScalar > 1.0):
        ArgCheck = 30
        ErrorMessage = "SDscalar is out of range (<0.0 or >1.0)."
        return ArgCheck
    for i in range(1, nlayer + 1):
        if scon[i - 1] <= 0.0:
            ArgCheck = 26
            ErrorMessage = format("Layer {:3} has conductivity which is less or equal to zero.", i)
            return ArgCheck
        if LayerType[i - 1] != TARCOGLayerType.SPECULAR and LayerType[i - 1] != TARCOGLayerType.WOVSHADE and LayerType[i - 1] != TARCOGLayerType.VENETBLIND_HORIZ and LayerType[i - 1] != TARCOGLayerType.PERFORATED and LayerType[i - 1] != TARCOGLayerType.DIFFSHADE and LayerType[i - 1] != TARCOGLayerType.BSDF and LayerType[i - 1] != TARCOGLayerType.VENETBLIND_VERT:
            ArgCheck = 22
            ErrorMessage = format(
                "Incorrect layer type for layer #{:3}"
                ".  Layer type can either be 0 (glazing layer), 1 (Venetian blind), 2 (woven shade), 3 (perforated), 4 (diffuse "
                "shade) or 5 (bsdf).",
                i,
            )
            return ArgCheck
        if (IsShadingLayer(LayerType[0])) and ((ThermalMod == TARCOGThermalModel.SCW) or (ThermalMod == TARCOGThermalModel.CSM)):
            ArgCheck = 39
            ErrorMessage = "CSM and SCW thermal models cannot be used for outdoor and indoor SD layers."
            return ArgCheck
        if (IsShadingLayer(LayerType[nlayer - 1])) and ((ThermalMod == TARCOGThermalModel.SCW) or (ThermalMod == TARCOGThermalModel.CSM)):
            ArgCheck = 39
            ErrorMessage = "CSM and SCW thermal models cannot be used for outdoor and indoor SD layers."
            return ArgCheck
        if LayerType[i - 1] == TARCOGLayerType.VENETBLIND_HORIZ or LayerType[i - 1] == TARCOGLayerType.VENETBLIND_VERT:
            if SlatThick[i - 1] <= 0:
                ArgCheck = 31
                ErrorMessage = format("Invalid slat thickness (must be >0). Layer #{:3}", i)
                return ArgCheck
            if SlatWidth[i - 1] <= 0.0:
                ArgCheck = 32
                ErrorMessage = format("Invalid slat width (must be >0). Layer #{:3}", i)
                return ArgCheck
            if (SlatAngle[i - 1] < -90.0) or (SlatAngle[i - 1] > 90.0):
                ArgCheck = 33
                ErrorMessage = format("Invalid slat angle (must be between -90 and 90). Layer #{:3}", i)
                return ArgCheck
            if SlatCond[i - 1] <= 0.0:
                ArgCheck = 34
                ErrorMessage = format("Invalid conductivity of slat material (must be >0). Layer #{:3}", i)
                return ArgCheck
            if SlatSpacing[i - 1] <= 0.0:
                ArgCheck = 35
                ErrorMessage = format("Invalid slat spacing (must be >0). Layer #{:3}", i)
                return ArgCheck
            if (SlatCurve[i - 1] != 0.0) and (abs(SlatCurve[i - 1]) <= (SlatWidth[i - 1] / 2.0)):
                ArgCheck = 36
                ErrorMessage = format(
                    "Invalid curvature radius (absolute value must be >SlatWidth/2, or 0 for flat slats). Layer #{:3}", i
                )
                return ArgCheck
    for i in range(1, nlayer + 2):
        if presure[i - 1] < 0.0:
            ArgCheck = 27
            if (i == 1) or (i == (nlayer + 1)):
                ErrorMessage = "One of environments (inside or outside) has pressure which is less than zero."
            else:
                ErrorMessage = format("One of gaps has pressure which is less than zero. Gap #{:3}", i)
            return ArgCheck
    return ArgCheck

def PrepVariablesISO15099(
    nlayer: Int,
    tout: Real64,
    tind: Real64,
    trmin: Real64,
    isky: Int,
    outir: Real64,
    tsky: Real64,
    esky: Real64,
    fclr: Real64,
    gap: Array1D[Real64],
    thick: Array1D[Real64],
    scon: Array1D[Real64],
    tir: Array1D[Real64],
    emis: Array1D[Real64],
    tilt: Real64,
    hin: Real64,
    hout: Real64,
    ibc: Array1D_int,
    SlatThick: Array1D[Real64],
    SlatWidth: Array1D[Real64],
    SlatAngle: Array1D[Real64],
    SlatCond: Array1D[Real64],
    LayerType: Array1D[TARCOGLayerType],
    ThermalMod: TARCOGThermalModel,
    SDScalar: Real64,
    ShadeEmisRatioOut: Real64,
    ShadeEmisRatioIn: Real64,
    ShadeHcRatioOut: Real64,
    ShadeHcRatioIn: Real64,
    Keff: Array1D[Real64],
    ShadeGapKeffConv: Array1D[Real64],
    sc: Real64,
    shgc: Real64,
    ufactor: Real64,
    flux: Real64,
    LaminateAU: Array1D[Real64],
    sumsolU: Array1D[Real64],
    sol0: Array1D[Real64],
    hint: Real64,
    houtt: Real64,
    trmout: Real64,
    ebsky: Real64,
    ebroom: Real64,
    Gout: Real64,
    Gin: Real64,
    rir: Array1D[Real64],
    vfreevent: Array1D[Real64],
    nperr: Int,
    ErrorMessage: String,
):
    EP_SIZE_CHECK(gap, MaxGap)
    EP_SIZE_CHECK(thick, maxlay)
    EP_SIZE_CHECK(scon, maxlay)
    EP_SIZE_CHECK(tir, maxlay2)
    EP_SIZE_CHECK(emis, maxlay2)
    EP_SIZE_CHECK(ibc, 2)
    EP_SIZE_CHECK(SlatThick, maxlay)
    EP_SIZE_CHECK(SlatWidth, maxlay)
    EP_SIZE_CHECK(SlatAngle, maxlay)
    EP_SIZE_CHECK(SlatCond, maxlay)
    EP_SIZE_CHECK(LayerType, maxlay)
    EP_SIZE_CHECK(Keff, maxlay)
    EP_SIZE_CHECK(ShadeGapKeffConv, MaxGap)
    EP_SIZE_CHECK(LaminateAU, maxlay)
    EP_SIZE_CHECK(sumsolU, maxlay)
    EP_SIZE_CHECK(sol0, maxlay)
    EP_SIZE_CHECK(rir, maxlay2)
    EP_SIZE_CHECK(vfreevent, maxlay1)
    var tiltr: Real64
    var Rsky: Real64
    var Fsky: Real64
    var Fground: Real64
    var e0: Real64
    ShadeEmisRatioOut = 1.0
    ShadeEmisRatioIn = 1.0
    ShadeHcRatioOut = 1.0
    ShadeHcRatioIn = 1.0
    sc = 0.0
    shgc = 0.0
    ufactor = 0.0
    flux = 0.0
    LaminateAU = 0.0
    sumsolU = 0.0
    vfreevent = 0.0
    sol0 = 0.0
    Keff = 0.0
    ShadeGapKeffConv = 0.0
    for i in range(1, nlayer + 1):
        if (TARCOGLayerType(LayerType[i - 1]) == TARCOGLayerType.VENETBLIND_HORIZ) or (TARCOGLayerType(LayerType[i - 1]) == TARCOGLayerType.VENETBLIND_VERT):
            scon[i - 1] = SlatCond[i - 1]
            if ThermalMod == TARCOGThermalModel.SCW:
                thick[i - 1] = SlatWidth[i - 1] * cos(SlatAngle[i - 1] * Pi / 180.0)
                if i > 1:
                    gap[i - 2] += (1.0 - SDScalar) / 2.0 * thick[i - 1]
                gap[i - 1] += (1.0 - SDScalar) / 2.0 * thick[i - 1]
                thick[i - 1] *= SDScalar
                if thick[i - 1] < SlatThick[i - 1]:
                    thick[i - 1] = SlatThick[i - 1]
            elif (ThermalMod == TARCOGThermalModel.ISO15099) or (ThermalMod == TARCOGThermalModel.CSM):
                thick[i - 1] = SlatThick[i - 1]
                var slatAngRad: Real64 = SlatAngle[i - 1] * 2.0 * Pi / 360.0
                var C4_VENET: Real64 = 0.0
                if (TARCOGLayerType(LayerType[i - 1]) == TARCOGLayerType.VENETBLIND_HORIZ):
                    C4_VENET = C4_VENET_HORIZONTAL
                if (TARCOGLayerType(LayerType[i - 1]) == TARCOGLayerType.VENETBLIND_VERT):
                    C4_VENET = C4_VENET_VERTICAL
                thick[i - 1] = C4_VENET * (SlatWidth[i - 1] * cos(slatAngRad) + thick[i - 1] * sin(slatAngRad))
    hint = hin
    houtt = hout
    tiltr = tilt * 2.0 * Pi / 360.0
    if isky == 3:
        Gout = outir
        trmout = root_4(Gout / StefanBoltzmann)
    elif isky == 2:
        Rsky = 5.31e-13 * pow_6(tout)
        esky = Rsky / (StefanBoltzmann * pow_4(tout))
    elif isky == 1:
        esky = pow_4(tsky) / pow_4(tout)
    elif isky == 0:
        esky *= pow_4(tsky) / pow_4(tout)
    else:
        nperr = 1
        return
    if isky != 3:
        Fsky = (1.0 + cos(tiltr)) / 2.0
        Fground = 1.0 - Fsky
        e0 = Fground + (1.0 - fclr) * Fsky + Fsky * fclr * esky
        if ibc[0] == 1:
            trmout = tout
        else:
            trmout = tout * root_4(e0)
        Gout = StefanBoltzmann * pow_4(trmout)
    ebsky = Gout
    if ibc[1] == 1:
        trmin = tind
    Gin = StefanBoltzmann * pow_4(trmin)
    ebroom = Gin
    for k in range(1, nlayer + 1):
        var k1: Int = 2 * k - 1
        rir[k1 - 1] = 1 - tir[k1 - 1] - emis[k1 - 1]
        rir[k1] = 1 - tir[k1] - emis[k1]
        if (tir[k1 - 1] < 0.0) or (tir[k1 - 1] > 1.0) or (tir[k1] < 0.0) or (tir[k1] > 1.0):
            nperr = 4
            ErrorMessage = format("Layer transmissivity is our of range (<0 or >1). Layer #{:3}", k)
            return
        if (emis[k1 - 1] < 0.0) or (emis[k1 - 1] > 1.0) or (emis[k1] < 0.0) or (emis[k1] > 1.0):
            nperr = 14
            ErrorMessage = format("Layer emissivity is our of range (<0 or >1). Layer #{:3}", k)
            return
        if (rir[k1 - 1] < 0.0) or (rir[k1 - 1] > 1.0) or (rir[k1] < 0.0) or (rir[k1] > 1.0):
            nperr = 3
            ErrorMessage = format("Layer reflectivity is our of range (<0 or >1). Layer #{:3}", k)
            return

def GoAhead(nperr: Int) -> Bool:
    return not (((nperr > 0) and (nperr < 1000)) or ((nperr > 2000) and (nperr < 3000)))