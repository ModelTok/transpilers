from gtest import Test, TestFixture, TestCase
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from Fixtures.SQLiteFixture import SQLiteFixture
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.HVACSizingSimulationManager import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.UtilityRoutines import *

using EnergyPlus = EnergyPlus
using DataPlant = DataPlant
using DataSizing = DataSizing
using OutputReportPredefined = OutputReportPredefined
using OutputProcessor = OutputProcessor

@value
struct HVACSizingSimulationManagerTest(EnergyPlusFixture):
    def SetUp(inout self):
        EnergyPlusFixture.SetUp() # Sets up the base fixture first.
        state.dataFluid.init_state(state)
        state.dataWeather.NumOfEnvrn = 2
        state.dataWeather.Environment.allocate(state.dataWeather.NumOfEnvrn)
        state.dataWeather.Environment[0].KindOfEnvrn = Constant.KindOfSim.DesignDay
        state.dataWeather.Environment[0].DesignDayNum = 1
        state.dataWeather.Environment[1].KindOfEnvrn = Constant.KindOfSim.DesignDay
        state.dataWeather.Environment[1].DesignDayNum = 2
        state.dataSize.NumPltSizInput = 1
        state.dataSize.PlantSizData.allocate(state.dataSize.NumPltSizInput)
        state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].SizingFactorOption = NoSizingFactorMode
        state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].DesVolFlowRate = 0.002
        state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].DeltaT = 10
        state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].ConcurrenceOption = DataSizing.SizingConcurrence.Coincident
        state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].NumTimeStepsInAvg = 1
        state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].PlantLoopName = "Test Plant Loop 1"
        state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].LoopType = DataSizing.TypeOfPlantLoop.Heating
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataPlnt.PlantLoop[0].Name = "Test Plant Loop 1"
        state.dataPlnt.PlantLoop[0].MaxVolFlowRateWasAutoSized = True
        state.dataPlnt.PlantLoop[0].MaxVolFlowRate = 0.002
        state.dataPlnt.PlantLoop[0].MaxMassFlowRate = 2.0
        state.dataPlnt.PlantLoop[0].VolumeWasAutoSized = True
        state.dataPlnt.PlantLoop[0].FluidName = "WATER"
        state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[0].LoopSide[LoopSideLocation.Supply].NodeNumIn = 1
        state.dataLoopNodes.Node.allocate(1)
        SetupTimePointers(state, OutputProcessor.TimeStepType.Zone, state.dataGlobal.TimeStepZone) # Set up Time pointer for HB/Zone Simulation
        SetupTimePointers(state, OutputProcessor.TimeStepType.System, state.dataHVACGlobal.TimeStepSys)
        state.dataGlobal.TimeStepsInHour = 4
        state.dataWeather.TimeStepFraction = 1.0 / float(state.dataGlobal.TimeStepsInHour)
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep = Pointer[float](address_of(state.dataGlobal.TimeStepZone))
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0 # init
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep = Pointer[float](address_of(state.dataHVACGlobal.TimeStepSys))
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0

    def TearDown(inout self):
        EnergyPlusFixture.TearDown() # Remember to tear down the base fixture after cleaning up derived fixture!


