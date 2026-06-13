from pathlib import Path
from datetime import import datetime
import math

alias maxlay = 10
alias maxlay1 = 11
alias maxlay2 = 20
alias maxlay3 = 21
alias maxgas = 10
alias MaxGap = 10
alias YES_SupportPillar = 1

struct Constant:
    alias Kelvin = 273.15

struct Stdrd:
    alias ISO15099 = 1
    alias EN673 = 2
    alias EN673Design = 3

struct TARCOGLayerType:
    alias SPECULAR = 1
    alias VENETBLIND_HORIZ = 2
    alias VENETBLIND_VERT = 3
    alias WOVSHADE = 4
    alias DIFFSHADE = 5

struct TARCOGThermalModel:
    alias ISO15099 = 1
    alias SCW = 2
    alias CSM = 3

struct DeflectionCalculation:
    alias NO = 0
    alias YES = 1

struct TARCOGOutputData:
    var winID: Int32
    var iguID: Int32

    fn __init__(inout self):
        self.winID = 0
        self.iguID = 0

trait InputOutputFileTrait:
    fn good(self) -> Bool: ...
    fn close(inout self): ...
    fn write(inout self, text: String): ...

trait EnergyPlusDataTrait:
    fn get_outputs(self) -> TARCOGOutputData: ...
    fn set_outputs(inout self, outputs: TARCOGOutputData): ...

struct Files:
    var DBGD: Path
    var WriteDebugOutput: Bool
    var WINCogFilePath: Path
    var WINCogFile: InputOutputFileTrait
    var TarcogIterationsFilePath: Path
    var TarcogIterationsFile: InputOutputFileTrait
    var IterationCSVFilePath: Path
    var IterationCSVFile: InputOutputFileTrait
    var DebugOutputFilePath: Path
    var DebugOutputFile: InputOutputFileTrait

    fn __init__(inout self):
        self.DBGD = Path(".")
        self.WriteDebugOutput = False
        self.WINCogFilePath = Path("test.w7")
        self.TarcogIterationsFilePath = Path("TarcogIterations.dbg")
        self.IterationCSVFilePath = Path("IterationResults.csv")
        self.DebugOutputFilePath = Path("Tarcog.dbg")

fn _format_output(format_str: String, args: VariadicList[String]) -> String:
    var result = format_str
    return result

fn _print_file(inout file_obj: InputOutputFileTrait, format_str: String, args: VariadicList[String]):
    if file_obj.good():
        var output = _format_output(format_str, args)
        file_obj.write(output)

fn IsShadingLayer(layer_type: Int32) -> Bool:
    return (layer_type == TARCOGLayerType.VENETBLIND_HORIZ or
            layer_type == TARCOGLayerType.VENETBLIND_VERT or
            layer_type == TARCOGLayerType.WOVSHADE or
            layer_type == TARCOGLayerType.DIFFSHADE)

