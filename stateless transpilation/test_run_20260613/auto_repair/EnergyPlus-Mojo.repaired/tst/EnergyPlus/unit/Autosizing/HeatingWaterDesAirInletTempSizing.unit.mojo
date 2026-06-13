# Import testing helpers (simplified for translation)
from testing import expect_true, expect_false, expect_near, expect_eq

# Import EnergyPlus modules (assumed Mojo equivalents)
from ............EnergyPlus.Autosizing.HeatingWaterDesAirInletTempSizing import HeatingWaterDesAirInletTempSizer
from ............EnergyPlus.DataAirSystems import PrimaryAirSystemsData
from ............EnergyPlus.DataEnvironment import EnvrnData
from ............EnergyPlus.DataHVACGlobals import NumPrimaryAirSys
from ............EnergyPlus.DataSizing import (AutoSize, ZoneEqSizingData, TermUnitSizingData,
    FinalZoneSizingData, FinalSysSizingData, SysSizInputData, OASysEqSizingData)
from ............EnergyPlus.DataAirLoop import OutsideAirSysData, AirLoopData
from ............EnergyPlus.DataAirLoopHVACDOAS import AirloopDOASData

# Assume AutoSizingFixture is defined elsewhere; we define a minimal struct for translation
struct AutoSizingFixture:
    var state: GlobalState  # placeholder for the EnergyPlus state

    def __init__(inout self):
        self.state = GlobalState()

    def has_eio_output(inout self, value: Bool): pass  # stub

    def compare_eio_stream(inout self, expected: String, reset: Bool) -> Bool: return True

# Global state placeholder (should be imported from EnergyPlus)
struct GlobalState:
    var dataEnvrn: EnvrnData
    var dataSize: SizingData
    var dataHVACGlobal: HVACGlobalData
    var dataAirSystemsData: AirSystemsData
    var dataAirLoop: AirLoopData
    var dataAirLoopHVACDOAS: AirLoopHVACDOASData

# Additional helper structs (stubs)
struct SizingData:
    var ZoneEqSizing: List[ZoneEqSizingData]
    var CurZoneEqNum: Int = 0
    var CurTermUnitSizingNum: Int = 0
    var TermUnitSingDuct: Bool = False
    var TermUnitSizing: List[TermUnitSizingData]
    var TermUnitFinalZoneSizing: List[FinalZoneSizingData]
    var FinalZoneSizing: List[FinalZoneSizingData]
    var ZoneSizingRunDone: Bool = False
    var TermUnitPIU: Bool = False
    var TermUnitIU: Bool = False
    var ZoneEqFanCoil: Bool = False
    var NumZoneSizingInput: Int = 0
    var CurSysNum: Int = 0
    var NumSysSizInput: Int = 0
    var SysSizingRunDone: Bool = False
    var FinalSysSizing: List[FinalSysSizingData]
    var SysSizInput: List[SysSizInputData]
    var CurDuctType: Int = 0  # Use AirDuctType enum
    var OASysEqSizing: List[OASysEqSizingData]
    var CurOASysNum: Int = 0

struct HVACGlobalData:
    var NumPrimaryAirSys: Int = 0

struct AirSystemsData:
    var PrimaryAirSystems: List[PrimaryAirSystemsData]

struct AirLoopData:
    var OutsideAirSys: List[OutsideAirSysData]

struct AirLoopHVACDOASData:
    var airloopDOAS: List[AirloopDOASData]

# Enums (simplified)
struct AutoSizingResultType:
    var ErrorType2: Int = 2
    var NoError: Int = 0

struct HVAC:
    struct CoilType:
        var HeatingWater: Int = 0
    var coilTypeNames: List[String] = ["Coil:Heating:Water"]
    struct AirDuctType:
        var Main: Int = 0
        var Cooling: Int = 1
        var Heating: Int = 2

struct DataSizing:
    var AutoSize: Float64 = -1.0  # placeholder

