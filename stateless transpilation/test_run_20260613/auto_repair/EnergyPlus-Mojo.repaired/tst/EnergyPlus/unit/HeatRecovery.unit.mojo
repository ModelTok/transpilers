# Faithful 1:1 conversion of HeatRecovery.unit.cc to Mojo

from EnergyPlus.DataAirLoop import *
from Fixtures.EnergyPlusFixture import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.Fans import *
from EnergyPlus.HeatRecovery import *
from EnergyPlus.IOFiles import *
from EnergyPlus.MixedAir import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ReturnAirPathManager import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimAirServingZones import *
from EnergyPlus.SimulationManager import *
# Global state (simulate the fixture)
var state: EnergyPlusData = EnergyPlusData()
# We'll also need a test runner: for simplicity, we'll define a function "run_tests" and call each test.

# -----------------------------------------------------------------------------
# Helper to approximate double equality (since Mojo doesn't have EXPECT_DOUBLE_EQ)
def assert_approx_equal(actual: Float64, expected: Float64, eps: Float64 = 1e-12) raises:
    if abs(actual - expected) > eps:
        raise Error("assert_approx_equal failed: " + str(actual) + " != " + str(expected) + " (eps=" + str(eps) + ")")

# -----------------------------------------------------------------------------
# Test: HeatRecovery_HRTest
def HeatRecovery_HRTest() raises:
    state.init_state(state)
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 0
    state.dataSize.CurOASysNum = 0
    state.dataHeatRecovery.NumHeatExchangers = 1
    state.dataHeatRecovery.ExchCond.allocate(state.dataHeatRecovery.NumHeatExchangers)
    state.dataLoopNodes.Node.allocate(4)
    state.dataEnvrn.OutBaroPress = 101325.0
    var ExchNum: Int = 1
    var CompanionCoilNum: Int = 0
    var HXUnitOn: Bool = false
    var FirstHVACIteration: Bool = false
    var EconomizerFlag: Bool = false
    var HighHumCtrlFlag: Bool = false
    var fanOp: HVAC.FanOp = HVAC.FanOp.Continuous  # 1 = cycling fan, 2 = constant fan
    var Toutlet: Float64 = 0.0
    var Tnode: Float64 = 0.0
    var SetPointTemp: Float64 = 19.0
    var PartLoadRatio: Float64 = 0.25
    var BalDesDehumPerfDataIndex: Int = 1
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 0
    state.dataSize.CurOASysNum = 0
    state.dataHeatRecovery.ExchCond[ExchNum].NomSupAirVolFlow = 1.0
    state.dataHeatRecovery.ExchCond[ExchNum].SupInMassFlow = 1.0
    state.dataHeatRecovery.ExchCond[ExchNum].SecInMassFlow = 1.0
    state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode = 1
    state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode = 2
    state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode = 3
    state.dataHeatRecovery.ExchCond[ExchNum].SecOutletNode = 4
    state.dataHeatRecovery.ExchCond[ExchNum].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataHeatRecovery.ExchCond[ExchNum].HeatEffectSensible100 = 0.75
    state.dataHeatRecovery.ExchCond[ExchNum].HeatEffectLatent100 = 0.0
    state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectSensible100 = 0.75
    state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectLatent100 = 0.0
    state.dataHeatRecovery.ExchCond[ExchNum].HeatEffectSensibleCurveIndex = 0
    state.dataHeatRecovery.ExchCond[ExchNum].HeatEffectLatentCurveIndex = 0
    state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectSensibleCurveIndex = 0
    state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectLatentCurveIndex = 0
    state.dataHeatRecovery.ExchCond[ExchNum].Name = "Test Heat Recovery 1"
    state.dataHeatRecovery.ExchCond[ExchNum].type = HVAC.HXType.AirToAir_SensAndLatent
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HeatRecovery.HXExchConfigType.Rotary
    state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp = 24.0
    state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp = 15.0
    state.dataHeatRecovery.ExchCond[ExchNum].SupInHumRat = 0.01
    state.dataHeatRecovery.ExchCond[ExchNum].SecInHumRat = 0.01
    state.dataHeatRecovery.ExchCond[ExchNum].SupInEnth = PsyHFnTdbW(
        state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp,
        state.dataHeatRecovery.ExchCond[ExchNum].SupInHumRat)
    state.dataHeatRecovery.ExchCond[ExchNum].SecInEnth = PsyHFnTdbW(
        state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp,
        state.dataHeatRecovery.ExchCond[ExchNum].SecInHumRat)
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].Temp = state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].Temp = state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].HumRat = state.dataHeatRecovery.ExchCond[ExchNum].SupInHumRat
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].HumRat = state.dataHeatRecovery.ExchCond[ExchNum].SecInHumRat
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].Enthalpy = state.dataHeatRecovery.ExchCond[ExchNum].SupInEnth
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].Enthalpy = state.dataHeatRecovery.ExchCond[ExchNum].SecInEnth
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].MassFlowRate = state.dataHeatRecovery.ExchCond[ExchNum].SupInMassFlow
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].MassFlowRate = state.dataHeatRecovery.ExchCond[ExchNum].SecInMassFlow
    state.dataHeatRecovery.ExchCond[ExchNum].NumericFieldNames.allocate(5)
    state.dataHeatRecovery.BalDesDehumPerfData.allocate(BalDesDehumPerfDataIndex)
    state.dataHeatRecovery.BalDesDehumPerfData[BalDesDehumPerfDataIndex].NumericFieldNames.allocate(2)
    var thisHX = state.dataHeatRecovery.ExchCond[ExchNum]
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    Toutlet = state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp
    Tnode = state.dataHeatRecovery.ExchCond[ExchNum].SupOutTemp
    assert_approx_equal(Toutlet, Tnode)
    state.dataHeatRecovery.ExchCond[ExchNum].ControlToTemperatureSetPoint = false
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].TempSetPoint = SetPointTemp
    HXUnitOn = true
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HXExchConfigType.Plate
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    Toutlet = (state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp +
               (state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectSensible100 *
                (state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp - state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp)))
    Tnode = state.dataHeatRecovery.ExchCond[ExchNum].SupOutTemp
    assert_approx_equal(Toutlet, Tnode)
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HXExchConfigType.Rotary
    HXUnitOn = true
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    Toutlet = (state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp +
               (state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectSensible100 *
                (state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp - state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp)))
    Tnode = state.dataHeatRecovery.ExchCond[ExchNum].SupOutTemp
    assert_approx_equal(Toutlet, Tnode)
    state.dataHeatRecovery.ExchCond[ExchNum].ControlToTemperatureSetPoint = true
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].TempSetPoint = 19.0
    HXUnitOn = true
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HXExchConfigType.Plate
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    Toutlet = SetPointTemp
    Tnode = state.dataHeatRecovery.ExchCond[ExchNum].SupOutTemp
    assert_approx_equal(Toutlet, Tnode)
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HXExchConfigType.Rotary
    HXUnitOn = true
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    Toutlet = state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].TempSetPoint
    Tnode = state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].Temp
    assert_approx_equal(Toutlet, Tnode)
    state.dataHeatRecovery.ExchCond[ExchNum].Name = "Test Heat Recovery 2"
    state.dataHeatRecovery.ExchCond[ExchNum].type = HVAC.HXType.AirToAir_SensAndLatent
    state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp = 15.0
    state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp = 24.0
    state.dataHeatRecovery.ExchCond[ExchNum].SupInHumRat = 0.01
    state.dataHeatRecovery.ExchCond[ExchNum].SecInHumRat = 0.01
    state.dataHeatRecovery.ExchCond[ExchNum].SupInEnth = PsyHFnTdbW(
        state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp,
        state.dataHeatRecovery.ExchCond[ExchNum].SupInHumRat)
    state.dataHeatRecovery.ExchCond[ExchNum].SecInEnth = PsyHFnTdbW(
        state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp,
        state.dataHeatRecovery.ExchCond[ExchNum].SecInHumRat)
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].Temp = state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].Temp = state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].HumRat = state.dataHeatRecovery.ExchCond[ExchNum].SupInHumRat
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].HumRat = state.dataHeatRecovery.ExchCond[ExchNum].SecInHumRat
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].Enthalpy = state.dataHeatRecovery.ExchCond[ExchNum].SupInEnth
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].Enthalpy = state.dataHeatRecovery.ExchCond[ExchNum].SecInEnth
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].MassFlowRate = state.dataHeatRecovery.ExchCond[ExchNum].SupInMassFlow
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].MassFlowRate = state.dataHeatRecovery.ExchCond[ExchNum].SecInMassFlow
    HXUnitOn = false
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    assert_approx_equal(state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp,
                         state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].Temp)
    state.dataHeatRecovery.ExchCond[ExchNum].ControlToTemperatureSetPoint = false
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].TempSetPoint = 19.0
    HXUnitOn = true
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HXExchConfigType.Plate
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    assert_approx_equal((state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp +
                          (state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectSensible100 *
                           (state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp - state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp))),
                         state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].Temp)
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HXExchConfigType.Rotary
    HXUnitOn = true
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    assert_approx_equal((state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp +
                          (state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectSensible100 *
                           (state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp - state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp))),
                         state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].Temp)
    state.dataHeatRecovery.ExchCond[ExchNum].ControlToTemperatureSetPoint = true
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].TempSetPoint = 19.0
    HXUnitOn = true
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HXExchConfigType.Plate
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    assert_approx_equal(state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].TempSetPoint,
                         state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].Temp)
    state.dataHeatRecovery.ExchCond[ExchNum].ExchConfig = HXExchConfigType.Rotary
    HXUnitOn = true
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag)
    thisHX.UpdateHeatRecovery(state)
    assert_approx_equal(state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].TempSetPoint,
                         state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].Temp)
    fanOp = HVAC.FanOp.Cycling
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupInletNode].MassFlowRate = state.dataHeatRecovery.ExchCond[ExchNum].SupInMassFlow / 4.0
    state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SecInletNode].MassFlowRate = state.dataHeatRecovery.ExchCond[ExchNum].SecInMassFlow / 4.0
    state.dataHeatRecovery.ExchCond[ExchNum].ControlToTemperatureSetPoint = false
    thisHX.initialize(state, CompanionCoilNum, HVAC.CoilType.Invalid)
    thisHX.CalcAirToAirGenericHeatExch(state, HXUnitOn, FirstHVACIteration, fanOp, EconomizerFlag, HighHumCtrlFlag, PartLoadRatio)
    thisHX.UpdateHeatRecovery(state)
    assert_approx_equal((state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp +
                          (state.dataHeatRecovery.ExchCond[ExchNum].CoolEffectSensible100 *
                           (state.dataHeatRecovery.ExchCond[ExchNum].SecInTemp - state.dataHeatRecovery.ExchCond[ExchNum].SupInTemp))),
                         state.dataLoopNodes.Node[state.dataHeatRecovery.ExchCond[ExchNum].SupOutletNode].Temp)

