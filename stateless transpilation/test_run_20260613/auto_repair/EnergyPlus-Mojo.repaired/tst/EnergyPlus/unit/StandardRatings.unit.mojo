# Mojo translation of StandardRatings.unit.cc
# Faithful 1:1 translation, no refactoring.

from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.ChillerElectricEIR import *
from EnergyPlus.ChillerReformulatedEIR import *
from EnergyPlus.Coils.CoilCoolingDX import *
from EnergyPlus.Coils.CoilCoolingDXCurveFitPerformance import *
from EnergyPlus.CurveManager import *
from EnergyPlus.DXCoils import *
from EnergyPlus.IOFiles import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.StandardRatings import *
from EnergyPlus.VariableSpeedCoils import *
from EnergyPlus import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.HVAC import *
from EnergyPlus.Constant import *
from EnergyPlus.DataPlant import *
from EnergyPlus.Curve import *
from EnergyPlus.DXCoils import *
from EnergyPlus.ChillerElectricEIR import *
from EnergyPlus.ChillerReformulatedEIR import *

# Helper types to mimic ObjexxFCL
struct Optional(T: AnyType):
    var has_value: Bool
    var value: T
    def __init__(inout self):
        self.has_value = False
        self.value = T()
    def __init__(inout self, val: T):
        self.has_value = True
        self.value = val

struct Array1D(T: AnyType):
    var data: List[T]
    def __init__(inout self):
        self.data = List[T]()
    def __init__(inout self, size: Int):
        self.data = List[T](size)
    def __getitem__(self, idx: Int) -> T:
        return self.data[idx]
    def __setitem__(self, idx: Int, val: T):
        self.data[idx] = val
    def push_back(inout self, val: T):
        self.data.append(val)
    def size(self) -> Int:
        return len(self.data)

# Helper assertion functions (simulating gtest)
def assert_true(cond: Bool, msg: String = ""):
    if not cond:
        print("Assertion failed: ", msg)
        abort()

def assert_false(cond: Bool, msg: String = ""):
    if cond:
        print("Assertion failed: ", msg)
        abort()

def assert_eq(a: AnyType, b: AnyType, msg: String = ""):
    if a != b:
        print("Assertion failed: ", msg, " expected ", b, " got ", a)
        abort()

def assert_ne(a: AnyType, b: AnyType, msg: String = ""):
    if a == b:
        print("Assertion failed: ", msg, " values equal")
        abort()

def assert_approx_eq(a: Float64, b: Float64, tol: Float64 = 1e-6, msg: String = ""):
    if abs(a - b) > tol:
        print("Assertion failed: ", msg, " expected ", b, " got ", a, " tolerance ", tol)
        abort()

def expect_true(cond: Bool, msg: String = ""):
    if not cond:
        print("Expectation failed: ", msg)

def expect_false(cond: Bool, msg: String = ""):
    if cond:
        print("Expectation failed: ", msg)

def expect_eq(a: AnyType, b: AnyType, msg: String = ""):
    if a != b:
        print("Expectation failed: ", msg, " expected ", b, " got ", a)

def expect_ne(a: AnyType, b: AnyType, msg: String = ""):
    if a == b:
        print("Expectation failed: ", msg, " values equal")

def expect_approx_eq(a: Float64, b: Float64, tol: Float64 = 1e-6, msg: String = ""):
    if abs(a - b) > tol:
        print("Expectation failed: ", msg, " expected ", b, " got ", a, " tolerance ", tol)

def expect_gt(a: Float64, b: Float64, msg: String = ""):
    if not (a > b):
        print("Expectation failed: ", msg, " ", a, " not > ", b)

def expect_lt(a: Float64, b: Float64, msg: String = ""):
    if not (a < b):
        print("Expectation failed: ", msg, " ", a, " not < ", b)

def expect_double_eq(a: Float64, b: Float64, msg: String = ""):
    if a != b:
        print("Expectation failed: ", msg, " expected ", b, " got ", a)

def expect_near(a: Float64, b: Float64, tol: Float64, msg: String = ""):
    if abs(a - b) > tol:
        print("Expectation failed: ", msg, " expected ", b, " got ", a, " tolerance ", tol)

def round(val: Float64, decimals: Int = 0) -> Float64:
    var factor = 10.0 ** decimals
    return (val * factor).round() / factor

