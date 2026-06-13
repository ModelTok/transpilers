from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import DataAirLoop
from EnergyPlus.DataAirSystems import DataAirSystems
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.Fans import Fans
from EnergyPlus.General import General
from EnergyPlus.HVACManager import HVACManager
from EnergyPlus.HeatBalanceAirManager import HeatBalanceAirManager
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.ZoneEquipmentManager import ZoneEquipmentManager
from EnergyPlus.ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import state
from EnergyPlus.DataHVACGlobals import Constant
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.HVACManager import ReportAirHeatBalance
from EnergyPlus.HVACManager import CheckAirLoopFlowBalance
from EnergyPlus.HVACManager import ConvergenceErrors
from EnergyPlus.HVACManager import ConvErrorCallType
from EnergyPlus.HeatBalanceManager import GetZoneData
from EnergyPlus.HeatBalanceManager import AllocateHeatBalArrays
from EnergyPlus.HeatBalanceAirManager import GetSimpleAirModelInputs
from EnergyPlus.HeatBalanceAirManager import CalcAirFlowSimple
from EnergyPlus.ZoneEquipmentManager import UpdateZoneListAndGroupLoads
from EnergyPlus.Psychrometrics import PsyCpAirFnW
from EnergyPlus.Psychrometrics import PsyHFnTdbW
from EnergyPlus.Psychrometrics import PsyRhoAirFnPbTdbW
from EnergyPlus.Fans import FanComponent
from EnergyPlus.HVAC import FanType
from EnergyPlus.DataLoopNode import Node
from EnergyPlus.DataHeatBalance import ZoneListSNLoadHeatEnergy
from EnergyPlus.DataHeatBalance import ZoneListSNLoadCoolEnergy
from EnergyPlus.DataHeatBalance import ZoneListSNLoadHeatRate
from EnergyPlus.DataHeatBalance import ZoneListSNLoadCoolRate
from EnergyPlus.DataZoneEnergyDemand import ZoneSysEnergyDemand
from EnergyPlus.DataHeatBalance import ZoneTotalExfiltrationHeatLoss
from EnergyPlus.DataHeatBalance import ZoneTotalExhaustHeatLoss
from EnergyPlus.DataAirLoop import AirLoopFlow
from EnergyPlus.DataAirLoop import AirToZoneNodeInfo
from EnergyPlus.DataAirSystems import PrimaryAirSystems
from EnergyPlus.DataFans import fans
from EnergyPlus.DataFans import fanMap
from EnergyPlus.DataLoopNodes import Node as LoopNode
from EnergyPlus.DataZoneEnergyDemand import ZoneSysEnergyDemand as ZoneEnergyDemand
from EnergyPlus.DataHeatBalance import ZoneList as HeatBalZoneList
from EnergyPlus.DataHeatBalance import Zone as HeatBalZone
from EnergyPlus.DataHeatBalance import ZnAirRpt as HeatBalZnAirRpt
from EnergyPlus.DataHeatBalance import Infiltration as HeatBalInfiltration
from EnergyPlus.DataHeatBalance import CrossMixing as HeatBalCrossMixing
from EnergyPlus.DataHeatBalance import Ventilation as HeatBalVentilation
from EnergyPlus.DataZoneTempPredictorCorrector import zoneHeatBalance as ZoneTempPredictorCorrectorZoneHeatBalance
from EnergyPlus.DataZoneTempPredictorCorrector import spaceHeatBalance as ZoneTempPredictorCorrectorSpaceHeatBalance
from EnergyPlus.DataZoneEquip import ZoneEquipConfig as DataZoneEquipZoneEquipConfig
from EnergyPlus.DataEnvironment import OutBaroPress
from EnergyPlus.DataEnvironment import OutHumRat
from EnergyPlus.DataEnvironment import StdRhoAir
from EnergyPlus.DataEnvironment import WindSpeed
from EnergyPlus.DataGlobal import NumOfZones
from EnergyPlus.DataGlobal import isPulseZoneSizing
from EnergyPlus.DataGlobal import WarmupFlag
from EnergyPlus.DataHVACGlobals import TimeStepSys
from EnergyPlus.DataHVACGlobals import TimeStepSysSec
from EnergyPlus.DataHVACGlobals import NumPrimaryAirSys
from EnergyPlus.DataHVACGlobals import AirLoopsSimOnce
from EnergyPlus.DataHeatBalance import TotCrossMixing
from EnergyPlus.DataHeatBalance import TotInfiltration
from EnergyPlus.DataHeatBalance import TotVentilation
from EnergyPlus.DataHeatBalance import AirFlowFlag
from EnergyPlus.DataHeatBalance import ZoneAirMassFlow
from EnergyPlus.DataHeatBalance import EnforceZoneMassBalance
from EnergyPlus.DataHeatBalance import space
from EnergyPlus.DataHeatBalance import Zone
from EnergyPlus.DataHeatBalance import ZnAirRpt
from EnergyPlus.DataHeatBalance import Infiltration
from EnergyPlus.DataHeatBalance import CrossMixing
from EnergyPlus.DataHeatBalance import Ventilation
from EnergyPlus.DataHeatBalance import ZoneList
from EnergyPlus.DataHeatBalance import ZoneListSNLoadHeatEnergy
from EnergyPlus.DataHeatBalance import ZoneListSNLoadCoolEnergy
from EnergyPlus.DataHeatBalance import ZoneListSNLoadHeatRate
from EnergyPlus.DataHeatBalance import ZoneListSNLoadCoolRate
from EnergyPlus.DataZoneEnergyDemand import ZoneSysEnergyDemand
from EnergyPlus.DataZoneTempPredictorCorrector import zoneHeatBalance
from EnergyPlus.DataZoneTempPredictorCorrector import spaceHeatBalance
from EnergyPlus.DataZoneEquip import ZoneEquipConfig
from EnergyPlus.DataEnvironment import OutBaroPress
from EnergyPlus.DataEnvironment import OutHumRat
from EnergyPlus.DataEnvironment import StdRhoAir
from EnergyPlus.DataEnvironment import WindSpeed
from EnergyPlus.DataLoopNodes import Node
from EnergyPlus.DataFans import fans
from EnergyPlus.DataFans import fanMap
from EnergyPlus.DataAirLoop import AirLoopFlow
from EnergyPlus.DataAirLoop import AirToZoneNodeInfo
from EnergyPlus.DataAirSystems import PrimaryAirSystems
from EnergyPlus.DataGlobal import TimeStepZone
from EnergyPlus.DataGlobal import TimeStepZoneSec
from EnergyPlus.DataHeatBalance import ZoneTotalExfiltrationHeatLoss
from EnergyPlus.DataHeatBalance import ZoneTotalExhaustHeatLoss
from EnergyPlus.DataZoneEnergyDemand import ZoneSysEnergyDemand as ZoneEnergyDemand