def WeatherFileDaysTest3(inout self: HVACSizingSimulationManagerTest):
    state.dataWeather.Environment.deallocate()
    state.dataWeather.NumOfEnvrn = 4
    state.dataWeather.Environment.allocate(state.dataWeather.NumOfEnvrn)
    state.dataWeather.Environment[0].KindOfEnvrn = Constant.KindOfSim.DesignDay
    state.dataWeather.Environment[0].DesignDayNum = 1
    state.dataWeather.Environment[1].KindOfEnvrn = Constant.KindOfSim.DesignDay
    state.dataWeather.Environment[1].DesignDayNum = 2
    state.dataWeather.Environment[2].KindOfEnvrn = Constant.KindOfSim.RunPeriodDesign
    state.dataWeather.Environment[2].DesignDayNum = 0
    state.dataWeather.Environment[2].TotalDays = 4
    state.dataWeather.Environment[3].KindOfEnvrn = Constant.KindOfSim.RunPeriodDesign
    state.dataWeather.Environment[3].DesignDayNum = 0
    state.dataWeather.Environment[3].TotalDays = 4
    var testSizeSimManagerObj: HVACSizingSimulationManager
    testSizeSimManagerObj.DetermineSizingAnalysesNeeded(state)
    assert_eq(1, testSizeSimManagerObj.plantCoincAnalyObjs[0].supplySideInletNodeNum)
    testSizeSimManagerObj.SetupSizingAnalyses(state)
    assert_eq(4, state.dataWeather.NumOfEnvrn)
    Weather.AddDesignSetToEnvironmentStruct(state, 1)
    assert_eq(8, state.dataWeather.NumOfEnvrn)
    state.dataGlobal.TimeStepZone = 15.0 / 60.0
    state.dataHVACGlobal.NumOfSysTimeSteps = 3
    state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone / state.dataHVACGlobal.NumOfSysTimeSteps
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    state.dataGlobal.DayOfSim = 1
    state.dataWeather.Envrn = 5
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].DesignDayNum = 1
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
        for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
            for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                state.dataLoopNodes.Node[0].Temp = 10.0
                state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
            testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
        # TimeStep loop
    # ... End hour loop.
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    state.dataGlobal.DayOfSim = 1
    state.dataWeather.Envrn = 6
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].DesignDayNum = 2
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
        for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
            for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                state.dataLoopNodes.Node[0].Temp = 10.0
                state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
            testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
        # TimeStep loop
    # End hour loop.
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeRunPeriodDesign
    state.dataGlobal.DayOfSim = 0
    state.dataWeather.Envrn = 7
    state.dataGlobal.NumOfDayInEnvrn = 4
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    while state.dataGlobal.DayOfSim < state.dataGlobal.NumOfDayInEnvrn:
        state.dataGlobal.DayOfSim += 1
        for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
            for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
                for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                    state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                    state.dataLoopNodes.Node[0].Temp = 10.0
                    state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                    testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
            # TimeStep loop
        # ... End hour loop.
    # day loop
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeRunPeriodDesign
    state.dataGlobal.DayOfSim = 0
    state.dataWeather.Envrn = 8
    state.dataGlobal.NumOfDayInEnvrn = 4
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    while state.dataGlobal.DayOfSim < state.dataGlobal.NumOfDayInEnvrn:
        state.dataGlobal.DayOfSim += 1
        for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
            for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
                for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                    state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                    state.dataLoopNodes.Node[0].Temp = 10.0
                    state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                    testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
            # TimeStep loop
        # ... End hour loop.
    # day loop
    testSizeSimManagerObj.PostProcessLogs()
    assert_almost_equal(2.0, state.dataPlnt.PlantLoop[0].MaxMassFlowRate) # original size
    testSizeSimManagerObj.ProcessCoincidentPlantSizeAdjustments(state, 1)
    assert_almost_equal(2.4, state.dataPlnt.PlantLoop[0].MaxMassFlowRate) # resize check
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[0].subSteps[0].LogDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[0].runningAvgDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[3].subSteps[2].LogDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[3].runningAvgDataValue)
    assert_almost_equal(0.2,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[7].subSteps[0].LogDataValue)
    assert_almost_equal(0.2,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[7].runningAvgDataValue)
    assert_almost_equal(2.4,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[95].subSteps[2].LogDataValue)
    assert_almost_equal(2.4,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[95].runningAvgDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[96].subSteps[0].LogDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[96].runningAvgDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[192].runningAvgDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[576].runningAvgDataValue)

