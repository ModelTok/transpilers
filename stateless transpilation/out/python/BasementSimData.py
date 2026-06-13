from dataclasses import dataclass, field
from typing import List, Dict, Optional, Callable

# EXTERNAL DEPS (to wire in glue):
# - DataPrecisionGlobals.r64: type alias for float (from Fortran source BasementSimData)
# - GetNewUnitNumber: external function returning int (from Fortran source BasementSimData)

MATLYPES = [
    'Foundation Wall',
    'Floor Slab     ',
    'Ceiling        ',
    'Soil           ',
    'Gravel         ',
    'Wood           ',
    'Air            '
]

SIGMA = 5.6697e-8
VONKAR = 0.41
G = 9.806


@dataclass
class WeatherData:
    TDB: List[float] = field(default_factory=lambda: [0.0] * 24)
    TWB: List[float] = field(default_factory=lambda: [0.0] * 24)
    PBAR: List[float] = field(default_factory=lambda: [0.0] * 24)
    HRAT: List[float] = field(default_factory=lambda: [0.0] * 24)
    WND: List[float] = field(default_factory=lambda: [0.0] * 24)
    RBEAM: List[float] = field(default_factory=lambda: [0.0] * 24)
    RDIFH: List[float] = field(default_factory=lambda: [0.0] * 24)
    ISNW: List[int] = field(default_factory=lambda: [0] * 24)
    DSNOW: List[float] = field(default_factory=lambda: [0.0] * 24)


@dataclass
class SiteParameters:
    LONG: float = 0.0
    LAT: float = 0.0
    MSTD: float = 0.0
    ELEV: float = 0.0
    AHH: int = 0
    ACH: int = 0


@dataclass
class Boundaries:
    NMAT: int = 0
    OLDTG: str = ''
    TGNAM: str = ''
    TWRITE: str = ''
    TREAD: str = ''
    TINIT: str = ''
    FIXBC: str = ''


@dataclass
class Insulation:
    REXT: float = 0.0
    RINT: float = 0.0
    INSFULL: str = ''
    RSID: float = 0.0
    RSILL: float = 0.0
    RCEIL: float = 0.0
    RSNOW: str = ''


@dataclass
class SurfaceProperties:
    ALBEDO: List[float] = field(default_factory=lambda: [0.0, 0.0])
    EPSLN: List[float] = field(default_factory=lambda: [0.0, 0.0])
    VEGHT: List[float] = field(default_factory=lambda: [0.0, 0.0])
    PET: str = ''


@dataclass
class BuildingParameters:
    DWALL: float = 0.0
    DSLAB: float = 0.0
    DGRAVXY: float = 0.0
    DGRAVZN: float = 0.0
    DGRAVZP: float = 0.0


@dataclass
class InteriorParameters:
    COND: str = ''
    TIN: List[float] = field(default_factory=lambda: [0.0, 0.0])
    HIN: List[float] = field(default_factory=lambda: [0.0] * 6)


@dataclass
class SimulationParameters:
    F: float = 0.0
    IYRS: int = 0
    TSTEP: float = 0.0


WeatherFile: str = ''
SNOW: str = ''
EquivSizing: str = ''
AUTOGRID: str = ''
Eplus: str = ''
ComBldg: str = ''
EPWFile: str = ''

RHO: List[float] = [0.0] * 7
CP: List[float] = [0.0] * 7
TCON: List[float] = [0.0] * 7

SLABX: float = 0.0
SLABY: float = 0.0
SlabDepth: float = 0.0
ConcAGHeight: float = 0.0
BaseDepth: float = 0.0
APRatio: float = 0.0

XFACE: List[float] = [0.0] * 101
YFACE: List[float] = [0.0] * 101
ZFACE: Dict[int, float] = {i: 0.0 for i in range(-35, 101)}
ZFACEINIT: Dict[int, float] = {i: 0.0 for i in range(-35, 101)}

TBasement: float = 0.0
TBasementAve: List[float] = [0.0] * 12
TBasementDailyAmp: float = 0.0
TDeadBandUp: float = 0.0
TDeadBandLow: float = 0.0

CLEARANCE: int = 0
COUNT1: int = 0
COUNT2: int = 0
COUNT3: int = 0

NDIM: List[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
NFDM: List[int] = [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

NX: int = 0
NY: int = 0
NZAG: int = 0
NZBG: int = 0
NZ1: int = 0
IBASE: int = 0
JBASE: int = 0
KBASE: int = 0
NUM: int = 0
IDAY: int = 0

GetNewUnitNumber: Optional[Callable[[], int]] = None

Weather: int = 0
SolarFile: int = 0
InputEcho: int = 0
GroundTemp: int = 0
QHouseFile: int = 0
DOUT: int = 0
DYFLX: int = 0
YTDBFile: int = 0
InitT: int = 0
LOADFile: int = 0
Ceil121: int = 0
Flor121: int = 0
RMJS121: int = 0
RMJW121: int = 0
WALS121: int = 0
WALW121: int = 0
SILS121: int = 0
SILW121: int = 0
CeilD21: int = 0
FlorD21: int = 0
RMJSD21: int = 0
RMJWD21: int = 0
WALSD21: int = 0
WALWD21: int = 0
XZYZero: int = 0
XZYHalf: int = 0
XZYFull: int = 0
XZWallTs: int = 0
YZWallTs: int = 0
FloorTs: int = 0
XZWallSplit: int = 0
YZWallSplit: int = 0
FloorSplit: int = 0
Centerline: int = 0
SILSD21: int = 0
SILWD21: int = 0
Weather2: int = 0
AvgTG: int = 0
Debugoutfile: int = 0
floorflux: int = 0
xzwallflux: int = 0
yzwallflux: int = 0
EPMonthly: int = 0
EPObjects: int = 0

TodaysWeather: WeatherData = WeatherData()
FullYearWeather: List[WeatherData] = [WeatherData() for _ in range(365)]
SiteInfo: SiteParameters = SiteParameters()
BCS: Boundaries = Boundaries()
Insul: Insulation = Insulation(
    REXT=0.00001,
    RINT=0.00001,
    INSFULL='F',
    RSID=0.00001,
    RSILL=0.00001,
    RCEIL=0.00001,
    RSNOW='F'
)
SP: SurfaceProperties = SurfaceProperties()
BuildingData: BuildingParameters = BuildingParameters()
Interior: InteriorParameters = InteriorParameters()
SimParams: SimulationParameters = SimulationParameters()
