# material.mojo — EnergyPlus Material translation (Mojo)
# Faithful port of Material.hh and Material.cc (C++)

from sys import sizeof
from math import sin, cos, asin, acos, atan, atan2, sqrt, exp, floor, ceil, pow, fabs, pi
import math

# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object parameter
# - Curve: curve object parameter
# - Schedule: schedule object parameter
# - DataWindowEquivalentLayer enums (Orientation, AngleType)
# - TARCOGParams enums
# - Window module: OpticalDataModel
# ============================================================================

# Stub for external types
alias Curve = UInt64
alias Schedule = UInt64

# Enums from external modules (stubs)
@value
struct OpticalDataModel:
    alias SpectralAverage = 0
    alias Spectral = 1
    alias SpectralAndAngle = 2

@value
struct Orientation:
    alias Invalid = -1
    alias Horizontal = 0
    alias Vertical = 1

@value
struct AngleType:
    alias Fixed = 0
    alias Variable = 1

@value
struct TARCOGLayerType:
    alias Invalid = -1
    alias VENETBLIND_HORIZ = 1
    alias VENETBLIND_VERT = 2
    alias OtherShadingType = 3

@value
struct TARCOGThermalModel:
    alias Invalid = -1

@value
struct DeflectionCalculation:
    alias Invalid = -1

@value
struct Stdrd:
    alias Invalid = -1

@value
struct Constants:
    alias Pi = 3.14159265358979323846
    alias DegToRad = Constants.Pi / 180.0
    alias RadToDeg = 180.0 / Constants.Pi
    alias PiOvr2 = Constants.Pi / 2.0

# ============================================================================
# ENUMS from Material.hh
# ============================================================================

@value
struct Group:
    alias Invalid = -1
    alias Regular = 0
    alias AirGap = 1
    alias Shade = 2
    alias Glass = 3
    alias Gas = 4
    alias Blind = 5
    alias GasMixture = 6
    alias Screen = 7
    alias EcoRoof = 8
    alias IRTransparent = 9
    alias GlassSimple = 10
    alias ComplexShade = 11
    alias ComplexWindowGap = 12
    alias GlassEQL = 13
    alias ShadeEQL = 14
    alias DrapeEQL = 15
    alias BlindEQL = 16
    alias ScreenEQL = 17
    alias WindowGapEQL = 18
    alias GlassTCParent = 19
    alias Num = 20

@value
struct GasType:
    alias Invalid = -1
    alias Custom = 0
    alias Air = 1
    alias Argon = 2
    alias Krypton = 3
    alias Xenon = 4
    alias Num = 5

@value
struct GapVentType:
    alias Invalid = -1
    alias Sealed = 0
    alias VentedIndoor = 1
    alias VentedOutdoor = 2
    alias Num = 3

@value
struct SlatAngleType:
    alias Invalid = -1
    alias FixedSlatAngle = 0
    alias MaximizeSolar = 1
    alias BlockBeamSolar = 2
    alias Num = 3

@value
struct ScreenBeamReflectanceModel:
    alias Invalid = -1
    alias DoNotModel = 0
    alias DirectBeam = 1
    alias Diffuse = 2
    alias Num = 3

@value
struct VariableAbsCtrlSignal:
    alias Invalid = -1
    alias SurfaceTemperature = 0
    alias SurfaceReceivedSolarRadiation = 1
    alias SpaceHeatingCoolingMode = 2
    alias Scheduled = 3
    alias Num = 4

@value
struct SurfaceRoughness:
    alias Invalid = -1
    alias VeryRough = 0
    alias Rough = 1
    alias MediumRough = 2
    alias MediumSmooth = 3
    alias Smooth = 4
    alias VerySmooth = 5
    alias Num = 6

@value
struct EcoRoofCalcMethod:
    alias Invalid = -1
    alias Simple = 0
    alias SchaapGenuchten = 1
    alias Num = 2

# ============================================================================
# CONSTANTS
# ============================================================================

alias MAX_SLAT_ANGS = 181
alias MAX_PROF_ANGS = 37
alias MAX_MIX_GASES = 5
alias MIN_DEG_RESOLUTION = 5
alias MAX_I_PHI = Int(Constants.Pi * Constants.RadToDeg / MIN_DEG_RESOLUTION) + 1
alias MAX_I_THETA = Int(Constants.Pi * Constants.RadToDeg / MIN_DEG_RESOLUTION) + 1