# Test functions (translated from TEST_F)
def SingleSpeedHeatingCoilCurveTest():
    using Psychrometrics.PsyRhoAirFnPbTdbW
    using StandardRatings.SingleSpeedDXHeatingCoilStandardRatings
    var DXCoilNum: Int
    state.dataDXCoils.NumDXCoils = 1
    DXCoilNum = 1
    state.dataDXCoils.DXCoil.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilNumericFields.allocate(1)
    state.dataDXCoils.DXCoilOutletTemp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilOutletHumRat.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilFanOp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilPartLoadRatio.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilTotalHeating.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilHeatInletAirDBTemp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilHeatInletAirWBTemp.allocate(state.dataDXCoils.NumDXCoils)
    var Coil: DXCoilData = state.dataDXCoils.DXCoil[DXCoilNum]
    Coil.Name = "DX Single Speed Heating Coil"
    Coil.coilType = HVAC.CoilType.HeatingDXSingleSpeed
    Coil.availSched = Sched.GetScheduleAlwaysOn(*state)
    Coil.RatedSHR[1] = 1.0
    Coil.RatedTotCap[1] = 1600.0
    Coil.RatedCOP[1] = 4.0
    Coil.RatedEIR[1] = 1 / Coil.RatedCOP[1]
    Coil.RatedAirVolFlowRate[1] = 0.50
    Coil.RatedAirMassFlowRate[1] = Coil.RatedAirVolFlowRate[1] * PsyRhoAirFnPbTdbW(*state, state.dataEnvrn.StdBaroPress, 21.11, 0.00881, "InitDXCoil")
    Coil.FanPowerPerEvapAirFlowRate[1] = 773.3
    Coil.FanPowerPerEvapAirFlowRate_2023[1] = 934.4
    Coil.MinOATCompressor = -10.0
    Coil.CrankcaseHeaterCapacity = 0.0
    Coil.MaxOATDefrost = 0.0
    Coil.DefrostStrategy = StandardRatings.DefrostStrat.Resistive
    Coil.DefrostControl = StandardRatings.HPdefrostControl.Invalid
    Coil.DefrostTime = 0.058333
    Coil.DefrostCapacity = 1000
    Coil.PLRImpact = false
    Coil.FuelType = Constant.eFuel.Electricity
    Coil.RegionNum = 4
    Coil.OATempCompressorOn = -5.0
    Coil.OATempCompressorOnOffBlank = true
    var curve1 = Curve.AddCurve(*state, "PTHPHeatingCAPFT")
    curve1.curveType = CurveType.Cubic
    curve1.numDims = 1
    curve1.Name = curve1.coeff[0] = 0.876825
    curve1.coeff[1] = -0.002955
    curve1.coeff[2] = 5.8e-005
    curve1.coeff[3] = 0.025335
    curve1.inputLimits[0].min = -5
    curve1.inputLimits[0].max = 25
    Coil.CCapFTemp[1] = curve1.Num
    var curve2 = Curve.AddCurve(*state, "HPHeatCapfFF")
    curve2.curveType = CurveType.Quadratic
    curve2.numDims = 1
    curve2.Name = curve2.coeff[0] = 1
    curve2.coeff[1] = 0
    curve2.coeff[2] = 0
    curve2.inputLimits[0].min = 0
    curve2.inputLimits[0].max = 2
    curve2.outputLimits.min = 0
    curve2.outputLimits.max = 2
    Coil.CCapFFlow[1] = curve2.Num
    var curve3 = Curve.AddCurve(*state, "PTHPHeatingEIRFT")
    curve3.curveType = CurveType.Cubic
    curve3.numDims = 1
    curve3.coeff[0] = 0.704658
    curve3.coeff[1] = 0.008767
    curve3.coeff[2] = 0.000625
    curve3.coeff[3] = -0.009037
    curve3.inputLimits[0].min = -5
    curve3.inputLimits[0].max = 25
    Coil.EIRFTemp[1] = curve3.Num
    var curve4 = Curve.AddCurve(*state, "HPHeatEIRfFF")
    curve4.curveType = CurveType.Quadratic
    curve4.numDims = 1
    curve4.coeff[0] = 1
    curve4.coeff[1] = 0
    curve4.coeff[2] = 0
    curve4.inputLimits[0].min = 0
    curve4.inputLimits[0].max = 2
    curve4.outputLimits.min = 0
    curve4.outputLimits.max = 2
    Coil.EIRFFlow[1] = curve4.Num
    var nPLFfPLR: Int = 5
    var curve5 = Curve.AddCurve(*state, "HPHeatPLFfPLR")
    curve5.curveType = CurveType.Quadratic
    curve5.numDims = 1
    curve5.coeff[0] = 1
    curve5.coeff[1] = 0
    curve5.coeff[2] = 0
    curve5.inputLimits[0].min = 0
    curve5.inputLimits[0].max = 1
    curve5.outputLimits.min = 0.7
    curve5.outputLimits.max = 1
    Coil.PLFFPLR[1] = nPLFfPLR
    var NetHeatingCapRatedHighTemp: Float64
    var NetHeatingCapRatedLowTemp: Float64
    var HSPF: Float64
    var NetHeatingCapRatedHighTemp_2023: Float64
    var NetHeatingCapRatedLowTemp_2023: Float64
    var HSPF_2023: Float64
    var StandardRatingsResults: Map[String, Float64]
    StandardRatingsResults = SingleSpeedDXHeatingCoilStandardRatings(*state, Coil.Name, Coil.coilType, Coil.RatedTotCap[1], Coil.RatedCOP[1], Coil.CCapFFlow[1], Coil.CCapFTemp[1], Coil.EIRFFlow[1], Coil.EIRFTemp[1], Coil.RatedAirVolFlowRate[1], Coil.FanPowerPerEvapAirFlowRate[1], Coil.FanPowerPerEvapAirFlowRate_2023[1], Coil.RegionNum, Coil.MinOATCompressor, Coil.OATempCompressorOn, Coil.OATempCompressorOnOffBlank, Coil.DefrostControl)
    NetHeatingCapRatedHighTemp = StandardRatingsResults["NetHeatingCapRated"]
    NetHeatingCapRatedLowTemp = StandardRatingsResults["NetHeatingCapH3Test"]
    HSPF = StandardRatingsResults["HSPF"]
    NetHeatingCapRatedHighTemp_2023 = StandardRatingsResults["NetHeatingCapRated_2023"]
    NetHeatingCapRatedLowTemp_2023 = StandardRatingsResults["NetHeatingCapH3Test_2023"]
    HSPF_2023 = StandardRatingsResults["HSPF2_2023"]
    assert_true(HSPF == HSPF_2023) # 0.0 for a negative Curve
    var TotCapTempModFacRated = CurveValue(*state, Coil.CCapFTemp[1], StandardRatings.HeatingOutdoorCoilInletAirDBTempRated)
    var TotCapFlowModFac = CurveValue(*state, Coil.CCapFFlow[1], 1.0)
    var NetHeatingCapRated = Coil.RatedTotCap[1] * TotCapTempModFacRated * TotCapFlowModFac + Coil.RatedAirVolFlowRate[1] * Coil.FanPowerPerEvapAirFlowRate[1]
    expect_gt(TotCapTempModFacRated, 0.0)
    expect_double_eq(TotCapFlowModFac, 1.0)
    expect_double_eq(NetHeatingCapRatedHighTemp, NetHeatingCapRated)
    var CapTempModFacH2Test = CurveValue(*state, Coil.CCapFTemp[1], StandardRatings.HeatingOutdoorCoilInletAirDBTempH2Test)
    expect_gt(CapTempModFacH2Test, 0.0)
    var CapTempModFacH3Test = CurveValue(*state, Coil.CCapFTemp[1], StandardRatings.HeatingOutdoorCoilInletAirDBTempH3Test)
    expect_lt(CapTempModFacH3Test, 0.0)
    var NetHeatingCapRated2023 = Coil.RatedTotCap[1] * TotCapTempModFacRated * TotCapFlowModFac + Coil.RatedAirVolFlowRate[1] * Coil.FanPowerPerEvapAirFlowRate_2023[1]
    expect_double_eq(NetHeatingCapRatedHighTemp_2023, NetHeatingCapRated2023)
    expect_double_eq(NetHeatingCapRatedLowTemp, 0.0)
    var EIRTempModFacRated = CurveValue(*state, Coil.EIRFTemp[1], StandardRatings.HeatingOutdoorCoilInletAirDBTempRated)
    var EIRTempModFacH2Test = CurveValue(*state, Coil.EIRFTemp[1], StandardRatings.HeatingOutdoorCoilInletAirDBTempH2Test)
    var EIRTempModFacH3Test = CurveValue(*state, Coil.EIRFTemp[1], StandardRatings.HeatingOutdoorCoilInletAirDBTempH3Test)
    expect_lt(EIRTempModFacRated, 0.0)
    expect_gt(EIRTempModFacH2Test, 0.0)
    expect_gt(EIRTempModFacH3Test, 0.0)
    expect_double_eq(HSPF, 0.0)
    expect_double_eq(NetHeatingCapRatedLowTemp_2023, 0.0)
    expect_double_eq(HSPF_2023, 0.0)

