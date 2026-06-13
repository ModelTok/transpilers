from dataclasses import dataclass, field
from typing import List, Optional, Callable

# EXTERNAL DEPS (to wire in glue):
# - DataPrecisionGlobals: defines r64 as 64-bit float precision type

r64 = float

PROGRAM_NAME = 'Slab'


@dataclass
class WeatherData:
    TDB: List[float] = field(default_factory=lambda: [0.0] * 24)
    TWB: List[float] = field(default_factory=lambda: [0.0] * 24)
    PBAR: List[float] = field(default_factory=lambda: [0.0] * 24)
    HRAT: List[float] = field(default_factory=lambda: [0.0] * 24)
    WND: List[float] = field(default_factory=lambda: [0.0] * 24)
    RBEAM: List[float] = field(default_factory=lambda: [0.0] * 24)
    RDIF: List[float] = field(default_factory=lambda: [0.0] * 24)
    ISNW: List[int] = field(default_factory=lambda: [0] * 24)
    DSNOW: List[float] = field(default_factory=lambda: [0.0] * 24)


@dataclass
class SiteParameters:
    LONG: float = 0.0
    LAT: float = 0.0
    MSTD: float = 0.0
    ELEV: float = 0.0


@dataclass
class ETemp:
    RSKY: float = 0.0
    HHEAT: float = 0.0
    HMASS: float = 0.0
    DODPG: float = 0.0
    TG: List[float] = field(default_factory=lambda: [0.0] * 36)


@dataclass
class Soil_SurfaceProperties:
    NumMaterials: int = 0
    ALBEDO: List[float] = field(default_factory=lambda: [0.0] * 2)
    EPSLW: List[float] = field(default_factory=lambda: [0.0] * 2)
    Z0: List[float] = field(default_factory=lambda: [0.0] * 2)
    HIN: List[float] = field(default_factory=lambda: [0.0] * 2)


@dataclass
class BoundaryConds:
    EVTR: str = ""
    FIXBC: str = ""
    TDEEPin: float = 0.0
    USERHFlag: str = ""
    USERH: float = 0.0


@dataclass
class InputGridProps:
    NX: int = 0
    NY: int = 0
    NZ: int = 0


@dataclass
class BldgProps:
    IYRS: int = 0
    Shape: int = 0
    HBLDG: float = 0.0
    TINave: List[float] = field(default_factory=lambda: [0.0] * 12)
    TIN: float = 0.0
    TINAmp: float = 0.0
    NumberOfTIN: int = 0
    ConvTol: float = 0.0


@dataclass
class Insulation:
    RINS: float = 0.0
    DINS: float = 0.0
    RVINS: float = 0.0
    ZVINS: float = 0.0
    IVINS: int = 0


@dataclass
class BuildingDimensions:
    IBOX: int = 0
    JBOX: int = 0


@dataclass
class GroundTemp:
    TG: List[float] = field(default_factory=lambda: [0.0] * 36)


XFACE: List[float] = [0.0] * 71
YFACE: List[float] = [0.0] * 71
ZFACE: List[float] = [0.0] * 36
RHO: List[float] = [0.0] * 2
TCON: List[float] = [0.0] * 2
CP: List[float] = [0.0] * 2
COUNT1: int = 0
COUNT2: int = 0
COUNT3: int = 0

SLABX: float = 0.0
SLABY: float = 0.0
CLEARANCE: float = 0.0
SLABDEPTH: float = 0.0
ZCLEARANCE: float = 0.0
APRatio: float = 0.0
EquivSizing: str = ""

TodaysWeather: WeatherData = WeatherData()
Site: SiteParameters = SiteParameters()
SSP: Soil_SurfaceProperties = Soil_SurfaceProperties()
BCS: BoundaryConds = BoundaryConds()
InitGrid: InputGridProps = InputGridProps()
BuildingData: BldgProps = BldgProps()
Insul: Insulation = Insulation()
Slab: BuildingDimensions = BuildingDimensions()
TGround: GroundTemp = GroundTemp()
EarthTemp: List[List[ETemp]] = [[ETemp() for _ in range(365)] for _ in range(24)]

GetNewUnitNumber: Optional[Callable[[], int]] = None

DebugInfo: int = 0
InputEcho: int = 0
DailyFlux: int = 0
History: int = 0
FluxDistn: int = 0
TempDistn: int = 0
SurfaceTemps: int = 0
CLTemps: int = 0
SplitSurfTemps: int = 0
Weather: int = 0
TempInit: int = 0
NUMRUNS: int = 0
RUNNUM: int = 0