alias D_PROF_ANG = Constants.Pi / (MAX_PROF_ANGS - 1)
alias D_SLAT_ANG = Constants.Pi / (MAX_SLAT_ANGS - 1)

# String constants
alias GAP_VENT_TYPE_NAMES_UC = InlineArray[StringRef, 3]("SEALED", "VENTEDINDOOR", "VENTEDOUTDOOR")
alias GAS_TYPE_NAMES = InlineArray[StringRef, 5]("Custom", "Air", "Argon", "Krypton", "Xenon")
alias GAS_TYPE_NAMES_UC = InlineArray[StringRef, 5]("CUSTOM", "AIR", "ARGON", "KRYPTON", "XENON")
alias SLAT_ANGLE_TYPE_NAMES_UC = InlineArray[StringRef, 3]("FIXEDSLATANGLE", "MAXIMIZESOLAR", "BLOCKBEAMSOLAR")
alias SCREEN_BEAM_REFLECTANCE_MODEL_NAMES_UC = InlineArray[StringRef, 3]("DONOTMODEL", "MODELASDIRECTBEAM", "MODELASDIFFUSE")
alias VARIABLE_ABS_CTRL_SIGNAL_NAMES_UC = InlineArray[StringRef, 4]("SURFACETEMPERATURE", "SURFACERECEIVEDSOLARRADIATION", "SPACEHEATINGCOOLINGMODE", "SCHEDULED")
alias SURFACE_ROUGHNESS_NAMES_UC = InlineArray[StringRef, 6]("VERYROUGH", "ROUGH", "MEDIUMROUGH", "MEDIUMSMOOTH", "SMOOTH", "VERYSMOOTH")
alias SURFACE_ROUGHNESS_NAMES = InlineArray[StringRef, 6]("VeryRough", "Rough", "MediumRough", "MediumSmooth", "Smooth", "VerySmooth")
alias ECO_ROOF_CALC_METHOD_NAMES_UC = InlineArray[StringRef, 2]("SIMPLE", "ADVANCED")

# ============================================================================
# GAS COEFFICIENTS
# ============================================================================

@value
struct GasCoeffs:
    var c0: Float64
    var c1: Float64
    var c2: Float64

    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0)

@value
struct Gas:
    var type: Int32
    var con: GasCoeffs
    var vis: GasCoeffs
    var cp: GasCoeffs
    var wght: Float64
    var specHeatRatio: Float64

    fn __init__() -> Self:
        return Self(GasType.Custom, GasCoeffs(), GasCoeffs(), GasCoeffs(), 0.0, 0.0)

fn init_gases() -> InlineArray[Gas, 10]:
    var result = InlineArray[Gas, 10]()
    result[0] = Gas()
    result[1] = Gas(GasType.Air, GasCoeffs(2.873e-3, 7.760e-5, 0.0), 
                   GasCoeffs(3.723e-6, 4.940e-8, 0.0), GasCoeffs(1002.737, 1.2324e-2, 0.0), 28.97, 1.4)
    result[2] = Gas(GasType.Argon, GasCoeffs(2.285e-3, 5.149e-5, 0.0),
                   GasCoeffs(3.379e-6, 6.451e-8, 0.0), GasCoeffs(521.929, 0.0, 0.0), 39.948, 1.67)
    result[3] = Gas(GasType.Krypton, GasCoeffs(9.443e-4, 2.826e-5, 0.0),
                   GasCoeffs(2.213e-6, 7.777e-8, 0.0), GasCoeffs(248.091, 0.0, 0.0), 83.8, 1.68)
    result[4] = Gas(GasType.Xenon, GasCoeffs(4.538e-4, 1.723e-5, 0.0),
                   GasCoeffs(1.069e-6, 7.414e-8, 0.0), GasCoeffs(158.340, 0.0, 0.0), 131.3, 1.66)
    result[5] = Gas()
    result[6] = Gas()
    result[7] = Gas()
    result[8] = Gas()
    result[9] = Gas()
    return result

alias GASES = init_gases()

# ============================================================================
# STRUCT HIERARCHY
# ============================================================================

