from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR, EXPECT_NO_THROW, EXPECT_ANY_THROW, ASSERT_TRUE, ASSERT_THROW, compare_err_stream, delimited_string, process_idf
from string import String
from EnergyPlus.CurveManager import AddCurve, CurveType
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.Fans import Fans, FanComponent, GetFanIndex
from EnergyPlus.FaultsManager import FaultsManager, CheckAndReadFaults, CalFaultyFanAirFlowReduction, FaultProperties, FaultPropertiesChillerSWT, FouledCoil
from EnergyPlus.HVACControllers import HVACControllers
from EnergyPlus.MixedAir import MixedAir
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.SetPointManager import SetPointManager
from EnergyPlus.WaterCoils import WaterCoils
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.DataPlant import DataPlant
from EnergyPlus.Constant import Constant
class FaultsManager_FaultFoulingAirFilters_CheckFaultyAirFilterFanCurve(Test):
    def run(self, state: EnergyPlusData):
        state.init_state(state)
        var numFans: Int = 2
        var TestResult: Bool
        state.dataFaultsMgr.FaultsFouledAirFilters.allocate(numFans)
        var curve = AddCurve(state, "Curve1")
        curve.curveType = CurveType.Cubic
        curve.coeff[0] = 1151.1
        curve.coeff[1] = 13.509
        curve.coeff[2] = -0.9105
        curve.coeff[3] = -0.0129
        curve.coeff[4] = 0.0
        curve.coeff[5] = 0.0
        curve.inputLimits[0].min = 7.0
        curve.inputLimits[0].max = 21.0
        var fan1 = FanComponent()
        fan1.Name = "FAN_1"
        fan1.type = HVAC.FanType.VAV
        fan1.maxAirFlowRate = 18.194
        fan1.deltaPress = 1017.59
        state.dataFans.fans.push_back(fan1)
        state.dataFans.fanMap.insert_or_assign(fan1.Name, state.dataFans.fans.size())
        var fault1 = state.dataFaultsMgr.FaultsFouledAirFilters[0]
        fault1.fanName = "FAN_1"
        fault1.fanNum = Fans.GetFanIndex(state, fault1.fanName)
        fault1.fanCurveNum = 1
        var fan2 = FanComponent()
        fan2.Name = "FAN_2"
        fan2.type = HVAC.FanType.VAV
        fan2.maxAirFlowRate = 18.194
        fan2.deltaPress = 1017.59 * 1.2
        state.dataFans.fans.push_back(fan2)
        state.dataFans.fanMap.insert_or_assign(fan2.Name, state.dataFans.fans.size())
        var fault2 = state.dataFaultsMgr.FaultsFouledAirFilters[1]
        fault2.fanName = "FAN_2"
        fault2.fanNum = Fans.GetFanIndex(state, fault2.fanName)
        fault2.fanCurveNum = 1
        TestResult = fault1.CheckFaultyAirFilterFanCurve(state)
        EXPECT_TRUE(TestResult)
        TestResult = fault2.CheckFaultyAirFilterFanCurve(state)
        EXPECT_FALSE(TestResult)
        state.dataCurveManager.curves.deallocate()
