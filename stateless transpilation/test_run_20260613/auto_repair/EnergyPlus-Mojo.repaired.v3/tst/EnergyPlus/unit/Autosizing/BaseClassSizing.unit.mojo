from testing import assert_equal, assert_almost_equal, assert_true, assert_false
from AutosizingFixture import EnergyPlusFixture, SQLiteFixture, has_err_output, process_idf, delimited_string
from CoolingCapacitySizing import CoolingCapacitySizer
from SystemAirFlowSizing import SystemAirFlowSizer
from DataAirSystems import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataSizing import *
from Fans import Fans as Fans
from IOFiles import *
from OutputReportPredefined import OutputReportPredefined
from Psychrometrics import *
from SimulationManager import SimulationManager
from WeatherManager import *
from BaseSizer import BaseSizer

# Note: The original C++ used `using namespace` to bring in symbols.
# In Mojo, we import them explicitly above, so they are available.
# The `state` object is accessed via the test fixture.

@staticmethod
def test_BaseSizer_selectSizerOutput(using self: EnergyPlusFixture):
    var errorsFound: Bool = False
    var PrintFlag: Bool = True
    var RoutineName: StringLiteral = "BaseSizer_selectSizerOutput"
    var CompType: StringLiteral = "testComp"
    var CompName: StringLiteral = "testName"
    var thisSizer: SystemAirFlowSizer
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataSize.ZoneEqSizing.allocate(self.state.dataSize.CurZoneEqNum)
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].DesignSizeFromParent = True
    self.state.dataSize.ZoneSizingRunDone = True
    self.state.dataSize.ZoneSizingInput.allocate(self.state.dataSize.CurZoneEqNum)
    self.state.dataSize.ZoneSizingInput[self.state.dataSize.CurZoneEqNum - 1].ZoneNum = self.state.dataSize.CurZoneEqNum
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].AirVolFlow = -1.0
    var TempSize: Float64 = DataSizing.AutoSize
    thisSizer.initializeWithinEP(self.state, CompType, CompName, PrintFlag, RoutineName)
    var autoSizedValue: Float64 = thisSizer.size(self.state, TempSize, errorsFound)
    assert_equal(-1.0, autoSizedValue)
    assert_equal(AutoSizingResultType.NoError, thisSizer.errorType)

@staticmethod
def test_BaseSizer_GetCoilDesFlowT(using self: EnergyPlusFixture):
    self.state.dataSize.SysSizInput.allocate(1)
    self.state.dataSize.SysSizPeakDDNum.allocate(1)
    self.state.dataSize.FinalSysSizing.allocate(1)
    self.state.dataSize.CalcSysSizing.allocate(1)
    self.state.dataSize.CalcSysSizing[0].SumZoneCoolLoadSeq.allocate(1)
    self.state.dataSize.CalcSysSizing[0].CoolZoneAvgTempSeq.allocate(1)
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtSensCoolPk.allocate(1)
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtCoolFlowPk.allocate(1)
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtTotCoolPk.allocate(1)
    let DesignDayForPeak: Int = 1
    self.state.dataSize.SysSizPeakDDNum[0].SensCoolPeakDD = DesignDayForPeak
    self.state.dataSize.SysSizPeakDDNum[0].CoolFlowPeakDD = DesignDayForPeak
    self.state.dataSize.SysSizPeakDDNum[0].TotCoolPeakDD = DesignDayForPeak
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtSensCoolPk[DesignDayForPeak - 1] = 1
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtCoolFlowPk[DesignDayForPeak - 1] = 1
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtTotCoolPk[DesignDayForPeak - 1] = 1
    self.state.dataSize.FinalSysSizing[0].CoolSupTemp = 10
    self.state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = 2.0
    self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow = 0.15
    self.state.dataSize.DataAirFlowUsedForSizing = 0.2
    self.state.dataEnvrn.StdRhoAir = 1000
    self.state.dataSize.CalcSysSizing[0].SumZoneCoolLoadSeq[0] = 1250000
    let sysNum: Int = 1
    let CpAir: Float64 = 4179
    var designFlowValue: Float64
    var designExitTemp: Float64
    var designExitHumRat: Float64
    self.state.dataSize.SysSizInput[0].coolingPeakLoad = DataSizing.PeakLoad.TotalCooling
    self.state.dataSize.FinalSysSizing[0].coolingPeakLoad = DataSizing.PeakLoad.TotalCooling
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VAV
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].CoolSupTemp, designExitTemp, 1e-12)
    assert_almost_equal(0.002, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.OnOff
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].CoolSupTemp, designExitTemp, 1e-12)
    assert_almost_equal(0.2, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VT
    self.state.dataSize.CalcSysSizing[0].CoolZoneAvgTempSeq[0] = 10
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].CoolSupTemp, designExitTemp, 1e-12)
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VT
    self.state.dataSize.CalcSysSizing[0].CoolZoneAvgTempSeq[0] = 15
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(13.00590, designExitTemp, 0.0001)
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.Bypass
    self.state.dataSize.CalcSysSizing[0].CoolZoneAvgTempSeq[0] = 13
    self.state.dataSize.CalcSysSizing[0].MixTempAtCoolPeak = 15
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(10, designExitTemp, 1e-12)
    assert_almost_equal(0.119823, designFlowValue, 0.0001)
    self.state.dataSize.CalcSysSizing[0].MixTempAtCoolPeak = 5
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(10, designExitTemp, 1e-12)
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].coolingPeakLoad = DataSizing.PeakLoad.SensibleCooling
    self.state.dataSize.FinalSysSizing[0].coolingPeakLoad = DataSizing.PeakLoad.SensibleCooling
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VT
    self.state.dataSize.CalcSysSizing[0].CoolZoneAvgTempSeq[0] = 10
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].CoolSupTemp, designExitTemp, 1e-12)
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.Bypass
    self.state.dataSize.CalcSysSizing[0].CoolZoneAvgTempSeq[0] = 13
    self.state.dataSize.CalcSysSizing[0].MixTempAtCoolPeak = 15
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(10, designExitTemp, 1e-12)
    assert_almost_equal(0.119823, designFlowValue, 0.0001)

@staticmethod
def test_BaseSizer_GetCoilDesFlowT_NoPeak(using self: EnergyPlusFixture):
    self.state.dataSize.SysSizInput.allocate(1)
    self.state.dataSize.SysSizPeakDDNum.allocate(1)
    self.state.dataSize.FinalSysSizing.allocate(1)
    self.state.dataSize.CalcSysSizing.allocate(1)
    self.state.dataSize.CalcSysSizing[0].SumZoneCoolLoadSeq.allocate(1)
    self.state.dataSize.CalcSysSizing[0].CoolZoneAvgTempSeq.allocate(1)
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtSensCoolPk.allocate(1)
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtCoolFlowPk.allocate(1)
    self.state.dataSize.SysSizPeakDDNum[0].TimeStepAtTotCoolPk.allocate(1)
    let DesignDayForPeak: Int = 0
    self.state.dataSize.SysSizPeakDDNum[0].SensCoolPeakDD = DesignDayForPeak
    self.state.dataSize.SysSizPeakDDNum[0].CoolFlowPeakDD = DesignDayForPeak
    self.state.dataSize.SysSizPeakDDNum[0].TotCoolPeakDD = DesignDayForPeak
    self.state.dataSize.FinalSysSizing[0].CoolSupTemp = 10
    self.state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = 2.0
    self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow = 0.15
    self.state.dataSize.DataAirFlowUsedForSizing = 0.2
    self.state.dataEnvrn.StdRhoAir = 1000
    self.state.dataSize.CalcSysSizing[0].SumZoneCoolLoadSeq[0] = 1250000
    let sysNum: Int = 1
    let CpAir: Float64 = 4179
    var designFlowValue: Float64
    var designExitTemp: Float64
    var designExitHumRat: Float64
    self.state.dataSize.SysSizInput[0].coolingPeakLoad = DataSizing.PeakLoad.TotalCooling
    self.state.dataSize.FinalSysSizing[0].coolingPeakLoad = DataSizing.PeakLoad.TotalCooling
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VAV
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].CoolSupTemp, designExitTemp, 1e-12)
    assert_almost_equal(0.002, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.OnOff
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_false(has_err_output(True))
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].CoolSupTemp, designExitTemp, 1e-12)
    assert_almost_equal(0.2, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VT
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_true(has_err_output(True))
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].CoolSupTemp, designExitTemp, 1e-12)
    assert_almost_equal(0.002, designFlowValue, 1e-12)
    self.state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.Bypass
    DataSizing.GetCoilDesFlowT(self.state, sysNum, CpAir, designFlowValue, designExitTemp, designExitHumRat)
    assert_true(has_err_output(True))
    assert_almost_equal(self.state.dataSize.FinalSysSizing[0].CoolSupTemp, designExitTemp, 1e-12)
    assert_almost_equal(0.002, designFlowValue, 1e-12)

