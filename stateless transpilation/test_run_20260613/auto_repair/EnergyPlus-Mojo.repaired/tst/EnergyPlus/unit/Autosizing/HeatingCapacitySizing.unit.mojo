# AutosizingFixture is assumed to be in the same directory
from AutosizingFixture import AutoSizingFixture, delimited_string, has_eio_output, compare_eio_stream, process_idf
from gtest import Test # Not needed, we'll define custom functions
from EnergyPlus.Autosizing.HeatingCapacitySizing import HeatingCapacitySizer, AutoSizingResultType
from EnergyPlus.DataEnvironment import StdRhoAir  # Actually accessed via state
from EnergyPlus.DataSizing import DataSizing, AutoSize, OAControl, HeatingCapMethod
from EnergyPlus.Fans import GetFanInput
from EnergyPlus.SimAirServingZones import SimAirServingZones
from EnergyPlus.HVAC import HVAC

# Helper functions to mimic gtest macros
def EXPECT_TRUE(condition: Bool, msg: String = ""):
    if not condition:
        print("FAIL: EXPECT_TRUE failed: " + msg)
        assert condition

def EXPECT_FALSE(condition: Bool, msg: String = ""):
    if condition:
        print("FAIL: EXPECT_FALSE failed: " + msg)
        assert not condition

def EXPECT_ENUM_EQ[T: AnyType](expected: T, actual: T, msg: String = ""):
    if expected != actual:
        print("FAIL: EXPECT_ENUM_EQ failed: " + msg + " (expected: " + str(expected) + ", actual: " + str(actual) + ")")
        assert expected == actual

def EXPECT_NEAR(expected: Float64, actual: Float64, abs_error: Float64, msg: String = ""):
    var diff: Float64 = expected - actual
    if diff < 0.0:
        diff = -diff
    if diff > abs_error:
        print("FAIL: EXPECT_NEAR failed: " + msg + " (expected: " + str(expected) + ", actual: " + str(actual) + ", diff: " + str(diff) + ")")
        assert diff <= abs_error