def SingleSpeedHeatingCoilCurveTest_PositiveCurve():
    using Psychrometrics.PsyRhoAirFnPbTdbW
    using StandardRatings.SingleSpeedDXHeatingCoilStandardRatings
    var DXCoilNum: Int
    state.dataDXCoils.NumDXCoils = 1
    DXCoilNum = 1
    state.dataDXCoils.DXCoil.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilNumericFields.allocate(1)
    state.dataDXCoils.DXCoilOutletTemp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilOutletHumRat.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilFanOp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilPartLoadRatio.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilTotalHeating.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilHeatInletAirDBTemp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilHeatInletAirWBTemp.allocate(state.dataDXCoils.NumDXCoils)
    var Coil: DXCoilData = state.dataDXCoils.DXCoil[DXCoilNum]
    Coil.Name = "DX Single Speed Heating Coil"
    Coil.coilType = HVAC.CoilType.HeatingDXSingleSpeed
    Coil.availSched = Sched.GetScheduleAlwaysOn(*state)
    Coil.RatedSHR[1] = 1.0
    Coil.RatedTotCap[1] = 1600.0
    Coil.RatedCOP[1] = 4.0
    Coil.RatedEIR[1] = 1 / Coil.RatedCOP[1]
    Coil.RatedAirVolFlowRate[1] = 0.50
    Coil.RatedAirMassFlowRate[1] = Coil.RatedAirVolFlowRate[1] * PsyRhoAirFnPbTdbW(*state, state.dataEnvrn.StdBaroPress, 21.11, 0.00881, "InitDXCoil")
    Coil.FanPowerPerEvapAirFlowRate[1] = 773.3
    Coil.FanPowerPerEvapAirFlowRate_2023[1] = 934.4
    Coil.MinOATCompressor = -10.0
    Coil.CrankcaseHeaterCapacity = 0.0
    Coil.MaxOATDefrost = 0.0
    Coil.DefrostStrategy = StandardRatings.DefrostStrat.Resistive
    Coil.DefrostControl = StandardRatings.HPdefrostControl.Invalid
    Coil.DefrostTime = 0.058333
    Coil.DefrostCapacity = 1000
    Coil.PLRImpact = false
    Coil.FuelType = Constant.eFuel.Electricity
    Coil.RegionNum = 4
    Coil.OATempCompressorOn = -5.0
    Coil.OATempCompressorOnOffBlank = true
    var curve1 = Curve.AddCurve(*state, "PTHPHeatingCAPFT")
    curve1.curveType = CurveType.Cubic
    curve1.numDims = 1
    curve1.coeff[0] = 0.876825
    curve1.coeff[1] = 0.002955
    curve1.coeff[2] = 5.8e-005
    curve1.coeff[3] = 0.025335
    curve1.inputLimits[0].min = 5
    curve1.inputLimits[0].max = 25
    Coil.CCapFTemp[1] = curve1.Num
    var curve2 = Curve.AddCurve(*state, "HPHeatCapfFF")
    curve2.curveType = CurveType.Quadratic
    curve2.numDims = 1
    curve2.coeff[0] = 1
    curve2.coeff[1] = 0
    curve2.coeff[2] = 0
    curve2.inputLimits[0].min = 0
    curve2.inputLimits[0].max = 2
    curve2.outputLimits.min = 0
    curve2.outputLimits.max = 2
    Coil.CCapFFlow[1] = curve2.Num
    var curve3 = Curve.AddCurve(*state, "PTHPHeatingEIRFT")
    curve3.curveType = CurveType.Cubic
    curve3.numDims = 1
    curve3.coeff[0] = 0.704658
    curve3.coeff[1] = 0.008767
    curve3.coeff[2] = 0.000625
    curve3.coeff[3] = 0.009037
    curve3.inputLimits[0].min = 5
    curve3.inputLimits[0].max = 25
    Coil.EIRFTemp[1] = curve3.Num
    var curve4 = Curve.AddCurve(*state, "HPHeatEIRfFF")
    curve4.curveType = CurveType.Quadratic
    curve4.numDims = 1
    curve4.coeff[0] = 1
    curve4.coeff[1] = 0
    curve4.coeff[2] = 0
    curve4.inputLimits[0].min = 0
    curve4.inputLimits[0].max = 2
    curve4.outputLimits.min = 0
    curve4.outputLimits.max = 2
    Coil.EIRFFlow[1] = curve4.Num
    var curve5 = Curve.AddCurve(*state, "HPHeatPLFfPLR")
    curve5.curveType = CurveType.Quadratic
    curve5.numDims = 1
    curve5.coeff[0] = 1
    curve5.coeff[1] = 0
    curve5.coeff[2] = 0
    curve5.inputLimits[0].min = 0
    curve5.inputLimits[0].max = 1
    curve5.outputLimits.min = 0.7
    curve5.outputLimits.max = 1
    Coil.PLFFPLR[1] = curve5.Num
    var NetHeatingCapRatedHighTemp: Float64
    var NetHeatingCapRatedLowTemp: Float64
    var HSPF: Float64
    var NetHeatingCapRatedHighTemp_2023: Float64
    var NetHeatingCapRatedLowTemp_2023: Float64
    var HSPF_2023: Float64
    var StandardRatingsResults: Map[String, Float64]
    StandardRatingsResults = SingleSpeedDXHeatingCoilStandardRatings(*state, Coil.Name, Coil.coilType, Coil.RatedTotCap[1], Coil.RatedCOP[1], Coil.CCapFFlow[1], Coil.CCapFTemp[1], Coil.EIRFFlow[1], Coil.EIRFTemp[1], Coil.RatedAirVolFlowRate[1], Coil.FanPowerPerEvapAirFlowRate[1], Coil.FanPowerPerEvapAirFlowRate_2023[1], Coil.RegionNum, Coil.MinOATCompressor, Coil.OATempCompressorOn, Coil.OATempCompressorOnOffBlank, Coil.DefrostControl)
    NetHeatingCapRatedHighTemp = StandardRatingsResults["NetHeatingCapRated"]
    NetHeatingCapRatedLowTemp = StandardRatingsResults["NetHeatingCapH3Test"]
    HSPF = StandardRatingsResults["HSPF"]
    NetHeatingCapRatedHighTemp_2023 = StandardRatingsResults["NetHeatingCapRated_2023"]
    NetHeatingCapRatedLowTemp_2023 = StandardRatingsResults["NetHeatingCapH3Test_2023"]
    HSPF_2023 = StandardRatingsResults["HSPF_2023"]

