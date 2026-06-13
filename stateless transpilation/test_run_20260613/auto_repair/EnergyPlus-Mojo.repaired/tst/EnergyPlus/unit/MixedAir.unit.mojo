from gtest import *
from Fixtures.EnergyPlusFixture import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataContaminantBalance import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneControls import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.Humidifiers import *
from EnergyPlus.IOFiles import *
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.InternalHeatGains import *
from EnergyPlus.MixedAir import *
from EnergyPlus.OutAirNodeManager import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SingleDuct import *
from EnergyPlus.SizingManager import *
from EnergyPlus.ZoneAirLoopEquipmentManager import *
from EnergyPlus.ZoneEquipmentManager import *
using EnergyPlus.MixedAir.*
using EnergyPlus.DataContaminantBalance.*
using EnergyPlus.DataAirLoop.*
using EnergyPlus.DataAirSystems.*
using EnergyPlus.DataSizing.*
using EnergyPlus.DataHeatBalance.*
using EnergyPlus.DataEnvironment.*
using EnergyPlus.DataZoneEquipment.*
using EnergyPlus.DataZoneEnergyDemands.*
using EnergyPlus.DataZoneControls.*
using EnergyPlus.HeatBalanceManager.*
using EnergyPlus.Humidifiers.*
using EnergyPlus.SizingManager.*
using EnergyPlus.ZoneEquipmentManager.*

@fixture
class EnergyPlusFixture:

@test
def MixedAir_ProcessOAControllerTest():
    var idf_objects: String = delimited_string([
        "  OutdoorAir:Node,",
        "    Outside Air Inlet Node 1; !- Name",
        "  Controller:OutdoorAir,",
        "    OA Controller 1,         !- Name",
        "    Relief Air Outlet Node 1, !- Relief Air Outlet Node Name",
        "    VAV Sys 1 Inlet Node,    !- Return Air Node Name",
        "    Mixed Air Node 1,        !- Mixed Air Node Name",
        "    Outside Air Inlet Node 1, !- Actuator Node Name",
        "    autosize,                !- Minimum Outdoor Air Flow Rate {m3/s}",
        "    autosize,                !- Maximum Outdoor Air Flow Rate {m3/s}",
        "    NoEconomizer,            !- Economizer Control Type",
        "    ModulateFlow,            !- Economizer Control Action Type",
        "    ,                        !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
        "    ,                        !- Economizer Maximum Limit Enthalpy {J/kg}",
        "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
        "    ,                        !- Electronic Enthalpy Limit Curve Name",
        "    ,                        !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
        "    NoLockout,               !- Lockout Type",
        "    ProportionalMinimum;     !- Minimum Limit Type",
        "  Controller:OutdoorAir,",
        "    OA Controller 2,         !- Name",
        "    Relief Air Outlet Node 2, !- Relief Air Outlet Node Name",
        "    VAV Sys 2 Inlet Node,    !- Return Air Node Name",
        "    Mixed Air Node 2,        !- Mixed Air Node Name",
        "    Outside Air Inlet Node 2, !- Actuator Node Name",
        "    autosize,                !- Minimum Outdoor Air Flow Rate {m3/s}",
        "    autosize,                !- Maximum Outdoor Air Flow Rate {m3/s}",
        "    NoEconomizer,            !- Economizer Control Type",
        "    ModulateFlow,            !- Economizer Control Action Type",
        "    ,                        !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
        "    ,                        !- Economizer Maximum Limit Enthalpy {J/kg}",
        "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
        "    ,                        !- Electronic Enthalpy Limit Curve Name",
        "    ,                        !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
        "    NoLockout,               !- Lockout Type",
        "    ProportionalMinimum;     !- Minimum Limit Type",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    var ErrorsFound: Bool = false
    var ControllerNum: Int = 0
    var NumArg: Int = 0
    var NumNums: Int = 0
    var NumAlphas: Int = 0
    var IOStat: Int = 0
    var CurrentModuleObject: StringSlice = CurrentModuleObjects[Int(CMO.OAController)]
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, CurrentModuleObjects[Int(CMO.OAController)], NumArg, NumAlphas, NumNums)
    var NumArray: DynamicVector[Float64] = DynamicVector[Float64](NumNums, 0.0)
    var AlphArray: DynamicVector[String] = DynamicVector[String](NumAlphas)
    var cAlphaFields: DynamicVector[String] = DynamicVector[String](NumAlphas)
    var cNumericFields: DynamicVector[String] = DynamicVector[String](NumNums)
    var lAlphaBlanks: DynamicVector[Bool] = DynamicVector[Bool](NumAlphas, true)
    var lNumericBlanks: DynamicVector[Bool] = DynamicVector[Bool](NumNums, true)
    state.dataMixedAir.NumOAControllers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataMixedAir.OAController.allocate(state.dataMixedAir.NumOAControllers)
    ControllerNum = 1
    state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                              CurrentModuleObject,
                                                              ControllerNum,
                                                              AlphArray,
                                                              NumAlphas,
                                                              NumArray,
                                                              NumNums,
                                                              IOStat,
                                                              lNumericBlanks,
                                                              lAlphaBlanks,
                                                              cAlphaFields,
                                                              cNumericFields)
    ProcessOAControllerInputs(state,
                              CurrentModuleObject,
                              ControllerNum,
                              AlphArray,
                              NumAlphas,
                              NumArray,
                              NumNums,
                              lNumericBlanks,
                              lAlphaBlanks,
                              cAlphaFields,
                              cNumericFields,
                              ErrorsFound)
    assert_false(ErrorsFound)
    assert_equal(2, state.dataMixedAir.OAController[0].OANode)  # 0-based index for ControllerNum=1
    assert_true(OutAirNodeManager.CheckOutAirNodeNumber(state, state.dataMixedAir.OAController[0].OANode))
    ControllerNum = 2
    state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                              CurrentModuleObject,
                                                              ControllerNum,
                                                              AlphArray,
                                                              NumAlphas,
                                                              NumArray,
                                                              NumNums,
                                                              IOStat,
                                                              lNumericBlanks,
                                                              lAlphaBlanks,
                                                              cAlphaFields,
                                                              cNumericFields)
    ErrorsFound = false
    ProcessOAControllerInputs(state,
                              CurrentModuleObject,
                              ControllerNum,
                              AlphArray,
                              NumAlphas,
                              NumArray,
                              NumNums,
                              lNumericBlanks,
                              lAlphaBlanks,
                              cAlphaFields,
                              cNumericFields,
                              ErrorsFound)
    assert_false(ErrorsFound)
    assert_equal(6, state.dataMixedAir.OAController[1].OANode)  # 0-based for ControllerNum=2
    assert_false(OutAirNodeManager.CheckOutAirNodeNumber(state, state.dataMixedAir.OAController[1].OANode))

