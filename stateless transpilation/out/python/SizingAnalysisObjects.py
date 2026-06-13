from typing import Any, Protocol
from dataclasses import dataclass, field
from enum import Enum, auto
import math

# EXTERNAL DEPS (to wire in glue):
# - Constant.KindOfSim: enum from EnergyPlus/Data/BaseData.hh
# - EnergyPlusData: struct from EnergyPlus/EnergyPlus.hh
#   Required attributes: dataWeather, dataGlobal, dataSize, dataPlnt, dataOutputProcessor, files, sizingAnalysisEioHeaderDoneOnce
# - OutputProcessor.TimeStepType: enum indices [0]=Zone, [1]=System
# - DataSizing sizing factor modes: constants 0=NoSizingFactorMode, 1=GlobalHeatingSizingFactorMode, 2=GlobalCoolingSizingFactorMode, 3=LoopComponentSizingFactorMode
# - LoopSideLocation.Supply: constant [0]
# - HVAC.SmallWaterVolFlow: float constant (1e-6 approx)
# - UtilityRoutines.ShowWarningMessage: function
# - OutputReportPredefined.PreDefTableEntry: function
# - print, fmt.to_string: output functions


def _c_round(x: float) -> int:
    """C++ round() behavior: round half away from zero."""
    return int(x + 0.5) if x >= 0 else int(x - 0.5)


class KindOfSim(Enum):
    Invalid = 0
    DesignDay = 1
    RunPeriodDesign = 2


@dataclass
class SystemTimestepObject:
    CurMinuteStart: float = 0.0
    CurMinuteEnd: float = 0.0
    TimeStepDuration: float = 0.0
    LogDataValue: float = 0.0
    stStepsIntoZoneStep: int = 0


class ZoneTimestepObject:
    def __init__(
        self,
        kindSim: KindOfSim = None,
        environmentNum: int = None,
        daySim: int = None,
        hourDay: int = None,
        timeStep: int = None,
        timeStepDurat: float = None,
        numOfTimeStepsPerHour: int = None,
    ):
        if kindSim is None:
            # Default constructor
            self.kindOfSim = KindOfSim.Invalid
            self.envrnNum = 0
            self.dayOfSim = 0
            self.hourOfDay = 0
            self.ztStepsIntoPeriod = 0
            self.stepStartMinute = 0.0
            self.stepEndMinute = 0.0
            self.timeStepDuration = 0.0
            self.logDataValue = 0.0
            self.runningAvgDataValue = 0.0
            self.hasSystemSubSteps = False
            self.numSubSteps = 0
            self.subSteps = []
        else:
            # Full constructor
            self.kindOfSim = kindSim
            self.envrnNum = environmentNum
            self.dayOfSim = daySim
            self.hourOfDay = hourDay
            self.timeStepDuration = timeStepDurat
            self.logDataValue = 0.0
            self.runningAvgDataValue = 0.0
            self.hasSystemSubSteps = True
            self.numSubSteps = 1
            self.subSteps = [SystemTimestepObject()]

            minutesPerHour = 60.0
            hoursPerDay = 24

            self.stepEndMinute = (
                timeStepDurat * minutesPerHour + (timeStep - 1) * timeStepDurat * minutesPerHour
            )
            self.stepStartMinute = self.stepEndMinute - timeStepDurat * minutesPerHour

            if self.stepStartMinute < 0.0:
                self.stepStartMinute = 0.0
                self.stepEndMinute = timeStepDurat * minutesPerHour

            self.ztStepsIntoPeriod = (
                (daySim - 1) * (hoursPerDay * numOfTimeStepsPerHour)
                + (hourDay - 1) * numOfTimeStepsPerHour
                + _c_round((self.stepStartMinute / minutesPerHour) / timeStepDurat)
            )

            if self.ztStepsIntoPeriod < 0:
                self.ztStepsIntoPeriod = 0


