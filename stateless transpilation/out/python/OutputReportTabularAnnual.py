from dataclasses import dataclass, field
from typing import Protocol, Any
from enum import IntEnum
from datetime import datetime
import math
import re

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state object, from EnergyPlus.Data.EnergyPlusData)
# - OutputProcessor.VariableType, OutputProcessor.StoreType, OutputProcessor.TimeStepType (from EnergyPlus.OutputProcessor)
# - OutputReportTabular functions (from EnergyPlus.OutputReportTabular)
# - Sched.Schedule, Sched.GetSchedule (from EnergyPlus.ScheduleManager)
# - Constant.Units (from EnergyPlus.DataGlobals)
# - ShowWarningError, ShowSevereError, ShowFatalError (from EnergyPlus.UtilityRoutines)
# - GetInternalVariableValue (from EnergyPlus.OutputProcessor)
# - General.EncodeMonDayHrMin (from EnergyPlus.General)

VERY_LARGE = float('inf')
VERY_SMALL = float('-inf')


class AggregationKind(IntEnum):
    sumOrAvg = 0
    maximum = 1
    minimum = 2
    valueWhenMaxMin = 3
    hoursZero = 4
    hoursNonZero = 5
    hoursPositive = 6
    hoursNonPositive = 7
    hoursNegative = 8
    hoursNonNegative = 9
    hoursInTenPercentBins = 10
    hoursInTenBinsMinToMax = 11
    hoursInTenBinsZeroToMax = 12
    hoursInTenBinsMinToZero = 13
    hoursInTenBinsPlusMinusTwoStdDev = 14
    hoursInTenBinsPlusMinusThreeStdDev = 15
    noAggregation = 16
    sumOrAverageHoursShown = 17
    maximumDuringHoursShown = 18
    minimumDuringHoursShown = 19


@dataclass
class CellData:
    result: float = 0.0
    duration: float = 0.0
    timeStamp: int = 0
    indexesForKeyVar: int = -1
    deferredResults: list = field(default_factory=list)
    deferredElapsed: list = field(default_factory=list)
    m_timeInBin: list = field(default_factory=lambda: [0.0] * 10)
    m_timeAboveTopBin: float = 0.0
    m_timeBelowBottomBin: float = 0.0


@dataclass
class AnnualFieldSet:
    m_variMeter: str = ""
    m_colHead: str = ""
    m_aggregate: AggregationKind = AggregationKind.sumOrAvg
    m_cell: list = field(default_factory=list)
    m_namesOfKeys: list = field(default_factory=list)
    m_indexesForKeyVar: list = field(default_factory=list)
    m_typeOfVar: Any = None
    m_varAvgSum: Any = None
    m_varStepType: Any = None
    m_varUnits: Any = None
    m_keyCount: int = 0
    m_showDigits: int = 2
    m_timeInBinTotal: list = field(default_factory=lambda: [0.0] * 10)
    m_timeAboveTopBinTotal: float = 0.0
    m_timeBelowBottomBinTotal: float = 0.0
    m_topBinValue: float = VERY_SMALL
    m_bottomBinValue: float = VERY_LARGE

    def __init__(self, varName: str, aggKind: AggregationKind, dgts: int):
        self.m_variMeter = varName
        self.m_colHead = varName
        self.m_aggregate = aggKind
        self.m_showDigits = dgts
        self.m_cell = []
        self.m_namesOfKeys = []
        self.m_indexesForKeyVar = []
        self.m_typeOfVar = None
        self.m_varAvgSum = None
        self.m_varStepType = None
        self.m_varUnits = None
        self.m_keyCount = 0
        self.m_timeInBinTotal = [0.0] * 10
        self.m_timeAboveTopBinTotal = 0.0
        self.m_timeBelowBottomBinTotal = 0.0
        self.m_topBinValue = VERY_SMALL
        self.m_bottomBinValue = VERY_LARGE


