from math import abs
from collections import Dict, List
from enum import Enum

# EXTERNAL DEPS (to wire in glue):
# - Constant.KindOfSim: enum from EnergyPlus/Data/BaseData.hh
# - EnergyPlusData: struct from EnergyPlus/EnergyPlus.hh
#   Required attributes: dataWeather, dataGlobal, dataSize, dataPlnt, dataOutputProcessor, files
# - OutputProcessor.TimeStepType: enum indices [0]=Zone, [1]=System
# - DataSizing sizing factor modes: constants 0=NoSizingFactorMode, 1=GlobalHeatingSizingFactorMode, 2=GlobalCoolingSizingFactorMode, 3=LoopComponentSizingFactorMode
# - LoopSideLocation.Supply: constant [0]
# - HVAC.SmallWaterVolFlow: float constant
# - UtilityRoutines.ShowWarningMessage: function
# - OutputReportPredefined.PreDefTableEntry: function
# - print, fmt.to_string: output functions


@always_inline
fn _c_round(x: Float64) -> Int64:
    """C++ round() behavior: round half away from zero."""
    if x >= 0:
        return int(x + 0.5)
    else:
        return int(x - 0.5)


@value
struct KindOfSim:
    var value: Int32

    alias Invalid = KindOfSim(0)
    alias DesignDay = KindOfSim(1)
    alias RunPeriodDesign = KindOfSim(2)


@value
struct SystemTimestepObject:
    var CurMinuteStart: Float64
    var CurMinuteEnd: Float64
    var TimeStepDuration: Float64
    var LogDataValue: Float64
    var stStepsIntoZoneStep: Int32

    fn __init__() -> Self:
        return SystemTimestepObject(
            CurMinuteStart=0.0,
            CurMinuteEnd=0.0,
            TimeStepDuration=0.0,
            LogDataValue=0.0,
            stStepsIntoZoneStep=0,
        )

    fn __init__(
        CurMinuteStart: Float64 = 0.0,
        CurMinuteEnd: Float64 = 0.0,
        TimeStepDuration: Float64 = 0.0,
        LogDataValue: Float64 = 0.0,
        stStepsIntoZoneStep: Int32 = 0,
    ) -> Self:
        return SystemTimestepObject(
            CurMinuteStart=CurMinuteStart,
            CurMinuteEnd=CurMinuteEnd,
            TimeStepDuration=TimeStepDuration,
            LogDataValue=LogDataValue,
            stStepsIntoZoneStep=stStepsIntoZoneStep,
        )


struct ZoneTimestepObject:
    var kindOfSim: KindOfSim
    var envrnNum: Int32
    var dayOfSim: Int32
    var hourOfDay: Int32
    var ztStepsIntoPeriod: Int32
    var stepStartMinute: Float64
    var stepEndMinute: Float64
    var timeStepDuration: Float64
    var logDataValue: Float64
    var runningAvgDataValue: Float64
    var hasSystemSubSteps: Bool
    var numSubSteps: Int32
    var subSteps: List[SystemTimestepObject]

    fn __init__() -> Self:
        return ZoneTimestepObject(
            kindOfSim=KindOfSim.Invalid,
            envrnNum=0,
            dayOfSim=0,
            hourOfDay=0,
            ztStepsIntoPeriod=0,
            stepStartMinute=0.0,
            stepEndMinute=0.0,
            timeStepDuration=0.0,
            logDataValue=0.0,
            runningAvgDataValue=0.0,
            hasSystemSubSteps=False,
            numSubSteps=0,
            subSteps=List[SystemTimestepObject](),
        )

    fn __init__(
        kindSim: KindOfSim,
        environmentNum: Int32,
        daySim: Int32,
        hourDay: Int32,
        timeStep: Int32,
        timeStepDurat: Float64,
        numOfTimeStepsPerHour: Int32,
    ) -> Self:
        var minutesPerHour: Float64 = 60.0
        var hoursPerDay: Int32 = 24

        var stepEndMinute = (
            timeStepDurat * minutesPerHour
            + (timeStep - 1) * timeStepDurat * minutesPerHour
        )
        var stepStartMinute = stepEndMinute - timeStepDurat * minutesPerHour

        if stepStartMinute < 0.0:
            stepStartMinute = 0.0
            stepEndMinute = timeStepDurat * minutesPerHour

        var ztStepsIntoPeriod = (
            (daySim - 1) * (hoursPerDay * numOfTimeStepsPerHour)
            + (hourDay - 1) * numOfTimeStepsPerHour
            + _c_round(
                (stepStartMinute / minutesPerHour) / timeStepDurat
            )
        )

        if ztStepsIntoPeriod < 0:
            ztStepsIntoPeriod = 0

        var subSteps = List[SystemTimestepObject]()
        subSteps.append(SystemTimestepObject())

        return ZoneTimestepObject(
            kindOfSim=kindSim,
            envrnNum=environmentNum,
            dayOfSim=daySim,
            hourOfDay=hourDay,
            ztStepsIntoPeriod=ztStepsIntoPeriod,
            stepStartMinute=stepStartMinute,
            stepEndMinute=stepEndMinute,
            timeStepDuration=timeStepDurat,
            logDataValue=0.0,
            runningAvgDataValue=0.0,
            hasSystemSubSteps=True,
            numSubSteps=1,
            subSteps=subSteps,
        )