struct TestEnergyPlusFixture(EnergyPlusFixture):

def CrossMixingReportTest():
    state.dataGlobal.NumOfZones = 2
    var NumOfCrossMixing: Int = 1
    state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.CrossMixing.allocate(NumOfCrossMixing)
    state.dataHeatBal.ZnAirRpt.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataGlobal.NumOfZones = state.dataGlobal.NumOfZones
    state.dataHeatBal.TotCrossMixing = NumOfCrossMixing
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPI = 0.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MCPI = 0.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPV = 0.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MCPV = 0.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MAT = 22.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MAT = 25.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].airHumRat = 0.0011
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRatAvg = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].airHumRatAvg = 0.0011
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataHeatBal.CrossMixing[0].ZonePtr = 1
    state.dataHeatBal.CrossMixing[0].FromZone = 2
    state.dataHeatBal.CrossMixing[0].DesiredAirFlowRate = 0.1
    state.dataHeatBal.CrossMixing[0].ReportFlag = true
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumInletNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumReturnNodes = 0
    ReportAirHeatBalance(*state)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixVolume, state.dataHeatBal.ZnAirRpt[1].MixVolume, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixVdotCurDensity, state.dataHeatBal.ZnAirRpt[1].MixVdotCurDensity, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixVdotStdDensity, state.dataHeatBal.ZnAirRpt[1].MixVdotStdDensity, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixMass, state.dataHeatBal.ZnAirRpt[1].MixMass, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixMdot, state.dataHeatBal.ZnAirRpt[1].MixMdot, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixHeatLoss, state.dataHeatBal.ZnAirRpt[1].MixHeatGain, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixHeatGain, state.dataHeatBal.ZnAirRpt[1].MixHeatLoss, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixLatentLoss, state.dataHeatBal.ZnAirRpt[1].MixLatentGain, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixLatentGain, state.dataHeatBal.ZnAirRpt[1].MixLatentLoss, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixTotalLoss, state.dataHeatBal.ZnAirRpt[1].MixTotalGain, 0.0001)
    EXPECT_NEAR(state.dataHeatBal.ZnAirRpt[0].MixTotalGain, state.dataHeatBal.ZnAirRpt[1].MixTotalLoss, 0.0001)