class AnnualTable:
    def __init__(self, state=None, name: str = "", filter_str: str = "", schedName: str = ""):
        self.m_name = name
        self.m_filter = filter_str
        if schedName and state:
            self.m_sched = state.dataScheduleManager.GetSchedule(state, schedName)
        else:
            self.m_sched = None
        self.m_objectNames = []
        self.m_annualFields = []

    def addFieldSet(self, varName: str, aggKind_or_colName: Any, aggKind_or_dgts: Any, dgts: int = None):
        if isinstance(aggKind_or_colName, str):
            colName = aggKind_or_colName
            aggKind = aggKind_or_dgts
            field_set = AnnualFieldSet(varName, aggKind, dgts)
            field_set.m_colHead = colName
        else:
            aggKind = aggKind_or_colName
            dgts_val = aggKind_or_dgts
            field_set = AnnualFieldSet(varName, aggKind, dgts_val)
        self.m_annualFields.append(field_set)

    def setupGathering(self, state):
        import re
        filter_field_upper = self.m_filter.upper()
        use_filter = len(self.m_filter) > 0
        all_keys = []
        
        for fldSt in self.m_annualFields:
            key_count = fldSt.getVariableKeyCountandTypeFromFldSt(state)
            fldSt.getVariableKeysFromFldSt(state, key_count)
            for nm in fldSt.m_namesOfKeys:
                nm_upper = nm.upper()
                if not use_filter or filter_field_upper in nm_upper:
                    all_keys.append(nm)
            
        all_keys = sorted(list(set(all_keys)))
        self.m_objectNames = all_keys
        
        for fldSt in self.m_annualFields:
            fldSt.m_cell = [CellData() for _ in range(len(self.m_objectNames))]
        
        for table_row_index, obj_name in enumerate(self.m_objectNames):
            for fldSt in self.m_annualFields:
                found_key_index = -1
                for i, key_name in enumerate(fldSt.m_namesOfKeys):
                    if key_name == obj_name:
                        found_key_index = i
                        break
                
                fldSt.m_cell[table_row_index].indexesForKeyVar = (
                    fldSt.m_indexesForKeyVar[found_key_index] if found_key_index >= 0 else -1
                )
                
                if fldSt.m_aggregate in [AggregationKind.maximum, AggregationKind.maximumDuringHoursShown]:
                    fldSt.m_cell[table_row_index].result = VERY_SMALL
                elif fldSt.m_aggregate in [AggregationKind.minimum, AggregationKind.minimumDuringHoursShown]:
                    fldSt.m_cell[table_row_index].result = VERY_LARGE
                else:
                    fldSt.m_cell[table_row_index].result = 0.0
                
                fldSt.m_cell[table_row_index].duration = 0.0
                fldSt.m_cell[table_row_index].timeStamp = 0

    def invalidAggregationOrder(self, state) -> bool:
        found_min_or_max = False
        found_hour_agg = False
        missing_max_or_min_error = False
        missing_hour_agg_error = False
        
        for fldSt in self.m_annualFields:
            if fldSt.m_aggregate in [AggregationKind.maximum, AggregationKind.minimum]:
                found_min_or_max = True
            elif fldSt.m_aggregate in [
                AggregationKind.hoursNonZero, AggregationKind.hoursZero,
                AggregationKind.hoursPositive, AggregationKind.hoursNonPositive,
                AggregationKind.hoursNegative, AggregationKind.hoursNonNegative
            ]:
                found_hour_agg = True
            elif fldSt.m_aggregate == AggregationKind.valueWhenMaxMin:
                if not found_min_or_max:
                    missing_max_or_min_error = True
            elif fldSt.m_aggregate in [
                AggregationKind.sumOrAverageHoursShown,
                AggregationKind.maximumDuringHoursShown,
                AggregationKind.minimumDuringHoursShown
            ]:
                if not found_hour_agg:
                    missing_hour_agg_error = True
        
        if missing_max_or_min_error:
            ShowSevereError(state, f"The Output:Table:Annual report named=\"{self.m_name}\" has a valueWhenMaxMin aggregation type "
                          "for a column without a previous column that uses either the minimum or maximum aggregation types. "
                          "The report will not be generated.")
        
        if missing_hour_agg_error:
            ShowSevereError(state, f"The Output:Table:Annual report named=\"{self.m_name}\" has a --DuringHoursShown aggregation type "
                          "for a column without a previous field that uses one of the Hour-- aggregation types. "
                          "The report will not be generated.")
        
        return missing_hour_agg_error or missing_max_or_min_error

    def gatherForTimestep(self, state, kindOfTimeStep):
        elapsed_time = AnnualTable.getElapsedTime(state, kindOfTimeStep)
        seconds_in_time_step = AnnualTable.getSecondsInTimeStep(state, kindOfTimeStep)
        active_min_max = False
        active_hours_shown = False
        
        if self.m_sched is not None and self.m_sched.getCurrentVal() == 0.0:
            return
        
        for row in range(len(self.m_objectNames)):
            for fld_st_it, fldSt in enumerate(self.m_annualFields):
                if fldSt.m_varStepType == kindOfTimeStep:
                    cur_var_num = fldSt.m_cell[row].indexesForKeyVar
                    if cur_var_num > -1:
                        cur_value = GetInternalVariableValue(state, fldSt.m_typeOfVar, cur_var_num)
                        old_result_value = fldSt.m_cell[row].result
                        old_duration = fldSt.m_cell[row].duration
                        new_result_value = 0.0
                        new_time_stamp = 0
                        new_duration = 0.0
                        active_new_value = False
                        
                        minute_calculated = state.dataOutputProcessor.DetermineMinuteForReporting(state)
                        timestep_time_stamp = General.EncodeMonDayHrMin(
                            state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth,
                            state.dataGlobal.HourOfDay, minute_calculated
                        )
                        
                        if fldSt.m_aggregate == AggregationKind.sumOrAvg:
                            if fldSt.m_varAvgSum == "Sum":
                                new_result_value = old_result_value + cur_value
                            else:
                                new_result_value = old_result_value + cur_value * elapsed_time
                            new_duration = old_duration + elapsed_time
                            active_new_value = True
                        elif fldSt.m_aggregate == AggregationKind.maximum:
                            if fldSt.m_varAvgSum == "Sum":
                                cur_value /= seconds_in_time_step
                            if cur_value > old_result_value:
                                new_result_value = cur_value
                                new_time_stamp = timestep_time_stamp
                                active_min_max = True
                                active_new_value = True
                            else:
                                active_min_max = False
                        elif fldSt.m_aggregate == AggregationKind.minimum:
                            if fldSt.m_varAvgSum == "Sum":
                                cur_value /= seconds_in_time_step
                            if cur_value < old_result_value:
                                new_result_value = cur_value
                                new_time_stamp = timestep_time_stamp
                                active_min_max = True
                                active_new_value = True
                            else:
                                active_min_max = False
                        elif fldSt.m_aggregate == AggregationKind.hoursNonZero:
                            if cur_value != 0:
                                new_result_value = old_result_value + elapsed_time
                                active_hours_shown = True
                                active_new_value = True
                            else:
                                active_hours_shown = False
                        elif fldSt.m_aggregate == AggregationKind.hoursZero:
                            if cur_value == 0:
                                new_result_value = old_result_value + elapsed_time
                                active_hours_shown = True
                                active_new_value = True
                            else:
                                active_hours_shown = False
                        elif fldSt.m_aggregate == AggregationKind.hoursPositive:
                            if cur_value > 0:
                                new_result_value = old_result_value + elapsed_time
                                active_hours_shown = True
                                active_new_value = True
                            else:
                                active_hours_shown = False
                        elif fldSt.m_aggregate == AggregationKind.hoursNonPositive:
                            if cur_value <= 0:
                                new_result_value = old_result_value + elapsed_time
                                active_hours_shown = True
                                active_new_value = True
                            else:
                                active_hours_shown = False
                        elif fldSt.m_aggregate == AggregationKind.hoursNegative:
                            if cur_value < 0:
                                new_result_value = old_result_value + elapsed_time
                                active_hours_shown = True
                                active_new_value = True
                            else:
                                active_hours_shown = False
                        elif fldSt.m_aggregate == AggregationKind.hoursNonNegative:
                            if cur_value >= 0:
                                new_result_value = old_result_value + elapsed_time
                                active_hours_shown = True
                                active_new_value = True
                            else:
                                active_hours_shown = False
                        elif fldSt.m_aggregate in [
                            AggregationKind.hoursInTenPercentBins, AggregationKind.hoursInTenBinsMinToMax,
                            AggregationKind.hoursInTenBinsZeroToMax, AggregationKind.hoursInTenBinsMinToZero,
                            AggregationKind.hoursInTenBinsPlusMinusTwoStdDev, AggregationKind.hoursInTenBinsPlusMinusThreeStdDev
                        ]:
                            if fldSt.m_varAvgSum == "Sum":
                                cur_value_rate = cur_value / seconds_in_time_step
                                fldSt.m_cell[row].deferredResults.append(cur_value_rate)
                            else:
                                fldSt.m_cell[row].deferredResults.append(cur_value)
                            fldSt.m_cell[row].deferredElapsed.append(elapsed_time)
                        
                        if active_new_value:
                            fldSt.m_cell[row].result = new_result_value
                            fldSt.m_cell[row].timeStamp = new_time_stamp
                            fldSt.m_cell[row].duration = new_duration
                        
                        if active_min_max:
                            for fld_st_remain_it in range(fld_st_it + 1, len(self.m_annualFields)):
                                fldStRemain = self.m_annualFields[fld_st_remain_it]
                                if fldStRemain.m_aggregate in [AggregationKind.maximum, AggregationKind.minimum]:
                                    break
                                if fldStRemain.m_aggregate == AggregationKind.valueWhenMaxMin:
                                    scan_type_of_var = fldStRemain.m_typeOfVar
                                    scan_var_num = fldStRemain.m_cell[row].indexesForKeyVar
                                    if scan_var_num > -1:
                                        scan_value = GetInternalVariableValue(state, scan_type_of_var, scan_var_num)
                                        if fldStRemain.m_varAvgSum == "Sum":
                                            scan_value /= seconds_in_time_step
                                        fldStRemain.m_cell[row].result = scan_value
                        
                        if active_hours_shown:
                            for fld_st_remain_it in range(fld_st_it + 1, len(self.m_annualFields)):
                                fldStRemain = self.m_annualFields[fld_st_remain_it]
                                scan_type_of_var = fldStRemain.m_typeOfVar
                                scan_var_num = fldStRemain.m_cell[row].indexesForKeyVar
                                old_scan_value = fldStRemain.m_cell[row].result
                                
                                if scan_var_num > -1:
                                    scan_value = GetInternalVariableValue(state, scan_type_of_var, scan_var_num)
                                    if fldStRemain.m_aggregate in [
                                        AggregationKind.hoursZero, AggregationKind.hoursNonZero,
                                        AggregationKind.hoursPositive, AggregationKind.hoursNonPositive,
                                        AggregationKind.hoursNegative, AggregationKind.hoursNonNegative
                                    ]:
                                        break
                                    if fldStRemain.m_aggregate == AggregationKind.sumOrAverageHoursShown:
                                        if fldSt.m_varAvgSum == "Sum":
                                            fldStRemain.m_cell[row].result = old_scan_value + scan_value
                                        else:
                                            fldStRemain.m_cell[row].result = old_scan_value + scan_value * elapsed_time
                                        fldStRemain.m_cell[row].duration += elapsed_time
                                    elif fldStRemain.m_aggregate == AggregationKind.minimumDuringHoursShown:
                                        if fldStRemain.m_varAvgSum == "Sum":
                                            scan_value /= seconds_in_time_step
                                        if scan_value < old_scan_value:
                                            fldStRemain.m_cell[row].result = scan_value
                                            fldStRemain.m_cell[row].timeStamp = timestep_time_stamp
                                    elif fldStRemain.m_aggregate == AggregationKind.maximumDuringHoursShown:
                                        if fldStRemain.m_varAvgSum == "Sum":
                                            scan_value /= seconds_in_time_step
                                        if scan_value > old_scan_value:
                                            fldStRemain.m_cell[row].result = scan_value
                                            fldStRemain.m_cell[row].timeStamp = timestep_time_stamp
                                active_hours_shown = False

    def resetGathering(self):
        for row in range(len(self.m_objectNames)):
            for fldSt in self.m_annualFields:
                cell = fldSt.m_cell[row]
                if fldSt.m_aggregate in [AggregationKind.maximum, AggregationKind.maximumDuringHoursShown]:
                    cell.result = VERY_SMALL
                elif fldSt.m_aggregate in [AggregationKind.minimum, AggregationKind.minimumDuringHoursShown]:
                    cell.result = VERY_LARGE
                else:
                    cell.result = 0.0
                cell.duration = 0.0
                cell.timeStamp = 0
                cell.deferredResults.clear()
                cell.deferredElapsed.clear()

    @staticmethod
    def getElapsedTime(state, kindOfTimeStep):
        if kindOfTimeStep == "Zone":
            return state.dataGlobal.TimeStepZone
        else:
            return state.dataHVACGlobal.TimeStepSys

    @staticmethod
    def getSecondsInTimeStep(state, kindOfTimeStep):
        if kindOfTimeStep == "Zone":
            return state.dataGlobal.TimeStepZoneSec
        else:
            return state.dataHVACGlobal.TimeStepSysSec

    def writeTable(self, state, style):
        agg_string = AnnualTable.setupAggString()
        energy_units_conversion_factor, energy_units_string = AnnualTable.setEnergyUnitStringAndFactor(style.unitsStyle)
        
        self.computeBinColumns(state, style.unitsStyle)
        self.columnHeadersToTitleCase(state)
        
        column_count = sum(AnnualTable.columnCountForAggregation(fldSt.m_aggregate) for fldSt in self.m_annualFields)
        column_head = [""] * column_count
        column_width = [14] * column_count
        row_count = len(self.m_objectNames) + 4
        row_sum_avg = len(self.m_objectNames) + 1
        row_min = len(self.m_objectNames) + 2
        row_max = len(self.m_objectNames) + 3
        
        row_head = [""] * row_count
        for row in range(len(self.m_objectNames)):
            row_head[row] = self.m_objectNames[row]
        row_head[row_sum_avg] = "Annual Sum or Average"
        row_head[row_min] = "Minimum of Rows"
        row_head[row_max] = "Maximum of Rows"
        
        table_body = [["" for _ in range(row_count)] for _ in range(column_count)]
        column_recount = 0
        
        for fldSt in self.m_annualFields:
            cur_agg_string = agg_string[int(fldSt.m_aggregate)]
            if cur_agg_string:
                cur_agg_string = " {" + cur_agg_string.strip() + "}"
            
            switch (style.unitsStyle):
                case "InchPound" | "InchPoundExceptElectricity":
                    var_name_with_units = f"{fldSt.m_variMeter} [{fldSt.m_varUnits}]"
                    index_unit_conv, cur_units = OutputReportTabular.LookupSItoIP(state, var_name_with_units)
                    cur_conversion_factor, cur_conversion_offset, cur_units = OutputReportTabular.GetUnitConversion(
                        state, index_unit_conv, cur_units
                    )
                case _:
                    if fldSt.m_varUnits == "J":
                        cur_units = energy_units_string
                        cur_conversion_factor = energy_units_conversion_factor
                        cur_conversion_offset = 0.0
                    else:
                        cur_units = fldSt.m_varUnits
                        cur_conversion_factor = 1.0
                        cur_conversion_offset = 0.0
            
            cur_agg = fldSt.m_aggregate
            column_recount += AnnualTable.columnCountForAggregation(fldSt.m_aggregate)
            
            if cur_agg in [AggregationKind.sumOrAvg, AggregationKind.sumOrAverageHoursShown]:
                column_head[column_recount - 1] = fldSt.m_colHead + cur_agg_string + " [" + cur_units + "]"
                sum_val = 0.0
                sum_duration = 0.0
                min_val = VERY_LARGE
                max_val = VERY_SMALL
                
                for row in range(len(self.m_objectNames)):
                    if fldSt.m_cell[row].indexesForKeyVar >= 0:
                        if fldSt.m_varAvgSum == "Average":
                            if fldSt.m_cell[row].duration != 0.0:
                                cur_val = (fldSt.m_cell[row].result / fldSt.m_cell[row].duration) * cur_conversion_factor + cur_conversion_offset
                            else:
                                cur_val = 0.0
                            sum_val += fldSt.m_cell[row].result * cur_conversion_factor + cur_conversion_offset
                            sum_duration += fldSt.m_cell[row].duration
                        else:
                            cur_val = fldSt.m_cell[row].result * cur_conversion_factor + cur_conversion_offset
                            sum_val += cur_val
                        
                        table_body[column_recount - 1][row] = OutputReportTabular.RealToStr(style.formatReals, cur_val, fldSt.m_showDigits)
                        if cur_val > max_val:
                            max_val = cur_val
                        if cur_val < min_val:
                            min_val = cur_val
                    else:
                        table_body[column_recount - 1][row] = "-"
                
                if fldSt.m_varAvgSum == "Average":
                    if sum_duration > 0:
                        table_body[column_recount - 1][row_sum_avg] = OutputReportTabular.RealToStr(
                            style.formatReals, sum_val / sum_duration, fldSt.m_showDigits
                        )
                    else:
                        table_body[column_recount - 1][row_sum_avg] = ""
                else:
                    table_body[column_recount - 1][row_sum_avg] = OutputReportTabular.RealToStr(style.formatReals, sum_val, fldSt.m_showDigits)
                
                if min_val != VERY_LARGE:
                    table_body[column_recount - 1][row_max] = OutputReportTabular.RealToStr(style.formatReals, min_val, fldSt.m_showDigits)
                if max_val != VERY_SMALL:
                    table_body[column_recount - 1][row_min] = OutputReportTabular.RealToStr(style.formatReals, max_val, fldSt.m_showDigits)

    @staticmethod
    def setupAggString():
        ret_string_vec = [""] * 20
        ret_string_vec[int(AggregationKind.sumOrAvg)] = ""
        ret_string_vec[int(AggregationKind.maximum)] = " MAXIMUM "
        ret_string_vec[int(AggregationKind.minimum)] = " MINIMUM "
        ret_string_vec[int(AggregationKind.valueWhenMaxMin)] = " AT MAX/MIN "
        ret_string_vec[int(AggregationKind.hoursZero)] = " HOURS ZERO "
        ret_string_vec[int(AggregationKind.hoursNonZero)] = " HOURS NON-ZERO "
        ret_string_vec[int(AggregationKind.hoursPositive)] = " HOURS POSITIVE "
        ret_string_vec[int(AggregationKind.hoursNonPositive)] = " HOURS NON-POSITIVE "
        ret_string_vec[int(AggregationKind.hoursNegative)] = " HOURS NEGATIVE "
        ret_string_vec[int(AggregationKind.hoursNonNegative)] = " HOURS NON-NEGATIVE "
        ret_string_vec[int(AggregationKind.hoursInTenPercentBins)] = " HOURS IN"
        ret_string_vec[int(AggregationKind.hoursInTenBinsMinToMax)] = " HOURS IN"
        ret_string_vec[int(AggregationKind.hoursInTenBinsZeroToMax)] = " HOURS IN"
        ret_string_vec[int(AggregationKind.hoursInTenBinsMinToZero)] = " HOURS IN"
        ret_string_vec[int(AggregationKind.hoursInTenBinsPlusMinusTwoStdDev)] = " HOURS IN"
        ret_string_vec[int(AggregationKind.hoursInTenBinsPlusMinusThreeStdDev)] = " HOURS IN"
        ret_string_vec[int(AggregationKind.noAggregation)] = " NO AGGREGATION "
        ret_string_vec[int(AggregationKind.sumOrAverageHoursShown)] = " FOR HOURS SHOWN "
        ret_string_vec[int(AggregationKind.maximumDuringHoursShown)] = " MAX FOR HOURS SHOWN "
        ret_string_vec[int(AggregationKind.minimumDuringHoursShown)] = " MIN FOR HOURS SHOWN "
        return ret_string_vec

    @staticmethod
    def setEnergyUnitStringAndFactor(units_style):
        conv_factor = 1.0
        unit_string = "J"
        if units_style == "JtoKWH":
            unit_string = "kWh"
            conv_factor = 1.0 / 3600000.0
        elif units_style == "JtoMJ":
            unit_string = "MJ"
            conv_factor = 1.0 / 1000000.0
        elif units_style == "JtoGJ":
            unit_string = "GJ"
            conv_factor = 1.0 / 1000000000.0
        return conv_factor, unit_string

    @staticmethod
    def fixUnitsPerSecond(unit_string: str, conversion_factor: float) -> tuple:
        if unit_string == "J/s":
            unit_string = "W"
        elif unit_string == "kWh/s":
            unit_string = "W"
            conversion_factor *= 3600000.0
        elif unit_string == "GJ/s":
            unit_string = "kW"
            conversion_factor *= 1000000.0
        elif unit_string == "MJ/s":
            unit_string = "kW"
            conversion_factor *= 1000.0
        elif unit_string == "therm/s":
            unit_string = "kBtu/h"
            conversion_factor *= 360000.0
        elif unit_string == "kBtu/s":
            unit_string = "kBtu/h"
            conversion_factor *= 3600.0
        elif unit_string == "ton-hrs/s":
            unit_string = "ton"
            conversion_factor *= 3600.0
        return unit_string, conversion_factor

    @staticmethod
    def columnCountForAggregation(cur_agg):
        if cur_agg in [
            AggregationKind.sumOrAvg, AggregationKind.valueWhenMaxMin,
            AggregationKind.hoursZero, AggregationKind.hoursNonZero,
            AggregationKind.hoursPositive, AggregationKind.hoursNonPositive,
            AggregationKind.hoursNegative, AggregationKind.hoursNonNegative,
            AggregationKind.sumOrAverageHoursShown, AggregationKind.noAggregation
        ]:
            return 1
        elif cur_agg in [
            AggregationKind.maximum, AggregationKind.minimum,
            AggregationKind.maximumDuringHoursShown, AggregationKind.minimumDuringHoursShown
        ]:
            return 2
        elif cur_agg == AggregationKind.hoursInTenBinsMinToMax:
            return 10
        elif cur_agg in [AggregationKind.hoursInTenBinsZeroToMax, AggregationKind.hoursInTenBinsMinToZero]:
            return 11
        elif cur_agg in [
            AggregationKind.hoursInTenPercentBins, AggregationKind.hoursInTenBinsPlusMinusTwoStdDev,
            AggregationKind.hoursInTenBinsPlusMinusThreeStdDev
        ]:
            return 12
        return 0

    @staticmethod
    def trim(s: str) -> str:
        return s.strip()

    def addTableOfContents(self, name_of_stream):
        name_of_stream.write(f"<p><b>{self.m_name}</b></p> |\n")
        anchor_name = OutputReportTabular.MakeAnchorName(self.m_name, "Entire Facility")
        name_of_stream.write(f"<a href=\"#{anchor_name}\">Entire Facility</a>    |   \n")

    def computeBinColumns(self, state, units_style):
        for fldStIt in self.m_annualFields:
            if fldStIt.m_aggregate in [
                AggregationKind.hoursInTenBinsMinToMax, AggregationKind.hoursInTenBinsZeroToMax,
                AggregationKind.hoursInTenBinsMinToZero, AggregationKind.hoursInTenPercentBins,
                AggregationKind.hoursInTenBinsPlusMinusTwoStdDev, AggregationKind.hoursInTenBinsPlusMinusThreeStdDev
            ]:
                if not self.allRowsSameSizeDeferredVectors(fldStIt):
                    break
                
                self.convertUnitForDeferredResults(state, fldStIt, units_style)
                
                deferred_total_for_column = []
                min_val = VERY_LARGE
                max_val = VERY_SMALL
                
                for j_def_res in range(len(fldStIt.m_cell[0].deferredResults)):
                    sum_val = sum(fldStIt.m_cell[row].deferredResults[j_def_res] for row in range(len(self.m_objectNames)))
                    for row in range(len(self.m_objectNames)):
                        cur_val = fldStIt.m_cell[row].deferredResults[j_def_res]
                        if cur_val > max_val:
                            max_val = cur_val
                        if cur_val < min_val:
                            min_val = cur_val
                    deferred_total_for_column.append(sum_val / len(self.m_objectNames))
                
                if fldStIt.m_aggregate == AggregationKind.hoursInTenBinsMinToMax:
                    fldStIt.m_topBinValue = max_val
                    fldStIt.m_bottomBinValue = min_val
                elif fldStIt.m_aggregate == AggregationKind.hoursInTenBinsZeroToMax:
                    fldStIt.m_topBinValue = max_val
                    fldStIt.m_bottomBinValue = 0.0
                elif fldStIt.m_aggregate == AggregationKind.hoursInTenBinsMinToZero:
                    fldStIt.m_topBinValue = 0.0
                    fldStIt.m_bottomBinValue = min_val
                elif fldStIt.m_aggregate == AggregationKind.hoursInTenPercentBins:
                    fldStIt.m_topBinValue = 1.0
                    fldStIt.m_bottomBinValue = 0.0
                
                for row in range(len(self.m_objectNames)):
                    fldStIt.m_cell[row].m_timeInBin = AnnualTable.calculateBins(
                        10, fldStIt.m_cell[row].deferredResults, fldStIt.m_cell[row].deferredElapsed,
                        fldStIt.m_topBinValue, fldStIt.m_bottomBinValue
                    )
                    fldStIt.m_cell[row].m_timeAboveTopBin = fldStIt.m_cell[row].m_timeInBin[-1]
                    fldStIt.m_cell[row].m_timeBelowBottomBin = fldStIt.m_cell[row].m_timeInBin[0]
                
                fldStIt.m_timeInBinTotal = AnnualTable.calculateBins(
                    10, deferred_total_for_column, fldStIt.m_cell[0].deferredElapsed,
                    fldStIt.m_topBinValue, fldStIt.m_bottomBinValue
                )

    def allRowsSameSizeDeferredVectors(self, fldSt) -> bool:
        if not self.m_objectNames:
            return True
        size_of_deferred = len(fldSt.m_cell[0].deferredResults)
        for row in range(len(self.m_objectNames)):
            if len(fldSt.m_cell[row].deferredResults) != size_of_deferred:
                return False
        return True

    def convertUnitForDeferredResults(self, state, fldSt, units_style):
        energy_units_conversion_factor, energy_units_string = AnnualTable.setEnergyUnitStringAndFactor(units_style)
        
        if units_style in ["InchPound", "InchPoundExceptElectricity"]:
            var_name_with_units = f"{fldSt.m_variMeter} [{fldSt.m_varUnits}]"
            index_unit_conv, cur_units = OutputReportTabular.LookupSItoIP(state, var_name_with_units)
            cur_conversion_factor, cur_conversion_offset, cur_units = OutputReportTabular.GetUnitConversion(
                state, index_unit_conv, cur_units
            )
        else:
            if fldSt.m_varUnits == "J":
                cur_units = energy_units_string
                cur_conversion_factor = energy_units_conversion_factor
                cur_conversion_offset = 0.0
            else:
                cur_units = fldSt.m_varUnits
                cur_conversion_factor = 1.0
                cur_conversion_offset = 0.0
        
        if fldSt.m_varAvgSum == "Sum":
            cur_units += "/s"
        cur_units, cur_conversion_factor = AnnualTable.fixUnitsPerSecond(cur_units, cur_conversion_factor)
        
        if cur_conversion_factor != 1.0 or cur_conversion_offset != 0.0:
            for row in range(len(self.m_objectNames)):
                for j_def_res in range(len(fldSt.m_cell[0].deferredResults)):
                    cur_si = fldSt.m_cell[row].deferredResults[j_def_res]
                    cur_ip = cur_si * cur_conversion_factor + cur_conversion_offset
                    fldSt.m_cell[row].deferredResults[j_def_res] = cur_ip

    @staticmethod
    def calculateBins(num_bins, values_to_bin, corr_elapsed_time, top_of_bins, bottom_of_bins):
        if num_bins <= 0:
            return []
        return_bins = [0.0] * num_bins
        time_above_top_bin = 0.0
        time_below_bottom_bin = 0.0
        
        if not values_to_bin:
            return return_bins
        
        interval_size = (top_of_bins - bottom_of_bins) / float(num_bins)
        
        for i, value_it in enumerate(values_to_bin):
            elapsed_time_val = corr_elapsed_time[i] if i < len(corr_elapsed_time) else 0
            if value_it < bottom_of_bins:
                time_below_bottom_bin += elapsed_time_val
            elif value_it >= top_of_bins:
                time_above_top_bin += elapsed_time_val
            else:
                bin_num = int((value_it - bottom_of_bins) / interval_size)
                if 0 <= bin_num < num_bins:
                    return_bins[bin_num] += elapsed_time_val
        
        return return_bins

    def columnHeadersToTitleCase(self, state):
        for fldSt in self.m_annualFields:
            if fldSt.m_variMeter == fldSt.m_colHead:
                if fldSt.m_indexesForKeyVar:
                    var_num = fldSt.m_indexesForKeyVar[0]
                    if fldSt.m_typeOfVar == "Real":
                        fldSt.m_colHead = state.dataOutputProcessor.outVars[var_num].name
                    elif fldSt.m_typeOfVar == "Meter":
                        fldSt.m_colHead = state.dataOutputProcessor.meters[var_num].Name

    def clearTable(self):
        self.m_name = ""
        self.m_filter = ""
        self.m_sched = None
        self.m_objectNames = []
        self.m_annualFields = []

    def inspectTable(self):
        ret = []
        ret.append(self.m_name)
        ret.append(self.m_filter)
        if self.m_sched:
            ret.append(self.m_sched.Name)
        return ret

    def inspectTableFieldSets(self, fld_index: int):
        fldSt = self.m_annualFields[fld_index]
        ret = []
        has_cell = len(fldSt.m_cell) > 0
        ret.append(fldSt.m_colHead)
        ret.append(fldSt.m_variMeter)
        ret.append(fldSt.m_varUnits)
        ret.append(str(fldSt.m_showDigits))
        ret.append(str(fldSt.m_typeOfVar))
        ret.append(str(fldSt.m_keyCount))
        ret.append(str(fldSt.m_varAvgSum))
        ret.append(str(fldSt.m_varStepType))
        ret.append(str(fldSt.m_aggregate))
        ret.append(str(fldSt.m_bottomBinValue))
        ret.append(str(fldSt.m_topBinValue))
        ret.append(str(fldSt.m_timeAboveTopBinTotal))
        ret.append(str(fldSt.m_timeBelowBottomBinTotal))
        if has_cell:
            ret.append(str(fldSt.m_cell[0].result))
        return ret


