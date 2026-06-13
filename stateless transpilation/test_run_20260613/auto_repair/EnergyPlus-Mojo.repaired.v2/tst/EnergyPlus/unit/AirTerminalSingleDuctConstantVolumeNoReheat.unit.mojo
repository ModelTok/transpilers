from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_NEAR, ASSERT_TRUE, ASSERT_FALSE
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import DataAirLoop
from EnergyPlus.DataDefineEquip import DataDefineEquip
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.DataRuntimeLanguage import DataRuntimeLanguage
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.EMSManager import EMSManager
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.InternalHeatGains import InternalHeatGains
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.SingleDuct import SingleDuct
from EnergyPlus.SizingManager import SizingManager
from EnergyPlus.ZoneAirLoopEquipmentManager import ZoneAirLoopEquipmentManager

using DataDefineEquip = DataDefineEquip
using DataEnvironment = DataEnvironment
using DataZoneEquipment = DataZoneEquipment
using HeatBalanceManager = HeatBalanceManager
using Psychrometrics = Psychrometrics
using SingleDuct = SingleDuct
using ZoneAirLoopEquipmentManager = ZoneAirLoopEquipmentManager
using EMSManager = EMSManager
using DataRuntimeLanguage = DataRuntimeLanguage
class EnergyPlus:

    @staticmethod
    def AirTerminalSingleDuctCVNoReheat_GetInput(self: EnergyPlusFixture):
        var ErrorsFound: Bool = False
        var idf_objects: String = delimited_string([
            "  AirTerminal:SingleDuct:ConstantVolume:NoReheat,",
            "    SDCVNoReheatAT1,         !- Name",
            "    AvailSchedule,           !- Availability Schedule Name",
            "    Zone1NoReheatAirInletNode,   !- Air Inlet Node Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Outlet Node Name",
            "    0.50;                    !- Maximum Air Flow Rate {m3/s}",
            "  Schedule:Compact,",
            "    AvailSchedule,           !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,1.0;        !- Field 3",
            "  ZoneHVAC:EquipmentList,",
            "    Zone1Equipment,          !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
            "    SDCVNoReheatADU1,        !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:AirDistributionUnit,",
            "    SDCVNoReheatADU1,        !- Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Distribution Unit Outlet Node Name",
            "    AirTerminal:SingleDuct:ConstantVolume:NoReheat,  !- Air Terminal Object Type",
            "    SDCVNoReheatAT1;         !- Air Terminal Name",
            "  Zone,",
            "    West Zone,               !- Name",
            "    0,                       !- Direction of Relative North {deg}",
            "    0,                       !- X Origin {m}",
            "    0,                       !- Y Origin {m}",
            "    0,                       !- Z Origin {m}",
            "    1,                       !- Type",
            "    1,                       !- Multiplier",
            "    2.40,                    !- Ceiling Height {m}",
            "    240.0;                   !- Volume {m3}",
            "  ZoneHVAC:EquipmentConnections,",
            "    West Zone,               !- Zone Name",
            "    Zone1Equipment,          !- Zone Conditioning Equipment List Name",
            "    Zone1Inlets,             !- Zone Air Inlet Node or NodeList Name",
            "    ,                        !- Zone Air Exhaust Node or NodeList Name",
            "    Zone 1 Node,             !- Zone Air Node Name",
            "    Zone 1 Outlet Node;      !- Zone Return Air Node Name",
            "  NodeList,",
            "    Zone1Inlets,             !- Name",
            "    Zone1NoReheatAirOutletNode;   !- Node 1 Name",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
        state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
        state.init_state(state)
        GetZoneData(state, ErrorsFound)
        ASSERT_FALSE(ErrorsFound)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetSysInput(state)
        EXPECT_EQ("AirTerminal:SingleDuct:ConstantVolume:NoReheat",
                  state.dataSingleDuct.sd_airterminal[0].sysType)                    # AT SD constant volume no reheat object type
        EXPECT_EQ("SDCVNOREHEATAT1", state.dataSingleDuct.sd_airterminal[0].SysName) # AT SD constant volume no reheat name
        EXPECT_EQ("AVAILSCHEDULE",
                  state.dataSingleDuct.sd_airterminal[0].availSched.Name)        # AT SD constant volume no reheat availability schedule name
        EXPECT_EQ(0.50, state.dataSingleDuct.sd_airterminal[0].MaxAirVolFlowRate) # maximum volume flow Rate
        ASSERT_TRUE(state.dataSingleDuct.sd_airterminal[0].NoOAFlowInputFromUser) # no OA flow input from user
        EXPECT_EQ(DataZoneEquipment.PerPersonVentRateMode.DCVByCurrentLevel,
                  state.dataSingleDuct.sd_airterminal[0].OAPerPersonMode) # default value when A6 input field is blank

    @staticmethod
    def AirTerminalSingleDuctCVNoReheat_SimConstVolNoReheat(self: EnergyPlusFixture):
        var ErrorsFound: Bool = False
        var idf_objects: String = delimited_string([
            "  AirTerminal:SingleDuct:ConstantVolume:NoReheat,",
            "    SDCVNoReheatAT1,         !- Name",
            "    AvailSchedule,           !- Availability Schedule Name",
            "    Zone1NoReheatAirInletNode,   !- Air Inlet Node Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Outlet Node Name",
            "    1.0;                    !- Maximum Air Flow Rate {m3/s}",
            "  Schedule:Compact,",
            "    AvailSchedule,           !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,1.0;        !- Field 3",
            "  ZoneHVAC:EquipmentList,",
            "    Zone1Equipment,          !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
            "    SDCVNoReheatADU1,        !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:AirDistributionUnit,",
            "    SDCVNoReheatADU1,        !- Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Distribution Unit Outlet Node Name",
            "    AirTerminal:SingleDuct:ConstantVolume:NoReheat,  !- Air Terminal Object Type",
            "    SDCVNoReheatAT1;         !- Air Terminal Name",
            "  Zone,",
            "    West Zone,               !- Name",
            "    0,                       !- Direction of Relative North {deg}",
            "    0,                       !- X Origin {m}",
            "    0,                       !- Y Origin {m}",
            "    0,                       !- Z Origin {m}",
            "    1,                       !- Type",
            "    1,                       !- Multiplier",
            "    2.40,                    !- Ceiling Height {m}",
            "    240.0;                   !- Volume {m3}",
            "  ZoneHVAC:EquipmentConnections,",
            "    West Zone,               !- Zone Name",
            "    Zone1Equipment,          !- Zone Conditioning Equipment List Name",
            "    Zone1Inlets,             !- Zone Air Inlet Node or NodeList Name",
            "    ,                        !- Zone Air Exhaust Node or NodeList Name",
            "    Zone 1 Node,             !- Zone Air Node Name",
            "    Zone 1 Outlet Node;      !- Zone Return Air Node Name",
            "  NodeList,",
            "    Zone1Inlets,             !- Name",
            "    Zone1NoReheatAirOutletNode;   !- Node 1 Name",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
        state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
        state.init_state(state)
        GetZoneData(state, ErrorsFound)
        ASSERT_FALSE(ErrorsFound)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetSysInput(state)
        state.dataEnvrn.StdRhoAir = 1.0
        var SysNum: Int = 0
        var MassFlowRateMaxAvail: Float64 = state.dataSingleDuct.sd_airterminal[SysNum].MaxAirVolFlowRate * state.dataEnvrn.StdRhoAir
        state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate = MassFlowRateMaxAvail
        state.dataSingleDuct.sd_airterminal[SysNum].availSched.currentVal = 1.0 # unit is always available
        state.dataSingleDuct.sd_airterminal[SysNum].SimConstVolNoReheat(state)
        EXPECT_EQ(MassFlowRateMaxAvail, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)

    @staticmethod
    def AirTerminalSingleDuctCVNoReheat_Sim(self: EnergyPlusFixture):
        var ErrorsFound: Bool = False
        var FirstHVACIteration: Bool = False
        var idf_objects: String = delimited_string([
            "  AirTerminal:SingleDuct:ConstantVolume:NoReheat,",
            "    SDCVNoReheatAT1,         !- Name",
            "    AvailSchedule,           !- Availability Schedule Name",
            "    Zone1NoReheatAirInletNode,   !- Air Inlet Node Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Outlet Node Name",
            "    1.0;                    !- Maximum Air Flow Rate {m3/s}",
            "  Schedule:Compact,",
            "    AvailSchedule,           !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,1.0;        !- Field 3",
            "  ZoneHVAC:EquipmentList,",
            "    Zone1Equipment,          !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
            "    SDCVNoReheatADU1,        !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:AirDistributionUnit,",
            "    SDCVNoReheatADU1,        !- Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Distribution Unit Outlet Node Name",
            "    AirTerminal:SingleDuct:ConstantVolume:NoReheat,  !- Air Terminal Object Type",
            "    SDCVNoReheatAT1;         !- Air Terminal Name",
            "  Zone,",
            "    West Zone,               !- Name",
            "    0,                       !- Direction of Relative North {deg}",
            "    0,                       !- X Origin {m}",
            "    0,                       !- Y Origin {m}",
            "    0,                       !- Z Origin {m}",
            "    1,                       !- Type",
            "    1,                       !- Multiplier",
            "    2.40,                    !- Ceiling Height {m}",
            "    240.0;                   !- Volume {m3}",
            "  ZoneHVAC:EquipmentConnections,",
            "    West Zone,               !- Zone Name",
            "    Zone1Equipment,          !- Zone Conditioning Equipment List Name",
            "    Zone1Inlets,             !- Zone Air Inlet Node or NodeList Name",
            "    ,                        !- Zone Air Exhaust Node or NodeList Name",
            "    Zone 1 Node,             !- Zone Air Node Name",
            "    Zone 1 Outlet Node;      !- Zone Return Air Node Name",
            "  NodeList,",
            "    Zone1Inlets,             !- Name",
            "    Zone1NoReheatAirOutletNode;   !- Node 1 Name",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
        state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
        state.init_state(state)
        GetZoneData(state, ErrorsFound)
        ASSERT_FALSE(ErrorsFound)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetSysInput(state)
        state.dataGlobal.SysSizingCalc = True
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataEnvrn.StdRhoAir = 1.0
        state.dataEnvrn.OutBaroPress = 101325.0
        var SysNum: Int = 0
        var InletNode: Int = state.dataSingleDuct.sd_airterminal[SysNum].InletNodeNum
        var ZonePtr: Int = state.dataSingleDuct.sd_airterminal[SysNum].CtrlZoneNum
        var ZoneAirNodeNum: Int = state.dataZoneEquip.ZoneEquipConfig[ZonePtr].ZoneNode
        state.dataSingleDuct.sd_airterminal[SysNum].availSched.currentVal = 1.0 # unit is always available
        var MassFlowRateMaxAvail: Float64 = state.dataSingleDuct.sd_airterminal[SysNum].MaxAirVolFlowRate * state.dataEnvrn.StdRhoAir
        EXPECT_EQ(1.0, state.dataSingleDuct.sd_airterminal[SysNum].MaxAirVolFlowRate)
        EXPECT_EQ(1.0, MassFlowRateMaxAvail)
        state.dataLoopNodes.Node[InletNode].Temp = 50.0
        state.dataLoopNodes.Node[InletNode].HumRat = 0.0075
        state.dataLoopNodes.Node[InletNode].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat)
        state.dataLoopNodes.Node[ZoneAirNodeNum].Temp = 20.0
        state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat = 0.0075
        state.dataLoopNodes.Node[ZoneAirNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[ZoneAirNodeNum].Temp, state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat)
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = 0.0
        FirstHVACIteration = True
        state.dataSingleDuct.GetInputFlag = False
        SimulateSingleDuct(state,
                           state.dataDefineEquipment.AirDistUnit[0].EquipName[0],
                           FirstHVACIteration,
                           ZonePtr,
                           ZoneAirNodeNum,
                           state.dataDefineEquipment.AirDistUnit[0].EquipIndex[0])
        EXPECT_EQ(MassFlowRateMaxAvail, state.dataSingleDuct.sd_airterminal[SysNum].AirMassFlowRateMax)         # design maximum mass flow rate
        EXPECT_EQ(0.0, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRateMaxAvail) # maximum available mass flow rate
        EXPECT_EQ(0.0, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)         # outlet mass flow rate is zero
        EXPECT_EQ(0.0, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)        # outlet mass flow rate is zero
        FirstHVACIteration = False
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = MassFlowRateMaxAvail
        EXPECT_EQ(1.0, MassFlowRateMaxAvail)
        SimulateSingleDuct(state,
                           state.dataDefineEquipment.AirDistUnit[0].EquipName[0],
                           FirstHVACIteration,
                           ZonePtr,
                           ZoneAirNodeNum,
                           state.dataDefineEquipment.AirDistUnit[0].EquipIndex[0])
        EXPECT_EQ(MassFlowRateMaxAvail, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)
        EXPECT_EQ(MassFlowRateMaxAvail, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirTemp,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirTemp)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirHumRat,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirHumRat)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirEnthalpy,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirEnthalpy)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)

    @staticmethod
    def AirTerminalSingleDuctCVNoReheat_OASpecification(self: EnergyPlusFixture):
        var ErrorsFound: Bool = False
        var FirstHVACIteration: Bool = False
        var idf_objects: String = delimited_string([
            "  AirTerminal:SingleDuct:ConstantVolume:NoReheat,",
            "    SDCVNoReheatAT1,         !- Name",
            "    ,                        !- Availability Schedule Name",
            "    Zone1NoReheatAirInletNode,   !- Air Inlet Node Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Outlet Node Name",
            "    3.0,                     !- Maximum Air Flow Rate {m3/s}",
            "    Zone 1 Ventilation,      !- Design Specification Outdoor Air Object Name",
            "    CurrentOccupancy;        !- Per Person Ventilation Rate Mode",
            "DesignSpecification:OutdoorAir,",
            "    Zone 1 Ventilation,      !- Name",
            "    Sum,                     !- Outdoor Air Method",
            "    0.1000,                  !- Outdoor Air Flow per Person {m3/s-person}",
            "    0.0000,                  !- Outdoor Air Flow per Zone Floor Area {m3/s-m2}",
            "    0.5,                     !- Outdoor Air Flow per Zone {m3/s}",
            "    0,                       !- Outdoor Air Flow Air Changes per Hour {1/hr}",
            "    VentSchedule;            !- Outdoor Air Schedule Name",
            "  Schedule:Compact,",
            "    VentSchedule,            !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 18:00,1.0,        !- Field 3",
            "    Until: 24:00,0.0;        !- Field 4",
            "  People,",
            "    West Zone People,        !- Name",
            "    West Zone,               !- Zone or ZoneList Name",
            "    OFFICE OCCUPANCY,        !- Number of People Schedule Name",
            "    people,                  !- Number of People Calculation Method",
            "    3.000000,                !- Number of People",
            "    ,                        !- People per Zone Floor Area {person/m2}",
            "    ,                        !- Zone Floor Area per Person {m2/person}",
            "    0.3000000,               !- Fraction Radiant",
            "    ,                        !- Sensible Heat Fraction",
            "    Activity Sch;            !- Activity Level Schedule Name",
            "  Schedule:Compact,",
            "    OFFICE OCCUPANCY,        !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: WeekDays,           !- Field 2",
            "    Until: 6:00,0.0,         !- Field 3",
            "    Until: 7:00,0.10,        !- Field 5",
            "    Until: 8:00,0.50,        !- Field 7",
            "    Until: 12:00,1.00,       !- Field 9",
            "    Until: 13:00,0.50,       !- Field 11",
            "    Until: 16:00,1.00,       !- Field 13",
            "    Until: 17:00,0.50,       !- Field 15",
            "    Until: 18:00,0.10,       !- Field 17",
            "    Until: 24:00,0.0,        !- Field 19",
            "    For: AllOtherDays,       !- Field 21",
            "    Until: 24:00,0.0;        !- Field 22",
            "  Schedule:Compact,",
            "    Activity Sch,            !- Name",
            "    Any Number,              !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,131.8;      !- Field 3",
            "  ZoneHVAC:EquipmentList,",
            "    Zone1Equipment,          !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
            "    SDCVNoReheatADU1,        !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:AirDistributionUnit,",
            "    SDCVNoReheatADU1,        !- Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Distribution Unit Outlet Node Name",
            "    AirTerminal:SingleDuct:ConstantVolume:NoReheat,  !- Air Terminal Object Type",
            "    SDCVNoReheatAT1;         !- Air Terminal Name",
            "  Zone,",
            "    West Zone,               !- Name",
            "    0,                       !- Direction of Relative North {deg}",
            "    0,                       !- X Origin {m}",
            "    0,                       !- Y Origin {m}",
            "    0,                       !- Z Origin {m}",
            "    1,                       !- Type",
            "    1,                       !- Multiplier",
            "    2.40,                    !- Ceiling Height {m}",
            "    240.0;                   !- Volume {m3}",
            "  ZoneHVAC:EquipmentConnections,",
            "    West Zone,               !- Zone Name",
            "    Zone1Equipment,          !- Zone Conditioning Equipment List Name",
            "    Zone1Inlets,             !- Zone Air Inlet Node or NodeList Name",
            "    ,                        !- Zone Air Exhaust Node or NodeList Name",
            "    Zone 1 Node,             !- Zone Air Node Name",
            "    Zone 1 Outlet Node;      !- Zone Return Air Node Name",
            "  NodeList,",
            "    Zone1Inlets,             !- Name",
            "    Zone1NoReheatAirOutletNode;   !- Node 1 Name",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
        state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
        state.init_state(state)
        GetZoneData(state, ErrorsFound)
        ASSERT_FALSE(ErrorsFound)
        SizingManager.GetOARequirements(state)
        InternalHeatGains.GetInternalHeatGainsInput(state)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetSysInput(state)
        state.dataGlobal.SysSizingCalc = True
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataEnvrn.StdRhoAir = 1.0
        state.dataEnvrn.OutBaroPress = 101325.0
        var SysNum: Int = 0
        var InletNode: Int = state.dataSingleDuct.sd_airterminal[SysNum].InletNodeNum
        var ZonePtr: Int = state.dataSingleDuct.sd_airterminal[SysNum].CtrlZoneNum
        var ZoneAirNodeNum: Int = state.dataZoneEquip.ZoneEquipConfig[ZonePtr].ZoneNode
        var MassFlowRateMaxAvail: Float64 = state.dataSingleDuct.sd_airterminal[SysNum].MaxAirVolFlowRate * state.dataEnvrn.StdRhoAir
        EXPECT_EQ(3.0, state.dataSingleDuct.sd_airterminal[SysNum].MaxAirVolFlowRate)
        EXPECT_EQ(3.0, MassFlowRateMaxAvail)
        state.dataLoopNodes.Node[InletNode].Temp = 50.0
        state.dataLoopNodes.Node[InletNode].HumRat = 0.0075
        state.dataLoopNodes.Node[InletNode].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat)
        state.dataLoopNodes.Node[InletNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[ZoneAirNodeNum].Temp = 20.0
        state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat = 0.0075
        state.dataLoopNodes.Node[ZoneAirNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[ZoneAirNodeNum].Temp, state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat)
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = 0.0
        FirstHVACIteration = True
        state.dataSingleDuct.GetInputFlag = False
        SimulateSingleDuct(state,
                           state.dataDefineEquipment.AirDistUnit[0].EquipName[0],
                           FirstHVACIteration,
                           ZonePtr,
                           ZoneAirNodeNum,
                           state.dataDefineEquipment.AirDistUnit[0].EquipIndex[0])
        EXPECT_EQ(MassFlowRateMaxAvail, state.dataSingleDuct.sd_airterminal[SysNum].AirMassFlowRateMax)         # design maximum mass flow rate
        EXPECT_EQ(0.0, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRateMaxAvail) # maximum available mass flow rate
        EXPECT_EQ(0.0, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)         # outlet mass flow rate is zero
        EXPECT_EQ(0.0, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)        # outlet mass flow rate is zero
        state.dataGlobal.BeginEnvrnFlag = False
        FirstHVACIteration = False
        state.dataSingleDuct.sd_airterminal[SysNum].AirLoopNum = 0
        state.dataAirLoop.AirLoopFlow.allocate(1)
        state.dataAirLoop.AirLoopFlow[state.dataSingleDuct.sd_airterminal[SysNum].AirLoopNum].OAFrac = 1.0
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = MassFlowRateMaxAvail
        EXPECT_EQ(3.0, MassFlowRateMaxAvail)
        state.dataEnvrn.DSTIndicator = 0
        state.dataEnvrn.DayOfYear_Schedule = 1
        state.dataEnvrn.DayOfWeek = 1
        state.dataEnvrn.HolidayIndex = 0
        state.dataGlobal.TimeStep = 1
        state.dataGlobal.HourOfDay = 12
        Sched.UpdateScheduleVals(state)
        state.dataHeatBal.ZoneIntGain[0].NOFOCC = 3.0
        var expectedMassFlow: Float64 = 1.0 * ((3.0 * 0.1) + 0.5)
        SimulateSingleDuct(state,
                           state.dataDefineEquipment.AirDistUnit[0].EquipName[0],
                           FirstHVACIteration,
                           ZonePtr,
                           ZoneAirNodeNum,
                           state.dataDefineEquipment.AirDistUnit[0].EquipIndex[0])
        EXPECT_EQ(expectedMassFlow, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)
        EXPECT_EQ(expectedMassFlow, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)
        state.dataGlobal.HourOfDay = 12
        Sched.UpdateScheduleVals(state)
        state.dataHeatBal.ZoneIntGain[0].NOFOCC = 1.5
        expectedMassFlow = 1.0 * ((1.5 * 0.1) + 0.5)
        SimulateSingleDuct(state,
                           state.dataDefineEquipment.AirDistUnit[0].EquipName[0],
                           FirstHVACIteration,
                           ZonePtr,
                           ZoneAirNodeNum,
                           state.dataDefineEquipment.AirDistUnit[0].EquipIndex[0])
        EXPECT_EQ(expectedMassFlow, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)
        EXPECT_EQ(expectedMassFlow, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)
        state.dataGlobal.HourOfDay = 24
        Sched.UpdateScheduleVals(state)
        state.dataHeatBal.ZoneIntGain[0].NOFOCC = 1.5
        expectedMassFlow = 0.0 * ((1.5 * 0.1) + 0.5)
        SimulateSingleDuct(state,
                           state.dataDefineEquipment.AirDistUnit[0].EquipName[0],
                           FirstHVACIteration,
                           ZonePtr,
                           ZoneAirNodeNum,
                           state.dataDefineEquipment.AirDistUnit[0].EquipIndex[0])
        EXPECT_EQ(expectedMassFlow, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)
        EXPECT_EQ(expectedMassFlow, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)

    @staticmethod
    def AirTerminalSingleDuctCVNoReheat_EMSOverrideAirFlow(self: EnergyPlusFixture):
        var ErrorsFound: Bool = False
        var FirstHVACIteration: Bool = False
        var idf_objects: String = delimited_string([
            "  AirTerminal:SingleDuct:ConstantVolume:NoReheat,",
            "    SDCVNoReheatAT1,         !- Name",
            "    AvailSchedule,           !- Availability Schedule Name",
            "    Zone1NoReheatAirInletNode,   !- Air Inlet Node Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Outlet Node Name",
            "    1.0;                    !- Maximum Air Flow Rate {m3/s}",
            "  Schedule:Compact,",
            "    AvailSchedule,           !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,1.0;        !- Field 3",
            "  ZoneHVAC:EquipmentList,",
            "    Zone1Equipment,          !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
            "    SDCVNoReheatADU1,        !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:AirDistributionUnit,",
            "    SDCVNoReheatADU1,        !- Name",
            "    Zone1NoReheatAirOutletNode,  !- Air Distribution Unit Outlet Node Name",
            "    AirTerminal:SingleDuct:ConstantVolume:NoReheat,  !- Air Terminal Object Type",
            "    SDCVNoReheatAT1;         !- Air Terminal Name",
            "  Zone,",
            "    West Zone,               !- Name",
            "    0,                       !- Direction of Relative North {deg}",
            "    0,                       !- X Origin {m}",
            "    0,                       !- Y Origin {m}",
            "    0,                       !- Z Origin {m}",
            "    1,                       !- Type",
            "    1,                       !- Multiplier",
            "    2.40,                    !- Ceiling Height {m}",
            "    240.0;                   !- Volume {m3}",
            "  ZoneHVAC:EquipmentConnections,",
            "    West Zone,               !- Zone Name",
            "    Zone1Equipment,          !- Zone Conditioning Equipment List Name",
            "    Zone1Inlets,             !- Zone Air Inlet Node or NodeList Name",
            "    ,                        !- Zone Air Exhaust Node or NodeList Name",
            "    Zone 1 Node,             !- Zone Air Node Name",
            "    Zone 1 Outlet Node;      !- Zone Return Air Node Name",
            "  NodeList,",
            "    Zone1Inlets,             !- Name",
            "    Zone1NoReheatAirOutletNode;   !- Node 1 Name",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
        state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
        state.init_state(state)
        GetZoneData(state, ErrorsFound)
        ASSERT_FALSE(ErrorsFound)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetSysInput(state)
        state.dataGlobal.SysSizingCalc = True
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataEnvrn.StdRhoAir = 1.0
        state.dataEnvrn.OutBaroPress = 101325.0
        var SysNum: Int = 0
        var InletNode: Int = state.dataSingleDuct.sd_airterminal[SysNum].InletNodeNum
        var ZonePtr: Int = state.dataSingleDuct.sd_airterminal[SysNum].CtrlZoneNum
        var ZoneAirNodeNum: Int = state.dataZoneEquip.ZoneEquipConfig[ZonePtr].ZoneNode
        state.dataSingleDuct.sd_airterminal[SysNum].availSched.currentVal = 1.0 # unit is always available
        var MassFlowRateMaxAvail: Float64 = state.dataSingleDuct.sd_airterminal[SysNum].MaxAirVolFlowRate * state.dataEnvrn.StdRhoAir
        EXPECT_EQ(1.0, state.dataSingleDuct.sd_airterminal[SysNum].MaxAirVolFlowRate)
        EXPECT_EQ(1.0, MassFlowRateMaxAvail)
        state.dataLoopNodes.Node[InletNode].Temp = 50.0
        state.dataLoopNodes.Node[InletNode].HumRat = 0.0075
        state.dataLoopNodes.Node[InletNode].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat)
        state.dataLoopNodes.Node[ZoneAirNodeNum].Temp = 20.0
        state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat = 0.0075
        state.dataLoopNodes.Node[ZoneAirNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[ZoneAirNodeNum].Temp, state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat)
        state.dataSingleDuct.GetInputFlag = False
        FirstHVACIteration = False
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = MassFlowRateMaxAvail
        EXPECT_EQ(1.0, MassFlowRateMaxAvail)
        SimulateSingleDuct(state,
                           state.dataDefineEquipment.AirDistUnit[0].EquipName[0],
                           FirstHVACIteration,
                           ZonePtr,
                           ZoneAirNodeNum,
                           state.dataDefineEquipment.AirDistUnit[0].EquipIndex[0])
        EXPECT_EQ(MassFlowRateMaxAvail, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)
        EXPECT_EQ(MassFlowRateMaxAvail, state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirTemp,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirTemp)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirHumRat,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirHumRat)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirEnthalpy,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirEnthalpy)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)
        state.dataSingleDuct.sd_airterminal[SysNum].EMSOverrideAirFlow = True
        state.dataSingleDuct.sd_airterminal[SysNum].EMSMassFlowRateValue = 0.5
        SimulateSingleDuct(state,
                           state.dataDefineEquipment.AirDistUnit[0].EquipName[0],
                           FirstHVACIteration,
                           ZonePtr,
                           ZoneAirNodeNum,
                           state.dataDefineEquipment.AirDistUnit[0].EquipIndex[0])
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].EMSMassFlowRateValue,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalInlet.AirMassFlowRate)
        EXPECT_EQ(state.dataSingleDuct.sd_airterminal[SysNum].EMSMassFlowRateValue,
                  state.dataSingleDuct.sd_airterminal[SysNum].sd_airterminalOutlet.AirMassFlowRate)

    @staticmethod
    def AirTerminalSingleDuctCVNoReheat_OAVolumeFlowRateReporting(self: EnergyPlusFixture):
        var ErrorsFound: Bool = False
        var FirstHVACIteration: Bool = False
        var idf_objects: String = delimited_string([
            "  AirTerminal:SingleDuct:ConstantVolume:NoReheat,",
            "    SDCVNoReheatATU,         !- Name",
            "    ,                        !- Availability Schedule Name",
            "    WZoneNoReheatAirInletNode,   !- Air Inlet Node Name",
            "    WZoneNoReheatAirOutletNode,  !- Air Outlet Node Name",
            "    3.0,                     !- Maximum Air Flow Rate {m3/s}",
            "    Ventilation Spec,        !- Design Specification Outdoor Air Object Name",
            "    CurrentOccupancy;        !- Per Person Ventilation Rate Mode",
            "DesignSpecification:OutdoorAir,",
            "    Ventilation Spec,        !- Name",
            "    Sum,                     !- Outdoor Air Method",
            "    0.1000,                  !- Outdoor Air Flow per Person {m3/s-person}",
            "    0.0000,                  !- Outdoor Air Flow per Zone Floor Area {m3/s-m2}",
            "    0.5,                     !- Outdoor Air Flow per Zone {m3/s}",
            "    0,                       !- Outdoor Air Flow Air Changes per Hour {1/hr}",
            "    VentSchedule;            !- Outdoor Air Schedule Name",
            "  Schedule:Compact,",
            "    VentSchedule,            !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 06:00,0.0,        !- Field 3",
            "    Until: 18:00,1.0,        !- Field 4",
            "    Until: 24:00,0.0;        !- Field 6",
            "  People,",
            "    West Zone People,        !- Name",
            "    West Zone,               !- Zone or ZoneList Name",
            "    Office Occupancy,        !- Number of People Schedule Name",
            "    people,                  !- Number of People Calculation Method",
            "    3.000000,                !- Number of People",
            "    ,                        !- People per Zone Floor Area {person/m2}",
            "    ,                        !- Zone Floor Area per Person {m2/person}",
            "    0.3000000,               !- Fraction Radiant",
            "    ,                        !- Sensible Heat Fraction",
            "    Activity Sch;            !- Activity Level Schedule Name",
            "  Schedule:Compact,",
            "    Office Occupancy,        !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: WeekDays,           !- Field 2",
            "    Until: 6:00,0.0,         !- Field 3",
            "    Until: 7:00,0.10,        !- Field 5",
            "    Until: 8:00,0.50,        !- Field 7",
            "    Until: 12:00,1.00,       !- Field 9",
            "    Until: 13:00,0.50,       !- Field 11",
            "    Until: 16:00,1.00,       !- Field 13",
            "    Until: 17:00,0.50,       !- Field 15",
            "    Until: 18:00,0.10,       !- Field 17",
            "    Until: 24:00,0.0,        !- Field 19",
            "    For: AllOtherDays,       !- Field 21",
            "    Until: 24:00,0.0;        !- Field 22",
            "  Schedule:Compact,",
            "    Activity Sch,            !- Name",
            "    Any Number,              !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,131.8;      !- Field 3",
            "  ZoneHVAC:EquipmentList,",
            "    WestZoneEquipment,       !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
            "    SDCVNoReheatADU,         !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:AirDistributionUnit,",
            "    SDCVNoReheatADU,         !- Name",
            "    WZoneNoReheatAirOutletNode,  !- Air Distribution Unit Outlet Node Name",
            "    AirTerminal:SingleDuct:ConstantVolume:NoReheat,  !- Air Terminal Object Type",
            "    SDCVNoReheatATU;         !- Air Terminal Name",
            "  Zone,",
            "    West Zone,               !- Name",
            "    0,                       !- Direction of Relative North {deg}",
            "    0,                       !- X Origin {m}",
            "    0,                       !- Y Origin {m}",
            "    0,                       !- Z Origin {m}",
            "    1,                       !- Type",
            "    1,                       !- Multiplier",
            "    2.40,                    !- Ceiling Height {m}",
            "    240.0;                   !- Volume {m3}",
            "  ZoneHVAC:EquipmentConnections,",
            "    West Zone,               !- Zone Name",
            "    WestZoneEquipment,       !- Zone Conditioning Equipment List Name",
            "    West Zone Inlet Nodes,   !- Zone Air Inlet Node or NodeList Name",
            "    ,                        !- Zone Air Exhaust Node or NodeList Name",
            "    West Zone Air Node,      !- Zone Air Node Name",
            "    West Zone Outlet Node;   !- Zone Return Air Node Name",
            "  NodeList,",
            "    West Zone Inlet Nodes,   !- Name",
            "    WZoneNoReheatAirOutletNode;   !- Node 1 Name",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
        state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
        state.init_state(state)
        GetZoneData(state, ErrorsFound)
        ASSERT_FALSE(ErrorsFound)
        SizingManager.GetOARequirements(state)
        InternalHeatGains.GetInternalHeatGainsInput(state)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetSysInput(state)
        state.dataGlobal.SysSizingCalc = True
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataEnvrn.StdRhoAir = 1.0
        state.dataEnvrn.OutBaroPress = 101325.0
        state.dataAirLoop.AirLoopFlow.allocate(1)
        var SysNum: Int = 0
        var thisAirTerminal = state.dataSingleDuct.sd_airterminal[SysNum]
        var thisAirTerminalInlet = thisAirTerminal.sd_airterminalInlet
        var thisAirTerminalOutlet = thisAirTerminal.sd_airterminalOutlet
        var thisAirDisUnit = state.dataDefineEquipment.AirDistUnit[0]
        var thisAirLoop = state.dataAirLoop.AirLoopFlow[0]
        var InletNode: Int = thisAirTerminal.InletNodeNum
        var ZonePtr: Int = thisAirTerminal.CtrlZoneNum
        var ZoneAirNodeNum: Int = state.dataZoneEquip.ZoneEquipConfig[ZonePtr].ZoneNode
        state.dataZoneEquip.ZoneEquipConfig[ZonePtr].InletNodeAirLoopNum[0] = 0
        thisAirTerminal.AirLoopNum = state.dataZoneEquip.ZoneEquipConfig[ZonePtr].InletNodeAirLoopNum[0]
        var MassFlowRateMaxAvail: Float64 = thisAirTerminal.MaxAirVolFlowRate * state.dataEnvrn.StdRhoAir
        EXPECT_EQ(3.0, thisAirTerminal.MaxAirVolFlowRate)
        EXPECT_EQ(3.0, MassFlowRateMaxAvail)
        state.dataLoopNodes.Node[InletNode].Temp = 50.0
        state.dataLoopNodes.Node[InletNode].HumRat = 0.0075
        state.dataLoopNodes.Node[InletNode].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat)
        state.dataLoopNodes.Node[InletNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[ZoneAirNodeNum].Temp = 20.0
        state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat = 0.0075
        state.dataLoopNodes.Node[ZoneAirNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[ZoneAirNodeNum].Temp, state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat)
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = 0.0
        FirstHVACIteration = True
        state.dataSingleDuct.GetInputFlag = False
        SimulateSingleDuct(state, thisAirDisUnit.EquipName[0], FirstHVACIteration, ZonePtr, ZoneAirNodeNum, thisAirDisUnit.EquipIndex[0])
        EXPECT_EQ(MassFlowRateMaxAvail, thisAirTerminal.AirMassFlowRateMax) # design maximum mass flow rate
        EXPECT_EQ(0.0, thisAirTerminalInlet.AirMassFlowRateMaxAvail)        # maximum available mass flow rate
        EXPECT_EQ(0.0, thisAirTerminalOutlet.AirMassFlowRate)               # outlet mass flow rate is zero
        EXPECT_EQ(0.0, thisAirTerminalOutlet.AirMassFlowRate)               # outlet mass flow rate is zero
        EXPECT_EQ(0.0, thisAirTerminal.OutdoorAirFlowRate)                  # OA volume flow rate is zero
        state.dataGlobal.BeginEnvrnFlag = False
        FirstHVACIteration = False
        thisAirLoop.OAFrac = 1.0
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = MassFlowRateMaxAvail
        EXPECT_EQ(3.0, MassFlowRateMaxAvail)
        state.dataEnvrn.DSTIndicator = 0
        state.dataEnvrn.DayOfYear_Schedule = 1
        state.dataEnvrn.DayOfWeek = 1
        state.dataEnvrn.HolidayIndex = 0
        state.dataGlobal.TimeStep = 1
        state.dataGlobal.HourOfDay = 12
        Sched.UpdateScheduleVals(state)
        state.dataHeatBal.ZoneIntGain[0].NOFOCC = 3.0
        var expectedMassFlow: Float64 = 1.0 * ((3.0 * 0.1) + 0.5)
        SimulateSingleDuct(state, thisAirDisUnit.EquipName[0], FirstHVACIteration, ZonePtr, ZoneAirNodeNum, thisAirDisUnit.EquipIndex[0])
        var expected_OAVolFlowRate: Float64 = thisAirTerminalOutlet.AirMassFlowRate * thisAirLoop.OAFrac / state.dataEnvrn.StdRhoAir
        EXPECT_EQ(expectedMassFlow, thisAirTerminalInlet.AirMassFlowRate)
        EXPECT_EQ(expectedMassFlow, thisAirTerminalOutlet.AirMassFlowRate)
        EXPECT_EQ(expected_OAVolFlowRate, thisAirTerminal.OutdoorAirFlowRate) # OA volume flow rate
        state.dataGlobal.HourOfDay = 12
        Sched.UpdateScheduleVals(state)
        state.dataHeatBal.ZoneIntGain[0].NOFOCC = 1.5
        expectedMassFlow = 1.0 * ((1.5 * 0.1) + 0.5)
        SimulateSingleDuct(state, thisAirDisUnit.EquipName[0], FirstHVACIteration, ZonePtr, ZoneAirNodeNum, thisAirDisUnit.EquipIndex[0])
        expected_OAVolFlowRate = thisAirTerminalOutlet.AirMassFlowRate * thisAirLoop.OAFrac / state.dataEnvrn.StdRhoAir
        EXPECT_EQ(expectedMassFlow, thisAirTerminalInlet.AirMassFlowRate)
        EXPECT_EQ(expectedMassFlow, thisAirTerminalOutlet.AirMassFlowRate)
        EXPECT_EQ(expected_OAVolFlowRate, thisAirTerminal.OutdoorAirFlowRate) # OA volume flow rate
        state.dataGlobal.HourOfDay = 24
        Sched.UpdateScheduleVals(state)
        state.dataHeatBal.ZoneIntGain[0].NOFOCC = 1.5
        expectedMassFlow = 0.0 * ((1.5 * 0.1) + 0.5)
        SimulateSingleDuct(state, thisAirDisUnit.EquipName[0], FirstHVACIteration, ZonePtr, ZoneAirNodeNum, thisAirDisUnit.EquipIndex[0])
        expected_OAVolFlowRate = thisAirTerminalOutlet.AirMassFlowRate * thisAirLoop.OAFrac / state.dataEnvrn.StdRhoAir
        EXPECT_EQ(expectedMassFlow, thisAirTerminalInlet.AirMassFlowRate)
        EXPECT_EQ(expectedMassFlow, thisAirTerminalOutlet.AirMassFlowRate)
        EXPECT_EQ(expected_OAVolFlowRate, thisAirTerminal.OutdoorAirFlowRate) # OA volume flow rate is zero

    @staticmethod
    def AirTerminalSingleDuctCVNoReheat_SimSensibleOutPutTest(self: EnergyPlusFixture):
        var ErrorsFound: Bool = False
        var FirstHVACIteration: Bool = False
        var idf_objects: String = delimited_string([
            "  AirTerminal:SingleDuct:ConstantVolume:NoReheat,",
            "    CVNoReheatATU,           !- Name",
            "    AvailSchedule,           !- Availability Schedule Name",
            "    NoReheatAirInletNode,    !- Air Inlet Node Name",
            "    NoReheatAirOutletNode,   !- Air Outlet Node Name",
            "    1.0;                     !- Maximum Air Flow Rate {m3/s}",
            "  Schedule:Compact,",
            "    AvailSchedule,           !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,1.0;        !- Field 3",
            "  ZoneHVAC:EquipmentList,",
            "    ZoneEquipment,           !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
            "    NoReheatADU,             !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:AirDistributionUnit,",
            "    NoReheatADU,             !- Name",
            "    NoReheatAirOutletNode,   !- Air Distribution Unit Outlet Node Name",
            "    AirTerminal:SingleDuct:ConstantVolume:NoReheat,  !- Air Terminal Object Type",
            "    CVNoReheatATU;           !- Air Terminal Name",
            "  Zone,",
            "    Zone One,                !- Name",
            "    0,                       !- Direction of Relative North {deg}",
            "    0,                       !- X Origin {m}",
            "    0,                       !- Y Origin {m}",
            "    0,                       !- Z Origin {m}",
            "    1,                       !- Type",
            "    1,                       !- Multiplier",
            "    2.40,                    !- Ceiling Height {m}",
            "    240.0;                   !- Volume {m3}",
            "  ZoneHVAC:EquipmentConnections,",
            "    Zone One,                !- Name",
            "    ZoneEquipment,           !- Zone Conditioning Equipment List Name",
            "    ZoneInlets,              !- Zone Air Inlet Node or NodeList Name",
            "    ,                        !- Zone Air Exhaust Node or NodeList Name",
            "    Zone Air Node,           !- Zone Air Node Name",
            "    Zone Return Air Node;    !- Zone Return Air Node Name",
            "  NodeList,",
            "    ZoneInlets,              !- Name",
            "    NoReheatAirOutletNode;   !- Node 1 Name",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
        state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
        state.init_state(state)
        GetZoneData(state, ErrorsFound)
        ASSERT_FALSE(ErrorsFound)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetSysInput(state)
        state.dataGlobal.SysSizingCalc = True
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataEnvrn.StdRhoAir = 1.0
        state.dataEnvrn.OutBaroPress = 101325.0
        var AirDistUnitNum: Int = 0
        var AirTerminalNum: Int = 0
        var thisAirTerminal = state.dataSingleDuct.sd_airterminal[AirTerminalNum]
        var InletNode: Int = thisAirTerminal.InletNodeNum
        var OutletNode: Int = thisAirTerminal.OutletNodeNum
        var ZonePtr: Int = thisAirTerminal.CtrlZoneNum
        var ZoneAirNodeNum: Int = state.dataZoneEquip.ZoneEquipConfig[ZonePtr].ZoneNode
        thisAirTerminal.availSched.currentVal = 1.0 # unit is always available
        var MassFlowRateMaxAvail: Float64 = thisAirTerminal.MaxAirVolFlowRate * state.dataEnvrn.StdRhoAir
        EXPECT_EQ(1.0, thisAirTerminal.MaxAirVolFlowRate)
        EXPECT_EQ(1.0, MassFlowRateMaxAvail)
        state.dataLoopNodes.Node[InletNode].Temp = 35.0
        state.dataLoopNodes.Node[InletNode].HumRat = 0.0075
        state.dataLoopNodes.Node[InletNode].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat)
        state.dataLoopNodes.Node[OutletNode].Temp = state.dataLoopNodes.Node[InletNode].Temp
        state.dataLoopNodes.Node[OutletNode].HumRat = state.dataLoopNodes.Node[InletNode].HumRat
        state.dataLoopNodes.Node[OutletNode].Enthalpy = state.dataLoopNodes.Node[InletNode].Enthalpy
        state.dataLoopNodes.Node[ZoneAirNodeNum].Temp = 20.0
        state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat = 0.005
        state.dataLoopNodes.Node[ZoneAirNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[ZoneAirNodeNum].Temp, state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat)
        state.dataLoopNodes.Node[InletNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = 0.0
        FirstHVACIteration = True
        state.dataSingleDuct.GetInputFlag = False
        var SysOutputProvided: Float64 = 0.0
        var NonAirSysOutput: Float64 = 0.0
        var LatOutputProvided: Float64 = 0.0
        SimZoneAirLoopEquipment(state, AirDistUnitNum, SysOutputProvided, NonAirSysOutput, LatOutputProvided, FirstHVACIteration, ZonePtr)
        EXPECT_EQ(MassFlowRateMaxAvail, thisAirTerminal.AirMassFlowRateMax)         # design maximum mass flow rate
        EXPECT_EQ(0.0, thisAirTerminal.sd_airterminalInlet.AirMassFlowRateMaxAvail) # maximum available mass flow rate
        EXPECT_EQ(0.0, thisAirTerminal.sd_airterminalInlet.AirMassFlowRate)         # inlet mass flow rate is zero
        EXPECT_EQ(0.0, thisAirTerminal.sd_airterminalOutlet.AirMassFlowRate)        # outlet mass flow rate is zero
        EXPECT_EQ(0.0, SysOutputProvided)                                           # delivered sensible heating is zero
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = MassFlowRateMaxAvail
        EXPECT_EQ(1.0, MassFlowRateMaxAvail)
        var CpAir: Float64 = PsyCpAirFnW(min(state.dataLoopNodes.Node[OutletNode].HumRat, state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat))
        var SensHeatRateProvided: Float64 = MassFlowRateMaxAvail * CpAir * (state.dataLoopNodes.Node[OutletNode].Temp - state.dataLoopNodes.Node[ZoneAirNodeNum].Temp)
        SimZoneAirLoopEquipment(state, AirDistUnitNum, SysOutputProvided, NonAirSysOutput, LatOutputProvided, FirstHVACIteration, ZonePtr)
        EXPECT_EQ(MassFlowRateMaxAvail, thisAirTerminal.sd_airterminalInlet.AirMassFlowRate)
        EXPECT_EQ(MassFlowRateMaxAvail, thisAirTerminal.sd_airterminalOutlet.AirMassFlowRate)
        EXPECT_NEAR(SensHeatRateProvided, SysOutputProvided, 0.001)
        EXPECT_EQ(thisAirTerminal.sd_airterminalOutlet.AirTemp, thisAirTerminal.sd_airterminalInlet.AirTemp)
        EXPECT_EQ(thisAirTerminal.sd_airterminalOutlet.AirHumRat, thisAirTerminal.sd_airterminalInlet.AirHumRat)
        EXPECT_EQ(thisAirTerminal.sd_airterminalOutlet.AirEnthalpy, thisAirTerminal.sd_airterminalInlet.AirEnthalpy)
        EXPECT_EQ(thisAirTerminal.sd_airterminalOutlet.AirMassFlowRate, thisAirTerminal.sd_airterminalInlet.AirMassFlowRate)
        state.dataLoopNodes.Node[InletNode].Temp = 15.0
        state.dataLoopNodes.Node[InletNode].HumRat = 0.0085
        state.dataLoopNodes.Node[InletNode].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, state.dataLoopNodes.Node[InletNode].HumRat)
        state.dataLoopNodes.Node[OutletNode].Temp = state.dataLoopNodes.Node[InletNode].Temp
        state.dataLoopNodes.Node[OutletNode].HumRat = state.dataLoopNodes.Node[InletNode].HumRat
        state.dataLoopNodes.Node[OutletNode].Enthalpy = state.dataLoopNodes.Node[InletNode].Enthalpy
        state.dataLoopNodes.Node[ZoneAirNodeNum].Temp = 24.0
        state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat = 0.00975
        state.dataLoopNodes.Node[ZoneAirNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[ZoneAirNodeNum].Temp, state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat)
        state.dataLoopNodes.Node[InletNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = 0.0
        FirstHVACIteration = True
        SysOutputProvided = 0.0
        NonAirSysOutput = 0.0
        LatOutputProvided = 0.0
        SimZoneAirLoopEquipment(state, AirDistUnitNum, SysOutputProvided, NonAirSysOutput, LatOutputProvided, FirstHVACIteration, ZonePtr)
        EXPECT_EQ(MassFlowRateMaxAvail, thisAirTerminal.AirMassFlowRateMax)         # design maximum mass flow rate
        EXPECT_EQ(0.0, thisAirTerminal.sd_airterminalInlet.AirMassFlowRateMaxAvail) # maximum available mass flow rate
        EXPECT_EQ(0.0, thisAirTerminal.sd_airterminalInlet.AirMassFlowRate)         # inlet mass flow rate is zero
        EXPECT_EQ(0.0, thisAirTerminal.sd_airterminalOutlet.AirMassFlowRate)        # outlet mass flow rate is zero
        EXPECT_EQ(0.0, SysOutputProvided)                                           # delivered sensible cooling is zero
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = MassFlowRateMaxAvail
        EXPECT_EQ(1.0, MassFlowRateMaxAvail)
        CpAir = PsyCpAirFnW(min(state.dataLoopNodes.Node[OutletNode].HumRat, state.dataLoopNodes.Node[ZoneAirNodeNum].HumRat))
        var SensCoolRateProvided: Float64 = MassFlowRateMaxAvail * CpAir * (state.dataLoopNodes.Node[OutletNode].Temp - state.dataLoopNodes.Node[ZoneAirNodeNum].Temp)
        SimZoneAirLoopEquipment(state, AirDistUnitNum, SysOutputProvided, NonAirSysOutput, LatOutputProvided, FirstHVACIteration, ZonePtr)
        EXPECT_EQ(MassFlowRateMaxAvail, thisAirTerminal.sd_airterminalInlet.AirMassFlowRate)
        EXPECT_EQ(MassFlowRateMaxAvail, thisAirTerminal.sd_airterminalOutlet.AirMassFlowRate)
        EXPECT_NEAR(SensCoolRateProvided, SysOutputProvided, 0.001)
        EXPECT_EQ(thisAirTerminal.sd_airterminalOutlet.AirTemp, thisAirTerminal.sd_airterminalInlet.AirTemp)
        EXPECT_EQ(thisAirTerminal.sd_airterminalOutlet.AirHumRat, thisAirTerminal.sd_airterminalInlet.AirHumRat)
        EXPECT_EQ(thisAirTerminal.sd_airterminalOutlet.AirEnthalpy, thisAirTerminal.sd_airterminalInlet.AirEnthalpy)
        EXPECT_EQ(thisAirTerminal.sd_airterminalOutlet.AirMassFlowRate, thisAirTerminal.sd_airterminalInlet.AirMassFlowRate)

    @staticmethod
    def AirTerminalSingleDuctCVNoReheat_DownstreamLeakTest(self: EnergyPlusFixture):
        var ErrorsFound: Bool = False
        var FirstHVACIteration: Bool = False
        var idf_objects: String = delimited_string([
            "  AirTerminal:SingleDuct:ConstantVolume:NoReheat,",
            "    CVNoReheatATU,           !- Name",
            "    AvailSchedule,           !- Availability Schedule Name",
            "    NoReheatAirInletNode,    !- Air Inlet Node Name",
            "    NoReheatAirOutletNode,   !- Air Outlet Node Name",
            "    1.0;                     !- Maximum Air Flow Rate {m3/s}",
            "  Schedule:Compact,",
            "    AvailSchedule,           !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,1.0;        !- Field 3",
            "  ZoneHVAC:EquipmentList,",
            "    ZoneEquipment,           !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "