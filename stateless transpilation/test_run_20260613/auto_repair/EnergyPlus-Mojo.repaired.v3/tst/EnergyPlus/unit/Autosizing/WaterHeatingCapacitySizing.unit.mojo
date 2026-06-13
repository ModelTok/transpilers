from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream
from EnergyPlus.Autosizing.WaterHeatingCapacitySizing import WaterHeatingCapacitySizer
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataSizing import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.HVAC import HVAC
from EnergyPlus.Fluid import Fluid
from testing import *

@fixture
def AutoSizingFixture_WaterHeatingCapacitySizingGauntlet(self: AutoSizingFixture):
    state = self.state
    state.dataFluid.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.2
    var routineName = "WaterHeatingCapacitySizingGauntlet"
    state.dataSize.ZoneEqSizing.allocate(1)
    var sizer = WaterHeatingCapacitySizer()
    var inputValue = 5125.3
    var errorsFound = False
    var printFlag = False
    var sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_true(errorsFound)
    assert_equal(AutoSizingResultType.ErrorType2, sizer.errorType)
    assert_almost_equal(0.0, sizedValue, 0.01)  # uninitialized sizing types always return 0
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.CurTermUnitSizingNum = 1
    state.dataSize.TermUnitSingDuct = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_almost_equal(5125.3, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_almost_equal(5125.3, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    var eiooutput = String(
        "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Rated Capacity [W], 5125.30\n"
    )
    assert_true(compare_eio_stream(eiooutput, True))
    state.dataSize.TermUnitSizing.allocate(1)
    state.dataSize.TermUnitFinalZoneSizing.allocate(1)
    state.dataSize.TermUnitFinalZoneSizing[0].DesHeatCoilInTempTU = 15.0
    state.dataSize.TermUnitFinalZoneSizing[0].ZoneTempAtHeatPeak = 20.0
    state.dataSize.TermUnitSizing[0].MaxHWVolFlow = 0.0005
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[0].ZoneTempAtHeatPeak = 20.0
    state.dataSize.FinalZoneSizing[0].ZoneRetTempAtHeatPeak = 24.0
    state.dataSize.FinalZoneSizing[0].ZoneHumRatAtHeatPeak = 0.007
    state.dataSize.FinalZoneSizing[0].ZoneHumRatAtHeatPeak = 0.006
    state.dataSize.FinalZoneSizing[0].DesHeatMassFlow = 0.2
    state.dataSize.FinalZoneSizing[0].HeatDesTemp = 30.0
    state.dataSize.FinalZoneSizing[0].HeatDesHumRat = 0.004
    state.dataSize.FinalZoneSizing[0].OutTempAtHeatPeak = 5.0
    state.dataSize.FinalZoneSizing[0].OutHumRatAtHeatPeak = 0.002
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.ZoneEqSizing[0].MaxHWVolFlow = 0.0002
    state.dataSize.ZoneEqSizing[0].ATMixerHeatPriDryBulb = 28.0
    state.dataSize.ZoneEqSizing[0].ATMixerHeatPriHumRat = 0.0045
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.DataWaterLoopNum = 1
    state.dataSize.DataWaterCoilSizHeatDeltaT = 5.0
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.zoneSizingInput.allocate(1)
    sizer.zoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_almost_equal(10286.73, sizedValue, 0.01)
    assert_almost_equal(1.2, state.dataEnvrn.StdRhoAir, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.TermUnitSingDuct = False
    state.dataSize.ZoneEqFanCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_almost_equal(4114.69, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.05
    state.dataSize.ZoneEqFanCoil = False
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_almost_equal(2935.6, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.03
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_almost_equal(1068.96, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.0
    state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SystemAirFlow = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].AirVolFlow = 0.3
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_almost_equal(3644.19, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SystemAirFlow = False
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].AirVolFlow = 0.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirFlow = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 0.4
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_almost_equal(4858.92, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirFlow = False
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_almost_equal(2024.55, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.DataHeatSizeRatio = 0.5
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_almost_equal(1012.27, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(True)
    inputValue = 1500.0
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_almost_equal(1500.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    assert_false(errorsFound)
    eiooutput = String(
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Rated Capacity [W], 1012.28\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Rated Capacity [W], 1500.00\n"
    )
    assert_true(compare_eio_stream(eiooutput, True))