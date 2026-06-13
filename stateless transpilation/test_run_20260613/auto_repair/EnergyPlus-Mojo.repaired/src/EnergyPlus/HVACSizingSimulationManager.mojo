# CHECK: This is a faithful 1:1 translation from C++ to Mojo.
# NOTE: Mojo does not have a direct unique_ptr equivalent; using Pointer.
# NOTE: Mojo does not have to_string, format, string_view, make_unique.
# NOTE: Mojo subscript is 0-based, C++ index is 1-based -> adjust all array/vector accesses.
# NOTE: ObjexxFCL style arrays (1-based) -> 0-based.

from vector import DynamicVector
from string import String, StringRef
from memory import Pointer
from Data.BaseData import BaseGlobalStruct
from DataEnvironment import *
from DataErrorTracking import *
from DataGlobals import *
from DataReportingFlags import *
from DataSizing import *
from DataSystemVariables import *
from DisplayRoutines import *
from EMSManager import *
from ExteriorEnergyUse import *
from FluidProperties import *
from General import *
from HeatBalanceManager import *
from Plant.DataPlant import *
from Plant.PlantManager import *
from PlantPipingSystemsManager import *
from SQLiteProcedures import *
from SimulationManager import *
from SizingAnalysisObjects import *
from UtilityRoutines import *
from WeatherManager import *
from HVACSizingSimulationManager import *  # for self-reference