def GetInputTabularAnnual(state):
    current_module_object = "Output:Table:Annual"
    annual_tables = state.dataOutputReportTabularAnnual.annualTables
    
    obj_count = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    if obj_count > 0:
        state.dataOutRptTab.WriteTabularFiles = True
        
        if not state.dataGlobal.DoWeathSim:
            ShowWarningError(state,
                f"{current_module_object} requested with SimulationControl Run Simulation for Weather File Run Periods "
                f"set to No so {current_module_object} will not be generated")
            return
    
    num_params, num_alphas, num_nums = state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, current_module_object
    )
    
    for tab_num in range(1, obj_count + 1):
        alph_array, num_array, io_stat = state.dataInputProcessing.inputProcessor.getObjectItem(
            state, current_module_object, tab_num, num_alphas, num_nums
        )
        
        if len(alph_array) >= 5:
            annual_tables.append(AnnualTable(state, alph_array[0], alph_array[1], alph_array[2]))
            
            for j_alpha in range(3, len(alph_array), 2):
                cur_var_mtr = alph_array[j_alpha]
                if not cur_var_mtr:
                    ShowWarningError(state,
                        f"{current_module_object}: Blank column specified in '{alph_array[0]}', "
                        "need to provide a variable or meter or EMS variable name")
                
                if j_alpha + 1 < len(alph_array):
                    aggregation_string = alph_array[j_alpha + 1]
                    cur_agg = stringToAggKind(state, aggregation_string)
                else:
                    cur_agg = AggregationKind.sumOrAvg
                
                index_nums = 1 + (j_alpha - 2) // 2
                if index_nums < len(num_array):
                    cur_num_dgts = int(num_array[index_nums])
                else:
                    cur_num_dgts = 2
                
                if cur_var_mtr:
                    annual_tables[-1].addFieldSet(cur_var_mtr, cur_agg, cur_num_dgts)
            
            annual_tables[-1].setupGathering(state)
        else:
            ShowSevereError(state, f"{current_module_object}: Must enter at least the first six fields.")


