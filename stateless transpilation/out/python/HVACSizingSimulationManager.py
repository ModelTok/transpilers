# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data structures
#   - dataSize.NumPltSizInput, dataSize.PlantSizData, dataSize.PlantSizData[i].ConcurrenceOption, 
#     dataSize.PlantSizData[i].PlantLoopName, dataSize.PlantSizData[i].NumTimeStepsInAvg, 
#     dataSize.PlantSizData[i].LoopType
#   - dataPlnt.TotNumLoops, dataPlnt.PlantLoop, dataPlnt.PlantLoop[i].Name,
#     dataPlnt.PlantLoop[i].LoopSide, dataPlnt.PlantLoop[i].glycol, 
#     dataPlnt.PlantLoop[i].HeatingDemand, dataPlnt.PlantLoop[i].CoolingDemand
#   - dataLoopNodes.Node, Node[].MassFlowRate, Node[].Temp
#   - dataGlobal: flags and counters (KickOffSimulation, RedoSizesHVACSimulation, DoingHVACSizingSimulations,
#     DoOutputReporting, WarmupFlag, HVACSizingSimMaxIterations, KindOfSim, DayOfSim, NumOfDayInEnvrn,
#     HourOfDay, TimeStep, TimeStepsInHour, BeginEnvrnFlag, EndEnvrnFlag, BeginTimeStepFlag,
#     EndHourFlag, EndDayFlag, AnySlabsInModel, AnyBasementsInModel, BeginHourFlag, BeginDayFlag,
#     BeginSimFlag, PreviousHour, DayOfSimChr)
#   - dataWeather.NumOfEnvrn, dataWeather.Envrn, dataWeather.Environment, 
#     Environment[].HVACSizingIterationNum
#   - dataSysVars.ReportDuringHVACSizingSimulation
#   - dataSQLiteProcedures.sqlite
#   - dataErrTracking.ExitDuringSimulations
#   - dataReportFlag.NumOfWarmupDays, dataReportFlag.cWarmupDay, dataReportFlag.DisplayPerfSimulationFlag
#   - dataEnvrn.CurEnvirNum, dataEnvrn.EnvironmentName, dataEnvrn.CurMnDy, 
#     dataEnvrn.CurrentOverallSimDay, dataEnvrn.TotalOverallSimDays
#   - dataHVACSizingSimMgr.hvacSizingSimulationManager
#   - files.eio
# - PlantCoinicidentAnalysis: type from SizingAnalysisObjects
# - SizingLoggerFramework: type from SizingAnalysisObjects
# - Constant.CWInitConvTemp, Constant.KindOfSim (RunPeriodWeather, DesignDay, RunPeriodDesign)
# - DataSizing.SizingConcurrence (Coincident), DataSizing.TypeOfPlantLoop (Heating, Steam, Cooling, Condenser)
# - DataPlant.LoopSideLocation (Supply)
# - Weather.ResetEnvironmentCounter, Weather.AddDesignSetToEnvironmentStruct, 
#   Weather.GetNextEnvironment, Weather.ManageWeather
# - SimulationManager.SetupSimulation
# - EMSManager.ManageEMS, EMSManager.EMSCallFrom (BeginNewEnvironment)
# - ExteriorEnergyUse.ManageExteriorEnergyUse
# - HeatBalanceManager.ManageHeatBalance
# - PlantPipingSystemsManager.SimulateGroundDomains
# - DisplayRoutines.DisplayString, DisplayRoutines.DisplaySimDaysProgress
# - UtilityRoutines.ShowFatalError