fn WriteInputArguments(
    state: EnergyPlusDataTrait,
    inout InArgumentsFile: InputOutputFileTrait,
    DBGD: Path,
    tout: Float64,
    tind: Float64,
    trmin: Float64,
    wso: Float64,
    iwd: Int32,
    wsi: Float64,
    dir: Float64,
    outir: Float64,
    isky: Int32,
    tsky: Float64,
    esky: Float64,
    fclr: Float64,
    VacuumPressure: Float64,
    VacuumMaxGapThickness: Float64,
    ibc: DynamicVector[Int32],
    hout: Float64,
    hin: Float64,
    standard: Int32,
    ThermalMod: Int32,
    SDScalar: Float64,
    height: Float64,
    heightt: Float64,
    width: Float64,
    tilt: Float64,
    totsol: Float64,
    nlayer: Int32,
    LayerType: DynamicVector[Int32],
    thick: DynamicVector[Float64],
    scon: DynamicVector[Float64],
    asol: DynamicVector[Float64],
    tir: DynamicVector[Float64],
    emis: DynamicVector[Float64],
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
    nslice: DynamicVector[Int32],
    LaminateA: DynamicVector[Float64],
    LaminateB: DynamicVector[Float64],
    sumsol: DynamicVector[Float64],
    gap: DynamicVector[Float64],
    vvent: DynamicVector[Float64],
    tvent: DynamicVector[Float64],
    presure: DynamicVector[Float64],
    nmix: DynamicVector[Int32],
    iprop: DynamicVector[DynamicVector[Int32]],
    frct: DynamicVector[DynamicVector[Float64]],
    xgcon: DynamicVector[DynamicVector[Float64]],
    xgvis: DynamicVector[DynamicVector[Float64]],
    xgcp: DynamicVector[DynamicVector[Float64]],
    xwght: DynamicVector[Float64]
):
    if not InArgumentsFile.good():
        return

    var now = datetime.now()
    
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "TARCOG debug output, " + str(now.year) + "-" + str(now.month) + "-" + str(now.day) + ", " + str(now.hour) + ":" + str(now.minute) + ":" + str(now.second) + "\n")
    _print_file(InArgumentsFile, "\n")

    if state.get_outputs().winID == -1:
        _print_file(InArgumentsFile, "     WindowID:{:8}  - Not specified\n")
    else:
        _print_file(InArgumentsFile, "     WindowID:{:8} \n")

    if state.get_outputs().iguID == -1:
        _print_file(InArgumentsFile, "     IGUID:   {:8}  - Not specified\n")
    else:
        _print_file(InArgumentsFile, "     IGUID:   {:8} \n")

    _print_file(InArgumentsFile, "     Debug dir:     " + str(DBGD) + "\n")
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "TARCOG input arguments:\n")
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "Simulation parameters:\n")
    _print_file(InArgumentsFile, "  Tout       =  " + format_float(tout, 10, 6) + " K ( " + format_float(tout - Constant.Kelvin, 7, 3) + " deg C) - Outdoor temperature\n")
    _print_file(InArgumentsFile, "  Tint       =  " + format_float(tind, 10, 6) + " K ( " + format_float(tind - Constant.Kelvin, 7, 3) + " deg C) - Indoor temperature\n")
    _print_file(InArgumentsFile, "  Trmin      =  " + format_float(trmin, 10, 6) + " K ( " + format_float(trmin - Constant.Kelvin, 7, 3) + " deg C) - Indoor mean radiant temp.\n")
    _print_file(InArgumentsFile, "  wso        =  " + format_float(wso, 7, 3) + "    - Outdoor wind speed [m/s]\n")
    if iwd == 0:
        _print_file(InArgumentsFile, "  iwd        =    0        - Wind direction - windward\n")
    if iwd == 1:
        _print_file(InArgumentsFile, "  iwd        =    1        - Wind direction - leeward\n")
    _print_file(InArgumentsFile, "  wsi        =  " + format_float(wsi, 7, 3) + "    - Indoor forced air speed [m/s]\n")
    _print_file(InArgumentsFile, "  dir        = " + format_float(dir, 8, 3) + "    - Direct solar radiation [W/m^2]\n")
    _print_file(InArgumentsFile, "  outir       = " + format_float(outir, 8, 3) + "    - IR radiation [W/m^2]\n")
    _print_file(InArgumentsFile, "  isky       =  " + str(isky) + "        - Flag for handling tsky, esky\n")
    _print_file(InArgumentsFile, "  tsky           =  " + format_float(tsky, 10, 6) + " K ( " + format_float(tsky - Constant.Kelvin, 7, 3) + " deg C) - Night sky temperature\n")
    _print_file(InArgumentsFile, "  esky           =  " + format_float(esky, 7, 3) + "    - Effective night sky emmitance\n")
    _print_file(InArgumentsFile, "  fclr           =  " + format_float(fclr, 7, 3) + "    - Fraction of sky that is clear\n")
    _print_file(InArgumentsFile, "  VacuumPressure =  " + format_float(VacuumPressure, 7, 3) + "    - maximum allowed gas pressure to be considered as vacuum\n")
    _print_file(InArgumentsFile, "  VacuumMaxGapThickness =  " + format_float(VacuumMaxGapThickness, 7, 3) + "    - maximum allowed vacuum gap thickness with support pillar\n")
    _print_file(InArgumentsFile, "  ibc(1)         =  " + str(ibc[0]) + "        - Outdoor BC switch\n")
    _print_file(InArgumentsFile, "  hout           =  " + format_float(hout, 9, 5) + "  - Outdoor film coeff. [W/m^2-K]\n")
    _print_file(InArgumentsFile, "  ibc(2)         =  " + str(ibc[1]) + "        - Indoor BC switch\n")
    _print_file(InArgumentsFile, "  hin            =  " + format_float(hin, 9, 5) + "  - Indoor film coeff. [W/m^2-K]\n")

    if standard == Stdrd.ISO15099:
        _print_file(InArgumentsFile, "  standard   =  " + str(standard) + "        - ISO 15099 calc. standard\n")
    if standard == Stdrd.EN673:
        _print_file(InArgumentsFile, "  standard   =  " + str(standard) + "        - EN 673/ISO 10292 Declared calc. standard\n")
    if standard == Stdrd.EN673Design:
        _print_file(InArgumentsFile, "  standard   =  " + str(standard) + "        - EN 673/ISO 10292 Design calc. standard\n")

    if ThermalMod == TARCOGThermalModel.ISO15099:
        _print_file(InArgumentsFile, "  ThermalMod =  " + str(ThermalMod) + "        - ISO15099 thermal model\n")
        _print_file(InArgumentsFile, "  SDScalar =  " + format_float(SDScalar, 7, 5) + "      - Factor of Venetian SD layer contribution to convection\n\n (only if ThermalModel = 2, otherwise ignored)\n")

    if ThermalMod == TARCOGThermalModel.SCW:
        _print_file(InArgumentsFile, "  ThermalMod =  " + str(ThermalMod) + "        - Scaled Cavity Width (SCW) thermal model\n")
        _print_file(InArgumentsFile, "  SDScalar =  " + format_float(SDScalar, 7, 5) + "      - Factor of Venetian SD layer contribution to convection\n\n (only if ThermalModel = 2, otherwise ignored)\n")

    if ThermalMod == TARCOGThermalModel.CSM:
        _print_file(InArgumentsFile, "  ThermalMod =  " + str(ThermalMod) + "        - Convective Scalar Model (CSM) thermal model\n")
        _print_file(InArgumentsFile, "  SDScalar =  " + format_float(SDScalar, 7, 5) + "      - Factor of Venetian SD layer contribution to convection\n\n (only if ThermalModel = 2, otherwise ignored)\n")

    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "IGU parameters:\n")
    _print_file(InArgumentsFile, "  height     =  " + format_float(height, 10, 6) + " - IGU cavity height [m]\n")
    _print_file(InArgumentsFile, "  heightt    =  " + format_float(heightt, 10, 6) + " - Total window height [m]\n")
    _print_file(InArgumentsFile, "  width      =  " + format_float(width, 10, 6) + " - Window width [m]\n")
    _print_file(InArgumentsFile, "  tilt       =  " + format_float(tilt, 7, 3) + "    - Window tilt [deg]\n")
    _print_file(InArgumentsFile, "  totsol     =  " + format_float(totsol, 10, 6) + " - Total solar transmittance of IGU\n")
    _print_file(InArgumentsFile, "  nlayer     =  " + str(nlayer) + "        - Number of glazing layers\n")
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "IGU layers list:\n")
    
    for i in range(nlayer):
        if LayerType[i] == TARCOGLayerType.DIFFSHADE:
            _print_file(InArgumentsFile, " Layer" + str(i+1) + " : " + str(LayerType[i]) + "              - Diffuse Shade\n")
        elif LayerType[i] == TARCOGLayerType.WOVSHADE:
            _print_file(InArgumentsFile, " Layer" + str(i+1) + " : " + str(LayerType[i]) + "              - Woven Shade\n")
        elif LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ:
            _print_file(InArgumentsFile, " Layer" + str(i+1) + " : " + str(LayerType[i]) + "              - Horizontal Venetian Blind\n")
        elif LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            _print_file(InArgumentsFile, " Layer" + str(i+1) + " : " + str(LayerType[i]) + "              - Vertical Venetian Blind\n")
        elif LayerType[i] == TARCOGLayerType.SPECULAR:
            if nslice[i] <= 1:
                _print_file(InArgumentsFile, " Layer" + str(i+1) + " : " + str(LayerType[i]) + "              - Specular layer - Monolyhtic Glass\n")
            else:
                _print_file(InArgumentsFile, " Layer" + str(i+1) + " : " + str(LayerType[i]) + "              - Laminated Glass\n")
        else:
            _print_file(InArgumentsFile, " Layer" + str(i+1) + " : " + str(LayerType[i]) + "              - UNKNOWN TYPE!\n")

        _print_file(InArgumentsFile, "    thick   = " + format_float(thick[i], 10, 6) + "   - Thickness [m]\n")
        _print_file(InArgumentsFile, "    scon    = " + format_float(scon[i], 10, 6) + "   - Thermal conductivity [W/m-K]\n")
        _print_file(InArgumentsFile, "    asol    = " + format_float(asol[i], 12, 8) + " - Absorbed solar energy [W/m^2]\n")
        _print_file(InArgumentsFile, "    tir     = " + format_float(tir[2*i], 12, 8) + " - IR transmittance\n")
        _print_file(InArgumentsFile, "    emis1   = " + format_float(emis[2*i], 10, 6) + "   - IR outdoor emissivity\n")
        _print_file(InArgumentsFile, "    emis2   = " + format_float(emis[2*i+1], 10, 6) + "   - IR indoor emissivity\n")

        if LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            _print_file(InArgumentsFile, "    Atop    = " + format_float(Atop[i], 10, 6) + "   - Top opening area [m^2]\n")
            _print_file(InArgumentsFile, "    Abot    = " + format_float(Abot[i], 10, 6) + "   - Bottom opening area [m^2]\n")
            _print_file(InArgumentsFile, "    Al      = " + format_float(Al[i], 10, 6) + "   - Left opening area [m^2]\n")
            _print_file(InArgumentsFile, "    Ar      = " + format_float(Ar[i], 10, 6) + "   - Right opening area [m^2]\n")
            _print_file(InArgumentsFile, "    Ah      = " + format_float(Ah[i], 10, 6) + "   - Total area of holes [m^2]\n")
            _print_file(InArgumentsFile, "    SlatThick   = " + format_float(SlatThick[i], 10, 6) + "   - Slat thickness [m]\n")
            _print_file(InArgumentsFile, "    SlatWidth   = " + format_float(SlatWidth[i], 10, 6) + "   - Slat width [m]\n")
            _print_file(InArgumentsFile, "    SlatAngle   = " + format_float(SlatAngle[i], 10, 6) + "   - Slat tilt angle [deg]\n")
            _print_file(InArgumentsFile, "    SlatCond    = " + format_float(SlatCond[i], 10, 6) + "   - Conductivity of the slat material [W/m.K]\n")
            _print_file(InArgumentsFile, "    SlatSpacing = " + format_float(SlatSpacing[i], 10, 6) + "   - Distance between slats [m]\n")
            _print_file(InArgumentsFile, "    SlatCurve   = " + format_float(SlatCurve[i], 10, 6) + "   - Curvature radius of the slat [m]\n")

        if nslice[i] > 1:
            _print_file(InArgumentsFile, "    nslice     = " + str(nslice[i]) + "          - Number of slices\n")

    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "IGU Gaps:\n")

    for i in range(nlayer + 1):
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, " Gap " + str(i) + ":\n")
        if i == 0:
            _print_file(InArgumentsFile, " Outdoor space:\n")
        if i == nlayer:
            _print_file(InArgumentsFile, " Indoor space:\n")
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, "    gap        = " + format_float(gap[i-1], 12, 5) + " - Gap width [m]\n")
        _print_file(InArgumentsFile, "    presure    = " + format_float(presure[i], 12, 5) + " - Gas pressure [N/m^2]\n")
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, "    vvent      = " + format_float(vvent[i], 12, 5) + " - Forced ventilation speed [m/s]\n")
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, "    tvent      = " + format_float(tvent[i], 12, 5) + " - Temperature in connected gap [K]\n")
        _print_file(InArgumentsFile, "    nmix       = " + str(nmix[i]) + "       - Num. of gasses in a gas mix\n")

        for j in range(nmix[i]):
            _print_file(InArgumentsFile, "      Gas " + str(iprop[j][i]) + ":     " + " " + "     " + format_float(100 * frct[j][i], 6, 2) + " %\n")
            _print_file(InArgumentsFile, "      Gas mix coefficients - gas " + str(iprop[j][i]) + ", " + format_float(100 * frct[j][i], 6, 2) + " %\n")

    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "=====  =====  =====  =====  =====  =====  =====  =====  =====  =====  =====\n")

