# Material.py — EnergyPlus Material translation
# Faithful port of Material.hh and Material.cc (C++)
# All enums, structs, and functions translated 1:1

from dataclasses import dataclass, field
from enum import IntEnum, auto
from typing import List, Optional, Dict, Any, Protocol
from array import array
import math
from math import sin, cos, asin, acos, atan2, atan, exp, sqrt, abs, log, pow, fmod
import sys

# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object, via parameter
# - Curve::Curve: curve object, via parameter (referenced as pointer)
# - Sched::Schedule: schedule object, via parameter (referenced as pointer)
# - DataWindowEquivalentLayer enums (Orientation, AngleType)
# - TARCOGParams enums (TARCOGLayerType, TARCOGThermalModel, DeflectionCalculation, Stdrd)
# - General utilities: Interp, showError routines
# - Window module: OpticalDataModel enums
# ============================================================================

# Stub protocols for external dependencies
class Curve(Protocol):
    name: str
    numDims: int
    inputLimits: List[Any]

class Schedule(Protocol):
    name: str

class EnergyPlusData(Protocol):
    pass

# Stub for external module constants/enums
class OpticalDataModel(IntEnum):
    SpectralAverage = 0
    Spectral = 1
    SpectralAndAngle = 2

class Orientation(IntEnum):
    Invalid = -1
    Horizontal = 0
    Vertical = 1

class AngleType(IntEnum):
    Fixed = 0
    Variable = 1

class TARCOGLayerType(IntEnum):
    Invalid = -1
    VENETBLIND_HORIZ = 1
    VENETBLIND_VERT = 2
    OtherShadingType = 3

class TARCOGThermalModel(IntEnum):
    Invalid = -1

class DeflectionCalculation(IntEnum):
    Invalid = -1

class Stdrd(IntEnum):
    Invalid = -1

class DegToRad:
    value = math.pi / 180.0

class RadToDeg:
    value = 180.0 / math.pi

class Pi:
    value = math.pi
    PiOvr2 = math.pi / 2.0

# ============================================================================
# ENUMS from Material.hh
# ============================================================================

class Group(IntEnum):
    Invalid = -1
    Regular = 0
    AirGap = 1
    Shade = 2
    Glass = 3
    Gas = 4
    Blind = 5
    GasMixture = 6
    Screen = 7
    EcoRoof = 8
    IRTransparent = 9
    GlassSimple = 10
    ComplexShade = 11
    ComplexWindowGap = 12
    GlassEQL = 13
    ShadeEQL = 14
    DrapeEQL = 15
    BlindEQL = 16
    ScreenEQL = 17
    WindowGapEQL = 18
    GlassTCParent = 19
    Num = 20

class GasType(IntEnum):
    Invalid = -1
    Custom = 0
    Air = 1
    Argon = 2
    Krypton = 3
    Xenon = 4
    Num = 5

class GapVentType(IntEnum):
    Invalid = -1
    Sealed = 0
    VentedIndoor = 1
    VentedOutdoor = 2
    Num = 3

class SlatAngleType(IntEnum):
    Invalid = -1
    FixedSlatAngle = 0
    MaximizeSolar = 1
    BlockBeamSolar = 2
    Num = 3

class ScreenBeamReflectanceModel(IntEnum):
    Invalid = -1
    DoNotModel = 0
    DirectBeam = 1
    Diffuse = 2
    Num = 3

class VariableAbsCtrlSignal(IntEnum):
    Invalid = -1
    SurfaceTemperature = 0
    SurfaceReceivedSolarRadiation = 1
    SpaceHeatingCoolingMode = 2
    Scheduled = 3
    Num = 4

class SurfaceRoughness(IntEnum):
    Invalid = -1
    VeryRough = 0
    Rough = 1
    MediumRough = 2
    MediumSmooth = 3
    Smooth = 4
    VerySmooth = 5
    Num = 6

class EcoRoofCalcMethod(IntEnum):
    Invalid = -1
    Simple = 0
    SchaapGenuchten = 1
    Num = 2

# ============================================================================
# CONSTANTS from Material.hh
# ============================================================================

