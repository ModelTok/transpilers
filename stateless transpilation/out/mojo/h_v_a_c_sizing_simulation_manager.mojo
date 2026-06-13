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


struct HVACSizingSimulationManager:
    var plantCoincAnalyObjs: List[AnyType]
    var plantCoinAnalyRequestsAnotherIteration: Bool
    var sizingLogger: AnyType

    fn __init__(inout self):
        self.plantCoincAnalyObjs = List[AnyType]()
        self.plantCoinAnalyRequestsAnotherIteration = False
        self.sizingLogger = AnyType()

    fn DetermineSizingAnalysesNeeded(inout self, inout state: AnyType):
        for i in range(1, state.dataSize.NumPltSizInput + 1):
            if state.dataSize.PlantSizData[i - 1].ConcurrenceOption == state.DataSizing.SizingConcurrence.Coincident:
                self.CreateNewCoincidentPlantAnalysisObject(state, state.dataSize.PlantSizData[i - 1].PlantLoopName, i)

    fn CreateNewCoincidentPlantAnalysisObject(inout self, inout state: AnyType, plant_loop_name: StringLiteral, plant_sizing_index: Int):
        var density: Float64 = 0.0
        var cp: Float64 = 0.0

        for i in range(1, state.dataPlnt.TotNumLoops + 1):
            if plant_loop_name == state.dataPlnt.PlantLoop[i - 1].Name:
                density = state.dataPlnt.PlantLoop[i - 1].glycol.getDensity(
                    state, 
                    state.Constant.CWInitConvTemp, 
                    "createNewCoincidentPlantAnalysisObject"
                )
                cp = state.dataPlnt.PlantLoop[i - 1].glycol.getSpecificHeat(
                    state, 
                    state.Constant.CWInitConvTemp, 
                    "createNewCoincidentPlantAnalysisObject"
                )

                self.plantCoincAnalyObjs.append(
                    state.PlantCoinicidentAnalysis(
                        plant_loop_name,
                        i,
                        state.dataPlnt.PlantLoop[i - 1].LoopSide[state.DataPlant.LoopSideLocation.Supply].NodeNumIn,
                        density,
                        cp,
                        state.dataSize.PlantSizData[plant_sizing_index - 1].NumTimeStepsInAvg,
                        plant_sizing_index
                    )
                )

    fn SetupSizingAnalyses(inout self, inout state: AnyType):
        for P in self.plantCoincAnalyObjs:
            P.supplyInletNodeFlow_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                state, 
                state.dataLoopNodes.Node[P.supplySideInletNodeNum - 1].MassFlowRate, 
                P.numTimeStepsInAvg
            )
            P.supplyInletNodeTemp_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                state, 
                state.dataLoopNodes.Node[P.supplySideInletNodeNum - 1].Temp, 
                P.numTimeStepsInAvg
            )
            if (state.dataSize.PlantSizData[P.plantSizingIndex - 1].LoopType == state.DataSizing.TypeOfPlantLoop.Heating or
                state.dataSize.PlantSizData[P.plantSizingIndex - 1].LoopType == state.DataSizing.TypeOfPlantLoop.Steam):
                P.loopDemand_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                    state, 
                    state.dataPlnt.PlantLoop[P.plantLoopIndex - 1].HeatingDemand, 
                    P.numTimeStepsInAvg
                )
            elif (state.dataSize.PlantSizData[P.plantSizingIndex - 1].LoopType == state.DataSizing.TypeOfPlantLoop.Cooling or
                  state.dataSize.PlantSizData[P.plantSizingIndex - 1].LoopType == state.DataSizing.TypeOfPlantLoop.Condenser):
                P.loopDemand_LogIndex = self.sizingLogger.SetupVariableSizingLog(
                    state, 
                    state.dataPlnt.PlantLoop[P.plantLoopIndex - 1].CoolingDemand, 
                    P.numTimeStepsInAvg
                )

    fn PostProcessLogs(inout self):
        for L in self.sizingLogger.logObjs:
            L.AverageSysTimeSteps()
            L.ProcessRunningAverage()

    fn ProcessCoincidentPlantSizeAdjustments(inout self, inout state: AnyType, hvac_sizing_iter_count: Int):
        self.plantCoinAnalyRequestsAnotherIteration = False
        for P in self.plantCoincAnalyObjs:
            P.newFoundMassFlowRateTimeStamp = self.sizingLogger.logObjs[P.supplyInletNodeFlow_LogIndex].GetLogVariableDataMax(state)
            P.peakMdotCoincidentDemand = self.sizingLogger.logObjs[P.loopDemand_LogIndex].GetLogVariableDataAtTimestamp(P.newFoundMassFlowRateTimeStamp)
            P.peakMdotCoincidentReturnTemp = self.sizingLogger.logObjs[P.supplyInletNodeTemp_LogIndex].GetLogVariableDataAtTimestamp(P.newFoundMassFlowRateTimeStamp)

            P.NewFoundMaxDemandTimeStamp = self.sizingLogger.logObjs[P.loopDemand_LogIndex].GetLogVariableDataMax(state)
            P.peakDemandMassFlow = self.sizingLogger.logObjs[P.supplyInletNodeFlow_LogIndex].GetLogVariableDataAtTimestamp(P.NewFoundMaxDemandTimeStamp)
            P.peakDemandReturnTemp = self.sizingLogger.logObjs[P.supplyInletNodeTemp_LogIndex].GetLogVariableDataAtTimestamp(P.NewFoundMaxDemandTimeStamp)

            P.ResolveDesignFlowRate(state, hvac_sizing_iter_count)
            if P.anotherIterationDesired:
                self.plantCoinAnalyRequestsAnotherIteration = True

    fn RedoKickOffAndResize(inout self, inout state: AnyType):
        var errors_found: Bool = False
        state.dataGlobal.KickOffSimulation = True
        state.dataGlobal.RedoSizesHVACSimulation = True

        state.Weather.ResetEnvironmentCounter(state)
        state.SimulationManager.SetupSimulation(state, errors_found)

        state.dataGlobal.KickOffSimulation = False
        state.dataGlobal.RedoSizesHVACSimulation = False

    fn UpdateSizingLogsZoneStep(inout self, inout state: AnyType):
        self.sizingLogger.UpdateSizingLogValuesZoneStep(state)

    fn UpdateSizingLogsSystemStep(inout self, inout state: AnyType):
        self.sizingLogger.UpdateSizingLogValuesSystemStep(state)


