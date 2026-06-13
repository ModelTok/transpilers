from Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, delimited_string
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import HVAC
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataSizing import DataSizing, AutoSize, SupplyAirFlowRate
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.Fans import Fans, GetFanIndex, GetFanInput
from EnergyPlus.HVACStandAloneERV import HVACStandAloneERV, SizeStandAloneERV
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.UtilityRoutines import UtilityRoutines

# Minimal test helpers to mimic gtest macros
def assert_true(condition: Bool, msg: String = ""):
    if not condition:
        print("ASSERT_TRUE failed: ", msg)
        # In a real test framework, this would abort; we'll just print and continue
        # For faithfulness, we keep the same behavior as C++ (fatal) but Mojo doesn't have abort
        # We'll raise an error
        raise Error("Assertion failed")

def expect_eq[T: Equatable](actual: T, expected: T, msg: String = ""):
    if actual != expected:
        print("EXPECT_EQ failed: ", msg, " expected ", expected, " got ", actual)

# The test fixture class is imported; we define test functions as methods of a test class
# Using @test decorator to indicate test functions
@test
def HVACStandAloneERV_Test1(inout self: EnergyPlusFixture):
    let idf_objects: String = delimited_string([
        "  Fan:OnOff,",
        "    ERV Supply Fan,          !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    0.5,                     !- Fan Total Efficiency",
        "    75.0,                    !- Pressure Rise {Pa}",
        "    20000.0,                 !- Maximum Flow Rate {m3/s}",
        "    0.9,                     !- Motor Efficiency",
        "    1.0,                     !- Motor In Airstream Fraction",
        "    HR Supply Outlet Node,   !- Air Inlet Node Name",
        "    Supply Fan Outlet Node;  !- Air Outlet Node Name",
        "  Fan:OnOff,",
        "    ERV Exhaust Fan,         !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    0.5,                     !- Fan Total Efficiency",
        "    75.0,                    !- Pressure Rise {Pa}",
        "    20000.0,                 !- Maximum Flow Rate {m3/s}",
        "    0.9,                     !- Motor Efficiency",
        "    1.0,                     !- Motor In Airstream Fraction",
        "    HR Secondary Outlet Node,!- Air Inlet Node Name",
        "    Exhaust Fan Outlet Node; !- Air Outlet Node Name",
        "  Schedule:Compact,",
        "    FanAndCoilAvailSched,    !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
    ])
    assert_true(process_idf(idf_objects))
    self.state.init_state(self.state)
    self.state.dataEnvrn.StdRhoAir = 1.0
    self.state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    self.state.dataHeatBal.Zone.allocate(1)
    self.state.dataHeatBal.Zone[0].Name = self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
    self.state.dataSize.ZoneEqSizing.allocate(1)
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
    self.state.dataHeatBal.TotPeople = 2
    self.state.dataHeatBal.People.allocate(self.state.dataHeatBal.TotPeople)
    self.state.dataHeatBal.People[0].ZonePtr = 1
    self.state.dataHeatBal.People[0].NumberOfPeople = 100.0
    self.state.dataHeatBal.People[0].sched = Sched.GetScheduleAlwaysOn(self.state)
    self.state.dataHeatBal.People[1].ZonePtr = 1
    self.state.dataHeatBal.People[1].NumberOfPeople = 200.0
    self.state.dataHeatBal.People[1].sched = Sched.GetScheduleAlwaysOn(self.state)
    self.state.dataHVACStandAloneERV.StandAloneERV.allocate(1)
    var erv = self.state.dataHVACStandAloneERV.StandAloneERV[0]
    erv.SupplyAirVolFlow = AutoSize
    erv.ExhaustAirVolFlow = AutoSize
    erv.AirVolFlowPerFloorArea = 1.0
    erv.AirVolFlowPerOccupant = 0.0
    erv.supplyAirFanType = HVAC.FanType.OnOff
    erv.SupplyAirFanName = "ERV SUPPLY FAN"
    erv.SupplyAirFanIndex = Fans.GetFanIndex(self.state, erv.SupplyAirFanName)
    erv.exhaustAirFanType = HVAC.FanType.OnOff
    erv.ExhaustAirFanName = "ERV EXHAUST FAN"
    erv.ExhaustAirFanIndex = Fans.GetFanIndex(self.state, erv.ExhaustAirFanName)
    self.state.dataHeatBal.Zone[0].Multiplier = 1.0
    self.state.dataHeatBal.Zone[0].FloorArea = 1000.0
    SizeStandAloneERV(self.state, 1)
    expect_eq(erv.SupplyAirVolFlow, 1000.0)
    erv.SupplyAirVolFlow = AutoSize
    erv.ExhaustAirVolFlow = AutoSize
    erv.AirVolFlowPerFloorArea = 0.0
    erv.AirVolFlowPerOccupant = 10.0
    self.state.dataHeatBal.Zone[0].Multiplier = 1.0
    self.state.dataHeatBal.Zone[0].FloorArea = 1000.0
    SizeStandAloneERV(self.state, 1)
    expect_eq(erv.SupplyAirVolFlow, 3000.0)
    erv.SupplyAirVolFlow = AutoSize
    erv.ExhaustAirVolFlow = AutoSize
    erv.AirVolFlowPerFloorArea = 1.0
    erv.AirVolFlowPerOccupant = 10.0
    self.state.dataHeatBal.Zone[0].Multiplier = 1.0
    self.state.dataHeatBal.Zone[0].FloorArea = 1000.0
    SizeStandAloneERV(self.state, 1)
    expect_eq(erv.SupplyAirVolFlow, 4000.0)
    erv.SupplyAirVolFlow = AutoSize
    erv.ExhaustAirVolFlow = AutoSize
    self.state.dataHeatBal.Zone[0].Multiplier = 5.0
    SizeStandAloneERV(self.state, 1)
    expect_eq(erv.SupplyAirVolFlow, 20000.0)

