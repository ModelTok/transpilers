# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object container (source: EnergyPlus/Data/EnergyPlusData.hh)
# - Files: file handle struct (source: TARCOGOutput.hh)
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

from math import abs as math_abs, fabs


@value
struct Pointer[T: Movable]:
    var _data: T
    
    fn __init__(inout self, data: T):
        self._data = data
    
    fn get(self) -> T:
        return self._data
    
    fn set(inout self, data: T):
        self._data = data


struct TARCOGMainData:
    var sconTemp: DynamicVector[Float64]
    var thickTemp: DynamicVector[Float64]
    var converged: Bool
    var told: DynamicVector[Float64]
    var CurGap: DynamicVector[Float64]
    var GapDefMean: DynamicVector[Float64]

    fn __init__(inout self):
        self.sconTemp = DynamicVector[Float64]()
        self.thickTemp = DynamicVector[Float64]()
        self.converged = False
        self.told = DynamicVector[Float64]()
        self.CurGap = DynamicVector[Float64]()
        self.GapDefMean = DynamicVector[Float64]()

    fn init_constant_state(inout self, state: EnergyPlusData):
        pass

    fn init_state(inout self, state: EnergyPlusData):
        pass

    fn clear_state(inout self):
        self.sconTemp = DynamicVector[Float64]()
        self.thickTemp = DynamicVector[Float64]()
        self.converged = False
        self.told = DynamicVector[Float64]()
        self.CurGap = DynamicVector[Float64]()
        self.GapDefMean = DynamicVector[Float64]()


struct EnergyPlusData:
    var dataTARCOGMain: TARCOGMainData


struct Files:
    pass


fn TARCOG90(
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
    CalcDeflection: Int,
    Pa: Float64,
    Pini: Float64,
    Tini: Float64,
    gap: DynamicVector[Float64],
    GapDefMax: DynamicVector[Float64],
    thick: DynamicVector[Float64],
    scon: DynamicVector[Float64],
    YoungsMod: DynamicVector[Float64],
    PoissonsRat: DynamicVector[Float64],
    tir: DynamicVector[Float64],
    emis: DynamicVector[Float64],
    totsol: Float64,
    tilt: Float64,
    asol: DynamicVector[Float64],
    height: Float64,
    heightt: Float64,
    width: Float64,
    presure: DynamicVector[Float64],
    iprop: DynamicVector[DynamicVector[Int32]],
    frct: DynamicVector[DynamicVector[Float64]],
    xgcon: DynamicVector[DynamicVector[Float64]],
    xgvis: DynamicVector[DynamicVector[Float64]],
    xgcp: DynamicVector[DynamicVector[Float64]],
    xwght: DynamicVector[Float64],
    gama: DynamicVector[Float64],
    nmix: DynamicVector[Int32],
    SupportPillar: DynamicVector[Int32],
    PillarSpacing: DynamicVector[Float64],
    PillarRadius: DynamicVector[Float64],
    theta: DynamicVector[Float64],
    LayerDef: DynamicVector[Float64],
    q: DynamicVector[Float64],
    qv: DynamicVector[Float64],
    ufactor: Float64,
    sc: Float64,
    hflux: Float64,
    hcin: Float64,
    hcout: Float64,
    hrin: Float64,
    hrout: Float64,
    hin: Float64,
    hout: Float64,
    hcgas: DynamicVector[Float64],
    hrgas: DynamicVector[Float64],
    shgc: Float64,
    nperr: Int,
    ErrorMessage: String,
    shgct: Float64,
    tamb: Float64,
    troom: Float64,
    ibc: DynamicVector[Int32],
    Atop: DynamicVector[Float64],
    Abot: DynamicVector[Float64],
    Al: DynamicVector[Float64],
    Ar: DynamicVector[Float64],
    Ah: DynamicVector[Float64],
    SlatThick: DynamicVector[Float64],
    SlatWidth: DynamicVector[Float64],
    SlatAngle: DynamicVector[Float64],
    SlatCond: DynamicVector[Float64],
    SlatSpacing: DynamicVector[Float64],
    SlatCurve: DynamicVector[Float64],
    vvent: DynamicVector[Float64],
    tvent: DynamicVector[Float64],
    LayerType: DynamicVector[Int32],
    nslice: DynamicVector[Int32],
    LaminateA: DynamicVector[Float64],
    LaminateB: DynamicVector[Float64],
    sumsol: DynamicVector[Float64],
    hg: DynamicVector[Float64],
    hr: DynamicVector[Float64],
    hs: DynamicVector[Float64],
    he: Float64,
    hi: Float64,
    Ra: DynamicVector[Float64],
    Nu: DynamicVector[Float64],
    standard: Int,
    ThermalMod: Int,
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
    Keff: DynamicVector[Float64],
    ShadeGapKeffConv: DynamicVector[Float64],
    SDScalar: Float64,
    SHGCCalc: Int,
    NumOfIterations: Int,
    edgeGlCorrFac: Float64,
) -> None:
    var eskyTemp: Float64 = 0.0
    var trminTemp: Float64 = 0.0
    var hinTemp: Float64 = 0.0
    var houtTemp: Float64 = 0.0
    var dtmax: Float64 = 0.0
    var i: Int = 0
    var counter: Int = 0
    var ErrorMessageLocal: String = "Normal Termination"

    for i in range(1, nlayer):
        state.dataTARCOGMain.CurGap[i - 1] = gap[i - 1]

    var files: Files = Files()

    if int(CalcDeflection) == 2:
        for i in range(1, nlayer):
            state.dataTARCOGMain.CurGap[i - 1] = state.dataTARCOGMain.GapDefMean[i - 1]

    if int(CalcDeflection) == 1:
        eskyTemp = esky
        trminTemp = trmin
        hinTemp = hin
        houtTemp = hout
        for i in range(scon.size):
            state.dataTARCOGMain.sconTemp[i] = scon[i]
        for i in range(thick.size):
            state.dataTARCOGMain.thickTemp[i] = thick[i]

    if nperr == 0:
        if standard == 1:
            pass
        elif (standard == 3) or (standard == 4):
            pass

    if nperr == 0:
        if not (nperr == 0):
            return

        if int(CalcDeflection) == 1:
            state.dataTARCOGMain.converged = False
            while not state.dataTARCOGMain.converged:
                if not (nperr == 0):
                    return

                for i in range(1, 2 * nlayer + 1):
                    state.dataTARCOGMain.told[i - 1] = theta[i - 1]

                esky = eskyTemp
                trmin = trminTemp
                hin = hinTemp
                hout = houtTemp
                for i in range(scon.size):
                    scon[i] = state.dataTARCOGMain.sconTemp[i]
                for i in range(thick.size):
                    thick[i] = state.dataTARCOGMain.thickTemp[i]

                if standard == 1:
                    pass
                elif (standard == 3) or (standard == 4):
                    pass

                if not (nperr == 0):
                    return

                dtmax = 0.0
                for i in range(1, 2 * nlayer + 1):
                    dtmax = max(dtmax, fabs(state.dataTARCOGMain.told[i - 1] - theta[i - 1]))

                if dtmax < 0.0001:
                    state.dataTARCOGMain.converged = True
                counter += 1

                if counter > 100:
                    state.dataTARCOGMain.converged = True
                    nperr = 41
                    ErrorMessageLocal = "Deflection calculations failed to converge"
