from .Data.BaseData import *
from  import *
from .Data.EnergyPlusData import *
from DataHVACGlobals import *
from DataSizing import *
from General import *
from OutputProcessor import *
from OutputReportPredefined import *
from .Plant.DataPlant import *
from UtilityRoutines import *
from WeatherManager import *
from memory import memset_zero
from math import round, abs, max
from utils import String

@value
struct SystemTimestepObject:
    var CurMinuteStart: Float64 = 0.0
    var CurMinuteEnd: Float64 = 0.0
    var TimeStepDuration: Float64 = 0.0
    var LogDataValue: Float64 = 0.0
    var stStepsIntoZoneStep: Int = 0

@value
struct ZoneTimestepObject:
    var kindOfSim: Constant.KindOfSim = Constant.KindOfSim.Invalid
    var envrnNum: Int = 0
    var dayOfSim: Int = 0
    var hourOfDay: Int = 0
    var ztStepsIntoPeriod: Int = 0
    var stepStartMinute: Float64 = 0.0
    var stepEndMinute: Float64 = 0.0
    var timeStepDuration: Float64 = 0.0
    var logDataValue: Float64 = 0.0
    var runningAvgDataValue: Float64 = 0.0
    var hasSystemSubSteps: Bool = False
    var numSubSteps: Int = 0
    var subSteps: List[SystemTimestepObject] = List[SystemTimestepObject]()

    def __init__(inout self):
        self.kindOfSim = Constant.KindOfSim.Invalid
        self.envrnNum = 0
        self.dayOfSim = 0
        self.hourOfDay = 0
        self.ztStepsIntoPeriod = 0
        self.stepStartMinute = 0.0
        self.stepEndMinute = 0.0
        self.timeStepDuration = 0.0

    def __init__(inout self, kindSim: Constant.KindOfSim, environmentNum: Int, daySim: Int, hourDay: Int, timeStep: Int, timeStepDurat: Float64, numOfTimeStepsPerHour: Int):
        self.kindOfSim = kindSim
        self.envrnNum = environmentNum
        self.dayOfSim = daySim
        self.hourOfDay = hourDay
        self.timeStepDuration = timeStepDurat
        let minutesPerHour: Float64 = 60.0
        let hoursPerDay: Int = 24
        self.stepEndMinute = timeStepDuration * minutesPerHour + (Float64(timeStep) - 1.0) * timeStepDuration * minutesPerHour
        self.stepStartMinute = self.stepEndMinute - timeStepDuration * minutesPerHour
        if self.stepStartMinute < 0.0:
            self.stepStartMinute = 0.0
            self.stepEndMinute = timeStepDuration * minutesPerHour
        self.ztStepsIntoPeriod = ((daySim - 1) * (hoursPerDay * numOfTimeStepsPerHour)) + ((hourDay - 1) * numOfTimeStepsPerHour) + round((self.stepStartMinute / minutesPerHour) / timeStepDuration)
        if self.ztStepsIntoPeriod < 0:
            self.ztStepsIntoPeriod = 0
        self.hasSystemSubSteps = True
        self.numSubSteps = 1
        self.subSteps = List[SystemTimestepObject](capacity=self.numSubSteps)
        for _ in range(self.numSubSteps):
            self.subSteps.append(SystemTimestepObject())