def SingleSpeedHeatingCoilCurveTest2023():
    using Psychrometrics.PsyRhoAirFnPbTdbW
    using StandardRatings.SingleSpeedDXHeatingCoilStandardRatings
    var DXCoilNum: Int
    state.dataDXCoils.NumDXCoils = 1
    DXCoilNum = 1
    state.dataDXCoils.DXCoil.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilNumericFields.allocate(1)
    state.dataDXCoils.DXCoilOutletTemp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilOutletHumRat.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilFanOp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilPartLoadRatio.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilTotalHeating.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilHeatInletAirDBTemp.allocate(state.dataDXCoils.NumDXCoils)
    state.dataDXCoils.DXCoilHeatInletAirWBTemp.allocate(state.dataDXCoils.NumDXCoils)
    var Coil: DXCoilData = state.dataDXCoils.DXCoil[DXCoilNum]
    Coil.Name = "HeatingCoilDXSingleSpeedAutosize"
    Coil.coilType = HVAC.CoilType.HeatingDXSingleSpeed
    Coil.availSched = Sched.GetScheduleAlwaysOn(*state)
    Coil.RatedSHR[1] = 1.0
    Coil.RatedTotCap[1] = 1600.0
    Coil.RatedCOP[1] = 3.8
    Coil.RatedEIR[1] = 1 / Coil.RatedCOP[1]
    Coil.RatedAirVolFlowRate[1] = 0.50
    Coil.RatedAirMassFlowRate[1] = Coil.RatedAirVolFlowRate[1] * PsyRhoAirFnPbTdbW(*state, state.dataEnvrn.StdBaroPress, 21.11, 0.00881, "InitDXCoil")
    Coil.FanPowerPerEvapAirFlowRate[1] = 773.3
    Coil.FanPowerPerEvapAirFlowRate_2023[1] = 934.4
    Coil.MinOATCompressor = -5
    Coil.CrankcaseHeaterCapacity = 200
    Coil.MaxOATDefrost = 5
    Coil.DefrostStrategy = StandardRatings.DefrostStrat.Resistive
    Coil.DefrostControl = StandardRatings.HPdefrostControl.Timed
    Coil.DefrostTime = 0.167
    Coil.DefrostCapacity = 20000
    Coil.PLRImpact = false
    Coil.FuelType = Constant.eFuel.Electricity
    Coil.RegionNum = 4
    Coil.OATempCompressorOn = -5.0
    Coil.OATempCompressorOnOffBlank = true
    var curve1 = AddCurve(*state, "PTHPHeatingCAPFT")
    curve1.curveType = CurveType.Cubic
    curve1.numDims = 1
    curve1.coeff[0] = 0.759
    curve1.coeff[1] = 0.028
    curve1.coeff[2] = 0
    curve1.coeff[3] = 0
    curve1.inputLimits[0].min = -20
    curve1.inputLimits[0].max = 20
    Coil.CCapFTemp[1] = curve1.Num
    var curve2 = AddCurve(*state, "HPHeatCapfFF")
    curve2.curveType = CurveType.Cubic
    curve2.numDims = 1
    curve2.coeff[0] = 0.84
    curve2.coeff[1] = 0.16
    curve2.coeff[2] = 0
    curve2.coeff[3] = 0
    curve2.inputLimits[0].min = 0.5
    curve2.inputLimits[0].max = 1.5
    Coil.CCapFFlow[1] = curve2.Num
    var curve3 = AddCurve(*state, "PTHPHeatingEIRFT")
    curve3.curveType = CurveType.BiQuadratic
    curve3.numDims = 1
    curve3.coeff[0] = 0.342
    curve3.coeff[1] = 0.035
    curve3.coeff[2] = -0.001
    curve3.coeff[3] = 0.005
    curve3.coeff[4] = 0
    curve3.coeff[5] = -0.001
    curve3.inputLimits[0].min = 12.778
    curve3.inputLimits[0].max = 23.889
    curve3.inputLimits[1].min = 18
    curve3.inputLimits[1].max = 46.111
    Coil.EIRFTemp[1] = curve3.Num
    var curve4 = AddCurve(*state, "HPHeatEIRfFF")
    curve4.curveType = CurveType.Cubic
    curve4.numDims = 1
    curve4.coeff[0] = 1.192
    curve4.coeff[1] = -0.03
    curve4.coeff[2] = 0.001
    curve4.coeff[3] = 0
    curve4.inputLimits[0].min = -20
    curve4.inputLimits[0].max = 20
    curve4.outputLimits.min = -20
    curve4.outputLimits.max = 20
    Coil.EIRFFlow[1] = curve4.Num
    var curve5 = AddCurve(*state, "HPHeatPLFfPLR")
    curve5.curveType = CurveType.Quadratic
    curve5.numDims = 1
    curve5.coeff[0] = 0.75
    curve5.coeff[1] = 0.25
    curve5.coeff[2] = 0
    curve5.inputLimits[0].min = 0
    curve5.inputLimits[0].max = 1
    curve5.outputLimits.min = 0
    curve5.outputLimits.max = 1
    Coil.PLFFPLR[1] = curve5.Num
    var NetHeatingCapRatedHighTemp: Float64
    var NetHeatingCapRatedLowTemp: Float64
    var HSPF: Float64
    var NetHeatingCapRatedHighTemp_2023: Float64
    var NetHeatingCapRatedLowTemp_2023: Float64
    var HSPF_2023: Float64
    var StandardRatingsResults: Map[String, Float64]
    StandardRatingsResults = SingleSpeedDXHeatingCoilStandardRatings(*state, Coil.Name, Coil.coilType, Coil.RatedTotCap[1], Coil.RatedCOP[1], Coil.CCapFFlow[1], Coil.CCapFTemp[1], Coil.EIRFFlow[1], Coil.EIRFTemp[1], Coil.RatedAirVolFlowRate[1], Coil.FanPowerPerEvapAirFlowRate[1], Coil.FanPowerPerEvapAirFlowRate_2023[1], Coil.RegionNum, Coil.MinOATCompressor, Coil.OATempCompressorOn, Coil.OATempCompressorOnOffBlank, Coil.DefrostControl)
    NetHeatingCapRatedHighTemp = StandardRatingsResults["NetHeatingCapRated"]
    NetHeatingCapRatedLowTemp = StandardRatingsResults["NetHeatingCapH3Test"]
    HSPF = StandardRatingsResults["HSPF"]
    NetHeatingCapRatedHighTemp_2023 = StandardRatingsResults["NetHeatingCapRated_2023"]
    NetHeatingCapRatedLowTemp_2023 = StandardRatingsResults["NetHeatingCapH3Test_2023"]
    HSPF_2023 = StandardRatingsResults["HSPF2_2023"]