def checkAggregationOrderForAnnual(state):
    invalid_aggregation_order_found = False
    annual_tables = state.dataOutputReportTabularAnnual.annualTables
    
    if not state.dataGlobal.DoWeathSim:
        return
    
    for annual_table in annual_tables:
        if annual_table.invalidAggregationOrder(state):
            invalid_aggregation_order_found = True
    
    if invalid_aggregation_order_found:
        ShowFatalError(state, "OutputReportTabularAnnual: Invalid aggregations detected, no simulation performed.")


def GatherAnnualResultsForTimeStep(state, kindOfTimeStep):
    annual_tables = state.dataOutputReportTabularAnnual.annualTables
    for annual_table in annual_tables:
        annual_table.gatherForTimestep(state, kindOfTimeStep)


def ResetAnnualGathering(state):
    annual_tables = state.dataOutputReportTabularAnnual.annualTables
    for annual_table in annual_tables:
        annual_table.resetGathering()


def WriteAnnualTables(state):
    annual_tables = state.dataOutputReportTabularAnnual.annualTables
    for current_style in state.dataOutRptTab.tabularReportPasses:
        for annual_table in annual_tables:
            annual_table.writeTable(state, current_style)


def stringToAggKind(state, in_string: str):
    in_str_upper = in_string.upper()
    
    if "SUMORAVERAGE" in in_str_upper:
        return AggregationKind.sumOrAvg
    elif "MAXIMUM" in in_str_upper:
        return AggregationKind.maximum
    elif "MINIMUM" in in_str_upper:
        return AggregationKind.minimum
    elif "VALUEWHENMAXIMUMORMINIMUM" in in_str_upper:
        return AggregationKind.valueWhenMaxMin
    elif "HOURSZERO" in in_str_upper:
        return AggregationKind.hoursZero
    elif "HOURSNONZERO" in in_str_upper:
        return AggregationKind.hoursNonZero
    elif "HOURSPOSITIVE" in in_str_upper:
        return AggregationKind.hoursPositive
    elif "HOURSNONPOSITIVE" in in_str_upper:
        return AggregationKind.hoursNonPositive
    elif "HOURSNEGATIVE" in in_str_upper:
        return AggregationKind.hoursNegative
    elif "HOURSNONNEGATIVE" in in_str_upper:
        return AggregationKind.hoursNonNegative
    elif "HOURSINTENPERCENT" in in_str_upper:
        return AggregationKind.hoursInTenPercentBins
    elif "HOURCINTENBINSMINTOMAX" in in_str_upper or "HOURSINTENBINSMINTOMAX" in in_str_upper:
        return AggregationKind.hoursInTenBinsMinToMax
    elif "HOURINTENBINSZEROTOM" in in_str_upper or "HOURSINTENBINSZEROTOM" in in_str_upper:
        return AggregationKind.hoursInTenBinsZeroToMax
    elif "HOURINTENBINSMINTOZERO" in in_str_upper or "HOURSINTENBINSMINTOZERO" in in_str_upper:
        return AggregationKind.hoursInTenBinsMinToZero
    elif "HOURSINTENBINSPLUSMINUSTWO" in in_str_upper:
        return AggregationKind.hoursInTenBinsPlusMinusTwoStdDev
    elif "HOURSINTENBINSPLUSMINUSTHREE" in in_str_upper:
        return AggregationKind.hoursInTenBinsPlusMinusThreeStdDev
    elif "NOAGGREGATION" in in_str_upper:
        return AggregationKind.noAggregation
    elif "SUMORAVERAGEDURING" in in_str_upper:
        return AggregationKind.sumOrAverageHoursShown
    elif "MAXIMUMDURING" in in_str_upper:
        return AggregationKind.maximumDuringHoursShown
    elif "MINIMUMDURING" in in_str_upper:
        return AggregationKind.minimumDuringHoursShown
    else:
        ShowWarningError(state, f"Invalid aggregation type=\"{in_string}\" Defaulting to SumOrAverage.")
        return AggregationKind.sumOrAvg


def AddAnnualTableOfContents(state, name_of_stream):
    annual_tables = state.dataOutputReportTabularAnnual.annualTables
    for annual_table in annual_tables:
        annual_table.addTableOfContents(name_of_stream)