def InfiltrationObjectLevelReport():
    var idf_objects: String = delimited_string({
        "  Zone,",
        "    Zone1,                   !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    100.0;                   !- Volume {m3}",
        "  Zone,",
        "    Zone2,                   !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    200.0;                   !- Volume {m3}",
        "  Zone,",
        "    Zone3,                   !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    300.0;                   !- Volume {m3}",
        "  Zone,",
        "    Zone4,                   !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    400.0;                   !- Volume {m3}",
        "ZoneList,",
        "  ZoneList,",
        "  Zone1,",
        "  Zone2;",
        "ZoneInfiltration:EffectiveLeakageArea,",
        "  Zone3 Infil,          !- Name",
        "  Zone3,                       !- Zone or ZoneList Name",
        "  AlwaysOn,                    !- Schedule Name",
        "  500.0,                       !- Effective Air Leakage Area",
        "  0.000145,                    !- Stack Coefficient",
        "  0.000174;                    !- Wind Coefficient",
        "ZoneInfiltration:FlowCoefficient,",
        "  Zone4 Infil,          !- Name",
        "  Zone4,                       !- Zone or ZoneList Name",
        "  AlwaysOn,                    !- Schedule Name",
        "  0.05,                        !- Flow Coefficient",
        "  0.089,                       !- Stack Coefficient",
        "  0.67,                        !- Pressure Exponent",
        "  0.156,                       !- Wind Coefficient",
        "  0.64;                        !- Shelter Factor",
        "ZoneInfiltration:DesignFlowRate,",
        "  Zonelist Infil,          !- Name",
        "  ZoneList,                       !- Zone or ZoneList Name",
        "  AlwaysOn,                    !- Schedule Name",
        "  flow/zone,                   !- Design Flow Rate Calculation Method",
        "  0.07,                        !- Design Flow Rate{ m3 / s }",
        "  ,                            !- Flow per Zone Floor Area{ m3 / s - m2 }",
        "  ,                            !- Flow per Exterior Surface Area{ m3 / s - m2 }",
        "  ,                            !- Air Changes per Hour{ 1 / hr }",
        "  1,                           !- Constant Term Coefficient",
        "  0,                           !- Temperature Term Coefficient",
        "  0,                           !- Velocity Term Coefficient",
        "  0;                           !- Velocity Squared Term Coefficient",
        "ZoneInfiltration:DesignFlowRate,",
        "  Zone2 Infil,                 !- Name",
        "  Zone2,                       !- Zone or ZoneList Name",
        "  AlwaysOn,                    !- Schedule Name",
        "  flow/zone,                   !- Design Flow Rate Calculation Method",
        "  0.07,                        !- Design Flow Rate{ m3 / s }",
        "  ,                            !- Flow per Zone Floor Area{ m3 / s - m2 }",
        "  ,                            !- Flow per Exterior Surface Area{ m3 / s - m2 }",
        "  ,                            !- Air Changes per Hour{ 1 / hr }",
        "  1,                           !- Constant Term Coefficient",
        "  0,                           !- Temperature Term Coefficient",
        "  0,                           !- Velocity Term Coefficient",
        "  0,                           !- Velocity Squared Term Coefficient",
        "  Standard;                    !- Density Basis",
        "Schedule:Constant,",
        "AlwaysOn,",
        "Fraction,",
        "1.0;",
    })
    ASSERT_TRUE(process_idf(idf_objects))
    EXPECT_FALSE(has_err_output())
    state.init_state(*state)
    var ErrorsFound: Bool = false
    GetZoneData(*state, ErrorsFound)
    state.dataHeatBal.space[0].Volume = state.dataHeatBal.Zone[0].Volume
    state.dataHeatBal.space[1].Volume = state.dataHeatBal.Zone[1].Volume
    state.dataHeatBal.space[2].Volume = state.dataHeatBal.Zone[2].Volume
    state.dataHeatBal.space[3].Volume = state.dataHeatBal.Zone[3].Volume
    AllocateHeatBalArrays(*state)
    GetSimpleAirModelInputs(*state, ErrorsFound)
    EXPECT_EQ(state.dataHeatBal.TotInfiltration, 5)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.spaceHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
    var zoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance
    zoneHB[0].MAT = 21.0
    zoneHB[1].MAT = 22.0
    zoneHB[2].MAT = 23.0
    zoneHB[3].MAT = 24.0
    zoneHB[0].airHumRat = 0.001
    zoneHB[1].airHumRat = 0.001
    zoneHB[2].airHumRat = 0.001
    zoneHB[3].airHumRat = 0.001
    var spaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance
    spaceHB[0].MAT = 21.0
    spaceHB[1].MAT = 22.0
    spaceHB[2].MAT = 23.0
    spaceHB[3].MAT = 24.0
    spaceHB[0].airHumRat = 0.001
    spaceHB[1].airHumRat = 0.001
    spaceHB[2].airHumRat = 0.001
    spaceHB[3].airHumRat = 0.001
    state.dataHeatBal.AirFlowFlag = true
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.OutHumRat = 0.0005
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataEnvrn.WindSpeed = 1.0
    state.dataHeatBal.Zone[0].WindSpeed = 1.0
    state.dataHeatBal.Zone[1].WindSpeed = 1.0
    state.dataHeatBal.Zone[2].WindSpeed = 1.0
    state.dataHeatBal.Zone[3].WindSpeed = 1.0
    state.dataHeatBal.Zone[0].OutDryBulbTemp = 15.0
    state.dataHeatBal.Zone[1].OutDryBulbTemp = 15.0
    state.dataHeatBal.Zone[2].OutDryBulbTemp = 15.0
    state.dataHeatBal.Zone[3].OutDryBulbTemp = 15.0
    Sched.GetSchedule(*state, "ALWAYSON").currentVal = 1.0
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataGlobal.TimeStepZone = 1.0
    state.dataGlobal.TimeStepZoneSec = 3600
    CalcAirFlowSimple(*state, 2)
    var infiltration = state.dataHeatBal.Infiltration
    EXPECT_NEAR(infiltration[0].MCpI_temp, 0.07 * 1.2242 * 1005.77, 0.01)
    EXPECT_NEAR(infiltration[1].MCpI_temp, 0.07 * 1.2242 * 1005.77, 0.01)
    EXPECT_NEAR(infiltration[2].MCpI_temp, 0.07 * state.dataEnvrn.StdRhoAir * 1005.77, 0.01)
    EXPECT_NEAR(infiltration[3].MCpI_temp, 22.486, 0.01)
    EXPECT_NEAR(infiltration[4].MCpI_temp, 24.459, 0.01)
    EXPECT_EQ(state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPI, infiltration[0].MCpI_temp)
    var zone2MCPIExpected: Float64 = infiltration[1].MCpI_temp + infiltration[2].MCpI_temp
    EXPECT_EQ(state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MCPI, zone2MCPIExpected)
    EXPECT_EQ(state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].MCPI, infiltration[3].MCpI_temp)
    EXPECT_EQ(state.dataZoneTempPredictorCorrector.zoneHeatBalance[3].MCPI, infiltration[4].MCpI_temp)
    ReportAirHeatBalance(*state)
    var ZnAirRpt = state.dataHeatBal.ZnAirRpt
    EXPECT_NEAR(ZnAirRpt[0].InfilHeatLoss, infiltration[0].InfilHeatLoss, 0.000001)
    var expectedValue: Float64 = infiltration[1].InfilHeatLoss + infiltration[2].InfilHeatLoss
    EXPECT_NEAR(ZnAirRpt[1].InfilHeatLoss, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilHeatLoss, infiltration[3].InfilHeatLoss, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilHeatLoss, infiltration[4].InfilHeatLoss, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilHeatGain, infiltration[0].InfilHeatGain, 0.000001)
    expectedValue = infiltration[1].InfilHeatGain + infiltration[2].InfilHeatGain
    EXPECT_NEAR(ZnAirRpt[1].InfilHeatGain, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilHeatGain, infiltration[3].InfilHeatGain, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilHeatGain, infiltration[4].InfilHeatGain, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilTotalLoss, infiltration[0].InfilTotalLoss, 0.000001)
    expectedValue = infiltration[1].InfilTotalLoss + infiltration[2].InfilTotalLoss
    EXPECT_NEAR(ZnAirRpt[1].InfilTotalLoss, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilTotalLoss, infiltration[3].InfilTotalLoss, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilTotalLoss, infiltration[4].InfilTotalLoss, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilTotalGain, infiltration[0].InfilTotalGain, 0.000001)
    expectedValue = infiltration[1].InfilTotalGain + infiltration[2].InfilTotalGain
    EXPECT_NEAR(ZnAirRpt[1].InfilTotalGain, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilTotalGain, infiltration[3].InfilTotalGain, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilTotalGain, infiltration[4].InfilTotalGain, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilMass, infiltration[0].InfilMass, 0.000001)
    expectedValue = infiltration[1].InfilMass + infiltration[2].InfilMass
    EXPECT_NEAR(ZnAirRpt[1].InfilMass, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilMass, infiltration[3].InfilMass, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilMass, infiltration[4].InfilMass, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilMdot, infiltration[0].InfilMdot, 0.000001)
    expectedValue = infiltration[1].InfilMdot + infiltration[2].InfilMdot
    EXPECT_NEAR(ZnAirRpt[1].InfilMdot, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilMdot, infiltration[3].InfilMdot, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilMdot, infiltration[4].InfilMdot, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilVolumeCurDensity, infiltration[0].InfilVolumeCurDensity, 0.000001)
    expectedValue = infiltration[1].InfilVolumeCurDensity + infiltration[2].InfilVolumeCurDensity
    EXPECT_NEAR(ZnAirRpt[1].InfilVolumeCurDensity, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilVolumeCurDensity, infiltration[3].InfilVolumeCurDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilVolumeCurDensity, infiltration[4].InfilVolumeCurDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilAirChangeRateCurDensity, infiltration[0].InfilAirChangeRateCurDensity, 0.000001)
    expectedValue = infiltration[1].InfilAirChangeRateCurDensity + infiltration[2].InfilAirChangeRateCurDensity
    EXPECT_NEAR(ZnAirRpt[1].InfilAirChangeRateCurDensity, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilAirChangeRateCurDensity, infiltration[3].InfilAirChangeRateCurDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilAirChangeRateCurDensity, infiltration[4].InfilAirChangeRateCurDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilVdotCurDensity, infiltration[0].InfilVdotCurDensity, 0.000001)
    expectedValue = infiltration[1].InfilVdotCurDensity + infiltration[2].InfilVdotCurDensity
    EXPECT_NEAR(ZnAirRpt[1].InfilVdotCurDensity, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilVdotCurDensity, infiltration[3].InfilVdotCurDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilVdotCurDensity, infiltration[4].InfilVdotCurDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilVolumeStdDensity, infiltration[0].InfilVolumeStdDensity, 0.000001)
    expectedValue = infiltration[1].InfilVolumeStdDensity + infiltration[2].InfilVolumeStdDensity
    EXPECT_NEAR(ZnAirRpt[1].InfilVolumeStdDensity, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilVolumeStdDensity, infiltration[3].InfilVolumeStdDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilVolumeStdDensity, infiltration[4].InfilVolumeStdDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[0].InfilVdotStdDensity, infiltration[0].InfilVdotStdDensity, 0.000001)
    expectedValue = infiltration[1].InfilVdotStdDensity + infiltration[2].InfilVdotStdDensity
    EXPECT_NEAR(ZnAirRpt[1].InfilVdotStdDensity, expectedValue, 0.000001)
    EXPECT_NEAR(ZnAirRpt[2].InfilVdotStdDensity, infiltration[3].InfilVdotStdDensity, 0.000001)
    EXPECT_NEAR(ZnAirRpt[3].InfilVdotStdDensity, infiltration[4].InfilVdotStdDensity, 0.000001)
    state.dataHeatBal.ZoneListSNLoadHeatEnergy.allocate(1)
    state.dataHeatBal.ZoneListSNLoadCoolEnergy.allocate(1)
    state.dataHeatBal.ZoneListSNLoadHeatRate.allocate(1)
    state.dataHeatBal.ZoneListSNLoadCoolRate.allocate(1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(2)
    UpdateZoneListAndGroupLoads(*state)
    EXPECT_EQ(1.0, state.dataHeatBal.Zone[0].Multiplier)
    EXPECT_EQ(1.0, state.dataHeatBal.Zone[1].Multiplier)
    EXPECT_EQ(1, state.dataHeatBal.ZoneList[0].Zone[0])
    EXPECT_EQ(2, state.dataHeatBal.ZoneList[0].Zone[1])
    EXPECT_EQ(0.0, state.dataHeatBal.ZoneListSNLoadHeatEnergy[0])
    EXPECT_EQ(0.0, state.dataHeatBal.ZoneListSNLoadCoolEnergy[0])
    EXPECT_EQ(0.0, state.dataHeatBal.ZoneListSNLoadHeatRate[0])
    EXPECT_EQ(0.0, state.dataHeatBal.ZoneListSNLoadCoolRate[0])
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].airSysCoolRate = 100.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].airSysCoolEnergy = 200.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].airSysHeatRate = 150.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].airSysHeatEnergy = 300.0
    UpdateZoneListAndGroupLoads(*state)
    EXPECT_EQ(1.0, state.dataHeatBal.Zone[0].Multiplier)
    EXPECT_EQ(1.0, state.dataHeatBal.Zone[1].Multiplier)
    EXPECT_EQ(1, state.dataHeatBal.ZoneList[0].Zone[0])
    EXPECT_EQ(2, state.dataHeatBal.ZoneList[0].Zone[1])
    EXPECT_EQ(100.0, state.dataHeatBal.ZoneListSNLoadCoolRate[0])
    EXPECT_EQ(200.0, state.dataHeatBal.ZoneListSNLoadCoolEnergy[0])
    EXPECT_EQ(150.0, state.dataHeatBal.ZoneListSNLoadHeatRate[0])
    EXPECT_EQ(300.0, state.dataHeatBal.ZoneListSNLoadHeatEnergy[0])
    EXPECT_EQ(0.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].airSysCoolRate)
    EXPECT_EQ(0.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].airSysCoolEnergy)
    EXPECT_EQ(0.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].airSysHeatRate)
    EXPECT_EQ(0.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].airSysHeatEnergy)
    state.dataHeatBal.Zone[0].Multiplier = 2
    UpdateZoneListAndGroupLoads(*state)
    EXPECT_EQ(200.0, state.dataHeatBal.ZoneListSNLoadCoolRate[0])
    EXPECT_EQ(400.0, state.dataHeatBal.ZoneListSNLoadCoolEnergy[0])
    EXPECT_EQ(300.0, state.dataHeatBal.ZoneListSNLoadHeatRate[0])
    EXPECT_EQ(600.0, state.dataHeatBal.ZoneListSNLoadHeatEnergy[0])
    state.dataHeatBal.ZoneList[0].Zone[0] = 2
    state.dataHeatBal.ZoneList[0].Zone[1] = 1
    UpdateZoneListAndGroupLoads(*state)
    EXPECT_EQ(200.0, state.dataHeatBal.ZoneListSNLoadCoolRate[0])
    EXPECT_EQ(400.0, state.dataHeatBal.ZoneListSNLoadCoolEnergy[0])
    EXPECT_EQ(300.0, state.dataHeatBal.ZoneListSNLoadHeatRate[0])
    EXPECT_EQ(600.0, state.dataHeatBal.ZoneListSNLoadHeatEnergy[0])
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].airSysCoolRate = 100.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].airSysCoolEnergy = 100.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].airSysHeatRate = 100.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].airSysHeatEnergy = 100.0
    UpdateZoneListAndGroupLoads(*state)
    EXPECT_EQ(300.0, state.dataHeatBal.ZoneListSNLoadCoolRate[0])
    EXPECT_EQ(500.0, state.dataHeatBal.ZoneListSNLoadCoolEnergy[0])
    EXPECT_EQ(400.0, state.dataHeatBal.ZoneListSNLoadHeatRate[0])
    EXPECT_EQ(700.0, state.dataHeatBal.ZoneListSNLoadHeatEnergy[0])
    state.dataHeatBal.Zone[0].Multiplier = 1
    state.dataHeatBal.Zone[1].Multiplier = 2
    UpdateZoneListAndGroupLoads(*state)
    EXPECT_EQ(300.0, state.dataHeatBal.ZoneListSNLoadCoolRate[0])
    EXPECT_EQ(400.0, state.dataHeatBal.ZoneListSNLoadCoolEnergy[0])
    EXPECT_EQ(350.0, state.dataHeatBal.ZoneListSNLoadHeatRate[0])
    EXPECT_EQ(500.0, state.dataHeatBal.ZoneListSNLoadHeatEnergy[0])