# Define the test method as part of AutoSizingFixture (assumed struct from imported module)
def HeatingCapacitySizingGauntlet(self: AutoSizingFixture):
    var idf_objects: String = delimited_string([
        "  Fan:SystemModel,",
        "    MyFan,                       !- Name",
        "    ,                            !- Availability Schedule Name",
        "    TestFanAirInletNode,         !- Air Inlet Node Name",
        "    TestFanOutletNode,           !- Air Outlet Node Name",
        "    0.2,                         !- Design Maximum Air Flow Rate",
        "    Discrete ,                   !- Speed Control Method",
        "    0.0,                         !- Electric Power Minimum Flow Rate Fraction",
        "    100.0,                       !- Design Pressure Rise",
        "    0.9 ,                        !- Motor Efficiency",
        "    1.0 ,                        !- Motor In Air Stream Fraction",
        "    AUTOSIZE,                    !- Design Electric Power Consumption",
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method",
        "    ,                            !- Electric Power Per Unit Flow Rate",
        "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure",
        "    0.50;                        !- Fan Total Efficiency",
    ])
    EXPECT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    self.state.dataEnvrn.StdRhoAir = 1.2
    Fans.GetFanInput(self.state)
    self.state.dataLoopNodes.Node[0].Press = 101325.0  # 1-based to 0-based
    self.state.dataLoopNodes.Node[0].Temp = 24.0
    self.state.dataFans.fans[0].simulate(self.state, False)  # using default placeholders for _, _
    const routineName: StringLiteral = "HeatingCapacitySizingGauntlet"
    self.state.dataSize.ZoneEqSizing = List[...]()  # allocate one element
    self.state.dataSize.ZoneEqSizing.append(None)  # placeholder
    var sizer: HeatingCapacitySizer = HeatingCapacitySizer()
    var inputValue: Float64 = 5125.3
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.01)  # uninitialized sizing types always return 0
    errorsFound = False
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataSize.CurTermUnitSizingNum = 1
    self.state.dataSize.TermUnitSingDuct = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5125.3, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(True)
    printFlag = True
    self.state.dataSize.ZoneSizingRunDone = True
    self.state.dataSize.ZoneSizingInput = List[...]()
    self.state.dataSize.ZoneSizingInput.append(None)
    self.state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    self.state.dataSize.ZoneEqSizing[0].DesignSizeFromParent = True
    self.state.dataSize.ZoneEqSizing[0].DesHeatingLoad = sizedValue
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5125.3, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqSizing[0].DesignSizeFromParent = False
    var eiooutput: String = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Heating Capacity [W], 5125.30\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    self.state.dataSize.TermUnitFinalZoneSizing = List[...]()
    self.state.dataSize.TermUnitFinalZoneSizing.append(None)
    self.state.dataSize.TermUnitFinalZoneSizing[0].DesHeatCoilInTempTU = 15.0
    self.state.dataSize.TermUnitFinalZoneSizing[0].DesHeatCoilInHumRatTU = 0.007
    self.state.dataSize.TermUnitFinalZoneSizing[0].HeatDesTemp = 30.0
    self.state.dataSize.TermUnitFinalZoneSizing[0].HeatDesHumRat = 0.007
    self.state.dataSize.TermUnitFinalZoneSizing[0].ZoneTempAtHeatPeak = 20.0
    self.state.dataSize.TermUnitFinalZoneSizing[0].ZoneHumRatAtHeatPeak = 0.006
    self.state.dataSize.TermUnitSizing = List[...]()
    self.state.dataSize.TermUnitSizing.append(None)
    self.state.dataSize.TermUnitSizing[0].InducRat = 0.5
    self.state.dataSize.TermUnitSizing[0].AirVolFlow = 0.2
    self.state.dataSize.FinalZoneSizing = List[...]()
    self.state.dataSize.FinalZoneSizing.append(None)
    self.state.dataSize.FinalZoneSizing[0].ZoneTempAtHeatPeak = 20.0
    self.state.dataSize.FinalZoneSizing[0].ZoneRetTempAtHeatPeak = 24.0
    self.state.dataSize.FinalZoneSizing[0].ZoneHumRatAtHeatPeak = 0.006
    self.state.dataSize.FinalZoneSizing[0].DesHeatMassFlow = 0.2
    self.state.dataSize.FinalZoneSizing[0].HeatDesTemp = 30.0
    self.state.dataSize.FinalZoneSizing[0].HeatDesHumRat = 0.004
    self.state.dataSize.FinalZoneSizing[0].OutTempAtHeatPeak = 5.0
    self.state.dataSize.FinalZoneSizing[0].OutHumRatAtHeatPeak = 0.002
    self.state.dataSize.ZoneEqSizing[0].ATMixerHeatPriDryBulb = 20.0
    self.state.dataSize.ZoneEqSizing[0].ATMixerHeatPriHumRat = 0.007
    self.state.dataPlnt.PlantLoop = List[...]()
    self.state.dataPlnt.PlantLoop.append(None)
    self.state.dataSize.DataWaterLoopNum = 1
    self.state.dataSize.DataWaterCoilSizHeatDeltaT = 5.0
    self.state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.zoneSizingInput = List[...]()
    sizer.zoneSizingInput.append(None)
    sizer.zoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3664.27, sizedValue, 0.01)
    EXPECT_NEAR(1.2, self.state.dataEnvrn.StdRhoAir, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitSingDuct = False
    self.state.dataSize.ZoneEqFanCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2024.55, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqFanCoil = False
    self.state.dataSize.DataFlowUsedForSizing = self.state.dataSize.FinalZoneSizing[0].DesHeatMassFlow / self.state.dataEnvrn.StdRhoAir
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2024.55, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2442.84, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitIU = False
    self.state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.05
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2935.6, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.03
    self.state.dataSize.ZoneEqDXCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1360.5, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.0
    self.state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2935.6, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitPIU = True
    self.state.dataSize.TermUnitSizing[0].MinPriFlowFrac = 0.3
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2809.27, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitSizing[0].InducesPlenumAir = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6229.26, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.0
    self.state.dataSize.DataCoolCoilCap = 4250.0  # overrides capacity
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(4250.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.DataCoolCoilCap = 0.0  # reset for next test
    self.state.dataSize.ZoneEqSizing[0].HeatingCapacity = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5125.3, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqSizing[0].HeatingCapacity = False
    self.state.dataSize.DataConstantUsedForSizing = 2800.0
    self.state.dataSize.DataFractionUsedForSizing = 1.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2800.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.DataConstantUsedForSizing = 0.0
    self.state.dataSize.DataFractionUsedForSizing = 0.0
    self.state.dataSize.DataEMSOverrideON = True
    self.state.dataSize.DataEMSOverride = 1500.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1500.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.DataEMSOverrideON = False
    self.state.dataSize.DataEMSOverride = 0.0
    has_eio_output(True)
    inputValue = 5500.0
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5500.0, sizedValue, 0.01)  # hard size value
    sizer.autoSizedValue = 0.0  # reset for next test
    EXPECT_FALSE(errorsFound)
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Heating Capacity [W], 6229.26\n"
                       " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Heating Capacity [W], 5500.00\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    eiooutput = ""
    self.state.dataSize.CurZoneEqNum = 0
    self.state.dataSize.NumZoneSizingInput = 0
    self.state.dataSize.ZoneEqSizing = List[...]()
    self.state.dataSize.FinalZoneSizing = List[...]()
    self.state.dataSize.CurSysNum = 1
    self.state.dataHVACGlobal.NumPrimaryAirSys = 1
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizingRunDone = False
    inputValue = 2700.8
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(2700.8, sizedValue, 0.0001)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    self.state.dataSize.SysSizingRunDone = True
    self.state.dataAirSystemsData.PrimaryAirSystems = List[...]()
    self.state.dataAirSystemsData.PrimaryAirSystems.append(None)
    self.state.dataAirLoop.AirLoopControlInfo = List[...]()
    self.state.dataAirLoop.AirLoopControlInfo.append(None)
    self.state.dataSize.UnitarySysEqSizing = List[...]()
    self.state.dataSize.UnitarySysEqSizing.append(None)
    self.state.dataSize.SysSizInput = List[...]()
    self.state.dataSize.SysSizInput.append(None)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    self.state.dataSize.FinalSysSizing = List[...]()
    self.state.dataSize.FinalSysSizing.append(None)
    self.state.dataSize.FinalSysSizing[0].HeatRetTemp = 20.0
    self.state.dataSize.FinalSysSizing[0].HeatOutTemp = 5.0
    self.state.dataSize.FinalSysSizing[0].HeatSupTemp = 30.0
    self.state.dataSize.FinalSysSizing[0].HeatRetHumRat = 0.006
    self.state.dataSize.FinalSysSizing[0].HeatOutHumRat = 0.004
    self.state.dataSize.FinalSysSizing[0].PreheatTemp = 10.0
    self.state.dataSize.FinalSysSizing[0].PreheatHumRat = 0.005
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 0.3
    self.state.dataSize.FinalSysSizing[0].DesHeatVolFlow = 0.27
    self.state.dataSize.FinalSysSizing[0].DesCoolVolFlow = 0.24
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5024.3, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    var unAdjustedSize: Float64 = sizedValue
    self.state.dataSize.FinalSysSizing[0].HeatingCapMethod = DataSizing.FractionOfAutosizedHeatingCapacity
    self.state.dataSize.FinalSysSizing[0].FractionOfAutosizedHeatingCapacity = 0.5
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(unAdjustedSize * 0.5, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].HeatingCapMethod = DataSizing.None
    self.state.dataSize.FinalSysSizing[0].FractionOfAutosizedHeatingCapacity = 0.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.02
    self.state.dataSize.FinalSysSizing[0].HeatOAOption = DataSizing.OAControl.MinOA
    self.state.dataAirSystemsData.PrimaryAirSystems[0].NumOAHeatCoils = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2250.88, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.UnitarySysEqSizing[0].HeatingCapacity = True
    self.state.dataSize.UnitarySysEqSizing[0].DesHeatingLoad = 4500.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(4500.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.UnitarySysEqSizing[0].HeatingCapacity = False
    self.state.dataSize.DataDesicRegCoil = True
    self.state.dataSize.DataDesOutletAirTemp = 32.0
    self.state.dataSize.DataDesInletAirTemp = 5.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5426.24, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.DataDesicRegCoil = False
    self.state.dataSize.DataFlowUsedForSizing = 0.0
    self.state.dataSize.UnitarySysEqSizing[0].AirFlow = True
    self.state.dataSize.UnitarySysEqSizing[0].AirVolFlow = 0.15
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2049.91, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.UnitarySysEqSizing[0].AirFlow = False
    self.state.dataSize.UnitarySysEqSizing[0].HeatingAirFlow = True
    self.state.dataSize.UnitarySysEqSizing[0].HeatingAirVolFlow = 0.12
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1688.16, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.UnitarySysEqSizing[0].HeatingAirFlow = False
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Main
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3858.66, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.3
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1326.41, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3135.16, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.3
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1109.36, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Heating
    self.state.dataSize.FinalSysSizing[0].SysAirMinFlowRat = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3496.91, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Other
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3858.66, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.RAB
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3858.66, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataAirLoop.AirLoopControlInfo[0].UnitarySys = True
    self.state.dataSize.UnitaryHeatCap = 4790.0
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Main
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3858.66, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataAirLoop.AirLoopControlInfo[0].UnitarySysSimulating = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(4790.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.DataCoilIsSuppHeater = True
    self.state.dataSize.SuppHeatCap = 5325.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5325.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.DataCoilIsSuppHeater = False
    self.state.dataSize.SuppHeatCap = 0.0
    self.state.dataSize.DataCoolCoilCap = 4325.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(4325.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.DataCoolCoilCap = 0.0
    self.state.dataAirLoop.AirLoopControlInfo[0].UnitarySys = False
    self.state.dataSize.FinalSysSizing[0].HeatingCapMethod = DataSizing.CapacityPerFloorArea
    self.state.dataSize.FinalSysSizing[0].HeatingTotalCapacity = 3325.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3325.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].HeatingCapMethod = DataSizing.HeatingDesignCapacity
    self.state.dataSize.FinalSysSizing[0].HeatingTotalCapacity = 2325.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2325.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.FinalSysSizing[0].HeatingCapMethod = DataSizing.None
    self.state.dataSize.FinalSysSizing[0].HeatingTotalCapacity = 0.0
    self.state.dataSize.CurOASysNum = 1
    self.state.dataAirLoop.OutsideAirSys = List[...]()
    self.state.dataAirLoop.OutsideAirSys.append(None)
    self.state.dataSize.OASysEqSizing = List[...]()
    self.state.dataSize.OASysEqSizing.append(None)
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(120.58, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.OASysEqSizing[0].AirFlow = True
    self.state.dataSize.OASysEqSizing[0].AirVolFlow = 1.5
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(9043.73, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.OASysEqSizing[0].AirFlow = False
    self.state.dataSize.OASysEqSizing[0].HeatingAirFlow = True
    self.state.dataSize.OASysEqSizing[0].HeatingAirVolFlow = 1.2
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(7234.98, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.OASysEqSizing[0].HeatingAirFlow = False
    self.state.dataSize.OASysEqSizing[0].HeatingCapacity = True
    self.state.dataSize.OASysEqSizing[0].DesHeatingLoad = 4400.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(4400.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.OASysEqSizing[0].HeatingCapacity = False
    self.state.dataSize.OASysEqSizing[0].DesHeatingLoad = 0.0
    self.state.dataSize.DataDesicRegCoil = True
    self.state.dataSize.DataDesOutletAirTemp = 38.0
    self.state.dataSize.DataDesInletAirTemp = 5.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(795.85, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.DataDesicRegCoil = False
    self.state.dataSize.OASysEqSizing[0].HeatingAirFlow = False
    self.state.dataAirLoop.OutsideAirSys = List[...]()
    self.state.dataAirLoop.OutsideAirSys.append(None)
    self.state.dataAirLoop.OutsideAirSys[0].AirLoopDOASNum = 0
    self.state.dataAirLoopHVACDOAS.airloopDOAS = List[...]()
    self.state.dataAirLoopHVACDOAS.airloopDOAS.append(None)
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingMassFlow = 1.1
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].HeatOutTemp = 5.0
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].PreheatTemp = 11.0
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanIndex = 0
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].FanBeforeCoolingCoilFlag = True
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanTypeNum = SimAirServingZones.CompType.Fan_System_Object
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6632.0666, sizedValue, 0.01)  # capacity includes system fan heat
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(True)
    inputValue = 4200.0
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(4200.0, sizedValue, 0.01)  # hard sized capacity
    sizer.autoSizedValue = 0.0  # reset for next test
    EXPECT_FALSE(errorsFound)
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Heating Capacity [W], 6632.07\n"
                       " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Heating Capacity [W], 4200.00\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))