@staticmethod
def test_BaseSizer_RequestSizingSystem(using self: EnergyPlusFixture):
    self.state.init_state(self.state)
    var CompName: String
    var CompType: String
    var SizingString: String
    var SizingType: Int
    var SizingResult: Float64
    var PrintWarning: Bool
    var CallingRoutine: String
    self.state.dataSize.DataTotCapCurveIndex = 0
    self.state.dataSize.DataDesOutletAirTemp = 0.0
    self.state.dataSize.CurZoneEqNum = 0
    self.state.dataSize.CurOASysNum = 0
    self.state.dataSize.CurSysNum = 1
    self.state.dataSize.FinalSysSizing.allocate(1)
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].CoolSupTemp = 12.0
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].CoolSupHumRat = 0.0085
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].MixTempAtCoolPeak = 28.0
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].MixHumRatAtCoolPeak = 0.0075
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].DesCoolVolFlow = 1.00
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].DesOutAirVolFlow = 0.2
    self.state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].NumOACoolCoils = 0
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].supFanNum = 0
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].retFanNum = 0
    self.state.dataSize.SysSizingRunDone = True
    self.state.dataSize.SysSizInput.allocate(1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = self.state.dataSize.CurSysNum
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataEnvrn.StdBaroPress = 101325.0
    self.state.dataEnvrn.StdRhoAir = 1.1583684
    self.state.dataSize.DataFlowUsedForSizing = self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].DesCoolVolFlow
    self.state.dataSize.UnitarySysEqSizing.allocate(1)
    self.state.dataSize.OASysEqSizing.allocate(1)
    CompType = "COIL:COOLING:DX:SINGLESPEED"
    CompName = "Single Speed DX Cooling Coil"
    SizingType = HVAC.CoolingCapacitySizing
    SizingString = "Nominal Capacity"
    SizingResult = DataSizing.AutoSize
    PrintWarning = True
    CallingRoutine = "RequestSizing"
    self.state.dataSize.DataIsDXCoil = True
    var errorsFound: Bool = False
    var sizerCoolingCapacity: CoolingCapacitySizer
    sizerCoolingCapacity.overrideSizingString(SizingString)
    sizerCoolingCapacity.initializeWithinEP(self.state, CompType, CompName, PrintWarning, CallingRoutine)
    SizingResult = sizerCoolingCapacity.size(self.state, SizingResult, errorsFound)
    assert_almost_equal(18882.0, SizingResult, 0.1)
    assert_almost_equal(self.state.dataSize.DataCoilSizingAirInTemp, 28.0, 0.0000001)
    assert_almost_equal(self.state.dataSize.DataCoilSizingAirInHumRat, 0.0075, 0.0000001)
    assert_almost_equal(self.state.dataSize.DataCoilSizingAirOutTemp, 12.0, 0.0000001)
    assert_almost_equal(self.state.dataSize.DataCoilSizingAirOutHumRat, 0.0075, 0.0000001)
    assert_almost_equal(self.state.dataSize.DataCoilSizingFanCoolLoad, 0.0, 0.0000001)
    assert_almost_equal(self.state.dataSize.DataCoilSizingCapFT, 1.0, 0.0000001)
    CompType = "COIL:COOLING:WATER"
    CompName = "Chilled Water Cooling Coil"
    SizingResult = DataSizing.AutoSize
    self.state.dataEnvrn.StdRhoAir = 1.18
    self.state.dataSize.DataIsDXCoil = False
    sizerCoolingCapacity.initializeWithinEP(self.state, CompType, CompName, PrintWarning, CallingRoutine)
    SizingResult = sizerCoolingCapacity.size(self.state, SizingResult, errorsFound)
    assert_almost_equal(19234.6, SizingResult, 0.1)

