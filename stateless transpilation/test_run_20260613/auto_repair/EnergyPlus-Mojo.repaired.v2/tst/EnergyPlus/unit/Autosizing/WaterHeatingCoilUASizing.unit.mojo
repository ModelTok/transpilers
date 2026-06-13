from AutosizingFixture import AutoSizingFixture
from .........src.EnergyPlus.Autosizing.WaterHeatingCoilUASizing import WaterHeatingCoilUASizer
from .........src.EnergyPlus.DataEnvironment import DataEnvironment
from .........src.EnergyPlus.DataHVACGlobals import DataHVACGlobals
from .........src.EnergyPlus.DataSizing import DataSizing, AutoSizingResultType
from .........src.EnergyPlus.FluidProperties import Fluid
from .........src.EnergyPlus.ScheduleManager import Sched
from .........src.EnergyPlus.WaterCoils import WaterCoils
from .........src.EnergyPlus.HVAC import HVAC

# Helper macros (expansions for EXPECT_*)
def expect_true(cond: Bool, msg: String = "") raises:
    if not cond:
        raise Error(msg if msg else "Expected true")

def expect_false(cond: Bool, msg: String = "") raises:
    if cond:
        raise Error(msg if msg else "Expected false")

def expect_near(actual: Float64, expected: Float64, tol: Float64) raises:
    if abs(actual - expected) > tol:
        raise Error("Expected " + String(expected) + " ± " + String(tol) + ", got " + String(actual))

def expect_enum_eq[T: EqualityComparable](expected: T, actual: T) raises:
    if actual != expected:
        raise Error("Enum mismatch: expected " + String(expected) + ", got " + String(actual))

