from Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import DataAirLoop
from EnergyPlus.DataContaminantBalance import DataContaminantBalance
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataHeatBalFanSys import DataHeatBalFanSys
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataZoneControls import DataZoneControls
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.General import General
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.SystemAvailabilityManager import Avail
from EnergyPlus.ThermalComfort import ThermalComforts
from EnergyPlus.ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from testing import assert_equal, assert_true, assert_false

@test
def SysAvailManager_OptimumStart():
    var idf_objects: String = delimited_string({
        " AvailabilityManager:OptimumStart,",
        "   OptStart Availability 1, !- Name",
        "   Sch_OptStart,            !- Applicability Schedule Name",
        "   Fan_Schedule,            !- Fan Schedule Name",
        "   MaximumofZoneList,       !- Control Type",
        "   ,                        !- Control Zone Name",
        "   List_Zones,              !- Zone List Name",
        "   4,                       !- Maximum Value for Optimum Start Time {hr}",
        "   AdaptiveTemperatureGradient,  !- Control Algorithm",
        "   ,                        !- Constant Temperature Gradient during Cooling {deltaC/hr}",
        "   ,                        !- Constant Temperature Gradient during Heating {deltaC/hr}",
        "   2,                       !- Initial Temperature Gradient during Cooling {deltaC/hr}",
        "   2,                       !- Initial Temperature Gradient during Heating {deltaC/hr}",
        "   ,                        !- Constant Start Time {hr}",
        "   2;                       !- Number of Previous Days {days}",
        " AvailabilityManager:OptimumStart,",
        "   OptStart Availability 2, !- Name",
        "   Sch_OptStart,            !- Applicability Schedule Name",
        "   Fan_Schedule,            !- Fan Schedule Name",
        "   ControlZone,             !- Control Type",
        "   Zone 4,                  !- Control Zone Name",
        "   ,                        !- Zone List Name",
        "   4,                       !- Maximum Value for Optimum Start Time {hr}",
        "   AdaptiveTemperatureGradient,  !- Control Algorithm",
        "   ,                        !- Constant Temperature Gradient during Cooling {deltaC/hr}",
        "   ,                        !- Constant Temperature Gradient during Heating {deltaC/hr}",
        "   2,                       !- Initial Temperature Gradient during Cooling {deltaC/hr}",
        "   2,                       !- Initial Temperature Gradient during Heating {deltaC/hr}",
        "   ,                        !- Constant Start Time {hr}",
        "   2;                       !- Number of Previous Days {days}",
        " AvailabilityManager:OptimumStart,",
        "   OptStart Availability 3, !- Name",
        "   Sch_OptStart,            !- Applicability Schedule Name",
        "   Fan_Schedule_Alt,            !- Fan Schedule Name",
        "   ControlZone,             !- Control Type",
        "   Zone 6,                  !- Control Zone Name",
        "   ,                        !- Zone List Name",
        "   1.5,                       !- Maximum Value for Optimum Start Time {hr}",
        "   AdaptiveTemperatureGradient,  !- Control Algorithm",
        "   ,                        !- Constant Temperature Gradient during Cooling {deltaC/hr}",
        "   ,                        !- Constant Temperature Gradient during Heating {deltaC/hr}",
        "   2,                       !- Initial Temperature Gradient during Cooling {deltaC/hr}",
        "   2,                       !- Initial Temperature Gradient during Heating {deltaC/hr}",
        "   ,                        !- Constant Start Time {hr}",
        "   2;                       !- Number of Previous Days {days}",
        " AvailabilityManager:OptimumStart,",
        "   OptStart Availability 4, !- Name",
        "   Sch_OptStart,            !- Applicability Schedule Name",
        "   Fan_Schedule_Alt,        !- Fan Schedule Name",
        "   ControlZone,             !- Control Type",
        "   Zone 7 - No AirloopHVAC, !- Control Zone Name",
        "   ,                        !- Zone List Name",
        "   6,                       !- Maximum Value for Optimum Start Time {hr}",
        "   ConstantStartTime,       !- Control Algorithm",
        "   3,                       !- Constant Temperature Gradient during Cooling {deltaC/hr}",
        "   3,                       !- Constant Temperature Gradient during Heating {deltaC/hr}",
        "   3,                       !- Initial Temperature Gradient during Cooling {deltaC/hr}",
        "   3,                       !- Initial Temperature Gradient during Heating {deltaC/hr}",
        "   1.5,                     !- Constant Start Time {hr}",
        "   2;                       !- Number of Previous Days {days}",
        " Schedule:Compact,",
        "   Sch_OptStart,            !- Name",
        "   Fraction,                !- Schedule Type Limits Name",
        "   Through: 12/31,          !- Field 1",
        "   For: AllDays,            !- Field 2",
        "   Until: 24:00, 1.0;       !- Field 3",
        " Schedule:Compact,",
        "   Fan_Schedule,            !- Name",
        "   Fraction,                !- Schedule Type Limits Name",
        "   Through: 12/31,          !- Field 1",
        "   For: AllDays,            !- Field 2",
        "   Until:  7:00, 0.0,       !- Field 3",
        "   Until: 24:00, 1.0;       !- Field 3",
        " Schedule:Compact,",
        "   Fan_Schedule_Alt,            !- Name",
        "   Fraction,                !- Schedule Type Limits Name",
        "   Through: 12/31,          !- Field 1",
        "   For: AllDays,            !- Field 2",
        "   Until:  6:30, 0.0,       !- Field 3",
        "   Until: 24:00, 1.0;       !- Field 3",
        " ZoneList,",
        "   List_Zones,              !- Name",
        "   Zone 1,                  !- Zone 1 Name",
        "   Zone 2,                  !- Zone 2 Name",
        "   Zone 3;                  !- Zone 3 Name",
        " ZoneControl:Thermostat,",
        "   LIST_ZONES Thermostat,  !- Name",
        "   LIST_ZONES,             !- Zone or ZoneList Name",
        "   Dual Zone Control Type Sched,  !- Control Type Schedule Name",
        "   ThermostatSetpoint:DualSetpoint,  !- Control 1 Object Type",
        "   Zone DualSPSched; !- Control 1 Name",
        " Schedule:Compact,",
        "   Dual Zone Control Type Sched,  !- Name",
        "   Control Type,            !- Schedule Type Limits Name",
        "   Through: 12/31,          !- Field 1",
        "   For: AllDays,            !- Field 2",
        "   Until: 24:00,4;          !- Field 3",
        " ThermostatSetpoint:DualSetpoint,",
        "   Zone DualSPSched, !- Name",
        "   HTGSETP_SCH,             !- Heating Setpoint Temperature Schedule Name",
        "   CLGSETP_SCH;             !- Cooling Setpoint Temperature Schedule Name",
        " Schedule:Compact,",
        "   CLGSETP_SCH,             !- Name",
        "   Temperature,             !- Schedule Type Limits Name",
        "   Through: 12/31,          !- Field 1",
        "   For: AllDays,            !- Field 2",
        "   Until: 7:00,29.4,       !- Field 3",
        "   Until: 18:00,24.0,       !- Field 3",
        "   Until: 24:00,29.4;       !- Field 3",
        " Schedule:Compact,",
        "   HTGSETP_SCH,             !- Name",
        "   Temperature,             !- Schedule Type Limits Name",
        "   Through: 12/31,          !- Field 1",
        "   For: AllDays,            !- Field 2",
        "   Until: 7:00,15.0,       !- Field 3",
        "   Until: 18:00,19.0,       !- Field 3",
        "   Until: 24:00,15.0;       !- Field 3",
    })
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 6    # must initialize this to get schedules initialized
    state.dataGlobal.MinutesInTimeStep = 10 # must initialize this to get schedules initialized
    state.init_state(*state)
    state.dataHeatBal.NumOfZoneLists = 1
    state.dataHeatBal.ZoneList.allocate(state.dataHeatBal.NumOfZoneLists)
    state.dataHeatBal.ZoneList[0].Name = "LIST_ZONES"
    state.dataHeatBal.ZoneList[0].NumOfZones = 3
    state.dataHeatBal.ZoneList[0].Zone.allocate(3)
    state.dataHeatBal.ZoneList[0].Zone[0] = 1
    state.dataHeatBal.ZoneList[0].Zone[1] = 2
    state.dataHeatBal.ZoneList[0].Zone[2] = 3
    state.dataHVACGlobal.NumPrimaryAirSys = 3
    state.dataAirLoop.PriAirSysAvailMgr.allocate(3)
    state.dataAirLoop.PriAirSysAvailMgr[0].NumAvailManagers = 1
    state.dataAirLoop.PriAirSysAvailMgr[1].NumAvailManagers = 1
    state.dataAirLoop.PriAirSysAvailMgr[2].NumAvailManagers = 1
    state.dataAirLoop.PriAirSysAvailMgr[0].availManagers.allocate(1)
    state.dataAirLoop.PriAirSysAvailMgr[1].availManagers.allocate(1)
    state.dataAirLoop.PriAirSysAvailMgr[2].availManagers.allocate(1)
    state.dataAirLoop.PriAirSysAvailMgr[0].availManagers[0].type = Avail.ManagerType.OptimumStart
    state.dataAirLoop.PriAirSysAvailMgr[0].availManagers[0].Name = "OptStart Availability 1"
    state.dataAirLoop.PriAirSysAvailMgr[0].availManagers[0].Num = 1
    state.dataAirLoop.PriAirSysAvailMgr[1].availManagers[0].type = Avail.ManagerType.OptimumStart
    state.dataAirLoop.PriAirSysAvailMgr[1].availManagers[0].Name = "OptStart Availability 2"
    state.dataAirLoop.PriAirSysAvailMgr[1].availManagers[0].Num = 2
    state.dataAirLoop.PriAirSysAvailMgr[2].availManagers[0].type = Avail.ManagerType.OptimumStart
    state.dataAirLoop.PriAirSysAvailMgr[2].availManagers[0].Name = "OptStart Availability 3"
    state.dataAirLoop.PriAirSysAvailMgr[2].availManagers[0].Num = 3
    state.dataAirLoop.AirToZoneNodeInfo.allocate(3)
    state.dataAirLoop.AirToZoneNodeInfo[0].NumZonesCooled = 3
    state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums.allocate(3)
    state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums[0] = 1
    state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums[1] = 2
    state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums[2] = 3
    state.dataAirLoop.AirToZoneNodeInfo[1].NumZonesCooled = 2
    state.dataAirLoop.AirToZoneNodeInfo[1].CoolCtrlZoneNums.allocate(2)
    state.dataAirLoop.AirToZoneNodeInfo[1].CoolCtrlZoneNums[0] = 4
    state.dataAirLoop.AirToZoneNodeInfo[1].CoolCtrlZoneNums[1] = 5
    state.dataAirLoop.AirToZoneNodeInfo[2].NumZonesCooled = 1
    state.dataAirLoop.AirToZoneNodeInfo[2].CoolCtrlZoneNums.allocate(1)
    state.dataAirLoop.AirToZoneNodeInfo[2].CoolCtrlZoneNums[0] = 6
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 1
    state.dataGlobal.HourOfDay = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.DayOfSim = 1
    state.dataEnvrn.DSTIndicator = 0
    state.dataEnvrn.DayOfWeek = 1
    state.dataEnvrn.DayOfWeekTomorrow = 2
    state.dataEnvrn.HolidayIndex = 0
    state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
    Sched.UpdateScheduleVals(*state)
    state.dataZoneEquip.ZoneEquipAvail.allocate(7)
    state.dataGlobal.NumOfZones = 7
    state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.Zone[0].Name = "ZONE 1"
    state.dataHeatBal.Zone[1].Name = "ZONE 2"
    state.dataHeatBal.Zone[2].Name = "ZONE 3"
    state.dataHeatBal.Zone[3].Name = "ZONE 4"
    state.dataHeatBal.Zone[4].Name = "ZONE 5"
    state.dataHeatBal.Zone[5].Name = "ZONE 6"
    state.dataHeatBal.Zone[6].Name = "ZONE 7 - NO AIRLOOPHVAC"
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode = 1
    state.dataZoneEquip.ZoneEquipConfig[1].ZoneName = "Zone 2"
    state.dataZoneEquip.ZoneEquipConfig[1].ZoneNode = 2
    state.dataZoneEquip.ZoneEquipConfig[2].ZoneName = "Zone 3"
    state.dataZoneEquip.ZoneEquipConfig[2].ZoneNode = 3
    state.dataZoneEquip.ZoneEquipConfig[3].ZoneName = "Zone 4"
    state.dataZoneEquip.ZoneEquipConfig[3].ZoneNode = 4
    state.dataZoneEquip.ZoneEquipConfig[4].ZoneName = "Zone 5"
    state.dataZoneEquip.ZoneEquipConfig[4].ZoneNode = 5
    state.dataZoneEquip.ZoneEquipConfig[5].ZoneName = "Zone 6"
    state.dataZoneEquip.ZoneEquipConfig[5].ZoneNode = 6
    state.dataZoneEquip.ZoneEquipConfig[6].ZoneName = "Zone 7 - No AirloopHVAC"
    state.dataZoneEquip.ZoneEquipConfig[6].ZoneNode = 7
    state.dataZoneEquip.ZoneEquipInputsFilled = true
    state.dataHeatBalFanSys.TempTstatAir.allocate(7)
    state.dataHeatBalFanSys.TempTstatAir[0] = 18.0 # all zones have different space temperature
    state.dataHeatBalFanSys.TempTstatAir[1] = 17.0
    state.dataHeatBalFanSys.TempTstatAir[2] = 16.0
    state.dataHeatBalFanSys.TempTstatAir[3] = 15.0
    state.dataHeatBalFanSys.TempTstatAir[4] = 14.0
    state.dataHeatBalFanSys.TempTstatAir[5] = 10.0
    state.dataHeatBalFanSys.TempTstatAir[6] = 8.0
    state.dataHeatBalFanSys.zoneTstatSetpts.allocate(7)
    for i in range(7):
        state.dataHeatBalFanSys.zoneTstatSetpts[i].setptLo = 19.0 # all zones use same set point temperature
        state.dataHeatBalFanSys.zoneTstatSetpts[i].setptHi = 24.0
    state.dataZoneCtrls.OccRoomTSetPointHeat.allocate(7)
    state.dataZoneCtrls.OccRoomTSetPointCool.allocate(7)
    state.dataZoneCtrls.OccRoomTSetPointHeat = 19.0 # all zones use same set point temperature
    state.dataZoneCtrls.OccRoomTSetPointCool = 24.0
    Avail.ManageSystemAvailability(*state) # 1st time through just gets input
    state.dataAvail.ZoneComp[11].TotalNumComp = 1 # where 11 = ZoneHVAC:TerminalUnit:VariableRefrigerantFlow
    state.dataAvail.ZoneComp[11].ZoneCompAvailMgrs.allocate(1)
    state.dataAvail.ZoneComp[11].ZoneCompAvailMgrs[0].NumAvailManagers = 1
    state.dataAvail.ZoneComp[11].ZoneCompAvailMgrs[0].ZoneNum = 7
    state.dataAvail.ZoneComp[11].ZoneCompAvailMgrs[0].availManagers.allocate(1)
    state.dataAvail.ZoneComp[11].ZoneCompAvailMgrs[0].availManagers[0].type = Avail.ManagerType.OptimumStart
    state.dataAvail.ZoneComp[11].ZoneCompAvailMgrs[0].availManagers[0].Name = "OptStart Availability 4"
    state.dataAvail.ZoneComp[11].ZoneCompAvailMgrs[0].availManagers[0].Num = 4
    state.dataGlobal.WarmupFlag = true
    state.dataGlobal.BeginDayFlag = true # initialize optimum start data to beginning of day data
    state.dataGlobal.CurrentTime = 1.0   # set the current time to 1 AM
    Avail.ManageSystemAvailability(*state)
    assert_equal(3, state.dataAvail.OptimumStartData[0].ATGWCZoneNumLo) # zone 3 is farthest from heating set point
    assert_equal(1,
              state.dataAvail.OptimumStartData[0].ATGWCZoneNumHi)   # zone 1 is default for cooling set point when heating load exists
    assert_equal(-3.0, state.dataAvail.OptimumStartData[0].TempDiffLo) # zone 3 is 3C below set point
    assert_equal(0.0, state.dataAvail.OptimumStartData[0].TempDiffHi)  # cooling data did not get set so is 0
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.OptimumStartData[0].availStatus)) # avail manager should not yet be set
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.OptimumStartData[1].availStatus)) # avail manager should not be set until 6 AM
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.OptimumStartData[3].availStatus)) # ZoneHVAC avail manager not set until 6 AM
    state.dataGlobal.WarmupFlag = false
    state.dataGlobal.BeginDayFlag = false # start processing temp data to find optimum start time
    state.dataGlobal.CurrentTime = 2.0    # set the current time to 2 AM
    Avail.ManageSystemAvailability(*state)
    assert_equal(3, state.dataAvail.OptimumStartData[0].ATGWCZoneNumLo) # zone 3 is farthest from heating set point
    assert_equal(1,
              state.dataAvail.OptimumStartData[0].ATGWCZoneNumHi)   # zone 1 is default for cooling set point when heating load exists
    assert_equal(-3.0, state.dataAvail.OptimumStartData[0].TempDiffLo) # zone 3 is 3C below set point
    assert_equal(0.0, state.dataAvail.OptimumStartData[0].TempDiffHi)  # cooling data did not get set so is 0
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.OptimumStartData[0].availStatus)) # avail manager should not yet be set
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.OptimumStartData[1].availStatus)) # avail manager should not be set until 6 AM
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.OptimumStartData[3].availStatus)) # ZoneHVAC avail manager not set until 6 AM
    state.dataGlobal.CurrentTime = 7.0 # set the current time to 7 AM which is past time to pre-start HVAC
    Avail.ManageSystemAvailability(*state)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.OptimumStartData[0].availStatus)) # avail manager should be set to cycle on
    assert_equal(1.5, state.dataAvail.OptimumStartData[0].NumHoursBeforeOccupancy)                  # 1.5 hours = 3C from SP divided by 2C/hour
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.OptimumStartData[1].availStatus)) # avail manager should be set at 6 AM
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.OptimumStartData[3].availStatus)) # ZoneHVAC avail manager set at 6 AM
    assert_true(state.dataAvail.OptStart[6].OptStartFlag) # ZoneHVAC avail manager set to cycle on for Zone 7
    state.dataGlobal.CurrentTime = 5.00 # set the current time to 5:00 AM, before max optimum start time
    Avail.ManageSystemAvailability(*state)
    assert_false(state.dataAvail.OptStart[5].OptStartFlag) # avail manager should be set to no action for Zone 6
    assert_false(state.dataAvail.OptStart[6].OptStartFlag) # ZoneHVAC avail manager set to no action for Zone 7
    state.dataGlobal.CurrentTime = 6.50                    # set the current time to 6:30 AM when occupancy begins
    Avail.ManageSystemAvailability(*state)
    assert_true(state.dataAvail.OptStart[5].OptStartFlag) # avail manager should be set to cycle on for Zone 6
    assert_true(state.dataAvail.OptStart[6].OptStartFlag) # ZoneHVAC avail manager set to cycle on for Zone 7
    ZoneTempPredictorCorrector.GetZoneAirSetPoints(*state)
    state.dataHeatBalFanSys.TempControlType.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.TempControlTypeRpt.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.zoneTstatSetpts.allocate(state.dataGlobal.NumOfZones)
    state.dataGlobal.CurrentTime = 19.0 # set the current time to 7 PM which is post-occupancy
    Avail.ManageSystemAvailability(*state)
    ZoneTempPredictorCorrector.CalcZoneAirTempSetPoints(*state)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.OptimumStartData[0].availStatus)) # avail manager should be set to no action
    assert_equal(15.0, state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo)                           # 15.0C is the unoccupied heating setpoint
    assert_equal(29.4, state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi)                           # 29.4C is the unoccupied cooling setpoint

