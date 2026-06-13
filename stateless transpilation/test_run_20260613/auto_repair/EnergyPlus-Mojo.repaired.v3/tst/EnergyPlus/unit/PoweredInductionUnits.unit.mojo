from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.BranchInputManager import *
from EnergyPlus.CurveManager import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataDefineEquip import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.ElectricPowerServiceManager import *
from EnergyPlus.Fans import *
from EnergyPlus.General import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HeatingCoils import *
from EnergyPlus.MixerComponent import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant.PlantManager import *
from EnergyPlus.PoweredInductionUnits import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.SizingManager import *
from EnergyPlus.ZoneAirLoopEquipmentManager import *

def ParallelPIUTest1(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Zone,",
        "  SPACE2-1;                               !- Name",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE2-1,                               !- Zone Name",
        "  SPACE2-1 Equipment,                     !- Zone Conditioning Equipment List Name",
        "  SPACE2-1 In Node,                       !- Zone Air Inlet Node or NodeList Name",
        "  SPACE2-1 ATU Sec Node,                  !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE2-1 Air Node,                      !- Zone Air Node Name",
        "  SPACE2-1 Return Node;                   !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  SPACE2-1 Equipment,                     !- Name",
        "  SequentialLoad,                         !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,           !- Zone Equipment 1 Object Type",
        "  SPACE2-1 ADU,                           !- Zone Equipment 1 Name",
        "  1,                                      !- Zone Equipment 1 Cooling Sequence",
        "  1;                                      !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:AirDistributionUnit,",
        "  SPACE2-1 ADU,                           !- Name",
        "  SPACE2-1 In Node,                       !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:ParallelPIU:Reheat,  !- Air Terminal Object Type",
        "  SPACE2-1 Parallel PIU Reheat;           !- Air Terminal Name",
        "AirTerminal:SingleDuct:ParallelPIU:Reheat,",
        "  SPACE2-1 Parallel PIU Reheat,           !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  0.1,                                    !- Maximum Primary Air Flow Rate {m3/s}",
        "  0.05,                                   !- Maximum Secondary Air Flow Rate {m3/s}",
        "  0.2,                                    !- Minimum Primary Air Flow Fraction",
        "  0.1,                                    !- Fan On Flow Fraction",
        "  SPACE2-1 ATU In Node,                   !- Supply Air Inlet Node Name",
        "  SPACE2-1 ATU Sec Node,                  !- Secondary Air Inlet Node Name",
        "  SPACE2-1 In Node,                       !- Outlet Node Name",
        "  SPACE2-1 PIU Mixer,                     !- Zone Mixer Name",
        "  SPACE2-1 PIU Fan,                       !- Fan Name",
        "  Coil:Heating:Electric,                  !- Reheat Coil Object Type",
        "  SPACE2-1 Zone Coil,                     !- Reheat Coil Name",
        "  0.0,                                    !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0,                                    !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0001;                                 !- Convergence Tolerance",
        "Fan:ConstantVolume,",
        "  SPACE2-1 PIU Fan,                       !- Name",
        "  AlwaysOff,                              !- Availability Schedule Name",
        "  0.5,                                    !- Fan Total Efficiency",
        "  50.0,                                   !- Pressure Rise {Pa}",
        "  0.05,                                   !- Maximum Flow Rate {m3/s}",
        "  0.9,                                    !- Motor Efficiency",
        "  1.0,                                    !- Motor In Airstream Fraction",
        "  SPACE2-1 ATU Sec Node,                  !- Air Inlet Node Name",
        "  SPACE2-1 ATU Fan Outlet Node;           !- Air Outlet Node Name",
        "AirLoopHVAC:ZoneMixer,",
        "  SPACE2-1 PIU Mixer,                     !- Name",
        "  SPACE2-1 Zone Coil Air In Node,         !- Outlet Node Name",
        "  SPACE2-1 ATU In Node,                   !- Inlet 1 Node Name",
        "  SPACE2-1 ATU Fan Outlet Node;           !- Inlet 2 Node Name",
        "Coil:Heating:Electric,",
        "  SPACE2-1 Zone Coil,                     !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  1.0,                                    !- Efficiency",
        "  1000,                                   !- Nominal Capacity",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Inlet Node Name",
        "  SPACE2-1 In Node;                       !- Air Outlet Node Name",
        "Schedule:Constant,",
        "  AlwaysOff,                              !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  0;                                      !- Hourly Value",
        "Schedule:Constant,",
        "  AlwaysOn,                               !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
        "Curve:Linear,",
        "  constant_leakage,        !- Name",
        "  0.1,                     !- Coefficient1 Constant",
        "  0,                       !- Coefficient2 x",
        "  0,                       !- Minimum Value of x",
        "  1;                       !- Maximum Value of x",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
    Sched.UpdateScheduleVals(self.state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    var _1: Bool = ErrorsFound
    DataZoneEquipment.GetZoneEquipmentData(self.state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(self.state)
    self.state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    Fans.GetFanInput(self.state)
    self.state.dataFans.GetFanInputFlag = False
    PoweredInductionUnits.GetPIUs(self.state)
    var error_string: String = delimited_string(
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSOFF",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSON",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
    )
    var _2: Bool = compare_err_stream(error_string)
    self.state.dataHeatBalFanSys.TempControlType.allocate(1)
    self.state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.DualHeatCool
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    var ZoneNum: Int = 1
    var SysNum: Int = 1
    var ZoneNodeNum: Int = 1
    var SecNodeNum: Int = self.state.dataPowerInductionUnits.PIU[SysNum].SecAirInNode
    var PriNodeNum: Int = self.state.dataPowerInductionUnits.PIU[SysNum].PriAirInNode
    var FirstHVACIteration: Bool = True
    var SecMaxMassFlow: Float64 = 0.05 * self.state.dataEnvrn.StdRhoAir
    self.state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    PoweredInductionUnits.InitPIU(self.state, SysNum, FirstHVACIteration)
    self.state.dataFans.fans[1].init(self.state)
    self.state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = False
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _3: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == 0.0
    var _4: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _5: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMaxMassFlow
    var _6: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = -2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _7: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == 0.0
    var _8: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = -2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _9: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == 0.0
    var _10: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _11: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMaxMassFlow
    var _12: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = self.state.dataPowerInductionUnits.PIU[SysNum].MinPriAirMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = True
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _13: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMaxMassFlow
    var _14: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.2
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = self.state.dataPowerInductionUnits.PIU[SysNum].MinPriAirMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _15: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMaxMassFlow
    var _16: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.2
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = self.state.dataPowerInductionUnits.PIU[SysNum].MinPriAirMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = -2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _17: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMaxMassFlow
    var _18: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 1.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = self.state.dataPowerInductionUnits.PIU[SysNum].MinPriAirMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = -2000.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputReqToHeatSP = -2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = False
    self.state.dataPowerInductionUnits.PIU[SysNum].leakFracCurve = Curve.GetCurveIndex(self.state, "CONSTANT_LEAKAGE")
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var SysOutputProvided: Float64 = 0.0
    var NonAirSysOutput: Float64 = 0.0
    var LatOutputProvided: Float64 = 0.0
    var AirDistUnitNum: Int = 1
    self.state.dataPowerInductionUnits.GetPIUInputFlag = False
    ZoneAirLoopEquipmentManager.SimZoneAirLoopEquipment(
        self.state,
        AirDistUnitNum,
        SysOutputProvided,
        NonAirSysOutput,
        LatOutputProvided,
        FirstHVACIteration,
        self.state.dataPowerInductionUnits.PIU[SysNum].CtrlZoneNum,
    )
    var _19: Bool = self.state.dataDefineEquipment.AirDistUnit[1].MassFlowRateTU > self.state.dataDefineEquipment.AirDistUnit[1].MassFlowRateZSup
    self.state.dataHeatBalFanSys.TempControlType.deallocate()
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.deallocate()
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.deallocate()

def SeriesPIUTest1(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Zone,",
        "  SPACE2-1;                !- Name",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE2-1,                !- Zone Name",
        "  SPACE2-1 Equipment,      !- Zone Conditioning Equipment List Name",
        "  SPACE2-1 In Node,        !- Zone Air Inlet Node or NodeList Name",
        "  SPACE2-1 ATU Sec Node,   !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE2-1 Air Node,       !- Zone Air Node Name",
        "  SPACE2-1 Return Node;    !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  SPACE2-1 Equipment,      !- Name",
        "  SequentialLoad,          !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
        "  SPACE2-1 ADU,            !- Zone Equipment 1 Name",
        "  1,                       !- Zone Equipment 1 Cooling Sequence",
        "  1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:AirDistributionUnit,",
        "  SPACE2-1 ADU,            !- Name",
        "  SPACE2-1 In Node,        !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:SeriesPIU:Reheat,  !- Air Terminal Object Type",
        "  SPACE2-1 Series PIU Reheat;           !- Air Terminal Name",
        "AirTerminal:SingleDuct:SeriesPIU:Reheat,",
        "  SPACE2-1 Series PIU Reheat,     !- Name",
        "  AlwaysOn,    !- Availability Schedule Name",
        "  0.15,                !- Maximum Air Flow Rate {m3/s}",
        "  0.05,                !- Maximum Primary Air Flow Rate {m3/s}",
        "  0.2,                !- Minimum Primary Air Flow Fraction",
        "  SPACE2-1 ATU In Node,    !- Supply Air Inlet Node Name",
        "  SPACE2-1 ATU Sec Node,   !- Secondary Air Inlet Node Name",
        "  SPACE2-1 In Node,        !- Outlet Node Name",
        "  SPACE2-1 PIU Mixer,      !- Zone Mixer Name",
        "  SPACE2-1 PIU Fan,        !- Fan Name",
        "  Coil:Heating:Electric,      !- Reheat Coil Object Type",
        "  SPACE2-1 Zone Coil,      !- Reheat Coil Name",
        "  0.0,                !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0,                     !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0001;                  !- Convergence Tolerance",
        "Fan:ConstantVolume,",
        "  SPACE2-1 PIU Fan,        !- Name",
        "  AlwaysOff,           !- Availability Schedule Name",
        "  0.5,                     !- Fan Total Efficiency",
        "  50.0,                    !- Pressure Rise {Pa}",
        "  0.05,                !- Maximum Flow Rate {m3/s}",
        "  0.9,                     !- Motor Efficiency",
        "  1.0,                     !- Motor In Airstream Fraction",
        "  SPACE2-1 ATU Fan Inlet Node,   !- Air Inlet Node Name",
        "  SPACE2-1 Zone Coil Air In Node;  !- Air Outlet Node Name",
        "AirLoopHVAC:ZoneMixer,",
        "  SPACE2-1 PIU Mixer,      !- Name",
        "  SPACE2-1 ATU Fan Inlet Node,  !- Outlet Node Name",
        "  SPACE2-1 ATU In Node,    !- Inlet 1 Node Name",
        "  SPACE2-1 ATU Sec Node;  !- Inlet 2 Node Name",
        "Coil:Heating:Electric,",
        "  SPACE2-1 Zone Coil,      !- Name",
        "  AlwaysOn,    !- Availability Schedule Name",
        "  1.0,                     !- Efficiency",
        "  1000,                !- Nominal Capacity",
        "  SPACE2-1 Zone Coil Air In Node,  !- Air Inlet Node Name",
        "  SPACE2-1 In Node;       !- Air Outlet Node Name",
        "Schedule:Constant,",
        "  AlwaysOff,               !- Name",
        "  ,                        !- Schedule Type Limits Name",
        "  0;                       !- Hourly Value",
        "Schedule:Constant,",
        "  AlwaysOn,               !- Name",
        "  ,                        !- Schedule Type Limits Name",
        "  1;                       !- Hourly Value",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
    Sched.UpdateScheduleVals(self.state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    var _1: Bool = ErrorsFound
    DataZoneEquipment.GetZoneEquipmentData(self.state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(self.state)
    self.state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    Fans.GetFanInput(self.state)
    self.state.dataFans.GetFanInputFlag = False
    PoweredInductionUnits.GetPIUs(self.state)
    var error_string: String = delimited_string(
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSOFF",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSON",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
    )
    var _2: Bool = compare_err_stream(error_string)
    self.state.dataHeatBalFanSys.TempControlType.allocate(1)
    self.state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.DualHeatCool
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    var ZoneNum: Int = 1
    var SysNum: Int = 1
    var ZoneNodeNum: Int = 1
    var SecNodeNum: Int = self.state.dataPowerInductionUnits.PIU[SysNum].SecAirInNode
    var PriNodeNum: Int = self.state.dataPowerInductionUnits.PIU[SysNum].PriAirInNode
    var FirstHVACIteration: Bool = True
    self.state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    PoweredInductionUnits.InitPIU(self.state, SysNum, FirstHVACIteration)
    self.state.dataFans.fans[1].init(self.state)
    self.state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    var SecMaxMassFlow: Float64 = self.state.dataPowerInductionUnits.PIU[SysNum].MaxTotAirMassFlow
    var PriMaxMassFlow: Float64 = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow
    var PriMinMassFlow: Float64 = self.state.dataPowerInductionUnits.PIU[SysNum].MaxPriAirMassFlow * self.state.dataPowerInductionUnits.PIU[SysNum].MinPriAirFlowFrac
    var SecMassFlowAtPrimMin: Float64 = self.state.dataPowerInductionUnits.PIU[SysNum].MaxTotAirMassFlow - PriMinMassFlow
    var SecMassFlowAtPrimMax: Float64 = self.state.dataPowerInductionUnits.PIU[SysNum].MaxTotAirMassFlow - PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = False
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _3: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == 0.0
    var _4: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _5: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMaxMassFlow
    var _6: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = -2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _7: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == 0.0
    var _8: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = -2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _9: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == 0.0
    var _10: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _11: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMaxMassFlow
    var _12: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 0.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMinMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = True
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _13: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMassFlowAtPrimMin
    var _14: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 1.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMinMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _15: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMassFlowAtPrimMin
    var _16: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 1.0
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMaxMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = -2000.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    self.state.dataHVACGlobal.TurnFansOn = True
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _17: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMassFlowAtPrimMax
    var _18: Bool = self.state.dataPowerInductionUnits.PIU[SysNum].PriDamperPosition == 1.0
    self.state.dataHeatBalFanSys.TempControlType.deallocate()
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.deallocate()
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.deallocate()

def PIUArrayOutOfBounds(self: EnergyPlusFixture):
    self.state.dataPowerInductionUnits.NumSeriesPIUs = 1
    self.state.dataPowerInductionUnits.NumPIUs = 1
    self.state.dataPowerInductionUnits.PIU.allocate(1)
    var PIUNum: Int = 1
    self.state.dataPowerInductionUnits.PIU[PIUNum].Name = "Series PIU"
    self.state.dataPowerInductionUnits.PIU[PIUNum].UnitType_Num = DataDefineEquip.ZnAirLoopEquipType.SingleDuct_SeriesPIU_Reheat
    self.state.dataPowerInductionUnits.PIU[PIUNum].heatCoilType = HVAC.CoilType.HeatingElectric
    self.state.dataPowerInductionUnits.PIU[PIUNum].MaxPriAirVolFlow = AutoSize
    self.state.dataPowerInductionUnits.PIU[PIUNum].MaxTotAirVolFlow = AutoSize
    self.state.dataPowerInductionUnits.PIU[PIUNum].MaxSecAirVolFlow = AutoSize
    self.state.dataPowerInductionUnits.PIU[PIUNum].MinPriAirFlowFrac = AutoSize
    self.state.dataPowerInductionUnits.PIU[PIUNum].FanOnFlowFrac = AutoSize
    self.state.dataPowerInductionUnits.PIU[PIUNum].MaxVolHotWaterFlow = AutoSize
    self.state.dataPowerInductionUnits.PIU[PIUNum].MaxVolHotSteamFlow = AutoSize
    self.state.dataSize.CurSysNum = 0
    self.state.dataSize.SysSizingRunDone = False
    self.state.dataSize.ZoneSizingRunDone = True
    self.state.dataSize.CurZoneEqNum = 2
    self.state.dataSize.FinalZoneSizing.allocate(2)
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum].DesCoolVolFlow = 2.0
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum].DesHeatVolFlow = 1.0
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum].DesHeatCoilInTempTU = 10.0
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum].ZoneTempAtHeatPeak = 21.0
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum].DesHeatCoilInHumRatTU = 0.006
    self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum].ZoneHumRatAtHeatPeak = 0.008
    self.state.dataSize.CurTermUnitSizingNum = 1
    self.state.dataSize.TermUnitSizing.allocate(1)
    self.state.dataSize.TermUnitFinalZoneSizing.allocate(1)
    self.state.dataSize.TermUnitSizing[self.state.dataSize.CurTermUnitSizingNum].AirVolFlow = 1.0
    self.state.dataSize.TermUnitSizing[self.state.dataSize.CurTermUnitSizingNum].MinPriFlowFrac = 0.5
    self.state.dataSize.TermUnitSingDuct = True
    self.state.dataSize.TermUnitFinalZoneSizing[self.state.dataSize.CurTermUnitSizingNum].copyFromZoneSizing(self.state.dataSize.FinalZoneSizing[self.state.dataSize.CurZoneEqNum])
    PoweredInductionUnits.SizePIU(self.state, PIUNum)
    var _: Bool = compare_err_stream("")