def InfiltrationReportTest():
    state.dataGlobal.NumOfZones = 2
    state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.ZnAirRpt.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.TotVentilation = 1
    state.dataHeatBal.Ventilation.allocate(state.dataHeatBal.TotVentilation)
    state.dataGlobal.NumOfZones = state.dataGlobal.NumOfZones
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPI = 1.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MCPI = 1.5
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPV = 2.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MCPV = 2.5
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.OutHumRat = 0.0005
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MAT = 22.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MAT = 25.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].airHumRat = 0.0011
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRatAvg = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].airHumRatAvg = 0.0011
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataHeatBal.Zone[0].OutDryBulbTemp = 20.0
    state.dataHeatBal.Zone[1].OutDryBulbTemp = 20.0
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumInletNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumReturnNodes = 0
    state.dataHeatBal.Ventilation[0].ZonePtr = 1
    state.dataHeatBal.Ventilation[0].AirTemp = state.dataHeatBal.Zone[0].OutDryBulbTemp
    state.dataHeatBal.Ventilation[0].MCP = state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPV
    ReportAirHeatBalance(*state)
    var znAirRpt1 = state.dataHeatBal.ZnAirRpt[0]
    var znAirRpt2 = state.dataHeatBal.ZnAirRpt[1]
    EXPECT_NEAR(2.9971591, znAirRpt1.InfilVolumeCurDensity, 0.0001)
    EXPECT_NEAR(5.9943183, znAirRpt1.VentilVolumeCurDensity, 0.0001)
    EXPECT_NEAR(2.9827908, znAirRpt1.InfilVolumeStdDensity, 0.0001)
    EXPECT_NEAR(5.9655817, znAirRpt1.VentilVolumeStdDensity, 0.0001)
    EXPECT_NEAR(4.5421638, znAirRpt2.InfilVolumeCurDensity, 0.0001)
    EXPECT_NEAR(7.5702731, znAirRpt2.VentilVolumeCurDensity, 0.0001)
    EXPECT_NEAR(4.4741862, znAirRpt2.InfilVolumeStdDensity, 0.0001)
    EXPECT_NEAR(7.4569771, znAirRpt2.VentilVolumeStdDensity, 0.0001)
    var zoneHB1 = state.dataZoneTempPredictorCorrector.zoneHeatBalance[0]
    var zone1 = state.dataHeatBal.Zone[0]
    var deltah: Float64 = zoneHB1.MCPI / (Psychrometrics.PsyCpAirFnW(state.dataEnvrn.OutHumRat)) * 3600.0 * (Psychrometrics.PsyHFnTdbW(zone1.OutDryBulbTemp, state.dataEnvrn.OutHumRat) - Psychrometrics.PsyHFnTdbW(zoneHB1.MAT, zoneHB1.airHumRat))
    EXPECT_NEAR(-deltah, znAirRpt1.InfilTotalLoss, 0.0001)
    deltah = zoneHB1.MCPV / (Psychrometrics.PsyCpAirFnW(state.dataEnvrn.OutHumRat)) * 3600.0 * (Psychrometrics.PsyHFnTdbW(zone1.OutDryBulbTemp, state.dataEnvrn.OutHumRat) - Psychrometrics.PsyHFnTdbW(zoneHB1.MAT, zoneHB1.airHumRat))
    EXPECT_NEAR(-deltah, znAirRpt1.VentilTotalLoss, 0.0001)
    var outdoorRho: Float64 = Psychrometrics.PsyRhoAirFnPbTdbW(state.dataEnvrn.OutBaroPress, zone1.OutDryBulbTemp, state.dataEnvrn.OutHumRat)
    var expected: Float64 = znAirRpt1.InfilVdotStdDensity * outdoorRho / state.dataEnvrn.StdRhoAir
    EXPECT_NEAR(znAirRpt1.InfilVdotOutDensity, expected, 0.0001)
    expected = znAirRpt1.VentilVdotStdDensity * outdoorRho / state.dataEnvrn.StdRhoAir
    EXPECT_NEAR(znAirRpt1.VentilVdotOutDensity, expected, 0.0001)
    expected = znAirRpt1.InfilVdotCurDensity * Constant.rSecsInHour / zone1.Volume
    EXPECT_NEAR(znAirRpt1.InfilAirChangeRateCurDensity, expected, 0.001)
    var zoneRho: Float64 = Psychrometrics.PsyRhoAirFnPbTdbW(state.dataEnvrn.OutBaroPress, zoneHB1.MAT, zoneHB1.airHumRat)
    expected = znAirRpt1.InfilAirChangeRateCurDensity * outdoorRho / zoneRho
    EXPECT_NEAR(znAirRpt1.InfilAirChangeRateOutDensity, expected, 0.001)
    expected = znAirRpt1.InfilAirChangeRateCurDensity * state.dataEnvrn.StdRhoAir / zoneRho
    EXPECT_NEAR(znAirRpt1.InfilAirChangeRateStdDensity, expected, 0.001)