def SingleSpeedHeatingCurveTest2023_II():
    var idf_objects1 = delimited_string({
        "Coil:Heating:DX:SingleSpeed,",
        "  Heat Pump 1 HP Heating Coil,                             !- Name",
        "  ,                                                        !- Availability Schedule Name",
        "  9000.0,                                                  !- Rated Total Heating Capacity {W}",
        "  2.75,                                                    !- Rated COP",
        "  0.5,                                                     !- Rated Air Flow Rate {m3/s}",
        "  773.3,                                                   !- 2017 Rated Supply Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "  934.4,                                                   !- 2023 Rated Supply Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "  Heat Pump 1 Cooling Coil Outlet,                         !- Air Inlet Node Name",
        "  Heat Pump 1 Heating Coil Outlet,                         !- Air Outlet Node Name",
        "  Heat Pump 1 HP Heating Coil Cap-FT,                      !- Total Heating Capacity Function of Temperature Curve Name",
        "  Heat Pump 1 HP Heating Coil Cap-FF,                      !- Total Heating Capacity Function of Flow Fraction Curve Name",
        "  Heat Pump 1 HP Heating Coil EIR-FT,                      !- Energy Input Ratio Function of Temperature Curve Name",
        "  Heat Pump 1 HP Heating Coil EIR-FF,                      !- Energy Input Ratio Function of Flow Fraction Curve Name",
        "  Heat Pump 1 HP Heating Coil PLF,                         !- Part Load Fraction Correlation Curve Name",
        "  Heat Pump 1 HP Heating Coil DefrEIR-FT,                  !- Defrost Energy Input Ratio Function of Temperature Curve Name",
        "  -8,                                                      !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}",
        "  ,                                                        !- Outdoor Dry-Bulb Temperature to Turn On Compressor",
        "  5,                                                       !- Maximum Outdoor Dry-Bulb Temperature for Defrost Operation {C}",
        "  0,                                                       !- Crankcase Heater Capacity {W}",
        "  ,                                                        !- Crankcase Heater Capacity Function of Temperature Curve Name",
        "  0,                                                       !- Maximum Outdoor Dry-Bulb Temperature for Crankcase Heater Operation {C}",
        "  ReverseCycle,                                            !- Defrost Strategy",
        "  Timed,                                                   !- Defrost Control",
        "  0.058333,                                                !- Defrost Time Period Fraction",
        "  10.0;                                                    !- Resistive Defrost Heater Capacity {W}",
        "Curve:Cubic,",
        "  Heat Pump 1 HP Heating Coil Cap-FT,                      !- Name",
        "  0.758746,                                                !- Coefficient1 Constant",
        "  0.027626,                                                !- Coefficient2 x",
        "  0.000148716,                                             !- Coefficient3 x**2",
        "  0.0000034992,                                            !- Coefficient4 x**3",
        "  -20.0,                                                   !- Minimum Value of x",
        "  20.0;                                                    !- Maximum Value of x",
        "Curve:Cubic,",
        "  Heat Pump 1 HP Heating Coil Cap-FF,                      !- Name",
        "  0.84,                                                    !- Coefficient1 Constant",
        "  0.16,                                                    !- Coefficient2 x",
        "  0.0,                                                     !- Coefficient3 x**2",
        "  0.0,                                                     !- Coefficient4 x**3",
        "  0.5,                                                     !- Minimum Value of x",
        "  1.5;                                                     !- Maximum Value of x",
        "Curve:Cubic,",
        "  Heat Pump 1 HP Heating Coil EIR-FT,                      !- Name",
        "  1.19248,                                                 !- Coefficient1 Constant",
        "  -0.0300438,                                              !- Coefficient2 x",
        "  0.00103745,                                              !- Coefficient3 x**2",
        "  -0.000023328,                                            !- Coefficient4 x**3",
        "  -20.0,                                                   !- Minimum Value of x",
        "  20.0;                                                    !- Maximum Value of x",
        "Curve:Quadratic,",
        "  Heat Pump 1 HP Heating Coil EIR-FF,                      !- Name",
        "  1.3824,                                                  !- Coefficient1 Constant",
        "  -0.4336,                                                 !- Coefficient2 x",
        "  0.0512,                                                  !- Coefficient3 x**2",
        "  0.0,                                                     !- Minimum Value of x",
        "  1.0;                                                     !- Maximum Value of x",
        "Curve:Quadratic,",
        "  Heat Pump 1 HP Heating Coil PLF,                         !- Name",
        "  0.75,                                                    !- Coefficient1 Constant",
        "  0.25,                                                    !- Coefficient2 x",
        "  0.0,                                                     !- Coefficient3 x**2",
        "  0.0,                                                     !- Minimum Value of x",
        "  1.0;                                                     !- Maximum Value of x",
        "Curve:Biquadratic,",
        "  Heat Pump 1 HP Heating Coil DefrEIR-FT,                  !- Name",
        "  1,                                                       !- Coefficient1 Constant",
        "  0,                                                       !- Coefficient2 x",
        "  0,                                                       !- Coefficient3 x**2",
        "  0,                                                       !- Coefficient4 y",
        "  0,                                                       !- Coefficient5 y**2",
        "  0,                                                       !- Coefficient6 x*y",
        "  0,                                                       !- Minimum Value of x",
        "  50,                                                      !- Maximum Value of x",
        "  0,                                                       !- Minimum Value of y",
        "  50;                                                      !- Maximum Value of y",
    })
    assert_true(process_idf(idf_objects1))
    state.init_state(*state)
    GetDXCoils(*state)
    var Coil = state.dataDXCoils.DXCoil[1]
    var NetHeatingCapRatedHighTemp: Float64
    var NetHeatingCapRatedLowTemp: Float64
    var HSPF: Float64
    var NetHeatingCapRatedHighTemp_2023: Float64
    var NetHeatingCapRatedLowTemp_2023: Float64
    var HSPF_2023: Float64
    var StandardRatingsResults: Map[String, Float64]
    StandardRatingsResults = SingleSpeedDXHeatingCoilStandardRatings(*state, Coil.Name, Coil.coilType, Coil.RatedTotCap[1], Coil.RatedCOP[1], Coil.CCapFFlow[1], Coil.CCapFTemp[1], Coil.EIRFFlow[1], Coil.EIRFTemp[1], Coil.RatedAirVolFlowRate[1], Coil.FanPowerPerEvapAirFlowRate[1], Coil.FanPowerPerEvapAirFlowRate_2023[1], Coil.RegionNum, Coil.MinOATCompressor, Coil.OATempCompressorOn, Coil.OATempCompressorOnOffBlank, Coil.DefrostControl)
    NetHeatingCapRatedHighTemp = StandardRatingsResults["NetHeatingCapRated"]
    NetHeatingCapRatedLowTemp = StandardRatingsResults["NetHeatingCapH3Test"]
    HSPF = StandardRatingsResults["HSPF"]
    NetHeatingCapRatedHighTemp_2023 = StandardRatingsResults["NetHeatingCapRated_2023"]
    NetHeatingCapRatedLowTemp_2023 = StandardRatingsResults["NetHeatingCapH3Test_2023"]
    HSPF_2023 = StandardRatingsResults["HSPF2_2023"]

