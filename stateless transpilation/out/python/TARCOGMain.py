# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object container (source: EnergyPlus/Data/EnergyPlusData.hh)
# - Files: file handle class (source: TARCOGOutput.hh)
# - PrepDebugFilesAndVariables: function (source: TARCOGOutput.hh)
# - ArgCheck: function (source: TARCOGArgs.hh)
# - PanesDeflection: function (source: TARCOGDeflection.hh)
# - Calc_ISO15099: function (source: ThermalISO15099Calc.hh)
# - Calc_EN673: function (source: ThermalEN673Calc.hh)
# - FinishDebugOutputFiles: function (source: TARCOGOutput.hh)
# - GoAhead: function (source: TARCOGParams.hh)
# - DeflectionCalculation: enum (source: TARCOGParams.hh)
# - TARCOGLayerType: enum (source: TARCOGParams.hh)
# - TARCOGThermalModel: enum (source: TARCOGParams.hh)
# - Stdrd: enum (source: TARCOGGassesParams.hh)
# - Constants: maxlay, maxlay1, maxlay2, maxlay3, MaxGap, maxgas, DeflectionErrorMargin, DeflectionMaxIterations

from typing import List, Protocol, Any


class EnergyPlusData(Protocol):
    dataTARCOGMain: Any


class TARCOGMainData:
    def __init__(self):
        self.sconTemp: List[float] = []
        self.thickTemp: List[float] = []
        self.converged: bool = False
        self.told: List[float] = []
        self.CurGap: List[float] = []
        self.GapDefMean: List[float] = []

    def init_constant_state(self, state: EnergyPlusData) -> None:
        pass

    def init_state(self, state: EnergyPlusData) -> None:
        pass

    def clear_state(self) -> None:
        self.sconTemp = [0.0] * 100
        self.thickTemp = [0.0] * 100
        self.converged = False
        self.told = [0.0] * 200
        self.CurGap = [0.0] * 100
        self.GapDefMean = [0.0] * 100