def ExfilAndExhaustReportTest():
    state.dataGlobal.NumOfZones = 2
    state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.ZnAirRpt.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataGlobal.NumOfZones = state.dataGlobal.NumOfZones
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPI = 1.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MCPI = 1.5
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPV = 2.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MCPV = 2.5
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.OutHumRat = 0.0005
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MAT = 22.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MAT = 25.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].airHumRat = 0.0011
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRatAvg = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].airHumRatAvg = 0.0011
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataHeatBal.Zone[0].OutDryBulbTemp = 20.0
    state.dataHeatBal.Zone[1].OutDryBulbTemp = 20.0
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumInletNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[1].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumReturnNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 1
    var fan1 = FanComponent()
    fan1.Name = "EXHAUST FAN 1"
    fan1.type = FanType.Exhaust
    fan1.outletAirMassFlowRate = 1.0
    fan1.outletAirTemp = 22.0
    fan1.outletAirEnthalpy = Psychrometrics.PsyHFnTdbW(fan1.outletAirTemp, 0.0005)
    fan1.inletNodeNum = 1
    state.dataFans.fans.push_back(fan1)
    state.dataFans.fanMap.insert_or_assign(fan1.Name, state.dataFans.fans.size())
    state.dataLoopNodes.Node.allocate(1)
    state.dataLoopNodes.Node[0].MassFlowRate = 0.0
    ReportAirHeatBalance(*state)
    EXPECT_NEAR(9.7853391, state.dataHeatBal.ZnAirRpt[0].ExfilTotalLoss, 0.0001)
    EXPECT_NEAR(26.056543, state.dataHeatBal.ZnAirRpt[1].ExfilTotalLoss, 0.0001)
    EXPECT_NEAR(6.0, state.dataHeatBal.ZnAirRpt[0].ExfilSensiLoss, 0.0001)
    EXPECT_NEAR(20.0, state.dataHeatBal.ZnAirRpt[1].ExfilSensiLoss, 0.0001)
    EXPECT_NEAR(23377.40, state.dataHeatBal.ZnAirRpt[0].ExhTotalLoss, 0.01)
    EXPECT_NEAR(0, state.dataHeatBal.ZnAirRpt[1].ExhTotalLoss, 0.01)
    EXPECT_NEAR(35.841882 * 3600, state.dataHeatBal.ZoneTotalExfiltrationHeatLoss, 0.01)
    EXPECT_NEAR(23377.39845 * 3600, state.dataHeatBal.ZoneTotalExhaustHeatLoss, 0.01)