class SizingLog:
    def __init__(self, rVariable):
        self.p_rVariable = rVariable
        self.NumOfEnvironmentsInLogSet = 0
        self.NumOfDesignDaysInLogSet = 0
        self.NumberOfSizingPeriodsInLogSet = 0
        self.ztStepCountByEnvrnMap: dict[int, int] = {}
        self.envrnStartZtStepIndexMap: dict[int, int] = {}
        self.newEnvrnToSeedEnvrnMap: dict[int, int] = {}
        self.NumOfStepsInLogSet = 0
        self.timeStepsInAverage = 0
        self.ztStepObj: list[ZoneTimestepObject] = []

    def GetZtStepIndex(self, tmpztStepStamp: ZoneTimestepObject) -> int:
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

    def FillZoneStep(self, tmpztStepStamp: ZoneTimestepObject) -> None:
        index = self.GetZtStepIndex(tmpztStepStamp)

        self.ztStepObj[index].kindOfSim = tmpztStepStamp.kindOfSim
        self.ztStepObj[index].envrnNum = tmpztStepStamp.envrnNum
        self.ztStepObj[index].dayOfSim = tmpztStepStamp.dayOfSim
        self.ztStepObj[index].hourOfDay = tmpztStepStamp.hourOfDay
        self.ztStepObj[index].ztStepsIntoPeriod = tmpztStepStamp.ztStepsIntoPeriod
        self.ztStepObj[index].stepStartMinute = tmpztStepStamp.stepStartMinute
        self.ztStepObj[index].stepEndMinute = tmpztStepStamp.stepEndMinute
        self.ztStepObj[index].timeStepDuration = tmpztStepStamp.timeStepDuration

        self.ztStepObj[index].logDataValue = self.p_rVariable

    def GetSysStepZtStepIndex(self, tmpztStepStamp: ZoneTimestepObject) -> int:
        znStepIndex = self.GetZtStepIndex(tmpztStepStamp)

        if znStepIndex >= self.NumOfStepsInLogSet:
            znStepIndex = self.NumOfStepsInLogSet - 1
        if znStepIndex < 0:
            znStepIndex = 0

        return znStepIndex

    def FillSysStep(
        self, tmpztStepStamp: ZoneTimestepObject, tmpSysStepStamp: SystemTimestepObject
    ) -> None:
        MinutesPerHour = 60.0

        ztIndex = self.GetSysStepZtStepIndex(tmpztStepStamp)

        if self.ztStepObj[ztIndex].hasSystemSubSteps:
            oldNumSubSteps = self.ztStepObj[ztIndex].numSubSteps
            newNumSubSteps = _c_round(
                tmpztStepStamp.timeStepDuration / tmpSysStepStamp.TimeStepDuration
            )
            if newNumSubSteps != oldNumSubSteps:
                self.ztStepObj[ztIndex].subSteps = [
                    SystemTimestepObject() for _ in range(newNumSubSteps)
                ]
                self.ztStepObj[ztIndex].numSubSteps = newNumSubSteps
        else:
            newNumSubSteps = _c_round(
                tmpztStepStamp.timeStepDuration / tmpSysStepStamp.TimeStepDuration
            )
            self.ztStepObj[ztIndex].subSteps = [
                SystemTimestepObject() for _ in range(newNumSubSteps)
            ]
            self.ztStepObj[ztIndex].numSubSteps = newNumSubSteps
            self.ztStepObj[ztIndex].hasSystemSubSteps = True

        ZoneStepStartMinutes = tmpztStepStamp.stepStartMinute

        tmpSysStepStamp.stStepsIntoZoneStep = _c_round(
            (
                (tmpSysStepStamp.CurMinuteStart - ZoneStepStartMinutes)
                / MinutesPerHour
            )
            / tmpSysStepStamp.TimeStepDuration
        )

        if (
            0 <= tmpSysStepStamp.stStepsIntoZoneStep
            < self.ztStepObj[ztIndex].numSubSteps
        ):
            self.ztStepObj[ztIndex].subSteps[tmpSysStepStamp.stStepsIntoZoneStep] = (
                tmpSysStepStamp
            )
            self.ztStepObj[ztIndex].subSteps[
                tmpSysStepStamp.stStepsIntoZoneStep
            ].LogDataValue = self.p_rVariable
        else:
            self.ztStepObj[ztIndex].subSteps[0] = tmpSysStepStamp
            self.ztStepObj[ztIndex].subSteps[0].LogDataValue = self.p_rVariable

    def AverageSysTimeSteps(self) -> None:
        for zt in self.ztStepObj:
            if zt.numSubSteps > 0:
                RunningSum = 0.0
                for SysT in zt.subSteps:
                    RunningSum += SysT.LogDataValue
                zt.logDataValue = RunningSum / float(zt.numSubSteps)

    def ProcessRunningAverage(self) -> None:
        RunningSum = 0.0
        divisor = float(self.timeStepsInAverage)

        for itr_key, itr_val in self.ztStepCountByEnvrnMap.items():
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

    def GetLogVariableDataMax(self, state: Any) -> ZoneTimestepObject:
        tmpztStepStamp = ZoneTimestepObject()
        MaxVal = 0.0

        if self.ztStepObj:
            tmpztStepStamp = self.ztStepObj[0]

        for zt in self.ztStepObj:
            if (
                zt.envrnNum > 0
                and zt.kindOfSim != KindOfSim.Invalid
                and zt.runningAvgDataValue > MaxVal
            ):
                MaxVal = zt.runningAvgDataValue
                tmpztStepStamp = zt
            elif zt.envrnNum == 0 and zt.kindOfSim == KindOfSim.Invalid:
                pass

        return tmpztStepStamp

    def GetLogVariableDataAtTimestamp(
        self, tmpztStepStamp: ZoneTimestepObject
    ) -> float:
        index = self.GetZtStepIndex(tmpztStepStamp)
        return self.ztStepObj[index].runningAvgDataValue

    def ReInitLogForIteration(self) -> None:
        self.ztStepObj = [
            ZoneTimestepObject() for _ in range(len(self.ztStepObj))
        ]

    def SetupNewEnvironment(self, seedEnvrnNum: int, newEnvrnNum: int) -> None:
        self.newEnvrnToSeedEnvrnMap[newEnvrnNum] = seedEnvrnNum