# -----------------------------------------------------------------------------
# Test: HeatRecoveryHXOnManinBranch_GetInputTest
def HeatRecoveryHXOnManinBranch_GetInputTest() raises:
    var idf_objects: String = delimited_string({
        " Coil:Cooling:Water,",
        "	AHU cooling coil,	!- Name",
        "	AvailSched,			!- Availability Schedule Name",
        "	autosize,			!- Design Water Flow Rate { m3 / s }",
        "	autosize,			!- Design Air Flow Rate { m3 / s }",
        "	autosize,			!- Design Inlet Water Temperature { C }",
        "	autosize,			!- Design Inlet Air Temperature { C }",
        "	autosize,			!- Design Outlet Air Temperature { C }",
        "	autosize,			!- Design Inlet Air Humidity Ratio { kgWater / kgDryAir }",
        "	autosize,			!- Design Outlet Air Humidity Ratio { kgWater / kgDryAir }",
        "	Water Inlet Node,	!- Water Inlet Node Name",
        "	Water Outlet Node,  !- Water Outlet Node Name",
        "	AHU mixed air outlet,		!- Air Inlet Node Name",
        "	AHU cooling coil outlet,	!- Air Outlet Node Name",
        "	SimpleAnalysis,		!- Type of Analysis",
        "	CrossFlow;          !- Heat Exchanger Configuration",
        " Coil:Heating:Water,",
        "	AHU Heating coil, !- Name",
        "	AvailSched,       !- Availability Schedule Name",
        "	autosize, !- U - Factor Times Area Value { W / K }",
        "	autosize, !- Maximum Water Flow Rate { m3 / s }",
        "	AHU Heating COil HW Inlet, !- Water Inlet Node Name",
        "	AHU Heating COil HW Outlet, !- Water Outlet Node Name",
        "	AHU cooling coil outlet, !- Air Inlet Node Name",
        "	AHU Heating Coil Outlet, !- Air Outlet Node Name",
        "	UFactorTimesAreaAndDesignWaterFlowRate, !- Performance Input Method",
        "	autosize, !- Rated Capacity { W }",
        "	82.2, !- Rated Inlet Water Temperature { C }",
        "	16.6, !- Rated Inlet Air Temperature { C }",
        "	71.1, !- Rated Outlet Water Temperature { C }",
        "	48.8888888888889, !- Rated Outlet Air Temperature { C }",
        "	1;          !- Rated Ratio for Air and Water Convection",
        " Controller:WaterCoil,",
        "	AHU cooling coil controller, !- Name",
        "	TemperatureAndHumidityRatio,		!- Control Variable",
        "	Reverse,			!- Action",
        "	FLOW,				!- Actuator Variable",
        "	AHU cooling coil outlet,	!- Sensor Node Name",
        "	Water Inlet Node,	!- Actuator Node Name",
        "	autosize,			!- Controller Convergence Tolerance { deltaC }",
        "	autosize,			!- Maximum Actuated Flow { m3 / s }",
        "	0.0;				!- Minimum Actuated Flow { m3 / s }",
        " Controller:WaterCoil,",
        "	AHU Heating coil, !- Name",
        "	Temperature,      !- Control Variable",
        "	Normal, !- Action",
        "	Flow,   !- Actuator Variable",
        "	AHU Heating Coil Outlet,   !- Sensor Node Name",
        "	AHU Heating COil HW Inlet, !- Actuator Node Name",
        "	autosize, !- Controller Convergence Tolerance { deltaC }",
        "	autosize, !- Maximum Actuated Flow { m3 / s }",
        "	0;        !- Minimum Actuated Flow { m3 / s }",
        " Schedule:Compact,",
        "   AvailSched,			!- Name",
        "	Fraction,			!- Schedule Type Limits Name",
        "	Through: 12/31,		!- Field 1",
        "	For: AllDays,		!- Field 2",
        "	Until: 24:00, 1.0;  !- Field 3",
        " AirLoopHVAC:ControllerList,",
        "	AHU controllers,    !- Name",
        " Controller:WaterCoil, !- Controller 1 Object Type",
        "	AHU cooling coil controller, !- Controller 1 Name",
        " Controller:WaterCoil, !- Controller 2 Object Type",
        "	AHU Heating coil;   !- Controller 2 Name",
        " HeatExchanger:AirToAir:SensibleAndLatent,",
        "   enthalpy HX,      !- Name",
        "   AvailSched,       !- Availability Schedule Name",
        "   4.71947443200001, !- Nominal Supply Air Flow Rate { m3 / s }",
        "   0,   !- Sensible Effectiveness at 100 % Heating Air Flow { dimensionless }",
        "   0.5, !- Latent Effectiveness at 100 % Heating Air Flow { dimensionless }",
        "   0,   !- Sensible Effectiveness at 100 % Cooling Air Flow { dimensionless }",
        "   0.5, !- Latent Effectiveness at 100 % Cooling Air Flow { dimensionless }",
        "   AHU Heating Coil Outlet, !- Supply Air Inlet Node Name",
        "   AHU Supply fan Inlet,    !- Supply Air Outlet Node Name",
        "   AHU relief air outlet,   !- Exhaust Air Inlet Node Name",
        "   AHU relief air outlet of ENTHALPY HX, !- Exhaust Air Outlet Node Name",
        "   0,      !- Nominal Electric Power { W }",
        "   No,     !- Supply Air Outlet Temperature Control",
        "   Rotary, !- Heat Exchanger Type",
        "   None,   !- Frost Control Type",
        "  -17.7777777777778, !- Threshold Temperature { C }",
        "   0.083,  !- Initial Defrost Time Fraction { dimensionless }",
        "   0.012,  !- Rate of Defrost Time Fraction Increase { 1 / K }",
        "   Yes;    !- Economizer Lockout",
        " Fan:VariableVolume,",
        "   AHU supply fan, !- Name",
        "   AvailSched,     !- Availability Schedule Name",
        "   0.7,            !- Fan Total Efficiency",
        "   996.355828557053, !- Pressure Rise { Pa }",
        "   autosize, !- Maximum Flow Rate { m3 / s }",
        "   Fraction, !- Fan Power Minimum Flow Rate Input Method",
        "   0,        !- Fan Power Minimum Flow Fraction",
        "   0,        !- Fan Power Minimum Air Flow Rate { m3 / s }",
        "   0.95,     !- Motor Efficiency",
        "   1,        !- Motor In Airstream Fraction",
        "   0.35071223, !- Fan Power Coefficient 1",
        "   0.30850535, !- Fan Power Coefficient 2",
        "  -0.54137364, !- Fan Power Coefficient 3",
        "   0.87198823, !- Fan Power Coefficient 4",
        "   0,          !- Fan Power Coefficient 5",
        "   AHU Supply fan Inlet,  !- Air Inlet Node Name",
        "   AHU Supply fan Outlet, !- Air Outlet Node Name",
        "   General;               !- End - Use Subcategory",
        " Branch,",
        "   AHU Main Branch, !- Name",
        "	,         !- Pressure Drop Curve Name",
        "   AirLoopHVAC:OutdoorAirSystem, !- Component 1 Object Type",
        "   AHU OA system,           !- Component 1 Name",
        "   AHU air loop inlet,      !- Component 1 Inlet Node Name",
        "   AHU mixed air outlet,    !- Component 1 Outlet Node Name",
        " Coil:Cooling:water,        !- Component 2 Object Type",
        "   AHU cooling coil,        !- Component 2 Name",
        "   AHU mixed air outlet,    !- Component 2 Inlet Node Name",
        "   AHU cooling coil outlet, !- Component 2 Outlet Node Name",
        " Coil:Heating:Water,        !- Component 3 Object Type",
        "   AHU Heating coil,        !- Component 3 Name",
        "   AHU cooling coil outlet, !- Component 3 Inlet Node Name",
        "   AHU Heating Coil Outlet, !- Component 3 Outlet Node Name",
        " HeatExchanger:AirToAir:SensibleAndLatent, !- Component 4 Object Type",
        "   enthalpy HX,             !- Component 4 Name",
        "   AHU Heating Coil Outlet, !- Component 4 Inlet Node Name",
        "   AHU Supply fan Inlet,    !- Component 4 Outlet Node Name",
        " Fan:VariableVolume,        !- Component 5 Object Type",
        "   AHU Supply Fan,          !- Component 5 Name",
        "   AHU Supply fan Inlet,    !- Component 5 Inlet Node Name",
        "   AHU Supply fan Outlet;   !- Component 5 Outlet Node Name",
        " AirLoopHVAC,",
        "   AHU,                   !- Name",
        "   AHU controllers,       !- Controller List Name",
        "   ,                      !- Availability Manager List Name",
        "   autosize,              !- Design Supply Air Flow Rate { m3 / s }",
        "   AHU Branches,          !- Branch List Name",
        "   ,                      !- Connector List Name",
        "   AHU air loop inlet,    !- Supply Side Inlet Node Name",
        "   AHU return air outlet, !- Demand Side Outlet Node Name",
        "   AHU Supply Path Inlet, !- Demand Side Inlet Node Names",
        "   AHU Supply fan Outlet; !- Supply Side Outlet Node Names",
        " BranchList,",
        "   AHU Branches,          !- Name",
        "   AHU Main Branch;       !- Branch 1 Name",
        " AirLoopHVAC:ReturnPath,",
        "   AHU return path,       !- Name",
        "   AHU return air outlet, !- Return Air Path Outlet Node Name",
        " AirLoopHVAC:ZoneMixer,   !- Component 1 Object Type",
        "   AHU zone mixer;        !- Component 1 Name",
        " AirLoopHVAC:ZoneMixer,",
        "   AHU zone mixer,        !- Name",
        "   AHU return air outlet, !- Outlet Node Name",
        "   Main FL1 Return Outlet;!- Inlet 1 Node Name",
        " ZoneHVAC:EquipmentConnections,",
        "   Main FL1,              !- Zone Name",
        "   Main FL1 Equipment,    !- Zone Conditioning Equipment List Name",
        "   Main FL1 Supply inlet, !- Zone Air Inlet Node or NodeList Name",
        "   ,                      !- Zone Air Exhaust Node or NodeList Name",
        "   Main FL1 Zone Air node,!- Zone Air Node Name",
        "   Main FL1 Return Outlet;!- Zone Return Air Node Name",
        " AirLoopHVAC:OutdoorAirSystem:EquipmentList,",
        "   AHU System equipment,  !- Name",
        " OutdoorAir:Mixer,        !- Component 1 Object Type",
        "   AHU OA Mixing Box;     !- Component 1 Name",
        " AirLoopHVAC:OutdoorAirSystem,",
        "   AHU OA System,             !- Name",
        "   AHU OA system controllers, !- Controller List Name",
        "   AHU System equipment;      !- Outdoor Air Equipment List Name",
        " OutdoorAir:Mixer,",
        "   AHU OA Mixing Box,         !- Name",
        "   AHU mixed air outlet,      !- Mixed Air Node Name",
        "   AHU Outside Air HX Outlet, !- Outdoor Air Stream Node Name",
        "   AHU relief air outlet,     !- Relief Air Stream Node Name",
        "   AHU air loop inlet;        !- Return Air Stream Node Name",
        " AirLoopHVAC:ControllerList,",
        "   AHU OA system controllers, !- Name",
        " Controller:OutdoorAir,       !- Controller 1 Object Type",
        "   AHU OA Controller;         !- Controller 1 Name",
    })
    assert process_idf(idf_objects)
    state.init_state(state)
    GetReturnAirPathInput(state)
    GetAirPathData(state)
    assert state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[4].CompType_Num == SimAirServingZones.CompType.HeatXchngr

