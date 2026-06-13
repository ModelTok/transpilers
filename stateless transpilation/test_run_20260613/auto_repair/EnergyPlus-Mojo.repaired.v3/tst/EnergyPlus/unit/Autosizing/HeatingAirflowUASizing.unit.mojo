from AutosizingFixture import AutosizingFixture
from gtest import EXPECT_TRUE, EXPECT_EQ, EXPECT_NEAR, EXPECT_ENUM_EQ, EXPECT_FALSE  # assume these exist

# Use module-level imports for EnergyPlus modules
from EnergyPlus.Autosizing.HeatingAirflowUASizing import HeatingAirflowUASizer
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataSizing import *
from EnergyPlus.HVAC import HVAC

# The following is a placeholder for the AutoSizingFixture struct.
# It should be defined in AutosizingFixture.hh imported above.
struct AutoSizingFixture:
    var state: ... # Placeholder: actual state structure from EnergyPlus
    # Methods from AutosizingFixture (assumed imported)
    def has_eio_output(self, flag: Bool): ...
    def compare_eio_stream(self, output: String, exact: Bool) -> Bool: ...

# Test functions as methods of AutoSizingFixture to preserve TEST_F structure
@test
def HeatingAirflowUA_APIExampleUnitTest(self: AutoSizingFixture):
    var errorsFound = false
    var sizer = HeatingAirflowUASizer()
    sizer.initializeForSingleDuctZoneTerminal(*self.state, 1650.0, 0.3)  # Denver
    EXPECT_TRUE(sizer.zoneSizingRunDone)
    EXPECT_EQ(sizer.curZoneEqNum, 1)
    EXPECT_TRUE(sizer.termUnitSingDuct)
    EXPECT_EQ(sizer.curTermUnitSizingNum, 1)
    EXPECT_GT(int(sizer.termUnitSizing.size()), 0)
    EXPECT_EQ(sizer.termUnitSizing[0].AirVolFlow, 0.3)  # 0-based index
    var sizedValue = sizer.size(*self.state, DataSizing.AutoSize, errorsFound)
    EXPECT_NEAR(sizedValue, 0.29599, 0.00001)  # converts volume input to mass flow rate at elevation
    EXPECT_FALSE(errorsFound)
    sizer.initializeForSingleDuctZoneTerminal(*self.state, 0.0, 0.3)
    sizedValue = sizer.size(*self.state, DataSizing.AutoSize, errorsFound)
    EXPECT_NEAR(sizedValue, 0.36129, 0.00001)  # converts volume input to mass flow rate at elevation

