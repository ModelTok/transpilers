from testing import *
from EnergyPlus.CurveManager import *
from EnergyPlus.Data import EnergyPlusData
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.Fans import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.General import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.OutdoorAirUnit import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant import DataPlant
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SteamCoils import *
from EnergyPlus.WaterCoils import *
from EnergyPlus.Fixtures.EnergyPlusFixture import (EnergyPlusFixture, compare_err_stream, compare_err_stream_substring)
from EnergyPlus.Curve import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataPlant import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.Fans import *
from EnergyPlus.HeatBalanceManager import *
from OutputReportPredefined import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.SteamCoils import *
from EnergyPlus.WaterCoils import *
from EnergyPlus.HVAC import *  # For HVAC::SystemAirflowSizing etc.

# Helper to convert C++ delimited_string (list of strings) to a single string
def delimited_string(parts: List[String]) -> String:
    var s: String = ""
    for i in range(len(parts)):
        if i > 0:
            s += "\n"
        s += parts[i]
    return s

# 1-based to 0-based index helper (not needed directly, but used throughout)
# We adjust array subscripts accordingly.

@test
def OutdoorAirUnit_AutoSize():
    var ErrorsFound: Bool = false
    var FirstHVACIteration: Bool = true
    var OAUnitNum: Int = 1
    var EquipPtr: Int = 1
    var CurZoneNum: Int = 1
    var SysOutputProvided: Float64 = 0.0
    var LatOutputProvided: Float64 = 0.0
    var ZoneInletNode: Int = 0
    let idf_objects: String = delimited_string([
        "Output:Diagnostics, DisplayExtraWarnings;",
        " ",
        "Zone,",
        "  SPACE1-1,                !- Name",
        "  0,                       !- Direction of Relative North {deg}",
        "  0,                       !- X Origin {m}",
        "  0,                       !- Y Origin {m}",
        "  0,                       !- Z Origin {m}",
        "  1,                       !- Type",
        "  1,                       !- Multiplier",
        "  2.5,                     !- Ceiling Height {m}",
        "  250.0;                   !- Volume {m3}",
        " ",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE1-1,                !- Zone Name",
        "  SPACE1-1 Eq,             !- Zone Conditioning Equipment List Name",
        "  Zone Eq Outlet Node,     !- Zone Air Inlet Node or NodeList Name",
        "  Zone Eq Exhaust Node,    !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE1-1 Node,           !- Zone Air Node Name",
        "  SPACE1-1 Out Node;       !- Zone Return Air Node Name",
        " ",
        "ZoneHVAC:EquipmentList,",
        "  SPACE1-1 Eq,             !- Name",
        "  SequentialLoad,          !- Load Distribution Scheme",
        "  ZoneHVAC:OutdoorAirUnit, !- Zone Equipment 1 Object Type",
        "  Zone1OutAir,             !- Zone Equipment 1 Name",
        "  1,                       !- Zone Equipment 1 Cooling Sequence",
        "  1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        " ",
        "ZoneHVAC:OutdoorAirUnit,",
        "  Zone1OutAir,             !- Name",
        "  AvailSched,              !- Availability Schedule Name",
        "  SPACE1-1,                !- Zone Name",
        "  autosize,                !- Outdoor Air Flow Rate{ m3 / s }",
        "  AvailSched,              !- Outdoor Air Schedule Name",
        "  Zone1OAUFan,             !- Supply Fan Name",
        "  DrawThrough,             !- Supply Fan Placement",
        "  Zone1OAUextFan,          !- Exhaust Fan Name",
        "  autosize,                !- Exhaust Air Flow Rate{ m3 / s }",
        "  AvailSched,              !- Exhaust Air Schedule Name",
        "  TemperatureControl,      !- Unit Control Type",
        "  OAUHiCtrlTemp,           !- High Air Control Temperature Schedule Name",
        "  OAULoCtrlTemp,           !- Low Air Control Temperature Schedule Name",
        "  Outside Air Inlet Node 1, !- Outdoor Air Node Name",
        "  Zone Eq Outlet Node,     !- AirOutlet Node Name",
        "  Zone Eq Inlet Node,      !- AirInlet Node Name",
        "  Zone Eq Inlet Node,      !- Supply Fan Outlet Node Name",
        "  Zone1OAEQLIST;           !- Outdoor Air Unit List Name",
        " ",
        "Fan:ConstantVolume,",
        "  Zone1OAUFan,             !- Name",
        "   AvailSched,             !- Availability Schedule Name",
        "   0.5,                    !- Fan Total Efficiency",
        "   75.0,                   !- Pressure Rise{ Pa }",
        "   autosize,               !- Maximum Flow Rate{ m3 / s }",
        "   0.9,                    !- Motor Efficiency",
        "   1.0,                    !- Motor In Airstream Fraction",
        "   Heat Coil Outlet Node,  !- Air Inlet Node Name",
        "   Zone Eq Inlet Node;     !- Air Outlet Node Name",
        " ",
        "Fan:ConstantVolume,",
        "   Zone1OAUextFan,         !- Name",
        "   AvailSched,             !- Availability Schedule Name",
        "   0.5,                    !- Fan Total Efficiency",
        "   75.0,                   !- Pressure Rise{ Pa }",
        "   autosize,               !- Maximum Flow Rate{ m3 / s }",
        "   0.9,                    !- Motor Efficiency",
        "   1.0,                    !- Motor In Airstream Fraction",
        "   Zone Eq Exhaust Node,   !- Air Inlet Node Name",
        "   OutAir1;                !- Air Outlet Node Name",
        " ",
        "ZoneHVAC:OutdoorAirUnit:EquipmentList,",
        "  Zone1OAEQLIST,           !- Name",
        "  CoilSystem:Cooling:DX,   !- Component 1 Object Type",
        "  DX Cooling Coil System 1, !- Component 1 Name",
        "  Coil:Heating:Electric,   !- Component 2 Object Type",
        "  Zone1OAUHeatingCoil;     !- Component 2 Name",
        " ",
        "CoilSystem:Cooling:DX,",
        "  DX Cooling Coil System 1, !- Name",
        "  AvailSched,              !- Availability Schedule Name",
        "  Zone Eq Outlet Node,     !- DX Cooling Coil System Inlet Node Name",
        "  Heat Coil Inlet Node,    !- DX Cooling Coil System Outlet Node Name",
        "  Heat Coil Inlet Node,    !- DX Cooling Coil System Sensor Node Name",
        "  Coil:Cooling:DX:SingleSpeed, !- Cooling Coil Object Type",
        "  ACDXCoil 1;              !- Cooling Coil Name",
        " ",
        "Coil:Cooling:DX:SingleSpeed,",
        "  ACDXCoil 1,              !- Name",
        "  AvailSched,              !- Availability Schedule Name",
        "  autosize,                !- Gross Rated Total Cooling Capacity{ W }",
        "  autosize,                !- Gross Rated Sensible Heat Ratio",
        "  3.0,                     !- Gross Rated Cooling COP{ W / W }",
        "  autosize,                !- Rated Air Flow Rate{ m3 / s }",
        "  ,                        !- 2017 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "  ,                        !- 2023 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "  Outside Air Inlet Node 1, !- Air Inlet Node Name",
        "  Heat Coil Inlet Node,    !- Air Outlet Node Name",
        "  BiQuadCurve,             !- Total Cooling Capacity Function of Temperature Curve Name",
        "  QuadraticCurve,          !- Total Cooling Capacity Function of Flow Fraction Curve Name",
        "  BiQuadCurve,             !- Energy Input Ratio Function of Temperature Curve Name",
        "  QuadraticCurve,          !- Energy Input Ratio Function of Flow Fraction Curve Name",
        "  QuadraticCurve;          !- Part Load Fraction Correlation Curve Name",
        " ",
        "Coil:Heating:Electric,",
        "  Zone1OAUHeatingCoil, !- Name",
        "  AvailSched, !- Availability Schedule Name",
        "  0.99, !- Efficiency",
        "  autosize, !- Nominal Capacity{ W }",
        "  Heat Coil Inlet Node, !- Air Inlet Node Name",
        "  Heat Coil Outlet Node;               !- Air Outlet Node Name",
        " ",
        "OutdoorAir:NodeList,",
        "  OutsideAirInletNodes;     !- Node or NodeList Name 1",
        " ",
        "NodeList,",
        "  OutsideAirInletNodes, !- Name",
        "  Outside Air Inlet Node 1; !- Node 1 Name",
        " ",
        " ",
        "ScheduleTypeLimits,",
        "  Any Number;              !- Name",
        " ",
        "Schedule:Compact,",
        "  AvailSched,           !- Name",
        "  Any Number,              !- Schedule Type Limits Name",
        "  Through: 12/31,          !- Field 13",
        "  For: AllDays,            !- Field 14",
        "  Until: 24:00,1.0;        !- Field 15",
        " ",
        "Schedule:Compact,",
        "  OAULoCtrlTemp, !- Name",
        "  Any Number, !- Schedule Type Limits Name",
        "  Through: 12/31, !- Field 1",
        "  For: AllDays, !- Field 2",
        "  Until: 24:00, 10;         !- Field 3",
        " ",
        "Schedule:Compact,",
        "  OAUHiCtrlTemp, !- Name",
        "  Any Number, !- Schedule Type Limits Name",
        "  Through: 12/31, !- Field 1",
        "  For: AllDays, !- Field 2",
        "  Until: 24:00, 15;         !- Field 3",
        " ",
        "Curve:Biquadratic,",
        "  BiQuadCurve,             !- Name",
        "  1.0,                     !- Coefficient1 Constant",
        "  0.0,                     !- Coefficient2 x",
        "  0.0,                     !- Coefficient3 x**2",
        "  0.0,                     !- Coefficient4 y",
        "  0.0,                     !- Coefficient5 y**2",
        "  0.0,                     !- Coefficient6 x*y",
        "  5,                       !- Minimum Value of x",
        "  36,                      !- Maximum Value of x",
        "  5,                       !- Minimum Value of y",
        "  36,                      !- Maximum Value of y",
        "  ,                        !- Minimum Curve Output",
        "  ,                        !- Maximum Curve Output",
        "  Temperature,             !- Input Unit Type for X",
        "  Temperature,             !- Input Unit Type for Y",
        "  Dimensionless;           !- Output Unit Type",
        " ",
        "Curve:Quadratic,",
        "  QuadraticCurve,          !- Name",
        "  1.0,                     !- Coefficient1 Constant",
        "  0.0,                     !- Coefficient2 x",
        "  0.0,                     !- Coefficient3 x**2",
        "  0.0,                     !- Minimum Value of x",
        "  1.5,                     !- Maximum Value of x",
        "  ,                        !- Minimum Curve Output",
        "  ,                        !- Maximum Curve Output",
        "  Dimensionless,           !- Input Unit Type for X",
        "  Dimensionless;           !- Output Unit Type",
        " ",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    state.dataGlobal.CurrentTime = 0.25
    state.dataGlobal.BeginEnvrnFlag = true
    state.dataSize.CurZoneEqNum = 1
    state.dataEnvrn.OutBaroPress = 101325
    state.dataZoneEquip.ZoneEquipInputsFilled = true
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.ZoneSizingRunDone = true
    state.dataSize.ZoneEqSizing[0].DesignSizeFromParent = false
    state.dataSize.ZoneEqSizing[0].SizingMethod.allocate(25)
    state.dataSize.ZoneEqSizing[0].SizingMethod[HVAC.SystemAirflowSizing] = DataSizing.SupplyAirFlowRate
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    GetZoneData(state, ErrorsFound)
    assert_false(ErrorsFound)
    GetZoneEquipmentData(state)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputRequired = 0.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = 0.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = 0.0
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[0].DesCoolVolFlow = 0.5
    state.dataSize.FinalZoneSizing[0].MinOA = 0.5
    state.dataSize.FinalZoneSizing[0].ZoneRetTempAtCoolPeak = 26.66667
    state.dataSize.FinalZoneSizing[0].ZoneTempAtCoolPeak = 26.66667
    state.dataSize.FinalZoneSizing[0].ZoneHumRatAtCoolPeak = 0.01117049470250416
    state.dataSize.FinalZoneSizing[0].CoolDDNum = 1
    state.dataSize.FinalZoneSizing[0].TimeStepNumAtCoolMax = 1
    state.dataSize.DesDayWeath.allocate(1)
    state.dataSize.DesDayWeath[0].Temp.allocate(1)
    state.dataSize.DesDayWeath[state.dataSize.FinalZoneSizing[0].CoolDDNum - 1].Temp[state.dataSize.FinalZoneSizing[0].TimeStepNumAtCoolMax - 1] = 35.0
    state.dataSize.FinalZoneSizing[0].CoolDesTemp = 13.1
    state.dataSize.FinalZoneSizing[0].CoolDesHumRat = 0.009297628698818194
    ZoneInletNode = OutdoorAirUnit.GetOutdoorAirUnitZoneInletNode(state, OAUnitNum)
    Sched.GetSchedule(state, "AVAILSCHED").currentVal = 1.0
    Sched.GetSchedule(state, "OAULOCTRLTEMP").currentVal = 1.0
    Sched.GetSchedule(state, "OAUHICTRLTEMP").currentVal = 1.0
    var EAFanInletNode = state.dataFans.fans[1].inletNodeNum  # 2 -> index 1 (0-based)
    state.dataLoopNodes.Node[EAFanInletNode].MassFlowRate = 0.60215437
    state.dataLoopNodes.Node[EAFanInletNode].MassFlowRateMaxAvail = 0.60215437
    OutdoorAirUnit.SimOutdoorAirUnit(state,
                                      "ZONE1OUTAIR",
                                      CurZoneNum,
                                      FirstHVACIteration,
                                      SysOutputProvided,
                                      LatOutputProvided,
                                      state.dataZoneEquip.ZoneEquipList[state.dataSize.CurZoneEqNum - 1].EquipIndex[EquipPtr - 1])
    assert_equal(state.dataSize.FinalZoneSizing[0].MinOA,
                 state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OutAirVolFlow)
    assert_equal(state.dataSize.FinalZoneSizing[0].MinOA * state.dataEnvrn.StdRhoAir,
                 state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OutAirMassFlow)
    assert_equal(state.dataSize.FinalZoneSizing[0].MinOA,
                 state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].ExtAirVolFlow)
    assert_equal(state.dataSize.FinalZoneSizing[0].MinOA * state.dataEnvrn.StdRhoAir,
                 state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].ExtAirMassFlow)
    var SAFanPower: Float64 = state.dataFans.fans[0].totalPower  # 1 -> 0
    var EAFanPower: Float64 = state.dataFans.fans[1].totalPower   # 2 -> 1
    assert_equal(SAFanPower, 75.0)
    assert_equal(EAFanPower, 75.0)
    assert_equal(SAFanPower + EAFanPower, state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].ElecFanRate)
    compare_err_stream_substring("", true)
    assert_true(compare_err_stream("", true))
    state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].ExtAirMassFlow = 0.0
    OutdoorAirUnit.CalcOutdoorAirUnit(state, OAUnitNum, CurZoneNum, FirstHVACIteration, SysOutputProvided, LatOutputProvided)
    let error_string: String = delimited_string([
        "   ** Warning ** Air mass flow between zone supply and exhaust is not balanced. Only the first occurrence is reported.",
        "   **   ~~~   ** Occurs in ZoneHVAC:OutdoorAirUnit Object= ZONE1OUTAIR",
        "   **   ~~~   ** Air mass balance is required by other outdoor air units: Fan:ZoneExhaust, ZoneMixing, ZoneCrossMixing, or other air flow control inputs.",
        "   **   ~~~   ** The outdoor mass flow rate = 0.602 and the exhaust mass flow rate = 0.000.",
        "   **   ~~~   **  Environment=, at Simulation time= 00:00 - 00:15",
    ])
    assert_true(compare_err_stream(error_string, true))

@test
def OutdoorAirUnit_WaterCoolingCoilAutoSizeTest():
    let idf_objects: String = delimited_string([
        "Zone,",
        "    Thermal Zone 1,          !- Name",
        "    ,                        !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    10,                      !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    ,                        !- Type",
        "    ,                        !- Multiplier",
        "    ,                        !- Ceiling Height {m}",
        "    300,                     !- Volume {m3}",
        "    100;                     !- Floor Area {m2}",
        "ZoneHVAC:EquipmentConnections,",
        "    Thermal Zone 1,          !- Zone Name",
        "    Thermal Zone 1 Equipment List,  !- Zone Conditioning Equipment List Name",
        "    Thermal Zone 1 Inlet Node List,  !- Zone Air Inlet Node or NodeList Name",
        "    Thermal Zone 1 Exhaust Node List,  !- Zone Air Exhaust Node or NodeList Name",
        "    Node 1,                  !- Zone Air Node Name",
        "    Thermal Zone 1 Return Air Node;  !- Zone Return Air Node or NodeList Name",
        "NodeList,",
        "    Thermal Zone 1 Inlet Node List,  !- Name",
        "    Node 5;                  !- Node 1 Name",
        "NodeList,",
        "    Thermal Zone 1 Exhaust Node List,  !- Name",
        "    Node 4;                  !- Node 1 Name",
        "OutdoorAir:Node,",
        "    Model Outdoor Air Node;  !- Name",
        "OutdoorAir:NodeList,",
        "    OAUnit OA Node;          !- Node or NodeList Name 1",
        "	Schedule:Constant,",
        "	FanAndCoilAvailSched, !- Name",
        "	FRACTION, !- Schedule Type",
        "	1;        !- TimeStep Value",
        "	ScheduleTypeLimits,",
        "	Fraction, !- Name",
        "	0.0, !- Lower Limit Value",
        "	1.0, !- Upper Limit Value",
        "	CONTINUOUS;              !- Numeric Type",
        "Schedule:Compact,",
        "    OAULoCtrlTemp,           !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    10;                      !- Field 4",
        "Schedule:Compact,",
        "    OAUHiCtrlTemp,           !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    15;                      !- Field 4",
        "ScheduleTypeLimits,",
        "    Temperature,             !- Name",
        "    -60,                     !- Lower Limit Value",
        "    200,                     !- Upper Limit Value",
        "    CONTINUOUS;              !- Numeric Type",
        "ZoneHVAC:EquipmentList,",
        "    Thermal Zone 1 Equipment List,  !- Name",
        "    ,                        !- Load Distribution Scheme",
        "    ZoneHVAC:OutdoorAirUnit, !- Zone Equipment 1 Object Type",
        "    OAUnit Zone 1,           !- Zone Equipment 1 Name",
        "    1,                       !- Zone Equipment 1 Cooling Sequence",
        "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:OutdoorAirUnit,",
        "    OAUnit Zone 1,           !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    Thermal Zone 1,          !- Zone Name",
        "    Autosize,                !- Outdoor Air Flow Rate {m3/s}",
        "    FanAndCoilAvailSched,    !- Outdoor Air Schedule Name",
        "    OAU Supply Fan,          !- Supply Fan Name",
        "    BlowThrough,             !- Supply Fan Placement",
        "    Zone 1 OAU ExhFan,       !- Exhaust Fan Name",
        "    Autosize,                !- Exhaust Air Flow Rate {m3/s}",
        "    FanAndCoilAvailSched,    !- Exhaust Air Schedule Name",
        "    TemperatureControl,      !- Unit Control Type",
        "    OAUHiCtrlTemp,           !- High Air Control Temperature Schedule Name",
        "    OAULoCtrlTemp,           !- Low Air Control Temperature Schedule Name",
        "    OAUnit OA Node,          !- Outdoor Air Node Name",
        "    Node 5,                  !- AirOutlet Node Name",
        "    OAUnit OA Node,          !- AirInlet Node Name",
        "    OAUnit Fan Outlet Node,  !- Supply FanOutlet Node Name",
        "    OAUnitZone1EQLIST;       !- Outdoor Air Unit List Name",
        "ZoneHVAC:OutdoorAirUnit:EquipmentList,",
        "    OAUnitZone1EQLIST,       !- Name",
        "    Coil:Cooling:Water,      !- Component 2 Object Type",
        "    OAU Water Cooling Coil;  !- Component 2 Name",
        "Fan:SystemModel,",
        "    Zone 1 OAU ExhFan,       !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    Node 4,                  !- Air Inlet Node Name",
        "    ZoneOAU Relief Node,     !- Air Outlet Node Name",
        "    Autosize,                !- Design Maximum Air Flow Rate {m3/s}",
        "    Discrete,                !- Speed Control Method",
        "    0.0,                     !- Electric Power Minimum Flow Rate Fraction",
        "    75.0,                    !- Design Pressure Rise {Pa}",
        "    0.9,                     !- Motor Efficiency",
        "    1.0,                     !- Motor In Air Stream Fraction",
        "    AUTOSIZE,                !- Design Electric Power Consumption {W}",
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method",
        "    ,                        !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "    ,                        !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "    0.50,                    !- Fan Total Efficiency",
        "    ,                        !- Electric Power Function of Flow Fraction Curve Name",
        "    ,                        !- Night Ventilation Mode Pressure Rise",
        "    ,                        !- Night Ventilation Mode Flow Fraction",
        "    ,                        !- Motor Loss Zone Name",
        "    ,                        !- Motor Loss Radiative Fraction ",
        "    ,                        !- End-Use Subcategory",
        "    1,                       !- Number of Speeds",
        "    1.0,                     !- Speed 1 Flow Fraction",
        "    1.0;                     !- Speed 1 Electric Power Fraction",
        "Fan:SystemModel,",
        "    OAU Supply Fan,          !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    OAUnit OA Node,          !- Air Inlet Node Name",
        "    OAUnit Fan Outlet Node,  !- Air Outlet Node Name",
        "    Autosize,                !- Design Maximum Air Flow Rate {m3/s}",
        "    Discrete,                !- Speed Control Method",
        "    0.0,                     !- Electric Power Minimum Flow Rate Fraction",
        "    75.0,                    !- Design Pressure Rise {Pa}",
        "    0.9,                     !- Motor Efficiency",
        "    1.0,                     !- Motor In Air Stream Fraction",
        "    AUTOSIZE,                !- Design Electric Power Consumption {W}",
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method",
        "    ,                        !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "    ,                        !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "    0.50,                    !- Fan Total Efficiency",
        "    ,                        !- Electric Power Function of Flow Fraction Curve Name",
        "    ,                        !- Night Ventilation Mode Pressure Rise",
        "    ,                        !- Night Ventilation Mode Flow Fraction",
        "    ,                        !- Motor Loss Zone Name",
        "    ,                        !- Motor Loss Radiative Fraction ",
        "    ,                        !- End-Use Subcategory",
        "    1,                       !- Number of Speeds",
        "    1.0,                     !- Speed 1 Flow Fraction",
        "    1.0;                     !- Speed 1 Electric Power Fraction",
        "Coil:Cooling:Water,",
        "    OAU Water Cooling Coil,  !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    Autosize,                !- Design Water Flow Rate {m3/s}",
        "    Autosize,                !- Design Air Flow Rate {m3/s}",
        "    Autosize,                !- Design Inlet Water Temperature {C}",
        "    Autosize,                !- Design Inlet Air Temperature {C}",
        "    Autosize,                !- Design Outlet Air Temperature {C}",
        "    Autosize,                !- Design Inlet Air Humidity Ratio {kgWater/kgDryAir}",
        "    Autosize,                !- Design Outlet Air Humidity Ratio {kgWater/kgDryAir}",
        "    Node 11,                 !- Water Inlet Node Name",
        "    Node 27,                 !- Water Outlet Node Name",
        "    Heating Coil Outlet Node,!- Air Inlet Node Name",
        "    Node 5,                  !- Air Outlet Node Name",
        "    SimpleAnalysis,          !- Type of Analysis",
        "    CrossFlow;               !- Heat Exchanger Configuration",
    ])
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.DoingSizing = true
    var ErrorsFound: Bool = false
    GetZoneData(state, ErrorsFound)
    assert_false(ErrorsFound)
    assert_equal("THERMAL ZONE 1", state.dataHeatBal.Zone[0].Name)
    GetZoneEquipmentData(state)
    Fans.GetFanInput(state)
    OutdoorAirUnit.GetOutdoorAirUnitInputs(state)
    var OAUnitNum: Int = 1
    assert_equal("OAU SUPPLY FAN", state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].SFanName)
    assert_equal("ZONE 1 OAU EXHFAN", state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].ExtFanName)
    assert_equal(Int(HVAC.FanType.SystemModel), Int(state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].supFanType))
    assert_equal(Int(HVAC.FanType.SystemModel), Int(state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].extFanType))
    assert_equal(1, state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].NumComponents)
    assert_true(state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OAEquip[0].Type == OutdoorAirUnit.CompType.WaterCoil_Cooling)
    assert_true(state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OAEquip[0].CoilType == DataPlant.PlantEquipmentType.CoilWaterCooling)
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData.allocate(state.dataSize.NumPltSizInput)
    for var l in range(state.dataPlnt.TotNumLoops):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.loopNum = 1
    state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
    state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.branchNum = 1
    state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.compNum = 1
    state.dataPlnt.PlantLoop[0].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = state.dataWaterCoils.WaterCoil[0].Name
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.CoilWaterCooling
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = state.dataWaterCoils.WaterCoil[0].WaterInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumOut = state.dataWaterCoils.WaterCoil[0].WaterOutletNodeNum
    state.dataSize.PlantSizData[0].PlantLoopName = "ChilledWaterLoop"
    state.dataSize.PlantSizData[0].ExitTemp = 6.7
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataSize.PlantSizData[0].LoopType = DataSizing.TypeOfPlantLoop.Cooling
    state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(1)
    state.dataWaterCoils.MyUAAndFlowCalcFlag[0] = true
    state.dataWaterCoils.MyUAAndFlowCalcFlag[0] = true
    state.dataGlobal.HourOfDay = 15
    state.dataEnvrn.DSTIndicator = 0
    state.dataEnvrn.Month = 7
    state.dataEnvrn.DayOfMonth = 21
    state.dataEnvrn.DayOfWeek = 2
    state.dataEnvrn.HolidayIndex = 0
    state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, state.dataGlobal.HourOfDay)
    Sched.UpdateScheduleVals(state)
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback[0] = false
    state.dataHeatBalFanSys.TempControlType.allocate(1)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.DualHeatCool
    state.dataSize.ZoneSizingRunDone = true
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.ZoneEqSizing[0].DesignSizeFromParent = false
    state.dataSize.ZoneEqSizing[0].SizingMethod.allocate(25)
    state.dataSize.ZoneEqSizing[0].SizingMethod[HVAC.SystemAirflowSizing] = DataSizing.SupplyAirFlowRate
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[0].MinOA = 0.5
    state.dataSize.FinalZoneSizing[0].DesCoolVolFlow = 0.5
    state.dataSize.FinalZoneSizing[0].DesCoolCoilInTemp = 30.0
    state.dataSize.FinalZoneSizing[0].DesCoolCoilInHumRat = 0.01
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 30.0, 0.0)
    state.dataSize.FinalZoneSizing[0].CoolDesTemp = 12.8
    state.dataSize.FinalZoneSizing[0].CoolDesHumRat = 0.0080
    state.dataSize.FinalZoneSizing[0].DesCoolDens = state.dataEnvrn.StdRhoAir
    state.dataSize.FinalZoneSizing[0].DesCoolMassFlow = state.dataSize.FinalZoneSizing[0].DesCoolVolFlow * state.dataSize.FinalZoneSizing[0].DesCoolDens
    state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OAEquip[0].MaxVolWaterFlow = DataSizing.AutoSize
    state.dataGlobal.BeginEnvrnFlag = true
    var FirstHVACIteration: Bool = true
    var ZoneNum: Int = 1
    OutdoorAirUnit.InitOutdoorAirUnit(state, OAUnitNum, ZoneNum, FirstHVACIteration)
    assert_equal(state.dataWaterCoils.WaterCoil[0].MaxWaterVolFlowRate, state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OAEquip[0].MaxVolWaterFlow)
    state.dataSize.DataFanType = HVAC.FanType.SystemModel
    state.dataSize.DataFanIndex = Fans.GetFanIndex(state, "OAU SUPPLY FAN")
    state.dataSize.DataAirFlowUsedForSizing = state.dataSize.FinalZoneSizing[0].DesCoolVolFlow
    var FanCoolLoad: Float64 = DataAirSystems.calcFanDesignHeatGain(state, state.dataSize.DataFanIndex, state.dataSize.DataAirFlowUsedForSizing)
    var DesAirMassFlow: Float64 = state.dataSize.FinalZoneSizing[0].DesCoolMassFlow
    var EnthalpyAirIn: Float64 = PsyHFnTdbW(state.dataSize.FinalZoneSizing[0].DesCoolCoilInTemp,
                                      state.dataSize.FinalZoneSizing[0].DesCoolCoilInHumRat)
    var EnthalpyAirOut: Float64 = PsyHFnTdbW(state.dataSize.FinalZoneSizing[0].CoolDesTemp,
                                       state.dataSize.FinalZoneSizing[0].CoolDesHumRat)
    var DesWaterCoolingCoilLoad: Float64 = DesAirMassFlow * (EnthalpyAirIn - EnthalpyAirOut) + FanCoolLoad
    var CoilDesWaterDeltaT: Float64 = state.dataSize.PlantSizData[0].DeltaT
    var Cp: Float64 = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, Constant.CWInitConvTemp, " ")
    var rho: Float64 = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, Constant.CWInitConvTemp, " ")
    var DesCoolingCoilWaterVolFlowRate: Float64 = DesWaterCoolingCoilLoad / (CoilDesWaterDeltaT * Cp * rho)
    assert_equal(DesWaterCoolingCoilLoad, state.dataWaterCoils.WaterCoil[0].DesWaterCoolingCoilRate)
    assert_equal(DesCoolingCoilWaterVolFlowRate, state.dataWaterCoils.WaterCoil[0].MaxWaterVolFlowRate)

