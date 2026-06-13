from dataclasses import dataclass, field
from pathlib import Path
from datetime import datetime
from typing import Protocol, List, Any
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with dataTARCOGOutputs
# - InputOutputFile: file wrapper with good(), close(), write() methods
# - TARCOGGassesParams.Stdrd: enum {ISO15099, EN673, EN673Design}
# - TARCOGParams.TARCOGLayerType: enum {SPECULAR, VENETBLIND_HORIZ, VENETBLIND_VERT, WOVSHADE, DIFFSHADE}
# - TARCOGThermalModel: enum {ISO15099, SCW, CSM}
# - DeflectionCalculation: enum (values used as integers)
# - Constant.Kelvin: float = 273.15
# - maxlay, maxlay1, maxlay2, maxlay3, maxgas, MaxGap: int constants
# - YES_SupportPillar: int constant

class InputOutputFile(Protocol):
    def good(self) -> bool: ...
    def close(self) -> None: ...
    def write(self, text: str) -> None: ...

class TARCOGOutputData:
    def __init__(self):
        self.winID: int = 0
        self.iguID: int = 0

class EnergyPlusData(Protocol):
    dataTARCOGOutputs: TARCOGOutputData

class Stdrd:
    ISO15099 = 1
    EN673 = 2
    EN673Design = 3

class TARCOGLayerType:
    SPECULAR = 1
    VENETBLIND_HORIZ = 2
    VENETBLIND_VERT = 3
    WOVSHADE = 4
    DIFFSHADE = 5

class TARCOGThermalModel:
    ISO15099 = 1
    SCW = 2
    CSM = 3

class DeflectionCalculation:
    NO = 0
    YES = 1

class Constant:
    Kelvin = 273.15

maxlay = 10
maxlay1 = 11
maxlay2 = 20
maxlay3 = 21
maxgas = 10
MaxGap = 10
YES_SupportPillar = 1

@dataclass
class Files:
    DBGD: Path = Path(".")
    WriteDebugOutput: bool = False
    WINCogFilePath: Path = Path("test.w7")
    WINCogFile: InputOutputFile = field(default_factory=lambda: None)
    TarcogIterationsFilePath: Path = Path("TarcogIterations.dbg")
    TarcogIterationsFile: InputOutputFile = field(default_factory=lambda: None)
    IterationCSVFilePath: Path = Path("IterationResults.csv")
    IterationCSVFile: InputOutputFile = field(default_factory=lambda: None)
    DebugOutputFilePath: Path = Path("Tarcog.dbg")
    DebugOutputFile: InputOutputFile = field(default_factory=lambda: None)

def _format_output(format_str: str, *args) -> str:
    try:
        return format_str.format(*args)
    except (IndexError, KeyError):
        return format_str

def _print_file(file_obj: InputOutputFile, format_str: str, *args):
    if file_obj is not None and file_obj.good():
        output = _format_output(format_str, *args)
        file_obj.write(output)