def AirloopFlowBalanceTest():
    state.dataGlobal.isPulseZoneSizing = false
    state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance = false
    state.dataGlobal.WarmupFlag = false
    state.dataHVACGlobal.AirLoopsSimOnce = true
    state.dataEnvrn.StdRhoAir = 1.0
    state.dataHVACGlobal.NumPrimaryAirSys = 2
    state.dataAirSystemsData.PrimaryAirSystems.allocate(state.dataHVACGlobal.NumPrimaryAirSys)
    state.dataAirSystemsData.PrimaryAirSystems[0].Name = "System 1"
    state.dataAirSystemsData.PrimaryAirSystems[1].Name = "System 2"
    state.dataAirLoop.AirLoopFlow.allocate(state.dataHVACGlobal.NumPrimaryAirSys)
    var thisAirLoopFlow1 = state.dataAirLoop.AirLoopFlow[0]
    var thisAirLoopFlow2 = state.dataAirLoop.AirLoopFlow[1]
    thisAirLoopFlow1.SupFlow = 0.0
    thisAirLoopFlow1.SysRetFlow = 0.0
    thisAirLoopFlow1.OAFlow = 0.0
    thisAirLoopFlow2.SupFlow = 0.0
    thisAirLoopFlow2.SysRetFlow = 0.0
    thisAirLoopFlow2.OAFlow = 0.0
    HVACManager.CheckAirLoopFlowBalance(*state)
    EXPECT_FALSE(has_err_output(true))
    thisAirLoopFlow1.SupFlow = 2.0
    thisAirLoopFlow1.SysRetFlow = 1.0
    thisAirLoopFlow1.OAFlow = 1.0
    thisAirLoopFlow2.SupFlow = 3.0
    thisAirLoopFlow2.SysRetFlow = 3.0
    thisAirLoopFlow2.OAFlow = 0.0
    HVACManager.CheckAirLoopFlowBalance(*state)
    EXPECT_FALSE(has_err_output(true))
    thisAirLoopFlow1.SupFlow = 2.0
    thisAirLoopFlow1.SysRetFlow = 1.0
    thisAirLoopFlow1.OAFlow = 0.0
    thisAirLoopFlow2.SupFlow = 3.0
    thisAirLoopFlow2.SysRetFlow = 3.0
    thisAirLoopFlow2.OAFlow = 0.0
    HVACManager.CheckAirLoopFlowBalance(*state)
    EXPECT_TRUE(has_err_output(false))
    var error_string: String = delimited_string({"   ** Severe  ** CheckAirLoopFlowBalance: AirLoopHVAC System 1 is unbalanced. Supply is > return plus outdoor air.",
                          "   **   ~~~   **  Environment=, at Simulation time= 00:00 - 00:00",
                          "   **   ~~~   **   Flows [m3/s at standard density]: Supply=2.00000  Return=1.00000  Outdoor Air=0.00000",
                          "   **   ~~~   **   Imbalance=1.00000",
                          "   **   ~~~   **   This error will only be reported once per system."})
    EXPECT_TRUE(compare_err_stream(error_string, true))
    thisAirLoopFlow1.SupFlow = 0.0
    thisAirLoopFlow1.SysRetFlow = 0.0
    thisAirLoopFlow1.OAFlow = 0.0
    thisAirLoopFlow2.SupFlow = 3.0
    thisAirLoopFlow2.SysRetFlow = 2.0
    thisAirLoopFlow2.OAFlow = 0.99
    HVACManager.CheckAirLoopFlowBalance(*state)
    EXPECT_TRUE(has_err_output(false))
    error_string = delimited_string({"   ** Severe  ** CheckAirLoopFlowBalance: AirLoopHVAC System 2 is unbalanced. Supply is > return plus outdoor air.",
                          "   **   ~~~   **  Environment=, at Simulation time= 00:00 - 00:00",
                          "   **   ~~~   **   Flows [m3/s at standard density]: Supply=3.00000  Return=2.00000  Outdoor Air=0.99000",
                          "   **   ~~~   **   Imbalance=0.01000",
                          "   **   ~~~   **   This error will only be reported once per system."})
    EXPECT_TRUE(compare_err_stream(error_string, true))

