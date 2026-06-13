"""
EnergyPlus Zone Equipment Manager module (Mojo port)

EXTERNAL DEPS (to wire in glue):
  - state.dataGlobal (NumOfZones, BeginEnvrnFlag, etc.)
  - state.dataZoneEquip (ZoneEquipConfig, ZoneEquipList, SupplyAirPath, etc.)
  - state.dataZoneEnergyDemand (ZoneSysEnergyDemand, ZoneSysMoistureDemand, etc.)
  - state.dataSize (ZoneSizing, CalcZoneSizing, FinalZoneSizing, etc.)
  - state.dataHeatBal (Zone, space, Mixing, Infiltration, Ventilation, etc.)
  - state.dataEnvrn (OutDryBulbTemp, OutHumRat, StdRhoAir, StdBaroPress, etc.)
  - state.dataLoopNodes (Node)
  - state.dataHVACGlobal (various flags and flows)
  - state.dataZoneTempPredictorCorrector (zoneHeatBalance, spaceHeatBalance)
  - state.dataHeatBalFanSys (zoneTstatSetpts, etc.)
  - state.dataAirLoop (AirLoopFlow, AirToZoneNodeInfo)
  - state.dataDefineEquipment (AirDistUnit)
  - state.dataAirSystemsData (PrimaryAirSystems)
  - state.dataContaminantBalance (Contaminant, MixingMassFlowCO2, etc.)
  - state.dataConvergParams (CallIndicator enum)
  - state.dataDuctLoss (DuctLossSimu, SysSen, SysLat)
  - state.dataRoomAir (AirPatternZoneInfo)
  - state.dataSurface (Surface, SurfWinAirflowThisTS, etc.)
  - state.afn (AirflowNetwork flags)
  - state.files (eio, zsz, spsz file objects)
  - Psychrometrics module (Psy* functions)
  - General module (MovingAvg, ParseTime, etc.)
  - DisplayRoutines module (ShowWarningError, ShowFatalError, etc.)
  - ScheduleManager module (Schedule objects)
  - EMSManager module (ManageEMS)
  - DataStringGlobals (CharComma, CharTab)
  - HVACInterfaceManager, ZonePlenum, SplitterComponent, etc. (equipment sim)
"""

from math import sqrt, abs, pow, min, max, floor
import math


struct SimulationOrder:
    """Zone equipment simulation priority order record."""
    var EquipTypeName: String
    var equipType: Int32
    var EquipName: String
    var EquipPtr: Int32
    var CoolingPriority: Int32
    var HeatingPriority: Int32

    fn __init__(inout self):
        self.EquipTypeName = ""
        self.equipType = -1
        self.EquipName = ""
        self.EquipPtr = 0
        self.CoolingPriority = 0
        self.HeatingPriority = 0


struct ZoneEquipmentManagerData:
    """Persistent state for zone equipment manager."""
    var AvgData: List[Float64]
    var NumOfTimeStepInDay: Int32
    var GetZoneEquipmentInputFlag: Bool
    var SizeZoneEquipmentOneTimeFlag: Bool
    var PrioritySimOrder: List[SimulationOrder]
    var InitZoneEquipmentOneTimeFlag: Bool
    var InitZoneEquipmentEnvrnFlag: Bool
    var FirstPassZoneEquipFlag: Bool

    fn __init__(inout self):
        self.AvgData = List[Float64]()
        self.NumOfTimeStepInDay = 0
        self.GetZoneEquipmentInputFlag = True
        self.SizeZoneEquipmentOneTimeFlag = True
        self.PrioritySimOrder = List[SimulationOrder]()
        self.InitZoneEquipmentOneTimeFlag = True
        self.InitZoneEquipmentEnvrnFlag = True
        self.FirstPassZoneEquipFlag = True

    fn clear_state(inout self):
        """Reset to initial state."""
        self.__init__()


# ==================== Main Functions ====================

fn ManageZoneEquipment(
    inout state: EnergyPlusData,
    FirstHVACIteration: Bool,
    inout SimZone: Bool,
    inout SimAir: Bool
):
    """
    Main manager for zone equipment simulation.
    """
    InitZoneEquipment(state, FirstHVACIteration)

    if state.dataGlobal.ZoneSizingCalc:
        SizeZoneEquipment(state)
    else:
        SimZoneEquipment(state, FirstHVACIteration, SimAir)
        state.dataZoneEquip.ZoneEquipSimulatedOnce = True

    UpdateZoneEquipment(state, SimAir)

    SimZone = False