def TopDownTestSysTimestep3(inout self: HVACSizingSimulationManagerTest):
    var testSizeSimManagerObj: HVACSizingSimulationManager
    testSizeSimManagerObj.DetermineSizingAnalysesNeeded(state)
    assert_eq(1, testSizeSimManagerObj.plantCoincAnalyObjs[0].supplySideInletNodeNum)
    testSizeSimManagerObj.SetupSizingAnalyses(state)
    assert_eq(2, state.dataWeather.NumOfEnvrn)
    Weather.AddDesignSetToEnvironmentStruct(state, 1)
    assert_eq(4, state.dataWeather.NumOfEnvrn)
    state.dataGlobal.TimeStepZone = 15.0 / 60.0
    state.dataHVACGlobal.NumOfSysTimeSteps = 3
    state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone / state.dataHVACGlobal.NumOfSysTimeSteps
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    state.dataGlobal.DayOfSim = 1
    state.dataWeather.Envrn = 3
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].DesignDayNum = 1
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
        for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
            for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                state.dataLoopNodes.Node[0].Temp = 10.0
                state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
            testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
        # TimeStep loop
    # ... End hour loop.
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    state.dataGlobal.DayOfSim = 1
    state.dataWeather.Envrn = 4
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].DesignDayNum = 2
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
        for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
            for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                state.dataLoopNodes.Node[0].Temp = 10.0
                state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
            testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
        # TimeStep loop
    # End hour loop.
    testSizeSimManagerObj.PostProcessLogs()
    assert_almost_equal(2.0, state.dataPlnt.PlantLoop[0].MaxMassFlowRate) # original size
    testSizeSimManagerObj.ProcessCoincidentPlantSizeAdjustments(state, 1)
    assert_almost_equal(2.4, state.dataPlnt.PlantLoop[0].MaxMassFlowRate) # resize check
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[0].subSteps[0].LogDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[0].runningAvgDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[3].subSteps[2].LogDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[3].runningAvgDataValue)
    assert_almost_equal(0.2,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[7].subSteps[0].LogDataValue)
    assert_almost_equal(0.2,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[7].runningAvgDataValue)
    assert_almost_equal(2.4,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[95].subSteps[2].LogDataValue)
    assert_almost_equal(2.4,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[95].runningAvgDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[96].subSteps[0].LogDataValue)
    assert_almost_equal(0.1,
                     testSizeSimManagerObj.sizingLogger.logObjs[testSizeSimManagerObj.plantCoincAnalyObjs[0].supplyInletNodeFlow_LogIndex].ztStepObj[96].runningAvgDataValue)

def TopDownTestSysTimestep1(inout self: HVACSizingSimulationManagerTest):
    state.dataSize.GlobalCoolSizingFactor = 1.0
    state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].SizingFactorOption = GlobalCoolingSizingFactorMode
    var testSizeSimManagerObj: HVACSizingSimulationManager
    testSizeSimManagerObj.DetermineSizingAnalysesNeeded(state)
    assert_eq(1, testSizeSimManagerObj.plantCoincAnalyObjs[0].supplySideInletNodeNum)
    testSizeSimManagerObj.SetupSizingAnalyses(state)
    assert_eq(2, state.dataWeather.NumOfEnvrn)
    Weather.AddDesignSetToEnvironmentStruct(state, 1)
    assert_eq(4, state.dataWeather.NumOfEnvrn)
    state.dataGlobal.TimeStepZone = 15.0 / 60.0
    state.dataHVACGlobal.NumOfSysTimeSteps = 1
    state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone / state.dataHVACGlobal.NumOfSysTimeSteps
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    state.dataGlobal.DayOfSim = 1
    state.dataWeather.Envrn = 3
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].DesignDayNum = 1
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
        for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
            for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                state.dataLoopNodes.Node[0].Temp = 10.0
                state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
            testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
        # TimeStep loop
    # ... End hour loop.
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    state.dataGlobal.DayOfSim = 1
    state.dataWeather.Envrn = 4
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].DesignDayNum = 2
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
        for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
            for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                state.dataLoopNodes.Node[0].Temp = 10.0
                state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
            testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
        # TimeStep loop
    # End hour loop.
    testSizeSimManagerObj.PostProcessLogs()
    assert_almost_equal(2.0, state.dataPlnt.PlantLoop[0].MaxMassFlowRate) # original size
    testSizeSimManagerObj.ProcessCoincidentPlantSizeAdjustments(state, 1)
    assert_almost_equal(2.4, state.dataPlnt.PlantLoop[0].MaxMassFlowRate) # resize check

