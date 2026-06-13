from algorithm import sort
from list import List
from utility_routines import ShowSevereError, ShowWarningError, ShowFatalError
from ...Data.BaseData import BaseGlobalStruct
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataEnvironment import *
from ...DataHVACGlobals import *
from ...General import EncodeMonDayHrMin, SameString
from ...InputProcessing.InputProcessor import *
from ...OutputProcessor import *
from ...OutputReportData import *
from ...OutputReportTabular import *
from ...ResultsFramework import *
from ...SQLiteProcedures import *
from ...ScheduleManager import *
from utility_routines import SameString as Util_SameString

alias Real64 = Float64
alias Array1D_string = List[String]
alias Array1D_int = List[Int]
alias Array1D_Real64 = List[Real64]
alias Array2D_string = List[List[String]]

struct AnnualTable:
    var m_name: String
    var m_filter: String
    var m_sched: Optional[Sched.Schedule] = None
    var m_objectNames: List[String] = List[String]()
    var m_annualFields: List[AnnualFieldSet] = List[AnnualFieldSet]()

    def __init__(inout self):

    def __init__(inout self, state: EnergyPlusData, name: String, filter: String, schedName: String):
        self.m_name = name
        self.m_filter = filter
        if schedName.__len__() > 0:
            self.m_sched = Sched.GetSchedule(state, schedName)
        else:
            self.m_sched = None

    def addFieldSet(inout self, varName: String, aggKind: AnnualFieldSet.AggregationKind, dgts: Int):
        self.m_annualFields.append(AnnualFieldSet(varName, aggKind, dgts))
        var i = self.m_annualFields.__len__() - 1
        self.m_annualFields[i].m_colHead = varName

    def addFieldSet(inout self, varName: String, colName: String, aggKind: AnnualFieldSet.AggregationKind, dgts: Int):
        self.m_annualFields.append(AnnualFieldSet(varName, aggKind, dgts))
        var i = self.m_annualFields.__len__() - 1
        self.m_annualFields[i].m_colHead = colName

    def setupGathering(inout self, state: EnergyPlusData):
        var typeVar: OutputProcessor.VariableType = OutputProcessor.VariableType.Invalid
        var avgSumVar: OutputProcessor.StoreType
        var stepTypeVar: OutputProcessor.TimeStepType
        var unitsVar: Constant.Units = Constant.Units.None
        var allKeys: List[String] = List[String]()
        var filterFieldUpper: String = self.m_filter
        filterFieldUpper = filterFieldUpper.upper()
        var useFilter: Bool = not self.m_filter.__eq__("")
        for fldSt in self.m_annualFields:
            var keyCount: Int = fldSt.getVariableKeyCountandTypeFromFldSt(state, typeVar, avgSumVar, stepTypeVar, unitsVar)
            fldSt.getVariableKeysFromFldSt(state, typeVar, keyCount, fldSt.m_namesOfKeys, fldSt.m_indexesForKeyVar)
            for nm in fldSt.m_namesOfKeys:
                var nmUpper: String = nm.upper()
                if not useFilter or nmUpper.find(filterFieldUpper) != -1:
                    allKeys.append(nm)
            fldSt.m_typeOfVar = typeVar
            fldSt.m_varAvgSum = avgSumVar
            fldSt.m_varStepType = stepTypeVar
            fldSt.m_varUnits = unitsVar
            fldSt.m_keyCount = keyCount
        sort(allKeys)
        # unique
        var uniqueKeys: List[String] = List[String]()
        for i in range(allKeys.__len__()):
            if i == 0 or allKeys[i] != allKeys[i-1]:
                uniqueKeys.append(allKeys[i])
        self.m_objectNames.clear()
        for key in uniqueKeys:
            self.m_objectNames.append(key)
        for fldSt in self.m_annualFields:
            fldSt.m_cell.resize(self.m_objectNames.__len__())
        var tableRowIndex: Int = 0
        for objName in self.m_objectNames:
            for fldSt in self.m_annualFields:
                var foundKeyIndex: Int = -1
                var i: Int = 0
                while i < fldSt.m_namesOfKeys.__len__():
                    if fldSt.m_namesOfKeys[i] == objName:
                        foundKeyIndex = i
                        break
                    i += 1
                fldSt.m_cell[tableRowIndex].indexesForKeyVar = fldSt.m_indexesForKeyVar[foundKeyIndex] if foundKeyIndex >= 0 else -1
                if fldSt.m_aggregate == AnnualFieldSet.AggregationKind.maximum or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.maximumDuringHoursShown:
                    fldSt.m_cell[tableRowIndex].result = verySmall
                elif fldSt.m_aggregate == AnnualFieldSet.AggregationKind.minimum or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.minimumDuringHoursShown:
                    fldSt.m_cell[tableRowIndex].result = veryLarge
                else:
                    fldSt.m_cell[tableRowIndex].result = 0.0
                fldSt.m_cell[tableRowIndex].duration = 0.0
                fldSt.m_cell[tableRowIndex].timeStamp = 0
            tableRowIndex += 1

    def invalidAggregationOrder(inout self, state: EnergyPlusData) -> Bool:
        var foundMinOrMax: Bool = False
        var foundHourAgg: Bool = False
        var missingMaxOrMinError: Bool = False
        var missingHourAggError: Bool = False
        for fldSt in self.m_annualFields:
            if fldSt.m_aggregate == AnnualFieldSet.AggregationKind.maximum or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.minimum:
                foundMinOrMax = True
            elif fldSt.m_aggregate == AnnualFieldSet.AggregationKind.hoursNonZero or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.hoursZero or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.hoursPositive or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.hoursNonPositive or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.hoursNegative or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.hoursNonNegative:
                foundHourAgg = True
            elif fldSt.m_aggregate == AnnualFieldSet.AggregationKind.valueWhenMaxMin:
                if not foundMinOrMax:
                    missingMaxOrMinError = True
            elif fldSt.m_aggregate == AnnualFieldSet.AggregationKind.sumOrAverageHoursShown or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.maximumDuringHoursShown or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.minimumDuringHoursShown:
                if not foundHourAgg:
                    missingHourAggError = True
        if missingMaxOrMinError:
            ShowSevereError(state, "The Output:Table:Annual report named=\"" + self.m_name + "\" has a valueWhenMaxMin aggregation type for a column without a previous column that uses either the minimum or maximum aggregation types. The report will not be generated.")
        if missingHourAggError:
            ShowSevereError(state, "The Output:Table:Annual report named=\"" + self.m_name + "\" has a --DuringHoursShown aggregation type for a column without a previous field that uses one of the Hour-- aggregation types. The report will not be generated.")
        return missingHourAggError or missingMaxOrMinError

    def gatherForTimestep(inout self, state: EnergyPlusData, kindOfTimeStep: OutputProcessor.TimeStepType):
        var timestepTimeStamp: Int
        var elapsedTime: Real64 = AnnualTable.getElapsedTime(state, kindOfTimeStep)
        var secondsInTimeStep: Real64 = AnnualTable.getSecondsInTimeStep(state, kindOfTimeStep)
        var activeMinMax: Bool = False
        var activeHoursShown: Bool = False
        if self.m_sched is not None:
            var sched_ptr = self.m_sched.value
            if sched_ptr.getCurrentVal() == 0.0:
                return
        var row: Int = 0
        while row < self.m_objectNames.__len__():
            var fldStIt: Int = 0
            while fldStIt < self.m_annualFields.__len__():
                var curTypeOfVar: OutputProcessor.VariableType = self.m_annualFields[fldStIt].m_typeOfVar
                var curStepType: OutputProcessor.TimeStepType = self.m_annualFields[fldStIt].m_varStepType
                if curStepType == kindOfTimeStep:
                    var curVarNum: Int = self.m_annualFields[fldStIt].m_cell[row].indexesForKeyVar
                    if curVarNum > -1:
                        var curValue: Real64 = GetInternalVariableValue(state, curTypeOfVar, curVarNum)
                        var oldResultValue: Real64 = self.m_annualFields[fldStIt].m_cell[row].result
                        var oldDuration: Real64 = self.m_annualFields[fldStIt].m_cell[row].duration
                        var newResultValue: Real64 = 0.0
                        var newTimeStamp: Int = 0
                        var newDuration: Real64 = 0.0
                        var activeNewValue: Bool = False
                        var minuteCalculated: Int = OutputProcessor.DetermineMinuteForReporting(state)
                        EncodeMonDayHrMin(timestepTimeStamp, state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, state.dataGlobal.HourOfDay, minuteCalculated)
                        if self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.sumOrAvg:
                            if self.m_annualFields[fldStIt].m_varAvgSum == OutputProcessor.StoreType.Sum:
                                newResultValue = oldResultValue + curValue
                            else:
                                newResultValue = oldResultValue + curValue * elapsedTime
                            newDuration = oldDuration + elapsedTime
                            activeNewValue = True
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.maximum:
                            if self.m_annualFields[fldStIt].m_varAvgSum == OutputProcessor.StoreType.Sum:
                                curValue /= secondsInTimeStep
                            if curValue > oldResultValue:
                                newResultValue = curValue
                                newTimeStamp = timestepTimeStamp
                                activeMinMax = True
                                activeNewValue = True
                            else:
                                activeMinMax = False
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.minimum:
                            if self.m_annualFields[fldStIt].m_varAvgSum == OutputProcessor.StoreType.Sum:
                                curValue /= secondsInTimeStep
                            if curValue < oldResultValue:
                                newResultValue = curValue
                                newTimeStamp = timestepTimeStamp
                                activeMinMax = True
                                activeNewValue = True
                            else:
                                activeMinMax = False
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursNonZero:
                            if curValue != 0:
                                newResultValue = oldResultValue + elapsedTime
                                activeHoursShown = True
                                activeNewValue = True
                            else:
                                activeHoursShown = False
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursZero:
                            if curValue == 0:
                                newResultValue = oldResultValue + elapsedTime
                                activeHoursShown = True
                                activeNewValue = True
                            else:
                                activeHoursShown = False
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursPositive:
                            if curValue > 0:
                                newResultValue = oldResultValue + elapsedTime
                                activeHoursShown = True
                                activeNewValue = True
                            else:
                                activeHoursShown = False
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursNonPositive:
                            if curValue <= 0:
                                newResultValue = oldResultValue + elapsedTime
                                activeHoursShown = True
                                activeNewValue = True
                            else:
                                activeHoursShown = False
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursNegative:
                            if curValue < 0:
                                newResultValue = oldResultValue + elapsedTime
                                activeHoursShown = True
                                activeNewValue = True
                            else:
                                activeHoursShown = False
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursNonNegative:
                            if curValue >= 0:
                                newResultValue = oldResultValue + elapsedTime
                                activeHoursShown = True
                                activeNewValue = True
                            else:
                                activeHoursShown = False
                        elif self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenPercentBins or self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToMax or self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsZeroToMax or self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToZero or self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusTwoStdDev or self.m_annualFields[fldStIt].m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusThreeStdDev:
                            if self.m_annualFields[fldStIt].m_varAvgSum == OutputProcessor.StoreType.Sum:
                                var curValueRate: Real64 = curValue / secondsInTimeStep
                                self.m_annualFields[fldStIt].m_cell[row].deferredResults.append(curValueRate)
                            else:
                                self.m_annualFields[fldStIt].m_cell[row].deferredResults.append(curValue)
                            self.m_annualFields[fldStIt].m_cell[row].deferredElapsed.append(elapsedTime)
                        if activeNewValue:
                            self.m_annualFields[fldStIt].m_cell[row].result = newResultValue
                            self.m_annualFields[fldStIt].m_cell[row].timeStamp = newTimeStamp
                            self.m_annualFields[fldStIt].m_cell[row].duration = newDuration
                        if activeMinMax:
                            var fldStRemainIt: Int = fldStIt + 1
                            while fldStRemainIt < self.m_annualFields.__len__():
                                if self.m_annualFields[fldStRemainIt].m_aggregate == AnnualFieldSet.AggregationKind.maximum or self.m_annualFields[fldStRemainIt].m_aggregate == AnnualFieldSet.AggregationKind.minimum:
                                    break
                                if self.m_annualFields[fldStRemainIt].m_aggregate == AnnualFieldSet.AggregationKind.valueWhenMaxMin:
                                    var scanTypeOfVar: OutputProcessor.VariableType = self.m_annualFields[fldStRemainIt].m_typeOfVar
                                    var scanVarNum: Int = self.m_annualFields[fldStRemainIt].m_cell[row].indexesForKeyVar
                                    if scanVarNum > -1:
                                        var scanValue: Real64 = GetInternalVariableValue(state, scanTypeOfVar, scanVarNum)
                                        if self.m_annualFields[fldStRemainIt].m_varAvgSum == OutputProcessor.StoreType.Sum:
                                            scanValue /= secondsInTimeStep
                                        self.m_annualFields[fldStRemainIt].m_cell[row].result = scanValue
                                fldStRemainIt += 1
                        if activeHoursShown:
                            var fldStRemainIt2: Int = fldStIt + 1
                            while fldStRemainIt2 < self.m_annualFields.__len__():
                                var scanTypeOfVar2: OutputProcessor.VariableType = self.m_annualFields[fldStRemainIt2].m_typeOfVar
                                var scanVarNum2: Int = self.m_annualFields[fldStRemainIt2].m_cell[row].indexesForKeyVar
                                var oldScanValue: Real64 = self.m_annualFields[fldStRemainIt2].m_cell[row].result
                                if scanVarNum2 > -1:
                                    var scanValue2: Real64 = GetInternalVariableValue(state, scanTypeOfVar2, scanVarNum2)
                                    if self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.hoursZero or self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.hoursNonZero or self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.hoursPositive or self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.hoursNonPositive or self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.hoursNegative or self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.hoursNonNegative:
                                        break
                                    if self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.sumOrAverageHoursShown:
                                        if self.m_annualFields[fldStIt].m_varAvgSum == OutputProcessor.StoreType.Sum:
                                            self.m_annualFields[fldStRemainIt2].m_cell[row].result = oldScanValue + scanValue2
                                        else:
                                            self.m_annualFields[fldStRemainIt2].m_cell[row].result = oldScanValue + scanValue2 * elapsedTime
                                        self.m_annualFields[fldStRemainIt2].m_cell[row].duration += elapsedTime
                                    elif self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.minimumDuringHoursShown:
                                        if self.m_annualFields[fldStRemainIt2].m_varAvgSum == OutputProcessor.StoreType.Sum:
                                            scanValue2 /= secondsInTimeStep
                                        if scanValue2 < oldScanValue:
                                            self.m_annualFields[fldStRemainIt2].m_cell[row].result = scanValue2
                                            self.m_annualFields[fldStRemainIt2].m_cell[row].timeStamp = timestepTimeStamp
                                    elif self.m_annualFields[fldStRemainIt2].m_aggregate == AnnualFieldSet.AggregationKind.maximumDuringHoursShown:
                                        if self.m_annualFields[fldStRemainIt2].m_varAvgSum == OutputProcessor.StoreType.Sum:
                                            scanValue2 /= secondsInTimeStep
                                        if scanValue2 > oldScanValue:
                                            self.m_annualFields[fldStRemainIt2].m_cell[row].result = scanValue2
                                            self.m_annualFields[fldStRemainIt2].m_cell[row].timeStamp = timestepTimeStamp
                                activeHoursShown = False
                                fldStRemainIt2 += 1
                fldStIt += 1
            row += 1

    def resetGathering(inout self):
        var row: Int = 0
        while row < self.m_objectNames.__len__():
            for fldSt in self.m_annualFields:
                if fldSt.m_aggregate == AnnualFieldSet.AggregationKind.maximum or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.maximumDuringHoursShown:
                    fldSt.m_cell[row].result = verySmall
                elif fldSt.m_aggregate == AnnualFieldSet.AggregationKind.minimum or fldSt.m_aggregate == AnnualFieldSet.AggregationKind.minimumDuringHoursShown:
                    fldSt.m_cell[row].result = veryLarge
                else:
                    fldSt.m_cell[row].result = 0.0
                fldSt.m_cell[row].duration = 0.0
                fldSt.m_cell[row].timeStamp = 0
                fldSt.m_cell[row].deferredResults.clear()
                fldSt.m_cell[row].deferredElapsed.clear()
            row += 1

    @staticmethod
    def getElapsedTime(state: EnergyPlusData, kindOfTimeStep: OutputProcessor.TimeStepType) -> Real64:
        var elapsedTime: Real64
        if kindOfTimeStep == OutputProcessor.TimeStepType.Zone:
            elapsedTime = state.dataGlobal.TimeStepZone
        else:
            elapsedTime = state.dataHVACGlobal.TimeStepSys
        return elapsedTime

    @staticmethod
    def getSecondsInTimeStep(state: EnergyPlusData, kindOfTimeStep: OutputProcessor.TimeStepType) -> Real64:
        var secondsInTimeStep: Real64
        if kindOfTimeStep == OutputProcessor.TimeStepType.Zone:
            secondsInTimeStep = state.dataGlobal.TimeStepZoneSec
        else:
            secondsInTimeStep = state.dataHVACGlobal.TimeStepSysSec
        return secondsInTimeStep

    def writeTable(inout self, state: EnergyPlusData, style: OutputReportTabular.tabularReportStyle):
        var columnHead: Array1D_string = Array1D_string()
        var columnWidth: Array1D_int = Array1D_int()
        var rowHead: Array1D_string = Array1D_string()
        var tableBody: Array2D_string = Array2D_string()
        var aggString: List[String] = List[String]()
        var energyUnitsString: String
        var varNameWithUnits: String
        var indexUnitConv: Int
        var curVal: Real64
        var curUnits: String
        var curConversionFactor: Real64
        var curConversionOffset: Real64
        var minVal: Real64
        var maxVal: Real64
        var sumVal: Real64
        var sumDuration: Real64
        var createBinRangeTable: Bool = False
        aggString = AnnualTable.setupAggString()
        var energyUnitsConversionFactor: Real64 = AnnualTable.setEnergyUnitStringAndFactor(style.unitsStyle, energyUnitsString)
        self.computeBinColumns(state, style.unitsStyle)
        self.columnHeadersToTitleCase(state)
        var columnCount: Int = 0
        for fldStIt in self.m_annualFields:
            columnCount += AnnualTable.columnCountForAggregation(fldStIt.m_aggregate)
        columnHead.reserve(columnCount)
        for i in range(columnCount):
            columnHead.append("")
        columnWidth.reserve(columnCount)
        for i in range(columnCount):
            columnWidth.append(14)
        var rowCount: Int = self.m_objectNames.__len__() + 4
        var rowSumAvg: Int = self.m_objectNames.__len__() + 2
        var rowMin: Int = self.m_objectNames.__len__() + 3
        var rowMax: Int = self.m_objectNames.__len__() + 4
        rowHead.reserve(rowCount)
        for i in range(rowCount):
            rowHead.append("")
        var rowIdx: Int = 0
        while rowIdx < self.m_objectNames.__len__():
            rowHead[rowIdx] = self.m_objectNames[rowIdx]
            rowIdx += 1
        rowHead[rowSumAvg] = "Annual Sum or Average"
        rowHead[rowMin] = "Minimum of Rows"
        rowHead[rowMax] = "Maximum of Rows"
        tableBody.reserve(columnCount)
        for i in range(columnCount):
            var col: List[String] = List[String]()
            for j in range(rowCount):
                col.append("")
            tableBody.append(col)
        var columnRecount: Int = 0
        for fldSt in self.m_annualFields:
            var curAggString: String = aggString[fldSt.m_aggregate.__int__()]
            if not curAggString.__eq__(""):
                curAggString = " {" + AnnualTable.trim(curAggString) + "}"
            if style.unitsStyle == OutputReportTabular.UnitsStyle.InchPound or style.unitsStyle == OutputReportTabular.UnitsStyle.InchPoundExceptElectricity:
                varNameWithUnits = fldSt.m_variMeter + " [" + Constant.unitNames[fldSt.m_varUnits.__int__()] + "]"
                indexUnitConv = OutputReportTabular.LookupSItoIP(state, varNameWithUnits, curUnits)
                OutputReportTabular.GetUnitConversion(state, indexUnitConv, curConversionFactor, curConversionOffset, curUnits)
            else:
                if fldSt.m_varUnits == Constant.Units.J:
                    curUnits = energyUnitsString
                    curConversionFactor = energyUnitsConversionFactor
                    curConversionOffset = 0.0
                else:
                    curUnits = Constant.unitNames[fldSt.m_varUnits.__int__()]
                    curConversionFactor = 1.0
                    curConversionOffset = 0.0
            var curAgg: Int = fldSt.m_aggregate.__int__()
            columnRecount += AnnualTable.columnCountForAggregation(fldSt.m_aggregate)
            if curAgg == AnnualFieldSet.AggregationKind.sumOrAvg.__int__() or curAgg == AnnualFieldSet.AggregationKind.sumOrAverageHoursShown.__int__():
                columnHead[columnRecount - 1] = fldSt.m_colHead + curAggString + " [" + curUnits + "]"
                sumVal = 0.0
                sumDuration = 0.0
                minVal = veryLarge
                maxVal = verySmall
                for row in range(self.m_objectNames.__len__()):
                    if fldSt.m_cell[row].indexesForKeyVar >= 0:
                        if fldSt.m_varAvgSum == OutputProcessor.StoreType.Average:
                            if fldSt.m_cell[row].duration != 0.0:
                                curVal = ((fldSt.m_cell[row].result / fldSt.m_cell[row].duration) * curConversionFactor) + curConversionOffset
                            else:
                                curVal = 0.0
                            sumVal += (fldSt.m_cell[row].result * curConversionFactor) + curConversionOffset
                            sumDuration += fldSt.m_cell[row].duration
                        else:
                            curVal = (fldSt.m_cell[row].result * curConversionFactor) + curConversionOffset
                            sumVal += curVal
                        tableBody[columnRecount - 1][row] = OutputReportTabular.RealToStr(style.formatReals, curVal, fldSt.m_showDigits)
                        if curVal > maxVal:
                            maxVal = curVal
                        if curVal < minVal:
                            minVal = curVal
                    else:
                        tableBody[columnRecount - 1][row] = "-"
                if fldSt.m_varAvgSum == OutputProcessor.StoreType.Average:
                    if sumDuration > 0:
                        tableBody[columnRecount - 1][rowSumAvg] = OutputReportTabular.RealToStr(style.formatReals, sumVal / sumDuration, fldSt.m_showDigits)
                    else:
                        tableBody[columnRecount - 1][rowSumAvg] = ""
                else:
                    tableBody[columnRecount - 1][rowSumAvg] = OutputReportTabular.RealToStr(style.formatReals, sumVal, fldSt.m_showDigits)
                if minVal != veryLarge:
                    tableBody[columnRecount - 1][rowMax] = OutputReportTabular.RealToStr(style.formatReals, minVal, fldSt.m_showDigits)
                if maxVal != verySmall:
                    tableBody[columnRecount - 1][rowMin] = OutputReportTabular.RealToStr(style.formatReals, maxVal, fldSt.m_showDigits)
            elif curAgg == AnnualFieldSet.AggregationKind.hoursZero.__int__() or curAgg == AnnualFieldSet.AggregationKind.hoursNonZero.__int__() or curAgg == AnnualFieldSet.AggregationKind.hoursPositive.__int__() or curAgg == AnnualFieldSet.AggregationKind.hoursNonPositive.__int__() or curAgg == AnnualFieldSet.AggregationKind.hoursNegative.__int__() or curAgg == AnnualFieldSet.AggregationKind.hoursNonNegative.__int__():
                columnHead[columnRecount - 1] = fldSt.m_colHead + curAggString + " [HOURS]"
                sumVal = 0.0
                minVal = veryLarge
                maxVal = verySmall
                for row in range(self.m_objectNames.__len__()):
                    curVal = fldSt.m_cell[row].result
                    curVal = curVal * curConversionFactor + curConversionOffset
                    tableBody[columnRecount - 1][row] = OutputReportTabular.RealToStr(style.formatReals, curVal, fldSt.m_showDigits)
                    sumVal += curVal
                    if curVal > maxVal:
                        maxVal = curVal
                    if curVal < minVal:
                        minVal = curVal
                tableBody[columnRecount - 1][rowSumAvg] = OutputReportTabular.RealToStr(style.formatReals, sumVal, fldSt.m_showDigits)
                if minVal != veryLarge:
                    tableBody[columnRecount - 1][rowMax] = OutputReportTabular.RealToStr(style.formatReals, minVal, fldSt.m_showDigits)
                if maxVal != verySmall:
                    tableBody[columnRecount - 1][rowMin] = OutputReportTabular.RealToStr(style.formatReals, maxVal, fldSt.m_showDigits)
            elif curAgg == AnnualFieldSet.AggregationKind.valueWhenMaxMin.__int__():
                if fldSt.m_varAvgSum == OutputProcessor.StoreType.Sum:
                    curUnits += "/s"
                AnnualTable.fixUnitsPerSecond(curUnits, curConversionFactor)
                columnHead[columnRecount - 1] = fldSt.m_colHead + curAggString + " [" + curUnits + "]"
                minVal = veryLarge
                maxVal = verySmall
                for row in range(self.m_objectNames.__len__()):
                    curVal = fldSt.m_cell[row].result
                    curVal = curVal * curConversionFactor + curConversionOffset
                    tableBody[columnRecount - 1][row] = OutputReportTabular.RealToStr(style.formatReals, curVal, fldSt.m_showDigits)
                    if curVal > maxVal:
                        maxVal = curVal
                    if curVal < minVal:
                        minVal = curVal
                if minVal != veryLarge:
                    tableBody[columnRecount - 1][rowMin] = OutputReportTabular.RealToStr(style.formatReals, minVal, fldSt.m_showDigits)
                if maxVal != verySmall:
                    tableBody[columnRecount - 1][rowMax] = OutputReportTabular.RealToStr(style.formatReals, maxVal, fldSt.m_showDigits)
            elif curAgg == AnnualFieldSet.AggregationKind.maximum.__int__() or curAgg == AnnualFieldSet.AggregationKind.minimum.__int__() or curAgg == AnnualFieldSet.AggregationKind.maximumDuringHoursShown.__int__() or curAgg == AnnualFieldSet.AggregationKind.minimumDuringHoursShown.__int__():
                if fldSt.m_varAvgSum == OutputProcessor.StoreType.Sum:
                    curUnits += "/s"
                AnnualTable.fixUnitsPerSecond(curUnits, curConversionFactor)
                columnHead[columnRecount - 2] = fldSt.m_colHead + curAggString + " [" + curUnits + "]"
                columnHead[columnRecount - 1] = fldSt.m_colHead + " {TIMESTAMP}"
                minVal = veryLarge
                maxVal = verySmall
                for row in range(self.m_objectNames.__len__()):
                    curVal = fldSt.m_cell[row].result
                    if (curVal < veryLarge) and (curVal > verySmall):
                        curVal = curVal * curConversionFactor + curConversionOffset
                        if curVal > maxVal:
                            maxVal = curVal
                        if curVal < minVal:
                            minVal = curVal
                        if curVal < veryLarge and curVal > verySmall:
                            tableBody[columnRecount - 2][row] = OutputReportTabular.RealToStr(style.formatReals, curVal, fldSt.m_showDigits)
                        else:
                            tableBody[columnRecount - 2][row] = "-"
                        tableBody[columnRecount - 1][row] = OutputReportTabular.DateToString(fldSt.m_cell[row].timeStamp)
                    else:
                        tableBody[columnRecount - 2][row] = "-"
                        tableBody[columnRecount - 1][row] = "-"
                if minVal < veryLarge:
                    tableBody[columnRecount - 2][rowMin] = OutputReportTabular.RealToStr(style.formatReals, minVal, fldSt.m_showDigits)
                else:
                    tableBody[columnRecount - 2][rowMin] = "-"
                if maxVal > verySmall:
                    tableBody[columnRecount - 2][rowMax] = OutputReportTabular.RealToStr(style.formatReals, maxVal, fldSt.m_showDigits)
                else:
                    tableBody[columnRecount - 2][rowMax] = "-"
            elif curAgg == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToMax.__int__():
                if fldSt.m_varAvgSum == OutputProcessor.StoreType.Sum:
                    curUnits += "/s"
                AnnualTable.fixUnitsPerSecond(curUnits, curConversionFactor)
                for iBin in range(10):
                    var binIndicator: String = chr(iBin + 65)
                    columnHead[columnRecount - 10 + iBin] = fldSt.m_colHead + curAggString + " BIN " + binIndicator
                    for row in range(self.m_objectNames.__len__()):
                        tableBody[columnRecount - 10 + iBin][row] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_cell[row].m_timeInBin[iBin], fldSt.m_showDigits)
                    tableBody[columnRecount - 10 + iBin][rowSumAvg] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_timeInBinTotal[iBin], fldSt.m_showDigits)
                createBinRangeTable = True
            elif curAgg == AnnualFieldSet.AggregationKind.hoursInTenBinsZeroToMax.__int__():
                if fldSt.m_varAvgSum == OutputProcessor.StoreType.Sum:
                    curUnits += "/s"
                AnnualTable.fixUnitsPerSecond(curUnits, curConversionFactor)
                for iBin in range(10):
                    var binIndicator: String = chr(iBin + 65)
                    columnHead[columnRecount - 10 + iBin] = fldSt.m_colHead + curAggString + " BIN " + binIndicator
                    for row in range(self.m_objectNames.__len__()):
                        tableBody[columnRecount - 10 + iBin][row] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_cell[row].m_timeInBin[iBin], fldSt.m_showDigits)
                    tableBody[columnRecount - 10 + iBin][rowSumAvg] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_timeInBinTotal[iBin], fldSt.m_showDigits)
                columnHead[columnRecount - 11] = fldSt.m_colHead + curAggString + " LESS THAN BIN A"
                for row in range(self.m_objectNames.__len__()):
                    tableBody[columnRecount - 11][row] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_cell[row].m_timeBelowBottomBin, fldSt.m_showDigits)
                tableBody[columnRecount - 11][rowSumAvg] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_timeBelowBottomBinTotal, fldSt.m_showDigits)
                createBinRangeTable = True
            elif curAgg == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToZero.__int__():
                if fldSt.m_varAvgSum == OutputProcessor.StoreType.Sum:
                    curUnits += "/s"
                AnnualTable.fixUnitsPerSecond(curUnits, curConversionFactor)
                for iBin in range(10):
                    var binIndicator: String = chr(iBin + 65)
                    columnHead[columnRecount - 11 + iBin] = fldSt.m_colHead + curAggString + " BIN " + binIndicator
                    for row in range(self.m_objectNames.__len__()):
                        tableBody[columnRecount - 11 + iBin][row] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_cell[row].m_timeInBin[iBin], fldSt.m_showDigits)
                    tableBody[columnRecount - 11 + iBin][rowSumAvg] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_timeInBinTotal[iBin], fldSt.m_showDigits)
                columnHead[columnRecount - 1] = fldSt.m_colHead + curAggString + " MORE THAN BIN J"
                for row in range(self.m_objectNames.__len__()):
                    tableBody[columnRecount - 1][row] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_cell[row].m_timeAboveTopBin, fldSt.m_showDigits)
                tableBody[columnRecount - 1][rowSumAvg] = OutputReportTabular.RealToStr(style.formatReals, fldSt.m_timeAboveTopBinTotal, fldSt.m_showDigits)
                createBinRangeTable = True
        if style.produceTabular:
            OutputReportTabular.WriteReportHeaders(state, self.m_name, "Entire Facility", OutputProcessor.StoreType.Average)
            OutputReportTabular.WriteSubtitle(state, "Custom Annual Report")
            OutputReportTabular.WriteTable(state, tableBody, rowHead, columnHead, columnWidth, True)
        if style.produceJSON:
            if state.dataResultsFramework.resultsFramework.timeSeriesAndTabularEnabled():
                state.dataResultsFramework.resultsFramework.TabularReportsCollection.addReportTable(tableBody, rowHead, columnHead, self.m_name, "Entire Facility", "Custom Annual Report")
        if style.produceSQLite:
            if state.dataSQLiteProcedures.sqlite:
                state.dataSQLiteProcedures.sqlite.createSQLiteTabularDataRecords(tableBody, rowHead, columnHead, self.m_name, "Entire Facility", "Custom Annual Report")
        if createBinRangeTable:
            var colHeadRange: Array1D_string = Array1D_string()
            var colWidthRange: Array1D_int = Array1D_int()
            var rowHeadRange: Array1D_string = Array1D_string()
            var tableBodyRange: Array2D_string = Array2D_string()
            colHeadRange.reserve(10)
            for i in range(10):
                colHeadRange.append("")
            colWidthRange.reserve(10)
            for i in range(10):
                colWidthRange.append(14)
            rowHeadRange.reserve(2)
            rowHeadRange.append("")
            rowHeadRange.append("")
            rowHeadRange[0] = ">="
            rowHeadRange[1] = "<"
            tableBodyRange.reserve(10)
            for i in range(10):
                var col: List[String] = List[String]()
                for j in range(2):
                    col.append("")
                tableBodyRange.append(col)
            for fldStIt in self.m_annualFields:
                if fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToMax or fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsZeroToMax or fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToZero:
                    var binBottom: Real64 = fldStIt.m_bottomBinValue
                    var binTop: Real64 = fldStIt.m_topBinValue
                    var numBins: Int = 10
                    var intervalSize: Real64 = 0.0 if (binBottom == veryLarge) and (binTop == verySmall) else ((binTop - binBottom) / numBins)
                    for iBin in range(numBins):
                        var binLetter: String = chr(65 + iBin)
                        colHeadRange[iBin] = "BIN " + binLetter
                    for iBin in range(numBins):
                        var lo: Real64 = binBottom + iBin * intervalSize
                        var hi: Real64 = binBottom + (iBin + 1) * intervalSize
                        tableBodyRange[iBin][0] = OutputReportTabular.RealToStr(style.formatReals, lo, fldStIt.m_showDigits)
                        tableBodyRange[iBin][1] = OutputReportTabular.RealToStr(style.formatReals, hi, fldStIt.m_showDigits)
                    if style.produceTabular:
                        OutputReportTabular.WriteSubtitle(state, "Bin Sizes for: " + fldStIt.m_colHead)
                        OutputReportTabular.WriteTable(state, tableBodyRange, rowHeadRange, colHeadRange, colWidthRange, True)
                    if style.produceSQLite:
                        if state.dataSQLiteProcedures.sqlite:
                            state.dataSQLiteProcedures.sqlite.createSQLiteTabularDataRecords(tableBodyRange, rowHeadRange, colHeadRange, self.m_name, "Entire Facility", "Bin Sizes")
                    if style.produceJSON:
                        if state.dataResultsFramework.resultsFramework.timeSeriesAndTabularEnabled():
                            state.dataResultsFramework.resultsFramework.TabularReportsCollection.addReportTable(tableBodyRange, rowHeadRange, colHeadRange, self.m_name, "Entire Facility", "Bin Sizes")

    @staticmethod
    def setupAggString() -> List[String]:
        var retStringVec: List[String] = List[String]()
        retStringVec.reserve(20)
        for i in range(20):
            retStringVec.append("")
        retStringVec[AnnualFieldSet.AggregationKind.sumOrAvg.__int__()] = ""
        retStringVec[AnnualFieldSet.AggregationKind.maximum.__int__()] = " MAXIMUM "
        retStringVec[AnnualFieldSet.AggregationKind.minimum.__int__()] = " MINIMUM "
        retStringVec[AnnualFieldSet.AggregationKind.valueWhenMaxMin.__int__()] = " AT MAX/MIN "
        retStringVec[AnnualFieldSet.AggregationKind.hoursZero.__int__()] = " HOURS ZERO "
        retStringVec[AnnualFieldSet.AggregationKind.hoursNonZero.__int__()] = " HOURS NON-ZERO "
        retStringVec[AnnualFieldSet.AggregationKind.hoursPositive.__int__()] = " HOURS POSITIVE "
        retStringVec[AnnualFieldSet.AggregationKind.hoursNonPositive.__int__()] = " HOURS NON-POSITIVE "
        retStringVec[AnnualFieldSet.AggregationKind.hoursNegative.__int__()] = " HOURS NEGATIVE "
        retStringVec[AnnualFieldSet.AggregationKind.hoursNonNegative.__int__()] = " HOURS NON-NEGATIVE "
        retStringVec[AnnualFieldSet.AggregationKind.hoursInTenPercentBins.__int__()] = " HOURS IN"
        retStringVec[AnnualFieldSet.AggregationKind.hoursInTenBinsMinToMax.__int__()] = " HOURS IN"
        retStringVec[AnnualFieldSet.AggregationKind.hoursInTenBinsZeroToMax.__int__()] = " HOURS IN"
        retStringVec[AnnualFieldSet.AggregationKind.hoursInTenBinsMinToZero.__int__()] = " HOURS IN"
        retStringVec[AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusTwoStdDev.__int__()] = " HOURS IN"
        retStringVec[AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusThreeStdDev.__int__()] = " HOURS IN"
        retStringVec[AnnualFieldSet.AggregationKind.noAggregation.__int__()] = " NO AGGREGATION "
        retStringVec[AnnualFieldSet.AggregationKind.sumOrAverageHoursShown.__int__()] = " FOR HOURS SHOWN "
        retStringVec[AnnualFieldSet.AggregationKind.maximumDuringHoursShown.__int__()] = " MAX FOR HOURS SHOWN "
        retStringVec[AnnualFieldSet.AggregationKind.minimumDuringHoursShown.__int__()] = " MIN FOR HOURS SHOWN "
        return retStringVec

    @staticmethod
    def setEnergyUnitStringAndFactor(unitsStyle: OutputReportTabular.UnitsStyle, inout unitString: String) -> Real64:
        var convFactor: Real64 = 1.0
        unitString = "J"
        if unitsStyle == OutputReportTabular.UnitsStyle.JtoKWH:
            unitString = "kWh"
            convFactor = 1.0 / 3600000.0
        elif unitsStyle == OutputReportTabular.UnitsStyle.JtoMJ:
            unitString = "MJ"
            convFactor = 1.0 / 1000000.0
        elif unitsStyle == OutputReportTabular.UnitsStyle.JtoGJ:
            unitString = "GJ"
            convFactor = 1.0 / 1000000000.0
        elif unitsStyle == OutputReportTabular.UnitsStyle.None:

        return convFactor

    @staticmethod
    def fixUnitsPerSecond(inout unitString: String, inout conversionFactor: Real64):
        if unitString == "J/s":
            unitString = "W"
        elif unitString == "kWh/s":
            unitString = "W"
            conversionFactor *= 3600000.0
        elif unitString == "GJ/s":
            unitString = "kW"
            conversionFactor *= 1000000.0
        elif unitString == "MJ/s":
            unitString = "kW"
            conversionFactor *= 1000.0
        elif unitString == "therm/s":
            unitString = "kBtu/h"
            conversionFactor *= 360000.0
        elif unitString == "kBtu/s":
            unitString = "kBtu/h"
            conversionFactor *= 3600.0
        elif unitString == "ton-hrs/s":
            unitString = "ton"
            conversionFactor *= 3600.0

    @staticmethod
    def columnCountForAggregation(curAgg: AnnualFieldSet.AggregationKind) -> Int:
        if curAgg == AnnualFieldSet.AggregationKind.sumOrAvg or curAgg == AnnualFieldSet.AggregationKind.valueWhenMaxMin or curAgg == AnnualFieldSet.AggregationKind.hoursZero or curAgg == AnnualFieldSet.AggregationKind.hoursNonZero or curAgg == AnnualFieldSet.AggregationKind.hoursPositive or curAgg == AnnualFieldSet.AggregationKind.hoursNonPositive or curAgg == AnnualFieldSet.AggregationKind.hoursNegative or curAgg == AnnualFieldSet.AggregationKind.hoursNonNegative or curAgg == AnnualFieldSet.AggregationKind.sumOrAverageHoursShown or curAgg == AnnualFieldSet.AggregationKind.noAggregation:
            return 1
        elif curAgg == AnnualFieldSet.AggregationKind.maximum or curAgg == AnnualFieldSet.AggregationKind.minimum or curAgg == AnnualFieldSet.AggregationKind.maximumDuringHoursShown or curAgg == AnnualFieldSet.AggregationKind.minimumDuringHoursShown:
            return 2
        elif curAgg == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToMax:
            return 10
        elif curAgg == AnnualFieldSet.AggregationKind.hoursInTenBinsZeroToMax or curAgg == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToZero:
            return 11
        elif curAgg == AnnualFieldSet.AggregationKind.hoursInTenPercentBins or curAgg == AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusTwoStdDev or curAgg == AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusThreeStdDev:
            return 12
        else:
            return 0

    @staticmethod
    def trim(str: String) -> String:
        var whitespace: String = " \t"
        var strBegin: Int = str.find_first_not_of(whitespace)
        if strBegin == -1:
            return ""
        var strEnd: Int = str.find_last_not_of(whitespace)
        var strRange: Int = strEnd - strBegin + 1
        return str.substr(strBegin, strRange)

    def addTableOfContents(self, nameOfStream: __import__("io").StringIO):
        nameOfStream.write("<p><b>" + self.m_name + "</b></p> |\n")
        nameOfStream.write("<a href=\"#" + OutputReportTabular.MakeAnchorName(self.m_name, "Entire Facility") + "\">" + "Entire Facility" + "</a>    |   \n")

    def computeBinColumns(inout self, state: EnergyPlusData, unitsStyle_para: OutputReportTabular.UnitsStyle):
        for fldStIt in self.m_annualFields:
            if fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToMax or fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsZeroToMax or fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToZero or fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenPercentBins or fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusTwoStdDev or fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusThreeStdDev:
                if not self.allRowsSameSizeDeferredVectors(fldStIt):
                    break
                self.convertUnitForDeferredResults(state, fldStIt, unitsStyle_para)
                var deferredTotalForColumn: List[Real64] = List[Real64]()
                var minVal: Real64 = veryLarge
                var maxVal: Real64 = verySmall
                var sum: Real64 = 0
                var curVal: Real64 = 0.0
                for jDefRes in range(fldStIt.m_cell[0].deferredResults.__len__()):
                    sum = 0
                    for row in range(self.m_objectNames.__len__()):
                        curVal = fldStIt.m_cell[row].deferredResults[jDefRes]
                        sum += curVal
                        if curVal > maxVal:
                            maxVal = curVal
                        if curVal < minVal:
                            minVal = curVal
                    deferredTotalForColumn.append(sum / self.m_objectNames.__len__())
                if fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToMax:
                    fldStIt.m_topBinValue = maxVal
                    fldStIt.m_bottomBinValue = minVal
                elif fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsZeroToMax:
                    fldStIt.m_topBinValue = maxVal
                    fldStIt.m_bottomBinValue = 0.0
                elif fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenBinsMinToZero:
                    fldStIt.m_topBinValue = 0.0
                    fldStIt.m_bottomBinValue = minVal
                elif fldStIt.m_aggregate == AnnualFieldSet.AggregationKind.hoursInTenPercentBins:
                    fldStIt.m_topBinValue = 1.0
                    fldStIt.m_bottomBinValue = 0.0
                for row in range(self.m_objectNames.__len__()):
                    fldStIt.m_cell[row].m_timeInBin = AnnualTable.calculateBins(10, fldStIt.m_cell[row].deferredResults, fldStIt.m_cell[row].deferredElapsed, fldStIt.m_topBinValue, fldStIt.m_bottomBinValue, fldStIt.m_cell[row].m_timeAboveTopBin, fldStIt.m_cell[row].m_timeBelowBottomBin)
                fldStIt.m_timeInBinTotal = AnnualTable.calculateBins(10, deferredTotalForColumn, fldStIt.m_cell[0].deferredElapsed, fldStIt.m_topBinValue, fldStIt.m_bottomBinValue, fldStIt.m_timeAboveTopBinTotal, fldStIt.m_timeBelowBottomBinTotal)

    def allRowsSameSizeDeferredVectors(self, fldSt: AnnualFieldSet) -> Bool:
        var returnFlag: Bool = True
        var sizeOfDeferred: Int = 0
        for row in range(self.m_objectNames.__len__()):
            if sizeOfDeferred == 0:
                sizeOfDeferred = fldSt.m_cell[row].deferredResults.__len__()
            else:
                if fldSt.m_cell[row].deferredResults.__len__() != sizeOfDeferred:
                    returnFlag = False
                    return returnFlag
        return returnFlag

    def convertUnitForDeferredResults(self, state: EnergyPlusData, inout fldSt: AnnualFieldSet, unitsStyle: OutputReportTabular.UnitsStyle):
        var curConversionFactor: Real64
        var curConversionOffset: Real64
        var curUnits: String
        var energyUnitsString: String
        var energyUnitsConversionFactor: Real64 = AnnualTable.setEnergyUnitStringAndFactor(unitsStyle, energyUnitsString)
        if unitsStyle == OutputReportTabular.UnitsStyle.InchPound or unitsStyle == OutputReportTabular.UnitsStyle.InchPoundExceptElectricity:
            var indexUnitConv: Int
            var varNameWithUnits: String = fldSt.m_variMeter + " [" + Constant.unitNames[fldSt.m_varUnits.__int__()] + "]"
            indexUnitConv = OutputReportTabular.LookupSItoIP(state, varNameWithUnits, curUnits)
            OutputReportTabular.GetUnitConversion(state, indexUnitConv, curConversionFactor, curConversionOffset, curUnits)
        else:
            if fldSt.m_varUnits == Constant.Units.J:
                curUnits = energyUnitsString
                curConversionFactor = energyUnitsConversionFactor
                curConversionOffset = 0.0
            else:
                curUnits = Constant.unitNames[fldSt.m_varUnits.__int__()]
                curConversionFactor = 1.0
                curConversionOffset = 0.0
        if fldSt.m_varAvgSum == OutputProcessor.StoreType.Sum:
            curUnits += "/s"
        AnnualTable.fixUnitsPerSecond(curUnits, curConversionFactor)
        if curConversionFactor != 1.0 or curConversionOffset != 0.0:
            for row in range(self.m_objectNames.__len__()):
                for jDefRes in range(fldSt.m_cell[0].deferredResults.__len__()):
                    var curSI: Real64 = fldSt.m_cell[row].deferredResults[jDefRes]
                    var curIP: Real64 = curSI * curConversionFactor + curConversionOffset
                    fldSt.m_cell[row].deferredResults[jDefRes] = curIP

    @staticmethod
    def calculateBins(numberOfBins: Int, valuesToBin: List[Real64], corrElapsedTime: List[Real64], topOfBins: Real64, bottomOfBins: Real64, inout timeAboveTopBin: Real64, inout timeBelowBottomBin: Real64) -> List[Real64]:
        if numberOfBins <= 0:
            return List[Real64]()
        var returnBins: List[Real64] = List[Real64]()
        for i in range(numberOfBins):
            returnBins.append(0.0)
        timeAboveTopBin = 0.0
        timeBelowBottomBin = 0.0
        if valuesToBin.__len__() == 0:
            return returnBins
        var intervalSize: Real64 = (topOfBins - bottomOfBins) / numberOfBins
        var elapsedTimeIt: Int = 0
        for valueIt in valuesToBin:
            if valueIt < bottomOfBins:
                timeBelowBottomBin += corrElapsedTime[elapsedTimeIt]
            elif valueIt >= topOfBins:
                timeAboveTopBin += corrElapsedTime[elapsedTimeIt]
            else:
                var binNum: Int = int((valueIt - bottomOfBins) / intervalSize)
                if binNum < numberOfBins and binNum >= 0:
                    returnBins[binNum] += corrElapsedTime[elapsedTimeIt]
            elapsedTimeIt += 1
        return returnBins

    def columnHeadersToTitleCase(self, state: EnergyPlusData):
        for fldSt in self.m_annualFields:
            if fldSt.m_variMeter == fldSt.m_colHead:
                if not fldSt.m_indexesForKeyVar.__len__() == 0:
                    var varNum: Int = fldSt.m_indexesForKeyVar[0]
                    if fldSt.m_typeOfVar == OutputProcessor.VariableType.Real:
                        fldSt.m_colHead = state.dataOutputProcessor.outVars[varNum].name
                    elif fldSt.m_typeOfVar == OutputProcessor.VariableType.Meter:
                        fldSt.m_colHead = state.dataOutputProcessor.meters[varNum].Name

    def clearTable(inout self):
        self.m_name = ""
        self.m_filter = ""
        self.m_sched = None
        self.m_objectNames.clear()
        self.m_annualFields.clear()

    def inspectTable(self) -> List[String]:
        var ret: List[String] = List[String]()
        ret.append(self.m_name)
        ret.append(self.m_filter)
        ret.append(self.m_sched.value.Name)
        return ret

    def inspectTableFieldSets(self, fldIndex: Int) -> List[String]:
        var fldSt: AnnualFieldSet = self.m_annualFields[fldIndex]
        var ret: List[String] = List[String]()
        var hasCell: Bool = not fldSt.m_cell.__len__() == 0
        ret.reserve(14 if hasCell else 13)
        ret.append(fldSt.m_colHead)
        ret.append(fldSt.m_variMeter)
        ret.append(Constant.unitNames[fldSt.m_varUnits.__int__()])
        var outStr: String = str(fldSt.m_showDigits)
        ret.append(outStr)
        outStr = str(fldSt.m_typeOfVar.__int__())
        ret.append(outStr)
        outStr = str(fldSt.m_keyCount)
        ret.append(outStr)
        outStr = str(fldSt.m_varAvgSum.__int__())
        ret.append(outStr)
        outStr = str(fldSt.m_varStepType.__int__())
        ret.append(outStr)
        outStr = str(fldSt.m_aggregate.__int__())
        ret.append(outStr)
        outStr = str(fldSt.m_bottomBinValue)
        ret.append(outStr)
        outStr = str(fldSt.m_topBinValue)
        ret.append(outStr)
        outStr = str(fldSt.m_timeAboveTopBinTotal)
        ret.append(outStr)
        outStr = str(fldSt.m_timeBelowBottomBinTotal)
        ret.append(outStr)
        if hasCell:
            outStr = str(fldSt.m_cell[0].result)
            ret.append(outStr)
        return ret