@test
def SysAvailManager_NightCycle_ZoneOutOfTolerance():
    var NumZones: Int = 4
    state.dataHeatBalFanSys.TempControlType.allocate(NumZones)
    state.dataHeatBalFanSys.TempControlTypeRpt.allocate(NumZones)
    state.dataHeatBalFanSys.TempTstatAir.allocate(NumZones)
    state.dataHeatBalFanSys.zoneTstatSetpts.allocate(NumZones)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.SingleCool
    state.dataHeatBalFanSys.TempTstatAir[0] = 30.0
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setpt = 25.0
    state.dataHeatBalFanSys.TempControlType[1] = HVAC.SetptType.SingleHeatCool
    state.dataHeatBalFanSys.TempTstatAir[1] = 25.0
    state.dataHeatBalFanSys.zoneTstatSetpts[1].setpt = 25.0
    state.dataHeatBalFanSys.TempControlType[2] = HVAC.SetptType.SingleHeat
    state.dataHeatBalFanSys.TempTstatAir[2] = 10.0
    state.dataHeatBalFanSys.zoneTstatSetpts[2].setpt = 20.0
    state.dataHeatBalFanSys.TempControlType[3] = HVAC.SetptType.DualHeatCool
    state.dataHeatBalFanSys.TempTstatAir[3] = 30.0
    state.dataHeatBalFanSys.zoneTstatSetpts[3].setptHi = 25.0
    state.dataHeatBalFanSys.zoneTstatSetpts[3].setptLo = 20.0
    var TempTol: Float64 = 0.5
    var ZoneNumList: DynamicArray[Int]
    ZoneNumList.allocate(NumZones)
    ZoneNumList[0] = 3
    ZoneNumList[1] = 2
    ZoneNumList[2] = 1
    ZoneNumList[3] = 4
    assert_true(Avail.CoolingZoneOutOfTolerance(*state, ZoneNumList, NumZones, TempTol))
    assert_true(Avail.HeatingZoneOutOfTolerance(*state, ZoneNumList, NumZones, TempTol))
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.1
    state.dataHeatBalFanSys.TempTstatAir[1] = 24.9
    state.dataHeatBalFanSys.TempTstatAir[2] = 19.8
    state.dataHeatBalFanSys.TempTstatAir[3] = 23.0
    assert_false(Avail.CoolingZoneOutOfTolerance(*state, ZoneNumList, NumZones, TempTol))
    assert_false(Avail.HeatingZoneOutOfTolerance(*state, ZoneNumList, NumZones, TempTol))
    state.dataHeatBalFanSys.TempControlType.deallocate()
    state.dataHeatBalFanSys.TempTstatAir.deallocate()
    state.dataHeatBalFanSys.zoneTstatSetpts.deallocate()
    ZoneNumList.deallocate()