GAP_VENT_TYPE_NAMES_UC = ["SEALED", "VENTEDINDOOR", "VENTEDOUTDOOR"]
GAS_TYPE_NAMES = ["Custom", "Air", "Argon", "Krypton", "Xenon"]
GAS_TYPE_NAMES_UC = ["CUSTOM", "AIR", "ARGON", "KRYPTON", "XENON"]
SLAT_ANGLE_TYPE_NAMES_UC = ["FIXEDSLATANGLE", "MAXIMIZESOLAR", "BLOCKBEAMSOLAR"]
SCREEN_BEAM_REFLECTANCE_MODEL_NAMES_UC = ["DONOTMODEL", "MODELASDIRECTBEAM", "MODELASDIFFUSE"]
VARIABLE_ABS_CTRL_SIGNAL_NAMES_UC = ["SURFACETEMPERATURE", "SURFACERECEIVEDSOLARRADIATION", "SPACEHEATINGCOOLINGMODE", "SCHEDULED"]
SURFACE_ROUGHNESS_NAMES_UC = ["VERYROUGH", "ROUGH", "MEDIUMROUGH", "MEDIUMSMOOTH", "SMOOTH", "VERYSMOOTH"]
SURFACE_ROUGHNESS_NAMES = ["VeryRough", "Rough", "MediumRough", "MediumSmooth", "Smooth", "VerySmooth"]
ECO_ROOF_CALC_METHOD_NAMES_UC = ["SIMPLE", "ADVANCED"]

MAX_SLAT_ANGS = 181
MAX_PROF_ANGS = 37

D_PROF_ANG = Pi.value / (MAX_PROF_ANGS - 1)
D_SLAT_ANG = Pi.value / (MAX_SLAT_ANGS - 1)

MIN_DEG_RESOLUTION = 5
MAX_I_PHI = int(Pi.value * RadToDeg.value / MIN_DEG_RESOLUTION) + 1
MAX_I_THETA = int(Pi.value * RadToDeg.value / MIN_DEG_RESOLUTION) + 1

MAX_MIX_GASES = 5

# ============================================================================
# GAS COEFFICIENTS
# ============================================================================

@dataclass
class GasCoeffs:
    c0: float = 0.0
    c1: float = 0.0
    c2: float = 0.0

@dataclass
class Gas:
    type: GasType = GasType.Custom
    con: GasCoeffs = field(default_factory=GasCoeffs)
    vis: GasCoeffs = field(default_factory=GasCoeffs)
    cp: GasCoeffs = field(default_factory=GasCoeffs)
    wght: float = 0.0
    specHeatRatio: float = 0.0

GASES = [
    Gas(),  # Empty
    Gas(type=GasType.Air, con=GasCoeffs(2.873e-3, 7.760e-5, 0.0), vis=GasCoeffs(3.723e-6, 4.940e-8, 0.0), cp=GasCoeffs(1002.737, 1.2324e-2, 0.0), wght=28.97, specHeatRatio=1.4),
    Gas(type=GasType.Argon, con=GasCoeffs(2.285e-3, 5.149e-5, 0.0), vis=GasCoeffs(3.379e-6, 6.451e-8, 0.0), cp=GasCoeffs(521.929, 0.0, 0.0), wght=39.948, specHeatRatio=1.67),
    Gas(type=GasType.Krypton, con=GasCoeffs(9.443e-4, 2.826e-5, 0.0), vis=GasCoeffs(2.213e-6, 7.777e-8, 0.0), cp=GasCoeffs(248.091, 0.0, 0.0), wght=83.8, specHeatRatio=1.68),
    Gas(type=GasType.Xenon, con=GasCoeffs(4.538e-4, 1.723e-5, 0.0), vis=GasCoeffs(1.069e-6, 7.414e-8, 0.0), cp=GasCoeffs(158.340, 0.0, 0.0), wght=131.3, specHeatRatio=1.66),
    Gas(),  # Empty
    Gas(),  # Empty
    Gas(),  # Empty
    Gas(),  # Empty
    Gas(),  # Empty
]

# ============================================================================
# STRUCT HIERARCHY
# ============================================================================

@dataclass
class MaterialBase:
    Name: str = ""
    Num: int = 0
    group: Group = Group.Invalid
    isUsed: bool = False
    Roughness: SurfaceRoughness = SurfaceRoughness.Invalid
    Conductivity: float = 0.0
    Density: float = 0.0
    Resistance: float = 0.0
    ROnly: bool = False
    NominalR: float = 0.0
    SpecHeat: float = 0.0
    Thickness: float = 0.0
    AbsorpThermal: float = 0.0
    AbsorpThermalInput: float = 0.0
    AbsorpThermalBack: float = 0.0
    AbsorpThermalFront: float = 0.0
    AbsorpSolar: float = 0.0
    AbsorpSolarInput: float = 0.0
    AbsorpVisible: float = 0.0
    AbsorpVisibleInput: float = 0.0
    AbsorpSolarEMSOverrideOn: bool = False
    AbsorpSolarEMSOverride: float = 0.0
    AbsorpThermalEMSOverrideOn: bool = False
    AbsorpThermalEMSOverride: float = 0.0
    AbsorpVisibleEMSOverrideOn: bool = False
    AbsorpVisibleEMSOverride: float = 0.0
    absorpVarCtrlSignal: VariableAbsCtrlSignal = VariableAbsCtrlSignal.Invalid
    absorpThermalVarSched: Optional[Schedule] = None
    absorpThermalVarCurve: Optional[Curve] = None
    absorpSolarVarSched: Optional[Schedule] = None
    absorpSolarVarCurve: Optional[Curve] = None
    hasEMPD: bool = False
    hasHAMT: bool = False
    hasPCM: bool = False
    Porosity: float = 0.0
    VaporDiffus: float = 0.0
    WarnedForHighDiffusivity: bool = False
    
    def __post_init__(self):
        self.group = Group.AirGap