def test_WaterHeatingCoilUASizingGauntlet(ctx: AutoSizingFixture) raises:
    ctx.state.dataFluid.init_state(ctx.state)
    ctx.state.dataEnvrn.StdRhoAir = 1.2
    ctx.state.dataSize.ZoneEqSizing = [DataSizing.ZoneEqSizing()]  # allocate(1) -> 0-based list with 1 element
    var routineName: StringLiteral = "WaterHeatingCoilUASizingGauntlet"
    var sizer: WaterHeatingCoilUASizer
    var inputValue: Float64 = 35.0
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(ctx.state, inputValue, errorsFound)
    expect_true(errorsFound)
    expect_enum_eq(AutoSizingResultType.ErrorType2, sizer.errorType)
    expect_near(0.0, sizedValue, 0.01)  # uninitialized sizing types always return 0
    errorsFound = False
    ctx.state.dataSize.CurZoneEqNum = 1
    ctx.state.dataSize.CurTermUnitSizingNum = 1
    ctx.state.dataSize.TermUnitSingDuct = True
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(35.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    ctx.has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(35.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    var eiooutput: String = \
        "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n" \
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified U-Factor Times Area Value [W/K], 35.0000\n"
    expect_true(ctx.compare_eio_stream(eiooutput, True))
    ctx.has_eio_output(True)
    ctx.state.dataPlnt.PlantLoop = [DataPlnt.PlantLoopStruct()]  # allocate(1)
    ctx.state.dataPlnt.PlantLoop[0].FluidIndex = 1
    ctx.state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(ctx.state)
    ctx.state.dataWaterCoils.WaterCoil = [WaterCoils.WaterCoilStruct()]  # allocate(1)
    ctx.state.dataWaterCoils.WaterCoil[0].InletAirTemp = 21.0
    ctx.state.dataWaterCoils.WaterCoil[0].InletAirHumRat = 0.006
    ctx.state.dataWaterCoils.WaterCoil[0].Control = ctx.state.dataWaterCoils.DesignCalc
    ctx.state.dataWaterCoils.WaterCoil[0].InletWaterTemp = 60.0
    ctx.state.dataWaterCoils.WaterCoil[0].InletAirMassFlowRate = 0.2
    ctx.state.dataWaterCoils.WaterCoil[0].InletWaterMassFlowRate = 0.8
    ctx.state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.loopNum = 1
    ctx.state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.loop = &ctx.state.dataPlnt.PlantLoop[0]  # pointer assignment
    ctx.state.dataWaterCoils.MyUAAndFlowCalcFlag = [Bool]()  # allocate(1) – assume list of bool
    ctx.state.dataWaterCoils.MyUAAndFlowCalcFlag.append(False)
    ctx.state.dataWaterCoils.MySizeFlag = [Bool]()
    ctx.state.dataWaterCoils.MySizeFlag.append(False)
    ctx.state.dataWaterCoils.WaterCoil[0].availSched = Sched.GetScheduleAlwaysOn(ctx.state)
    ctx.state.dataSize.TermUnitSizing = [DataSizing.TermUnitSizingStruct()]  # allocate(1)
    ctx.state.dataSize.TermUnitSizing[0].AirVolFlow = 0.0008
    ctx.state.dataSize.FinalZoneSizing = [DataSizing.FinalZoneSizingStruct()]  # allocate(1)
    ctx.state.dataSize.FinalZoneSizing[0].HeatDesTemp = 30.0
    ctx.state.dataSize.FinalZoneSizing[0].HeatDesHumRat = 0.007
    ctx.state.dataSize.FinalZoneSizing[0].ZoneName = "MyZone"
    ctx.state.dataSize.ZoneEqSizing = [DataSizing.ZoneEqSizing()]  # allocate(1) (re‑allocate)
    ctx.state.dataSize.PlantSizData = [DataSizing.PlantSizDataStruct()]  # allocate(1)
    ctx.state.dataSize.PlantSizData[0].ExitTemp = 60.0
    ctx.state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.loopNum = 1
    ctx.state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.loop = &ctx.state.dataPlnt.PlantLoop[0]  # pointer assignment
    ctx.state.dataSize.ZoneSizingRunDone = True
    ctx.state.dataSize.DataCapacityUsedForSizing = 3000.0
    ctx.state.dataSize.DataWaterFlowUsedForSizing = 0.0002
    ctx.state.dataSize.DataFlowUsedForSizing = 0.2
    ctx.state.dataSize.DataCoilNum = 1
    ctx.state.dataSize.DataFanOp = HVAC.FanOp.Continuous
    ctx.state.dataSize.DataPltSizHeatNum = 1
    ctx.state.dataSize.DataWaterCoilSizHeatDeltaT = 5.0
    ctx.state.dataSize.DataDesInletAirTemp = 21.0
    ctx.state.dataSize.DataDesInletAirHumRat = 0.009
    inputValue = DataSizing.AutoSize
    ctx.state.dataSize.ZoneSizingInput = [DataSizing.ZoneSizingInputStruct()]  # allocate(1)
    ctx.state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(98.35, sizedValue, 0.01)
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size U-Factor Times Area Value [W/K], 98.3510\n"
    expect_true(ctx.compare_eio_stream(eiooutput, True))
    ctx.state.dataWaterCoils.WaterCoil[0].InletAirTemp = 61.0
    inputValue = DataSizing.AutoSize
    ctx.state.dataSize.ZoneSizingInput = [DataSizing.ZoneSizingInputStruct()]  # allocate(1) (re‑allocate)
    ctx.state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_true(errorsFound)
    expect_true(ctx.state.dataSize.DataErrorsFound)
    expect_true(sizer.dataErrorsFound)
    expect_enum_eq(AutoSizingResultType.ErrorType1, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(3.0, sizedValue, 0.01)  # 0.1% of 3000 W capacity
    ctx.state.dataWaterCoils.WaterCoil[0].InletAirTemp = 21.0
    ctx.state.dataSize.DataErrorsFound = False
    sizer.dataErrorsFound = False
    errorsFound = False
    ctx.has_eio_output(True)
    eiooutput = ""
    ctx.state.dataSize.CurZoneEqNum = 0
    ctx.state.dataSize.NumZoneSizingInput = 0
    ctx.state.dataSize.CurTermUnitSizingNum = 0
    ctx.state.dataSize.ZoneEqSizing = []  # deallocate
    ctx.state.dataSize.FinalZoneSizing = []  # deallocate
    ctx.state.dataSize.CurSysNum = 1
    ctx.state.dataHVACGlobal.NumPrimaryAirSys = 1
    ctx.state.dataSize.NumSysSizInput = 1
    ctx.state.dataSize.SysSizingRunDone = False
    inputValue = 5.0
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    expect_true(ctx.compare_eio_stream(eiooutput, True))
    ctx.state.dataSize.CurSysNum = 1
    ctx.state.dataHVACGlobal.NumPrimaryAirSys = 1
    ctx.state.dataSize.NumSysSizInput = 1
    ctx.state.dataSize.SysSizingRunDone = True
    ctx.state.dataSize.FinalSysSizing = [DataSizing.FinalSysSizingStruct()]  # allocate(1)
    ctx.state.dataSize.SysSizInput = [DataSizing.SysSizInputStruct()]  # allocate(1)
    ctx.state.dataSize.SysSizInput[0].AirLoopNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(98.35, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size U-Factor Times Area Value [W/K], 98.3510\n"
    expect_true(ctx.compare_eio_stream(eiooutput, True))
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(98.35, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    ctx.state.dataWaterCoils.WaterCoil[0].InletAirTemp = 61.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.ErrorType1, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_true(errorsFound)
    expect_true(ctx.state.dataSize.DataErrorsFound)
    expect_true(sizer.dataErrorsFound)
    expect_near(3.0, sizedValue, 0.01)  # 0.1% of 3000 W capacity
    ctx.state.dataWaterCoils.WaterCoil[0].InletAirTemp = 21.0
    ctx.state.dataSize.DataErrorsFound = False
    sizer.dataErrorsFound = False
    errorsFound = False
    sizer.autoSizedValue = 0.0  # reset for next test
    ctx.state.dataSize.CurOASysNum = 1
    ctx.state.dataSize.OASysEqSizing = [DataSizing.OASysEqSizingStruct()]  # allocate(1)
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(98.35, sizedValue, 0.03)
    sizer.autoSizedValue = 0.0  # reset for next test
    ctx.has_eio_output(True)
    inputValue = 5.0
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(ctx.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(ctx.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)  # cumulative of previous calls
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    expect_false(errorsFound)
    # #ifdef GET_OUT block (translated as dead code)
    if False:
        eiooutput = \
            " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size U-Factor Times Area Value [W/K], 98.3510\n" \
            " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified U-Factor Times Area Value [W/K], 5.00000\n"
        expect_true(ctx.compare_eio_stream(eiooutput, True))
    # #endif // GET_OUT

# Entry point for test runner (optional)
def main() raises:
    var fixture = AutoSizingFixture()
    fixture.SetUp()
    test_WaterHeatingCoilUASizingGauntlet(fixture)
    fixture.TearDown()