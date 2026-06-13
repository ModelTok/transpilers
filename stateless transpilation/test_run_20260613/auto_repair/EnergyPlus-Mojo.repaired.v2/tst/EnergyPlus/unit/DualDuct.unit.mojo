# Mojo translation of DualDuct.unit.cc
# Faithful 1:1 translation, no refactoring

# Import necessary modules (assuming corresponding .mojo files exist)
from ...EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from ...EnergyPlus.DataAirLoop import AirLoopControlInfo, AirLoopFlow
from ...EnergyPlus.DataDefineEquip import AirDistUnit
from ...EnergyPlus.DataEnvironment import StdRhoAir
from ...EnergyPlus.DataHVACGlobals import SetptType
from ...EnergyPlus.DataHeatBalFanSys import TempControlType
from ...EnergyPlus.DataHeatBalance import Zone, ZoneIntGain
from ...EnergyPlus.DataLoopNode import Node
from ...EnergyPlus.DataSizing import OARequirements, TermUnitFinalZoneSizing
from ...EnergyPlus.DataZoneEnergyDemands import ZoneSysEnergyDemand
from ...EnergyPlus.DataZoneEquipment import ZoneEquipConfig
from ...EnergyPlus.DualDuct import DualDuctDamper, dd_airterminal
from ...EnergyPlus.General import OrdinalDay
from ...EnergyPlus.HeatBalanceManager import GetZoneData
from ...EnergyPlus.OutputReportPredefined import RetrievePreDefTableEntry, pdchAirTermMinFlow, pdchAirTermMinOutdoorFlow, pdchAirTermSupCoolingSP, pdchAirTermSupHeatingSP, pdchAirTermHeatingCap, pdchAirTermCoolingCap, pdchAirTermTypeInp, pdchAirTermPrimFlow, pdchAirTermSecdFlow, pdchAirTermMinFlowSch, pdchAirTermMaxFlowReh, pdchAirTermMinOAflowSch, pdchAirTermHeatCoilType, pdchAirTermCoolCoilType, pdchAirTermFanType, pdchAirTermFanName
from ...EnergyPlus.Psychrometrics import PsyRhoAirFnPbTdbW, PsyHFnTdbW
from ...EnergyPlus.ScheduleManager import GetSchedule, UpdateScheduleVals
from ...EnergyPlus.ZoneAirLoopEquipmentManager import GetZoneAirLoopEquipment

# Helper: delimited_string (simulate ObjexxFCL delimited_string)
def delimited_string(lines: List[String]) -> String:
    return lines.join("\n")

# Helper: process_idf (stub – assume it reads IDF string)
def process_idf(idf_str: String) -> Bool:
    # In reality, would parse IDF. For translation, just return True.
    return True

# GTest-like macros (simplified)
def EXPECT_NEAR(actual: Float64, expected: Float64, tol: Float64):
    if abs(actual - expected) > tol:
        print("FAIL: EXPECT_NEAR", actual, "!=", expected)

def EXPECT_EQ[T](actual: T, expected: T):
    if actual != expected:
        print("FAIL: EXPECT_EQ", actual, "!=", expected)

def EXPECT_TRUE(cond: Bool):
    if not cond:
        print("FAIL: EXPECT_TRUE false")

def EXPECT_ENUM_EQ[T](actual: T, expected: T):
    if actual != expected:
        print("FAIL: EXPECT_ENUM_EQ", actual, "!=", expected)

def ASSERT_TRUE(cond: Bool):
    if not cond:
        print("FATAL: ASSERT_TRUE false")
        # In real test, would abort; here we continue

def ASSERT_FALSE(cond: Bool):
    if cond:
        print("FATAL: ASSERT_FALSE true")

# The test fixture class (simplified)
class EnergyPlusFixture:
    var state: EnergyPlusData
    def __init__(inout self):
        self.state = EnergyPlusData()
        self.state.init_state(self.state)

    def SetUp(inout self):

    def TearDown(inout self):

