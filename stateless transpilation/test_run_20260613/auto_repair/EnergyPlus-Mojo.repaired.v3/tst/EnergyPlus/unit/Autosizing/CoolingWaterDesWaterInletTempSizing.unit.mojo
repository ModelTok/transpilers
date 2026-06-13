from AutosizingFixture import AutoSizingFixture
from EnergyPlus.Autosizing.CoolingWaterDesWaterInletTempSizing import CoolingWaterDesWaterInletTempSizer
from EnergyPlus.DataHVACGlobals import HVAC
from EnergyPlus.DataSizing import DataSizing, AutoSizingResultType
from EnergyPlus.Fans import Fans

def CoolingWaterDesWaterInletTempSizingGauntlet(self: AutoSizingFixture) -> None:
    let routineName: StringLiteral = "CoolingWaterDesWaterInletTempSizingGauntlet"
    var sizer = CoolingWaterDesWaterInletTempSizer()
    var inputValue: Float64 = 5.0
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(self.state, inputValue, errorsFound)
    expect_true(errorsFound)
    expect_enum_eq(AutoSizingResultType.ErrorType2, sizer.errorType)
    expect_near(0.0, sizedValue, 0.01)  # uninitialized sizing types always return 0
    errorsFound = False
    self.state.dataSize.DataPltSizCoolNum = 1
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    var eiooutput = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Inlet Water Temperature [C], 5.00000\n"
    expect_true(compare_eio_stream(eiooutput, True))
    self.state.dataSize.PlantSizData.allocate(1)
    self.state.dataSize.PlantSizData[0].ExitTemp = 15.0
    self.state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitSingDuct = False
    self.state.dataSize.TermUnitPIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitPIU = False
    self.state.dataSize.TermUnitIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.TermUnitIU = False
    self.state.dataSize.ZoneEqFanCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.ZoneEqFanCoil = False
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)  # uses a mass flow rate for sizing
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(True)
    eiooutput = ""
    self.state.dataSize.CurZoneEqNum = 0
    self.state.dataSize.NumZoneSizingInput = 0
    self.state.dataSize.CurTermUnitSizingNum = 0
    self.state.dataSize.ZoneEqSizing.deallocate()
    self.state.dataSize.FinalZoneSizing.deallocate()
    self.state.dataSize.CurSysNum = 1
    self.state.dataHVACGlobal.NumPrimaryAirSys = 1
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizingRunDone = False
    inputValue = 5.0
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_false(sizer.wasAutoSized)
    expect_near(5.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    expect_true(compare_eio_stream(eiooutput, True))
    self.state.dataSize.CurSysNum = 1
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizingRunDone = True
    self.state.dataSize.FinalSysSizing.allocate(1)
    self.state.dataSize.FinalSysSizing[0].HeatOutTemp = 10.0
    self.state.dataSize.FinalSysSizing[0].HeatRetTemp = 12.0
    self.state.dataSize.SysSizInput.allocate(1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Inlet Water Temperature [C], 15.0000\n"
    expect_true(compare_eio_stream(eiooutput, True))
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Main
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Heating
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataSize.OASysEqSizing.allocate(1)
    self.state.dataAirLoop.OutsideAirSys.allocate(1)
    self.state.dataSize.CurOASysNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    self.state.dataAirLoop.OutsideAirSys[self.state.dataSize.CurOASysNum - 1].AirLoopDOASNum = 0
    self.state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].HeatOutTemp = 12.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
    expect_true(sizer.wasAutoSized)
    expect_near(15.0, sizedValue, 0.01)  # uses a mass flow rate for sizing
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(True)
    inputValue = 12.0
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)  # cumulative of previous calls
    expect_false(sizer.wasAutoSized)
    expect_near(12.0, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    expect_false(errorsFound)
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Inlet Water Temperature [C], 15.0000\n Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Inlet Water Temperature [C], 12.0000\n"
    expect_true(compare_eio_stream(eiooutput, True))