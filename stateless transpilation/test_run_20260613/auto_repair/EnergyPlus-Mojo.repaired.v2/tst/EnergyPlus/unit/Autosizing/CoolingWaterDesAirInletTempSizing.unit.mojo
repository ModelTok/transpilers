from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream
from EnergyPlus.Autosizing.CoolingWaterDesAirInletTempSizing import CoolingWaterDesAirInletTempSizer, AutoSizingResultType
from EnergyPlus.DataAirSystems import PrimaryAirSystemsData
from EnergyPlus.DataEnvironment import EnvironData
from EnergyPlus.DataHVACGlobals import HVAC, coilTypeNames, CoilType, FanType, FanPlace
from EnergyPlus.DataSizing import DataSizing, ZoneEqSizingData, FinalZoneSizingData, FinalSysSizingData, SysSizInputData, OASysEqSizingData
from EnergyPlus.Fans import Fans, FanComponent, GetFanIndex
from EnergyPlus.DataAirLoop import OutsideAirSysData, airloopDOASData
from EnergyPlus.DataHVACDOAS import HVACDOASData
from memory import allocate

@test
def test_CoolingWaterDesAirInletTempSizingGauntlet():
    var fixture = AutoSizingFixture()
    var state = fixture.state
    state.dataSize.ZoneEqSizing = ZoneEqSizingData[1]()
    state.dataEnvrn.StdRhoAir = 1.2
    var routineName: StringLiteral = "CoolingWaterDesAirInletTempSizingGauntlet"
    var sizer = CoolingWaterDesAirInletTempSizer()
    var inputValue: Float64 = 23.7
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(state, inputValue, errorsFound)
    assert_true(errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.ErrorType2)
    assert_approx_equal(0.0, sizedValue, 0.01)  // uninitialized sizing types always return 0
    errorsFound = False
    state.dataSize.CurZoneEqNum = 1
    has_eio_output(True)
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(23.7, sizedValue, 0.001)  // hard-sized value
    sizer.autoSizedValue = 0.0  // reset for next test
    var eiooutput: String = ""
    assert_true(compare_eio_stream(eiooutput, True))
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(23.7, sizedValue, 0.001)  // hard-sized value
    sizer.autoSizedValue = 0.0  // reset for next test
    eiooutput = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n" + \
                " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Inlet Air Temperature [C], 23.7000\n"
    assert_true(compare_eio_stream(eiooutput, True))
    has_eio_output(True)
    state.dataSize.FinalZoneSizing = FinalZoneSizingData[1]()
    state.dataSize.ZoneEqSizing = ZoneEqSizingData[1]()
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneTempAtCoolPeak = 21.77
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolCoilInTemp = 22.88
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolMassFlow = 0.01
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].OutTempAtCoolPeak = 29.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneRetTempAtCoolPeak = 23.9
    state.dataSize.ZoneSizingInput = ZoneSizingInputData[1]()
    state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum - 1].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(22.88, sizedValue, 0.0001)
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Inlet Air Temperature [C], 22.8800\n"
    assert_true(compare_eio_stream(eiooutput, True))
    state.dataSize.TermUnitSingDuct = False
    state.dataSize.TermUnitPIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(22.88, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.TermUnitPIU = False
    state.dataSize.TermUnitIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(21.77, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0  // reset for next test
    var fan1 = FanComponent()
    fan1.Name = "CONSTANT FAN 1"
    fan1.deltaPress = 600.0
    fan1.motorEff = 0.9
    fan1.totalEff = 0.6
    fan1.motorInAirFrac = 0.5
    fan1.type = HVAC.FanType.constant
    state.dataFans.fans.append(fan1)
    state.dataFans.fanMap.insert_or_assign(fan1.Name, len(state.dataFans.fans) - 1 + 1)  # 1-based index
    state.dataSize.DataFanIndex = GetFanIndex(state, "CONSTANT FAN 1")
    state.dataSize.DataFanType = HVAC.FanType.constant
    state.dataSize.DataFanPlacement = HVAC.FanPlace.blowThru
    state.dataSize.DataDesInletAirHumRat = 0.008
    state.dataSize.DataAirFlowUsedForSizing = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolMassFlow
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(22.5464, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.DataFanIndex = 0
    state.dataSize.TermUnitIU = False
    state.dataSize.ZoneEqFanCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(21.77, sizedValue, 0.0001)  // no fan heat since DataFanInext = -1
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.ZoneEqSizing[0].OAVolFlow = \
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolMassFlow / (10.0 * state.dataEnvrn.StdRhoAir)
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    var mixedTemp: Float64 = 0.9 * 21.77 + 0.1 * 29.0  // 90% of ZoneTempAtCoolPeak, 10% of OutTempAtCoolPeak
    assert_approx_equal(mixedTemp, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.ZoneEqSizing[0].ATMixerCoolPriDryBulb = 17.4
    state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.002 / state.dataEnvrn.StdRhoAir  // AT mass flow smaller than DesCoolMassFlow by factor of 5
    var mixedTemp2: Float64 = 0.8 * 23.9 + 0.2 * 17.4  // 80% of ZoneHumRatAtCoolPeak, 20% of ATMixerCoolPriDryBulb
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(mixedTemp2, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.ZoneEqFanCoil = False
    has_eio_output(True)
    eiooutput = ""
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.ZoneEqSizing.deallocate()
    state.dataSize.FinalZoneSizing.deallocate()
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataAirSystemsData.PrimaryAirSystems = PrimaryAirSystemsData[1]()
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 18.0
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(18.0, sizedValue, 0.0001)  // hard-sized value
    sizer.autoSizedValue = 0.0  // reset for next test
    assert_true(compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing = FinalSysSizingData[1]()
    state.dataSize.SysSizInput = SysSizInputData[1]()
    state.dataSize.SysSizInput[0].AirLoopNum = 1
    state.dataSize.FinalSysSizing[0].MixTempAtCoolPeak = 20.15
    state.dataSize.FinalSysSizing[0].RetTempAtCoolPeak = 24.11
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].OutTempAtCoolPeak = 27.88
    inputValue = DataSizing.AutoSize
    state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum - 1].NumOACoolCoils = 1
    state.dataSize.DataDesInletAirTemp = 19.155
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(19.155, sizedValue, 0.001)
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.DataDesInletAirTemp = 0.0
    state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum - 1].NumOACoolCoils = 0
    state.dataSize.DataDesInletAirTemp = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(20.15, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  // reset for next test
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Inlet Air Temperature [C], 20.1500\n"
    assert_true(compare_eio_stream(eiooutput, True))
    state.dataAirSystemsData.PrimaryAirSystems[state.dataSize.CurSysNum - 1].NumOACoolCoils = 1
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].PrecoolTemp = 12.21
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(12.21, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].DesOutAirVolFlow = 0.01
    state.dataSize.DataFlowUsedForSizing = 0.1  // system volume flow
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(22.92, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.OASysEqSizing = OASysEqSizingData[1]()
    state.dataAirLoop.OutsideAirSys = OutsideAirSysData[1]()
    state.dataSize.CurOASysNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    var outAirTemp: Float64 = state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].OutTempAtCoolPeak
    assert_approx_equal(outAirTemp, sizedValue, 0.00001)
    sizer.autoSizedValue = 0.0  // reset for next test
    state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.0
    state.dataAirLoop.OutsideAirSys[0].AirLoopDOASNum = 0
    state.dataAirLoopHVACDOAS.airloopDOAS = airloopDOASData(1)
    state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingCoolOATemp = 27.44
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(27.44, sizedValue, 0.00001)  // DOAS system hum rat
    sizer.autoSizedValue = 0.0  // reset for next test
    has_eio_output(True)
    inputValue = 24.44  // value not previously used
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.coolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_equal(sizer.errorType, AutoSizingResultType.NoError)  // cumulative of previous calls
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(inputValue, sizedValue, 0.01)  // hard-sized value
    sizer.autoSizedValue = 0.0  // reset for next test
    assert_false(errorsFound)
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Inlet Air Temperature [C], 27.4400\n" + \
                " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Inlet Air Temperature [C], 24.4400\n"
    assert_true(compare_eio_stream(eiooutput, True))
    sizer.clearState()