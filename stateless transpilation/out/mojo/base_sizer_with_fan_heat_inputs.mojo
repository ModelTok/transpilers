# EXTERNAL DEPS (to wire in glue):
#   BaseSizer - from EnergyPlus.Autosizing.Base
#       fields: primaryAirSystem, curSysNum, curOASysNum, dataFanType, dataFanIndex,
#       isFanReportObject, dataDesAccountForFanHeat
#       methods: initializeWithinEP, clearState
#   BaseGlobalStruct - from EnergyPlus.Data.BaseData
#       methods: init_constant_state, init_state, clear_state
#   EnergyPlusData - state object from EnergyPlus.Data.EnergyPlusData
#   HVAC - from EnergyPlus.api with FanType enum
#   Fan objects in state.dataFans.fans with getInputsForDesignHeatGain method

from collections import List

struct BaseSizer:
    var primaryAirSystem: List[Any]
    var curSysNum: Int
    var curOASysNum: Int
    var dataFanType: Any
    var dataFanIndex: Int
    var isFanReportObject: Bool
    var dataDesAccountForFanHeat: Bool
    
    fn __init__(inout self):
        self.primaryAirSystem = List[Any]()
        self.curSysNum = 0
        self.curOASysNum = 0
        self.dataFanType = None
        self.dataFanIndex = 0
        self.isFanReportObject = False
        self.dataDesAccountForFanHeat = False
    
    fn initializeWithinEP(inout self, state: Any, _compType: StringLiteral,
                         _compName: StringLiteral, _printWarningFlag: Bool,
                         _callingRoutine: StringLiteral) -> None:
        pass
    
    fn clearState(inout self) -> None:
        pass

struct BaseSizerWithFanHeatInputs(BaseSizer):
    var deltaP: Float64 = 0.0
    var motEff: Float64 = 0.0
    var totEff: Float64 = 0.0
    var motInAirFrac: Float64 = 0.0
    var fanCompModel: Bool = False
    var fanShaftPow: Float64 = 0.0
    var motInPower: Float64 = 0.0
    
    fn getFanInputsForDesHeatGain(inout self, state: Any, fanIndex: Int,
                                 inout deltaP: Float64, inout motEff: Float64,
                                 inout totEff: Float64, inout motInAirFrac: Float64,
                                 inout fanShaftPow: Float64, inout motInPower: Float64,
                                 inout fanCompModel: Bool) -> None:
        if fanIndex <= 0 or self.isFanReportObject:
            return
        
        state.dataFans.fans[fanIndex - 1].getInputsForDesignHeatGain(
            state, deltaP, motEff, totEff, motInAirFrac, fanShaftPow, motInPower, fanCompModel
        )
    
    fn calcFanDesHeatGain(self, airVolFlow: Float64) -> Float64:
        if self.dataFanType is None or self.dataFanIndex == 0:
            return 0.0
        if self.fanCompModel:
            return self.fanShaftPow + (self.motInPower - self.fanShaftPow) * self.motInAirFrac
        var fanPowerTot: Float64 = (airVolFlow * self.deltaP) / self.totEff
        return self.motEff * fanPowerTot + (fanPowerTot - self.motEff * fanPowerTot) * self.motInAirFrac
    
    fn initializeWithinEP(inout self, state: Any, _compType: StringLiteral,
                         _compName: StringLiteral, _printWarningFlag: Bool,
                         _callingRoutine: StringLiteral) -> None:
        BaseSizer.initializeWithinEP(self, state, _compType, _compName, _printWarningFlag, _callingRoutine)
        self.dataDesAccountForFanHeat = state.dataSize.DataDesAccountForFanHeat
        
        if len(self.primaryAirSystem) > 0 and self.curSysNum > 0 and self.curOASysNum == 0:
            var sys_item = self.primaryAirSystem[self.curSysNum - 1]
            if sys_item.supFanType is not HVAC.FanType.Invalid:
                self.dataFanType = sys_item.supFanType
                self.dataFanIndex = sys_item.supFanNum
        
        var deltaP_val: Float64 = self.deltaP
        var motEff_val: Float64 = self.motEff
        var totEff_val: Float64 = self.totEff
        var motInAirFrac_val: Float64 = self.motInAirFrac
        var fanShaftPow_val: Float64 = self.fanShaftPow
        var motInPower_val: Float64 = self.motInPower
        var fanCompModel_val: Bool = self.fanCompModel
        
        self.getFanInputsForDesHeatGain(state, self.dataFanIndex, deltaP_val, motEff_val,
                                       totEff_val, motInAirFrac_val, fanShaftPow_val,
                                       motInPower_val, fanCompModel_val)
        
        self.deltaP = deltaP_val
        self.motEff = motEff_val
        self.totEff = totEff_val
        self.motInAirFrac = motInAirFrac_val
        self.fanShaftPow = fanShaftPow_val
        self.motInPower = motInPower_val
        self.fanCompModel = fanCompModel_val
    
    fn setDataDesAccountForFanHeat(inout self, state: Any, flag: Bool) -> None:
        state.dataSize.DataDesAccountForFanHeat = flag
    
    fn clearState(inout self) -> None:
        BaseSizer.clearState(self)
        self.deltaP = 0.0
        self.motEff = 0.0
        self.totEff = 0.0
        self.motInAirFrac = 0.0
        self.fanCompModel = False
        self.fanShaftPow = 0.0
        self.motInPower = 0.0

struct BaseGlobalStruct:
    fn init_constant_state(inout self, state: Any) -> None:
        pass
    
    fn init_state(inout self, state: Any) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        pass

struct BaseSizerWithFanHeatInputsData(BaseGlobalStruct):
    fn init_constant_state(inout self, state: Any) -> None:
        pass
    
    fn init_state(inout self, state: Any) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        pass