@value
class HVACSizingSimulationManager:
    var plantCoincAnalyObjs: DynamicVector[PlantCoinicidentAnalysis]
    var plantCoinAnalyRequestsAnotherIteration: Bool
    var sizingLogger: SizingLoggerFramework

    def __init__(inout self):
        self.plantCoincAnalyObjs = DynamicVector[PlantCoinicidentAnalysis]()
        self.plantCoinAnalyRequestsAnotherIteration = False
        self.sizingLogger = SizingLoggerFramework()

    def __moveinit__(inout self, owned existing: Self):
        self.plantCoincAnalyObjs = existing.plantCoincAnalyObjs^
        self.plantCoinAnalyRequestsAnotherIteration = existing.plantCoinAnalyRequestsAnotherIteration
        self.sizingLogger = existing.sizingLogger^

    def __del__(owned self):

    def DetermineSizingAnalysesNeeded(inout self, inout state: EnergyPlusData):
        for i in range(state.dataSize.NumPltSizInput):  # 0-based loop, but original 1-based
            if state.dataSize.PlantSizData[i].ConcurrenceOption == DataSizing.SizingConcurrence.Coincident:
                self.CreateNewCoincidentPlantAnalysisObject(state, state.dataSize.PlantSizData[i].PlantLoopName, i)

    def CreateNewCoincidentPlantAnalysisObject(inout self, inout state: EnergyPlusData, PlantLoopName: String, PlantSizingIndex: Int):
        var density: Float64
        var cp: Float64
        for i in range(state.dataPlnt.TotNumLoops):  # 0-based
            if PlantLoopName == state.dataPlnt.PlantLoop[i].Name:  # found it
                density = state.dataPlnt.PlantLoop[i].glycol.getDensity(state, Constant.CWInitConvTemp, "createNewCoincidentPlantAnalysisObject")
                cp = state.dataPlnt.PlantLoop[i].glycol.getSpecificHeat(state, Constant.CWInitConvTemp, "createNewCoincidentPlantAnalysisObject")
                self.plantCoincAnalyObjs.push_back(
                    PlantCoinicidentAnalysis(
                        PlantLoopName,
                        i,
                        state.dataPlnt.PlantLoop[i].LoopSide[DataPlant.LoopSideLocation.Supply].NodeNumIn,
                        density,
                        cp,
                        state.dataSize.PlantSizData[PlantSizingIndex].NumTimeStepsInAvg,
                        PlantSizingIndex
                    )
                )

    def SetupSizingAnalyses(inout self, inout state: EnergyPlusData):
        for p in range(len(self.plantCoincAnalyObjs)):
            var P = self.plantCoincAnalyObjs[p]
            P.supplyInletNodeFlow_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                state, state.dataLoopNodes.Node[P.supplySideInletNodeNum].MassFlowRate, P.numTimeStepsInAvg
            )
            P.supplyInletNodeTemp_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                state, state.dataLoopNodes.Node[P.supplySideInletNodeNum].Temp, P.numTimeStepsInAvg
            )
            if (state.dataSize.PlantSizData[P.plantSizingIndex].LoopType == DataSizing.TypeOfPlantLoop.Heating or
                state.dataSize.PlantSizData[P.plantSizingIndex].LoopType == DataSizing.TypeOfPlantLoop.Steam):
                P.loopDemand_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                    state, state.dataPlnt.PlantLoop[P.plantLoopIndex].HeatingDemand, P.numTimeStepsInAvg
                )
            elif (state.dataSize.PlantSizData[P.plantSizingIndex].LoopType == DataSizing.TypeOfPlantLoop.Cooling or
                  state.dataSize.PlantSizData[P.plantSizingIndex].LoopType == DataSizing.TypeOfPlantLoop.Condenser):
                P.loopDemand_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                    state, state.dataPlnt.PlantLoop[P.plantLoopIndex].CoolingDemand, P.numTimeStepsInAvg
                )
            self.plantCoincAnalyObjs[p] = P

    def PostProcessLogs(inout self):
        for l in range(len(self.sizingLogger.logObjs)):
            var L = self.sizingLogger.logObjs[l]
            L.AverageSysTimeSteps()   # collapse subtimestep data into zone step data
            L.ProcessRunningAverage()  # apply zone step moving average
            self.sizingLogger.logObjs[l] = L

    def ProcessCoincidentPlantSizeAdjustments(inout self, inout state: EnergyPlusData, HVACSizingIterCount: Int):
        self.plantCoinAnalyRequestsAnotherIteration = False
        for p in range(len(self.plantCoincAnalyObjs)):
            var P = self.plantCoincAnalyObjs[p]
            P.newFoundMassFlowRateTimeStamp = self.sizingLogger.logObjs[P.supplyInletNodeFlow_LogIndex].GetLogVariableDataMax(state)
            P.peakMdotCoincidentDemand = self.sizingLogger.logObjs[P.loopDemand_LogIndex].GetLogVariableDataAtTimestamp(P.newFoundMassFlowRateTimeStamp)
            P.peakMdotCoincidentReturnTemp = self.sizingLogger.logObjs[P.supplyInletNodeTemp_LogIndex].GetLogVariableDataAtTimestamp(P.newFoundMassFlowRateTimeStamp)
            P.NewFoundMaxDemandTimeStamp = self.sizingLogger.logObjs[P.loopDemand_LogIndex].GetLogVariableDataMax(state)
            P.peakDemandMassFlow = self.sizingLogger.logObjs[P.supplyInletNodeFlow_LogIndex].GetLogVariableDataAtTimestamp(P.NewFoundMaxDemandTimeStamp)
            P.peakDemandReturnTemp = self.sizingLogger.logObjs[P.supplyInletNodeTemp_LogIndex].GetLogVariableDataAtTimestamp(P.NewFoundMaxDemandTimeStamp)
            P.ResolveDesignFlowRate(state, HVACSizingIterCount)
            if P.anotherIterationDesired:
                self.plantCoinAnalyRequestsAnotherIteration = True
            self.plantCoincAnalyObjs[p] = P

    def RedoKickOffAndResize(inout self, inout state: EnergyPlusData):
        var ErrorsFound: Bool = False
        state.dataGlobal.KickOffSimulation = True
        state.dataGlobal.RedoSizesHVACSimulation = True
        Weather.ResetEnvironmentCounter(state)
        SimulationManager.SetupSimulation(state, ErrorsFound)
        state.dataGlobal.KickOffSimulation = False
        state.dataGlobal.RedoSizesHVACSimulation = False

    def UpdateSizingLogsZoneStep(inout self, inout state: EnergyPlusData):
        self.sizingLogger.UpdateSizingLogValuesZoneStep(state)

    def UpdateSizingLogsSystemStep(inout self, inout state: EnergyPlusData):
        self.sizingLogger.UpdateSizingLogValuesSystemStep(state)