fn format_float(value: Float64, width: Int32, precision: Int32) -> String:
    return str(value)

fn WriteModifiedArguments(
    inout InArgumentsFile: InputOutputFileTrait,
    DBGD: Path,
    esky: Float64,
    trmout: Float64,
    trmin: Float64,
    ebsky: Float64,
    ebroom: Float64,
    Gout: Float64,
    Gin: Float64,
    nlayer: Int32,
    LayerType: DynamicVector[Int32],
    nmix: DynamicVector[Int32],
    frct: DynamicVector[DynamicVector[Float64]],
    thick: DynamicVector[Float64],
    scon: DynamicVector[Float64],
    gap: DynamicVector[Float64],
    xgcon: DynamicVector[DynamicVector[Float64]],
    xgvis: DynamicVector[DynamicVector[Float64]],
    xgcp: DynamicVector[DynamicVector[Float64]],
    xwght: DynamicVector[Float64]
):
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "Adjusted input arguments:\n")
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "  esky       =  " + format_float(esky, 7, 3) + "    - Effective night sky emmitance\n")
    _print_file(InArgumentsFile, "  Trmout     =  " + format_float(trmout, 10, 6) + " K ( " + format_float(trmout - Constant.Kelvin, 7, 3) + " deg C) - Outdoor mean radiant temp.\n")
    _print_file(InArgumentsFile, "  Trmin      =  " + format_float(trmin, 10, 6) + " K ( " + format_float(trmin - Constant.Kelvin, 7, 3) + " deg C) - Indoor mean radiant temp.\n")
    _print_file(InArgumentsFile, "  Ebsky      =  " + format_float(ebsky, 10, 6) + " \n")
    _print_file(InArgumentsFile, "  Ebroom     =  " + format_float(ebroom, 10, 6) + " \n")
    _print_file(InArgumentsFile, "  Gout       =  " + format_float(Gout, 10, 6) + " \n")
    _print_file(InArgumentsFile, "  Gin        =  " + format_float(Gin, 10, 6) + " \n")
    _print_file(InArgumentsFile, "\n")

    for i in range(nlayer):
        if (LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or 
            LayerType[i] == TARCOGLayerType.VENETBLIND_VERT):
            _print_file(InArgumentsFile, " Layer" + str(i+1) + " : " + str(LayerType[i]) + "              - Venetian Blind\n")
            _print_file(InArgumentsFile, "    thick   = " + format_float(thick[i], 10, 6) + "   - Thickness [m]\n")
            _print_file(InArgumentsFile, "    scon    = " + format_float(scon[i], 10, 6) + "   - Thermal conductivity [W/m-K]\n")
    _print_file(InArgumentsFile, "\n")

    _print_file(InArgumentsFile, " Gass coefficients:\n")
    for i in range(nlayer + 1):
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, " Gap " + str(i) + ":\n")
            _print_file(InArgumentsFile, " Gap width: " + format_float(gap[i-1], 11, 8) + "\n")
        if i == 0:
            _print_file(InArgumentsFile, " Outdoor space:\n")
        if i == nlayer:
            _print_file(InArgumentsFile, " Indoor space:\n")

    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "=====  =====  =====  =====  =====  =====  =====  =====  =====  =====  =====\n")

