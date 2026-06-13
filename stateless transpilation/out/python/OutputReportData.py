from typing import List
from enum import Enum
from dataclasses import dataclass, field

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state, from EnergyPlus)
# - OutputProcessor.VariableType (enum, from EnergyPlus.OutputProcessor)
# - OutputProcessor.StoreType (enum, from EnergyPlus.OutputProcessor)
# - OutputProcessor.TimeStepType (enum, from EnergyPlus.OutputProcessor)
# - Constant.Units (enum, from EnergyPlus.Constant)
# - GetVariableKeyCountandType(state, varname, numkeys, typevar, avgsumvar, steptypevar, unitsvar) (from EnergyPlus.OutputProcessor)
# - GetVariableKeys(state, varname, typevar, namesofkeys, indexesforkey) (from EnergyPlus.OutputProcessor)


class AggregationKind(Enum):
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


@dataclass
class AnnualCell:
    indexesForKeyVar: int = 0
    result: float = 0.0
    duration: float = 0.0
    timeStamp: int = 0
    deferredResults: List[float] = field(default_factory=list)
    deferredElapsed: List[float] = field(default_factory=list)
    m_timeAboveTopBin: float = 0.0
    m_timeBelowBottomBin: float = 0.0
    m_timeInBin: List[float] = field(default_factory=list)


class AnnualFieldSet:
    def __init__(
        self,
        var_name: str = "",
        kind_of_aggregation: AggregationKind = None,
        num_digits_shown: int = 2
    ):
        if kind_of_aggregation is None:
            kind_of_aggregation = AggregationKind.sumOrAvg
        self.m_variMeter = var_name
        self.m_colHead = ""
        self.m_aggregate = kind_of_aggregation
        self.m_showDigits = num_digits_shown
        self.m_varUnits = None
        self.m_typeOfVar = None
        self.m_keyCount = 0
        self.m_varAvgSum = None
        self.m_varStepType = None
        self.m_namesOfKeys: List[str] = []
        self.m_indexesForKeyVar: List[int] = []
        self.m_cell: List[AnnualCell] = []
        self.m_bottomBinValue = -999.0
        self.m_topBinValue = -999.0
        self.m_timeAboveTopBinTotal = 0.0
        self.m_timeBelowBottomBinTotal = 0.0
        self.m_timeInBinTotal: List[float] = []

    def getVariableKeyCountandTypeFromFldSt(
        self,
        state,
        typeVar,
        avgSumVar,
        stepTypeVar,
        unitsVar
    ) -> int:
        numkeys = [0]
        GetVariableKeyCountandType(
            state,
            self.m_variMeter,
            numkeys,
            typeVar,
            avgSumVar,
            stepTypeVar,
            unitsVar
        )
        return numkeys[0]

    def getVariableKeysFromFldSt(
        self,
        state,
        typeVar,
        keyCount: int,
        namesOfKeys: List[str],
        indexesForKeyVar: List[int]
    ) -> None:
        tmp_var_names = [""] * keyCount
        tmp_var_nums = [0] * keyCount
        GetVariableKeys(
            state,
            self.m_variMeter,
            typeVar,
            tmp_var_names,
            tmp_var_nums
        )
        namesOfKeys.clear()
        indexesForKeyVar.clear()
        for i_key in range(keyCount):
            indexesForKeyVar.append(tmp_var_nums[i_key])
            namesOfKeys.append(tmp_var_names[i_key])