@test
def SysAvailManager_HybridVentilation_OT_CO2Control():
    state.dataAvail.HybridVentData.allocate(1)
    state.dataAirLoop.PriAirSysAvailMgr.allocate(1)
    state.dataHeatBal.Zone.allocate(1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataContaminantBalance.ZoneAirCO2.allocate(1)
    state.dataContaminantBalance.ZoneCO2SetPoint.allocate(1)
    state.dataAirLoop.PriAirSysAvailMgr.allocate(1)
    state.dataAvail.SchedData.allocate(1)
    state.dataAvail.ZoneComp.allocate(DataZoneEquipment.NumValidSysAvailZoneComponents)
    state.dataHeatBalFanSys.TempControlType.allocate(1)
    state.dataHeatBalFanSys.TempControlTypeRpt.allocate(1)
    state.dataHeatBalFanSys.zoneTstatSetpts.allocate(1)
    state.dataAvail.HybridVentData[0].Name = "HybridControl"
    state.dataAvail.HybridVentData[0].ControlledZoneNum = 1
    state.dataAvail.HybridVentData[0].AirLoopNum = 1
    state.dataAvail.HybridVentData[0].controlModeSched = Sched.AddScheduleConstant(*state, "CONTROL MODE")
    state.dataAvail.HybridVentData[0].UseRainIndicator = false
    state.dataAvail.HybridVentData[0].MaxWindSpeed = 40.0
    state.dataAvail.HybridVentData[0].MinOutdoorTemp = 15.0
    state.dataAvail.HybridVentData[0].MaxOutdoorTemp = 35.0
    state.dataAvail.HybridVentData[0].MinOutdoorEnth = 20000.0
    state.dataAvail.HybridVentData[0].MaxOutdoorEnth = 30000.0
    state.dataAvail.HybridVentData[0].MinOutdoorDewPoint = 15.0
    state.dataAvail.HybridVentData[0].MaxOutdoorDewPoint = 35.0
    state.dataAvail.HybridVentData[0].minOASched = Sched.AddScheduleConstant(*state, "MIN OA")
    state.dataAvail.HybridVentData[0].MinOperTime = 10.0
    state.dataAvail.HybridVentData[0].MinVentTime = 10.0
    state.dataAvail.HybridVentData[0].TimeVentDuration = 0.0
    state.dataAvail.HybridVentData[0].TimeOperDuration = 0.0
    state.dataHeatBal.Zone[0].OutDryBulbTemp = 20.0
    state.dataHeatBal.Zone[0].WindSpeed = 5.0
    state.dataAvail.HybridVentData[0].ctrlType = Avail.VentCtrlType.OperT80 # 80% acceptance
    state.dataThermalComforts.runningAverageASH = 20.0
    var zoneHB1 = state.dataZoneTempPredictorCorrector.zoneHeatBalance[0]
    zoneHB1.MAT = 23.0
    zoneHB1.MRT = 27.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Open), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # Vent open
    zoneHB1.MAT = 26.0
    zoneHB1.MRT = 30.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Close), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # System operation
    state.dataAvail.HybridVentData[0].ctrlType = Avail.VentCtrlType.OperT90 # 90% acceptance
    zoneHB1.MAT = 23.0
    zoneHB1.MRT = 27.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Open), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # Vent open
    zoneHB1.MAT = 26.0
    zoneHB1.MRT = 30.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Close), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # System operation
    state.dataAvail.HybridVentData[0].ctrlType = Avail.VentCtrlType.CO2 # CO2 control with an AirLoop
    state.dataContaminantBalance.ZoneAirCO2[0] = 900.0
    state.dataContaminantBalance.ZoneCO2SetPoint[0] = 800.0
    state.dataAvail.HybridVentData[0].HybridVentMgrConnectedToAirLoop = true
    state.dataAirLoop.PriAirSysAvailMgr[0].NumAvailManagers = 1
    state.dataAirLoop.PriAirSysAvailMgr[0].availManagers.allocate(1)
    state.dataAirLoop.PriAirSysAvailMgr[0].availStatus = Avail.Status.ForceOff
    state.dataAirLoop.PriAirSysAvailMgr[0].availManagers[0].type = Avail.ManagerType.Scheduled # Scheduled
    state.dataAirLoop.PriAirSysAvailMgr[0].availManagers[0].Name = "Avail 1"
    state.dataAirLoop.PriAirSysAvailMgr[0].availManagers[0].Num = 1
    var availSched = state.dataAvail.SchedData[0].availSched = Sched.AddScheduleConstant(*state, "AVAIL")
    availSched.currentVal = 1
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Close), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # System operation
    availSched.currentVal = 0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Open), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # Vent open
    state.dataContaminantBalance.ZoneAirCO2[0] = 500.0
    state.dataContaminantBalance.ZoneCO2SetPoint[0] = 800.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.NoAction), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # No action
    state.dataAvail.ZoneComp[0].TotalNumComp = 1 #  CO2 control with zone equipment
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs.allocate(1)
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].availStatus = Avail.Status.CycleOn
    state.dataContaminantBalance.ZoneAirCO2[0] = 900.0
    state.dataAvail.HybridVentData[0].HybridVentMgrConnectedToAirLoop = false
    state.dataAvail.HybridVentData[0].SimHybridVentSysAvailMgr = true
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Close), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # System operation
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].availStatus = Avail.Status.ForceOff
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Open), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # Vent open
    state.dataHeatBal.Zone[0].OutDryBulbTemp = 40.0
    state.dataAvail.HybridVentData[0].ctrlType = Avail.VentCtrlType.Temp     # Temperature control
    state.dataAvail.HybridVentData[0].ctrlStatus = Avail.VentCtrlStatus.Open # Open
    state.dataAvail.HybridVentData[0].TimeOperDuration = 5.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Open), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # No change
    state.dataAvail.HybridVentData[0].TimeOperDuration = 11.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Close), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # Can change
    state.dataAvail.HybridVentData[0].ctrlStatus = Avail.VentCtrlStatus.Close # close
    state.dataAvail.HybridVentData[0].TimeOperDuration = 0.0
    state.dataAvail.HybridVentData[0].TimeVentDuration = 5.0
    state.dataHeatBal.Zone[0].OutDryBulbTemp = 20.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Close), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # No change
    state.dataAvail.HybridVentData[0].TimeVentDuration = 11.0
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.SingleHeat
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setpt = 25.0
    Avail.CalcHybridVentSysAvailMgr(*state, 1, 1)
    assert_equal(Int(Avail.VentCtrlStatus.Open), Int(state.dataAvail.HybridVentData[0].ctrlStatus)) # Can change