fn GetZoneEquipment(inout state: EnergyPlusData):
    """Get zone equipment configuration from input."""
    var zem = state.dataZoneEquipmentManager
    if zem.GetZoneEquipmentInputFlag:
        # GetZoneEquipmentData would be called here
        # (external function not translated)
        zem.GetZoneEquipmentInputFlag = False
        state.dataZoneEquip.ZoneEquipInputsFilled = True

        zem.NumOfTimeStepInDay = state.dataGlobal.TimeStepsInHour * 24

        var MaxNumOfEquipTypes: Int32 = 0
        for Counter in range(1, state.dataGlobal.NumOfZones + 1):
            if not state.dataZoneEquip.ZoneEquipConfig[Counter - 1].IsControlled:
                continue
            MaxNumOfEquipTypes = max(
                MaxNumOfEquipTypes,
                state.dataZoneEquip.ZoneEquipList[Counter - 1].NumOfEquipTypes
            )

        zem.PrioritySimOrder = List[SimulationOrder]()
        for _ in range(MaxNumOfEquipTypes):
            zem.PrioritySimOrder.append(SimulationOrder())


fn InitZoneEquipment(inout state: EnergyPlusData, FirstHVACIteration: Bool):
    """Initialize zone equipment for simulation."""
    var zem = state.dataZoneEquipmentManager

    if zem.InitZoneEquipmentOneTimeFlag:
        zem.InitZoneEquipmentOneTimeFlag = False
        # state.dataSize.ZoneEqSizing.allocate(state.dataGlobal.NumOfZones)

        for ControlledZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
            if not state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1].IsControlled:
                continue
            if state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1].EquipListIndex == 0:
                continue

            var ZoneEquipCount: Int32 = state.dataZoneEquip.ZoneEquipList[
                state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1].EquipListIndex - 1
            ].NumOfEquipTypes

            var thisZoneSysEnergyDemand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum - 1]
            thisZoneSysEnergyDemand.NumZoneEquipment = ZoneEquipCount
            # Allocate arrays - placeholder for actual implementation
            # thisZoneSysEnergyDemand.SequencedOutputRequired.allocate(ZoneEquipCount)

            var thisZoneSysMoistureDemand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ControlledZoneNum - 1]
            thisZoneSysMoistureDemand.NumZoneEquipment = ZoneEquipCount

    # Begin environment initialization
    if zem.InitZoneEquipmentEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        state.dataZoneEquip.ZoneEquipAvail = 0

        if state.dataAvail.ZoneComp.size() > 0:
            for ZoneEquipType in range(state.dataAvail.ZoneComp.size()):
                if state.dataAvail.ZoneComp[ZoneEquipType].ZoneCompAvailMgrs.size() > 0:
                    for ZoneCompNum in range(state.dataAvail.ZoneComp[ZoneEquipType].ZoneCompAvailMgrs.size()):
                        state.dataAvail.ZoneComp[ZoneEquipType].ZoneCompAvailMgrs[ZoneCompNum].availStatus = 0
                        state.dataAvail.ZoneComp[ZoneEquipType].ZoneCompAvailMgrs[ZoneCompNum].StartTime = 0
                        state.dataAvail.ZoneComp[ZoneEquipType].ZoneCompAvailMgrs[ZoneCompNum].StopTime = 0

        for thisZoneEquipConfig in state.dataZoneEquip.ZoneEquipConfig:
            if not thisZoneEquipConfig.IsControlled:
                continue
            thisZoneEquipConfig.beginEnvirnInit(state)

        zem.InitZoneEquipmentEnvrnFlag = False

    if not state.dataGlobal.BeginEnvrnFlag:
        zem.InitZoneEquipmentEnvrnFlag = True

    # HVAC time step initialization
    for thisZoneEquipConfig in state.dataZoneEquip.ZoneEquipConfig:
        if not thisZoneEquipConfig.IsControlled:
            continue
        thisZoneEquipConfig.hvacTimeStepInit(state, FirstHVACIteration)

    # Air loop initialization
    for airLoop in range(1, state.dataHVACGlobal.NumPrimaryAirSys + 1):
        var airLoopFlow = state.dataAirLoop.AirLoopFlow[airLoop - 1]
        airLoopFlow.SupFlow = 0.0
        airLoopFlow.ZoneRetFlow = 0.0
        airLoopFlow.SysRetFlow = 0.0
        airLoopFlow.RecircFlow = 0.0
        airLoopFlow.LeakFlow = 0.0
        airLoopFlow.ExcessZoneExhFlow = 0.0


