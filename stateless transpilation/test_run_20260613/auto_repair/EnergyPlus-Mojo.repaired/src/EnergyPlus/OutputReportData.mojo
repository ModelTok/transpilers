from string import String
from vector import Vector
from Array1D import Array1D
from Array2D import Array2D
from Array2S import Array2S
from EnergyPlus import EnergyPlusData
from OutputProcessor import OutputProcessor, GetVariableKeyCountandType, GetVariableKeys
from Constant import Constant

struct AnnualFieldSet:
    enum AggregationKind:
        case sumOrAvg
        case maximum
        case minimum
        case hoursNonZero
        case hoursZero
        case hoursPositive
        case hoursNonPositive
        case hoursNegative
        case hoursNonNegative
        case hoursInTenPercentBins
        case hoursInTenBinsMinToMax
        case hoursInTenBinsZeroToMax
        case hoursInTenBinsMinToZero
        case hoursInTenBinsPlusMinusTwoStdDev
        case hoursInTenBinsPlusMinusThreeStdDev
        case noAggregation
        case valueWhenMaxMin
        case sumOrAverageHoursShown
        case maximumDuringHoursShown
        case minimumDuringHoursShown

    struct AnnualCell:
        var indexesForKeyVar: Int
        var result: Float64
        var duration: Float64
        var timeStamp: Int
        var deferredResults: Vector[Float64]
        var deferredElapsed: Vector[Float64]
        var m_timeAboveTopBin: Float64
        var m_timeBelowBottomBin: Float64
        var m_timeInBin: Vector[Float64]

    var m_variMeter: String
    var m_colHead: String
    var m_aggregate: AggregationKind
    var m_showDigits: Int
    var m_varUnits: Constant.Units
    var m_typeOfVar: OutputProcessor.VariableType
    var m_keyCount: Int
    var m_varAvgSum: OutputProcessor.StoreType
    var m_varStepType: OutputProcessor.TimeStepType
    var m_namesOfKeys: Vector[String]
    var m_indexesForKeyVar: Vector[Int]
    var m_cell: Vector[AnnualCell]
    var m_bottomBinValue: Float64
    var m_topBinValue: Float64
    var m_timeAboveTopBinTotal: Float64
    var m_timeBelowBottomBinTotal: Float64
    var m_timeInBinTotal: Vector[Float64]

    def __init__(inout self):
        self.m_aggregate = AggregationKind.sumOrAvg
        self.m_showDigits = 2
        self.m_varUnits = Constant.Units.None
        self.m_typeOfVar = OutputProcessor.VariableType.Invalid
        self.m_keyCount = 0
        self.m_varAvgSum = OutputProcessor.StoreType.Invalid
        self.m_varStepType = OutputProcessor.TimeStepType.Invalid
        self.m_bottomBinValue = -999.0
        self.m_topBinValue = -999.0
        self.m_timeAboveTopBinTotal = 0.0
        self.m_timeBelowBottomBinTotal = 0.0

    def __init__(inout self, varName: String, kindOfAggregation: AggregationKind, numDigitsShown: Int):
        self.m_variMeter = varName
        self.m_aggregate = kindOfAggregation
        self.m_showDigits = numDigitsShown
        self.m_varUnits = Constant.Units.None
        self.m_typeOfVar = OutputProcessor.VariableType.Invalid
        self.m_keyCount = 0
        self.m_varAvgSum = OutputProcessor.StoreType.Invalid
        self.m_varStepType = OutputProcessor.TimeStepType.Invalid
        self.m_bottomBinValue = -999.0
        self.m_topBinValue = -999.0
        self.m_timeAboveTopBinTotal = 0.0
        self.m_timeBelowBottomBinTotal = 0.0

    def getVariableKeyCountandTypeFromFldSt(inout self, inout state: EnergyPlusData, inout typeVar: OutputProcessor.VariableType, inout avgSumVar: OutputProcessor.StoreType, inout stepTypeVar: OutputProcessor.TimeStepType, inout unitsVar: Constant.Units) -> Int:
        var numkeys: Int = 0
        GetVariableKeyCountandType(state, self.m_variMeter, numkeys, typeVar, avgSumVar, stepTypeVar, unitsVar)
        return numkeys

    def getVariableKeysFromFldSt(inout self, inout state: EnergyPlusData, inout typeVar: OutputProcessor.VariableType, keyCount: Int, inout namesOfKeys: Vector[String], inout indexesForKeyVar: Vector[Int]):
        var tmpVarNums: Array1D[Int]
        var tmpVarNames: Array1D[String]
        tmpVarNums.allocate(keyCount)
        tmpVarNames.allocate(keyCount)
        GetVariableKeys(state, self.m_variMeter, typeVar, tmpVarNames, tmpVarNums)
        namesOfKeys.clear()
        indexesForKeyVar.clear()
        for iKey in range(1, keyCount + 1):
            indexesForKeyVar.push_back(tmpVarNums[iKey - 1])
            namesOfKeys.push_back(tmpVarNames[iKey - 1])