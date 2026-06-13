"""
EnergyPlus HeatBalFiniteDiffManager module - Mojo port
Copyright notice and license as per original C++ source
"""

from math import sqrt, pow, fabs, floor
from collections import List, Dict
from memory import DynamicVector, Reference, UnsafePointer

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state object (dataHeatBalFiniteDiffMgr, dataSurface, dataConstruction, dataMaterial,
#   dataHeatBal, dataHeatBalSurf, dataMstBal, dataGlobal, dataEnvrn, dataHeatBalFanSys, dataIPShortCut,
#   dataInputProcessing, dataZoneTempPredictorCorrector, afn)
# - Material types (Phase, phaseInts, MaterialPhaseChange, Group, hasPCM, Resistance, SpecHeat, Density,
#   Thickness, Conductivity, Porosity, ROnly, VaporDiffus, Name)
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

fn nint(x: Float64) -> Int32:
    """Round half away from zero (NOT banker's rounding)."""
    if x >= 0.0:
        return Int32(x + 0.5)
    else:
        return Int32(x - 0.5)

struct Array1D:
    """1-based Mojo wrapper for C++ Array1D<Real64>."""
    var data: List[Float64]
    var lower: Int32
    var upper: Int32
    var allocated: Bool
    
    fn __init__(inout self, size: Int32 = 0, init_value: Float64 = 0.0, lower: Int32 = 1):
        self.lower = lower
        self.upper = lower + size - 1 if size > 0 else lower - 1
        self.data = List[Float64](capacity=size)
        for _ in range(size):
            self.data.append(init_value)
        self.allocated = size > 0
    
    fn allocate(inout self, size: Int32, init_value: Float64 = 0.0):
        self.data = List[Float64](capacity=size)
        for _ in range(size):
            self.data.append(init_value)
        self.lower = 1
        self.upper = size
        self.allocated = True
    
    fn deallocate(inout self):
        self.data = List[Float64]()
        self.allocated = False
    
    fn dimension(inout self, size: Int32, init_value: Float64 = 0.0):
        self.allocate(size, init_value)
    
    fn __call__(self, i: Int32) -> Float64:
        """1-based access via ()."""
        return self.data[i - self.lower]
    
    fn set(inout self, i: Int32, value: Float64):
        """1-based write."""
        self.data[i - self.lower] = value
    
    fn __getitem__(self, i: Int32) -> Float64:
        """1-based access via []."""
        return self.data[i - self.lower]
    
    fn __len__(self) -> Int32:
        return Int32(len(self.data))
    
    fn l(self) -> Int32:
        return self.lower
    
    fn u(self) -> Int32:
        return self.upper

struct Array2D:
    """1-based Mojo wrapper for C++ Array2D<Real64>."""
    var data: List[Float64]
    var rows: Int32
    var cols: Int32
    var allocated: Bool
    
    fn __init__(inout self, rows: Int32 = 0, cols: Int32 = 0, init_value: Float64 = 0.0):
        self.rows = rows
        self.cols = cols
        self.data = List[Float64](capacity=rows * cols)
        for _ in range(rows * cols):
            self.data.append(init_value)
        self.allocated = len(self.data) > 0
    
    fn allocate(inout self, rows: Int32, cols: Int32, init_value: Float64 = 0.0):
        self.rows = rows
        self.cols = cols
        self.data = List[Float64](capacity=rows * cols)
        for _ in range(rows * cols):
            self.data.append(init_value)
        self.allocated = True
    
    fn deallocate(inout self):
        self.data = List[Float64]()
        self.allocated = False
    
    fn dimension(inout self, rows: Int32, cols: Int32, init_value: Float64 = 0.0):
        self.allocate(rows, cols, init_value)
    
    fn index(self, row: Int32, col: Int32) -> Int32:
        """Convert 1-based (row, col) to flat index. Row-major layout."""
        return (row - 1) * self.cols + col
    
    fn __getitem__(self, idx: Int32) -> Float64:
        """Raw flat access."""
        return self.data[idx]
    
    fn set(inout self, idx: Int32, value: Float64):
        """Raw flat write."""
        self.data[idx] = value
    
    fn l2(self) -> Int32:
        return 1
    
    fn u2(self) -> Int32:
        return self.cols
    
    fn size2(self) -> Int32:
        return self.cols
    
    fn empty(self) -> Bool:
        return len(self.data) == 0

struct Array1D_string:
    """1-based Mojo wrapper for C++ Array1D<string>."""
    var data: List[String]
    var allocated: Bool
    
    fn __init__(inout self, size: Int32 = 0):
        self.data = List[String](capacity=size)
        for _ in range(size):
            self.data.append("")
        self.allocated = size > 0
    
    fn allocate(inout self, size: Int32):
        self.data = List[String](capacity=size)
        for _ in range(size):
            self.data.append("")
        self.allocated = True
    
    fn deallocate(inout self):
        self.data = List[String]()
        self.allocated = False
    
    fn __call__(self, i: Int32) -> String:
        return self.data[i - 1]
    
    fn set(inout self, i: Int32, value: String):
        self.data[i - 1] = value

struct Array1D_int:
    """1-based Mojo wrapper for C++ Array1D<int>."""
    var data: List[Int32]
    var allocated: Bool
    
    fn __init__(inout self, size: Int32 = 0, init_value: Int32 = 0):
        self.data = List[Int32](capacity=size)
        for _ in range(size):
            self.data.append(init_value)
        self.allocated = size > 0
    
    fn allocate(inout self, size: Int32, init_value: Int32 = 0):
        self.data = List[Int32](capacity=size)
        for _ in range(size):
            self.data.append(init_value)
        self.allocated = True
    
    fn __call__(self, i: Int32) -> Int32:
        return self.data[i - 1]
    
    fn set(inout self, i: Int32, value: Int32):
        self.data[i - 1] = value
    
    fn __getitem__(self, i: Int32) -> Int32:
        return self.data[i - 1]

fn equal_dimensions(a: Reference[Array1D], b: Reference[Array1D]) -> Bool:
    return len(a[].data) == len(b[].data)

fn sum_array(arr: Reference[Array1D]) -> Float64:
    var s: Float64 = 0.0
    for v in arr[].data:
        s += v
    return s

fn max_array(a: Float64, b: Float64) -> Float64:
    return a if a > b else b

fn relax_array(inout a: Array1D, b: Reference[Array1D], r: Float64):
    """Relax array a towards b with factor r in [0,1]. Modifies a in place."""
    debug_assert(equal_dimensions(Reference(a), b))
    debug_assert(0.0 <= r <= 1.0)
    var q: Float64 = 1.0 - r
    for i in range(len(a.data)):
        a.data[i] = r * b[].data[i] + q * a.data[i]

fn sum_array_diff(a: Reference[Array1D], b: Reference[Array1D]) -> Float64:
    """Sum of (a - b) element-wise. Note: NO abs()."""
    debug_assert(equal_dimensions(a, b))
    var s: Float64 = 0.0
    for i in range(len(a[].data)):
        s += a[].data[i] - b[].data[i]
    return s

fn terpld(a: Reference[Array2D], x1: Float64, nind: Int32, ndep: Int32) -> Float64:
    """Linear interpolation on 2D array. nind=row of independent, ndep=row of dependent."""
    if a[].empty() or a[].size2() == 1:
        return a[][a[].index(ndep, 1)]
    
    var first: Int32 = a[].l2()
    var last: Int32 = first
    var r: Float64 = a[][a[].index(nind, first)]
    for i1 in range(first + 1, a[].u2() + 1):
        var l: Int32 = a[].index(nind, i1 - first)
        if a[][l] > r:
            r = a[][l]
            last = i1
    
    var lind: Int32 = a[].index(nind, 0)
    var ldep: Int32 = a[].index(ndep, 0)
    
    if x1 <= a[][lind + first]:
        return a[][ldep + first]
    if x1 >= a[][lind + last]:
        return a[][ldep + last]
    
    var i1: Int32 = first
    var i2: Int32 = last
    while (i2 - i1) > 1:
        var i: Int32 = i1 + ((i2 - i1) >> 1)
        if x1 < a[][lind + i]:
            i2 = i
        else:
            i1 = i
    
    var i: Int32 = i2
    lind += i
    ldep += i
    var fract: Float64 = (x1 - a[][lind - 1]) / (a[][lind] - a[][lind - 1])
    return a[][ldep - 1] + fract * (a[][ldep] - a[][ldep - 1])

struct CondFDScheme:
    var value: Int32
    alias Invalid = 0
    alias CrankNicholsonSecondOrder = 1
    alias FullyImplicitFirstOrder = 2
    alias Num = 3

alias COND_FD_SCHEME_TYPE_NAMES_CC = ("CrankNicholsonSecondOrder", "FullyImplicitFirstOrder")
alias COND_FD_SCHEME_TYPE_NAMES_UC = ("CRANKNICHOLSONSECONDORDER", "FULLYIMPLICITFIRSTORDER")

alias TEMP_INIT_VALUE: Float64 = 23.0
alias RHOV_INIT_VALUE: Float64 = 0.0115
alias ENTH_INIT_VALUE: Float64 = 100.0
alias SMALL_DIFF: Float64 = 1e-8
alias MIN_TEMP_LIMIT: Float64 = -100.0
alias MAX_TEMP_LIMIT: Float64 = 100.0

struct ConstructionDataFD:
    var Name: Array1D_string
    var DelX: Array1D
    var TempStability: Array1D
    var MoistStability: Array1D
    var NodeNumPoint: Array1D_int
    var Thickness: Array1D
    var NodeXlocation: Array1D
    var TotNodes: Int32
    var DeltaTime: Int32
    
    fn __init__(inout self):
        self.Name = Array1D_string()
        self.DelX = Array1D()
        self.TempStability = Array1D()
        self.MoistStability = Array1D()
        self.NodeNumPoint = Array1D_int()
        self.Thickness = Array1D()
        self.NodeXlocation = Array1D()
        self.TotNodes = 0
        self.DeltaTime = 0

struct MaterialActuatorData:
    var actuatorName: String
    var isActuated: Bool
    var actuatedValue: Float64
    
    fn __init__(inout self):
        self.actuatorName = ""
        self.isActuated = False
        self.actuatedValue = 0.0

struct SurfaceDataFD:
    var T: Array1D
    var TOld: Array1D
    var TT: Array1D
    var Rhov: Array1D
    var RhovOld: Array1D
    var RhoT: Array1D
    var TD: Array1D
    var TDT: Array1D
    var TDTLast: Array1D
    var TDOld: Array1D
    var TDreport: Array1D
    var RH: Array1D
    var RHreport: Array1D
    var EnthOld: Array1D
    var EnthNew: Array1D
    var EnthLast: Array1D
    var QDreport: Array1D
    var CpDelXRhoS1: Array1D
    var CpDelXRhoS2: Array1D
    var TDpriortimestep: Array1D
    var SourceNodeNum: Int32
    var QSource: Float64
    var GSloopCounter: Int32
    var MaxNodeDelTemp: Float64
    var indexNodeMaxTempLimit: Int32
    var indexNodeMinTempLimit: Int32
    var EnthalpyM: Float64
    var EnthalpyF: Float64
    var PhaseChangeState: Array1D
    var PhaseChangeStateOld: Array1D
    var PhaseChangeStateOldOld: Array1D
    var PhaseChangeStateRep: Array1D_int
    var PhaseChangeStateOldRep: Array1D_int
    var PhaseChangeStateOldOldRep: Array1D_int
    var PhaseChangeTemperatureReverse: Array1D
    var condMaterialActuators: Array1D
    var specHeatMaterialActuators: Array1D
    var heatSourceFluxMaterialActuators: Array1D
    var condNodeReport: Array1D
    var specHeatNodeReport: Array1D
    var heatSourceInternalFluxLayerReport: Array1D
    var heatSourceInternalFluxEnergyLayerReport: Array1D
    var heatSourceEMSFluxLayerReport: Array1D
    var heatSourceEMSFluxEnergyLayerReport: Array1D
    var enetActuator: MaterialActuatorData
    var enetActuatorReport: Float64
    
    fn __init__(inout self):
        self.T = Array1D()
        self.TOld = Array1D()
        self.TT = Array1D()
        self.Rhov = Array1D()
        self.RhovOld = Array1D()
        self.RhoT = Array1D()
        self.TD = Array1D()
        self.TDT = Array1D()
        self.TDTLast = Array1D()
        self.TDOld = Array1D()
        self.TDreport = Array1D()
        self.RH = Array1D()
        self.RHreport = Array1D()
        self.EnthOld = Array1D()
        self.EnthNew = Array1D()
        self.EnthLast = Array1D()
        self.QDreport = Array1D()
        self.CpDelXRhoS1 = Array1D()
        self.CpDelXRhoS2 = Array1D()
        self.TDpriortimestep = Array1D()
        self.SourceNodeNum = 0
        self.QSource = 0.0
        self.GSloopCounter = 0
        self.MaxNodeDelTemp = 0.0
        self.indexNodeMaxTempLimit = 0
        self.indexNodeMinTempLimit = 0
        self.EnthalpyM = 0.0
        self.EnthalpyF = 0.0
        self.PhaseChangeState = Array1D()
        self.PhaseChangeStateOld = Array1D()
        self.PhaseChangeStateOldOld = Array1D()
        self.PhaseChangeStateRep = Array1D_int()
        self.PhaseChangeStateOldRep = Array1D_int()
        self.PhaseChangeStateOldOldRep = Array1D_int()
        self.PhaseChangeTemperatureReverse = Array1D()
        self.condMaterialActuators = Array1D()
        self.specHeatMaterialActuators = Array1D()
        self.heatSourceFluxMaterialActuators = Array1D()
        self.condNodeReport = Array1D()
        self.specHeatNodeReport = Array1D()
        self.heatSourceInternalFluxLayerReport = Array1D()
        self.heatSourceInternalFluxEnergyLayerReport = Array1D()
        self.heatSourceEMSFluxLayerReport = Array1D()
        self.heatSourceEMSFluxEnergyLayerReport = Array1D()
        self.enetActuator = MaterialActuatorData()
        self.enetActuatorReport = 0.0
    
    fn UpdateMoistureBalance(inout self):
        self.TOld.data = self.T.data
        self.RhovOld.data = self.Rhov.data
        self.TDOld.data = self.TDreport.data

struct MaterialDataFD:
    var tk1: Float64
    var numTempEnth: Int32
    var numTempCond: Int32
    var TempEnth: Array2D
    var TempCond: Array2D
    
    fn __init__(inout self):
        self.tk1 = 0.0
        self.numTempEnth = 0
        self.numTempCond = 0
        self.TempEnth = Array2D()
        self.TempCond = Array2D()

fn ManageHeatBalFiniteDiff(inout state, SurfNum: Int32, inout SurfTempInTmp: Float64, inout TempSurfOutTmp: Float64):
    pass

fn GetCondFDInput(inout state):
    pass

fn setSizeMaxProperties(inout state) -> Int32:
    return 0

fn InitHeatBalFiniteDiff(inout state):
    pass

fn InitialInitHeatBalFiniteDiff(inout state):
    pass

fn numNodesInMaterialLayer(inout state, surfName: String, matName: String) -> Int32:
    return 0

fn CalcHeatBalFiniteDiff(inout state, Surf: Int32, inout SurfTempInTmp: Float64, inout TempSurfOutTmp: Float64):
    pass

fn ReportFiniteDiffInits(inout state):
    pass

fn CalcNodeHeatFlux(inout state, Surf: Int32, TotNodes: Int32):
    pass

fn ExteriorBCEqns(inout state, Delt: Int32, i: Int32, Lay: Int32, Surf: Int32, T, TT, Rhov, RhoT, RH, TD, TDT, EnthOld, EnthNew, TotNodes: Int32, HMovInsul: Float64):
    pass

fn InteriorNodeEqns(inout state, Delt: Int32, i: Int32, Lay: Int32, Surf: Int32, T, TT, Rhov, RhoT, RH, TD, TDT, EnthOld, EnthNew):
    pass

fn IntInterfaceNodeEqns(inout state, Delt: Int32, i: Int32, Lay: Int32, Surf: Int32, T, TT, Rhov, RhoT, RH, TD, TDT, EnthOld, EnthNew, GSiter: Int32):
    pass

fn InteriorBCEqns(inout state, Delt: Int32, i: Int32, Lay: Int32, SurfNum: Int32, T, TT, Rhov, RhoT, RH, TD, TDT, EnthOld, EnthNew, TDreport):
    pass

fn CheckFDSurfaceTempLimits(inout state, SurfNum: Int32, CheckTemperature: Float64):
    pass

fn CheckFDNodeTempLimits(inout state, surfNum: Int32, nodeNum: Int32, inout nodeTemp: Float64):
    pass

fn adjustPropertiesForPhaseChange(inout state, finiteDifferenceLayerIndex: Int32, surfNum: Int32, mat, temperaturePrevious: Float64, temperatureUpdated: Float64):
    pass

fn findAnySurfacesUsingConstructionAndCondFD(state, constructionNum: Int32) -> Bool:
    return False
