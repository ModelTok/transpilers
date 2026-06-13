from ObjexxFCL.Array1D import Array1D, Array2A, Array2A_int
from ObjexxFCL.Array2D import Array2D  # placeholder
from EnergyPlus.EnergyPlus import EnergyPlusData
from EnergyPlus.TARCOGGassesParams import TARCOGGassesParams, Stdrd
from TARCOGParams import TARCOGParams, DeflectionCalculation, TARCOGLayerType, TARCOGThermalModel
from TARCOGArgs import ArgCheck
from TARCOGDeflection import PanesDeflection
from TARCOGOutput import Files, PrepDebugFilesAndVariables, FinishDebugOutputFiles
from ThermalEN673Calc import Calc_EN673
from ThermalISO15099Calc import Calc_ISO15099

# EP_SIZE_CHECK macro replacement (no-op for faithful translation)
def EP_SIZE_CHECK[T](arr: T, size: Int):

# Global constants (from TARCOGParams presumably)
alias maxlay: Int = 10   # placeholder, should match TARCOGParams::maxlay
alias maxlay1: Int = 9   # placeholder
alias maxlay2: Int = 20  # placeholder
alias maxlay3: Int = 30  # placeholder
alias maxgas: Int = 5    # placeholder
alias MaxGap: Int = 9    # placeholder
alias DeflectionErrorMargin: Float64 = 0.001  # placeholder
alias DeflectionMaxIterations: Int = 10       # placeholder

struct TARCOGMainData(BaseGlobalStruct):
    var sconTemp: Array1D[Float64] = Array1D[Float64](maxlay)
    var thickTemp: Array1D[Float64] = Array1D[Float64](maxlay)
    var converged: Bool = False
    var told: Array1D[Float64] = Array1D[Float64](maxlay2)
    var CurGap: Array1D[Float64] = Array1D[Float64](MaxGap)
    var GapDefMean: Array1D[Float64] = Array1D[Float64](MaxGap)
    def init_constant_state(inout state: EnergyPlusData):

    def init_state(inout state: EnergyPlusData):

    def clear_state(inout self):
        self.sconTemp = Array1D[Float64](maxlay)
        self.thickTemp = Array1D[Float64](maxlay)
        self.converged = False
        self.told = Array1D[Float64](maxlay2)
        self.CurGap = Array1D[Float64](MaxGap)
        self.GapDefMean = Array1D[Float64](MaxGap)