@test
def SysAvailManager_NightCycleGetInput():
    var idf_objects: String = delimited_string({
        "  AvailabilityManager:NightCycle,",
        "    VAV Sys 1 Avail,         !- Name",
        "    SysAvailApplicSch,       !- Applicability Schedule Name",
        "    FanAvailSched,           !- Fan Schedule Name",
        "    CycleOnAny,              !- Control Type",
        "    1,                       !- Thermostat Tolerance {deltaC}",
        "    FixedRunTime,            !- Cycling Run Time Control Type",
        "    7200.0;                  !- Cycling Run Time {s}",
        "  Schedule:Compact,",
        "    SysAvailApplicSch,       !- Name",
        "    On/Off,                  !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 9",
        "    For: AllDays,            !- Field 10",
        "    Until: 24:00,1.0;        !- Field 11",
        " Schedule:Compact,",
        "   FanAvailSched,            !- Name",
        "   Fraction,                 !- Schedule Type Limits Name",
        "   Through: 12/31,           !- Field 1",
        "   For: AllDays,             !- Field 2",
        "   Until:  7:00, 0.0,        !- Field 3",
        "   Until: 24:00, 1.0;        !- Field 3",
        "  AvailabilityManager:NightCycle,",
        "    VAV Sys 2 Avail,         !- Name",
        "    SysAvailApplicSch,       !- Applicability Schedule Name",
        "    FanAvailSched,           !- Fan Schedule Name",
        "    CycleOnAny,              !- Control Type",
        "    1,                       !- Thermostat Tolerance {deltaC}",
        "    Thermostat,              !- Cycling Run Time Control Type",
        "    7200.0;                  !- Cycling Run Time {s}",
        "  AvailabilityManager:NightCycle,",
        "    VAV Sys 3 Avail,         !- Name",
        "    SysAvailApplicSch,       !- Applicability Schedule Name",
        "    FanAvailSched,           !- Fan Schedule Name",
        "    CycleOnAny,              !- Control Type",
        "    1,                       !- Thermostat Tolerance {deltaC}",
        "    ThermostatWithMinimumRunTime, !- Cycling Run Time Control Type",
        "    7200.0;                  !- Cycling Run Time {s}",
    })
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
    state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
    state.init_state(*state)
    Avail.GetSysAvailManagerInputs(*state)
    assert_equal(3, state.dataAvail.NumNCycSysAvailMgrs)
    assert_equal(Avail.CyclingRunTimeControl.FixedRunTime, state.dataAvail.NightCycleData[0].cyclingRunTimeControl)
    assert_equal(Avail.CyclingRunTimeControl.Thermostat, state.dataAvail.NightCycleData[1].cyclingRunTimeControl)
    assert_equal(Avail.CyclingRunTimeControl.ThermostatWithMinimumRunTime, state.dataAvail.NightCycleData[2].cyclingRunTimeControl)