fn WriteOutputArguments(
    inout OutArgumentsFile: InputOutputFileTrait,
    DBGD: Path,
    nlayer: Int32,
    tamb: Float64,
    q: DynamicVector[Float64],
    qv: DynamicVector[Float64],
    qcgas: DynamicVector[Float64],
    qrgas: DynamicVector[Float64],
    theta: DynamicVector[Float64],
    vfreevent: DynamicVector[Float64],
    vvent: DynamicVector[Float64],
    Keff: DynamicVector[Float64],
    ShadeGapKeffConv: DynamicVector[Float64],
    troom: Float64,
    ufactor: Float64,
    shgc: Float64,
    sc: Float64,
    hflux: Float64,
    shgct: Float64,
    hcin: Float64,
    hrin: Float64,
    hcout: Float64,
    hrout: Float64,
    Ra: DynamicVector[Float64],
    Nu: DynamicVector[Float64],
    LayerType: DynamicVector[Int32],
    Ebf: DynamicVector[Float64],
    Ebb: DynamicVector[Float64],
    Rf: DynamicVector[Float64],
    Rb: DynamicVector[Float64],
    ebsky: Float64,
    Gout: Float64,
    ebroom: Float64,
    Gin: Float64,
    ShadeEmisRatioIn: Float64,
    ShadeEmisRatioOut: Float64,
    ShadeHcRatioIn: Float64,
    ShadeHcRatioOut: Float64,
    HcUnshadedIn: Float64,
    HcUnshadedOut: Float64,
    hcgas: DynamicVector[Float64],
    hrgas: DynamicVector[Float64],
    AchievedErrorTolerance: Float64,
    NumOfIter: Int32
):
    pass