def SeriesPIUZoneOAVolumeFlowRateTest(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Zone,",
        "  SPACE2-1;                !- Name",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE2-1,                !- Zone Name",
        "  SPACE2-1 Equipment,      !- Zone Conditioning Equipment List Name",
        "  SPACE2-1 In Node,        !- Zone Air Inlet Node or NodeList Name",
        "  SPACE2-1 ATU Sec Node,   !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE2-1 Air Node,       !- Zone Air Node Name",
        "  SPACE2-1 Return Node;    !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  SPACE2-1 Equipment,      !- Name",
        "  SequentialLoad,          !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,  !- Zone Equipment 1 Object Type",
        "  SPACE2-1 ADU,            !- Zone Equipment 1 Name",
        "  1,                       !- Zone Equipment 1 Cooling Sequence",
        "  1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:AirDistributionUnit,",
        "  SPACE2-1 ADU,            !- Name",
        "  SPACE2-1 In Node,        !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:SeriesPIU:Reheat,  !- Air Terminal Object Type",
        "  SPACE2-1 Series PIU Reheat;           !- Air Terminal Name",
        "AirTerminal:SingleDuct:SeriesPIU:Reheat,",
        "  SPACE2-1 Series PIU Reheat,     !- Name",
        "  ,                        !- Availability Schedule Name",
        "  0.15,                    !- Maximum Air Flow Rate {m3/s}",
        "  0.05,                    !- Maximum Primary Air Flow Rate {m3/s}",
        "  0.2,                     !- Minimum Primary Air Flow Fraction",
        "  SPACE2-1 ATU In Node,    !- Supply Air Inlet Node Name",
        "  SPACE2-1 ATU Sec Node,   !- Secondary Air Inlet Node Name",
        "  SPACE2-1 In Node,        !- Outlet Node Name",
        "  SPACE2-1 PIU Mixer,      !- Zone Mixer Name",
        "  SPACE2-1 PIU Fan,        !- Fan Name",
        "  Coil:Heating:Electric,      !- Reheat Coil Object Type",
        "  SPACE2-1 Zone Coil,      !- Reheat Coil Name",
        "  0.0,                     !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0,                     !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0001;                  !- Convergence Tolerance",
        "Fan:ConstantVolume,",
        "  SPACE2-1 PIU Fan,        !- Name",
        "  ,                        !- Availability Schedule Name",
        "  0.5,                     !- Fan Total Efficiency",
        "  50.0,                    !- Pressure Rise {Pa}",
        "  0.05,                    !- Maximum Flow Rate {m3/s}",
        "  0.9,                     !- Motor Efficiency",
        "  1.0,                     !- Motor In Airstream Fraction",
        "  SPACE2-1 ATU Fan Inlet Node,   !- Air Inlet Node Name",
        "  SPACE2-1 Zone Coil Air In Node;  !- Air Outlet Node Name",
        "AirLoopHVAC:ZoneMixer,",
        "  SPACE2-1 PIU Mixer,      !- Name",
        "  SPACE2-1 ATU Fan Inlet Node,  !- Outlet Node Name",
        "  SPACE2-1 ATU In Node,    !- Inlet 1 Node Name",
        "  SPACE2-1 ATU Sec Node;   !- Inlet 2 Node Name",
        "Coil:Heating:Electric,",
        "  SPACE2-1 Zone Coil,      !- Name",
        "  ,                        !- Availability Schedule Name",
        "  1.0,                     !- Efficiency",
        "  2000,                    !- Nominal Capacity",
        "  SPACE2-1 Zone Coil Air In Node,  !- Air Inlet Node Name",
        "  SPACE2-1 In Node;        !- Air Outlet Node Name",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
    Sched.UpdateScheduleVals(self.state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    var _1: Bool = ErrorsFound
    DataZoneEquipment.GetZoneEquipmentData(self.state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(self.state)
    self.state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    Fans.GetFanInput(self.state)
    self.state.dataFans.GetFanInputFlag = False
    PoweredInductionUnits.GetPIUs(self.state)
    var _2: Bool = compare_err_stream("")
    self.state.dataHeatBalFanSys.TempControlType.allocate(1)
    self.state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.DualHeatCool
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    var ZoneNum: Int = 1
    var PIUNum: Int = 1
    var ZoneNodeNum: Int = 1
    var thisSeriesAT = self.state.dataPowerInductionUnits.PIU[PIUNum]
    var SecNodeNum: Int = thisSeriesAT.SecAirInNode
    var PriNodeNum: Int = thisSeriesAT.PriAirInNode
    var FirstHVACIteration: Bool = True
    self.state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    PoweredInductionUnits.InitPIU(self.state, PIUNum, FirstHVACIteration)
    self.state.dataFans.fans[1].init(self.state)
    self.state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    self.state.dataHVACGlobal.TurnFansOn = True
    var SecMaxMassFlow: Float64 = thisSeriesAT.MaxTotAirMassFlow
    var PriMaxMassFlow: Float64 = thisSeriesAT.MaxPriAirMassFlow
    var PriMinMassFlow: Float64 = thisSeriesAT.MaxPriAirMassFlow * thisSeriesAT.MinPriAirFlowFrac
    var SecMassFlowAtPrimMin: Float64 = thisSeriesAT.MaxTotAirMassFlow - PriMinMassFlow
    var SecMassFlowAtPrimMax: Float64 = thisSeriesAT.MaxTotAirMassFlow - PriMaxMassFlow
    var AirLoopOAFraction: Float64 = 0.20
    thisSeriesAT.AirLoopNum = 1
    self.state.dataAirLoop.AirLoopFlow.allocate(1)
    self.state.dataAirLoop.AirLoopFlow[thisSeriesAT.AirLoopNum].OAFrac = AirLoopOAFraction
    self.state.dataZoneEquip.ZoneEquipConfig[thisSeriesAT.CtrlZoneNum].InletNodeAirLoopNum[thisSeriesAT.ctrlZoneInNodeIndex] = 1
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 20.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.005
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = self.state.dataLoopNodes.Node[ZoneNodeNum].Temp
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 5.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.006
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    PoweredInductionUnits.CalcSeriesPIU(self.state, PIUNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    PoweredInductionUnits.ReportPIU(self.state, PIUNum)
    var expect_OutdoorAirFlowRate: Float64 = (0.0 / self.state.dataEnvrn.StdRhoAir) * AirLoopOAFraction
    var _3: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMaxMassFlow
    var _4: Bool = self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate == 0.0
    var _5: Bool = thisSeriesAT.OutdoorAirFlowRate == expect_OutdoorAirFlowRate
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMinMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = 2000.0
    PoweredInductionUnits.CalcSeriesPIU(self.state, PIUNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    PoweredInductionUnits.ReportPIU(self.state, PIUNum)
    expect_OutdoorAirFlowRate = (PriMinMassFlow / self.state.dataEnvrn.StdRhoAir) * AirLoopOAFraction
    var _6: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMassFlowAtPrimMin
    var _7: Bool = self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate == PriMinMassFlow
    var _8: Bool = thisSeriesAT.OutdoorAirFlowRate == expect_OutdoorAirFlowRate
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 24.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.0080
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = self.state.dataLoopNodes.Node[ZoneNodeNum].Temp
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.0075
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMaxMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].RemainingOutputRequired = -3000.0
    PoweredInductionUnits.CalcSeriesPIU(self.state, PIUNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    PoweredInductionUnits.ReportPIU(self.state, PIUNum)
    expect_OutdoorAirFlowRate = (PriMaxMassFlow / self.state.dataEnvrn.StdRhoAir) * AirLoopOAFraction
    var _9: Bool = self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRate == SecMassFlowAtPrimMax
    var _10: Bool = self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate == PriMaxMassFlow
    var _11: Bool = thisSeriesAT.OutdoorAirFlowRate == expect_OutdoorAirFlowRate

def PIU_InducedAir_Plenums(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Timestep,",
        "  4;                                      !- Number of Timesteps per Hour",
        "ScheduleTypeLimits,",
        "  Any Number;                             !- Name",
        "Building,",
        "  Building 1,                             !- Name",
        "  0,                                      !- North Axis {deg}",
        "  ,                                       !- Terrain",
        "  ,                                       !- Loads Convergence Tolerance Value {W}",
        "  ,                                       !- Temperature Convergence Tolerance Value {deltaC}",
        "  ,                                       !- Solar Distribution",
        "  ,                                       !- Maximum Number of Warmup Days",
        "  ;                                       !- Minimum Number of Warmup Days",
        "Zone,",
        "  ReturnPlenum,                           !- Name",
        "  0,                                      !- Direction of Relative North {deg}",
        "  0,                                      !- X Origin {m}",
        "  0,                                      !- Y Origin {m}",
        "  0,                                      !- Z Origin {m}",
        "  ,                                       !- Type",
        "  1,                                      !- Multiplier",
        "  ,                                       !- Ceiling Height {m}",
        "  ,                                       !- Volume {m3}",
        "  ,                                       !- Floor Area {m2}",
        "  ,                                       !- Zone Inside Convection Algorithm",
        "  ,                                       !- Zone Outside Convection Algorithm",
        "  No;                                     !- Part of Total Floor Area",
        "BuildingSurface:Detailed,",
        "  FLOOR 2,                                !- Name",
        "  Floor,                                  !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  ReturnPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Ground,                                 !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  NoSun,                                  !- Sun Exposure",
        "  NoWind,                                 !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 0, 2.5,                              !- X,Y,Z Vertex 1 {m}",
        "  0, 10, 2.5,                             !- X,Y,Z Vertex 2 {m}",
        "  20, 10, 2.5,                            !- X,Y,Z Vertex 3 {m}",
        "  20, 0, 2.5;                             !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  RETURNPLENUM - 1-SOUTH,                 !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  ReturnPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 0, 3,                                !- X,Y,Z Vertex 1 {m}",
        "  0, 0, 2.5,                              !- X,Y,Z Vertex 2 {m}",
        "  20, 0, 2.5,                             !- X,Y,Z Vertex 3 {m}",
        "  20, 0, 3;                               !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  RETURNPLENUM - 2-WEST,                  !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  ReturnPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 10, 3,                               !- X,Y,Z Vertex 1 {m}",
        "  0, 10, 2.5,                             !- X,Y,Z Vertex 2 {m}",
        "  0, 0, 2.5,                              !- X,Y,Z Vertex 3 {m}",
        "  0, 0, 3;                                !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  RETURNPLENUM - 3-EAST,                  !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  ReturnPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 0, 3,                               !- X,Y,Z Vertex 1 {m}",
        "  20, 0, 2.5,                             !- X,Y,Z Vertex 2 {m}",
        "  20, 10, 2.5,                            !- X,Y,Z Vertex 3 {m}",
        "  20, 10, 3;                              !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  RETURNPLENUM - 4-NORTH,                 !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  ReturnPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 10, 3,                              !- X,Y,Z Vertex 1 {m}",
        "  20, 10, 2.5,                            !- X,Y,Z Vertex 2 {m}",
        "  0, 10, 2.5,                             !- X,Y,Z Vertex 3 {m}",
        "  0, 10, 3;                               !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  ROOF 2,                                 !- Name",
        "  Roof,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  ReturnPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 0, 3,                               !- X,Y,Z Vertex 1 {m}",
        "  20, 10, 3,                              !- X,Y,Z Vertex 2 {m}",
        "  0, 10, 3,                               !- X,Y,Z Vertex 3 {m}",
        "  0, 0, 3;                                !- X,Y,Z Vertex 4 {m}",
        "Zone,",
        "  SupplyPlenum,                           !- Name",
        "  0,                                      !- Direction of Relative North {deg}",
        "  0,                                      !- X Origin {m}",
        "  0,                                      !- Y Origin {m}",
        "  0,                                      !- Z Origin {m}",
        "  ,                                       !- Type",
        "  1,                                      !- Multiplier",
        "  ,                                       !- Ceiling Height {m}",
        "  ,                                       !- Volume {m3}",
        "  ,                                       !- Floor Area {m2}",
        "  ,                                       !- Zone Inside Convection Algorithm",
        "  ,                                       !- Zone Outside Convection Algorithm",
        "  No;                                     !- Part of Total Floor Area",
        "BuildingSurface:Detailed,",
        "  FLOOR,                                  !- Name",
        "  Floor,                                  !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  SupplyPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Ground,                                 !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  NoSun,                                  !- Sun Exposure",
        "  NoWind,                                 !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 0, 3,                                !- X,Y,Z Vertex 1 {m}",
        "  0, 10, 3,                               !- X,Y,Z Vertex 2 {m}",
        "  20, 10, 3,                              !- X,Y,Z Vertex 3 {m}",
        "  20, 0, 3;                               !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  ROOF,                                   !- Name",
        "  Roof,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  SupplyPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 0, 3.5,                             !- X,Y,Z Vertex 1 {m}",
        "  20, 10, 3.5,                            !- X,Y,Z Vertex 2 {m}",
        "  0, 10, 3.5,                             !- X,Y,Z Vertex 3 {m}",
        "  0, 0, 3.5;                              !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  SUPPLYPLENUM - 1-SOUTH,                 !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  SupplyPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 0, 3.5,                              !- X,Y,Z Vertex 1 {m}",
        "  0, 0, 3,                                !- X,Y,Z Vertex 2 {m}",
        "  20, 0, 3,                               !- X,Y,Z Vertex 3 {m}",
        "  20, 0, 3.5;                             !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  SUPPLYPLENUM - 2-WEST,                  !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  SupplyPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 10, 3.5,                             !- X,Y,Z Vertex 1 {m}",
        "  0, 10, 3,                               !- X,Y,Z Vertex 2 {m}",
        "  0, 0, 3,                                !- X,Y,Z Vertex 3 {m}",
        "  0, 0, 3.5;                              !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  SUPPLYPLENUM - 3-EAST,                  !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  SupplyPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 0, 3.5,                             !- X,Y,Z Vertex 1 {m}",
        "  20, 0, 3,                               !- X,Y,Z Vertex 2 {m}",
        "  20, 10, 3,                              !- X,Y,Z Vertex 3 {m}",
        "  20, 10, 3.5;                            !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  SUPPLYPLENUM - 4-NORTH,                 !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  SupplyPlenum,                           !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 10, 3.5,                            !- X,Y,Z Vertex 1 {m}",
        "  20, 10, 3,                              !- X,Y,Z Vertex 2 {m}",
        "  0, 10, 3,                               !- X,Y,Z Vertex 3 {m}",
        "  0, 10, 3.5;                             !- X,Y,Z Vertex 4 {m}",
        "Zone,",
        "  Zone1,                                  !- Name",
        "  0,                                      !- Direction of Relative North {deg}",
        "  0,                                      !- X Origin {m}",
        "  0,                                      !- Y Origin {m}",
        "  0,                                      !- Z Origin {m}",
        "  ,                                       !- Type",
        "  1,                                      !- Multiplier",
        "  ,                                       !- Ceiling Height {m}",
        "  ,                                       !- Volume {m3}",
        "  ,                                       !- Floor Area {m2}",
        "  ,                                       !- Zone Inside Convection Algorithm",
        "  ,                                       !- Zone Outside Convection Algorithm",
        "  Yes;                                    !- Part of Total Floor Area",
        "BuildingSurface:Detailed,",
        "  FLOOR 1,                                !- Name",
        "  Floor,                                  !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  Zone1,                                  !- Zone Name",
        "  ,                                       !- Space Name",
        "  Ground,                                 !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  NoSun,                                  !- Sun Exposure",
        "  NoWind,                                 !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 0, 0,                                !- X,Y,Z Vertex 1 {m}",
        "  0, 10, 0,                               !- X,Y,Z Vertex 2 {m}",
        "  20, 10, 0,                              !- X,Y,Z Vertex 3 {m}",
        "  20, 0, 0;                               !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  ROOF 1,                                 !- Name",
        "  Roof,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  Zone1,                                  !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 0, 2.5,                             !- X,Y,Z Vertex 1 {m}",
        "  20, 10, 2.5,                            !- X,Y,Z Vertex 2 {m}",
        "  0, 10, 2.5,                             !- X,Y,Z Vertex 3 {m}",
        "  0, 0, 2.5;                              !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  ZONE1 - 1-SOUTH,                        !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  Zone1,                                  !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 0, 2.5,                              !- X,Y,Z Vertex 1 {m}",
        "  0, 0, 0,                                !- X,Y,Z Vertex 2 {m}",
        "  20, 0, 0,                               !- X,Y,Z Vertex 3 {m}",
        "  20, 0, 2.5;                             !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  ZONE1 - 2-WEST,                         !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  Zone1,                                  !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 10, 2.5,                             !- X,Y,Z Vertex 1 {m}",
        "  0, 10, 0,                               !- X,Y,Z Vertex 2 {m}",
        "  0, 0, 0,                                !- X,Y,Z Vertex 3 {m}",
        "  0, 0, 2.5;                              !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  ZONE1 - 3-EAST,                         !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  Zone1,                                  !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 0, 2.5,                             !- X,Y,Z Vertex 1 {m}",
        "  20, 0, 0,                               !- X,Y,Z Vertex 2 {m}",
        "  20, 10, 0,                              !- X,Y,Z Vertex 3 {m}",
        "  20, 10, 2.5;                            !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  ZONE1 - 4-NORTH,                        !- Name",
        "  Wall,                                   !- Surface Type",
        "  R13 Construction,                       !- Construction Name",
        "  Zone1,                                  !- Zone Name",
        "  ,                                       !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  20, 10, 2.5,                            !- X,Y,Z Vertex 1 {m}",
        "  20, 10, 0,                              !- X,Y,Z Vertex 2 {m}",
        "  0, 10, 0,                               !- X,Y,Z Vertex 3 {m}",
        "  0, 10, 2.5;                             !- X,Y,Z Vertex 4 {m}",
        "ZoneControl:Thermostat,",
        "  Zone1 Thermostat,                       !- Name",
        "  Zone1,                                  !- Zone or ZoneList Name",
        "  Zone1 Thermostat Schedule,              !- Control Type Schedule Name",
        "  ThermostatSetpoint:DualSetpoint,        !- Control 1 Object Type",
        "  Thermostat Setpoint Dual Setpoint 2,    !- Control 1 Name",
        "  ,                                       !- Control 2 Object Type",
        "  ,                                       !- Control 2 Name",
        "  ,                                       !- Control 3 Object Type",
        "  ,                                       !- Control 3 Name",
        "  ,                                       !- Control 4 Object Type",
        "  ,                                       !- Control 4 Name",
        "  0;                                      !- Temperature Difference Between Cutout And Setpoint {deltaC}",
        "Schedule:Compact,",
        "  Zone1 Thermostat Schedule,              !- Name",
        "  Zone1 Thermostat Schedule Type Limits,  !- Schedule Type Limits Name",
        "  Through: 12/31,                         !- Field 1",
        "  For: AllDays,                           !- Field 2",
        "  Until: 24:00,                           !- Field 3",
        "  4;                                      !- Field 4",
        "ScheduleTypeLimits,",
        "  Zone1 Thermostat Schedule Type Limits,  !- Name",
        "  0,                                      !- Lower Limit Value {BasedOnField A3}",
        "  4,                                      !- Upper Limit Value {BasedOnField A3}",
        "  DISCRETE;                               !- Numeric Type",
        "ThermostatSetpoint:DualSetpoint,",
        "  Thermostat Setpoint Dual Setpoint 2,    !- Name",
        "  Schedule Constant 14,                   !- Heating Setpoint Temperature Schedule Name",
        "  Schedule Constant 13;                   !- Cooling Setpoint Temperature Schedule Name",
        "Schedule:Constant,",
        "  Schedule Constant 14,                   !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  19;                                     !- Hourly Value",
        "Schedule:Constant,",
        "  Schedule Constant 13,                   !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  26;                                     !- Hourly Value",
        "ZoneHVAC:EquipmentConnections,",
        "  Zone1,                                  !- Zone Name",
        "  Zone1 Equipment List,                   !- Zone Conditioning Equipment List Name",
        "  Zone1 Inlet Node List,                  !- Zone Air Inlet Node or NodeList Name",
        "  Zone1 Exhaust Node List,                !- Zone Air Exhaust Node or NodeList Name",
        "  Zone1 Zone Air Node,                    !- Zone Air Node Name",
        "  Zone1 Return Node List;                 !- Zone Return Air Node or NodeList Name",
        "NodeList,",
        "  Zone1 Inlet Node List,                  !- Name",
        "  SeriesPIU Outlet Node;                  !- Node Name 1",
        "NodeList,",
        "  Zone1 Exhaust Node List,                !- Name",
        "  SeriesPIU Secondary Air Inlet Node;     !- Node Name 1",
        "NodeList,",
        "  Zone1 Return Node List,                 !- Name",
        "  Zone1 Return Air Node;                  !- Node Name 1",
        "ZoneHVAC:AirDistributionUnit,",
        "  Air Terminal Single Duct Series PIU Reheat 1 Air Distribution Unit, !- Name",
        "  SeriesPIU Outlet Node,                  !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:SeriesPIU:Reheat, !- Air Terminal Object Type",
        "  Air Terminal Single Duct Series PIU Reheat 1; !- Air Terminal Name",
        "AirTerminal:SingleDuct:SeriesPIU:Reheat,",
        "  Air Terminal Single Duct Series PIU Reheat 1, !- Name",
        "  ,                                       !- Availability Schedule Name",
        "  Autosize,                               !- Maximum Air Flow Rate {m3/s}",
        "  Autosize,                               !- Maximum Primary Air Flow Rate {m3/s}",
        "  Autosize,                               !- Minimum Primary Air Flow Fraction",
        "  SeriesPIU Supply Air Inlet Node,        !- Supply Air Inlet Node Name",
        "  SeriesPIU Secondary Air Inlet Node,     !- Secondary Air Inlet Node Name",
        "  SeriesPIU Outlet Node,                  !- Outlet Node Name",
        "  Air Terminal Single Duct Series PIU Reheat 1 Mixer, !- Zone Mixer Name",
        "  Fan System Model 1,                     !- Fan Name",
        "  Coil:Heating:Electric,                  !- Reheat Coil Object Type",
        "  Coil Heating Electric 2,                !- Reheat Coil Name",
        "  Autosize,                               !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0,                                      !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.001;                                  !- Convergence Tolerance",
        "Coil:Heating:Electric,",
        "  Coil Heating Electric 2,                !- Name",
        "  Always On Discrete,                     !- Availability Schedule Name",
        "  1,                                      !- Efficiency",
        "  Autosize,                               !- Nominal Capacity {W}",
        "  Air Terminal Single Duct Series PIU Reheat 1 Fan Outlet, !- Air Inlet Node Name",
        "  SeriesPIU Outlet Node;                  !- Air Outlet Node Name",
        "Schedule:Constant,",
        "  Always On Discrete,                     !- Name",
        "  OnOff,                                  !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
        "Fan:SystemModel,",
        "  Fan System Model 1,                     !- Name",
        "  Always On Discrete,                     !- Availability Schedule Name",
        "  Air Terminal Single Duct Series PIU Reheat 1 Mixer Outlet, !- Air Inlet Node Name",
        "  Air Terminal Single Duct Series PIU Reheat 1 Fan Outlet, !- Air Outlet Node Name",
        "  Autosize,                               !- Design Maximum Air Flow Rate {m3/s}",
        "  Discrete,                               !- Speed Control Method",
        "  0.2,                                    !- Electric Power Minimum Flow Rate Fraction",
        "  500,                                    !- Design Pressure Rise {Pa}",
        "  0.9,                                    !- Motor Efficiency",
        "  1,                                      !- Motor In Air Stream Fraction",
        "  Autosize,                               !- Design Electric Power Consumption {W}",
        "  PowerPerFlowPerPressure,                !- Design Power Sizing Method",
        "  840,                                    !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "  1.66667,                                !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "  0.7,                                    !- Fan Total Efficiency",
        "  ,                                       !- Electric Power Function of Flow Fraction Curve Name",
        "  ,                                       !- Night Ventilation Mode Pressure Rise {Pa}",
        "  ,                                       !- Night Ventilation Mode Flow Fraction",
        "  ,                                       !- Motor Loss Zone Name",
        "  0,                                      !- Motor Loss Radiative Fraction",
        "  General,                                !- End-Use Subcategory",
        "  1;                                      !- Number of Speeds",
        "AirLoopHVAC:ZoneMixer,",
        "  Air Terminal Single Duct Series PIU Reheat 1 Mixer, !- Name",
        "  Air Terminal Single Duct Series PIU Reheat 1 Mixer Outlet, !- Outlet Node Name",
        "  SeriesPIU Secondary Air Inlet Node,     !- Inlet Node Name 1",
        "  SeriesPIU Supply Air Inlet Node;        !- Inlet Node Name 2",
        "ZoneHVAC:EquipmentList,",
        "  Zone1 Equipment List,                   !- Name",
        "  SequentialLoad,                         !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,           !- Zone Equipment Object Type 1",
        "  Air Terminal Single Duct Series PIU Reheat 1 Air Distribution Unit, !- Zone Equipment Name 1",
        "  1,                                      !- Zone Equipment Cooling Sequence 1",
        "  1,                                      !- Zone Equipment Heating or No-Load Sequence 1",
        "  ,                                       !- Zone Equipment Sequential Cooling Fraction Schedule Name 1",
        "  ;                                       !- Zone Equipment Sequential Heating Fraction Schedule Name 1",
        "Sizing:Zone,",
        "  Zone1,                                  !- Zone or ZoneList Name",
        "  SupplyAirTemperature,                   !- Zone Cooling Design Supply Air Temperature Input Method",
        "  14,                                     !- Zone Cooling Design Supply Air Temperature {C}",
        "  11.11,                                  !- Zone Cooling Design Supply Air Temperature Difference {deltaC}",
        "  SupplyAirTemperature,                   !- Zone Heating Design Supply Air Temperature Input Method",
        "  40,                                     !- Zone Heating Design Supply Air Temperature {C}",
        "  11.11,                                  !- Zone Heating Design Supply Air Temperature Difference {deltaC}",
        "  0.0085,                                 !- Zone Cooling Design Supply Air Humidity Ratio {kgWater/kgDryAir}",
        "  0.008,                                  !- Zone Heating Design Supply Air Humidity Ratio {kgWater/kgDryAir}",
        "  ,                                       !- Design Specification Outdoor Air Object Name",
        "  ,                                       !- Zone Heating Sizing Factor",
        "  ,                                       !- Zone Cooling Sizing Factor",
        "  DesignDay,                              !- Cooling Design Air Flow Method",
        "  0,                                      !- Cooling Design Air Flow Rate {m3/s}",
        "  0.000762,                               !- Cooling Minimum Air Flow per Zone Floor Area {m3/s-m2}",
        "  0,                                      !- Cooling Minimum Air Flow {m3/s}",
        "  0,                                      !- Cooling Minimum Air Flow Fraction",
        "  DesignDay,                              !- Heating Design Air Flow Method",
        "  0,                                      !- Heating Design Air Flow Rate {m3/s}",
        "  0.002032,                               !- Heating Maximum Air Flow per Zone Floor Area {m3/s-m2}",
        "  0.1415762,                              !- Heating Maximum Air Flow {m3/s}",
        "  0.3,                                    !- Heating Maximum Air Flow Fraction",
        "  ,                                       !- Design Specification Zone Air Distribution Object Name",
        "  No,                                     !- Account for Dedicated Outdoor Air System",
        "  ,                                       !- Dedicated Outdoor Air System Control Strategy",
        "  ,                                       !- Dedicated Outdoor Air Low Setpoint Temperature for Design {C}",
        "  ,                                       !- Dedicated Outdoor Air High Setpoint Temperature for Design {C}",
        "  Sensible Load Only No Latent Load,      !- Zone Load Sizing Method",
        "  HumidityRatioDifference,                !- Zone Latent Cooling Design Supply Air Humidity Ratio Input Method",
        "  ,                                       !- Zone Dehumidification Design Supply Air Humidity Ratio {kgWater/kgDryAir}",
        "  0.005,                                  !- Zone Cooling Design Supply Air Humidity Ratio Difference {kgWater/kgDryAir}",
        "  HumidityRatioDifference,                !- Zone Latent Heating Design Supply Air Humidity Ratio Input Method",
        "  ,                                       !- Zone Humidification Design Supply Air Humidity Ratio {kgWater/kgDryAir}",
        "  0.005;                                  !- Zone Humidification Design Supply Air Humidity Ratio Difference {kgWater/kgDryAir}",
        "Controller:MechanicalVentilation,",
        "  Controller Mechanical Ventilation 1,    !- Name",
        "  Always On Discrete,                     !- Availability Schedule Name",
        "  No,                                     !- Demand Controlled Ventilation",
        "  ZoneSum,                                !- System Outdoor Air Method",
        "  ,                                       !- Zone Maximum Outdoor Air Fraction {dimensionless}",
        "  Zone1,                                  !- Zone or ZoneList Name 1",
        "  ,                                       !- Design Specification Outdoor Air Object Name 1",
        "  ;                                       !- Design Specification Zone Air Distribution Object Name 1",
        "SimulationControl,",
        "  Yes,                                    !- Do Zone Sizing Calculation",
        "  Yes,                                    !- Do System Sizing Calculation",
        "  No,                                     !- Do Plant Sizing Calculation",
        "  Yes,                                    !- Run Simulation for Sizing Periods",
        "  No,                                     !- Run Simulation for Weather File Run Periods",
        "  ,                                       !- Do HVAC Sizing Simulation for Sizing Periods",
        "  ;                                       !- Maximum Number of HVAC Sizing Simulation Passes",
        "Sizing:Parameters,",
        "  1.25,                                   !- Heating Sizing Factor",
        "  1.15;                                   !- Cooling Sizing Factor",
        "RunPeriod,",
        "  Run Period 1,                           !- Name",
        "  1,                                      !- Begin Month",
        "  1,                                      !- Begin Day of Month",
        "  2009,                                   !- Begin Year",
        "  12,                                     !- End Month",
        "  31,                                     !- End Day of Month",
        "  2009,                                   !- End Year",
        "  Thursday,                               !- Day of Week for Start Day",
        "  No,                                     !- Use Weather File Holidays and Special Days",
        "  No,                                     !- Use Weather File Daylight Saving Period",
        "  No,                                     !- Apply Weekend Holiday Rule",
        "  Yes,                                    !- Use Weather File Rain Indicators",
        "  Yes;                                    !- Use Weather File Snow Indicators",
        "Output:Table:SummaryReports,",
        "  AllSummary;                             !- Report Name 1",
        "GlobalGeometryRules,",
        "  UpperLeftCorner,                        !- Starting Vertex Position",
        "  Counterclockwise,                       !- Vertex Entry Direction",
        "  Relative,                               !- Coordinate System",
        "  Relative,                               !- Daylighting Reference Point Coordinate System",
        "  Relative;                               !- Rectangular Surface Coordinate System",
        "Material:NoMass,",
        "  R13-IP,                                 !- Name",
        "  Smooth,                                 !- Roughness",
        "  2.28943238786998,                       !- Thermal Resistance {m2-K/W}",
        "  0.9,                                    !- Thermal Absorptance",
        "  0.7,                                    !- Solar Absorptance",
        "  0.7;                                    !- Visible Absorptance",
        "Material,",
        "  C5 - 4 IN HW CONCRETE,                  !- Name",
        "  MediumRough,                            !- Roughness",
        "  0.1014984,                              !- Thickness {m}",
        "  1.729577,                               !- Conductivity {W/m-K}",
        "  2242.585,                               !- Density {kg/m3}",
        "  836.8000,                               !- Specific Heat {J/kg-K}",
        "  0.9000000,                              !- Thermal Absorptance",
        "  0.6500000,                              !- Solar Absorptance",
        "  0.6500000;                              !- Visible Absorptance",
        "Construction,",
        "  R13 Construction,                       !- Name",
        "  R13-IP,                                 !- Layer 1",
        "  C5 - 4 IN HW CONCRETE;                  !- Layer 2",
        "ScheduleTypeLimits,",
        "  OnOff,                                  !- Name",
        "  0,                                      !- Lower Limit Value {BasedOnField A3}",
        "  1,                                      !- Upper Limit Value {BasedOnField A3}",
        "  Discrete,                               !- Numeric Type",
        "  availability;                           !- Unit Type",
        "ScheduleTypeLimits,",
        "  Temperature,                            !- Name",
        "  ,                                       !- Lower Limit Value {BasedOnField A3}",
        "  ,                                       !- Upper Limit Value {BasedOnField A3}",
        "  Continuous,                             !- Numeric Type",
        "  temperature;                            !- Unit Type",
        "  Schedule:Day:Interval,",
        "  Deck_Temperature_Default,               !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  No,                                     !- Interpolate to Timestep",
        "  24:00,                                  !- Time 1 {hh:mm}",
        "  12.8;                                   !- Value Until Time 1",
        "Schedule:Day:Interval,",
        "  Deck_Temperature_Summer_Design_Day,     !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  No,                                     !- Interpolate to Timestep",
        "  24:00,                                  !- Time 1 {hh:mm}",
        "  12.8;                                   !- Value Until Time 1",
        "Schedule:Day:Interval,",
        "  Deck_Temperature_Winter_Design_Day,     !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  No,                                     !- Interpolate to Timestep",
        "  24:00,                                  !- Time 1 {hh:mm}",
        "  12.8;                                   !- Value Until Time 1",
        "Schedule:Week:Daily,",
        "  Deck_Temperature Week Rule - Jan1-Dec31, !- Name",
        "  Deck_Temperature_Default,               !- Sunday Schedule:Day Name",
        "  Deck_Temperature_Default,               !- Monday Schedule:Day Name",
        "  Deck_Temperature_Default,               !- Tuesday Schedule:Day Name",
        "  Deck_Temperature_Default,               !- Wednesday Schedule:Day Name",
        "  Deck_Temperature_Default,               !- Thursday Schedule:Day Name",
        "  Deck_Temperature_Default,               !- Friday Schedule:Day Name",
        "  Deck_Temperature_Default,               !- Saturday Schedule:Day Name",
        "  Deck_Temperature_Default,               !- Holiday Schedule:Day Name",
        "  Deck_Temperature_Summer_Design_Day,     !- SummerDesignDay Schedule:Day Name",
        "  Deck_Temperature_Winter_Design_Day,     !- WinterDesignDay Schedule:Day Name",
        "  Deck_Temperature_Default,               !- CustomDay1 Schedule:Day Name",
        "  Deck_Temperature_Default;               !- CustomDay2 Schedule:Day Name",
        "Schedule:Year,",
        "  Deck_Temperature,                       !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  Deck_Temperature Week Rule - Jan1-Dec31, !- Schedule:Week Name 1",
        "  1,                                      !- Start Month 1",
        "  1,                                      !- Start Day 1",
        "  12,                                     !- End Month 1",
        "  31;                                     !- End Day 1",
        "Schedule:Constant,",
        "  Always Off Discrete,                    !- Name",
        "  OnOff,                                  !- Schedule Type Limits Name",
        "  0;                                      !- Hourly Value",
        "Schedule:Constant,",
        "  Always On Continuous,                   !- Name",
        "  Any Number,                             !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
        "OutdoorAir:Node,",
        "  Model Outdoor Air Node;                 !- Name",
        "AirLoopHVAC,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat, !- Name",
        "  ,                                       !- Controller List Name",
        "  Packaged Rooftop VAV with PFP Boxes and ReheatAvailability Manager List, !- Availability Manager List Name",
        "  AutoSize,                               !- Design Supply Air Flow Rate {m3/s}",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Supply Branches, !- Branch List Name",
        "  ,                                       !- Connector List Name",
        "  Node 1,                                 !- Supply Side Inlet Node Name",
        "  Node 4,                                 !- Demand Side Outlet Node Name",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Demand Inlet Nodes, !- Demand Side Inlet Node Names",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Supply Outlet Nodes, !- Supply Side Outlet Node Names",
        "  1;                                      !- Design Return Air Flow Fraction of Supply Air Flow",
        "NodeList,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Supply Outlet Nodes, !- Name",
        "  Node 2;                                 !- Node Name 1",
        "NodeList,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Demand Inlet Nodes, !- Name",
        "  Node 3;                                 !- Node Name 1",
        "Sizing:System,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat, !- AirLoop Name",
        "  Sensible,                               !- Type of Load to Size On",
        "  Autosize,                               !- Design Outdoor Air Flow Rate {m3/s}",
        "  0.3,                                    !- Central Heating Maximum System Air Flow Ratio",
        "  7,                                      !- Preheat Design Temperature {C}",
        "  0.008,                                  !- Preheat Design Humidity Ratio {kgWater/kgDryAir}",
        "  12.8,                                   !- Precool Design Temperature {C}",
        "  0.008,                                  !- Precool Design Humidity Ratio {kgWater/kgDryAir}",
        "  12.8,                                   !- Central Cooling Design Supply Air Temperature {C}",
        "  16.7,                                   !- Central Heating Design Supply Air Temperature {C}",
        "  NonCoincident,                          !- Type of Zone Sum to Use",
        "  Yes,                                    !- 100% Outdoor Air in Cooling",
        "  Yes,                                    !- 100% Outdoor Air in Heating",
        "  0.0085,                                 !- Central Cooling Design Supply Air Humidity Ratio {kgWater/kgDryAir}",
        "  0.008,                                  !- Central Heating Design Supply Air Humidity Ratio {kgWater/kgDryAir}",
        "  DesignDay,                              !- Cooling Supply Air Flow Rate Method",
        "  0,                                      !- Cooling Supply Air Flow Rate {m3/s}",
        "  0.0099676501,                           !- Cooling Supply Air Flow Rate Per Floor Area {m3/s-m2}",
        "  1,                                      !- Cooling Fraction of Autosized Cooling Supply Air Flow Rate",
        "  3.9475456e-05,                          !- Cooling Supply Air Flow Rate Per Unit Cooling Capacity {m3/s-W}",
        "  DesignDay,                              !- Heating Supply Air Flow Rate Method",
        "  0,                                      !- Heating Supply Air Flow Rate {m3/s}",
        "  0.0099676501,                           !- Heating Supply Air Flow Rate Per Floor Area {m3/s-m2}",
        "  1,                                      !- Heating Fraction of Autosized Heating Supply Air Flow Rate",
        "  1,                                      !- Heating Fraction of Autosized Cooling Supply Air Flow Rate",
        "  3.1588213e-05,                          !- Heating Supply Air Flow Rate Per Unit Heating Capacity {m3/s-W}",
        "  ZoneSum,                                !- System Outdoor Air Method",
        "  1,                                      !- Zone Maximum Outdoor Air Fraction {dimensionless}",
        "  CoolingDesignCapacity,                  !- Cooling Design Capacity Method",
        "  Autosize,                               !- Cooling Design Capacity {W}",
        "  234.7,                                  !- Cooling Design Capacity Per Floor Area {W/m2}",
        "  1,                                      !- Fraction of Autosized Cooling Design Capacity",
        "  HeatingDesignCapacity,                  !- Heating Design Capacity Method",
        "  Autosize,                               !- Heating Design Capacity {W}",
        "  157,                                    !- Heating Design Capacity Per Floor Area {W/m2}",
        "  1,                                      !- Fraction of Autosized Heating Design Capacity",
        "  OnOff,                                  !- Central Cooling Capacity Control Method",
        "  Autosize;                               !- Occupant Diversity",
        "AvailabilityManagerAssignmentList,",
        "  Packaged Rooftop VAV with PFP Boxes and ReheatAvailability Manager List, !- Name",
        "  AvailabilityManager:Scheduled,          !- Availability Manager Object Type 1",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Availability Manager; !- Availability Manager Name 1",
        "AvailabilityManager:Scheduled,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Availability Manager, !- Name",
        "  Always On Discrete;                     !- Schedule Name",
        "BranchList,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Supply Branches, !- Name",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Main Branch; !- Branch Name 1",
        "Branch,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Main Branch, !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  AirLoopHVAC:OutdoorAirSystem,           !- Component Object Type 1",
        "  Air Loop HVAC Outdoor Air System 1,     !- Component Name 1",
        "  Node 1,                                 !- Component Inlet Node Name 1",
        "  Node 8,                                 !- Component Outlet Node Name 1",
        "  CoilSystem:Cooling:DX,                  !- Component Object Type 2",
        "  Coil Cooling DX Two Speed 1 CoilSystem, !- Component Name 2",
        "  Node 8,                                 !- Component Inlet Node Name 2",
        "  Node 9,                                 !- Component Outlet Node Name 2",
        "  Coil:Heating:Electric,                  !- Component Object Type 3",
        "  Coil Heating Electric 1,                !- Component Name 3",
        "  Node 9,                                 !- Component Inlet Node Name 3",
        "  Node 10,                                !- Component Outlet Node Name 3",
        "  Fan:VariableVolume,                     !- Component Object Type 4",
        "  Fan Variable Volume 1,                  !- Component Name 4",
        "  Node 10,                                !- Component Inlet Node Name 4",
        "  Node 2;                                 !- Component Outlet Node Name 4",
        "AirLoopHVAC:OutdoorAirSystem,",
        "  Air Loop HVAC Outdoor Air System 1,     !- Name",
        "  Air Loop HVAC Outdoor Air System 1 Controller List, !- Controller List Name",
        "  Air Loop HVAC Outdoor Air System 1 Equipment List; !- Outdoor Air Equipment List Name",
        "AirLoopHVAC:ControllerList,",
        "  Air Loop HVAC Outdoor Air System 1 Controller List, !- Name",
        "  Controller:OutdoorAir,                  !- Controller Object Type 1",
        "  Controller Outdoor Air 1;               !- Controller Name 1",
        "Controller:OutdoorAir,",
        "  Controller Outdoor Air 1,               !- Name",
        "  Node 7,                                 !- Relief Air Outlet Node Name",
        "  Node 1,                                 !- Return Air Node Name",
        "  Node 8,                                 !- Mixed Air Node Name",
        "  Node 6,                                 !- Actuator Node Name",
        "  0,                                      !- Minimum Outdoor Air Flow Rate {m3/s}",
        "  Autosize,                               !- Maximum Outdoor Air Flow Rate {m3/s}",
        "  NoEconomizer,                           !- Economizer Control Type",
        "  ModulateFlow,                           !- Economizer Control Action Type",
        "  28,                                     !- Economizer Maximum Limit Dry-Bulb Temperature {C}",
        "  64000,                                  !- Economizer Maximum Limit Enthalpy {J/kg}",
        "  ,                                       !- Economizer Maximum Limit Dewpoint Temperature {C}",
        "  ,                                       !- Electronic Enthalpy Limit Curve Name",
        "  -100,                                   !- Economizer Minimum Limit Dry-Bulb Temperature {C}",
        "  NoLockout,                              !- Lockout Type",
        "  FixedMinimum,                           !- Minimum Limit Type",
        "  ,                                       !- Minimum Outdoor Air Schedule Name",
        "  ,                                       !- Minimum Fraction of Outdoor Air Schedule Name",
        "  ,                                       !- Maximum Fraction of Outdoor Air Schedule Name",
        "  Controller Mechanical Ventilation 1,    !- Mechanical Ventilation Controller Name",
        "  ,                                       !- Time of Day Economizer Control Schedule Name",
        "  No,                                     !- High Humidity Control",
        "  ,                                       !- Humidistat Control Zone Name",
        "  ,                                       !- High Humidity Outdoor Air Flow Ratio",
        "  Yes,                                    !- Control High Indoor Humidity Based on Outdoor Humidity Ratio",
        "  BypassWhenWithinEconomizerLimits;       !- Heat Recovery Bypass Control Type",
        "AvailabilityManagerAssignmentList,",
        "  Air Loop HVAC Outdoor Air System 1 Availability Manager List, !- Name",
        "  AvailabilityManager:Scheduled,          !- Availability Manager Object Type 1",
        "  Air Loop HVAC Outdoor Air System 1 Availability Manager; !- Availability Manager Name 1",
        "AvailabilityManager:Scheduled,",
        "  Air Loop HVAC Outdoor Air System 1 Availability Manager, !- Name",
        "  Always On Discrete;                     !- Schedule Name",
        "OutdoorAir:NodeList,",
        "  Node 6;                                 !- Node or NodeList Name 1",
        "AirLoopHVAC:OutdoorAirSystem:EquipmentList,",
        "  Air Loop HVAC Outdoor Air System 1 Equipment List, !- Name",
        "  OutdoorAir:Mixer,                       !- Component Object Type 1",
        "  Air Loop HVAC Outdoor Air System 1 Outdoor Air Mixer; !- Component Name 1",
        "OutdoorAir:Mixer,",
        "  Air Loop HVAC Outdoor Air System 1 Outdoor Air Mixer, !- Name",
        "  Node 8,                                 !- Mixed Air Node Name",
        "  Node 6,                                 !- Outdoor Air Stream Node Name",
        "  Node 7,                                 !- Relief Air Stream Node Name",
        "  Node 1;                                 !- Return Air Stream Node Name",
        "SetpointManager:MixedAir,",
        "  Node 8 OS Default SPM,                  !- Name",
        "  Temperature,                            !- Control Variable",
        "  Node 2,                                 !- Reference Setpoint Node Name",
        "  Node 10,                                !- Fan Inlet Node Name",
        "  Node 2,                                 !- Fan Outlet Node Name",
        "  Node 8;                                 !- Setpoint Node or NodeList Name",
        "CoilSystem:Cooling:DX,",
        "  Coil Cooling DX Two Speed 1 CoilSystem, !- Name",
        "  Always On Discrete,                     !- Availability Schedule Name",
        "  Node 8,                                 !- DX Cooling Coil System Inlet Node Name",
        "  Node 9,                                 !- DX Cooling Coil System Outlet Node Name",
        "  Node 9,                                 !- DX Cooling Coil System Sensor Node Name",
        "  Coil:Cooling:DX:TwoSpeed,               !- Cooling Coil Object Type",
        "  Coil Cooling DX Two Speed 1;            !- Cooling Coil Name",
        "Coil:Cooling:DX:TwoSpeed,",
        "  Coil Cooling DX Two Speed 1,            !- Name",
        "  Always On Discrete,                     !- Availability Schedule Name",
        "  Autosize,                               !- High Speed Gross Rated Total Cooling Capacity {W}",
        "  Autosize,                               !- High Speed Rated Sensible Heat Ratio",
        "  3,                                      !- High Speed Gross Rated Cooling COP {W/W}",
        "  Autosize,                               !- High Speed Rated Air Flow Rate {m3/s}",
        "    ,",
        "    ,",
        "  773.3,                                  !- Unit Internal Static Air Pressure {Pa}",
        "  Node 8,                                 !- Air Inlet Node Name",
        "  Node 9,                                 !- Air Outlet Node Name",
        "  Curve Biquadratic 1,                    !- Total Cooling Capacity Function of Temperature Curve Name",
        "  Curve Quadratic 1,                      !- Total Cooling Capacity Function of Flow Fraction Curve Name",
        "  Curve Biquadratic 2,                    !- Energy Input Ratio Function of Temperature Curve Name",
        "  Curve Quadratic 2,                      !- Energy Input Ratio Function of Flow Fraction Curve Name",
        "  Curve Quadratic 3,                      !- Part Load Fraction Correlation Curve Name",
        "  Autosize,                               !- Low Speed Gross Rated Total Cooling Capacity {W}",
        "  0.69,                                   !- Low Speed Gross Rated Sensible Heat Ratio",
        "  3,                                      !- Low Speed Gross Rated Cooling COP {W/W}",
        "  Autosize,                               !- Low Speed Rated Air Flow Rate {m3/s}",
        "    ,",
        "    ,",
        "  Curve Biquadratic 3,                    !- Low Speed Total Cooling Capacity Function of Temperature Curve Name",
        "  Curve Biquadratic 4,                    !- Low Speed Energy Input Ratio Function of Temperature Curve Name",
        "  ,                                       !- Condenser Air Inlet Node Name",
        "  AirCooled,                              !- Condenser Type",
        "  -25,                                    !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}",
        "  0.9,                                    !- High Speed Evaporative Condenser Effectiveness {dimensionless}",
        "  Autosize,                               !- High Speed Evaporative Condenser Air Flow Rate {m3/s}",
        "  Autosize,                               !- High Speed Evaporative Condenser Pump Rated Power Consumption {W}",
        "  0.9,                                    !- Low Speed Evaporative Condenser Effectiveness {dimensionless}",
        "  Autosize,                               !- Low Speed Evaporative Condenser Air Flow Rate {m3/s}",
        "  Autosize,                               !- Low Speed Evaporative Condenser Pump Rated Power Consumption {W}",
        "  ,                                       !- Supply Water Storage Tank Name",
        "  ,                                       !- Condensate Collection Water Storage Tank Name",
        "  0,                                      !- Basin Heater Capacity {W/K}",
        "  2;                                      !- Basin Heater Setpoint Temperature {C}",
        "SetpointManager:MixedAir,",
        "  Node 9 OS Default SPM,                  !- Name",
        "  Temperature,                            !- Control Variable",
        "  Node 2,                                 !- Reference Setpoint Node Name",
        "  Node 10,                                !- Fan Inlet Node Name",
        "  Node 2,                                 !- Fan Outlet Node Name",
        "  Node 9;                                 !- Setpoint Node or NodeList Name",
        "Curve:Biquadratic,",
        "  Curve Biquadratic 1,                    !- Name",
        "  0.42415,                                !- Coefficient1 Constant",
        "  0.04426,                                !- Coefficient2 x",
        "  -0.00042,                               !- Coefficient3 x**2",
        "  0.00333,                                !- Coefficient4 y",
        "  -8e-05,                                 !- Coefficient5 y**2",
        "  -0.00021,                               !- Coefficient6 x*y",
        "  17,                                     !- Minimum Value of x {BasedOnField A2}",
        "  22,                                     !- Maximum Value of x {BasedOnField A2}",
        "  13,                                     !- Minimum Value of y {BasedOnField A3}",
        "  46;                                     !- Maximum Value of y {BasedOnField A3}",
        "Curve:Quadratic,",
        "  Curve Quadratic 1,                      !- Name",
        "  0.77136,                                !- Coefficient1 Constant",
        "  0.34053,                                !- Coefficient2 x",
        "  -0.11088,                               !- Coefficient3 x**2",
        "  0.75918,                                !- Minimum Value of x {BasedOnField A2}",
        "  1.13877;                                !- Maximum Value of x {BasedOnField A2}",
        "Curve:Biquadratic,",
        "  Curve Biquadratic 2,                    !- Name",
        "  1.23649,                                !- Coefficient1 Constant",
        "  -0.02431,                               !- Coefficient2 x",
        "  0.00057,                                !- Coefficient3 x**2",
        "  -0.01434,                               !- Coefficient4 y",
        "  0.00063,                                !- Coefficient5 y**2",
        "  -0.00038,                               !- Coefficient6 x*y",
        "  17,                                     !- Minimum Value of x {BasedOnField A2}",
        "  22,                                     !- Maximum Value of x {BasedOnField A2}",
        "  13,                                     !- Minimum Value of y {BasedOnField A3}",
        "  46;                                     !- Maximum Value of y {BasedOnField A3}",
        "Curve:Quadratic,",
        "  Curve Quadratic 2,                      !- Name",
        "  1.2055,                                 !- Coefficient1 Constant",
        "  -0.32953,                               !- Coefficient2 x",
        "  0.12308,                                !- Coefficient3 x**2",
        "  0.75918,                                !- Minimum Value of x {BasedOnField A2}",
        "  1.13877;                                !- Maximum Value of x {BasedOnField A2}",
        "Curve:Quadratic,",
        "  Curve Quadratic 3,                      !- Name",
        "  0.771,                                  !- Coefficient1 Constant",
        "  0.229,                                  !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  0,                                      !- Minimum Value of x {BasedOnField A2}",
        "  1;                                      !- Maximum Value of x {BasedOnField A2}",
        "Curve:Biquadratic,",
        "  Curve Biquadratic 3,                    !- Name",
        "  0.42415,                                !- Coefficient1 Constant",
        "  0.04426,                                !- Coefficient2 x",
        "  -0.00042,                               !- Coefficient3 x**2",
        "  0.00333,                                !- Coefficient4 y",
        "  -8e-05,                                 !- Coefficient5 y**2",
        "  -0.00021,                               !- Coefficient6 x*y",
        "  17,                                     !- Minimum Value of x {BasedOnField A2}",
        "  22,                                     !- Maximum Value of x {BasedOnField A2}",
        "  13,                                     !- Minimum Value of y {BasedOnField A3}",
        "  46;                                     !- Maximum Value of y {BasedOnField A3}",
        "Curve:Biquadratic,",
        "  Curve Biquadratic 4,                    !- Name",
        "  1.23649,                                !- Coefficient1 Constant",
        "  -0.02431,                               !- Coefficient2 x",
        "  0.00057,                                !- Coefficient3 x**2",
        "  -0.01434,                               !- Coefficient4 y",
        "  0.00063,                                !- Coefficient5 y**2",
        "  -0.00038,                               !- Coefficient6 x*y",
        "  17,                                     !- Minimum Value of x {BasedOnField A2}",
        "  22,                                     !- Maximum Value of x {BasedOnField A2}",
        "  13,                                     !- Minimum Value of y {BasedOnField A3}",
        "  46;                                     !- Maximum Value of y {BasedOnField A3}",
        "Coil:Heating:Electric,",
        "  Coil Heating Electric 1,                !- Name",
        "  Always On Discrete,                     !- Availability Schedule Name",
        "  1,                                      !- Efficiency",
        "  Autosize,                               !- Nominal Capacity {W}",
        "  Node 9,                                 !- Air Inlet Node Name",
        "  Node 10,                                !- Air Outlet Node Name",
        "  Node 10;                                !- Temperature Setpoint Node Name",
        "SetpointManager:MixedAir,",
        "  Node 10 OS Default SPM,                 !- Name",
        "  Temperature,                            !- Control Variable",
        "  Node 2,                                 !- Reference Setpoint Node Name",
        "  Node 10,                                !- Fan Inlet Node Name",
        "  Node 2,                                 !- Fan Outlet Node Name",
        "  Node 10;                                !- Setpoint Node or NodeList Name",
        "Fan:VariableVolume,",
        "  Fan Variable Volume 1,                  !- Name",
        "  Always On Discrete,                     !- Availability Schedule Name",
        "  0.6045,                                 !- Fan Total Efficiency",
        "  500,                                    !- Pressure Rise {Pa}",
        "  AutoSize,                               !- Maximum Flow Rate {m3/s}",
        "  FixedFlowRate,                          !- Fan Power Minimum Flow Rate Input Method",
        "  0,                                      !- Fan Power Minimum Flow Fraction",
        "  0,                                      !- Fan Power Minimum Air Flow Rate {m3/s}",
        "  0.93,                                   !- Motor Efficiency",
        "  1,                                      !- Motor In Airstream Fraction",
        "  0.040759894,                            !- Fan Power Coefficient 1",
        "  0.08804497,                             !- Fan Power Coefficient 2",
        "  -0.07292612,                            !- Fan Power Coefficient 3",
        "  0.943739823,                            !- Fan Power Coefficient 4",
        "  0,                                      !- Fan Power Coefficient 5",
        "  Node 10,                                !- Air Inlet Node Name",
        "  Node 2,                                 !- Air Outlet Node Name",
        "  General;                                !- End-Use Subcategory",
        "SetpointManager:Scheduled,",
        "  Setpoint Manager Scheduled 1,           !- Name",
        "  Temperature,                            !- Control Variable",
        "  Deck_Temperature,                       !- Schedule Name",
        "  Node 2;                                 !- Setpoint Node or NodeList Name",
        "AirLoopHVAC:SupplyPath,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Node 3 Supply Path, !- Name",
        "  Node 3,                                 !- Supply Air Path Inlet Node Name",
        "  AirLoopHVAC:ZoneSplitter,               !- Component Object Type 1",
        "  Air Loop HVAC Zone Splitter 1,          !- Component Name 1",
        "  AirLoopHVAC:SupplyPlenum,               !- Component Object Type 2",
        "  Air Loop HVAC Supply Plenum 1;          !- Component Name 2",
        "AirLoopHVAC:ZoneSplitter,",
        "  Air Loop HVAC Zone Splitter 1,          !- Name",
        "  Node 3,                                 !- Inlet Node Name",
        "  Node 12;                                !- Outlet Node Name 1",
        "AirLoopHVAC:SupplyPlenum,",
        "  Air Loop HVAC Supply Plenum 1,          !- Name",
        "  SupplyPlenum,                           !- Zone Name",
        "  SupplyPlenum Zone Air Node,             !- Zone Node Name",
        "  Node 12,                                !- Inlet Node Name",
        "  SeriesPIU Supply Air Inlet Node;        !- Outlet Node Name 1",
        "AirLoopHVAC:ReturnPath,",
        "  Packaged Rooftop VAV with PFP Boxes and Reheat Return Path, !- Name",
        "  Node 4,                                 !- Return Air Path Outlet Node Name",
        "  AirLoopHVAC:ReturnPlenum,               !- Component Object Type 1",
        "  Air Loop HVAC Return Plenum 1,          !- Component Name 1",
        "  AirLoopHVAC:ZoneMixer,                  !- Component Object Type 2",
        "  Air Loop HVAC Zone Mixer 1;             !- Component Name 2",
        "AirLoopHVAC:ReturnPlenum,",
        "  Air Loop HVAC Return Plenum 1,          !- Name",
        "  ReturnPlenum,                           !- Zone Name",
        "  ReturnPlenum Zone Air Node,             !- Zone Node Name",
        "  Plenum Outlet Node,                     !- Outlet Node Name",
        "  SeriesPIU Secondary Air Inlet Node,     !- Induced Air Outlet Node or NodeList Name",
        "  Zone1 Return Air Node;                  !- Inlet Node Name 1",
        "AirLoopHVAC:ZoneMixer,",
        "  Air Loop HVAC Zone Mixer 1,             !- Name",
        "  Node 4,                                 !- Outlet Node Name",
        "  Plenum Outlet Node;                     !- Inlet Node Name 1",
        "Site:Location,",
        "  USA IL-CHICAGO-OHARE,                   !- Name",
        "  41.77,                                  !- Latitude {deg}",
        "  -87.75,                                 !- Longitude {deg}",
        "  -6.00,                                  !- Time Zone {hr}",
        "  190;                                    !- Elevation {m}",
        "SizingPeriod:DesignDay,",
        "  Chicago Ohare Intl Ap Ann Clg .4% Condns DB=>MWB, !- Name",
        "  7,                                      !- Month",
        "  21,                                     !- Day of Month",
        "  SummerDesignDay,                        !- Day Type",
        "  33.3,                                   !- Maximum Dry-Bulb Temperature {C}",
        "  10.5,                                   !- Daily Dry-Bulb Temperature Range {deltaC}",
        "  DefaultMultipliers,                     !- Dry-Bulb Temperature Range Modifier Type",
        "  ,                                       !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "  Wetbulb,                                !- Humidity Condition Type",
        "  23.7,                                   !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "  ,                                       !- Humidity Condition Day Schedule Name",
        "  ,                                       !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "  ,                                       !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "  ,                                       !- Daily Wet-Bulb Temperature Range {deltaC}",
        "  98934,                                  !- Barometric Pressure {Pa}",
        "  5.2,                                    !- Wind Speed {m/s}",
        "  230,                                    !- Wind Direction {deg}",
        "  No,                                     !- Rain Indicator",
        "  No,                                     !- Snow Indicator",
        "  No,                                     !- Daylight Saving Time Indicator",
        "  ASHRAETau,                              !- Solar Model Indicator",
        "  ,                                       !- Beam Solar Day Schedule Name",
        "  ,                                       !- Diffuse Solar Day Schedule Name",
        "  0.455,                                  !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "  2.05,                                   !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "  ,                                       !- Sky Clearness",
        "  ,                                       !- Maximum Number Warmup Days",
        "  FullResetAtBeginEnvironment;            !- Begin Environment Reset Mode",
        "SizingPeriod:DesignDay,",
        "  Chicago Ohare Intl Ap Ann Htg 99.6% Condns DB, !- Name",
        "  1,                                      !- Month",
        "  21,                                     !- Day of Month",
        "  WinterDesignDay,                        !- Day Type",
        "  -20,                                    !- Maximum Dry-Bulb Temperature {C}",
        "  0,                                      !- Daily Dry-Bulb Temperature Range {deltaC}",
        "  DefaultMultipliers,                     !- Dry-Bulb Temperature Range Modifier Type",
        "  ,                                       !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "  Wetbulb,                                !- Humidity Condition Type",
        "  -20,                                    !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "  ,                                       !- Humidity Condition Day Schedule Name",
        "  ,                                       !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "  ,                                       !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "  ,                                       !- Daily Wet-Bulb Temperature Range {deltaC}",
        "  98934,                                  !- Barometric Pressure {Pa}",
        "  4.9,                                    !- Wind Speed {m/s}",
        "  270,                                    !- Wind Direction {deg}",
        "  No,                                     !- Rain Indicator",
        "  No,                                     !- Snow Indicator",
        "  No,                                     !- Daylight Saving Time Indicator",
        "  ASHRAEClearSky,                         !- Solar Model Indicator",
        "  ,                                       !- Beam Solar Day Schedule Name",
        "  ,                                       !- Diffuse Solar Day Schedule Name",
        "  ,                                       !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "  ,                                       !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "  0,                                      !- Sky Clearness",
        "  ,                                       !- Maximum Number Warmup Days",
        "  FullResetAtBeginEnvironment;            !- Begin Environment Reset Mode",
        "Site:GroundTemperature:BuildingSurface,19.527,19.502,19.536,19.598,20.002,21.640,22.225,22.375,21.449,20.121,19.802,19.633;",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.init_state(self.state)
    self.state.dataGlobal.BeginSimFlag = True
    SimulationManager.GetProjectData(self.state)
    HeatBalanceManager.SetPreConstructionInputParameters(self.state)
    OutputProcessor.SetupTimePointers(self.state, OutputProcessor.TimeStepType.Zone, self.state.dataGlobal.TimeStepZone)
    OutputProcessor.SetupTimePointers(self.state, OutputProcessor.TimeStepType.System, self.state.dataHVACGlobal.TimeStepSys)
    PlantManager.CheckIfAnyPlant(self.state)
    EnergyPlus.createFacilityElectricPowerServiceObject(self.state)
    BranchInputManager.ManageBranchInput(self.state)
    self.state.dataGlobal.DoingSizing = True
    self.state.dataGlobal.BeginEnvrnFlag = True
    self.state.dataGlobal.ZoneSizingCalc = True
    var _1: Bool = has_err_output(True)
    var _2 = SizingManager.ManageSizing(self.state)
    var expectedError: String = delimited_string(
        "   ************* Beginning Zone Sizing Calculations",
        "   ************* Beginning System Sizing Calculations",
    )
    var _3: Bool = compare_err_stream(expectedError, True)

def VSParallelPIUStagedHeat(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Zone,",
        "  SPACE2-1;                               !- Name",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE2-1,                               !- Zone Name",
        "  SPACE2-1 Equipment,                     !- Zone Conditioning Equipment List Name",
        "  SPACE2-1 In Node,                       !- Zone Air Inlet Node or NodeList Name",
        "  SPACE2-1 ATU Sec Node,                  !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE2-1 Air Node,                      !- Zone Air Node Name",
        "  SPACE2-1 Return Node;                   !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  SPACE2-1 Equipment,                     !- Name",
        "  SequentialLoad,                         !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,           !- Zone Equipment 1 Object Type",
        "  SPACE2-1 ADU,                           !- Zone Equipment 1 Name",
        "  1,                                      !- Zone Equipment 1 Cooling Sequence",
        "  1;                                      !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:AirDistributionUnit,",
        "  SPACE2-1 ADU,                           !- Name",
        "  SPACE2-1 In Node,                       !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:ParallelPIU:Reheat,  !- Air Terminal Object Type",
        "  SPACE2-1 Parallel PIU Reheat;           !- Air Terminal Name",
        "AirTerminal:SingleDuct:ParallelPIU:Reheat,",
        "  SPACE2-1 Parallel PIU Reheat,           !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  0.1,                                    !- Maximum Primary Air Flow Rate {m3/s}",
        "  0.05,                                   !- Maximum Secondary Air Flow Rate {m3/s}",
        "  0.2,                                    !- Minimum Primary Air Flow Fraction",
        "  0.1,                                    !- Fan On Flow Fraction",
        "  SPACE2-1 ATU In Node,                   !- Supply Air Inlet Node Name",
        "  SPACE2-1 ATU Sec Node,                  !- Secondary Air Inlet Node Name",
        "  SPACE2-1 In Node,                       !- Outlet Node Name",
        "  SPACE2-1 PIU Mixer,                     !- Zone Mixer Name",
        "  SPACE2-1 PIU Fan,                       !- Fan Name",
        "  Coil:Heating:Electric,                  !- Reheat Coil Object Type",
        "  SPACE2-1 Zone Coil,                     !- Reheat Coil Name",
        "  0.0,                                    !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0,                                    !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0001,                                 !- Convergence Tolerance",
        "  VariableSpeed,                          !- Fan Control Type",
        "  0.3,                                    !- Minimum Fan Turn Down Ratio",
        "  Staged;                                 !- Heating Control Type",
        "Fan:SystemModel,",
        "  SPACE2-1 PIU Fan,                       !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  SPACE2-1 ATU Sec Node,                  !- Air Inlet Node Name",
        "  SPACE2-1 ATU Fan Outlet Node,           !- Air Outlet Node Name",
        "  0.05,                               !- Design Maximum Air Flow Rate {m3/s}",
        "  Continuous,                             !- Speed Control Method",
        "  0.0,                                    !- Electric Power Minimum Flow Rate Fraction",
        "  50.0,                                   !- Design Pressure Rise {Pa}",
        "  0.9,                                    !- Motor Efficiency",
        "  1.0,                                    !- Motor In Air Stream Fraction",
        "  AUTOSIZE,                               !- Design Electric Power Consumption {W}",
        "  TotalEfficiencyAndPressure,             !- Design Power Sizing Method",
        "  ,                                       !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "  ,                                       !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "  0.50,                                   !- Fan Total Efficiency",
        "  CombinedPowerAndFanEff;                 !- Electric Power Function of Flow Fraction Curve Name",
        "  Curve:Cubic,",
        "    CombinedPowerAndFanEff,  !- Name",
        "    0.0,                     !- Coefficient1 Constant",
        "    0.027411,                !- Coefficient2 x",
        "    0.008740,                !- Coefficient3 x**2",
        "    0.969563,                !- Coefficient4 x**3",
        "    0.5,                     !- Minimum Value of x",
        "    1.5,                     !- Maximum Value of x",
        "    0.01,                    !- Minimum Curve Output",
        "    1.5;                     !- Maximum Curve Output",
        "AirLoopHVAC:ZoneMixer,",
        "  SPACE2-1 PIU Mixer,                     !- Name",
        "  SPACE2-1 Zone Coil Air In Node,         !- Outlet Node Name",
        "  SPACE2-1 ATU In Node,                   !- Inlet 1 Node Name",
        "  SPACE2-1 ATU Fan Outlet Node;           !- Inlet 2 Node Name",
        "Coil:Heating:Electric,",
        "  SPACE2-1 Zone Coil,                     !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  1.0,                                    !- Efficiency",
        "  1000,                                   !- Nominal Capacity",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Inlet Node Name",
        "  SPACE2-1 In Node;                       !- Air Outlet Node Name",
        "Schedule:Constant,",
        "  AlwaysOff,                              !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  0;                                      !- Hourly Value",
        "Schedule:Constant,",
        "  AlwaysOn,                               !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
    Sched.UpdateScheduleVals(self.state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    var _1: Bool = ErrorsFound
    DataZoneEquipment.GetZoneEquipmentData(self.state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(self.state)
    self.state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    Fans.GetFanInput(self.state)
    self.state.dataFans.GetFanInputFlag = False
    PoweredInductionUnits.GetPIUs(self.state)
    var error_string: String = delimited_string(
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSOFF",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSON",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
    )
    var _2: Bool = compare_err_stream(error_string)
    self.state.dataHeatBalFanSys.TempControlType.allocate(1)
    self.state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.DualHeatCool
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    var ZoneNum: Int = 1
    var SysNum: Int = 1
    var ZoneNodeNum: Int = 1
    var FirstHVACIteration: Bool = True
    self.state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    PoweredInductionUnits.InitPIU(self.state, SysNum, FirstHVACIteration)
    var thisPIU = self.state.dataPowerInductionUnits.PIU[1]
    self.state.dataFans.fans[thisPIU.Fan_Index].simulate(self.state, FirstHVACIteration, _, _)
    self.state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    var SecNodeNum: Int = thisPIU.SecAirInNode
    var PriNodeNum: Int = thisPIU.PriAirInNode
    var PriMaxMassFlow: Float64 = thisPIU.MaxPriAirMassFlow
    var PriMinMassFlow: Float64 = thisPIU.MinPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMinMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 500.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 500.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNodeNum] = False
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = 26.0
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[SecNodeNum].Temp, self.state.dataLoopNodes.Node[SecNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 16.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMaxAvail = thisPIU.MaxSecAirMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMinAvail = thisPIU.MinSecAirMassFlow
    self.state.dataHVACGlobal.TurnFansOn = True
    self.state.dataLoopNodes.Node[7].MassFlowRateMax = thisPIU.MaxSecAirMassFlow
    self.state.dataLoopNodes.Node[7].MassFlowRateMin = thisPIU.MinSecAirMassFlow
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _3: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.StagedHeatFirstStage
    var _4: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _5: Bool = thisPIU.SecMassFlowRate > thisPIU.MinSecAirMassFlow
    var _6: Bool = thisPIU.DischargeAirTemp == self.state.dataLoopNodes.Node[thisPIU.HCoilInAirNode].Temp
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 1000.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 1000.0
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _7: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.StagedHeatSecondStage
    var _8: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _9: Bool = thisPIU.SecMassFlowRate == thisPIU.MaxSecAirMassFlow

def VSParallelPIUModulatedHeat(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Zone,",
        "  SPACE2-1;                               !- Name",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE2-1,                               !- Zone Name",
        "  SPACE2-1 Equipment,                     !- Zone Conditioning Equipment List Name",
        "  SPACE2-1 In Node,                       !- Zone Air Inlet Node or NodeList Name",
        "  SPACE2-1 ATU Sec Node,                  !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE2-1 Air Node,                      !- Zone Air Node Name",
        "  SPACE2-1 Return Node;                   !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  SPACE2-1 Equipment,                     !- Name",
        "  SequentialLoad,                         !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,           !- Zone Equipment 1 Object Type",
        "  SPACE2-1 ADU,                           !- Zone Equipment 1 Name",
        "  1,                                      !- Zone Equipment 1 Cooling Sequence",
        "  1;                                      !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:AirDistributionUnit,",
        "  SPACE2-1 ADU,                           !- Name",
        "  SPACE2-1 In Node,                       !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:ParallelPIU:Reheat,  !- Air Terminal Object Type",
        "  SPACE2-1 Parallel PIU Reheat;           !- Air Terminal Name",
        "AirTerminal:SingleDuct:ParallelPIU:Reheat,",
        "  SPACE2-1 Parallel PIU Reheat,           !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  0.1,                                    !- Maximum Primary Air Flow Rate {m3/s}",
        "  0.05,                                   !- Maximum Secondary Air Flow Rate {m3/s}",
        "  0.2,                                    !- Minimum Primary Air Flow Fraction",
        "  0.1,                                    !- Fan On Flow Fraction",
        "  SPACE2-1 ATU In Node,                   !- Supply Air Inlet Node Name",
        "  SPACE2-1 ATU Sec Node,                  !- Secondary Air Inlet Node Name",
        "  SPACE2-1 In Node,                       !- Outlet Node Name",
        "  SPACE2-1 PIU Mixer,                     !- Zone Mixer Name",
        "  SPACE2-1 PIU Fan,                       !- Fan Name",
        "  Coil:Heating:Electric,                  !- Reheat Coil Object Type",
        "  SPACE2-1 Zone Coil,                     !- Reheat Coil Name",
        "  0.0,                                    !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0,                                    !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0001,                                 !- Convergence Tolerance",
        "  VariableSpeed,                          !- Fan Control Type",
        "  0.3,                                    !- Minimum Fan Turn Down Ratio",
        "  Modulated;                              !- Heating Control Type",
        "Fan:SystemModel,",
        "  SPACE2-1 PIU Fan,                       !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  SPACE2-1 ATU Sec Node,                  !- Air Inlet Node Name",
        "  SPACE2-1 ATU Fan Outlet Node,           !- Air Outlet Node Name",
        "  0.05,                               !- Design Maximum Air Flow Rate {m3/s}",
        "  Continuous,                             !- Speed Control Method",
        "  0.0,                                    !- Electric Power Minimum Flow Rate Fraction",
        "  50.0,                                   !- Design Pressure Rise {Pa}",
        "  0.9,                                    !- Motor Efficiency",
        "  1.0,                                    !- Motor In Air Stream Fraction",
        "  AUTOSIZE,                               !- Design Electric Power Consumption {W}",
        "  TotalEfficiencyAndPressure,             !- Design Power Sizing Method",
        "  ,                                       !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "  ,                                       !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "  0.50,                                   !- Fan Total Efficiency",
        "  CombinedPowerAndFanEff;                 !- Electric Power Function of Flow Fraction Curve Name",
        "  Curve:Cubic,",
        "    CombinedPowerAndFanEff,  !- Name",
        "    0.0,                     !- Coefficient1 Constant",
        "    0.027411,                !- Coefficient2 x",
        "    0.008740,                !- Coefficient3 x**2",
        "    0.969563,                !- Coefficient4 x**3",
        "    0.5,                     !- Minimum Value of x",
        "    1.5,                     !- Maximum Value of x",
        "    0.01,                    !- Minimum Curve Output",
        "    1.5;                     !- Maximum Curve Output",
        "AirLoopHVAC:ZoneMixer,",
        "  SPACE2-1 PIU Mixer,                     !- Name",
        "  SPACE2-1 Zone Coil Air In Node,         !- Outlet Node Name",
        "  SPACE2-1 ATU In Node,                   !- Inlet 1 Node Name",
        "  SPACE2-1 ATU Fan Outlet Node;           !- Inlet 2 Node Name",
        "Coil:Heating:Electric,",
        "  SPACE2-1 Zone Coil,                     !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  1.0,                                    !- Efficiency",
        "  2500,                                   !- Nominal Capacity",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Inlet Node Name",
        "  SPACE2-1 In Node;                       !- Air Outlet Node Name",
        "Schedule:Constant,",
        "  AlwaysOff,                              !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  0;                                      !- Hourly Value",
        "Schedule:Constant,",
        "  AlwaysOn,                               !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
    Sched.UpdateScheduleVals(self.state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    var _1: Bool = ErrorsFound
    DataZoneEquipment.GetZoneEquipmentData(self.state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(self.state)
    self.state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    Fans.GetFanInput(self.state)
    self.state.dataFans.GetFanInputFlag = False
    PoweredInductionUnits.GetPIUs(self.state)
    var error_string: String = delimited_string(
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSOFF",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSON",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
    )
    var _2: Bool = compare_err_stream(error_string)
    self.state.dataHeatBalFanSys.TempControlType.allocate(1)
    self.state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.DualHeatCool
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    var ZoneNum: Int = 1
    var SysNum: Int = 1
    var ZoneNodeNum: Int = 1
    var FirstHVACIteration: Bool = True
    self.state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    PoweredInductionUnits.InitPIU(self.state, SysNum, FirstHVACIteration)
    var thisPIU = self.state.dataPowerInductionUnits.PIU[1]
    self.state.dataFans.fans[thisPIU.Fan_Index].simulate(self.state, False, _, _)
    self.state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    var SecNodeNum: Int = thisPIU.SecAirInNode
    var PriNodeNum: Int = thisPIU.PriAirInNode
    var PriMaxMassFlow: Float64 = thisPIU.MaxPriAirMassFlow
    var PriMinMassFlow: Float64 = thisPIU.MinPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMinMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 500.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 500.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNodeNum] = False
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = 26.0
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[SecNodeNum].Temp, self.state.dataLoopNodes.Node[SecNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 16.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMaxAvail = thisPIU.MaxSecAirMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMinAvail = thisPIU.MinSecAirMassFlow
    self.state.dataHVACGlobal.TurnFansOn = True
    self.state.dataLoopNodes.Node[7].MassFlowRateMax = thisPIU.MaxSecAirMassFlow
    self.state.dataLoopNodes.Node[7].MassFlowRateMin = thisPIU.MinSecAirMassFlow
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _3: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.ModulatedHeatFirstStage
    var _4: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _5: Bool = thisPIU.SecMassFlowRate == thisPIU.MinSecAirMassFlow
    var _6: Bool = thisPIU.DischargeAirTemp < thisPIU.designHeatingDAT
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 1000.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 1000.0
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _7: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.ModulatedHeatSecondStage
    var _8: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _9: Bool = thisPIU.SecMassFlowRate < thisPIU.MaxSecAirMassFlow
    var _10: Bool = thisPIU.SecMassFlowRate > thisPIU.MinSecAirMassFlow
    var _11: Bool = thisPIU.DischargeAirTemp == thisPIU.designHeatingDAT
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 1500.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 1500.0
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _12: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.ModulatedHeatThirdStage
    var _13: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _14: Bool = thisPIU.SecMassFlowRate == thisPIU.MaxSecAirMassFlow
    var _15: Bool = thisPIU.DischargeAirTemp < thisPIU.highLimitDAT
    var _16: Bool = thisPIU.DischargeAirTemp > thisPIU.designHeatingDAT
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[SecNodeNum].Temp, self.state.dataLoopNodes.Node[SecNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 16.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMaxAvail = thisPIU.MaxSecAirMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMinAvail = thisPIU.MinSecAirMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 2000.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 2000.0
    PoweredInductionUnits.CalcParallelPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _17: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.ModulatedHeatThirdStage
    var _18: Bool = thisPIU.DischargeAirTemp == thisPIU.highLimitDAT

def VSSeriesPIUStagedHeat(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Zone,",
        "  SPACE2-1;                               !- Name",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE2-1,                               !- Zone Name",
        "  SPACE2-1 Equipment,                     !- Zone Conditioning Equipment List Name",
        "  SPACE2-1 In Node,                       !- Zone Air Inlet Node or NodeList Name",
        "  SPACE2-1 ATU Sec Node,                  !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE2-1 Air Node,                      !- Zone Air Node Name",
        "  SPACE2-1 Return Node;                   !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  SPACE2-1 Equipment,                     !- Name",
        "  SequentialLoad,                         !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,           !- Zone Equipment 1 Object Type",
        "  SPACE2-1 ADU,                           !- Zone Equipment 1 Name",
        "  1,                                      !- Zone Equipment 1 Cooling Sequence",
        "  1;                                      !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:AirDistributionUnit,",
        "  SPACE2-1 ADU,                           !- Name",
        "  SPACE2-1 In Node,                       !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:SeriesPIU:Reheat,  !- Air Terminal Object Type",
        "  SPACE2-1 Series PIU Reheat;           !- Air Terminal Name",
        "AirTerminal:SingleDuct:SeriesPIU:Reheat,",
        "  SPACE2-1 Series PIU Reheat,              !- Name",
        "  AlwaysOn,                                !- Availability Schedule Name",
        "  0.15,                                    !- Maximum Air Flow Rate {m3/s}",
        "  0.05,                                    !- Maximum Primary Air Flow Rate {m3/s}",
        "  0.2,                                     !- Minimum Primary Air Flow Fraction",
        "  SPACE2-1 ATU In Node,                    !- Supply Air Inlet Node Name",
        "  SPACE2-1 ATU Sec Node,                   !- Secondary Air Inlet Node Name",
        "  SPACE2-1 In Node,                        !- Outlet Node Name",
        "  SPACE2-1 PIU Mixer,                      !- Zone Mixer Name",
        "  SPACE2-1 PIU Fan,                        !- Fan Name",
        "  Coil:Heating:Electric,                   !- Reheat Coil Object Type",
        "  SPACE2-1 Zone Coil,                      !- Reheat Coil Name",
        "  0.0,                                     !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0,                                     !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0001,                                  !- Convergence Tolerance",
        "  VariableSpeed,                           !- Fan Control Type",
        "  0.3,                                     !- Minimum Fan Turn Down Ratio",
        "  Staged;                                  !- Heating Control Type",
        "Fan:SystemModel,",
        "  SPACE2-1 PIU Fan,                       !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  SPACE2-1 ATU Fan Inlet Node,            !- Air Inlet Node Name",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Outlet Node Name",
        "  0.15,                                   !- Design Maximum Air Flow Rate {m3/s}",
        "  Continuous,                             !- Speed Control Method",
        "  0.0,                                    !- Electric Power Minimum Flow Rate Fraction",
        "  50.0,                                   !- Design Pressure Rise {Pa}",
        "  0.9,                                    !- Motor Efficiency",
        "  1.0,                                    !- Motor In Air Stream Fraction",
        "  AUTOSIZE,                               !- Design Electric Power Consumption {W}",
        "  TotalEfficiencyAndPressure,             !- Design Power Sizing Method",
        "  ,                                       !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "  ,                                       !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "  0.50,                                   !- Fan Total Efficiency",
        "  CombinedPowerAndFanEff;                 !- Electric Power Function of Flow Fraction Curve Name",
        "  Curve:Cubic,",
        "    CombinedPowerAndFanEff,  !- Name",
        "    0.0,                     !- Coefficient1 Constant",
        "    0.027411,                !- Coefficient2 x",
        "    0.008740,                !- Coefficient3 x**2",
        "    0.969563,                !- Coefficient4 x**3",
        "    0.5,                     !- Minimum Value of x",
        "    1.5,                     !- Maximum Value of x",
        "    0.01,                    !- Minimum Curve Output",
        "    1.5;                     !- Maximum Curve Output",
        "AirLoopHVAC:ZoneMixer,",
        "  SPACE2-1 PIU Mixer,      !- Name",
        "  SPACE2-1 ATU Fan Inlet Node,  !- Outlet Node Name",
        "  SPACE2-1 ATU In Node,    !- Inlet 1 Node Name",
        "  SPACE2-1 ATU Sec Node;  !- Inlet 2 Node Name",
        "Coil:Heating:Electric,",
        "  SPACE2-1 Zone Coil,                     !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  1.0,                                    !- Efficiency",
        "  2500,                                   !- Nominal Capacity",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Inlet Node Name",
        "  SPACE2-1 In Node;                       !- Air Outlet Node Name",
        "Schedule:Constant,",
        "  AlwaysOff,                              !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  0;                                      !- Hourly Value",
        "Schedule:Constant,",
        "  AlwaysOn,                               !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
    Sched.UpdateScheduleVals(self.state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    var _1: Bool = ErrorsFound
    DataZoneEquipment.GetZoneEquipmentData(self.state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(self.state)
    self.state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    self.state.dataFans.GetFanInputFlag = False
    Fans.GetFanInput(self.state)
    PoweredInductionUnits.GetPIUs(self.state)
    var error_string: String = delimited_string(
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSOFF",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSON",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
    )
    var _2: Bool = compare_err_stream(error_string)
    self.state.dataHeatBalFanSys.TempControlType.allocate(1)
    self.state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.DualHeatCool
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    var ZoneNum: Int = 1
    var SysNum: Int = 1
    var ZoneNodeNum: Int = 1
    var FirstHVACIteration: Bool = True
    self.state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    PoweredInductionUnits.InitPIU(self.state, SysNum, FirstHVACIteration)
    MixerComponent.GetMixerInput(self.state)
    var thisPIU = self.state.dataPowerInductionUnits.PIU[1]
    self.state.dataFans.fans[thisPIU.Fan_Index].simulate(self.state, False, _, _)
    self.state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    var SecNodeNum: Int = thisPIU.SecAirInNode
    var PriNodeNum: Int = thisPIU.PriAirInNode
    var PriMaxMassFlow: Float64 = thisPIU.MaxPriAirMassFlow
    var PriMinMassFlow: Float64 = thisPIU.MinPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMinMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 500.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 500.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNodeNum] = False
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = 26.0
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[SecNodeNum].Temp, self.state.dataLoopNodes.Node[SecNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 16.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMaxAvail = thisPIU.MaxTotAirMassFlow - thisPIU.MinPriAirMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMinAvail = thisPIU.MinTotAirMassFlow - thisPIU.MinPriAirMassFlow
    self.state.dataHVACGlobal.TurnFansOn = True
    self.state.dataLoopNodes.Node[7].MassFlowRateMax = thisPIU.MaxTotAirMassFlow
    self.state.dataLoopNodes.Node[7].MassFlowRateMin = thisPIU.MinTotAirMassFlow
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _3: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.StagedHeatFirstStage
    var _4: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _5: Bool = thisPIU.SecMassFlowRate < thisPIU.MaxTotAirMassFlow - thisPIU.MinPriAirMassFlow
    var _6: Bool = thisPIU.SecMassFlowRate > thisPIU.MinSecAirMassFlow
    var _7: Bool = thisPIU.DischargeAirTemp == self.state.dataLoopNodes.Node[thisPIU.HCoilInAirNode].Temp
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 2500.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 2500.0
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _8: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.StagedHeatSecondStage
    var _9: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _10: Bool = thisPIU.SecMassFlowRate == thisPIU.MaxTotAirMassFlow - thisPIU.MinPriAirMassFlow
    var _11: Bool = thisPIU.DischargeAirTemp > self.state.dataLoopNodes.Node[thisPIU.HCoilInAirNode].Temp
    var _12: Bool = thisPIU.DischargeAirTemp < thisPIU.highLimitDAT

def VSSeriesPIUModulatedHeat(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Zone,",
        "  SPACE2-1;                               !- Name",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE2-1,                               !- Zone Name",
        "  SPACE2-1 Equipment,                     !- Zone Conditioning Equipment List Name",
        "  SPACE2-1 In Node,                       !- Zone Air Inlet Node or NodeList Name",
        "  SPACE2-1 ATU Sec Node,                  !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE2-1 Air Node,                      !- Zone Air Node Name",
        "  SPACE2-1 Return Node;                   !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  SPACE2-1 Equipment,                     !- Name",
        "  SequentialLoad,                         !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,           !- Zone Equipment 1 Object Type",
        "  SPACE2-1 ADU,                           !- Zone Equipment 1 Name",
        "  1,                                      !- Zone Equipment 1 Cooling Sequence",
        "  1;                                      !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:AirDistributionUnit,",
        "  SPACE2-1 ADU,                           !- Name",
        "  SPACE2-1 In Node,                       !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:SeriesPIU:Reheat,!- Air Terminal Object Type",
        "  SPACE2-1 Series PIU Reheat;             !- Air Terminal Name",
        "AirTerminal:SingleDuct:SeriesPIU:Reheat,",
        "  SPACE2-1 Series PIU Reheat,              !- Name",
        "  AlwaysOn,                                !- Availability Schedule Name",
        "  0.15,                                    !- Maximum Air Flow Rate {m3/s}",
        "  0.05,                                    !- Maximum Primary Air Flow Rate {m3/s}",
        "  0.2,                                     !- Minimum Primary Air Flow Fraction",
        "  SPACE2-1 ATU In Node,                    !- Supply Air Inlet Node Name",
        "  SPACE2-1 ATU Sec Node,                   !- Secondary Air Inlet Node Name",
        "  SPACE2-1 In Node,                        !- Outlet Node Name",
        "  SPACE2-1 PIU Mixer,                      !- Zone Mixer Name",
        "  SPACE2-1 PIU Fan,                        !- Fan Name",
        "  Coil:Heating:Electric,                   !- Reheat Coil Object Type",
        "  SPACE2-1 Zone Coil,                      !- Reheat Coil Name",
        "  0.0,                                     !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0,                                     !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0001,                                  !- Convergence Tolerance",
        "  VariableSpeed,                           !- Fan Control Type",
        "  0.3,                                     !- Minimum Fan Turn Down Ratio",
        "  Modulated;                               !- Heating Control Type",
        "Fan:SystemModel,",
        "  SPACE2-1 PIU Fan,                       !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  SPACE2-1 ATU Fan Inlet Node,            !- Air Inlet Node Name",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Outlet Node Name",
        "  0.15,                                   !- Design Maximum Air Flow Rate {m3/s}",
        "  Continuous,                             !- Speed Control Method",
        "  0.0,                                    !- Electric Power Minimum Flow Rate Fraction",
        "  50.0,                                   !- Design Pressure Rise {Pa}",
        "  0.9,                                    !- Motor Efficiency",
        "  1.0,                                    !- Motor In Air Stream Fraction",
        "  AUTOSIZE,                               !- Design Electric Power Consumption {W}",
        "  TotalEfficiencyAndPressure,             !- Design Power Sizing Method",
        "  ,                                       !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "  ,                                       !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "  0.50,                                   !- Fan Total Efficiency",
        "  CombinedPowerAndFanEff;                 !- Electric Power Function of Flow Fraction Curve Name",
        "  Curve:Cubic,",
        "    CombinedPowerAndFanEff,  !- Name",
        "    0.0,                     !- Coefficient1 Constant",
        "    0.027411,                !- Coefficient2 x",
        "    0.008740,                !- Coefficient3 x**2",
        "    0.969563,                !- Coefficient4 x**3",
        "    0.5,                     !- Minimum Value of x",
        "    1.5,                     !- Maximum Value of x",
        "    0.01,                    !- Minimum Curve Output",
        "    1.5;                     !- Maximum Curve Output",
        "AirLoopHVAC:ZoneMixer,",
        "  SPACE2-1 PIU Mixer,           !- Name",
        "  SPACE2-1 ATU Fan Inlet Node,  !- Outlet Node Name",
        "  SPACE2-1 ATU In Node,         !- Inlet 1 Node Name",
        "  SPACE2-1 ATU Sec Node;        !- Inlet 2 Node Name",
        "Coil:Heating:Electric,",
        "  SPACE2-1 Zone Coil,                     !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  1.0,                                    !- Efficiency",
        "  5000,                                   !- Nominal Capacity",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Inlet Node Name",
        "  SPACE2-1 In Node;                       !- Air Outlet Node Name",
        "Schedule:Constant,",
        "  AlwaysOff,                              !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  0;                                      !- Hourly Value",
        "Schedule:Constant,",
        "  AlwaysOn,                               !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
    Sched.UpdateScheduleVals(self.state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    var _1: Bool = ErrorsFound
    DataZoneEquipment.GetZoneEquipmentData(self.state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(self.state)
    self.state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    Fans.GetFanInput(self.state)
    self.state.dataFans.GetFanInputFlag = False
    PoweredInductionUnits.GetPIUs(self.state)
    var error_string: String = delimited_string(
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSOFF",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSON",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
    )
    var _2: Bool = compare_err_stream(error_string)
    self.state.dataHeatBalFanSys.TempControlType.allocate(1)
    self.state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.DualHeatCool
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    var ZoneNum: Int = 1
    var SysNum: Int = 1
    var ZoneNodeNum: Int = 1
    var FirstHVACIteration: Bool = True
    self.state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    PoweredInductionUnits.InitPIU(self.state, SysNum, FirstHVACIteration)
    MixerComponent.GetMixerInput(self.state)
    var thisPIU = self.state.dataPowerInductionUnits.PIU[1]
    self.state.dataFans.fans[thisPIU.Fan_Index].simulate(self.state, False, _, _)
    self.state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    var SecNodeNum: Int = thisPIU.SecAirInNode
    var PriNodeNum: Int = thisPIU.PriAirInNode
    var PriMaxMassFlow: Float64 = thisPIU.MaxPriAirMassFlow
    var PriMinMassFlow: Float64 = thisPIU.MinPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMinMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 500.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 500.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNodeNum] = False
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = 20.0
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[SecNodeNum].Temp, self.state.dataLoopNodes.Node[SecNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 16.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMaxAvail = thisPIU.MaxTotAirMassFlow - thisPIU.MinPriAirMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMinAvail = thisPIU.MinTotAirMassFlow - thisPIU.MinPriAirMassFlow
    self.state.dataHVACGlobal.TurnFansOn = True
    self.state.dataLoopNodes.Node[7].MassFlowRateMax = thisPIU.MaxTotAirMassFlow
    self.state.dataLoopNodes.Node[7].MassFlowRateMin = thisPIU.MinTotAirMassFlow
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _3: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.ModulatedHeatFirstStage
    var _4: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _5: Bool = thisPIU.SecMassFlowRate == thisPIU.MinTotAirMassFlow - thisPIU.MinPriAirMassFlow
    var _6: Bool = thisPIU.DischargeAirTemp < thisPIU.designHeatingDAT
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 1500.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 1500.0
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _7: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.ModulatedHeatSecondStage
    var _8: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _9: Bool = thisPIU.SecMassFlowRate < thisPIU.MaxSecAirMassFlow
    var _10: Bool = thisPIU.SecMassFlowRate > thisPIU.MinSecAirMassFlow
    var _11: Bool = thisPIU.DischargeAirTemp == thisPIU.designHeatingDAT
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 3300.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 3300.0
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _12: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.ModulatedHeatThirdStage
    var _13: Bool = thisPIU.PriMassFlowRate == PriMinMassFlow
    var _14: Bool = self.state.dataLoopNodes.Node[thisPIU.OutAirNode].MassFlowRate == thisPIU.MaxTotAirMassFlow
    var _15: Bool = thisPIU.DischargeAirTemp < thisPIU.highLimitDAT
    var _16: Bool = thisPIU.DischargeAirTemp > thisPIU.designHeatingDAT
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = 15.0
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[SecNodeNum].Temp, self.state.dataLoopNodes.Node[SecNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 16.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = 4800.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToHeatSP = 4800.0
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _17: Bool = thisPIU.heatingOperatingMode == PoweredInductionUnits.HeatOpModeType.ModulatedHeatThirdStage
    var _18: Bool = thisPIU.DischargeAirTemp == thisPIU.highLimitDAT

def VSSeriesPIUCool(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string(
        "Zone,",
        "  SPACE2-1;                               !- Name",
        "ZoneHVAC:EquipmentConnections,",
        "  SPACE2-1,                               !- Zone Name",
        "  SPACE2-1 Equipment,                     !- Zone Conditioning Equipment List Name",
        "  SPACE2-1 In Node,                       !- Zone Air Inlet Node or NodeList Name",
        "  SPACE2-1 ATU Sec Node,                  !- Zone Air Exhaust Node or NodeList Name",
        "  SPACE2-1 Air Node,                      !- Zone Air Node Name",
        "  SPACE2-1 Return Node;                   !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  SPACE2-1 Equipment,                     !- Name",
        "  SequentialLoad,                         !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,           !- Zone Equipment 1 Object Type",
        "  SPACE2-1 ADU,                           !- Zone Equipment 1 Name",
        "  1,                                      !- Zone Equipment 1 Cooling Sequence",
        "  1;                                      !- Zone Equipment 1 Heating or No-Load Sequence",
        "ZoneHVAC:AirDistributionUnit,",
        "  SPACE2-1 ADU,                           !- Name",
        "  SPACE2-1 In Node,                       !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:SeriesPIU:Reheat,!- Air Terminal Object Type",
        "  SPACE2-1 Series PIU Reheat;             !- Air Terminal Name",
        "AirTerminal:SingleDuct:SeriesPIU:Reheat,",
        "  SPACE2-1 Series PIU Reheat,              !- Name",
        "  AlwaysOn,                                !- Availability Schedule Name",
        "  0.15,                                    !- Maximum Air Flow Rate {m3/s}",
        "  0.05,                                    !- Maximum Primary Air Flow Rate {m3/s}",
        "  0.2,                                     !- Minimum Primary Air Flow Fraction",
        "  SPACE2-1 ATU In Node,                    !- Supply Air Inlet Node Name",
        "  SPACE2-1 ATU Sec Node,                   !- Secondary Air Inlet Node Name",
        "  SPACE2-1 In Node,                        !- Outlet Node Name",
        "  SPACE2-1 PIU Mixer,                      !- Zone Mixer Name",
        "  SPACE2-1 PIU Fan,                        !- Fan Name",
        "  Coil:Heating:Electric,                   !- Reheat Coil Object Type",
        "  SPACE2-1 Zone Coil,                      !- Reheat Coil Name",
        "  0.0,                                     !- Maximum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0,                                     !- Minimum Hot Water or Steam Flow Rate {m3/s}",
        "  0.0001,                                  !- Convergence Tolerance",
        "  VariableSpeed,                           !- Fan Control Type",
        "  0.3,                                     !- Minimum Fan Turn Down Ratio",
        "  Modulated;                               !- Heating Control Type",
        "Fan:SystemModel,",
        "  SPACE2-1 PIU Fan,                       !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  SPACE2-1 ATU Fan Inlet Node,            !- Air Inlet Node Name",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Outlet Node Name",
        "  0.15,                                   !- Design Maximum Air Flow Rate {m3/s}",
        "  Continuous,                             !- Speed Control Method",
        "  0.0,                                    !- Electric Power Minimum Flow Rate Fraction",
        "  50.0,                                   !- Design Pressure Rise {Pa}",
        "  0.9,                                    !- Motor Efficiency",
        "  1.0,                                    !- Motor In Air Stream Fraction",
        "  AUTOSIZE,                               !- Design Electric Power Consumption {W}",
        "  TotalEfficiencyAndPressure,             !- Design Power Sizing Method",
        "  ,                                       !- Electric Power Per Unit Flow Rate {W/(m3/s)}",
        "  ,                                       !- Electric Power Per Unit Flow Rate Per Unit Pressure {W/((m3/s)-Pa)}",
        "  0.50,                                   !- Fan Total Efficiency",
        "  CombinedPowerAndFanEff;                 !- Electric Power Function of Flow Fraction Curve Name",
        "  Curve:Cubic,",
        "    CombinedPowerAndFanEff,  !- Name",
        "    0.0,                     !- Coefficient1 Constant",
        "    0.027411,                !- Coefficient2 x",
        "    0.008740,                !- Coefficient3 x**2",
        "    0.969563,                !- Coefficient4 x**3",
        "    0.5,                     !- Minimum Value of x",
        "    1.5,                     !- Maximum Value of x",
        "    0.01,                    !- Minimum Curve Output",
        "    1.5;                     !- Maximum Curve Output",
        "AirLoopHVAC:ZoneMixer,",
        "  SPACE2-1 PIU Mixer,           !- Name",
        "  SPACE2-1 ATU Fan Inlet Node,  !- Outlet Node Name",
        "  SPACE2-1 ATU In Node,         !- Inlet 1 Node Name",
        "  SPACE2-1 ATU Sec Node;        !- Inlet 2 Node Name",
        "Coil:Heating:Electric,",
        "  SPACE2-1 Zone Coil,                     !- Name",
        "  AlwaysOn,                               !- Availability Schedule Name",
        "  1.0,                                    !- Efficiency",
        "  5000,                                   !- Nominal Capacity",
        "  SPACE2-1 Zone Coil Air In Node,         !- Air Inlet Node Name",
        "  SPACE2-1 In Node;                       !- Air Outlet Node Name",
        "Schedule:Constant,",
        "  AlwaysOff,                              !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  0;                                      !- Hourly Value",
        "Schedule:Constant,",
        "  AlwaysOn,                               !- Name",
        "  ,                                       !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
    )
    var _: Bool = process_idf(idf_objects)
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
    Sched.UpdateScheduleVals(self.state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    var _1: Bool = ErrorsFound
    DataZoneEquipment.GetZoneEquipmentData(self.state)
    ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(self.state)
    self.state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    Fans.GetFanInput(self.state)
    self.state.dataFans.GetFanInputFlag = False
    PoweredInductionUnits.GetPIUs(self.state)
    var error_string: String = delimited_string(
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSOFF",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ALWAYSON",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
    )
    var _2: Bool = compare_err_stream(error_string)
    self.state.dataHeatBalFanSys.TempControlType.allocate(1)
    self.state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.DualHeatCool
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    var ZoneNum: Int = 1
    var SysNum: Int = 1
    var ZoneNodeNum: Int = 1
    var FirstHVACIteration: Bool = True
    self.state.dataGlobal.BeginEnvrnFlag = True
    FirstHVACIteration = True
    PoweredInductionUnits.InitPIU(self.state, SysNum, FirstHVACIteration)
    MixerComponent.GetMixerInput(self.state)
    var thisPIU = self.state.dataPowerInductionUnits.PIU[1]
    self.state.dataFans.fans[thisPIU.Fan_Index].simulate(self.state, False, _, _)
    self.state.dataGlobal.BeginEnvrnFlag = False
    FirstHVACIteration = False
    var SecNodeNum: Int = thisPIU.SecAirInNode
    var PriNodeNum: Int = thisPIU.PriAirInNode
    var PriMaxMassFlow: Float64 = thisPIU.MaxPriAirMassFlow
    var PriMinMassFlow: Float64 = thisPIU.MinPriAirMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRate = PriMinMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = -400.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToCoolSP = -400.0
    self.state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNodeNum] = False
    self.state.dataLoopNodes.Node[ZoneNodeNum].Temp = 19.0
    self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[ZoneNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[ZoneNodeNum].Temp, self.state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
    self.state.dataLoopNodes.Node[SecNodeNum].Temp = 19.0
    self.state.dataLoopNodes.Node[SecNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[SecNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[SecNodeNum].Temp, self.state.dataLoopNodes.Node[SecNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].Temp = 12.0
    self.state.dataLoopNodes.Node[PriNodeNum].HumRat = 0.0085
    self.state.dataLoopNodes.Node[PriNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[PriNodeNum].Temp, self.state.dataLoopNodes.Node[PriNodeNum].HumRat)
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMaxAvail = PriMaxMassFlow
    self.state.dataLoopNodes.Node[PriNodeNum].MassFlowRateMinAvail = PriMinMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMaxAvail = thisPIU.MaxTotAirMassFlow - thisPIU.MinPriAirMassFlow
    self.state.dataLoopNodes.Node[SecNodeNum].MassFlowRateMinAvail = thisPIU.MinTotAirMassFlow - thisPIU.MinPriAirMassFlow
    self.state.dataHVACGlobal.TurnFansOn = True
    self.state.dataLoopNodes.Node[7].MassFlowRateMax = thisPIU.MaxTotAirMassFlow
    self.state.dataLoopNodes.Node[7].MassFlowRateMin = thisPIU.MinTotAirMassFlow
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _3: Bool = thisPIU.coolingOperatingMode == PoweredInductionUnits.CoolOpModeType.CoolFirstStage
    var _4: Bool = self.state.dataLoopNodes.Node[thisPIU.OutAirNode].MassFlowRate < thisPIU.MaxTotAirMassFlow
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputRequired = -800.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNodeNum].RemainingOutputReqToCoolSP = -800.0
    PoweredInductionUnits.CalcSeriesPIU(self.state, SysNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    var _5: Bool = thisPIU.coolingOperatingMode == PoweredInductionUnits.CoolOpModeType.CoolSecondStage
    var _6: Bool = self.state.dataLoopNodes.Node[thisPIU.OutAirNode].MassFlowRate == thisPIU.MaxTotAirMassFlow

def PIU_reportTerminalUnit(self: EnergyPlusFixture):
    var orp = self.state.dataOutRptPredefined
    Sched.AddScheduleConstant(self.state, "SCHA")
    Sched.AddScheduleConstant(self.state, "SCHB")
    var adu = self.state.dataDefineEquipment.AirDistUnit
    adu.allocate(2)
    adu[1].Name = "ADU a"
    adu[1].TermUnitSizingNum = 1
    var siz = self.state.dataSize.TermUnitFinalZoneSizing
    siz.allocate(2)
    siz[1].DesCoolVolFlowMin = 0.15
    siz[1].MinOA = 0.05
    siz[1].CoolDesTemp = 12.5
    siz[1].HeatDesTemp = 40.0
    siz[1].DesHeatLoad = 2000.0
    siz[1].DesCoolLoad = 3000.0
    var piu = self.state.dataPowerInductionUnits.PIU
    piu.allocate(2)
    piu[1].ADUNum = 1
    piu[1].UnitType = "AirTerminal:SingleDuct:SeriesPIU:Reheat"
    piu[1].MaxPriAirVolFlow = 0.30
    piu[1].MaxSecAirVolFlow = 0.25
    piu[1].heatCoilType = HVAC.CoilType.HeatingElectric
    piu[1].fanType = HVAC.FanType.Constant
    piu[1].FanName = "FanA"
    piu[1].reportTerminalUnit(self.state)
    var _: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermMinFlow, "ADU a") == "0.15"
    var _2: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermMinOutdoorFlow, "ADU a") == "0.05"
    var _3: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermSupCoolingSP, "ADU a") == "12.50"
    var _4: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermSupHeatingSP, "ADU a") == "40.00"
    var _5: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermHeatingCap, "ADU a") == "2000.00"
    var _6: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermCoolingCap, "ADU a") == "3000.00"
    var _7: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermTypeInp, "ADU a") == "AirTerminal:SingleDuct:SeriesPIU:Reheat"
    var _8: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermPrimFlow, "ADU a") == "0.30"
    var _9: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermSecdFlow, "ADU a") == "0.25"
    var _10: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermMinFlowSch, "ADU a") == "n/a"
    var _11: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermMaxFlowReh, "ADU a") == "n/a"
    var _12: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermMinOAflowSch, "ADU a") == "n/a"
    var _13: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermHeatCoilType, "ADU a") == "COIL:HEATING:ELECTRIC"
    var _14: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermCoolCoilType, "ADU a") == "n/a"
    var _15: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermFanType, "ADU a") == "Fan:ConstantVolume"
    var _16: Bool = RetrievePreDefTableEntry(self.state, orp.pdchAirTermFanName, "ADU a") == "FanA"