@test
def OutdoorAirUnit_SteamHeatingCoilAutoSizeTest():
    let idf_objects: String = delimited_string([
        "Zone,",
        "    Thermal Zone 1,          !- Name",
        "    ,                        !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    10,                      !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    ,                        !- Type",
        "    ,                        !- Multiplier",
        "    ,                        !- Ceiling Height {m}",
        "    300,                     !- Volume {m3}",
        "    100;                     !- Floor Area {m2}",
        "ZoneHVAC:EquipmentConnections,",
        "    Thermal Zone 1,          !- Zone Name",
        "    Thermal Zone 1 Equipment List,  !- Zone Conditioning Equipment List Name",
        "    Thermal Zone 1 Inlet Node List,  !- Zone Air Inlet Node or NodeList Name",
        "    Thermal Zone 1 Exhaust Node List,  !- Zone Air Exhaust Node or NodeList Name",
        "    Node 1,                  !- Zone Air Node Name",
        "    Thermal Zone 1 Return Air Node;  !- Zone Return Air Node or NodeList Name",
        "NodeList,",
        "    Thermal Zone 1 Inlet Node List,  !- Name",
        "    Node 5;                  !- Node 1 Name",
        "NodeList,",
        "    Thermal Zone 1 Exhaust Node List,  !- Name",
        "    Node 4;                  !- Node 1 Name",
        "OutdoorAir:Node,",
        "    Model Outdoor Air Node;  !- Name",
        "OutdoorAir:NodeList,",
        "    OAUnit OA Node;          !- Node or NodeList Name 1",
        "	Schedule:Constant,",
        "	FanAndCoilAvailSched, !- Name",
        "	FRACTION, !- Schedule Type",
        "	1;        !- TimeStep Value",
        "	ScheduleTypeLimits,",
        "	Fraction, !- Name",
        "	0.0, !- Lower Limit Value",
        "	1.0, !- Upper Limit Value",
        "	CONTINUOUS;              !- Numeric Type",
        "Schedule:Compact,",
        "    OAULoCtrlTemp,           !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    10;                      !- Field 4",
        "Schedule:Compact,",
        "    OAUHiCtrlTemp,           !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    15;                      !- Field 4",
        "ScheduleTypeLimits,",
        "    Temperature,             !- Name",
        "    -60,                     !- Lower Limit Value",
        "    200,                     !- Upper Limit Value",
        "    CONTINUOUS;              !- Numeric Type",
        "ZoneHVAC:EquipmentList,",
        "    Thermal Zone 1 Equipment List,  !- Name",
        "    ,                        !- Load Distribution Scheme",
        "    ZoneHVAC:OutdoorAirUnit, !- Zone Equipment 1 Object Type",
        "    OAUnit Zone 1,           !- Zone Equipment 1 Name",
        "    1,                       !- Zone Equipment 1 Cooling Sequence",
        "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:OutdoorAirUnit,",
        "    OAUnit Zone 1,           !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    Thermal Zone 1,          !- Zone Name",
        "    Autosize,                !- Outdoor Air Flow Rate {m3/s}",
        "    FanAndCoilAvailSched,    !- Outdoor Air Schedule Name",
        "    OAU Supply Fan,          !- Supply Fan Name",
        "    BlowThrough,             !- Supply Fan Placement",
        "    Zone 1 OAU ExhFan,       !- Exhaust Fan Name",
        "    Autosize,                !- Exhaust Air Flow Rate {m3/s}",
        "    FanAndCoilAvailSched,    !- Exhaust Air Schedule Name",
        "    TemperatureControl,      !- Unit Control Type",
        "    OAUHiCtrlTemp,           !- High Air Control Temperature Schedule Name",
        "    OAULoCtrlTemp,           !- Low Air Control Temperature Schedule Name",
        "    OAUnit OA Node,          !- Outdoor Air Node Name",
        "    Node 5,                  !- AirOutlet Node Name",
        "    OAUnit OA Node,          !- AirInlet Node Name",
        "    OAUnit Fan Outlet Node,  !- Supply FanOutlet Node Name",
        "    OAUnitZone1EQLIST;       !- Outdoor Air Unit List Name",
        "ZoneHVAC:OutdoorAirUnit:EquipmentList,",
        "    OAUnitZone1EQLIST,       !- Name",
        "    Coil:Heating:Steam,      !- Component 1 Object Type",
        "    OAU Steam Heating Coil;  !- Component 1 Name",
        "Fan:SystemModel,",
        "    Zone 1 OAU ExhFan,       !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    Node 4,                  !- Air Inlet Node Name",
        "    ZoneOAU Relief Node,     !- Air Outlet Node Name",
        "    Autosize,                !- Design Maximum Air Flow Rate {m3/s}",
        "    Discrete,                !- Speed Control Method",
        "    0.0,                     !- Electric Power Minimum Flow Rate Fraction",
        "    75.0,                    !- Design Pressure Rise {Pa}",
        "    0.9,                     !- Motor Efficiency",
        "    1.0,                     !- Motor In Air Stream Fraction",
        "    AUTOSIZE,                !- Design Electric Power Consumption {W}",
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method",
        "    ,                        !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "    ,                        !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "    0.50,                    !- Fan Total Efficiency",
        "    ,                        !- Electric Power Function of Flow Fraction Curve Name",
        "    ,                        !- Night Ventilation Mode Pressure Rise",
        "    ,                        !- Night Ventilation Mode Flow Fraction",
        "    ,                        !- Motor Loss Zone Name",
        "    ,                        !- Motor Loss Radiative Fraction ",
        "    ,                        !- End-Use Subcategory",
        "    1,                       !- Number of Speeds",
        "    1.0,                     !- Speed 1 Flow Fraction",
        "    1.0;                     !- Speed 1 Electric Power Fraction",
        "Fan:SystemModel,",
        "    OAU Supply Fan,          !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    OAUnit OA Node,          !- Air Inlet Node Name",
        "    OAUnit Fan Outlet Node,  !- Air Outlet Node Name",
        "    Autosize,                !- Design Maximum Air Flow Rate {m3/s}",
        "    Discrete,                !- Speed Control Method",
        "    0.0,                     !- Electric Power Minimum Flow Rate Fraction",
        "    75.0,                    !- Design Pressure Rise {Pa}",
        "    0.9,                     !- Motor Efficiency",
        "    1.0,                     !- Motor In Air Stream Fraction",
        "    AUTOSIZE,                !- Design Electric Power Consumption {W}",
        "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method",
        "    ,                        !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "    ,                        !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "    0.50,                    !- Fan Total Efficiency",
        "    ,                        !- Electric Power Function of Flow Fraction Curve Name",
        "    ,                        !- Night Ventilation Mode Pressure Rise",
        "    ,                        !- Night Ventilation Mode Flow Fraction",
        "    ,                        !- Motor Loss Zone Name",
        "    ,                        !- Motor Loss Radiative Fraction ",
        "    ,                        !- End-Use Subcategory",
        "    1,                       !- Number of Speeds",
        "    1.0,                     !- Speed 1 Flow Fraction",
        "    1.0;                     !- Speed 1 Electric Power Fraction",
        "Coil:Heating:Steam,",
        "     OAU Steam Heating Coil, !- Name",
        "    FanAndCoilAvailSched,    !- Availability Schedule Name",
        "    Autosize,                !- Maximum Steam Flow Rate {m3/s}",
        "    5.0,                     !- Degree of SubCooling {C}",
        "    15.0,                    !- Degree of Loop SubCooling {C}",
        "    Node 21,                 !- Water Inlet Node Name",
        "    Node 26,                 !- Water Outlet Node Name",
        "    OAUnit Fan Outlet Node,  !- Air Inlet Node Name",
        "    Heating Coil Outlet Node,!- Air Outlet Node Name",
        "    ZoneLoadControl;         !- Coil Control Type",
    ])
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.DoingSizing = true
    var ErrorsFound: Bool = false
    GetZoneData(state, ErrorsFound)
    assert_false(ErrorsFound)
    assert_equal("THERMAL ZONE 1", state.dataHeatBal.Zone[0].Name)
    GetZoneEquipmentData(state)
    Fans.GetFanInput(state)
    OutdoorAirUnit.GetOutdoorAirUnitInputs(state)
    var OAUnitNum: Int = 1
    assert_equal("OAU SUPPLY FAN", state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].SFanName)
    assert_equal("ZONE 1 OAU EXHFAN", state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].ExtFanName)
    assert_equal(Int(HVAC.FanType.SystemModel), Int(state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].supFanType))
    assert_equal(Int(HVAC.FanType.SystemModel), Int(state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].extFanType))
    assert_equal(1, state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].NumComponents)
    assert_true(state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OAEquip[0].Type == OutdoorAirUnit.CompType.SteamCoil_AirHeat)
    assert_true(state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OAEquip[0].CoilType == DataPlant.PlantEquipmentType.CoilSteamAirHeating)
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData.allocate(state.dataSize.NumPltSizInput)
    for var l in range(state.dataPlnt.TotNumLoops):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    state.dataSteamCoils.SteamCoil[0].plantLoc.loopNum = 1
    state.dataSteamCoils.SteamCoil[0].plantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
    state.dataSteamCoils.SteamCoil[0].plantLoc.branchNum = 1
    state.dataSteamCoils.SteamCoil[0].plantLoc.compNum = 1
    state.dataPlnt.PlantLoop[0].Name = "SteamLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "STEAM"
    state.dataPlnt.PlantLoop[0].steam = Fluid.GetSteam(state)
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = state.dataSteamCoils.SteamCoil[0].Name
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.CoilSteamAirHeating
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = state.dataSteamCoils.SteamCoil[0].SteamInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumOut = state.dataSteamCoils.SteamCoil[0].SteamOutletNodeNum
    state.dataSize.PlantSizData[0].PlantLoopName = "SteamLoop"
    state.dataSize.PlantSizData[0].ExitTemp = 100.0
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataSize.PlantSizData[0].LoopType = DataSizing.TypeOfPlantLoop.Steam
    state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(2)
    state.dataWaterCoils.MyUAAndFlowCalcFlag[0] = true
    state.dataWaterCoils.MyUAAndFlowCalcFlag[1] = true
    state.dataGlobal.HourOfDay = 15
    state.dataEnvrn.DSTIndicator = 0
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 21
    state.dataEnvrn.DayOfWeek = 2
    state.dataEnvrn.HolidayIndex = 0
    state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, state.dataGlobal.HourOfDay)
    Sched.UpdateScheduleVals(state)
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback[0] = false
    state.dataHeatBalFanSys.TempControlType.allocate(1)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.DualHeatCool
    state.dataSize.ZoneSizingRunDone = true
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.ZoneEqSizing[0].DesignSizeFromParent = false
    state.dataSize.ZoneEqSizing[0].SizingMethod.allocate(25)
    state.dataSize.ZoneEqSizing[0].SizingMethod[HVAC.SystemAirflowSizing] = DataSizing.SupplyAirFlowRate
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[0].MinOA = 0.5
    state.dataSize.FinalZoneSizing[0].DesHeatVolFlow = 0.5
    state.dataSize.FinalZoneSizing[0].DesHeatCoilInTemp = 5.0
    state.dataSize.FinalZoneSizing[0].DesHeatCoilInHumRat = 0.005
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 5.0, 0.0)
    state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OAEquip[0].MaxVolWaterFlow = DataSizing.AutoSize
    state.dataSize.FinalZoneSizing[0].HeatDesTemp = 50.0
    state.dataSize.FinalZoneSizing[0].HeatDesHumRat = 0.0050
    state.dataSize.FinalZoneSizing[0].DesHeatDens = state.dataEnvrn.StdRhoAir
    state.dataSize.FinalZoneSizing[0].DesHeatMassFlow = state.dataSize.FinalZoneSizing[0].DesHeatVolFlow * state.dataSize.FinalZoneSizing[0].DesHeatDens
    state.dataGlobal.BeginEnvrnFlag = true
    var FirstHVACIteration: Bool = true
    var ZoneNum: Int = 1
    OutdoorAirUnit.InitOutdoorAirUnit(state, OAUnitNum, ZoneNum, FirstHVACIteration)
    assert_equal(state.dataSteamCoils.SteamCoil[0].MaxSteamVolFlowRate, state.dataOutdoorAirUnit.OutAirUnit[OAUnitNum - 1].OAEquip[0].MaxVolWaterFlow)
    var DesCoilInTemp: Float64 = state.dataSize.FinalZoneSizing[0].DesHeatCoilInTemp
    var DesCoilOutTemp: Float64 = state.dataSize.FinalZoneSizing[0].HeatDesTemp
    var DesCoilOutHumRat: Float64 = state.dataSize.FinalZoneSizing[0].HeatDesHumRat
    var DesAirMassFlow: Float64 = state.dataSize.FinalZoneSizing[0].DesHeatMassFlow
    var CpAirAvg: Float64 = PsyCpAirFnW(DesCoilOutHumRat)
    var DesSteamCoilLoad: Float64 = DesAirMassFlow * CpAirAvg * (DesCoilOutTemp - DesCoilInTemp)
    var EnthSteamIn: Float64 = state.dataSteamCoils.SteamCoil[0].steam.getSatEnthalpy(state, Constant.SteamInitConvTemp, 1.0, "")
    var EnthSteamOut: Float64 = state.dataSteamCoils.SteamCoil[0].steam.getSatEnthalpy(state, Constant.SteamInitConvTemp, 0.0, "")
    var SteamDensity: Float64 = state.dataSteamCoils.SteamCoil[0].steam.getSatDensity(state, Constant.SteamInitConvTemp, 1.0, "")
    var CpOfCondensate: Float64 = state.dataSteamCoils.SteamCoil[0].steam.getSatSpecificHeat(state, Constant.SteamInitConvTemp, 0.0, "")
    var LatentHeatChange: Float64 = EnthSteamIn - EnthSteamOut
    var DesMaxSteamVolFlowRate: Float64 = DesSteamCoilLoad / (SteamDensity * (LatentHeatChange + state.dataSteamCoils.SteamCoil[0].DegOfSubcooling * CpOfCondensate))
    assert_equal(DesSteamCoilLoad, state.dataSteamCoils.SteamCoil[0].DesCoilCapacity)
    assert_equal(DesMaxSteamVolFlowRate, state.dataSteamCoils.SteamCoil[0].MaxSteamVolFlowRate)