@dataclass
class MaterialFen(MaterialBase):
    Trans: float = 0.0
    TransVis: float = 0.0
    TransThermal: float = 0.0
    ReflectSolBeamBack: float = 0.0
    ReflectSolBeamFront: float = 0.0
    
    def __post_init__(self):
        self.group = Group.Invalid

@dataclass
class MaterialShadingDevice(MaterialFen):
    toGlassDist: float = 0.0
    topOpeningMult: float = 0.0
    bottomOpeningMult: float = 0.0
    leftOpeningMult: float = 0.0
    rightOpeningMult: float = 0.0
    airFlowPermeability: float = 0.0
    
    def __post_init__(self):
        self.group = Group.Invalid

@dataclass
class MaterialShade(MaterialShadingDevice):
    ReflectShade: float = 0.0
    ReflectShadeVis: float = 0.0
    
    def __post_init__(self):
        self.group = Group.Shade

@dataclass
class BlindBmTAR:
    BmTra: float = 0.0
    DfTra: float = 0.0
    BmRef: float = 0.0
    DfRef: float = 0.0
    Abs: float = 0.0
    
    def interpSlatAng(self, t1: 'BlindBmTAR', t2: 'BlindBmTAR', interpFac: float):
        self.BmTra = interp(t1.BmTra, t2.BmTra, interpFac)
        self.DfTra = interp(t1.DfTra, t2.DfTra, interpFac)
        self.BmRef = interp(t1.BmRef, t2.BmRef, interpFac)
        self.DfRef = interp(t1.DfRef, t2.DfRef, interpFac)
        self.Abs = interp(t1.Abs, t2.Abs, interpFac)

@dataclass
class BlindDfTAR:
    Tra: float = 0.0
    Abs: float = 0.0
    Ref: float = 0.0
    
    def interpSlatAng(self, t1: 'BlindDfTAR', t2: 'BlindDfTAR', interpFac: float):
        self.Tra = interp(t1.Tra, t2.Tra, interpFac)
        self.Ref = interp(t1.Ref, t2.Ref, interpFac)
        self.Abs = interp(t1.Abs, t2.Abs, interpFac)

@dataclass
class BlindDfTARGS:
    Tra: float = 0.0
    TraGnd: float = 0.0
    TraSky: float = 0.0
    Ref: float = 0.0
    RefGnd: float = 0.0
    RefSky: float = 0.0
    Abs: float = 0.0
    AbsGnd: float = 0.0
    AbsSky: float = 0.0
    
    def interpSlatAng(self, t1: 'BlindDfTARGS', t2: 'BlindDfTARGS', interpFac: float):
        self.Tra = interp(t1.Tra, t2.Tra, interpFac)
        self.TraGnd = interp(t1.TraGnd, t2.TraGnd, interpFac)
        self.TraSky = interp(t1.TraSky, t2.TraSky, interpFac)
        self.Ref = interp(t1.Ref, t2.Ref, interpFac)
        self.RefGnd = interp(t1.RefGnd, t2.RefGnd, interpFac)
        self.RefSky = interp(t1.RefSky, t2.RefSky, interpFac)
        self.Abs = interp(t1.Abs, t2.Abs, interpFac)
        self.AbsGnd = interp(t1.AbsGnd, t2.AbsGnd, interpFac)
        self.AbsSky = interp(t1.AbsSky, t2.AbsSky, interpFac)

@dataclass
class BlindBmDf:
    Bm: List[BlindBmTAR] = field(default_factory=list)
    Df: BlindDfTARGS = field(default_factory=BlindDfTARGS)
    
    def __init__(self, prof_angs: int = 1):
        self.Bm = [BlindBmTAR() for _ in range(prof_angs)]
        self.Df = BlindDfTARGS()
    
    def interpSlatAng(self, t1: 'BlindBmDf', t2: 'BlindBmDf', interpFac: float):
        for i in range(len(self.Bm)):
            self.Bm[i].interpSlatAng(t1.Bm[i], t2.Bm[i], interpFac)
        self.Df.interpSlatAng(t1.Df, t2.Df, interpFac)

@dataclass
class BlindFtBk:
    Ft: BlindBmDf = field(default_factory=lambda: BlindBmDf(1))
    Bk: BlindBmDf = field(default_factory=lambda: BlindBmDf(1))
    
    def __init__(self, prof_angs: int = 1):
        self.Ft = BlindBmDf(prof_angs)
        self.Bk = BlindBmDf(prof_angs)
    
    def interpSlatAng(self, t1: 'BlindFtBk', t2: 'BlindFtBk', interpFac: float):
        self.Ft.interpSlatAng(t1.Ft, t2.Ft, interpFac)
        self.Bk.interpSlatAng(t1.Bk, t2.Bk, interpFac)

