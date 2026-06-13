from AutosizingFixture import AutoSizingFixture
from gtest import *
from EnergyPlus.Autosizing.CoolingWaterDesAirInletHumRatSizing import CoolingWaterDesAirInletHumRatSizer
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirLoopHVACDOAS import *
from EnergyPlus.HVAC import *

@fixture
class AutoSizingFixture:
    var state: State

def TestBody_AutoSizingFixture_CoolingWaterDesAirInletHumRatSizingGauntlet(reg: TestRegistry):
    var state = State()
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataEnvrn.StdRhoAir = 1.2
    var routineName: StringLiteral = "CoolingWaterDesAirInletHumRatSizingGauntlet"
    var sizer = CoolingWaterDesAirInletHumRatSizer()
    var inputValue: Float64 = 0.009
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.01)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    has_eio_output(True)
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.009, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = ""
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.009, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    eiooutput = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n" \
                " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Inlet Air Humidity Ratio " \
                "[kgWater/kgDryAir], 9.000E-03\n"
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    has_eio_output(True)
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtCoolPeak = 0.007
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInHumRat = 0.008
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMassFlow = 0.01
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].OutHumRatAtCoolPeak = 0.004
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.008, sizedValue, 0.0001)
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Inlet Air Humidity Ratio " \
                "[kgWater/kgDryAir], 8.000E-03\n"
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.TermUnitSingDuct = False
    state.dataSize.TermUnitPIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.008, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.TermUnitPIU = False
    state.dataSize.TermUnitIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.007, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.TermUnitIU = False
    state.dataSize.ZoneEqFanCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.007, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[1].OAVolFlow = \
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMassFlow / (10.0 * state.dataEnvrn.StdRhoAir)
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    var mixedHumRat: Float64 = 0.9 * 0.007 + 0.1 * 0.004
    EXPECT_NEAR(mixedHumRat, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[1].ATMixerCoolPriHumRat = 0.001
    state.dataSize.ZoneEqSizing[1].ATMixerVolFlow = 0.002 / state.dataEnvrn.StdRhoAir
    var mixedHumRat2: Float64 = 0.8 * 0.007 + 0.2 * 0.001
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(mixedHumRat2, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqFanCoil = False
    has_eio_output(True)
    eiooutput = ""
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.ZoneEqSizing.deallocate()
    state.dataSize.FinalZoneSizing.deallocate()
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 0.012
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.012, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    state.dataSize.FinalSysSizing[1].MixHumRatAtCoolPeak = 0.0105
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0105, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Inlet Air Humidity Ratio " \
                "[kgWater/kgDryAir], 1.050E-02\n"
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum].NumOACoolCoils = 1
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].RetHumRatAtCoolPeak = 0.015
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].PrecoolHumRat = 0.01
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.010, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].DesOutAirVolFlow = 0.01
    state.dataSize.DataFlowUsedForSizing = 0.1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0145, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0
    state.dataSize.OASysEqSizing.allocate(1)
    state.dataAirLoop.OutsideAirSys.allocate(1)
    state.dataSize.CurOASysNum = 1
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].OutHumRatAtCoolPeak = 0.003
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    var outAirHumRat: Float64 = state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].OutHumRatAtCoolPeak
    EXPECT_NEAR(outAirHumRat, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0
    state.dataSize.FinalSysSizing[1].DesOutAirVolFlow = 0.0
    state.dataAirLoop.OutsideAirSys[1].AirLoopDOASNum = 0
    state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
    state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingCoolOAHumRat = 0.0036
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0036, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    inputValue = 0.00665
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(inputValue, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0
    EXPECT_FALSE(errorsFound)
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Inlet Air Humidity Ratio " \
                "[kgWater/kgDryAir], 3.600E-03\n" \
                " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Inlet Air Humidity Ratio " \
                "[kgWater/kgDryAir], 6.650E-03\n"
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))