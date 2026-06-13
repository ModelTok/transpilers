from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream
from Autosizing.CoolingWaterflowSizing import CoolingWaterflowSizer, AutoSizingResultType
from DataEnvironment import *
from DataHVACGlobals import *
from DataSizing import DataSizing
from Fans import Fans
from FluidProperties import Fluid
from testing import assert_true, assert_false, assert_equal, assert_approx_equal

def CoolingWaterflowSizingGauntlet[this: AutoSizingFixture]():
    this.state.dataFluid.init_state(this.state)
    this.state.dataEnvrn.StdRhoAir = 1.2
    this.state.dataSize.ZoneEqSizing.allocate(1)
    let routineName: StringLiteral = "CoolingWaterflowSizingGauntlet"
    var sizer: CoolingWaterflowSizer
    var inputValue: Float64 = 5.0
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(this.state, inputValue, errorsFound)
    assert_true(errorsFound)
    assert_equal(AutoSizingResultType.ErrorType2, sizer.errorType)
    assert_approx_equal(0.0, sizedValue, 0.01)
    errorsFound = False
    inputValue = 5.0
    this.state.dataSize.CurZoneEqNum = 1
    this.state.dataSize.CurTermUnitSizingNum = 1
    this.state.dataSize.TermUnitSingDuct = True
    this.state.dataSize.TermUnitSizing.allocate(1)
    this.state.dataSize.TermUnitSizing[0].MaxCWVolFlow = 0.005
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(5.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0
    this.state.dataSize.DataWaterLoopNum = 1
    this.state.dataPlnt.PlantLoop.allocate(1)
    this.state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(this.state)
    this.state.dataSize.DataWaterCoilSizCoolDeltaT = 10.0
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(5.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(5.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0
    var eiooutput: String = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"\
        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Water Flow Rate [m3/s], 5.00000\n"
    assert_true(compare_eio_stream(eiooutput, True))
    has_eio_output(True)
    this.state.dataSize.FinalZoneSizing.allocate(1)
    this.state.dataSize.ZoneEqSizing.allocate(1)
    this.state.dataSize.ZoneEqSizing[0].MaxCWVolFlow = 0.3
    this.state.dataSize.FinalZoneSizing[0].DesCoolMassFlow = 0.3
    this.state.dataSize.FinalZoneSizing[0].CoolDesTemp = 12.0
    this.state.dataSize.FinalZoneSizing[0].CoolDesHumRat = 0.006
    this.state.dataSize.FinalZoneSizing[0].DesCoolCoilInTemp = 25.0
    this.state.dataSize.FinalZoneSizing[0].DesCoolCoilInHumRat = 0.009
    this.state.dataSize.ZoneSizingRunDone = True
    this.state.dataSize.TermUnitSingDuct = True
    inputValue = DataSizing.AutoSize
    this.state.dataSize.ZoneSizingInput.allocate(1)
    this.state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.000149, sizedValue, 0.000001)
    assert_approx_equal(1.2, this.state.dataEnvrn.StdRhoAir, 0.01)
    var previousWaterFlow: Float64 = sizedValue
    sizer.autoSizedValue = 0.0
    sizedValue = 0.0
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Water Flow Rate [m3/s], 0.000149018\n"
    assert_true(compare_eio_stream(eiooutput, True))
    var fan1: Fans.FanComponent = Fans.FanComponent()
    fan1.Name = "CONSTANT FAN 1"
    fan1.deltaPress = 600.0
    fan1.motorEff = 0.9
    fan1.totalEff = 0.6
    fan1.motorInAirFrac = 0.5
    fan1.type = HVAC.FanType.Constant
    this.state.dataFans.fans.append(fan1)
    this.state.dataFans.fanMap.insert_or_assign(fan1.Name, this.state.dataFans.fans.size())
    this.state.dataSize.DataFanIndex = Fans.GetFanIndex(this.state, "CONSTANT FAN 1")
    this.state.dataSize.DataFanType = HVAC.FanType.Constant
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.000154, sizedValue, 0.000001)
    assert_true(sizedValue > previousWaterFlow)
    var desVolFlow: Float64 = this.state.dataSize.FinalZoneSizing[this.state.dataSize.CurZoneEqNum].DesCoolMassFlow / this.state.dataEnvrn.StdRhoAir
    var desFanHeat: Float64 = sizer.calcFanDesHeatGain(desVolFlow)
    assert_false(sizer.fanCompModel)
    assert_approx_equal(237.5, desFanHeat, 0.001)
    var fanPowerTot: Float64 = (desVolFlow * 600.0) / 0.6
    var designFanHeatGain: Float64 = 0.9 * fanPowerTot + (fanPowerTot - 0.9 * fanPowerTot) * 0.5
    assert_approx_equal(designFanHeatGain, desFanHeat, 0.0001)
    this.state.dataSize.TermUnitSingDuct = False
    this.state.dataSize.TermUnitPIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.000154, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0
    this.state.dataSize.TermUnitPIU = False
    this.state.dataSize.TermUnitIU = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.005, sizedValue, 0.0001)
    assert_approx_equal(this.state.dataSize.TermUnitSizing[0].MaxCWVolFlow, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    this.state.dataSize.TermUnitIU = False
    this.state.dataSize.ZoneEqFanCoil = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.3, sizedValue, 0.0001)
    assert_approx_equal(this.state.dataSize.ZoneEqSizing[0].MaxCWVolFlow, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    this.state.dataSize.ZoneEqFanCoil = False
    this.state.dataSize.ZoneEqUnitVent = True
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.3, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0
    this.state.dataSize.ZoneEqUnitVent = False
    this.state.dataSize.DataWaterCoilSizCoolDeltaT = 5.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.000309, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    has_eio_output(True)
    eiooutput = ""
    this.state.dataSize.CurZoneEqNum = 0
    this.state.dataSize.NumZoneSizingInput = 0
    this.state.dataSize.CurTermUnitSizingNum = 0
    this.state.dataSize.ZoneEqSizing.deallocate()
    this.state.dataSize.FinalZoneSizing.deallocate()
    this.state.dataSize.CurSysNum = 1
    this.state.dataHVACGlobal.NumPrimaryAirSys = 1
    this.state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    this.state.dataSize.NumSysSizInput = 1
    this.state.dataSize.SysSizingRunDone = False
    this.state.dataSize.DataCapacityUsedForSizing = 5000.0
    inputValue = 5.0
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(5.0, sizedValue, 0.01)
    sizer.autoSizedValue = 0.0
    assert_true(compare_eio_stream(eiooutput, True))
    this.state.dataSize.SysSizingRunDone = True
    this.state.dataSize.FinalSysSizing.allocate(1)
    this.state.dataSize.SysSizInput.allocate(1)
    this.state.dataSize.SysSizInput[0].AirLoopNum = 1
    this.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 5.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_true(sizer.wasAutoSized)
    assert_approx_equal(0.000238, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Water Flow Rate [m3/s], 0.000238237\n"
    assert_true(compare_eio_stream(eiooutput, True))
    has_eio_output(True)
    eiooutput = ""
    this.state.dataSize.CurOASysNum = 1
    this.state.dataSize.OASysEqSizing.allocate(1)
    inputValue = 0.0002
    printFlag = True
    errorsFound = False
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(this.state, HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(this.state, inputValue, errorsFound)
    assert_equal(AutoSizingResultType.NoError, sizer.errorType)
    assert_false(sizer.wasAutoSized)
    assert_approx_equal(0.0002, sizedValue, 0.000001)
    sizer.autoSizedValue = 0.0
    assert_false(errorsFound)
    eiooutput = " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, Design Size Design Water Flow Rate [m3/s], 0.000476474\n"\
        " Component Sizing Information, Coil:Cooling:Water, MyWaterCoil, User-Specified Design Water Flow Rate [m3/s], 0.000200000\n"
    assert_true(compare_eio_stream(eiooutput, True))
    sizer.clearState()