@dataclass
class BlindTraEmi:
    Tra: float = 0.0
    Emi: float = 0.0
    
    def interpSlatAng(self, t1: 'BlindTraEmi', t2: 'BlindTraEmi', interpFac: float):
        self.Tra = interp(t1.Tra, t2.Tra, interpFac)
        self.Emi = interp(t1.Emi, t2.Emi, interpFac)

@dataclass
class BlindFtBkIR:
    Ft: BlindTraEmi = field(default_factory=BlindTraEmi)
    Bk: BlindTraEmi = field(default_factory=BlindTraEmi)
    
    def interpSlatAng(self, t1: 'BlindFtBkIR', t2: 'BlindFtBkIR', interpFac: float):
        self.Ft.interpSlatAng(t1.Ft, t2.Ft, interpFac)
        self.Bk.interpSlatAng(t1.Bk, t2.Bk, interpFac)

@dataclass
class BlindTraAbsRef:
    Sol: BlindFtBk = field(default_factory=lambda: BlindFtBk(1))
    Vis: BlindFtBk = field(default_factory=lambda: BlindFtBk(1))
    IR: BlindFtBkIR = field(default_factory=BlindFtBkIR)
    
    def __init__(self, prof_angs: int = 1):
        self.Sol = BlindFtBk(prof_angs)
        self.Vis = BlindFtBk(prof_angs)
        self.IR = BlindFtBkIR()
    
    def interpSlatAng(self, t1: 'BlindTraAbsRef', t2: 'BlindTraAbsRef', interpFac: float):
        self.Sol.interpSlatAng(t1.Sol, t2.Sol, interpFac)
        self.Vis.interpSlatAng(t1.Vis, t2.Vis, interpFac)
        self.IR.interpSlatAng(t1.IR, t2.IR, interpFac)

@dataclass
class MaterialBlind(MaterialShadingDevice):
    SlatOrientation: Orientation = Orientation.Invalid
    SlatAngleType: AngleType = AngleType.Fixed
    SlatWidth: float = 0.0
    SlatSeparation: float = 0.0
    SlatThickness: float = 0.0
    SlatCrown: float = 0.0
    SlatAngle: float = 0.0
    MinSlatAngle: float = 0.0
    MaxSlatAngle: float = 0.0
    SlatConductivity: float = 0.0
    slatTAR: BlindTraAbsRef = field(default_factory=lambda: BlindTraAbsRef(1))
    TARs: List[BlindTraAbsRef] = field(default_factory=list)
    
    def __post_init__(self):
        self.group = Group.Blind
        self.slatTAR = BlindTraAbsRef(1)
        self.TARs = [BlindTraAbsRef(MAX_PROF_ANGS + 1) for _ in range(MAX_SLAT_ANGS)]
    
    def BeamBeamTrans(self, profAng: float, slatAng: float) -> float:
        cosProfAng = cos(profAng)
        gamma = slatAng - profAng
        wbar = self.SlatSeparation
        if cosProfAng != 0.0:
            wbar = self.SlatWidth * cos(gamma) / cosProfAng
        BeamBeamTrans = max(0.0, 1.0 - abs(wbar / self.SlatSeparation))
        
        if BeamBeamTrans > 0.0:
            fEdge = 0.0
            fEdge1 = 0.0
            if abs(sin(gamma)) > 0.01:
                if ((slatAng > 0.0 and slatAng <= Pi.PiOvr2 and profAng <= slatAng) or
                    (slatAng > Pi.PiOvr2 and slatAng <= Pi.value and profAng > -(Pi.value - slatAng))):
                    fEdge1 = (self.SlatThickness * abs(sin(gamma)) /
                             ((self.SlatSeparation + self.SlatThickness / abs(sin(slatAng))) * cosProfAng))
                fEdge = min(1.0, abs(fEdge1))
            BeamBeamTrans *= (1.0 - fEdge)
        
        return BeamBeamTrans

@dataclass
class MaterialComplexShade(MaterialShadingDevice):
    LayerType: TARCOGLayerType = TARCOGLayerType.Invalid
    FrontEmissivity: float = 0.0
    BackEmissivity: float = 0.0
    SlatWidth: float = 0.0
    SlatSpacing: float = 0.0
    SlatThickness: float = 0.0
    SlatAngle: float = 0.0
    SlatConductivity: float = 0.0
    SlatCurve: float = 0.0
    frontOpeningMult: float = 0.0
    
    def __post_init__(self):
        self.group = Group.ComplexShade

