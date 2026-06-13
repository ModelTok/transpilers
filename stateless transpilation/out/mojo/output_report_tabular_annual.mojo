from collections.abc import Callable
from typing import Optional
import math

alias Real64 = Float64

var VERY_LARGE = math.inf
var VERY_SMALL = -math.inf


@export
struct AggregationKind:
    alias sumOrAvg = 0
    alias maximum = 1
    alias minimum = 2
    alias valueWhenMaxMin = 3
    alias hoursZero = 4
    alias hoursNonZero = 5
    alias hoursPositive = 6
    alias hoursNonPositive = 7
    alias hoursNegative = 8
    alias hoursNonNegative = 9
    alias hoursInTenPercentBins = 10
    alias hoursInTenBinsMinToMax = 11
    alias hoursInTenBinsZeroToMax = 12
    alias hoursInTenBinsMinToZero = 13
    alias hoursInTenBinsPlusMinusTwoStdDev = 14
    alias hoursInTenBinsPlusMinusThreeStdDev = 15
    alias noAggregation = 16
    alias sumOrAverageHoursShown = 17
    alias maximumDuringHoursShown = 18
    alias minimumDuringHoursShown = 19


struct CellData:
    var result: Real64
    var duration: Real64
    var timeStamp: Int32
    var indexesForKeyVar: Int32
    var deferredResults: DynamicVector[Real64]
    var deferredElapsed: DynamicVector[Real64]
    var m_timeInBin: InlineArray[Real64, 10]
    var m_timeAboveTopBin: Real64
    var m_timeBelowBottomBin: Real64

    fn __init__(inout self):
        self.result = 0.0
        self.duration = 0.0
        self.timeStamp = 0
        self.indexesForKeyVar = -1
        self.deferredResults = DynamicVector[Real64]()
        self.deferredElapsed = DynamicVector[Real64]()
        self.m_timeInBin = InlineArray[Real64, 10](fill=0.0)
        self.m_timeAboveTopBin = 0.0
        self.m_timeBelowBottomBin = 0.0


struct AnnualFieldSet:
    var m_variMeter: String
    var m_colHead: String
    var m_aggregate: Int32
    var m_cell: DynamicVector[CellData]
    var m_namesOfKeys: DynamicVector[String]
    var m_indexesForKeyVar: DynamicVector[Int32]
    var m_typeOfVar: UInt8
    var m_varAvgSum: UInt8
    var m_varStepType: UInt8
    var m_varUnits: UInt8
    var m_keyCount: Int32
    var m_showDigits: Int32
    var m_timeInBinTotal: InlineArray[Real64, 10]
    var m_timeAboveTopBinTotal: Real64
    var m_timeBelowBottomBinTotal: Real64
    var m_topBinValue: Real64
    var m_bottomBinValue: Real64

    fn __init__(inout self, varName: String, aggKind: Int32, dgts: Int32):
        self.m_variMeter = varName
        self.m_colHead = varName
        self.m_aggregate = aggKind
        self.m_showDigits = dgts
        self.m_cell = DynamicVector[CellData]()
        self.m_namesOfKeys = DynamicVector[String]()
        self.m_indexesForKeyVar = DynamicVector[Int32]()
        self.m_typeOfVar = 0
        self.m_varAvgSum = 0
        self.m_varStepType = 0
        self.m_varUnits = 0
        self.m_keyCount = 0
        self.m_timeInBinTotal = InlineArray[Real64, 10](fill=0.0)
        self.m_timeAboveTopBinTotal = 0.0
        self.m_timeBelowBottomBinTotal = 0.0
        self.m_topBinValue = VERY_SMALL
        self.m_bottomBinValue = VERY_LARGE