fn SizeZoneEquipment(inout state: EnergyPlusData):
    """Perform zone equipment sizing calculations."""
    var zem = state.dataZoneEquipmentManager
    if zem.SizeZoneEquipmentOneTimeFlag:
        SetUpZoneSizingArrays(state)
        zem.SizeZoneEquipmentOneTimeFlag = False

    for ControlledZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
        var zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1]
        if not zoneEquipConfig.IsControlled:
            continue

        var calcZoneSizing = state.dataSize.CalcZoneSizing[state.dataSize.CurOverallSimDay - 1][ControlledZoneNum - 1]
        var zoneSysEnergyDemand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum - 1]
        var zoneSysMoistureDemand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ControlledZoneNum - 1]
        var zone = state.dataHeatBal.Zone[ControlledZoneNum - 1]

        sizeZoneSpaceEquipmentPart1(
            state, zoneEquipConfig, calcZoneSizing,
            zoneSysEnergyDemand, zoneSysMoistureDemand,
            zone, ControlledZoneNum
        )

    CalcZoneMassBalance(state, True)
    CalcZoneLeavingConditions(state, True)

    for ControlledZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
        var zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1]
        if not zoneEquipConfig.IsControlled:
            continue
        sizeZoneSpaceEquipmentPart2(
            state, zoneEquipConfig,
            state.dataSize.CalcZoneSizing[state.dataSize.CurOverallSimDay - 1][ControlledZoneNum - 1],
            ControlledZoneNum
        )


fn sizeZoneSpaceEquipmentPart1(
    inout state: EnergyPlusData,
    inout zoneEquipConfig,
    inout zsCalcSizing,
    inout zsEnergyDemand,
    inout zsMoistureDemand,
    zoneOrSpace,
    zoneNum: Int32,
    spaceNum: Int32 = 0
):
    """Size zone/space equipment Part 1."""
    # Placeholder for complex implementation
    pass


fn sizeZoneSpaceEquipmentPart2(
    inout state: EnergyPlusData,
    inout zoneEquipConfig,
    inout zsCalcSizing,
    zoneNum: Int32,
    spaceNum: Int32 = 0
):
    """Size zone/space equipment Part 2."""
    var returnNodeNum: Int32 = (
        zoneEquipConfig.ReturnNode[0]
        if zoneEquipConfig.NumReturnNodes > 0
        else 0
    )
    var zoneNodeNum: Int32 = (
        state.dataHeatBal.space[spaceNum - 1].SystemZoneNodeNumber
        if spaceNum > 0
        else state.dataHeatBal.Zone[zoneNum - 1].SystemZoneNodeNumber
    )

    var RetTemp: Float64 = (
        state.dataLoopNodes.Node[returnNodeNum - 1].Temp
        if returnNodeNum > 0
        else state.dataLoopNodes.Node[zoneNodeNum - 1].Temp
    )

    var zoneTstatSetpt = state.dataHeatBalFanSys.zoneTstatSetpts[zoneNum - 1]

    if zsCalcSizing.HeatLoad > 0.0:
        zsCalcSizing.HeatZoneRetTemp = RetTemp
        zsCalcSizing.HeatTstatTemp = (
            zoneTstatSetpt.setpt
            if zoneTstatSetpt.setpt > 0.0
            else zoneTstatSetpt.setptLo
        )
        zsCalcSizing.CoolTstatTemp = zoneTstatSetpt.setptHi
    elif zsCalcSizing.CoolLoad > 0.0:
        zsCalcSizing.CoolZoneRetTemp = RetTemp
        zsCalcSizing.CoolTstatTemp = (
            zoneTstatSetpt.setpt
            if zoneTstatSetpt.setpt > 0.0
            else zoneTstatSetpt.setptHi
        )
        zsCalcSizing.HeatTstatTemp = zoneTstatSetpt.setptLo
    else:
        zsCalcSizing.CoolZoneRetTemp = RetTemp
        zsCalcSizing.HeatTstatTemp = zoneTstatSetpt.setptLo
        zsCalcSizing.CoolTstatTemp = zoneTstatSetpt.setptHi