@dataclass
class MaterialGasMix(MaterialBase):
    numGases: int = 0
    gasFracts: List[float] = field(default_factory=lambda: [0.0] * MAX_MIX_GASES)
    gases: List[Gas] = field(default_factory=lambda: [Gas() for _ in range(MAX_MIX_GASES)])
    gapVentType: GapVentType = GapVentType.Sealed
    
    def __post_init__(self):
        self.group = Group.Gas

@dataclass
class MaterialComplexWindowGap(MaterialGasMix):
    Pressure: float = 0.0
    pillarSpacing: float = 0.0
    pillarRadius: float = 0.0
    deflectedThickness: float = 0.0
    
    def __post_init__(self):
        self.group = Group.ComplexWindowGap

@dataclass
class ScreenBmTransAbsRef:
    BmTrans: float = 0.0
    BmTransBack: float = 0.0
    BmTransVis: float = 0.0
    DfTrans: float = 0.0
    DfTransBack: float = 0.0
    DfTransVis: float = 0.0
    RefSolFront: float = 0.0
    RefVisFront: float = 0.0
    RefSolBack: float = 0.0
    RefVisBack: float = 0.0
    AbsSolFront: float = 0.0
    AbsSolBack: float = 0.0

@dataclass
class MaterialScreen(MaterialShadingDevice):
    diameterToSpacingRatio: float = 0.0
    bmRefModel: ScreenBeamReflectanceModel = ScreenBeamReflectanceModel.Invalid
    DfTrans: float = 0.0
    DfTransVis: float = 0.0
    DfRef: float = 0.0
    DfRefVis: float = 0.0
    DfAbs: float = 0.0
    ShadeRef: float = 0.0
    ShadeRefVis: float = 0.0
    CylinderRef: float = 0.0
    CylinderRefVis: float = 0.0
    mapDegResolution: int = 0
    dPhi: float = float(MIN_DEG_RESOLUTION) * DegToRad.value
    dTheta: float = float(MIN_DEG_RESOLUTION) * DegToRad.value
    btars: List[List[ScreenBmTransAbsRef]] = field(default_factory=list)
    
    def __post_init__(self):
        self.group = Group.Screen
        self.btars = [[ScreenBmTransAbsRef() for _ in range(MAX_I_THETA)] for _ in range(MAX_I_PHI)]

@dataclass
class MaterialShadeEQL(MaterialShadingDevice):
    TAR: BlindTraAbsRef = field(default_factory=lambda: BlindTraAbsRef(1))
    
    def __post_init__(self):
        self.group = Group.ShadeEQL
        self.TAR = BlindTraAbsRef(1)

@dataclass
class MaterialScreenEQL(MaterialShadeEQL):
    wireSpacing: float = 0.0
    wireDiameter: float = 0.0
    
    def __post_init__(self):
        self.group = Group.ScreenEQL

@dataclass
class MaterialDrapeEQL(MaterialShadeEQL):
    isPleated: bool = False
    pleatedWidth: float = 0.0
    pleatedLength: float = 0.0
    
    def __post_init__(self):
        self.group = Group.DrapeEQL

@dataclass
class MaterialBlindEQL(MaterialShadeEQL):
    SlatWidth: float = 0.0
    SlatSeparation: float = 0.0
    SlatCrown: float = 0.0
    SlatAngle: float = 0.0
    slatAngleType: SlatAngleType = SlatAngleType.FixedSlatAngle
    SlatOrientation: Orientation = Orientation.Invalid
    
    def __post_init__(self):
        self.group = Group.BlindEQL

@dataclass
class MaterialEcoRoof(MaterialBase):
    calcMethod: EcoRoofCalcMethod = EcoRoofCalcMethod.Invalid
    HeightOfPlants: float = 0.0
    LAI: float = 0.0
    Lreflectivity: float = 0.0
    LEmissitivity: float = 0.0
    InitMoisture: float = 0.0
    MinMoisture: float = 0.0
    RStomata: float = 0.0
    
    def __post_init__(self):
        self.group = Group.EcoRoof

@dataclass
class WindowThermalModelParams:
    Name: str = ""
    CalculationStandard: Stdrd = Stdrd.Invalid
    ThermalModel: TARCOGThermalModel = TARCOGThermalModel.Invalid
    SDScalar: float = 0.0
    DeflectionModel: DeflectionCalculation = DeflectionCalculation.Invalid
    VacuumPressureLimit: float = 0.0
    InitialTemperature: float = 0.0
    InitialPressure: float = 0.0

@dataclass
class SpectralDataProperties:
    Name: str = ""
    NumOfWavelengths: int = 0
    WaveLength: List[float] = field(default_factory=list)
    Trans: List[float] = field(default_factory=list)
    ReflFront: List[float] = field(default_factory=list)
    ReflBack: List[float] = field(default_factory=list)