struct SizingLog:
    var p_rVariable: Float64
    var NumOfEnvironmentsInLogSet: Int32
    var NumOfDesignDaysInLogSet: Int32
    var NumberOfSizingPeriodsInLogSet: Int32
    var ztStepCountByEnvrnMap: Dict[Int32, Int32]
    var envrnStartZtStepIndexMap: Dict[Int32, Int32]
    var newEnvrnToSeedEnvrnMap: Dict[Int32, Int32]
    var NumOfStepsInLogSet: Int32
    var timeStepsInAverage: Int32
    var ztStepObj: List[ZoneTimestepObject]

    fn __init__(rVariable: Float64) -> Self:
        return SizingLog(
            p_rVariable=rVariable,
            NumOfEnvironmentsInLogSet=0,
            NumOfDesignDaysInLogSet=0,
            NumberOfSizingPeriodsInLogSet=0,
            ztStepCountByEnvrnMap=Dict[Int32, Int32](),
            envrnStartZtStepIndexMap=Dict[Int32, Int32](),
            newEnvrnToSeedEnvrnMap=Dict[Int32, Int32](),
            NumOfStepsInLogSet=0,
            timeStepsInAverage=0,
            ztStepObj=List[ZoneTimestepObject](),
        )

    fn GetZtStepIndex(mut self, tmpztStepStamp: ZoneTimestepObject) -> Int32:
        var vecIndex: Int32

        if tmpztStepStamp.ztStepsIntoPeriod > 0:
            vecIndex = (
                self.envrnStartZtStepIndexMap[
                    self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]
                ]
                + tmpztStepStamp.ztStepsIntoPeriod
            )
        else:
            vecIndex = self.envrnStartZtStepIndexMap[
                self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]
            ]

        if vecIndex < self.envrnStartZtStepIndexMap[
            self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]
        ]:
            vecIndex = self.envrnStartZtStepIndexMap[
                self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]
            ]
        if vecIndex > (
            self.envrnStartZtStepIndexMap[
                self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]
            ]
            + self.ztStepCountByEnvrnMap[
                self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]
            ]
        ):
            vecIndex = (
                self.envrnStartZtStepIndexMap[
                    self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]
                ]
                + self.ztStepCountByEnvrnMap[
                    self.newEnvrnToSeedEnvrnMap[tmpztStepStamp.envrnNum]
                ]
            )
        return vecIndex

    fn FillZoneStep(mut self, tmpztStepStamp: ZoneTimestepObject) -> None:
        var index = self.GetZtStepIndex(tmpztStepStamp)

        self.ztStepObj[index].kindOfSim = tmpztStepStamp.kindOfSim
        self.ztStepObj[index].envrnNum = tmpztStepStamp.envrnNum
        self.ztStepObj[index].dayOfSim = tmpztStepStamp.dayOfSim
        self.ztStepObj[index].hourOfDay = tmpztStepStamp.hourOfDay
        self.ztStepObj[index].ztStepsIntoPeriod = tmpztStepStamp.ztStepsIntoPeriod
        self.ztStepObj[index].stepStartMinute = tmpztStepStamp.stepStartMinute
        self.ztStepObj[index].stepEndMinute = tmpztStepStamp.stepEndMinute
        self.ztStepObj[index].timeStepDuration = tmpztStepStamp.timeStepDuration

        self.ztStepObj[index].logDataValue = self.p_rVariable

    fn GetSysStepZtStepIndex(
        mut self, tmpztStepStamp: ZoneTimestepObject
    ) -> Int32:
        var znStepIndex = self.GetZtStepIndex(tmpztStepStamp)

        if znStepIndex >= self.NumOfStepsInLogSet:
            znStepIndex = self.NumOfStepsInLogSet - 1
        if znStepIndex < 0:
            znStepIndex = 0

        return znStepIndex

    fn FillSysStep(
        mut self,
        tmpztStepStamp: ZoneTimestepObject,
        tmpSysStepStamp: SystemTimestepObject,
    ) -> None:
        var MinutesPerHour: Float64 = 60.0

        var ztIndex = self.GetSysStepZtStepIndex(tmpztStepStamp)

        if self.ztStepObj[ztIndex].hasSystemSubSteps:
            var oldNumSubSteps = self.ztStepObj[ztIndex].numSubSteps
            var newNumSubSteps = _c_round(
                tmpztStepStamp.timeStepDuration / tmpSysStepStamp.TimeStepDuration
            )
            if newNumSubSteps != oldNumSubSteps:
                self.ztStepObj[ztIndex].subSteps = List[SystemTimestepObject]()
                for _ in range(newNumSubSteps):
                    self.ztStepObj[ztIndex].subSteps.append(SystemTimestepObject())
                self.ztStepObj[ztIndex].numSubSteps = newNumSubSteps
        else:
            var newNumSubSteps = _c_round(
                tmpztStepStamp.timeStepDuration / tmpSysStepStamp.TimeStepDuration
            )
            self.ztStepObj[ztIndex].subSteps = List[SystemTimestepObject]()
            for _ in range(newNumSubSteps):
                self.ztStepObj[ztIndex].subSteps.append(SystemTimestepObject())
            self.ztStepObj[ztIndex].numSubSteps = newNumSubSteps
            self.ztStepObj[ztIndex].hasSystemSubSteps = True

        var ZoneStepStartMinutes = tmpztStepStamp.stepStartMinute

        var stStepsIntoZoneStep = _c_round(
            (
                (tmpSysStepStamp.CurMinuteStart - ZoneStepStartMinutes)
                / MinutesPerHour
            )
            / tmpSysStepStamp.TimeStepDuration
        )

        if (
            0 <= stStepsIntoZoneStep
            < self.ztStepObj[ztIndex].numSubSteps
        ):
            self.ztStepObj[ztIndex].subSteps[stStepsIntoZoneStep] = tmpSysStepStamp
            self.ztStepObj[ztIndex].subSteps[stStepsIntoZoneStep].LogDataValue = (
                self.p_rVariable
            )
        else:
            self.ztStepObj[ztIndex].subSteps[0] = tmpSysStepStamp
            self.ztStepObj[ztIndex].subSteps[0].LogDataValue = self.p_rVariable

    fn AverageSysTimeSteps(mut self) -> None:
        for i in range(len(self.ztStepObj)):
            if self.ztStepObj[i].numSubSteps > 0:
                var RunningSum: Float64 = 0.0
                for j in range(len(self.ztStepObj[i].subSteps)):
                    RunningSum += self.ztStepObj[i].subSteps[j].LogDataValue
                self.ztStepObj[i].logDataValue = (
                    RunningSum / float(self.ztStepObj[i].numSubSteps)
                )

    fn ProcessRunningAverage(mut self) -> None:
        var RunningSum: Float64 = 0.0
        var divisor = float(self.timeStepsInAverage)

        for itr_key in self.ztStepCountByEnvrnMap:
            var itr_val = self.ztStepCountByEnvrnMap[itr_key]
            for i in range(itr_val):
                if self.timeStepsInAverage > 0:
                    RunningSum = 0.0
                    for j in range(self.timeStepsInAverage):
                        if (i - j) < 0:
                            RunningSum += self.ztStepObj[
                                self.envrnStartZtStepIndexMap[itr_key]
                            ].logDataValue
                        else:
                            RunningSum += self.ztStepObj[
                                ((i - j) + self.envrnStartZtStepIndexMap[itr_key])
                            ].logDataValue
                    self.ztStepObj[
                        (i + self.envrnStartZtStepIndexMap[itr_key])
                    ].runningAvgDataValue = RunningSum / divisor

    fn GetLogVariableDataMax(mut self, state) -> ZoneTimestepObject:
        var tmpztStepStamp = ZoneTimestepObject()
        var MaxVal: Float64 = 0.0

        if len(self.ztStepObj) > 0:
            tmpztStepStamp = self.ztStepObj[0]

        for i in range(len(self.ztStepObj)):
            var zt = self.ztStepObj[i]
            if (
                zt.envrnNum > 0
                and zt.kindOfSim.value != KindOfSim.Invalid.value
                and zt.runningAvgDataValue > MaxVal
            ):
                MaxVal = zt.runningAvgDataValue
                tmpztStepStamp = zt

        return tmpztStepStamp

    fn GetLogVariableDataAtTimestamp(
        mut self, tmpztStepStamp: ZoneTimestepObject
    ) -> Float64:
        var index = self.GetZtStepIndex(tmpztStepStamp)
        return self.ztStepObj[index].runningAvgDataValue

    fn ReInitLogForIteration(mut self) -> None:
        var newList = List[ZoneTimestepObject]()
        for _ in range(len(self.ztStepObj)):
            newList.append(ZoneTimestepObject())
        self.ztStepObj = newList

    fn SetupNewEnvironment(
        mut self, seedEnvrnNum: Int32, newEnvrnNum: Int32
    ) -> None:
        self.newEnvrnToSeedEnvrnMap[newEnvrnNum] = seedEnvrnNum