def WriteInputArguments(
    state: EnergyPlusData,
    InArgumentsFile: InputOutputFile,
    DBGD: Path,
    tout: float,
    tind: float,
    trmin: float,
    wso: float,
    iwd: int,
    wsi: float,
    dir: float,
    outir: float,
    isky: int,
    tsky: float,
    esky: float,
    fclr: float,
    VacuumPressure: float,
    VacuumMaxGapThickness: float,
    ibc: List[int],
    hout: float,
    hin: float,
    standard: int,
    ThermalMod: int,
    SDScalar: float,
    height: float,
    heightt: float,
    width: float,
    tilt: float,
    totsol: float,
    nlayer: int,
    LayerType: List[int],
    thick: List[float],
    scon: List[float],
    asol: List[float],
    tir: List[float],
    emis: List[float],
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
    nslice: List[int],
    LaminateA: List[float],
    LaminateB: List[float],
    sumsol: List[float],
    gap: List[float],
    vvent: List[float],
    tvent: List[float],
    presure: List[float],
    nmix: List[int],
    iprop: List[List[int]],
    frct: List[List[float]],
    xgcon: List[List[float]],
    xgvis: List[List[float]],
    xgcp: List[List[float]],
    xwght: List[float]
):
    if not InArgumentsFile.good():
        return

    now = datetime.now()
    
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "TARCOG debug output, {:04d}-{:02d}-{:02d}, {:02d}:{:02d}:{:02d}\n",
                now.year, now.month, now.day, now.hour, now.minute, now.second)
    _print_file(InArgumentsFile, "\n")

    if state.dataTARCOGOutputs.winID == -1:
        _print_file(InArgumentsFile, "     WindowID:{:8}  - Not specified\n", state.dataTARCOGOutputs.winID)
    else:
        _print_file(InArgumentsFile, "     WindowID:{:8} \n", state.dataTARCOGOutputs.winID)

    if state.dataTARCOGOutputs.iguID == -1:
        _print_file(InArgumentsFile, "     IGUID:   {:8}  - Not specified\n", state.dataTARCOGOutputs.iguID)
    else:
        _print_file(InArgumentsFile, "     IGUID:   {:8} \n", state.dataTARCOGOutputs.iguID)

    _print_file(InArgumentsFile, "     Debug dir:     {}\n", str(DBGD))
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "TARCOG input arguments:\n")
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "Simulation parameters:\n")
    _print_file(InArgumentsFile, "  Tout       =  {:10.6f} K ( {:7.3f} deg C) - Outdoor temperature\n", tout, tout - Constant.Kelvin)
    _print_file(InArgumentsFile, "  Tint       =  {:10.6f} K ( {:7.3f} deg C) - Indoor temperature\n", tind, tind - Constant.Kelvin)
    _print_file(InArgumentsFile, "  Trmin      =  {:10.6f} K ( {:7.3f} deg C) - Indoor mean radiant temp.\n", trmin, trmin - Constant.Kelvin)
    _print_file(InArgumentsFile, "  wso        =  {:7.3f}    - Outdoor wind speed [m/s]\n", wso)
    if iwd == 0:
        _print_file(InArgumentsFile, "  iwd        =    0        - Wind direction - windward\n")
    if iwd == 1:
        _print_file(InArgumentsFile, "  iwd        =    1        - Wind direction - leeward\n")
    _print_file(InArgumentsFile, "  wsi        =  {:7.3f}    - Indoor forced air speed [m/s]\n", wsi)
    _print_file(InArgumentsFile, "  dir        = {:8.3f}    - Direct solar radiation [W/m^2]\n", dir)
    _print_file(InArgumentsFile, "  outir       = {:8.3f}    - IR radiation [W/m^2]\n", outir)
    _print_file(InArgumentsFile, "  isky       =  {:3}        - Flag for handling tsky, esky\n", isky)
    _print_file(InArgumentsFile, "  tsky           =  {:10.6f} K ( {:7.3f} deg C) - Night sky temperature\n", tsky, tsky - Constant.Kelvin)
    _print_file(InArgumentsFile, "  esky           =  {:7.3f}    - Effective night sky emmitance\n", esky)
    _print_file(InArgumentsFile, "  fclr           =  {:7.3f}    - Fraction of sky that is clear\n", fclr)
    _print_file(InArgumentsFile, "  VacuumPressure =  {:7.3f}    - maximum allowed gas pressure to be considered as vacuum\n", VacuumPressure)
    _print_file(InArgumentsFile, "  VacuumMaxGapThickness =  {:7.3f}    - maximum allowed vacuum gap thickness with support pillar\n", VacuumMaxGapThickness)
    _print_file(InArgumentsFile, "  ibc(1)         =  {:3}        - Outdoor BC switch\n", ibc[0])
    _print_file(InArgumentsFile, "  hout           =  {:9.5f}  - Outdoor film coeff. [W/m^2-K]\n", hout)
    _print_file(InArgumentsFile, "  ibc(2)         =  {:3}        - Indoor BC switch\n", ibc[1])
    _print_file(InArgumentsFile, "  hin            =  {:9.5f}  - Indoor film coeff. [W/m^2-K]\n", hin)

    if standard == Stdrd.ISO15099:
        _print_file(InArgumentsFile, "  standard   =  {:3}        - ISO 15099 calc. standard\n", standard)
    if standard == Stdrd.EN673:
        _print_file(InArgumentsFile, "  standard   =  {:3}        - EN 673/ISO 10292 Declared calc. standard\n", standard)
    if standard == Stdrd.EN673Design:
        _print_file(InArgumentsFile, "  standard   =  {:3}        - EN 673/ISO 10292 Design calc. standard\n", standard)

    if ThermalMod == TARCOGThermalModel.ISO15099:
        _print_file(InArgumentsFile, "  ThermalMod =  {:3}        - ISO15099 thermal model\n", ThermalMod)
        _print_file(InArgumentsFile, "  SDScalar =  {:7.5f}      - Factor of Venetian SD layer contribution to convection\n\n (only if ThermalModel = 2, otherwise ignored)\n", SDScalar)

    if ThermalMod == TARCOGThermalModel.SCW:
        _print_file(InArgumentsFile, "  ThermalMod =  {:3}        - Scaled Cavity Width (SCW) thermal model\n", ThermalMod)
        _print_file(InArgumentsFile, "  SDScalar =  {:7.5f}      - Factor of Venetian SD layer contribution to convection\n\n (only if ThermalModel = 2, otherwise ignored)\n", SDScalar)

    if ThermalMod == TARCOGThermalModel.CSM:
        _print_file(InArgumentsFile, "  ThermalMod =  {:3}        - Convective Scalar Model (CSM) thermal model\n", ThermalMod)
        _print_file(InArgumentsFile, "  SDScalar =  {:7.5f}      - Factor of Venetian SD layer contribution to convection\n\n (only if ThermalModel = 2, otherwise ignored)\n", SDScalar)

    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "IGU parameters:\n")
    _print_file(InArgumentsFile, "  height     =  {:10.6f} - IGU cavity height [m]\n", height)
    _print_file(InArgumentsFile, "  heightt    =  {:10.6f} - Total window height [m]\n", heightt)
    _print_file(InArgumentsFile, "  width      =  {:10.6f} - Window width [m]\n", width)
    _print_file(InArgumentsFile, "  tilt       =  {:7.3f}    - Window tilt [deg]\n", tilt)
    _print_file(InArgumentsFile, "  totsol     =  {:10.6f} - Total solar transmittance of IGU\n", totsol)
    _print_file(InArgumentsFile, "  nlayer     =  {:3}        - Number of glazing layers\n", nlayer)
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "IGU layers list:\n")
    
    for i in range(nlayer):
        if LayerType[i] == TARCOGLayerType.DIFFSHADE:
            _print_file(InArgumentsFile, " Layer{:3} : {:1}              - Diffuse Shade\n", i+1, LayerType[i])
        elif LayerType[i] == TARCOGLayerType.WOVSHADE:
            _print_file(InArgumentsFile, " Layer{:3} : {:1}              - Woven Shade\n", i+1, LayerType[i])
        elif LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ:
            _print_file(InArgumentsFile, " Layer{:3} : {:1}              - Horizontal Venetian Blind\n", i+1, LayerType[i])
        elif LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            _print_file(InArgumentsFile, " Layer{:3} : {:1}              - Vertical Venetian Blind\n", i+1, LayerType[i])
        elif LayerType[i] == TARCOGLayerType.SPECULAR:
            if nslice[i] <= 1:
                _print_file(InArgumentsFile, " Layer{:3} : {:1}              - Specular layer - Monolyhtic Glass\n", i+1, LayerType[i])
            else:
                _print_file(InArgumentsFile, " Layer{:3} : {:1}              - Laminated Glass\n", i+1, LayerType[i])
        else:
            _print_file(InArgumentsFile, " Layer{:3} : {:1}              - UNKNOWN TYPE!\n", i+1, LayerType[i])

        _print_file(InArgumentsFile, "    thick   = {:10.6f}   - Thickness [m]\n", thick[i])
        _print_file(InArgumentsFile, "    scon    = {:10.6f}   - Thermal conductivity [W/m-K]\n", scon[i])
        _print_file(InArgumentsFile, "    asol    = {:12.8f} - Absorbed solar energy [W/m^2]\n", asol[i])
        _print_file(InArgumentsFile, "    tir     = {:12.8f} - IR transmittance\n", tir[2*i])
        _print_file(InArgumentsFile, "    emis1   = {:10.6f}   - IR outdoor emissivity\n", emis[2*i])
        _print_file(InArgumentsFile, "    emis2   = {:10.6f}   - IR indoor emissivity\n", emis[2*i+1])

        if LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            _print_file(InArgumentsFile, "    Atop    = {:10.6f}   - Top opening area [m^2]\n", Atop[i])
            _print_file(InArgumentsFile, "    Abot    = {:10.6f}   - Bottom opening area [m^2]\n", Abot[i])
            _print_file(InArgumentsFile, "    Al      = {:10.6f}   - Left opening area [m^2]\n", Al[i])
            _print_file(InArgumentsFile, "    Ar      = {:10.6f}   - Right opening area [m^2]\n", Ar[i])
            _print_file(InArgumentsFile, "    Ah      = {:10.6f}   - Total area of holes [m^2]\n", Ah[i])
            _print_file(InArgumentsFile, "    SlatThick   = {:10.6f}   - Slat thickness [m]\n", SlatThick[i])
            _print_file(InArgumentsFile, "    SlatWidth   = {:10.6f}   - Slat width [m]\n", SlatWidth[i])
            _print_file(InArgumentsFile, "    SlatAngle   = {:10.6f}   - Slat tilt angle [deg]\n", SlatAngle[i])
            _print_file(InArgumentsFile, "    SlatCond    = {:10.6f}   - Conductivity of the slat material [W/m.K]\n", SlatCond[i])
            _print_file(InArgumentsFile, "    SlatSpacing = {:10.6f}   - Distance between slats [m]\n", SlatSpacing[i])
            _print_file(InArgumentsFile, "    SlatCurve   = {:10.6f}   - Curvature radius of the slat [m]\n", SlatCurve[i])

        if nslice[i] > 1:
            _print_file(InArgumentsFile, "    nslice     = {:3}          - Number of slices\n", nslice[i])
            _print_file(InArgumentsFile, "    nslice     = {:3}          - Number of slices\n", int(LaminateA[i]))
            _print_file(InArgumentsFile, "    nslice     = {:3}          - Number of slices\n", int(LaminateB[i]))
            _print_file(InArgumentsFile, "    nslice     = {:3}          - Number of slices\n", int(sumsol[i]))

    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "IGU Gaps:\n")

    for i in range(nlayer + 1):
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, " Gap {:2}:\n", i)
        if i == 0:
            _print_file(InArgumentsFile, " Outdoor space:\n")
        if i == nlayer:
            _print_file(InArgumentsFile, " Indoor space:\n")
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, "    gap        = {:12.5f} - Gap width [m]\n", gap[i-1])
        _print_file(InArgumentsFile, "    presure    = {:12.5f} - Gas pressure [N/m^2]\n", presure[i])
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, "    vvent      = {:12.5f} - Forced ventilation speed [m/s]\n", vvent[i])
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, "    tvent      = {:12.5f} - Temperature in connected gap [K]\n", tvent[i])
        _print_file(InArgumentsFile, "    nmix       = {:6}       - Num. of gasses in a gas mix\n", nmix[i])

        for j in range(nmix[i]):
            _print_file(InArgumentsFile, "      Gas {:1}:     {}     {:6.2f} %\n", iprop[j][i], ' ', 100 * frct[j][i])
            _print_file(InArgumentsFile, "      Gas mix coefficients - gas {:1}, {:6.2f} %\n", iprop[j][i], 100 * frct[j][i])
            _print_file(InArgumentsFile, "        gcon   = {:11.6f}, {:11.6f}, {:11.6f} - Conductivity\n", 
                       xgcon[0][iprop[j][i]-1], xgcon[1][iprop[j][i]-1], xgcon[2][iprop[j][i]-1])
            _print_file(InArgumentsFile, "        gvis   = {:11.6f}, {:11.6f}, {:11.6f} - Dynamic viscosity\n",
                       xgvis[0][iprop[j][i]-1], xgvis[1][iprop[j][i]-1], xgvis[2][iprop[j][i]-1])
            _print_file(InArgumentsFile, "        gcp    = {:11.6f}, {:11.6f}, {:11.6f} - Spec.heat @ const.P\n",
                       xgcp[0][iprop[j][i]-1], xgcp[1][iprop[j][i]-1], xgcp[2][iprop[j][i]-1])
            _print_file(InArgumentsFile, "        wght   = {:11.6f}                           - Molecular weight\n", 
                       xwght[iprop[j][i]-1])

    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "=====  =====  =====  =====  =====  =====  =====  =====  =====  =====  =====\n")