# The test function (equivalent to TEST_F(AutoSizingFixture, HeatingWaterDesAirInletTempSizingGauntlet))
def HeatingWaterDesAirInletTempSizingGauntlet():
    var fixture = AutoSizingFixture()
    var state = fixture.state

    state.dataEnvrn.StdRhoAir = 1.2
    var routineName: StringLiteral = "HeatingWaterDesAirInletTempSizingGauntlet"
    state.dataSize.ZoneEqSizing = List[ZoneEqSizingData](1)  # allocate 1

    var sizer = HeatingWaterDesAirInletTempSizer()
    var inputValue: Float64 = 5.0
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue = sizer.size(fixture.state, inputValue, errorsFound)  # note: state passed by value? Mojo pass by ref? We'll use pointer-like.

    expect_true(errorsFound)
    expect_eq(AutoSizingResultType.ErrorType2, sizer.errorType)
    expect_near(0.0, sizedValue, 0.01)  # uninitialized sizing types always return 0

    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.CurTermUnitSizingNum = 1
    state.dataSize.TermUnitSingDuct = True
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value

    sizer.autoSizedValue = 0.0  # reset for next test
    fixture.has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value

    sizer.autoSizedValue = 0.0  # reset for next test
    var eiooutput: String = (
        "Component Sizing Information, Component Type, Component Name, Input Field Description, Value\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Rated Inlet Air Temperature [C], 5.00000\n"
    )
    expect_true(fixture.compare_eio_stream(eiooutput, True))

    state.dataSize.TermUnitSizing = List[TermUnitSizingData](1)
    state.dataSize.TermUnitFinalZoneSizing = List[FinalZoneSizingData](1)
    state.dataSize.TermUnitFinalZoneSizing[0].DesHeatCoilInTempTU = 15.0
    state.dataSize.TermUnitFinalZoneSizing[0].ZoneTempAtHeatPeak = 20.0
    state.dataSize.FinalZoneSizing = List[FinalZoneSizingData](1)
    state.dataSize.FinalZoneSizing[0].ZoneTempAtHeatPeak = 20.0
    state.dataSize.ZoneEqSizing = List[ZoneEqSizingData](1)
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.zoneSizingInput = List[ZoneSizingInputData](1)
    sizer.zoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    expect_near(1.2, state.dataEnvrn.StdRhoAir, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.TermUnitSingDuct = False
    state.dataSize.TermUnitPIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(20.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.TermUnitPIU = False
    state.dataSize.TermUnitIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(20.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.TermUnitIU = False
    state.dataSize.ZoneEqFanCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(20.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqFanCoil = False
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(20.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(20.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(20.0, sizedValue, 0.01)  # uses a mass flow rate for sizing

    sizer.autoSizedValue = 0.0  # reset for next test
    fixture.has_eio_output(True)
    eiooutput = ""
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.CurTermUnitSizingNum = 0
    state.dataSize.ZoneEqSizing = List[ZoneEqSizingData]()  # deallocate
    state.dataSize.FinalZoneSizing = List[FinalZoneSizingData]()
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 5.0
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value

    sizer.autoSizedValue = 0.0  # reset for next test
    expect_true(fixture.compare_eio_stream(eiooutput, True))

    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing = List[FinalSysSizingData](1)
    state.dataSize.FinalSysSizing[0].HeatOutTemp = 10.0
    state.dataSize.FinalSysSizing[0].HeatRetTemp = 12.0
    state.dataSize.SysSizInput = List[SysSizInputData](1)
    state.dataSize.SysSizInput[0].AirLoopNum = 1
    state.dataAirSystemsData.PrimaryAirSystems = List[PrimaryAirSystemsData](1)
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(10.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Inlet Air Temperature [C], 10.0000\n"
    expect_true(fixture.compare_eio_stream(eiooutput, True))

    state.dataSize.CurDuctType = HVAC.AirDuctType.Main
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(10.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(10.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(10.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(10.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.CurDuctType = HVAC.AirDuctType.Heating
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(10.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.OASysEqSizing = List[OASysEqSizingData](1)
    state.dataAirLoop.OutsideAirSys = List[OutsideAirSysData](1)
    state.dataSize.CurOASysNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(10.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataAirLoop.OutsideAirSys[state.dataSize.CurOASysNum - 1].AirLoopDOASNum = 0  # 1->0 shift
    state.dataAirLoopHVACDOAS.airloopDOAS.append(AirloopDOASData())
    state.dataAirLoopHVACDOAS.airloopDOAS[0].HeatOutTemp = 12.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(12.0, sizedValue, 0.01)  # uses a mass flow rate for sizing

    sizer.autoSizedValue = 0.0  # reset for next test
    fixture.has_eio_output(True)
    inputValue = 5.0
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(fixture.state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(fixture.state, inputValue, errorsFound)
    expect_eq(AutoSizingResultType.NoError, sizer.errorType)  # cumulative of previous calls
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value

    sizer.autoSizedValue = 0.0  # reset for next test
    expect_false(errorsFound)
    eiooutput = (
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Inlet Air Temperature [C], 12.0000\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Rated Inlet Air Temperature [C], 5.00000\n"
    )
    expect_true(fixture.compare_eio_stream(eiooutput, True))

# Main entry point for test (if run standalone)
def main():
    HeatingWaterDesAirInletTempSizingGauntlet()
<<<FILE>>>