@staticmethod
def test_BaseSizer_RequestSizingSystemWithFans(using self: EnergyPlusFixture):
    var idf_objects: String = "  Fan:SystemModel,\n" \
        "    Test Fan 1 ,                   !- Name\n" \
        "    ,                            !- Availability Schedule Name\n" \
        "    TestFanAirInletNode,         !- Air Inlet Node Name\n" \
        "    TestFanOutletNode,           !- Air Outlet Node Name\n" \
        "    1.0 ,                        !- Design Maximum Air Flow Rate\n" \
        "    Discrete ,                   !- Speed Control Method\n" \
        "    0.0,                         !- Electric Power Minimum Flow Rate Fraction\n" \
        "    50.0,                       !- Design Pressure Rise\n" \
        "    0.9 ,                        !- Motor Efficiency\n" \
        "    1.0 ,                        !- Motor In Air Stream Fraction\n" \
        "    AUTOSIZE,                    !- Design Electric Power Consumption\n" \
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method\n" \
        "    ,                            !- Electric Power Per Unit Flow Rate\n" \
        "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure\n" \
        "    0.50;                        !- Fan Total Efficiency\n" \
        "  \n" \
        "  Fan:SystemModel,\n" \
        "    Test Fan 2 ,                   !- Name\n" \
        "    ,                            !- Availability Schedule Name\n" \
        "    TestFan2AirInletNode,         !- Air Inlet Node Name\n" \
        "    TestFan2OutletNode,           !- Air Outlet Node Name\n" \
        "    1.0 ,                        !- Design Maximum Air Flow Rate\n" \
        "    Discrete ,                   !- Speed Control Method\n" \
        "    0.0,                         !- Electric Power Minimum Flow Rate Fraction\n" \
        "    100.0,                       !- Design Pressure Rise\n" \
        "    0.9 ,                        !- Motor Efficiency\n" \
        "    1.0 ,                        !- Motor In Air Stream Fraction\n" \
        "    AUTOSIZE,                    !- Design Electric Power Consumption\n" \
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method\n" \
        "    ,                            !- Electric Power Per Unit Flow Rate\n" \
        "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure\n" \
        "    0.50;                        !- Fan Total Efficiency\n" \
        "  Fan:SystemModel,\n" \
        "    Test Fan 3 ,                   !- Name\n" \
        "    ,                            !- Availability Schedule Name\n" \
        "    TestFan3AirInletNode,         !- Air Inlet Node Name\n" \
        "    TestFan3OutletNode,           !- Air Outlet Node Name\n" \
        "    1.0 ,                        !- Design Maximum Air Flow Rate\n" \
        "    Discrete ,                   !- Speed Control Method\n" \
        "    0.0,                         !- Electric Power Minimum Flow Rate Fraction\n" \
        "    200.0,                       !- Design Pressure Rise\n" \
        "    0.9 ,                        !- Motor Efficiency\n" \
        "    1.0 ,                        !- Motor In Air Stream Fraction\n" \
        "    AUTOSIZE,                    !- Design Electric Power Consumption\n" \
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method\n" \
        "    ,                            !- Electric Power Per Unit Flow Rate\n" \
        "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure\n" \
        "    0.50;                        !- Fan Total Efficiency\n" \
        "  Fan:ConstantVolume,\n" \
        "    Test Fan 4,            !- Name\n" \
        "    ,    !- Availability Schedule Name\n" \
        "    0.5,                     !- Fan Total Efficiency\n" \
        "    25.0,                   !- Pressure Rise {Pa}\n" \
        "    1.0,                  !- Maximum Flow Rate {m3/s}\n" \
        "    0.9,                     !- Motor Efficiency\n" \
        "    1.0,                     !- Motor In Airstream Fraction\n" \
        "    TestFan4AirInletNode,         !- Air Inlet Node Name\n" \
        "    TestFan4OutletNode;           !- Air Outlet Node Name\n"
    assert_true(process_idf(idf_objects))
    self.state.init_state(self.state)
    Fans.GetFanInput(self.state)
    self.state.dataSize.CurZoneEqNum = 0
    self.state.dataSize.CurSysNum = 0
    self.state.dataSize.CurOASysNum = 0
    self.state.dataEnvrn.StdRhoAir = 1.2
    var fan1 = self.state.dataFans.fans(Fans.GetFanIndex(self.state, "TEST FAN 1"))
    fan1.simulate(self.state, False, _, _)          # triggers sizing call
    var locFanSizeVdot: Float64 = fan1.maxAirFlowRate # get function
    var locDesignHeatGain1: Float64 = fan1.getDesignHeatGain(self.state, locFanSizeVdot)
    assert_almost_equal(locDesignHeatGain1, 100.0, 0.1)
    var fan2 = self.state.dataFans.fans(Fans.GetFanIndex(self.state, "TEST FAN 2"))
    fan2.simulate(self.state, False, _, _)   # triggers sizing call
    locFanSizeVdot = fan2.maxAirFlowRate # get function
    var locDesignHeatGain2: Float64 = fan2.getDesignHeatGain(self.state, locFanSizeVdot)
    assert_almost_equal(locDesignHeatGain2, 200.0, 0.1)
    var fan3 = self.state.dataFans.fans(Fans.GetFanIndex(self.state, "TEST FAN 3"))
    self.state.dataEnvrn.StdRhoAir = 1.2
    fan3.simulate(self.state, False, _, _)                       # triggers sizing call
    locFanSizeVdot = self.state.dataFans.fans(3).maxAirFlowRate # get function
    var locDesignHeatGain3: Float64 = fan3.getDesignHeatGain(self.state, locFanSizeVdot)
    assert_almost_equal(locDesignHeatGain3, 400.0, 0.1)
    var fan4 = self.state.dataFans.fans(Fans.GetFanIndex(self.state, "TEST FAN 4"))
    var locDesignHeatGain4: Float64 = fan4.getDesignHeatGain(self.state, locFanSizeVdot)
    assert_almost_equal(locDesignHeatGain4, 50.0, 0.1)
    var CompName: String
    var CompType: String
    var SizingString: String
    var SizingType: Int
    var SizingResult: Float64
    var PrintWarning: Bool
    var CallingRoutine: String
    self.state.dataSize.DataTotCapCurveIndex = 0
    self.state.dataSize.DataDesOutletAirTemp = 0.0
    self.state.dataSize.CurZoneEqNum = 0
    self.state.dataSize.CurOASysNum = 0
    self.state.dataSize.CurSysNum = 1
    self.state.dataSize.FinalSysSizing.allocate(1)
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].CoolSupTemp = 12.0
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].CoolSupHumRat = 0.0085
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].MixTempAtCoolPeak = 28.0
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].MixHumRatAtCoolPeak = 0.0075
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].DesCoolVolFlow = 1.00
    self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].DesOutAirVolFlow = 0.2
    self.state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].NumOACoolCoils = 0
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].supFanNum = 0
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].retFanNum = 0
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].supFanType = HVAC.FanType.Invalid
    self.state.dataSize.SysSizingRunDone = True
    self.state.dataSize.SysSizInput.allocate(1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = self.state.dataSize.CurSysNum
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataEnvrn.StdBaroPress = 101325.0
    self.state.dataEnvrn.StdRhoAir = 1.1583684
    self.state.dataSize.DataFlowUsedForSizing = self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].DesCoolVolFlow
    self.state.dataSize.UnitarySysEqSizing.allocate(1)
    self.state.dataSize.OASysEqSizing.allocate(1)
    CompType = "COIL:COOLING:DX:SINGLESPEED"
    CompName = "Single Speed DX Cooling Coil"
    SizingType = HVAC.CoolingCapacitySizing
    SizingString = "Nominal Capacity"
    SizingResult = DataSizing.AutoSize
    PrintWarning = True
    CallingRoutine = "RequestSizing"
    self.state.dataSize.DataIsDXCoil = True
    var errorsFound: Bool = False
    var sizerCoolingCapacity: CoolingCapacitySizer
    sizerCoolingCapacity.overrideSizingString(SizingString)
    sizerCoolingCapacity.initializeWithinEP(self.state, CompType, CompName, PrintWarning, CallingRoutine)
    SizingResult = sizerCoolingCapacity.size(self.state, SizingResult, errorsFound)
    assert_almost_equal(18882.0, SizingResult, 0.1)
    var dxCoilSizeNoFan: Float64 = SizingResult
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].supFanNum = Fans.GetFanIndex(self.state, "TEST FAN 4")
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].retFanNum = 0
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].supFanType = HVAC.FanType.Constant
    CompType = "COIL:COOLING:DX:SINGLESPEED"
    CompName = "Single Speed DX Cooling Coil"
    SizingType = HVAC.CoolingCapacitySizing
    SizingString = "Nominal Capacity"
    SizingResult = DataSizing.AutoSize
    PrintWarning = True
    CallingRoutine = "RequestSizing"
    self.state.dataSize.DataIsDXCoil = True
    var expectedDXCoilSize: Float64 = dxCoilSizeNoFan + locDesignHeatGain4
    sizerCoolingCapacity.initializeWithinEP(self.state, CompType, CompName, PrintWarning, CallingRoutine)
    SizingResult = sizerCoolingCapacity.size(self.state, SizingResult, errorsFound)
    assert_almost_equal(expectedDXCoilSize, SizingResult, 0.1)
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].supFanNum = Fans.GetFanIndex(self.state, "TEST FAN 3")
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].retFanNum = 0
    self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].supFanType = HVAC.FanType.SystemModel
    CompType = "COIL:COOLING:DX:SINGLESPEED"
    CompName = "Single Speed DX Cooling Coil"
    SizingType = HVAC.CoolingCapacitySizing
    SizingString = "Nominal Capacity"
    SizingResult = DataSizing.AutoSize
    PrintWarning = True
    CallingRoutine = "RequestSizing"
    self.state.dataSize.DataIsDXCoil = True
    expectedDXCoilSize = dxCoilSizeNoFan + locDesignHeatGain3
    sizerCoolingCapacity.initializeWithinEP(self.state, CompType, CompName, PrintWarning, CallingRoutine)
    SizingResult = sizerCoolingCapacity.size(self.state, SizingResult, errorsFound)
    assert_almost_equal(expectedDXCoilSize, SizingResult, 0.1)

@staticmethod
def test_BaseSizer_RequestSizingZone(using self: EnergyPlusFixture):
    self.state.init_state(self.state)
    let ZoneNum: Int = 1
    var CompName: String
    var CompType: String
    var SizingString: String
    var SizingType: Int
    var SizingResult: Float64
    var PrintWarning: Bool
    var CallingRoutine: String
    self.state.dataSize.DataTotCapCurveIndex = 0
    self.state.dataSize.DataDesOutletAirTemp = 0.0
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataSize.CurOASysNum = 0
    self.state.dataSize.CurSysNum = 0
    self.state.dataSize.FinalZoneSizing.allocate(1)
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].CoolDesTemp = 12.0
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].CoolDesHumRat = 0.0085
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolCoilInTemp = 28.0
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolCoilInHumRat = 0.0075
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolOAFlowFrac = 0.2
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow = 0.30
    self.state.dataSize.ZoneSizingRunDone = True
    self.state.dataEnvrn.StdBaroPress = 101325.0
    self.state.dataEnvrn.StdRhoAir = 1.1583684
    self.state.dataSize.ZoneEqSizing.allocate(1)
    self.state.dataSize.ZoneSizingInput.allocate(1)
    self.state.dataSize.ZoneSizingInput[0].ZoneNum = ZoneNum
    self.state.dataSize.NumZoneSizingInput = 1
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].DesignSizeFromParent = False
    self.state.dataSize.DataFlowUsedForSizing = self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow
    CompType = "COIL:COOLING:DX:SINGLESPEED"
    CompName = "Single Speed DX Cooling Coil"
    SizingType = HVAC.CoolingCapacitySizing
    SizingString = "Nominal Capacity"
    SizingResult = DataSizing.AutoSize
    PrintWarning = True
    CallingRoutine = "RequestSizing"
    self.state.dataSize.DataIsDXCoil = True
    var errorsFound: Bool = False
    var sizerCoolingCapacity: CoolingCapacitySizer
    sizerCoolingCapacity.overrideSizingString(SizingString)
    sizerCoolingCapacity.initializeWithinEP(self.state, CompType, CompName, PrintWarning, CallingRoutine)
    SizingResult = sizerCoolingCapacity.size(self.state, SizingResult, errorsFound)
    assert_almost_equal(5664.6, SizingResult, 0.1)
    CompType = "COIL:COOLING:WATER"
    CompName = "Chilled Water Cooling Coil"
    SizingResult = DataSizing.AutoSize
    self.state.dataEnvrn.StdRhoAir = 1.18
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolMassFlow = \
        self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow * self.state.dataEnvrn.StdRhoAir
    self.state.dataSize.DataIsDXCoil = False
    sizerCoolingCapacity.initializeWithinEP(self.state, CompType, CompName, PrintWarning, CallingRoutine)
    SizingResult = sizerCoolingCapacity.size(self.state, SizingResult, errorsFound)
    assert_almost_equal(5770.4, SizingResult, 0.1)

@staticmethod
def test_BaseSizer_SQLiteRecordReportSizerOutputTest(using self: SQLiteFixture):
    var CompName: String
    var CompType: String
    var VarDesc: String
    var UsrDesc: String
    var VarValue: Float64
    var UsrValue: Float64
    CompType = "BOILER:HOTWATER"
    CompName = "RESIDENTIAL BOILER ELECTRIC"
    VarDesc = "Design Size Nominal Capacity [W]"
    VarValue = 105977.98934
    UsrDesc = "User-Specified Nominal Capacity [W]"
    UsrValue = 26352.97405
    BaseSizer.reportSizerOutput(self.state, CompType, CompName, VarDesc, VarValue, UsrDesc, UsrValue)
    var result = queryResult("SELECT * FROM ComponentSizes;", "ComponentSizes")
    assert_equal(2, result.size())
    var testResult0: List[String] = ["1", "BOILER:HOTWATER", "RESIDENTIAL BOILER ELECTRIC", "Design Size Nominal Capacity", "105977.98934", "W", ""]
    var testResult1: List[String] = ["2", "BOILER:HOTWATER", "RESIDENTIAL BOILER ELECTRIC", "User-Specified Nominal Capacity", "26352.97405", "W", ""]
    assert_equal(testResult0, result[0])
    assert_equal(testResult1, result[1])

@staticmethod
def test_BaseSizer_setOAFracForZoneEqSizing_Test(using self: EnergyPlusFixture):
    var sizer: CoolingCapacitySizer
    self.state.dataSize.ZoneEqSizing.allocate(1)
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].OAVolFlow = 0.34
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].ATMixerVolFlow = 0.0
    self.state.dataEnvrn.StdRhoAir = 1.23
    var oaFrac: Float64 = 0.0
    var DesMassFlow: Float64 = 0.685
    var massFlowRate: Float64 = self.state.dataEnvrn.StdRhoAir * self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].OAVolFlow
    var oaFrac_Test: Float64 = massFlowRate / DesMassFlow
    var zoneEqSizing = self.state.dataSize.ZoneEqSizing[0]
    oaFrac = sizer.setOAFracForZoneEqSizing(self.state, DesMassFlow, zoneEqSizing)
    assert_equal(oaFrac, oaFrac_Test)
    zoneEqSizing.ATMixerVolFlow = 0.11
    oaFrac = 0.0
    massFlowRate = self.state.dataEnvrn.StdRhoAir * zoneEqSizing.ATMixerVolFlow
    oaFrac_Test = massFlowRate / DesMassFlow
    oaFrac = sizer.EnergyPlus.BaseSizer.setOAFracForZoneEqSizing(self.state, DesMassFlow, zoneEqSizing)
    assert_equal(oaFrac, oaFrac_Test)
    DesMassFlow = 0.0
    oaFrac = 1.0
    oaFrac_Test = 0.0
    zoneEqSizing.OAVolFlow = 1.0
    zoneEqSizing.ATMixerVolFlow = 1.0
    oaFrac = sizer.EnergyPlus.BaseSizer.setOAFracForZoneEqSizing(self.state, DesMassFlow, zoneEqSizing)
    assert_equal(oaFrac, oaFrac_Test)

@staticmethod
def test_BaseSizer_setZoneCoilInletConditions(using self: EnergyPlusFixture):
    self.state.dataSize.ZoneEqSizing.allocate(1)
    self.state.dataSize.CurZoneEqNum = 1
    var zoneEqSizing = self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1]
    self.state.dataSize.FinalZoneSizing.allocate(1)
    var finalZoneSizing = self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1]
    zoneEqSizing.OAVolFlow = 0.34
    zoneEqSizing.ATMixerVolFlow = 0.0
    self.state.dataEnvrn.StdRhoAir = 1.23
    var DesMassFlow: Float64 = 0.685
    var massFlowRate: Float64 = self.state.dataEnvrn.StdRhoAir * zoneEqSizing.OAVolFlow
    var oaFrac: Float64 = massFlowRate / DesMassFlow
    zoneEqSizing.ATMixerHeatPriDryBulb = 22.0
    finalZoneSizing.ZoneRetTempAtHeatPeak = 25.0
    finalZoneSizing.ZoneTempAtHeatPeak = 20.0
    finalZoneSizing.OutTempAtHeatPeak = 10.0
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 0.0
    var zoneCond: Float64 = finalZoneSizing.ZoneTempAtHeatPeak
    var calcCoilInletCond: Float64 = zoneCond
    var sizer: CoolingCapacitySizer
    var coilInletCond: Float64 = sizer.setHeatCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerVolFlow = 1.0
    zoneEqSizing.OAVolFlow = 0.0
    zoneCond = finalZoneSizing.ZoneRetTempAtHeatPeak
    var oaCond: Float64 = zoneEqSizing.ATMixerHeatPriDryBulb
    calcCoilInletCond = (oaFrac * oaCond) + ((1.0 - oaFrac) * zoneCond)
    coilInletCond = sizer.setHeatCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 1.0
    zoneCond = finalZoneSizing.ZoneTempAtHeatPeak
    oaCond = finalZoneSizing.OutTempAtHeatPeak
    calcCoilInletCond = (oaFrac * oaCond) + ((1.0 - oaFrac) * zoneCond)
    coilInletCond = sizer.setHeatCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerHeatPriDryBulb = 0.0
    finalZoneSizing.ZoneRetTempAtHeatPeak = 0.0
    finalZoneSizing.ZoneTempAtHeatPeak = 0.0
    finalZoneSizing.OutTempAtHeatPeak = 0.0
    zoneEqSizing.ATMixerHeatPriHumRat = 0.008
    finalZoneSizing.ZoneHumRatAtHeatPeak = 0.01
    finalZoneSizing.OutHumRatAtHeatPeak = 0.003
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 0.0
    zoneCond = finalZoneSizing.ZoneHumRatAtHeatPeak
    calcCoilInletCond = zoneCond
    coilInletCond = sizer.setHeatCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerVolFlow = 1.0
    zoneEqSizing.OAVolFlow = 0.0
    zoneCond = finalZoneSizing.ZoneHumRatAtHeatPeak
    oaCond = zoneEqSizing.ATMixerHeatPriHumRat
    calcCoilInletCond = (oaFrac * oaCond) + ((1.0 - oaFrac) * zoneCond)
    coilInletCond = sizer.setHeatCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 1.0
    zoneCond = finalZoneSizing.ZoneHumRatAtHeatPeak
    oaCond = finalZoneSizing.OutHumRatAtHeatPeak
    calcCoilInletCond = (oaFrac * oaCond) + ((1.0 - oaFrac) * zoneCond)
    coilInletCond = sizer.setHeatCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, calcCoilInletCond)
    zoneEqSizing.ATMixerHeatPriHumRat = 0.0
    finalZoneSizing.ZoneHumRatAtHeatPeak = 0.0
    finalZoneSizing.OutHumRatAtHeatPeak = 0.0
    zoneEqSizing.ATMixerCoolPriDryBulb = 22.0
    finalZoneSizing.ZoneRetTempAtCoolPeak = 25.0
    finalZoneSizing.ZoneTempAtCoolPeak = 20.0
    finalZoneSizing.OutTempAtCoolPeak = 10.0
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 0.0
    zoneCond = finalZoneSizing.ZoneTempAtCoolPeak
    calcCoilInletCond = zoneCond
    coilInletCond = sizer.setCoolCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerVolFlow = 1.0
    zoneEqSizing.OAVolFlow = 0.0
    zoneCond = finalZoneSizing.ZoneRetTempAtCoolPeak
    oaCond = zoneEqSizing.ATMixerCoolPriDryBulb
    calcCoilInletCond = (oaFrac * oaCond) + ((1.0 - oaFrac) * zoneCond)
    coilInletCond = sizer.setCoolCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 1.0
    zoneCond = finalZoneSizing.ZoneTempAtCoolPeak
    oaCond = finalZoneSizing.OutTempAtCoolPeak
    calcCoilInletCond = (oaFrac * oaCond) + ((1.0 - oaFrac) * zoneCond)
    coilInletCond = sizer.setCoolCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerCoolPriDryBulb = 0.0
    finalZoneSizing.ZoneRetTempAtCoolPeak = 0.0
    finalZoneSizing.ZoneTempAtCoolPeak = 0.0
    finalZoneSizing.OutTempAtCoolPeak = 0.0
    zoneEqSizing.ATMixerCoolPriHumRat = 0.008
    finalZoneSizing.ZoneHumRatAtCoolPeak = 0.01
    finalZoneSizing.OutHumRatAtCoolPeak = 0.003
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 0.0
    zoneCond = finalZoneSizing.ZoneHumRatAtCoolPeak
    calcCoilInletCond = zoneCond
    coilInletCond = sizer.setCoolCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerVolFlow = 1.0
    zoneEqSizing.OAVolFlow = 0.0
    zoneCond = finalZoneSizing.ZoneHumRatAtCoolPeak
    oaCond = zoneEqSizing.ATMixerCoolPriHumRat
    calcCoilInletCond = (oaFrac * oaCond) + ((1.0 - oaFrac) * zoneCond)
    coilInletCond = sizer.setCoolCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 1.0
    zoneCond = finalZoneSizing.ZoneHumRatAtCoolPeak
    oaCond = finalZoneSizing.OutHumRatAtCoolPeak
    calcCoilInletCond = (oaFrac * oaCond) + ((1.0 - oaFrac) * zoneCond)
    coilInletCond = sizer.setCoolCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_almost_equal(coilInletCond, calcCoilInletCond, 1e-12)
    zoneEqSizing.ATMixerCoolPriHumRat = 0.0
    finalZoneSizing.ZoneHumRatAtCoolPeak = 0.0
    finalZoneSizing.OutHumRatAtCoolPeak = 0.0
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 0.0
    coilInletCond = sizer.setHeatCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setHeatCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setCoolCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setCoolCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    zoneEqSizing.ATMixerVolFlow = 1.0
    zoneEqSizing.OAVolFlow = 0.0
    coilInletCond = sizer.setHeatCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setHeatCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setCoolCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setCoolCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    zoneEqSizing.ATMixerVolFlow = 0.0
    zoneEqSizing.OAVolFlow = 1.0
    coilInletCond = sizer.setHeatCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setHeatCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setCoolCoilInletTempForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)
    coilInletCond = sizer.setCoolCoilInletHumRatForZoneEqSizing(oaFrac, zoneEqSizing, finalZoneSizing)
    assert_equal(coilInletCond, 0.0)