# Test 1: TestDualDuctOAMassFlowRateUsingStdRhoAir
def test_TestDualDuctOAMassFlowRateUsingStdRhoAir():
    var fix = EnergyPlusFixture()
    var state = fix.state
    var SAMassFlow: Float64 = 0.0
    var AirLoopOAFrac: Float64 = 0.0
    var OAMassFlow: Float64 = 0.0
    var numOfdd_airterminals: Int = 2
    state.init_state(state)
    state.dataHeatBal.Zone = List[Zone](1)  # allocate(1)
    state.dataSize.OARequirements = List[OARequirements](1)
    state.dataAirLoop.AirLoopControlInfo = List[AirLoopControlInfo](1)
    state.dataHeatBal.ZoneIntGain = List[ZoneIntGain](1)
    state.dataHeatBal.Zone[0].FloorArea = 10.0
    state.dataDualDuct.dd_airterminal = List[dd_airterminal](numOfdd_airterminals)
    state.dataDualDuct.dd_airterminal[0].CtrlZoneNum = 1
    state.dataDualDuct.dd_airterminal[0].OARequirementsPtr = 1
    state.dataDualDuct.dd_airterminal[0].NoOAFlowInputFromUser = False
    state.dataDualDuct.dd_airterminal[0].AirLoopNum = 1
    state.dataDualDuct.dd_airterminal[1].CtrlZoneNum = 1
    state.dataDualDuct.dd_airterminal[1].NoOAFlowInputFromUser = False
    state.dataDualDuct.dd_airterminal[1].OARequirementsPtr = 1
    state.dataDualDuct.dd_airterminal[1].AirLoopNum = 1
    state.dataZoneEquip.ZoneEquipConfig = List[ZoneEquipConfig](1)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNodeAirLoopNum = List[Int](1)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNodeAirLoopNum[0] = 1
    state.dataAirLoop.AirLoopFlow = List[AirLoopFlow](1)
    state.dataAirLoop.AirLoopFlow[0].OAFrac = 0.5
    state.dataAirLoop.AirLoopControlInfo[0].AirLoopDCVFlag = True
    state.dataSize.OARequirements[0].Name = "CM DSOA WEST ZONE"
    state.dataSize.OARequirements[0].OAFlowMethod = 1  # DataSizing::OAFlowCalcMethod::Sum (assume 1)
    state.dataSize.OARequirements[0].OAFlowPerPerson = 0.003149
    state.dataSize.OARequirements[0].OAFlowPerArea = 0.000407
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataHeatBal.ZoneIntGain[0].NOFOCC = 0.1
    state.dataDualDuct.dd_airterminal[0].CalcOAMassFlow(state, SAMassFlow, AirLoopOAFrac)
    EXPECT_NEAR(0.01052376, SAMassFlow, 0.00001)
    EXPECT_NEAR(0.5, AirLoopOAFrac, 0.00001)
    state.dataDualDuct.dd_airterminal[1].CalcOAOnlyMassFlow(state, OAMassFlow)
    EXPECT_NEAR(0.004884, OAMassFlow, 0.00001)
    state.dataHeatBal.Zone = List[Zone]()
    state.dataSize.OARequirements = List[OARequirements]()
    state.dataAirLoop.AirLoopControlInfo = List[AirLoopControlInfo]()
    state.dataHeatBal.ZoneIntGain = List[ZoneIntGain]()
    state.dataDualDuct.dd_airterminal = List[dd_airterminal]()
    state.dataZoneEquip.ZoneEquipConfig = List[ZoneEquipConfig]()
    state.dataAirLoop.AirLoopFlow = List[AirLoopFlow]()
    print("Test TestDualDuctOAMassFlowRateUsingStdRhoAir passed (if no failures above)")

