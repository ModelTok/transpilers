from Base import BaseSizer
from Data.BaseData import BaseGlobalStruct
from api.TypeDefs import *
@value
struct BaseSizerWithFanHeatInputs(BaseSizer):
    var deltaP: Float64 = 0.0
    var motEff: Float64 = 0.0
    var totEff: Float64 = 0.0
    var motInAirFrac: Float64 = 0.0
    var fanCompModel: Bool = False
    var fanShaftPow: Float64 = 0.0
    var motInPower: Float64 = 0.0
    def getFanInputsForDesHeatGain(inout self, inout state: EnergyPlusData, fanIndex: Int32, inout deltaP: Float64, inout motEff: Float64, inout totEff: Float64, inout motInAirFrac: Float64, inout fanShaftPow: Float64, inout motInPower: Float64, inout fanCompModel: Bool):

    def calcFanDesHeatGain(inout self, airVolFlow: Float64) -> Float64:
        return 0.0
    def initializeWithinEP(inout self, inout state: EnergyPlusData, _compType: StringLiteral, _compName: StringLiteral, _printWarningFlag: Bool, _callingRoutine: StringLiteral):

    def setDataDesAccountForFanHeat(inout self, inout state: EnergyPlusData, flag: Bool):

    def clearState(inout self):
        self.clearState()  # base call
        self.deltaP = 0.0
        self.motEff = 0.0
        self.totEff = 0.0
        self.motInAirFrac = 0.0
        self.fanCompModel = False
        self.fanShaftPow = 0.0
        self.motInPower = 0.0
@value
struct BaseSizerWithFanHeatInputsData(BaseGlobalStruct):
    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):

def initializeWithinEP(inout self: BaseSizerWithFanHeatInputs, inout state: EnergyPlusData, inout _compType: StringLiteral, inout _compName: StringLiteral, inout _printWarningFlag: Bool, inout _callingRoutine: StringLiteral):
    self.initializeWithinEP(state, _compType, _compName, _printWarningFlag, _callingRoutine)
    self.dataDesAccountForFanHeat = state.dataSize.DataDesAccountForFanHeat
    if not (self.primaryAirSystem.empty()) and self.curSysNum > 0 and self.curOASysNum == 0:
        if self.primaryAirSystem[self.curSysNum - 1].supFanType != HVAC.FanType.Invalid:  # 1-based to 0-based
            self.dataFanType = self.primaryAirSystem[self.curSysNum - 1].supFanType  # 1-based to 0-based
            self.dataFanIndex = self.primaryAirSystem[self.curSysNum - 1].supFanNum  # 1-based to 0-based
    self.getFanInputsForDesHeatGain(state,
                                     self.dataFanIndex,
                                     self.deltaP,
                                     self.motEff,
                                     self.totEff,
                                     self.motInAirFrac,
                                     self.fanShaftPow,
                                     self.motInPower,
                                     self.fanCompModel)
def calcFanDesHeatGain(inout self: BaseSizerWithFanHeatInputs, airVolFlow: Float64) -> Float64:
    if self.dataFanType == HVAC.FanType.Invalid or self.dataFanIndex == 0:
        return 0.0
    if self.fanCompModel:
        return self.fanShaftPow + (self.motInPower - self.fanShaftPow) * self.motInAirFrac
    var fanPowerTot: Float64 = (airVolFlow * self.deltaP) / self.totEff
    return self.motEff * fanPowerTot + (fanPowerTot - self.motEff * fanPowerTot) * self.motInAirFrac
def getFanInputsForDesHeatGain(inout self: BaseSizerWithFanHeatInputs, inout state: EnergyPlusData, fanIndex: Int32, inout deltaP: Float64, inout motEff: Float64, inout totEff: Float64, inout motInAirFrac: Float64, inout fanShaftPow: Float64, inout motInPower: Float64, inout fanCompModel: Bool):
    if fanIndex <= 0 or self.isFanReportObject:
        return
    state.dataFans.fans[fanIndex - 1].getInputsForDesignHeatGain(state, deltaP, motEff, totEff, motInAirFrac, fanShaftPow, motInPower, fanCompModel)  # 1-based to 0-based
def setDataDesAccountForFanHeat(inout self: BaseSizerWithFanHeatInputs, inout state: EnergyPlusData, flag: Bool):
    state.dataSize.DataDesAccountForFanHeat = flag