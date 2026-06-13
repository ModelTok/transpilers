from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from AirflowNetwork.Solver import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataRoomAirModel import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataZoneControls import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HybridModel import *
from EnergyPlus.IOFiles import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.PoweredInductionUnits import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.WeatherManager import *
from EnergyPlus.ZonePlenum import *
from EnergyPlus.ZoneTempPredictorCorrector import *
from DataStringGlobals import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.RoomAir import *

def test_ZoneTempPredictorCorrector_CorrectZoneHumRatTest():
    state.dataHVACGlobal.TimeStepSys = 15.0 / 60.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.init_state(state)
    state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 2
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(2)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 1
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[1] = 2
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 3
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 4
    state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
    state.dataLoopNodes.Node.allocate(5)
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[0].Name = state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.CurZoneEqNum = 1
    state.dataHeatBal.Zone[0].Multiplier = 1.0
    state.dataHeatBal.Zone[0].Volume = 1000.0
    state.dataHeatBal.Zone[0].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
    state.dataHeatBalFanSys.SumLatentHTRadSys.allocate(1)
    state.dataHeatBalFanSys.SumLatentHTRadSys[0] = 0.0
    state.dataHeatBalFanSys.SumLatentPool.allocate(1)
    state.dataHeatBalFanSys.SumLatentPool[0] = 0.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataZoneTempPredictorCorrector.spaceHeatBalance.allocate(1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[0]
    thisZoneHB.ZT = 24.0
    state.dataHeatBal.space.allocate(1)
    state.dataHeatBal.spaceIntGainDevices.allocate(1)
    state.dataHeatBal.Zone[0].spaceIndexes.append(1)
    state.dataHeatBal.space[0].HTSurfaceFirst = 1
    state.dataHeatBal.space[0].HTSurfaceLast = 2
    state.dataSurface.Surface.allocate(2)
    state.dataZonePlenum.NumZoneReturnPlenums = 0
    state.dataZonePlenum.NumZoneSupplyPlenums = 0
    state.dataHeatBal.ZoneAirSolutionAlgo = DataHeatBalance.SolutionAlgo.EulerMethod
    state.dataRoomAir.AirModel.allocate(1)
    state.dataHeatBal.ZoneIntGain.allocate(1)
    thisZoneHB.W1 = 0.008
    state.dataLoopNodes.Node[0].MassFlowRate = 0.01
    state.dataLoopNodes.Node[0].HumRat = 0.008
    state.dataLoopNodes.Node[1].MassFlowRate = 0.02
    state.dataLoopNodes.Node[1].HumRat = 0.008
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExhBalanced = 0.0
    state.dataLoopNodes.Node[2].MassFlowRate = 0.00
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = state.dataLoopNodes.Node[2].MassFlowRate
    state.dataLoopNodes.Node[2].HumRat = thisZoneHB.W1
    state.dataLoopNodes.Node[3].MassFlowRate = 0.03
    state.dataLoopNodes.Node[3].HumRat = 0.000
    state.dataLoopNodes.Node[4].HumRat = 0.000
    thisZoneHB.airHumRat = 0.008
    thisZoneHB.OAMFL = 0.0
    thisZoneHB.VAMFL = 0.0
    thisZoneHB.EAMFL = 0.0
    thisZoneHB.EAMFLxHumRat = 0.0
    thisZoneHB.CTMFL = 0.0
    state.dataEnvrn.OutHumRat = 0.008
    thisZoneHB.MixingMassFlowXHumRat = 0.0
    thisZoneHB.MixingMassFlowZone = 0.0
    thisZoneHB.MDotOA = 0.0
    thisZoneHB.correctHumRat(state, 1)
    assert_almost_equal(0.008, state.dataLoopNodes.Node[4].HumRat, 0.00001)
    thisZoneHB.W1 = 0.008
    state.dataLoopNodes.Node[0].MassFlowRate = 0.01
    state.dataLoopNodes.Node[0].HumRat = 0.008
    state.dataLoopNodes.Node[1].MassFlowRate = 0.02
    state.dataLoopNodes.Node[1].HumRat = 0.008
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExhBalanced = 0.0
    state.dataLoopNodes.Node[2].MassFlowRate = 0.02
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = state.dataLoopNodes.Node[2].MassFlowRate
    state.dataLoopNodes.Node[2].HumRat = thisZoneHB.W1
    state.dataLoopNodes.Node[3].MassFlowRate = 0.01
    state.dataLoopNodes.Node[3].HumRat = thisZoneHB.W1
    state.dataLoopNodes.Node[4].HumRat = 0.000
    thisZoneHB.airHumRat = 0.008
    thisZoneHB.OAMFL = 0.0
    thisZoneHB.VAMFL = 0.0
    thisZoneHB.EAMFL = 0.0
    thisZoneHB.EAMFLxHumRat = 0.0
    thisZoneHB.CTMFL = 0.0
    state.dataEnvrn.OutHumRat = 0.004
    thisZoneHB.MixingMassFlowXHumRat = 0.0
    thisZoneHB.MixingMassFlowZone = 0.0
    thisZoneHB.MDotOA = 0.0
    thisZoneHB.correctHumRat(state, 1)
    assert_almost_equal(0.008, state.dataLoopNodes.Node[4].HumRat, 0.00001)
    thisZoneHB.W1 = 0.008
    state.dataLoopNodes.Node[0].MassFlowRate = 0.01
    state.dataLoopNodes.Node[0].HumRat = 0.008
    state.dataLoopNodes.Node[1].MassFlowRate = 0.02
    state.dataLoopNodes.Node[1].HumRat = 0.008
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExhBalanced = 0.02
    state.dataLoopNodes.Node[2].MassFlowRate = 0.02
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = state.dataLoopNodes.Node[2].MassFlowRate
    state.dataLoopNodes.Node[2].HumRat = thisZoneHB.W1
    state.dataLoopNodes.Node[3].MassFlowRate = 0.03
    state.dataLoopNodes.Node[3].HumRat = thisZoneHB.W1
    state.dataLoopNodes.Node[4].HumRat = 0.000
    thisZoneHB.airHumRat = 0.008
    thisZoneHB.OAMFL = 0.0
    thisZoneHB.VAMFL = 0.0
    thisZoneHB.EAMFL = 0.0
    thisZoneHB.EAMFLxHumRat = 0.0
    thisZoneHB.CTMFL = 0.0
    state.dataEnvrn.OutHumRat = 0.004
    thisZoneHB.MixingMassFlowXHumRat = 0.02 * 0.008
    thisZoneHB.MixingMassFlowZone = 0.02
    thisZoneHB.MDotOA = 0.0
    thisZoneHB.correctHumRat(state, 1)
    assert_almost_equal(0.008, state.dataLoopNodes.Node[4].HumRat, 0.00001)
    thisZoneHB.W1 = 0.008
    state.dataLoopNodes.Node[0].MassFlowRate = 0.01
    state.dataLoopNodes.Node[0].HumRat = 0.008
    state.dataLoopNodes.Node[1].MassFlowRate = 0.02
    state.dataLoopNodes.Node[1].HumRat = 0.008
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExhBalanced = 0.02
    state.dataLoopNodes.Node[2].MassFlowRate = 0.02
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = state.dataLoopNodes.Node[2].MassFlowRate
    state.dataLoopNodes.Node[2].HumRat = thisZoneHB.W1
    state.dataLoopNodes.Node[3].MassFlowRate = 0.01
    state.dataLoopNodes.Node[3].HumRat = thisZoneHB.W1
    state.dataLoopNodes.Node[4].HumRat = 0.000
    thisZoneHB.airHumRat = 0.008
    thisZoneHB.OAMFL = 0.0
    thisZoneHB.VAMFL = 0.0
    thisZoneHB.EAMFL = 0.0
    thisZoneHB.EAMFLxHumRat = 0.0
    thisZoneHB.CTMFL = 0.0
    state.dataEnvrn.OutHumRat = 0.004
    thisZoneHB.MixingMassFlowXHumRat = 0.0
    thisZoneHB.MixingMassFlowZone = 0.0
    thisZoneHB.MDotOA = 0.0
    thisZoneHB.correctHumRat(state, 1)
    assert_almost_equal(0.008, state.dataLoopNodes.Node[4].HumRat, 0.00001)
    thisZoneHB.correctHumRat(state, 1)
    assert_almost_equal(0.008, state.dataLoopNodes.Node[4].HumRat, 0.00001)
    state.dataHeatBal.Zone[0].IsControlled = true
    thisZoneHB.correctHumRat(state, 1)
    assert_almost_equal(0.008, state.dataLoopNodes.Node[4].HumRat, 0.00001)

def test_ZoneTempPredictorCorrector_ReportingTest():
    var idf_objects = """Zone,
  Core_top,             !- Name
  0.0000,                  !- Direction of Relative North {deg}
  0.0000,                  !- X Origin {m}
  0.0000,                  !- Y Origin {m}
  0.0000,                  !- Z Origin {m}
  1,                       !- Type
  1,                       !- Multiplier
  ,                        !- Ceiling Height {m}
  ,                        !- Volume {m3}
  autocalculate,           !- Floor Area {m2}
  ,                        !- Zone Inside Convection Algorithm
  ,                        !- Zone Outside Convection Algorithm
  Yes;                     !- Part of Total Floor Area
 
ZoneControl:Thermostat,
  Core_top Thermostat,     !- Name
  Core_top,                !- Zone or ZoneList Name
  Single Heating Control Type Sched,  !- Control Type Schedule Name
  ThermostatSetpoint:SingleHeating,  !- Control 1 Object Type
  Core_top HeatSPSched;    !- Control 1 Name
 
ZoneControl:Humidistat,
  Core_top Humidistat,     !- Name
  Core_top,                !- Zone Name
  Humidification Seasonal Dew-Point Temperature Sch,    !- Humidifying Setpoint Schedule Name
  Dehumidification Seasonal Dew-Point Temperature Sch,  !- Dehumidifying Setpoint Schedule Name
  Dewpoint;                                             !- Control Variable
 
ZoneControl:Humidistat,
  Core_bottom Humidistat,     !- Name
  Core_bottom,                !- Zone Name
  Humidification Seasonal Dew-Point Temperature Sch,    !- Humidifying Setpoint Schedule Name
  Dehumidification Seasonal Dew-Point Temperature Sch,  !- Dehumidifying Setpoint Schedule Name
  Dewpoint;                                             !- Control Variable
 
ZoneControl:Humidistat,
  Core_middle Humidistat,     !- Name
  Core_middle,                !- Zone Name
  Humidification Seasonal Dew-Point Temperature Sch,    !- Humidifying Setpoint Schedule Name
  Dehumidification Seasonal Dew-Point Temperature Sch,  !- Dehumidifying Setpoint Schedule Name
  Dewpoint;                                             !- Control Variable
 
ZoneControl:Humidistat,
  Core_basement Humidistat,     !- Name
  Core_basement,                !- Zone Name
  Humidification Seasonal Dew-Point Temperature Sch,    !- Humidifying Setpoint Schedule Name
  Dehumidification Seasonal Dew-Point Temperature Sch,  !- Dehumidifying Setpoint Schedule Name
  Dewpoint;                                             !- Control Variable
 
Schedule:Constant,
  Dehumidification Seasonal Dew-Point Temperature Sch,,14.0;
 
Schedule:Constant,
  Humidification Seasonal Dew-Point Temperature Sch,,10.0;
 
Schedule:Compact,
  Single Heating Control Type Sched,  !- Name
  Control Type,            !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,1;          !- Field 3
 
ThermostatSetpoint:SingleHeating,
  Core_top HeatSPSched,    !- Name
  SNGL_HTGSETP_SCH;        !- Heating Setpoint Temperature Schedule Name
 
Schedule:Compact,
  SNGL_HTGSETP_SCH,        !- Name
  Temperature,             !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,15.0;       !- Field 3
 
Zone,
  Core_middle,             !- Name
  0.0000,                  !- Direction of Relative North {deg}
  0.0000,                  !- X Origin {m}
  0.0000,                  !- Y Origin {m}
  0.0000,                  !- Z Origin {m}
  1,                       !- Type
  1,                       !- Multiplier
  ,                        !- Ceiling Height {m}
  ,                        !- Volume {m3}
  autocalculate,           !- Floor Area {m2}
  ,                        !- Zone Inside Convection Algorithm
  ,                        !- Zone Outside Convection Algorithm
  Yes;                     !- Part of Total Floor Area
 
ZoneControl:Thermostat,
  Core_middle Thermostat,  !- Name
  Core_middle,             !- Zone or ZoneList Name
  Single Cooling Control Type Sched,  !- Control Type Schedule Name
  ThermostatSetpoint:SingleCooling,  !- Control 1 Object Type
  Core_middle CoolSPSched; !- Control 1 Name
 
Schedule:Compact,
  Single Cooling Control Type Sched,  !- Name
  Control Type,            !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,2;          !- Field 3
 
ThermostatSetpoint:SingleCooling,
  Core_middle CoolSPSched, !- Name
  SNGL_CLGSETP_SCH;        !- Cooling Setpoint Temperature Schedule Name
 
Schedule:Compact,
  SNGL_CLGSETP_SCH,        !- Name
  Temperature,             !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,24.0;       !- Field 3
 
Zone,
  Core_basement,             !- Name
  0.0000,                  !- Direction of Relative North {deg}
  0.0000,                  !- X Origin {m}
  0.0000,                  !- Y Origin {m}
  0.0000,                  !- Z Origin {m}
  1,                       !- Type
  1,                       !- Multiplier
  ,                        !- Ceiling Height {m}
  ,                        !- Volume {m3}
  autocalculate,           !- Floor Area {m2}
  ,                        !- Zone Inside Convection Algorithm
  ,                        !- Zone Outside Convection Algorithm
  Yes;                     !- Part of Total Floor Area
 
ZoneControl:Thermostat,
  Core_basement Thermostat,  !- Name
  Core_basement,             !- Zone or ZoneList Name
  Single Cooling Heating Control Type Sched,  !- Control Type Schedule Name
  ThermostatSetpoint:SingleHeatingOrCooling,  !- Control 1 Object Type
  Core_basement CoolHeatSPSched; !- Control 1 Name
 
Schedule:Compact,
  Single Cooling Heating Control Type Sched,  !- Name
  Control Type,            !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,3;          !- Field 3
 
ThermostatSetpoint:SingleHeatingOrCooling,
  Core_basement CoolHeatSPSched, !- Name
  CLGHTGSETP_SCH;             !- Heating Setpoint Temperature Schedule Name
 
Zone,
  Core_bottom,             !- Name
  0.0000,                  !- Direction of Relative North {deg}
  0.0000,                  !- X Origin {m}
  0.0000,                  !- Y Origin {m}
  0.0000,                  !- Z Origin {m}
  1,                       !- Type
  1,                       !- Multiplier
  ,                        !- Ceiling Height {m}
  ,                        !- Volume {m3}
  autocalculate,           !- Floor Area {m2}
  ,                        !- Zone Inside Convection Algorithm
  ,                        !- Zone Outside Convection Algorithm
  Yes;                     !- Part of Total Floor Area
 
ZoneControl:Thermostat,
  Core_bottom Thermostat,  !- Name
  Core_bottom,             !- Zone or ZoneList Name
  Dual Zone Control Type Sched,  !- Control Type Schedule Name
  ThermostatSetpoint:DualSetpoint,  !- Control 1 Object Type
  Core_bottom DualSPSched; !- Control 1 Name
 
Schedule:Compact,
  Dual Zone Control Type Sched,  !- Name
  Control Type,            !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,4;          !- Field 3
 
ThermostatSetpoint:DualSetpoint,
  Core_bottom DualSPSched, !- Name
  HTGSETP_SCH,             !- Heating Setpoint Temperature Schedule Name
  CLGSETP_SCH;             !- Cooling Setpoint Temperature Schedule Name
 
Schedule:Compact,
  CLGSETP_SCH,             !- Name
  Temperature,             !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,24.0;       !- Field 3
 
Schedule:Compact,
  HTGSETP_SCH,             !- Name
  Temperature,             !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,15.0;       !- Field 3
 
Schedule:Compact,
  CLGHTGSETP_SCH,          !- Name
  Temperature,             !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 24:00,24.0;       !- Field 3
"""
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataHVACGlobal.TimeStepSysSec = 6
    state.init_state(state)
    var ErrorsFound: Bool = False
    GetZoneData(state, ErrorsFound)
    assert_false(ErrorsFound)
    var HeatZoneNum: Int = 0  # 0-based
    var CoolZoneNum: Int = 1
    var CoolHeatZoneNum: Int = 2
    var DualZoneNum: Int = 3
    GetZoneAirSetPoints(state)
    state.dataZoneEnergyDemand.DeadBandOrSetback.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataHeatBalFanSys.TempControlType.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataHeatBalFanSys.TempControlTypeRpt.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataHeatBalFanSys.zoneTstatSetpts.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataZoneEnergyDemand.Setback.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.spaceHeatBalance.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.LoadCorrectionFactor.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataHeatBalFanSys.LoadCorrectionFactor[HeatZoneNum] = 1.0
    state.dataHeatBalFanSys.LoadCorrectionFactor[CoolZoneNum] = 1.0
    state.dataHeatBalFanSys.LoadCorrectionFactor[CoolHeatZoneNum] = 1.0
    state.dataHeatBalFanSys.LoadCorrectionFactor[DualZoneNum] = 1.0
    state.dataHeatBalFanSys.SumLatentHTRadSys.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataHeatBalFanSys.SumLatentHTRadSys[HeatZoneNum] = 0.0
    state.dataHeatBalFanSys.SumLatentHTRadSys[CoolZoneNum] = 0.0
    state.dataHeatBalFanSys.SumLatentHTRadSys[CoolHeatZoneNum] = 0.0
    state.dataHeatBalFanSys.SumLatentHTRadSys[DualZoneNum] = 0.0
    state.dataHeatBalFanSys.SumLatentPool.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataHeatBalFanSys.SumLatentPool[HeatZoneNum] = 0.0
    state.dataHeatBalFanSys.SumLatentPool[CoolZoneNum] = 0.0
    state.dataHeatBalFanSys.SumLatentPool[CoolHeatZoneNum] = 0.0
    state.dataHeatBalFanSys.SumLatentPool[DualZoneNum] = 0.0
    state.dataZoneEnergyDemand.ZoneSysMoistureDemand.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataRoomAir.AirModel.allocate(state.dataZoneCtrls.NumTempControlledZones)
    state.dataRoomAir.AirModel[HeatZoneNum].AirModel = RoomAirModel.Mixing
    state.dataRoomAir.AirModel[CoolZoneNum].AirModel = RoomAirModel.Mixing
    state.dataRoomAir.AirModel[CoolHeatZoneNum].AirModel = RoomAirModel.Mixing
    state.dataRoomAir.AirModel[DualZoneNum].AirModel = RoomAirModel.Mixing
    state.dataZoneCtrls.TempControlledZone[HeatZoneNum].setptTypeSched.currentVal = Int(HVAC.SetptType.SingleHeat)
    state.dataZoneCtrls.TempControlledZone[CoolZoneNum].setptTypeSched.currentVal = Int(HVAC.SetptType.SingleCool)
    state.dataZoneCtrls.TempControlledZone[CoolHeatZoneNum].setptTypeSched.currentVal = Int(HVAC.SetptType.SingleHeatCool)
    state.dataZoneCtrls.TempControlledZone[DualZoneNum].setptTypeSched.currentVal = Int(HVAC.SetptType.Uncontrolled)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[DualZoneNum].TotalOutputRequired = 0.0
    CalcZoneAirTempSetPoints(state)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[DualZoneNum].calcPredictedSystemLoad(state, 1.0, DualZoneNum + 1)  # note: original 1-based
    assert_equal(0.0, state.dataHeatBalFanSys.zoneTstatSetpts[DualZoneNum].setpt)
    state.dataZoneCtrls.TempControlledZone[DualZoneNum].setptTypeSched.currentVal = Int(HVAC.SetptType.DualHeatCool)
    state.dataZoneCtrls.TempControlledZone[HeatZoneNum].setpts[Int(HVAC.SetptType.SingleHeat)].heatSetptSched.currentVal = 20.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[HeatZoneNum].TotalOutputRequired = -1000.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[HeatZoneNum].tempDepLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[HeatZoneNum].TotalOutputRequired / state.dataZoneCtrls.TempControlledZone[HeatZoneNum].setpts[Int(HVAC.SetptType.SingleHeat)].heatSetptSched.currentVal
    CalcZoneAirTempSetPoints(state)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[HeatZoneNum].calcPredictedSystemLoad(state, 1.0, HeatZoneNum + 1)
    assert_equal(20.0, state.dataHeatBalFanSys.zoneTstatSetpts[HeatZoneNum].setpt)
    assert_equal(-1000.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[HeatZoneNum].TotalOutputRequired)
    assert_true(state.dataZoneEnergyDemand.CurDeadBandOrSetback[HeatZoneNum])
    state.dataZoneCtrls.TempControlledZone[HeatZoneNum].setpts[Int(HVAC.SetptType.SingleHeat)].heatSetptSched.currentVal = 21.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[HeatZoneNum].TotalOutputRequired = 1000.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[HeatZoneNum].tempDepLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[HeatZoneNum].TotalOutputRequired / state.dataZoneCtrls.TempControlledZone[HeatZoneNum].setpts[Int(HVAC.SetptType.SingleHeat)].heatSetptSched.currentVal
    state.dataZoneCtrls.TempControlledZone[CoolZoneNum].setpts[Int(HVAC.SetptType.SingleCool)].coolSetptSched.currentVal = 23.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CoolZoneNum].TotalOutputRequired = -3000.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[CoolZoneNum].tempDepLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CoolZoneNum].TotalOutputRequired / state.dataZoneCtrls.TempControlledZone[CoolZoneNum].setpts[Int(HVAC.SetptType.SingleCool)].coolSetptSched.currentVal
    state.dataZoneCtrls.TempControlledZone[CoolHeatZoneNum].setpts[Int(HVAC.SetptType.SingleHeatCool)].heatSetptSched.currentVal = 22.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CoolHeatZoneNum].TotalOutputRequired = -4000.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[CoolHeatZoneNum].tempDepLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CoolHeatZoneNum].TotalOutputRequired / state.dataZoneCtrls.TempControlledZone[CoolHeatZoneNum].setpts[Int(HVAC.SetptType.SingleHeatCool)].heatSetptSched.currentVal
    state.dataZoneCtrls.TempControlledZone[DualZoneNum].setpts[Int(HVAC.SetptType.DualHeatCool)].coolSetptSched.currentVal = 24.0
    state.dataZoneCtrls.TempControlledZone[DualZoneNum].setpts[Int(HVAC.SetptType.DualHeatCool)].heatSetptSched.currentVal = 20.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[DualZoneNum].TotalOutputRequired = 2500.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[DualZoneNum].tempDepLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[DualZoneNum].TotalOutputRequired / state.dataZoneCtrls.TempControlledZone[DualZoneNum].setpts[Int(HVAC.SetptType.DualHeatCool)].heatSetptSched.currentVal
    CalcZoneAirTempSetPoints(state)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[HeatZoneNum].calcPredictedSystemLoad(state, 1.0, HeatZoneNum + 1)
    assert_equal(21.0, state.dataHeatBalFanSys.zoneTstatSetpts[HeatZoneNum].setpt)
    assert_false(state.dataZoneEnergyDemand.CurDeadBandOrSetback[HeatZoneNum])
    assert_equal(1000.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[HeatZoneNum].TotalOutputRequired)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[CoolZoneNum].calcPredictedSystemLoad(state, 1.0, CoolZoneNum + 1)
    assert_equal(23.0, state.dataHeatBalFanSys.zoneTstatSetpts[CoolZoneNum].setpt)
    assert_false(state.dataZoneEnergyDemand.CurDeadBandOrSetback[CoolZoneNum])
    assert_equal(-3000.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CoolZoneNum].TotalOutputRequired)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[CoolHeatZoneNum].calcPredictedSystemLoad(state, 1.0, CoolHeatZoneNum + 1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[CoolHeatZoneNum].calcPredictedHumidityRatio(state, 1.0, CoolHeatZoneNum + 1)
    assert_equal(22.0, state.dataHeatBalFanSys.zoneTstatSetpts[CoolHeatZoneNum].setpt)
    assert_equal(10.0, state.dataZoneCtrls.HumidityControlZone[CoolHeatZoneNum].humidifyingSched.getCurrentVal())
    assert_equal(14.0, state.dataZoneCtrls.HumidityControlZone[CoolHeatZoneNum].dehumidifyingSched.getCurrentVal())
    assert_almost_equal(-357.443, state.dataZoneEnergyDemand.ZoneSysMoistureDemand[CoolHeatZoneNum].OutputRequiredToDehumidifyingSP, 0.001)
    assert_false(state.dataZoneEnergyDemand.CurDeadBandOrSetback[CoolHeatZoneNum])
    assert_equal(-4000.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CoolHeatZoneNum].TotalOutputRequired)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[DualZoneNum].calcPredictedSystemLoad(state, 1.0, DualZoneNum + 1)
    assert_equal(20.0, state.dataHeatBalFanSys.zoneTstatSetpts[DualZoneNum].setpt)
    assert_false(state.dataZoneEnergyDemand.CurDeadBandOrSetback[DualZoneNum])
    assert_equal(2500.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[DualZoneNum].TotalOutputRequired)
    state.dataZoneCtrls.TempControlledZone[DualZoneNum].setpts[Int(HVAC.SetptType.DualHeatCool)].coolSetptSched.currentVal = 25.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[DualZoneNum].TotalOutputRequired = 1000.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[DualZoneNum].tempDepLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[DualZoneNum].TotalOutputRequired / state.dataZoneCtrls.TempControlledZone[DualZoneNum].setpts[Int(HVAC.SetptType.DualHeatCool)].coolSetptSched.currentVal
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[DualZoneNum].tempIndLoad = 3500.0
    CalcZoneAirTempSetPoints(state)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[DualZoneNum].calcPredictedSystemLoad(state, 1.0, DualZoneNum + 1)
    assert_equal(25.0, state.dataHeatBalFanSys.zoneTstatSetpts[DualZoneNum].setpt)
    assert_false(state.dataZoneEnergyDemand.CurDeadBandOrSetback[DualZoneNum])
    assert_equal(-2500.0, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[DualZoneNum].TotalOutputRequired)

