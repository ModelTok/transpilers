# This is a faithful 1:1 translation of CoolingCapacitySizing.unit.cc
# Mojo test file for CoolingCapacitySizing.

from AutosizingFixture import (
    AutoSizingFixture,
    process_idf,
    has_eio_output,
    compare_eio_stream,
    delimited_string,
    state,
)
from .........src.EnergyPlus.Autosizing.CoolingCapacitySizing import CoolingCapacitySizer, AutoSizingResultType
from .........src.EnergyPlus.DataEnvironment import DataEnvironment
from .........src.EnergyPlus.DataSizing import DataSizing
from .........src.EnergyPlus.Fans import Fans
from .........src.EnergyPlus.SimAirServingZones import SimAirServingZones
from .........src.EnergyPlus.DataLoopNodes import DataLoopNodes
from .........src.EnergyPlus.DataGlobals import DataGlobals
from .........src.EnergyPlus.HVAC import HVAC

# Import additional data structures used in the test
from .........src.EnergyPlus.DataAirSystems import DataAirSystems
from .........src.EnergyPlus.DataAirLoop import DataAirLoop
from .........src.EnergyPlus.DataAirLoopHVACDOAS import DataAirLoopHVACDOAS

# Note: The test uses a global state object from AutosizingFixture.
# The test function name is preserved.