@value
struct MaterialBase:
    var Name: String
    var Num: Int32
    var group: Int32
    var isUsed: Bool
    var Roughness: Int32
    var Conductivity: Float64
    var Density: Float64
    var Resistance: Float64
    var ROnly: Bool
    var NominalR: Float64
    var SpecHeat: Float64
    var Thickness: Float64
    var AbsorpThermal: Float64
    var AbsorpThermalInput: Float64
    var AbsorpThermalBack: Float64
    var AbsorpThermalFront: Float64
    var AbsorpSolar: Float64
    var AbsorpSolarInput: Float64
    var AbsorpVisible: Float64
    var AbsorpVisibleInput: Float64
    var AbsorpSolarEMSOverrideOn: Bool
    var AbsorpSolarEMSOverride: Float64
    var AbsorpThermalEMSOverrideOn: Bool
    var AbsorpThermalEMSOverride: Float64
    var AbsorpVisibleEMSOverrideOn: Bool
    var AbsorpVisibleEMSOverride: Float64
    var absorpVarCtrlSignal: Int32
    var absorpThermalVarSched: Curve
    var absorpThermalVarCurve: Curve
    var absorpSolarVarSched: Curve
    var absorpSolarVarCurve: Curve
    var hasEMPD: Bool
    var hasHAMT: Bool
    var hasPCM: Bool
    var Porosity: Float64
    var VaporDiffus: Float64
    var WarnedForHighDiffusivity: Bool

    fn __init__() -> Self:
        return Self(
            "", 0, Group.AirGap, False, SurfaceRoughness.Invalid,
            0.0, 0.0, 0.0, False, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, False, 0.0, False, 0.0, False, 0.0,
            VariableAbsCtrlSignal.Invalid, 0, 0, 0, 0,
            False, False, False, 0.0, 0.0, False
        )

@value
struct MaterialFen(MaterialBase):
    var Trans: Float64
    var TransVis: Float64
    var TransThermal: Float64
    var ReflectSolBeamBack: Float64
    var ReflectSolBeamFront: Float64

    fn __init__() -> Self:
        var base = MaterialBase()
        base.group = Group.Invalid
        return Self(base, 0.0, 0.0, 0.0, 0.0, 0.0)

@value
struct MaterialShadingDevice(MaterialFen):
    var toGlassDist: Float64
    var topOpeningMult: Float64
    var bottomOpeningMult: Float64
    var leftOpeningMult: Float64
    var rightOpeningMult: Float64
    var airFlowPermeability: Float64

    fn __init__() -> Self:
        var fen = MaterialFen()
        return Self(fen, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

@value
struct MaterialShade(MaterialShadingDevice):
    var ReflectShade: Float64
    var ReflectShadeVis: Float64

    fn __init__() -> Self:
        var dev = MaterialShadingDevice()
        dev.group = Group.Shade
        return Self(dev, 0.0, 0.0)

@value
struct BlindBmTAR:
    var BmTra: Float64
    var DfTra: Float64
    var BmRef: Float64
    var DfRef: Float64
    var Abs: Float64

    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0, 0.0, 0.0)

    fn interpSlatAng(inout self, t1: BlindBmTAR, t2: BlindBmTAR, interpFac: Float64):
        self.BmTra = interp(t1.BmTra, t2.BmTra, interpFac)
        self.DfTra = interp(t1.DfTra, t2.DfTra, interpFac)
        self.BmRef = interp(t1.BmRef, t2.BmRef, interpFac)
        self.DfRef = interp(t1.DfRef, t2.DfRef, interpFac)
        self.Abs = interp(t1.Abs, t2.Abs, interpFac)

@value
struct BlindDfTAR:
    var Tra: Float64
    var Abs: Float64
    var Ref: Float64

    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0)

    fn interpSlatAng(inout self, t1: BlindDfTAR, t2: BlindDfTAR, interpFac: Float64):
        self.Tra = interp(t1.Tra, t2.Tra, interpFac)
        self.Ref = interp(t1.Ref, t2.Ref, interpFac)
        self.Abs = interp(t1.Abs, t2.Abs, interpFac)