def MultiSpeedHeatingCoil_HSPFValueTest_2Speed():
    var idf_objects1 = delimited_string({
        " Coil:Heating:DX:MultiSpeed,",
        "   ashp htg coil,                          !- Name",
        "   ,                                       !- Availability Schedule Name",
        "   ashp unitary system Cooling Coil - Heating Coil Node, !- Air Inlet Node Name",
        "   ashp unitary system Heating Coil - Supplemental Coil Node, !- Air Outlet Node Name",
        "   -17.7777777777778,                      !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}",
        "   ,                                       !- Outdoor Dry-Bulb Temperature to Turn On Compressor {C}",
        "   50,                                     !- Crankcase Heater Capacity {W}",
        "   ,                                       !- Crankcase Heater Capacity Function of Temperature Curve Name",
        "   10,                                     !- Maximum Outdoor Dry-Bulb Temperature for Crankcase Heater Operation {C}",
        "   DefrostEIR,                             !- Defrost Energy Input Ratio Function of Temperature Curve Name",
        "   4.44444444444444,                       !- Maximum Outdoor Dry-Bulb Temperature for Defrost Operation {C}",
        "   ReverseCycle,                           !- Defrost Strategy",
        "   OnDemand,                               !- Defrost Control",
        "   0.058333,                               !- Defrost Time Period Fraction",
        "   AutoSize,                               !- Resistive Defrost Heater Capacity {W}",
        "   No,                                     !- Apply Part Load Fraction to Speeds Greater than 1",
        "   Electricity,                            !- Fuel Type",
        "   4,                                      !- Region number for Calculating HSPF",
        "   2,                                      !- Number of Speeds",
        "   10128.5361851424,                       !- Speed Gross Rated Heating Capacity 1 {W}",
        "   4.4518131589158,                        !- Speed Gross Rated Heating COP 1 {W/W}",
        "   0.531903646383625,                      !- Speed Rated Air Flow Rate 1 {m3/s}",
        "   773.3,                                  !- 2017 Speed 1 Rated Supply Air Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "   934.3,                                  !- 2023 Speed 1 Rated Supply Air Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "   HP_Heat-Cap-fT1,                        !- Speed Heating Capacity Function of Temperature Curve Name 1",
        "   HP_Heat-CAP-fFF1,                       !- Speed Heating Capacity Function of Flow Fraction Curve Name 1",
        "   HP_Heat-EIR-fT1,                        !- Speed Energy Input Ratio Function of Temperature Curve Name 1",
        "   HP_Heat-EIR-fFF1,                       !- Speed Energy Input Ratio Function of Flow Fraction Curve Name 1",
        "   HP_Heat-PLF-fPLR1,                      !- Speed Part Load Fraction Correlation Curve Name 1",
        "   0.2,                                    !- Speed Rated Waste Heat Fraction of Power Input 1 {dimensionless}",
        "   ConstantBiquadratic,                    !- Speed Waste Heat Function of Temperature Curve Name 1",
        "   14067.4113682534,                       !- Speed Gross Rated Heating Capacity 2 {W}",
        "   3.9871749697327,                        !- Speed Gross Rated Heating COP 2 {W/W}",
        "   0.664879557979531,                      !- Speed Rated Air Flow Rate 2 {m3/s}",
        "   773.3,                                  !- 2017 Speed 2 Rated Supply Air Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "   934.3,                                  !- 2023 Speed 2 Rated Supply Air Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "   HP_Heat-Cap-fT2,                        !- Speed Heating Capacity Function of Temperature Curve Name 2",
        "   HP_Heat-CAP-fFF2,                       !- Speed Heating Capacity Function of Flow Fraction Curve Name 2",
        "   HP_Heat-EIR-fT2,                        !- Speed Energy Input Ratio Function of Temperature Curve Name 2",
        "   HP_Heat-EIR-fFF2,                       !- Speed Energy Input Ratio Function of Flow Fraction Curve Name 2",
        "   HP_Heat-PLF-fPLR2,                      !- Speed Part Load Fraction Correlation Curve Name 2",
        "   0.2,                                    !- Speed Rated Waste Heat Fraction of Power Input 2 {dimensionless}",
        "   ConstantBiquadratic;                    !- Speed Waste Heat Function of Temperature Curve Name 2",
        " Curve:Biquadratic,",
        "   DefrostEIR,                             !- Name",
        "   0.1528,                                 !- Coefficient1 Constant",
        "   0,                                      !- Coefficient2 x",
        "   0,                                      !- Coefficient3 x**2",
        "   0,                                      !- Coefficient4 y",
        "   0,                                      !- Coefficient5 y**2",
        "   0,                                      !- Coefficient6 x*y",
        "   -100,                                   !- Minimum Value of x {BasedOnField A2}",
        "   100,                                    !- Maximum Value of x {BasedOnField A2}",
        "   -100,                                   !- Minimum Value of y {BasedOnField A3}",
        "   100;                                    !- Maximum Value of y {BasedOnField A3}",
        " Curve:Biquadratic,",
        "   HP_Heat-Cap-fT1,                        !- Name",
        "   0.84077409,                             !- Coefficient1 Constant",
        "   -0.0014336586,                          !- Coefficient2 x",
        "   -0.000150336,                           !- Coefficient3 x**2",
        "   0.029628603,                            !- Coefficient4 y",
        "   0.000161676,                            !- Coefficient5 y**2",
        "   -2.349e-005,                            !- Coefficient6 x*y",
        "   -100,                                   !- Minimum Value of x {BasedOnField A2}",
        "   100,                                    !- Maximum Value of x {BasedOnField A2}",
        "   -100,                                   !- Minimum Value of y {BasedOnField A3}",
        "   100;                                    !- Maximum Value of y {BasedOnField A3}",
        " Curve:Quadratic,",
        "   HP_Heat-CAP-fFF1,                       !- Name",
        "   0.741466907,                            !- Coefficient1 Constant",
        "   0.378645444,                            !- Coefficient2 x",
        "   -0.119754733,                           !- Coefficient3 x**2",
        "   0,                                      !- Minimum Value of x {BasedOnField A2}",
        "   2,                                      !- Maximum Value of x {BasedOnField A2}",
        "   0,                                      !- Minimum Curve Output {BasedOnField A3}",
        "   2;                                      !- Maximum Curve Output {BasedOnField A3}",
        " Curve:Biquadratic,",
        "   HP_Heat-EIR-fT1,                        !- Name",
        "   0.539472334,                            !- Coefficient1 Constant",
        "   0.0165103146,                           !- Coefficient2 x",
        "   0.00083874528,                          !- Coefficient3 x**2",
        "   -0.00403234020000001,                   !- Coefficient4 y",
        "   0.00142404156,                          !- Coefficient5 y**2",
        "   -0.00211806252,                         !- Coefficient6 x*y",
        "   -100,                                   !- Minimum Value of x {BasedOnField A2}",
        "   100,                                    !- Maximum Value of x {BasedOnField A2}",
        "   -100,                                   !- Minimum Value of y {BasedOnField A3}",
        "   100;                                    !- Maximum Value of y {BasedOnField A3}",
        " Curve:Quadratic,",
        "   HP_Heat-EIR-fFF1,                       !- Name",
        "   2.153618211,                            !- Coefficient1 Constant",
        "   -1.737190609,                           !- Coefficient2 x",
        "   0.584269478,                            !- Coefficient3 x**2",
        "   0,                                      !- Minimum Value of x {BasedOnField A2}",
        "   2,                                      !- Maximum Value of x {BasedOnField A2}",
        "   0,                                      !- Minimum Curve Output {BasedOnField A3}",
        "   2;                                      !- Maximum Curve Output {BasedOnField A3}",
        " Curve:Quadratic,",
        "   HP_Heat-PLF-fPLR1,                      !- Name",
        "   0.89,                                   !- Coefficient1 Constant",
        "   0.11,                                   !- Coefficient2 x",
        "   0,                                      !- Coefficient3 x**2",
        "   0,                                      !- Minimum Value of x {BasedOnField A2}",
        "   1,                                      !- Maximum Value of x {BasedOnField A2}",
        "   0.7,                                    !- Minimum Curve Output {BasedOnField A3}",
        "   1;                                      !- Maximum Curve Output {BasedOnField A3}",
        " Curve:Biquadratic,",
        "   ConstantBiquadratic,                    !- Name",
        "   1,                                      !- Coefficient1 Constant",
        "   0,                                      !- Coefficient2 x",
        "   0,                                      !- Coefficient3 x**2",
        "   0,                                      !- Coefficient4 y",
        "   0,                                      !- Coefficient5 y**2",
        "   0,                                      !- Coefficient6 x*y",
        "   -100,                                   !- Minimum Value of x {BasedOnField A2}",
        "   100,                                    !- Maximum Value of x {BasedOnField A2}",
        "   -100,                                   !- Minimum Value of y {BasedOnField A3}",
        "   100;                                    !- Maximum Value of y {BasedOnField A3}",
        " Curve:Biquadratic,",
        "   HP_Heat-Cap-fT2,                        !- Name",
        "   0.831506971,                            !- Coefficient1 Constant",
        "   0.0018392166,                           !- Coefficient2 x",
        "   -0.000187596,                           !- Coefficient3 x**2",
        "   0.0266002056,                           !- Coefficient4 y",
        "   0.000191484,                            !- Coefficient5 y**2",
        "   -6.5772e-005,                           !- Coefficient6 x*y",
        "   -100,                                   !- Minimum Value of x {BasedOnField A2}",
        "   100,                                    !- Maximum Value of x {BasedOnField A2}",
        "   -100,                                   !- Minimum Value of y {BasedOnField A3}",
        "   100;                                    !- Maximum Value of y {BasedOnField A3}",
        " Curve:Quadratic,",
        "   HP_Heat-CAP-fFF2,                       !- Name",
        "   0.76634609,                             !- Coefficient1 Constant",
        "   0.32840943,                             !- Coefficient2 x",
        "   -0.094701495,                           !- Coefficient3 x**2",
        "   0,                                      !- Minimum Value of x {BasedOnField A2}",
        "   2,                                      !- Maximum Value of x {BasedOnField A2}",
        "   0,                                      !- Minimum Curve Output {BasedOnField A3}",
        "   2;                                      !- Maximum Curve Output {BasedOnField A3}",
        " Curve:Biquadratic,",
        "   HP_Heat-EIR-fT2,                        !- Name",
        "   0.787746797,                            !- Coefficient1 Constant",
        "   -0.000652314599999999,                  !- Coefficient2 x",
        "   0.00078866784,                          !- Coefficient3 x**2",
        "   -0.0023209056,                          !- Coefficient4 y",
        "   0.00074760408,                          !- Coefficient5 y**2",
        "   -0.00109173096,                         !- Coefficient6 x*y",
        "   -100,                                   !- Minimum Value of x {BasedOnField A2}",
        "   100,                                    !- Maximum Value of x {BasedOnField A2}",
        "   -100,                                   !- Minimum Value of y {BasedOnField A3}",
        "   100;                                    !- Maximum Value of y {BasedOnField A3}",
        " Curve:Quadratic,",
        "   HP_Heat-EIR-fFF2,                       !- Name",
        "   2.001041353,                            !- Coefficient1 Constant",
        "   -1.58869128,                            !- Coefficient2 x",
        "   0.587593517,                            !- Coefficient3 x**2",
        "   0,                                      !- Minimum Value of x {BasedOnField A2}",
        "   2,                                      !- Maximum Value of x {BasedOnField A2}",
        "   0,                                      !- Minimum Curve Output {BasedOnField A3}",
        "   2;                                      !- Maximum Curve Output {BasedOnField A3}",
        " Curve:Quadratic,",
        "   HP_Heat-PLF-fPLR2,                      !- Name",
        "   0.89,                                   !- Coefficient1 Constant",
        "   0.11,                                   !- Coefficient2 x",
        "   0,                                      !- Coefficient3 x**2",
        "   0,                                      !- Minimum Value of x {BasedOnField A2}",
        "   1,                                      !- Maximum Value of x {BasedOnField A2}",
        "   0.7,                                    !- Minimum Curve Output {BasedOnField A3}",
        "   1;                                      !- Maximum Curve Output {BasedOnField A3}",
    })
    assert_true(process_idf(idf_objects1))
    state.init_state(*state)
    GetDXCoils(*state)
    var Coil = state.dataDXCoils.DXCoil[1]
    var StandardRatingsResult: Map[String, Float64]
    var NetHeatingCapRatedHighTemp: Float64 = 0.0
    var NetHeatingCapRatedLowTemp: Float64 = 0.0
    var HSPF: Float64 = 0.0
    var NetHeatingCapRatedHighTemp_2023: Float64 = 0.0
    var NetHeatingCapRatedLowTemp_2023: Float64 = 0.0
    var HSPF2_2023: Float64 = 0.0
    StandardRatingsResult = MultiSpeedDXHeatingCoilStandardRatings(*state, Coil.Name, Coil.coilType, Coil.MSCCapFTemp, Coil.MSCCapFFlow, Coil.MSEIRFTemp, Coil.MSEIRFFlow, Coil.MSPLFFPLR, Coil.MSRatedTotCap, Coil.MSRatedCOP, Coil.MSRatedAirVolFlowRate, Coil.MSFanPowerPerEvapAirFlowRate, Coil.MSFanPowerPerEvapAirFlowRate_2023, Coil.NumOfSpeeds, Coil.RegionNum, Coil.MinOATCompressor, Coil.OATempCompressorOn, Coil.OATempCompressorOnOffBlank, Coil.DefrostControl)
    NetHeatingCapRatedHighTemp = StandardRatingsResult["NetHeatingCapRatedHighTemp"]
    NetHeatingCapRatedLowTemp = StandardRatingsResult["NetHeatingCapRatedLowTemp"]
    HSPF = StandardRatingsResult["HSPF"]
    NetHeatingCapRatedHighTemp_2023 = StandardRatingsResult["NetHeatingCapRatedHighTemp_2023"]
    NetHeatingCapRatedLowTemp_2023 = StandardRatingsResult["NetHeatingCapRatedLowTemp_2023"]
    HSPF2_2023 = StandardRatingsResult["HSPF2_2023"]
    assert_true(HSPF != 0.0)
    assert_true(NetHeatingCapRatedHighTemp != 0.0)
    assert_true(NetHeatingCapRatedLowTemp != 0.0)
    expect_near(1.8604449198065671, HSPF, 0.01)
    expect_near(14723.494682539813, NetHeatingCapRatedHighTemp, 0.01)
    expect_near(8814.4702147982516, NetHeatingCapRatedLowTemp, 0.01)
    expect_near(6.35, HSPF * StandardRatings.ConvFromSIToIP, 0.01)
    assert_true(HSPF2_2023 != 0.0)
    assert_true(NetHeatingCapRatedHighTemp_2023 != 0.0)
    assert_true(NetHeatingCapRatedLowTemp_2023 != 0.0)
    assert_true(HSPF != HSPF2_2023)