def WriteModifiedArguments(
    InArgumentsFile: InputOutputFile,
    DBGD: Path,
    esky: float,
    trmout: float,
    trmin: float,
    ebsky: float,
    ebroom: float,
    Gout: float,
    Gin: float,
    nlayer: int,
    LayerType: List[int],
    nmix: List[int],
    frct: List[List[float]],
    thick: List[float],
    scon: List[float],
    gap: List[float],
    xgcon: List[List[float]],
    xgvis: List[List[float]],
    xgcp: List[List[float]],
    xwght: List[float]
):
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "Adjusted input arguments:\n")
    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "  esky       =  {:7.3f}    - Effective night sky emmitance\n", esky)
    _print_file(InArgumentsFile, "  Trmout     =  {:10.6f} K ( {:7.3f} deg C) - Outdoor mean radiant temp.\n", trmout, trmout - Constant.Kelvin)
    _print_file(InArgumentsFile, "  Trmin      =  {:10.6f} K ( {:7.3f} deg C) - Indoor mean radiant temp.\n", trmin, trmin - Constant.Kelvin)
    _print_file(InArgumentsFile, "  Ebsky      =  {:10.6f} \n", ebsky)
    _print_file(InArgumentsFile, "  Ebroom     =  {:10.6f} \n", ebroom)
    _print_file(InArgumentsFile, "  Gout       =  {:10.6f} \n", Gout)
    _print_file(InArgumentsFile, "  Gin        =  {:10.6f} \n", Gin)
    _print_file(InArgumentsFile, "\n")

    for i in range(nlayer):
        if (LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or 
            LayerType[i] == TARCOGLayerType.VENETBLIND_VERT):
            _print_file(InArgumentsFile, " Layer{:3} : {:1}              - Venetian Blind\n", i+1, LayerType[i])
            _print_file(InArgumentsFile, "    thick   = {:10.6f}   - Thickness [m]\n", thick[i])
            _print_file(InArgumentsFile, "    scon    = {:10.6f}   - Thermal conductivity [W/m-K]\n", scon[i])
    _print_file(InArgumentsFile, "\n")

    _print_file(InArgumentsFile, " Gass coefficients:\n")
    for i in range(nlayer + 1):
        if i > 0 and i < nlayer:
            _print_file(InArgumentsFile, " Gap {:2}:\n", i)
            _print_file(InArgumentsFile, " Gap width: {:11.8f}\n", gap[i-1])
        if i == 0:
            _print_file(InArgumentsFile, " Outdoor space:\n")
        if i == nlayer:
            _print_file(InArgumentsFile, " Indoor space:\n")
        for j in range(nmix[i]):
            _print_file(InArgumentsFile, "      Gas mix coefficients - gas {:1}, {:6.2f} %\n", j+1, 100 * frct[j][i])
            _print_file(InArgumentsFile, "        gcon   = {:11.6f}, {:11.6f}, {:11.6f} - Conductivity\n",
                       xgcon[0][j], xgcon[1][j], xgcon[2][j])
            _print_file(InArgumentsFile, "        gvis   = {:11.6f}, {:11.6f}, {:11.6f} - Dynamic viscosity\n",
                       xgvis[0][j], xgvis[1][j], xgvis[2][j])
            _print_file(InArgumentsFile, "        gcp    = {:11.6f}, {:11.6f}, {:11.6f} - Spec.heat @ const.P\n",
                       xgcp[0][j], xgcp[1][j], xgcp[2][j])
            _print_file(InArgumentsFile, "        wght   = {:11.6f}                           - Molecular weight\n", xwght[j])

    _print_file(InArgumentsFile, "\n")
    _print_file(InArgumentsFile, "=====  =====  =====  =====  =====  =====  =====  =====  =====  =====  =====\n")