class FaultsManager_FaultFoulingAirFilters_CheckFaultyAirFilterFanCurve_AutosizedFan(Test):
    def run(self, state: EnergyPlusData):
        var idf_objects: String = delimited_string([
            "ScheduleTypeLimits,",
            "  Fraction,                !- Name",
            "  0,                       !- Lower Limit Value",
            "  1.5,                     !- Upper Limit Value",
            "  Continuous;              !- Numeric Type",
            "ScheduleTypeLimits,",
            "  OnOff,                   !- Name",
            "  0,                       !- Lower Limit Value",
            "  1,                       !- Upper Limit Value",
            "  Discrete;                !- Numeric Type",
            "Schedule:Constant,Always On Discrete,OnOff,1;",
            "Schedule:Compact,",
            "  AvailSched,              !- Name",
            "  Fraction,                !- Schedule Type Limits Name",
            "  Through: 12/31,          !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,1.00;       !- Field 3",
            "Schedule:Compact,",
            "  Pressure Fraction Schedule,  !- Name",
            "  Fraction,                !- Schedule Type Limits Name",
            "  Through: 12/31,          !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,1.25;       !- Field 3",
            "Fan:ConstantVolume,",
            "  Fan CV,                  !- Name",
            "  Always On Discrete,      !- Availability Schedule Name",
            "  0.7,                     !- Fan Total Efficiency",
            "  150,                     !- Pressure Rise {Pa}",
            "  AutoSize,                !- Maximum Flow Rate {m3/s}",
            "  0.93,                    !- Motor Efficiency",
            "  1,                       !- Motor In Airstream Fraction",
            "  Node 21,                 !- Air Inlet Node Name",
            "  Node 38;                 !- Air Outlet Node Name",
            "FaultModel:Fouling:AirFilter,",
            "  Fan CV Fouling Air Filter,  !- Name",
            "  Fan:ConstantVolume,      !- Fan Object Type",
            "  Fan CV,                  !- Fan Name",
            "  AvailSched,              !- Availability Schedule Name",
            "  Pressure Fraction Schedule,  !- Pressure Fraction Schedule Name",
            "  Fouled Fan Curve;        !- Fan Curve Name",
            "Curve:Cubic,",
            "  Fouled Fan Curve,        !- Name",
            "  1015,                    !- Coefficient1 Constant",
            "  -1750,                   !- Coefficient2 x",
            "  59050,                   !- Coefficient3 x**2",
            "  -1624000,                !- Coefficient4 x**3",
            "  0,                       !- Minimum Value of x",
            "  0.09,                    !- Maximum Value of x",
            "  ,                        !- Minimum Curve Output",
            "  ,                        !- Maximum Curve Output",
            "  Dimensionless,           !- Input Unit Type for X",
            "  Dimensionless;           !- Output Unit Type",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state)
        state.dataEnvrn.StdRhoAir = 1.2
        EXPECT_NO_THROW(CheckAndReadFaults(state))
        compare_err_stream("", True)
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.CurSysNum = 0
        state.dataSize.CurOASysNum = 0
        state.dataSize.DataNonZoneNonAirloopValue = 0.114
        EXPECT_NO_THROW(state.dataFans.fans[0].set_size(state))
        EXPECT_DOUBLE_EQ(0.114, state.dataFans.fans[0].maxAirFlowRate)
class FaultsManager_FaultFoulingAirFilters_CheckFaultyAirFilterFanCurve_NonAutosizedFan(Test):
    def run(self, state: EnergyPlusData):
        var idf_objects: String = delimited_string([
            "ScheduleTypeLimits,",
            "  Fraction,                !- Name",
            "  0,                       !- Lower Limit Value",
            "  1.5,                     !- Upper Limit Value",
            "  Continuous;              !- Numeric Type",
            "ScheduleTypeLimits,",
            "  OnOff,                   !- Name",
            "  0,                       !- Lower Limit Value",
            "  1,                       !- Upper Limit Value",
            "  Discrete;                !- Numeric Type",
            "Schedule:Constant,Always On Discrete,OnOff,1;",
            "Schedule:Compact,",
            "  AvailSched,              !- Name",
            "  Fraction,                !- Schedule Type Limits Name",
            "  Through: 12/31,          !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,1.00;       !- Field 3",
            "Schedule:Compact,",
            "  Pressure Fraction Schedule,  !- Name",
            "  Fraction,                !- Schedule Type Limits Name",
            "  Through: 12/31,          !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,1.25;       !- Field 3",
            "Fan:ConstantVolume,",
            "  Fan CV,                  !- Name",
            "  Always On Discrete,      !- Availability Schedule Name",
            "  0.7,                     !- Fan Total Efficiency",
            "  400,                     !- Pressure Rise {Pa}",
            "  0.114,                   !- Maximum Flow Rate {m3/s}",
            "  0.93,                    !- Motor Efficiency",
            "  1,                       !- Motor In Airstream Fraction",
            "  Node 21,                 !- Air Inlet Node Name",
            "  Node 38;                 !- Air Outlet Node Name",
            "FaultModel:Fouling:AirFilter,",
            "  Fan CV Fouling Air Filter,  !- Name",
            "  Fan:ConstantVolume,      !- Fan Object Type",
            "  Fan CV,                  !- Fan Name",
            "  AvailSched,              !- Availability Schedule Name",
            "  Pressure Fraction Schedule,  !- Pressure Fraction Schedule Name",
            "  Fouled Fan Curve;        !- Fan Curve Name",
            "Curve:Cubic,",
            "  Fouled Fan Curve,        !- Name",
            "  1015,                    !- Coefficient1 Constant",
            "  -1750,                   !- Coefficient2 x",
            "  59050,                   !- Coefficient3 x**2",
            "  -1624000,                !- Coefficient4 x**3",
            "  0,                       !- Minimum Value of x",
            "  0.09,                    !- Maximum Value of x",
            "  ,                        !- Minimum Curve Output",
            "  ,                        !- Maximum Curve Output",
            "  Dimensionless,           !- Input Unit Type for X",
            "  Dimensionless;           !- Output Unit Type",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state)
        state.dataEnvrn.StdRhoAir = 1.2
        EXPECT_NO_THROW(CheckAndReadFaults(state))
        compare_err_stream("", True)
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.CurSysNum = 0
        state.dataSize.CurOASysNum = 0
        state.dataSize.DataNonZoneNonAirloopValue = 0.15
        EXPECT_ANY_THROW(state.dataFans.fans[0].set_size(state))
        EXPECT_DOUBLE_EQ(0.114, state.dataFans.fans[0].maxAirFlowRate)
        var error_string: String = delimited_string([
            "   ** Severe  ** FaultModel:Fouling:AirFilter = \"FAN CV FOULING AIR FILTER\"",
            "   **   ~~~   ** Invalid Fan Curve Name = \"FOULED FAN CURVE\" does not cover ",
            "   **   ~~~   ** the operational point of Fan FAN CV",
            "   **  Fatal  ** SizeFan: Invalid FaultModel:Fouling:AirFilter=FAN CV FOULING AIR FILTER",
            "   ...Summary of Errors that led to program termination:",
            "   ..... Reference severe error count=1",
            "   ..... Last severe error=FaultModel:Fouling:AirFilter = \"FAN CV FOULING AIR FILTER\"",
        ])
        compare_err_stream(error_string, True)
class FaultsManager_FaultFoulingAirFilters_CalFaultyFanAirFlowReduction(Test):
    def run(self, state: EnergyPlusData):
        var FanDesignFlowRateDec: Float64
        var FanFaultyDeltaPressInc: Float64 = 0.10
        var curve = AddCurve(state, "Curve1")
        curve.curveType = CurveType.Cubic
        curve.coeff[0] = 1151.1
        curve.coeff[1] = 13.509
        curve.coeff[2] = -0.9105
        curve.coeff[3] = -0.0129
        curve.coeff[4] = 0.0
        curve.coeff[5] = 0.0
        curve.inputLimits[0].min = 7.0
        curve.inputLimits[0].max = 21.0
        var fan1 = FanComponent()
        fan1.Name = "FAN_1"
        fan1.type = HVAC.FanType.VAV
        fan1.maxAirFlowRate = 18.194
        fan1.deltaPress = 1017.59
        state.dataFans.fans.push_back(fan1)
        state.dataFans.fanMap.insert_or_assign(fan1.Name, state.dataFans.fans.size())
        FanDesignFlowRateDec = CalFaultyFanAirFlowReduction(state, fan1.Name, fan1.maxAirFlowRate, fan1.deltaPress, FanFaultyDeltaPressInc * fan1.deltaPress, 1)
        EXPECT_NEAR(3.845, FanDesignFlowRateDec, 0.005)
        state.dataCurveManager.curves.deallocate()
class FaultsManager_TemperatureSensorOffset_CoilSAT(Test):
    def run(self, state: EnergyPlusData):
        var idf_objects: String = delimited_string([
            "                                                              ", "FaultModel:TemperatureSensorOffset:CoilSupplyAir,             ",
            "   Fault_SAT_CoolCoil1,!- Name                                ", "   ,                   !- Availability Schedule Name          ",
            "   ,                   !- Severity Schedule Name              ", "   Coil:Cooling:Water, !- Coil Object Type                    ",
            "   Chilled Water Coil, !- Coil Object Name                    ", "   CW Coil Controller, !- Water Coil Controller Name          ",
            "   2.0;                !- Reference Sensor Offset {deltaC}    ", "                                                              ",
            "Coil:Cooling:Water,                                           ", "   Chilled Water Coil, !- Name                                ",
            "   AvailSched,         !- Availability Schedule Name          ", "   autosize,           !- Design Water Flow Rate {m3/s}       ",
            "   autosize,           !- Design Air Flow Rate {m3/s}         ", "   autosize,           !- Design Inlet Water Temperature {C}  ",
            "   autosize,           !- Design Inlet Air Temperature {C}    ", "   autosize,           !- Design Outlet Air Temperature {C}   ",
            "   autosize,           !- Design Inlet Air Humidity Ratio {-} ", "   autosize,           !- Design Outlet Air Humidity Ratio {-}",
            "   Water Inlet Node,   !- Water Inlet Node Name               ", "   Water Outlet Node,  !- Water Outlet Node Name              ",
            "   Air Inlet Node,     !- Air Inlet Node Name                 ", "   Air Outlet Node,    !- Air Outlet Node Name                ",
            "   SimpleAnalysis,     !- Type of Analysis                    ", "   CrossFlow;          !- Heat Exchanger Configuration        ",
            "                                                              ", "Controller:WaterCoil,                                         ",
            "   CW Coil Controller, !- Name                                ", "   HumidityRatio,      !- Control Variable                    ",
            "   Reverse,            !- Action                              ", "   FLOW,               !- Actuator Variable                   ",
            "   Air Outlet Node,    !- Sensor Node Name                    ", "   Water Inlet Node,   !- Actuator Node Name                  ",
            "   autosize,           !- Controller Convergence Tolerance {C}", "   autosize,           !- Maximum Actuated Flow {m3/s}        ",
            "   0.0;                !- Minimum Actuated Flow {m3/s}        ", "                                                              ",
            "SetpointManager:Scheduled,                                    ", "   HumRatSPManager,    !- Name                                ",
            "   HumidityRatio,      !- Control Variable                    ", "   HumRatioSched,      !- Schedule Name                       ",
            "   Air Outlet Node;    !- Setpoint Node or NodeList Name      ", "                                                              ",
            "Schedule:Compact,                                             ", "   HumRatioSched,      !- Name                                ",
            "   Any Number,         !- Schedule Type Limits Name           ", "   Through: 12/31,     !- Field 1                             ",
            "   For: AllDays,       !- Field 2                             ", "   Until: 24:00, 0.015;!- Field 3                             ",
            "Schedule:Compact,                                             ", "   AvailSched,         !- Name                                ",
            "   Fraction,           !- Schedule Type Limits Name           ", "   Through: 12/31,     !- Field 1                             ",
            "   For: AllDays,       !- Field 2                             ", "   Until: 24:00, 1.0;  !- Field 3                             ",
            "                                                              ", "AirLoopHVAC:ControllerList,                                   ",
            "   CW Coil Controller, !- Name                                ", "   Controller:WaterCoil,!- Controller 1 Object Type           ",
            "   CW Coil Controller; !- Controller 1 Name                   ",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state)
        SetPointManager.GetSetPointManagerInputs(state)
        state.dataSetPointManager.GetInputFlag = False
        HVACControllers.GetControllerInput(state)
        CheckAndReadFaults(state)
        EXPECT_EQ(2.0, state.dataFaultsMgr.FaultsCoilSATSensor[0].Offset)
        EXPECT_EQ("COIL:COOLING:WATER", state.dataFaultsMgr.FaultsCoilSATSensor[0].CoilType)
        EXPECT_TRUE(state.dataHVACControllers.ControllerProps[0].FaultyCoilSATFlag)
        EXPECT_EQ(1, state.dataHVACControllers.ControllerProps[0].FaultyCoilSATIndex)
class FaultsManager_FaultChillerSWTSensor_CalFaultChillerSWT(Test):
    def run(self, state: EnergyPlusData):
        state.init_state(state)
        var FlagVariableFlow: Bool
        var FaultyChillerSWTOffset: Float64
        var Cp: Float64 = 4500
        var EvapInletTemp: Float64 = 12
        var EvapOutletTemp: Float64 = 7
        var EvapMassFlowRate: Float64 = 40
        var QEvaporator: Float64 = 900000
        var FaultChiller: FaultPropertiesChillerSWT
        FlagVariableFlow = False
        var EvapOutletTemp_1: Float64 = EvapOutletTemp
        var EvapMassFlowRate_1: Float64 = EvapMassFlowRate
        var QEvaporator_1: Float64 = QEvaporator
        FaultyChillerSWTOffset = 0
        FaultChiller.CalFaultChillerSWT(FlagVariableFlow, FaultyChillerSWTOffset, Cp, EvapInletTemp, EvapOutletTemp_1, EvapMassFlowRate_1, QEvaporator_1)
        EXPECT_EQ(1, EvapOutletTemp_1 / EvapOutletTemp)
        EXPECT_EQ(1, QEvaporator_1 / QEvaporator)
        var EvapOutletTemp_2: Float64 = EvapOutletTemp
        var EvapMassFlowRate_2: Float64 = EvapMassFlowRate
        var QEvaporator_2: Float64 = QEvaporator
        FaultyChillerSWTOffset = 2
        FaultChiller.CalFaultChillerSWT(FlagVariableFlow, FaultyChillerSWTOffset, Cp, EvapInletTemp, EvapOutletTemp_2, EvapMassFlowRate_2, QEvaporator_2)
        EXPECT_NEAR(0.714, EvapOutletTemp_2 / EvapOutletTemp, 0.001)
        EXPECT_NEAR(1.400, QEvaporator_2 / QEvaporator, 0.001)
        var EvapOutletTemp_3: Float64 = EvapOutletTemp
        var EvapMassFlowRate_3: Float64 = EvapMassFlowRate
        var QEvaporator_3: Float64 = QEvaporator
        FaultyChillerSWTOffset = -2
        FaultChiller.CalFaultChillerSWT(FlagVariableFlow, FaultyChillerSWTOffset, Cp, EvapInletTemp, EvapOutletTemp_3, EvapMassFlowRate_3, QEvaporator_3)
        EXPECT_NEAR(1.285, EvapOutletTemp_3 / EvapOutletTemp, 0.001)
        EXPECT_NEAR(0.600, QEvaporator_3 / QEvaporator, 0.001)
class FaultsManager_CalFaultOffsetAct(Test):
    def run(self, state: EnergyPlusData):
        state.init_state(state)
        var OffsetAct: Float64
        var Fault: FaultProperties
        Fault.availSched = Sched.GetScheduleAlwaysOn(state)
        Fault.severitySched = Sched.GetScheduleAlwaysOn(state)
        Fault.Offset = 10
        OffsetAct = Fault.CalFaultOffsetAct(state)
        EXPECT_EQ(10, OffsetAct)
class FaultsManager_EconomizerFaultGetInput(Test):
    def run(self, state: EnergyPlusData):
        var idf_objects: String = delimited_string([
            "  Controller:OutdoorAir,",
            "    VAV_1_OA_Controller,     !- Name",
            "    VAV_1_OARelief Node,     !- Relief Air Outlet Node Name",
            "    VAV_1 Supply Equipment Inlet Node,  !- Return Air Node Name",
            "    VAV_1_OA-VAV_1_CoolCNode,!- Mixed Air Node Name",
            "    VAV_1_OAInlet Node,      !- Actuator Node Name",
            "    AUTOSIZE,                !- Minimum Outdoor Air Flow Rate {m3/s}",
            "    AUTOSIZE,                !- Maximum Outdoor Air Flow Rate {m3/s}",
            "    DifferentialDryBulb,     !- Economizer Control Type",
            "    ModulateFlow,            !- Economizer Control Action Type",
            "    28.0,                    !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
            "    64000.0,                 !- Economizer Maximum Limit Enthalpy {J/kg}",
            "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
            "    ,                        !- Electronic Enthalpy Limit Curve Name",
            "    -100.0,                  !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
            "    NoLockout,               !- Lockout Type",
            "    FixedMinimum,            !- Minimum Limit Type",
            "    MinOA_MotorizedDamper_Sched;  !- Minimum Outdoor Air Schedule Name",
            "  Controller:OutdoorAir,",
            "    VAV_2_OA_Controller,     !- Name",
            "    VAV_2_OARelief Node,     !- Relief Air Outlet Node Name",
            "    VAV_2 Supply Equipment Inlet Node,  !- Return Air Node Name",
            "    VAV_2_OA-VAV_2_CoolCNode,!- Mixed Air Node Name",
            "    VAV_2_OAInlet Node,      !- Actuator Node Name",
            "    AUTOSIZE,                !- Minimum Outdoor Air Flow Rate {m3/s}",
            "    AUTOSIZE,                !- Maximum Outdoor Air Flow Rate {m3/s}",
            "    DifferentialDryBulb,     !- Economizer Control Type",
            "    ModulateFlow,            !- Economizer Control Action Type",
            "    28.0,                    !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
            "    64000.0,                 !- Economizer Maximum Limit Enthalpy {J/kg}",
            "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
            "    ,                        !- Electronic Enthalpy Limit Curve Name",
            "    -100.0,                  !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
            "    NoLockout,               !- Lockout Type",
            "    FixedMinimum,            !- Minimum Limit Type",
            "    MinOA_MotorizedDamper_Sched;  !- Minimum Outdoor Air Schedule Name",
            "  Schedule:Compact,",
            "    MinOA_MotorizedDamper_Sched,  !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 07:00,0.0,        !- Field 3",
            "    Until: 22:00,1.0,        !- Field 4",
            "    Until: 24:00,0.0;        !- Field 5",
            "  Schedule:Compact,",
            "    ALWAYS_ON,               !- Name",
            "    On/Off,                  !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,1;          !- Field 3",
            "  Schedule:Compact,",
            "    OATSeveritySch,          !- Name",
            "    On/Off,                  !- Schedule Type Limits Name",
            "    Through: 6/30,           !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,0,          !- Field 3",
            "    Through: 12/31,          !- Field 5",
            "    For: AllDays,            !- Field 6",
            "    Until: 24:00,1;          !- Field 7",
            "  FaultModel:TemperatureSensorOffset:OutdoorAir,",
            "    OATFault,                !- Name",
            "    ALWAYS_ON,               !- Availability Schedule Name",
            "    OATSeveritySch,          !- Severity Schedule Name",
            "    Controller:OutdoorAir,   !- Controller Object Type",
            "    VAV_1_OA_Controller,     !- Controller Object Name",
            "    2.0;                     !- Temperature Sensor Offset {deltaC}",
            "  FaultModel:HumiditySensorOffset:OutdoorAir,",
            "    OAWFault,                !- Name",
            "    ALWAYS_ON,               !- Availability Schedule Name",
            "    ,                        !- Severity Schedule Name",
            "    Controller:OutdoorAir,   !- Controller Object Type",
            "    VAV_1_OA_Controller,     !- Controller Object Name",
            "    -0.002;                  !- Humidity Sensor Offset {kgWater/kgDryAir}",
            "  FaultModel:EnthalpySensorOffset:OutdoorAir,",
            "    OAHFault,                !- Name",
            "    ALWAYS_ON,               !- Availability Schedule Name",
            "    ,                        !- Severity Schedule Name",
            "    Controller:OutdoorAir,   !- Controller Object Type",
            "    VAV_1_OA_Controller,     !- Controller Object Name",
            "    5000;                    !- Enthalpy Sensor Offset {J/kg}",
            "  FaultModel:TemperatureSensorOffset:ReturnAir,",
            "    RATFault,                !- Name",
            "    ,                        !- Availability Schedule Name",
            "    ,                        !- Severity Schedule Name",
            "    Controller:OutdoorAir,   !- Controller Object Type",
            "    VAV_2_OA_Controller,     !- Controller Object Name",
            "    -2.0;                    !- Temperature Sensor Offset {deltaC}",
            "  FaultModel:EnthalpySensorOffset:ReturnAir,",
            "    RAHFault,                !- Name",
            "    ,                        !- Availability Schedule Name",
            "    ,                        !- Severity Schedule Name",
            "    Controller:OutdoorAir,   !- Controller Object Type",
            "    VAV_2_OA_Controller,     !- Controller Object Name",
            "    -2000;                   !- Enthalpy Sensor Offset {J/kg}",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state)
        MixedAir.GetOAControllerInputs(state)
        EXPECT_EQ(state.dataMixedAir.NumOAControllers, 2)
        EXPECT_EQ(state.dataFaultsMgr.NumFaultyEconomizer, 5)
        EXPECT_EQ(state.dataMixedAir.OAController[0].NumFaultyEconomizer, 3)
        EXPECT_EQ(state.dataMixedAir.OAController[0].EconmizerFaultNum[0], 1)
        EXPECT_EQ(state.dataMixedAir.OAController[0].EconmizerFaultNum[1], 2)
        EXPECT_EQ(state.dataMixedAir.OAController[0].EconmizerFaultNum[2], 3)
        EXPECT_EQ(state.dataMixedAir.OAController[1].NumFaultyEconomizer, 2)
        EXPECT_EQ(state.dataMixedAir.OAController[1].EconmizerFaultNum[0], 4)
        EXPECT_EQ(state.dataMixedAir.OAController[1].EconmizerFaultNum[1], 5)
class FaultsManager_FoulingCoil_CoilNotFound(Test):
    def run(self, state: EnergyPlusData):
        var idf_objects: String = delimited_string([
            "Schedule:Compact,                                             ",
            "   AvailSched,         !- Name                                ",
            "   ,                   !- Schedule Type Limits Name           ",
            "   Through: 12/31,     !- Field 1                             ",
            "   For: AllDays,       !- Field 2                             ",
            "   Until: 24:00, 1.0;  !- Field 3                             ",
            "FaultModel:Fouling:Coil,",
            "  FouledHeatingCoil,       !- Name",
            "  Non Existent Cooling Coil, !- Coil Name",
            "  ,                        !- Availability Schedule Name",
            "  ,                        !- Severity Schedule Name",
            "  FouledUARated,           !- Fouling Input Method",
            "  3.32;                    !- UAFouled {W/K}",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state)
        ASSERT_THROW(FaultsManager.CheckAndReadFaults(state), RuntimeError)
        var error_string: String = delimited_string([
            "   ** Warning ** ProcessScheduleInput: Schedule:Compact = AVAILSCHED",
            "   **   ~~~   ** Schedule Type Limits Name is empty.",
            "   **   ~~~   ** Schedule will not be validated.",
            "   ** Severe  ** FaultModel:Fouling:Coil = \"FOULEDHEATINGCOIL\". Referenced Coil named \"NON EXISTENT COOLING COIL\" was not found.",
            "   **  Fatal  ** CheckAndReadFaults: Errors found in getting FaultModel input data. Preceding condition(s) cause termination.",
            "   ...Summary of Errors that led to program termination:",
            "   ..... Reference severe error count=1",
            "   ..... Last severe error=FaultModel:Fouling:Coil = \"FOULEDHEATINGCOIL\". Referenced Coil named \"NON EXISTENT COOLING COIL\" was not found.",
        ])
        EXPECT_TRUE(compare_err_stream(error_string, True))
class FaultsManager_FoulingCoil_BadCoilType(Test):
    def run(self, state: EnergyPlusData):
        var idf_objects: String = delimited_string([
            "Schedule:Compact,                                             ",
            "   AvailSched,         !- Name                                ",
            "   ,                   !- Schedule Type Limits Name           ",
            "   Through: 12/31,     !- Field 1                             ",
            "   For: AllDays,       !- Field 2                             ",
            "   Until: 24:00, 1.0;  !- Field 3                             ",
            "  Coil:Cooling:Water:DetailedGeometry,",
            "    Detailed Pre Cooling Coil, !- Name",
            "    ,                        !- Availability Schedule Name",
            "    autosize,                !- Maximum Water Flow Rate {m3/s}",
            "    autosize,                !- Tube Outside Surface Area {m2}",
            "    autosize,                !- Total Tube Inside Area {m2}",
            "    autosize,                !- Fin Surface Area {m2}",
            "    autosize,                !- Minimum Airflow Area {m2}",
            "    autosize,                !- Coil Depth {m}",
            "    autosize,                !- Fin Diameter {m}",
            "    ,                        !- Fin Thickness {m}",
            "    ,                        !- Tube Inside Diameter {m}",
            "    ,                        !- Tube Outside Diameter {m}",
            "    ,                        !- Tube Thermal Conductivity {W/m-K}",
            "    ,                        !- Fin Thermal Conductivity {W/m-K}",
            "    ,                        !- Fin Spacing {m}",
            "    ,                        !- Tube Depth Spacing {m}",
            "    ,                        !- Number of Tube Rows",
            "    autosize,                !- Number of Tubes per Row",
            "    Main Cooling Coil 1 Water Inlet Node,  !- Water Inlet Node Name",
            "    Main Cooling Coil 1 Water Outlet Node,  !- Water Outlet Node Name",
            "    Main Cooling Coil 1 Inlet Node,  !- Air Inlet Node Name",
            "    Main Cooling Coil 1 Outlet Node;  !- Air Outlet Node Name",
            "FaultModel:Fouling:Coil,",
            "  FouledHeatingCoil,       !- Name",
            "  Detailed Pre Cooling Coil, !- Coil Name",
            "  ,                        !- Availability Schedule Name",
            "  ,                        !- Severity Schedule Name",
            "  FouledUARated,           !- Fouling Input Method",
            "  3.32;                    !- UAFouled {W/K}",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state)
        ASSERT_THROW(FaultsManager.CheckAndReadFaults(state), RuntimeError)
        var error_string: String = delimited_string([
            "   ** Warning ** ProcessScheduleInput: Schedule:Compact = AVAILSCHED",
            "   **   ~~~   ** Schedule Type Limits Name is empty.",
            "   **   ~~~   ** Schedule will not be validated.",
            "   ** Severe  ** FaultModel:Fouling:Coil = \"FOULEDHEATINGCOIL\" invalid Coil Name = \"DETAILED PRE COOLING COIL\".",
            "   **   ~~~   ** Coil was found but it is not one of the supported types (\"Coil:Cooling:Water\" or \"Coil:Heating:Water\").",
            "   **  Fatal  ** CheckAndReadFaults: Errors found in getting FaultModel input data. Preceding condition(s) cause termination.",
            "   ...Summary of Errors that led to program termination:",
            "   ..... Reference severe error count=1",
            "   ..... Last severe error=FaultModel:Fouling:Coil = \"FOULEDHEATINGCOIL\" invalid Coil Name = \"DETAILED PRE COOLING COIL\".",
        ])
        EXPECT_TRUE(compare_err_stream(error_string, True))
class FaultsManager_FoulingCoil_AssignmentAndCalc(Test):
    def run(self, state: EnergyPlusData):
        var idf_objects: String = delimited_string([
            "ScheduleTypeLimits,",
            "  Fraction,                !- Name",
            "  0,                       !- Lower Limit Value",
            "  1,                       !- Upper Limit Value",
            "  Continuous;              !- Numeric Type",
            "Schedule:Compact,",
            "  AvailSched,              !- Name",
            "  Fraction,                !- Schedule Type Limits Name",
            "  Through: 12/31,          !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,1.00;       !- Field 3",
            "Schedule:Compact,",
            "  SeveritySched,           !- Name",
            "  Fraction,                !- Schedule Type Limits Name",
            "  Through: 12/31,          !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,0.75;       !- Field 3",
            "Coil:Heating:Water,",
            "  AHU HW Heating Coil,     !- Name",
            "  AvailSched,              !- Availability Schedule Name",
            "  6.64,                    !- U-Factor Times Area Value {W/K}",
            "  0.000010,                !- Maximum Water Flow Rate {m3/s}",
            "  AHU HW Heating Coil Water Inlet Node,  !- Water Inlet Node Name",
            "  AHU HW Heating Coil Water Outlet Node,  !- Water Outlet Node Name",
            "  Air Loop Reference AHU Cooling Coil Air Outlet Node,  !- Air Inlet Node Name",
            "  AHU HW Heating Coil Air Outlet Node,  !- Air Outlet Node Name",
            "  UFactorTimesAreaAndDesignWaterFlowRate,  !- Performance Input Method",
            "  438.32,                  !- Rated Capacity {W}",
            "  80,                      !- Rated Inlet Water Temperature {C}",
            "  16,                      !- Rated Inlet Air Temperature {C}",
            "  70,                      !- Rated Outlet Water Temperature {C}",
            "  35,                      !- Rated Outlet Air Temperature {C}",
            "  0.50;                    !- Rated Ratio for Air and Water Convection",
            "FaultModel:Fouling:Coil,",
            "  FouledHeatingCoil,       !- Name",
            "  AHU HW Heating Coil,     !- Coil Name",
            "  ,                        !- Availability Schedule Name",
            "  SeveritySched,           !- Severity Schedule Name",
            "  FouledUARated,           !- Fouling Input Method",
            "  3.32;                    !- UAFouled {W/K}",
            "Coil:Cooling:Water,",
            "   AHU CHW Cooling Coil,   !- Name",
            "   AvailSched,             !- Availability Schedule Name",
            "   autosize,               !- Design Water Flow Rate {m3/s}",
            "   autosize,               !- Design Air Flow Rate {m3/s}",
            "   autosize,               !- Design Inlet Water Temperature {C}",
            "   autosize,               !- Design Inlet Air Temperature {C}",
            "   autosize,               !- Design Outlet Air Temperature {C}",
            "   autosize,               !- Design Inlet Air Humidity Ratio {-}",
            "   autosize,               !- Design Outlet Air Humidity Ratio {-}",
            "   Water Inlet Node,       !- Water Inlet Node Name",
            "   Water Outlet Node,      !- Water Outlet Node Name",
            "   Air Inlet Node,         !- Air Inlet Node Name",
            "   Air Outlet Node,        !- Air Outlet Node Name",
            "   SimpleAnalysis,         !- Type of Analysis",
            "   CrossFlow;              !- Heat Exchanger Configuration",
            "FaultModel:Fouling:Coil,",
            "  FouledCoolingCoil,       !- Name",
            "  AHU CHW Cooling Coil,    !- Coil Name",
            "  AvailSched,              !- Availability Schedule Name",
            "  SeveritySched,           !- Severity Schedule Name",
            "  FoulingFactor,           !- Fouling Input Method",
            "  ,                        !- UAFouled {W/K}",
            "  0.0005,                  !- Water Side Fouling Factor, m2-K/W",
            "  0.0001,                  !- Air Side Fouling Factor, m2-K/W",
            "  100.0,                   !- Outside Coil Surface Area, m2",
            "  0.1;                     !- Inside to Outside Coil Surface Area Ratio",
            "Coil:Cooling:Water,",
            "   AHU CHW Coil With no fault, !- Name",
            "   AvailSched,             !- Availability Schedule Name",
            "   autosize,               !- Design Water Flow Rate {m3/s}",
            "   autosize,               !- Design Air Flow Rate {m3/s}",
            "   autosize,               !- Design Inlet Water Temperature {C}",
            "   autosize,               !- Design Inlet Air Temperature {C}",
            "   autosize,               !- Design Outlet Air Temperature {C}",
            "   autosize,               !- Design Inlet Air Humidity Ratio {-}",
            "   autosize,               !- Design Outlet Air Humidity Ratio {-}",
            "   Water 2 Inlet Node,     !- Water Inlet Node Name",
            "   Water 2 Outlet Node,    !- Water Outlet Node Name",
            "   Air 2 Inlet Node,       !- Air Inlet Node Name",
            "   Air 2 Outlet Node,      !- Air Outlet Node Name",
            "   SimpleAnalysis,         !- Type of Analysis",
            "   CrossFlow;              !- Heat Exchanger Configuration",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataHVACGlobal.TimeStepSys = 1
        state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        state.dataGlobal.TimeStepsInHour = 4
        state.dataGlobal.MinutesInTimeStep = 60 / state.dataGlobal.TimeStepsInHour
        state.init_state(state)
        var avaiSched = Sched.GetSchedule(state, "AVAILSCHED")
        EXPECT_NE(None, avaiSched)
        var severitySched = Sched.GetSchedule(state, "SEVERITYSCHED")
        EXPECT_NE(None, severitySched)
        ASSERT_NO_THROW(FaultsManager.CheckAndReadFaults(state))
        state.dataGlobal.TimeStep = 1
        state.dataGlobal.HourOfDay = 1
        state.dataEnvrn.DayOfWeek = 1
        state.dataEnvrn.DayOfYear_Schedule = 1
        Sched.UpdateScheduleVals(state)
        EXPECT_EQ(2, state.dataFaultsMgr.NumFouledCoil)
        EXPECT_EQ(3, state.dataWaterCoils.NumWaterCoils)
        {
            var CoilNum: Int = 0
            var FaultIndex: Int = 0
            EXPECT_EQ("AHU HW HEATING COIL", state.dataWaterCoils.WaterCoil[CoilNum].Name)
            EXPECT_NEAR(6.64, state.dataWaterCoils.WaterCoil[CoilNum].UACoil, 0.0001)
            EXPECT_ENUM_EQ(DataPlant.PlantEquipmentType.CoilWaterSimpleHeating, state.dataWaterCoils.WaterCoil[CoilNum].WaterCoilType)
            EXPECT_EQ(CoilNum + 1, state.dataFaultsMgr.FouledCoils[FaultIndex].FouledCoilNum)
            EXPECT_ENUM_EQ(DataPlant.PlantEquipmentType.CoilWaterSimpleHeating, state.dataFaultsMgr.FouledCoils[FaultIndex].FouledCoilType)
            EXPECT_TRUE(state.dataWaterCoils.WaterCoil[CoilNum].FaultyCoilFoulingFlag)
            EXPECT_EQ(FaultIndex + 1, state.dataWaterCoils.WaterCoil[CoilNum].FaultyCoilFoulingIndex)
            EXPECT_EQ(state.dataFaultsMgr.FouledCoils[FaultIndex].availSched.Num, Sched.SchedNum_AlwaysOn)
            EXPECT_NE(None, state.dataFaultsMgr.FouledCoils[FaultIndex].severitySched)
            EXPECT_ENUM_EQ(FaultsManager.FouledCoil.UARated, state.dataFaultsMgr.FouledCoils[FaultIndex].FoulingInputMethod)
            EXPECT_NEAR(3.32, state.dataFaultsMgr.FouledCoils[FaultIndex].UAFouled, 0.0001)
        }
        {
            var CoilNum: Int = 1
            var FaultIndex: Int = 1
            EXPECT_EQ("AHU CHW COOLING COIL", state.dataWaterCoils.WaterCoil[CoilNum].Name)
            EXPECT_ENUM_EQ(DataPlant.PlantEquipmentType.CoilWaterCooling, state.dataWaterCoils.WaterCoil[CoilNum].WaterCoilType)
            EXPECT_EQ(CoilNum + 1, state.dataFaultsMgr.FouledCoils[FaultIndex].FouledCoilNum)
            EXPECT_ENUM_EQ(DataPlant.PlantEquipmentType.CoilWaterCooling, state.dataFaultsMgr.FouledCoils[FaultIndex].FouledCoilType)
            EXPECT_TRUE(state.dataWaterCoils.WaterCoil[CoilNum].FaultyCoilFoulingFlag)
            EXPECT_EQ(FaultIndex + 1, state.dataWaterCoils.WaterCoil[CoilNum].FaultyCoilFoulingIndex)
            EXPECT_NE(None, state.dataFaultsMgr.FouledCoils[FaultIndex].availSched)
            EXPECT_NE(None, state.dataFaultsMgr.FouledCoils[FaultIndex].severitySched)
            EXPECT_ENUM_EQ(FaultsManager.FouledCoil.FoulingFactor, state.dataFaultsMgr.FouledCoils[FaultIndex].FoulingInputMethod)
            EXPECT_NEAR(0.0005, state.dataFaultsMgr.FouledCoils[FaultIndex].Rfw, 0.0001)
            EXPECT_NEAR(0.0001, state.dataFaultsMgr.FouledCoils[FaultIndex].Rfa, 0.0001)
            EXPECT_NEAR(100.0, state.dataFaultsMgr.FouledCoils[FaultIndex].Aout, 0.01)
            EXPECT_NEAR(0.1, state.dataFaultsMgr.FouledCoils[FaultIndex].Aratio, 0.0001)
        }
        {
            var CoilNum: Int = 2
            EXPECT_EQ("AHU CHW COIL WITH NO FAULT", state.dataWaterCoils.WaterCoil[CoilNum].Name)
            EXPECT_ENUM_EQ(DataPlant.PlantEquipmentType.CoilWaterCooling, state.dataWaterCoils.WaterCoil[CoilNum].WaterCoilType)
            EXPECT_FALSE(state.dataWaterCoils.WaterCoil[CoilNum].FaultyCoilFoulingFlag)
            EXPECT_EQ(0, state.dataWaterCoils.WaterCoil[CoilNum].FaultyCoilFoulingIndex)
        }