def test_ZoneTempPredictorCorrector_AdaptiveThermostat():
    var idf_objects = """Zone,
  Core_top,                !- Name
  0.0000,                  !- Direction of Relative North {deg}
  0.0000,                  !- X Origin {m}
  0.0000,                  !- Y Origin {m}
  0.0000,                  !- Z Origin {m}
  1,                       !- Type
  1,                       !- Multiplier
  ,                        !- Ceiling Height {m}
  ,                        !- Volume {m3}
  autocalculate,           !- Floor Area {m2}
  ,                        !- Zone Inside Convection Algorithm
  ,                        !- Zone Outside Convection Algorithm
  Yes;                     !- Part of Total Floor Area
 
Zone,
  Core_middle,             !- Name
  0.0000,                  !- Direction of Relative North {deg}
  0.0000,                  !- X Origin {m}
  0.0000,                  !- Y Origin {m}
  0.0000,                  !- Z Origin {m}
  1,                       !- Type
  1,                       !- Multiplier
  ,                        !- Ceiling Height {m}
  ,                        !- Volume {m3}
  autocalculate,           !- Floor Area {m2}
  ,                        !- Zone Inside Convection Algorithm
  ,                        !- Zone Outside Convection Algorithm
  Yes;                     !- Part of Total Floor Area
 
Zone,
  Core_basement,             !- Name
  0.0000,                  !- Direction of Relative North {deg}
  0.0000,                  !- X Origin {m}
  0.0000,                  !- Y Origin {m}
  0.0000,                  !- Z Origin {m}
  1,                       !- Type
  1,                       !- Multiplier
  ,                        !- Ceiling Height {m}
  ,                        !- Volume {m3}
  autocalculate,           !- Floor Area {m2}
  ,                        !- Zone Inside Convection Algorithm
  ,                        !- Zone Outside Convection Algorithm
  Yes;                     !- Part of Total Floor Area
 
Zone,
  Core_bottom,             !- Name
  0.0000,                  !- Direction of Relative North {deg}
  0.0000,                  !- X Origin {m}
  0.0000,                  !- Y Origin {m}
  0.0000,                  !- Z Origin {m}
  1,                       !- Type
  1,                       !- Multiplier
  ,                        !- Ceiling Height {m}
  ,                        !- Volume {m3}
  autocalculate,           !- Floor Area {m2}
  ,                        !- Zone Inside Convection Algorithm
  ,                        !- Zone Outside Convection Algorithm
  Yes;                     !- Part of Total Floor Area
 
ZoneControl:Thermostat,
  Core_top Thermostat,                   !- Name
  Core_top,                              !- Zone or ZoneList Name
  Single Cooling Control Type Sched,     !- Control Type Schedule Name
  ThermostatSetpoint:SingleCooling,      !- Control 1 Object Type
  Core_top CoolSPSched;                  !- Control 1 Name
 
ZoneControl:Thermostat:OperativeTemperature,
  Core_top Thermostat,                   !- Thermostat Name
  CONSTANT,                              !- Radiative Fraction Input Mode
  0.0,                                   !- Fixed Radiative Fraction
  ,                                      !- Radiative Fraction Schedule Name
  AdaptiveASH55CentralLine;              !- Adaptive Comfort Model Type
 
ZoneControl:Thermostat,
  Core_middle Thermostat,                !- Name
  Core_middle,                           !- Zone or ZoneList Name
  Single Cooling Control Type Sched,     !- Control Type Schedule Name
  ThermostatSetpoint:SingleCooling,      !- Control 1 Object Type
  Core_middle CoolSPSched;               !- Control 1 Name
 
ZoneControl:Thermostat:OperativeTemperature,
  Core_middle Thermostat,                !- Thermostat Name
  CONSTANT,                              !- Radiative Fraction Input Mode
  0.0,                                   !- Fixed Radiative Fraction
  ,                                      !- Radiative Fraction Schedule Name
  AdaptiveCEN15251CentralLine;           !- Adaptive Comfort Model Type
 
ZoneControl:Thermostat,
  Core_basement Thermostat,                   !- Name
  Core_basement,                              !- Zone or ZoneList Name
  Single Cooling Heating Control Type Sched,  !- Control Type Schedule Name
  ThermostatSetpoint:SingleHeatingOrCooling,  !- Control 1 Object Type
  Core_basement CoolHeatSPSched;              !- Control 1 Name
 
ZoneControl:Thermostat:OperativeTemperature,
  Core_basement Thermostat,              !- Thermostat Name
  CONSTANT,                              !- Radiative Fraction Input Mode
  0.0,                                   !- Fixed Radiative Fraction
  ,                                      !- Radiative Fraction Schedule Name
  None;                                  !- Adaptive Comfort Model Type
 
ZoneControl:Thermostat,
  Core_bottom Thermostat,                !- Name
  Core_bottom,                           !- Zone or ZoneList Name
  Dual Zone Control Type Sched,          !- Control Type Schedule Name
  ThermostatSetpoint:DualSetpoint,       !- Control 1 Object Type
  Core_bottom DualSPSched;               !- Control 1 Name
 
ZoneControl:Thermostat:OperativeTemperature,
  Core_bottom Thermostat,                !- Thermostat Name
  CONSTANT,                              !- Radiative Fraction Input Mode
  0.0,                                   !- Fixed Radiative Fraction
  ,                                      !- Radiative Fraction Schedule Name
  AdaptiveASH55CentralLine;              !- Adaptive Comfort Model Type
 
ThermostatSetpoint:SingleCooling,
  Core_middle CoolSPSched,               !- Name
  SNGL_CLGSETP_SCH;                      !- Cooling Setpoint Temperature Schedule Name
 
ThermostatSetpoint:SingleHeatingOrCooling,
  Core_basement CoolHeatSPSched,         !- Name
  CLGHTGSETP_SCH;                        !- Heating Setpoint Temperature Schedule Name
 
ThermostatSetpoint:DualSetpoint,
  Core_bottom DualSPSched,               !- Name
  HTGSETP_SCH,                           !- Heating Setpoint Temperature Schedule Name
  CLGSETP_SCH;                           !- Cooling Setpoint Temperature Schedule Name
 
Schedule:Compact,
  Single Cooling Control Type Sched,  !- Name
  Control Type,                          !- Schedule Type Limits Name
  Through: 12/31,                        !- Field 1
  For: AllDays,                          !- Field 2
  Until: 24:00,2;                        !- Field 3
 
Schedule:Compact,
  SNGL_CLGSETP_SCH,                      !- Name
  Temperature,                           !- Schedule Type Limits Name
  Through: 12/31,                        !- Field 1
  For: AllDays,                          !- Field 2
  Until: 24:00,24.0;                     !- Field 3
 
Schedule:Compact,
  Single Cooling Heating Control Type Sched,  !- Name
  Control Type,                          !- Schedule Type Limits Name
  Through: 12/31,                        !- Field 1
  For: AllDays,                          !- Field 2
  Until: 24:00,3;                        !- Field 3
 
Schedule:Compact,
  Dual Zone Control Type Sched,          !- Name
  Control Type,                          !- Schedule Type Limits Name
  Through: 12/31,                        !- Field 1
  For: AllDays,                          !- Field 2
  Until: 24:00,4;                        !- Field 3
 
Schedule:Compact,
  CLGSETP_SCH,                           !- Name
  Temperature,                           !- Schedule Type Limits Name
  Through: 12/31,                        !- Field 1
  For: AllDays,                          !- Field 2
  Until: 24:00,24.0;                     !- Field 3
 
Schedule:Compact,
  HTGSETP_SCH,                           !- Name
  Temperature,                           !- Schedule Type Limits Name
  Through: 12/31,                        !- Field 1
  For: AllDays,                          !- Field 2
  Until: 24:00,15.0;                     !- Field 3
 
Schedule:Compact,
  CLGHTGSETP_SCH,                        !- Name
  Temperature,                           !- Schedule Type Limits Name
  Through: 12/31,                        !- Field 1
  For: AllDays,                          !- Field 2
  Until: 24:00,24.0;                     !- Field 3
"""
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    var ZoneNum: Int = 4
    var CoolZoneASHNum: Int = 0
    var CoolZoneCENNum: Int = 1
    var NoneAdapZoneNum: Int = 2
    var DualZoneNum: Int = 3
    var summerDesignDayTypeIndex: Int = 9
    var ASH55_CENTRAL: Int = 2
    var CEN15251_CENTRAL: Int = 5
    state.dataEnvrn.DayOfYear = 1
    state.dataWeather.Envrn = 1
    state.dataWeather.Environment.allocate(1)
    state.dataWeather.DesDayInput.allocate(1)
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].KindOfEnvrn = Constant.KindOfSim.RunPeriodWeather
    state.dataWeather.DesDayInput[state.dataWeather.Envrn - 1].DayType = summerDesignDayTypeIndex
    state.dataWeather.DesDayInput[state.dataWeather.Envrn - 1].MaxDryBulb = 30.0
    state.dataWeather.DesDayInput[state.dataWeather.Envrn - 1].DailyDBRange = 10.0
    var ZoneAirSetPoint: Float64 = 0.0
    var ErrorsFound: Bool = False
    GetZoneData(state, ErrorsFound)
    assert_false(ErrorsFound)
    assert_false(state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.initialized)
    var runningAverageASH_1: List[Float64] = List[Float64](repeat=0.0, size=365)
    var runningAverageCEN_1: List[Float64] = List[Float64](repeat=0.0, size=365)
    CalculateAdaptiveComfortSetPointSchl(state, runningAverageASH_1, runningAverageCEN_1)
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Central(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Upper_90(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Upper_80(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Central(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_I(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_II(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_III(state.dataEnvrn.DayOfYear - 1))
    var runningAverageASH_2: List[Float64] = List[Float64](repeat=40.0, size=365)
    var runningAverageCEN_2: List[Float64] = List[Float64](repeat=40.0, size=365)
    CalculateAdaptiveComfortSetPointSchl(state, runningAverageASH_2, runningAverageCEN_2)
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Central(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Upper_90(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Upper_80(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Central(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_I(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_II(state.dataEnvrn.DayOfYear - 1))
    assert_equal(-1, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_III(state.dataEnvrn.DayOfYear - 1))
    var runningAverageASH: List[Float64] = List[Float64](repeat=25.0, size=365)
    var runningAverageCEN: List[Float64] = List[Float64](repeat=25.0, size=365)
    CalculateAdaptiveComfortSetPointSchl(state, runningAverageASH, runningAverageCEN)
    assert_true(state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.initialized)
    assert_equal(25.55, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Central(state.dataEnvrn.DayOfYear - 1))
    assert_equal(28.05, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Upper_90(state.dataEnvrn.DayOfYear - 1))
    assert_equal(29.05, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Upper_80(state.dataEnvrn.DayOfYear - 1))
    assert_equal(27.05, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Central(state.dataEnvrn.DayOfYear - 1))
    assert_equal(29.05, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_I(state.dataEnvrn.DayOfYear - 1))
    assert_equal(30.05, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_II(state.dataEnvrn.DayOfYear - 1))
    assert_equal(31.05, state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveCEN15251_Upper_III(state.dataEnvrn.DayOfYear - 1))
    assert_equal(25.55, state.dataZoneTempPredictorCorrector.AdapComfortSetPointSummerDesDay[0])
    assert_equal(27.05, state.dataZoneTempPredictorCorrector.AdapComfortSetPointSummerDesDay[3])
    state.dataZoneCtrls.TempControlledZone.allocate(ZoneNum)
    state.dataZoneCtrls.TempControlledZone[CoolZoneASHNum].AdaptiveComfortTempControl = true
    state.dataZoneCtrls.TempControlledZone[CoolZoneASHNum].AdaptiveComfortModelTypeIndex = ASH55_CENTRAL
    state.dataZoneCtrls.TempControlledZone[CoolZoneCENNum].AdaptiveComfortTempControl = true
    state.dataZoneCtrls.TempControlledZone[CoolZoneCENNum].AdaptiveComfortModelTypeIndex = CEN15251_CENTRAL
    state.dataZoneCtrls.TempControlledZone[NoneAdapZoneNum].AdaptiveComfortTempControl = true
    state.dataZoneCtrls.TempControlledZone[NoneAdapZoneNum].AdaptiveComfortModelTypeIndex = ASH55_CENTRAL
    state.dataZoneCtrls.TempControlledZone[DualZoneNum].AdaptiveComfortTempControl = true
    state.dataZoneCtrls.TempControlledZone[DualZoneNum].AdaptiveComfortModelTypeIndex = ASH55_CENTRAL
    ZoneAirSetPoint = 0.0
    AdjustOperativeSetPointsforAdapComfort(state, CoolZoneASHNum, ZoneAirSetPoint)
    assert_equal(25.55, ZoneAirSetPoint)
    ZoneAirSetPoint = 0.0
    AdjustOperativeSetPointsforAdapComfort(state, CoolZoneCENNum, ZoneAirSetPoint)
    assert_equal(27.05, ZoneAirSetPoint)
    ZoneAirSetPoint = 0.0
    state.dataZoneTempPredictorCorrector.AdapComfortDailySetPointSchedule.ThermalComfortAdaptiveASH55_Central(state.dataEnvrn.DayOfYear - 1) = -1
    AdjustOperativeSetPointsforAdapComfort(state, NoneAdapZoneNum, ZoneAirSetPoint)
    assert_equal(0, ZoneAirSetPoint)
    ZoneAirSetPoint = 26.0
    AdjustOperativeSetPointsforAdapComfort(state, DualZoneNum, ZoneAirSetPoint)
    assert_equal(26.0, ZoneAirSetPoint)

def test_ZoneTempPredictorCorrector_calcZoneOrSpaceSums_SurfConvectionTest():
    state.init_state(state)
    var ZoneNum: Int = 0  # 1-based in original, we use 0-based
    state.dataHeatBal.ZoneIntGain.allocate(1)
    state.dataHeatBalFanSys.SumConvHTRadSys.allocate(1)
    state.dataHeatBalFanSys.SumConvPool.allocate(1)
    state.dataHeatBalFanSys.SumConvHTRadSys[0] = 0.0
    state.dataHeatBalFanSys.SumConvPool[0] = 0.0
    state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 2
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(2)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 1
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[1] = 2
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 3
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 4
    state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[0].Name = state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
    state.dataHeatBal.Zone[0].IsControlled = true
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.CurZoneEqNum = 1
    state.dataHeatBal.Zone[0].Multiplier = 1.0
    state.dataHeatBal.Zone[0].Volume = 1000.0
    state.dataHeatBal.Zone[0].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
    state.dataHeatBalFanSys.SumLatentHTRadSys.allocate(1)
    state.dataHeatBalFanSys.SumLatentHTRadSys[0] = 0.0
    state.dataHeatBalFanSys.SumLatentPool.allocate(1)
    state.dataHeatBalFanSys.SumLatentPool[0] = 0.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataZoneTempPredictorCorrector.spaceHeatBalance.allocate(1)
    var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum]
    thisZoneHB.MAT = 24.0
    thisZoneHB.airHumRat = 0.001
    state.dataHeatBal.space.allocate(1)
    state.dataHeatBal.spaceIntGainDevices.allocate(1)
    state.dataHeatBal.Zone[0].spaceIndexes.append(1)
    state.dataHeatBal.space[0].HTSurfaceFirst = 1
    state.dataHeatBal.space[0].HTSurfaceLast = 3
    state.dataSurface.Surface.allocate(3)
    state.dataHeatBalSurf.SurfHConvInt.allocate(3)
    state.dataLoopNodes.Node.allocate(5)
    state.dataHeatBal.SurfTempEffBulkAir.allocate(3)
    state.dataHeatBalSurf.SurfTempInTmp.allocate(3)
    state.dataSurface.SurfTAirRef.allocate(3)
    state.dataSurface.SurfTAirRef[0] = DataSurfaces.RefAirTemp.ZoneMeanAirTemp
    state.dataSurface.SurfTAirRef[1] = DataSurfaces.RefAirTemp.AdjacentAirTemp
    state.dataSurface.SurfTAirRef[2] = DataSurfaces.RefAirTemp.ZoneSupplyAirTemp
    state.dataSurface.Surface[0].HeatTransSurf = true
    state.dataSurface.Surface[1].HeatTransSurf = true
    state.dataSurface.Surface[2].HeatTransSurf = true
    state.dataSurface.Surface[0].Area = 10.0
    state.dataSurface.Surface[1].Area = 10.0
    state.dataSurface.Surface[2].Area = 10.0
    state.dataHeatBalSurf.SurfTempInTmp[0] = 15.0
    state.dataHeatBalSurf.SurfTempInTmp[1] = 20.0
    state.dataHeatBalSurf.SurfTempInTmp[2] = 25.0
    state.dataHeatBal.SurfTempEffBulkAir[0] = 10.0
    state.dataHeatBal.SurfTempEffBulkAir[1] = 10.0
    state.dataHeatBal.SurfTempEffBulkAir[2] = 10.0
    state.dataLoopNodes.Node[0].Temp = 20.0
    state.dataLoopNodes.Node[1].Temp = 20.0
    state.dataLoopNodes.Node[2].Temp = 20.0
    state.dataLoopNodes.Node[3].Temp = 20.0
    state.dataLoopNodes.Node[0].MassFlowRate = 0.1
    state.dataLoopNodes.Node[1].MassFlowRate = 0.1
    state.dataLoopNodes.Node[2].MassFlowRate = 0.1
    state.dataLoopNodes.Node[3].MassFlowRate = 0.1
    state.dataHeatBalSurf.SurfHConvInt[0] = 0.5
    state.dataHeatBalSurf.SurfHConvInt[1] = 0.5
    state.dataHeatBalSurf.SurfHConvInt[2] = 0.5
    state.dataZonePlenum.NumZoneReturnPlenums = 0
    state.dataZonePlenum.NumZoneSupplyPlenums = 0
    thisZoneHB.calcZoneOrSpaceSums(state, true, ZoneNum + 1)
    assert_equal(5.0, thisZoneHB.SumHA)
    assert_equal(300.0, thisZoneHB.SumHATsurf)
    assert_equal(150.0, thisZoneHB.SumHATref)
    state.dataLoopNodes.Node[0].MassFlowRate = 0.0
    state.dataLoopNodes.Node[1].MassFlowRate = 0.0
    thisZoneHB.calcZoneOrSpaceSums(state, true, ZoneNum + 1)
    assert_equal(10.0, thisZoneHB.SumHA)
    assert_equal(300.0, thisZoneHB.SumHATsurf)
    assert_equal(50.0, thisZoneHB.SumHATref)
    state.dataLoopNodes.Node[0].MassFlowRate = 0.1
    state.dataLoopNodes.Node[1].MassFlowRate = 0.2
    thisZoneHB.calcZoneOrSpaceSums(state, true, ZoneNum + 1)
    assert_almost_equal(302.00968500, thisZoneHB.SumSysMCp, 0.0001)
    assert_almost_equal(6040.1937, thisZoneHB.SumSysMCpT, 0.0001)
    thisZoneHB.calcZoneOrSpaceSums(state, false, ZoneNum + 1)
    assert_equal(0.0, thisZoneHB.SumSysMCp)
    assert_equal(0.0, thisZoneHB.SumSysMCpT)
    state.dataHeatBal.Zone[0].leakageParallelPIUNums.append(1)
    state.dataPowerInductionUnits.GetPIUInputFlag = false
    state.dataPowerInductionUnits.NumPIUs = 1
    state.dataPowerInductionUnits.PIU.allocate(1)
    state.dataPowerInductionUnits.PIU[0].SecAirInNode = 3
    state.dataPowerInductionUnits.PIU[0].PriAirInNode = 5
    state.dataPowerInductionUnits.PIU[0].leakFlow = 0.1
    state.dataLoopNodes.Node[4].HumRat = 0.008
    state.dataLoopNodes.Node[4].Temp = 12.8
    thisZoneHB.calcZoneOrSpaceSums(state, true, ZoneNum + 1)
    assert_almost_equal(402.67958, thisZoneHB.SumSysMCp, 0.0001)
    assert_almost_equal(7328.768356, thisZoneHB.SumSysMCpT, 0.0001)

def test_ZoneTempPredictorCorrector_EMSOverrideSetpointTest():
    state.init_state(state)
    state.dataZoneCtrls.NumTempControlledZones = 1
    state.dataZoneCtrls.NumComfortControlledZones = 0
    state.dataZoneCtrls.TempControlledZone.allocate(1)
    state.dataZoneCtrls.TempControlledZone[0].EMSOverrideHeatingSetPointOn = true
    state.dataZoneCtrls.TempControlledZone[0].EMSOverrideCoolingSetPointOn = true
    state.dataZoneCtrls.TempControlledZone[0].ActualZoneNum = 1
    state.dataZoneCtrls.TempControlledZone[0].EMSOverrideHeatingSetPointValue = 23
    state.dataZoneCtrls.TempControlledZone[0].EMSOverrideCoolingSetPointValue = 26
    state.dataHeatBalFanSys.TempControlType.allocate(1)
    state.dataHeatBalFanSys.TempControlTypeRpt.allocate(1)
    state.dataHeatBalFanSys.zoneTstatSetpts.allocate(1)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.DualHeatCool
    OverrideAirSetPointsforEMSCntrl(state)
    assert_equal(23.0, state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo)
    assert_equal(26.0, state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi)
    state.dataZoneCtrls.NumTempControlledZones = 0
    state.dataZoneCtrls.NumComfortControlledZones = 1
    state.dataZoneCtrls.ComfortControlledZone.allocate(1)
    state.dataHeatBalFanSys.ComfortControlType.allocate(1)
    state.dataZoneCtrls.ComfortControlledZone[0].ActualZoneNum = 1
    state.dataZoneCtrls.ComfortControlledZone[0].EMSOverrideHeatingSetPointOn = true
    state.dataZoneCtrls.ComfortControlledZone[0].EMSOverrideCoolingSetPointOn = true
    state.dataHeatBalFanSys.ComfortControlType[0] = HVAC.SetptType.DualHeatCool
    state.dataZoneCtrls.ComfortControlledZone[0].EMSOverrideHeatingSetPointValue = 22
    state.dataZoneCtrls.ComfortControlledZone[0].EMSOverrideCoolingSetPointValue = 25
    OverrideAirSetPointsforEMSCntrl(state)
    assert_equal(22.0, state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo)
    assert_equal(25.0, state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi)

def test_ZoneTempPredictorCorrector_WrongControlTypeSchedule():
    var idf_objects = """Zone,
  Zone1,                                  !- Name
  0,                                      !- Direction of Relative North {deg}
  0,                                      !- X Origin {m}
  0,                                      !- Y Origin {m}
  0,                                      !- Z Origin {m}
  ,                                       !- Type
  1,                                      !- Multiplier
  ,                                       !- Ceiling Height {m}
  ,                                       !- Volume {m3}
  ,                                       !- Floor Area {m2}
  ,                                       !- Zone Inside Convection Algorithm
  ,                                       !- Zone Outside Convection Algorithm
  Yes;                                    !- Part of Total Floor Area
ZoneControl:Thermostat,
  Zone1 Thermostat,                       !- Name
  Zone1,                                  !- Zone or ZoneList Name
  Single HEATING Control Type Sched,      !- Control Type Schedule Name
  ThermostatSetpoint:SingleCooling,       !- Control 1 Object Type
  Thermostat Setpoint Single Cooling;     !- Control 1 Name
Schedule:Constant,
  Single HEATING Control Type Sched,      !- Name
  Control Type,                           !- Schedule Type Limits Name
  1;                                      !- Hourly Value
ThermostatSetpoint:SingleCooling,
  Thermostat Setpoint Single Cooling,    !- Name
  Always 26C;                             !- Setpoint Temperature Schedule Name
Schedule:Constant,
  Always 26C,                             !- Name
  Temperature,                            !- Schedule Type Limits Name
  26;                                     !- Hourly Value
ScheduleTypeLimits,
  Control Type,                           !- Name
  0,                                      !- Lower Limit Value {BasedOnField A3}
  4,                                      !- Upper Limit Value {BasedOnField A3}
  Discrete;                               !- Numeric Type
ScheduleTypeLimits,
  Temperature,                            !- Name
  ,                                       !- Lower Limit Value {BasedOnField A3}
  ,                                       !- Upper Limit Value {BasedOnField A3}
  Continuous,                             !- Numeric Type
  Temperature;                            !- Unit Type
"""
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    var ErrorsFound: Bool = False
    GetZoneData(state, ErrorsFound)
    assert_false(ErrorsFound)
    assert_raise(EnergyPlus.FatalError, GetZoneAirSetPoints, state)
    var error_string = """   ** Severe  ** Control Type Schedule=SINGLE HEATING CONTROL TYPE SCHED
   **   ~~~   ** ..specifies 1 (ThermostatSetpoint:SingleHeating) as the control type. Not valid for this zone.
   **   ~~~   ** ..reference ZoneControl:Thermostat=ZONE1 THERMOSTAT
   **   ~~~   ** ..reference ZONE=ZONE1
   ** Severe  ** GetStagedDualSetpoint: Errors with invalid names in ZoneControl:Thermostat:StagedDualSetpoint objects.
   **   ~~~   **