class SizingLoggerFramework:
    def __init__(self):
        self.logObjs: list[SizingLog] = []
        self.NumOfLogs = 0

    def SetupVariableSizingLog(
        self, state: Any, rVariable: float, stepsInAverage: int
    ) -> int:
        HoursPerDay = 24

        tmpLog = SizingLog(rVariable)
        tmpLog.NumOfEnvironmentsInLogSet = 0
        tmpLog.NumOfDesignDaysInLogSet = 0
        tmpLog.NumberOfSizingPeriodsInLogSet = 0

        for i in range(1, state.dataWeather.NumOfEnvrn + 1):
            if state.dataWeather.Environment[i].KindOfEnvrn == KindOfSim.DesignDay:
                tmpLog.NumOfEnvironmentsInLogSet += 1
                tmpLog.NumOfDesignDaysInLogSet += 1
            if (
                state.dataWeather.Environment[i].KindOfEnvrn
                == KindOfSim.RunPeriodDesign
            ):
                tmpLog.NumOfEnvironmentsInLogSet += 1
                tmpLog.NumberOfSizingPeriodsInLogSet += 1

        for i in range(1, state.dataWeather.NumOfEnvrn + 1):
            if state.dataWeather.Environment[i].KindOfEnvrn == KindOfSim.DesignDay:
                tmpLog.ztStepCountByEnvrnMap[i] = (
                    HoursPerDay * state.dataGlobal.TimeStepsInHour
                )
            if (
                state.dataWeather.Environment[i].KindOfEnvrn
                == KindOfSim.RunPeriodDesign
            ):
                tmpLog.ztStepCountByEnvrnMap[i] = (
                    HoursPerDay
                    * state.dataGlobal.TimeStepsInHour
                    * state.dataWeather.Environment[i].TotalDays
                )

        stepSum = 0
        for itr_key, itr_val in tmpLog.ztStepCountByEnvrnMap.items():
            tmpLog.envrnStartZtStepIndexMap[itr_key] = stepSum
            stepSum += itr_val

        tmpLog.timeStepsInAverage = stepsInAverage

        VectorLength = stepSum

        tmpLog.NumOfStepsInLogSet = VectorLength
        tmpLog.ztStepObj = [ZoneTimestepObject() for _ in range(VectorLength)]

        self.logObjs.append(tmpLog)
        self.NumOfLogs += 1
        return self.NumOfLogs - 1

    def SetupSizingLogsNewEnvironment(self, state: Any) -> None:
        for l in self.logObjs:
            l.SetupNewEnvironment(
                state.dataWeather.Environment[state.dataWeather.Envrn].SeedEnvrnNum,
                state.dataWeather.Envrn,
            )

    def PrepareZoneTimestepStamp(self, state: Any) -> ZoneTimestepObject:
        if state.dataGlobal.WarmupFlag:
            locDayOfSim = 1
        else:
            locDayOfSim = state.dataGlobal.DayOfSim

        tmpztStepStamp = ZoneTimestepObject(
            state.dataGlobal.KindOfSim,
            state.dataWeather.Envrn,
            locDayOfSim,
            state.dataGlobal.HourOfDay,
            state.dataGlobal.TimeStep,
            state.dataOutputProcessor.TimeValue[0].TimeStep,
            state.dataGlobal.TimeStepsInHour,
        )

        return tmpztStepStamp

    def UpdateSizingLogValuesZoneStep(self, state: Any) -> None:
        tmpztStepStamp = self.PrepareZoneTimestepStamp(state)

        for l in self.logObjs:
            l.FillZoneStep(tmpztStepStamp)

    def UpdateSizingLogValuesSystemStep(self, state: Any) -> None:
        MinutesPerHour = 60.0
        tmpztStepStamp = self.PrepareZoneTimestepStamp(state)
        tmpSysStepStamp = SystemTimestepObject()

        tmpSysStepStamp.CurMinuteEnd = state.dataOutputProcessor.TimeValue[1].CurMinute
        if tmpSysStepStamp.CurMinuteEnd == 0.0:
            tmpSysStepStamp.CurMinuteEnd = MinutesPerHour
        tmpSysStepStamp.CurMinuteStart = (
            tmpSysStepStamp.CurMinuteEnd
            - state.dataOutputProcessor.TimeValue[1].TimeStep * MinutesPerHour
        )
        tmpSysStepStamp.TimeStepDuration = state.dataOutputProcessor.TimeValue[
            1
        ].TimeStep

        for l in self.logObjs:
            l.FillSysStep(tmpztStepStamp, tmpSysStepStamp)

    def IncrementSizingPeriodSet(self) -> None:
        for l in self.logObjs:
            l.ReInitLogForIteration()