struct SizingLog:
    var NumOfEnvironmentsInLogSet: Int
    var NumOfDesignDaysInLogSet: Int
    var NumberOfSizingPeriodsInLogSet: Int
    var ztStepCountByEnvrnMap: Map[Int, Int]
    var envrnStartZtStepIndexMap: Map[Int, Int]
    var newEnvrnToSeedEnvrnMap: Map[Int, Int]
    var NumOfStepsInLogSet: Int
    var timeStepsInAverage: Int
    var p_rVariable: Float64
    var ztStepObj: List[ZoneTimestepObject]

    def __init__(inout self, rVariable: Float64):
        self.p_rVariable = rVariable
        self.NumOfEnvironmentsInLogSet = 0
        self.NumOfDesignDaysInLogSet = 0
        self.NumberOfSizingPeriodsInLogSet = 0
        self.NumOfStepsInLogSet = 0
        self.timeStepsInAverage = 0

    def GetZtStepIndex(inout self, tmpztStepStamp: ZoneTimestepObject) -> Int:
        var vecIndex: Int
        if tmpztStepStamp.ztStepsIntoPeriod > 0:
            vecIndex = self.envrnStartZtStepIndexMap[self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]] + tmpztStepStamp.ztStepsIntoPeriod
        else:
            vecIndex = self.envrnStartZtStepIndexMap[self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]]
        if vecIndex < self.envrnStartZtStepIndexMap[self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]]:
            vecIndex = self.envrnStartZtStepIndexMap[self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]]
        if vecIndex > (self.envrnStartZtStepIndexMap[self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]] + self.ztStepCountByEnvrnMap[self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]]):
            vecIndex = self.envrnStartZtStepIndexMap[self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]] + self.ztStepCountByEnvrnMap[self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]]
        return vecIndex

    def FillZoneStep(inout self, tmpztStepStamp: ZoneTimestepObject):
        let index = self.GetZtStepIndex(tmpztStepStamp)
        self.ztStepObj[index].kindOfSim = tmpztStepStamp.kindOfSim
        self.ztStepObj[index].envrnNum = tmpztStepStamp.envrnNum
        self.ztStepObj[index].dayOfSim = tmpztStepStamp.dayOfSim
        self.ztStepObj[index].hourOfDay = tmpztStepStamp.hourOfDay
        self.ztStepObj[index].ztStepsIntoPeriod = tmpztStepStamp.ztStepsIntoPeriod
        self.ztStepObj[index].stepStartMinute = tmpztStepStamp.stepStartMinute
        self.ztStepObj[index].stepEndMinute = tmpztStepStamp.stepEndMinute
        self.ztStepObj[index].timeStepDuration = tmpztStepStamp.timeStepDuration
        self.ztStepObj[index].logDataValue = self.p_rVariable

    def GetSysStepZtStepIndex(inout self, tmpztStepStamp: ZoneTimestepObject) -> Int:
        var znStepIndex = self.GetZtStepIndex(tmpztStepStamp)
        if znStepIndex >= self.NumOfStepsInLogSet:
            znStepIndex = self.NumOfStepsInLogSet - 1
        if znStepIndex < 0:
            znStepIndex = 0
        return znStepIndex

    def FillSysStep(inout self, tmpztStepStamp: ZoneTimestepObject, tmpSysStepStamp: SystemTimestepObject):
        var newNumSubSteps: Int
        let MinutesPerHour: Float64 = 60.0
        let ztIndex = self.GetSysStepZtStepIndex(tmpztStepStamp)
        if self.ztStepObj[ztIndex].hasSystemSubSteps:
            let oldNumSubSteps = self.ztStepObj[ztIndex].numSubSteps
            newNumSubSteps = round(tmpztStepStamp.timeStepDuration / tmpSysStepStamp.TimeStepDuration)
            if newNumSubSteps != oldNumSubSteps:
                self.ztStepObj[ztIndex].subSteps = List[SystemTimestepObject](capacity=newNumSubSteps)
                for _ in range(newNumSubSteps):
                    self.ztStepObj[ztIndex].subSteps.append(SystemTimestepObject())
                self.ztStepObj[ztIndex].numSubSteps = newNumSubSteps
        else:
            newNumSubSteps = round(tmpztStepStamp.timeStepDuration / tmpSysStepStamp.TimeStepDuration)
            self.ztStepObj[ztIndex].subSteps = List[SystemTimestepObject](capacity=newNumSubSteps)
            for _ in range(newNumSubSteps):
                self.ztStepObj[ztIndex].subSteps.append(SystemTimestepObject())
            self.ztStepObj[ztIndex].numSubSteps = newNumSubSteps
            self.ztStepObj[ztIndex].hasSystemSubSteps = True
        let ZoneStepStartMinutes = tmpztStepStamp.stepStartMinute
        var tmpSysStepStampMut = tmpSysStepStamp
        tmpSysStepStampMut.stStepsIntoZoneStep = round((((tmpSysStepStamp.CurMinuteStart - ZoneStepStartMinutes) / MinutesPerHour) / tmpSysStepStamp.TimeStepDuration))
        if (tmpSysStepStampMut.stStepsIntoZoneStep >= 0) and (tmpSysStepStampMut.stStepsIntoZoneStep < self.ztStepObj[ztIndex].numSubSteps):
            self.ztStepObj[ztIndex].subSteps[tmpSysStepStampMut.stStepsIntoZoneStep] = tmpSysStepStampMut
            self.ztStepObj[ztIndex].subSteps[tmpSysStepStampMut.stStepsIntoZoneStep].LogDataValue = self.p_rVariable
        else:
            self.ztStepObj[ztIndex].subSteps[0] = tmpSysStepStampMut
            self.ztStepObj[ztIndex].subSteps[0].LogDataValue = self.p_rVariable

    def AverageSysTimeSteps(inout self):
        var RunningSum: Float64
        for zt in self.ztStepObj:
            if zt.numSubSteps > 0:
                RunningSum = 0.0
                for SysT in zt.subSteps:
                    RunningSum += SysT.LogDataValue
                zt.logDataValue = RunningSum / Float64(zt.numSubSteps)

    def ProcessRunningAverage(inout self):
        var RunningSum: Float64 = 0.0
        let divisor = Float64(self.timeStepsInAverage)
        let end = self.ztStepCountByEnvrnMap.end()
        var itr = self.ztStepCountByEnvrnMap.begin()
        while itr != end:
            for i in range(itr[].second):
                if self.timeStepsInAverage > 0:
                    RunningSum = 0.0
                    for j in range(self.timeStepsInAverage):
                        if (i - j) < 0:
                            RunningSum += self.ztStepObj[self.envrnStartZtStepIndexMap[itr[].first]].logDataValue
                        else:
                            RunningSum += self.ztStepObj[((i - j) + self.envrnStartZtStepIndexMap[itr[].first])].logDataValue
                    self.ztStepObj[(i + self.envrnStartZtStepIndexMap[itr[].first])].runningAvgDataValue = RunningSum / divisor
            itr = itr.next()

    def GetLogVariableDataMax(inout self, state: EnergyPlusData) -> ZoneTimestepObject:
        var tmpztStepStamp = ZoneTimestepObject()
        var MaxVal: Float64 = 0.0
        if len(self.ztStepObj) > 0:
            tmpztStepStamp = self.ztStepObj[0]
        for zt in self.ztStepObj:
            if zt.envrnNum > 0 and zt.kindOfSim != Constant.KindOfSim.Invalid and zt.runningAvgDataValue > MaxVal:
                MaxVal = zt.runningAvgDataValue
                tmpztStepStamp = zt
            elif zt.envrnNum == 0 and zt.kindOfSim == Constant.KindOfSim.Invalid:
                ShowWarningMessage(state, "GetLogVariableDataMax: null timestamp in log")
        return tmpztStepStamp

    def GetLogVariableDataAtTimestamp(inout self, tmpztStepStamp: ZoneTimestepObject) -> Float64:
        let index = self.GetZtStepIndex(tmpztStepStamp)
        return self.ztStepObj[index].runningAvgDataValue

    def ReInitLogForIteration(inout self):
        let tmpNullztStepObj = ZoneTimestepObject()
        for i in range(len(self.ztStepObj)):
            self.ztStepObj[i] = tmpNullztStepObj

    def SetupNewEnvironment(inout self, seedEnvrnNum: Int, newEnvrnNum: Int):
        self.newEnvrnToSeedEnvrnMap[newEnvrnNum] = seedEnvrnNum