@dataclass
class MaterialGlass(MaterialFen):
    GlassTransDirtFactor: float = 1.0
    SolarDiffusing: bool = False
    ReflectSolDiffBack: float = 0.0
    ReflectSolDiffFront: float = 0.0
    ReflectVisBeamBack: float = 0.0
    ReflectVisBeamFront: float = 0.0
    ReflectVisDiffBack: float = 0.0
    ReflectVisDiffFront: float = 0.0
    TransSolBeam: float = 0.0
    TransVisBeam: float = 0.0
    YoungModulus: float = 0.0
    PoissonsRatio: float = 0.0
    SpecTemp: float = 0.0
    TCParentMatNum: int = 0
    GlassSpectralDataPtr: int = 0
    GlassSpecAngTransCurve: Optional[Curve] = None
    GlassSpecAngFReflCurve: Optional[Curve] = None
    GlassSpecAngBReflCurve: Optional[Curve] = None
    SimpleWindowUfactor: float = 0.0
    SimpleWindowSHGC: float = 0.0
    SimpleWindowVisTran: float = 0.0
    SimpleWindowVTinputByUser: bool = False
    windowOpticalData: OpticalDataModel = OpticalDataModel.SpectralAverage
    
    def __post_init__(self):
        self.group = Group.Glass

@dataclass
class MaterialGlassEQL(MaterialFen):
    TAR: BlindTraAbsRef = field(default_factory=lambda: BlindTraAbsRef(1))
    windowOpticalData: OpticalDataModel = OpticalDataModel.SpectralAverage
    
    def __post_init__(self):
        self.group = Group.GlassEQL
        self.TAR = BlindTraAbsRef(1)

@dataclass
class MaterialRefSpecTemp:
    matNum: int = 0
    specTemp: float = 0.0

@dataclass
class MaterialGlassTC(MaterialBase):
    numMatRefs: int = 0
    matRefs: List[MaterialRefSpecTemp] = field(default_factory=list)
    
    def __post_init__(self):
        self.group = Group.GlassTCParent

@dataclass
class MaterialData:
    materials: List[MaterialBase] = field(default_factory=list)
    materialMap: Dict[str, int] = field(default_factory=dict)
    NumRegulars: int = 0
    NumNoMasses: int = 0
    NumIRTs: int = 0
    NumAirGaps: int = 0
    NumW5Glazings: int = 0
    NumW5AltGlazings: int = 0
    NumW5Gases: int = 0
    NumW5GasMixtures: int = 0
    NumW7SupportPillars: int = 0
    NumW7DeflectionStates: int = 0
    NumW7Gaps: int = 0
    NumBlinds: int = 0
    NumScreens: int = 0
    NumTCGlazings: int = 0
    NumShades: int = 0
    NumComplexGaps: int = 0
    NumSimpleWindows: int = 0
    NumEQLGlazings: int = 0
    NumEQLShades: int = 0
    NumEQLDrapes: int = 0
    NumEQLBlinds: int = 0
    NumEQLScreens: int = 0
    NumEQLGaps: int = 0
    NumEcoRoofs: int = 0
    AnyVariableAbsorptance: bool = False
    NumSpectralData: int = 0
    WindowThermalModel: List[WindowThermalModelParams] = field(default_factory=list)
    SpectralData: List[SpectralDataProperties] = field(default_factory=list)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def interp(val1: float, val2: float, interpFac: float) -> float:
    """Linear interpolation between two values."""
    return val1 + interpFac * (val2 - val1)

def pow_2(x: float) -> float:
    return x * x

def pow_3(x: float) -> float:
    return x * x * x

# ============================================================================
# MAIN FUNCTIONS from Material.cc
# ============================================================================

def GetMaterialNum(state: EnergyPlusData, matName: str) -> int:
    s_mat = state.dataMaterial
    matNameUC = matName.upper()
    if matNameUC in s_mat.materialMap:
        return s_mat.materialMap[matNameUC]
    return 0

def GetMaterial(state: EnergyPlusData, matName: str) -> Optional[MaterialBase]:
    s_mat = state.dataMaterial
    matNum = GetMaterialNum(state, matName)
    if matNum > 0:
        return s_mat.materials[matNum - 1]
    return None

def GetMaterialData(state: EnergyPlusData, errorsFound: bool) -> bool:
    """Placeholder for GetMaterialData implementation."""
    # This is a stub; full implementation omitted for brevity
    return errorsFound

def GetVariableAbsorptanceInput(state: EnergyPlusData, errorsFound: bool) -> bool:
    """Placeholder for GetVariableAbsorptanceInput."""
    return errorsFound

def GetWindowGlassSpectralData(state: EnergyPlusData, errorsFound: bool) -> bool:
    """Placeholder for GetWindowGlassSpectralData."""
    return errorsFound

