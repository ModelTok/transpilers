from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream
from EnergyPlus.Autosizing.All_Simple_Sizing import (
    AutoCalculateSizer,
    MaxHeaterOutletTempSizer,
    ZoneCoolingLoadSizer,
    ZoneHeatingLoadSizer,
    ASHRAEMinSATCoolingSizer,
    ASHRAEMaxSATHeatingSizer,
    DesiccantDehumidifierBFPerfDataFaceVelocitySizer,
    HeatingCoilDesAirInletTempSizer,
    HeatingCoilDesAirOutletTempSizer,
    HeatingCoilDesAirInletHumRatSizer,
)
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataSizing import DataSizing, AutoSize
from EnergyPlus.DesiccantDehumidifiers import *
from EnergyPlus import HVAC

def test_AutoCalculateSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "AutoCalculateSizingGauntlet"
    var sizer = AutoCalculateSizer()
    var inputValue: Float64 = 37.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    state.dataSize.DataFractionUsedForSizing = 1.0
    state.dataSize.DataConstantUsedForSizing = 30.0
    var sizingString: String = "Any sizing that requires AutoCalculate []"
    sizer.overrideSizingString(sizingString)
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(37.5, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String(
        "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Any sizing that requires AutoCalculate [], 30.0000\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Any sizing that requires AutoCalculate [], 37.5000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.DataFractionUsedForSizing = 1.0
    state.dataSize.DataConstantUsedForSizing = 30.0
    sizer.wasAutoSized = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(30.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    sizer.wasAutoSized = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    state.dataSize.DataEMSOverrideON = True
    state.dataSize.DataEMSOverride = 33.4
    sizer.wasAutoSized = False
    inputValue = 28.8
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(33.4, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Any sizing that requires AutoCalculate [], 33.4000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    has_eio_output(True)
    sizer.wasAutoSized = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(33.4, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Any sizing that requires AutoCalculate [], 33.4000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))

def test_MaxHeaterOutletTempSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "MaxHeaterOutletTempSizingGauntlet"
    var sizer = MaxHeaterOutletTempSizer()
    var inputValue: Float64 = 37.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(37.5, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(37.5, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
                    " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Maximum Supply Air Temperature [C], 37.5000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatDesTemp = 32.6
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(32.6, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
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
    inputValue = 27.8
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(27.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatSupTemp = 25.8
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(25.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Maximum Supply Air Temperature [C], 25.8000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    sizer.wasAutoSized = False
    inputValue = 28.8
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(28.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Maximum Supply Air Temperature [C], 25.8000\n"
                    " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Maximum Supply Air Temperature [C], 28.8000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))

def test_ZoneCoolingLoadSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "ZoneCoolingLoadSizingGauntlet"
    var sizer = ZoneCoolingLoadSizer()
    var inputValue: Float64 = 3007.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(3007.5, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(3007.5, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
                    " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Zone Cooling Sensible Load [W], 3007.50\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolLoad = 2500.0
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2500.0, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
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
    inputValue = 2007.8
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(2007.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatSupTemp = 25.8
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Zone Cooling Sensible Load [W], 0.00000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    sizer.wasAutoSized = False
    inputValue = 2880.0
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(2880.0, sizedValue, 0.0001)
    EXPECT_EQ(sizer.autoSizedValue, 2880.0)
    EXPECT_EQ(sizer.originalValue, 2880.0)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Zone Cooling Sensible Load [W], 2880.00\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))

def test_ZoneHeatingLoadSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "ZoneHeatingLoadSizingGauntlet"
    var sizer = ZoneHeatingLoadSizer()
    var inputValue: Float64 = 3007.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(3007.5, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(3007.5, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
                    " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Zone Heating Sensible Load [W], 3007.50\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatLoad = 2500.0
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2500.0, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
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
    inputValue = 2007.8
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(2007.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Zone Heating Sensible Load [W], 0.00000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    sizer.wasAutoSized = False
    inputValue = 2880.0
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(2880.0, sizedValue, 0.0001)
    EXPECT_EQ(sizer.autoSizedValue, 2880.0)
    EXPECT_EQ(sizer.originalValue, 2880.0)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Zone Heating Sensible Load [W], 2880.00\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))

def test_ASHRAEMinSATCoolingSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "ASHRAEMinSATCoolingSizingGauntlet"
    var sizer = ASHRAEMinSATCoolingSizer()
    var inputValue: Float64 = 16.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(16.5, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(16.5, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
                                        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Minimum Supply Air "
                                        "Temperature in Cooling Mode [C], 16.5000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[1].ZoneTempAtCoolPeak = 23.9
    state.dataSize.FinalZoneSizing[1].ZoneHumRatAtCoolPeak = 0.009
    state.dataSize.DataCapacityUsedForSizing = 2500.0
    state.dataSize.DataFlowUsedForSizing = 0.125
    state.dataSize.ZoneSizingRunDone = True
    state.dataEnvrn.StdRhoAir = 1.2
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(7.585, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataFlowUsedForSizing = 0.0
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    eiooutput = ""
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 14.8
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(14.8, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    inputValue = DataSizing.AutoSize
    state.dataSize.DataZoneUsedForSizing = 1
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_TRUE(errorsFound)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    errorsFound = False
    has_eio_output(True)
    state.dataSize.DataFlowUsedForSizing = 0.125
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(7.585, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Minimum Supply Air Temperature in Cooling Mode [C], 7.58525\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    sizer.wasAutoSized = False
    inputValue = 9.0
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(9.0, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Minimum Supply Air Temperature in Cooling Mode [C], 7.58525\n"
        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Minimum Supply Air Temperature in Cooling Mode [C], "
        "9.00000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))

def test_ASHRAEMaxSATHeatingSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "ASHRAEMaxSATHeatingSizingGauntlet"
    var sizer = ASHRAEMaxSATHeatingSizer()
    var inputValue: Float64 = 26.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(26.5, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(26.5, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
                                        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Maximum Supply Air "
                                        "Temperature in Heating Mode [C], 26.5000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[1].ZoneTempAtHeatPeak = 21.9
    state.dataSize.FinalZoneSizing[1].ZoneHumRatAtHeatPeak = 0.007
    state.dataSize.DataCapacityUsedForSizing = 2500.0
    state.dataSize.DataFlowUsedForSizing = 0.125
    state.dataSize.ZoneSizingRunDone = True
    state.dataEnvrn.StdRhoAir = 1.2
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(38.274, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataFlowUsedForSizing = 0.0
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    eiooutput = ""
    state.dataSize.DataFlowUsedForSizing = 0.125
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 32.8
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(32.8, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    inputValue = DataSizing.AutoSize
    state.dataSize.DataZoneUsedForSizing = 1
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(38.274, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Maximum Supply Air Temperature in Heating Mode [C], 38.2743\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    sizer.wasAutoSized = False
    inputValue = 32.3
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(32.3, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Maximum Supply Air Temperature in Heating Mode [C], 38.2743\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Maximum Supply Air Temperature in Heating Mode [C], "
        "32.3000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    sizer.wasAutoSized = False
    state.dataSize.DataCapacityUsedForSizing = 0.0
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType1, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0

def test_DesiccantDehumidifierBFPerfDataFaceVelocitySizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "DesiccantDehumidifierBFPerfDataFaceVelocitySizingGauntlet"
    let compType: StringLiteral = "HeatExchanger:Desiccant:BalancedFlow:PerformanceDataType1"
    var sizer = DesiccantDehumidifierBFPerfDataFaceVelocitySizer()
    var inputValue: Float64 = 4.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, compType, "MyDesiccantHX", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(4.5, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(^this.state, compType, "MyDesiccantHX", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(4.5, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
                                        " Component Sizing Information, " + String(compType) + ", MyDesiccantHX, User-Specified Nominal Air Face Velocity [m/s], 4.50000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.DataAirFlowUsedForSizing = 0.125
    state.dataSize.ZoneSizingRunDone = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, compType, "MyDesiccantHX", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(4.307, sizedValue, 0.001)
    var expectedValue: Float64 = 4.30551 + 0.01969 * state.dataSize.DataAirFlowUsedForSizing
    EXPECT_NEAR(expectedValue, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataEMSOverrideON = True
    state.dataSize.DataEMSOverride = 2.887
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, compType, "MyDesiccantHX", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2.887, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    eiooutput = ""
    state.dataSize.DataEMSOverrideON = False
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 3.2
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, compType, "MyDesiccantHX", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(3.2, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    inputValue = DataSizing.AutoSize
    state.dataSize.DataZoneUsedForSizing = 1
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, compType, "MyDesiccantHX", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(4.307, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, " + String(compType) +
                            ", MyDesiccantHX, Design Size Nominal Air Face Velocity [m/s], 4.30797\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    sizer.wasAutoSized = False
    inputValue = 3.2
    sizer.initializeWithinEP(^this.state, compType, "MyDesiccantHX", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(3.2, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, " + String(compType) +
                            ", MyDesiccantHX, Design Size Nominal Air Face Velocity [m/s], 4.30797\n"
                            " Component Sizing Information, " +
                            String(compType) + ", MyDesiccantHX, User-Specified Nominal Air Face Velocity [m/s], 3.20000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))

def test_HeatingCoilDesAirInletTempSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "HeatingCoilDesAirInletTempSizingGauntlet"
    var sizer = HeatingCoilDesAirInletTempSizer()
    var inputValue: Float64 = 17.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(17.5, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 17.8
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(17.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatRetTemp = 15.8
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatOutTemp = 13.8
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataDesicRegCoil = True
    state.dataSize.DataDesicDehumNum = 1
    state.dataDesiccantDehumidifiers.DesicDehum.allocate(1)
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(15.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n Component Sizing "
                    "Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Inlet Air Temperature, 15.8000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataDesiccantDehumidifiers.DesicDehum[1].RegenInletIsOutsideAirNode = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(13.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    eiooutput = ""
    sizer.wasAutoSized = False
    inputValue = 19.8
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(19.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Inlet Air Temperature, 13.8000\n"
                            " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Rated Inlet Air Temperature, 19.8000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))

def test_HeatingCoilDesAirOutletTempSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "HeatingCoilDesAirOutletTempSizingGauntlet"
    var sizer = HeatingCoilDesAirOutletTempSizer()
    var inputValue: Float64 = 37.5
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(37.5, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 27.8
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(27.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatRetTemp = 15.8
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatOutTemp = 13.8
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataDesicRegCoil = True
    state.dataSize.DataDesicDehumNum = 1
    state.dataDesiccantDehumidifiers.DesicDehum.allocate(1)
    state.dataDesiccantDehumidifiers.DesicDehum[1].RegenSetPointTemp = 26.4
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(26.4, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n Component Sizing "
                    "Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Outlet Air Temperature, 26.4000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    sizer.wasAutoSized = False
    inputValue = 32.8
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(32.8, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Outlet Air Temperature, 26.4000\n"
                            " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Rated Outlet Air Temperature, 32.8000\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))

def test_HeatingCoilDesAirInletHumRatSizingGauntlet(owned: AutoSizingFixture):
    let routineName: StringLiteral = "HeatingCoilDesAirInletHumRatSizingGauntlet"
    var sizer = HeatingCoilDesAirInletHumRatSizer()
    var inputValue: Float64 = 0.005
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.005, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 0.008
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.008, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[1].AirLoopNum = 1
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatRetHumRat = 0.008
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatOutHumRat = 0.004
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataDesicRegCoil = True
    state.dataSize.DataDesicDehumNum = 1
    state.dataDesiccantDehumidifiers.DesicDehum.allocate(1)
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.008, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n Component Sizing "
                    "Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Inlet Air Humidity Ratio, 8.000E-03\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    state.dataDesiccantDehumidifiers.DesicDehum[1].RegenInletIsOutsideAirNode = True
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.004, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    eiooutput = ""
    sizer.wasAutoSized = False
    inputValue = 0.009
    sizer.initializeWithinEP(^this.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(^this.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(0.009, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Inlet Air Humidity Ratio, 4.000E-03\n"
                    " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Rated Inlet Air Humidity Ratio, 9.000E-03\n")
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))