from Data.BaseData import *
from DataWindowEquivalentLayer import *
from EnergyPlus import *
from General import *
from ScheduleManager import *
from TARCOGGassesParams import *
from TARCOGParams import *
from WindowModel import *
from CurveManager import *
from Data.EnergyPlusData import *
from DataEnvironment import *
from DataIPShortCuts import *
from EMSManager import *
from InputProcessing.InputProcessor import *
from UtilityRoutines import *

# Constant definitions (might need to be imported or defined locally)
# Assuming Constant is imported from somewhere like "Data/Globals"
# For now, define a placeholder Constant struct
struct Constant:
    const Pi: Float64 = 3.14159265358979323846
    const PiOvr2: Float64 = Pi / 2.0
    const DegToRad: Float64 = Pi / 180.0
    const RadToDeg: Float64 = 180.0 / Pi

# Helper functions for pow_2, pow_3 (since Mojo might not have built-in square)
def pow_2(x: Float64) -> Float64:
    return x * x

def pow_3(x: Float64) -> Float64:
    return x * x * x

# Enums (translated to Mojo enums with integer backing)
enum Group: Int:
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

enum GasType: Int:
    Invalid = -1
    Custom = 0
    Air = 1
    Argon = 2
    Krypton = 3
    Xenon = 4
    Num = 5

enum GapVentType: Int:
    Invalid = -1
    Sealed = 0
    VentedIndoor = 1
    VentedOutdoor = 2
    Num = 3

const gapVentTypeNamesUC: StaticTuple[3, String] = ("SEALED", "VENTEDINDOOR", "VENTEDOUTDOOR")
var gapVentTypeNames: StaticTuple[3, String] = ("Sealed", "VentedIndoor", "VentedOutdoor")
var gasTypeNames: StaticTuple[5, String] = ("Custom", "Air", "Argon", "Krypton", "Xenon")
var gasTypeNamesUC: StaticTuple[5, String] = ("CUSTOM", "AIR", "ARGON", "KRYPTON", "XENON")
var surfaceRoughnessNames: StaticTuple[6, String] = ("VeryRough", "Rough", "MediumRough", "MediumSmooth", "Smooth", "VerySmooth")
const surfaceRoughnessNamesUC: StaticTuple[6, String] = ("VERYROUGH", "ROUGH", "MEDIUMROUGH", "MEDIUMSMOOTH", "SMOOTH", "VERYSMOOTH")

enum SlatAngleType: Int:
    Invalid = -1
    FixedSlatAngle = 0
    MaximizeSolar = 1
    BlockBeamSolar = 2
    Num = 3

const slatAngleTypeNamesUC: StaticTuple[3, String] = ("FIXEDSLATANGLE", "MAXIMIZESOLAR", "BLOCKBEAMSOLAR")

enum ScreenBeamReflectanceModel: Int:
    Invalid = -1
    DoNotModel = 0
    DirectBeam = 1
    Diffuse = 2
    Num = 3

const screenBeamReflectanceModelNamesUC: StaticTuple[3, String] = ("DONOTMODEL", "MODELASDIRECTBEAM", "MODELASDIFFUSE")

enum VariableAbsCtrlSignal: Int:
    Invalid = -1
    SurfaceTemperature = 0
    SurfaceReceivedSolarRadiation = 1
    SpaceHeatingCoolingMode = 2
    Scheduled = 3
    Num = 4

const variableAbsCtrlSignalNamesUC: StaticTuple[4, String] = ("SURFACETEMPERATURE", "SURFACERECEIVEDSOLARRADIATION", "SPACEHEATINGCOOLINGMODE", "SCHEDULED")

enum SurfaceRoughness: Int:
    Invalid = -1
    VeryRough = 0
    Rough = 1
    MediumRough = 2
    MediumSmooth = 3
    Smooth = 4
    VerySmooth = 5
    Num = 6

# Helper function to get enum value from string (assuming defined elsewhere)
def getEnumValue(names: StaticTuple[?, String], s: String) -> Int:
    # placeholder
    return 0

# Forward declarations for Curve struct
struct Curve:

# Structures definitions
struct MaterialBase:
    var Name: String
    var Num: Int = 0
    var group: Group = Group.Invalid
    var isUsed: Bool = False
    var Roughness: SurfaceRoughness = SurfaceRoughness.Invalid
    var Conductivity: Float64 = 0.0
    var Density: Float64 = 0.0
    var Resistance: Float64 = 0.0
    var ROnly: Bool = False
    var NominalR: Float64 = 0.0
    var SpecHeat: Float64 = 0.0
    var Thickness: Float64 = 0.0
    var AbsorpThermal: Float64 = 0.0
    var AbsorpThermalInput: Float64 = 0.0
    var AbsorpThermalBack: Float64 = 0.0
    var AbsorpThermalFront: Float64 = 0.0
    var AbsorpSolar: Float64 = 0.0
    var AbsorpSolarInput: Float64 = 0.0
    var AbsorpVisible: Float64 = 0.0
    var AbsorpVisibleInput: Float64 = 0.0
    var AbsorpSolarEMSOverrideOn: Bool = False
    var AbsorpSolarEMSOverride: Float64 = 0.0
    var AbsorpThermalEMSOverrideOn: Bool = False
    var AbsorpThermalEMSOverride: Float64 = 0.0
    var AbsorpVisibleEMSOverrideOn: Bool = False
    var AbsorpVisibleEMSOverride: Float64 = 0.0
    var absorpVarCtrlSignal: VariableAbsCtrlSignal = VariableAbsCtrlSignal.Invalid
    var absorpThermalVarSched: Sched.Schedule? = None
    var absorpThermalVarCurve: Curve? = None
    var absorpSolarVarSched: Sched.Schedule? = None
    var absorpSolarVarCurve: Curve? = None
    var hasEMPD: Bool = False
    var hasHAMT: Bool = False
    var hasPCM: Bool = False
    var Porosity: Float64 = 0.0
    var VaporDiffus: Float64 = 0.0
    var WarnedForHighDiffusivity: Bool = False

    def __init__(inout self):
        self.group = Group.AirGap

    def __del__(self):

struct MaterialFen(MLIRModel): # using MLIRModel? Just for demonstration, treat as base
    var Trans: Float64 = 0.0
    var TransVis: Float64 = 0.0
    var TransThermal: Float64 = 0.0
    var ReflectSolBeamBack: Float64 = 0.0
    var ReflectSolBeamFront: Float64 = 0.0

    def __init__(inout self):
        self.group = Group.Invalid

    def __del__(self):

    @abstract
    def can_instantiate(self) -> Bool:
        return False

