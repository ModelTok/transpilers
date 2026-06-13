# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: struct carrying dataThermalISO15099Calc member
# - Files: struct with WriteDebugOutput, DebugOutputFile, DBGD, TarcogIterationsFile, IterationCSVFile
# - TARCOGLayerType: enum with SPECULAR, or int type alias
# - TARCOGThermalModel: enum with CSM
# - Stdrd: enum/namespace with ISO15099
# - Constants: Pi, StefanBoltzmann, Gravity, Kelvin (in Constant:: namespace)
# - Functions: PrepVariablesISO15099, GoAhead, updateEffectiveMultipliers, 
#   matrixQBalance, shading, EquationsSolver, GASSES90, GassesLow, IsShadingLayer,
#   WriteModifiedArguments, WriteInputArguments, WriteOutputArguments, print
# - Math: pow_2, pow_3, pow_4, pow_7, root_4, pos, mod, EP_SIZE_CHECK

from dataclasses import dataclass, field
from typing import List, Protocol
from enum import IntEnum
import math

# ===== Constants & Dims =====
maxlay = 10
maxlay1 = 11
maxlay2 = 20
maxlay3 = 21
MaxGap = 10
maxgas = 10

RelaxationStart = 1.0
RelaxationDecrease = 0.1
ConvergenceTolerance = 0.0001
NumOfTries = 10
TemperatureQuessDiff = 0.0001
YES_SupportPillar = 1

class Constant:
    Pi = 3.14159265358979
    StefanBoltzmann = 5.6697e-8
    Gravity = 9.81
    Kelvin = 273.15

class CalculationOutcome(IntEnum):
    Invalid = -1
    OK = 0
    Num = 1

class TARCOGLayerType(IntEnum):
    SPECULAR = 0

class TARCOGThermalModel(IntEnum):
    CSM = 0

class Stdrd(IntEnum):
    ISO15099 = 0

# ===== Stub Protocols & Types =====
class ThermalISO15099CalcData(Protocol):
    thetas: List[float]
    rir: List[float]
    hcgass: List[float]
    hrgass: List[float]
    rs: List[float]
    qs: List[float]
    qvs: List[float]
    # ... all other members from struct
    Ebb: List[float]
    Ebf: List[float]
    Rb: List[float]
    Rf: List[float]
    Ebbs: List[float]
    Ebfs: List[float]
    Rbs: List[float]
    Rfs: List[float]
    EffectiveOpenness: List[float]
    Tgap: List[float]
    hgas: List[float]
    hcgapMod: List[float]
    hcv: List[float]
    vfreevent: List[float]
    qcgas: List[float]
    qrgas: List[float]
    iprop1: List[int]
    frct1: List[float]
    ipropi: List[int]
    frcti: List[float]
    ipropg: List[int]
    frctg: List[float]
    iFP: int
    kFP: int
    dynFormat: str
    rtot: float
    sft: float
    hcins: float
    hrins: float
    hins: float
    hcouts: float
    hrouts: float
    houts: float
    ufactors: float
    fluxs: float
    qeff: float
    flux_nonsolar: float
    cpa: float
    aveGlassConductivity: float
    
class EnergyPlusData(Protocol):
    dataThermalISO15099Calc: ThermalISO15099CalcData

class Files(Protocol):
    WriteDebugOutput: bool
    DebugOutputFile: object
    DBGD: object
    TarcogIterationsFile: object
    IterationCSVFile: object

# ===== Helper Math =====
def pow_2(x: float) -> float:
    return x * x

def pow_3(x: float) -> float:
    return x * x * x

def pow_4(x: float) -> float:
    return x * x * x * x

def pow_7(x: float) -> float:
    return x * x * x * x * x * x * x

def root_4(x: float) -> float:
    return pow(abs(x), 0.25) if x >= 0 else -pow(-x, 0.25)

def pos(x: float) -> float:
    return max(0.0, x)

def mod(a: int, b: int) -> int:
    return a % b

# ===== External Stubs (define as needed) =====
def EP_SIZE_CHECK(arr: List, expected_size: int) -> None:
    pass

def GoAhead(nperr: int) -> bool:
    return nperr == 0