@staticmethod
def test_BaseSizer_FanPeak(using self: EnergyPlusFixture):
    self.state.dataGlobal.TimeStepsInHour = 4
    self.state.dataGlobal.MinutesInTimeStep = 15
    let ZoneNum: Int = 1
    var CompName: String
    var CompType: String
    var SizingString: String
    var SizingType: Int
    var SizingResult: Float64
    var PrintWarning: Bool
    var CallingRoutine: String
    CompType = "Fan:ConstantVolume"
    CompName = "My Fan"
    SizingType = HVAC.SystemAirflowSizing
    SizingString = "Nominal Capacity"
    SizingResult = DataSizing.AutoSize
    PrintWarning = True
    CallingRoutine = "Size Fan: "
    self.state.dataSize.DataIsDXCoil = False
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataSize.CurOASysNum = 0
    self.state.dataSize.CurSysNum = 0
    self.state.dataSize.FinalZoneSizing.allocate(1)
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow = 0.30
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].CoolDDNum = 1
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].TimeStepNumAtCoolMax = 72
    self.state.dataWeather.DesDayInput.allocate(1)
    var DDTitle: String = "CHICAGO ANN CLG 1% CONDNS DB=>MWB"
    self.state.dataWeather.DesDayInput[self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].CoolDDNum - 1].Title = DDTitle
    self.state.dataWeather.DesDayInput[self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].CoolDDNum - 1].Month = 7
    self.state.dataWeather.DesDayInput[self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].CoolDDNum - 1].DayOfMonth = 15
    self.state.dataEnvrn.TotDesDays = 1
    self.state.dataSize.ZoneSizingRunDone = True
    self.state.dataSize.ZoneEqSizing.allocate(1)
    self.state.dataSize.ZoneSizingInput.allocate(1)
    self.state.dataSize.ZoneSizingInput[0].ZoneNum = ZoneNum
    self.state.dataSize.NumZoneSizingInput = 1
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].DesignSizeFromParent = False
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SizingMethod[SizingType - 1] = DataSizing.SupplyAirFlowRate
    var errorsFound: Bool = False
    var sizerSystemAirFlow: SystemAirFlowSizer
    sizerSystemAirFlow.initializeWithinEP(self.state, CompType, CompName, PrintWarning, CallingRoutine)
    SizingResult = sizerSystemAirFlow.size(self.state, SizingResult, errorsFound)
    assert_equal(DDTitle, OutputReportPredefined.RetrievePreDefTableEntry(self.state, self.state.dataOutRptPredefined.pdchFanDesDay, CompName))
    assert_equal("7/15 18:00:00", OutputReportPredefined.RetrievePreDefTableEntry(self.state, self.state.dataOutRptPredefined.pdchFanPkTime, CompName))
    assert_equal("End Use Subcategory", self.state.dataOutRptPredefined.columnTag(self.state.dataOutRptPredefined.pdchFanEndUse).heading)