@test
def HeatingAirflowUASizingGauntlet(self: AutoSizingFixture):
    self.state.dataEnvrn.StdRhoAir = 1.2
    self.state.dataSize.ZoneEqSizing.allocate(1)
    const routineName = String("HeatingAirflowUASizingGauntlet")
    var sizer = HeatingAirflowUASizer()
    var inputValue = 5.0
    var errorsFound = false
    var printFlag = false
    var sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.01)  # uninitialized sizing types always return 0
    errorsFound = false
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataSize.CurTermUnitSizingNum = 1
    self.state.dataSize.TermUnitSingDuct = true
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    self.has_eio_output(true)
    printFlag = true
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    var eiooutput = String(
        "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Heating Coil Airflow for UA [m3/s], 5.00000\n"
    )
    EXPECT_TRUE(self.compare_eio_stream(eiooutput, true))
    self.has_eio_output(true)
    self.state.dataSize.TermUnitSizing.allocate(1)
    self.state.dataSize.TermUnitSizing[0].AirVolFlow = 0.0008
    self.state.dataSize.FinalZoneSizing.allocate(1)
    self.state.dataSize.ZoneEqSizing.allocate(1)
    self.state.dataSize.ZoneSizingRunDone = true
    self.state.dataSize.TermUnitSingDuct = true
    inputValue = DataSizing.AutoSize
    self.state.dataSize.ZoneSizingInput.allocate(1)
    self.state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.01)
    EXPECT_NEAR(0.0008, self.state.dataSize.TermUnitSizing[0].AirVolFlow, 0.0001)
    EXPECT_NEAR(1.2, self.state.dataEnvrn.StdRhoAir, 0.01)
    eiooutput = String(
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Heating Coil Airflow for UA [m3/s], 0.00000\n"
    )
    EXPECT_TRUE(self.compare_eio_stream(eiooutput, true))
    self.state.dataSize.TermUnitSizing[0].AirVolFlow = 5
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    EXPECT_NEAR(5.0, self.state.dataSize.TermUnitSizing[0].AirVolFlow, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitSingDuct = false
    self.state.dataSize.TermUnitPIU = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitPIU = false
    self.state.dataSize.TermUnitIU = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitIU = false
    self.state.dataSize.ZoneEqFanCoil = true
    self.state.dataSize.TermUnitSizing[0].AirVolFlow = 0.0
    self.state.dataSize.FinalZoneSizing[0].DesHeatVolFlow = 5.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqFanCoil = false
    self.state.dataSize.FinalZoneSizing[0].DesHeatVolFlow = 0.0
    self.state.dataSize.ZoneEqSizing[0].AirVolFlow = 5.0
    self.state.dataSize.ZoneEqSizing[0].SystemAirFlow = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqSizing[0].AirVolFlow = 0.0
    self.state.dataSize.ZoneEqSizing[0].HeatingAirVolFlow = 5.0
    self.state.dataSize.ZoneEqSizing[0].SystemAirFlow = false
    self.state.dataSize.ZoneEqSizing[0].HeatingAirFlow = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqSizing[0].HeatingAirVolFlow = 0.0
    self.state.dataSize.ZoneEqSizing[0].HeatingAirFlow = false
    self.state.dataSize.FinalZoneSizing[0].DesHeatMassFlow = 5.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)  # uses a mass flow rate for sizing
    sizer.autoSizedValue = 0.0  # reset for next test
    self.has_eio_output(true)
    eiooutput = ""
    self.state.dataSize.CurZoneEqNum = 0
    self.state.dataSize.NumZoneSizingInput = 0
    self.state.dataSize.CurTermUnitSizingNum = 0
    self.state.dataSize.ZoneEqSizing.deallocate()
    self.state.dataSize.FinalZoneSizing.deallocate()
    self.state.dataSize.CurSysNum = 1
    self.state.dataHVACGlobal.NumPrimaryAirSys = 1
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizingRunDone = false
    inputValue = 5.0
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    EXPECT_TRUE(self.compare_eio_stream(eiooutput, true))
    self.state.dataSize.CurSysNum = 1
    self.state.dataHVACGlobal.NumPrimaryAirSys = 1
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizingRunDone = true
    self.state.dataSize.FinalSysSizing.allocate(1)
    self.state.dataSize.SysSizInput.allocate(1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 5.0  # CurDuctType not set
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = true
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    eiooutput = String(
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Heating Coil Airflow for UA [m3/s], 6.00000\n"
    )
    EXPECT_TRUE(self.compare_eio_stream(eiooutput, true))
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Main
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 5.0
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.5
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 0.0
    self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow = 5.0
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.5
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Heating
    self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow = 0.0
    self.state.dataSize.FinalSysSizing[0].DesHeatVolFlow = 5.0
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.5
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].DesHeatVolFlow = 0.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 5.0
    self.state.dataSize.OASysEqSizing.allocate(1)
    self.state.dataAirLoop.OutsideAirSys.allocate(1)
    self.state.dataSize.CurOASysNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.0
    self.state.dataAirLoop.OutsideAirSys[0].AirLoopDOASNum = 0
    self.state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingMassFlow = 5.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)  # uses a mass flow rate for sizing
    sizer.autoSizedValue = 0.0  # reset for next test
    self.has_eio_output(true)
    inputValue = 5.0
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingMassFlow = 3.0
    sizer.wasAutoSized = false
    printFlag = true
    sizer.initializeWithinEP(*self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(*self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)  # cumulative of previous calls
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    EXPECT_FALSE(errorsFound)
    eiooutput = String(
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Heating Coil Airflow for UA [m3/s], 3.00000\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Heating Coil Airflow for UA [m3/s], 5.00000\n"
    )
    EXPECT_TRUE(self.compare_eio_stream(eiooutput, true))