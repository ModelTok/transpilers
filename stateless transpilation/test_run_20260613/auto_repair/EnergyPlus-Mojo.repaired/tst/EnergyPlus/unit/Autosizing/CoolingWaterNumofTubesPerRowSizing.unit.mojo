from AutosizingFixture import AutoSizingFixture
from .........src.EnergyPlus.Autosizing.CoolingWaterNumofTubesPerRowSizing import CoolingWaterNumofTubesPerRowSizer
from .........src.EnergyPlus.DataHVACGlobals import HVAC
from .........src.EnergyPlus.DataSizing import DataSizing, AutoSizingResultType
from testing import assert_true, assert_false, assert_equal, assert_approx_eq

module EnergyPlus:

    def coolingWaterNumofTubesPerRowSizingGauntlet():
        var fixture = AutoSizingFixture()
        var state = fixture.state
        const routineName = String("CoolingWaterNumofTubesPerRowSizingGauntlet")
        var sizer = CoolingWaterNumofTubesPerRowSizer()
        var inputValue: Float64 = 5.0
        var errorsFound: Bool = False
        var printFlag: Bool = False
        var sizedValue: Float64 = sizer.size(state, inputValue, errorsFound)
        assert_true(errorsFound)
        assert_equal(AutoSizingResultType.ErrorType2, sizer.errorType)
        assert_approx_eq(0.0, sizedValue, 0.01)
        errorsFound = False
        state.dataSize.DataPltSizCoolNum = 1
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_false(sizer.wasAutoSized)
        assert_approx_eq(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        fixture.has_eio_output(True)
        printFlag = True
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_false(sizer.wasAutoSized)
        assert_approx_eq(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        var eiooutput = String(
            "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
            " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Number of Tubes per Row, 5.00000\n"
        )
        assert_true(fixture.compare_eio_stream(eiooutput, True))
        state.dataSize.PlantSizData.allocate(1)
        state.dataSize.DataWaterFlowUsedForSizing = 0.0001
        state.dataSize.TermUnitSingDuct = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_true(sizer.wasAutoSized)
        assert_approx_eq(3.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.DataWaterFlowUsedForSizing = 0.00025
        state.dataSize.TermUnitSingDuct = False
        state.dataSize.TermUnitPIU = True
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_true(sizer.wasAutoSized)
        assert_approx_eq(4.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        fixture.has_eio_output(True)
        eiooutput = ""
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.NumZoneSizingInput = 0
        state.dataSize.CurTermUnitSizingNum = 0
        state.dataSize.ZoneEqSizing.deallocate()
        state.dataSize.FinalZoneSizing.deallocate()
        state.dataSize.CurSysNum = 1
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        state.dataSize.NumSysSizInput = 1
        state.dataSize.SysSizingRunDone = False
        inputValue = 5.0
        sizer.wasAutoSized = False
        printFlag = False
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_false(sizer.wasAutoSized)
        assert_approx_eq(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        assert_true(fixture.compare_eio_stream(eiooutput, True))
        state.dataSize.CurSysNum = 1
        state.dataSize.NumSysSizInput = 1
        state.dataSize.SysSizingRunDone = True
        state.dataSize.FinalSysSizing.allocate(1)
        state.dataSize.SysSizInput.allocate(1)
        state.dataSize.SysSizInput[0].AirLoopNum = 1
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_true(sizer.wasAutoSized)
        assert_approx_eq(4.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        eiooutput = String(
            " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Number of Tubes per Row, 4.00000\n"
        )
        assert_true(fixture.compare_eio_stream(eiooutput, True))
        state.dataSize.OASysEqSizing.allocate(1)
        state.dataAirLoop.OutsideAirSys.allocate(1)
        state.dataSize.CurOASysNum = 1
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_true(sizer.wasAutoSized)
        assert_approx_eq(4.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataAirLoop.OutsideAirSys[state.dataSize.CurOASysNum - 1].AirLoopDOASNum = 0
        state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_true(sizer.wasAutoSized)
        assert_approx_eq(4.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        fixture.has_eio_output(True)
        inputValue = 5.0
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(
            state,
            HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)],
            "MyWaterCoil",
            printFlag,
            routineName,
        )
        sizedValue = sizer.size(state, inputValue, errorsFound)
        assert_equal(AutoSizingResultType.NoError, sizer.errorType)
        assert_false(sizer.wasAutoSized)
        assert_approx_eq(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        assert_false(errorsFound)
        eiooutput = String(
            " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Number of Tubes per Row, 4.00000\n"
            " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Number of Tubes per Row, 5.00000\n"
        )
        assert_true(fixture.compare_eio_stream(eiooutput, True))