var veryLarge: Real64 = Float64.MAX
var verySmall: Real64 = Float64.MIN

def GetInputTabularAnnual(state: EnergyPlusData):
    var currentModuleObject: String = "Output:Table:Annual"
    var numParams: Int = 0
    var numAlphas: Int = 0
    var numNums: Int = 0
    var alphArray: Array1D_string = Array1D_string()
    var numArray: Array1D_Real64 = Array1D_Real64()
    var IOStat: Int = 0
    var objCount: Int = 0
    var curAgg: AnnualFieldSet.AggregationKind = AnnualFieldSet.AggregationKind.sumOrAvg
    var annualTables = state.dataOutputReportTabularAnnual.annualTables
    objCount = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, currentModuleObject)
    if objCount > 0:
        state.dataOutRptTab.WriteTabularFiles = True
        if not state.dataGlobal.DoWeathSim:
            ShowWarningError(state, currentModuleObject + " requested with SimulationControl Run Simulation for Weather File Run Periods set to No so " + currentModuleObject + " will not be generated")
            return
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, currentModuleObject, numParams, numAlphas, numNums)
    for i in range(numAlphas):
        alphArray.append("")
    for i in range(numNums):
        numArray.append(0.0)
    for tabNum in range(1, objCount + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, currentModuleObject, tabNum, alphArray, numAlphas, numArray, numNums, IOStat)
        if numAlphas >= 5:
            annualTables.append(AnnualTable(state, alphArray[0], alphArray[1], alphArray[2]))
            for jAlpha in range(3, numAlphas, 2):
                var curVarMtr: String = alphArray[jAlpha]
                if curVarMtr.__eq__(""):
                    ShowWarningError(state, currentModuleObject + ": Blank column specified in '" + alphArray[0] + "', need to provide a variable or meter or EMS variable name ")
                if jAlpha < numAlphas:
                    var aggregationString: String = alphArray[jAlpha + 1]
                    curAgg = stringToAggKind(state, aggregationString)
                else:
                    curAgg = AnnualFieldSet.AggregationKind.sumOrAvg
                var indexNums: Int = 1 + (jAlpha - 2) / 2
                var curNumDgts: Int
                if indexNums < numNums:
                    curNumDgts = numArray[indexNums]
                else:
                    curNumDgts = 2
                if not curVarMtr.__eq__(""):
                    annualTables[annualTables.__len__() - 1].addFieldSet(curVarMtr, curAgg, curNumDgts)
            annualTables[annualTables.__len__() - 1].setupGathering(state)
        else:
            ShowSevereError(state, currentModuleObject + ": Must enter at least the first six fields.")