fn SetUpZoneSizingArrays(inout state: EnergyPlusData):
    """Set up zone sizing arrays."""
    # Placeholder
    pass


fn CalcDOASSupCondsForSizing(
    inout state: EnergyPlusData,
    OutDB: Float64,
    OutHR: Float64,
    DOASControl: Int32,
    DOASLowTemp: Float64,
    DOASHighTemp: Float64,
    W90H: Float64,
    W90L: Float64,
    inout DOASSupTemp: Float64,
    inout DOASSupHR: Float64
):
    """Calculate DOAS supply conditions for sizing."""
    DOASSupTemp = 0.0
    DOASSupHR = 0.0

    if DOASControl == 0:  # NeutralSup
        if OutDB < DOASLowTemp:
            DOASSupTemp = DOASLowTemp
            DOASSupHR = OutHR
        elif OutDB > DOASHighTemp:
            DOASSupTemp = DOASHighTemp
            DOASSupHR = min(OutHR, W90H)
        else:
            DOASSupTemp = OutDB
            DOASSupHR = OutHR
    elif DOASControl == 1:  # NeutralDehumSup
        if OutDB < DOASLowTemp:
            DOASSupTemp = DOASHighTemp
            DOASSupHR = OutHR
        else:
            DOASSupTemp = DOASHighTemp
            DOASSupHR = min(OutHR, W90L)
    elif DOASControl == 2:  # CoolSup
        if OutDB < DOASLowTemp:
            DOASSupTemp = DOASHighTemp
            DOASSupHR = OutHR
        else:
            DOASSupTemp = DOASLowTemp
            DOASSupHR = min(OutHR, W90L)


fn calcSizingOA(
    inout state: EnergyPlusData,
    inout zsFinalSizing,
    inout zsCalcFinalSizing,
    inout dsoaError: Bool,
    inout ErrorsFound: Bool,
    zoneNum: Int32,
    spaceNum: Int32 = 0
):
    """Calculate outdoor air requirements for sizing."""
    # Placeholder
    pass


fn fillZoneSizingFromInput(
    inout state: EnergyPlusData,
    zoneSizingInput,
    inout zsSizing,
    inout zsCalcSizing,
    inout zsFinalSizing,
    inout zsCalcFinalSizing,
    zoneOrSpaceName: StringRef,
    zoneOrSpaceNum: Int32
):
    """Fill zone sizing arrays from input data."""
    # Placeholder
    pass


fn RezeroZoneSizingArrays(inout state: EnergyPlusData):
    """Zero zone sizing arrays between pulse and normal sizing."""
    # Placeholder
    pass


fn UpdateZoneSizing(inout state: EnergyPlusData, CallIndicator: Int32):
    """Update zone sizing results."""
    # Placeholder
    pass


fn SimZoneEquipment(inout state: EnergyPlusData, FirstHVACIteration: Bool, inout SimAir: Bool):
    """Simulate zone equipment."""
    # Placeholder
    pass


fn SetZoneEquipSimOrder(inout state: EnergyPlusData, ControlledZoneNum: Int32):
    """Set zone equipment simulation order based on priorities."""
    # Placeholder
    pass


fn InitSystemOutputRequired(
    inout state: EnergyPlusData,
    ZoneNum: Int32,
    FirstHVACIteration: Bool,
    ResetSimOrder: Bool = False
):
    """Initialize system output required."""
    initOutputRequired(
        state, ZoneNum,
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1],
        state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum - 1],
        FirstHVACIteration, ResetSimOrder
    )
    DistributeSystemOutputRequired(state, ZoneNum, FirstHVACIteration)


