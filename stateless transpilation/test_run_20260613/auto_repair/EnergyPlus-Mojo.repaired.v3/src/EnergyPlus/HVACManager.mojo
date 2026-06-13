from .AirflowNetwork.src.Solver import ControlType
from .Coils.CoilCoolingDX import CoilCoolingDX
from .Data.EnergyPlusData import EnergyPlusData
from .Data.AirLoop import AirLoopData, AirLoopControlInfo, AirLoopFlow
from .Data.AirSystems import PrimaryAirSystems
from .Data.ConvergParams import DataConvergParams
from .Data.HVACGlobals import DataHVACGlobals
from .Data.HeatBalFanSys import DataHeatBalFanSys, PredictorCorrectorCtrl
from .Data.HeatBalance import AirReportVars, EquipConfiguration, AirBalance, FanType, FanOp, RefDoorMixing
from .Data.LoopNode import Node
from .Data.ReportingFlags import DataReportingFlags
from .Data.Surfaces import WindowAirFlowDestination
from .Data.SystemVariables import DataSystemVariables
from .Data.ZoneEnergyDemands import ZoneSysEnergyDemand
from DemandManager import ManageDemand, UpdateDemandManagers
from DisplayRoutines import DisplayString
from DuctLoss import DuctLossSimu, DuctLoss
from EMSManager import EMSManager, EMSCallFrom
from ElectricPowerServiceManager import ElectricPowerServiceManager
from Fans import Fans, FanType
from General import General, CreateSysTimeIntervalString
from HVACManager import HVACManagerData, ConvErrorCallType, ManageHVAC, SimHVAC, SimSelectedEquipment, ResetTerminalUnitFlowLimits, ResolveAirLoopFlowLimits, ResolveLockoutFlags, ResetHVACControl, ResetNodeData, UpdateZoneListAndGroupLoads, ReportAirHeatBalance, reportAirHeatBal1, reportAirHeatBal2, SetHeatToReturnAirFlag, UpdateZoneInletConvergenceLog, CheckAirLoopFlowBalance, ConvergenceErrors
from HVACSizingSimulationManager import hvacSizingSimulationManager
from IceThermalStorage import UpdateIceFractions
from IndoorGreen import SimIndoorGreen
from InternalHeatGains import UpdateInternalGainValues
from NodeInputManager import NodeInputManager
from NonZoneEquipmentManager import ManageNonZoneEquipment
from OutAirNodeManager import SetOutAirNodes
from OutputProcessor import SetupOutputVariable, UpdateDataandReport, TimeStepType, StoreType
from OutputReportTabular import CalcHeatEmissionReport, UpdateTabularReports, GatherComponentLoadsHVAC
from .Plant.DataPlant import DataPlant, NumConvergenceHistoryTerms, ConvergenceHistoryARR, sum_ConvergenceHistoryARR, square_sum_ConvergenceHistoryARR, sum_square_ConvergenceHistoryARR
from .Plant.PlantManager import GetPlantLoopData, GetPlantInput, SetupInitialPlantCallingOrder, SetupBranchControlTypes, SetupReports, InitOneTimePlantSizingInfo, ManagePlantLoops, ReInitPlantLoopsAtFirstHVACIteration, UpdateNodeThermalHistory
from PlantCondLoopOperation import SetupPlantEMSActuators
from PlantLoopHeatPumpEIR import EIRPlantLoopHeatPump
from PlantUtilities import SetAllPlantSimFlagsToValue, SetAllFlowLocks, ResetAllPlantInterConnectFlags, CheckPlantMixerSplitterConsistency, CheckForRunawayPlantTemps, AnyPlantSplitterMixerLacksContinuity, AnyPlantLoopSidesNeedSim
from PollutionModule import CalculatePollution, InitEnergyReports, ReportSystemEnergyUse, ReportVentilationLoads
from Psychrometrics import Psyrh, PsyCpAirFnW, PsyRhoAirFnPbTdbW, PsyHgAirFnWTdb
from RefrigeratedCase import ManageRefrigeratedCaseRacks
from ScheduleManager import ScheduleManager
from SetPointManager import ManageSetPoints, SetPointManager
from SimAirServingZones import ManageAirLoops
from SizingManager import UpdateFacilitySizing
from SystemAvailabilityManager import ManageSystemAvailability
from SystemReports import SystemReports
from UtilityRoutines import ShowWarningError, ShowContinueError, ShowContinueErrorTimeStamp, ShowSevereError, ShowFatalError, ShowRecurringWarningErrorAtEnd
from WaterManager import ManageWaterInits, ManageWater, ManageWaterInits
from ZoneContaminantPredictorCorrector import ManageZoneContaminanUpdates
from ZoneEquipmentManager import ManageZoneEquipment, CalcAirFlowSimple, UpdateZoneSizing
from ZoneTempPredictorCorrector import ManageZoneAirUpdates, DetectOscillatingZoneTemp, ZoneSpaceHeatBalanceData
from Avail import ManageHybridVentilation, Status
from .Data.Plant import LoopSideLocation, LoopSideKeys, FlowLock
from .Data.HVAC import HVAC
from .Data.Constant import Constant
from ObjexxFCL.Array.functions import isize, sum
from ObjexxFCL.Fmath import min, max

import sys

