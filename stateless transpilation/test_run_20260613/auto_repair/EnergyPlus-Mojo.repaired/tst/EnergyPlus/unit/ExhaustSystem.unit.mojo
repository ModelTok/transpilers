from ...DataAirLoop import *
from ...Fixtures.EnergyPlusFixture import *
from ...Data.EnergyPlusData import *
from ...DataAirSystems import *
from ...DataEnvironment import *
from ...DataErrorTracking import *
from ...DataHVACGlobals import *
from ...DataLoopNode import *
from ...DataSizing import *
from ...DataZoneEquipment import *
from ...Fans import *
from ...General import *
from ...HeatRecovery import *
from ...IOFiles import *
from ...MixedAir import *
from ...NodeInputManager import *
from ...OutputProcessor import *
from ...Psychrometrics import *
from ...ScheduleManager import *
from ...SimAirServingZones import *
from ...SimulationManager import *
from ...ZoneTempPredictorCorrector import *
from ...DataHeatBalance import *
from ...ExhaustAirSystemManager import *
from ...MixerComponent import *
from testing import expect_eq, expect_near, expect_true, assert_true

def ExhaustSystemInputTest():
    let idf_objects = delimited_string([
        "! Zone1,",
        "! Zone2,",
        "! Zone3,",
        "! Zone4,",
        "AirLoopHVAC:ZoneMixer,",
        "    Mixer1,   !-Name",
        "    Central_ExhFan_1_Inlet,     !-Outlet Node Name",
        "    Zone1 Exhaust Outlet Node,  !-Inlet 1 Node Name",
        "    Zone4 Exhaust Outlet Node;  !-Inlet 2 Node Name",
        "AirLoopHVAC:ZoneMixer,",
        "    Mixer2, !-Name",
        "    Central_ExhFan_2_Inlet,    !-Outlet Node Name",
        "    Zone2 Exhaust Outlet Node, !-Inlet 1 Node Name",
        "    Zone3 Exhaust Outlet Node; !-Inlet 2 Node Name",
        "Fan:SystemModel,",
        "    CentralExhaustFan1,      !- Name",
        "    Omni_Sched,              !- Availability Schedule Name",
        "    Central_ExhFan_1_Inlet,  !- Air Inlet Node Name",
        "    Central_ExhFan_1_Outlet, !- Air Outlet Node Name",
        "    1,                       !- Design Maximum Air Flow Rate {m3/s}",
        "    Discrete,                !- Speed Control Method",
        "    0.2,                     !- Electric Power Minimum Flow Rate Fraction",
        "    10,                      !- Design Pressure Rise {Pa}",
        "    0.9,                     !- Motor Efficiency",
        "    1,                       !- Motor In Air Stream Fraction",
        "    autosize,                !- Design Electric Power Consumption {W}",
        "    PowerPerFlowPerPressure, !- Design Power Sizing Method",
        "    ,                        !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "    1.66667,                 !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "    0.7,                     !- Fan Total Efficiency",
        "    ,                        !- Electric Power Function of Flow Fraction Curve Name",
        "    ,                        !- Night Ventilation Mode Pressure Rise {Pa}",
        "    ,                        !- Night Ventilation Mode Flow Fraction",
        "    ,                        !- Motor Loss Zone Name",
        "    ,                        !- Motor Loss Radiative Fraction",
        "    General,                 !- End-Use Subcategory",
        "    1;                       !- Number of Speeds",
        "Fan:SystemModel,",
        "    CentralExhaustFan2,      !- Name",
        "    Omni_Sched,              !- Availability Schedule Name",
        "    Central_ExhFan_2_Inlet,  !- Air Inlet Node Name",
        "    Central_ExhFan_2_Outlet, !- Air Outlet Node Name",
        "    1,                       !- Design Maximum Air Flow Rate {m3/s}",
        "    Discrete,                !- Speed Control Method",
        "    0.2,                     !- Electric Power Minimum Flow Rate Fraction",
        "    15,                      !- Design Pressure Rise {Pa}",
        "    0.9,                     !- Motor Efficiency",
        "    1,                       !- Motor In Air Stream Fraction",
        "    autosize,                !- Design Electric Power Consumption {W}",
        "    PowerPerFlowPerPressure, !- Design Power Sizing Method",
        "    ,                        !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "    1.66667,                 !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "    0.7,                     !- Fan Total Efficiency",
        "    ,                        !- Electric Power Function of Flow Fraction Curve Name",
        "    ,                        !- Night Ventilation Mode Pressure Rise {Pa}",
        "    ,                        !- Night Ventilation Mode Flow Fraction",
        "    ,                        !- Motor Loss Zone Name",
        "    ,                        !- Motor Loss Radiative Fraction",
        "    General,                 !- End-Use Subcategory",
        "    1;                       !- Number of Speeds",
        "AirLoopHVAC:ExhaustSystem,",
        "    Central Exhaust 1,     !-Name",
        "    Mixer1,                !-AirLoopHVAC:ZoneMixer Name",
        "    Fan:SystemModel,       !-Fan Object Type",
        "    CentralExhaustFan1;    !-Fan Name",
        "AirLoopHVAC:ExhaustSystem,",
        "    Central Exhaust 2,     !-Name",
        "    Mixer2,                !-AirLoopHVAC:ZoneMixer Name",
        "    Fan:SystemModel,       !-Fan Object Type",
        "    CentralExhaustFan2;    !-Fan Name",
        "ZoneHVAC:ExhaustControl,",
        "    Zone1 Exhaust Control,              !-Name",
        "    HVACOperationSchd,                  !- Availability Schedule Name",
        "    Zone1,                              !- Zone Name",
        "    Zone1 Exhaust Node,                 !- Inlet Node Name",
        "    Zone1 Exhaust Oulet Node,           !- Outlet Node Name",
        "    0.1,                                !- Design Flow Rate {m3/s}",
        "    Scheduled,                          !- Flow Control Type (Scheduled, or FollowSupply)",
        "    Zone1Exh Exhaust Flow Frac Sched,   !- Flow Fraction Schedule Name",
        "    ,                                   !- Supply Node or NodeList Name (used with FollowSupply control type)",
        "    ,                                   !- Minimum Zone Temperature Limit Schedule Name",
        "    Zone1Exh Min Exhaust Flow Frac Sched,   !- Minimum Flow Fraction Schedule Name",
        "    Zone1Exh FlowBalancedSched;         !-Balanced Exhaust Fraction Schedule Name",
        "ZoneHVAC:ExhaustControl,",
        "    Zone2 Exhaust Control,              !-Name",
        "    HVACOperationSchd,                  !- Availability Schedule Name",
        "    Zone2,                              !- Zone Name",
        "    Zone2 Exhaust Node,                 !- Inlet Node Name",
        "    Zone2 Exhaust Outlet Node,          !- Outlet Node Name",
        "    autosize,                                !- Design Flow Rate {m3/s}",
        "    Scheduled,",
        "    ,                                   !- Flow Fraction Schedule Name",
        "    ,",
        "    ,                                   !- Minimum Zone Temperature Limit Schedule Name",
        "    Zone2Exh Min Exhaust Flow Frac Sched,   !- Minimum Flow Fraction Schedule Name",
        "    Zone2Exh FlowBalancedSched;         !-Balanced Exhaust Fraction Schedule Name",
        "ZoneHVAC:ExhaustControl,",
        "    Zone3 Exhaust Control,              !-Name",
        "    HVACOperationSchd,                  !- Availability Schedule Name",
        "    Zone3,                              !- Zone Name",
        "    Zone3 Exhaust Node,                 !- Inlet Node Name",
        "    Zone3 Exhaust Outlet Node,          !- Outlet Node Name",
        "    0.3,                                !- Design Flow Rate {m3/s}",
        "    Scheduled,                          !- Flow Control Type (Scheduled, or FollowSupply)",
        "    Zone3Exh Exhaust Flow Frac Sched,   !- Flow Fraction Schedule Name",
        "    ,                                   !- Supply Node or NodeList Name (used with FollowSupply control type)",
        "    ,                                   !- Minimum Zone Temperature Limit Schedule Name",
        "    Zone3Exh Min Exhaust Flow Frac Sched,   !- Minimum Flow Fraction Schedule Name",
        "    Zone3Exh FlowBalancedSched;         !-Balanced Exhaust Fraction Schedule Name",
        "ZoneHVAC:ExhaustControl,",
        "    Zone4 Exhaust Control,              !-Name",
        "    HVACOperationSchd,                  !- Availability Schedule Name",
        "    Zone4,                              !- Zone Name",
        "    Zone4 Exhaust Node,                 !- Inlet Node Name",
        "    Zone4 Exhaust Outlet Node,          !- Outlet Node Name",
        "    0.4,                                !- Design Flow Rate {m3/s}",
        "    Scheduled,                          !- Flow Control Type (Scheduled, or FollowSupply)",
        "    Zone4Exh Exhaust Flow Frac Sched,   !- Flow Fraction Schedule Name",
        "    ,                                   !- Supply Node or NodeList Name (used with FollowSupply control type)",
        "    Zone4_MinZoneTempLimitSched,        !- Minimum Zone Temperature Limit Schedule Name",
        "    Zone4Exh Min Exhaust Flow Frac Sched,   !- Minimum Flow Fraction Schedule Name",
        "    Zone4Exh FlowBalancedSched;         !-Balanced Exhaust Fraction Schedule Name",
        "Schedule:Compact,",
        "    Omni_Sched,              !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    HVACOperationSchd,       !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone1Exh Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone1_MinZoneTempLimitSched,             !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 20;        !- Field 3",
        "Schedule:Compact,",
        "    Zone1Exh Min Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone1Exh_FlowBalancedSched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone2Exh Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone2_MinZoneTempLimitSched,             !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 20;        !- Field 3",
        "Schedule:Compact,",
        "    Zone2Exh Min Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone2Exh_FlowBalancedSched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone3Exh Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone3_MinZoneTempLimitSched,             !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 20;        !- Field 3",
        "Schedule:Compact,",
        "    Zone3Exh Min Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone3Exh_FlowBalancedSched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone4Exh Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone4_MinZoneTempLimitSched,             !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 20;        !- Field 3",
        "Schedule:Compact,",
        "    Zone4Exh Min Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone4Exh_FlowBalancedSched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "ScheduleTypeLimits,",
        "    Fraction,                !- Name",
        "    0.0,                     !- Lower Limit Value",
        "    1.0,                     !- Upper Limit Value",
        "    CONTINUOUS;              !- Numeric Type",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    state.dataHeatBal.Zone.allocate(4)
    state.dataHeatBal.Zone[0].Name = "ZONE1"
    state.dataHeatBal.Zone[1].Name = "ZONE2"
    state.dataHeatBal.Zone[2].Name = "ZONE3"
    state.dataHeatBal.Zone[3].Name = "ZONE4"
    state.dataSize.FinalZoneSizing.allocate(4)
    state.dataSize.FinalZoneSizing[1].MinOA = 0.25
    ExhaustAirSystemManager.GetZoneExhaustControlInput(state)
    ExhaustAirSystemManager.GetExhaustAirSystemInput(state)
    expect_eq(state.dataZoneEquip.ZoneExhaustControlSystem[0].ZoneName, "ZONE1")
    expect_eq(state.dataZoneEquip.ZoneExhaustControlSystem[1].ZoneName, "ZONE2")
    expect_eq(state.dataZoneEquip.ZoneExhaustControlSystem[2].ZoneName, "ZONE3")
    expect_eq(state.dataZoneEquip.ZoneExhaustControlSystem[3].ZoneName, "ZONE4")
    expect_eq(state.dataZoneEquip.ZoneExhaustControlSystem[0].ZoneNum, 1)
    expect_eq(state.dataZoneEquip.ZoneExhaustControlSystem[1].ZoneNum, 2)
    expect_eq(state.dataZoneEquip.ZoneExhaustControlSystem[2].ZoneNum, 3)
    expect_eq(state.dataZoneEquip.ZoneExhaustControlSystem[3].ZoneNum, 4)
    expect_near(state.dataZoneEquip.ZoneExhaustControlSystem[0].DesignExhaustFlowRate, 0.1, 1e-5)
    expect_near(state.dataZoneEquip.ZoneExhaustControlSystem[1].DesignExhaustFlowRate, 0.25, 1e-5)
    expect_near(state.dataZoneEquip.ZoneExhaustControlSystem[2].DesignExhaustFlowRate, 0.3, 1e-5)
    expect_near(state.dataZoneEquip.ZoneExhaustControlSystem[3].DesignExhaustFlowRate, 0.4, 1e-5)
    expect_true((state.dataZoneEquip.ZoneExhaustControlSystem[0].FlowControlOption ==
                 ExhaustAirSystemManager.ZoneExhaustControl.FlowControlType.Scheduled))
    expect_true((state.dataZoneEquip.ZoneExhaustControlSystem[1].FlowControlOption ==
                 ExhaustAirSystemManager.ZoneExhaustControl.FlowControlType.Scheduled))
    expect_true((state.dataZoneEquip.ZoneExhaustControlSystem[2].FlowControlOption ==
                 ExhaustAirSystemManager.ZoneExhaustControl.FlowControlType.Scheduled))
    expect_true((state.dataZoneEquip.ZoneExhaustControlSystem[3].FlowControlOption ==
                 ExhaustAirSystemManager.ZoneExhaustControl.FlowControlType.Scheduled))
    expect_eq(state.dataZoneEquip.NumExhaustAirSystems, 2)
    expect_eq(state.dataZoneEquip.ExhaustAirSystem[0].Name, "CENTRAL EXHAUST 1")
    expect_eq(state.dataZoneEquip.ExhaustAirSystem[1].Name, "CENTRAL EXHAUST 2")
    expect_eq(state.dataZoneEquip.ExhaustAirSystem[0].ZoneMixerName, "MIXER1")
    expect_eq(state.dataZoneEquip.ExhaustAirSystem[1].ZoneMixerName, "MIXER2")
    expect_eq(state.dataZoneEquip.ExhaustAirSystem[0].ZoneMixerIndex, 1)
    expect_eq(state.dataZoneEquip.ExhaustAirSystem[1].ZoneMixerIndex, 2)
    expect_eq(state.dataZoneEquip.ExhaustAirSystem[0].CentralFanName, "CENTRALEXHAUSTFAN1")
    expect_eq(state.dataZoneEquip.ExhaustAirSystem[1].CentralFanName, "CENTRALEXHAUSTFAN2")

def ZoneExhaustCtrl_CheckSupplyNode_Test():
    state.init_state(state)
    state.dataGlobal.NumOfZones = 4
    state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.Zone[0].Name = "ZONE1"
    state.dataHeatBal.Zone[1].Name = "ZONE2"
    state.dataHeatBal.Zone[2].Name = "ZONE3"
    state.dataHeatBal.Zone[3].Name = "ZONE4"
    state.dataSize.FinalZoneSizing.allocate(4)
    state.dataSize.FinalZoneSizing[1].MinOA = 0.25
    state.dataZoneEquip.ZoneExhaustControlSystem.allocate(4)
    ref thisExhCtrl1 = state.dataZoneEquip.ZoneExhaustControlSystem[0]
    ref thisExhCtrl2 = state.dataZoneEquip.ZoneExhaustControlSystem[1]
    ref thisExhCtrl3 = state.dataZoneEquip.ZoneExhaustControlSystem[2]
    ref thisExhCtrl4 = state.dataZoneEquip.ZoneExhaustControlSystem[3]
    thisExhCtrl1.ZoneName = "ZONE1"
    thisExhCtrl2.ZoneName = "ZONE2"
    thisExhCtrl3.ZoneName = "ZONE3"
    thisExhCtrl4.ZoneName = "ZONE4"
    thisExhCtrl1.ZoneNum = 1
    thisExhCtrl2.ZoneNum = 2
    thisExhCtrl3.ZoneNum = 3
    thisExhCtrl4.ZoneNum = 4
    thisExhCtrl1.DesignExhaustFlowRate = 0.1
    thisExhCtrl2.DesignExhaustFlowRate = 0.25
    thisExhCtrl3.DesignExhaustFlowRate = 0.3
    thisExhCtrl4.DesignExhaustFlowRate = 0.4
    thisExhCtrl1.FlowControlOption = ExhaustAirSystemManager.ZoneExhaustControl.FlowControlType.FollowSupply
    thisExhCtrl2.FlowControlOption = ExhaustAirSystemManager.ZoneExhaustControl.FlowControlType.FollowSupply
    thisExhCtrl3.FlowControlOption = ExhaustAirSystemManager.ZoneExhaustControl.FlowControlType.Scheduled
    thisExhCtrl4.FlowControlOption = ExhaustAirSystemManager.ZoneExhaustControl.FlowControlType.Scheduled
    state.dataZoneEquip.ZoneEquipConfig.allocate(4)
    var Zone1InletName = "Zone1_Inlet_Node"
    var ExhCtrlNum = 1
    ref ZoneEquipConf1 = state.dataZoneEquip.ZoneEquipConfig[0]
    var ErrorsFound = false
    var inletNodeNum = Node.GetOnlySingleNode(state,
                                               Zone1InletName,
                                               ErrorsFound,
                                               Node.ConnectionObjectType.ZoneHVACExhaustControl,
                                               thisExhCtrl1.Name,
                                               Node.FluidType.Air,
                                               Node.ConnectionType.ZoneInlet,
                                               Node.CompFluidStream.Primary,
                                               Node.ObjectIsParent)
    ZoneEquipConf1.ZoneName = "ZONE1"
    ZoneEquipConf1.NumInletNodes = 1
    ZoneEquipConf1.NumExhaustNodes = 1
    ZoneEquipConf1.NumReturnNodes = 2
    ZoneEquipConf1.InletNode.allocate(ZoneEquipConf1.NumInletNodes)
    ZoneEquipConf1.InletNode[0] = inletNodeNum
    ZoneEquipConf1.ReturnNode.allocate(ZoneEquipConf1.NumReturnNodes)
    ZoneEquipConf1.ReturnNode[0] = 4
    ZoneEquipConf1.ReturnNode[1] = 5
    ZoneEquipConf1.ExhaustNode.allocate(ZoneEquipConf1.NumExhaustNodes)
    ZoneEquipConf1.ExhaustNode[0] = 3
    thisExhCtrl1.SupplyNodeOrNodelistName = "Zone1_Inlet_Node"
    var NodeListError = false
    var NumParams = 1
    var NumNodes = 0
    thisExhCtrl1.SuppNodeNums.dimension(NumParams, 0)
    thisExhCtrl1.SuppNodeNums = Node.GetOnlySingleNode(state,
                                                        thisExhCtrl1.SupplyNodeOrNodelistName,
                                                        ErrorsFound,
                                                        Node.ConnectionObjectType.ZoneHVACExhaustControl,
                                                        thisExhCtrl1.Name,
                                                        Node.FluidType.Air,
                                                        Node.ConnectionType.Sensor,
                                                        Node.CompFluidStream.Primary,
                                                        Node.ObjectIsParent)
    var NodeNotFound = false
    ExhaustAirSystemManager.CheckForSupplyNode(state, ExhCtrlNum, NodeNotFound)
    expect_false(NodeNotFound)
    var Zone2InletName = "Zone2_Inlet_Node"
    ExhCtrlNum = 2
    ref ZoneEquipConf2 = state.dataZoneEquip.ZoneEquipConfig[1]
    ErrorsFound = false
    inletNodeNum = Node.GetOnlySingleNode(state,
                                           Zone2InletName,
                                           ErrorsFound,
                                           Node.ConnectionObjectType.ZoneHVACExhaustControl,
                                           thisExhCtrl2.Name,
                                           Node.FluidType.Air,
                                           Node.ConnectionType.ZoneInlet,
                                           Node.CompFluidStream.Primary,
                                           Node.ObjectIsParent)
    ZoneEquipConf2.ZoneName = "ZONE2"
    ZoneEquipConf2.NumInletNodes = 1
    ZoneEquipConf2.NumExhaustNodes = 1
    ZoneEquipConf2.NumReturnNodes = 2
    ZoneEquipConf2.InletNode.allocate(ZoneEquipConf2.NumInletNodes)
    ZoneEquipConf2.InletNode[0] = inletNodeNum
    ZoneEquipConf2.ReturnNode.allocate(ZoneEquipConf2.NumReturnNodes)
    ZoneEquipConf2.ReturnNode[0] = 4
    ZoneEquipConf2.ReturnNode[1] = 5
    ZoneEquipConf2.ExhaustNode.allocate(ZoneEquipConf2.NumExhaustNodes)
    ZoneEquipConf2.ExhaustNode[0] = 3
    thisExhCtrl2.SupplyNodeOrNodelistName = "Zone22_Inlet_Node" # set with an incorrect name
    NodeListError = false
    NumParams = 1
    NumNodes = 0
    thisExhCtrl2.SuppNodeNums.dimension(NumParams, 0)
    thisExhCtrl2.SuppNodeNums = Node.GetOnlySingleNode(state,
                                                        thisExhCtrl2.SupplyNodeOrNodelistName,
                                                        ErrorsFound,
                                                        Node.ConnectionObjectType.ZoneHVACExhaustControl,
                                                        thisExhCtrl2.Name,
                                                        Node.FluidType.Air,
                                                        Node.ConnectionType.Sensor,
                                                        Node.CompFluidStream.Primary,
                                                        Node.ObjectIsParent)
    NodeNotFound = false
    ExhaustAirSystemManager.CheckForSupplyNode(state, ExhCtrlNum, NodeNotFound)
    expect_true(NodeNotFound)
    expect_eq(state.dataErrTracking.TotalWarningErrors, 1)
    expect_eq(state.dataErrTracking.TotalSevereErrors, 1)
    expect_eq(state.dataErrTracking.LastSevereError, "GetExhaustControlInput: ZoneHVAC:ExhaustControl=")

def ZoneExhaustCtrl_Test_CalcZoneHVACExhaustControl_Call():
    let idf_objects = delimited_string([
        "! Zone1,",
        "! Zone2,",
        "! Zone3,",
        "! Zone4,",
        "AirLoopHVAC:ZoneMixer,",
        "    Mixer1,   !-Name",
        "    Central_ExhFan_1_Inlet,     !-Outlet Node Name",
        "    Zone1 Exhaust Outlet Node,  !-Inlet 1 Node Name",
        "    Zone4 Exhaust Outlet Node;  !-Inlet 2 Node Name",
        "AirLoopHVAC:ZoneMixer,",
        "    Mixer2, !-Name",
        "    Central_ExhFan_2_Inlet,    !-Outlet Node Name",
        "    Zone2 Exhaust Outlet Node, !-Inlet 1 Node Name",
        "    Zone3 Exhaust Outlet Node; !-Inlet 2 Node Name",
        "Fan:SystemModel,",
        "    CentralExhaustFan1,      !- Name",
        "    Omni_Sched,              !- Availability Schedule Name",
        "    Central_ExhFan_1_Inlet,  !- Air Inlet Node Name",
        "    Central_ExhFan_1_Outlet, !- Air Outlet Node Name",
        "    1,                       !- Design Maximum Air Flow Rate {m3/s}",
        "    Discrete,                !- Speed Control Method",
        "    0.2,                     !- Electric Power Minimum Flow Rate Fraction",
        "    10,                      !- Design Pressure Rise {Pa}",
        "    0.9,                     !- Motor Efficiency",
        "    1,                       !- Motor In Air Stream Fraction",
        "    autosize,                !- Design Electric Power Consumption {W}",
        "    PowerPerFlowPerPressure, !- Design Power Sizing Method",
        "    ,                        !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "    1.66667,                 !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "    0.7,                     !- Fan Total Efficiency",
        "    ,                        !- Electric Power Function of Flow Fraction Curve Name",
        "    ,                        !- Night Ventilation Mode Pressure Rise {Pa}",
        "    ,                        !- Night Ventilation Mode Flow Fraction",
        "    ,                        !- Motor Loss Zone Name",
        "    ,                        !- Motor Loss Radiative Fraction",
        "    General,                 !- End-Use Subcategory",
        "    1;                       !- Number of Speeds",
        "Fan:SystemModel,",
        "    CentralExhaustFan2,      !- Name",
        "    Omni_Sched,              !- Availability Schedule Name",
        "    Central_ExhFan_2_Inlet,  !- Air Inlet Node Name",
        "    Central_ExhFan_2_Outlet, !- Air Outlet Node Name",
        "    1,                       !- Design Maximum Air Flow Rate {m3/s}",
        "    Discrete,                !- Speed Control Method",
        "    0.2,                     !- Electric Power Minimum Flow Rate Fraction",
        "    15,                      !- Design Pressure Rise {Pa}",
        "    0.9,                     !- Motor Efficiency",
        "    1,                       !- Motor In Air Stream Fraction",
        "    autosize,                !- Design Electric Power Consumption {W}",
        "    PowerPerFlowPerPressure, !- Design Power Sizing Method",
        "    ,                        !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "    1.66667,                 !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "    0.7,                     !- Fan Total Efficiency",
        "    ,                        !- Electric Power Function of Flow Fraction Curve Name",
        "    ,                        !- Night Ventilation Mode Pressure Rise {Pa}",
        "    ,                        !- Night Ventilation Mode Flow Fraction",
        "    ,                        !- Motor Loss Zone Name",
        "    ,                        !- Motor Loss Radiative Fraction",
        "    General,                 !- End-Use Subcategory",
        "    1;                       !- Number of Speeds",
        "AirLoopHVAC:ExhaustSystem,",
        "    Central Exhaust 1,     !-Name",
        "    Mixer1,                !-AirLoopHVAC:ZoneMixer Name",
        "    Fan:SystemModel,       !-Fan Object Type",
        "    CentralExhaustFan1;    !-Fan Name",
        "AirLoopHVAC:ExhaustSystem,",
        "    Central Exhaust 2,     !-Name",
        "    Mixer2,                !-AirLoopHVAC:ZoneMixer Name",
        "    Fan:SystemModel,       !-Fan Object Type",
        "    CentralExhaustFan2;    !-Fan Name",
        "ZoneHVAC:ExhaustControl,",
        "    Zone1 Exhaust Control,              !-Name",
        "    HVACOperationSchd1,                 !- Availability Schedule Name",
        "    Zone1,                              !- Zone Name",
        "    Zone1 Exhaust Node,                 !- Inlet Node Name",
        "    Zone1 Exhaust Oulet Node,           !- Outlet Node Name",
        "    0.1,                                !- Design Flow Rate {m3/s}",
        "    Scheduled,                          !- Flow Control Type (Scheduled, or FollowSupply)",
        "    Zone1Exh Exhaust Flow Frac Sched,   !- Flow Fraction Schedule Name",
        "    ,                                   !- Supply Node or NodeList Name (used with FollowSupply control type)",
        "    ,                                   !- Minimum Zone Temperature Limit Schedule Name",
        "    Zone1Exh Min Exhaust Flow Frac Sched,   !- Minimum Flow Fraction Schedule Name",
        "    Zone1Exh FlowBalancedSched;         !-Balanced Exhaust Fraction Schedule Name",
        "ZoneHVAC:ExhaustControl,",
        "    Zone2 Exhaust Control,              !-Name",
        "    HVACOperationSchd,                  !- Availability Schedule Name",
        "    Zone2,                              !- Zone Name",
        "    Zone2 Exhaust Node,                 !- Inlet Node Name",
        "    Zone2 Exhaust Outlet Node,          !- Outlet Node Name",
        "    autosize,                           !- Design Flow Rate {m3/s}",
        "    Scheduled,",
        "    ,                                   !- Flow Fraction Schedule Name",
        "    ,",
        "    ,                                   !- Minimum Zone Temperature Limit Schedule Name",
        "    Zone2Exh Min Exhaust Flow Frac Sched,   !- Minimum Flow Fraction Schedule Name",
        "    Zone2Exh FlowBalancedSched;         !-Balanced Exhaust Fraction Schedule Name",
        "ZoneHVAC:ExhaustControl,",
        "    Zone3 Exhaust Control,              !-Name",
        "    HVACOperationSchd,                  !- Availability Schedule Name",
        "    Zone3,                              !- Zone Name",
        "    Zone3 Exhaust Node,                 !- Inlet Node Name",
        "    Zone3 Exhaust Outlet Node,          !- Outlet Node Name",
        "    0.3,                                !- Design Flow Rate {m3/s}",
        "    Scheduled,                          !- Flow Control Type (Scheduled, or FollowSupply)",
        "    Zone3Exh Exhaust Flow Frac Sched,   !- Flow Fraction Schedule Name",
        "    ,                                   !- Supply Node or NodeList Name (used with FollowSupply control type)",
        "    ,                                   !- Minimum Zone Temperature Limit Schedule Name",
        "    Zone3Exh Min Exhaust Flow Frac Sched,   !- Minimum Flow Fraction Schedule Name",
        "    Zone3Exh FlowBalancedSched;         !-Balanced Exhaust Fraction Schedule Name",
        "ZoneHVAC:ExhaustControl,",
        "    Zone4 Exhaust Control,              !-Name",
        "    HVACOperationSchd,                  !- Availability Schedule Name",
        "    Zone4,                              !- Zone Name",
        "    Zone4 Exhaust Node,                 !- Inlet Node Name",
        "    Zone4 Exhaust Outlet Node,          !- Outlet Node Name",
        "    0.4,                                !- Design Flow Rate {m3/s}",
        "    Scheduled,                          !- Flow Control Type (Scheduled, or FollowSupply)",
        "    Zone4Exh Exhaust Flow Frac Sched,   !- Flow Fraction Schedule Name",
        "    ,                                   !- Supply Node or NodeList Name (used with FollowSupply control type)",
        "    Zone4_MinZoneTempLimitSched,        !- Minimum Zone Temperature Limit Schedule Name",
        "    Zone4Exh Min Exhaust Flow Frac Sched,   !- Minimum Flow Fraction Schedule Name",
        "    Zone4Exh FlowBalancedSched;         !-Balanced Exhaust Fraction Schedule Name",
        "Schedule:Compact,",
        "    Omni_Sched,              !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    HVACOperationSchd,       !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    HVACOperationSchd1,      !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,0.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone1Exh Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone1_MinZoneTempLimitSched,             !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 20;        !- Field 3",
        "Schedule:Compact,",
        "    Zone1Exh Min Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone1Exh_FlowBalancedSched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone2Exh Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone2_MinZoneTempLimitSched,             !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 20;        !- Field 3",
        "Schedule:Compact,",
        "    Zone2Exh Min Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone2Exh_FlowBalancedSched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone3Exh Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone3_MinZoneTempLimitSched,             !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 20;        !- Field 3",
        "Schedule:Compact,",
        "    Zone3Exh Min Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone3Exh_FlowBalancedSched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone4Exh Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "Schedule:Compact,",
        "    Zone4_MinZoneTempLimitSched,             !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 20;        !- Field 3",
        "Schedule:Compact,",
        "    Zone4Exh Min Exhaust Flow Frac Sched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "Schedule:Compact,",
        "    Zone4Exh_FlowBalancedSched,             !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00, 0.2;       !- Field 3",
        "ScheduleTypeLimits,",
        "    Fraction,                !- Name",
        "    0.0,                     !- Lower Limit Value",
        "    1.0,                     !- Upper Limit Value",
        "    CONTINUOUS;              !- Numeric Type",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    state.dataHeatBal.Zone.allocate(4)
    state.dataHeatBal.Zone[0].Name = "ZONE1"
    state.dataHeatBal.Zone[1].Name = "ZONE2"
    state.dataHeatBal.Zone[2].Name = "ZONE3"
    state.dataHeatBal.Zone[3].Name = "ZONE4"
    state.dataSize.FinalZoneSizing.allocate(4)
    state.dataSize.FinalZoneSizing[1].MinOA = 0.25
    ExhaustAirSystemManager.GetZoneExhaustControlInput(state)
    ExhaustAirSystemManager.GetExhaustAirSystemInput(state)
    var ExhaustControlNum = 1
    ref thisExhCtrl1 = state.dataZoneEquip.ZoneExhaustControlSystem[0]
    var zoneNum = thisExhCtrl1.ZoneNum
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(zoneNum)
    ref thisExhInlet = state.dataLoopNodes.Node[thisExhCtrl1.InletNodeNum]
    ref thisExhOutlet = state.dataLoopNodes.Node[thisExhCtrl1.OutletNodeNum]
    thisExhInlet.MassFlowRate = 0.25
    expect_near(thisExhInlet.MassFlowRate, 0.25, 1e-5)
    ExhaustAirSystemManager.CalcZoneHVACExhaustControl(state, ExhaustControlNum)
    expect_near(thisExhInlet.MassFlowRate, 0.0, 1e-5)
    expect_near(thisExhOutlet.MassFlowRate, 0.0, 1e-5)
    expect_near(thisExhCtrl1.BalancedFlow, 0.0, 1e-5)
    expect_near(thisExhCtrl1.UnbalancedFlow, 0.0, 1e-5)
    thisExhInlet.MassFlowRate = 0.25
    var schedAvail = Sched.GetSchedule(state, "HVACOPERATIONSCHD1")
    var schedFlow = Sched.GetSchedule(state, "ZONE1EXH EXHAUST FLOW FRAC SCHED")
    schedAvail.currentVal = 1.0
    schedFlow.currentVal = 1.0
    ExhaustAirSystemManager.CalcZoneHVACExhaustControl(state, ExhaustControlNum)
    expect_near(thisExhInlet.MassFlowRate, 0.1, 1e-5) # matches design flow rate for fan 1
    expect_near(thisExhOutlet.MassFlowRate, 0.1, 1e-5)
    expect_near(thisExhCtrl1.BalancedFlow, 0.0, 1e-5)
    expect_near(thisExhCtrl1.UnbalancedFlow, 0.1, 1e-5)
    state.dataZoneEquip.ZoneExhaustControlSystem[0].exhaustFlowFractionSched = None # delete exhaust flow schedule
    ExhaustAirSystemManager.CalcZoneHVACExhaustControl(state, ExhaustControlNum)
    expect_near(thisExhInlet.MassFlowRate, 0.1, 1e-5) # matches design flow rate for fan 1
    expect_near(thisExhOutlet.MassFlowRate, 0.1, 1e-5)
    expect_near(thisExhCtrl1.BalancedFlow, 0.0, 1e-5)
    expect_near(thisExhCtrl1.UnbalancedFlow, 0.1, 1e-5)