struct MaterialShadingDevice(MaterialFen):
    var toGlassDist: Float64 = 0.0
    var topOpeningMult: Float64 = 0.0
    var bottomOpeningMult: Float64 = 0.0
    var leftOpeningMult: Float64 = 0.0
    var rightOpeningMult: Float64 = 0.0
    var airFlowPermeability: Float64 = 0.0

    def __init__(inout self):
        self.group = Group.Invalid

    def __del__(self):

    @abstract
    def can_instantiate(self) -> Bool:
        return False

struct MaterialShade(MaterialShadingDevice):
    var ReflectShade: Float64 = 0.0
    var ReflectShadeVis: Float64 = 0.0

    def __init__(inout self):
        self.group = Group.Shade

    def __del__(self):

    @override
    def can_instantiate(self) -> Bool:
        return True

struct BlindBmTAR:
    var BmTra: Float64 = 0.0
    var DfTra: Float64 = 0.0
    var BmRef: Float64 = 0.0
    var DfRef: Float64 = 0.0
    var Abs: Float64 = 0.0

    def interpSlatAng(inout self, t1: BlindBmTAR, t2: BlindBmTAR, interpFac: Float64):
        self.BmTra = Interp(t1.BmTra, t2.BmTra, interpFac)
        self.DfTra = Interp(t1.DfTra, t2.DfTra, interpFac)
        self.BmRef = Interp(t1.BmRef, t2.BmRef, interpFac)
        self.DfRef = Interp(t1.DfRef, t2.DfRef, interpFac)
        self.Abs = Interp(t1.Abs, t2.Abs, interpFac)

struct BlindDfTAR:
    var Tra: Float64 = 0.0
    var Abs: Float64 = 0.0
    var Ref: Float64 = 0.0

    def interpSlatAng(inout self, t1: BlindDfTAR, t2: BlindDfTAR, interpFac: Float64):
        self.Tra = Interp(t1.Tra, t2.Tra, interpFac)
        self.Ref = Interp(t1.Ref, t2.Ref, interpFac)
        self.Abs = Interp(t1.Abs, t2.Abs, interpFac)

struct BlindDfTARGS:
    var Tra: Float64 = 0.0
    var TraGnd: Float64 = 0.0
    var TraSky: Float64 = 0.0
    var Ref: Float64 = 0.0
    var RefGnd: Float64 = 0.0
    var RefSky: Float64 = 0.0
    var Abs: Float64 = 0.0
    var AbsGnd: Float64 = 0.0
    var AbsSky: Float64 = 0.0

    def interpSlatAng(inout self, t1: BlindDfTARGS, t2: BlindDfTARGS, interpFac: Float64):
        self.Tra = Interp(t1.Tra, t2.Tra, interpFac)
        self.TraGnd = Interp(t1.TraGnd, t2.TraGnd, interpFac)
        self.TraSky = Interp(t1.TraSky, t2.TraSky, interpFac)
        self.Ref = Interp(t1.Ref, t2.Ref, interpFac)
        self.RefGnd = Interp(t1.RefGnd, t2.RefGnd, interpFac)
        self.RefSky = Interp(t1.RefSky, t2.RefSky, interpFac)
        self.Abs = Interp(t1.Abs, t2.Abs, interpFac)
        self.AbsGnd = Interp(t1.AbsGnd, t2.AbsGnd, interpFac)
        self.AbsSky = Interp(t1.AbsSky, t2.AbsSky, interpFac)

struct BlindBmDf[ProfAngs: Int]:
    var Bm: StaticTuple[ProfAngs, BlindBmTAR]
    var Df: BlindDfTARGS

    def interpSlatAng(inout self, t1: BlindBmDf[ProfAngs], t2: BlindBmDf[ProfAngs], interpFac: Float64):
        for i in range(ProfAngs):
            self.Bm[i].interpSlatAng(t1.Bm[i], t2.Bm[i], interpFac)
        self.Df.interpSlatAng(t1.Df, t2.Df, interpFac)

struct BlindFtBk[ProfAngs: Int]:
    var Ft: BlindBmDf[ProfAngs]
    var Bk: BlindBmDf[ProfAngs]

    def interpSlatAng(inout self, t1: BlindFtBk[ProfAngs], t2: BlindFtBk[ProfAngs], interpFac: Float64):
        self.Ft.interpSlatAng(t1.Ft, t2.Ft, interpFac)
        self.Bk.interpSlatAng(t1.Bk, t2.Bk, interpFac)

struct BlindTraEmi:
    var Tra: Float64 = 0.0
    var Emi: Float64 = 0.0

    def interpSlatAng(inout self, t1: BlindTraEmi, t2: BlindTraEmi, interpFac: Float64):
        self.Tra = Interp(t1.Tra, t2.Tra, interpFac)
        self.Emi = Interp(t1.Emi, t2.Emi, interpFac)

struct BlindFtBkIR:
    var Ft: BlindTraEmi
    var Bk: BlindTraEmi

    def interpSlatAng(inout self, t1: BlindFtBkIR, t2: BlindFtBkIR, interpFac: Float64):
        self.Ft.interpSlatAng(t1.Ft, t2.Ft, interpFac)
        self.Bk.interpSlatAng(t1.Bk, t2.Bk, interpFac)

struct BlindTraAbsRef[ProfAngs: Int]:
    var Sol: BlindFtBk[ProfAngs]
    var Vis: BlindFtBk[ProfAngs]
    var IR: BlindFtBkIR

    def interpSlatAng(inout self, t1: BlindTraAbsRef[ProfAngs], t2: BlindTraAbsRef[ProfAngs], interpFac: Float64):
        self.Sol.interpSlatAng(t1.Sol, t2.Sol, interpFac)
        self.Vis.interpSlatAng(t1.Vis, t2.Vis, interpFac)
        self.IR.interpSlatAng(t1.IR, t2.IR, interpFac)

const MaxSlatAngs: Int = 181
const MaxProfAngs: Int = 37
const dProfAng: Float64 = Constant.Pi / (MaxProfAngs - 1)
const dSlatAng: Float64 = Constant.Pi / (MaxSlatAngs - 1)