def checkAggregationOrderForAnnual(state: EnergyPlusData):
    var invalidAggregationOrderFound: Bool = False
    var annualTables = state.dataOutputReportTabularAnnual.annualTables
    if not state.dataGlobal.DoWeathSim:
        return
    for annualTable in annualTables:
        if annualTable.invalidAggregationOrder(state):
            invalidAggregationOrderFound = True
    if invalidAggregationOrderFound:
        ShowFatalError(state, "OutputReportTabularAnnual: Invalid aggregations detected, no simulation performed.")

def GatherAnnualResultsForTimeStep(state: EnergyPlusData, kindOfTimeStep: OutputProcessor.TimeStepType):
    var annualTables = state.dataOutputReportTabularAnnual.annualTables
    for annualTable in annualTables:
        annualTable.gatherForTimestep(state, kindOfTimeStep)

def ResetAnnualGathering(state: EnergyPlusData):
    var annualTables = state.dataOutputReportTabularAnnual.annualTables
    for annualTable in annualTables:
        annualTable.resetGathering()

def WriteAnnualTables(state: EnergyPlusData):
    var annualTables = state.dataOutputReportTabularAnnual.annualTables
    for currentStyle in state.dataOutRptTab.tabularReportPasses:
        for annualTable in annualTables:
            annualTable.writeTable(state, currentStyle)