@staticmethod
def test_BaseSizer_SupplyAirTempLessThanZoneTStatTest(using self: EnergyPlusFixture):
    var idf_objects: String = "  Timestep,1;\n" \
        "  Building,\n" \
        "    Simple One Zone,         !- Name\n" \
        "    0,                       !- North Axis {deg}\n" \
        "    Suburbs,                 !- Terrain\n" \
        "    0.04,                    !- Loads Convergence Tolerance Value\n" \
        "    0.004,                   !- Temperature Convergence Tolerance Value {deltaC}\n" \
        "    MinimalShadowing,        !- Solar Distribution\n" \
        "    30,                      !- Maximum Number of Warmup Days\n" \
        "    6;                       !- Minimum Number of Warmup Days\n" \
        "  HeatBalanceAlgorithm,ConductionTransferFunction;\n" \
        "  SurfaceConvectionAlgorithm:Inside,TARP;\n" \
        "  SurfaceConvectionAlgorithm:Outside,DOE-2;\n" \
        "  SimulationControl,\n" \
        "    Yes,                     !- Do Zone Sizing Calculation\n" \
        "    No,                      !- Do System Sizing Calculation\n" \
        "    No,                      !- Do Plant Sizing Calculation\n" \
        "    Yes,                     !- Run Simulation for Sizing Periods\n" \
        "    No;                      !- Run Simulation for Weather File Run Periods\n" \
        "    Site:Location,\n" \
        "      Phoenix Sky Harbor Intl Ap_AZ_USA,  !- Name\n" \
        "      33.45,                   !- Latitude {deg}\n" \
        "      -111.98,                 !- Longitude {deg}\n" \
        "      -7,                      !- Time Zone {hr}\n" \
        "      337;                     !- Elevation {m}\n" \
        "    Site:GroundTemperature:BuildingSurface,20.83,20.81,20.88,20.96,21.03,23.32,23.68,23.74,23.75,21.42,21.09,20.9;\n" \
        "    SizingPeriod:DesignDay,\n" \
        "      Phoenix Sky Harbor Intl Ap Ann Clg .4% Condns DB=>MWB,  !- Name\n" \
        "      7,                       !- Month\n" \
        "      21,                      !- Day of Month\n" \
        "      SummerDesignDay,         !- Day Type\n" \
        "      43.4,                    !- Maximum Dry-Bulb Temperature {C}\n" \
        "      12,                      !- Daily Dry-Bulb Temperature Range {deltaC}\n" \
        "      DefaultMultipliers,      !- Dry-Bulb Temperature Range Modifier Type\n" \
        "      ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name\n" \
        "      Wetbulb,                 !- Humidity Condition Type\n" \
        "      21.1,                    !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}\n" \
        "      ,                        !- Humidity Condition Day Schedule Name\n" \
        "      ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}\n" \
        "      ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}\n" \
        "      ,                        !- Daily Wet-Bulb Temperature Range {deltaC}\n" \
        "      97342,                   !- Barometric Pressure {Pa}\n" \
        "      4.1,                     !- Wind Speed {m/s}\n" \
        "      260,                     !- Wind Direction {deg}\n" \
        "      No,                      !- Rain Indicator\n" \
        "      No,                      !- Snow Indicator\n" \
        "      No,                      !- Daylight Saving Time Indicator\n" \
        "      ASHRAETau,               !- Solar Model Indicator\n" \
        "      ,                        !- Beam Solar Day Schedule Name\n" \
        "      ,                        !- Diffuse Solar Day Schedule Name\n" \
        "      0.588,                   !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}\n" \
        "      1.653;                   !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}\n" \
        "  \n" \
        "    SizingPeriod:DesignDay,\n" \
        "      Phoenix Sky Harbor Intl Ap Ann Htg 99.6% Condns DB,  !- Name\n" \
        "      12,                      !- Month\n" \
        "      21,                      !- Day of Month\n" \
        "      WinterDesignDay,         !- Day Type\n" \
        "      3.7,                     !- Maximum Dry-Bulb Temperature {C}\n" \
        "      0,                       !- Daily Dry-Bulb Temperature Range {deltaC}\n" \
        "      DefaultMultipliers,      !- Dry-Bulb Temperature Range Modifier Type\n" \
        "      ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name\n" \
        "      Wetbulb,                 !- Humidity Condition Type\n" \
        "      3.7,                     !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}\n" \
        "      ,                        !- Humidity Condition Day Schedule Name\n" \
        "      ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}\n" \
        "      ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}\n" \
        "      ,                        !- Daily Wet-Bulb Temperature Range {deltaC}\n" \
        "      97342,                   !- Barometric Pressure {Pa}\n" \
        "      1.7,                     !- Wind Speed {m/s}\n" \
        "      100,                     !- Wind Direction {deg}\n" \
        "      No,                      !- Rain Indicator\n" \
        "      No,                      !- Snow Indicator\n" \
        "      No,                      !- Daylight Saving Time Indicator\n" \
        "      ASHRAEClearSky,          !- Solar Model Indicator\n" \
        "      ,                        !- Beam Solar Day Schedule Name\n" \
        "      ,                        !- Diffuse Solar Day Schedule Name\n" \
        "      ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}\n" \
        "      ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}\n" \
        "      0;                       !- Sky Clearness\n" \
        "  Material:NoMass,\n" \
        "    R13LAYER,                !- Name\n" \
        "    Rough,                   !- Roughness\n" \
        "    2.290965,                !- Thermal Resistance {m2-K/W}\n" \
        "    0.9000000,               !- Thermal Absorptance\n" \
        "    0.7500000,               !- Solar Absorptance\n" \
        "    0.7500000;               !- Visible Absorptance\n" \
        "  Material:NoMass,\n" \
        "    R31LAYER,                !- Name\n" \
        "    Rough,                   !- Roughness\n" \
        "    5.456,                   !- Thermal Resistance {m2-K/W}\n" \
        "    0.9000000,               !- Thermal Absorptance\n" \
        "    0.7500000,               !- Solar Absorptance\n" \
        "    0.7500000;               !- Visible Absorptance\n" \
        "  Material,\n" \
        "    C5 - 4 IN HW CONCRETE,   !- Name\n" \
        "    MediumRough,             !- Roughness\n" \
        "    0.1014984,               !- Thickness {m}\n" \
        "    1.729577,                !- Conductivity {W/m-K}\n" \
        "    2242.585,                !- Density {kg/m3}\n" \
        "    836.8000,                !- Specific Heat {J/kg-K}\n" \
        "    0.9000000,               !- Thermal Absorptance\n" \
        "    0.6500000,               !- Solar Absorptance\n" \
        "    0.6500000;               !- Visible Absorptance\n" \
        "  Construction,\n" \
        "    R13WALL,                 !- Name\n" \
        "    R13LAYER;                !- Outside Layer\n" \
        "  Construction,\n" \
        "    FLOOR,                   !- Name\n" \
        "    C5 - 4 IN HW CONCRETE;   !- Outside Layer\n" \
        "  Construction,\n" \
        "    ROOF31,                  !- Name\n" \
        "    R31LAYER;                !- Outside Layer\n" \
        "  Zone,\n" \
        "    ZONE ONE,                !- Name\n" \
        "    0,                       !- Direction of Relative North {deg}\n" \
        "    0,                       !- X Origin {m}\n" \
        "    0,                       !- Y Origin {m}\n" \
        "    0,                       !- Z Origin {m}\n" \
        "    1,                       !- Type\n" \
        "    1,                       !- Multiplier\n" \
        "    autocalculate,           !- Ceiling Height {m}\n" \
        "    autocalculate;           !- Volume {m3}\n" \
        "  ScheduleTypeLimits,\n" \
        "    Fraction,                !- Name\n" \
        "    0.0,                     !- Lower Limit Value\n" \
        "    1.0,                     !- Upper Limit Value\n" \
        "    CONTINUOUS;              !- Numeric Type\n" \
        "  GlobalGeometryRules,\n" \
        "    UpperLeftCorner,         !- Starting Vertex Position\n" \
        "    CounterClockWise,        !- Vertex Entry Direction\n" \
        "    World;                   !- Coordinate System\n" \
        "  BuildingSurface:Detailed,\n" \
        "    Zn001:Wall001,           !- Name\n" \
        "    Wall,                    !- Surface Type\n" \
        "    R13WALL,                 !- Construction Name\n" \
        "    ZONE ONE,                !- Zone Name\n" \
        "    ,                        !- Space Name\n" \
        "    Outdoors,                !- Outside Boundary Condition\n" \
        "    ,                        !- Outside Boundary Condition Object\n" \
        "    SunExposed,              !- Sun Exposure\n" \
        "    WindExposed,             !- Wind Exposure\n" \
        "    0.5000000,               !- View Factor to Ground\n" \
        "    4,                       !- Number of Vertices\n" \
        "    0,0,4.572000,            !- X,Y,Z ==> Vertex 1 {m}\n" \
        "    0,0,0,                   !- X,Y,Z ==> Vertex 2 {m}\n" \
        "    15.24000,0,0,            !- X,Y,Z ==> Vertex 3 {m}\n" \
        "    15.24000,0,4.572000;     !- X,Y,Z ==> Vertex 4 {m}\n" \
        "  BuildingSurface:Detailed,\n" \
        "    Zn001:Wall002,           !- Name\n" \
        "    Wall,                    !- Surface Type\n" \
        "    R13WALL,                 !- Construction Name\n" \
        "    ZONE ONE,                !- Zone Name\n" \
        "    ,                        !- Space Name\n" \
        "    Outdoors,                !- Outside Boundary Condition\n" \
        "    ,                        !- Outside Boundary Condition Object\n" \
        "    SunExposed,              !- Sun Exposure\n" \
        "    WindExposed,             !- Wind Exposure\n" \
        "    0.5000000,               !- View Factor to Ground\n" \
        "    4,                       !- Number of Vertices\n" \
        "    15.24000,0,4.572000,     !- X,Y,Z ==> Vertex 1 {m}\n" \
        "    15.24000,0,0,            !- X,Y,Z ==> Vertex 2 {m}\n" \
        "    15.24000,15.24000,0,     !- X,Y,Z ==> Vertex 3 {m}\n" \
        "    15.24000,15.24000,4.572000;  !- X,Y,Z ==> Vertex 4 {m}\n" \
        "  BuildingSurface:Detailed,\n" \
        "    Zn001:Wall003,           !- Name\n" \
        "    Wall,                    !- Surface Type\n" \
        "    R13WALL,                 !- Construction Name\n" \
        "    ZONE ONE,                !- Zone Name\n" \
        "    ,                        !- Space Name\n" \
        "    Outdoors,                !- Outside Boundary Condition\n" \
        "    ,                        !- Outside Boundary Condition Object\n" \
        "    SunExposed,              !- Sun Exposure\n" \
        "    WindExposed,             !- Wind Exposure\n" \
        "    0.5000000,               !- View Factor to Ground\n" \
        "    4,                       !- Number of Vertices\n" \
        "    15.24000,15.24000,4.572000,  !- X,Y,Z ==> Vertex 1 {m}\n" \
        "    15.24000,15.24000,0,     !- X,Y,Z ==> Vertex 2 {m}\n" \
        "    0,15.24000,0,            !- X,Y,Z ==> Vertex 3 {m}\n" \
        "    0,15.24000,4.572000;     !- X,Y,Z ==> Vertex 4 {m}\n" \
        "  BuildingSurface:Detailed,\n" \
        "    Zn001:Wall004,           !- Name\n" \
        "    Wall,                    !- Surface Type\n" \
        "    R13WALL,                 !- Construction Name\n" \
        "    ZONE ONE,                !- Zone Name\n" \
        "    ,                        !- Space Name\n" \
        "    Outdoors,                !- Outside Boundary Condition\n" \
        "    ,                        !- Outside Boundary Condition Object\n" \
        "    SunExposed,              !- Sun Exposure\n" \
        "    WindExposed,             !- Wind Exposure\n" \
        "    0.5000000,               !- View Factor to Ground\n" \
        "    4,                       !- Number of Vertices\n" \
        "    0,15.24000,4.572000,     !- X,Y,Z ==> Vertex 1 {m}\n" \
        "    0,15.24000,0,            !- X,Y,Z ==> Vertex 2 {m}\n" \
        "    0,0,0,                   !- X,Y,Z ==> Vertex 3 {m}\n" \
        "    0,0,4.572000;            !- X,Y,Z ==> Vertex 4 {m}\n" \
        "  BuildingSurface:Detailed,\n" \
        "    Zn001:Flr001,            !- Name\n" \
        "    Floor,                   !- Surface Type\n" \
        "    FLOOR,                   !- Construction Name\n" \
        "    ZONE ONE,                !- Zone Name\n" \
        "    ,                        !- Space Name\n" \
        "    Surface,                 !- Outside Boundary Condition\n" \
        "    Zn001:Flr001,            !- Outside Boundary Condition Object\n" \
        "    NoSun,                   !- Sun Exposure\n" \
        "    NoWind,                  !- Wind Exposure\n" \
        "    1.000000,                !- View Factor to Ground\n" \
        "    4,                       !- Number of Vertices\n" \
        "    15.24000,0.000000,0.0,   !- X,Y,Z ==> Vertex 1 {m}\n" \
        "    0.000000,0.000000,0.0,   !- X,Y,Z ==> Vertex 2 {m}\n" \
        "    0.000000,15.24000,0.0,   !- X,Y,Z ==> Vertex 3 {m}\n" \
        "    15.24000,15.24000,0.0;   !- X,Y,Z ==> Vertex 4 {m}\n" \
        "  BuildingSurface:Detailed,\n" \
        "    Zn001:Roof001,           !- Name\n" \
        "    Roof,                    !- Surface Type\n" \
        "    ROOF31,                  !- Construction Name\n" \
        "    ZONE ONE,                !- Zone Name\n" \
        "    ,                        !- Space Name\n" \
        "    Outdoors,                !- Outside Boundary Condition\n" \
        "    ,                        !- Outside Boundary Condition Object\n" \
        "    SunExposed,              !- Sun Exposure\n" \
        "    WindExposed,             !- Wind Exposure\n" \
        "    0,                       !- View Factor to Ground\n" \
        "    4,                       !- Number of Vertices\n" \
        "    0.000000,15.24000,4.572, !- X,Y,Z ==> Vertex 1 {m}\n" \
        "    0.000000,0.000000,4.572, !- X,Y,Z ==> Vertex 2 {m}\n" \
        "    15.24000,0.000000,4.572, !- X,Y,Z ==> Vertex 3 {m}\n" \
        "    15.24000,15.24000,4.572; !- X,Y,Z ==> Vertex 4 {m}\n" \
        "  FenestrationSurface:Detailed,\n" \
        "    Zn001:Wall001:Win001,    !- Name\n" \
        "    Window,                  !- Surface Type\n" \
        "    SimpleWindowConstruct,   !- Construction Name\n" \
        "    Zn001:Wall001,           !- Building Surface Name\n" \
        "    ,                        !- Outside Boundary Condition Object\n" \
        "    0.5000000,               !- View Factor to Ground\n" \
        "    ,                        !- Frame and Divider Name\n" \
        "    1.0,                     !- Multiplier\n" \
        "    4,                       !- Number of Vertices\n" \
        "    0.548000,0,2.5000,       !- X,Y,Z ==> Vertex 1 {m}\n" \
        "    0.548000,0,0.5000,       !- X,Y,Z ==> Vertex 2 {m}\n" \
        "    5.548000,0,0.5000,       !- X,Y,Z ==> Vertex 3 {m}\n" \
        "    5.548000,0,2.5000;       !- X,Y,Z ==> Vertex 4 {m}\n" \
        "    Construction,\n" \
        "      SimpleWindowConstruct,   !- Name\n" \
        "      SimpleWindowTest;        !- Outside Layer\n" \
        "    WindowMaterial:SimpleGlazingSystem,\n" \
        "      SimpleWindowTest,        !- Name\n" \
        "      0.600,                   !- U-Factor {W/m2-K}\n" \
        "      0.700,                   !- Solar Heat Gain Coefficient\n" \
        "      0.700;                   !- Visible Transmittance\n" \
        "    Sizing:Zone,\n" \
        "      ZONE ONE,                !- Zone or ZoneList Name\n" \
        "      SupplyAirTemperature,    !- Zone Cooling Design Supply Air Temperature Input Method\n" \
        "      12.0,                    !- Zone Cooling Design Supply Air Temperature {C}\n" \
        "      ,                        !- Zone Cooling Design Supply Air Temperature Difference {deltaC}\n" \
        "      SupplyAirTemperature,    !- Zone Heating Design Supply Air Temperature Input Method\n" \
        "      12.0,                    !- Zone Heating Design Supply Air Temperature {C}\n" \
        "      ,                        !- Zone Heating Design Supply Air Temperature Difference {deltaC}\n" \
        "      0.0075,                  !- Zone Cooling Design Supply Air Humidity Ratio {kgWater/kgDryAir}\n" \
        "      0.004,                   !- Zone Heating Design Supply Air Humidity Ratio {kgWater/kgDryAir}\n" \
        "      SZ DSOA Zone One,        !- Design Specification Outdoor Air Object Name\n" \
        "      0.0,                     !- Zone Heating Sizing Factor\n" \
        "      0.0,                     !- Zone Cooling Sizing Factor\n" \
        "      DesignDay,               !- Cooling Design Air Flow Method\n" \
        "      0,                       !- Cooling Design Air Flow Rate {m3/s}\n" \
        "      ,                        !- Cooling Minimum Air Flow per Zone Floor Area {m3/s-m2}\n" \
        "      ,                        !- Cooling Minimum Air Flow {m3/s}\n" \
        "      ,                        !- Cooling Minimum Air Flow Fraction\n" \
        "      DesignDay,               !- Heating Design Air Flow Method\n" \
        "      0,                       !- Heating Design Air Flow Rate {m3/s}\n" \
        "      ,                        !- Heating Maximum Air Flow per Zone Floor Area {m3/s-m2}\n" \
        "      ,                        !- Heating Maximum Air Flow {m3/s}\n" \
        "      ;                        !- Heating Maximum Air Flow Fraction\n" \
        "    DesignSpecification:OutdoorAir,\n" \
        "      SZ DSOA Zone One,        !- Name\n" \
        "      Sum,                     !- Outdoor Air Method\n" \
        "      0.0,                     !- Outdoor Air Flow per Person {m3/s-person}\n" \
        "      0.0,                     !- Outdoor Air Flow per Zone Floor Area {m3/s-m2}\n" \
        "      0.0;                     !- Outdoor Air Flow per Zone {m3/s}\n" \
        "    ZoneControl:Thermostat,\n" \
        "      Zone Thermostat,         !- Name\n" \
        "      ZONE ONE,                !- Zone or ZoneList Name\n" \
        "      Zone Control Type Sched, !- Control Type Schedule Name\n" \
        "      ThermostatSetpoint:DualSetpoint,  !- Control 1 Object Type\n" \
        "      Temperature Setpoints;   !- Control 1 Name\n" \
        "    Schedule:Compact,\n" \
        "      Zone Control Type Sched, !- Name\n" \
        "      Control Type,            !- Schedule Type Limits Name\n" \
        "      Through: 12/31,          !- Field 1\n" \
        "      For: AllDays,            !- Field 2\n" \
        "      Until: 24:00,4;          !- Field 3\n" \
        "    ThermostatSetpoint:DualSetpoint,\n" \
        "      Temperature Setpoints,   !- Name\n" \
        "      Heating Setpoints,       !- Heating Setpoint Temperature Schedule Name\n" \
        "      Cooling Setpoints;       !- Cooling Setpoint Temperature Schedule Name\n" \
        "    Schedule:Compact,\n" \
        "      Heating Setpoints,       !- Name\n" \
        "      Temperature,             !- Schedule Type Limits Name\n" \
        "      Through: 12/31,          !- Field 1\n" \
        "      For: AllDays,            !- Field 2\n" \
        "      Until: 24:00,21.0;       !- Field 3\n" \
        "    Schedule:Compact,\n" \
        "      Cooling Setpoints,       !- Name\n" \
        "      Temperature,             !- Schedule Type Limits Name\n" \
        "      Through: 12/31,          !- Field 1\n" \
        "      For: AllDays,            !- Field 2\n" \
        "      Until: 24:00,24.0;       !- Field 3\n" \
        "    ScheduleTypeLimits,\n" \
        "      Control Type,            !- Name\n" \
        "      0,                       !- Lower Limit Value\n" \
        "      4,                       !- Upper Limit Value\n" \
        "      DISCRETE;                !- Numeric Type\n" \
        "    ScheduleTypeLimits,\n" \
        "      Temperature,             !- Name\n" \
        "      -60,                     !- Lower Limit Value\n" \
        "      200,                     !- Upper Limit Value\n" \
        "      CONTINUOUS,              !- Numeric Type\n" \
        "      Temperature;             !- Unit Type\n" \
        "    ZoneHVAC:EquipmentConnections,\n" \
        "      ZONE ONE,                  !- Zone Name\n" \
        "      ZONE 1 EQUIPMENT,        !- Zone Conditioning Equipment List Name\n" \
        "      ZONE 1 INLETS,           !- Zone Air Inlet Node or NodeList Name\n" \
        "      ,                        !- Zone Air Exhaust Node or NodeList Name\n" \
        "      ZONE 1 NODE,             !- Zone Air Node Name\n" \
        "      ZONE 1 OUTLET;           !- Zone Return Air Node or NodeList Name\n" \
        "    ZoneHVAC:EquipmentList,\n" \
        "      ZONE 1 EQUIPMENT,        !- Name\n" \
        "      SequentialLoad,          !- Load Distribution Scheme\n" \
        "      ZoneHVAC:IdealLoadsAirSystem,  !- Zone Equipment 1 Object Type\n" \
        "      ZONE 1 Ideal Loads,      !- Zone Equipment 1 Name\n" \
        "      1,                       !- Zone Equipment 1 Cooling Sequence\n" \
        "      1,                       !- Zone Equipment 1 Heating or No-Load Sequence\n" \
        "      ,                        !- Zone Equipment 1 Sequential Cooling Load Fraction\n" \
        "      ;                        !- Zone Equipment 1 Sequential Heating Load Fraction\n" \
        "    ZoneHVAC:IdealLoadsAirSystem,\n" \
        "      ZONE 1 Ideal Loads,      !- Name\n" \
        "      ,                        !- Availability Schedule Name\n" \
        "      ZONE 1 INLETS,           !- Zone Supply Air Node Name\n" \
        "      ,                        !- Zone Exhaust Air Node Name\n" \
        "      ,                        !- System Inlet Air Node Name\n" \
        "      50,                      !- Maximum Heating Supply Air Temperature {C}\n" \
        "      13,                      !- Minimum Cooling Supply Air Temperature {C}\n" \
        "      0.015,                   !- Maximum Heating Supply Air Humidity Ratio {kgWater/kgDryAir}\n" \
        "      0.009,                   !- Minimum Cooling Supply Air Humidity Ratio {kgWater/kgDryAir}\n" \
        "      NoLimit,                 !- Heating Limit\n" \
        "      autosize,                !- Maximum Heating Air Flow Rate {m3/s}\n" \
        "      ,                        !- Maximum Sensible Heating Capacity {W}\n" \
        "      NoLimit,                 !- Cooling Limit\n" \
        "      autosize,                !- Maximum Cooling Air Flow Rate {m3/s}\n" \
        "      ,                        !- Maximum Total Cooling Capacity {W}\n" \
        "      ,                        !- Heating Availability Schedule Name\n" \
        "      ,                        !- Cooling Availability Schedule Name\n" \
        "      ConstantSupplyHumidityRatio,  !- Dehumidification Control Type\n" \
        "      ,                        !- Cooling Sensible Heat Ratio {dimensionless}\n" \
        "      ConstantSupplyHumidityRatio,  !- Humidification Control Type\n" \
        "      ,                        !- Design Specification Outdoor Air Object Name\n" \
        "      ,                        !- Outdoor Air Inlet Node Name\n" \
        "      ,                        !- Demand Controlled Ventilation Type\n" \
        "      ,                        !- Outdoor Air Economizer Type\n" \
        "      ,                        !- Heat Recovery Type\n" \
        "      ,                        !- Sensible Heat Recovery Effectiveness {dimensionless}\n" \
        "      ;                        !- Latent Heat Recovery Effectiveness {dimensionless}\n" \
        "    NodeList,\n" \
        "      ZONE 1 INLETS,           !- Name\n" \
        "      ZONE 1 INLET;            !- Node 1 Name\n" \
        "  People,\n" \
        "      OpenOffice People,       !- Name\n" \
        "      ZONE ONE,                !- Zone or ZoneList Name\n" \
        "      BLDG_OCC_SCH,            !- Number of People Schedule Name\n" \
        "      People/Area,             !- Number of People Calculation Method\n" \
        "      ,                        !- Number of People\n" \
        "      0.010,                    !- People per Zone Floor Area {person/m2}\n" \
        "      ,                        !- Zone Floor Area per Person {m2/person}\n" \
        "      0.3,                     !- Fraction Radiant\n" \
        "      ,                        !- Sensible Heat Fraction\n" \
        "      ACTIVITY_SCH;            !- Activity Level Schedule Name\n" \
        "  Lights,\n" \
        "      OfficeLights,            !- Name\n" \
        "      ZONE ONE,                !- Zone or ZoneList Name\n" \
        "      BLDG_LIGHT_SCH,          !- Schedule Name\n" \
        "      Watts/Area,              !- Design Level Calculation Method\n" \
        "      ,                        !- Lighting Level {W}\n" \
        "      8.0,                    !- Watts per Zone Floor Area {W/m2}\n" \
        "      ,                        !- Watts per Person {W/person}\n" \
        "      ,                        !- Return Air Fraction\n" \
        "      ,                        !- Fraction Radiant\n" \
        "      ,                        !- Fraction Visible\n" \
        "      ;                        !- Fraction Replaceable\n" \
        "  ElectricEquipment,\n" \
        "      ElectricEquipment,       !- Name\n" \
        "      ZONE ONE,                !- Zone or ZoneList Name\n" \
        "      BLDG_EQUIP_SCH,          !- Schedule Name\n" \
        "      Watts/Area,              !- Design Level Calculation Method\n" \
        "      ,                        !- Design Level {W}\n" \
        "      8.0,                    !- Watts per Zone Floor Area {W/m2}\n" \
        "      ,                        !- Watts per Person {W/person}\n" \
        "      ,                        !- Fraction Latent\n" \
        "      ,                        !- Fraction Radiant\n" \
        "      ;                        !- Fraction Lost\n" \
        "  Schedule:Compact,\n" \
        "      BLDG_EQUIP_SCH,          !- Name\n" \
        "      Fraction,                !- Schedule Type Limits Name\n" \
        "      Through: 12/31,          !- Field 1\n" \
        "      For: AllDays,            !- Field 2\n" \
        "      Until: 24:00,            !- Field 3\n" \
        "      0.7;                     !- Field 4\n" \
        "  Schedule:Compact,\n" \
        "      BLDG_LIGHT_SCH,          !- Name\n" \
        "      Fraction,                !- Schedule Type Limits Name\n" \
        "      Through: 12/31,          !- Field 1\n" \
        "      For: AllDays,            !- Field 2\n" \
        "      Until: 24:00,            !- Field 3\n" \
        "      0.5;                     !- Field 4\n" \
        "  Schedule:Compact,\n" \
        "      BLDG_OCC_SCH,            !- Name\n" \
        "      Fraction,                !- Schedule Type Limits Name\n" \
        "      Through: 12/31,          !- Field 1\n" \
        "      For: AllDays,            !- Field 2\n" \
        "      Until: 24:00,            !- Field 3\n" \
        "      0.5;                     !- Field 4\n" \
        "  Schedule:Compact,\n" \
        "      ACTIVITY_SCH,            !- Name\n" \
        "      Any Number,              !- Schedule Type Limits Name\n" \
        "      Through: 12/31,          !- Field 1\n" \
        "      For: AllDays,            !- Field 2\n" \
        "      Until: 24:00,            !- Field 3\n" \
        "      120.;                    !- Field 4\n" \
        "    ScheduleTypeLimits,\n" \
        "      Any Number;              !- Name\n" \
        "  Output:Table:SummaryReports,\n" \
        "      AllSummary,                             !- Report Name 1\n" \
        "      AllSummaryAndSizingPeriod;              !- Report Name 2\n"
    assert_true(process_idf(idf_objects))
    self.state.init_state(self.state)
    SimulationManager.ManageSimulation(self.state)
    let CtrlZoneNum: Int = 1
    assert_equal(self.state.dataSize.CalcFinalZoneSizing[CtrlZoneNum - 1].HeatTstatTemp, 21.0) # expects specified value
    assert_equal(self.state.dataSize.CalcFinalZoneSizing[CtrlZoneNum - 1].HeatDesTemp, 12.0)   # less than zone air Temp
    assert_equal(self.state.dataSize.CalcFinalZoneSizing[CtrlZoneNum - 1].HeatDesDay, "PHOENIX SKY HARBOR INTL AP ANN HTG 99.6% CONDNS DB")
    assert_almost_equal(self.state.dataSize.CalcFinalZoneSizing[CtrlZoneNum - 1].ZoneTempAtHeatPeak, 17.08, 0.01)
    assert_almost_equal(self.state.dataSize.FinalZoneSizing[CtrlZoneNum - 1].ZoneTempAtHeatPeak, 17.08, 0.01)
    assert_equal(self.state.dataSize.CalcFinalZoneSizing[CtrlZoneNum - 1].DesHeatVolFlow, 0.0)  # expects zero
    assert_equal(self.state.dataSize.CalcFinalZoneSizing[CtrlZoneNum - 1].DesHeatMassFlow, 0.0) # expects zero
    assert_equal(self.state.dataSize.FinalZoneSizing[CtrlZoneNum - 1].DesHeatVolFlow, 0.0)      # expects zero
    assert_equal(self.state.dataSize.FinalZoneSizing[CtrlZoneNum - 1].DesHeatMassFlow, 0.0)     # expects zero
    assert_almost_equal(self.state.dataSize.CalcFinalZoneSizing[CtrlZoneNum - 1].DesHeatLoad, 6911.42, 0.5)
    assert_almost_equal(self.state.dataSize.FinalZoneSizing[CtrlZoneNum - 1].DesHeatLoad, 6911.42, 0.5)