from AutosizingFixture import AutoSizingFixture
from HeatingWaterDesCoilLoadUsedForUASizing import HeatingWaterDesCoilLoadUsedForUASizer
from DataEnvironment import dataEnvrn
from DataHVACGlobals import dataHVACGlobal
from DataSizing import dataSize, AutoSize, AutoSizingResultType, OAControl
from FluidProperties import Fluid
from HVAC import HVAC, CoilType
from PlantManager import dataPlnt
from DataAirSystems import dataAirSystemsData
from DataAirLoop import dataAirLoop
from DataAirLoopHVACDOAS import dataAirLoopHVACDOAS
from DataSizing import OAControl
import "DataGlobalConstants" as DataGlobalConstants

# Test fixture
struct AutoSizingFixture:
    var state: DataGlobalTypes.State

    def __init__(inout self):
        self.state = DataGlobalTypes.State()

# Alias for constants
alias routineName = "HeatingWaterDesCoilLoadUsedForUASizingGauntlet"

# Test function
def test_HeatingWaterDesCoilLoadUsedForUASizingGauntlet():
    var fixture = AutoSizingFixture()
    var state = fixture.state
    state.dataFluid.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.2
    state.dataSize.ZoneEqSizing.allocate(1)
    var sizer = HeatingWaterDesCoilLoadUsedForUASizer()
    var inputValue = 5125.3
    var errorsFound = False
    var printFlag = False
    var sizedValue = sizer.size(state, inputValue, errorsFound)
    assert errorsFound
    assert sizer.errorType == AutoSizingResultType.ErrorType2
    assert abs(sizedValue - 0.0) < 0.01
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.CurTermUnitSizingNum = 1
    state.dataSize.TermUnitSingDuct = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert not sizer.wasAutoSized
    assert abs(sizedValue - 5125.3) < 0.01
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert not sizer.wasAutoSized
    assert abs(sizedValue - 5125.3) < 0.01
    sizer.autoSizedValue = 0.0
    var eiooutput = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Water Heating Design Coil Load for UA Sizing [W], 5125.30\n"
    assert compare_eio_stream(eiooutput, True)
    state.dataSize.TermUnitSizing.allocate(1)
    state.dataSize.TermUnitFinalZoneSizing.allocate(1)
    state.dataSize.TermUnitFinalZoneSizing[0].DesHeatCoilInTempTU = 15.0
    state.dataSize.TermUnitFinalZoneSizing[0].ZoneTempAtHeatPeak = 20.0
    state.dataSize.TermUnitSizing[0].AirVolFlow = 0.0005
    state.dataSize.TermUnitSizing[0].ReheatAirFlowMult = 1.0
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
    state.dataSize.DataWaterFlowUsedForSizing = 0.0002
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = AutoSize
    sizer.zoneSizingInput.allocate(1)
    sizer.zoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 4114.69) < 0.01
    assert abs(state.dataEnvrn.StdRhoAir - 1.2) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.TermUnitSingDuct = False
    state.dataSize.ZoneEqFanCoil = True
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 4114.69) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqFanCoil = False
    state.dataSize.TermUnitIU = True
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 4114.69) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.05
    state.dataSize.TermUnitIU = False
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 2935.6) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.03
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 1068.96) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.0
    state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SystemAirFlow = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].AirVolFlow = 0.3
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 3644.19) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SystemAirFlow = False
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].AirVolFlow = 0.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirFlow = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 0.4
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 4858.92) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirFlow = False
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 0.0
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 2024.55) < 0.01
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    inputValue = 1500.0
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert not sizer.wasAutoSized
    assert abs(sizedValue - 1500.0) < 0.01
    sizer.autoSizedValue = 0.0
    assert not errorsFound
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Water Heating Design Coil Load for UA Sizing [W], 2024.55\n Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Water Heating Design Coil Load for UA Sizing [W], 1500.00\n"
    assert compare_eio_stream(eiooutput, True)
    has_eio_output(True)
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
    inputValue = 5000.0
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert not sizer.wasAutoSized
    assert abs(sizedValue - 5000.0) < 0.01
    sizer.autoSizedValue = 0.0
    assert compare_eio_stream(eiooutput, True)
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.FinalSysSizing[0].HeatOutTemp = 10.0
    state.dataSize.FinalSysSizing[0].HeatRetTemp = 24.0
    state.dataSize.FinalSysSizing[0].HeatSupTemp = 30.0
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[0].AirLoopNum = 1
    state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    state.dataSize.DataAirFlowUsedForSizing = 0.6
    inputValue = AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 14469.96) < 0.01
    sizer.autoSizedValue = 0.0
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Water Heating Design Coil Load for UA Sizing [W], 14470.0\n"
    assert compare_eio_stream(eiooutput, True)
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].HeatingCapMethod = DataSizing.FractionOfAutosizedHeatingCapacity
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].FractionOfAutosizedHeatingCapacity = 1.25
    inputValue = AutoSize
    sizer.wasAutoSized = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    var expectedValue = 14469.96 * state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].FractionOfAutosizedHeatingCapacity
    assert abs(sizedValue - expectedValue) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].FractionOfAutosizedHeatingCapacity = 1.0
    assert not errorsFound
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Water Heating Design Coil Load for UA Sizing [W], 18087.5\n"
    assert compare_eio_stream(eiooutput, True)
    has_eio_output(True)
    eiooutput = ""
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].HeatOAOption = OAControl.MinOA
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].DesOutAirVolFlow = state.dataSize.DataAirFlowUsedForSizing / 2.0
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].PreheatTemp = 19.0
    inputValue = AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 9405.48) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.DataDesicRegCoil = True
    state.dataSize.DataDesOutletAirTemp = 20.0
    state.dataSize.DataDesInletAirTemp = 10.0
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 7234.98) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum - 1].NumOAHeatCoils = 1
    state.dataSize.DataDesicRegCoil = False
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 6149.73) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataSize.OASysEqSizing.allocate(1)
    state.dataAirLoop.OutsideAirSys.allocate(1)
    state.dataSize.CurOASysNum = 1
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 6511.48) < 0.01
    sizer.autoSizedValue = 0.0
    state.dataAirLoop.OutsideAirSys[state.dataSize.CurOASysNum - 1].AirLoopDOASNum = 0
    state.dataAirLoopHVACDOAS.airloopDOAS.append()
    state.dataAirLoopHVACDOAS.airloopDOAS[0].HeatOutTemp = 8.0
    state.dataAirLoopHVACDOAS.airloopDOAS[0].PreheatTemp = 15.0
    inputValue = AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert sizer.wasAutoSized
    assert abs(sizedValue - 5064.49) < 0.01
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    inputValue = 7000.0
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[CoilType.HeatingWater], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert sizer.errorType == AutoSizingResultType.NoError
    assert not sizer.wasAutoSized
    assert abs(sizedValue - 7000.0) < 0.01
    sizer.autoSizedValue = 0.0
    assert not errorsFound
    eiooutput = " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Water Heating Design Coil Load for UA Sizing [W], 5064.49\n Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Water Heating Design Coil Load for UA Sizing [W], 7000.00\n"
    assert compare_eio_stream(eiooutput, True)