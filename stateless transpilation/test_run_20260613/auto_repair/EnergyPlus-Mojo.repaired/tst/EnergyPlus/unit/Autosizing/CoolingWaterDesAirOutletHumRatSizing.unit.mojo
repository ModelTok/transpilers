from AutosizingFixture import AutoSizingFixture
from gtest import *
from EnergyPlus.Autosizing.CoolingWaterDesAirOutletHumRatSizing import CoolingWaterDesAirOutletHumRatSizer
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirLoopHVACDOAS import *
from EnergyPlus.HVAC import *

@register_test
struct AutoSizingFixture_CoolingWaterDesAirOutletHumRatSizingGauntlet(AutoSizingFixture):
    def TestBody(self):
        self.state.dataSize.ZoneEqSizing.allocate(1)
        self.state.dataEnvrn.StdRhoAir = 1.2
        var routineName: StringLiteral = "CoolingWaterDesAirOutletHumRatSizingGauntlet"
        var sizer: CoolingWaterDesAirOutletHumRatSizer
        var inputValue: Float64 = 0.006
        var errorsFound: Bool = False
        var printFlag: Bool = False
        var sizedValue: Float64 = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_TRUE(errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
        EXPECT_NEAR(0.0, sizedValue, 0.01)
        errorsFound = False
        self.state.dataSize.CurZoneEqNum = 1
        self.has_eio_output(True)
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_FALSE(sizer.wasAutoSized)
        EXPECT_NEAR(0.006, sizedValue, 0.001)
        sizer.autoSizedValue = 0.0
        var eiooutput: String = String("")
        EXPECT_TRUE(self.compare_eio_stream(eiooutput, True))
        printFlag = True
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_FALSE(sizer.wasAutoSized)
        EXPECT_NEAR(0.006, sizedValue, 0.001)
        sizer.autoSizedValue = 0.0
        eiooutput = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
                            " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Outlet Air Humidity Ratio "
                            "[kgWater/kgDryAir], 6.000E-03\n")
        EXPECT_TRUE(self.compare_eio_stream(eiooutput, True))
        self.has_eio_output(True)
        self.state.dataSize.FinalZoneSizing.allocate(1)
        self.state.dataSize.DataDesInletAirHumRat = 0.009
        self.state.dataSize.DataDesOutletAirTemp = 12.0
        self.state.dataSize.DataDesInletWaterTemp = 7.0
        self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum].CoolDesHumRat = 0.008
        self.state.dataSize.ZoneSizingRunDone = True
        self.state.dataSize.TermUnitSingDuct = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(0.008, sizedValue, 0.0001)
        eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Outlet Air Humidity Ratio "
                            "[kgWater/kgDryAir], 8.000E-03\n")
        EXPECT_TRUE(self.compare_eio_stream(eiooutput, True))
        self.state.dataSize.TermUnitSingDuct = False
        self.state.dataSize.TermUnitPIU = True
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(0.008, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        self.state.dataSize.TermUnitPIU = False
        self.state.dataSize.ZoneEqFanCoil = True
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(0.008, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        self.state.dataSize.TermUnitPIU = False
        self.state.dataSize.TermUnitIU = True
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(0.0078, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        self.state.dataSize.TermUnitIU = False
        self.has_eio_output(True)
        eiooutput = ""
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.NumZoneSizingInput = 0
        self.state.dataSize.ZoneEqSizing.deallocate()
        self.state.dataSize.FinalZoneSizing.deallocate()
        self.state.dataSize.CurSysNum = 1
        self.state.dataHVACGlobal.NumPrimaryAirSys = 1
        self.state.dataSize.NumSysSizInput = 1
        self.state.dataSize.SysSizingRunDone = False
        inputValue = 0.012
        sizer.wasAutoSized = False
        printFlag = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_FALSE(sizer.wasAutoSized)
        EXPECT_NEAR(0.012, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        EXPECT_TRUE(self.compare_eio_stream(eiooutput, True))
        self.state.dataSize.CurSysNum = 1
        self.state.dataHVACGlobal.NumPrimaryAirSys = 1
        self.state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        self.state.dataSize.NumSysSizInput = 1
        self.state.dataSize.SysSizingRunDone = True
        self.state.dataSize.FinalSysSizing.allocate(1)
        self.state.dataSize.SysSizInput.allocate(1)
        self.state.dataSize.SysSizInput[1].AirLoopNum = 1
        self.state.dataSize.FinalSysSizing[1].CoolSupHumRat = 0.0105
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_GT(self.state.dataSize.FinalSysSizing[1].CoolSupHumRat, self.state.dataSize.DataDesInletAirHumRat)
        EXPECT_NEAR(self.state.dataSize.DataDesInletAirHumRat, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Outlet Air Humidity Ratio "
                            "[kgWater/kgDryAir], 9.000E-03\n")
        EXPECT_TRUE(self.compare_eio_stream(eiooutput, True))
        self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum].NumOACoolCoils = 1
        self.state.dataSize.FinalSysSizing[1].CoolSupHumRat = 0.0075
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        printFlag = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(0.0075, sizedValue, 0.00001)
        sizer.autoSizedValue = 0.0
        self.state.dataSize.DataDesOutletAirHumRat = 0.0077
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(0.0077, sizedValue, 0.00001)
        sizer.autoSizedValue = 0.0
        self.state.dataSize.OASysEqSizing.allocate(1)
        self.state.dataAirLoop.OutsideAirSys.allocate(1)
        self.state.dataSize.CurOASysNum = 1
        self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum].OutHumRatAtCoolPeak = 0.005
        self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum].PrecoolHumRat = 0.004
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        var precoolHumRat: Float64 = self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum].PrecoolHumRat
        EXPECT_NEAR(precoolHumRat, sizedValue, 0.00001)
        sizer.autoSizedValue = 0.0
        self.state.dataSize.FinalSysSizing[1].DesOutAirVolFlow = 0.0
        self.state.dataAirLoop.OutsideAirSys[1].AirLoopDOASNum = 0
        self.state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
        self.state.dataAirLoopHVACDOAS.airloopDOAS[0].PrecoolHumRat = 0.0036
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(0.0036, sizedValue, 0.00001)
        sizer.autoSizedValue = 0.0
        self.has_eio_output(True)
        inputValue = 0.00665
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_FALSE(sizer.wasAutoSized)
        EXPECT_NEAR(inputValue, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        EXPECT_FALSE(errorsFound)
        eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Outlet Air Humidity Ratio "
                            "[kgWater/kgDryAir], 3.600E-03\n"
                            " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Outlet Air Humidity Ratio "
                            "[kgWater/kgDryAir], 6.650E-03\n")
        EXPECT_TRUE(self.compare_eio_stream(eiooutput, True))
        self.has_eio_output(True)
        inputValue = DataSizing.AutoSize
        self.state.dataSize.DataDesInletAirHumRat = 0.003
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(self.state.dataSize.DataDesInletAirHumRat, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        EXPECT_FALSE(errorsFound)
        eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Outlet Air Humidity Ratio "
                            "[kgWater/kgDryAir], 3.000E-03\n")
        EXPECT_TRUE(self.compare_eio_stream(eiooutput, True))
        inputValue = DataSizing.AutoSize
        self.state.dataSize.DataDesInletAirHumRat = 0.010
        self.state.dataSize.DataDesInletWaterTemp = 12.0
        self.state.dataSize.DataDesInletAirHumRat = 0.008
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
        EXPECT_TRUE(sizer.wasAutoSized)
        EXPECT_NEAR(self.state.dataSize.DataDesInletAirHumRat, sizedValue, 0.0001)
        EXPECT_NEAR(0.008, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0