def test_CoolingCapacitySizingGauntlet() raises:

    let idf_objects = delimited_string([
        "  Fan:SystemModel,",
        "    MyFan,                       !- Name",
        "    ,                            !- Availability Schedule Name",
        "    TestFanAirInletNode,         !- Air Inlet Node Name",
        "    TestFanOutletNode,           !- Air Outlet Node Name",
        "    0.2,                         !- Design Maximum Air Flow Rate",
        "    Discrete ,                   !- Speed Control Method",
        "    0.0,                         !- Electric Power Minimum Flow Rate Fraction",
        "    100.0,                       !- Design Pressure Rise",
        "    0.9 ,                        !- Motor Efficiency",
        "    1.0 ,                        !- Motor In Air Stream Fraction",
        "    AUTOSIZE,                    !- Design Electric Power Consumption",
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method",
        "    ,                            !- Electric Power Per Unit Flow Rate",
        "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure",
        "    0.50;                        !- Fan Total Efficiency",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.2
    Fans.GetFanInput(state)
    state.dataLoopNodes.Node[0].Press = 101325.0
    state.dataLoopNodes.Node[0].Temp = 24.0
    state.dataFans.fans[0].simulate(state, false, _, _)
    let routineName = "CoolingCapacitySizingGauntlet"
    state.dataSize.ZoneEqSizing.allocate(1)
    let sizer = CoolingCapacitySizer()
    var inputValue: Float64 = 5125.3
    var errorsFound = false
    var printFlag = false
    var sizedValue: Float64 = sizer.size(state, inputValue, errorsFound)
    assert_true(errorsFound)
    assert_eq(AutoSizingResultType.ErrorType2, sizer.errorType)
    assert_approx_eq(0.0, sizedValue, 0.01)  # uninitialized sizing types always return 0
    errorsFound = false
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.CurTermUnitSizingNum = 1
    state.dataSize.TermUnitSingDuct = true
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_eq(5125.3, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(true)
    printFlag = true
    state.dataSize.ZoneSizingRunDone = true
    state.dataSize.ZoneSizingInput.allocate(1)
    state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    state.dataSize.ZoneEqSizing[0].DesignSizeFromParent = true
    state.dataSize.ZoneEqSizing[0].DesCoolingLoad = sizedValue
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_eq(5125.3, sizedValue, 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[0].DesignSizeFromParent = false
    var eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Cooling Design Capacity [W], 5125.30\n")
    assert_true(compare_eio_stream(eiooutput, true))
    state.dataSize.TermUnitSizing.allocate(1)
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[0].DesCoolMassFlow = 0.2
    state.dataSize.FinalZoneSizing[0].DesCoolCoilInTemp = 24.0
    state.dataSize.FinalZoneSizing[0].DesCoolCoilInHumRat = 0.009
    state.dataSize.FinalZoneSizing[0].CoolDesTemp = 7.0
    state.dataSize.FinalZoneSizing[0].CoolDesHumRat = 0.006
    state.dataSize.FinalZoneSizing[0].ZoneRetTempAtCoolPeak = 22.0
    state.dataSize.FinalZoneSizing[0].ZoneTempAtCoolPeak = 23.0
    state.dataSize.FinalZoneSizing[0].ZoneHumRatAtCoolPeak = 0.008
    state.dataSize.ZoneEqSizing[0].ATMixerCoolPriDryBulb = 20.0
    state.dataSize.ZoneEqSizing[0].ATMixerCoolPriHumRat = 0.007
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataSize.DataWaterLoopNum = 1
    state.dataSize.DataWaterCoilSizHeatDeltaT = 5.0
    state.dataSize.TermUnitSingDuct = true
    inputValue = DataSizing.AutoSize
    sizer.zoneSizingInput.allocate(1)
    sizer.zoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4981.71, sizedValue, 0.01)
    assert_approx_eq(1.2, state.dataEnvrn.StdRhoAir, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.TermUnitSingDuct = false
    state.dataSize.ZoneEqFanCoil = true
    state.dataSize.ZoneEqSizing[0].DesCoolingLoad = 4000.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4000.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[0].DesCoolingLoad = 0.0
    state.dataSize.DataFlowUsedForSizing = state.dataSize.FinalZoneSizing[0].DesCoolMassFlow / state.dataEnvrn.StdRhoAir
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWaterHXAssisted)], "MyHXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4268.66, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.TermUnitIU = true
    state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum].DesCoolingLoad = 3500.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(3500.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqFanCoil = false
    state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.05
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4981.71, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.03
    state.dataSize.ZoneEqDXCoil = true
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(3899.81, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.0
    state.dataSize.ZoneEqSizing[0].ATMixerVolFlow = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingDXSingleSpeed)], "MyDXCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4981.71, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.0
    has_eio_output(true)
    inputValue = 5500.0
    sizer.wasAutoSized = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_eq(5500.0, sizedValue, 0.01)  # hard size value
    sizer.autoSizedValue = 0.0  # reset for next test
    assert_false(errorsFound)
    eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Cooling Design Capacity [W], 3500.00\n"
                       " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Cooling Design Capacity [W], 5500.00\n")
    assert_true(compare_eio_stream(eiooutput, true))
    eiooutput = ""
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.ZoneEqSizing.deallocate()
    state.dataSize.FinalZoneSizing.deallocate()
    state.dataSize.CurSysNum = 1
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = false
    inputValue = 2700.8
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_eq(2700.8, sizedValue, 0.0001)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    assert_true(compare_eio_stream(eiooutput, true))
    state.dataSize.SysSizingRunDone = true
    state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.SysSizInput[0].AirLoopNum = 1
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.FinalSysSizing[0].CoolSupTemp = 7.0
    state.dataSize.FinalSysSizing[0].CoolSupHumRat = 0.006
    state.dataSize.FinalSysSizing[0].MixTempAtCoolPeak = 24.0
    state.dataSize.FinalSysSizing[0].MixHumRatAtCoolPeak = 0.009
    state.dataSize.FinalSysSizing[0].RetTempAtCoolPeak = 25.0
    state.dataSize.FinalSysSizing[0].RetHumRatAtCoolPeak = 0.0085
    state.dataSize.FinalSysSizing[0].OutTempAtCoolPeak = 35.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4981.71, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    assert_true(compare_eio_stream(eiooutput, true))
    state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.02
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4981.71, sizedValue, 0.01)  # no change in capacity because coil is in air loop
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataAirSystemsData.PrimaryAirSystems[0].NumOACoolCoils = 1
    state.dataSize.FinalSysSizing[0].PrecoolTemp = 12.0
    state.dataSize.FinalSysSizing[0].PrecoolHumRat = 0.008
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4582.31, sizedValue, 0.01)  # change in capacity because precool conditions mixed with return
    sizer.autoSizedValue = 0.0  # reset for next test
    let fan1 = Fans.FanComponent()
    fan1.Name = "CONSTANT FAN 1"
    fan1.deltaPress = 600.0
    fan1.motorEff = 0.9
    fan1.totalEff = 0.6
    fan1.motorInAirFrac = 0.5
    fan1.type = HVAC.FanType.Constant
    state.dataFans.fans.append(fan1)
    state.dataFans.fanMap.insert_or_assign(fan1.Name, state.dataFans.fans.size())
    state.dataAirSystemsData.PrimaryAirSystems[0].supFanNum = Fans.GetFanIndex(state, "CONSTANT FAN 1")
    state.dataAirSystemsData.PrimaryAirSystems[0].supFanType = HVAC.FanType.Constant
    state.dataSize.DataFanPlacement = HVAC.FanPlace.BlowThru
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4740.64, sizedValue, 0.01)                               # change in capacity because precool conditions mixed with return
    assert_approx_eq(158.33, sizer.primaryAirSystem[0].FanDesCoolLoad, 0.01)  # air loop fan heat is saved in sizer class
    assert_approx_eq(state.dataSize.DataCoilSizingAirInTemp, 23.44, 0.01)     # does not include fan heat because PrimaryAirSys fan place not set
    assert_eq(1.0, state.dataSize.DataFracOfAutosizedCoolingCapacity)
    sizer.autoSizedValue = 0.0  # reset for next test
    let unScaledCapacity = sizedValue
    state.dataSize.FinalSysSizing[0].CoolingCapMethod = DataSizing.FractionOfAutosizedCoolingCapacity
    state.dataSize.FinalSysSizing[0].FractionOfAutosizedCoolingCapacity = 0.5
    state.dataAirSystemsData.PrimaryAirSystems[0].supFanPlace = HVAC.FanPlace.BlowThru
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(unScaledCapacity * 0.5, sizedValue, 0.01)                # change in capacity because precool conditions mixed with return
    assert_approx_eq(158.33, sizer.primaryAirSystem[0].FanDesCoolLoad, 0.01)  # air loop fan heat is saved in sizer class
    assert_eq(1.0, state.dataSize.DataFracOfAutosizedCoolingCapacity)         # Data global is not affected
    assert_approx_eq(state.dataSize.DataCoilSizingAirInTemp, 24.22, 0.01)     # does include fan heat because PrimaryAirSys fan place is set
    assert_eq(0.5, sizer.dataFracOfAutosizedCoolingCapacity)                  # sizer class holds fractional value
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.FinalSysSizing[0].CoolingCapMethod = DataSizing.CapacityPerFloorArea
    state.dataSize.FinalSysSizing[0].CoolingTotalCapacity = 4500.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(4500.0, sizedValue, 0.01)  # capacity precalculated and saved in FinalSysSizing[0].CoolingTotalCapacity
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.FinalSysSizing[0].CoolingCapMethod = DataSizing.CoolingDesignCapacity
    state.dataSize.FinalSysSizing[0].CoolingTotalCapacity = 3500.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(3500.0, sizedValue, 0.01)  # capacity precalculated and saved in FinalSysSizing[0].CoolingTotalCapacity
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.UnitarySysEqSizing.allocate(1)
    state.dataSize.UnitarySysEqSizing[0].CoolingCapacity = true
    state.dataSize.UnitarySysEqSizing[0].DesCoolingLoad = 2500.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(2500.0, sizedValue, 0.01)  # capacity precalculated and saved in UnitarySysEqSizing[0].DesCoolingLoad
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.UnitarySysEqSizing[0].CoolingCapacity = false
    state.dataSize.CurOASysNum = 1
    state.dataSize.OASysEqSizing.allocate(1)
    state.dataSize.OASysEqSizing[0].CoolingCapacity = true
    state.dataSize.OASysEqSizing[0].DesCoolingLoad = 1500.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(1500.0, sizedValue, 0.01)  # capacity precalculated and saved in OASysEqSizing[0].DesCoolingLoad
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.OASysEqSizing[0].CoolingCapacity = false
    state.dataAirLoop.OutsideAirSys.allocate(1)
    state.dataAirLoop.OutsideAirSys[0].AirLoopDOASNum = 0
    state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
    state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingMassFlow = 0.2
    state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingCoolOATemp = 32.0
    state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanIndex = Fans.GetFanIndex(state, "MYFAN")
    state.dataAirLoopHVACDOAS.airloopDOAS[0].FanBeforeCoolingCoilFlag = true
    state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanTypeNum = SimAirServingZones.CompType.Fan_System_Object
    state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingCoolOAHumRat = 0.009
    state.dataAirLoopHVACDOAS.airloopDOAS[0].PrecoolTemp = 12.0
    state.dataAirLoopHVACDOAS.airloopDOAS[0].PrecoolHumRat = 0.006
    state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanInletNodeNum = 1
    state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanOutletNodeNum = 2
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(5634.12, sizedValue, 0.01)  # capacity includes system fan heat
    sizer.autoSizedValue = 0.0  # reset for next test
    has_eio_output(true)
    inputValue = 4200.0
    sizer.wasAutoSized = false
    printFlag = true
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_eq(4200.0, sizedValue, 0.01)  # hard sized capacity
    sizer.autoSizedValue = 0.0  # reset for next test
    assert_false(errorsFound)
    eiooutput = String(" Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Cooling Design Capacity [W], 5634.12\n"
                       " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Cooling Design Capacity [W], 4200.00\n")
    assert_true(compare_eio_stream(eiooutput, true))
    state.dataSize.OASysEqSizing[0].CoolingCapacity = false
    state.dataAirLoop.OutsideAirSys.allocate(1)
    state.dataAirLoop.OutsideAirSys[0].AirLoopDOASNum = 0
    state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
    state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingMassFlow = 0.2
    state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingCoolOATemp = 32.0
    state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanIndex = Fans.GetFanIndex(state, "MYFAN")
    state.dataAirLoopHVACDOAS.airloopDOAS[0].FanBeforeCoolingCoilFlag = false
    state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanTypeNum = SimAirServingZones.CompType.Fan_System_Object
    state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingCoolOAHumRat = 0.009
    state.dataAirLoopHVACDOAS.airloopDOAS[0].PrecoolTemp = 12.0
    state.dataAirLoopHVACDOAS.airloopDOAS[0].PrecoolHumRat = 0.006
    state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanInletNodeNum = 1
    state.dataAirLoopHVACDOAS.airloopDOAS[0].m_FanOutletNodeNum = 2
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = false
    printFlag = false
    sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert_eq(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_eq(5633.933, sizedValue, 0.01)  # capacity includes system fan heat
    sizer.autoSizedValue = 0.0  # reset for next test
