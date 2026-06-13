from collections import InlineArray
from math import max

alias r64 = Float64

var PROGRAM_NAME: StringLiteral = "Slab"


struct WeatherData:
    var TDB: InlineArray[Float64, 24]
    var TWB: InlineArray[Float64, 24]
    var PBAR: InlineArray[Float64, 24]
    var HRAT: InlineArray[Float64, 24]
    var WND: InlineArray[Float64, 24]
    var RBEAM: InlineArray[Float64, 24]
    var RDIF: InlineArray[Float64, 24]
    var ISNW: InlineArray[Int32, 24]
    var DSNOW: InlineArray[Float64, 24]

    fn __init__(inout self):
        self.TDB = InlineArray[Float64, 24](fill=0.0)
        self.TWB = InlineArray[Float64, 24](fill=0.0)
        self.PBAR = InlineArray[Float64, 24](fill=0.0)
        self.HRAT = InlineArray[Float64, 24](fill=0.0)
        self.WND = InlineArray[Float64, 24](fill=0.0)
        self.RBEAM = InlineArray[Float64, 24](fill=0.0)
        self.RDIF = InlineArray[Float64, 24](fill=0.0)
        self.ISNW = InlineArray[Int32, 24](fill=0)
        self.DSNOW = InlineArray[Float64, 24](fill=0.0)


struct SiteParameters:
    var LONG: Float64
    var LAT: Float64
    var MSTD: Float64
    var ELEV: Float64

    fn __init__(inout self):
        self.LONG = 0.0
        self.LAT = 0.0
        self.MSTD = 0.0
        self.ELEV = 0.0


struct ETemp:
    var RSKY: Float64
    var HHEAT: Float64
    var HMASS: Float64
    var DODPG: Float64
    var TG: InlineArray[Float64, 36]

    fn __init__(inout self):
        self.RSKY = 0.0
        self.HHEAT = 0.0
        self.HMASS = 0.0
        self.DODPG = 0.0
        self.TG = InlineArray[Float64, 36](fill=0.0)


struct Soil_SurfaceProperties:
    var NumMaterials: Int32
    var ALBEDO: InlineArray[Float64, 2]
    var EPSLW: InlineArray[Float64, 2]
    var Z0: InlineArray[Float64, 2]
    var HIN: InlineArray[Float64, 2]

    fn __init__(inout self):
        self.NumMaterials = 0
        self.ALBEDO = InlineArray[Float64, 2](fill=0.0)
        self.EPSLW = InlineArray[Float64, 2](fill=0.0)
        self.Z0 = InlineArray[Float64, 2](fill=0.0)
        self.HIN = InlineArray[Float64, 2](fill=0.0)


struct BoundaryConds:
    var EVTR: String
    var FIXBC: String
    var TDEEPin: Float64
    var USERHFlag: String
    var USERH: Float64

    fn __init__(inout self):
        self.EVTR = ""
        self.FIXBC = ""
        self.TDEEPin = 0.0
        self.USERHFlag = ""
        self.USERH = 0.0


struct InputGridProps:
    var NX: Int32
    var NY: Int32
    var NZ: Int32

    fn __init__(inout self):
        self.NX = 0
        self.NY = 0
        self.NZ = 0


struct BldgProps:
    var IYRS: Int32
    var Shape: Int32
    var HBLDG: Float64
    var TINave: InlineArray[Float64, 12]
    var TIN: Float64
    var TINAmp: Float64
    var NumberOfTIN: Int32
    var ConvTol: Float64

    fn __init__(inout self):
        self.IYRS = 0
        self.Shape = 0
        self.HBLDG = 0.0
        self.TINave = InlineArray[Float64, 12](fill=0.0)
        self.TIN = 0.0
        self.TINAmp = 0.0
        self.NumberOfTIN = 0
        self.ConvTol = 0.0


struct Insulation:
    var RINS: Float64
    var DINS: Float64
    var RVINS: Float64
    var ZVINS: Float64
    var IVINS: Int32

    fn __init__(inout self):
        self.RINS = 0.0
        self.DINS = 0.0
        self.RVINS = 0.0
        self.ZVINS = 0.0
        self.IVINS = 0


struct BuildingDimensions:
    var IBOX: Int32
    var JBOX: Int32

    fn __init__(inout self):
        self.IBOX = 0
        self.JBOX = 0


struct GroundTemp:
    var TG: InlineArray[Float64, 36]

    fn __init__(inout self):
        self.TG = InlineArray[Float64, 36](fill=0.0)


struct EarthTempArray:
    var data: InlineArray[InlineArray[ETemp, 365], 24]

    fn __init__(inout self):
        @parameter
        for i in range(24):
            @parameter
            for j in range(365):
                self.data[i][j] = ETemp()


var XFACE: InlineArray[Float64, 71] = InlineArray[Float64, 71](fill=0.0)
var YFACE: InlineArray[Float64, 71] = InlineArray[Float64, 71](fill=0.0)
var ZFACE: InlineArray[Float64, 36] = InlineArray[Float64, 36](fill=0.0)
var RHO: InlineArray[Float64, 2] = InlineArray[Float64, 2](fill=0.0)
var TCON: InlineArray[Float64, 2] = InlineArray[Float64, 2](fill=0.0)
var CP: InlineArray[Float64, 2] = InlineArray[Float64, 2](fill=0.0)
var COUNT1: Int32 = 0
var COUNT2: Int32 = 0
var COUNT3: Int32 = 0

var SLABX: Float64 = 0.0
var SLABY: Float64 = 0.0
var CLEARANCE: Float64 = 0.0
var SLABDEPTH: Float64 = 0.0
var ZCLEARANCE: Float64 = 0.0
var APRatio: Float64 = 0.0
var EquivSizing: String = ""

var TodaysWeather: WeatherData = WeatherData()
var Site: SiteParameters = SiteParameters()
var SSP: Soil_SurfaceProperties = Soil_SurfaceProperties()
var BCS: BoundaryConds = BoundaryConds()
var InitGrid: InputGridProps = InputGridProps()
var BuildingData: BldgProps = BldgProps()
var Insul: Insulation = Insulation()
var Slab: BuildingDimensions = BuildingDimensions()
var TGround: GroundTemp = GroundTemp()
var EarthTemp: EarthTempArray = EarthTempArray()

var GetNewUnitNumber: Optional[fn() -> Int32] = None

var DebugInfo: Int32 = 0
var InputEcho: Int32 = 0
var DailyFlux: Int32 = 0
var History: Int32 = 0
var FluxDistn: Int32 = 0
var TempDistn: Int32 = 0
var SurfaceTemps: Int32 = 0
var CLTemps: Int32 = 0
var SplitSurfTemps: Int32 = 0
var Weather: Int32 = 0
var TempInit: Int32 = 0
var NUMRUNS: Int32 = 0
var RUNNUM: Int32 = 0
