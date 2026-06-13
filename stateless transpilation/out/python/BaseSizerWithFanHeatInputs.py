# EXTERNAL DEPS (to wire in glue):
#   BaseSizer - from EnergyPlus.Autosizing.Base
#       base class with: primaryAirSystem (list-like), curSysNum, curOASysNum, dataFanType,
#       dataFanIndex, isFanReportObject, dataDesAccountForFanHeat; methods initializeWithinEP, clearState
#   BaseGlobalStruct - from EnergyPlus.Data.BaseData
#       base class with: init_constant_state, init_state, clear_state methods
#   EnergyPlusData - from EnergyPlus.Data.EnergyPlusData
#       .dataSize.DataDesAccountForFanHeat; .dataFans.fans (list-like)
#   HVAC - from EnergyPlus.api
#       .FanType.Invalid enum sentinel
#   Fan objects in state.dataFans.fans
#       method getInputsForDesignHeatGain(state, deltaP, motEff, totEff, motInAirFrac, fanShaftPow, motInPower, fanCompModel)

from typing import Any

class BaseSizer:
    def __init__(self):
        self.primaryAirSystem = []
        self.curSysNum = 0
        self.curOASysNum = 0
        self.dataFanType = None
        self.dataFanIndex = 0
        self.isFanReportObject = False
        self.dataDesAccountForFanHeat = False
    
    def initializeWithinEP(self, state: Any, _compType: str, _compName: str,
                          _printWarningFlag: bool, _callingRoutine: str) -> None:
        pass
    
    def clearState(self) -> None:
        pass

class BaseGlobalStruct:
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        pass

class _FanType:
    Invalid = None

class _HVAC:
    FanType = _FanType()

HVAC = _HVAC()

class BaseSizerWithFanHeatInputs(BaseSizer):
    def __init__(self):
        super().__init__()
        self.deltaP = 0.0
        self.motEff = 0.0
        self.totEff = 0.0
        self.motInAirFrac = 0.0
        self.fanCompModel = False
        self.fanShaftPow = 0.0
        self.motInPower = 0.0
    
    def getFanInputsForDesHeatGain(self, state: Any, fanIndex: int,
                                   deltaP: list, motEff: list, totEff: list,
                                   motInAirFrac: list, fanShaftPow: list,
                                   motInPower: list, fanCompModel: list) -> None:
        if fanIndex <= 0 or self.isFanReportObject:
            return
        
        state.dataFans.fans[fanIndex - 1].getInputsForDesignHeatGain(
            state, deltaP, motEff, totEff, motInAirFrac, fanShaftPow, motInPower, fanCompModel
        )
    
    def calcFanDesHeatGain(self, airVolFlow: float) -> float:
        if self.dataFanType is None or self.dataFanIndex == 0:
            return 0.0
        if self.fanCompModel:
            return self.fanShaftPow + (self.motInPower - self.fanShaftPow) * self.motInAirFrac
        fanPowerTot = (airVolFlow * self.deltaP) / self.totEff
        return self.motEff * fanPowerTot + (fanPowerTot - self.motEff * fanPowerTot) * self.motInAirFrac
    
    def initializeWithinEP(self, state: Any, _compType: str, _compName: str,
                          _printWarningFlag: bool, _callingRoutine: str) -> None:
        super().initializeWithinEP(state, _compType, _compName, _printWarningFlag, _callingRoutine)
        self.dataDesAccountForFanHeat = state.dataSize.DataDesAccountForFanHeat
        
        if len(self.primaryAirSystem) > 0 and self.curSysNum > 0 and self.curOASysNum == 0:
            sys_item = self.primaryAirSystem[self.curSysNum - 1]
            if sys_item.supFanType is not HVAC.FanType.Invalid:
                self.dataFanType = sys_item.supFanType
                self.dataFanIndex = sys_item.supFanNum
        
        deltaP = [self.deltaP]
        motEff = [self.motEff]
        totEff = [self.totEff]
        motInAirFrac = [self.motInAirFrac]
        fanShaftPow = [self.fanShaftPow]
        motInPower = [self.motInPower]
        fanCompModel = [self.fanCompModel]
        
        self.getFanInputsForDesHeatGain(state, self.dataFanIndex, deltaP, motEff, totEff,
                                       motInAirFrac, fanShaftPow, motInPower, fanCompModel)
        
        self.deltaP = deltaP[0]
        self.motEff = motEff[0]
        self.totEff = totEff[0]
        self.motInAirFrac = motInAirFrac[0]
        self.fanShaftPow = fanShaftPow[0]
        self.motInPower = motInPower[0]
        self.fanCompModel = fanCompModel[0]
    
    def setDataDesAccountForFanHeat(self, state: Any, flag: bool) -> None:
        state.dataSize.DataDesAccountForFanHeat = flag
    
    def clearState(self) -> None:
        super().clearState()
        self.deltaP = 0.0
        self.motEff = 0.0
        self.totEff = 0.0
        self.motInAirFrac = 0.0
        self.fanCompModel = False
        self.fanShaftPow = 0.0
        self.motInPower = 0.0

class BaseSizerWithFanHeatInputsData(BaseGlobalStruct):
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        pass
