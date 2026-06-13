from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream
from ..\..\..\..\src\EnergyPlus\Autosizing\HeatingWaterDesCoilWaterVolFlowUsedForUASizing import HeatingWaterDesCoilWaterVolFlowUsedForUASizer
from ..\..\..\..\src\EnergyPlus\DataHVACGlobals import HVAC
from ..\..\..\..\src\EnergyPlus\DataSizing import DataSizing
from ..\..\..\..\src\EnergyPlus\DataAirLoop import DataAirLoop
from ..\..\..\..\src\EnergyPlus\DataAirLoopHVACDOAS import DataAirLoopHVACDOAS
from ..\..\..\..\src\EnergyPlus\DataGlobals import DataGlobals_

struct AutoSizingFixture_HeatingWaterDesCoilWaterVolFlowUsedForUASizingGauntlet_Test(AutoSizingFixture):
    def TestBody(inout self):
        var routineName = "HeatingWaterDesCoilWaterVolFlowUsedForUASizingSizingGauntlet"
        var sizer = HeatingWaterDesCoilWaterVolFlowUsedForUASizer()
        var inputValue = 0.0005
        var errorsFound = False
        var printFlag = False
        var sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertTrue(errorsFound)
        assertEq(AutoSizingResultType.ErrorType2, sizer.errorType)
        assertNear(0.0, sizedValue, 0.0001)
        errorsFound = False
        self.state.dataSize.DataPltSizHeatNum = 1
        self.state.dataSize.CurZoneEqNum = 1
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertFalse(sizer.wasAutoSized)
        assertNear(0.0005, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        has_eio_output(True)
        printFlag = True
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertFalse(sizer.wasAutoSized)
        assertNear(0.0005, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        var eiooutput = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n" \
                        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Design Water Volume Flow " \
                        "Rate Used for UA Sizing [m3/s], 0.000500000\n"
        assertTrue(compare_eio_stream(eiooutput, True))
        self.state.dataSize.PlantSizData.allocate(1)
        self.state.dataSize.DataWaterFlowUsedForSizing = 0.0001
        self.state.dataSize.ZoneSizingInput.allocate(1)
        self.state.dataSize.ZoneSizingInput[self.state.dataSize.CurZoneEqNum].ZoneNum = self.state.dataSize.CurZoneEqNum
        self.state.dataSize.ZoneSizingRunDone = True
        self.state.dataSize.TermUnitSingDuct = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertTrue(sizer.wasAutoSized)
        assertNear(0.0001, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        self.state.dataSize.DataWaterFlowUsedForSizing = 0.00025
        self.state.dataSize.TermUnitSingDuct = False
        self.state.dataSize.TermUnitPIU = True
        self.state.dataSize.CurTermUnitSizingNum = 1
        self.state.dataSize.TermUnitSizing.allocate(1)
        self.state.dataSize.TermUnitSizing[1].ReheatLoadMult = 0.5
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertTrue(sizer.wasAutoSized)
        assertNear(0.000125, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        var inputValue2 = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue2, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertTrue(sizer.wasAutoSized)
        assertNear(0.000125, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        has_eio_output(True)
        eiooutput = ""
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.NumZoneSizingInput = 0
        self.state.dataSize.CurTermUnitSizingNum = 0
        self.state.dataSize.ZoneEqSizing.deallocate()
        self.state.dataSize.CurSysNum = 1
        self.state.dataHVACGlobal.NumPrimaryAirSys = 1
        self.state.dataSize.NumSysSizInput = 1
        self.state.dataSize.SysSizingRunDone = False
        inputValue = 0.0003
        sizer.wasAutoSized = False
        printFlag = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertFalse(sizer.wasAutoSized)
        assertNear(0.0003, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        assertTrue(compare_eio_stream(eiooutput, True))
        self.state.dataSize.SysSizingRunDone = True
        self.state.dataSize.FinalSysSizing.allocate(1)
        self.state.dataSize.SysSizInput.allocate(1)
        self.state.dataSize.SysSizInput[1].AirLoopNum = 1
        self.state.dataSize.DataWaterFlowUsedForSizing = 0.0004
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertTrue(sizer.wasAutoSized)
        assertNear(0.0004, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Design Water Volume Flow " \
                    "Rate Used for UA Sizing [m3/s], 0.000400000\n"
        assertTrue(compare_eio_stream(eiooutput, True))
        self.state.dataSize.OASysEqSizing.allocate(1)
        self.state.dataAirLoop.OutsideAirSys.allocate(1)
        self.state.dataSize.CurOASysNum = 1
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertTrue(sizer.wasAutoSized)
        assertNear(0.0004, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        self.state.dataAirLoop.OutsideAirSys[self.state.dataSize.CurOASysNum].AirLoopDOASNum = 0
        self.state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertTrue(sizer.wasAutoSized)
        assertNear(0.0004, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        has_eio_output(True)
        inputValue = 0.0005
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(self.state, inputValue, errorsFound)
        assertEq(AutoSizingResultType.NoError, sizer.errorType)
        assertFalse(sizer.wasAutoSized)
        assertNear(0.0005, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        assertFalse(errorsFound)
        eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Design Water Volume Flow " \
                    "Rate Used for UA Sizing [m3/s], 0.000400000\n" \
                    " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Design Water Volume Flow " \
                    "Rate Used for UA Sizing [m3/s], 0.000500000\n"
        assertTrue(compare_eio_stream(eiooutput, True))