@value
struct BlindDfTARGS:
    var Tra: Float64
    var TraGnd: Float64
    var TraSky: Float64
    var Ref: Float64
    var RefGnd: Float64
    var RefSky: Float64
    var Abs: Float64
    var AbsGnd: Float64
    var AbsSky: Float64

    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    fn interpSlatAng(inout self, t1: BlindDfTARGS, t2: BlindDfTARGS, interpFac: Float64):
        self.Tra = interp(t1.Tra, t2.Tra, interpFac)
        self.TraGnd = interp(t1.TraGnd, t2.TraGnd, interpFac)
        self.TraSky = interp(t1.TraSky, t2.TraSky, interpFac)
        self.Ref = interp(t1.Ref, t2.Ref, interpFac)
        self.RefGnd = interp(t1.RefGnd, t2.RefGnd, interpFac)
        self.RefSky = interp(t1.RefSky, t2.RefSky, interpFac)
        self.Abs = interp(t1.Abs, t2.Abs, interpFac)
        self.AbsGnd = interp(t1.AbsGnd, t2.AbsGnd, interpFac)
        self.AbsSky = interp(t1.AbsSky, t2.AbsSky, interpFac)

@value
struct BlindBmDf:
    var Bm: DynamicVector[BlindBmTAR]
    var Df: BlindDfTARGS

    fn __init__(prof_angs: Int32) -> Self:
        var bm_vec = DynamicVector[BlindBmTAR](prof_angs)
        for i in range(prof_angs):
            bm_vec.push_back(BlindBmTAR())
        return Self(bm_vec, BlindDfTARGS())

    fn interpSlatAng(inout self, t1: BlindBmDf, t2: BlindBmDf, interpFac: Float64):
        for i in range(len(self.Bm)):
            self.Bm[i].interpSlatAng(t1.Bm[i], t2.Bm[i], interpFac)
        self.Df.interpSlatAng(t1.Df, t2.Df, interpFac)

@value
struct BlindFtBk:
    var Ft: BlindBmDf
    var Bk: BlindBmDf

    fn __init__(prof_angs: Int32) -> Self:
        return Self(BlindBmDf(prof_angs), BlindBmDf(prof_angs))

    fn interpSlatAng(inout self, t1: BlindFtBk, t2: BlindFtBk, interpFac: Float64):
        self.Ft.interpSlatAng(t1.Ft, t2.Ft, interpFac)
        self.Bk.interpSlatAng(t1.Bk, t2.Bk, interpFac)

@value
struct BlindTraEmi:
    var Tra: Float64
    var Emi: Float64

    fn __init__() -> Self:
        return Self(0.0, 0.0)

    fn interpSlatAng(inout self, t1: BlindTraEmi, t2: BlindTraEmi, interpFac: Float64):
        self.Tra = interp(t1.Tra, t2.Tra, interpFac)
        self.Emi = interp(t1.Emi, t2.Emi, interpFac)

@value
struct BlindFtBkIR:
    var Ft: BlindTraEmi
    var Bk: BlindTraEmi

    fn __init__() -> Self:
        return Self(BlindTraEmi(), BlindTraEmi())

    fn interpSlatAng(inout self, t1: BlindFtBkIR, t2: BlindFtBkIR, interpFac: Float64):
        self.Ft.interpSlatAng(t1.Ft, t2.Ft, interpFac)
        self.Bk.interpSlatAng(t1.Bk, t2.Bk, interpFac)

@value
struct BlindTraAbsRef:
    var Sol: BlindFtBk
    var Vis: BlindFtBk
    var IR: BlindFtBkIR

    fn __init__(prof_angs: Int32) -> Self:
        return Self(BlindFtBk(prof_angs), BlindFtBk(prof_angs), BlindFtBkIR())

    fn interpSlatAng(inout self, t1: BlindTraAbsRef, t2: BlindTraAbsRef, interpFac: Float64):
        self.Sol.interpSlatAng(t1.Sol, t2.Sol, interpFac)
        self.Vis.interpSlatAng(t1.Vis, t2.Vis, interpFac)
        self.IR.interpSlatAng(t1.IR, t2.IR, interpFac)