fn initOutputRequired(
    inout state: EnergyPlusData,
    ZoneNum: Int32,
    inout energy,
    inout moisture,
    FirstHVACIteration: Bool,
    ResetSimOrder: Bool,
    spaceNum: Int32 = 0
):
    """Initialize output required at zone/space level."""
    energy.RemainingOutputRequired = energy.TotalOutputRequired
    energy.UnadjRemainingOutputRequired = energy.TotalOutputRequired
    energy.RemainingOutputReqToHeatSP = energy.OutputRequiredToHeatingSP
    energy.UnadjRemainingOutputReqToHeatSP = energy.OutputRequiredToHeatingSP
    energy.RemainingOutputReqToCoolSP = energy.OutputRequiredToCoolingSP
    energy.UnadjRemainingOutputReqToCoolSP = energy.OutputRequiredToCoolingSP

    moisture.RemainingOutputRequired = moisture.TotalOutputRequired
    moisture.UnadjRemainingOutputRequired = moisture.TotalOutputRequired
    moisture.RemainingOutputReqToHumidSP = moisture.OutputRequiredToHumidifyingSP
    moisture.UnadjRemainingOutputReqToHumidSP = moisture.OutputRequiredToHumidifyingSP
    moisture.RemainingOutputReqToDehumidSP = moisture.OutputRequiredToDehumidifyingSP
    moisture.UnadjRemainingOutputReqToDehumidSP = moisture.OutputRequiredToDehumidifyingSP

    if ResetSimOrder and spaceNum == 0:
        SetZoneEquipSimOrder(state, ZoneNum)


fn DistributeSystemOutputRequired(
    inout state: EnergyPlusData,
    ZoneNum: Int32,
    FirstHVACIteration: Bool
):
    """Distribute system output required."""
    if not state.dataHeatBal.Zone[ZoneNum - 1].IsControlled:
        return
    if state.dataGlobal.ZoneSizingCalc:
        return
    if FirstHVACIteration and (state.dataZoneEquip.ZoneEquipList[ZoneNum - 1].LoadDistScheme not in [1, 2]):
        return

    distributeOutputRequired(
        state, ZoneNum,
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1],
        state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum - 1]
    )


fn distributeOutputRequired(
    inout state: EnergyPlusData,
    ZoneNum: Int32,
    inout energy,
    inout moisture
):
    """Distribute output required across zone equipment."""
    # Placeholder
    pass


fn updateSystemOutputRequired(
    inout state: EnergyPlusData,
    ZoneNum: Int32,
    SysOutputProvided: Float64,
    LatOutputProvided: Float64,
    inout energy,
    inout moisture,
    EquipPriorityNum: Int32 = -1
):
    """Update system output required after equipment simulation."""
    # Placeholder
    pass


fn CalcZoneMassBalance(inout state: EnergyPlusData, FirstHVACIteration: Bool):
    """Calculate zone mass balance."""
    # Placeholder
    pass


fn CalcZoneInfiltrationFlows(
    inout state: EnergyPlusData,
    ZoneNum: Int32,
    ZoneReturnAirMassFlowRate: Float64
):
    """Calculate zone infiltration flows."""
    # Placeholder
    pass


fn CalcZoneLeavingConditions(inout state: EnergyPlusData, FirstHVACIteration: Bool):
    """Calculate zone leaving/return air conditions."""
    # Placeholder
    pass


fn UpdateZoneEquipment(inout state: EnergyPlusData, inout SimAir: Bool):
    """Update zone equipment results."""
    # Placeholder
    pass


fn CalcAirFlowSimple(
    inout state: EnergyPlusData,
    SysTimestepLoop: Int32 = 0,
    AdjustZoneMixingFlowFlag: Bool = False,
    AdjustZoneInfiltrationFlowFlag: Bool = False
):
    """Calculate simple air flows (mixing, infiltration, ventilation)."""
    # Placeholder
    pass


fn GetStandAloneERVNodes(inout state: EnergyPlusData, inout thisZoneAirBalance):
    """Get stand-alone ERV inlet/outlet nodes."""
    # Placeholder
    pass


fn CalcZoneMixingFlowRateOfReceivingZone(
    inout state: EnergyPlusData,
    ZoneNum: Int32,
    inout ZoneMixingMassFlowRate: Float64
):
    """Calculate zone mixing flow rate for receiving zone."""
    # Placeholder
    pass


fn CalcZoneMixingFlowRateOfSourceZone(inout state: EnergyPlusData, ZoneNum: Int32):
    """Calculate zone mixing flow rate for source zone."""
    # Placeholder
    pass


fn AutoCalcDOASControlStrategy(inout state: EnergyPlusData):
    """Auto-calculate DOAS control strategy setpoints."""
    # Placeholder
    pass


fn ReportZoneSizingDOASInputs(
    inout state: EnergyPlusData,
    ZoneName: StringRef,
    DOASCtrlStrategy: StringRef,
    DOASLowTemp: Float64,
    DOASHighTemp: Float64,
    inout headerAlreadyPrinted: Bool
):
    """Report zone sizing DOAS inputs."""
    # Placeholder
    pass