struct SizingLoggerFramework:
    var logObjs: List[SizingLog]
    var NumOfLogs: Int

    def __init__(inout self):
        self.NumOfLogs = 0

    def SetupVariableSizingLog(inout self, state: EnergyPlusData, rVariable: Float64, stepsInAverage: Int) -> Int:
        let HoursPerDay: Int = 24
        var tmpLog = SizingLog(rVariable)
        tmpLog.NumOfEnvironmentsInLogSet = 0
        tmpLog.NumOfDesignDaysInLogSet = 0
        tmpLog.NumberOfSizingPeriodsInLogSet = 0
        for i in range(1, state.dataWeather.NumOfEnvrn + 1):
            if state.dataWeather.Environment(i).KindOfEnvrn == Constant.KindOfSim.DesignDay:
                tmpLog.NumOfEnvironmentsInLogSet += 1
                tmpLog.NumOfDesignDaysInLogSet += 1
            if state.dataWeather.Environment(i).KindOfEnvrn == Constant.KindOfSim.RunPeriodDesign:
                tmpLog.NumOfEnvironmentsInLogSet += 1
                tmpLog.NumberOfSizingPeriodsInLogSet += 1
        for i in range(1, state.dataWeather.NumOfEnvrn + 1):
            if state.dataWeather.Environment(i).KindOfEnvrn == Constant.KindOfSim.DesignDay:
                tmpLog.ztStepCountByEnvrnMap[i] = HoursPerDay * state.dataGlobal.TimeStepsInHour
            if state.dataWeather.Environment(i).KindOfEnvrn == Constant.KindOfSim.RunPeriodDesign:
                tmpLog.ztStepCountByEnvrnMap[i] = HoursPerDay * state.dataGlobal.TimeStepsInHour * state.dataWeather.Environment(i).TotalDays
        var stepSum: Int = 0
        let end = tmpLog.ztStepCountByEnvrnMap.end()
        var itr = tmpLog.ztStepCountByEnvrnMap.begin()
        while itr != end:
            tmpLog.envrnStartZtStepIndexMap[itr[].first] = stepSum
            stepSum += itr[].second
            itr = itr.next()
        tmpLog.timeStepsInAverage = stepsInAverage
        let VectorLength = stepSum
        tmpLog.NumOfStepsInLogSet = VectorLength
        tmpLog.ztStepObj = List[ZoneTimestepObject](capacity=VectorLength)
        for _ in range(VectorLength):
            tmpLog.ztStepObj.append(ZoneTimestepObject())
        self.logObjs.append(tmpLog)
        self.NumOfLogs += 1
        return self.NumOfLogs - 1

    def SetupSizingLogsNewEnvironment(inout self, state: EnergyPlusData):
        for l in self.logObjs:
            l.SetupNewEnvironment(state.dataWeather.Environment(state.dataWeather.Envrn).SeedEnvrnNum, state.dataWeather.Envrn)

    def PrepareZoneTimestepStamp(inout self, state: EnergyPlusData) -> ZoneTimestepObject:
        var locDayOfSim: Int
        if state.dataGlobal.WarmupFlag:
            locDayOfSim = 1
        else:
            locDayOfSim = state.dataGlobal.DayOfSim
        let tmpztStepStamp = ZoneTimestepObject(
            state.dataGlobal.KindOfSim,
            state.dataWeather.Envrn,
            locDayOfSim,
            state.dataGlobal.HourOfDay,
            state.dataGlobal.TimeStep,
            state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.Zone)].TimeStep[],
            state.dataGlobal.TimeStepsInHour)
        return tmpztStepStamp

    def UpdateSizingLogValuesZoneStep(inout self, state: EnergyPlusData):
        let tmpztStepStamp = self.PrepareZoneTimestepStamp(state)
        for l in self.logObjs:
            l.FillZoneStep(tmpztStepStamp)

    def UpdateSizingLogValuesSystemStep(inout self, state: EnergyPlusData):
        let MinutesPerHour: Float64 = 60.0
        let tmpztStepStamp = self.PrepareZoneTimestepStamp(state)
        var tmpSysStepStamp = SystemTimestepObject()
        tmpSysStepStamp.CurMinuteEnd = state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].CurMinute
        if tmpSysStepStamp.CurMinuteEnd == 0.0:
            tmpSysStepStamp.CurMinuteEnd = MinutesPerHour
        tmpSysStepStamp.CurMinuteStart = tmpSysStepStamp.CurMinuteEnd - (state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].TimeStep[]) * MinutesPerHour
        tmpSysStepStamp.TimeStepDuration = state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].TimeStep[]
        for l in self.logObjs:
            l.FillSysStep(tmpztStepStamp, tmpSysStepStamp)

    def IncrementSizingPeriodSet(inout self):
        for l in self.logObjs:
            l.ReInitLogForIteration()