# -----------------------------------------------------------------------------
# Test: HeatRecoveryHXOnMainBranch_SimHeatRecoveryTest
def HeatRecoveryHXOnMainBranch_SimHeatRecoveryTest() raises:
    var Qhr_HeatingRateTot: Float64 = 0.0
    var InletNode: Int = 0
    var OutletNode: Int = 0
    var idf_objects: String = delimited_string({
        "SimulationControl,",
        "    Yes,                     !- Do Zone Sizing Calculation",
        "    Yes,                     !- Do System Sizing Calculation",
        "    Yes,                     !- Do Plant Sizing Calculation",
        "    Yes,                     !- Run Simulation for Sizing Periods",
        "    No;                      !- Run Simulation for Weather File Run Periods",
        "Building,",
        "    Fan Coil with DOAS,      !- Name",
        "    30.,                     !- North Axis {deg}",
        "    City,                    !- Terrain",
        "    0.04,                    !- Loads Convergence Tolerance Value",
        "    0.4,                     !- Temperature Convergence Tolerance Value {deltaC}",
        "    FullExterior,            !- Solar Distribution",
        "    25,                      !- Maximum Number of Warmup Days",
        "    6;                       !- Minimum Number of Warmup Days",
        "Timestep,4;",
        "Site:Location,",
        "    CHICAGO_IL_USA TMY2-94846,  !- Name",
        "    41.78,                   !- Latitude {deg}",
        "    -87.75,                  !- Longitude {deg}",
        "    -6.00,                   !- Time Zone {hr}",
        "    190.00;                  !- Elevation {m}",
        "! CHICAGO_IL_USA Annual Cooling 1% Design Conditions, MaxDB=  31.5degC MCWB=  23.0degC",
        "SizingPeriod:DesignDay,",
        "    CHICAGO_IL_USA Annual Cooling 1% Design Conditions DB/MCWB,  !- Name",
        "    7,                       !- Month",
        "    21,                      !- Day of Month",
        "    SummerDesignDay,         !- Day Type",
        "    31.5,                    !- Maximum Dry-Bulb Temperature {C}",
        "    10.7,                    !- Daily Dry-Bulb Temperature Range {deltaC}",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "    Wetbulb,                 !- Humidity Condition Type",
        "    23.0,                    !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "    ,                        !- Humidity Condition Day Schedule Name",
        "    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "    99063.,                  !- Barometric Pressure {Pa}",
        "    5.3,                     !- Wind Speed {m/s}",
        "    230,                     !- Wind Direction {deg}",
        "    No,                      !- Rain Indicator",
        "    No,                      !- Snow Indicator",
        "    No,                      !- Daylight Saving Time Indicator",
        "    ASHRAEClearSky,          !- Solar Model Indicator",
        "    ,                        !- Beam Solar Day Schedule Name",
        "    ,                        !- Diffuse Solar Day Schedule Name",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "    1.0;                     !- Sky Clearness",
        "! CHICAGO_IL_USA Annual Heating 99% Design Conditions DB, MaxDB= -17.3degC",
        "SizingPeriod:DesignDay,",
        "    CHICAGO_IL_USA Annual Heating 99% Design Conditions DB,  !- Name",
        "    1,                       !- Month",
        "    21,                      !- Day of Month",
        "    WinterDesignDay,         !- Day Type",
        "    -17.3,                   !- Maximum Dry-Bulb Temperature {C}",
        "    0.0,                     !- Daily Dry-Bulb Temperature Range {deltaC}",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "    Wetbulb,                 !- Humidity Condition Type",
        "    -17.3,                   !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "    ,                        !- Humidity Condition Day Schedule Name",
        "    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "    99063.,                  !- Barometric Pressure {Pa}",
        "    4.9,                     !- Wind Speed {m/s}",
        "    270,                     !- Wind Direction {deg}",
        "    No,                      !- Rain Indicator",
        "    No,                      !- Snow Indicator",
        "    No,                      !- Daylight Saving Time Indicator",
        "    ASHRAEClearSky,          !- Solar Model Indicator",
        "    ,                        !- Beam Solar Day Schedule Name",
        "    ,                        !- Diffuse Solar Day Schedule Name",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "    0.0;                     !- Sky Clearness",
        "Site:GroundTemperature:BuildingSurface,21.5,21.4,21.5,21.5,22.0,22.9,23.0,23.1,23.1,22.2,21.7,21.6;",
        "ScheduleTypeLimits,",
        "    Any Number;              !- Name",
        "ScheduleTypeLimits,",
        "    Fraction,                !- Name",
        "    0.0,                     !- Lower Limit Value",
        "    1.0,                     !- Upper Limit Value",
        "    CONTINUOUS;              !- Numeric Type",
        "ScheduleTypeLimits,",
        "    Temperature,             !- Name",
        "    -60,                     !- Lower Limit Value",
        "    200,                     !- Upper Limit Value",
        "    CONTINUOUS,              !- Numeric Type",
        "    Temperature;             !- Unit Type",
        "ScheduleTypeLimits,",
        "    Control Type,            !- Name",
        "    0,                       !- Lower Limit Value",
        "    4,                       !- Upper Limit Value",
        "    DISCRETE;                !- Numeric Type",
        "ScheduleTypeLimits,",
        "    On/Off,                  !- Name",
        "    0,                       !- Lower Limit Value",
        "    1,                       !- Upper Limit Value",
        "    DISCRETE;                !- Numeric Type",
        "ScheduleTypeLimits,",
        "    FlowRate,                !- Name",
        "    0.0,                     !- Lower Limit Value",
        "    10,                      !- Upper Limit Value",
        "    CONTINUOUS;              !- Numeric Type",
        "ScheduleTypeLimits,",
        "    HVACTemplate Any Number; !- Name",
        "!-   ===========  ALL OBJECTS IN CLASS: SCHEDULE:COMPACT ===========",
        "Schedule:Compact,",
        "    OCCUPY-1,                !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: WeekDays SummerDesignDay CustomDay1 CustomDay2,  !- Field 2",
        "    Until: 8:00, 0.0,        !- Field 4",
        "    Until: 11:00, 1.00,      !- Field 6",
        "    Until: 12:00, 0.80,      !- Field 8",
        "    Until: 13:00, 0.40,      !- Field 10",
        "    Until: 14:00, 0.80,      !- Field 12",
        "    Until: 18:00, 1.00,      !- Field 14",
        "    Until: 19:00, 0.50,      !- Field 16",
        "    Until: 21:00, 0.10,      !- Field 18",
        "    Until: 24:00, 0.0,       !- Field 20",
        "    For: Weekends WinterDesignDay Holiday,  !- Field 21",
        "    Until: 24:00, 0.0;       !- Field 23",
        "Schedule:Compact,",
        "    LIGHTS-1,                !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: WeekDays SummerDesignDay CustomDay1 CustomDay2,  !- Field 2",
        "    Until: 8:00, 0.05,       !- Field 4",
        "    Until: 9:00, 0.9,        !- Field 6",
        "    Until: 10:00, 0.95,      !- Field 8",
        "    Until: 11:00, 1.00,      !- Field 10",
        "    Until: 12:00, 0.95,      !- Field 12",
        "    Until: 13:00, 0.8,       !- Field 14",
        "    Until: 14:00, 0.9,       !- Field 16",
        "    Until: 18:00, 1.00,      !- Field 18",
        "    Until: 19:00, 0.60,      !- Field 20",
        "    Until: 21:00, 0.40,      !- Field 22",
        "    Until: 24:00, 0.05,      !- Field 24",
        "    For: Weekends WinterDesignDay Holiday,  !- Field 25",
        "    Until: 24:00, 0.05;      !- Field 27",
        "Schedule:Compact,",
        "    EQUIP-1,                 !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: WeekDays SummerDesignDay CustomDay1 CustomDay2,  !- Field 2",
        "    Until: 8:00, 0.02,       !- Field 4",
        "    Until: 9:00, 0.4,        !- Field 6",
        "    Until: 14:00, 0.9,       !- Field 8",
        "    Until: 15:00, 0.8,       !- Field 10",
        "    Until: 16:00, 0.7,       !- Field 12",
        "    Until: 18:00, 0.5,       !- Field 14",
        "    Until: 21:00, 0.3,       !- Field 16",
        "    Until: 24:00, 0.02,      !- Field 18",
        "    For: Weekends WinterDesignDay Holiday,  !- Field 19",
        "    Until: 24:00, 0.02;      !- Field 21",
        "Schedule:Compact,",
        "    INFIL-SCH,               !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: WeekDays CustomDay1 CustomDay2,  !- Field 2",
        "    Until: 7:00, 1.0,        !- Field 4",
        "    Until: 21:00, 0.0,       !- Field 6",
        "    Until: 24:00, 1.0,       !- Field 8",
        "    For: Weekends Holiday,   !- Field 9",
        "    Until: 24:00, 1.0,       !- Field 11",
        "    For: SummerDesignDay,    !- Field 12",
        "    Until: 24:00, 1.0,       !- Field 14",
        "    For: WinterDesignDay,    !- Field 15",
        "    Until: 24:00, 1.0;       !- Field 17",
        "Schedule:Compact,",
        "    ActSchd,                 !- Name",
        "    Any Number,              !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 117.239997864;",
        "                             !- Field 4",
        "Schedule:Compact,",
        "    ShadeTransSch,           !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.0;       !- Field 4",
        "! For heating, recover 2 hrs early",
        "Schedule:Compact,",
        "    Htg-SetP-Sch,            !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: WeekDays CustomDay1 CustomDay2,  !- Field 2",
        "    Until: 6:00, 13.0,       !- Field 4",
        "    Until: 7:00, 18.0,       !- Field 6",
        "    Until: 21:00, 23.0,      !- Field 8",
        "    Until: 24:00, 13.0,      !- Field 10",
        "    For: WeekEnds Holiday,   !- Field 11",
        "    Until: 24:00, 13.0,      !- Field 13",
        "    For: SummerDesignDay,    !- Field 14",
        "    Until: 24:00, 13.0,      !- Field 16",
        "    For: WinterDesignDay,    !- Field 17",
        "    Until: 24:00, 23.0;      !- Field 19",
        "! For cooling, recover 1 hr early",
        "Schedule:Compact,",
        "    Clg-SetP-Sch,            !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: WeekDays CustomDay1 CustomDay2,  !- Field 2",
        "    Until: 7:00, 32.0,       !- Field 4",
        "    Until: 21:00, 24.0,      !- Field 6",
        "    Until: 24:00, 32.0,      !- Field 8",
        "    For: WeekEnds Holiday,   !- Field 9",
        "    Until: 24:00, 32.0,      !- Field 11",
        "    For: SummerDesignDay,    !- Field 12",
        "    Until: 24:00, 24.0,      !- Field 14",
        "    For: WinterDesignDay,    !- Field 15",
        "    Until: 24:00, 32.0;      !- Field 17",
        "Schedule:Compact,",
        "    FanAvailSched,           !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: WeekDays CustomDay1 CustomDay2,  !- Field 2",
        "    Until: 7:00, 0.0,        !- Field 4",
        "    Until: 21:00, 1.0,       !- Field 6",
        "    Until: 24:00, 0.0,       !- Field 8",
        "    For: Weekends Holiday,   !- Field 9",
        "    Until: 24:00, 0.0,       !- Field 11",
        "    For: SummerDesignDay,    !- Field 12",
        "    Until: 24:00, 1.0,       !- Field 14",
        "    For: WinterDesignDay,    !- Field 15",
        "    Until: 24:00, 1.0;       !- Field 17",
        "Schedule:Compact,",
        "    HVACTemplate-Always 1,   !- Name",
        "    HVACTemplate Any Number, !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 1;         !- Field 4",
        "Schedule:Compact,",
        "    HVACTemplate-Always 4,   !- Name",
        "    HVACTemplate Any Number, !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 4;         !- Field 4",
        "Schedule:Compact,",
        "    HVACTemplate-Always 12.2,!- Name",
        "    HVACTemplate Any Number, !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 12.2;      !- Field 4",
        "Material,",
        "    WD10,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    0.667,                   !- Thickness {m}",
        "    0.115,                   !- Conductivity {W/m-K}",
        "    513,                     !- Density {kg/m3}",
        "    1381,                    !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.78,                    !- Solar Absorptance",
        "    0.78;                    !- Visible Absorptance",
        "Material,",
        "    RG01,                    !- Name",
        "    Rough,                   !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    1.442000,                !- Conductivity {W/m-K}",
        "    881.0000,                !- Density {kg/m3}",
        "    1674.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.6500000,               !- Solar Absorptance",
        "    0.6500000;               !- Visible Absorptance",
        "Material,",
        "    BR01,                    !- Name",
        "    VeryRough,               !- Roughness",
        "    9.4999997E-03,           !- Thickness {m}",
        "    0.1620000,               !- Conductivity {W/m-K}",
        "    1121.000,                !- Density {kg/m3}",
        "    1464.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7000000,               !- Solar Absorptance",
        "    0.7000000;               !- Visible Absorptance",
        "Material,",
        "    IN46,                    !- Name",
        "    VeryRough,               !- Roughness",
        "    7.6200001E-02,           !- Thickness {m}",
        "    2.3000000E-02,           !- Conductivity {W/m-K}",
        "    24.00000,                !- Density {kg/m3}",
        "    1590.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.5000000,               !- Solar Absorptance",
        "    0.5000000;               !- Visible Absorptance",
        "Material,",
        "    WD01,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.9099999E-02,           !- Thickness {m}",
        "    0.1150000,               !- Conductivity {W/m-K}",
        "    513.0000,                !- Density {kg/m3}",
        "    1381.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7800000,               !- Solar Absorptance",
        "    0.7800000;               !- Visible Absorptance",
        "Material,",
        "    PW03,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    0.1150000,               !- Conductivity {W/m-K}",
        "    545.0000,                !- Density {kg/m3}",
        "    1213.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7800000,               !- Solar Absorptance",
        "    0.7800000;               !- Visible Absorptance",
        "Material,",
        "    IN02,                    !- Name",
        "    Rough,                   !- Roughness",
        "    9.0099998E-02,           !- Thickness {m}",
        "    4.3000001E-02,           !- Conductivity {W/m-K}",
        "    10.00000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "Material,",
        "    GP01,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    0.1600000,               !- Conductivity {W/m-K}",
        "    801.0000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "Material,",
        "    GP02,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.5900001E-02,           !- Thickness {m}",
        "    0.1600000,               !- Conductivity {W/m-K}",
        "    801.0000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "Material,",
        "    CC03,                    !- Name",
        "    MediumRough,             !- Roughness",
        "    0.1016000,               !- Thickness {m}",
        "    1.310000,                !- Conductivity {W/m-K}",
        "    2243.000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.6500000,               !- Solar Absorptance",
        "    0.6500000;               !- Visible Absorptance",
        "Material:NoMass,",
        "    CP01,                    !- Name",
        "    Rough,                   !- Roughness",
        "    0.3670000,               !- Thermal Resistance {m2-K/W}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "Material:NoMass,",
        "    MAT-CLNG-1,              !- Name",
        "    Rough,                   !- Roughness",
        "    0.652259290,             !- Thermal Resistance {m2-K/W}",
        "    0.65,                    !- Thermal Absorptance",
        "    0.65,                    !- Solar Absorptance",
        "    0.65;                    !- Visible Absorptance",
        "Material:AirGap,",
        "    AL21,                    !- Name",
        "    0.1570000;               !- Thermal Resistance {m2-K/W}",
        "Material:AirGap,",
        "    AL23,                    !- Name",
        "    0.1530000;               !- Thermal Resistance {m2-K/W}",
        "WindowMaterial:Glazing,",
        "    CLEAR 3MM,               !- Name",
        "    SpectralAverage,         !- Optical Data Type",
        "    ,                        !- Window Glass Spectral Data Set Name",
        "    0.003,                   !- Thickness {m}",
        "    0.837,                   !- Solar Transmittance at Normal Incidence",
        "    0.075,                   !- Front Side Solar Reflectance at Normal Incidence",
        "    0.075,                   !- Back Side Solar Reflectance at Normal Incidence",
        "    0.898,                   !- Visible Transmittance at Normal Incidence",
        "    0.081,                   !- Front Side Visible Reflectance at Normal Incidence",
        "    0.081,                   !- Back Side Visible Reflectance at Normal Incidence",
        "    0.0,                     !- Infrared Transmittance at Normal Incidence",
        "    0.84,                    !- Front Side Infrared Hemispherical Emissivity",
        "    0.84,                    !- Back Side Infrared Hemispherical Emissivity",
        "    0.9;                     !- Conductivity {W/m-K}",
        "WindowMaterial:Glazing,",
        "    GREY 3MM,                !- Name",
        "    SpectralAverage,         !- Optical Data Type",
        "    ,                        !- Window Glass Spectral Data Set Name",
        "    0.003,                   !- Thickness {m}",
        "    0.626,                   !- Solar Transmittance at Normal Incidence",
        "    0.061,                   !- Front Side Solar Reflectance at Normal Incidence",
        "    0.061,                   !- Back Side Solar Reflectance at Normal Incidence",
        "    0.611,                   !- Visible Transmittance at Normal Incidence",
        "    0.061,                   !- Front Side Visible Reflectance at Normal Incidence",
        "    0.061,                   !- Back Side Visible Reflectance at Normal Incidence",
        "    0.0,                     !- Infrared Transmittance at Normal Incidence",
        "    0.84,                    !- Front Side Infrared Hemispherical Emissivity",
        "    0.84,                    !- Back Side Infrared Hemispherical Emissivity",
        "    0.9;                     !- Conductivity {W/m-K}",
        "WindowMaterial:Glazing,",
        "    CLEAR 6MM,               !- Name",
        "    SpectralAverage,         !- Optical Data Type",
        "    ,                        !- Window Glass Spectral Data Set Name",
        "    0.006,                   !- Thickness {m}",
        "    0.775,                   !- Solar Transmittance at Normal Incidence",
        "    0.071,                   !- Front Side Solar Reflectance at Normal Incidence",
        "    0.071,                   !- Back Side Solar Reflectance at Normal Incidence",
        "    0.881,                   !- Visible Transmittance at Normal Incidence",
        "    0.080,                   !- Front Side Visible Reflectance at Normal Incidence",
        "    0.080,                   !- Back Side Visible Reflectance at Normal Incidence",
        "    0.0,                     !- Infrared Transmittance at Normal Incidence",
        "    0.84,                    !- Front Side Infrared Hemispherical Emissivity",
        "    0.84,                    !- Back Side Infrared Hemispherical Emissivity",
        "    0.9;                     !- Conductivity {W/m-K}",
        "WindowMaterial:Glazing,",
        "    LoE CLEAR 6MM,           !- Name",
        "    SpectralAverage,         !- Optical Data Type",
        "    ,                        !- Window Glass Spectral Data Set Name",
        "    0.006,                   !- Thickness {m}",
        "    0.600,                   !- Solar Transmittance at Normal Incidence",
        "    0.170,                   !- Front Side Solar Reflectance at Normal Incidence",
        "    0.220