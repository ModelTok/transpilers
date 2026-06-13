"""
EnergyPlus HeatBalFiniteDiffManager module - Python port
Copyright notice and license as per original C++ source
"""

from enum import Enum
from typing import Any, Callable, List, Optional, Tuple
from dataclasses import dataclass, field
from math import sqrt, pow, fabs, floor
import copy

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state object (dataHeatBalFiniteDiffMgr, dataSurface, dataConstruction, dataMaterial,
#   dataHeatBal, dataHeatBalSurf, dataMstBal, dataGlobal, dataEnvrn, dataHeatBalFanSys, dataIPShortCut,
#   dataInputProcessing, dataZoneTempPredictorCorrector, afn)
# - Material types (Phase, phaseInts, MaterialPhaseChange, Group, hasPCM, Resistance, SpecHeat, Density,
#   Thickness, Conductivity, Porosity, ROnly, VaporDiffus, Conductivity, Name)
# - Construction types (LayerPoint, TotLayers, TypeIsWindow, TypeIsIRT, TypeIsAirBoundary, IsUsed,
#   IsCondFD, SourceSinkPresent, SourceAfterLayer, TempAfterLayer)
# - DataSurfaces types (HeatTransferModel::CondFD, ExternalEnvironment, OtherSideCondModeledExt, Ground,
#   SurfaceClass)
# - Logging: ShowSevereError, ShowContinueError, ShowFatalError, ShowSevereItemNotFound,
#   ShowContinueErrorTimeStamp, ShowRecurringSevereErrorAtEnd, ShowSevereMessage
# - IO: SetupOutputVariable, SetupEMSActuator, print
# - Utility: getEnumValue, makeUPPER, equal_dimensions
# - Constants: HighDiffusivityThreshold, ThinMaterialLayerThreshold, MinSurfaceTempLimit, Constant::*
# - Functions: dynamic_cast (type checking), nint (round half away from zero)

def nint(x: float) -> int:
    """Round half away from zero (NOT banker's rounding)."""
    if x >= 0.0:
        return int(x + 0.5)
    else:
        return int(x - 0.5)

class Array1D:
    """1-based Python wrapper for C++ Array1D<Real64>."""
    def __init__(self, size: int = 0, init_value: float = 0.0, lower: int = 1):
        self.lower = lower
        self.upper = lower + size - 1 if size > 0 else lower - 1
        self.data = [init_value] * size if size > 0 else []
        self.allocated = size > 0
    
    def allocate(self, size: int, init_value: float = 0.0):
        self.data = [init_value] * size
        self.lower = 1
        self.upper = size
        self.allocated = True
    
    def deallocate(self):
        self.data = []
        self.allocated = False
    
    def dimension(self, size: int, init_value: float = 0.0):
        self.allocate(size, init_value)
    
    def __call__(self, i: int) -> float:
        """1-based access via ()."""
        return self.data[i - self.lower]
    
    def __setitem__(self, i: int, value):
        """1-based write via []. Supports both scalar and array assignment."""
        if isinstance(value, (int, float)):
            self.data[i - self.lower] = value
        elif isinstance(value, Array1D):
            # Deep copy
            self.data = copy.copy(value.data)
        elif isinstance(value, list):
            self.data = copy.copy(value)
    
    def __getitem__(self, i: int) -> float:
        """1-based access via []."""
        return self.data[i - self.lower]
    
    def __len__(self) -> int:
        return len(self.data)
    
    def l(self) -> int:
        return self.lower
    
    def u(self) -> int:
        return self.upper
    
    def __iter__(self):
        return iter(self.data)
    
    def __setattr__(self, name, value):
        if name in ('lower', 'upper', 'data', 'allocated'):
            super().__setattr__(name, value)
        else:
            super().__setattr__(name, value)

class Array2D:
    """1-based Python wrapper for C++ Array2D<Real64>."""
    def __init__(self, rows: int = 0, cols: int = 0, init_value: float = 0.0):
        self.rows = rows
        self.cols = cols
        self.data = [init_value] * (rows * cols) if rows > 0 and cols > 0 else []
        self.allocated = len(self.data) > 0
    
    def allocate(self, rows: int, cols: int, init_value: float = 0.0):
        self.rows = rows
        self.cols = cols
        self.data = [init_value] * (rows * cols)
        self.allocated = True
    
    def deallocate(self):
        self.data = []
        self.allocated = False
    
    def dimension(self, rows: int, cols: int, init_value: float = 0.0):
        self.allocate(rows, cols, init_value)
    
    def index(self, row: int, col: int) -> int:
        """Convert 1-based (row, col) to flat index. Row-major layout."""
        return (row - 1) * self.cols + col
    
    def __getitem__(self, idx: int) -> float:
        """Raw flat access (0-based)."""
        return self.data[idx]
    
    def __setitem__(self, idx: int, value: float):
        """Raw flat access (0-based)."""
        self.data[idx] = value
    
    def __call__(self, row: int, col: int) -> float:
        """1-based access via ()."""
        return self.data[(row - 1) * self.cols + (col - 1)]
    
    def l2(self) -> int:
        return 1
    
    def u2(self) -> int:
        return self.cols
    
    def size2(self) -> int:
        return self.cols
    
    def empty(self) -> bool:
        return len(self.data) == 0

class Array1D_string:
    """1-based Python wrapper for C++ Array1D<string>."""
    def __init__(self, size: int = 0):
        self.data = [""] * size if size > 0 else []
        self.allocated = size > 0
    
    def allocate(self, size: int):
        self.data = [""] * size
        self.allocated = True
    
    def deallocate(self):
        self.data = []
        self.allocated = False
    
    def dimension(self, size: int):
        self.allocate(size)
    
    def __call__(self, i: int) -> str:
        return self.data[i - 1]
    
    def __setitem__(self, i: int, value: str):
        self.data[i - 1] = value

class Array1D_int:
    """1-based Python wrapper for C++ Array1D<int>."""
    def __init__(self, size: int = 0, init_value: int = 0):
        self.data = [init_value] * size if size > 0 else []
        self.allocated = size > 0
    
    def allocate(self, size: int, init_value: int = 0):
        self.data = [init_value] * size
        self.allocated = True
    
    def deallocate(self):
        self.data = []
        self.allocated = False
    
    def __call__(self, i: int) -> int:
        return self.data[i - 1]
    
    def __setitem__(self, i: int, value: int):
        self.data[i - 1] = value
    
    def __getitem__(self, i: int) -> int:
        return self.data[i - 1]

class CondFDScheme(Enum):
    Invalid = -1
    CrankNicholsonSecondOrder = 0
    FullyImplicitFirstOrder = 1
    Num = 2

COND_FD_SCHEME_TYPE_NAMES_CC = ["CrankNicholsonSecondOrder", "FullyImplicitFirstOrder"]
COND_FD_SCHEME_TYPE_NAMES_UC = ["CRANKNICHOLSONSECONDORDER", "FULLYIMPLICITFIRSTORDER"]

TEMP_INIT_VALUE = 23.0
RHOV_INIT_VALUE = 0.0115
ENTH_INIT_VALUE = 100.0
SMALL_DIFF = 1e-8
MIN_TEMP_LIMIT = -100.0
MAX_TEMP_LIMIT = 100.0

@dataclass
class ConstructionDataFD:
    Name: Array1D_string = field(default_factory=Array1D_string)
    DelX: Array1D = field(default_factory=Array1D)
    TempStability: Array1D = field(default_factory=Array1D)
    MoistStability: Array1D = field(default_factory=Array1D)
    NodeNumPoint: Array1D_int = field(default_factory=Array1D_int)
    Thickness: Array1D = field(default_factory=Array1D)
    NodeXlocation: Array1D = field(default_factory=Array1D)
    TotNodes: int = 0
    DeltaTime: int = 0

@dataclass
class MaterialActuatorData:
    actuatorName: str = ""
    isActuated: bool = False
    actuatedValue: float = 0.0

@dataclass
class SurfaceDataFD:
    T: Array1D = field(default_factory=Array1D)
    TOld: Array1D = field(default_factory=Array1D)
    TT: Array1D = field(default_factory=Array1D)
    Rhov: Array1D = field(default_factory=Array1D)
    RhovOld: Array1D = field(default_factory=Array1D)
    RhoT: Array1D = field(default_factory=Array1D)
    TD: Array1D = field(default_factory=Array1D)
    TDT: Array1D = field(default_factory=Array1D)
    TDTLast: Array1D = field(default_factory=Array1D)
    TDOld: Array1D = field(default_factory=Array1D)
    TDreport: Array1D = field(default_factory=Array1D)
    RH: Array1D = field(default_factory=Array1D)
    RHreport: Array1D = field(default_factory=Array1D)
    EnthOld: Array1D = field(default_factory=Array1D)
    EnthNew: Array1D = field(default_factory=Array1D)
    EnthLast: Array1D = field(default_factory=Array1D)
    QDreport: Array1D = field(default_factory=Array1D)
    CpDelXRhoS1: Array1D = field(default_factory=Array1D)
    CpDelXRhoS2: Array1D = field(default_factory=Array1D)
    TDpriortimestep: Array1D = field(default_factory=Array1D)
    SourceNodeNum: int = 0
    QSource: float = 0.0
    GSloopCounter: int = 0
    MaxNodeDelTemp: float = 0.0
    indexNodeMaxTempLimit: int = 0
    indexNodeMinTempLimit: int = 0
    EnthalpyM: float = 0.0
    EnthalpyF: float = 0.0
    PhaseChangeState: Array1D = field(default_factory=Array1D)
    PhaseChangeStateOld: Array1D = field(default_factory=Array1D)
    PhaseChangeStateOldOld: Array1D = field(default_factory=Array1D)
    PhaseChangeStateRep: Array1D_int = field(default_factory=Array1D_int)
    PhaseChangeStateOldRep: Array1D_int = field(default_factory=Array1D_int)
    PhaseChangeStateOldOldRep: Array1D_int = field(default_factory=Array1D_int)
    PhaseChangeTemperatureReverse: Array1D = field(default_factory=Array1D)
    condMaterialActuators: Array1D = field(default_factory=Array1D)
    specHeatMaterialActuators: Array1D = field(default_factory=Array1D)
    heatSourceFluxMaterialActuators: Array1D = field(default_factory=Array1D)
    condNodeReport: Array1D = field(default_factory=Array1D)
    specHeatNodeReport: Array1D = field(default_factory=Array1D)
    heatSourceInternalFluxLayerReport: Array1D = field(default_factory=Array1D)
    heatSourceInternalFluxEnergyLayerReport: Array1D = field(default_factory=Array1D)
    heatSourceEMSFluxLayerReport: Array1D = field(default_factory=Array1D)
    heatSourceEMSFluxEnergyLayerReport: Array1D = field(default_factory=Array1D)
    enetActuator: MaterialActuatorData = field(default_factory=MaterialActuatorData)
    enetActuatorReport: float = 0.0

    def UpdateMoistureBalance(self):
        self.TOld.data = copy.copy(self.T.data)
        self.RhovOld.data = copy.copy(self.Rhov.data)
        self.TDOld.data = copy.copy(self.TDreport.data)

@dataclass
class MaterialDataFD:
    tk1: float = 0.0
    numTempEnth: int = 0
    numTempCond: int = 0
    TempEnth: Array2D = field(default_factory=Array2D)
    TempCond: Array2D = field(default_factory=Array2D)

def equal_dimensions(a: Array1D, b: Array1D) -> bool:
    return len(a.data) == len(b.data)

def sum_array(arr: Array1D) -> float:
    return sum(arr.data)

def max_array(a: float, b: float) -> float:
    return a if a > b else b

def relax_array(a: Array1D, b: Array1D, r: float):
    """Relax array a towards b with factor r in [0,1]. Modifies a in place."""
    assert equal_dimensions(a, b)
    assert 0.0 <= r <= 1.0
    q = 1.0 - r
    for i in range(len(a.data)):
        a.data[i] = r * b.data[i] + q * a.data[i]

def sum_array_diff(a: Array1D, b: Array1D) -> float:
    """Sum of (a - b) element-wise. Note: NO abs()."""
    assert equal_dimensions(a, b)
    s = 0.0
    for i in range(len(a.data)):
        s += a.data[i] - b.data[i]
    return s

def terpld(a: Array2D, x1: float, nind: int, ndep: int) -> float:
    """Linear interpolation on 2D array. nind=row of independent, ndep=row of dependent."""
    if a.empty() or a.size2() == 1:
        return a[a.index(ndep, 1)]
    
    first = a.l2()
    last = first
    r = a[a.index(nind, first)]
    for i1 in range(first + 1, a.u2() + 1):
        l = a.index(nind, i1 - first)
        if a[l] > r:
            r = a[l]
            last = i1
    
    lind = a.index(nind, 0)
    ldep = a.index(ndep, 0)
    
    if x1 <= a[lind + first]:
        return a[ldep + first]
    if x1 >= a[lind + last]:
        return a[ldep + last]
    
    i1 = first
    i2 = last
    while (i2 - i1) > 1:
        i = i1 + ((i2 - i1) >> 1)
        if x1 < a[lind + i]:
            i2 = i
        else:
            i1 = i
    
    i = i2
    lind += i
    ldep += i
    fract = (x1 - a[lind - 1]) / (a[lind] - a[lind - 1])
    return a[ldep - 1] + fract * (a[ldep] - a[ldep - 1])

# Stub functions (signatures only; implementation provided by caller)
def ManageHeatBalFiniteDiff(state, SurfNum: int, SurfTempInTmp_ref, TempSurfOutTmp_ref):
    pass

def GetCondFDInput(state):
    pass

def setSizeMaxProperties(state) -> int:
    pass

def InitHeatBalFiniteDiff(state):
    pass

def InitialInitHeatBalFiniteDiff(state):
    pass

def numNodesInMaterialLayer(state, surfName: str, matName: str) -> int:
    pass

def CalcHeatBalFiniteDiff(state, Surf: int, SurfTempInTmp_ref, TempSurfOutTmp_ref):
    pass

def ReportFiniteDiffInits(state):
    pass

def CalcNodeHeatFlux(state, Surf: int, TotNodes: int):
    pass

def ExteriorBCEqns(state, Delt: int, i: int, Lay: int, Surf: int, T, TT, Rhov, RhoT, RH, TD, TDT, EnthOld, EnthNew, TotNodes: int, HMovInsul: float):
    pass

def InteriorNodeEqns(state, Delt: int, i: int, Lay: int, Surf: int, T, TT, Rhov, RhoT, RH, TD, TDT, EnthOld, EnthNew):
    pass

def IntInterfaceNodeEqns(state, Delt: int, i: int, Lay: int, Surf: int, T, TT, Rhov, RhoT, RH, TD, TDT, EnthOld, EnthNew, GSiter: int):
    pass

def InteriorBCEqns(state, Delt: int, i: int, Lay: int, SurfNum: int, T, TT, Rhov, RhoT, RH, TD, TDT, EnthOld, EnthNew, TDreport):
    pass

def CheckFDSurfaceTempLimits(state, SurfNum: int, CheckTemperature: float):
    pass

def CheckFDNodeTempLimits(state, surfNum: int, nodeNum: int, nodeTemp_ref):
    pass

def adjustPropertiesForPhaseChange(state, finiteDifferenceLayerIndex: int, surfNum: int, mat, temperaturePrevious: float, temperatureUpdated: float):
    pass

def findAnySurfacesUsingConstructionAndCondFD(state, constructionNum: int) -> bool:
    pass