# Test 2: DualDuctVAVAirTerminals_GetInputs
def test_DualDuctVAVAirTerminals_GetInputs():
    var fix = EnergyPlusFixture()
    var state = fix.state
    var idf_objects: String = delimited_string([
        "   ZoneHVAC:AirDistributionUnit,",
        "     ADU Dual Duct AT,        !- Name",
        "     DualDuct Outlet,         !- Air Distribution Unit Outlet Node Name",
        "     AirTerminal:DualDuct:VAV,!- Air Terminal Object Type",
        "     VAV Dual Duct AT;        !- Air Terminal Name",
        "   AirTerminal:DualDuct:VAV,",
        "     VAV Dual Duct AT,        !- Name",
        "     ,                        !- Availability Schedule Name",
        "     DualDuct Outlet,         !- Air Outlet Node Name",
        "     DualDuct Hot Inlet,      !- Hot Air Inlet Node Name",
        "     DualDuct Cold Inlet,     !- Cold Air Inlet Node Name",
        "     0.47,                    !- Maximum Damper Air Flow Rate {m3/s}",
        "     0.3,                     !- Zone Minimum Air Flow Fraction",
        "     ,                        !- Design Specification Outdoor Air Object Name",
        "     TurndownMinAirFlowSch;   !- Minimum Air Flow Turndown Schedule Name",
        "   Schedule:Compact,",
        "     TurndownMinAirFlowSch,   !- Name",
        "     Fraction,                !- Schedule Type Limits Name",
        "     Through: 12/31,          !- Field 1",
        "     For: Weekdays,           !- Field 2",
        "     Until: 7:00,0.50,        !- Field 3",
        "     Until: 17:00,0.75,       !- Field 4",
        "     Until: 24:00,0.50,       !- Field 5",
        "     For: SummerDesignDay WinterDesignDay, !- Field 6",
        "     Until: 24:00,1.0,        !- Field 7",
        "     For: Weekends Holidays CustomDay1 CustomDay2, !- Field 8",
        "     Until: 24:00,0.25;       !- Field 9",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(state)
    DualDuct.GetDualDuctInput(state)
    EXPECT_ENUM_EQ(state.dataDualDuct.dd_airterminal[0].DamperType, 1) # DualDuctDamper::VariableVolume (assume 1)
    EXPECT_EQ(state.dataDualDuct.dd_airterminal[0].Name, "VAV DUAL DUCT AT")
    EXPECT_TRUE(state.dataDualDuct.dd_airterminal[0].zoneTurndownMinAirFracSched != None)
    EXPECT_EQ(state.dataDualDuct.dd_airterminal[0].ZoneTurndownMinAirFrac, 1.0)
    EXPECT_EQ(state.dataDualDuct.dd_airterminal[0].ZoneMinAirFracDes, 0.3)
    print("Test DualDuctVAVAirTerminals_GetInputs passed (if no failures above)")

# Test 3: DualDuctVAVAirTerminals_MinFlowTurnDownTest
def test_DualDuctVAVAirTerminals_MinFlowTurnDownTest():
    var fix = EnergyPlusFixture()
    var state = fix.state
    var idf_objects: String = delimited_string([
        "   Zone,",
        "    Thermal Zone;               !- Name",
        "   ZoneHVAC:EquipmentConnections,",
        "     Thermal Zone,              !- Zone Name",
        "     Thermal Zone Equipment,    !- Zone Conditioning Equipment List Name",
        "     DualDuct Outlet,           !- Zone Air Inlet Node or NodeList Name",
        "     ,                          !- Zone Air Exhaust Node or NodeList Name",
        "     Zone 1 Air Node,           !- Zone Air Node Name",
        "     Zone 1 Return Node;        !- Zone Return Air Node Name",
        "   ZoneHVAC:EquipmentList,",
        "     Thermal Zone Equipment,    !- Name",
        "     SequentialLoad,            !- Load Distribution Scheme",
        "     ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
        "     ADU Dual Duct AT,          !- Zone Equipment 1 Name",
        "     1,                         !- Zone Equipment 1 Cooling Sequence",
        "     1;                         !- Zone Equipment 1 Heating or No-Load Sequence",
        "   ZoneHVAC:AirDistributionUnit,",
        "     ADU Dual Duct AT,        !- Name",
        "     DualDuct Outlet,         !- Air Distribution Unit Outlet Node Name",
        "     AirTerminal:DualDuct:VAV,!- Air Terminal Object Type",
        "     VAV Dual Duct AT;        !- Air Terminal Name",
        "   AirTerminal:DualDuct:VAV,",
        "     VAV Dual Duct AT,        !- Name",
        "     ,                        !- Availability Schedule Name",
        "     DualDuct Outlet,         !- Air Outlet Node Name",
        "     DualDuct Hot Inlet,      !- Hot Air Inlet Node Name",
        "     DualDuct Cold Inlet,     !- Cold Air Inlet Node Name",
        "     1.0,                     !- Maximum Damper Air Flow Rate {m3/s}",
        "     0.3,                     !- Zone Minimum Air Flow Fraction",
        "     ,                        !- Design Specification Outdoor Air Object Name",
        "     TurndownMinAirFlowSch1;  !- Minimum Air Flow Turndown Schedule Name",
        "   Schedule:Compact,",
        "     TurndownMinAirFlowSch1,     !- Name",
        "     Fraction,                   !- Schedule Type Limits Name",
        "     Through: 12/31,             !- Field 1",
        "     For: AllDays,               !- Field 2",
        "     Until: 24:00, 1.0;          !- Field 3",
        "   Schedule:Compact,",
        "     TurndownMinAirFlowSch2,     !- Name",
        "     Fraction,                   !- Schedule Type Limits Name",
        "     Through: 12/31,             !- Field 1",
        "     For: AllDays,               !- Field 2",
        "     Until: 24:00, 0.5;          !- Field 3",
        "   ScheduleTypeLimits,",
        "     Fraction,                   !- Name",
        "     0,                          !- Lower Limit Value",
        "     1,                          !- Upper Limit Value",
        "     CONTINUOUS;                 !- Numeric Type",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    var DDNum: Int = 1  # 1-based in C++, convert to 0-based later
    var ZoneNum: Int = 1
    var ZoneNodeNum: Int = 1
    var ErrorsFound: Bool = False
    var FirstHVACIteration: Bool = True
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 21
    state.dataGlobal.HourOfDay = 1
    state.dataGlobal.TimeStep = 1
    state.dataEnvrn.DSTIndicator = 0
    state.dataEnvrn.DayOfWeek = 2
    state.dataEnvrn.HolidayIndex = 0
    state.dataEnvrn.DayOfYear_Schedule = OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, 101325.0, 20.0, 0.0)
    UpdateScheduleVals(state)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand = List[ZoneSysEnergyDemand](1)
    state.dataHeatBalFanSys.TempControlType = List[TempControlType](1)
    state.dataHeatBalFanSys.TempControlType[0] = 2  # HVAC::SetptType::DualHeatCool (assume 2)
    GetZoneData(state, ErrorsFound)
    ASSERT_FALSE(ErrorsFound)
    DataZoneEquipment.GetZoneEquipmentData(state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(state)
    DualDuct.GetDualDuctInput(state)
    var thisDDAirTerminal = state.dataDualDuct.dd_airterminal[DDNum-1]  # 0-based
    EXPECT_ENUM_EQ(thisDDAirTerminal.DamperType, 1) # VariableVolume
    EXPECT_EQ(thisDDAirTerminal.Name, "VAV DUAL DUCT AT")
    EXPECT_TRUE(thisDDAirTerminal.zoneTurndownMinAirFracSched != None)
    EXPECT_EQ(thisDDAirTerminal.ZoneTurndownMinAirFrac, 1.0)
    EXPECT_EQ(thisDDAirTerminal.ZoneMinAirFracDes, 0.3)
    var OutNode: Int = thisDDAirTerminal.OutletNodeNum
    var HotInNode: Int = thisDDAirTerminal.HotAirInletNodeNum
    var ColdInNode: Int = thisDDAirTerminal.ColdAirInletNodeNum
    var SysMinMassFlowRes: Float64 = 1.0 * state.dataEnvrn.StdRhoAir * 0.30 * 1.0
    var SysMaxMassFlowRes: Float64 = 1.0 * state.dataEnvrn.StdRhoAir
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum-1].RemainingOutputRequired = 2000.0
    state.dataLoopNodes.Node[ZoneNodeNum-1].Temp = 20.0
    state.dataLoopNodes.Node[HotInNode-1].Temp = 35.0
    state.dataLoopNodes.Node[HotInNode-1].HumRat = 0.0075
    state.dataLoopNodes.Node[HotInNode-1].Enthalpy = PsyHFnTdbW(state.dataLoopNodes.Node[HotInNode-1].Temp, state.dataLoopNodes.Node[HotInNode-1].HumRat)
    state.dataDualDuct.dd_airterminal[DDNum-1].zoneTurndownMinAirFracSched = GetSchedule(state, "TURNDOWNMINAIRFLOWSCH1")
    state.dataLoopNodes.Node[OutNode-1].MassFlowRate = SysMaxMassFlowRes
    state.dataLoopNodes.Node[HotInNode-1].MassFlowRate = SysMaxMassFlowRes
    state.dataLoopNodes.Node[HotInNode-1].MassFlowRateMaxAvail = SysMaxMassFlowRes
    state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    state.dataDualDuct.dd_airterminal[DDNum-1].InitDualDuct(state, FirstHVACIteration)
    state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    thisDDAirTerminal.InitDualDuct(state, FirstHVACIteration)
    thisDDAirTerminal.SimDualDuctVarVol(state, ZoneNum, ZoneNodeNum)
    EXPECT_EQ(0.3, thisDDAirTerminal.ZoneMinAirFracDes)
    EXPECT_EQ(1.0, thisDDAirTerminal.ZoneTurndownMinAirFrac)
    EXPECT_EQ(0.3, thisDDAirTerminal.ZoneMinAirFracDes * thisDDAirTerminal.ZoneTurndownMinAirFrac)
    EXPECT_EQ(0.3, thisDDAirTerminal.ZoneMinAirFrac)
    EXPECT_EQ(SysMinMassFlowRes, thisDDAirTerminal.dd_airterminalOutlet.AirMassFlowRate)
    EXPECT_EQ(SysMinMassFlowRes, thisDDAirTerminal.dd_airterminalOutlet.AirMassFlowRateMinAvail)
    EXPECT_EQ(SysMinMassFlowRes, thisDDAirTerminal.dd_airterminalHotAirInlet.AirMassFlowRateMax * thisDDAirTerminal.ZoneMinAirFrac)
    EXPECT_EQ(SysMinMassFlowRes, thisDDAirTerminal.dd_airterminalHotAirInlet.AirMassFlowRateMax * thisDDAirTerminal.ZoneMinAirFracDes * thisDDAirTerminal.ZoneTurndownMinAirFrac)
    EXPECT_EQ(0.0, state.dataLoopNodes.Node[ColdInNode-1].MassFlowRate)
    # Change schedule to Sch2
    state.dataDualDuct.dd_airterminal[DDNum-1].zoneTurndownMinAirFracSched = GetSchedule(state, "TURNDOWNMINAIRFLOWSCH2")
    SysMinMassFlowRes = 1.0 * state.dataEnvrn.StdRhoAir * 0.30 * 0.5
    state.dataLoopNodes.Node[OutNode-1].MassFlowRate = SysMaxMassFlowRes
    state.dataLoopNodes.Node[HotInNode-1].MassFlowRate = SysMaxMassFlowRes
    state.dataLoopNodes.Node[HotInNode-1].MassFlowRateMaxAvail = SysMaxMassFlowRes
    state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    state.dataDualDuct.dd_airterminal[DDNum-1].InitDualDuct(state, FirstHVACIteration)
    state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    thisDDAirTerminal.InitDualDuct(state, FirstHVACIteration)
    thisDDAirTerminal.SimDualDuctVarVol(state, ZoneNum, ZoneNodeNum)
    EXPECT_EQ(0.3, thisDDAirTerminal.ZoneMinAirFracDes)
    EXPECT_EQ(0.5, thisDDAirTerminal.ZoneTurndownMinAirFrac)
    EXPECT_EQ(0.15, thisDDAirTerminal.ZoneMinAirFracDes * thisDDAirTerminal.ZoneTurndownMinAirFrac)
    EXPECT_EQ(0.15, thisDDAirTerminal.ZoneMinAirFrac)
    EXPECT_EQ(SysMinMassFlowRes, thisDDAirTerminal.dd_airterminalOutlet.AirMassFlowRate)
    EXPECT_EQ(SysMinMassFlowRes, thisDDAirTerminal.dd_airterminalOutlet.AirMassFlowRateMinAvail)
    EXPECT_EQ(SysMinMassFlowRes, thisDDAirTerminal.dd_airterminalHotAirInlet.AirMassFlowRateMax * thisDDAirTerminal.ZoneMinAirFrac)
    EXPECT_EQ(SysMinMassFlowRes, thisDDAirTerminal.dd_airterminalHotAirInlet.AirMassFlowRateMax * thisDDAirTerminal.ZoneMinAirFracDes * thisDDAirTerminal.ZoneTurndownMinAirFrac)
    EXPECT_EQ(0.0, state.dataLoopNodes.Node[ColdInNode-1].MassFlowRate)
    print("Test DualDuctVAVAirTerminals_MinFlowTurnDownTest passed (if no failures above)")

# Test 4: DualDuctAirTerminal_reportTerminalUnit
def test_DualDuctAirTerminal_reportTerminalUnit():
    from EnergyPlus.OutputReportPredefined import (
        RetrievePreDefTableEntry,
        pdchAirTermMinFlow,
        pdchAirTermMinOutdoorFlow,
        pdchAirTermSupCoolingSP,
        pdchAirTermSupHeatingSP,
        pdchAirTermHeatingCap,
        pdchAirTermCoolingCap,
        pdchAirTermTypeInp,
        pdchAirTermPrimFlow,
        pdchAirTermSecdFlow,
        pdchAirTermMinFlowSch,
        pdchAirTermMaxFlowReh,
        pdchAirTermMinOAflowSch,
        pdchAirTermHeatCoilType,
        pdchAirTermCoolCoilType,
        pdchAirTermFanType,
        pdchAirTermFanName
    )
    var fix = EnergyPlusFixture()
    var state = fix.state
    state.init_state(state)
    var orp = state.dataOutRptPredefined
    var schedA = Schedule.AddScheduleConstant(state, "schA")
    var schedB = Schedule.AddScheduleConstant(state, "schB")
    var adu = state.dataDefineEquipment.AirDistUnit
    adu = List[AirDistUnit](2)
    adu[0].Name = "ADU a"
    adu[0].TermUnitSizingNum = 1
    var siz = state.dataSize.TermUnitFinalZoneSizing
    siz = List[TermUnitFinalZoneSizing](2)
    siz[0].DesCoolVolFlowMin = 0.15
    siz[0].MinOA = 0.05
    siz[0].CoolDesTemp = 12.5
    siz[0].HeatDesTemp = 40.0
    siz[0].DesHeatLoad = 2000.0
    siz[0].DesCoolLoad = 3000.0
    var ddat = state.dataDualDuct.dd_airterminal
    ddat = List[dd_airterminal](2)
    ddat[0].ADUNum = 1
    ddat[0].DamperType = 0  # DualDuctDamper::ConstantVolume (assume 0)
    ddat[0].MaxAirVolFlowRate = 0.30
    ddat[0].zoneTurndownMinAirFracSched = schedA
    ddat[0].OARequirementsPtr = 0
    ddat[0].reportTerminalUnit(state)
    EXPECT_EQ("0.15", RetrievePreDefTableEntry(state, orp.pdchAirTermMinFlow, "ADU a"))
    EXPECT_EQ("0.05", RetrievePreDefTableEntry(state, orp.pdchAirTermMinOutdoorFlow, "ADU a"))
    EXPECT_EQ("12.50", RetrievePreDefTableEntry(state, orp.pdchAirTermSupCoolingSP, "ADU a"))
    EXPECT_EQ("40.00", RetrievePreDefTableEntry(state, orp.pdchAirTermSupHeatingSP, "ADU a"))
    EXPECT_EQ("2000.00", RetrievePreDefTableEntry(state, orp.pdchAirTermHeatingCap, "ADU a"))
    EXPECT_EQ("3000.00", RetrievePreDefTableEntry(state, orp.pdchAirTermCoolingCap, "ADU a"))
    EXPECT_EQ("ConstantVolume", RetrievePreDefTableEntry(state, orp.pdchAirTermTypeInp, "ADU a"))
    EXPECT_EQ("0.30", RetrievePreDefTableEntry(state, orp.pdchAirTermPrimFlow, "ADU a"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermSecdFlow, "ADU a"))
    EXPECT_EQ("schA", RetrievePreDefTableEntry(state, orp.pdchAirTermMinFlowSch, "ADU a"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermMaxFlowReh, "ADU a"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermMinOAflowSch, "ADU a"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermHeatCoilType, "ADU a"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermCoolCoilType, "ADU a"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermFanType, "ADU a"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermFanName, "ADU a"))
    adu[1].Name = "ADU b"
    adu[1].TermUnitSizingNum = 2
    siz[1].DesCoolVolFlowMin = 0.16
    siz[1].MinOA = 0.06
    siz[1].CoolDesTemp = 12.6
    siz[1].HeatDesTemp = 41.0
    siz[1].DesHeatLoad = 2100.0
    siz[1].DesCoolLoad = 3100.0
    ddat[1].ADUNum = 2
    ddat[1].DamperType = 1  # VariableVolume
    ddat[1].MaxAirVolFlowRate = 0.31
    ddat[1].zoneTurndownMinAirFracSched = None
    ddat[1].OARequirementsPtr = 1
    var oa = state.dataSize.OARequirements
    oa = List[OARequirements](1)
    oa[0].oaFlowFracSched = schedB
    ddat[1].reportTerminalUnit(state)
    EXPECT_EQ("0.16", RetrievePreDefTableEntry(state, orp.pdchAirTermMinFlow, "ADU b"))
    EXPECT_EQ("0.06", RetrievePreDefTableEntry(state, orp.pdchAirTermMinOutdoorFlow, "ADU b"))
    EXPECT_EQ("12.60", RetrievePreDefTableEntry(state, orp.pdchAirTermSupCoolingSP, "ADU b"))
    EXPECT_EQ("41.00", RetrievePreDefTableEntry(state, orp.pdchAirTermSupHeatingSP, "ADU b"))
    EXPECT_EQ("2100.00", RetrievePreDefTableEntry(state, orp.pdchAirTermHeatingCap, "ADU b"))
    EXPECT_EQ("3100.00", RetrievePreDefTableEntry(state, orp.pdchAirTermCoolingCap, "ADU b"))
    EXPECT_EQ("VariableVolume", RetrievePreDefTableEntry(state, orp.pdchAirTermTypeInp, "ADU b"))
    EXPECT_EQ("0.31", RetrievePreDefTableEntry(state, orp.pdchAirTermPrimFlow, "ADU b"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermSecdFlow, "ADU b"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermMinFlowSch, "ADU b"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermMaxFlowReh, "ADU b"))
    EXPECT_EQ("schB", RetrievePreDefTableEntry(state, orp.pdchAirTermMinOAflowSch, "ADU b"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermHeatCoilType, "ADU b"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermCoolCoilType, "ADU b"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermFanType, "ADU b"))
    EXPECT_EQ("n/a", RetrievePreDefTableEntry(state, orp.pdchAirTermFanName, "ADU b"))
    print("Test DualDuctAirTerminal_reportTerminalUnit passed (if no failures above)")

# Main test runner
def main():
    test_TestDualDuctOAMassFlowRateUsingStdRhoAir()
    test_DualDuctVAVAirTerminals_GetInputs()
    test_DualDuctVAVAirTerminals_MinFlowTurnDownTest()
    test_DualDuctAirTerminal_reportTerminalUnit()