def VarySysTimesteps(inout self: HVACSizingSimulationManagerTest):
    state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].NumTimeStepsInAvg = 2
    state.dataSize.GlobalHeatSizingFactor = 1.0
    state.dataSize.PlantSizData[state.dataSize.NumPltSizInput - 1].SizingFactorOption = GlobalHeatingSizingFactorMode
    var testSizeSimManagerObj: HVACSizingSimulationManager
    testSizeSimManagerObj.DetermineSizingAnalysesNeeded(state)
    assert_eq(1, testSizeSimManagerObj.plantCoincAnalyObjs[0].supplySideInletNodeNum)
    testSizeSimManagerObj.SetupSizingAnalyses(state)
    assert_eq(2, state.dataWeather.NumOfEnvrn)
    Weather.AddDesignSetToEnvironmentStruct(state, 1)
    assert_eq(4, state.dataWeather.NumOfEnvrn)
    state.dataGlobal.TimeStepZone = 15.0 / 60.0
    state.dataHVACGlobal.NumOfSysTimeSteps = 1
    state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone / state.dataHVACGlobal.NumOfSysTimeSteps
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    state.dataGlobal.DayOfSim = 1
    state.dataWeather.Envrn = 3
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].DesignDayNum = 1
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
        for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
            state.dataHVACGlobal.NumOfSysTimeSteps = state.dataGlobal.TimeStep
            state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone / state.dataHVACGlobal.NumOfSysTimeSteps
            state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
            for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                state.dataLoopNodes.Node[0].Temp = 10.0
                state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
            testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
        # TimeStep loop
    # ... End hour loop.
    state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    state.dataGlobal.DayOfSim = 1
    state.dataWeather.Envrn = 4
    state.dataWeather.Environment[state.dataWeather.Envrn - 1].DesignDayNum = 2
    testSizeSimManagerObj.sizingLogger.SetupSizingLogsNewEnvironment(state)
    for state.dataGlobal.HourOfDay in range(1, 25): # Begin hour loop ...
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute = 0.0
        state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute = 0.0
        for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
            state.dataHVACGlobal.NumOfSysTimeSteps = state.dataGlobal.TimeStep
            state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone / state.dataHVACGlobal.NumOfSysTimeSteps
            state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
            for SysTimestepLoop in range(1, state.dataHVACGlobal.NumOfSysTimeSteps + 1):
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].CurMinute += (
                    state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.System)].TimeStep[]) * 60.0
                state.dataLoopNodes.Node[0].MassFlowRate = state.dataGlobal.HourOfDay * 0.1
                state.dataLoopNodes.Node[0].Temp = 10.0
                state.dataPlnt.PlantLoop[0].HeatingDemand = state.dataGlobal.HourOfDay * 10.0
                testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesSystemStep(state)
            state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].CurMinute += (
                state.dataOutputProcessor.TimeValue[int(OutputProcessor.TimeStepType.Zone)].TimeStep[]) * 60.0
            testSizeSimManagerObj.sizingLogger.UpdateSizingLogValuesZoneStep(state)
        # TimeStep loop
    # End hour loop.
    testSizeSimManagerObj.PostProcessLogs()
    assert_almost_equal(2.0, state.dataPlnt.PlantLoop[0].MaxMassFlowRate) # original size
    testSizeSimManagerObj.ProcessCoincidentPlantSizeAdjustments(state, 1)
    assert_almost_equal(2.4, state.dataPlnt.PlantLoop[0].MaxMassFlowRate) # resize check
    testSizeSimManagerObj.ProcessCoincidentPlantSizeAdjustments(state, 1)
    testSizeSimManagerObj.sizingLogger.IncrementSizingPeriodSet()