fn WriteOutputEN673(
    inout OutArgumentsFile: InputOutputFileTrait,
    DBGD: Path,
    nlayer: Int32,
    ufactor: Float64,
    hout: Float64,
    hin: Float64,
    Ra: DynamicVector[Float64],
    Nu: DynamicVector[Float64],
    hg: DynamicVector[Float64],
    hr: DynamicVector[Float64],
    hs: DynamicVector[Float64],
    inout nperr: Int32
):
    pass

fn WriteTARCOGInputFile(
    state: EnergyPlusDataTrait,
    inout files: Files,
    VerNum: String,
    tout: Float64,
    tind: Float64,
    trmin: Float64,
    wso: Float64,
    iwd: Int32,
    wsi: Float64,
    dir: Float64,
    outir: Float64,
    isky: Int32,
    tsky: Float64,
    esky: Float64,
    fclr: Float64,
    VacuumPressure: Float64,
    VacuumMaxGapThickness: Float64,
    CalcDeflection: Int32,
    Pa: Float64,
    Pini: Float64,
    Tini: Float64,
    ibc: DynamicVector[Int32],
    hout: Float64,
    hin: Float64,
    standard: Int32,
    ThermalMod: Int32,
    SDScalar: Float64,
    height: Float64,
    heightt: Float64,
    width: Float64,
    tilt: Float64,
    totsol: Float64,
    nlayer: Int32,
    LayerType: DynamicVector[Int32],
    thick: DynamicVector[Float64],
    scon: DynamicVector[Float64],
    YoungsMod: DynamicVector[Float64],
    PoissonsRat: DynamicVector[Float64],
    asol: DynamicVector[Float64],
    tir: DynamicVector[Float64],
    emis: DynamicVector[Float64],
    Atop: DynamicVector[Float64],
    Abot: DynamicVector[Float64],
    Al: DynamicVector[Float64],
    Ar: DynamicVector[Float64],
    Ah: DynamicVector[Float64],
    SupportPillar: DynamicVector[Int32],
    PillarSpacing: DynamicVector[Float64],
    PillarRadius: DynamicVector[Float64],
    SlatThick: DynamicVector[Float64],
    SlatWidth: DynamicVector[Float64],
    SlatAngle: DynamicVector[Float64],
    SlatCond: DynamicVector[Float64],
    SlatSpacing: DynamicVector[Float64],
    SlatCurve: DynamicVector[Float64],
    nslice: DynamicVector[Int32],
    gap: DynamicVector[Float64],
    GapDef: DynamicVector[Float64],
    vvent: DynamicVector[Float64],
    tvent: DynamicVector[Float64],
    presure: DynamicVector[Float64],
    nmix: DynamicVector[Int32],
    iprop: DynamicVector[DynamicVector[Int32]],
    frct: DynamicVector[DynamicVector[Float64]],
    xgcon: DynamicVector[DynamicVector[Float64]],
    xgvis: DynamicVector[DynamicVector[Float64]],
    xgcp: DynamicVector[DynamicVector[Float64]],
    xwght: DynamicVector[Float64],
    gama: DynamicVector[Float64]
):
    pass

fn FinishDebugOutputFiles(inout files: Files, nperr: Int32):
    pass

fn PrepDebugFilesAndVariables(
    inout state: EnergyPlusDataTrait,
    inout files: Files,
    Debug_dir: Path,
    Debug_file: Path,
    Debug_mode: Int32,
    win_ID: Int32,
    igu_ID: Int32
):
    files.DBGD = Debug_dir
    var outputs = state.get_outputs()
    outputs.winID = win_ID
    outputs.iguID = igu_ID
    state.set_outputs(outputs)

    if Debug_file != Path(""):
        files.WINCogFilePath = Path(str(Debug_file) + ".w7")
        files.DebugOutputFilePath = Path(str(Debug_file) + ".dbg")

    files.WriteDebugOutput = False