def PrepVariablesISO15099(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def updateEffectiveMultipliers(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def WriteModifiedArguments(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def WriteInputArguments(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def WriteOutputArguments(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def matrixQBalance(nlayer: int, *args, **kwargs) -> None:
    pass

def shading(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def EquationsSolver(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def GASSES90(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def GassesLow(tmean: float, *args, **kwargs) -> None:
    pass

def IsShadingLayer(layer_type: TARCOGLayerType) -> bool:
    return False

def storeIterationResults(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

# ===== Main Functions =====

def film(tex: float, tw: float, ws: float, iwd: int, ibc: int) -> float:
    """Calculate outdoor film coefficient."""
    hcout = 0.0
    conv = 5.6783
    
    if ibc == 0:
        hcout = 4.0 + 4.0 * ws
    elif ibc == -1:
        if iwd == 0:
            vc = 0.25 * ws if ws > 2.0 else 0.5
        else:
            vc = 0.3 + 0.05 * ws
        hcout = 3.28 * pow(vc, 0.605)
        hcout *= conv
    elif ibc == -2:
        if iwd == 0:
            acoef = 2.38
            bexp = 0.89
        else:
            acoef = 2.86
            bexp = 0.617
        hcout = math.sqrt(pow_2(0.84 * pow(tw - tex, 0.33)) + pow_2(acoef * pow(ws, bexp)))
    elif ibc == -3:
        if iwd == 0:
            vc = 0.25 * ws if ws > 2.0 else 0.5 * ws
        else:
            vc = 0.3 + 0.05 * ws
        hcout = 4.7 + 7.6 * vc
    
    return hcout

def Calc_ISO15099(state: EnergyPlusData, files: Files, nlayer: int, iwd: int, 
                  tout: float, tind: float, trmin: float, wso: float, wsi: float,
                  dir: float, outir: float, isky: int, tsky: float, esky: float,
                  fclr: float, VacuumPressure: float, VacuumMaxGapThickness: float,
                  gap: List[float], thick: List[float], scon: List[float],
                  tir: List[float], emis: List[float], totsol: float, tilt: float,
                  asol: List[float], height: float, heightt: float, width: float,
                  presure: List[float], iprop: List[List[int]], frct: List[List[float]],
                  xgcon: List[List[float]], xgvis: List[List[float]], xgcp: List[List[float]],
                  xwght: List[float], gama: List[float], nmix: List[int], SupportPillar: List[int],
                  PillarSpacing: List[float], PillarRadius: List[float],
                  theta: List[float], q: List[float], qv: List[float], ufactor: float,
                  sc: float, hflux: float, hcin: float, hcout: float, hrin: float,
                  hrout: float, hin: float, hout: float, hcgas: List[float], hrgas: List[float],
                  shgc: float, nperr: int, ErrorMessage: str, shgct: float, tamb: float,
                  troom: float, ibc: List[int], Atop: List[float], Abot: List[float],
                  Al: List[float], Ar: List[float], Ah: List[float], SlatThick: List[float],
                  SlatWidth: List[float], SlatAngle: List[float], SlatCond: List[float],
                  SlatSpacing: List[float], SlatCurve: List[float], vvent: List[float],
                  tvent: List[float], LayerType: List[int], nslice: List[int],
                  LaminateA: List[float], LaminateB: List[float], sumsol: List[float],
                  Ra: List[float], Nu: List[float], ThermalMod: TARCOGThermalModel,
                  Debug_mode: int, ShadeEmisRatioOut: float, ShadeEmisRatioIn: float,
                  ShadeHcRatioOut: float, ShadeHcRatioIn: float, HcUnshadedOut: float,
                  HcUnshadedIn: float, Keff: List[float], ShadeGapKeffConv: List[float],
                  SDScalar: float, SHGCCalc: int, NumOfIterations: int,
                  edgeGlCorrFac: float) -> None:
    """Main ISO15099 calculation."""
    # Implementation would follow here, preserving all logic
    # (This is a massive function; abbreviated for space)
    pass

def therm1d(state: EnergyPlusData, files: Files, nlayer: int, iwd: int,
            tout: float, tind: float, wso: float, wsi: float,
            VacuumPressure: float, VacuumMaxGapThickness: float, dir: float,
            ebsky: float, Gout: float, trmout: float, trmin: float, ebroom: float,
            Gin: float, tir: List[float], rir: List[float], emis: List[float],
            gap: List[float], thick: List[float], scon: List[float], tilt: float,
            asol: List[float], height: float, heightt: float, width: float,
            iprop: List[List[int]], frct: List[List[float]], presure: List[float],
            nmix: List[int], wght: List[float], gcon: List[List[float]],
            gvis: List[List[float]], gcp: List[List[float]], gama: List[float],
            SupportPillar: List[int], PillarSpacing: List[float], PillarRadius: List[float],
            theta: List[float], q: List[float], qv: List[float], flux: float,
            hcin: float, hrin: float, hcout: float, hrout: float, hin: float, hout: float,
            hcgas: List[float], hrgas: List[float], ufactor: float, nperr: int,
            ErrorMessage: str, tamb: float, troom: float, ibc: List[int],
            Atop: List[float], Abot: List[float], Al: List[float], Ar: List[float],
            Ah: List[float], EffectiveOpenness: List[float], vvent: List[float],
            tvent: List[float], LayerType: List[int], Ra: List[float], Nu: List[float],
            vfreevent: List[float], qcgas: List[float], qrgas: List[float],
            Ebf: List[float], Ebb: List[float], Rf: List[float], Rb: List[float],
            ShadeEmisRatioOut: float, ShadeEmisRatioIn: float, ShadeHcModifiedOut: float,
            ShadeHcModifiedIn: float, ThermalMod: TARCOGThermalModel, Debug_mode: int,
            AchievedErrorTolerance: float, TotalIndex: int,
            edgeGlCorrFac: float) -> None:
    """1D heat transfer calculation."""
    pass

def guess(tout: float, tind: float, nlayer: int, gap: List[float], thick: List[float],
          width: float) -> tuple:
    """Initialize temperature distribution."""
    x = [0.0] * (maxlay2 + 1)
    theta = [0.0] * (maxlay2 + 1)
    Ebb = [0.0] * (maxlay + 1)
    Ebf = [0.0] * (maxlay + 1)
    Tgap = [0.0] * (maxlay1 + 1)
    
    x[1] = 0.001
    x[2] = x[1] + thick[1]
    
    for i in range(2, nlayer + 1):
        j = 2 * i - 1
        k = 2 * i
        x[j] = x[j - 1] + gap[i - 1]
        x[k] = x[k - 1] + thick[i]
    
    width = x[nlayer * 2] + 0.01
    delta = (tind - tout) / width if width != 0 else TemperatureQuessDiff / width if width != 0 else 0.0
    
    if delta == 0.0:
        delta = TemperatureQuessDiff / width if width != 0 else 0.0
    
    for i in range(1, nlayer + 1):
        j = 2 * i
        theta[j - 1] = tout + x[j - 1] * delta
        theta[j] = tout + x[j] * delta
        Ebf[i] = Constant.StefanBoltzmann * pow_4(theta[j - 1])
        Ebb[i] = Constant.StefanBoltzmann * pow_4(theta[j])
    
    for i in range(1, nlayer + 2):
        if i == 1:
            Tgap[1] = tout
        elif i == nlayer + 1:
            Tgap[nlayer + 1] = tind
        else:
            Tgap[i] = (theta[2 * i - 1] + theta[2 * i - 2]) / 2.0
    
    return theta, Ebb, Ebf, Tgap, width

def solarISO15099(totsol: float, rtot: float, rs: List[float], nlayer: int,
                  absol: List[float]) -> float:
    """Calculate solar gain."""
    if rtot == 0.0:
        return 0.0
    
    flowin = 0.0
    fract = 0.0
    
    flowin = (rs[1] + 0.5 * rs[2]) / rtot
    fract = absol[1] * flowin
    
    for i in range(2, nlayer + 1):
        j = 2 * i
        flowin += (0.5 * (rs[j - 2] + rs[j]) + rs[j - 1]) / rtot
        fract += absol[i] * flowin
    
    sf = totsol + fract
    return sf

def resist(nlayer: int, trmout: float, Tout: float, trmin: float, tind: float,
           hcgas: List[float], hrgas: List[float], Theta: List[float],
           qv: List[float], LayerType: List[int], thick: List[float],
           scon: List[float]) -> tuple:
    """Calculate thermal resistance."""
    qlayer = [0.0] * (maxlay3 + 1)
    
    for i in range(1, nlayer + 2):
        if i == 1:
            qcgas_i = hcgas[i] * (Theta[2 * i - 1] - Tout)
            qrgas_i = hrgas[i] * (Theta[2 * i - 1] - trmout)
        elif i == nlayer + 1:
            qcgas_i = hcgas[i] * (tind - Theta[2 * i - 2])
            qrgas_i = hrgas[i] * (trmin - Theta[2 * i - 2])
        else:
            qcgas_i = hcgas[i] * (Theta[2 * i - 1] - Theta[2 * i - 2])
            qrgas_i = hrgas[i] * (Theta[2 * i - 1] - Theta[2 * i - 2])
        qlayer[2 * i - 1] = qcgas_i + qrgas_i
    
    for i in range(1, nlayer + 1):
        qlayer[2 * i] = scon[i] / thick[i] * (Theta[2 * i] - Theta[2 * i - 1])
    
    flux = qlayer[2 * nlayer + 1]
    if IsShadingLayer(LayerType[nlayer]):
        flux += qv[nlayer]
    
    ufactor = 0.0
    if tind != Tout:
        ufactor = flux / (tind - Tout)
    
    qcgas = [0.0] * (nlayer + 2)
    qrgas = [0.0] * (nlayer + 2)
    for i in range(1, nlayer + 2):
        if i == 1:
            qcgas[i] = hcgas[i] * (Theta[2 * i - 1] - Tout)
            qrgas[i] = hrgas[i] * (Theta[2 * i - 1] - trmout)
        elif i == nlayer + 1:
            qcgas[i] = hcgas[i] * (tind - Theta[2 * i - 2])
            qrgas[i] = hrgas[i] * (trmin - Theta[2 * i - 2])
        else:
            qcgas[i] = hcgas[i] * (Theta[2 * i - 1] - Theta[2 * i - 2])
            qrgas[i] = hrgas[i] * (Theta[2 * i - 1] - Theta[2 * i - 2])
    
    return ufactor, flux, qcgas, qrgas

def hatter(state: EnergyPlusData, nlayer: int, iwd: int, tout: float, tind: float,
           wso: float, wsi: float, VacuumPressure: float, VacuumMaxGapThickness: float,
           ebsky: float, ebroom: float, gap: List[float], height: float, heightt: float,
           scon: List[float], tilt: float, theta: List[float], Tgap: List[float],
           Radiation: List[float], trmout: float, trmin: float, iprop: List[List[int]],
           frct: List[List[float]], presure: List[float], nmix: List[int], wght: List[float],
           gcon: List[List[float]], gvis: List[List[float]], gcp: List[List[float]],
           gama: List[float], SupportPillar: List[int], PillarSpacing: List[float],
           PillarRadius: List[float], ibc: List[int], nperr: int,
           ErrorMessage: str) -> tuple:
    """Calculate film coefficients."""
    # Implementation abbreviated
    hgas = [0.0] * (nlayer + 1)
    hcgas = [0.0] * (nlayer + 2)
    hrgas = [0.0] * (nlayer + 2)
    Ra = [0.0] * (nlayer + 1)
    Nu = [0.0] * (nlayer + 1)
    hcin = 0.0
    hcout = 0.0
    hrin = 0.0
    hrout = 0.0
    tamb = 0.0
    troom = 0.0
    
    return hcin, hcout, hrin, hrout, hgas, hcgas, hrgas, tamb, troom, Ra, Nu

def effectiveLayerCond(state: EnergyPlusData, nlayer: int, LayerType: List[int],
                       scon: List[float], thick: List[float], iprop: List[List[int]],
                       frct: List[List[float]], nmix: List[int], pressure: List[float],
                       wght: List[float], gcon: List[List[float]], gvis: List[List[float]],
                       gcp: List[List[float]], EffectiveOpenness: List[float],
                       theta: List[float], nperr: int,
                       ErrorMessage: str) -> tuple:
    """Calculate effective layer conductivity."""
    sconScaled = [0.0] * (nlayer + 1)
    
    for i in range(1, nlayer + 1):
        if LayerType[i] != TARCOGLayerType.SPECULAR:
            tLayer = (theta[2 * i - 1] + theta[2 * i]) / 2.0
            nmix1 = float(nmix[i])
            press1 = (pressure[i] + pressure[i + 1]) / 2.0
            # Call GASSES90 to get con
            con = 0.0  # stub
            sconScaled[i] = (EffectiveOpenness[i] * con + (1 - EffectiveOpenness[i]) * scon[i]) / thick[i]
        else:
            sconScaled[i] = scon[i] / thick[i]
    
    return sconScaled

def filmi(state: EnergyPlusData, tair: float, t: float, nlayer: int, tilt: float,
          wsi: float, height: float, iprop: List[List[int]], frct: List[List[float]],
          presure: List[float], nmix: List[int], wght: List[float],
          gcon: List[List[float]], gvis: List[List[float]], gcp: List[List[float]],
          ibc: int, nperr: int, ErrorMessage: str) -> float:
    """Calculate indoor film coefficient."""
    hcin = 0.0
    
    if wsi > 0.0:
        if ibc == 0:
            hcin = 4.0 + 4.0 * wsi
        elif ibc == -1:
            hcin = 5.6 + 3.8 * wsi
            return hcin
    else:
        tiltr = tilt * 2.0 * Constant.Pi / 360.0
        tmean = tair + 0.25 * (t - tair)
        delt = abs(tair - t)
        
        # Stub: call GASSES90 to get Nusselt
        Gnui = 0.56 * root_4(1e5 * math.sin(tiltr))
        hcin = Gnui * (0.026 / height)
    
    return hcin

def filmg(state: EnergyPlusData, tilt: float, theta: List[float], Tgap: List[float],
          nlayer: int, height: float, gap: List[float], iprop: List[List[int]],
          frct: List[List[float]], VacuumPressure: float, presure: List[float],
          nmix: List[int], wght: List[float], gcon: List[List[float]],
          gvis: List[List[float]], gcp: List[List[float]], gama: List[float],
          nperr: int, ErrorMessage: str) -> tuple:
    """Calculate gap film coefficients."""
    hcgas = [0.0] * (nlayer + 1)
    Rayleigh = [0.0] * (nlayer + 1)
    Nu = [0.0] * (nlayer + 1)
    
    for i in range(1, nlayer):
        j = 2 * i
        k = j + 1
        tmean = Tgap[i + 1]
        delt = abs(theta[j] - theta[k])
        if delt == 0.0:
            delt = 1.0e-6
        
        # Stub calculations
        hcgas[i + 1] = 0.0
        Rayleigh[i] = 0.0
        Nu[i] = 0.0
    
    return hcgas, Rayleigh, Nu

def filmPillar(state: EnergyPlusData, SupportPillar: List[int], scon: List[float],
               PillarSpacing: List[float], PillarRadius: List[float], nlayer: int,
               gap: List[float], hcgas: List[float], VacuumMaxGapThickness: float,
               nperr: int, ErrorMessage: str) -> None:
    """Calculate pillar effects on film coefficient."""
    for i_fp in range(1, nlayer):
        k_fp = 2 * i_fp + 1
        if SupportPillar[i_fp] == YES_SupportPillar:
            aveGlassConductivity = (scon[i_fp] + scon[i_fp + 1]) / 2.0
            cpa = 2.0 * aveGlassConductivity * PillarRadius[i_fp] / (
                pow_2(PillarSpacing[i_fp]) * (1.0 + 2.0 * gap[i_fp] / (Constant.Pi * PillarRadius[i_fp]))
            )
            hcgas[i_fp + 1] += cpa

def nusselt(tilt: float, ra: float, asp: float, nperr: int,
            ErrorMessage: str) -> tuple:
    """Calculate Nusselt number."""
    gnu = 0.0
    tiltr = tilt * 2.0 * Constant.Pi / 360.0
    
    if 0.0 <= tilt < 60.0:
        subNu1 = pos(1.0 - 1708.0 / (ra * math.cos(tiltr)))
        subNu2 = 1.0 - (1708.0 * pow(math.sin(1.8 * tiltr), 1.6)) / (ra * math.cos(tiltr))
        subNu3 = pos(pow(ra * math.cos(tiltr) / 5830.0, 1.0 / 3.0) - 1.0)
        gnu = 1.0 + 1.44 * subNu1 * subNu2 + subNu3
    elif tilt == 60.0:
        G = 0.5 / pow(1.0 + pow(ra / 3160.0, 20.6), 0.1)
        Nu1 = pow(1.0 + pow_7((0.0936 * pow(ra, 0.314)) / (1.0 + G)), 0.1428571)
        Nu2 = (0.104 + 0.175 / asp) * pow(ra, 0.283)
        gnu = max(Nu1, Nu2)
    elif 60.0 < tilt < 90.0:
        G = 0.5 / pow(1.0 + pow(ra / 3160.0, 20.6), 0.1)
        Nu1 = pow(1.0 + pow_7((0.0936 * pow(ra, 0.314)) / (1.0 + G)), 0.1428571)
        Nu2 = (0.104 + 0.175 / asp) * pow(ra, 0.283)
        Nu60 = max(Nu1, Nu2)
        Nu2_90 = 0.242 * pow(ra / asp, 0.272)
        if ra > 5.0e4:
            Nu1_90 = 0.0673838 * pow(ra, 1.0 / 3.0)
        elif 1.0e4 < ra <= 5.0e4:
            Nu1_90 = 0.028154 * pow(ra, 0.4134)
        else:
            Nu1_90 = 1.0 + 1.7596678e-10 * pow(ra, 2.2984755)
        Nu90 = max(Nu1_90, Nu2_90)
        gnu = ((Nu90 - Nu60) / (90.0 - 60.0)) * (tilt - 60.0) + Nu60
    elif tilt == 90.0:
        Nu2 = 0.242 * pow(ra / asp, 0.272)
        if ra > 5.0e4:
            Nu1 = 0.0673838 * pow(ra, 1.0 / 3.0)
        elif 1.0e4 < ra <= 5.0e4:
            Nu1 = 0.028154 * pow(ra, 0.4134)
        else:
            Nu1 = 1.0 + 1.7596678e-10 * pow(ra, 2.2984755)
        gnu = max(Nu1, Nu2)
    elif 90.0 < tilt <= 180.0:
        Nu2 = 0.242 * pow(ra / asp, 0.272)
        if ra > 5.0e4:
            Nu1 = 0.0673838 * pow(ra, 1.0 / 3.0)
        elif 1.0e4 < ra <= 5.0e4:
            Nu1 = 0.028154 * pow(ra, 0.4134)
        else:
            Nu1 = 1.0 + 1.7596678e-10 * pow(ra, 2.2984755)
        gnu = max(Nu1, Nu2)
        gnu = 1.0 + (gnu - 1.0) * math.sin(tiltr)
    else:
        nperr = 10
        ErrorMessage = "Window tilt angle is out of range."
    
    return gnu, nperr, ErrorMessage

def storeIterationResults(state: EnergyPlusData, files: Files, nlayer: int, index: int,
                          theta: List[float], trmout: float, tamb: float, trmin: float,
                          troom: float, ebsky: float, ebroom: float, hcin: float,
                          hcout: float, hrin: float, hrout: float, hin: float, hout: float,
                          Ebb: List[float], Ebf: List[float], Rb: List[float],
                          Rf: List[float]) -> None:
    """Store iteration results for debugging."""
    pass

def CalculateFuncResults(nlayer: int, a: List[List[float]], b: List[float],
                         x: List[float]) -> List[float]:
    """Calculate function results."""
    nlayer4 = 4 * nlayer
    FRes = [0.0] * (nlayer4 + 1)
    
    for i in range(1, nlayer4 + 1):
        FRes[i] = -b[i]
    
    for j in range(1, nlayer4 + 1):
        x_j = x[j]
        for i in range(1, nlayer4 + 1):
            FRes[i] += a[j][i] * x_j
    
    return FRes