def HVACConvergenceErrorTest():
    var i: Int
    var AirSysNum: Int = 1
    var HVACNotConverged: StaticTuple[Bool, 3]
    var DemandToSupply: StaticTuple[Float64, 10]
    var SupplyDeck1ToDemand: StaticTuple[Float64, 10]
    var SupplyDeck2ToDemand: StaticTuple[Float64, 10]
    HVACNotConverged[0] = true
    HVACNotConverged[1] = false
    HVACNotConverged[2] = false
    state.dataAirLoop.AirToZoneNodeInfo.allocate(1)
    state.dataAirLoop.AirToZoneNodeInfo[AirSysNum - 1].AirLoopName = "AirLoop1"
    for i in range(10):
        DemandToSupply[i] = i * 1.0
        SupplyDeck1ToDemand[i] = 0.1 * i
        SupplyDeck2ToDemand[i] = 0.0
    HVACManager.ConvergenceErrors(*state, HVACNotConverged, DemandToSupply, SupplyDeck1ToDemand, SupplyDeck2ToDemand, AirSysNum, ConvErrorCallType.MassFlow)
    var expectedErrString1: String = delimited_string({"   **   ~~~   ** Air System Named = AirLoop1 did not converge for mass flow rate",
                          "   **   ~~~   ** Check values should be zero. Most Recent values listed first.",
                          "   **   ~~~   ** Demand-to-Supply interface mass flow rate check value iteration history trace: 0.00000,1.00000,2.00000,3.00000,4.00000,5.00000,6.00000,7.00000,8.00000,9.00000,",
                          "   **   ~~~   ** Supply-to-demand interface deck 1 mass flow rate check value iteration history trace: 0.00000,0.10000,0.20000,0.30000,0.40000,0.50000,0.60000,0.70000,0.80000,0.90000,"})
    EXPECT_TRUE(compare_err_stream(expectedErrString1, true))
    for i in range(10):
        DemandToSupply[i] = i * 1.0
        SupplyDeck1ToDemand[i] = 0.1 * i
        SupplyDeck2ToDemand[i] = 0.0
    HVACManager.ConvergenceErrors(*state, HVACNotConverged, DemandToSupply, SupplyDeck1ToDemand, SupplyDeck2ToDemand, AirSysNum, ConvErrorCallType.HumidityRatio)
    var expectedErrString2: String = delimited_string({"   **   ~~~   ** Air System Named = AirLoop1 did not converge for humidity ratio",
                          "   **   ~~~   ** Check values should be zero. Most Recent values listed first.",
                          "   **   ~~~   ** Demand-to-Supply interface humidity ratio check value iteration history trace: 0.00000,1.00000,2.00000,3.00000,4.00000,5.00000,6.00000,7.00000,8.00000,9.00000,",
                          "   **   ~~~   ** Supply-to-demand interface deck 1 humidity ratio check value iteration history trace: 0.00000,0.10000,0.20000,0.30000,0.40000,0.50000,0.60000,0.70000,0.80000,0.90000,"})
    EXPECT_TRUE(compare_err_stream(expectedErrString2, true))
    for i in range(10):
        DemandToSupply[i] = i * 1.0
        SupplyDeck1ToDemand[i] = 0.1 * i
        SupplyDeck2ToDemand[i] = 0.0
    HVACManager.ConvergenceErrors(*state, HVACNotConverged, DemandToSupply, SupplyDeck1ToDemand, SupplyDeck2ToDemand, AirSysNum, ConvErrorCallType.Temperature)
    var expectedErrString3: String = delimited_string({"   **   ~~~   ** Air System Named = AirLoop1 did not converge for temperature",
                          "   **   ~~~   ** Check values should be zero. Most Recent values listed first.",
                          "   **   ~~~   ** Demand-to-Supply interface temperature check value iteration history trace: 0.00000,1.00000,2.00000,3.00000,4.00000,5.00000,6.00000,7.00000,8.00000,9.00000,",
                          "   **   ~~~   ** Supply-to-demand interface deck 1 temperature check value iteration history trace: 0.00000,0.10000,0.20000,0.30000,0.40000,0.50000,0.60000,0.70000,0.80000,0.90000,"})
    EXPECT_TRUE(compare_err_stream(expectedErrString3, true))
    for i in range(10):
        DemandToSupply[i] = i * 1.0
        SupplyDeck1ToDemand[i] = 0.0
        SupplyDeck2ToDemand[i] = 0.0
    HVACManager.ConvergenceErrors(*state, HVACNotConverged, DemandToSupply, SupplyDeck1ToDemand, SupplyDeck2ToDemand, AirSysNum, ConvErrorCallType.Energy)
    var expectedErrString4: String = delimited_string({"   **   ~~~   ** Air System Named = AirLoop1 did not converge for energy",
                          "   **   ~~~   ** Check values should be zero. Most Recent values listed first.",
                          "   **   ~~~   ** Demand-to-Supply interface energy check value iteration history trace: 0.00000,1.00000,2.00000,3.00000,4.00000,5.00000,6.00000,7.00000,8.00000,9.00000,",
                          "   **   ~~~   ** Supply-to-demand interface deck 1 energy check value iteration history trace: 0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,"})
    EXPECT_TRUE(compare_err_stream(expectedErrString4, true))
    for i in range(10):
        DemandToSupply[i] = i * 1.0
        SupplyDeck1ToDemand[i] = 0.1 * i
        SupplyDeck2ToDemand[i] = 0.0
    HVACManager.ConvergenceErrors(*state, HVACNotConverged, DemandToSupply, SupplyDeck1ToDemand, SupplyDeck2ToDemand, AirSysNum, ConvErrorCallType.CO2)
    var expectedErrString5: String = delimited_string({"   **   ~~~   ** Air System Named = AirLoop1 did not converge for CO2",
                          "   **   ~~~   ** Check values should be zero. Most Recent values listed first.",
                          "   **   ~~~   ** Demand-to-Supply interface CO2 check value iteration history trace: 0.00000,1.00000,2.00000,3.00000,4.00000,5.00000,6.00000,7.00000,8.00000,9.00000,",
                          "   **   ~~~   ** Supply-to-demand interface deck 1 CO2 check value iteration history trace: 0.00000,0.10000,0.20000,0.30000,0.40000,0.50000,0.60000,0.70000,0.80000,0.90000,"})
    EXPECT_TRUE(compare_err_stream(expectedErrString5, true))
    for i in range(10):
        DemandToSupply[i] = i * 1.0
        SupplyDeck1ToDemand[i] = 0.0
        SupplyDeck2ToDemand[i] = 0.1 * i
    state.dataAirLoop.AirToZoneNodeInfo[AirSysNum - 1].NumSupplyNodes = 2
    HVACManager.ConvergenceErrors(*state, HVACNotConverged, DemandToSupply, SupplyDeck1ToDemand, SupplyDeck2ToDemand, AirSysNum, ConvErrorCallType.Generic)
    var expectedErrString6: String = delimited_string({"   **   ~~~   ** Air System Named = AirLoop1 did not converge for generic contaminant",
                          "   **   ~~~   ** Check values should be zero. Most Recent values listed first.",
                          "   **   ~~~   ** Demand-to-Supply interface generic contaminant check value iteration history trace: 0.00000,1.00000,2.00000,3.00000,4.00000,5.00000,6.00000,7.00000,8.00000,9.00000,",
                          "   **   ~~~   ** Supply-to-demand interface deck 1 generic contaminant check value iteration history trace: 0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,0.00000,",
                          "   **   ~~~   ** Supply-to-demand interface deck 2 generic contaminant check value iteration history trace: 0.00000,0.10000,0.20000,0.30000,0.40000,0.50000,0.60000,0.70000,0.80000,0.90000,"})
    EXPECT_TRUE(compare_err_stream(expectedErrString6, true))