def WriteOutputArguments(
    OutArgumentsFile: InputOutputFile,
    DBGD: Path,
    nlayer: int,
    tamb: float,
    q: List[float],
    qv: List[float],
    qcgas: List[float],
    qrgas: List[float],
    theta: List[float],
    vfreevent: List[float],
    vvent: List[float],
    Keff: List[float],
    ShadeGapKeffConv: List[float],
    troom: float,
    ufactor: float,
    shgc: float,
    sc: float,
    hflux: float,
    shgct: float,
    hcin: float,
    hrin: float,
    hcout: float,
    hrout: float,
    Ra: List[float],
    Nu: List[float],
    LayerType: List[int],
    Ebf: List[float],
    Ebb: List[float],
    Rf: List[float],
    Rb: List[float],
    ebsky: float,
    Gout: float,
    ebroom: float,
    Gin: float,
    ShadeEmisRatioIn: float,
    ShadeEmisRatioOut: float,
    ShadeHcRatioIn: float,
    ShadeHcRatioOut: float,
    HcUnshadedIn: float,
    HcUnshadedOut: float,
    hcgas: List[float],
    hrgas: List[float],
    AchievedErrorTolerance: float,
    NumOfIter: int
):
    now = datetime.now()
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "TARCOG calculation results - {:04d}-{:02d}-{:02d}, {:02d}:{:02d}:{:02d}\n",
                now.year, now.month, now.day, now.hour, now.minute, now.second)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "Heat Flux Flow and Temperatures of Layer Surfaces:\n")
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "                                            Tamb ={:11.6f} K ( {:7.3f} deg C)\n", tamb, tamb - Constant.Kelvin)
    _print_file(OutArgumentsFile, "           qout ={:12.5f}\n", q[0])

    for i in range(nlayer):
        if LayerType[i] == TARCOGLayerType.SPECULAR:
            _print_file(OutArgumentsFile, "  ----------------- ------------------   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+1, theta[2*i], theta[2*i] - Constant.Kelvin)
            _print_file(OutArgumentsFile, "  |     qpane{:2} ={:12.5f}        |\n", i+1, q[2*i+1])
            _print_file(OutArgumentsFile, "  ----------------- ------------------   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+2, theta[2*i+1], theta[2*i+1] - Constant.Kelvin)
        elif LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            _print_file(OutArgumentsFile, "  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+1, theta[2*i], theta[2*i] - Constant.Kelvin)
            _print_file(OutArgumentsFile, "  |     qpane{:2} ={:12.5f}        |         keffc{:2} ={:11.6f}\n",
                       i+1, q[2*i+1], i+1, ShadeGapKeffConv[i])
            _print_file(OutArgumentsFile, "  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+2, theta[2*i+1], theta[2*i+1] - Constant.Kelvin)
        elif LayerType[i] == TARCOGLayerType.WOVSHADE:
            _print_file(OutArgumentsFile, "  +++++++++++++++++ ++++++++++++++++++   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+1, theta[2*i], theta[2*i] - Constant.Kelvin)
            _print_file(OutArgumentsFile, "  |     qpane{:2} ={:12.5f}        |         keffc{:2} ={:11.6f}\n",
                       i+1, q[2*i+1], i+1, ShadeGapKeffConv[i])
            _print_file(OutArgumentsFile, "  +++++++++++++++++ ++++++++++++++++++   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+2, theta[2*i+1], theta[2*i+1] - Constant.Kelvin)
        elif LayerType[i] == TARCOGLayerType.DIFFSHADE:
            _print_file(OutArgumentsFile, "  ----------------- ------------------   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+1, theta[2*i], theta[2*i] - Constant.Kelvin)
            _print_file(OutArgumentsFile, "  |     qpane{:2} ={:12.5f}        |\n", i+1, q[2*i+1])
            _print_file(OutArgumentsFile, "  ----------------- ------------------   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+2, theta[2*i+1], theta[2*i+1] - Constant.Kelvin)
        else:
            _print_file(OutArgumentsFile, "  ----------------- ------------------   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+1, theta[2*i], theta[2*i] - Constant.Kelvin)
            _print_file(OutArgumentsFile, "  |      qlayer{:2} ={:12.5f}       |\n", i+1, q[2*i+1])
            _print_file(OutArgumentsFile, "  ----------------- ------------------   Theta{:2} ={:11.6f} K ( {:7.3f} deg C)\n",
                       2*i+2, theta[2*i+1], theta[2*i+1] - Constant.Kelvin)

        if i != nlayer - 1:
            _print_file(OutArgumentsFile, "            q{:2} ={:12.5f}\n", i+1, q[2*i+2])
            _print_file(OutArgumentsFile, "           qv{:2} ={:12.5f}\n", i+1, qv[i+1])
            if vvent[i+1] == 0:
                _print_file(OutArgumentsFile, "       airspd{:2} ={:12.5f}    keff{:2} ={:12.5f}\n",
                           i+1, vfreevent[i+1], i+1, Keff[i])
            else:
                if i > 0:
                    _print_file(OutArgumentsFile, "       airspd{:2} ={:12.5f}    keff{:2} ={:12.5f}\n",
                               i+1, vvent[i+1], i+1, Keff[i-1])
            _print_file(OutArgumentsFile, "           qc{:2} ={:12.5f}      qr{:2} ={:12.5f}\n",
                       i+1, qcgas[i+1], i+1, qrgas[i+1])
        else:
            _print_file(OutArgumentsFile, "            qin ={:11.6f}\n", q[2*i+2])

    _print_file(OutArgumentsFile, "                                           Troom ={:11.6f} K ( {:7.3f} deg C)\n",
               troom, troom - Constant.Kelvin)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "Energy balances on Layer Surfaces:\n")
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  Ebsky ={:11.6f} [W/m2], Gout ={:11.6f} [W/m2]\n", ebsky, Gout)
    _print_file(OutArgumentsFile, "\n")

    for i in range(nlayer):
        if LayerType[i] == TARCOGLayerType.SPECULAR:
            _print_file(OutArgumentsFile, "  Ef{:2} ={:11.6f} [W/m2], Rf{:2} ={:11.6f} [W/m2]\n", i+1, Ebf[i], i+1, Rf[i])
            _print_file(OutArgumentsFile, "  ----------------- ------------------\n")
            _print_file(OutArgumentsFile, "  |                     |\n")
            _print_file(OutArgumentsFile, "  ----------------- ------------------\n")
            _print_file(OutArgumentsFile, "  Eb{:2} ={:11.6f} [W/m2], Rb{:2} ={:11.6f} [W/m2]\n", i+1, Ebb[i], i+1, Rb[i])
        elif LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            _print_file(OutArgumentsFile, "  Ef{:2} ={:11.6f} [W/m2], Rf{:2} ={:11.6f} [W/m2]\n", i+1, Ebf[i], i+1, Rf[i])
            _print_file(OutArgumentsFile, "  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n")
            _print_file(OutArgumentsFile, "  |                     |\n")
            _print_file(OutArgumentsFile, "  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n")
            _print_file(OutArgumentsFile, "  Eb{:2} ={:11.6f} [W/m2], Rb{:2} ={:11.6f} [W/m2]\n", i+1, Ebb[i], i+1, Rb[i])
        elif LayerType[i] == TARCOGLayerType.WOVSHADE:
            _print_file(OutArgumentsFile, "  Ef{:2} ={:11.6f} [W/m2], Rf{:2} ={:11.6f} [W/m2]\n", i+1, Ebf[i], i+1, Rf[i])
            _print_file(OutArgumentsFile, "  +++++++++++++++++ ++++++++++++++++++\n")
            _print_file(OutArgumentsFile, "  |                     |\n")
            _print_file(OutArgumentsFile, "  +++++++++++++++++ ++++++++++++++++++\n")
            _print_file(OutArgumentsFile, "  Eb{:2} ={:11.6f} [W/m2], Rb{:2} ={:11.6f} [W/m2]\n", i+1, Ebb[i], i+1, Rb[i])
        elif LayerType[i] == TARCOGLayerType.DIFFSHADE:
            _print_file(OutArgumentsFile, "  Ef{:2} ={:11.6f} [W/m2], Rf{:2} ={:11.6f} [W/m2]\n", i+1, Ebf[i], i+1, Rf[i])
            _print_file(OutArgumentsFile, "  ooooooooooooooooo oooooooooooooooooo\n")
            _print_file(OutArgumentsFile, "  |                     |\n")
            _print_file(OutArgumentsFile, "  ooooooooooooooooo oooooooooooooooooo\n")
            _print_file(OutArgumentsFile, "  Eb{:2} ={:11.6f} [W/m2], Rb{:2} ={:11.6f} [W/m2]\n", i+1, Ebb[i], i+1, Rb[i])
        else:
            _print_file(OutArgumentsFile, "  Ef{:2} ={:11.6f} [W/m2], Rf{:2} ={:11.6f} [W/m2]\n", i+1, Ebf[i], i+1, Rf[i])
            _print_file(OutArgumentsFile, "  ----------------- ------------------\n")
            _print_file(OutArgumentsFile, "  |                     |\n")
            _print_file(OutArgumentsFile, "  ----------------- ------------------\n")
            _print_file(OutArgumentsFile, "  Eb{:2} ={:11.6f} [W/m2], Rb{:2} ={:11.6f} [W/m2]\n", i+1, Ebb[i], i+1, Rb[i])
        _print_file(OutArgumentsFile, "\n")

    _print_file(OutArgumentsFile, "  Ebroom ={:11.6f} [W/m2], Gin  ={:11.6f} [W/m2]\n", ebroom, Gin)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "Basic IGU properties:\n")
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  Ufactor  = {:12.6f}\n", ufactor)
    _print_file(OutArgumentsFile, "  SHGC     = {:12.6f}\n", shgc)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  SC       = {:12.6f}\n", sc)
    _print_file(OutArgumentsFile, "  hflux    = {:12.6f}\n", hflux)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  SHGC_OLD = {:12.6f}\n", shgct)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  hcin  = {:10.6f}   hrin  = {:10.6f}   hin  = {:10.6f}\n",
               hcin, hrin, hcin + hrin)
    _print_file(OutArgumentsFile, "  hcout = {:10.6f}   hrout = {:10.6f}   hout = {:10.6f}\n",
               hcout, hrout, hcout + hrout)
    _print_file(OutArgumentsFile, "\n")

    for i in range(nlayer - 1):
        _print_file(OutArgumentsFile, "  Ra({:1}) ={:15.6f}        Nu({:1}) ={:12.6f}\n",
                   i+1, Ra[i], i+1, Nu[i])

    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  ShadeEmisRatioIn  ={:11.6f}        ShadeEmisRatioOut ={:11.6f}\n",
               ShadeEmisRatioIn, ShadeEmisRatioOut)
    _print_file(OutArgumentsFile, "  ShadeHcRatioIn    ={:11.6f}        ShadeHcRatioOut   ={:11.6f}\n",
               ShadeHcRatioIn, ShadeHcRatioOut)
    _print_file(OutArgumentsFile, "  HcUnshadedIn      ={:11.6f}        HcUnshadedOut     ={:11.6f}\n",
               HcUnshadedIn, HcUnshadedOut)
    _print_file(OutArgumentsFile, "\n")

    for i in range(1, nlayer):
        _print_file(OutArgumentsFile, "  hcgas({:1}) ={:15.6f}      hrgas({:1}) ={:24.6f}\n",
                   i+1, hcgas[i], i+1, hrgas[i])

    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  Error Tolerance = {:12.6E}\n", AchievedErrorTolerance)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  Number of Iterations = {}\n", NumOfIter)

def WriteOutputEN673(
    OutArgumentsFile: InputOutputFile,
    DBGD: Path,
    nlayer: int,
    ufactor: float,
    hout: float,
    hin: float,
    Ra: List[float],
    Nu: List[float],
    hg: List[float],
    hr: List[float],
    hs: List[float],
    nperr: int
):
    now = datetime.now()
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "TARCOG calculation results - {:04d}-{:02d}-{:02d}, {:02d}:{:02d}:{:02d}\n",
                now.year, now.month, now.day, now.hour, now.minute, now.second)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "Basic IGU properties:\n")
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  Ufactor  = {:12.6f}\n", ufactor)
    _print_file(OutArgumentsFile, "\n")
    _print_file(OutArgumentsFile, "  he = {:8.4f},   hi = {:8.4f}\n", hout, hin)
    _print_file(OutArgumentsFile, "\n")

    for i in range(nlayer - 1):
        _print_file(OutArgumentsFile, "  Ra({:1}) ={:15.6f}        Nu({:1}) ={:12.6f}\n",
                   i+1, Ra[i], i+1, Nu[i])

    _print_file(OutArgumentsFile, "\n")
    for i in range(nlayer - 1):
        _print_file(OutArgumentsFile, "  hg{:2} ={:15.6E}      hr{:2} ={:15.6E}      hs{:2} ={:15.6E}\n",
                   i+1, hg[i], i+1, hr[i], i+1, hs[i])

def IsShadingLayer(layer_type: int) -> bool:
    return layer_type in [TARCOGLayerType.VENETBLIND_HORIZ, TARCOGLayerType.VENETBLIND_VERT,
                          TARCOGLayerType.WOVSHADE, TARCOGLayerType.DIFFSHADE]

def WriteTARCOGInputFile(
    state: EnergyPlusData,
    files: Files,
    VerNum: str,
    tout: float,
    tind: float,
    trmin: float,
    wso: float,
    iwd: int,
    wsi: float,
    dir: float,
    outir: float,
    isky: int,
    tsky: float,
    esky: float,
    fclr: float,
    VacuumPressure: float,
    VacuumMaxGapThickness: float,
    CalcDeflection: int,
    Pa: float,
    Pini: float,
    Tini: float,
    ibc: List[int],
    hout: float,
    hin: float,
    standard: int,
    ThermalMod: int,
    SDScalar: float,
    height: float,
    heightt: float,
    width: float,
    tilt: float,
    totsol: float,
    nlayer: int,
    LayerType: List[int],
    thick: List[float],
    scon: List[float],
    YoungsMod: List[float],
    PoissonsRat: List[float],
    asol: List[float],
    tir: List[float],
    emis: List[float],
    Atop: List[float],
    Abot: List[float],
    Al: List[float],
    Ar: List[float],
    Ah: List[float],
    SupportPillar: List[int],
    PillarSpacing: List[float],
    PillarRadius: List[float],
    SlatThick: List[float],
    SlatWidth: List[float],
    SlatAngle: List[float],
    SlatCond: List[float],
    SlatSpacing: List[float],
    SlatCurve: List[float],
    nslice: List[int],
    gap: List[float],
    GapDef: List[float],
    vvent: List[float],
    tvent: List[float],
    presure: List[float],
    nmix: List[int],
    iprop: List[List[int]],
    frct: List[List[float]],
    xgcon: List[List[float]],
    xgvis: List[List[float]],
    xgcp: List[List[float]],
    xwght: List[float],
    gama: List[float]
):
    now = datetime.now()
    
    _print_file(files.WINCogFile, "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n")
    _print_file(files.WINCogFile, "*\n")
    _print_file(files.WINCogFile, "* TARCOG debug output for WinCOG, {:04d}-{:02d}-{:02d}, {:02d}:{:02d}:{:02d}\n",
                now.year, now.month, now.day, now.hour, now.minute, now.second)
    _print_file(files.WINCogFile, "* created by TARCOG v. {}\n", VerNum)
    _print_file(files.WINCogFile, "*\n")

    if state.dataTARCOGOutputs.winID == -1:
        _print_file(files.WINCogFile, "*     WindowID:   {:8}  - Not specified\n", state.dataTARCOGOutputs.winID)
    else:
        _print_file(files.WINCogFile, "*     WindowID:   {:8} \n", state.dataTARCOGOutputs.winID)
    
    if state.dataTARCOGOutputs.iguID == -1:
        _print_file(files.WINCogFile, "*     IGUID:      {:8}  - Not specified\n", state.dataTARCOGOutputs.iguID)
    else:
        _print_file(files.WINCogFile, "*     IGUID:      {:8} \n", state.dataTARCOGOutputs.iguID)

    _print_file(files.WINCogFile, "*     Num Layers: {:8} \n", nlayer)
    _print_file(files.WINCogFile, "*\n")
    _print_file(files.WINCogFile, "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n")
    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* General options:\n")
    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* <nlayer, debug, standard, ThermalMod, CalcDeflection, SDScalar, VacuumPressure, VacuumMaxGapThickness>\n")
    _print_file(files.WINCogFile, "    {:1}, {:1}, {:1}, {:1}, {:1}, {:24.12f}, {:24.12f}, {:24.12f}\n",
               nlayer, 2, standard, ThermalMod, CalcDeflection, SDScalar, VacuumPressure, VacuumMaxGapThickness)

    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* Environmental settings:\n")
    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* <tout, tind, wso, iwd, wsi, dir, outir, isky, tsky, esky, fclr, trmin, Pa, Pini, Tini>\n")
    _print_file(files.WINCogFile, "    {:24.12f}, {:24.12f}, {:24.12f}, {:1}, {:24.12f}, {:24.12f}, {:24.12f}, {:1}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}\n",
               tout, tind, wso, iwd, wsi, dir, outir, isky, tsky, esky, fclr, trmin, Pa, Pini, Tini)

    NumOfProvGasses = 0
    while NumOfProvGasses < len(xwght) and xwght[NumOfProvGasses] != 0:
        NumOfProvGasses += 1

    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* Gas coefficients information\n")
    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* <NumberOfGasses>\n")
    _print_file(files.WINCogFile, "    {:2}\n", NumOfProvGasses)

    for i in range(NumOfProvGasses):
        _print_file(files.WINCogFile, "* <MolecularWeight>\n")
        _print_file(files.WINCogFile, "    {:12.6E}\n", xwght[i])
        _print_file(files.WINCogFile, "* <gconA, gconB, gconC>\n")
        for j in range(1, 3):
            _print_file(files.WINCogFile, ", {:12.6E}", xgcon[j][i])
        _print_file(files.WINCogFile, "\n")
        _print_file(files.WINCogFile, "* <gvisA, gvisB, gvisC>\n")
        for j in range(1, 3):
            _print_file(files.WINCogFile, ", {:12.6E}", xgvis[j][i])
        _print_file(files.WINCogFile, "\n")
        _print_file(files.WINCogFile, "* <gcpA, gcpB, gcpC>\n")
        for j in range(1, 3):
            _print_file(files.WINCogFile, ", {:12.6E}", xgcp[j][i])
        _print_file(files.WINCogFile, "\n")
        _print_file(files.WINCogFile, "* <Gamma>\n")
        _print_file(files.WINCogFile, "    {:12.6E}\n", gama[i])

    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* Overall IGU properties:\n")
    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* <totsol, tilt, height, heightt, width>\n")
    _print_file(files.WINCogFile, "    {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}\n",
               totsol, tilt, height, heightt, width)

    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* Outdoor environment:\n")
    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* <ibc(1), hout, presure(1), 1, 1, 1.0, vvent(1), tvent(1)>\n")
    _print_file(files.WINCogFile, "    {:1}, {:24.12f}, {:24.12f}, {:1}, {:1}, {:24.12f}, {:24.12f}, {:24.12f}\n",
               ibc[0], hout, presure[0], 1, 1, 1.0, vvent[0], tvent[0])

    _print_file(files.WINCogFile, "* IGU definition:\n")

    for i in range(nlayer):
        _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
        if LayerType[i] == TARCOGLayerType.SPECULAR:
            _print_file(files.WINCogFile, "* Layer {:1} - specular-glass:\n", i+1)
        elif LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            _print_file(files.WINCogFile, "* Layer {:1} - venetian blind:\n", i+1)
        elif LayerType[i] == TARCOGLayerType.WOVSHADE:
            _print_file(files.WINCogFile, "* Layer {:1} - woven shade:\n", i+1)
        elif LayerType[i] == TARCOGLayerType.DIFFSHADE:
            _print_file(files.WINCogFile, "* Layer {:1} - diffuse shade:\n", i+1)
        else:
            _print_file(files.WINCogFile, "* Layer {:1} - ???:\n", i+1)
        _print_file(files.WINCogFile, "*------------------------------------------------------------\n")

        _print_file(files.WINCogFile, "* <scon(i), asol(i), thick(i), emis(2*i-1), emis(2*i), tir(2*i-1), YoungsMod(i),\n\n PoissonsRat(i), LayerType(i), nslice(i)>\n")
        _print_file(files.WINCogFile, "    {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:1}, {:1}\n",
                   scon[i], asol[i], thick[i], emis[2*i], emis[2*i+1], tir[2*i], YoungsMod[i], PoissonsRat[i], LayerType[i], nslice[i])

        if IsShadingLayer(LayerType[i]):
            _print_file(files.WINCogFile, "* <Atop(i), Abot(i), Al(i), Ar(i), Ah(i)>\n")
            _print_file(files.WINCogFile, "    {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}\n",
                       Atop[i], Abot[i], Al[i], Ar[i], Ah[i])

        if LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            _print_file(files.WINCogFile, "* <SlatThick(i), SlatWidth(i), SlatAngle(i), SlatCond(i), SlatSpacing(i), SlatCurve(i)>\n")
            _print_file(files.WINCogFile, "    {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}, {:24.12f}\n",
                       SlatThick[i], SlatWidth[i], SlatAngle[i], SlatCond[i], SlatSpacing[i], SlatCurve[i])

        if i < nlayer - 1:
            _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
            _print_file(files.WINCogFile, "* Gap {:1}:\n", i+1)
            _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
            _print_file(files.WINCogFile, "* <gap(i), GapDef(i), presure(i+1), nmix(i+1), (iprop(i+1, j), j=1,nmix(i+1)), (frct(i+1, j), \n\nj=1,nmix(i+1)), vvent(i), tvent(i), SupportPillar(i)>\n")
            output = "    {:24.12f}, {:24.12f}, {:24.12f}, {:1}, ".format(gap[i], GapDef[i], presure[i+1], nmix[i+1])
            for j in range(nmix[i+1]):
                output += "{:1}, ".format(iprop[j][i+1])
            for j in range(nmix[i+1]):
                output += "{:24.12f}, ".format(frct[j][i+1])
            output += "    {:24.12f}, {:24.12f}, {:1}, \n".format(vvent[i+1], tvent[i+1], SupportPillar[i])
            _print_file(files.WINCogFile, output)
            
            if SupportPillar[i] == YES_SupportPillar:
                _print_file(files.WINCogFile, "* <PillarSpacing(i), PillarRadius(i)\n")
                _print_file(files.WINCogFile, "    {:24.12f}, {:24.12f}\n", PillarSpacing[i], PillarRadius[i])

    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* Indoor environment:\n")
    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* <ibc(2), hin, presure(nlayer+1), 1, 1, 1.0, vvent(nlayer+1), tvent(nlayer+1)>\n")
    _print_file(files.WINCogFile, "    {:1}, {:24.12f}, {:24.12f}, {:1}, {:1}, {:24.12f}, {:24.12f}, {:24.12f}\n",
               ibc[1], hin, presure[nlayer], 1, 1, 1.0, vvent[nlayer], tvent[nlayer])

    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "* End file\n")
    _print_file(files.WINCogFile, "*------------------------------------------------------------\n")
    _print_file(files.WINCogFile, "\n")

def FinishDebugOutputFiles(files: Files, nperr: int):
    if files.WriteDebugOutput:
        _print_file(files.DebugOutputFile, "\n")
        if 0 < nperr < 1000:
            _print_file(files.DebugOutputFile, "TARCOG status: {:3} - Error!\n", nperr)
        elif nperr >= 1000:
            _print_file(files.DebugOutputFile, "TARCOG status: {:3} - Warning!\n", nperr)
        else:
            _print_file(files.DebugOutputFile, "TARCOG status: {:3} - Normal termination.\n", nperr)

        _print_file(files.DebugOutputFile, "\n")
        _print_file(files.DebugOutputFile, "#####  #####  #####  #####  #####  #####  #####  #####  #####  #####  #####\n")
        _print_file(files.DebugOutputFile, "#####  #####  #####  #####  #####  #####  #####  #####  #####  #####  #####\n")

    if files.DebugOutputFile is not None and files.DebugOutputFile.good():
        files.DebugOutputFile.close()

    if files.WINCogFile is not None and files.WINCogFile.good():
        files.WINCogFile.close()

    if files.IterationCSVFile is not None and files.IterationCSVFile.good():
        files.IterationCSVFile.close()

    if files.TarcogIterationsFile is not None and files.TarcogIterationsFile.good():
        files.TarcogIterationsFile.close()

def PrepDebugFilesAndVariables(
    state: EnergyPlusData,
    files: Files,
    Debug_dir: Path,
    Debug_file: Path,
    Debug_mode: int,
    win_ID: int,
    igu_ID: int
):
    files.DBGD = Debug_dir
    state.dataTARCOGOutputs.winID = win_ID
    state.dataTARCOGOutputs.iguID = igu_ID

    if Debug_file != Path(""):
        files.WINCogFilePath = Path(str(Debug_file) + ".w7")
        files.DebugOutputFilePath = Path(str(Debug_file) + ".dbg")

    files.WriteDebugOutput = False