def TARCOG90(
    state: EnergyPlusData,
    nlayer: int,
    iwd: int,
    tout: List[float],
    tind: List[float],
    trmin: List[float],
    wso: float,
    wsi: float,
    dir: float,
    outir: float,
    isky: int,
    tsky: float,
    esky: List[float],
    fclr: float,
    VacuumPressure: float,
    VacuumMaxGapThickness: List[float],
    CalcDeflection: Any,
    Pa: float,
    Pini: float,
    Tini: float,
    gap: List[float],
    GapDefMax: List[float],
    thick: List[float],
    scon: List[float],
    YoungsMod: List[float],
    PoissonsRat: List[float],
    tir: List[float],
    emis: List[float],
    totsol: float,
    tilt: float,
    asol: List[float],
    height: float,
    heightt: float,
    width: float,
    presure: List[float],
    iprop: List[List[int]],
    frct: List[List[float]],
    xgcon: List[List[float]],
    xgvis: List[List[float]],
    xgcp: List[List[float]],
    xwght: List[float],
    gama: List[float],
    nmix: List[int],
    SupportPillar: List[int],
    PillarSpacing: List[float],
    PillarRadius: List[float],
    theta: List[float],
    LayerDef: List[float],
    q: List[float],
    qv: List[float],
    ufactor: List[float],
    sc: List[float],
    hflux: List[float],
    hcin: List[float],
    hcout: List[float],
    hrin: List[float],
    hrout: List[float],
    hin: List[float],
    hout: List[float],
    hcgas: List[float],
    hrgas: List[float],
    shgc: List[float],
    nperr: List[int],
    ErrorMessage: List[str],
    shgct: List[float],
    tamb: List[float],
    troom: List[float],
    ibc: List[int],
    Atop: List[float],
    Abot: List[float],
    Al: List[float],
    Ar: List[float],
    Ah: List[float],
    SlatThick: List[float],
    SlatWidth: List[float],
    SlatAngle: List[float],
    SlatCond: List[float],
    SlatSpacing: List[float],
    SlatCurve: List[float],
    vvent: List[float],
    tvent: List[float],
    LayerType: List[Any],
    nslice: List[int],
    LaminateA: List[float],
    LaminateB: List[float],
    sumsol: List[float],
    hg: List[float],
    hr: List[float],
    hs: List[float],
    he: List[float],
    hi: List[float],
    Ra: List[float],
    Nu: List[float],
    standard: Any,
    ThermalMod: Any,
    Debug_mode: int,
    Debug_dir: str,
    Debug_file: str,
    win_ID: int,
    igu_ID: int,
    ShadeEmisRatioOut: List[float],
    ShadeEmisRatioIn: List[float],
    ShadeHcRatioOut: List[float],
    ShadeHcRatioIn: List[float],
    HcUnshadedOut: List[float],
    HcUnshadedIn: List[float],
    Keff: List[float],
    ShadeGapKeffConv: List[float],
    SDScalar: float,
    SHGCCalc: int,
    NumOfIterations: List[int],
    edgeGlCorrFac: float,
) -> None:
    from enum import Enum

    eskyTemp = 0.0
    trminTemp = 0.0
    hinTemp = 0.0
    houtTemp = 0.0

    dtmax = 0.0
    i = 0
    counter = 0

    he[0] = 0.0
    hi[0] = 0.0
    hcin[0] = 0.0
    hrin[0] = 0.0
    hcout[0] = 0.0
    hrout[0] = 0.0
    LayerDef[:] = [0.0] * len(LayerDef)
    dtmax = 0.0
    i = 0
    counter = 0
    eskyTemp = 0.0
    trminTemp = 0.0
    hinTemp = 0.0
    houtTemp = 0.0
    ErrorMessage[0] = "Normal Termination"

    for i in range(1, nlayer):
        state.dataTARCOGMain.CurGap[i - 1] = gap[i - 1]

    files = None
    from TARCOG_stubs import (
        PrepDebugFilesAndVariables,
        ArgCheck,
        PanesDeflection,
        Calc_ISO15099,
        Calc_EN673,
        FinishDebugOutputFiles,
        GoAhead,
        Files,
    )
    from TARCOG_enums import (
        DeflectionCalculation,
        Stdrd,
        TARCOGLayerType,
        TARCOGThermalModel,
    )

    files = Files()

    PrepDebugFilesAndVariables(state, files, Debug_dir, Debug_file, Debug_mode, win_ID, igu_ID)

    nperr[0] = ArgCheck(
        state,
        files,
        nlayer,
        iwd,
        tout,
        tind,
        trmin,
        wso,
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
        gap,
        GapDefMax,
        thick,
        scon,
        YoungsMod,
        PoissonsRat,
        tir,
        emis,
        totsol,
        tilt,
        asol,
        height,
        heightt,
        width,
        presure,
        iprop,
        frct,
        xgcon,
        xgvis,
        xgcp,
        xwght,
        gama,
        nmix,
        SupportPillar,
        PillarSpacing,
        PillarRadius,
        hin,
        hout,
        ibc,
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
        vvent,
        tvent,
        LayerType,
        nslice,
        LaminateA,
        LaminateB,
        sumsol,
        standard,
        ThermalMod,
        SDScalar,
        ErrorMessage,
    )

    if CalcDeflection == DeflectionCalculation.GAP_WIDTHS:
        PanesDeflection(
            CalcDeflection,
            width,
            height,
            nlayer,
            Pa,
            Pini,
            Tini,
            thick,
            gap,
            GapDefMax,
            state.dataTARCOGMain.GapDefMean,
            theta,
            YoungsMod,
            PoissonsRat,
            LayerDef,
            nperr,
            ErrorMessage,
        )
        for i in range(1, nlayer):
            state.dataTARCOGMain.CurGap[i - 1] = state.dataTARCOGMain.GapDefMean[i - 1]

    if CalcDeflection == DeflectionCalculation.TEMPERATURE:
        eskyTemp = esky[0]
        trminTemp = trmin[0]
        hinTemp = hin[0]
        houtTemp = hout[0]
        state.dataTARCOGMain.sconTemp = scon[:]
        state.dataTARCOGMain.thickTemp = thick[:]

    if GoAhead(nperr[0]):

        if standard == Stdrd.ISO15099:
            Calc_ISO15099(
                state,
                files,
                nlayer,
                iwd,
                tout,
                tind,
                trmin,
                wso,
                wsi,
                dir,
                outir,
                isky,
                tsky,
                esky,
                fclr,
                VacuumPressure,
                VacuumMaxGapThickness,
                state.dataTARCOGMain.CurGap,
                thick,
                scon,
                tir,
                emis,
                totsol,
                tilt,
                asol,
                height,
                heightt,
                width,
                presure,
                iprop,
                frct,
                xgcon,
                xgvis,
                xgcp,
                xwght,
                gama,
                nmix,
                SupportPillar,
                PillarSpacing,
                PillarRadius,
                theta,
                q,
                qv,
                ufactor,
                sc,
                hflux,
                hcin,
                hcout,
                hrin,
                hrout,
                hin,
                hout,
                hcgas,
                hrgas,
                shgc,
                nperr,
                ErrorMessage,
                shgct,
                tamb,
                troom,
                ibc,
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
                vvent,
                tvent,
                LayerType,
                nslice,
                LaminateA,
                LaminateB,
                sumsol,
                Ra,
                Nu,
                ThermalMod,
                Debug_mode,
                ShadeEmisRatioOut,
                ShadeEmisRatioIn,
                ShadeHcRatioOut,
                ShadeHcRatioIn,
                HcUnshadedOut,
                HcUnshadedIn,
                Keff,
                ShadeGapKeffConv,
                SDScalar,
                SHGCCalc,
                NumOfIterations,
                edgeGlCorrFac,
            )
        elif (standard == Stdrd.EN673) or (standard == Stdrd.EN673Design):
            Calc_EN673(
                state,
                files,
                standard,
                nlayer,
                tout,
                tind,
                state.dataTARCOGMain.CurGap,
                thick,
                scon,
                emis,
                totsol,
                tilt,
                dir,
                asol,
                presure,
                iprop,
                frct,
                nmix,
                xgcon,
                xgvis,
                xgcp,
                xwght,
                theta,
                ufactor,
                hcin,
                hin,
                hout,
                shgc,
                nperr,
                ErrorMessage,
                ibc,
                hg,
                hr,
                hs,
                Ra,
                Nu,
            )

    if GoAhead(nperr[0]):
        if not GoAhead(nperr[0]):
            return

        if CalcDeflection == DeflectionCalculation.TEMPERATURE:
            state.dataTARCOGMain.converged = False
            while not state.dataTARCOGMain.converged:
                PanesDeflection(
                    CalcDeflection,
                    width,
                    height,
                    nlayer,
                    Pa,
                    Pini,
                    Tini,
                    thick,
                    gap,
                    GapDefMax,
                    state.dataTARCOGMain.GapDefMean,
                    theta,
                    YoungsMod,
                    PoissonsRat,
                    LayerDef,
                    nperr,
                    ErrorMessage,
                )

                if not GoAhead(nperr[0]):
                    return

                for i in range(1, 2 * nlayer + 1):
                    state.dataTARCOGMain.told[i - 1] = theta[i - 1]

                esky[0] = eskyTemp
                trmin[0] = trminTemp
                hin[0] = hinTemp
                hout[0] = houtTemp
                scon[:] = state.dataTARCOGMain.sconTemp[:]
                thick[:] = state.dataTARCOGMain.thickTemp[:]

                if standard == Stdrd.ISO15099:
                    Calc_ISO15099(
                        state,
                        files,
                        nlayer,
                        iwd,
                        tout,
                        tind,
                        trmin,
                        wso,
                        wsi,
                        dir,
                        outir,
                        isky,
                        tsky,
                        esky,
                        fclr,
                        VacuumPressure,
                        VacuumMaxGapThickness,
                        state.dataTARCOGMain.GapDefMean,
                        thick,
                        scon,
                        tir,
                        emis,
                        totsol,
                        tilt,
                        asol,
                        height,
                        heightt,
                        width,
                        presure,
                        iprop,
                        frct,
                        xgcon,
                        xgvis,
                        xgcp,
                        xwght,
                        gama,
                        nmix,
                        SupportPillar,
                        PillarSpacing,
                        PillarRadius,
                        theta,
                        q,
                        qv,
                        ufactor,
                        sc,
                        hflux,
                        hcin,
                        hcout,
                        hrin,
                        hrout,
                        hin,
                        hout,
                        hcgas,
                        hrgas,
                        shgc,
                        nperr,
                        ErrorMessage,
                        shgct,
                        tamb,
                        troom,
                        ibc,
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
                        vvent,
                        tvent,
                        LayerType,
                        nslice,
                        LaminateA,
                        LaminateB,
                        sumsol,
                        Ra,
                        Nu,
                        ThermalMod,
                        Debug_mode,
                        ShadeEmisRatioOut,
                        ShadeEmisRatioIn,
                        ShadeHcRatioOut,
                        ShadeHcRatioIn,
                        HcUnshadedOut,
                        HcUnshadedIn,
                        Keff,
                        ShadeGapKeffConv,
                        SDScalar,
                        SHGCCalc,
                        NumOfIterations,
                        edgeGlCorrFac,
                    )
                elif (standard == Stdrd.EN673) or (standard == Stdrd.EN673Design):
                    Calc_EN673(
                        state,
                        files,
                        standard,
                        nlayer,
                        tout,
                        tind,
                        state.dataTARCOGMain.GapDefMean,
                        thick,
                        scon,
                        emis,
                        totsol,
                        tilt,
                        dir,
                        asol,
                        presure,
                        iprop,
                        frct,
                        nmix,
                        xgcon,
                        xgvis,
                        xgcp,
                        xwght,
                        theta,
                        ufactor,
                        hcin,
                        hin,
                        hout,
                        shgc,
                        nperr,
                        ErrorMessage,
                        ibc,
                        hg,
                        hr,
                        hs,
                        Ra,
                        Nu,
                    )

                if not GoAhead(nperr[0]):
                    return

                dtmax = 0.0
                for i in range(1, 2 * nlayer + 1):
                    dtmax = max(dtmax, abs(state.dataTARCOGMain.told[i - 1] - theta[i - 1]))

                if dtmax < 0.0001:
                    state.dataTARCOGMain.converged = True
                counter += 1

                if counter > 100:
                    state.dataTARCOGMain.converged = True
                    nperr[0] = 41
                    ErrorMessage[0] = "Deflection calculations failed to converge"

    FinishDebugOutputFiles(files, nperr[0])
