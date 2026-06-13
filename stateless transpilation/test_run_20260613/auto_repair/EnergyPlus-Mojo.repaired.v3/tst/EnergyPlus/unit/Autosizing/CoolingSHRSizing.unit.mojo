from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream
from EnergyPlus.Autosizing.CoolingSHRSizing import CoolingSHRSizer
from EnergyPlus.DataHVACGlobals import HVAC
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.DataSize import state as dataSize  # Note: this mapping may need adjustment
from EnergyPlus.DataHVACGlobals import state as dataHVACGlobal  # Note: this mapping may need adjustment

from testing import *
import sys

@value
struct AutoSizingFixtureTest(AutoSizingFixture):

def test_CoolingSHRSizingGauntlet() raises:
    var state = AutoSizingFixtureTest()
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    var routineName: String = "CoolingSHRSizingGauntlet"
    var sizer = CoolingSHRSizer()
    var inputValue: Float64 = 0.75
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(state, inputValue, errorsFound)
    assert_true(errorsFound)
    assert_equal(AutoSizingResultType.ErrorType2, sizer.errorType)
    assert_approx_equal(0.0, sizedValue, 0.01)
    assert_false(sizer.hardSizeNoDesignRun)
    assert_false(sizer.sizingDesRunThisZone)
    assert_false(sizer.sizingDesRunThisAirSys)
    assert_false(sizer.sizingDesValueFromParent)
    assert_false(sizer.airLoopSysFlag)
    assert_false(sizer.oaSysFlag)
    errorsFound = False
    inputValue = 0.85
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.DataFlowUsedForSizing = 0.5
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(0.85, sizedValue, 0.01)
    assert_false(sizer.sizingDesRunThisZone)
    assert_equal(sizer.sizingString, "Gross Rated Sensible Heat Ratio")
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    inputValue = 0.85
    state.dataSize.DataCapacityUsedForSizing = 10000.0
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(0.85, sizedValue, 0.01)
    var RatedVolFlowPerRatedTotCap: Float64 = state.dataSize.DataFlowUsedForSizing / state.dataSize.DataCapacityUsedForSizing
    var initialSHR: Float64 = 0.431 + 6086.0 * RatedVolFlowPerRatedTotCap
    assert_less_than(initialSHR, sizedValue)
    assert_false(sizer.sizingDesRunThisZone)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = (
        "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        " Component Sizing Information, Coil:Cooling:DX:SingleSpeed, MyDXCoil, User-Specified Gross Rated Sensible Heat Ratio, 0.850000\n"
    )
    assert_true(compare_eio_stream(eiooutput, True))
    has_eio_output(True)
    state.dataSize.ZoneSizingRunDone = True
    inputValue = DataSizing.AutoSize
    state.dataHVACGlobal.DXCT = HVAC.DXCoilType.Regular
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.776167, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    sizedValue = 0.0
    eiooutput = (
        " Component Sizing Information, Coil:Cooling:DX:SingleSpeed, MyDXCoil, Design Size Gross Rated Sensible Heat Ratio, 0.776167\n"
    )
    assert_true(compare_eio_stream(eiooutput, True))
    inputValue = DataSizing.AutoSize
    state.dataSize.DataCapacityUsedForSizing = 0.0
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.ErrorType1, sizer.errorType)
    assert_true(errorsFound)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(1.0, sizedValue, 0.01)
    state.dataSize.DataCapacityUsedForSizing = 10000.0
    state.dataSize.DataFlowUsedForSizing = 1.0
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(1.0, sizedValue, 0.000001)
    initialSHR = 0.431 + 6086.0 * HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
    assert_less_than(initialSHR, sizedValue)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataFlowUsedForSizing = 0.1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    initialSHR = (
        0.431 +
        6086.0 * HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
    )
    assert_greater_than(initialSHR, sizedValue)
    assert_approx_equal(0.676083, initialSHR, 0.000001)
    assert_approx_equal(0.675083, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    state.dataSize.DataFlowUsedForSizing = 0.3
    inputValue = DataSizing.AutoSize
    state.dataHVACGlobal.DXCT = HVAC.DXCoilType.DOAS
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    RatedVolFlowPerRatedTotCap = state.dataSize.DataFlowUsedForSizing / state.dataSize.DataCapacityUsedForSizing
    initialSHR = 0.389 + 7684.0 * RatedVolFlowPerRatedTotCap
    assert_approx_equal(0.61952, initialSHR, 0.000001)
    assert_approx_equal(0.631462, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    sizedValue = 0.0
    eiooutput = (
        " Component Sizing Information, Coil:Cooling:DX:SingleSpeed, MyDXCoil, Design Size Gross Rated Sensible Heat Ratio, 0.631462\n"
    )
    assert_true(compare_eio_stream(eiooutput, True))
    state.dataSize.DataFlowUsedForSizing = 1.0
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(1.0, sizedValue, 0.000001)
    initialSHR = (
        0.431 +
        6086.0 * HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
    )
    assert_less_than(initialSHR, sizedValue)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataFlowUsedForSizing = 0.1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    initialSHR = (
        0.431 +
        6086.0 * HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
    )
    assert_less_than(initialSHR, sizedValue)
    assert_approx_equal(0.533062, initialSHR, 0.000001)
    assert_approx_equal(0.675925, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    eiooutput = ""
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.ZoneEqSizing.deallocate()
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 0.67
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(0.67, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0
    assert_true(compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[0].AirLoopNum = 1
    state.dataSize.DataFlowUsedForSizing = 0.5
    state.dataHVACGlobal.DXCT = HVAC.DXCoilType.Regular
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.776167, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    eiooutput = (
        " Component Sizing Information, Coil:Cooling:DX:SingleSpeed, MyDXCoil, Design Size Gross Rated Sensible Heat Ratio, 0.776167\n"
    )
    assert_true(compare_eio_stream(eiooutput, True))
    state.dataSize.DataFlowUsedForSizing = 0.6
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.856504, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    state.dataSize.DataFlowUsedForSizing = 0.1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.675083, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    eiooutput = ""
    state.dataSize.CurOASysNum = 1
    state.dataSize.OASysEqSizing.allocate(1)
    inputValue = 0.52
    printFlag = True
    errorsFound = False
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(0.52, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    assert_false(errorsFound)
    eiooutput = (
        " Component Sizing Information, Coil:Cooling:DX:SingleSpeed, MyDXCoil, Design Size Gross Rated Sensible Heat Ratio, 0.675083\n"
        " Component Sizing Information, Coil:Cooling:DX:SingleSpeed, MyDXCoil, User-Specified Gross Rated Sensible Heat Ratio, 0.520000\n"
    )
    assert_true(compare_eio_stream(eiooutput, True))