@test
def MixedAir_HXBypassOptionTest():
    var idf_objects: String = delimited_string(
        ["  OutdoorAir:Node,",
         "    Outside Air Inlet Node 1; !- Name",
         "  Controller:OutdoorAir,",
         "    OA Controller 1,         !- Name",
         "    Relief Air Outlet Node 1, !- Relief Air Outlet Node Name",
         "    VAV Sys 1 Inlet Node,    !- Return Air Node Name",
         "    Mixed Air Node 1,        !- Mixed Air Node Name",
         "    Outside Air Inlet Node 1, !- Actuator Node Name",
         "    0.2,                !- Minimum Outdoor Air Flow Rate {m3/s}",
         "    1.0,                !- Maximum Outdoor Air Flow Rate {m3/s}",
         "    DifferentialDryBulb,     !- Economizer Control Type",
         "    ModulateFlow,            !- Economizer Control Action Type",
         "    ,                        !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
         "    ,                        !- Economizer Maximum Limit Enthalpy {J/kg}",
         "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
         "    ,                        !- Electronic Enthalpy Limit Curve Name",
         "    ,                        !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
         "    NoLockout,               !- Lockout Type",
         "    ProportionalMinimum,     !- Minimum Limit Type",
         "    ,                        !- Minimum Outdoor Air Schedule Name",
         "    ,                        !- Minimum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Maximum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Mechanical Ventilation Controller Name",
         "    ,                        !- Time of Day Economizer Control Schedule Name",
         "    No,                      !- High Humidity Control",
         "    ,                        !- Humidistat Control Zone Name",
         "    ,                        !- High Humidity Outdoor Air Flow Ratio",
         "    Yes,                     !- Control High Indoor Humidity Based on Outdoor Humidity Ratio",
         "    BypassWhenWithinEconomizerLimits;  !- Heat Recovery Bypass Control Type",
         "  OutdoorAir:Mixer,",
         "    OA Mixer 1,                !- Name",
         "    Mixed Air Node 1,          !- Mixed Air Node Name",
         "    Outside Air Inlet Node 1, !- Outdoor Air Stream Node Name",
         "    Relief Air Outlet Node 1,  !- Relief Air Stream Node Name",
         "    VAV Sys 1 Inlet Node;     !- Return Air Stream Node Name",
         " AirLoopHVAC:ControllerList,",
         "    OA Sys 1 controller,     !- Name",
         "    Controller:OutdoorAir,   !- Controller 1 Object Type",
         "    OA Controller 1;         !- Controller 1 Name",
         " AirLoopHVAC:OutdoorAirSystem:EquipmentList,",
         "    OA Sys 1 Equipment list, !- Name",
         "    OutdoorAir:Mixer,        !- Component 1 Object Type",
         "    OA Mixer 1;                !- Component 1 Name",
         " AirLoopHVAC:OutdoorAirSystem,",
         "    OA Sys 1, !- Name",
         "    OA Sys 1 controller,     !- Controller List Name",
         "    OA Sys 1 Equipment list; !- Outdoor Air Equipment List Name",
         "  Controller:OutdoorAir,",
         "    OA Controller 2,         !- Name",
         "    Relief Air Outlet Node 2, !- Relief Air Outlet Node Name",
         "    VAV Sys 2 Inlet Node,    !- Return Air Node Name",
         "    Mixed Air Node 2,        !- Mixed Air Node Name",
         "    Outside Air Inlet Node 2, !- Actuator Node Name",
         "    0.2,                !- Minimum Outdoor Air Flow Rate {m3/s}",
         "    1.0,                !- Maximum Outdoor Air Flow Rate {m3/s}",
         "    DifferentialDryBulb,     !- Economizer Control Type",
         "    ModulateFlow,            !- Economizer Control Action Type",
         "    ,                        !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
         "    ,                        !- Economizer Maximum Limit Enthalpy {J/kg}",
         "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
         "    ,                        !- Electronic Enthalpy Limit Curve Name",
         "    ,                        !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
         "    LockoutWithHeating,               !- Lockout Type",
         "    ProportionalMinimum,     !- Minimum Limit Type",
         "    ,                        !- Minimum Outdoor Air Schedule Name",
         "    ,                        !- Minimum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Maximum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Mechanical Ventilation Controller Name",
         "    ,                        !- Time of Day Economizer Control Schedule Name",
         "    No,                      !- High Humidity Control",
         "    ,                        !- Humidistat Control Zone Name",
         "    ,                        !- High Humidity Outdoor Air Flow Ratio",
         "    Yes,                     !- Control High Indoor Humidity Based on Outdoor Humidity Ratio",
         "    BypassWhenWithinEconomizerLimits;  !- Heat Recovery Bypass Control Type",
         "  OutdoorAir:Mixer,",
         "    OA Mixer 2,                !- Name",
         "    Mixed Air Node 2,          !- Mixed Air Node Name",
         "    Outside Air Inlet Node 2, !- Outdoor Air Stream Node Name",
         "    Relief Air Outlet Node 2,  !- Relief Air Stream Node Name",
         "    VAV Sys 2 Inlet Node;     !- Return Air Stream Node Name",
         " AirLoopHVAC:ControllerList,",
         "    OA Sys 2 controller,     !- Name",
         "    Controller:OutdoorAir,   !- Controller 1 Object Type",
         "    OA Controller 2;         !- Controller 1 Name",
         " AirLoopHVAC:OutdoorAirSystem:EquipmentList,",
         "    OA Sys 2 Equipment list, !- Name",
         "    OutdoorAir:Mixer,        !- Component 1 Object Type",
         "    OA Mixer 2;                !- Component 1 Name",
         " AirLoopHVAC:OutdoorAirSystem,",
         "    OA Sys 2, !- Name",
         "    OA Sys 2 controller,     !- Controller List Name",
         "    OA Sys 2 Equipment list; !- Outdoor Air Equipment List Name",
         "  Controller:OutdoorAir,",
         "    OA Controller 3,         !- Name",
         "    Relief Air Outlet Node 3, !- Relief Air Outlet Node Name",
         "    VAV Sys 3 Inlet Node,    !- Return Air Node Name",
         "    Mixed Air Node 3,        !- Mixed Air Node Name",
         "    Outside Air Inlet Node 3, !- Actuator Node Name",
         "    0.2,                !- Minimum Outdoor Air Flow Rate {m3/s}",
         "    1.0,                !- Maximum Outdoor Air Flow Rate {m3/s}",
         "    DifferentialDryBulb,     !- Economizer Control Type",
         "    ModulateFlow,            !- Economizer Control Action Type",
         "    ,                        !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
         "    ,                        !- Economizer Maximum Limit Enthalpy {J/kg}",
         "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
         "    ,                        !- Electronic Enthalpy Limit Curve Name",
         "    ,                        !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
         "    NoLockout,               !- Lockout Type",
         "    ProportionalMinimum,     !- Minimum Limit Type",
         "    ,                        !- Minimum Outdoor Air Schedule Name",
         "    ,                        !- Minimum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Maximum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Mechanical Ventilation Controller Name",
         "    ,                        !- Time of Day Economizer Control Schedule Name",
         "    No,                      !- High Humidity Control",
         "    ,                        !- Humidistat Control Zone Name",
         "    ,                        !- High Humidity Outdoor Air Flow Ratio",
         "    Yes,                     !- Control High Indoor Humidity Based on Outdoor Humidity Ratio",
         "    BypassWhenOAFlowGreaterThanMinimum;  !- Heat Recovery Bypass Control Type",
         "  OutdoorAir:Mixer,",
         "    OA Mixer 3,                !- Name",
         "    Mixed Air Node 3,          !- Mixed Air Node Name",
         "    Outside Air Inlet Node 3, !- Outdoor Air Stream Node Name",
         "    Relief Air Outlet Node 3,  !- Relief Air Stream Node Name",
         "    VAV Sys 3 Inlet Node;     !- Return Air Stream Node Name",
         " AirLoopHVAC:ControllerList,",
         "    OA Sys 3 controller,     !- Name",
         "    Controller:OutdoorAir,   !- Controller 1 Object Type",
         "    OA Controller 3;         !- Controller 1 Name",
         " AirLoopHVAC:OutdoorAirSystem:EquipmentList,",
         "    OA Sys 3 Equipment list, !- Name",
         "    OutdoorAir:Mixer,        !- Component 1 Object Type",
         "    OA Mixer 3;                !- Component 1 Name",
         " AirLoopHVAC:OutdoorAirSystem,",
         "    OA Sys 3, !- Name",
         "    OA Sys 3 controller,     !- Controller List Name",
         "    OA Sys 3 Equipment list; !- Outdoor Air Equipment List Name",
         "  Controller:OutdoorAir,",
         "    OA Controller 4,         !- Name",
         "    Relief Air Outlet Node 4, !- Relief Air Outlet Node Name",
         "    VAV Sys 4 Inlet Node,    !- Return Air Node Name",
         "    Mixed Air Node 4,        !- Mixed Air Node Name",
         "    Outside Air Inlet Node 4, !- Actuator Node Name",
         "    0.2,                !- Minimum Outdoor Air Flow Rate {m3/s}",
         "    1.0,                !- Maximum Outdoor Air Flow Rate {m3/s}",
         "    DifferentialDryBulb,     !- Economizer Control Type",
         "    ModulateFlow,            !- Economizer Control Action Type",
         "    ,                        !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
         "    ,                        !- Economizer Maximum Limit Enthalpy {J/kg}",
         "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
         "    ,                        !- Electronic Enthalpy Limit Curve Name",
         "    ,                        !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
         "    NoLockout,               !- Lockout Type",
         "    ProportionalMinimum,     !- Minimum Limit Type",
         "    ,                        !- Minimum Outdoor Air Schedule Name",
         "    ,                        !- Minimum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Maximum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Mechanical Ventilation Controller Name",
         "    ,                        !- Time of Day Economizer Control Schedule Name",
         "    No,                      !- High Humidity Control",
         "    ,                        !- Humidistat Control Zone Name",
         "    ,                        !- High Humidity Outdoor Air Flow Ratio",
         "    Yes,                     !- Control High Indoor Humidity Based on Outdoor Humidity Ratio",
         "    BypassWhenOAFlowGreaterThanMinimum;  !- Heat Recovery Bypass Control Type",
         "  OutdoorAir:Mixer,",
         "    OA Mixer 4,                !- Name",
         "    Mixed Air Node 4,          !- Mixed Air Node Name",
         "    Outside Air Inlet Node 4, !- Outdoor Air Stream Node Name",
         "    Relief Air Outlet Node 4,  !- Relief Air Stream Node Name",
         "    VAV Sys 4 Inlet Node;     !- Return Air Stream Node Name",
         " AirLoopHVAC:ControllerList,",
         "    OA Sys 4 controller,     !- Name",
         "    Controller:OutdoorAir,   !- Controller 1 Object Type",
         "    OA Controller 4;         !- Controller 1 Name",
         " AirLoopHVAC:OutdoorAirSystem:EquipmentList,",
         "    OA Sys 4 Equipment list, !- Name",
         "    OutdoorAir:Mixer,        !- Component 1 Object Type",
         "    OA Mixer 4;                !- Component 1 Name",
         " AirLoopHVAC:OutdoorAirSystem,",
         "    OA Sys 4, !- Name",
         "    OA Sys 4 controller,     !- Controller List Name",
         "    OA Sys 4 Equipment list; !- Outdoor Air Equipment List Name",
         "  Controller:OutdoorAir,",
         "    OA Controller 5,         !- Name",
         "    Relief Air Outlet Node 5, !- Relief Air Outlet Node Name",
         "    VAV Sys 5 Inlet Node,    !- Return Air Node Name",
         "    Mixed Air Node 5,        !- Mixed Air Node Name",
         "    Outside Air Inlet Node 5, !- Actuator Node Name",
         "    0.2,                !- Minimum Outdoor Air Flow Rate {m3/s}",
         "    1.0,                !- Maximum Outdoor Air Flow Rate {m3/s}",
         "    DifferentialDryBulb,     !- Economizer Control Type",
         "    ModulateFlow,            !- Economizer Control Action Type",
         "    ,                        !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
         "    ,                        !- Economizer Maximum Limit Enthalpy {J/kg}",
         "    ,                        !- Economizer Maximum Limit Dewpoint Temperature {C}",
         "    ,                        !- Electronic Enthalpy Limit Curve Name",
         "    ,                        !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
         "    NoLockout,               !- Lockout Type",
         "    ProportionalMinimum,     !- Minimum Limit Type",
         "    ,                        !- Minimum Outdoor Air Schedule Name",
         "    ,                        !- Minimum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Maximum Fraction of Outdoor Air Schedule Name",
         "    ,                        !- Mechanical Ventilation Controller Name",
         "    ,                        !- Time of Day Economizer Control Schedule Name",
         "    No,                      !- High Humidity Control",
         "    ,                        !- Humidistat Control Zone Name",
         "    ,                        !- High Humidity Outdoor Air Flow Ratio",
         "    No,                      !- Control High Indoor Humidity Based on Outdoor Humidity Ratio",
         "    BypassWhenOAFlowGreaterThanMinimum;  !- Heat Recovery Bypass Control Type",
         "  OutdoorAir:Mixer,",
         "    OA Mixer 5,                !- Name",
         "    Mixed Air Node 5,          !- Mixed Air Node Name",
         "    OA Sys 5 HC Outlet Node,   !- Outdoor Air Stream Node Name",
         "    Relief Air Outlet Node 5,  !- Relief Air Stream Node Name",
         "    VAV Sys 5 Inlet Node;     !- Return Air Stream Node Name",
         " AirLoopHVAC:ControllerList,",
         "    OA Sys 5 controller,     !- Name",
         "    Controller:OutdoorAir,   !- Controller 1 Object Type",
         "    OA Controller 5;         !- Controller 1 Name",
         " AirLoopHVAC:OutdoorAirSystem:EquipmentList,",
         "    OA Sys 5 Equipment list, !- Name",
         "    Coil:Heating:Electric,    !- Component 1 Object Type",
         "    OA Sys 5 Heating Coil,    !- Component 1 Name",
         "    OutdoorAir:Mixer,         !- Component 2 Object Type",
         "    OA Mixer 5;               !- Component 2 Name",
         " AirLoopHVAC:OutdoorAirSystem,",
         "    OA Sys 5, !- Name",
         "    OA Sys 5 controller,      !- Controller List Name",
         "    OA Sys 5 Equipment list;  !- Outdoor Air Equipment List Name",
         " Coil:Heating:Electric,",
         "    OA Sys 5 Heating Coil,    !- Name",
         "    ,                         !- Availability Schedule Name",
         "    1,                        !- Efficiency",
         "    2500,                     !- Nominal Capacity{ W }",
         "    Outside Air Inlet Node 5, !- Air Inlet Node Name",
         "    OA Sys 5 HC Outlet Node,  !- Air Outlet Node Name",
         "    OA Sys 5 HC Outlet Node;  !- Temperature Setpoint Node Name"
        ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    GetOAControllerInputs(state)
    expect_equal(2, state.dataMixedAir.OAController[0].OANode)
    expect_true(OutAirNodeManager.CheckOutAirNodeNumber(state, state.dataMixedAir.OAController[0].OANode))
    expect_equal(6, state.dataMixedAir.OAController[1].OANode)
    expect_false(OutAirNodeManager.CheckOutAirNodeNumber(state, state.dataMixedAir.OAController[1].OANode))
    var OAControllerNum: Int
    var AirLoopNum: Int
    state.dataHVACGlobal.NumPrimaryAirSys = 5
    state.dataAirLoop.AirLoopControlInfo.allocate(5)
    state.dataAirLoop.AirLoopFlow.allocate(5)
    state.dataAirSystemsData.PrimaryAirSystems.allocate(5)
    state.dataLoopNodes.Node.allocate(21)
    state.dataEnvrn.StdBaroPress = StdPressureSeaLevel
    state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, 20.0, 0.0)
    for AirLoopNum in range(1, 6):
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].OASysNum = AirLoopNum
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].EconoLockout = false
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].NightVent = false
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].fanOp = HVAC.FanOp.Continuous
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].LoopFlowRateSet = false
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].CheckHeatRecoveryBypassStatus = true
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].OASysComponentsSimulated = true
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].EconomizerFlowLocked = false
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatRecoveryBypass = false
        state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatRecoveryResimFlag = false
        state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].DesSupply = 1.0 * state.dataEnvrn.StdRhoAir
        state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].NumBranches = 1
        state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].Branch.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].Branch[0].TotalComponents = 1
        state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum - 1].Branch[0].Comp.allocate(1)
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "OA Sys 1"
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].TypeOf = "AirLoopHVAC:OutdoorAirSystem"
    state.dataAirSystemsData.PrimaryAirSystems[1].Branch[0].Comp[0].Name = "OA Sys 2"
    state.dataAirSystemsData.PrimaryAirSystems[1].Branch[0].Comp[0].TypeOf = "AirLoopHVAC:OutdoorAirSystem"
    state.dataAirSystemsData.PrimaryAirSystems[2].Branch[0].Comp[0].Name = "OA Sys 3"
    state.dataAirSystemsData.PrimaryAirSystems[2].Branch[0].Comp[0].TypeOf = "AirLoopHVAC:OutdoorAirSystem"
    state.dataAirSystemsData.PrimaryAirSystems[3].Branch[0].Comp[0].Name = "OA Sys 4"
    state.dataAirSystemsData.PrimaryAirSystems[3].Branch[0].Comp[0].TypeOf = "AirLoopHVAC:OutdoorAirSystem"
    for OAControllerNum in range(1, 6):
        state.dataMixedAir.OAController[OAControllerNum - 1].MinOAMassFlowRate = \
            state.dataMixedAir.OAController[OAControllerNum - 1].MinOA * state.dataEnvrn.StdRhoAir
        state.dataMixedAir.OAController[OAControllerNum - 1].MaxOAMassFlowRate = \
            state.dataMixedAir.OAController[OAControllerNum - 1].MaxOA * state.dataEnvrn.StdRhoAir
        if OAControllerNum == 5:
            state.dataMixedAir.OAController[OAControllerNum - 1].InletNode = 18
        else:
            state.dataMixedAir.OAController[OAControllerNum - 1].InletNode = state.dataMixedAir.OAController[OAControllerNum - 1].OANode
        state.dataMixedAir.OAController[OAControllerNum - 1].RetTemp = 24.0
        state.dataMixedAir.OAController[OAControllerNum - 1].InletTemp = 20.0
        state.dataMixedAir.OAController[OAControllerNum - 1].OATemp = 20.0
        state.dataMixedAir.OAController[OAControllerNum - 1].MixSetTemp = 22.0
        state.dataMixedAir.OAController[OAControllerNum - 1].ExhMassFlow = 0.0
        state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow = 0.5
        state.dataLoopNodes.Node[OAControllerNum * 4 - 1].MassFlowRate = \
            state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow
        state.dataLoopNodes.Node[OAControllerNum + (OAControllerNum - 1) * 3 - 1].MassFlowRateMaxAvail = \
            state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow
        state.dataLoopNodes.Node[OAControllerNum * 4 - 1].Temp = state.dataMixedAir.OAController[OAControllerNum - 1].RetTemp
        state.dataLoopNodes.Node[OAControllerNum * 4 - 1].Enthalpy = \
            Psychrometrics.PsyHFnTdbW(state.dataMixedAir.OAController[OAControllerNum - 1].RetTemp, 0.0)
        state.dataLoopNodes.Node[OAControllerNum * 4 - 4].TempSetPoint = \
            state.dataMixedAir.OAController[OAControllerNum - 1].MixSetTemp
        if OAControllerNum == 5:
            state.dataLoopNodes.Node[17].TempSetPoint = state.dataMixedAir.OAController[OAControllerNum - 1].MixSetTemp + 1.0
        state.dataLoopNodes.Node[OAControllerNum * 4 - 3].Temp = \
            state.dataMixedAir.OAController[OAControllerNum - 1].OATemp
        state.dataLoopNodes.Node[OAControllerNum * 4 - 3].Enthalpy = \
            Psychrometrics.PsyHFnTdbW(state.dataMixedAir.OAController[OAControllerNum - 1].InletTemp, 0.0)
    var expectedOAflow: Float64 = 0.0
    var expectedMinOAflow: Float64 = 0.0
    AirLoopNum = 1
    OAControllerNum = 1
    state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatingActiveFlag = true
    state.dataMixedAir.OAController[OAControllerNum - 1].CalcOAController(state, AirLoopNum, true)
    expectedMinOAflow = 0.2 * state.dataEnvrn.StdRhoAir * state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow / \
                        state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].DesSupply
    expectedOAflow = state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow * \
                     (state.dataMixedAir.OAController[OAControllerNum - 1].MixSetTemp - state.dataMixedAir.OAController[OAControllerNum - 1].RetTemp) / \
                     (state.dataMixedAir.OAController[OAControllerNum - 1].InletTemp - state.dataMixedAir.OAController[OAControllerNum - 1].RetTemp)
    expect_near(expectedOAflow, state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow, 0.00001)
    expect_near(state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAFrac, 0.00001)
    expect_equal(expectedMinOAflow, state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].MinOutAir)
    expect_equal(expectedMinOAflow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                 state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAMinFrac)
    expect_true(state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatRecoveryBypass)
    expect_equal(1, state.dataMixedAir.OAController[OAControllerNum - 1].HeatRecoveryBypassStatus)
    AirLoopNum = 2
    OAControllerNum = 2
    state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatingActiveFlag = true
    state.dataMixedAir.OAController[OAControllerNum - 1].InletTemp = 0.0
    state.dataMixedAir.OAController[OAControllerNum - 1].OATemp = 0.0
    state.dataLoopNodes.Node[OAControllerNum * 4 - 3].Temp = \
        state.dataMixedAir.OAController[OAControllerNum - 1].OATemp
    state.dataMixedAir.OAController[OAControllerNum - 1].CalcOAController(state, AirLoopNum, true)
    expectedMinOAflow = 0.2 * state.dataEnvrn.StdRhoAir * state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow / \
                        state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].DesSupply
    expectedOAflow = expectedMinOAflow
    expect_near(expectedOAflow, state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow, 0.00001)
    expect_near(state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAFrac, 0.00001)
    expect_equal(expectedMinOAflow, state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].MinOutAir)
    expect_equal(expectedMinOAflow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                 state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAMinFrac)
    expect_false(state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatRecoveryBypass)
    expect_equal(0, state.dataMixedAir.OAController[OAControllerNum - 1].HeatRecoveryBypassStatus)
    AirLoopNum = 3
    OAControllerNum = 3
    state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatingActiveFlag = true
    state.dataMixedAir.OAController[OAControllerNum - 1].InletTemp = 20.0
    state.dataMixedAir.OAController[OAControllerNum - 1].OATemp = 20.0
    state.dataLoopNodes.Node[OAControllerNum * 4 - 3].Temp = \
        state.dataMixedAir.OAController[OAControllerNum - 1].OATemp
    state.dataMixedAir.OAController[OAControllerNum - 1].CalcOAController(state, AirLoopNum, true)
    expectedMinOAflow = 0.2 * state.dataEnvrn.StdRhoAir * state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow / \
                        state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].DesSupply
    expectedOAflow = state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow * \
                     (state.dataMixedAir.OAController[OAControllerNum - 1].MixSetTemp - state.dataMixedAir.OAController[OAControllerNum - 1].RetTemp) / \
                     (state.dataMixedAir.OAController[OAControllerNum - 1].InletTemp - state.dataMixedAir.OAController[OAControllerNum - 1].RetTemp)
    expect_near(expectedOAflow, state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow, 0.00001)
    expect_near(state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAFrac, 0.00001)
    expect_equal(expectedMinOAflow, state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].MinOutAir)
    expect_equal(expectedMinOAflow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                 state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAMinFrac)
    expect_true(state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatRecoveryBypass)
    expect_equal(1, state.dataMixedAir.OAController[OAControllerNum - 1].HeatRecoveryBypassStatus)
    AirLoopNum = 4
    OAControllerNum = 4
    state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatingActiveFlag = true
    state.dataMixedAir.OAController[OAControllerNum - 1].InletTemp = 0.0
    state.dataMixedAir.OAController[OAControllerNum - 1].OATemp = 0.0
    state.dataLoopNodes.Node[OAControllerNum * 4 - 3].Temp = \
        state.dataMixedAir.OAController[OAControllerNum - 1].OATemp
    state.dataMixedAir.OAController[OAControllerNum - 1].CalcOAController(state, AirLoopNum, true)
    expectedMinOAflow = 0.2 * state.dataEnvrn.StdRhoAir * state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow / \
                        state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].DesSupply
    expectedOAflow = expectedMinOAflow
    expect_near(expectedOAflow, state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow, 0.00001)
    expect_near(state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAFrac, 0.00001)
    expect_equal(expectedMinOAflow, state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].MinOutAir)
    expect_equal(expectedMinOAflow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                 state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAMinFrac)
    expect_false(state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatRecoveryBypass)
    expect_equal(0, state.dataMixedAir.OAController[OAControllerNum - 1].HeatRecoveryBypassStatus)
    AirLoopNum = 5
    OAControllerNum = 5
    state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatingActiveFlag = false
    state.dataMixedAir.OAController[OAControllerNum - 1].InletTemp = 20.0
    state.dataMixedAir.OAController[OAControllerNum - 1].OATemp = 20.0
    state.dataLoopNodes.Node[OAControllerNum * 4 - 4].MassFlowRate = \
        state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow
    state.dataLoopNodes.Node[OAControllerNum * 4 - 3].Temp = \
        state.dataMixedAir.OAController[OAControllerNum - 1].OATemp
    state.dataMixedAir.OAController[OAControllerNum - 1].CalcOAController(state, AirLoopNum, true)
    expectedMinOAflow = 0.2 * state.dataEnvrn.StdRhoAir * state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow / \
                        state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].DesSupply
    expectedOAflow = expectedMinOAflow
    expect_gt(state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow, expectedOAflow)
    expect_near(state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAFrac, 0.00001)
    expect_near(state.dataMixedAir.OAController[OAControllerNum - 1].OAMassFlow, 0.145329, 0.000001)
    expect_equal(expectedMinOAflow, state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].MinOutAir)
    expect_equal(expectedMinOAflow / state.dataMixedAir.OAController[OAControllerNum - 1].MixMassFlow,
                 state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].OAMinFrac)
    expect_false(state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].HeatRecoveryBypass)
    expect_equal(0, state.dataMixedAir.OAController[OAControllerNum - 1].HeatRecoveryBypassStatus)