def ManageHVACSizingSimulation(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    var hvacSizingSimulationManager = Pointer[HVACSizingSimulationManager].alloc(1)
    hvacSizingSimulationManager[] = HVACSizingSimulationManager()
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager = hvacSizingSimulationManager

    var HVACSizingIterCount: Int
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager[].DetermineSizingAnalysesNeeded(state)
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager[].SetupSizingAnalyses(state)
    DisplayString(state, "Beginning HVAC Sizing Simulation")
    state.dataGlobal.DoingHVACSizingSimulations = True
    state.dataGlobal.DoOutputReporting = True
    Weather.ResetEnvironmentCounter(state)

    for HVACSizingIterCount in range(1, state.dataGlobal.HVACSizingSimMaxIterations + 1):  # inclusive loop
        Weather.AddDesignSetToEnvironmentStruct(state, HVACSizingIterCount)
        state.dataGlobal.WarmupFlag = True
        var Available: Bool = True
        for i in range(state.dataWeather.NumOfEnvrn):  # 0-based
            Weather.GetNextEnvironment(state, Available, ErrorsFound)
            if ErrorsFound:
                break
            if not Available:
                continue
            state.dataHVACSizingSimMgr.hvacSizingSimulationManager.sizingLogger.SetupSizingLogsNewEnvironment(state)
            if state.dataGlobal.KindOfSim == Constant.KindOfSim.RunPeriodWeather:
                continue
            if state.dataGlobal.KindOfSim == Constant.KindOfSim.DesignDay:
                continue
            if state.dataGlobal.KindOfSim == Constant.KindOfSim.RunPeriodDesign:
                continue
            if state.dataWeather.Environment[state.dataWeather.Envrn].HVACSizingIterationNum != HVACSizingIterCount:
                continue
            if state.dataSysVars.ReportDuringHVACSizingSimulation:
                if state.dataSQLiteProcedures.sqlite:
                    state.dataSQLiteProcedures.sqlite.sqliteBegin()
                    state.dataSQLiteProcedures.sqlite.createSQLiteEnvironmentPeriodRecord(
                        state.dataEnvrn.CurEnvirNum, state.dataEnvrn.EnvironmentName, state.dataGlobal.KindOfSim
                    )
                    state.dataSQLiteProcedures.sqlite.sqliteCommit()
            state.dataErrTracking.ExitDuringSimulations = True
            DisplayString(state, "Initializing New Environment Parameters, HVAC Sizing Simulation")
            state.dataGlobal.BeginEnvrnFlag = True
            state.dataGlobal.EndEnvrnFlag = False
            state.dataGlobal.WarmupFlag = True
            state.dataGlobal.DayOfSim = 0
            state.dataGlobal.DayOfSimChr = "0"
            state.dataReportFlag.NumOfWarmupDays = 0
            var anyEMSRan: Bool
            ManageEMS(state, EMSManager.EMSCallFrom.BeginNewEnvironment, anyEMSRan, Optional_int_const())  # calling point
            while (state.dataGlobal.DayOfSim < state.dataGlobal.NumOfDayInEnvrn) or (state.dataGlobal.WarmupFlag):  # Begin day loop ...
                if state.dataSQLiteProcedures.sqlite:
                    state.dataSQLiteProcedures.sqlite.sqliteBegin()  # setup for one transaction per day
                state.dataGlobal.DayOfSim = state.dataGlobal.DayOfSim + 1
                state.dataGlobal.DayOfSimChr = String(state.dataGlobal.DayOfSim)
                if not state.dataGlobal.WarmupFlag:
                    state.dataEnvrn.CurrentOverallSimDay = state.dataEnvrn.CurrentOverallSimDay + 1
                    DisplaySimDaysProgress(state, state.dataEnvrn.CurrentOverallSimDay, state.dataEnvrn.TotalOverallSimDays)
                else:
                    state.dataGlobal.DayOfSimChr = "0"
                state.dataGlobal.BeginDayFlag = True
                state.dataGlobal.EndDayFlag = False
                if state.dataGlobal.WarmupFlag:
                    state.dataReportFlag.NumOfWarmupDays = state.dataReportFlag.NumOfWarmupDays + 1
                    state.dataReportFlag.cWarmupDay = String(state.dataReportFlag.NumOfWarmupDays)
                    DisplayString(state, "Warming up {" + state.dataReportFlag.cWarmupDay + '}')
                elif state.dataGlobal.DayOfSim == 1:
                    DisplayString(
                        state,
                        "Starting HVAC Sizing Simulation at " + state.dataEnvrn.CurMnDy + " for " + state.dataEnvrn.EnvironmentName
                    )
                    # static string_view Format_700("Environment:WarmupDays,{:3}\n");
                    var Format_700: String = "Environment:WarmupDays,{:3}\n"
                    print(state.files.eio, Format_700, state.dataReportFlag.NumOfWarmupDays)
                elif state.dataReportFlag.DisplayPerfSimulationFlag:
                    DisplayString(state, "Continuing Simulation at " + state.dataEnvrn.CurMnDy + " for " + state.dataEnvrn.EnvironmentName)
                    state.dataReportFlag.DisplayPerfSimulationFlag = False
                for state.dataGlobal.HourOfDay in range(1, 25):  # Begin hour loop ... 1..24 inclusive
                    state.dataGlobal.BeginHourFlag = True
                    state.dataGlobal.EndHourFlag = False
                    for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):  # 1-based
                        if state.dataGlobal.AnySlabsInModel or state.dataGlobal.AnyBasementsInModel:
                            PlantPipingSystemsManager.SimulateGroundDomains(state, False)
                        state.dataGlobal.BeginTimeStepFlag = True
                        if state.dataGlobal.TimeStep == state.dataGlobal.TimeStepsInHour:
                            state.dataGlobal.EndHourFlag = True
                            if state.dataGlobal.HourOfDay == 24:
                                state.dataGlobal.EndDayFlag = True
                                if not state.dataGlobal.WarmupFlag and (state.dataGlobal.DayOfSim == state.dataGlobal.NumOfDayInEnvrn):
                                    state.dataGlobal.EndEnvrnFlag = True
                        Weather.ManageWeather(state)
                        ExteriorEnergyUse.ManageExteriorEnergyUse(state)
                        HeatBalanceManager.ManageHeatBalance(state)
                        state.dataGlobal.BeginHourFlag = False
                        state.dataGlobal.BeginDayFlag = False
                        state.dataGlobal.BeginEnvrnFlag = False
                        state.dataGlobal.BeginSimFlag = False
                    # TimeStep loop
                    state.dataGlobal.PreviousHour = state.dataGlobal.HourOfDay
                # ... End hour loop.
                if state.dataSQLiteProcedures.sqlite:
                    if state.dataSysVars.ReportDuringHVACSizingSimulation:
                        state.dataSQLiteProcedures.sqlite.sqliteCommit()  # one transaction per day
                    else:
                        state.dataSQLiteProcedures.sqlite.sqliteRollback()  # Cancel transaction
            # ... End day loop.
        # ... End environment loop.
        if ErrorsFound:
            ShowFatalError(state, "Error condition occurred.  Previous Severe Errors cause termination.")
        state.dataHVACSizingSimMgr.hvacSizingSimulationManager.PostProcessLogs()
        state.dataHVACSizingSimMgr.hvacSizingSimulationManager.ProcessCoincidentPlantSizeAdjustments(state, HVACSizingIterCount)
        state.dataHVACSizingSimMgr.hvacSizingSimulationManager.RedoKickOffAndResize(state)
        if not state.dataHVACSizingSimMgr.hvacSizingSimulationManager.plantCoinAnalyRequestsAnotherIteration:
            break
        state.dataHVACSizingSimMgr.hvacSizingSimulationManager.sizingLogger.IncrementSizingPeriodSet()
    # End HVAC Sizing Iteration loop
    state.dataGlobal.WarmupFlag = False
    state.dataGlobal.DoOutputReporting = True
    state.dataGlobal.DoingHVACSizingSimulations = False
    # delete/reset unique_ptr
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager[].__del__()
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager = Pointer[HVACSizingSimulationManager]()