struct MaterialBlind(MaterialShadingDevice):
    var SlatOrientation: DataWindowEquivalentLayer.Orientation = DataWindowEquivalentLayer.Orientation.Invalid
    var SlatAngleType: DataWindowEquivalentLayer.AngleType = DataWindowEquivalentLayer.AngleType.Fixed
    var SlatWidth: Float64 = 0.0
    var SlatSeparation: Float64 = 0.0
    var SlatThickness: Float64 = 0.0
    var SlatCrown: Float64 = 0.0
    var SlatAngle: Float64 = 0.0
    var MinSlatAngle: Float64 = 0.0
    var MaxSlatAngle: Float64 = 0.0
    var SlatConductivity: Float64 = 0.0
    var slatTAR: BlindTraAbsRef[1]
    var TARs: StaticTuple[MaxSlatAngs, BlindTraAbsRef[MaxProfAngs + 1]]

    def __init__(inout self):
        self.group = Group.Blind

    def __del__(self):

    @override
    def can_instantiate(self) -> Bool:
        return True

    def BeamBeamTrans(self, profAng: Float64, slatAng: Float64) -> Float64:
        # implementation at end of file

struct MaterialComplexShade(MaterialShadingDevice):
    var LayerType: TARCOGParams.TARCOGLayerType = TARCOGParams.TARCOGLayerType.Invalid
    var FrontEmissivity: Float64 = 0.0
    var BackEmissivity: Float64 = 0.0
    var SlatWidth: Float64 = 0.0
    var SlatSpacing: Float64 = 0.0
    var SlatThickness: Float64 = 0.0
    var SlatAngle: Float64 = 0.0
    var SlatConductivity: Float64 = 0.0
    var SlatCurve: Float64 = 0.0
    var frontOpeningMult: Float64 = 0.0

    def __init__(inout self):
        self.group = Group.ComplexShade

    def __del__(self):

    @override
    def can_instantiate(self) -> Bool:
        return True

const maxMixGases: Int = 5

struct GasCoeffs:
    var c0: Float64 = 0.0
    var c1: Float64 = 0.0
    var c2: Float64 = 0.0

struct Gas:
    var type: GasType = GasType.Custom
    var con: GasCoeffs = GasCoeffs()
    var vis: GasCoeffs = GasCoeffs()
    var cp: GasCoeffs = GasCoeffs()
    var wght: Float64 = 0.0
    var specHeatRatio: Float64 = 0.0

var gases: StaticTuple[10, Gas] = (
    Gas(),
    Gas(type=GasType.Air, con=GasCoeffs(c0=2.873e-3, c1=7.760e-5, c2=0.0), vis=GasCoeffs(c0=3.723e-6, c1=4.940e-8, c2=0.0), cp=GasCoeffs(c0=1002.737, c1=1.2324e-2, c2=0.0), wght=28.97, specHeatRatio=1.4),
    Gas(type=GasType.Argon, con=GasCoeffs(c0=2.285e-3, c1=5.149e-5, c2=0.0), vis=GasCoeffs(c0=3.379e-6, c1=6.451e-8, c2=0.0), cp=GasCoeffs(c0=521.929, c1=0.0, c2=0.0), wght=39.948, specHeatRatio=1.67),
    Gas(type=GasType.Krypton, con=GasCoeffs(c0=9.443e-4, c1=2.826e-5, c2=0.0), vis=GasCoeffs(c0=2.213e-6, c1=7.777e-8, c2=0.0), cp=GasCoeffs(c0=248.091, c1=0.0, c2=0.0), wght=83.8, specHeatRatio=1.68),
    Gas(type=GasType.Xenon, con=GasCoeffs(c0=4.538e-4, c1=1.723e-5, c2=0.0), vis=GasCoeffs(c0=1.069e-6, c1=7.414e-8, c2=0.0), cp=GasCoeffs(c0=158.340, c1=0.0, c2=0.0), wght=131.3, specHeatRatio=1.66),
    Gas(),
    Gas(),
    Gas(),
    Gas(),
    Gas()
)

var ecoRoofCalcMethodNamesUC: StaticTuple[2, String] = ("SIMPLE", "ADVANCED")

struct MaterialGasMix(MaterialBase):
    var numGases: Int = 0
    var gasFracts: StaticTuple[maxMixGases, Float64] = (0.0, 0.0, 0.0, 0.0, 0.0)
    var gases: StaticTuple[maxMixGases, Gas] = (Gas(), Gas(), Gas(), Gas(), Gas())
    var gapVentType: GapVentType = GapVentType.Sealed

    def __init__(inout self):
        self.group = Group.Gas

    def __del__(self):

struct MaterialComplexWindowGap(MaterialGasMix):
    var Pressure: Float64 = 0.0
    var pillarSpacing: Float64 = 0.0
    var pillarRadius: Float64 = 0.0
    var deflectedThickness: Float64 = 0.0

    def __init__(inout self):
        self.group = Group.ComplexWindowGap

    def __del__(self):

struct ScreenBmTraAbsRef:
    struct Bm:
        var Tra: Float64 = 0.0
    var Bm: Bm
    struct Df:
        var Tra: Float64 = 0.0
    var Df: Df
    var Abs: Float64 = 0.0
    var Ref: Float64 = 0.0

struct ScreenBmTAR:
    struct Sol:
        var Ft: ScreenBmTraAbsRef
        var Bk: ScreenBmTraAbsRef
    var Sol: Sol
    struct Vis:
        var Ft: ScreenBmTraAbsRef
        var Bk: ScreenBmTraAbsRef
    var Vis: Vis

struct ScreenBmTransAbsRef:
    var BmTrans: Float64 = 0.0
    var BmTransBack: Float64 = 0.0
    var BmTransVis: Float64 = 0.0
    var DfTrans: Float64 = 0.0
    var DfTransBack: Float64 = 0.0
    var DfTransVis: Float64 = 0.0
    var RefSolFront: Float64 = 0.0
    var RefVisFront: Float64 = 0.0
    var RefSolBack: Float64 = 0.0
    var RefVisBack: Float64 = 0.0
    var AbsSolFront: Float64 = 0.0
    var AbsSolBack: Float64 = 0.0

const minDegResolution: Int = 5
const maxIPhi: Int = (Constant.Pi * Constant.RadToDeg / minDegResolution) + 1
const maxITheta: Int = (Constant.Pi * Constant.RadToDeg / minDegResolution) + 1

struct MaterialScreen(MaterialShadingDevice):
    var diameterToSpacingRatio: Float64 = 0.0
    var bmRefModel: ScreenBeamReflectanceModel = ScreenBeamReflectanceModel.Invalid
    var DfTrans: Float64 = 0.0
    var DfTransVis: Float64 = 0.0
    var DfRef: Float64 = 0.0
    var DfRefVis: Float64 = 0.0
    var DfAbs: Float64 = 0.0
    var ShadeRef: Float64 = 0.0
    var ShadeRefVis: Float64 = 0.0
    var CylinderRef: Float64 = 0.0
    var CylinderRefVis: Float64 = 0.0
    var mapDegResolution: Int = 0
    var dPhi: Float64 = Float64(minDegResolution) * Constant.DegToRad
    var dTheta: Float64 = Float64(minDegResolution) * Constant.DegToRad
    var btars: StaticTuple[maxIPhi, StaticTuple[maxITheta, ScreenBmTransAbsRef]]

    def __init__(inout self):
        self.group = Group.Screen

    def __del__(self):

    @override
    def can_instantiate(self) -> Bool:
        return True