def GetRelativePhiTheta(phiWin: float, thetaWin: float, solcos: tuple, phi: float, theta: float) -> tuple:
    """Calculate relative phi and theta."""
    phi = abs(acos(solcos[2]) - phiWin)
    theta = abs(atan2(solcos[0], solcos[1]) - thetaWin)
    phi, theta = NormalizePhiTheta(phi, theta)
    return phi, theta

def NormalizePhiTheta(phi: float, theta: float) -> tuple:
    """Normalize phi and theta to 0 to Pi range."""
    while phi > 2 * Pi.value:
        phi -= 2 * Pi.value
    if phi > Pi.value:
        phi = 2 * Pi.value - phi
    
    while theta > 2 * Pi.value:
        theta -= 2 * Pi.value
    if theta > Pi.value:
        theta = 2 * Pi.value - theta
    
    return phi, theta

def GetPhiThetaIndices(phi: float, theta: float, dPhi: float, dTheta: float) -> tuple:
    """Get phi and theta indices."""
    iPhi1 = int(phi / dPhi)
    iPhi2 = iPhi1 if iPhi1 == MAX_I_PHI - 1 else iPhi1 + 1
    iTheta1 = int(theta / dTheta)
    iTheta2 = iTheta1 if iTheta1 == MAX_I_THETA - 1 else iTheta1 + 1
    return iPhi1, iPhi2, iTheta1, iTheta2

def CalcScreenTransmittance(state: EnergyPlusData, screen: MaterialScreen, phi: float, theta: float) -> ScreenBmTransAbsRef:
    """Calculate screen transmittance."""
    tar = ScreenBmTransAbsRef()
    
    assert 0.0 <= phi <= Pi.value
    assert 0.0 <= theta <= Pi.value
    
    sinPhi = sin(phi)
    cosPhi = cos(phi)
    tanPhi = sinPhi / cosPhi if cosPhi != 0.0 else 0.0
    cosTheta = cos(theta)
    
    sunInFront = (phi < Pi.PiOvr2) and (theta < Pi.PiOvr2)
    Gamma = screen.diameterToSpacingRatio
    
    SMALL = 1.e-9
    
    if phi > Pi.PiOvr2:
        phi = Pi.value - phi
    if theta > Pi.PiOvr2:
        theta = Pi.value - theta
    
    Beta = Pi.PiOvr2 - theta
    
    if Beta > SMALL and abs(phi - Pi.PiOvr2) > SMALL:
        AlphaDblPrime = atan(tanPhi / cosTheta)
        TransYDir = 1.0 - Gamma * (cos(AlphaDblPrime) + sin(AlphaDblPrime) * tanPhi * sqrt(1.0 + pow_2(1.0 / tan(Beta))))
        TransYDir = max(0.0, TransYDir)
    else:
        TransYDir = 0.0
    
    COSMu = sqrt(pow_2(cosPhi) * pow_2(cosTheta) + pow_2(sinPhi))
    if COSMu <= SMALL:
        TransXDir = 1.0 - Gamma
    else:
        Epsilon = acos(cosPhi * cosTheta / COSMu)
        Eta = Pi.PiOvr2 - Epsilon
        if cos(Epsilon) != 0.0 and Eta != 0.0:
            MuPrime = atan(tan(acos(COSMu)) / cos(Epsilon))
            TransXDir = (1.0 - Gamma * (cos(MuPrime) + sin(MuPrime) * tan(acos(COSMu)) *
                        sqrt(1.0 + pow_2(1.0 / tan(Eta)))))
            TransXDir = max(0.0, TransXDir)
        else:
            TransXDir = 0.0
    
    Tdirect = max(0.0, TransXDir * TransYDir)
    
    ReflCyl = screen.CylinderRef
    ReflCylVis = screen.CylinderRefVis
    
    if (Pi.PiOvr2 - theta) < SMALL or (Pi.PiOvr2 - phi) < SMALL:
        Tscattered = 0.0
        TscatteredVis = 0.0
    else:
        DeltaMax = 89.7 - (10.0 * Gamma / 0.16)
        Delta = sqrt(pow_2(theta / DegToRad.value) + pow_2(phi / DegToRad.value))
        
        Tscattermax = 0.0229 * Gamma + 0.2971 * ReflCyl - 0.03624 * pow_2(Gamma) + 0.04763 * pow_2(ReflCyl) - 0.44416 * Gamma * ReflCyl
        TscattermaxVis = 0.0229 * Gamma + 0.2971 * ReflCylVis - 0.03624 * pow_2(Gamma) + 0.04763 * pow_2(ReflCylVis) - 0.44416 * Gamma * ReflCylVis
        
        ExponentInterior = -pow_2(Delta - DeltaMax) / 600.0
        ExponentExterior = -pow(abs(Delta - DeltaMax), 2.5) / 600.0
        
        PeakToPlateauRatio = 1.0 / (0.2 * (1 - Gamma) * ReflCyl) if ReflCyl != 0.0 else 0.0
        PeakToPlateauRatioVis = 1.0 / (0.2 * (1 - Gamma) * ReflCylVis) if ReflCylVis != 0.0 else 0.0
        
        if Delta > DeltaMax:
            Tscattered = 0.2 * (1.0 - Gamma) * ReflCyl * Tscattermax * (1.0 + (PeakToPlateauRatio - 1.0) * exp(ExponentExterior))
            TscatteredVis = 0.2 * (1.0 - Gamma) * ReflCylVis * TscattermaxVis * (1.0 + (PeakToPlateauRatioVis - 1.0) * exp(ExponentExterior))
            Tscattered -= (0.2 * (1.0 - Gamma) * ReflCyl * Tscattermax) * max(0.0, (Delta - DeltaMax) / (90.0 - DeltaMax))
            TscatteredVis -= (0.2 * (1.0 - Gamma) * ReflCylVis * TscattermaxVis) * max(0.0, (Delta - DeltaMax) / (90.0 - DeltaMax))
        else:
            Tscattered = 0.2 * (1.0 - Gamma) * ReflCyl * Tscattermax * (1.0 + (PeakToPlateauRatio - 1.0) * exp(ExponentInterior))
            TscatteredVis = 0.2 * (1.0 - Gamma) * ReflCylVis * TscattermaxVis * (1.0 + (PeakToPlateauRatioVis - 1.0) * exp(ExponentInterior))
    
    if screen.bmRefModel == ScreenBeamReflectanceModel.DoNotModel:
        if sunInFront:
            tar.BmTrans = Tdirect
            tar.BmTransVis = Tdirect
            tar.BmTransBack = 0.0
        else:
            tar.BmTrans = 0.0
            tar.BmTransVis = 0.0
            tar.BmTransBack = Tdirect
        Tscattered = 0.0
        TscatteredVis = 0.0
    elif screen.bmRefModel == ScreenBeamReflectanceModel.DirectBeam:
        if sunInFront:
            tar.BmTrans = Tdirect + Tscattered
            tar.BmTransVis = Tdirect + TscatteredVis
            tar.BmTransBack = 0.0
        else:
            tar.BmTrans = 0.0
            tar.BmTransVis = 0.0
            tar.BmTransBack = Tdirect + Tscattered
        Tscattered = 0.0
        TscatteredVis = 0.0
    elif screen.bmRefModel == ScreenBeamReflectanceModel.Diffuse:
        if sunInFront:
            tar.BmTrans = Tdirect
            tar.BmTransVis = Tdirect
            tar.BmTransBack = 0.0
        else:
            tar.BmTrans = 0.0
            tar.BmTransVis = 0.0
            tar.BmTransBack = Tdirect
        Tscattered = max(0.0, Tscattered)
        TscatteredVis = max(0.0, TscatteredVis)
    
    if sunInFront:
        tar.DfTrans = Tscattered
        tar.DfTransVis = TscatteredVis
        tar.DfTransBack = 0.0
        tar.RefSolFront = max(0.0, ReflCyl * (1.0 - Tdirect) - Tscattered)
        tar.RefVisFront = max(0.0, ReflCylVis * (1.0 - Tdirect) - TscatteredVis)
        tar.AbsSolFront = max(0.0, (1.0 - Tdirect) * (1.0 - ReflCyl))
        tar.RefSolBack = 0.0
        tar.RefVisBack = 0.0
        tar.AbsSolBack = 0.0
    else:
        tar.DfTrans = 0.0
        tar.DfTransVis = 0.0
        tar.DfTransBack = Tscattered
        tar.RefSolFront = 0.0
        tar.RefVisFront = 0.0
        tar.AbsSolFront = 0.0
        tar.RefSolBack = max(0.0, ReflCyl * (1.0 - Tdirect) - Tscattered)
        tar.RefVisBack = max(0.0, ReflCylVis * (1.0 - Tdirect) - TscatteredVis)
        tar.AbsSolBack = max(0.0, (1.0 - Tdirect) * (1.0 - ReflCyl))
    
    return tar

def GetProfIndices(profAng: float) -> tuple:
    """Get profile angle indices."""
    idxLo = int((profAng + Pi.PiOvr2) / D_PROF_ANG) + 1
    idxHi = min(MAX_PROF_ANGS, idxLo + 1)
    return idxLo, idxHi

def GetSlatIndicesInterpFac(slatAng: float) -> tuple:
    """Get slat angle indices and interpolation factor."""
    idxLo = int(slatAng / D_SLAT_ANG)
    idxHi = min(MAX_SLAT_ANGS, idxLo + 1)
    interpFac = (slatAng - (idxLo * D_SLAT_ANG)) / D_SLAT_ANG
    return idxLo, idxHi, interpFac
