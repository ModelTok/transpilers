from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream
from EnergyPlus.Autosizing.HeatingWaterDesAirInletHumRatSizing import HeatingWaterDesAirInletHumRatSizer
from EnergyPlus.DataAirSystems import PrimaryAirSystems
from EnergyPlus.DataEnvironment import StdRhoAir
from EnergyPlus.DataHVACGlobals import HVACCoilType, coilTypeNames
from EnergyPlus.DataSizing import AutoSize, OAControl, ZoneEqSizing, FinalZoneSizing, TermUnitSizing, TermUnitFinalZoneSizing, ZoneSizingInput, SysSizInput, FinalSysSizing, OASysEqSizing
from EnergyPlus.DataHVACGlobals import NumPrimaryAirSys
from EnergyPlus.DataAirLoop import OutsideAirSys
from EnergyPlus.DataAirLoopHVACDOAS import AirloopDOAS
from memory import Array
from math import abs

@value
struct AutoSizingFixtureTest(AutoSizingFixture):
    def HeatingWaterDesAirInletHumRatSizingGauntlet(self):
        self.state.dataSize.ZoneEqSizing = Array[ZoneEqSizing](1)
        self.state.dataEnvrn.StdRhoAir = 1.2
        var routineName: String = "HeatingWaterDesAirInletHumRatSizingGauntlet"
        var sizer = HeatingWaterDesAirInletHumRatSizer()
        var inputValue: Float64 = 0.009
        var errorsFound: Bool = False
        var printFlag: Bool = False
        var sizedValue: Float64 = sizer.size(self.state, inputValue, errorsFound)
        assert(errorsFound)
        assert(sizer.errorType == AutoSizingResultType.ErrorType2)
        assert(abs(0.0 - sizedValue) <= 0.01)  # uninitialized sizing types always return 0
        errorsFound = False
        self.state.dataSize.CurZoneEqNum = 1
        has_eio_output(True)
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(not sizer.wasAutoSized)
        assert(abs(0.009 - sizedValue) <= 0.001)  # hard-sized value
        sizer.autoSizedValue = 0.0  # reset for next test
        var eiooutput: String = ""
        assert(compare_eio_stream(eiooutput, True))
        printFlag = True
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(not sizer.wasAutoSized)
        assert(abs(0.009 - sizedValue) <= 0.001)  # hard-sized value
        sizer.autoSizedValue = 0.0  # reset for next test
        eiooutput = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n" \
                    " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Design Inlet Air Humidity Ratio " \
                    "[kgWater/kgDryAir], 9.000E-03\n"
        assert(compare_eio_stream(eiooutput, True))
        has_eio_output(True)
        self.state.dataSize.FinalZoneSizing = Array[FinalZoneSizing](1)
        self.state.dataSize.ZoneEqSizing = Array[ZoneEqSizing](1)
        self.state.dataSize.TermUnitSizing = Array[TermUnitSizing](1)
        self.state.dataSize.TermUnitFinalZoneSizing = Array[TermUnitFinalZoneSizing](1)
        self.state.dataSize.TermUnitFinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesHeatCoilInHumRatTU = 0.008
        self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].ZoneHumRatAtHeatPeak = 0.007
        self.state.dataSize.TermUnitFinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].ZoneHumRatAtHeatPeak = 0.006
        self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesHeatCoilInHumRat = 0.008
        self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesHeatMassFlow = 0.01
        self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].OutHumRatAtHeatPeak = 0.004
        self.state.dataSize.ZoneSizingInput = Array[ZoneSizingInput](1)
        self.state.dataSize.ZoneSizingInput[self.state.dataSize.CurZoneEqNum - 1].ZoneNum = self.state.dataSize.CurZoneEqNum
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].AirVolFlow = 0.021
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 0.015
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].OAVolFlow = 0.003
        self.state.dataSize.ZoneSizingRunDone = True
        self.state.dataSize.CurTermUnitSizingNum = 1
        self.state.dataSize.TermUnitSingDuct = True
        inputValue = AutoSize
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.008 - sizedValue) <= 0.0001)
        eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Design Inlet Air Humidity Ratio " \
                    "[kgWater/kgDryAir], 8.000E-03\n"
        assert(compare_eio_stream(eiooutput, True))
        self.state.dataSize.TermUnitSingDuct = False
        self.state.dataSize.TermUnitPIU = True
        self.state.dataSize.TermUnitSizing[0].MinPriFlowFrac = 0.0  # all zone air
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.007 - sizedValue) <= 0.0001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.TermUnitSizing[0].MinPriFlowFrac = 0.3  # mix zone air and DesHeatCoilInHumRatTU
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        var expectedValue: Float64 = 0.7 * 0.007 + 0.3 * 0.008  # 70% zone + 30% DesHeatCoilInHumRatTU
        assert(abs(expectedValue - sizedValue) <= 0.00001)
        assert(abs(0.0073 - sizedValue) <= 0.0001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.TermUnitPIU = False
        self.state.dataSize.TermUnitIU = True
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.006 - sizedValue) <= 0.0001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.TermUnitIU = False
        self.state.dataSize.ZoneEqFanCoil = True
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.0059 - sizedValue) <= 0.0001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SystemAirFlow = True
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.00657 - sizedValue) <= 0.00001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SystemAirFlow = False
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 1.0
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.00592 - sizedValue) <= 0.00001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 0.0
        self.state.dataSize.ZoneEqSizing[0].OAVolFlow = \
            self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesHeatMassFlow / (10.0 * self.state.dataEnvrn.StdRhoAir)
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        expectedValue = 0.9 * 0.007 + 0.1 * 0.004  # 90% zone + 10% OA
        assert(abs(expectedValue - sizedValue) <= 0.0001)
        assert(abs(0.0067 - sizedValue) <= 0.0001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.ZoneEqSizing[0].ATMixerHeatPriHumRat = 0.001
        self.state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.002 / self.state.dataEnvrn.StdRhoAir  # AT mass flow smaller than DesCoolMassFlow by factor of 5
        var mixedHumRat2: Float64 = 0.8 * 0.007 + 0.2 * 0.001  # 80% of ZoneHumRatAtCoolPeak, 20% of AT Mixer mass flow
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(mixedHumRat2 - sizedValue) <= 0.00001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.0
        self.state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.0
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.007 - sizedValue) <= 0.00001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.ZoneEqFanCoil = False
        has_eio_output(True)
        eiooutput = ""
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.NumZoneSizingInput = 0
        self.state.dataSize.ZoneEqSizing = Array[ZoneEqSizing]()
        self.state.dataSize.FinalZoneSizing = Array[FinalZoneSizing]()
        self.state.dataSize.CurSysNum = 1
        self.state.dataHVACGlobal.NumPrimaryAirSys = 1
        self.state.dataSize.NumSysSizInput = 1
        self.state.dataSize.SysSizingRunDone = False
        inputValue = 0.012
        sizer.wasAutoSized = False
        printFlag = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(not sizer.wasAutoSized)
        assert(abs(0.012 - sizedValue) <= 0.0001)  # hard-sized value
        sizer.autoSizedValue = 0.0  # reset for next test
        assert(compare_eio_stream(eiooutput, True))
        self.state.dataSize.CurSysNum = 1
        self.state.dataHVACGlobal.NumPrimaryAirSys = 1
        self.state.dataAirSystemsData.PrimaryAirSystems = Array[PrimaryAirSystems](1)
        self.state.dataSize.NumSysSizInput = 1
        self.state.dataSize.SysSizingRunDone = True
        self.state.dataSize.FinalSysSizing = Array[FinalSysSizing](1)
        self.state.dataSize.SysSizInput = Array[SysSizInput](1)
        self.state.dataSize.SysSizInput[0].AirLoopNum = 1
        self.state.dataSize.FinalSysSizing[0].HeatRetHumRat = 0.012
        self.state.dataSize.FinalSysSizing[0].HeatOutHumRat = 0.006
        inputValue = AutoSize
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.006 - sizedValue) <= 0.01)
        sizer.autoSizedValue = 0.0  # reset for next test
        eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Design Inlet Air Humidity Ratio " \
                    "[kgWater/kgDryAir], 6.000E-03\n"
        assert(compare_eio_stream(eiooutput, True))
        self.state.dataAirSystemsData.PrimaryAirSystems[self.state.dataSize.CurSysNum - 1].NumOACoolCoils = 1
        self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].RetHumRatAtCoolPeak = 0.015
        self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].PrecoolHumRat = 0.01
        inputValue = AutoSize
        sizer.wasAutoSized = False
        printFlag = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.006 - sizedValue) <= 0.00001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].DesOutAirVolFlow = 0.01
        self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].HeatOAOption = OAControl.MinOA
        self.state.dataSize.DataFlowUsedForSizing = 0.1  # system volume flow
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.0114 - sizedValue) <= 0.00001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.OASysEqSizing = Array[OASysEqSizing](1)
        self.state.dataAirLoop.OutsideAirSys = Array[OutsideAirSys](1)
        self.state.dataSize.CurOASysNum = 1
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        var outAirHumRat: Float64 = self.state.dataSize.FinalSysSizing[self.state.dataSize.CurSysNum - 1].HeatOutHumRat
        assert(abs(outAirHumRat - sizedValue) <= 0.00001)
        sizer.autoSizedValue = 0.0  # reset for next test
        self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.0
        self.state.dataAirLoop.OutsideAirSys[0].AirLoopDOASNum = 0
        self.state.dataAirLoopHVACDOAS.airloopDOAS.append(AirloopDOAS())
        self.state.dataAirLoopHVACDOAS.airloopDOAS[0].HeatOutHumRat = 0.0036
        inputValue = AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)
        assert(sizer.wasAutoSized)
        assert(abs(0.0036 - sizedValue) <= 0.00001)  # DOAS system hum rat
        sizer.autoSizedValue = 0.0  # reset for next test
        has_eio_output(True)
        inputValue = 0.00665  # value not previously used
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(self.state, coilTypeNames[HVACCoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assert(sizer.errorType == AutoSizingResultType.NoError)  # cumulative of previous calls
        assert(not sizer.wasAutoSized)
        assert(abs(inputValue - sizedValue) <= 0.01)  # hard-sized value
        sizer.autoSizedValue = 0.0  # reset for next test
        assert(not errorsFound)
        eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Design Inlet Air Humidity Ratio " \
                    "[kgWater/kgDryAir], 3.600E-03\n" \
                    " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Design Inlet Air Humidity Ratio " \
                    "[kgWater/kgDryAir], 6.650E-03\n"
        assert(compare_eio_stream(eiooutput, True))