class PlantCoinicidentAnalysis:
    def __init__(
        self,
        loopName: str,
        loopIndex: int,
        nodeNum: int,
        density: float,
        cp: float,
        numStepsInAvg: int,
        sizingIndex: int,
    ):
        self.plantLoopIndex = loopIndex
        self.supplySideInletNodeNum = nodeNum
        self.plantSizingIndex = sizingIndex
        self.numTimeStepsInAvg = numStepsInAvg
        self.newFoundMassFlowRateTimeStamp = ZoneTimestepObject()
        self.peakMdotCoincidentReturnTemp = 0.0
        self.peakMdotCoincidentDemand = 0.0
        self.anotherIterationDesired = False
        self.supplyInletNodeFlow_LogIndex = 0
        self.supplyInletNodeTemp_LogIndex = 0
        self.loopDemand_LogIndex = 0
        self.peakDemandAndFlowMismatch = False
        self.NewFoundMaxDemandTimeStamp = ZoneTimestepObject()
        self.peakDemandReturnTemp = 0.0
        self.peakDemandMassFlow = 0.0

        self.name = loopName
        self.newAdjustedMassFlowRate = 0.0
        self.newFoundMassFlowRate = 0.0
        self.significantNormalizedChange = 0.005
        self.densityForSizing = density
        self.specificHeatForSizing = cp
        self.previousVolDesignFlowRate = 0.0
        self.newVolDesignFlowRate = 0.0

    def CheckTimeStampForNull(self, testStamp: ZoneTimestepObject) -> bool:
        isNull = True

        if testStamp.envrnNum != 0:
            isNull = False
        if testStamp.kindOfSim != KindOfSim.Invalid:
            isNull = False

        return isNull

    def ResolveDesignFlowRate(self, state: Any, HVACSizingIterCount: int) -> None:
        setNewSizes = False
        sizingFac = 0.0
        normalizedChange = 0.0
        newFoundVolFlowRate = 0.0
        peakLoadCalculatedMassFlow = 0.0
        chIteration = ""
        chSetSizes = ""
        chDemandTrapUsed = ""
        changedByDemand = False
        nullStampProblem = False

        if self.CheckTimeStampForNull(
            self.newFoundMassFlowRateTimeStamp
        ) and self.CheckTimeStampForNull(self.NewFoundMaxDemandTimeStamp):
            nullStampProblem = True
        else:
            nullStampProblem = False

        self.previousVolDesignFlowRate = state.dataSize.PlantSizData[
            self.plantSizingIndex
        ].DesVolFlowRate

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
        SmallWaterVolFlow = 1e-6

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

        if (
            state.dataSize.PlantSizData[self.plantSizingIndex].SizingFactorOption == 3
        ):
            pdchPlantSizPrevVdot = 0
            pdchPlantSizMeasVdot = 1
            pdchPlantSizCalcVdot = 2
            pdchPlantSizCoincYesNo = 3
            pdchPlantSizDesDay = 4
            pdchPlantSizPkTimeDayOfSim = 5
            pdchPlantSizPkTimeHour = 6
            pdchPlantSizPkTimeMin = 7

            PreDefTableEntry(
                state,
                pdchPlantSizPrevVdot,
                state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                + " Sizing Pass "
                + chIteration,
                self.previousVolDesignFlowRate,
                6,
            )
            PreDefTableEntry(
                state,
                pdchPlantSizMeasVdot,
                state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                + " Sizing Pass "
                + chIteration,
                newFoundVolFlowRate,
                6,
            )
            PreDefTableEntry(
                state,
                pdchPlantSizCalcVdot,
                state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                + " Sizing Pass "
                + chIteration,
                self.newVolDesignFlowRate,
                6,
            )

            if setNewSizes:
                PreDefTableEntry(
                    state,
                    pdchPlantSizCoincYesNo,
                    state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                    + " Sizing Pass "
                    + chIteration,
                    "Yes",
                )
            else:
                PreDefTableEntry(
                    state,
                    pdchPlantSizCoincYesNo,
                    state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                    + " Sizing Pass "
                    + chIteration,
                    "No",
                )

            if not nullStampProblem:
                if (
                    not changedByDemand
                    and not self.CheckTimeStampForNull(
                        self.newFoundMassFlowRateTimeStamp
                    )
                ):
                    if self.newFoundMassFlowRateTimeStamp.envrnNum > 0:
                        PreDefTableEntry(
                            state,
                            pdchPlantSizDesDay,
                            state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                            + " Sizing Pass "
                            + chIteration,
                            state.dataWeather.Environment[
                                self.newFoundMassFlowRateTimeStamp.envrnNum
                            ].Title,
                        )
                    PreDefTableEntry(
                        state,
                        pdchPlantSizPkTimeDayOfSim,
                        state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                        + " Sizing Pass "
                        + chIteration,
                        self.newFoundMassFlowRateTimeStamp.dayOfSim,
                    )
                    PreDefTableEntry(
                        state,
                        pdchPlantSizPkTimeHour,
                        state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                        + " Sizing Pass "
                        + chIteration,
                        self.newFoundMassFlowRateTimeStamp.hourOfDay - 1,
                    )
                    PreDefTableEntry(
                        state,
                        pdchPlantSizPkTimeMin,
                        state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                        + " Sizing Pass "
                        + chIteration,
                        self.newFoundMassFlowRateTimeStamp.stepStartMinute,
                        0,
                    )
                elif (
                    changedByDemand
                    and not self.CheckTimeStampForNull(
                        self.NewFoundMaxDemandTimeStamp
                    )
                ):
                    if self.NewFoundMaxDemandTimeStamp.envrnNum > 0:
                        PreDefTableEntry(
                            state,
                            pdchPlantSizDesDay,
                            state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                            + " Sizing Pass "
                            + chIteration,
                            state.dataWeather.Environment[
                                self.NewFoundMaxDemandTimeStamp.envrnNum
                            ].Title,
                        )
                    PreDefTableEntry(
                        state,
                        pdchPlantSizPkTimeDayOfSim,
                        state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                        + " Sizing Pass "
                        + chIteration,
                        self.NewFoundMaxDemandTimeStamp.dayOfSim,
                    )
                    PreDefTableEntry(
                        state,
                        pdchPlantSizPkTimeHour,
                        state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                        + " Sizing Pass "
                        + chIteration,
                        self.NewFoundMaxDemandTimeStamp.hourOfDay - 1,
                    )
                    PreDefTableEntry(
                        state,
                        pdchPlantSizPkTimeMin,
                        state.dataPlnt.PlantLoop[self.plantLoopIndex].Name
                        + " Sizing Pass "
                        + chIteration,
                        self.NewFoundMaxDemandTimeStamp.stepStartMinute,
                        0,
                    )


def PreDefTableEntry(state: Any, key: int, name: str, value: Any, decimals: int = 0) -> None:
    pass