def ManageHVAC(state: EnergyPlusData) -> None:
    var PriorTimeStep: Float64
    var ZoneTempChange: Float64 = 0.0
    s_hbfs = state.dataHeatBalFanSys

    if state.dataHVACMgr.TriggerGetAFN:
        state.dataHVACMgr.TriggerGetAFN = False
        DisplayString(state, "Initializing HVAC")
        state.afn.manage_balance()

    for i in range(len(state.dataZoneTempPredictorCorrector.zoneHeatBalance)):
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[i]
        thisZoneHB.ZT = thisZoneHB.MAT
        thisZoneHB.ZTAV = 0.0
        thisZoneHB.airHumRatAvg = 0.0

    for i in range(len(state.dataZoneTempPredictorCorrector.spaceHeatBalance)):
        var thisSpaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance[i]
        thisSpaceHB.ZT = thisSpaceHB.MAT
        thisSpaceHB.ZTAV = 0.0
        thisSpaceHB.airHumRatAvg = 0.0

    for i in range(len(s_hbfs.zoneTstatSetpts)):
        var zoneTstatSetpt = s_hbfs.zoneTstatSetpts[i]
        zoneTstatSetpt.setptHiAver = 0.0
        zoneTstatSetpt.setptLoAver = 0.0

    state.dataHVACMgr.PrintedWarmup = False

    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataContaminantBalance.OutdoorCO2 = state.dataContaminantBalance.Contaminant.CO2OutdoorSched.getCurrentVal()
        state.dataContaminantBalance.ZoneAirCO2Avg = 0.0

    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataContaminantBalance.OutdoorGC = state.dataContaminantBalance.Contaminant.genericOutdoorSched.getCurrentVal()
        if state.dataContaminantBalance.ZoneAirGCAvg is not None:
            state.dataContaminantBalance.ZoneAirGCAvg = 0.0

    if state.dataGlobal.BeginEnvrnFlag and state.dataHVACMgr.MyEnvrnFlag:
        state.dataHVACGlobal.AirLoopsSimOnce = False
        state.dataHVACMgr.MyEnvrnFlag = False
        state.dataHVACGlobal.NumOfSysTimeStepsLastZoneTimeStep = 1
        state.dataHVACGlobal.PreviousTimeStep = state.dataGlobal.TimeStepZone

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHVACMgr.MyEnvrnFlag = True

    state.dataHeatBalFanSys.QRadSurfAFNDuct = 0.0
    state.dataHVACGlobal.SysTimeElapsed = 0.0
    state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataHVACGlobal.FirstTimeStepSysFlag = True
    state.dataHVACGlobal.ShortenTimeStepSys = False
    state.dataHVACGlobal.UseZoneTimeStepHistory = True
    PriorTimeStep = state.dataGlobal.TimeStepZone
    state.dataHVACGlobal.NumOfSysTimeSteps = 1
    state.dataHVACGlobal.FracTimeStepZone = state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone

    var anyEMSRan: Bool = False
    EMSManager.ManageEMS(state, EMSCallFrom.BeginTimestepBeforePredictor, anyEMSRan, None)

    OutAirNodeManager.SetOutAirNodes(state)
    RefrigeratedCase.ManageRefrigeratedCaseRacks(state)
    ZoneTempPredictorCorrector.ManageZoneAirUpdates(
        state, PredictorCorrectorCtrl.GetZoneSetPoints, ZoneTempChange,
        state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)

    if state.dataContaminantBalance.Contaminant.SimulateContaminants:
        ZoneContaminantPredictorCorrector.ManageZoneContaminanUpdates(
            state, PredictorCorrectorCtrl.GetZoneSetPoints,
            state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)

    Avail.ManageHybridVentilation(state)
    ZoneEquipmentManager.CalcAirFlowSimple(state)

    if state.afn.simulation_control.type != ControlType.NoMultizoneOrDistribution:
        state.afn.RollBackFlag = False
        state.afn.manage_balance(False)

    SetHeatToReturnAirFlag(state)

    for zoneNum in range(1, state.dataGlobal.NumOfZones + 1):
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum - 1]
        thisZoneHB.SysDepZoneLoadsLagged = thisZoneHB.SysDepZoneLoads
        if state.dataHeatBal.doSpaceHeatBalance:
            for spaceNum in state.dataHeatBal.Zone[zoneNum - 1].spaceIndexes:
                state.dataZoneTempPredictorCorrector.spaceHeatBalance[spaceNum - 1].SysDepZoneLoadsLagged = (
                    thisZoneHB.SysDepZoneLoads * state.dataHeatBal.space[spaceNum - 1].fracZoneVolume)

    IndoorGreen.SimIndoorGreen(state)
    InternalHeatGains.UpdateInternalGainValues(state, True, True)

    ZoneTempPredictorCorrector.ManageZoneAirUpdates(
        state, PredictorCorrectorCtrl.PredictStep, ZoneTempChange,
        state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)

    if state.dataContaminantBalance.Contaminant.SimulateContaminants:
        ZoneContaminantPredictorCorrector.ManageZoneContaminanUpdates(
            state, PredictorCorrectorCtrl.PredictStep,
            state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)

    SimHVAC(state)

    if state.dataGlobal.AnyIdealCondEntSetPointInModel and state.dataGlobal.MetersHaveBeenInitialized and not state.dataGlobal.WarmupFlag:
        state.dataGlobal.RunOptCondEntTemp = True
        while state.dataGlobal.RunOptCondEntTemp:
            SimHVAC(state)

    WaterManager.ManageWaterInits(state)

    if state.dataHVACGlobal.FirstTimeStepSysFlag and state.dataGlobal.MetersHaveBeenInitialized:
        DemandManager.ManageDemand(state)

    state.dataGlobal.BeginTimeStepFlag = False

    ZoneTempPredictorCorrector.ManageZoneAirUpdates(
        state, PredictorCorrectorCtrl.CorrectStep, ZoneTempChange,
        state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)

    if state.dataContaminantBalance.Contaminant.SimulateContaminants:
        ZoneContaminantPredictorCorrector.ManageZoneContaminanUpdates(
            state, PredictorCorrectorCtrl.CorrectStep,
            state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)

    if ZoneTempChange > state.dataConvergeParams.MaxZoneTempDiff and not state.dataGlobal.KickOffSimulation:
        var ZTempTrendsNumSysSteps: Int = int(ZoneTempChange / state.dataConvergeParams.MaxZoneTempDiff + 1.0)
        state.dataHVACGlobal.NumOfSysTimeSteps = min(ZTempTrendsNumSysSteps, state.dataHVACGlobal.LimitNumSysSteps)
        if state.dataHVACGlobal.NumOfSysTimeSteps > 0:
            state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone / state.dataHVACGlobal.NumOfSysTimeSteps
        state.dataHVACGlobal.TimeStepSys = max(state.dataHVACGlobal.TimeStepSys, state.dataConvergeParams.MinTimeStepSys)
        state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        state.dataHVACGlobal.UseZoneTimeStepHistory = False
        state.dataHVACGlobal.ShortenTimeStepSys = True
    else:
        state.dataHVACGlobal.NumOfSysTimeSteps = 1
        state.dataHVACGlobal.UseZoneTimeStepHistory = True

    if state.dataHVACGlobal.UseZoneTimeStepHistory:
        state.dataHVACGlobal.PreviousTimeStep = state.dataGlobal.TimeStepZone

    for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
        if state.dataGlobal.stopSimulation:
            break
        if state.dataHVACGlobal.TimeStepSys < state.dataGlobal.TimeStepZone:
            Avail.ManageHybridVentilation(state)
            ZoneEquipmentManager.CalcAirFlowSimple(state, SysTimestepLoop)
            if state.afn.simulation_control.type != ControlType.NoMultizoneOrDistribution:
                state.afn.RollBackFlag = False
                state.afn.manage_balance(False)
            InternalHeatGains.UpdateInternalGainValues(state, True, True)
            ZoneTempPredictorCorrector.ManageZoneAirUpdates(
                state, PredictorCorrectorCtrl.PredictStep, ZoneTempChange,
                state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
            if state.dataContaminantBalance.Contaminant.SimulateContaminants:
                ZoneContaminantPredictorCorrector.ManageZoneContaminanUpdates(
                    state, PredictorCorrectorCtrl.PredictStep,
                    state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
            SimHVAC(state)
            if state.dataGlobal.AnyIdealCondEntSetPointInModel and state.dataGlobal.MetersHaveBeenInitialized and not state.dataGlobal.WarmupFlag:
                state.dataGlobal.RunOptCondEntTemp = True
                while state.dataGlobal.RunOptCondEntTemp:
                    SimHVAC(state)
            WaterManager.ManageWaterInits(state)
            state.dataHVACGlobal.ShortenTimeStepSys = False
            ZoneTempPredictorCorrector.ManageZoneAirUpdates(
                state, PredictorCorrectorCtrl.CorrectStep, ZoneTempChange,
                state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
            if state.dataContaminantBalance.Contaminant.SimulateContaminants:
                ZoneContaminantPredictorCorrector.ManageZoneContaminanUpdates(
                    state, PredictorCorrectorCtrl.CorrectStep,
                    state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
            ZoneTempPredictorCorrector.ManageZoneAirUpdates(
                state, PredictorCorrectorCtrl.PushSystemTimestepHistories, ZoneTempChange,
                state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
            if state.dataContaminantBalance.Contaminant.SimulateContaminants:
                ZoneContaminantPredictorCorrector.ManageZoneContaminanUpdates(
                    state, PredictorCorrectorCtrl.PushSystemTimestepHistories,
                    state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
            state.dataHVACGlobal.PreviousTimeStep = state.dataHVACGlobal.TimeStepSys

        state.dataHVACGlobal.FracTimeStepZone = state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone

        for ZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
            var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]
            thisZoneHB.ZTAV += thisZoneHB.ZT * state.dataHVACGlobal.FracTimeStepZone
            thisZoneHB.airHumRatAvg += thisZoneHB.airHumRat * state.dataHVACGlobal.FracTimeStepZone
            for spaceNum in state.dataHeatBal.Zone[ZoneNum - 1].spaceIndexes:
                var thisSpaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance[spaceNum - 1]
                thisSpaceHB.ZTAV += thisSpaceHB.ZT * state.dataHVACGlobal.FracTimeStepZone
                thisSpaceHB.airHumRatAvg += thisSpaceHB.airHumRat * state.dataHVACGlobal.FracTimeStepZone
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                state.dataContaminantBalance.ZoneAirCO2Avg[ZoneNum - 1] += (
                    state.dataContaminantBalance.ZoneAirCO2[ZoneNum - 1] * state.dataHVACGlobal.FracTimeStepZone)
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                state.dataContaminantBalance.ZoneAirGCAvg[ZoneNum - 1] += (
                    state.dataContaminantBalance.ZoneAirGC[ZoneNum - 1] * state.dataHVACGlobal.FracTimeStepZone)
            if state.dataZoneTempPredictorCorrector.NumOnOffCtrZone > 0:
                var zoneTstatSetpt = s_hbfs.zoneTstatSetpts[ZoneNum - 1]
                zoneTstatSetpt.setptHiAver += zoneTstatSetpt.setptHi * state.dataHVACGlobal.FracTimeStepZone
                zoneTstatSetpt.setptLoAver += zoneTstatSetpt.setptLo * state.dataHVACGlobal.FracTimeStepZone

        ZoneTempPredictorCorrector.DetectOscillatingZoneTemp(state)
        UpdateZoneListAndGroupLoads(state)
        IceThermalStorage.UpdateIceFractions(state)
        WaterManager.ManageWater(state)
        var DummyLogical: Bool = False
        state.dataElectPwrSvcMgr.facilityElectricServiceObj.manageElectricPowerService(state, False, DummyLogical, True)
        PlantManager.UpdateNodeThermalHistory(state)
        if state.dataOutRptTab.displayHeatEmissionsSummary:
            OutputReportTabular.CalcHeatEmissionReport(state)
        EMSManager.ManageEMS(state, EMSCallFrom.EndSystemTimestepBeforeHVACReporting, anyEMSRan, None)

        if not state.dataGlobal.WarmupFlag:
            if state.dataGlobal.DoOutputReporting and not state.dataGlobal.ZoneSizingCalc:
                Node.CalcMoreNodeInfo(state)
                Pollution.CalculatePollution(state)
                SystemReports.InitEnergyReports(state)
                SystemReports.ReportSystemEnergyUse(state)
            if state.dataGlobal.DoOutputReporting or (state.dataGlobal.ZoneSizingCalc and state.dataGlobal.CompLoadReportIsReq):
                ReportAirHeatBalance(state)
                if state.dataGlobal.ZoneSizingCalc:
                    OutputReportTabular.GatherComponentLoadsHVAC(state)
            if state.dataGlobal.DoOutputReporting:
                SystemReports.ReportVentilationLoads(state)
                UpdateDataandReport(state, TimeStepType.System)
                if state.dataGlobal.KindOfSim == Constant.KindOfSim.HVACSizeDesignDay or state.dataGlobal.KindOfSim == Constant.KindOfSim.HVACSizeRunPeriodDesign:
                    if state.dataHVACSizingSimMgr.hvacSizingSimulationManager:
                        state.dataHVACSizingSimMgr.hvacSizingSimulationManager.UpdateSizingLogsSystemStep(state)
                OutputReportTabular.UpdateTabularReports(state, TimeStepType.System)
            if state.dataGlobal.ZoneSizingCalc:
                ZoneEquipmentManager.UpdateZoneSizing(state, Constant.CallIndicator.DuringDay)
                SizingManager.UpdateFacilitySizing(state, Constant.CallIndicator.DuringDay)
            EIRPlantLoopHeatPump.checkConcurrentOperation(state)
        elif not state.dataGlobal.KickOffSimulation and state.dataGlobal.DoOutputReporting and state.dataSysVars.ReportDuringWarmup:
            if state.dataGlobal.BeginDayFlag and not state.dataEnvrn.PrintEnvrnStampWarmupPrinted:
                state.dataEnvrn.PrintEnvrnStampWarmup = True
                state.dataEnvrn.PrintEnvrnStampWarmupPrinted = True
            if not state.dataGlobal.BeginDayFlag:
                state.dataEnvrn.PrintEnvrnStampWarmupPrinted = False
            if state.dataEnvrn.PrintEnvrnStampWarmup:
                if state.dataReportFlag.PrintEndDataDictionary and not state.dataHVACMgr.PrintedWarmup:
                    print(state.files.eso, "{}\n".format(EndOfHeaderString))
                    print(state.files.mtr, "{}\n".format(EndOfHeaderString))
                    state.dataReportFlag.PrintEndDataDictionary = False
                if not state.dataHVACMgr.PrintedWarmup:
                    print(state.files.eso,
                          EnvironmentStampFormatStr,
                          "1",
                          "Warmup {" + state.dataReportFlag.cWarmupDay + "} " + state.dataEnvrn.EnvironmentName,
                          state.dataEnvrn.Latitude,
                          state.dataEnvrn.Longitude,
                          state.dataEnvrn.TimeZoneNumber,
                          state.dataEnvrn.Elevation)
                    print(state.files.mtr,
                          EnvironmentStampFormatStr,
                          "1",
                          "Warmup {" + state.dataReportFlag.cWarmupDay + "} " + state.dataEnvrn.EnvironmentName,
                          state.dataEnvrn.Latitude,
                          state.dataEnvrn.Longitude,
                          state.dataEnvrn.TimeZoneNumber,
                          state.dataEnvrn.Elevation)
                    state.dataEnvrn.PrintEnvrnStampWarmup = False
                state.dataHVACMgr.PrintedWarmup = True
            if not state.dataGlobal.DoingSizing:
                Node.CalcMoreNodeInfo(state)
            UpdateDataandReport(state, TimeStepType.System)
            if state.dataGlobal.KindOfSim == Constant.KindOfSim.HVACSizeDesignDay or state.dataGlobal.KindOfSim == Constant.KindOfSim.HVACSizeRunPeriodDesign:
                if state.dataHVACSizingSimMgr.hvacSizingSimulationManager:
                    state.dataHVACSizingSimMgr.hvacSizingSimulationManager.UpdateSizingLogsSystemStep(state)
        elif state.dataSysVars.UpdateDataDuringWarmupExternalInterface:
            if state.dataGlobal.BeginDayFlag and not state.dataEnvrn.PrintEnvrnStampWarmupPrinted:
                state.dataEnvrn.PrintEnvrnStampWarmup = True
                state.dataEnvrn.PrintEnvrnStampWarmupPrinted = True
            if not state.dataGlobal.BeginDayFlag:
                state.dataEnvrn.PrintEnvrnStampWarmupPrinted = False
            if state.dataEnvrn.PrintEnvrnStampWarmup:
                if state.dataReportFlag.PrintEndDataDictionary and state.dataGlobal.DoOutputReporting and not state.dataHVACMgr.PrintedWarmup:
                    print(state.files.eso, "{}\n".format(EndOfHeaderString))
                    print(state.files.mtr, "{}\n".format(EndOfHeaderString))
                    state.dataReportFlag.PrintEndDataDictionary = False
                if state.dataGlobal.DoOutputReporting and not state.dataHVACMgr.PrintedWarmup:
                    print(state.files.eso,
                          EnvironmentStampFormatStr,
                          "1",
                          "Warmup {" + state.dataReportFlag.cWarmupDay + "} " + state.dataEnvrn.EnvironmentName,
                          state.dataEnvrn.Latitude,
                          state.dataEnvrn.Longitude,
                          state.dataEnvrn.TimeZoneNumber,
                          state.dataEnvrn.Elevation)
                    print(state.files.mtr,
                          EnvironmentStampFormatStr,
                          "1",
                          "Warmup {" + state.dataReportFlag.cWarmupDay + "} " + state.dataEnvrn.EnvironmentName,
                          state.dataEnvrn.Latitude,
                          state.dataEnvrn.Longitude,
                          state.dataEnvrn.TimeZoneNumber,
                          state.dataEnvrn.Elevation)
                    state.dataEnvrn.PrintEnvrnStampWarmup = False
                state.dataHVACMgr.PrintedWarmup = True
            UpdateDataandReport(state, TimeStepType.System)

        EMSManager.ManageEMS(state, EMSCallFrom.EndSystemTimestepAfterHVACReporting, anyEMSRan, None)
        state.dataHVACGlobal.SysTimeElapsed += state.dataHVACGlobal.TimeStepSys
        state.dataHVACGlobal.FirstTimeStepSysFlag = False

    for i in range(len(state.dataZoneTempPredictorCorrector.zoneHeatBalance)):
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[i]
        thisZoneHB.ZTAVComf = thisZoneHB.ZTAV
        thisZoneHB.airHumRatAvgComf = thisZoneHB.airHumRatAvg

    for i in range(len(state.dataZoneTempPredictorCorrector.spaceHeatBalance)):
        var thisSpaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance[i]
        thisSpaceHB.ZTAVComf = thisSpaceHB.ZTAV
        thisSpaceHB.airHumRatAvgComf = thisSpaceHB.airHumRatAvg

    ZoneTempPredictorCorrector.ManageZoneAirUpdates(
        state, PredictorCorrectorCtrl.PushZoneTimestepHistories, ZoneTempChange,
        state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)

    if state.dataContaminantBalance.Contaminant.SimulateContaminants:
        ZoneContaminantPredictorCorrector.ManageZoneContaminanUpdates(
            state, PredictorCorrectorCtrl.PushZoneTimestepHistories,
            state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)

    state.dataHVACGlobal.NumOfSysTimeStepsLastZoneTimeStep = state.dataHVACGlobal.NumOfSysTimeSteps
    DemandManager.UpdateDemandManagers(state)

    if state.dataReportFlag.DebugOutput:
        var ReportDebug: Bool
        if state.dataReportFlag.EvenDuringWarmup:
            ReportDebug = True
        else:
            ReportDebug = not state.dataGlobal.WarmupFlag
        if ReportDebug and (state.dataGlobal.DayOfSim > 0):
            var numNodes: Int = 0
            if len(state.dataLoopNodes.Node) > numNodes:
                state.dataHVACMgr.DebugNamesReported = False
            if len(state.dataLoopNodes.Node) > 0 and not state.dataHVACMgr.DebugNamesReported:
                numNodes = len(state.dataLoopNodes.Node)
                print(state.files.debug, "{}\n".format("node #   Node Type      Name"))
                for NodeNum in range(1, len(state.dataLoopNodes.Node) + 1):
                    print(state.files.debug,
                          " {:3}        {}         {}\n".format(
                              NodeNum,
                              Node.FluidTypeNames[int(state.dataLoopNodes.Node[NodeNum - 1].fluidType)],
                              state.dataLoopNodes.NodeID[NodeNum - 1]))
                print(state.files.debug, "Day of Sim, Hour of Day, TimeStep,")
                for NodeNum in range(1, len(state.dataLoopNodes.Node) + 1):
                    print(state.files.debug, "{}: Temp,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: MassMinAv,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: MassMaxAv,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: TempSP,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: MassFlow,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: MassMin,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: MassMax,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: MassSP,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: Press,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: Enth,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: HumRat,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    print(state.files.debug, "{}: Fluid Type,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    if state.dataContaminantBalance.Contaminant.CO2Simulation:
                        print(state.files.debug, "{}: CO2Conc,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                        print(state.files.debug, "{}: GenericContamConc,".format(state.dataLoopNodes.NodeID[NodeNum - 1]))
                    if NodeNum == len(state.dataLoopNodes.Node):
                        print(state.files.debug, "\n")
                state.dataHVACMgr.DebugNamesReported = True
            if len(state.dataLoopNodes.Node) > 0:
                print(state.files.debug,
                      "{:12},{:12}, {:22.15G},".format(state.dataGlobal.DayOfSim, state.dataGlobal.HourOfDay,
                                                         state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone))
            var Format_20: StringLiteral = " {:8.2F},  {:8.3F},  {:8.3F},  {:8.2F}, {:13.2F}, {:13.2F}, {:13.2F}, {:13.2F},  {:#7.0F},  {:11.2F},  {:9.5F},  {},"
            var Format_21: StringLiteral = " {:8.2F},"
            for NodeNum in range(1, len(state.dataLoopNodes.Node) + 1):
                print(state.files.debug,
                      Format_20,
                      state.dataLoopNodes.Node[NodeNum - 1].Temp,
                      state.dataLoopNodes.Node[NodeNum - 1].MassFlowRateMinAvail,
                      state.dataLoopNodes.Node[NodeNum - 1].MassFlowRateMaxAvail,
                      state.dataLoopNodes.Node[NodeNum - 1].TempSetPoint,
                      state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate,
                      state.dataLoopNodes.Node[NodeNum - 1].MassFlowRateMin,
                      state.dataLoopNodes.Node[NodeNum - 1].MassFlowRateMax,
                      state.dataLoopNodes.Node[NodeNum - 1].MassFlowRateSetPoint,
                      state.dataLoopNodes.Node[NodeNum - 1].Press,
                      state.dataLoopNodes.Node[NodeNum - 1].Enthalpy,
                      state.dataLoopNodes.Node[NodeNum - 1].HumRat,
                      Node.FluidTypeNames[int(state.dataLoopNodes.Node[NodeNum - 1].fluidType)])
                if state.dataContaminantBalance.Contaminant.CO2Simulation:
                    print(state.files.debug, Format_21, state.dataLoopNodes.Node[NodeNum - 1].CO2)
                if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                    print(state.files.debug, Format_21, state.dataLoopNodes.Node[NodeNum - 1].GenContam)
                if NodeNum == len(state.dataLoopNodes.Node):
                    print(state.files.debug, "\n")

def SimHVAC(state: EnergyPlusData) -> None:
    var SimWithPlantFlowUnlocked: Bool = False
    var SimWithPlantFlowLocked: Bool = True
    var FirstHVACIteration: Bool
    var SlopeHumRat: Float64
    var SlopeMdot: Float64
    var SlopeTemps: Float64
    var AvgValue: Float64
    var ConvergLogStackARR: StaticArray[Float64, DataConvergParams.ConvergLogStackDepth] = [
        0.0, -1.0, -2.0, -3.0, -4.0, -5.0, -6.0, -7.0, -8.0, -9.0
    ]
    var sum_ConvergLogStackARR: Float64 = -45.0
    var square_sum_ConvergLogStackARR: Float64 = 2025.0
    var sum_square_ConvergLogStackARR: Float64 = 285.0

    var NumPrimaryAirSys: Int = state.dataHVACGlobal.NumPrimaryAirSys
    state.dataHVACGlobal.SimZoneEquipmentFlag = True
    state.dataHVACGlobal.SimNonZoneEquipmentFlag = True
    state.dataHVACGlobal.SimAirLoopsFlag = True
    state.dataHVACGlobal.SimPlantLoopsFlag = True
    state.dataHVACGlobal.SimElecCircuitsFlag = True
    FirstHVACIteration = True

    if state.dataAirLoop.AirLoopInputsFilled:
        for i in range(len(state.dataAirLoop.AirLoopControlInfo)):
            var e = state.dataAirLoop.AirLoopControlInfo[i]
            e.CoolingActiveFlag = False
            e.HeatingActiveFlag = False
            e.HeatRecoveryBypass = True
            e.CheckHeatRecoveryBypassStatus = True
            e.OASysComponentsSimulated = False
            e.EconomizerFlowLocked = False
            e.HeatRecoveryResimFlag = True
            e.HeatRecoveryResimFlag2 = False
            e.ResimAirLoopFlag = False

    state.dataHVACMgr.HVACManageIteration = 0
    state.dataPlnt.PlantManageSubIterations = 0
    state.dataPlnt.PlantManageHalfLoopCalls = 0
    PlantUtilities.SetAllPlantSimFlagsToValue(state, True)

    if not state.dataHVACMgr.SimHVACIterSetup:
        SetupOutputVariable(state,
                            "HVAC System Solver Iteration Count",
                            Constant.Units.None,
                            state.dataHVACMgr.HVACManageIteration,
                            TimeStepType.System,
                            StoreType.Sum,
                            "SimHVAC")
        SetupOutputVariable(state,
                            "Air System Solver Iteration Count",
                            Constant.Units.None,
                            state.dataHVACMgr.RepIterAir,
                            TimeStepType.System,
                            StoreType.Sum,
                            "SimHVAC")
        SetupOutputVariable(state,
                            "Air System Relief Air Total Heat Loss Energy",
                            Constant.Units.J,
                            state.dataHeatBal.SysTotalHVACReliefHeatLoss,
                            TimeStepType.System,
                            StoreType.Sum,
                            "SimHVAC")
        SetupOutputVariable(state,
                            "HVAC System Total Heat Rejection Energy",
                            Constant.Units.J,
                            state.dataHeatBal.SysTotalHVACRejectHeatLoss,
                            TimeStepType.System,
                            StoreType.Sum,
                            "SimHVAC")
        SetPointManager.ManageSetPoints(state)
        PlantManager.GetPlantLoopData(state)
        PlantManager.GetPlantInput(state)
        PlantManager.SetupInitialPlantCallingOrder(state)
        PlantManager.SetupBranchControlTypes(state)
        PlantManager.SetupReports(state)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            PlantCondLoopOperation.SetupPlantEMSActuators(state)
        if state.dataPlnt.TotNumLoops > 0:
            SetupOutputVariable(state,
                                "Plant Solver Sub Iteration Count",
                                Constant.Units.None,
                                state.dataPlnt.PlantManageSubIterations,
                                TimeStepType.System,
                                StoreType.Sum,
                                "SimHVAC")
            SetupOutputVariable(state,
                                "Plant Solver Half Loop Calls Count",
                                Constant.Units.None,
                                state.dataPlnt.PlantManageHalfLoopCalls,
                                TimeStepType.System,
                                StoreType.Sum,
                                "SimHVAC")
            for LoopNum in range(1, state.dataPlnt.TotNumLoops + 1):
                PlantManager.InitOneTimePlantSizingInfo(state, LoopNum)
        state.dataHVACMgr.SimHVACIterSetup = True

    if state.dataGlobal.ZoneSizingCalc:
        ZoneEquipmentManager.ManageZoneEquipment(
            state, FirstHVACIteration, state.dataHVACGlobal.SimZoneEquipmentFlag, state.dataHVACGlobal.SimAirLoopsFlag)
        NonZoneEquipmentManager.ManageNonZoneEquipment(state, FirstHVACIteration, state.dataHVACGlobal.SimNonZoneEquipmentFlag)
        state.dataElectPwrSvcMgr.facilityElectricServiceObj.manageElectricPowerService(
            state, FirstHVACIteration, state.dataHVACGlobal.SimElecCircuitsFlag, False)
        return

    ResetHVACControl(state)
    var anyEMSRan: Bool = False
    EMSManager.ManageEMS(state, EMSCallFrom.BeforeHVACManagers, anyEMSRan, None)
    SetPointManager.ManageSetPoints(state)
    PlantManager.ReInitPlantLoopsAtFirstHVACIteration(state)
    Avail.ManageSystemAvailability(state)
    EMSManager.ManageEMS(state, EMSCallFrom.AfterHVACManagers, anyEMSRan, None)
    EMSManager.ManageEMS(state, EMSCallFrom.HVACIterationLoop, anyEMSRan, None)

    SimSelectedEquipment(state,
                         state.dataHVACGlobal.SimAirLoopsFlag,
                         state.dataHVACGlobal.SimZoneEquipmentFlag,
                         state.dataHVACGlobal.SimNonZoneEquipmentFlag,
                         state.dataHVACGlobal.SimPlantLoopsFlag,
                         state.dataHVACGlobal.SimElecCircuitsFlag,
                         FirstHVACIteration,
                         SimWithPlantFlowUnlocked)

    state.dataHVACGlobal.SimPlantLoopsFlag = True
    PlantUtilities.SetAllPlantSimFlagsToValue(state, True)
    FirstHVACIteration = False

    while ((state.dataHVACGlobal.SimAirLoopsFlag or state.dataHVACGlobal.SimZoneEquipmentFlag or state.dataHVACGlobal.SimNonZoneEquipmentFlag or
            state.dataHVACGlobal.SimPlantLoopsFlag or state.dataHVACGlobal.SimElecCircuitsFlag) and
           (state.dataHVACMgr.HVACManageIteration <= state.dataConvergeParams.MaxIter)):
        if state.dataGlobal.stopSimulation:
            break
        EMSManager.ManageEMS(state, EMSCallFrom.HVACIterationLoop, anyEMSRan, None)
        SimSelectedEquipment(state,
                             state.dataHVACGlobal.SimAirLoopsFlag,
                             state.dataHVACGlobal.SimZoneEquipmentFlag,
                             state.dataHVACGlobal.SimNonZoneEquipmentFlag,
                             state.dataHVACGlobal.SimPlantLoopsFlag,
                             state.dataHVACGlobal.SimElecCircuitsFlag,
                             FirstHVACIteration,
                             SimWithPlantFlowUnlocked)
        UpdateZoneInletConvergenceLog(state)
        state.dataHVACMgr.HVACManageIteration += 1
        if anyEMSRan and state.dataHVACMgr.HVACManageIteration <= 2:
            state.dataHVACGlobal.SimAirLoopsFlag = True
        if state.dataHVACMgr.HVACManageIteration < state.dataHVACGlobal.MinAirLoopIterationsAfterFirst:
            state.dataHVACGlobal.SimAirLoopsFlag = True
            state.dataHVACGlobal.SimZoneEquipmentFlag = True

    if state.dataGlobal.AnyPlantInModel:
        if PlantUtilities.AnyPlantSplitterMixerLacksContinuity(state):
            state.dataHVACGlobal.SimAirLoopsFlag = False
            state.dataHVACGlobal.SimZoneEquipmentFlag = False
            state.dataHVACGlobal.SimNonZoneEquipmentFlag = False
            state.dataHVACGlobal.SimPlantLoopsFlag = True
            state.dataHVACGlobal.SimElecCircuitsFlag = False
            SimSelectedEquipment(state,
                                 state.dataHVACGlobal.SimAirLoopsFlag,
                                 state.dataHVACGlobal.SimZoneEquipmentFlag,
                                 state.dataHVACGlobal.SimNonZoneEquipmentFlag,
                                 state.dataHVACGlobal.SimPlantLoopsFlag,
                                 state.dataHVACGlobal.SimElecCircuitsFlag,
                                 FirstHVACIteration,
                                 SimWithPlantFlowUnlocked)
            state.dataHVACGlobal.SimAirLoopsFlag = True
            state.dataHVACGlobal.SimZoneEquipmentFlag = True
            state.dataHVACGlobal.SimNonZoneEquipmentFlag = True
            state.dataHVACGlobal.SimPlantLoopsFlag = False
            state.dataHVACGlobal.SimElecCircuitsFlag = True
            SimSelectedEquipment(state,
                                 state.dataHVACGlobal.SimAirLoopsFlag,
                                 state.dataHVACGlobal.SimZoneEquipmentFlag,
                                 state.dataHVACGlobal.SimNonZoneEquipmentFlag,
                                 state.dataHVACGlobal.SimPlantLoopsFlag,
                                 state.dataHVACGlobal.SimElecCircuitsFlag,
                                 FirstHVACIteration,
                                 SimWithPlantFlowLocked)
            UpdateZoneInletConvergenceLog(state)
            state.dataHVACGlobal.SimAirLoopsFlag = False
            state.dataHVACGlobal.SimZoneEquipmentFlag = False
            state.dataHVACGlobal.SimNonZoneEquipmentFlag = False
            state.dataHVACGlobal.SimPlantLoopsFlag = True
            state.dataHVACGlobal.SimElecCircuitsFlag = False
            SimSelectedEquipment(state,
                                 state.dataHVACGlobal.SimAirLoopsFlag,
                                 state.dataHVACGlobal.SimZoneEquipmentFlag,
                                 state.dataHVACGlobal.SimNonZoneEquipmentFlag,
                                 state.dataHVACGlobal.SimPlantLoopsFlag,
                                 state.dataHVACGlobal.SimElecCircuitsFlag,
                                 FirstHVACIteration,
                                 SimWithPlantFlowUnlocked)
            state.dataHVACGlobal.SimAirLoopsFlag = True
            state.dataHVACGlobal.SimZoneEquipmentFlag = True
            state.dataHVACGlobal.SimNonZoneEquipmentFlag = True
            state.dataHVACGlobal.SimPlantLoopsFlag = False
            state.dataHVACGlobal.SimElecCircuitsFlag = True
            SimSelectedEquipment(state,
                                 state.dataHVACGlobal.SimAirLoopsFlag,
                                 state.dataHVACGlobal.SimZoneEquipmentFlag,
                                 state.dataHVACGlobal.SimNonZoneEquipmentFlag,
                                 state.dataHVACGlobal.SimPlantLoopsFlag,
                                 state.dataHVACGlobal.SimElecCircuitsFlag,
                                 FirstHVACIteration,
                                 SimWithPlantFlowLocked)
            UpdateZoneInletConvergenceLog(state)

    for LoopNum in range(1, state.dataPlnt.TotNumLoops + 1):
        for LoopSide in LoopSideKeys:
            PlantUtilities.CheckPlantMixerSplitterConsistency(state, LoopNum, LoopSide, FirstHVACIteration)
            PlantUtilities.CheckForRunawayPlantTemps(state, LoopNum, LoopSide)

    if (state.dataHVACMgr.HVACManageIteration > state.dataConvergeParams.MaxIter) and (not state.dataGlobal.WarmupFlag):
        state.dataHVACMgr.ErrCount += 1
        if state.dataHVACMgr.ErrCount < 15:
            state.dataHVACMgr.ErrEnvironmentName = state.dataEnvrn.EnvironmentName
            ShowWarningError(state,
                             "SimHVAC: Maximum iterations ({}) exceeded for all HVAC loops, at {}, {} {}".format(
                                 state.dataConvergeParams.MaxIter,
                                 state.dataEnvrn.EnvironmentName,
                                 state.dataEnvrn.CurMnDy,
                                 General.CreateSysTimeIntervalString(state)))
            if state.dataHVACGlobal.SimAirLoopsFlag:
                ShowContinueError(state, "The solution for one or more of the Air Loop HVAC systems did not appear to converge")
            if state.dataHVACGlobal.SimZoneEquipmentFlag:
                ShowContinueError(state, "The solution for zone HVAC equipment did not appear to converge")
            if state.dataHVACGlobal.SimNonZoneEquipmentFlag:
                ShowContinueError(state, "The solution for non-zone equipment did not appear to converge")
            if state.dataHVACGlobal.SimPlantLoopsFlag:
                ShowContinueError(state, "The solution for one or more plant systems did not appear to converge")
            if state.dataHVACGlobal.SimElecCircuitsFlag:
                ShowContinueError(state, "The solution for on-site electric generators did not appear to converge")
            if state.dataHVACMgr.ErrCount == 1 and not state.dataGlobal.DisplayExtraWarnings:
                ShowContinueError(state, "...use Output:Diagnostics,DisplayExtraWarnings; to show more details on each max iteration exceeded.")
            if state.dataGlobal.DisplayExtraWarnings:
                for AirSysNum in range(1, NumPrimaryAirSys + 1):
                    var conv = state.dataConvergeParams.AirLoopConvergence[AirSysNum - 1]
                    ConvergenceErrors(state,
                                      conv.HVACMassFlowNotConverged,
                                      conv.HVACFlowDemandToSupplyTolValue,
                                      conv.HVACFlowSupplyDeck1ToDemandTolValue,
                                      conv.HVACFlowSupplyDeck2ToDemandTolValue,
                                      AirSysNum,
                                      ConvErrorCallType.MassFlow)
                    ConvergenceErrors(state,
                                      conv.HVACHumRatNotConverged,
                                      conv.HVACHumDemandToSupplyTolValue,
                                      conv.HVACHumSupplyDeck1ToDemandTolValue,
                                      conv.HVACHumSupplyDeck2ToDemandTolValue,
                                      AirSysNum,
                                      ConvErrorCallType.HumidityRatio)
                    ConvergenceErrors(state,
                                      conv.HVACTempNotConverged,
                                      conv.HVACTempDemandToSupplyTolValue,
                                      conv.HVACTempSupplyDeck1ToDemandTolValue,
                                      conv.HVACTempSupplyDeck2ToDemandTolValue,
                                      AirSysNum,
                                      ConvErrorCallType.Temperature)
                    ConvergenceErrors(state,
                                      conv.HVACEnergyNotConverged,
                                      conv.HVACEnergyDemandToSupplyTolValue,
                                      conv.HVACEnergySupplyDeck1ToDemandTolValue,
                                      conv.HVACEnergySupplyDeck2ToDemandTolValue,
                                      AirSysNum,
                                      ConvErrorCallType.Energy)
                    ConvergenceErrors(state,
                                      conv.HVACCO2NotConverged,
                                      conv.HVACCO2DemandToSupplyTolValue,
                                      conv.HVACCO2SupplyDeck1ToDemandTolValue,
                                      conv.HVACCO2SupplyDeck2ToDemandTolValue,
                                      AirSysNum,
                                      ConvErrorCallType.CO2)
                    ConvergenceErrors(state,
                                      conv.HVACGenContamNotConverged,
                                      conv.HVACGenContamDemandToSupplyTolValue,
                                      conv.HVACGenContamSupplyDeck1ToDemandTolValue,
                                      conv.HVACGenContamSupplyDeck2ToDemandTolValue,
                                      AirSysNum,
                                      ConvErrorCallType.Generic)

                for ZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
                    for NodeIndex in range(1, state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].NumInletNodes + 1):
                        var humRatInletNode = state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].HumidityRatio
                        var mdotInletNode = state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].MassFlowRate
                        var inletTemp = state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].Temperature
                        var FoundOscillationByDuplicate: Bool = False
                        var MonotonicDecreaseFound: Bool = False
                        var MonotonicIncreaseFound: Bool = False
                        var summation: Float64 = 0.0
                        summation = sum(humRatInletNode)
                        AvgValue = summation / Float64(DataConvergParams.ConvergLogStackDepth)
                        if abs(humRatInletNode[0] - AvgValue) > DataConvergParams.HVACHumRatOscillationToler:
                            FoundOscillationByDuplicate = False
                            for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                if abs(humRatInletNode[0] - humRatInletNode[StackDepth]) < DataConvergParams.HVACHumRatOscillationToler:
                                    FoundOscillationByDuplicate = True
                                    ShowContinueError(
                                        state,
                                        "Node named {} shows oscillating humidity ratio across iterations with a repeated value of {:#G}".format(
                                            state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                            humRatInletNode[0]))
                                    break
                            if not FoundOscillationByDuplicate:
                                var humRatInletNodDotProd: Float64 = 0.0
                                for idx in range(len(ConvergLogStackARR)):
                                    humRatInletNodDotProd += ConvergLogStackARR[idx] * humRatInletNode[idx]
                                var summation2: Float64 = sum(humRatInletNode)
                                SlopeHumRat = (sum_ConvergLogStackARR * summation2 - Float64(DataConvergParams.ConvergLogStackDepth) * humRatInletNodDotProd) / (square_sum_ConvergLogStackARR - Float64(DataConvergParams.ConvergLogStackDepth) * sum_square_ConvergLogStackARR)
                                if abs(SlopeHumRat) > DataConvergParams.HVACHumRatSlopeToler:
                                    if SlopeHumRat < 0.0:
                                        MonotonicDecreaseFound = True
                                        for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                            if humRatInletNode[StackDepth - 1] > humRatInletNode[StackDepth]:
                                                MonotonicDecreaseFound = False
                                                break
                                        if MonotonicDecreaseFound:
                                            ShowContinueError(
                                                state,
                                                "Node named {} shows monotonically decreasing humidity ratio with a trend rate across iterations of {:#G} [kg-water/kg-dryair/iteration]".format(
                                                    state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                                    SlopeHumRat))
                                    else:
                                        MonotonicIncreaseFound = True
                                        for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                            if humRatInletNode[StackDepth - 1] < humRatInletNode[StackDepth]:
                                                MonotonicIncreaseFound = False
                                                break
                                        if MonotonicIncreaseFound:
                                            ShowContinueError(
                                                state,
                                                "Node named {} shows monotonically increasing humidity ratio with a trend rate across iterations of {:#G} [kg-water/kg-dryair/iteration]".format(
                                                    state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                                    SlopeHumRat))

                        if MonotonicDecreaseFound or MonotonicIncreaseFound or FoundOscillationByDuplicate:
                            var HistoryTrace: String = ""
                            for StackDepth in range(DataConvergParams.ConvergLogStackDepth):
                                HistoryTrace += "{:#G},".format(humRatInletNode[StackDepth])
                            ShowContinueError(
                                state,
                                "Node named {} humidity ratio [kg-water/kg-dryair] iteration history trace (most recent first): {}".format(
                                    state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                    HistoryTrace))

                        FoundOscillationByDuplicate = False
                        MonotonicDecreaseFound = False
                        MonotonicIncreaseFound = False
                        var summation2: Float64 = sum(mdotInletNode)
                        AvgValue = summation2 / Float64(DataConvergParams.ConvergLogStackDepth)
                        if abs(mdotInletNode[0] - AvgValue) > DataConvergParams.HVACFlowRateOscillationToler:
                            FoundOscillationByDuplicate = False
                            for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                if abs(mdotInletNode[0] - mdotInletNode[StackDepth]) < DataConvergParams.HVACFlowRateOscillationToler:
                                    FoundOscillationByDuplicate = True
                                    ShowContinueError(
                                        state,
                                        "Node named {} shows oscillating mass flow rate across iterations with a repeated value of {:#G}".format(
                                            state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                            mdotInletNode[0]))
                                    break
                            if not FoundOscillationByDuplicate:
                                var humRatInletNodDotProd: Float64 = 0.0
                                for idx in range(len(ConvergLogStackARR)):
                                    humRatInletNodDotProd += ConvergLogStackARR[idx] * mdotInletNode[idx]
                                var summation3: Float64 = sum(mdotInletNode)
                                SlopeMdot = (sum_ConvergLogStackARR * summation3 - Float64(DataConvergParams.ConvergLogStackDepth) * humRatInletNodDotProd) / (square_sum_ConvergLogStackARR - Float64(DataConvergParams.ConvergLogStackDepth) * sum_square_ConvergLogStackARR)
                                if abs(SlopeMdot) > DataConvergParams.HVACFlowRateSlopeToler:
                                    if SlopeMdot < 0.0:
                                        MonotonicDecreaseFound = True
                                        for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                            if mdotInletNode[StackDepth - 1] > mdotInletNode[StackDepth]:
                                                MonotonicDecreaseFound = False
                                                break
                                        if MonotonicDecreaseFound:
                                            ShowContinueError(
                                                state,
                                                "Node named {} shows monotonically decreasing mass flow rate with a trend rate across iterations of {:#G} [kg/s/iteration]".format(
                                                    state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                                    SlopeMdot))
                                    else:
                                        MonotonicIncreaseFound = True
                                        for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                            if mdotInletNode[StackDepth - 1] < mdotInletNode[StackDepth]:
                                                MonotonicIncreaseFound = False
                                                break
                                        if MonotonicIncreaseFound:
                                            ShowContinueError(
                                                state,
                                                "Node named {} shows monotonically increasing mass flow rate with a trend rate across iterations of {:#G} [kg/s/iteration]".format(
                                                    state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                                    SlopeMdot))

                        if MonotonicDecreaseFound or MonotonicIncreaseFound or FoundOscillationByDuplicate:
                            var HistoryTrace: String = ""
                            for StackDepth in range(DataConvergParams.ConvergLogStackDepth):
                                HistoryTrace += "{:#G},".format(mdotInletNode[StackDepth])
                            ShowContinueError(state,
                                              "Node named {} mass flow rate [kg/s] iteration history trace (most recent first): {}".format(
                                                  state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                                  HistoryTrace))

                        FoundOscillationByDuplicate = False
                        MonotonicDecreaseFound = False
                        MonotonicIncreaseFound = False
                        var summation3: Float64 = sum(inletTemp)
                        AvgValue = summation3 / Float64(DataConvergParams.ConvergLogStackDepth)
                        if abs(inletTemp[0] - AvgValue) > DataConvergParams.HVACTemperatureOscillationToler:
                            FoundOscillationByDuplicate = False
                            for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                if abs(inletTemp[0] - inletTemp[StackDepth]) < DataConvergParams.HVACTemperatureOscillationToler:
                                    FoundOscillationByDuplicate = True
                                    ShowContinueError(
                                        state,
                                        "Node named {} shows oscillating temperatures across iterations with a repeated value of {:#G}".format(
                                            state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                            inletTemp[0]))
                                    break
                            if not FoundOscillationByDuplicate:
                                var inletTempDotProd: Float64 = 0.0
                                for idx in range(len(ConvergLogStackARR)):
                                    inletTempDotProd += ConvergLogStackARR[idx] * inletTemp[idx]
                                var summation4: Float64 = sum(inletTemp)
                                SlopeTemps = (sum_ConvergLogStackARR * summation4 - Float64(DataConvergParams.ConvergLogStackDepth) * inletTempDotProd) / (square_sum_ConvergLogStackARR - Float64(DataConvergParams.ConvergLogStackDepth) * sum_square_ConvergLogStackARR)
                                if abs(SlopeTemps) > DataConvergParams.HVACTemperatureSlopeToler:
                                    if SlopeTemps < 0.0:
                                        MonotonicDecreaseFound = True
                                        for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                            if inletTemp[StackDepth - 1] > inletTemp[StackDepth]:
                                                MonotonicDecreaseFound = False
                                                break
                                        if MonotonicDecreaseFound:
                                            ShowContinueError(
                                                state,
                                                "Node named {} shows monotonically decreasing temperature with a trend rate across iterations of {:.4f} [C/iteration]".format(
                                                    state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                                    SlopeTemps))
                                    else:
                                        MonotonicIncreaseFound = True
                                        for StackDepth in range(1, DataConvergParams.ConvergLogStackDepth):
                                            if inletTemp[StackDepth - 1] < inletTemp[StackDepth]:
                                                MonotonicIncreaseFound = False
                                                break
                                        if MonotonicIncreaseFound:
                                            ShowContinueError(
                                                state,
                                                "Node named {} shows monotonically increasing temperatures with a trend rate across iterations of {:.4f} [C/iteration]".format(
                                                    state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                                    SlopeTemps))

                        if MonotonicDecreaseFound or MonotonicIncreaseFound or FoundOscillationByDuplicate:
                            var HistoryTrace: String = ""
                            for StackDepth in range(DataConvergParams.ConvergLogStackDepth):
                                HistoryTrace += "{:#G},".format(inletTemp[StackDepth])
                            ShowContinueError(state,
                                              "Node named {} temperature [C] iteration history trace (most recent first): {}".format(
                                                  state.dataLoopNodes.NodeID[state.dataConvergeParams.ZoneInletConvergence[ZoneNum - 1].InletNode[NodeIndex - 1].NodeNum - 1],
                                                  HistoryTrace))

                for LoopNum in range(1, state.dataPlnt.TotNumLoops + 1):
                    var FoundOscillationByDuplicate: Bool
                    var MonotonicIncreaseFound: Bool
                    var MonotonicDecreaseFound: Bool
                    if state.dataConvergeParams.PlantConvergence[LoopNum - 1].PlantMassFlowNotConverged:
                        ShowContinueError(
                            state,
                            "Plant System Named = {} did not converge for mass flow rate".format(state.dataPlnt.PlantLoop[LoopNum - 1].Name))
                        ShowContinueError(state, "Check values should be zero. Most Recent values listed first.")
                        var HistoryTrace: String = ""
                        for StackDepth in range(DataConvergParams.ConvergLogStackDepth):
                            HistoryTrace += "{:.5f},".format(state.dataConvergeParams.PlantConvergence[LoopNum - 1].PlantFlowDemandToSupplyTolValue[StackDepth])
                        ShowContinueError(
                            state, "Demand-to-Supply interface mass flow rate check value iteration history trace: {}".format(HistoryTrace))
                        HistoryTrace = ""
                        for StackDepth in range(DataConvergParams.ConvergLogStackDepth):
                            HistoryTrace += "{:.5f},".format(state.dataConvergeParams.PlantConvergence[LoopNum - 1].PlantFlowSupplyToDemandTolValue[StackDepth])
                        ShowContinueError(
                            state, "Supply-to-Demand interface mass flow rate check value iteration history trace: {}".format(HistoryTrace))
                        for ThisLoopSide in LoopSideKeys:
                            var mdotHistInletNode = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].InletNode.MassFlowRateHistory
                            var mdotHistOutletNode = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].OutletNode.MassFlowRateHistory
                            FoundOscillationByDuplicate = False
                            MonotonicDecreaseFound = False
                            MonotonicIncreaseFound = False
                            AvgValue = sum(mdotHistInletNode) / Float64(NumConvergenceHistoryTerms)
                            if abs(mdotHistInletNode[1] - AvgValue) > DataConvergParams.PlantFlowRateOscillationToler:
                                FoundOscillationByDuplicate = False
                                for StackDepth in range(2, NumConvergenceHistoryTerms + 1):
                                    if abs(mdotHistInletNode[1] - mdotHistInletNode[StackDepth]) < DataConvergParams.PlantFlowRateOscillationToler:
                                        FoundOscillationByDuplicate = True
                                        ShowContinueError(
                                            state,
                                            "Node named {} shows oscillating flow rates across iterations with a repeated value of {:#G}".format(
                                                state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].NodeNameIn,
                                                mdotHistInletNode[1]))
                                        break
                            if not FoundOscillationByDuplicate:
                                var mdotHistInletNodeDotProd: Float64 = 0.0
                                for idx in range(len(ConvergenceHistoryARR)):
                                    mdotHistInletNodeDotProd += ConvergenceHistoryARR[idx] * mdotHistInletNode[idx]
                                SlopeMdot = (sum_ConvergenceHistoryARR * sum(mdotHistInletNode) - Float64(NumConvergenceHistoryTerms) * mdotHistInletNodeDotProd) / (square_sum_ConvergenceHistoryARR - Float64(NumConvergenceHistoryTerms) * sum_square_ConvergenceHistoryARR)
                                if abs(SlopeMdot) > DataConvergParams.PlantFlowRateSlopeToler:
                                    if SlopeMdot < 0.0:
                                        MonotonicDecreaseFound = True
                                        for StackDepth in range(2, NumConvergenceHistoryTerms + 1):
                                            if mdotHistInletNode[StackDepth - 1] > mdotHistInletNode[StackDepth]:
                                                MonotonicDecreaseFound = False
                                                break
                                        if MonotonicDecreaseFound:
                                            ShowContinueError(state,
                                                              "Node named {} shows monotonically decreasing mass flow rate with a trend rate across iterations of {:#G} [kg/s/iteration]".format(
                                                                  state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].NodeNameIn,
                                                                  SlopeMdot))
                                    else:
                                        MonotonicIncreaseFound = True
                                        for StackDepth in range(2, NumConvergenceHistoryTerms + 1):
                                            if mdotHistInletNode[StackDepth - 1] < mdotHistInletNode[StackDepth]:
                                                MonotonicIncreaseFound = False
                                                break
                                        if MonotonicIncreaseFound:
                                            ShowContinueError(state,
                                                              "Node named {} shows monotonically increasing mass flow rate with a trend rate across iterations of {:#G} [kg/s/iteration]".format(
                                                                  state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].NodeNameIn,
                                                                  SlopeMdot))
                            if MonotonicDecreaseFound or MonotonicIncreaseFound or FoundOscillationByDuplicate:
                                HistoryTrace = ""
                                for StackDepth in range(1, NumConvergenceHistoryTerms + 1):
                                    HistoryTrace += "{:#G},".format(mdotHistInletNode[StackDepth])
                                ShowContinueError(state,
                                                  "Node named {} mass flow rate [kg/s] iteration history trace (most recent first): {}".format(
                                                      state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].NodeNameIn,
                                                      HistoryTrace))
                            FoundOscillationByDuplicate = False
                            MonotonicDecreaseFound = False
                            MonotonicIncreaseFound = False
                            AvgValue = sum(mdotHistOutletNode) / Float64(NumConvergenceHistoryTerms)
                            if abs(mdotHistOutletNode[1] - AvgValue) > DataConvergParams.PlantFlowRateOscillationToler:
                                FoundOscillationByDuplicate = False
                                for StackDepth in range(2, NumConvergenceHistoryTerms + 1):
                                    if abs(mdotHistOutletNode[1] - mdotHistOutletNode[StackDepth]) < DataConvergParams.PlantFlowRateOscillationToler:
                                        FoundOscillationByDuplicate = True
                                        ShowContinueError(
                                            state,
                                            "Node named {} shows oscillating flow rates across iterations with a repeated value of {:#G}".format(
                                                state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].NodeNameOut,
                                                mdotHistOutletNode[1]))
                                        break
                            if not FoundOscillationByDuplicate:
                                var mdotHistOutletNodeDotProd: Float64 = 0.0
                                for idx in range(len(ConvergenceHistoryARR)):
                                    mdotHistOutletNodeDotProd += ConvergenceHistoryARR[idx] * mdotHistOutletNode[idx]
                                SlopeMdot = (sum_ConvergenceHistoryARR * sum(mdotHistOutletNode) - Float64(NumConvergenceHistoryTerms) * mdotHistOutletNodeDotProd) / (square_sum_ConvergenceHistoryARR - Float64(NumConvergenceHistoryTerms) * sum_square_ConvergenceHistoryARR)
                                if abs(SlopeMdot) > DataConvergParams.PlantFlowRateSlopeToler:
                                    if SlopeMdot < 0.0:
                                        MonotonicDecreaseFound = True
                                        for StackDepth in range(2, NumConvergenceHistoryTerms + 1):
                                            if mdotHistOutletNode[StackDepth - 1] > mdotHistOutletNode[StackDepth]:
                                                MonotonicDecreaseFound = False
                                                break
                                        if MonotonicDecreaseFound:
                                            ShowContinueError(state,
                                                              "Node named {} shows monotonically decreasing mass flow rate with a trend rate across iterations of {:#G} [kg/s/iteration]".format(
                                                                  state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].NodeNameOut,
                                                                  SlopeMdot))
                                    else:
                                        MonotonicIncreaseFound = True
                                        for StackDepth in range(2, NumConvergenceHistoryTerms + 1):
                                            if mdotHistOutletNode[StackDepth - 1] < mdotHistOutletNode[StackDepth]:
                                                MonotonicIncreaseFound = False
                                                break
                                        if MonotonicIncreaseFound:
                                            ShowContinueError(state,
                                                              "Node named {} shows monotonically increasing mass flow rate with a trend rate across iterations of {:#G} [kg/s/iteration]".format(
                                                                  state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].NodeNameOut,
                                                                  SlopeMdot))
                            if MonotonicDecreaseFound or MonotonicIncreaseFound or FoundOscillationByDuplicate:
                                HistoryTrace = ""
                                for StackDepth in range(1, NumConvergenceHistoryTerms + 1):
                                    HistoryTrace += "{:#G},".format(mdotHistOutletNode[StackDepth])
                                ShowContinueError(state,
                                                  "Node named {} mass flow rate [kg/s] iteration history trace (most recent first): {}".format(
                                                      state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSide].NodeNameOut,
                                                      HistoryTrace))

                    if state.dataConvergeParams.PlantConvergence[LoopNum - 1].PlantTempNotConverged:
                        ShowContinueError(
                            state, "Plant System Named = {} did not converge for temperature".format(state.dataPlnt.PlantLoop[LoopNum - 1].Name))
                        ShowContinueError(state, "Check values should be zero. Most Recent values listed first.")
                        var HistoryTrace: String = ""
                        for StackDepth in range(DataConvergParams.ConvergLogStackDepth):
                            HistoryTrace += "{:.5f},".format(state.dataConvergeParams.PlantConvergence[LoopNum - 1].PlantTempDemandToSupplyTolValue[StackDepth])
                        Show