@test
def CO2ControlDesignOccupancyTest():
    var idf_objects: String = delimited_string([
        "  OutdoorAir:Node,",
        "    Outside Air Inlet Node; !- Name",
        "  Schedule:Constant,",
        "    VentSchedule, !- Name",
        "     , !- Schedule Type Limits Name",
        "     1; !- Hourly value",
        "  Schedule:Constant,",
        "    ZoneADEffSch, !- Name",
        "     , !- Schedule Type Limits Name",
        "     1; !- Hourly value",
        "  Schedule:Constant,",
        "    OAFractionSched, !- Name",
        "     , !- Schedule Type Limits Name",
        "     1; !- Hourly value",
        "  Schedule:Constant,",
        "    CO2AvailSchedule, !- Name",
        "     , !- Schedule Type Limits Name",
        "     1.0; !- Hourly value",
        "People,",
        "    West Zone People,           !- Name",
        "    West Zone,                  !- Zone or ZoneList Name",
        "    OCCUPY-1,                !- Number of People Schedule Name",
        "    people,                  !- Number of People Calculation Method",
        "    11,                      !- Number of People",
        "    ,                        !- People per Zone Floor Area {person/m2}",
        "    ,                        !- Zone Floor Area per Person {m2/person}",
        "    0.3,                     !- Fraction Radiant",
        "    ,                        !- Sensible Heat Fraction",
        "    ActSchd;                 !- Activity Level Schedule Name",
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
        "    ActSchd,                 !- Name",
        "    Any Number,              !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 117.239997864;",
        "                             !- Field 4",
        "  Controller:OutdoorAir,",
        "    OA Controller 1, !- Name",
        "    Relief Air Outlet Node, !- Relief Air Outlet Node Name",
        "    Outdoor Air Mixer Inlet Node, !- Return Air Node Name",
        "    Mixed Air Node, !- Mixed Air Node Name",
        "    Outside Air Inlet Node, !- Actuator Node Name",
        "    0.0, !- Minimum Outdoor Air Flow Rate{ m3 / s }",
        "    1.7, !- Maximum Outdoor Air Flow Rate{ m3 / s }",
        "    NoEconomizer, !- Economizer Control Type",
        "    ModulateFlow, !- Economizer Control Action Type",
        "    , !- Economizer Maximum Limit Dry - Bulb Temperature{ C }",
        "    , !- Economizer Maximum Limit Enthalpy{ J / kg }",
        "    , !- Economizer Maximum Limit Dewpoint Temperature{ C }",
        "    , !- Electronic Enthalpy Limit Curve Name",
        "    , !- Economizer Minimum Limit Dry - Bulb Temperature{ C }",
        "    NoLockout, !- Lockout Type",
        "    FixedMinimum, !- Minimum Limit Type",
        "    OAFractionSched, !- Minimum Outdoor Air Schedule Name",
        "    , !- Minimum Fraction of Outdoor Air Schedule Name",
        "    , !- Maximum Fraction of Outdoor Air Schedule Name",
        "    DCVObject;               !- Mechanical Ventilation Controller Name",
        "  Controller:MechanicalVentilation,",
        "    DCVObject, !- Name",
        "    VentSchedule, !- Availability Schedule Name",
        "    Yes, !- Demand Controlled Ventilation",
        "    ProportionalControlBasedonDesignOccupancy, !- System Outdoor Air Method",
        "     , !- Zone Maximum Outdoor Air Fraction{ dimensionless }",
        "    West Zone, !- Zone 1 Name",
        "    CM DSOA West Zone, !- Design Specification Outdoor Air Object Name 1",
        "    CM DSZAD West Zone; !- Design Specification Zone Air Distribution Object Name 1",
    ])
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 4
    state.dataGlobal.MinutesInTimeStep = 15
    state.init_state(state)
    state.dataContaminantBalance.Contaminant.CO2Simulation = true
    state.dataContaminantBalance.Contaminant.CO2OutdoorSched = Sched.GetSchedule(state, "OCCUPY-1")
    state.dataAirLoop.AirLoopControlInfo.allocate(1)
    state.dataAirLoop.AirLoopControlInfo[0].LoopFlowRateSet = true
    state.dataSize.OARequirements.allocate(1)
    var oaRequirements: ref = state.dataSize.OARequirements[0]
    oaRequirements.Name = "CM DSOA WEST ZONE"
    oaRequirements.OAFlowMethod = OAFlowCalcMethod.Sum
    oaRequirements.OAFlowPerPerson = 0.003149
    oaRequirements.OAFlowPerArea = 0.000407
    oaRequirements.oaFlowFracSched = Sched.GetScheduleAlwaysOn(state)
    state.dataSize.ZoneAirDistribution.allocate(1)
    state.dataSize.ZoneAirDistribution[0].Name = "CM DSZAD WEST ZONE"
    state.dataSize.ZoneAirDistribution[0].zoneADEffSched = Sched.GetSchedule(state, "ZONEADEFFSCH")
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[0].Name = "WEST ZONE"
    state.dataHeatBal.Zone[0].FloorArea = 10.0
    state.dataHeatBal.Zone[0].zoneContamControllerSched = Sched.GetSchedule(state, "ZONEADEFFSCH")
    state.dataHeatBal.Zone[0].numSpaces = 1
    state.dataHeatBal.Zone[0].spaceIndexes.append(1)
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.space.allocate(1)
    state.dataHeatBal.space[0].Name = "WEST ZONE"
    state.dataHeatBal.space[0].FloorArea = 10.0
    state.dataHeatBal.space[0].zoneNum = 1
    state.dataGlobal.numSpaces = 1
    DataHeatBalance.AllocateIntGains(state)
    state.dataAirLoop.AirLoopFlow.allocate(1)
    state.dataAirLoop.AirLoopFlow[0].OAFrac = 0.01
    state.dataAirLoop.AirLoopFlow[0].OAMinFrac = 0.01
    state.dataEnvrn.StdBaroPress = StdPressureSeaLevel
    state.dataEnvrn.OutDryBulbTemp = 13.0
    state.dataEnvrn.OutBaroPress = StdPressureSeaLevel
    state.dataEnvrn.OutHumRat = 0.008
    state.dataEnvrn.StdRhoAir = \
        Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutHumRat)
    InternalHeatGains.GetInternalHeatGainsInput(state)
    GetOAControllerInputs(state)
    var oaController: ref = state.dataMixedAir.OAController[0]
    var ventMechanical: ref = state.dataMixedAir.VentilationMechanical[0]
    expect_equal(SysOAMethod.ProportionalControlDesOcc, ventMechanical.SystemOAMethod)
    expect_true(OutAirNodeManager.CheckOutAirNodeNumber(state, oaController.OANode))
    var oaReq1: ref = state.dataSize.OARequirements[ventMechanical.VentMechZone[0].ZoneDesignSpecOAObjIndex - 1]  # 0-based index
    var zoneNum1: Int = ventMechanical.VentMechZone[0].zoneNum
    var expectedOAPerPerson1: Float64 = oaReq1.desFlowPerZonePerson(state, zoneNum1)
    var expectedOAPerArea1: Float64 = oaReq1.desFlowPerZoneArea(state, zoneNum1)
    expect_near(0.00314899, expectedOAPerPerson1, 0.00001)
    expect_near(0.000407, expectedOAPerArea1, 0.00001)
    ventMechanical.availSched = Sched.GetSchedule(state, "OCCUPY-1")
    ventMechanical.availSched.currentVal = 1.0
    ventMechanical.VentMechZone[0].zoneADEffSched = Sched.GetSchedule(state, "ACTSCHD")
    ventMechanical.VentMechZone[0].zoneADEffSched.currentVal = 1.0
    state.dataHeatBal.Zone[0].TotOccupants = 3
    Sched.GetSchedule(state, "ZONEADEFFSCH").currentVal = 1.0
    state.dataContaminantBalance.ZoneCO2GainFromPeople.allocate(1)
    state.dataContaminantBalance.ZoneCO2GainFromPeople[0] = 3.82E-8
    state.dataContaminantBalance.OutdoorCO2 = 400
    state.dataContaminantBalance.ZoneAirCO2.allocate(1)
    state.dataContaminantBalance.ZoneAirCO2[0] = 600.0
    state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].AirDistUnitCool.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].AirDistUnitCool[0].InNode = 10
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 10
    state.dataLoopNodes.Node.allocate(10)
    state.dataLoopNodes.Node[9].Temp = 13.00
    state.dataLoopNodes.Node[9].HumRat = 0.008
    state.dataLoopNodes.Node[9].MassFlowRate = 1.7 * state.dataEnvrn.StdRhoAir
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    oaRequirements.OAFlowMethod = OAFlowCalcMethod.PCDesOcc
    state.dataAirLoop.NumOASystems = 1
    state.dataAirLoop.OutsideAirSys.allocate(1)
    var OASys: ref = state.dataAirLoop.OutsideAirSys[0]
    OASys.Name = "AIRLOOP OASYSTEM"
    OASys.NumControllers = 1
    OASys.ControllerName.allocate(1)
    OASys.ControllerName[0] = "OA CONTROLLER 1"
    OASys.ComponentType.allocate(1)
    OASys.ComponentType[0] = "OutdoorAir:Mixer"
    OASys.ComponentName.allocate(1)
    OASys.ComponentName[0] = "OAMixer"
    state.dataMixedAir.OAMixer.allocate(1)
    state.dataMixedAir.OAMixer[0].Name = "OAMixer"
    state.dataMixedAir.OAMixer[0].InletNode = 2
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    var airSys: ref = state.dataAirSystemsData.PrimaryAirSystems[0]
    airSys.Name = "PrimaryAirLoop"
    airSys.NumBranches = 1
    airSys.Branch.allocate(1)
    airSys.Branch[0].TotalComponents = 1
    airSys.Branch[0].Comp.allocate(1)
    airSys.Branch[0].Comp[0].Name = state.dataAirLoop.OutsideAirSys[0].Name
    airSys.Branch[0].Comp[0].TypeOf = "AirLoopHVAC:OutdoorAirSystem"
    state.dataAirLoop.AirLoopZoneInfo.allocate(1)
    state.dataAirLoop.AirLoopZoneInfo[0].NumZones = 1
    state.dataAirLoop.AirLoopZoneInfo[0].ActualZoneNumber.allocate(1)
    state.dataAirLoop.AirLoopZoneInfo[0].ActualZoneNumber[0] = 1
    InitOAController(state, 1, true, 1)
    expect_equal("ProportionalControlBasedOnDesignOccupancy", DataSizing.OAFlowCalcMethodNames[Int(oaReq1.OAFlowMethod)])
    oaController.MixMassFlow = 1.7 * state.dataEnvrn.StdRhoAir
    oaController.MaxOAMassFlowRate = 1.7 * state.dataEnvrn.StdRhoAir
    state.dataAirLoop.AirLoopFlow[0].DesSupply = 1.7 * state.dataEnvrn.StdRhoAir
    var zoneCO2Max: Float64 = 431.08678
    var zoneCO2Min: Float64 = 400.0
    state.dataContaminantBalance.ZoneAirCO2[0] = 600.0
    var ZoneOA: Float64 = (oaRequirements.OAFlowPerArea * state.dataHeatBal.Zone[0].FloorArea + \
                            oaRequirements.OAFlowPerPerson * state.dataHeatBal.Zone[0].TotOccupants)
    var ZoneOAFrac: Float64 = ZoneOA / 1.7
    var Evz: Float64 = 1.0 - ZoneOAFrac
    var expectedOAMassFlow: Float64 = ZoneOA * state.dataEnvrn.StdRhoAir / Evz
    oaController.CalcOAController(state, 1, true)
    expect_near(expectedOAMassFlow, oaController.OAMassFlow, 0.00001)
    expect_near(expectedOAMassFlow / oaController.MixMassFlow, oaController.MinOAFracLimit, 0.00001)
    state.dataContaminantBalance.ZoneAirCO2[0] = 200.0
    ZoneOA = oaRequirements.OAFlowPerArea * state.dataHeatBal.Zone[0].FloorArea
    ZoneOAFrac = ZoneOA / 1.7
    Evz = 1.0 - ZoneOAFrac
    expectedOAMassFlow = ZoneOA * state.dataEnvrn.StdRhoAir / Evz
    oaController.CalcOAController(state, 1, true)
    expect_near(expectedOAMassFlow, oaController.OAMassFlow, 0.00001)
    expect_near(expectedOAMassFlow / oaController.MixMassFlow, oaController.MinOAFracLimit, 0.00001)
    state.dataContaminantBalance.ZoneAirCO2[0] = zoneCO2Min + 0.3 * (zoneCO2Max - zoneCO2Min)
    ZoneOA = (oaRequirements.OAFlowPerArea * state.dataHeatBal.Zone[0].FloorArea + \
              0.3 * oaRequirements.OAFlowPerPerson * state.dataHeatBal.Zone[0].TotOccupants)
    ZoneOAFrac = ZoneOA / 1.7
    Evz = 1.0 - ZoneOAFrac
    expectedOAMassFlow = ZoneOA * state.dataEnvrn.StdRhoAir / Evz
    oaController.CalcOAController(state, 1, true)
    expect_near(expectedOAMassFlow, oaController.OAMassFlow, 0.00001)
    expect_near(expectedOAMassFlow / oaController.MixMassFlow, oaController.MinOAFracLimit, 0.00001)

