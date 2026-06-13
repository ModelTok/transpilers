from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream
from EnergyPlus.Autosizing.HeatingWaterflowSizing import HeatingWaterflowSizer
from EnergyPlus.DataEnvironment import EnvironmentData
from EnergyPlus.DataHVACGlobals import HVACGlobals
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.FluidProperties import FluidProperties
from gtest import Test, Assert  # Assuming a gtest module for Mojo, if not, we'll define # Inline definitions for EXPECT_* macros as Mojo functions to keep 1:1 translation
def EXPECT_TRUE(condition: Bool):
    assert condition, "EXPECT_TRUE failed"

def EXPECT_FALSE(condition: Bool):
    assert not condition, "EXPECT_FALSE failed"

def EXPECT_ENUM_EQ[A: Eqable](expected: A, actual: A):
    assert expected == actual, "EXPECT_ENUM_EQ failed"

def EXPECT_NEAR(expected: Float64, actual: Float64, tolerance: Float64):
    assert abs(expected - actual) <= tolerance, "EXPECT_NEAR failed: " + str(expected) + " vs " + str(actual)

# The test function
def HeatingWaterflowSizingGauntlet(using state: AutoSizingFixture):
    # state->dataFluid->init_state(*state)
    state.dataFluid.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.2
    state.dataSize.ZoneEqSizing.allocate(1)

    let routineName: String = "HeatingWaterflowSizingGauntlet"

    var sizer = HeatingWaterflowSizer()
    var inputValue: Float64 = 5.0
    var errorsFound: Bool = false
    var printFlag: Bool = false

    var sizedValue: Float64 = sizer.size(state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.01)

    errorsFound = false
    state.dataSize.DataFractionUsedForSizing = 0.0
    state.dataSize.DataConstantUsedForSizing = 1.0
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.01)
    EXPECT_NEAR(5.0, sizer.originalValue, 0.01)

    sizer.autoSizedValue = 0.0
    state.dataSize.DataFractionUsedForSizing = 1.0
    state.dataSize.DataConstantUsedForSizing = 0.0
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.01)
    EXPECT_NEAR(5.0, sizer.originalValue, 0.01)

    sizer.autoSizedValue = 0.0
    state.dataSize.DataFractionUsedForSizing = 1.0
    state.dataSize.DataConstantUsedForSizing = 1.0
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(1.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    inputValue = DataSizing.AutoSize
    state.dataSize.DataFractionUsedForSizing = 1.0
    state.dataSize.DataConstantUsedForSizing = 2.0
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    state.dataSize.DataFractionUsedForSizing = 0.0
    state.dataSize.DataConstantUsedForSizing = 0.0
    inputValue = 5.0
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.CurTermUnitSizingNum = 1
    state.dataSize.TermUnitSingDuct = true
    state.dataSize.TermUnitSizing.allocate(1)
    state.dataSize.TermUnitSizing[0].MaxHWVolFlow = 0.005  # 0-based index
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    has_eio_output(true)
    printFlag = true
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    var eiooutput: String = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
    eiooutput += " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Maximum Water Flow Rate [m3/s], 5.00000\n"
    EXPECT_TRUE(compare_eio_stream(eiooutput, true))

    has_eio_output(true)
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.FinalZoneSizing[0].DesHeatMassFlow = 0.3
    state.dataSize.FinalZoneSizing[0].HeatDesTemp = 30.0
    state.dataSize.FinalZoneSizing[0].HeatDesHumRat = 0.004
    state.dataSize.FinalZoneSizing[0].ZoneRetTempAtHeatPeak = 19.0
    state.dataSize.FinalZoneSizing[0].ZoneTempAtHeatPeak = 21.0
    state.dataSize.FinalZoneSizing[0].OutTempAtHeatPeak = 10.0
    state.dataSize.FinalZoneSizing[0].ZoneHumRatAtHeatPeak = 0.006
    state.dataSize.FinalZoneSizing[0].OutHumRatAtHeatPeak = 0.003
    state.dataSize.ZoneSizingRunDone = true
    state.dataSize.TermUnitSingDuct = true
    inputValue = DataSizing.AutoSize
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.005, sizedValue, 0.01)
    EXPECT_NEAR(0.005, state.dataSize.TermUnitSizing[0].MaxHWVolFlow, 0.0001)
    EXPECT_NEAR(1.2, state.dataEnvrn.StdRhoAir, 0.01)

    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Maximum Water Flow Rate [m3/s], 0.00500000\n"
    EXPECT_TRUE(compare_eio_stream(eiooutput, true))

    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.005, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    state.dataSize.TermUnitSingDuct = false
    state.dataSize.TermUnitPIU = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.005, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    state.dataSize.TermUnitPIU = false
    state.dataSize.TermUnitIU = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.005, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    state.dataSize.TermUnitIU = false
    state.dataSize.ZoneEqFanCoil = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.005, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqFanCoil = false
    state.dataSize.ZoneEqUnitHeater = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.005, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqUnitHeater = false
    state.dataSize.DataWaterLoopNum = 1
    state.dataSize.DataWaterCoilSizHeatDeltaT = 10.0
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataPlnt.PlantLoop[0].FluidName = "Water"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.000066, sizedValue, 0.000001)

    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[0].AirVolFlow = 0.5
    state.dataSize.ZoneEqSizing[0].SystemAirFlow = true
    state.dataSize.FinalZoneSizing[0].DesHeatMassFlow = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.000133, sizedValue, 0.000001)

    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[0].AirVolFlow = 0.0
    state.dataSize.ZoneEqSizing[0].SystemAirFlow = false
    state.dataSize.ZoneEqSizing[0].HeatingAirVolFlow = 0.25
    state.dataSize.ZoneEqSizing[0].HeatingAirFlow = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.000066, sizedValue, 0.000001)

    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[0].HeatingAirVolFlow = 0.0
    state.dataSize.ZoneEqSizing[0].HeatingAirFlow = false
    has_eio_output(true)
    eiooutput = ""
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.CurTermUnitSizingNum = 0
    state.dataSize.ZoneEqSizing.deallocate()
    state.dataSize.FinalZoneSizing.deallocate()
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = false
    inputValue = 5.0
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)

    sizer.autoSizedValue = 0.0
    EXPECT_TRUE(compare_eio_stream(eiooutput, true))

    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = true
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[0].AirLoopNum = 1
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 5.0
    inputValue = DataSizing.AutoSize
    state.dataSize.DataCapacityUsedForSizing = 5000.0
    sizer.wasAutoSized = false
    printFlag = true
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.000121, sizedValue, 0.000001)

    sizer.autoSizedValue = 0.0
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Maximum Water Flow Rate [m3/s], 0.000121516\n"
    EXPECT_TRUE(compare_eio_stream(eiooutput, true))

    has_eio_output(true)
    eiooutput = ""
    state.dataSize.CurOASysNum = 1
    state.dataSize.OASysEqSizing.allocate(1)
    inputValue = 0.0002
    printFlag = true
    errorsFound = false
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[HVAC.CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0002, sizedValue, 0.000001)

    sizer.autoSizedValue = 0.0
    EXPECT_FALSE(errorsFound)
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Maximum Water Flow Rate [m3/s], 0.000121516\n"
    eiooutput += " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Maximum Water Flow Rate [m3/s], 0.000200000\n"
    EXPECT_TRUE(compare_eio_stream(eiooutput, true))

# The test entry point (mimicking TEST_F)
def main() raises:
    var fixture = AutoSizingFixture()
    HeatingWaterflowSizingGauntlet(fixture)