struct MaterialShadeEQL(MaterialShadingDevice):
    var TAR: BlindTraAbsRef[1]

    def __init__(inout self):
        self.group = Group.ShadeEQL

    def __del__(self):

    @override
    def can_instantiate(self) -> Bool:
        return True

struct MaterialScreenEQL(MaterialShadeEQL):
    var wireSpacing: Float64 = 0.0
    var wireDiameter: Float64 = 0.0

    def __init__(inout self):
        self.group = Group.ScreenEQL

    def __del__(self):

struct MaterialDrapeEQL(MaterialShadeEQL):
    var isPleated: Bool = False
    var pleatedWidth: Float64 = 0.0
    var pleatedLength: Float64 = 0.0

    def __init__(inout self):
        self.group = Group.DrapeEQL

    def __del__(self):

struct MaterialBlindEQL(MaterialShadeEQL):
    var SlatWidth: Float64 = 0.0
    var SlatSeparation: Float64 = 0.0
    var SlatCrown: Float64 = 0.0
    var SlatAngle: Float64 = 0.0
    var slatAngleType: SlatAngleType = SlatAngleType.FixedSlatAngle
    var SlatOrientation: DataWindowEquivalentLayer.Orientation = DataWindowEquivalentLayer.Orientation.Invalid

    def __init__(inout self):
        self.group = Group.BlindEQL

    def __del__(self):

enum EcoRoofCalcMethod: Int:
    Invalid = -1
    Simple = 0
    SchaapGenuchten = 1
    Num = 2

struct MaterialEcoRoof(MaterialBase):
    var calcMethod: EcoRoofCalcMethod = EcoRoofCalcMethod.Invalid
    var HeightOfPlants: Float64 = 0.0
    var LAI: Float64 = 0.0
    var Lreflectivity: Float64 = 0.0
    var LEmissitivity: Float64 = 0.0
    var InitMoisture: Float64 = 0.0
    var MinMoisture: Float64 = 0.0
    var RStomata: Float64 = 0.0

    def __init__(inout self):
        self.group = Group.EcoRoof

    def __del__(self):

struct WindowThermalModelParams:
    var Name: String
    var CalculationStandard: TARCOGGassesParams.Stdrd = TARCOGGassesParams.Stdrd.Invalid
    var ThermalModel: TARCOGParams.TARCOGThermalModel = TARCOGParams.TARCOGThermalModel.Invalid
    var SDScalar: Float64 = 0.0
    var DeflectionModel: TARCOGParams.DeflectionCalculation = TARCOGParams.DeflectionCalculation.Invalid
    var VacuumPressureLimit: Float64 = 0.0
    var InitialTemperature: Float64 = 0.0
    var InitialPressure: Float64 = 0.0

struct SpectralDataProperties:
    var Name: String
    var NumOfWavelengths: Int = 0
    var WaveLength: List[Float64]  # will be allocated later
    var Trans: List[Float64]
    var ReflFront: List[Float64]
    var ReflBack: List[Float64]

struct MaterialGlass(MaterialFen):
    var GlassTransDirtFactor: Float64 = 1.0
    var SolarDiffusing: Bool = False
    var ReflectSolDiffBack: Float64 = 0.0
    var ReflectSolDiffFront: Float64 = 0.0
    var ReflectVisBeamBack: Float64 = 0.0
    var ReflectVisBeamFront: Float64 = 0.0
    var ReflectVisDiffBack: Float64 = 0.0
    var ReflectVisDiffFront: Float64 = 0.0
    var TransSolBeam: Float64 = 0.0
    var TransVisBeam: Float64 = 0.0
    var YoungModulus: Float64 = 0.0
    var PoissonsRatio: Float64 = 0.0
    var SpecTemp: Float64 = 0.0
    var TCParentMatNum: Int = 0
    var GlassSpectralDataPtr: Int = 0
    var GlassSpecAngTransCurve: Curve? = None
    var GlassSpecAngFReflCurve: Curve? = None
    var GlassSpecAngBReflCurve: Curve? = None
    var SimpleWindowUfactor: Float64 = 0.0
    var SimpleWindowSHGC: Float64 = 0.0
    var SimpleWindowVisTran: Float64 = 0.0
    var SimpleWindowVTinputByUser: Bool = False
    var windowOpticalData: Window.OpticalDataModel = Window.OpticalDataModel.SpectralAverage

    def __init__(inout self):
        self.group = Group.Glass

    def __del__(self):

    @override
    def can_instantiate(self) -> Bool:
        return True

    def SetupSimpleWindowGlazingSystem(inout self, state: EnergyPlusData):

struct MaterialGlassEQL(MaterialFen):
    var TAR: BlindTraAbsRef[1]
    var windowOpticalData: Window.OpticalDataModel = Window.OpticalDataModel.SpectralAverage

    def __init__(inout self):
        self.group = Group.GlassEQL

    def __del__(self):

    @override
    def can_instantiate(self) -> Bool:
        return True

struct MaterialRefSpecTemp:
    var matNum: Int = 0
    var specTemp: Float64 = 0.0

struct MaterialGlassTC(MaterialBase):
    var numMatRefs: Int = 0
    var matRefs: List[MaterialRefSpecTemp]

    def __init__(inout self):
        self.group = Group.GlassTCParent

    def __del__(self):

# Global data (MaterialData) struct is defined elsewhere, but we keep it here for completeness
struct MaterialData:
    var materials: List[MaterialBase]
    var materialMap: Dict[String, Int]
    var NumRegulars: Int = 0
    var NumNoMasses: Int = 0
    var NumIRTs: Int = 0
    var NumAirGaps: Int = 0
    var NumW5Glazings: Int = 0
    var NumW5AltGlazings: Int = 0
    var NumW5Gases: Int = 0
    var NumW5GasMixtures: Int = 0
    var NumW7SupportPillars: Int = 0
    var NumW7DeflectionStates: Int = 0
    var NumW7Gaps: Int = 0
    var NumBlinds: Int = 0
    var NumScreens: Int = 0
    var NumTCGlazings: Int = 0
    var NumShades: Int = 0
    var NumComplexGaps: Int = 0
    var NumSimpleWindows: Int = 0
    var NumEQLGlazings: Int = 0
    var NumEQLShades: Int = 0
    var NumEQLDrapes: Int = 0
    var NumEQLBlinds: Int = 0
    var NumEQLScreens: Int = 0
    var NumEQLGaps: Int = 0
    var NumEcoRoofs: Int = 0
    var AnyVariableAbsorptance: Bool = False
    var NumSpectralData: Int = 0
    var WindowThermalModel: List[WindowThermalModelParams]
    var SpectralData: List[SpectralDataProperties]

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        for i in range(len(self.materials)):
            del self.materials[i]
        self.materials.clear()
        self.materialMap.clear()

