from collections import List

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state, from EnergyPlus)
# - OutputProcessor.VariableType (enum, from EnergyPlus.OutputProcessor)
# - OutputProcessor.StoreType (enum, from EnergyPlus.OutputProcessor)
# - OutputProcessor.TimeStepType (enum, from EnergyPlus.OutputProcessor)
# - Constant.Units (enum, from EnergyPlus.Constant)
# - GetVariableKeyCountandType(state, varname, numkeys, typevar, avgsumvar, steptypevar, unitsvar) (from EnergyPlus.OutputProcessor)
# - GetVariableKeys(state, varname, typevar, namesofkeys, indexesforkey) (from EnergyPlus.OutputProcessor)


enum AggregationKind:
    sumOrAvg = 0
    maximum = 1
    minimum = 2
    hoursNonZero = 3
    hoursZero = 4
    hoursPositive = 5
    hoursNonPositive = 6
    hoursNegative = 7
    hoursNonNegative = 8
    hoursInTenPercentBins = 9
    hoursInTenBinsMinToMax = 10
    hoursInTenBinsZeroToMax = 11
    hoursInTenBinsMinToZero = 12
    hoursInTenBinsPlusMinusTwoStdDev = 13
    hoursInTenBinsPlusMinusThreeStdDev = 14
    noAggregation = 15
    valueWhenMaxMin = 16
    sumOrAverageHoursShown = 17
    maximumDuringHoursShown = 18
    minimumDuringHoursShown = 19


struct AnnualCell:
    var indexesForKeyVar: Int
    var result: Float64
    var duration: Float64
    var timeStamp: Int
    var deferredResults: List[Float64]
    var deferredElapsed: List[Float64]
    var m_timeAboveTopBin: Float64
    var m_timeBelowBottomBin: Float64
    var m_timeInBin: List[Float64]

    fn __init__(inout self):
        self.indexesForKeyVar = 0
        self.result = 0.0
        self.duration = 0.0
        self.timeStamp = 0
        self.deferredResults = List[Float64]()
        self.deferredElapsed = List[Float64]()
        self.m_timeAboveTopBin = 0.0
        self.m_timeBelowBottomBin = 0.0
        self.m_timeInBin = List[Float64]()


struct AnnualFieldSet:
    var m_variMeter: String
    var m_colHead: String
    var m_aggregate: AggregationKind
    var m_showDigits: Int
    var m_varUnits: object
    var m_typeOfVar: object
    var m_keyCount: Int
    var m_varAvgSum: object
    var m_varStepType: object
    var m_namesOfKeys: List[String]
    var m_indexesForKeyVar: List[Int]
    var m_cell: List[AnnualCell]
    var m_bottomBinValue: Float64
    var m_topBinValue: Float64
    var m_timeAboveTopBinTotal: Float64
    var m_timeBelowBottomBinTotal: Float64
    var m_timeInBinTotal: List[Float64]

    fn __init__(inout self):
        self.m_variMeter = ""
        self.m_colHead = ""
        self.m_aggregate = AggregationKind.sumOrAvg
        self.m_showDigits = 2
        self.m_varUnits = None
        self.m_typeOfVar = None
        self.m_keyCount = 0
        self.m_varAvgSum = None
        self.m_varStepType = None
        self.m_namesOfKeys = List[String]()
        self.m_indexesForKeyVar = List[Int]()
        self.m_cell = List[AnnualCell]()
        self.m_bottomBinValue = -999.0
        self.m_topBinValue = -999.0
        self.m_timeAboveTopBinTotal = 0.0
        self.m_timeBelowBottomBinTotal = 0.0
        self.m_timeInBinTotal = List[Float64]()

    fn __init__(inout self, var_name: String, kind_of_aggregation: AggregationKind, num_digits_shown: Int):
        self.__init__()
        self.m_variMeter = var_name
        self.m_aggregate = kind_of_aggregation
        self.m_showDigits = num_digits_shown

    fn getVariableKeyCountandTypeFromFldSt(
        inout self,
        state: object,
        type_var: object,
        avg_sum_var: object,
        step_type_var: object,
        units_var: object
    ) -> Int:
        var numkeys: Int = 0
        GetVariableKeyCountandType(
            state,
            self.m_variMeter,
            numkeys,
            type_var,
            avg_sum_var,
            step_type_var,
            units_var
        )
        return numkeys

    fn getVariableKeysFromFldSt(
        inout self,
        state: object,
        type_var: object,
        key_count: Int,
        inout names_of_keys: List[String],
        inout indexes_for_key_var: List[Int]
    ):
        var tmp_var_names = List[String]()
        var tmp_var_nums = List[Int]()
        for _ in range(key_count):
            tmp_var_names.append("")
            tmp_var_nums.append(0)

        GetVariableKeys(
            state,
            self.m_variMeter,
            type_var,
            tmp_var_names,
            tmp_var_nums
        )

        names_of_keys.clear()
        indexes_for_key_var.clear()
        for i_key in range(key_count):
            indexes_for_key_var.append(tmp_var_nums[i_key])
            names_of_keys.append(tmp_var_names[i_key])