struct SizingLoggerFramework:
    var logObjs: List[SizingLog]
    var NumOfLogs: Int32

    fn __init__() -> Self:
        return SizingLoggerFramework(
            logObjs=List[SizingLog](),
            NumOfLogs=0,
        )

    fn SetupVariableSizingLog(
        mut self, state, rVariable: Float64, stepsInAverage: Int32
    ) -> Int32:
        var HoursPerDay: Int32 = 24

        var tmpLog = SizingLog(rVariable)

        for i in range(1, state.dataWeather.NumOfEnvrn + 1):
            if state.dataWeather.Environment[i].KindOfEnvrn.value == KindOfSim.DesignDay.value:
                tmpLog.NumOfEnvironmentsInLogSet += 1
                tmpLog.NumOfDesignDaysInLogSet += 1
            if (
                state.dataWeather.Environment[i].KindOfEnvrn.value
                == KindOfSim.RunPeriodDesign.value
            ):
                tmpLog.NumOfEnvironmentsInLogSet += 1
                tmpLog.NumberOfSizingPeriodsInLogSet += 1

        for i in range(1, state.dataWeather.NumOfEnvrn + 1):
            if state.dataWeather.Environment[i].KindOfEnvrn.value == KindOfSim.DesignDay.value:
                tmpLog.ztStepCountByEnvrnMap[i] = (
                    HoursPerDay * state.dataGlobal.TimeStepsInHour
                )
            if (
                state.dataWeather.Environment[i].KindOfEnvrn.value
                == KindOfSim.RunPeriodDesign.value
            ):
                tmpLog.ztStepCountByEnvrnMap[i] = (
                    HoursPerDay
                    * state.dataGlobal.TimeStepsInHour
                    * state.dataWeather.Environment[i].TotalDays
                )

        var stepSum: Int32 = 0
        for itr_key in tmpLog.ztStepCountByEnvrnMap:
            tmpLog.envrnStartZtStepIndexMap[itr_key] = stepSum
            stepSum += tmpLog.ztStepCountByEnvrnMap[itr_key]

        tmpLog.timeStepsInAverage = stepsInAverage

        var VectorLength = stepSum

        tmpLog.NumOfStepsInLogSet = VectorLength
        tmpLog.ztStepObj = List[ZoneTimestepObject]()
        for _ in range(VectorLength):
            tmpLog.ztStepObj.append(ZoneTimestepObject())

        self.logObjs.append(tmpLog)
        self.NumOfLogs += 1
        return self.NumOfLogs - 1

    fn SetupSizingLogsNewEnvironment(mut self, state) -> None:
        for i in range(len(self.logObjs)):
            self.logObjs[i].SetupNewEnvironment(
                state.dataWeather.Environment[state.dataWeather.Envrn].SeedEnvrnNum,
                state.dataWeather.Envrn,
            )

    fn PrepareZoneTimestepStamp(mut self, state) -> ZoneTimestepObject:
        var locDayOfSim: Int32
        if state.dataGlobal.WarmupFlag:
            locDayOfSim = 1
        else:
            locDayOfSim = state.dataGlobal.DayOfSim

        var tmpztStepStamp = ZoneTimestepObject(
            state.dataGlobal.KindOfSim,
            state.dataWeather.Envrn,
            locDayOfSim,
            state.dataGlobal.HourOfDay,
            state.dataGlobal.TimeStep,
            state.dataOutputProcessor.TimeValue[0].TimeStep,
            state.dataGlobal.TimeStepsInHour,
        )

        return tmpztStepStamp

    fn UpdateSizingLogValuesZoneStep(mut self, state) -> None:
        var tmpztStepStamp = self.PrepareZoneTimestepStamp(state)

        for i in range(len(self.logObjs)):
            self.logObjs[i].FillZoneStep(tmpztStepStamp)

    fn UpdateSizingLogValuesSystemStep(mut self, state) -> None:
        var MinutesPerHour: Float64 = 60.0
        var tmpztStepStamp = self.PrepareZoneTimestepStamp(state)
        var tmpSysStepStamp = SystemTimestepObject()

        tmpSysStepStamp.CurMinuteEnd = (
            state.dataOutputProcessor.TimeValue[1].CurMinute
        )
        if tmpSysStepStamp.CurMinuteEnd == 0.0:
            tmpSysStepStamp.CurMinuteEnd = MinutesPerHour
        tmpSysStepStamp.CurMinuteStart = (
            tmpSysStepStamp.CurMinuteEnd
            - state.dataOutputProcessor.TimeValue[1].TimeStep * MinutesPerHour
        )
        tmpSysStepStamp.TimeStepDuration = (
            state.dataOutputProcessor.TimeValue[1].TimeStep
        )

        for i in range(len(self.logObjs)):
            self.logObjs[i].FillSysStep(tmpztStepStamp, tmpSysStepStamp)

    fn IncrementSizingPeriodSet(mut self) -> None:
        for i in range(len(self.logObjs)):
            self.logObjs[i].ReInitLogForIteration()