def AddAnnualTableOfContents(state: EnergyPlusData, nameOfStream: __import__("io").StringIO):
    var annualTables = state.dataOutputReportTabularAnnual.annualTables
    for annualTable in annualTables:
        annualTable.addTableOfContents(nameOfStream)

def stringToAggKind(state: EnergyPlusData, inString: String) -> AnnualFieldSet.AggregationKind:
    var outAggType: AnnualFieldSet.AggregationKind
    if Util_SameString(inString, "SumOrAverage"):
        outAggType = AnnualFieldSet.AggregationKind.sumOrAvg
    elif Util_SameString(inString, "Maximum"):
        outAggType = AnnualFieldSet.AggregationKind.maximum
    elif Util_SameString(inString, "Minimum"):
        outAggType = AnnualFieldSet.AggregationKind.minimum
    elif Util_SameString(inString, "ValueWhenMaximumOrMinimum"):
        outAggType = AnnualFieldSet.AggregationKind.valueWhenMaxMin
    elif Util_SameString(inString, "HoursZero"):
        outAggType = AnnualFieldSet.AggregationKind.hoursZero
    elif Util_SameString(inString, "HoursNonzero"):
        outAggType = AnnualFieldSet.AggregationKind.hoursNonZero
    elif Util_SameString(inString, "HoursPositive"):
        outAggType = AnnualFieldSet.AggregationKind.hoursPositive
    elif Util_SameString(inString, "HoursNonpositive"):
        outAggType = AnnualFieldSet.AggregationKind.hoursNonPositive
    elif Util_SameString(inString, "HoursNegative"):
        outAggType = AnnualFieldSet.AggregationKind.hoursNegative
    elif Util_SameString(inString, "HoursNonNegative"):
        outAggType = AnnualFieldSet.AggregationKind.hoursNonNegative
    elif Util_SameString(inString, "HoursInTenPercentBins"):
        outAggType = AnnualFieldSet.AggregationKind.hoursInTenPercentBins
    elif Util_SameString(inString, "HourInTenBinsMinToMax"):
        outAggType = AnnualFieldSet.AggregationKind.hoursInTenBinsMinToMax
    elif Util_SameString(inString, "HourInTenBinsZeroToMax"):
        outAggType = AnnualFieldSet.AggregationKind.hoursInTenBinsZeroToMax
    elif Util_SameString(inString, "HourInTenBinsMinToZero"):
        outAggType = AnnualFieldSet.AggregationKind.hoursInTenBinsMinToZero
    elif Util_SameString(inString, "HoursInTenBinsPlusMinusTwoStdDev"):
        outAggType = AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusTwoStdDev
    elif Util_SameString(inString, "HoursInTenBinsPlusMinusThreeStdDev"):
        outAggType = AnnualFieldSet.AggregationKind.hoursInTenBinsPlusMinusThreeStdDev
    elif Util_SameString(inString, "NoAggregation"):
        outAggType = AnnualFieldSet.AggregationKind.noAggregation
    elif Util_SameString(inString, "SumOrAverageDuringHoursShown"):
        outAggType = AnnualFieldSet.AggregationKind.sumOrAverageHoursShown
    elif Util_SameString(inString, "MaximumDuringHoursShown"):
        outAggType = AnnualFieldSet.AggregationKind.maximumDuringHoursShown
    elif Util_SameString(inString, "MinimumDuringHoursShown"):
        outAggType = AnnualFieldSet.AggregationKind.minimumDuringHoursShown
    else:
        outAggType = AnnualFieldSet.AggregationKind.sumOrAvg
        ShowWarningError(state, "Invalid aggregation type=\"" + inString + "\"  Defaulting to SumOrAverage.")
    return outAggType

struct OutputReportTabularAnnualData(BaseGlobalStruct):
    var annualTables: List[AnnualTable] = List[AnnualTable]()
    def init_constant_state(self, state: EnergyPlusData):

    def init_state(self, state: EnergyPlusData):

    def clear_state(self):
        self.annualTables.clear()