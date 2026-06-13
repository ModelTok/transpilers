# EXTERNAL DEPS (to wire in glue):
# - DataPrecisionGlobals.r64: type alias for Float64 (from Fortran source BasementSimData)
# - GetNewUnitNumber: external function returning Int32 (from Fortran source BasementSimData)

from collections.list import List
from collections.dict import Dict

alias r64 = Float64

fn _init_matlypes() -> List[String]:
    var result = List[String]()
    result.append("Foundation Wall")
    result.append("Floor Slab     ")
    result.append("Ceiling        ")
    result.append("Soil           ")
    result.append("Gravel         ")
    result.append("Wood           ")
    result.append("Air            ")
    return result

var MATLYPES = _init_matlypes()

alias SIGMA: r64 = 5.6697e-8
alias VONKAR: r64 = 0.41
alias G: r64 = 9.806


@value
struct WeatherData:
    var TDB: InlineArray[r64, 24]
    var TWB: InlineArray[r64, 24]
    var PBAR: InlineArray[r64, 24]
    var HRAT: InlineArray[r64, 24]
    var WND: InlineArray[r64, 24]
    var RBEAM: InlineArray[r64, 24]
    var RDIFH: InlineArray[r64, 24]
    var ISNW: InlineArray[Int32, 24]
    var DSNOW: InlineArray[r64, 24]

    fn __init__(inout self):
        self.TDB = InlineArray[r64, 24](fill=0.0)
        self.TWB = InlineArray[r64, 24](fill=0.0)
        self.PBAR = InlineArray[r64, 24](fill=0.0)
        self.HRAT = InlineArray[r64, 24](fill=0.0)
        self.WND = InlineArray[r64, 24](fill=0.0)
        self.RBEAM = InlineArray[r64, 24](fill=0.0)
        self.RDIFH = InlineArray[r64, 24](fill=0.0)
        self.ISNW = InlineArray[Int32, 24](fill=0)
        self.DSNOW = InlineArray[r64, 24](fill=0.0)


@value
struct SiteParameters:
    var LONG: r64
    var LAT: r64
    var MSTD: r64
    var ELEV: r64
    var AHH: Int32
    var ACH: Int32

    fn __init__(inout self):
        self.LONG = 0.0
        self.LAT = 0.0
        self.MSTD = 0.0
        self.ELEV = 0.0
        self.AHH = 0
        self.ACH = 0


@value
struct Boundaries:
    var NMAT: Int32
    var OLDTG: String
    var TGNAM: String
    var TWRITE: String
    var TREAD: String
    var TINIT: String
    var FIXBC: String

    fn __init__(inout self):
        self.NMAT = 0
        self.OLDTG = ""
        self.TGNAM = ""
        self.TWRITE = ""
        self.TREAD = ""
        self.TINIT = ""
        self.FIXBC = ""


@value
struct Insulation:
    var REXT: r64
    var RINT: r64
    var INSFULL: String
    var RSID: r64
    var RSILL: r64
    var RCEIL: r64
    var RSNOW: String

    fn __init__(inout self):
        self.REXT = 0.0
        self.RINT = 0.0
        self.INSFULL = ""
        self.RSID = 0.0
        self.RSILL = 0.0
        self.RCEIL = 0.0
        self.RSNOW = ""

    fn __init__(inout self, rext: r64, rint: r64, insfull: String, rsid: r64, rsill: r64, rceil: r64, rsnow: String):
        self.REXT = rext
        self.RINT = rint
        self.INSFULL = insfull
        self.RSID = rsid
        self.RSILL = rsill
        self.RCEIL = rceil
        self.RSNOW = rsnow


@value
struct SurfaceProperties:
    var ALBEDO: InlineArray[r64, 2]
    var EPSLN: InlineArray[r64, 2]
    var VEGHT: InlineArray[r64, 2]
    var PET: String

    fn __init__(inout self):
        self.ALBEDO = InlineArray[r64, 2](fill=0.0)
        self.EPSLN = InlineArray[r64, 2](fill=0.0)
        self.VEGHT = InlineArray[r64, 2](fill=0.0)
        self.PET = ""


@value
struct BuildingParameters:
    var DWALL: r64
    var DSLAB: r64
    var DGRAVXY: r64
    var DGRAVZN: r64
    var DGRAVZP: r64

    fn __init__(inout self):
        self.DWALL = 0.0
        self.DSLAB = 0.0
        self.DGRAVXY = 0.0
        self.DGRAVZN = 0.0
        self.DGRAVZP = 0.0


@value
struct InteriorParameters:
    var COND: String
    var TIN: InlineArray[r64, 2]
    var HIN: InlineArray[r64, 6]

    fn __init__(inout self):
        self.COND = ""
        self.TIN = InlineArray[r64, 2](fill=0.0)
        self.HIN = InlineArray[r64, 6](fill=0.0)


@value
struct SimulationParameters:
    var F: r64
    var IYRS: Int32
    var TSTEP: r64

    fn __init__(inout self):
        self.F = 0.0
        self.IYRS = 0
        self.TSTEP = 0.0


var WeatherFile: String = ""
var SNOW: String = ""
var EquivSizing: String = ""
var AUTOGRID: String = ""
var Eplus: String = ""
var ComBldg: String = ""
var EPWFile: String = ""