struct PlantCoinicidentAnalysis:
    var plantLoopIndex: Int32
    var supplySideInletNodeNum: Int32
    var plantSizingIndex: Int32
    var numTimeStepsInAvg: Int32
    var newFoundMassFlowRateTimeStamp: ZoneTimestepObject
    var peakMdotCoincidentReturnTemp: Float64
    var peakMdotCoincidentDemand: Float64
    var anotherIterationDesired: Bool
    var supplyInletNodeFlow_LogIndex: Int32
    var supplyInletNodeTemp_LogIndex: Int32
    var loopDemand_LogIndex: Int32
    var peakDemandAndFlowMismatch: Bool
    var NewFoundMaxDemandTimeStamp: ZoneTimestepObject
    var peakDemandReturnTemp: Float64
    var peakDemandMassFlow: Float64
    var name: String
    var newAdjustedMassFlowRate: Float64
    var newFoundMassFlowRate: Float64
    var significantNormalizedChange: Float64
    var densityForSizing: Float64
    var specificHeatForSizing: Float64
    var previousVolDesignFlowRate: Float64
    var newVolDesignFlowRate: Float64

    fn __init__(
        loopName: String,
        loopIndex: Int32,
        nodeNum: Int32,
        density: Float64,
        cp: Float64,
        numStepsInAvg: Int32,
        sizingIndex: Int32,
    ) -> Self:
        return PlantCoinicidentAnalysis(
            plantLoopIndex=loopIndex,
            supplySideInletNodeNum=nodeNum,
            plantSizingIndex=sizingIndex,
            numTimeStepsInAvg=numStepsInAvg,
            newFoundMassFlowRateTimeStamp=ZoneTimestepObject(),
            peakMdotCoincidentReturnTemp=0.0,
            peakMdotCoincidentDemand=0.0,
            anotherIterationDesired=False,
            supplyInletNodeFlow_LogIndex=0,
            supplyInletNodeTemp_LogIndex=0,
            loopDemand_LogIndex=0,
            peakDemandAndFlowMismatch=False,
            NewFoundMaxDemandTimeStamp=ZoneTimestepObject(),
            peakDemandReturnTemp=0.0,
            peakDemandMassFlow=0.0,
            name=loopName,
            newAdjustedMassFlowRate=0.0,
            newFoundMassFlowRate=0.0,
            significantNormalizedChange=0.005,
            densityForSizing=density,
            specificHeatForSizing=cp,
            previousVolDesignFlowRate=0.0,
            newVolDesignFlowRate=0.0,
        )

    fn CheckTimeStampForNull(self, testStamp: ZoneTimestepObject) -> Bool:
        var isNull = True

        if testStamp.envrnNum != 0:
            isNull = False
        if testStamp.kindOfSim.value != KindOfSim.Invalid.value:
            isNull = False

        return isNull

    fn ResolveDesignFlowRate(
        mut self, state, HVACSizingIterCount: Int32
    ) -> None:
        var setNewSizes = False
        var sizingFac: Float64 = 0.0
        var normalizedChange: Float64 = 0.0
        var newFoundVolFlowRate: Float64 = 0.0
        var peakLoadCalculatedMassFlow: Float64 = 0.0
        var chIteration = ""
        var chSetSizes = ""
        var chDemandTrapUsed = ""
        var changedByDemand = False
        var nullStampProblem = False

        if self.CheckTimeStampForNull(
            self.newFoundMassFlowRateTimeStamp
        ) and self.CheckTimeStampForNull(self.NewFoundMaxDemandTimeStamp):
            nullStampProblem = True
        else:
            nullStampProblem = False

        self.previousVolDesignFlowRate = (
            state.dataSize.PlantSizData[self.plantSizingIndex].DesVolFlowRate
        )

        if (
            not self.CheckTimeStampForNull(self.newFoundMassFlowRateTimeStamp)
            and (self.newFoundMassFlowRateTimeStamp.runningAvgDataValue > 0.0)
        ):
            self.newFoundMassFlowRate = (
                self.newFoundMassFlowRateTimeStamp.runningAvgDataValue
            )
        else:
            self.newFoundMassFlowRate = 0.0

        if (
            (
                not self.CheckTimeStampForNull(self.NewFoundMaxDemandTimeStamp)
                and (self.NewFoundMaxDemandTimeStamp.runningAvgDataValue > 0.0)
            )
            and (
                (
                    self.specificHeatForSizing
                    * state.dataSize.PlantSizData[self.plantSizingIndex].DeltaT
                )
                > 0.0
            )
        ):
            peakLoadCalculatedMassFlow = (
                self.NewFoundMaxDemandTimeStamp.runningAvgDataValue
                / (
                    self.specificHeatForSizing
                    * state.dataSize.PlantSizData[self.plantSizingIndex].DeltaT
                )
            )
        else:
            peakLoadCalculatedMassFlow = 0.0

        if peakLoadCalculatedMassFlow > self.newFoundMassFlowRate:
            changedByDemand = True
        else:
            changedByDemand = False

        self.newFoundMassFlowRate = max(
            self.newFoundMassFlowRate, peakLoadCalculatedMassFlow
        )

        newFoundVolFlowRate = self.newFoundMassFlowRate / self.densityForSizing

        sizingFac = 1.0
        if (
            state.dataSize.PlantSizData[self.plantSizingIndex].SizingFactorOption
            == 0
        ):
            sizingFac = 1.0
        elif (
            state.dataSize.PlantSizData[self.plantSizingIndex].SizingFactorOption
            == 1
        ):
            sizingFac = state.dataSize.GlobalHeatSizingFactor
        elif (
            state.dataSize.PlantSizData[self.plantSizingIndex].SizingFactorOption
            == 2
        ):
            sizingFac = state.dataSize.GlobalCoolSizingFactor
        elif (
            state.dataSize.PlantSizData[self.plantSizingIndex].SizingFactorOption
            == 3
        ):
            sizingFac = (
                state.dataPlnt.PlantLoop[self.plantLoopIndex]
                .LoopSide[0]
                .Branch[0]
                .PumpSizFac
            )

        self.newAdjustedMassFlowRate = self.newFoundMassFlowRate * sizingFac

        self.newVolDesignFlowRate = (
            self.newAdjustedMassFlowRate / self.densityForSizing
        )

        setNewSizes = False
        normalizedChange = 0.0
        var SmallWaterVolFlow: Float64 = 1e-6

        if self.newVolDesignFlowRate > SmallWaterVolFlow and not nullStampProblem:
            normalizedChange = abs(
                (
                    (
                        self.newVolDesignFlowRate - self.previousVolDesignFlowRate
                    )
                    / self.previousVolDesignFlowRate
                )
            )
            if normalizedChange > self.significantNormalizedChange:
                self.anotherIterationDesired = True
                setNewSizes = True
            else:
                self.anotherIterationDesired = False

        if setNewSizes:
            state.dataSize.PlantSizData[
                self.plantSizingIndex
            ].DesVolFlowRate = self.newVolDesignFlowRate

            if state.dataPlnt.PlantLoop[self.plantLoopIndex].MaxVolFlowRateWasAutoSized:
                state.dataPlnt.PlantLoop[
                    self.plantLoopIndex
                ].MaxVolFlowRate = self.newVolDesignFlowRate
                state.dataPlnt.PlantLoop[
                    self.plantLoopIndex
                ].MaxMassFlowRate = self.newAdjustedMassFlowRate

            if state.dataPlnt.PlantLoop[self.plantLoopIndex].VolumeWasAutoSized:
                state.dataPlnt.PlantLoop[self.plantLoopIndex].Volume = (
                    state.dataPlnt.PlantLoop[self.plantLoopIndex].MaxVolFlowRate
                    * state.dataPlnt.PlantLoop[self.plantLoopIndex].CirculationTime
                    * 60.0
                )
                state.dataPlnt.PlantLoop[self.plantLoopIndex].Mass = (
                    state.dataPlnt.PlantLoop[self.plantLoopIndex].Volume
                    * self.densityForSizing
                )

        if not state.dataGlobal.sizingAnalysisEioHeaderDoneOnce:
            state.files.eio.write(
                "! <Plant Coincident Sizing Algorithm>,Plant Loop Name,Sizing Pass {#},Measured Mass "
                "Flow{kg/s},Measured Demand {W},Demand Calculated Mass Flow{kg/s},Sizes Changed {Yes/No},Previous "
                "Volume Flow Rate {m3/s},New Volume Flow Rate {m3/s},Demand Check Applied {Yes/No},Sizing Factor "
                "{},Normalized Change {},Specific Heat{J/kg-K},Density {kg/m3}\n"
            )
            state.dataGlobal.sizingAnalysisEioHeaderDoneOnce = True

        chIteration = str(HVACSizingIterCount)
        if setNewSizes:
            chSetSizes = "Yes"
        else:
            chSetSizes = "No"
        if changedByDemand:
            chDemandTrapUsed = "Yes"
        else:
            chDemandTrapUsed = "No"

        state.files.eio.write(
            f"Plant Coincident Sizing Algorithm,{self.name},{chIteration},"
            f"{self.newFoundMassFlowRateTimeStamp.runningAvgDataValue:.7g},"
            f"{self.NewFoundMaxDemandTimeStamp.runningAvgDataValue:.2f},"
            f"{peakLoadCalculatedMassFlow:.7g},{chSetSizes},"
            f"{self.previousVolDesignFlowRate:.6f},{self.newVolDesignFlowRate:.6f},"
            f"{chDemandTrapUsed},{sizingFac:.4f},{normalizedChange:.6f},"
            f"{self.specificHeatForSizing:.4f},{self.densityForSizing:.4f}\n"
        )

        # PreDefTableEntry stubs
        pass