@test
def SysAvailManager_NightCycleZone_CalcNCycSysAvailMgr():
    var NumZones: Int = 1
    var SysAvailNum: Int = 1
    var PriAirSysNum: Int = 0
    var ZoneEquipType: Int = 1
    var CompNum: Int = 1
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.Zone.allocate(NumZones)
    state.dataHeatBal.Zone[0].Name = "SPACE1-1"
    state.dataAvail.ZoneComp.allocate(1)
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs.allocate(1)
    state.dataAvail.ZoneComp[0].TotalNumComp = 1
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].availStatus = Avail.Status.NoAction
    state.dataHeatBalFanSys.TempControlType.allocate(NumZones)
    state.dataHeatBalFanSys.TempControlTypeRpt.allocate(NumZones)
    state.dataHeatBalFanSys.TempTstatAir.allocate(NumZones)
    state.dataHeatBalFanSys.zoneTstatSetpts.allocate(NumZones)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.SingleCool
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setpt = 25.0
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.1
    state.dataAvail.NightCycleData.allocate(NumZones)
    state.dataAvail.NightCycleData[0].Name = "System Avail"
    state.dataAvail.NightCycleData[0].nightCycleControlType = Avail.NightCycleControlType.OnAny
    var availSched = state.dataAvail.NightCycleData[0].availSched = Sched.AddScheduleConstant(*state, "AVAIL")
    var fanSched = state.dataAvail.NightCycleData[0].fanSched = Sched.AddScheduleConstant(*state, "FAN")
    state.dataAvail.NightCycleData[0].TempTolRange = 0.4
    state.dataAvail.NightCycleData[0].CyclingTimeSteps = 4
    state.dataAvail.NightCycleData[0].CtrlZoneListName = state.dataHeatBal.Zone[0].Name
    state.dataAvail.NightCycleData[0].NumOfCtrlZones = NumZones
    state.dataAvail.NightCycleData[0].CtrlZonePtrs.allocate(1)
    state.dataAvail.NightCycleData[0].CtrlZonePtrs[0] = 1
    state.dataAvail.NightCycleData[0].CoolingZoneListName = state.dataHeatBal.Zone[0].Name
    state.dataAvail.NightCycleData[0].NumOfCoolingZones = NumZones
    state.dataAvail.NightCycleData[0].CoolingZonePtrs = NumZones
    availSched.currentVal = 1
    fanSched.currentVal = 0
    state.dataGlobal.SimTimeSteps = 0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StartTime = 0.0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StopTime = 4.0
    state.dataAvail.NightCycleData[0].cyclingRunTimeControl = Avail.CyclingRunTimeControl.FixedRunTime
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.NoAction
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum, ZoneEquipType, CompNum)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StartTime = 4.0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StopTime = 4.0
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.CycleOn
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum, ZoneEquipType, CompNum)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataAvail.NightCycleData[0].nightCycleControlType = Avail.NightCycleControlType.OnControlZone
    state.dataAvail.NightCycleData[0].cyclingRunTimeControl = Avail.CyclingRunTimeControl.Thermostat
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.NoAction
    state.dataGlobal.SimTimeSteps = 0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StartTime = 0.0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StopTime = 4.0
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum, ZoneEquipType, CompNum)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StartTime = 4.0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StopTime = 4.0
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.NoAction
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.1
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum, ZoneEquipType, CompNum)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StartTime = 4.0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StopTime = 4.0
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.CycleOn
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.04
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum, ZoneEquipType, CompNum)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StartTime = 4.0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StopTime = 4.0
    state.dataAvail.NightCycleData[0].cyclingRunTimeControl = Avail.CyclingRunTimeControl.ThermostatWithMinimumRunTime
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.NoAction
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.1
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum, ZoneEquipType, CompNum)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StartTime = 4.0
    state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StopTime = 4.0
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.CycleOn
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.04
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum, ZoneEquipType, CompNum)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.WarmupFlag = true
    state.dataGlobal.BeginDayFlag = true
    state.dataGlobal.SimTimeSteps = 96
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum, ZoneEquipType, CompNum)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.NightCycleData[0].availStatus))
    assert_equal(state.dataGlobal.SimTimeSteps, state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StartTime)
    assert_equal(state.dataGlobal.SimTimeSteps, state.dataAvail.ZoneComp[0].ZoneCompAvailMgrs[0].StopTime)