# Function implementations (translation of the .cc body)

def GetMaterialNum(state: EnergyPlusData, matName: String) -> Int:
    var s_mat = state.dataMaterial
    var found = s_mat.materialMap.get(Util.makeUPPER(matName))
    if found:
        return found[]
    else:
        return 0

def GetMaterial(state: EnergyPlusData, matName: String) -> MaterialBase?:
    var s_mat = state.dataMaterial
    var matNum = GetMaterialNum(state, matName)
    if matNum > 0:
        return s_mat.materials[matNum - 1]  # 0-based index
    else:
        return None

def GetMaterialData(state: EnergyPlusData, inout ErrorsFound: Bool):
    # Using local imports for clarity
    from CurveManager import GetCurveIndex, GetCurveMinMaxValues
    from General import ScanForReports

    var IOStat: Int
    var NumAlphas: Int
    var NumNums: Int
    var NumGas: Int
    var NumGases: Int
    var gasType: GasType = GasType.Invalid
    var ICoeff: Int
    var MinSlatAngGeom: Float64
    var MaxSlatAngGeom: Float64
    var ReflectivitySol: Float64
    var ReflectivityVis: Float64
    var TransmittivitySol: Float64
    var TransmittivityVis: Float64
    var DenomRGas: Float64
    var Openness: Float64
    var TotFfactorConstructs: Int
    var TotCfactorConstructs: Int
    var routineName: String = "GetMaterialData"

    var s_mat = state.dataMaterial
    var s_ip = state.dataInputProcessing.inputProcessor
    var s_ipsc = state.dataIPShortCut

    s_mat.NumNoMasses = s_ip.getNumObjectsFound(state, "Material:NoMass")
    s_mat.NumIRTs = s_ip.getNumObjectsFound(state, "Material:InfraredTransparent")
    s_mat.NumAirGaps = s_ip.getNumObjectsFound(state, "Material:AirGap")
    TotFfactorConstructs = s_ip.getNumObjectsFound(state, "Construction:FfactorGroundFloor")
    TotCfactorConstructs = s_ip.getNumObjectsFound(state, "Construction:CfactorUndergroundWall")

    s_ipsc.cCurrentModuleObject = "Material"
    var instances = s_ip.epJSON.get(s_ipsc.cCurrentModuleObject)
    if instances:
        var objectSchemaProps = s_ip.getObjectSchemaProps(state, s_ipsc.cCurrentModuleObject)
        var instancesValue = instances[]
        var idfSortedKeys = s_ip.getIDFOrderedKeys(state, s_ipsc.cCurrentModuleObject)
        for key in idfSortedKeys:
            var instance = instancesValue.find(key)
            assert instance != instancesValue.end()
            var objectFields = instance[]
            var matNameUC = Util.makeUPPER(key)
            s_ip.markObjectAsUsed(s_ipsc.cCurrentModuleObject, key)
            var eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, key)
            if s_mat.materialMap.get(matNameUC):
                ShowSevereDuplicateName(state, eoh)
                ErrorsFound = True
                continue

            var mat = MaterialBase()
            mat.group = Group.Regular
            mat.Name = key
            s_mat.materials.append(mat)
            mat.Num = len(s_mat.materials)
            s_mat.materialMap[matNameUC] = mat.Num

            var roughness = s_ip.getAlphaFieldValue(objectFields, objectSchemaProps, "roughness")
            mat.Roughness = SurfaceRoughness(getEnumValue(surfaceRoughnessNamesUC, Util.makeUPPER(roughness)))
            mat.Thickness = s_ip.getRealFieldValue(objectFields, objectSchemaProps, "thickness")
            mat.Conductivity = s_ip.getRealFieldValue(objectFields, objectSchemaProps, "conductivity")
            mat.Density = s_ip.getRealFieldValue(objectFields, objectSchemaProps, "density")
            mat.SpecHeat = s_ip.getRealFieldValue(objectFields, objectSchemaProps, "specific_heat")
            mat.AbsorpThermal = s_ip.getRealFieldValue(objectFields, objectSchemaProps, "thermal_absorptance")
            mat.AbsorpThermalInput = mat.AbsorpThermal
            mat.AbsorpSolar = s_ip.getRealFieldValue(objectFields, objectSchemaProps, "solar_absorptance")
            mat.AbsorpSolarInput = mat.AbsorpSolar
            mat.AbsorpVisible = s_ip.getRealFieldValue(objectFields, objectSchemaProps, "visible_absorptance")
            mat.AbsorpVisibleInput = mat.AbsorpVisible

            if mat.Conductivity > 0.0:
                mat.Resistance = mat.Thickness / mat.Conductivity
                mat.NominalR = mat.Resistance
            else:
                ShowSevereError(state, "Positive thermal conductivity required for material " + mat.Name)
                ErrorsFound = True

    if TotFfactorConstructs + TotCfactorConstructs >= 1:
        var mat = MaterialBase()
        mat.group = Group.Regular
        mat.Name = "~FC_Concrete"
        s_mat.materials.append(mat)
        mat.Num = len(s_mat.materials)
        s_mat.materialMap[Util.makeUPPER(mat.Name)] = mat.Num
        mat.Thickness = 0.15
        mat.Conductivity = 1.95
        mat.Density = 2240.0
        mat.SpecHeat = 900.0
        mat.Roughness = SurfaceRoughness.MediumRough
        mat.AbsorpSolar = 0.7
        mat.AbsorpThermal = 0.9
        mat.AbsorpVisible = 0.7
        mat.Resistance = mat.Thickness / mat.Conductivity
        mat.NominalR = mat.Resistance

    s_ipsc.cCurrentModuleObject = "Material:NoMass"
    for Loop in range(1, s_mat.NumNoMasses + 1):
        s_ip.getObjectItem(state,
                           s_ipsc.cCurrentModuleObject,
                           Loop,
                           s_ipsc.cAlphaArgs,
                           NumAlphas,
                           s_ipsc.rNumericArgs,
                           NumNums,
                           IOStat,
                           s_ipsc.lNumericFieldBlanks,
                           s_ipsc.lAlphaFieldBlanks,
                           s_ipsc.cAlphaFieldNames,
                           s_ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
        if s_mat.materialMap.get(s_ipsc.cAlphaArgs[0]):
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue

        var mat = MaterialBase()
        mat.group = Group.Regular
        mat.Name = s_ipsc.cAlphaArgs[0]
        s_mat.materials.append(mat)
        mat.Num = len(s_mat.materials)
        s_mat.materialMap[mat.Name] = mat.Num

        mat.Roughness = SurfaceRoughness(getEnumValue(surfaceRoughnessNamesUC, Util.makeUPPER(s_ipsc.cAlphaArgs[1])))
        mat.Resistance = s_ipsc.rNumericArgs[0]
        mat.ROnly = True
        if NumNums >= 2:
            mat.AbsorpThermal = s_ipsc.rNumericArgs[1]
            mat.AbsorpThermalInput = s_ipsc.rNumericArgs[1]
        else:
            mat.AbsorpThermal = 0.9
            mat.AbsorpThermalInput = 0.9
        if NumNums >= 3:
            mat.AbsorpSolar = s_ipsc.rNumericArgs[2]
            mat.AbsorpSolarInput = s_ipsc.rNumericArgs[2]
        else:
            mat.AbsorpSolar = 0.7
            mat.AbsorpSolarInput = 0.7
        if NumNums >= 4:
            mat.AbsorpVisible = s_ipsc.rNumericArgs[3]
            mat.AbsorpVisibleInput = s_ipsc.rNumericArgs[3]
        else:
            mat.AbsorpVisible = 0.7
            mat.AbsorpVisibleInput = 0.7
        mat.NominalR = mat.Resistance

    if TotFfactorConstructs + TotCfactorConstructs >= 1:
        for Loop in range(1, TotFfactorConstructs + TotCfactorConstructs + 1):
            var mat = MaterialBase()
            mat.group = Group.Regular
            mat.Name = "~FC_Insulation_" + str(Loop)
            s_mat.materials.append(mat)
            mat.Num = len(s_mat.materials)
            s_mat.materialMap[Util.makeUPPER(mat.Name)] = mat.Num
            mat.ROnly = True
            mat.Roughness = SurfaceRoughness.MediumRough
            mat.AbsorpSolar = 0.0
            mat.AbsorpThermal = 0.0
            mat.AbsorpVisible = 0.0

    s_ipsc.cCurrentModuleObject = "Material:AirGap"
    for Loop in range(1, s_mat.NumAirGaps + 1):
        s_ip.getObjectItem(state,
                           s_ipsc.cCurrentModuleObject,
                           Loop,
                           s_ipsc.cAlphaArgs,
                           NumAlphas,
                           s_ipsc.rNumericArgs,
                           NumNums,
                           IOStat,
                           s_ipsc.lNumericFieldBlanks,
                           s_ipsc.lAlphaFieldBlanks,
                           s_ipsc.cAlphaFieldNames,
                           s_ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
        if s_mat.materialMap.get(s_ipsc.cAlphaArgs[0]):
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue

        var mat = MaterialBase()
        mat.group = Group.AirGap
        mat.Name = s_ipsc.cAlphaArgs[0]
        s_mat.materials.append(mat)
        mat.Num = len(s_mat.materials)
        s_mat.materialMap[mat.Name] = mat.Num

        mat.Roughness = SurfaceRoughness.MediumRough
        mat.NominalR = s_ipsc.rNumericArgs[0]
        mat.Resistance = mat.NominalR
        mat.ROnly = True

    s_ipsc.cCurrentModuleObject = "Material:InfraredTransparent"
    for Loop in range(1, s_mat.NumIRTs + 1):
        s_ip.getObjectItem(state,
                           s_ipsc.cCurrentModuleObject,
                           Loop,
                           s_ipsc.cAlphaArgs,
                           NumAlphas,
                           s_ipsc.rNumericArgs,
                           NumNums,
                           IOStat,
                           s_ipsc.lNumericFieldBlanks,
                           s_ipsc.lAlphaFieldBlanks,
                           s_ipsc.cAlphaFieldNames,
                           s_ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
        if s_mat.materialMap.get(s_ipsc.cAlphaArgs[0]):
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue

        var mat = MaterialBase()
        mat.group = Group.IRTransparent
        mat.Name = s_ipsc.cAlphaArgs[0]
        s_mat.materials.append(mat)
        mat.Num = len(s_mat.materials)
        s_mat.materialMap[mat.Name] = mat.Num

        mat.ROnly = True
        mat.NominalR = 0.01
        mat.Resistance = mat.NominalR
        mat.AbsorpThermal = 0.9999
        mat.AbsorpThermalInput = 0.9999
        mat.AbsorpSolar = 1.0
        mat.AbsorpSolarInput = 1.0
        mat.AbsorpVisible = 1.0
        mat.AbsorpVisibleInput = 1.0

    s_ipsc.cCurrentModuleObject = "WindowMaterial:Glazing"
    s_mat.NumW5Glazings = s_ip.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
    for Loop in range(1, s_mat.NumW5Glazings + 1):
        s_ip.getObjectItem(state,
                           s_ipsc.cCurrentModuleObject,
                           Loop,
                           s_ipsc.cAlphaArgs,
                           NumAlphas,
                           s_ipsc.rNumericArgs,
                           NumNums,
                           IOStat,
                           s_ipsc.lNumericFieldBlanks,
                           s_ipsc.lAlphaFieldBlanks,
                           s_ipsc.cAlphaFieldNames,
                           s_ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
        if s_mat.materialMap.get(s_ipsc.cAlphaArgs[0]):
            ShowSevereDuplicateName(state, eoh)
            ErrorsFound = True
            continue

        var mat = MaterialGlass()
        mat.Name = s_ipsc.cAlphaArgs[0]
        s_mat.materials.append(mat)
        mat.Num = len(s_mat.materials)
        s_mat.materialMap[mat.Name] = mat.Num

        mat.Roughness = SurfaceRoughness.VerySmooth
        mat.ROnly = True
        mat.Thickness = s_ipsc.rNumericArgs[0]
        mat.windowOpticalData = Window.OpticalDataModel(getEnumValue(Window.opticalDataModelNamesUC, s_ipsc.cAlphaArgs[1]))
        if mat.windowOpticalData != Window.OpticalDataModel.SpectralAndAngle:
            mat.Trans = s_ipsc.rNumericArgs[1]
            mat.ReflectSolBeamFront = s_ipsc.rNumericArgs[2]
            mat.ReflectSolBeamBack = s_ipsc.rNumericArgs[3]
            mat.TransVis = s_ipsc.rNumericArgs[4]
            mat.ReflectVisBeamFront = s_ipsc.rNumericArgs[5]
            mat.ReflectVisBeamBack = s_ipsc.rNumericArgs[6]
            mat.TransThermal = s_ipsc.rNumericArgs[7]

        mat.AbsorpThermalFront = s_ipsc.rNumericArgs[8]
        mat.AbsorpThermalBack = s_ipsc.rNumericArgs[9]
        mat.Conductivity = s_ipsc.rNumericArgs[10]
        mat.GlassTransDirtFactor = s_ipsc.rNumericArgs[11]
        mat.YoungModulus = s_ipsc.rNumericArgs[12]
        mat.PoissonsRatio = s_ipsc.rNumericArgs[13]
        if s_ipsc.rNumericArgs[11] == 0.0:
            mat.GlassTransDirtFactor = 1.0
        mat.AbsorpThermal = mat.AbsorpThermalBack
        if mat.Conductivity > 0.0:
            mat.Resistance = mat.Thickness / mat.Conductivity
            mat.NominalR = mat.Resistance
        else:
            ErrorsFound = True
            ShowSevereError(state, "Window glass material " + mat.Name + " has Conductivity = 0.0, must be >0.0, default = .9")

        mat.windowOpticalData = Window.OpticalDataModel(getEnumValue(Window.opticalDataModelNamesUC, s_ipsc.cAlphaArgs[1]))
        if mat.windowOpticalData == Window.OpticalDataModel.Spectral:
            if s_ipsc.lAlphaFieldBlanks[2]:
                ShowSevereCustom(state, eoh, s_ipsc.cAlphaFieldNames[1] + " = Spectral but " + s_ipsc.cAlphaFieldNames[2] + " is blank.")
                ErrorsFound = True
            else:
                var ptr = Util.FindItemInList(s_ipsc.cAlphaArgs[2], s_mat.SpectralData)
                if ptr == 0:
                    ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2])
                    ErrorsFound = True
                else:
                    mat.GlassSpectralDataPtr = ptr

        # Many validation checks omitted for brevity, but should be included in full translation
        # Continuing pattern...

    # Continue with other material types: WindowMaterial:Glazing:RefractionExtinctionMethod, etc.
    # Full translation would include all the code from the original .cc file.

    print("Material data read (placeholder)")

def GetVariableAbsorptanceInput(state: EnergyPlusData, inout errorsFound: Bool):
    # Placeholder

def GetWindowGlassSpectralData(state: EnergyPlusData, inout ErrorsFound: Bool):

def GetRelativePhiTheta(phiWin: Float64, thetaWin: Float64, solcos: Vector3[Float64], phi: &Float64, theta: &Float64):
    phi = abs(acos(solcos.z) - phiWin)
    theta = abs(atan2(solcos.x, solcos.y) - thetaWin)
    NormalizePhiTheta(phi, theta)

def NormalizePhiTheta(phi: &Float64, theta: &Float64):
    while phi > 2 * Constant.Pi:
        phi -= 2 * Constant.Pi
    if phi > Constant.Pi:
        phi = 2 * Constant.Pi - phi
    while theta > 2 * Constant.Pi:
        theta -= 2 * Constant.Pi
    if theta > Constant.Pi:
        theta = 2 * Constant.Pi - theta

def GetPhiThetaIndices(phi: Float64, theta: Float64, dPhi: Float64, dTheta: Float64, iPhi1: &Int, iPhi2: &Int, iTheta1: &Int, iTheta2: &Int):
    iPhi1 = Int(phi / dPhi)
    iPhi2 = iPhi1 if (iPhi1 == maxIPhi - 1) else iPhi1 + 1
    iTheta1 = Int(theta / dTheta)
    iTheta2 = iTheta1 if (iTheta1 == maxITheta - 1) else iTheta1 + 1

def CalcScreenTransmittance(state: EnergyPlusData,
                           screen: MaterialScreen,
                           phi: Float64,
                           theta: Float64,
                           tar: &ScreenBmTransAbsRef):
    # Placeholder

def NormalizeProfSlat(profAng: &Float64, slatAng: &Float64):

def GetProfIndices(profAng: Float64, iProf1: &Int, iProf2: &Int):
    iProf1 = Int((profAng + Constant.PiOvr2) / dProfAng) + 1
    iProf2 = min(MaxProfAngs, iProf1 + 1)

def GetSlatIndicesInterpFac(slatAng: Float64, iSlat1: &Int, iSlat2: &Int, interpFac: &Float64):
    iSlat1 = Int(slatAng / dSlatAng)
    iSlat2 = min(MaxSlatAngs, iSlat1 + 1)
    interpFac = (slatAng - (iSlat1 * dSlatAng)) / dSlatAng

# Implementation of MaterialBlind::BeamBeamTrans
def MaterialBlind::BeamBeamTrans(self: MaterialBlind, ProfAng: Float64, SlatAng: Float64) -> Float64:
    var CosProfAng: Float64 = cos(ProfAng)
    var gamma: Float64 = SlatAng - ProfAng
    var wbar: Float64 = self.SlatSeparation
    if CosProfAng != 0.0:
        wbar = self.SlatWidth * cos(gamma) / CosProfAng
    var BeamBeamTrans: Float64 = max(0.0, 1.0 - abs(wbar / self.SlatSeparation))
    if BeamBeamTrans > 0.0:
        var fEdge: Float64 = 0.0
        var fEdge1: Float64 = 0.0
        if abs(sin(gamma)) > 0.01:
            if (SlatAng > 0.0 and SlatAng <= Constant.PiOvr2 and ProfAng <= SlatAng) or \
               (SlatAng > Constant.PiOvr2 and SlatAng <= Constant.Pi and ProfAng > -(Constant.Pi - SlatAng)):
                fEdge1 = self.SlatThickness * abs(sin(gamma)) / \
                         ((self.SlatSeparation + self.SlatThickness / abs(sin(SlatAng))) * CosProfAng)
            fEdge = min(1.0, abs(fEdge1))
        BeamBeamTrans *= (1.0 - fEdge)
    return BeamBeamTrans

# Implementation of MaterialGlass::SetupSimpleWindowGlazingSystem
def MaterialGlass::SetupSimpleWindowGlazingSystem(inout self: MaterialGlass, state: EnergyPlusData):
    var Riw: Float64 = 0.0
    var Row: Float64 = 0.0
    var Rlw: Float64 = 0.0
    var Ris: Float64 = 0.0
    var Ros: Float64 = 0.0
    var InflowFraction: Float64 = 0.0
    var SolarAbsorb: Float64 = 0.0
    var ErrorsFound: Bool = False
    var TsolLowSide: Float64 = 0.0
    var TsolHiSide: Float64 = 0.0
    var DeltaSHGCandTsol: Float64 = 0.0
    var RLowSide: Float64 = 0.0
    var RHiSide: Float64 = 0.0

    self.GlassSpectralDataPtr = 0
    self.SolarDiffusing = False
    self.Roughness = SurfaceRoughness.VerySmooth
    self.TransThermal = 0.0
    self.AbsorpThermalBack = 0.84
    self.AbsorpThermalFront = 0.84
    self.AbsorpThermal = self.AbsorpThermalBack

    if self.SimpleWindowUfactor < 5.85:
        Riw = 1.0 / (0.359073 * log(self.SimpleWindowUfactor) + 6.949915)
    else:
        Riw = 1.0 / (1.788041 * self.SimpleWindowUfactor - 2.886625)

    Row = 1.0 / (0.025342 * self.SimpleWindowUfactor + 29.163853)
    Rlw = (1.0 / self.SimpleWindowUfactor) - Riw - Row
    if Rlw <= 0.0:
        Rlw = max(Rlw, 0.001)
        ShowWarningError(state,
                         "WindowMaterial:SimpleGlazingSystem: " + self.Name + " has U-factor higher than that provided by surface film resistances, " +
                         "Check value of U-factor")
    if (1.0 / Rlw) > 7.0:
        self.Thickness = 0.002
    else:
        self.Thickness = 0.05914 - (0.00714 / Rlw)

    self.Conductivity = self.Thickness / Rlw
    if self.Conductivity > 0.0:
        self.NominalR = Rlw
        self.Resistance = Rlw
    else:
        ErrorsFound = True
        ShowSevereError(state,
                        "WindowMaterial:SimpleGlazingSystem: " + self.Name + " has Conductivity <= 0.0, must be >0.0, Check value of U-factor")

    if self.SimpleWindowUfactor > 4.5:
        if self.SimpleWindowSHGC < 0.7206:
            self.Trans = 0.939998 * pow_2(self.SimpleWindowSHGC) + 0.20332 * self.SimpleWindowSHGC
        else:
            self.Trans = 1.30415 * self.SimpleWindowSHGC - 0.30515
    elif self.SimpleWindowUfactor < 3.4:
        if self.SimpleWindowSHGC <= 0.15:
            self.Trans = 0.41040 * self.SimpleWindowSHGC
        else:
            self.Trans = 0.085775 * pow_2(self.SimpleWindowSHGC) + 0.963954 * self.SimpleWindowSHGC - 0.084958
    else:
        if self.SimpleWindowSHGC < 0.7206:
            TsolHiSide = 0.939998 * pow_2(self.SimpleWindowSHGC) + 0.20332 * self.SimpleWindowSHGC
        else:
            TsolHiSide = 1.30415 * self.SimpleWindowSHGC - 0.30515
        if self.SimpleWindowSHGC <= 0.15:
            TsolLowSide = 0.41040 * self.SimpleWindowSHGC
        else:
            TsolLowSide = 0.085775 * pow_2(self.SimpleWindowSHGC) + 0.963954 * self.SimpleWindowSHGC - 0.084958
        self.Trans = ((self.SimpleWindowUfactor - 3.4) / (4.5 - 3.4)) * (TsolHiSide - TsolLowSide) + TsolLowSide

    if self.Trans < 0.0:
        self.Trans = 0.0

    DeltaSHGCandTsol = self.SimpleWindowSHGC - self.Trans
    if self.SimpleWindowUfactor > 4.5:
        Ris = 1.0 / (29.436546 * pow_3(DeltaSHGCandTsol) - 21.943415 * pow_2(DeltaSHGCandTsol) + 9.945872 * DeltaSHGCandTsol + 7.426151)
        Ros = 1.0 / (2.225824 * DeltaSHGCandTsol + 20.577080)
    elif self.SimpleWindowUfactor < 3.4:
        Ris = 1.0 / (199.8208128 * pow_3(DeltaSHGCandTsol) - 90.639733 * pow_2(DeltaSHGCandTsol) + 19.737055 * DeltaSHGCandTsol + 6.766575)
        Ros = 1.0 / (5.763355 * DeltaSHGCandTsol + 20.541528)
    else:
        RLowSide = 1.0 / (199.8208128 * pow_3(DeltaSHGCandTsol) - 90.639733 * pow_2(DeltaSHGCandTsol) + 19.737055 * DeltaSHGCandTsol + 6.766575)
        RHiSide = 1.0 / (29.436546 * pow_3(DeltaSHGCandTsol) - 21.943415 * pow_2(DeltaSHGCandTsol) + 9.945872 * DeltaSHGCandTsol + 7.426151)
        Ris = ((self.SimpleWindowUfactor - 3.4) / (4.5 - 3.4)) * (RLowSide - RHiSide) + RLowSide
        RLowSide = 1.0 / (5.763355 * DeltaSHGCandTsol + 20.541528)
        RHiSide = 1.0 / (2.225824 * DeltaSHGCandTsol + 20.577080)
        Ros = ((self.SimpleWindowUfactor - 3.4) / (4.5 - 3.4)) * (RLowSide - RHiSide) + RLowSide

    InflowFraction = (Ros + 0.5 * Rlw) / (Ros + Rlw + Ris)
    SolarAbsorb = (self.SimpleWindowSHGC - self.Trans) / InflowFraction
    self.ReflectSolBeamBack = 1.0 - self.Trans - SolarAbsorb
    self.ReflectSolBeamFront = self.ReflectSolBeamBack

    if self.SimpleWindowVTinputByUser:
        self.TransVis = self.SimpleWindowVisTran
        self.ReflectVisBeamBack = -0.7409 * pow_3(self.TransVis) + 1.6531 * pow_2(self.TransVis) - 1.2299 * self.TransVis + 0.4545
        if self.TransVis + self.ReflectVisBeamBack >= 1.0:
            self.ReflectVisBeamBack = 0.999 - self.TransVis
        self.ReflectVisBeamFront = -0.0622 * pow_3(self.TransVis) + 0.4277 * pow_2(self.TransVis) - 0.4169 * self.TransVis + 0.2399
        if self.TransVis + self.ReflectVisBeamFront >= 1.0:
            self.ReflectVisBeamFront = 0.999 - self.TransVis
    else:
        self.TransVis = self.Trans
        self.ReflectVisBeamBack = self.ReflectSolBeamBack
        self.ReflectVisBeamFront = self.ReflectSolBeamFront

    if ErrorsFound:
        ShowFatalError(state, "Program halted because of input problem(s) in WindowMaterial:SimpleGlazingSystem")