struct HVACSizingSimMgrData:
    var hvacSizingSimulationManager: AnyType

    fn __init__(inout self):
        self.hvacSizingSimulationManager = AnyType()

    fn init_constant_state(inout self, inout state: AnyType):
        pass

    fn init_state(inout self, inout state: AnyType):
        pass

    fn clear_state(inout self):
        self.hvacSizingSimulationManager = AnyType()


fn ManageHVACSizingSimulation(inout state: AnyType, inout errors_found: Bool):
    var hvac_sizing_simulation_manager = HVACSizingSimulationManager()
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager = hvac_sizing_simulation_manager

    hvac_sizing_simulation_manager.sizingLogger = state.SizingLoggerFramework()

    hvac_sizing_simulation_manager.DetermineSizingAnalysesNeeded(state)

    hvac_sizing_simulation_manager.SetupSizingAnalyses(state)

    state.DisplayString(state, "Beginning HVAC Sizing Simulation")
    state.dataGlobal.DoingHVACSizingSimulations = True
    state.dataGlobal.DoOutputReporting = True

    state.Weather.ResetEnvironmentCounter(state)

    for hvac_sizing_iter_count in range(1, state.dataGlobal.HVACSizingSimMaxIterations + 1):
        state.Weather.AddDesignSetToEnvironmentStruct(state, hvac_sizing_iter_count)

        state.dataGlobal.WarmupFlag = True
        var available: Bool = True
        for i in range(1, state.dataWeather.NumOfEnvrn + 1):
            state.Weather.GetNextEnvironment(state, available, errors_found)
            if errors_found:
                break
            if not available:
                continue

            hvac_sizing_simulation_manager.sizingLogger.SetupSizingLogsNewEnvironment(state)

            if state.dataGlobal.KindOfSim == state.Constant.KindOfSim.RunPeriodWeather:
                continue
            if state.dataGlobal.KindOfSim == state.Constant.KindOfSim.DesignDay:
                continue
            if state.dataGlobal.KindOfSim == state.Constant.KindOfSim.RunPeriodDesign:
                continue

            if state.dataWeather.Environment[state.dataWeather.Envrn - 1].HVACSizingIterationNum != hvac_sizing_iter_count:
                continue

            if state.dataSysVars.ReportDuringHVACSizingSimulation:
                if state.dataSQLiteProcedures.sqlite:
                    state.dataSQLiteProcedures.sqlite.sqliteBegin()
                    state.dataSQLiteProcedures.sqlite.createSQLiteEnvironmentPeriodRecord(
                        state.dataEnvrn.CurEnvirNum, 
                        state.dataEnvrn.EnvironmentName, 
                        state.dataGlobal.KindOfSim
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

            var any_ems_ran: Bool = False
            state.ManageEMS(state, state.EMSManager.EMSCallFrom.BeginNewEnvironment, any_ems_ran)

            while (state.dataGlobal.DayOfSim < state.dataGlobal.NumOfDayInEnvrn) or state.dataGlobal.WarmupFlag:
                if state.dataSQLiteProcedures.sqlite:
                    state.dataSQLiteProcedures.sqlite.sqliteBegin()

                state.dataGlobal.DayOfSim += 1
                state.dataGlobal.DayOfSimChr = str(state.dataGlobal.DayOfSim)
                if not state.dataGlobal.WarmupFlag:
                    state.dataEnvrn.CurrentOverallSimDay += 1
                    state.DisplaySimDaysProgress(
                        state, 
                        state.dataEnvrn.CurrentOverallSimDay, 
                        state.dataEnvrn.TotalOverallSimDays
                    )
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
                        "Starting HVAC Sizing Simulation at " + state.dataEnvrn.CurMnDy + " for " + state.dataEnvrn.EnvironmentName
                    )
                    state.files.eio.write("Environment:WarmupDays," + str(state.dataReportFlag.NumOfWarmupDays).rjust(3) + "\n")
                elif state.dataReportFlag.DisplayPerfSimulationFlag:
                    state.DisplayString(
                        state,
                        "Continuing Simulation at " + state.dataEnvrn.CurMnDy + " for " + state.dataEnvrn.EnvironmentName
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

        if errors_found:
            state.ShowFatalError(state, "Error condition occurred.  Previous Severe Errors cause termination.")

        hvac_sizing_simulation_manager.PostProcessLogs()

        hvac_sizing_simulation_manager.ProcessCoincidentPlantSizeAdjustments(state, hvac_sizing_iter_count)

        hvac_sizing_simulation_manager.RedoKickOffAndResize(state)

        if not hvac_sizing_simulation_manager.plantCoinAnalyRequestsAnotherIteration:
            break

        hvac_sizing_simulation_manager.sizingLogger.IncrementSizingPeriodSet()

    state.dataGlobal.WarmupFlag = False
    state.dataGlobal.DoOutputReporting = True
    state.dataGlobal.DoingHVACSizingSimulations = False
    state.dataHVACSizingSimMgr.hvacSizingSimulationManager = AnyType()