class HVACSizingSimulationManager:
    def __init__(self):
        self.plantCoincAnalyObjs = []
        self.plantCoinAnalyRequestsAnotherIteration = False
        self.sizingLogger = None

    def DetermineSizingAnalysesNeeded(self, state):
        for i in range(1, state.dataSize.NumPltSizInput + 1):
            if state.dataSize.PlantSizData[i - 1].ConcurrenceOption == state.DataSizing.SizingConcurrence.Coincident:
                self.CreateNewCoincidentPlantAnalysisObject(state, state.dataSize.PlantSizData[i - 1].PlantLoopName, i)

    def CreateNewCoincidentPlantAnalysisObject(self, state, PlantLoopName, PlantSizingIndex):
        density = None
        cp = None

        for i in range(1, state.dataPlnt.TotNumLoops + 1):
            if PlantLoopName == state.dataPlnt.PlantLoop[i - 1].Name:
                density = state.dataPlnt.PlantLoop[i - 1].glycol.getDensity(state, state.Constant.CWInitConvTemp, "createNewCoincidentPlantAnalysisObject")
                cp = state.dataPlnt.PlantLoop[i - 1].glycol.getSpecificHeat(state, state.Constant.CWInitConvTemp, "createNewCoincidentPlantAnalysisObject")

                self.plantCoincAnalyObjs.append(
                    state.PlantCoinicidentAnalysis(
                        PlantLoopName,
                        i,
                        state.dataPlnt.PlantLoop[i - 1].LoopSide[state.DataPlant.LoopSideLocation.Supply].NodeNumIn,
                        density,
                        cp,
                        state.dataSize.PlantSizData[PlantSizingIndex - 1].NumTimeStepsInAvg,
                        PlantSizingIndex
                    )
                )

    def SetupSizingAnalyses(self, state):
        for P in self.plantCoincAnalyObjs:
            P.supplyInletNodeFlow_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                state, state.dataLoopNodes.Node[P.supplySideInletNodeNum - 1].MassFlowRate, P.numTimeStepsInAvg
            )
            P.supplyInletNodeTemp_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                state, state.dataLoopNodes.Node[P.supplySideInletNodeNum - 1].Temp, P.numTimeStepsInAvg
            )
            if (state.dataSize.PlantSizData[P.plantSizingIndex - 1].LoopType == state.DataSizing.TypeOfPlantLoop.Heating or
                state.dataSize.PlantSizData[P.plantSizingIndex - 1].LoopType == state.DataSizing.TypeOfPlantLoop.Steam):
                P.loopDemand_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                    state, state.dataPlnt.PlantLoop[P.plantLoopIndex - 1].HeatingDemand, P.numTimeStepsInAvg
                )
            elif (state.dataSize.PlantSizData[P.plantSizingIndex - 1].LoopType == state.DataSizing.TypeOfPlantLoop.Cooling or
                  state.dataSize.PlantSizData[P.plantSizingIndex - 1].LoopType == state.DataSizing.TypeOfPlantLoop.Condenser):
                P.loopDemand_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                    state, state.dataPlnt.PlantLoop[P.plantLoopIndex - 1].CoolingDemand, P.numTimeStepsInAvg
                )

    def PostProcessLogs(self):
        for L in self.sizingLogger.logObjs:
            L.AverageSysTimeSteps()
            L.ProcessRunningAverage()

    def ProcessCoincidentPlantSizeAdjustments(self, state, HVACSizingIterCount):
        self.plantCoinAnalyRequestsAnotherIteration = False
        for P in self.plantCoincAnalyObjs:
            P.newFoundMassFlowRateTimeStamp = self.sizingLogger.logObjs[P.supplyInletNodeFlow_LogIndex].GetLogVariableDataMax(state)
            P.peakMdotCoincidentDemand = self.sizingLogger.logObjs[P.loopDemand_LogIndex].GetLogVariableDataAtTimestamp(P.newFoundMassFlowRateTimeStamp)
            P.peakMdotCoincidentReturnTemp = self.sizingLogger.logObjs[P.supplyInletNodeTemp_LogIndex].GetLogVariableDataAtTimestamp(P.newFoundMassFlowRateTimeStamp)

            P.NewFoundMaxDemandTimeStamp = self.sizingLogger.logObjs[P.loopDemand_LogIndex].GetLogVariableDataMax(state)
            P.peakDemandMassFlow = self.sizingLogger.logObjs[P.supplyInletNodeFlow_LogIndex].GetLogVariableDataAtTimestamp(P.NewFoundMaxDemandTimeStamp)
            P.peakDemandReturnTemp = self.sizingLogger.logObjs[P.supplyInletNodeTemp_LogIndex].GetLogVariableDataAtTimestamp(P.NewFoundMaxDemandTimeStamp)

            P.ResolveDesignFlowRate(state, HVACSizingIterCount)
            if P.anotherIterationDesired:
                self.plantCoinAnalyRequestsAnotherIteration = True

    def RedoKickOffAndResize(self, state):
        ErrorsFound = False
        state.dataGlobal.KickOffSimulation = True
        state.dataGlobal.RedoSizesHVACSimulation = True

        state.Weather.ResetEnvironmentCounter(state)
        state.SimulationManager.SetupSimulation(state, ErrorsFound)

        state.dataGlobal.KickOffSimulation = False
        state.dataGlobal.RedoSizesHVACSimulation = False

    def UpdateSizingLogsZoneStep(self, state):
        self.sizingLogger.UpdateSizingLogValuesZoneStep(state)

    def UpdateSizingLogsSystemStep(self, state):
        self.sizingLogger.UpdateSizingLogValuesSystemStep(state)