var RHO: List[r64] = List[r64]()
var CP: List[r64] = List[r64]()
var TCON: List[r64] = List[r64]()

var SLABX: r64 = 0.0
var SLABY: r64 = 0.0
var SlabDepth: r64 = 0.0
var ConcAGHeight: r64 = 0.0
var BaseDepth: r64 = 0.0
var APRatio: r64 = 0.0

var XFACE: List[r64] = List[r64]()
var YFACE: List[r64] = List[r64]()
var ZFACE: Dict[Int, r64] = Dict[Int, r64]()
var ZFACEINIT: Dict[Int, r64] = Dict[Int, r64]()

var TBasement: r64 = 0.0
var TBasementAve: List[r64] = List[r64]()
var TBasementDailyAmp: r64 = 0.0
var TDeadBandUp: r64 = 0.0
var TDeadBandLow: r64 = 0.0

var CLEARANCE: Int32 = 0
var COUNT1: Int32 = 0
var COUNT2: Int32 = 0
var COUNT3: Int32 = 0

var NDIM: InlineArray[Int32, 12] = InlineArray[Int32, 12]()
var NFDM: InlineArray[Int32, 12] = InlineArray[Int32, 12]()

var NX: Int32 = 0
var NY: Int32 = 0
var NZAG: Int32 = 0
var NZBG: Int32 = 0
var NZ1: Int32 = 0
var IBASE: Int32 = 0
var JBASE: Int32 = 0
var KBASE: Int32 = 0
var NUM: Int32 = 0
var IDAY: Int32 = 0

var Weather: Int32 = 0
var SolarFile: Int32 = 0
var InputEcho: Int32 = 0
var GroundTemp: Int32 = 0
var QHouseFile: Int32 = 0
var DOUT: Int32 = 0
var DYFLX: Int32 = 0
var YTDBFile: Int32 = 0
var InitT: Int32 = 0
var LOADFile: Int32 = 0
var Ceil121: Int32 = 0
var Flor121: Int32 = 0
var RMJS121: Int32 = 0
var RMJW121: Int32 = 0
var WALS121: Int32 = 0
var WALW121: Int32 = 0
var SILS121: Int32 = 0
var SILW121: Int32 = 0
var CeilD21: Int32 = 0
var FlorD21: Int32 = 0
var RMJSD21: Int32 = 0
var RMJWD21: Int32 = 0
var WALSD21: Int32 = 0
var WALWD21: Int32 = 0
var XZYZero: Int32 = 0
var XZYHalf: Int32 = 0
var XZYFull: Int32 = 0
var XZWallTs: Int32 = 0
var YZWallTs: Int32 = 0
var FloorTs: Int32 = 0
var XZWallSplit: Int32 = 0
var YZWallSplit: Int32 = 0
var FloorSplit: Int32 = 0
var Centerline: Int32 = 0
var SILSD21: Int32 = 0
var SILWD21: Int32 = 0
var Weather2: Int32 = 0
var AvgTG: Int32 = 0
var Debugoutfile: Int32 = 0
var floorflux: Int32 = 0
var xzwallflux: Int32 = 0
var yzwallflux: Int32 = 0
var EPMonthly: Int32 = 0
var EPObjects: Int32 = 0

fn _init_module_vars():
    for _ in range(7):
        RHO.append(0.0)
        CP.append(0.0)
        TCON.append(0.0)
    for _ in range(101):
        XFACE.append(0.0)
        YFACE.append(0.0)
    for i in range(-35, 101):
        ZFACE[i] = 0.0
        ZFACEINIT[i] = 0.0
    for _ in range(12):
        TBasementAve.append(0.0)
    NDIM[0] = 31
    NDIM[1] = 28
    NDIM[2] = 31
    NDIM[3] = 30
    NDIM[4] = 31
    NDIM[5] = 30
    NDIM[6] = 31
    NDIM[7] = 31
    NDIM[8] = 30
    NDIM[9] = 31
    NDIM[10] = 30
    NDIM[11] = 31
    NFDM[0] = 1
    NFDM[1] = 32
    NFDM[2] = 60
    NFDM[3] = 91
    NFDM[4] = 121
    NFDM[5] = 152
    NFDM[6] = 182
    NFDM[7] = 213
    NFDM[8] = 244
    NFDM[9] = 274
    NFDM[10] = 305
    NFDM[11] = 335

var TodaysWeather: WeatherData = WeatherData()
var FullYearWeather: List[WeatherData] = List[WeatherData]()
var SiteInfo: SiteParameters = SiteParameters()
var BCS: Boundaries = Boundaries()
var Insul: Insulation = Insulation(0.00001, 0.00001, "F", 0.00001, 0.00001, 0.00001, "F")
var SP: SurfaceProperties = SurfaceProperties()
var BuildingData: BuildingParameters = BuildingParameters()
var Interior: InteriorParameters = InteriorParameters()
var SimParams: SimulationParameters = SimulationParameters()

fn _init_full_year_weather():
    for _ in range(365):
        FullYearWeather.append(WeatherData())

_init_module_vars()
_init_full_year_weather()
