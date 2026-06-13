module EnergyPlus:

from AutosizingFixture import AutoSizingFixture
from .........src.EnergyPlus.Autosizing.CoolingWaterDesAirOutletTempSizing import CoolingWaterDesAirOutletTempSizer
from .........src.EnergyPlus.DataAirSystems import PrimaryAirSystems, OutsideAirSysStruct
from .........src.EnergyPlus.DataEnvironment import DataEnvironment
from .........src.EnergyPlus.DataHVACGlobals import HVAC
from .........src.EnergyPlus.DataSizing import (
    AutoSizingResultType,
    DataSizing,
    ZoneEqSizingStruct,
    FinalZoneSizingStruct,
    PlantSizDataStruct,
    ZoneSizingInputStruct,
    FinalSysSizingStruct,
    SysSizInputStruct,
    OASysEqSizingStruct,
)
from .........src.EnergyPlus.Fans import Fans, FanComponent
from .........src.EnergyPlus.FluidProperties import Fluid
from .........src.EnergyPlus.DataPlant import PlantLoopStruct
from .........src.EnergyPlus.DataAirLoop import OutsideAirSys, AirLoopDOASStruct

def CoolingWaterDesAirOutletTempSizingGauntlet(inout fixture: AutoSizingFixture) raises:
    var state = fixture.state
    state.dataFluid.init_state(state)
    state.dataSize.ZoneEqSizing = list[ZoneEqSizingStruct]()
    state.dataSize.ZoneEqSizing.append(ZoneEqSizingStruct())  # allocate 1
    state.dataEnvrn.StdRhoAir = 1.2
    var routineName: StringLiteral = "CoolingWaterDesAirInletTempSizingGauntlet"
    var sizer = CoolingWaterDesAirOutletTempSizer()
    var inputValue: Float64 = 13.7
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(state, inputValue, errorsFound)
    assert(errorsFound)
    assert(sizer.errorType == AutoSizingResultType.ErrorType2)
    assert(abs(sizedValue - 0.0) <= 0.01)  # uninitialized sizing types always return 0
    errorsFound = False
    state.dataSize.CurZoneEqNum = 0  # 1-based -> 0-based
    fixture.has_eio_output(True)
    var coilTypeName = HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)]
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(not sizer.wasAutoSized)
    assert(abs(sizedValue - 13.7) <= 0.001)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    var eiooutput: String = String("")
    assert(fixture.compare_eio_stream(eiooutput, True))
    printFlag = True
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(not sizer.wasAutoSized)
    assert(abs(sizedValue - 13.7) <= 0.001)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    eiooutput = String(
        "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Outlet Air Temperature [C], 13.7000\n"
    )
    assert(fixture.compare_eio_stream(eiooutput, True))
    fixture.has_eio_output(True)
    state.dataSize.FinalZoneSizing = list[FinalZoneSizingStruct]()
    state.dataSize.FinalZoneSizing.append(FinalZoneSizingStruct())  # allocate 1
    state.dataSize.ZoneEqSizing = list[ZoneEqSizingStruct]()
    state.dataSize.ZoneEqSizing.append(ZoneEqSizingStruct())  # allocate 1
    state.dataPlnt.PlantLoop = list[PlantLoopStruct]()
    state.dataPlnt.PlantLoop.append(PlantLoopStruct())  # allocate 1
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.PlantSizData = list[PlantSizDataStruct]()
    state.dataSize.PlantSizData.append(PlantSizDataStruct())  # allocate 1
    state.dataSize.PlantSizData[0].ExitTemp = 7.0
    state.dataSize.DataPltSizCoolNum = 1
    state.dataSize.DataDesInletWaterTemp = 7.0
    state.dataSize.FinalZoneSizing[0].CoolDesTemp = 12.88
    state.dataSize.ZoneSizingInput = list[ZoneSizingInputStruct]()
    state.dataSize.ZoneSizingInput.append(ZoneSizingInputStruct())  # allocate 1
    # CurZoneEqNum = 0 already, used as index into ZoneSizingInput
    state.dataSize.ZoneSizingInput[0].ZoneNum = 0  # because CurZoneEqNum is 0
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 12.88) <= 0.0001)
    eiooutput = String(
        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Outlet Air Temperature [C], 12.8800\n"
    )
    assert(fixture.compare_eio_stream(eiooutput, True))
    state.dataSize.TermUnitSingDuct = False
    state.dataSize.TermUnitPIU = True
    state.dataSize.DataAirFlowUsedForSizing = 0.2
    state.dataSize.DataWaterFlowUsedForSizing = 0.0001
    state.dataSize.DataWaterCoilSizCoolDeltaT = 5.0
    state.dataSize.DataDesInletAirTemp = 23.0
    state.dataSize.DataDesInletAirHumRat = 0.007
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 12.88) <= 0.0001)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.TermUnitPIU = False
    state.dataSize.TermUnitIU = True
    state.dataSize.DataWaterLoopNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 14.408) <= 0.001)
    sizer.autoSizedValue = 0.0  # reset for next test
    var fan1 = Fans.FanComponent()
    fan1.Name = "CONSTANT FAN 1"
    fan1.deltaPress = 100.0
    fan1.motorEff = 0.9
    fan1.totalEff = 0.6
    fan1.motorInAirFrac = 0.1
    fan1.type = HVAC.FanType.Constant
    state.dataFans.fans.append(fan1)
    state.dataFans.fanMap[fan1.Name] = state.dataFans.fans.size()  # 1-based index as in C++
    state.dataSize.DataFanIndex = Fans.GetFanIndex(state, "CONSTANT FAN 1")
    state.dataSize.DataFanType = HVAC.FanType.Constant
    state.dataSize.DataFanPlacement = HVAC.FanPlace.DrawThru
    state.dataSize.DataDesInletAirHumRat = 0.008
    state.dataSize.DataAirFlowUsedForSizing = 0.24
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 15.729) <= 0.001)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.DataFanIndex = 0
    state.dataSize.TermUnitIU = False
    state.dataSize.ZoneEqFanCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 12.88) <= 0.0001)  # no fan heat since DataFanIndex = -1 (0 in 0-based)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.DataDesInletWaterTemp = 13.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - (state.dataSize.DataDesInletWaterTemp + 0.5)) <= 0.0001)  # 0.5 C above inlet water temp
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.DataDesInletWaterTemp = 7.0
    fixture.has_eio_output(True)
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.NumZoneSizingInput = 0
    state.dataSize.ZoneEqSizing = list[ZoneEqSizingStruct]()
    state.dataSize.FinalZoneSizing = list[FinalZoneSizingStruct]()
    state.dataSize.CurSysNum = 0  # 1-based -> 0-based
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataAirSystemsData.PrimaryAirSystems = list[PrimaryAirSystems]()
    state.dataAirSystemsData.PrimaryAirSystems.append(PrimaryAirSystems())  # allocate 1
    state.dataSize.NumSysSizInput = 1
    state.dataSize.SysSizingRunDone = False
    inputValue = 14.0
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(not sizer.wasAutoSized)
    assert(abs(sizedValue - 14.0) <= 0.0001)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    eiooutput = String("")
    assert(fixture.compare_eio_stream(eiooutput, True))
    state.dataSize.SysSizingRunDone = True
    state.dataSize.FinalSysSizing = list[FinalSysSizingStruct]()
    state.dataSize.FinalSysSizing.append(FinalSysSizingStruct())  # allocate 1
    state.dataSize.SysSizInput = list[SysSizInputStruct]()
    state.dataSize.SysSizInput.append(SysSizInputStruct())  # allocate 1
    state.dataSize.SysSizInput[0].AirLoopNum = 1
    state.dataSize.FinalSysSizing[0].CoolSupTemp = 12.15
    state.dataSize.FinalSysSizing[0].OutTempAtCoolPeak = 27.88
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 12.15) <= 0.01)
    sizer.autoSizedValue = 0.0  # reset for next test
    eiooutput = String(
        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Outlet Air Temperature [C], 12.1500\n"
    )
    assert(fixture.compare_eio_stream(eiooutput, True))
    state.dataAirSystemsData.PrimaryAirSystems[0].supFanPlace = HVAC.FanPlace.DrawThru
    state.dataSize.DataFanIndex = Fans.GetFanIndex(state, "CONSTANT FAN 1")
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 12.026) <= 0.001)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataAirSystemsData.PrimaryAirSystems[0].NumOACoolCoils = 1
    state.dataSize.FinalSysSizing[0].PrecoolTemp = 12.21
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 12.026) <= 0.0001)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.DataDesOutletAirTemp = 10.6
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 10.476) <= 0.001)  # includes impact of fan heat
    assert(sizedValue < state.dataSize.DataDesOutletAirTemp)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.OASysEqSizing = list[OASysEqSizingStruct]()
    state.dataSize.OASysEqSizing.append(OASysEqSizingStruct())  # allocate 1
    state.dataAirLoop.OutsideAirSys = list[OutsideAirSysStruct]()
    state.dataAirLoop.OutsideAirSys.append(OutsideAirSysStruct())  # allocate 1
    state.dataSize.CurOASysNum = 0  # 1-based -> 0-based
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    var outAirTemp: Float64 = state.dataSize.FinalSysSizing[0].PrecoolTemp
    assert(abs(sizedValue - outAirTemp) <= 0.00001)
    sizer.autoSizedValue = 0.0  # reset for next test
    state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.0
    state.dataAirLoop.OutsideAirSys[0].AirLoopDOASNum = 0
    state.dataAirLoopHVACDOAS.airloopDOAS.append(AirLoopDOASStruct())
    state.dataAirLoopHVACDOAS.airloopDOAS[0].PrecoolTemp = 11.44
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - 11.44) <= 0.00001)  # DOAS system hum rat
    sizer.autoSizedValue = 0.0  # reset for next test
    fixture.has_eio_output(True)
    inputValue = 14.44  # value not previously used
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(not sizer.wasAutoSized)
    assert(abs(sizedValue - inputValue) <= 0.01)  # hard-sized value
    sizer.autoSizedValue = 0.0  # reset for next test
    assert(not errorsFound)  # cumulative of previous calls
    eiooutput = String(
        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Outlet Air Temperature [C], 11.4400\n"
        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Outlet Air Temperature [C], 14.4400\n"
    )
    assert(fixture.compare_eio_stream(eiooutput, True))
    state.dataSize.DataDesInletWaterTemp = 12.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(state, coilTypeName, "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(state, inputValue, errorsFound)
    assert(sizer.errorType == AutoSizingResultType.NoError)
    assert(sizer.wasAutoSized)
    assert(abs(sizedValue - (state.dataSize.DataDesInletWaterTemp + 0.5)) <= 0.01)  # 0.5 C above water temp
    sizer.autoSizedValue = 0.0  # reset for next test
    sizer.clearState()