struct PlantCoinicidentAnalysis:
    var plantLoopIndex: Int = 0
    var supplySideInletNodeNum: Int = 0
    var plantSizingIndex: Int = 0
    var numTimeStepsInAvg: Int = 0
    var newFoundMassFlowRateTimeStamp: ZoneTimestepObject
    var peakMdotCoincidentReturnTemp: Float64
    var peakMdotCoincidentDemand: Float64
    var anotherIterationDesired: Bool = False
    var supplyInletNodeFlow_LogIndex: Int
    var supplyInletNodeTemp_LogIndex: Int
    var loopDemand_LogIndex: Int
    var peakDemandAndFlowMismatch: Bool
    var NewFoundMaxDemandTimeStamp: ZoneTimestepObject
    var peakDemandReturnTemp: Float64
    var peakDemandMassFlow: Float64
    var name: String
    var newAdjustedMassFlowRate: Float64 = 0.0
    var newFoundMassFlowRate: Float64 = 0.0
    var significantNormalizedChange: Float64 = 0.005
    var densityForSizing: Float64 = 0.0
    var specificHeatForSizing: Float64 = 0.0
    var previousVolDesignFlowRate: Float64 = 0.0
    var newVolDesignFlowRate: Float64 = 0.0

    def __init__(inout self, loopName: String, loopIndex: Int, nodeNum: Int, density: Float64, cp: Float64, numStepsInAvg: Int, sizingIndex: Int):
        self.name = loopName
        self.plantLoopIndex = loopIndex
        self.supplySideInletNodeNum = nodeNum
        self.densityForSizing = density
        self.specificHeatForSizing = cp
        self.numTimeStepsInAvg = numStepsInAvg
        self.plantSizingIndex = sizingIndex

    def CheckTimeStampForNull(inout self, testStamp: ZoneTimestepObject) -> Bool:
        var isNull: Bool = True
        if testStamp.envrnNum != 0:
            isNull = False
        if testStamp.kindOfSim != Constant.KindOfSim.Invalid:
            isNull = False
        return isNull

    def ResolveDesignFlowRate(inout self, state: EnergyPlusData, HVACSizingIterCount: Int):
        var setNewSizes: Bool
        var sizingFac: Float64
        var normalizedChange: Float64
        var newFoundVolFlowRate: Float64
        var peakLoadCalculatedMassFlow: Float64
        var chIteration: String
        var chSetSizes: String
        var chDemandTrapUsed: String
        var changedByDemand: Bool = False
        var nullStampProblem: Bool
        if self.CheckTimeStampForNull(self.newFoundMassFlowRateTimeStamp) and self.CheckTimeStampForNull(self.NewFoundMaxDemandTimeStamp):
            nullStampProblem = True
        else:
            nullStampProblem = False
        self.previousVolDesignFlowRate = state.dataSize.PlantSizData(self.plantSizingIndex).DesVolFlowRate
        if (not self.CheckTimeStampForNull(self.newFoundMassFlowRateTimeStamp)) and (self.newFoundMassFlowRateTimeStamp.runningAvgDataValue > 0.0):
            self.newFoundMassFlowRate = self.newFoundMassFlowRateTimeStamp.runningAvgDataValue
        else:
            self.newFoundMassFlowRate = 0.0
        if ((not self.CheckTimeStampForNull(self.NewFoundMaxDemandTimeStamp)) and (self.NewFoundMaxDemandTimeStamp.runningAvgDataValue > 0.0)) and ((self.specificHeatForSizing * state.dataSize.PlantSizData(self.plantSizingIndex).DeltaT) > 0.0):
            peakLoadCalculatedMassFlow = self.NewFoundMaxDemandTimeStamp.runningAvgDataValue / (self.specificHeatForSizing * state.dataSize.PlantSizData(self.plantSizingIndex).DeltaT)
        else:
            peakLoadCalculatedMassFlow = 0.0
        if peakLoadCalculatedMassFlow > self.newFoundMassFlowRate:
            changedByDemand = True
        else:
            changedByDemand = False
        self.newFoundMassFlowRate = max(self.newFoundMassFlowRate, peakLoadCalculatedMassFlow)
        newFoundVolFlowRate = self.newFoundMassFlowRate / self.densityForSizing
        sizingFac = 1.0
        if state.dataSize.PlantSizData(self.plantSizingIndex).SizingFactorOption == DataSizing.NoSizingFactorMode:
            sizingFac = 1.0
        elif state.dataSize.PlantSizData(self.plantSizingIndex).SizingFactorOption == DataSizing.GlobalHeatingSizingFactorMode:
            sizingFac = state.dataSize.GlobalHeatSizingFactor
        elif state.dataSize.PlantSizData(self.plantSizingIndex).SizingFactorOption == DataSizing.GlobalCoolingSizingFactorMode:
            sizingFac = state.dataSize.GlobalCoolSizingFactor
        elif state.dataSize.PlantSizData(self.plantSizingIndex).SizingFactorOption == DataSizing.LoopComponentSizingFactorMode:
            sizingFac = state.dataPlnt.PlantLoop(self.plantLoopIndex).LoopSide(LoopSideLocation.Supply).Branch(1).PumpSizFac
        self.newAdjustedMassFlowRate = self.newFoundMassFlowRate * sizingFac
        self.newVolDesignFlowRate = self.newAdjustedMassFlowRate / self.densityForSizing
        setNewSizes = False
        normalizedChange = 0.0
        if self.newVolDesignFlowRate > HVAC.SmallWaterVolFlow and not nullStampProblem:
            normalizedChange = abs((self.newVolDesignFlowRate - self.previousVolDesignFlowRate) / self.previousVolDesignFlowRate)
            if normalizedChange > self.significantNormalizedChange:
                self.anotherIterationDesired = True
                setNewSizes = True
            else:
                self.anotherIterationDesired = False
        if setNewSizes:
            state.dataSize.PlantSizData(self.plantSizingIndex).DesVolFlowRate = self.newVolDesignFlowRate
            if state.dataPlnt.PlantLoop(self.plantLoopIndex).MaxVolFlowRateWasAutoSized:
                state.dataPlnt.PlantLoop(self.plantLoopIndex).MaxVolFlowRate = self.newVolDesignFlowRate
                state.dataPlnt.PlantLoop(self.plantLoopIndex).MaxMassFlowRate = self.newAdjustedMassFlowRate
            if state.dataPlnt.PlantLoop(self.plantLoopIndex).VolumeWasAutoSized:
                state.dataPlnt.PlantLoop(self.plantLoopIndex).Volume = state.dataPlnt.PlantLoop(self.plantLoopIndex).MaxVolFlowRate * state.dataPlnt.PlantLoop(self.plantLoopIndex).CirculationTime * 60.0
                state.dataPlnt.PlantLoop(self.plantLoopIndex).Mass = state.dataPlnt.PlantLoop(self.plantLoopIndex).Volume * self.densityForSizing
        if not state.dataGlobal.sizingAnalysisEioHeaderDoneOnce:
            print(state.files.eio, "! <Plant Coincident Sizing Algorithm>,Plant Loop Name,Sizing Pass {#},Measured Mass Flow{kg/s},Measured Demand {W},Demand Calculated Mass Flow{kg/s},Sizes Changed {Yes/No},Previous Volume Flow Rate {m3/s},New Volume Flow Rate {m3/s},Demand Check Applied {Yes/No},Sizing Factor {},Normalized Change {},Specific Heat{J/kg-K},Density {kg/m3}\n")
            state.dataGlobal.sizingAnalysisEioHeaderDoneOnce = True
        chIteration = String(HVACSizingIterCount)
        if setNewSizes:
            chSetSizes = "Yes"
        else:
            chSetSizes = "No"
        if changedByDemand:
            chDemandTrapUsed = "Yes"
        else:
            chDemandTrapUsed = "No"
        print(state.files.eio, "Plant Coincident Sizing Algorithm,{},{},{:.7R},{:.2R},{:.7R},{},{:.6R},{:.6R},{},{:.4R},{:.6R},{:.4R},{:.4R}\n",
              self.name, chIteration, self.newFoundMassFlowRateTimeStamp.runningAvgDataValue,
              self.NewFoundMaxDemandTimeStamp.runningAvgDataValue, peakLoadCalculatedMassFlow,
              chSetSizes, self.previousVolDesignFlowRate, self.newVolDesignFlowRate,
              chDemandTrapUsed, sizingFac, normalizedChange, self.specificHeatForSizing, self.densityForSizing)
        PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizPrevVdot,
                         state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                         self.previousVolDesignFlowRate, 6)
        PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizMeasVdot,
                         state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                         newFoundVolFlowRate, 6)
        PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizCalcVdot,
                         state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                         self.newVolDesignFlowRate, 6)
        if setNewSizes:
            PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizCoincYesNo,
                             state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                             "Yes")
        else:
            PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizCoincYesNo,
                             state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                             "No")
        if not nullStampProblem:
            if (not changedByDemand) and (not self.CheckTimeStampForNull(self.newFoundMassFlowRateTimeStamp)):
                if self.newFoundMassFlowRateTimeStamp.envrnNum > 0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizDesDay,
                                     state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                                     state.dataWeather.Environment(self.newFoundMassFlowRateTimeStamp.envrnNum).Title)
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizPkTimeDayOfSim,
                                 state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                                 self.newFoundMassFlowRateTimeStamp.dayOfSim)
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizPkTimeHour,
                                 state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                                 self.newFoundMassFlowRateTimeStamp.hourOfDay - 1)
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizPkTimeMin,
                                 state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                                 self.newFoundMassFlowRateTimeStamp.stepStartMinute, 0)
            elif changedByDemand and (not self.CheckTimeStampForNull(self.NewFoundMaxDemandTimeStamp)):
                if self.NewFoundMaxDemandTimeStamp.envrnNum > 0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizDesDay,
                                     state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                                     state.dataWeather.Environment(self.NewFoundMaxDemandTimeStamp.envrnNum).Title)
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizPkTimeDayOfSim,
                                 state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                                 self.NewFoundMaxDemandTimeStamp.dayOfSim)
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizPkTimeHour,
                                 state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                                 self.NewFoundMaxDemandTimeStamp.hourOfDay - 1)
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSizPkTimeMin,
                                 state.dataPlnt.PlantLoop(self.plantLoopIndex).Name + " Sizing Pass " + chIteration,
                                 self.NewFoundMaxDemandTimeStamp.stepStartMinute, 0)