struct AnnualTable:
    var m_name: String
    var m_filter: String
    var m_sched: UnsafePointer[UInt8]
    var m_objectNames: DynamicVector[String]
    var m_annualFields: DynamicVector[AnnualFieldSet]

    fn __init__(inout self, name: String = "", filter_str: String = ""):
        self.m_name = name
        self.m_filter = filter_str
        self.m_sched = UnsafePointer[UInt8]()
        self.m_objectNames = DynamicVector[String]()
        self.m_annualFields = DynamicVector[AnnualFieldSet]()

    fn addFieldSet(inout self, varName: String, aggKind: Int32, dgts: Int32):
        var field_set = AnnualFieldSet(varName, aggKind, dgts)
        self.m_annualFields.push_back(field_set)

    fn addFieldSet(inout self, varName: String, colName: String, aggKind: Int32, dgts: Int32):
        var field_set = AnnualFieldSet(varName, aggKind, dgts)
        field_set.m_colHead = colName
        self.m_annualFields.push_back(field_set)

    fn setupGathering(inout self, state: UnsafePointer[UInt8]):
        var filter_field_upper = self.m_filter
        @always_inline
        fn to_upper_inline(s: String) -> String:
            var result = String()
            for c in s:
                if c >= ord("a") and c <= ord("z"):
                    result.append(chr(c - 32))
                else:
                    result.append(c)
            return result
        
        filter_field_upper = to_upper_inline(filter_field_upper)
        var use_filter = len(self.m_filter) > 0
        var all_keys = DynamicVector[String]()

        for i in range(len(self.m_annualFields)):
            pass

        var unique_keys = DynamicVector[String]()
        for i in range(len(all_keys)):
            var found = False
            for j in range(len(unique_keys)):
                if all_keys[i] == unique_keys[j]:
                    found = True
                    break
            if not found:
                unique_keys.push_back(all_keys[i])

        for i in range(len(self.m_annualFields)):
            for j in range(len(self.m_objectNames)):
                self.m_annualFields[i].m_cell.push_back(CellData())

        for table_row_index in range(len(self.m_objectNames)):
            for i in range(len(self.m_annualFields)):
                var found_key_index = -1
                for j in range(len(self.m_annualFields[i].m_namesOfKeys)):
                    if self.m_annualFields[i].m_namesOfKeys[j] == self.m_objectNames[table_row_index]:
                        found_key_index = j
                        break

                if found_key_index >= 0:
                    self.m_annualFields[i].m_cell[table_row_index].indexesForKeyVar = (
                        self.m_annualFields[i].m_indexesForKeyVar[found_key_index]
                    )
                else:
                    self.m_annualFields[i].m_cell[table_row_index].indexesForKeyVar = -1

                if self.m_annualFields[i].m_aggregate == AggregationKind.maximum or (
                    self.m_annualFields[i].m_aggregate == AggregationKind.maximumDuringHoursShown
                ):
                    self.m_annualFields[i].m_cell[table_row_index].result = VERY_SMALL
                elif self.m_annualFields[i].m_aggregate == AggregationKind.minimum or (
                    self.m_annualFields[i].m_aggregate == AggregationKind.minimumDuringHoursShown
                ):
                    self.m_annualFields[i].m_cell[table_row_index].result = VERY_LARGE
                else:
                    self.m_annualFields[i].m_cell[table_row_index].result = 0.0

                self.m_annualFields[i].m_cell[table_row_index].duration = 0.0
                self.m_annualFields[i].m_cell[table_row_index].timeStamp = 0

    fn invalidAggregationOrder(self, state: UnsafePointer[UInt8]) -> Bool:
        var found_min_or_max = False
        var found_hour_agg = False
        var missing_max_or_min_error = False
        var missing_hour_agg_error = False

        for i in range(len(self.m_annualFields)):
            if self.m_annualFields[i].m_aggregate == AggregationKind.maximum or (
                self.m_annualFields[i].m_aggregate == AggregationKind.minimum
            ):
                found_min_or_max = True
            elif self.m_annualFields[i].m_aggregate == AggregationKind.hoursNonZero or (
                self.m_annualFields[i].m_aggregate == AggregationKind.hoursZero or
                self.m_annualFields[i].m_aggregate == AggregationKind.hoursPositive or
                self.m_annualFields[i].m_aggregate == AggregationKind.hoursNonPositive or
                self.m_annualFields[i].m_aggregate == AggregationKind.hoursNegative or
                self.m_annualFields[i].m_aggregate == AggregationKind.hoursNonNegative
            ):
                found_hour_agg = True
            elif self.m_annualFields[i].m_aggregate == AggregationKind.valueWhenMaxMin:
                if not found_min_or_max:
                    missing_max_or_min_error = True
            elif self.m_annualFields[i].m_aggregate == AggregationKind.sumOrAverageHoursShown or (
                self.m_annualFields[i].m_aggregate == AggregationKind.maximumDuringHoursShown or
                self.m_annualFields[i].m_aggregate == AggregationKind.minimumDuringHoursShown
            ):
                if not found_hour_agg:
                    missing_hour_agg_error = True

        return missing_hour_agg_error or missing_max_or_min_error

    fn gatherForTimestep(inout self, state: UnsafePointer[UInt8], kindOfTimeStep: UInt8):
        pass

    fn resetGathering(inout self):
        for row in range(len(self.m_objectNames)):
            for i in range(len(self.m_annualFields)):
                var cell = self.m_annualFields[i].m_cell[row]
                if self.m_annualFields[i].m_aggregate == AggregationKind.maximum or (
                    self.m_annualFields[i].m_aggregate == AggregationKind.maximumDuringHoursShown
                ):
                    cell.result = VERY_SMALL
                elif self.m_annualFields[i].m_aggregate == AggregationKind.minimum or (
                    self.m_annualFields[i].m_aggregate == AggregationKind.minimumDuringHoursShown
                ):
                    cell.result = VERY_LARGE
                else:
                    cell.result = 0.0
                cell.duration = 0.0
                cell.timeStamp = 0
                cell.deferredResults.clear()
                cell.deferredElapsed.clear()

    @staticmethod
    fn getElapsedTime(state: UnsafePointer[UInt8], kindOfTimeStep: UInt8) -> Real64:
        return 0.0

    @staticmethod
    fn getSecondsInTimeStep(state: UnsafePointer[UInt8], kindOfTimeStep: UInt8) -> Real64:
        return 0.0

    fn writeTable(inout self, state: UnsafePointer[UInt8], style: UnsafePointer[UInt8]):
        pass

    @staticmethod
    fn setupAggString() -> DynamicVector[String]:
        var ret_string_vec = DynamicVector[String]()
        for i in range(20):
            ret_string_vec.push_back("")
        return ret_string_vec

    @staticmethod
    fn setEnergyUnitStringAndFactor(units_style: UInt8) -> Tuple[Real64, String]:
        var conv_factor = 1.0
        var unit_string = String("J")
        return (conv_factor, unit_string)

    @staticmethod
    fn fixUnitsPerSecond(inout unit_string: String, inout conversion_factor: Real64):
        pass

    @staticmethod
    fn columnCountForAggregation(cur_agg: Int32) -> Int32:
        if cur_agg == AggregationKind.sumOrAvg or cur_agg == AggregationKind.valueWhenMaxMin or (
            cur_agg == AggregationKind.hoursZero or cur_agg == AggregationKind.hoursNonZero or
            cur_agg == AggregationKind.hoursPositive or cur_agg == AggregationKind.hoursNonPositive or
            cur_agg == AggregationKind.hoursNegative or cur_agg == AggregationKind.hoursNonNegative or
            cur_agg == AggregationKind.sumOrAverageHoursShown or cur_agg == AggregationKind.noAggregation
        ):
            return 1
        elif cur_agg == AggregationKind.maximum or cur_agg == AggregationKind.minimum or (
            cur_agg == AggregationKind.maximumDuringHoursShown or
            cur_agg == AggregationKind.minimumDuringHoursShown
        ):
            return 2
        elif cur_agg == AggregationKind.hoursInTenBinsMinToMax:
            return 10
        elif cur_agg == AggregationKind.hoursInTenBinsZeroToMax or (
            cur_agg == AggregationKind.hoursInTenBinsMinToZero
        ):
            return 11
        elif cur_agg == AggregationKind.hoursInTenPercentBins or (
            cur_agg == AggregationKind.hoursInTenBinsPlusMinusTwoStdDev or
            cur_agg == AggregationKind.hoursInTenBinsPlusMinusThreeStdDev
        ):
            return 12
        return 0

    @staticmethod
    fn trim(s: String) -> String:
        return s.strip()

    fn addTableOfContents(self, name_of_stream: UnsafePointer[UInt8]):
        pass

    fn computeBinColumns(inout self, state: UnsafePointer[UInt8], units_style: UInt8):
        pass

    fn allRowsSameSizeDeferredVectors(self, fldSt: AnnualFieldSet) -> Bool:
        if len(self.m_objectNames) == 0:
            return True
        var size_of_deferred = len(fldSt.m_cell[0].deferredResults)
        for row in range(len(self.m_objectNames)):
            if len(fldSt.m_cell[row].deferredResults) != size_of_deferred:
                return False
        return True

    fn convertUnitForDeferredResults(inout self, state: UnsafePointer[UInt8], inout fldSt: AnnualFieldSet, units_style: UInt8):
        pass

    @staticmethod
    fn calculateBins(num_bins: Int32, values_to_bin: DynamicVector[Real64], corr_elapsed_time: DynamicVector[Real64],
                     top_of_bins: Real64, bottom_of_bins: Real64) -> DynamicVector[Real64]:
        var return_bins = DynamicVector[Real64]()
        for i in range(num_bins):
            return_bins.push_back(0.0)
        return return_bins

    fn columnHeadersToTitleCase(inout self, state: UnsafePointer[UInt8]):
        pass

    fn clearTable(inout self):
        self.m_name = ""
        self.m_filter = ""
        self.m_sched = UnsafePointer[UInt8]()
        self.m_objectNames.clear()
        self.m_annualFields.clear()

    fn inspectTable(self) -> DynamicVector[String]:
        var ret = DynamicVector[String]()
        ret.push_back(self.m_name)
        ret.push_back(self.m_filter)
        return ret

    fn inspectTableFieldSets(self, fld_index: Int32) -> DynamicVector[String]:
        var ret = DynamicVector[String]()
        var fldSt = self.m_annualFields[fld_index]
        ret.push_back(fldSt.m_colHead)
        ret.push_back(fldSt.m_variMeter)
        return ret


fn GetInputTabularAnnual(state: UnsafePointer[UInt8]):
    pass


fn checkAggregationOrderForAnnual(state: UnsafePointer[UInt8]):
    pass


fn GatherAnnualResultsForTimeStep(state: UnsafePointer[UInt8], kindOfTimeStep: UInt8):
    pass


fn ResetAnnualGathering(state: UnsafePointer[UInt8]):
    pass


fn WriteAnnualTables(state: UnsafePointer[UInt8]):
    pass


fn stringToAggKind(state: UnsafePointer[UInt8], in_string: String) -> Int32:
    return AggregationKind.sumOrAvg


fn AddAnnualTableOfContents(state: UnsafePointer[UInt8], name_of_stream: UnsafePointer[UInt8]):
    pass