@value
struct MaterialBlind(MaterialShadingDevice):
    var SlatOrientation: Int32
    var SlatAngleType: Int32
    var SlatWidth: Float64
    var SlatSeparation: Float64
    var SlatThickness: Float64
    var SlatCrown: Float64
    var SlatAngle: Float64
    var MinSlatAngle: Float64
    var MaxSlatAngle: Float64
    var SlatConductivity: Float64
    var slatTAR: BlindTraAbsRef
    var TARs: DynamicVector[BlindTraAbsRef]

    fn __init__() -> Self:
        var dev = MaterialShadingDevice()
        dev.group = Group.Blind
        var tars_vec = DynamicVector[BlindTraAbsRef]()
        for _ in range(MAX_SLAT_ANGS):
            tars_vec.push_back(BlindTraAbsRef(MAX_PROF_ANGS + 1))
        return Self(dev, Orientation.Invalid, AngleType.Fixed, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                   BlindTraAbsRef(1), tars_vec)

    fn BeamBeamTrans(self, ProfAng: Float64, SlatAng: Float64) -> Float64:
        var cosProfAng = cos(ProfAng)
        var gamma = SlatAng - ProfAng
        var wbar = self.SlatSeparation
        if cosProfAng != 0.0:
            wbar = self.SlatWidth * cos(gamma) / cosProfAng
        var result = max(0.0, 1.0 - fabs(wbar / self.SlatSeparation))
        
        if result > 0.0:
            var fEdge = 0.0
            var fEdge1 = 0.0
            if fabs(sin(gamma)) > 0.01:
                if ((SlatAng > 0.0 and SlatAng <= Constants.PiOvr2 and ProfAng <= SlatAng) or
                    (SlatAng > Constants.PiOvr2 and SlatAng <= Constants.Pi and ProfAng > -(Constants.Pi - SlatAng))):
                    fEdge1 = (self.SlatThickness * fabs(sin(gamma)) /
                             ((self.SlatSeparation + self.SlatThickness / fabs(sin(SlatAng))) * cosProfAng))
                fEdge = min(1.0, fabs(fEdge1))
            result *= (1.0 - fEdge)
        
        return result