@test
def CO2ControlDesignOccupancyTest3Zone():
    var idf_objects: String = delimited_string([
        "  OutdoorAir:Node,",
        "    Outside Air Inlet Node; !- Name",
        "  Schedule:Constant,",
        "    VentSchedule, !- Name",
        "     , !- Schedule Type Limits Name",
        "     1; !- Hourly value",
        "  Schedule:Constant,",
        "    ZoneADEffSch, !- Name",
        "     , !- Schedule Type Limits Name",
        "     1; !- Hourly value",
        "  Schedule:Constant,",
        "    OAFractionSched, !- Name",
        "     , !- Schedule Type Limits Name",
        "     1; !- Hourly value",
        "  Schedule:Constant,",
        "    CO2AvailSchedule, !- Name",
        "     , !- Schedule Type Limits Name",
        "     1.0; !- Hourly value",
        "People,",
        "    West Zone People,           !- Name",
        "    West Zone,                  !- Zone or ZoneList Name",
        "    OCCUPY-1,                !- Number of People Schedule Name",
        "    people,                  !- Number of People Calculation Method",
        "    11,                      !- Number of People",
        "    ,                        !- People per Zone Floor Area {person/m2}",
        "    ,                        !- Zone Floor Area per Person {m2/person}",
        "    0.3,                     !- Fraction Radiant",
        "    ,                        !- Sensible Heat Fraction",
        "    ActSchd;                 !- Activity Level Schedule Name",
        "People,",
        "    North Zone People,           !- Name",
        "    North Zone,                  !- Zone or ZoneList Name",
        "    OCCUPY-1,                !- Number of People Schedule Name",
        "    people,                  !- Number of People Calculation Method",
        "    11,                      !- Number of People",
        "    ,                        !- People per Zone Floor Area {person/m2}",
        "    ,                        !- Zone Floor Area per Person {m2/person}",
        "    0.3,                     !- Fraction Radiant",
        "    ,                        !- Sensible Heat Fraction",
        "    ActSchd;                 !- Activity Level Schedule Name",
        "People,",
        "    East Zone People,           !- Name",
        "    East Zone,                  !- Zone or ZoneList Name",
        "    OCCUPY-1,                !- Number of People Schedule Name",
        "    people,                  !- Number of People Calculation Method",
        "    11,                      !- Number of People",
        "    ,                        !- People per Zone Floor Area {person/m2}",
        "    ,                        !- Zone Floor Area per Person {m2/person}",
        "    0.3,                     !- Fraction Radiant",
        "    ,                        !- Sensible Heat Fraction",
        "    ActSchd;                 !- Activity Level Schedule Name",
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
        "    ActSchd,                 !- Name",
        "    Any Number,              !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 117.239997864;",
        "                             !- Field 4",
        "  Controller:OutdoorAir,",
        "    OA Controller 1, !- Name",
        "    Relief Air Outlet Node, !- Relief Air Outlet Node Name",
        "    Outdoor Air Mixer Inlet Node, !- Return Air Node Name",
        "    Mixed Air Node, !- Mixed Air Node Name",
        "    Outside Air Inlet Node, !- Actuator Node Name",
        "    0.0, !- Minimum Outdoor Air Flow Rate{ m3 / s }",
        "    1.7, !- Maximum Outdoor Air Flow Rate{ m3 / s }",
        "    NoEconomizer, !- Economizer Control Type",
        "    ModulateFlow, !- Economizer Control Action Type",
        "    , !- Economizer Maximum Limit Dry - Bulb Temperature{ C }",
        "    , !- Economizer Maximum Limit Enthalpy{ J / kg }",
        "    , !- Economizer Maximum Limit Dewpoint Temperature{ C }",
        "    , !- Electronic Enthalpy Limit Curve Name",
        "    , !- Economizer Minimum Limit Dry - Bulb Temperature{ C }",
        "    NoLockout, !- Lockout Type",
        "    FixedMinimum, !- Minimum Limit Type",
        "    OAFractionSched, !- Minimum Outdoor Air Schedule Name",
        "    , !- Minimum Fraction of Outdoor Air Schedule Name",
        "    , !- Maximum Fraction of Outdoor Air Schedule Name",
        "    DCVObject;               !- Mechanical Ventilation Controller Name",
        "  Controller:MechanicalVentilation,",
        "    DCVObject, !- Name",
        "    VentSchedule, !- Availability Schedule Name",
        "    Yes, !- Demand Controlled Ventilation",
        "    ProportionalControlBasedonDesignOccupancy, !- System Outdoor Air Method",
        "     , !- Zone Maximum Outdoor Air Fraction{ dimensionless }",
        "    West Zone, !- Zone 1 Name",
        "    CM DSOA West Zone, !- Design Specification Outdoor Air Object Name 1",
        "    CM DSZAD West Zone, !- Design Specification Zone Air Distribution Object Name 1",
        "    North Zone, !- Zone 2 Name",
        "    CM DSOA West Zone, !- Design Specification Outdoor Air Object Name 1",
        "    CM DSZAD West Zone, !- Design Specification Zone Air Distribution Object Name 1",
        "    East Zone, !- Zone 3 Name",
        "    CM DSOA West Zone, !- Design Specification Outdoor Air Object Name 1",
        "    CM DSZAD West Zone; !- Design Specification Zone Air Distribution Object Name 1",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    state.dataContaminantBalance.Contaminant.CO2Simulation = true
    state.dataContaminantBalance.Contaminant.CO2OutdoorSched = Sched.GetSchedule(state, "OCCUPY-1")
    state.dataAirLoop.AirLoopControlInfo.allocate(1)
    state.dataAirLoop.AirLoopControlInfo[0].LoopFlowRateSet = true
    state.dataSize.OARequirements.allocate(1)
    var oa