@test
def SysAvailManager_NightCycleSys_CalcNCycSysAvailMgr():
    var NumZones: Int = 1
    var SysAvailNum: Int = 1
    var PriAirSysNum: Int = 1
    state.dataGlobal.NumOfZones = 1
    state.dataAirLoop.PriAirSysAvailMgr.allocate(PriAirSysNum)
    state.dataAvail.NightCycleData.allocate(NumZones)
    state.dataHeatBalFanSys.TempControlType.allocate(NumZones)
    state.dataHeatBalFanSys.TempControlTypeRpt.allocate(NumZones)
    state.dataHeatBalFanSys.TempTstatAir.allocate(NumZones)
    state.dataHeatBalFanSys.zoneTstatSetpts.allocate(NumZones)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.SingleCool
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setpt = 25.0
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.1
    state.dataHeatBal.Zone.allocate(NumZones)
    state.dataHeatBal.Zone[0].Name = "SPACE1-1"
    state.dataAirLoop.AirToZoneNodeInfo.allocate(1)
    state.dataAirLoop.AirToZoneNodeInfo[0].NumZonesCooled = 1
    state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums.allocate(1)
    state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums[0] = 1
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "SPACE1-1"
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode = 1
    state.dataAvail.NightCycleData[0].Name = "System Avail"
    state.dataAvail.NightCycleData[0].nightCycleControlType = Avail.NightCycleControlType.OnAny
    var availSched = state.dataAvail.NightCycleData[0].availSched = Sched.AddScheduleConstant(*state, "AVAIL")
    var fanSched = state.dataAvail.NightCycleData[0].fanSched = Sched.AddScheduleConstant(*state, "FAN")
    state.dataAvail.NightCycleData[0].TempTolRange = 0.4
    state.dataAvail.NightCycleData[0].CyclingTimeSteps = 4
    state.dataAvail.NightCycleData[0].CtrlZoneListName = state.dataHeatBal.Zone[0].Name
    state.dataAvail.NightCycleData[0].NumOfCtrlZones = NumZones
    state.dataAvail.NightCycleData[0].CtrlZonePtrs.allocate(1)
    state.dataAvail.NightCycleData[0].CtrlZonePtrs[0] = 1
    state.dataAvail.NightCycleData[0].CoolingZoneListName = state.dataHeatBal.Zone[0].Name
    state.dataAvail.NightCycleData[0].NumOfCoolingZones = NumZones
    state.dataAvail.NightCycleData[0].CoolingZonePtrs = NumZones
    availSched.currentVal = 1
    fanSched.currentVal = 0
    state.dataGlobal.SimTimeSteps = 0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StartTime = 0.0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StopTime = 4.0
    state.dataAvail.NightCycleData[0].cyclingRunTimeControl = Avail.CyclingRunTimeControl.FixedRunTime
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.NoAction
    state.dataAvail.NightCycleData[0].priorAvailStatus = Avail.Status.CycleOn
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StartTime = 4.0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StopTime = 4.0
    state.dataAvail.NightCycleData[0].cyclingRunTimeControl = Avail.CyclingRunTimeControl.FixedRunTime
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.CycleOn
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataAvail.NightCycleData[0].nightCycleControlType = Avail.NightCycleControlType.OnControlZone
    state.dataAvail.NightCycleData[0].cyclingRunTimeControl = Avail.CyclingRunTimeControl.Thermostat
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.NoAction
    state.dataGlobal.SimTimeSteps = 0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StartTime = 0.0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StopTime = 4.0
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StartTime = 4.0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StopTime = 4.0
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.NoAction
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.1
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StartTime = 4.0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StopTime = 4.0
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.CycleOn
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.04
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StartTime = 4.0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StopTime = 4.0
    state.dataAvail.NightCycleData[0].cyclingRunTimeControl = Avail.CyclingRunTimeControl.ThermostatWithMinimumRunTime
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.NoAction
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.1
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum)
    assert_equal(Int(Avail.Status.CycleOn), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.SimTimeSteps = 4
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StartTime = 4.0
    state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StopTime = 4.0
    state.dataAvail.NightCycleData[0].availStatus = Avail.Status.CycleOn
    state.dataHeatBalFanSys.TempTstatAir[0] = 25.04
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.NightCycleData[0].availStatus))
    state.dataGlobal.WarmupFlag = true
    state.dataGlobal.BeginDayFlag = true
    state.dataGlobal.SimTimeSteps = 96
    Avail.CalcNCycSysAvailMgr(*state, SysAvailNum, PriAirSysNum)
    assert_equal(Int(Avail.Status.NoAction), Int(state.dataAvail.NightCycleData[0].availStatus))
    assert_equal(state.dataGlobal.SimTimeSteps, state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StartTime)
    assert_equal(state.dataGlobal.SimTimeSteps, state.dataAirLoop.PriAirSysAvailMgr[PriAirSysNum - 1].StopTime)