class HVACSizingSimMgrData:
    def __init__(self):
        self.hvacSizingSimulationManager = None

    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        self.hvacSizingSimulationManager = None


def ManageHVACSizingSimulation(state, ErrorsFound):
    hvacSizingSimulationManager = HVACSizingSimulationManager()
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager = hvacSizingSimulationManager

    hvacSizingSimulationManager.sizingLogger = state.SizingLoggerFramework()

    hvacSizingSimulationManager.DetermineSizingAnalysesNeeded(state)

    hvacSizingSimulationManager.SetupSizingAnalyses(state)

    state.DisplayString(state, "Beginning HVAC Sizing Simulation")
    state.dataGlobal.DoingHVACSizingSimulations = True
    state.dataGlobal.DoOutputReporting = True

    state.Weather.ResetEnvironmentCounter(state)

    for HVACSizingIterCount in range(1, state.dataGlobal.HVACSizingSimMaxIterations + 1):
        state.Weather.AddDesignSetToEnvironmentStruct(state, HVACSizingIterCount)

        state.dataGlobal.WarmupFlag = True
        Available = True
        for i in range(1, state.dataWeather.NumOfEnvrn + 1):
            state.Weather.GetNextEnvironment(state, Available, ErrorsFound)
            if ErrorsFound:
                break
            if not Available:
                continue

            hvacSizingSimulationManager.sizingLogger.SetupSizingLogsNewEnvironment(state)

            if state.dataGlobal.KindOfSim == state.Constant.KindOfSim.RunPeriodWeather:
                continue
            if state.dataGlobal.KindOfSim == state.Constant.KindOfSim.DesignDay:
                continue
            if state.dataGlobal.KindOfSim == state.Constant.KindOfSim.RunPeriodDesign:
                continue

            if state.dataWeather.Environment[state.dataWeather.Envrn - 1].HVACSizingIterationNum != HVACSizingIterCount:
                continue

            if state.dataSysVars.ReportDuringHVACSizingSimulation:
                if state.dataSQLiteProcedures.sqlite:
                    state.dataSQLiteProcedures.sqlite.sqliteBegin()
                    state.dataSQLiteProcedures.sqlite.createSQLiteEnvironmentPeriodRecord(
                        state.dataEnvrn.CurEnvirNum, state.dataEnvrn.EnvironmentName, state.dataGlobal.KindOfSim
                    )
                    state.dataSQLiteProcedures.sqlite.sqliteCommit()

            state.dataErrTracking.ExitDuringSimulations = True

            state.DisplayString(state, "Initializing New Environment Parameters, HVAC Sizing Simulation")

            state.dataGlobal.BeginEnvrnFlag = True
            state.dataGlobal.EndEnvrnFlag = False
            state.dataGlobal.WarmupFlag = True
            state.dataGlobal.DayOfSim = 0
            state.dataGlobal.DayOfSimChr = "0"
            state.dataReportFlag.NumOfWarmupDays = 0

            anyEMSRan = False
            state.ManageEMS(state, state.EMSManager.EMSCallFrom.BeginNewEnvironment, anyEMSRan)

            while (state.dataGlobal.DayOfSim < state.dataGlobal.NumOfDayInEnvrn) or state.dataGlobal.WarmupFlag:
                if state.dataSQLiteProcedures.sqlite:
                    state.dataSQLiteProcedures.sqlite.sqliteBegin()

                state.dataGlobal.DayOfSim += 1
                state.dataGlobal.DayOfSimChr = str(state.dataGlobal.DayOfSim)
                if not state.dataGlobal.WarmupFlag:
                    state.dataEnvrn.CurrentOverallSimDay += 1
                    state.DisplaySimDaysProgress(state, state.dataEnvrn.CurrentOverallSimDay, state.dataEnvrn.TotalOverallSimDays)
                else:
                    state.dataGlobal.DayOfSimChr = "0"

                state.dataGlobal.BeginDayFlag = True
                state.dataGlobal.EndDayFlag = False

                if state.dataGlobal.WarmupFlag:
                    state.dataReportFlag.NumOfWarmupDays += 1
                    state.dataReportFlag.cWarmupDay = str(state.dataReportFlag.NumOfWarmupDays)
                    state.DisplayString(state, "Warming up {" + state.dataReportFlag.cWarmupDay + "}")
                elif state.dataGlobal.DayOfSim == 1:
                    state.DisplayString(
                        state,
                        f"Starting HVAC Sizing Simulation at {state.dataEnvrn.CurMnDy} for {state.dataEnvrn.EnvironmentName}"
                    )
                    state.files.eio.write(f"Environment:WarmupDays,{state.dataReportFlag.NumOfWarmupDays:3d}\n")
                elif state.dataReportFlag.DisplayPerfSimulationFlag:
                    state.DisplayString(
                        state,
                        f"Continuing Simulation at {state.dataEnvrn.CurMnDy} for {state.dataEnvrn.EnvironmentName}"
                    )
                    state.dataReportFlag.DisplayPerfSimulationFlag = False

                for state.dataGlobal.HourOfDay in range(1, 25):
                    state.dataGlobal.BeginHourFlag = True
                    state.dataGlobal.EndHourFlag = False

                    for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
                        if state.dataGlobal.AnySlabsInModel or state.dataGlobal.AnyBasementsInModel:
                            state.PlantPipingSystemsManager.SimulateGroundDomains(state, False)

                        state.dataGlobal.BeginTimeStepFlag = True

                        if state.dataGlobal.TimeStep == state.dataGlobal.TimeStepsInHour:
                            state.dataGlobal.EndHourFlag = True
                            if state.dataGlobal.HourOfDay == 24:
                                state.dataGlobal.EndDayFlag = True
                                if not state.dataGlobal.WarmupFlag and (state.dataGlobal.DayOfSim == state.dataGlobal.NumOfDayInEnvrn):
                                    state.dataGlobal.EndEnvrnFlag = True

                        state.Weather.ManageWeather(state)

                        state.ExteriorEnergyUse.ManageExteriorEnergyUse(state)

                        state.HeatBalanceManager.ManageHeatBalance(state)

                        state.dataGlobal.BeginHourFlag = False
                        state.dataGlobal.BeginDayFlag = False
                        state.dataGlobal.BeginEnvrnFlag = False
                        state.dataGlobal.BeginSimFlag = False

                state.dataGlobal.PreviousHour = state.dataGlobal.HourOfDay

                if state.dataSQLiteProcedures.sqlite:
                    if state.dataSysVars.ReportDuringHVACSizingSimulation:
                        state.dataSQLiteProcedures.sqlite.sqliteCommit()
                    else:
                        state.dataSQLiteProcedures.sqlite.sqliteRollback()

        if ErrorsFound:
            state.ShowFatalError(state, "Error condition occurred.  Previous Severe Errors cause termination.")

        hvacSizingSimulationManager.PostProcessLogs()

        hvacSizingSimulationManager.ProcessCoincidentPlantSizeAdjustments(state, HVACSizingIterCount)

        hvacSizingSimulationManager.RedoKickOffAndResize(state)

        if not hvacSizingSimulationManager.plantCoinAnalyRequestsAnotherIteration:
            break

        hvacSizingSimulationManager.sizingLogger.IncrementSizingPeriodSet()

    state.dataGlobal.WarmupFlag = False
    state.dataGlobal.DoOutputReporting = True
    state.dataGlobal.DoingHVACSizingSimulations = False
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager = None