def TARCOG90(
    state: EnergyPlusData,
    nlayer: Int,
    iwd: Int,
    tout: Float64,
    tind: Float64,
    trmin: Float64,
    wso: Float64,
    wsi: Float64,
    dir: Float64,
    outir: Float64,
    isky: Int,
    tsky: Float64,
    esky: Float64,
    fclr: Float64,
    VacuumPressure: Float64,
    VacuumMaxGapThickness: Float64,
    CalcDeflection: DeflectionCalculation,
    Pa: Float64,
    Pini: Float64,
    Tini: Float64,
    gap: Array1D[Float64],
    GapDefMax: Array1D[Float64],
    thick: Array1D[Float64],
    scon: Array1D[Float64],
    YoungsMod: Array1D[Float64],
    PoissonsRat: Array1D[Float64],
    tir: Array1D[Float64],
    emis: Array1D[Float64],
    totsol: Float64,
    tilt: Float64,
    asol: Array1D[Float64],
    height: Float64,
    heightt: Float64,
    width: Float64,
    presure: Array1D[Float64],
    iprop: Array2A_int,
    frct: Array2A[Float64],
    xgcon: Array2A[Float64],
    xgvis: Array2A[Float64],
    xgcp: Array2A[Float64],
    xwght: Array1D[Float64],
    gama: Array1D[Float64],
    nmix: Array1D[Int],
    SupportPillar: Array1D[Int],
    PillarSpacing: Array1D[Float64],
    PillarRadius: Array1D[Float64],
    theta: Array1D[Float64],
    LayerDef: Array1D[Float64],
    q: Array1D[Float64],
    qv: Array1D[Float64],
    ufactor: Float64,
    sc: Float64,
    hflux: Float64,
    hcin: Float64,
    hcout: Float64,
    hrin: Float64,
    hrout: Float64,
    hin: Float64,
    hout: Float64,
    hcgas: Array1D[Float64],
    hrgas: Array1D[Float64],
    shgc: Float64,
    nperr: Int,
    ErrorMessage: String,
    shgct: Float64,
    tamb: Float64,
    troom: Float64,
    ibc: Array1D[Int],
    Atop: Array1D[Float64],
    Abot: Array1D[Float64],
    Al: Array1D[Float64],
    Ar: Array1D[Float64],
    Ah: Array1D[Float64],
    SlatThick: Array1D[Float64],
    SlatWidth: Array1D[Float64],
    SlatAngle: Array1D[Float64],
    SlatCond: Array1D[Float64],
    SlatSpacing: Array1D[Float64],
    SlatCurve: Array1D[Float64],
    vvent: Array1D[Float64],
    tvent: Array1D[Float64],
    LayerType: Array1D[TARCOGLayerType],
    nslice: Array1D[Int],
    LaminateA: Array1D[Float64],
    LaminateB: Array1D[Float64],
    sumsol: Array1D[Float64],
    hg: Array1D[Float64],
    hr: Array1D[Float64],
    hs: Array1D[Float64],
    he: Float64,
    hi: Float64,
    Ra: Array1D[Float64],
    Nu: Array1D[Float64],
    standard: Stdrd,
    ThermalMod: TARCOGThermalModel,
    Debug_mode: Int,
    Debug_dir: String,
    Debug_file: String,
    win_ID: Int,
    igu_ID: Int,
    ShadeEmisRatioOut: Float64,
    ShadeEmisRatioIn: Float64,
    ShadeHcRatioOut: Float64,
    ShadeHcRatioIn: Float64,
    HcUnshadedOut: Float64,
    HcUnshadedIn: Float64,
    Keff: Array1D[Float64],
    ShadeGapKeffConv: Array1D[Float64],
    SDScalar: Float64,
    SHGCCalc: Int,
    NumOfIterations: Int,
    edgeGlCorrFac: Float64
):
    EP_SIZE_CHECK(gap, maxlay)
    EP_SIZE_CHECK(GapDefMax, MaxGap)
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
    EP_SIZE_CHECK(theta, maxlay2)
    EP_SIZE_CHECK(LayerDef, maxlay)
    EP_SIZE_CHECK(q, maxlay3)
    EP_SIZE_CHECK(qv, maxlay1)
    EP_SIZE_CHECK(hcgas, maxlay1)
    EP_SIZE_CHECK(hrgas, maxlay1)
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
    EP_SIZE_CHECK(hg, maxlay)
    EP_SIZE_CHECK(hr, maxlay)
    EP_SIZE_CHECK(hs, maxlay)
    EP_SIZE_CHECK(Ra, maxlay)
    EP_SIZE_CHECK(Nu, maxlay)
    EP_SIZE_CHECK(Keff, maxlay)
    EP_SIZE_CHECK(ShadeGapKeffConv, MaxGap)
    var eskyTemp: Float64
    var trminTemp: Float64
    var hinTemp: Float64
    var houtTemp: Float64
    var dtmax: Float64
    var i: Int
    var counter: Int
    he = 0.0
    hi = 0.0
    hcin = 0.0
    hrin = 0.0
    hcout = 0.0
    hrout = 0.0
    LayerDef = 0.0
    dtmax = 0.0
    i = 0
    counter = 0
    eskyTemp = 0.0
    trminTemp = 0.0
    hinTemp = 0.0
    houtTemp = 0.0
    ErrorMessage = "Normal Termination"
    for i in range(0, nlayer - 1):
        state.dataTARCOGMain.CurGap[i] = gap[i]
    var files: Files
    PrepDebugFilesAndVariables(state, files, Debug_dir, Debug_file, Debug_mode, win_ID, igu_ID)
    nperr = ArgCheck(
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
        ErrorMessage
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
            ErrorMessage
        )
        for i in range(0, nlayer - 1):
            state.dataTARCOGMain.CurGap[i] = state.dataTARCOGMain.GapDefMean[i]
    if CalcDeflection == DeflectionCalculation.TEMPERATURE:
        eskyTemp = esky
        trminTemp = trmin
        hinTemp = hin
        houtTemp = hout
        state.dataTARCOGMain.sconTemp = scon
        state.dataTARCOGMain.thickTemp = thick
    if GoAhead(nperr):
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
                edgeGlCorrFac
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
                Nu
            )
        else:

    if GoAhead(nperr):
        if not GoAhead(nperr):
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
                    ErrorMessage
                )
                if not GoAhead(nperr):
                    return
                for i in range(0, 2 * nlayer):
                    state.dataTARCOGMain.told[i] = theta[i]
                esky = eskyTemp
                trmin = trminTemp
                hin = hinTemp
                hout = houtTemp
                scon = state.dataTARCOGMain.sconTemp
                thick = state.dataTARCOGMain.thickTemp
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
                        edgeGlCorrFac
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
                        Nu
                    )
                else:

                if not GoAhead(nperr):
                    return
                dtmax = 0.0
                for i in range(0, 2 * nlayer):
                    dtmax = abs(state.dataTARCOGMain.told[i] - theta[i])
                if dtmax < DeflectionErrorMargin:
                    state.dataTARCOGMain.converged = True
                counter += 1
                if counter > DeflectionMaxIterations:
                    state.dataTARCOGMain.converged = True
                    nperr = 41
                    ErrorMessage = "Deflection calculations failed to converge"
    FinishDebugOutputFiles(files, nperr)

# Helper function (imported from TARCOGArgs? assumed)
def GoAhead(nperr: Int) -> Bool:
    return nperr == 0