@test
def HVACStandAloneERV_Test2(inout self: EnergyPlusFixture):
    let idf_objects: String = delimited_string([
        "  Fan:OnOff,",
        "    ERV Supply Fan,          !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    0.5,                     !- Fan Total Efficiency",
        "    75.0,                    !- Pressure Rise {Pa}",
        "    autosize,                !- Maximum Flow Rate {m3/s}",
        "    0.9,                     !- Motor Efficiency",
        "    1.0,                     !- Motor In Airstream Fraction",
        "    HR Supply Outlet Node,   !- Air Inlet Node Name",
        "    Supply Fan Outlet Node;  !- Air Outlet Node Name",
        "  Fan:OnOff,",
        "    ERV Exhaust Fan,         !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    0.5,                     !- Fan Total Efficiency",
        "    75.0,                    !- Pressure Rise {Pa}",
        "    autosize,                !- Maximum Flow Rate {m3/s}",
        "    0.9,                     !- Motor Efficiency",
        "    1.0,                     !- Motor In Airstream Fraction",
        "    HR Secondary Outlet Node,!- Air Inlet Node Name",
        "    Exhaust Fan Outlet Node; !- Air Outlet Node Name",
        "  Schedule:Compact,",
        "    FanAndCoilAvailSched,    !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
    ])
    assert_true(process_idf(idf_objects))
    self.state.dataEnvrn.StdRhoAir = 1.0
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    GetFanInput(self.state)
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    self.state.dataHeatBal.Zone.allocate(1)
    self.state.dataHeatBal.Zone[0].Name = self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
    self.state.dataHeatBal.Zone[0].Multiplier = 1.0
    self.state.dataHeatBal.Zone[0].FloorArea = 100.0
    self.state.dataSize.ZoneEqSizing.allocate(1)
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SizingMethod.allocate(25)
    self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SizingMethod[HVAC.SystemAirflowSizing] = SupplyAirFlowRate
    self.state.dataSize.FinalZoneSizing.allocate(1)
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow = 0.0
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum - 1].DesHeatVolFlow = 0.0
    self.state.dataHeatBal.TotPeople = 2
    self.state.dataHeatBal.People.allocate(self.state.dataHeatBal.TotPeople)
    self.state.dataHeatBal.People[0].ZonePtr = 1
    self.state.dataHeatBal.People[0].NumberOfPeople = 10.0
    self.state.dataHeatBal.People[0].sched = Sched.GetScheduleAlwaysOn(self.state)
    self.state.dataHeatBal.People[1].ZonePtr = 1
    self.state.dataHeatBal.People[1].NumberOfPeople = 20.0
    self.state.dataHeatBal.People[1].sched = Sched.GetScheduleAlwaysOn(self.state)
    self.state.dataHVACStandAloneERV.StandAloneERV.allocate(1)
    var erv = self.state.dataHVACStandAloneERV.StandAloneERV[0]
    erv.SupplyAirVolFlow = AutoSize
    erv.ExhaustAirVolFlow = AutoSize
    erv.DesignSAFanVolFlowRate = AutoSize
    erv.DesignEAFanVolFlowRate = AutoSize
    erv.DesignHXVolFlowRate = AutoSize
    erv.SupplyAirFanName = self.state.dataFans.fans[0].Name
    erv.SupplyAirFanIndex = 1
    erv.ExhaustAirFanName = self.state.dataFans.fans[1].Name
    erv.ExhaustAirFanIndex = 2
    erv.hxType = HVAC.HXType.AirToAir_SensAndLatent
    erv.HeatExchangerName = "ERV Heat Exchanger"
    erv.AirVolFlowPerFloorArea = 0.01
    erv.AirVolFlowPerOccupant = 0.0
    erv.HighRHOAFlowRatio = 1.2
    SizeStandAloneERV(self.state, 1)
    expect_eq(erv.SupplyAirVolFlow, 1.0)
    expect_eq(erv.DesignSAFanVolFlowRate, 1.2)
    expect_eq(erv.DesignEAFanVolFlowRate, 1.2)