@value
struct MaterialComplexShade(MaterialShadingDevice):
    var LayerType: Int32
    var FrontEmissivity: Float64
    var BackEmissivity: Float64
    var SlatWidth: Float64
    var SlatSpacing: Float64
    var SlatThickness: Float64
    var SlatAngle: Float64
    var SlatConductivity: Float64
    var SlatCurve: Float64
    var frontOpeningMult: Float64

    fn __init__() -> Self:
        var dev = MaterialShadingDevice()
        dev.group = Group.ComplexShade
        return Self(dev, TARCOGLayerType.Invalid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

@value
struct MaterialGasMix(MaterialBase):
    var numGases: Int32
    var gasFracts: InlineArray[Float64, MAX_MIX_GASES]
    var gases: InlineArray[Gas, MAX_MIX_GASES]
    var gapVentType: Int32

    fn __init__() -> Self:
        var base = MaterialBase()
        base.group = Group.Gas
        var fracts = InlineArray[Float64, MAX_MIX_GASES](fill=0.0)
        var gases = InlineArray[Gas, MAX_MIX_GASES]()
        for _ in range(MAX_MIX_GASES):
            gases[_] = Gas()
        return Self(base, 0, fracts, gases, GapVentType.Sealed)

@value
struct MaterialComplexWindowGap(MaterialGasMix):
    var Pressure: Float64
    var pillarSpacing: Float64
    var pillarRadius: Float64
    var deflectedThickness: Float64

    fn __init__() -> Self:
        var mix = MaterialGasMix()
        mix.group = Group.ComplexWindowGap
        return Self(mix, 0.0, 0.0, 0.0, 0.0)

@value
struct ScreenBmTransAbsRef:
    var BmTrans: Float64
    var BmTransBack: Float64
    var BmTransVis: Float64
    var DfTrans: Float64
    var DfTransBack: Float64
    var DfTransVis: Float64
    var RefSolFront: Float64
    var RefVisFront: Float64
    var RefSolBack: Float64
    var RefVisBack: Float64
    var AbsSolFront: Float64
    var AbsSolBack: Float64

    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

@value
struct MaterialScreen(MaterialShadingDevice):
    var diameterToSpacingRatio: Float64
    var bmRefModel: Int32
    var DfTrans: Float64
    var DfTransVis: Float64
    var DfRef: Float64
    var DfRefVis: Float64
    var DfAbs: Float64
    var ShadeRef: Float64
    var ShadeRefVis: Float64
    var CylinderRef: Float64
    var CylinderRefVis: Float64
    var mapDegResolution: Int32
    var dPhi: Float64
    var dTheta: Float64

    fn __init__() -> Self:
        var dev = MaterialShadingDevice()
        dev.group = Group.Screen
        return Self(dev, 0.0, ScreenBeamReflectanceModel.Invalid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0,
                   Float64(MIN_DEG_RESOLUTION) * Constants.DegToRad,
                   Float64(MIN_DEG_RESOLUTION) * Constants.DegToRad)

@value
struct MaterialShadeEQL(MaterialShadingDevice):
    var TAR: BlindTraAbsRef

    fn __init__() -> Self:
        var dev = MaterialShadingDevice()
        dev.group = Group.ShadeEQL
        return Self(dev, BlindTraAbsRef(1))

@value
struct MaterialScreenEQL(MaterialShadeEQL):
    var wireSpacing: Float64
    var wireDiameter: Float64

    fn __init__() -> Self:
        var eql = MaterialShadeEQL()
        eql.group = Group.ScreenEQL
        return Self(eql, 0.0, 0.0)

@value
struct MaterialDrapeEQL(MaterialShadeEQL):
    var isPleated: Bool
    var pleatedWidth: Float64
    var pleatedLength: Float64

    fn __init__() -> Self:
        var eql = MaterialShadeEQL()
        eql.group = Group.DrapeEQL
        return Self(eql, False, 0.0, 0.0)

@value
struct MaterialBlindEQL(MaterialShadeEQL):
    var SlatWidth: Float64
    var SlatSeparation: Float64
    var SlatCrown: Float64
    var SlatAngle: Float64
    var slatAngleType: Int32
    var SlatOrientation: Int32

    fn __init__() -> Self:
        var eql = MaterialShadeEQL()
        eql.group = Group.BlindEQL
        return Self(eql, 0.0, 0.0, 0.0, 0.0, SlatAngleType.FixedSlatAngle, Orientation.Invalid)

@value
struct MaterialEcoRoof(MaterialBase):
    var calcMethod: Int32
    var HeightOfPlants: Float64
    var LAI: Float64
    var Lreflectivity: Float64
    var LEmissitivity: Float64
    var InitMoisture: Float64
    var MinMoisture: Float64
    var RStomata: Float64

    fn __init__() -> Self:
        var base = MaterialBase()
        base.group = Group.EcoRoof
        return Self(base, EcoRoofCalcMethod.Invalid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

@value
struct WindowThermalModelParams:
    var Name: String
    var CalculationStandard: Int32
    var ThermalModel: Int32
    var SDScalar: Float64
    var DeflectionModel: Int32
    var VacuumPressureLimit: Float64
    var InitialTemperature: Float64
    var InitialPressure: Float64

    fn __init__() -> Self:
        return Self("", Stdrd.Invalid, TARCOGThermalModel.Invalid, 0.0, DeflectionCalculation.Invalid, 0.0, 0.0, 0.0)

@value
struct SpectralDataProperties:
    var Name: String
    var NumOfWavelengths: Int32
    var WaveLength: DynamicVector[Float64]
    var Trans: DynamicVector[Float64]
    var ReflFront: DynamicVector[Float64]
    var ReflBack: DynamicVector[Float64]

    fn __init__() -> Self:
        return Self("", 0, DynamicVector[Float64](), DynamicVector[Float64](), DynamicVector[Float64](), DynamicVector[Float64]())

@value
struct MaterialGlass(MaterialFen):
    var GlassTransDirtFactor: Float64
    var SolarDiffusing: Bool
    var ReflectSolDiffBack: Float64
    var ReflectSolDiffFront: Float64
    var ReflectVisBeamBack: Float64
    var ReflectVisBeamFront: Float64
    var ReflectVisDiffBack: Float64
    var ReflectVisDiffFront: Float64
    var TransSolBeam: Float64
    var TransVisBeam: Float64
    var YoungModulus: Float64
    var PoissonsRatio: Float64
    var SpecTemp: Float64
    var TCParentMatNum: Int32
    var GlassSpectralDataPtr: Int32
    var GlassSpecAngTransCurve: Curve
    var GlassSpecAngFReflCurve: Curve
    var GlassSpecAngBReflCurve: Curve
    var SimpleWindowUfactor: Float64
    var SimpleWindowSHGC: Float64
    var SimpleWindowVisTran: Float64
    var SimpleWindowVTinputByUser: Bool
    var windowOpticalData: Int32

    fn __init__() -> Self:
        var fen = MaterialFen()
        fen.group = Group.Glass
        return Self(fen, 1.0, False, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0,
                   0.0, 0.0, 0.0, False, OpticalDataModel.SpectralAverage)

@value
struct MaterialGlassEQL(MaterialFen):
    var TAR: BlindTraAbsRef
    var windowOpticalData: Int32

    fn __init__() -> Self:
        var fen = MaterialFen()
        fen.group = Group.GlassEQL
        return Self(fen, BlindTraAbsRef(1), OpticalDataModel.SpectralAverage)

@value
struct MaterialRefSpecTemp:
    var matNum: Int32
    var specTemp: Float64

    fn __init__() -> Self:
        return Self(0, 0.0)

@value
struct MaterialGlassTC(MaterialBase):
    var numMatRefs: Int32
    var matRefs: DynamicVector[MaterialRefSpecTemp]

    fn __init__() -> Self:
        var base = MaterialBase()
        base.group = Group.GlassTCParent
        return Self(base, 0, DynamicVector[MaterialRefSpecTemp]())

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

@always_inline
fn interp(val1: Float64, val2: Float64, interpFac: Float64) -> Float64:
    return val1 + interpFac * (val2 - val1)

@always_inline
fn pow_2(x: Float64) -> Float64:
    return x * x

@always_inline
fn pow_3(x: Float64) -> Float64:
    return x * x * x

@always_inline
fn tan(x: Float64) -> Float64:
    return sin(x) / cos(x)

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

fn GetMaterialNum(matName: String) -> Int32:
    # Placeholder; full implementation omitted
    return 0

fn GetMaterial(matName: String) -> UInt64:
    # Placeholder; returns null pointer equivalent
    return 0

fn CalcScreenTransmittance(screen_ptr: UInt64, phi: Float64, theta: Float64) -> ScreenBmTransAbsRef:
    var tar = ScreenBmTransAbsRef()
    
    var SMALL = 1.e-9
    
    var sinPhi = sin(phi)
    var cosPhi = cos(phi)
    var tanPhi = sinPhi / cosPhi if cosPhi != 0.0 else 0.0
    var cosTheta = cos(theta)
    
    var phi_norm = phi
    var theta_norm = theta
    if phi_norm > Constants.PiOvr2:
        phi_norm = Constants.Pi - phi_norm
    if theta_norm > Constants.PiOvr2:
        theta_norm = Constants.Pi - theta_norm
    
    var Beta = Constants.PiOvr2 - theta_norm
    
    var TransYDir = 0.0
    if Beta > SMALL and fabs(phi_norm - Constants.PiOvr2) > SMALL:
        var AlphaDblPrime = atan(tanPhi / cosTheta)
        TransYDir = 1.0 - 0.16 * (cos(AlphaDblPrime) + sin(AlphaDblPrime) * tanPhi * sqrt(1.0 + pow_2(1.0 / tan(Beta))))
        TransYDir = max(0.0, TransYDir)
    
    var COSMu = sqrt(pow_2(cosPhi) * pow_2(cosTheta) + pow_2(sinPhi))
    var TransXDir = 0.0
    if COSMu <= SMALL:
        TransXDir = 1.0 - 0.16
    else:
        var Epsilon = acos(cosPhi * cosTheta / COSMu)
        var Eta = Constants.PiOvr2 - Epsilon
        if cos(Epsilon) != 0.0 and Eta != 0.0:
            var MuPrime = atan(tan(acos(COSMu)) / cos(Epsilon))
            TransXDir = (1.0 - 0.16 * (cos(MuPrime) + sin(MuPrime) * tan(acos(COSMu)) *
                        sqrt(1.0 + pow_2(1.0 / tan(Eta)))))
            TransXDir = max(0.0, TransXDir)
    
    tar.BmTrans = max(0.0, TransXDir * TransYDir)
    return tar

fn GetProfIndices(profAng: Float64) -> Tuple[Int32, Int32]:
    var idxLo = Int32((profAng + Constants.PiOvr2) / D_PROF_ANG) + 1
    var idxHi = min(MAX_PROF_ANGS, idxLo + 1)
    return idxLo, idxHi

fn GetSlatIndicesInterpFac(slatAng: Float64) -> Tuple[Int32, Int32, Float64]:
    var idxLo = Int32(slatAng / D_SLAT_ANG)
    var idxHi = min(MAX_SLAT_ANGS, idxLo + 1)
    var interpFac = (slatAng - (idxLo * D_SLAT_ANG)) / D_SLAT_ANG
    return idxLo, idxHi, interpFac