def ChillerIPLVTestAirCooled():
    using StandardRatings.CalcChillerIPLV
    state.dataChillerElectricEIR.ElectricEIRChiller.allocate(1)
    state.dataChillerElectricEIR.ElectricEIRChiller[1].Name = "Air Cooled Chiller"
    state.dataChillerElectricEIR.ElectricEIRChiller[1].RefCap = 216000
    state.dataChillerElectricEIR.ElectricEIRChiller[1].RefCOP = 2.81673861898309
    state.dataChillerElectricEIR.ElectricEIRChiller[1].CondenserType = DataPlant.CondenserType.AirCooled
    state.dataChillerElectricEIR.ElectricEIRChiller[1].MinUnloadRat = 0.15
    var curve1 = AddCurve(*state, "AirCooledChillerScrewCmpCapfT")
    curve1.curveType = CurveType.BiQuadratic
    curve1.numDims = 2
    curve1.coeff[0] = 0.98898813
    curve1.coeff[1] = 0.036832851
    curve1.coeff[2] = 0.000174006
    curve1.coeff[3] = -0.000275634
    curve1.coeff[4] = -0.000143667
    curve1.coeff[5] = -0.000246286
    curve1.inputLimits[0].min = 4.44
    curve1.inputLimits[0].max = 10
    curve1.inputLimits[1].min = 23.89
    curve1.inputLimits[1].max = 46.11
    state.dataChillerElectricEIR.ElectricEIRChiller[1].ChillerCapFTIndex = curve1.Num
    var curve2 = AddCurve(*state, "AirCooledChillerScrewCmpEIRfT")
    curve2.curveType = CurveType.BiQuadratic
    curve2.numDims = 2
    curve2.coeff[0] = 0.814058418
    curve2.coeff[1] = 0.002335553
    curve2.coeff[2] = 0.000817786
    curve2.coeff[3] = -0.017129784
    curve2.coeff[4] = 0.000773288
    curve2.coeff[5] = -0.000922024
    curve2.inputLimits[0].min = 4.44
    curve2.inputLimits[0].max = 10
    curve2.inputLimits[1].min = 10
    curve2.inputLimits[1].max = 46.11
    state.dataChillerElectricEIR.ElectricEIRChiller[1].ChillerEIRFTIndex = curve2.Num
    var curve3 = AddCurve(*state, "AirCooledChillerScrewCmpEIRfPLR")
    curve3.curveType = CurveType.Cubic
    curve3.numDims = 1
    curve3.coeff[0] = -0.08117804
    curve3.coeff[1] = 1.433532026
    curve3.coeff[2] = -0.762289434
    curve3.coeff[3] = 0.412199944
    curve3.inputLimits[0].min = 0
    curve3.inputLimits[0].max = 1
    state.dataChillerElectricEIR.ElectricEIRChiller[1].ChillerEIRFPLRIndex = curve3.Num
    var IPLVSI: Float64 = 0.0
    var IPLVIP: Float64 = 0.0
    CalcChillerIPLV(*state, state.dataChillerElectricEIR.ElectricEIRChiller[1].Name