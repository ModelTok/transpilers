# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: struct from EnergyPlus.Autosizing.Base
# - AutoSizingType: enum from EnergyPlus.Autosizing.Base (value: HeatingWaterDesCoilWaterVolFlowUsedForUASizing)
# - ReportCoilSelection: utility module from EnergyPlus.ReportCoilSelection
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData

from typing import AnyType


struct TermUnitSizingData:
    var ReheatLoadMult: Float64


struct BaseSizer:
    fn checkInitialized(self, state: AnyType, errorsFound: List[Bool]) -> Bool:
        return False
    
    fn preSize(self, state: AnyType, originalValue: Float64) -> None:
        pass
    
    fn selectSizerOutput(self, state: AnyType, errorsFound: List[Bool]) -> None:
        pass


fn setCoilWaterFlowPltSizNum(
    state: AnyType,
    coilReportNum: Int,
    autoSizedValue: Float64,
    wasAutoSized: Bool,
    dataPltSizHeatNum: Int,
    dataWaterLoopNum: Int
) -> None:
    pass


fn setCoilReheatMultiplier(state: AnyType, coilReportNum: Int, multiplier: Float64) -> None:
    pass


struct HeatingWaterDesCoilWaterVolFlowUsedForUASizer(BaseSizer):
    var sizingType: String
    var sizingString: String
    var curZoneEqNum: Int
    var wasAutoSized: Bool
    var sizingDesRunThisZone: Bool
    var termUnitSingDuct: Bool
    var zoneEqFanCoil: Bool
    var termUnitPIU: Bool
    var termUnitIU: Bool
    var curTermUnitSizingNum: Int
    var dataWaterFlowUsedForSizing: Float64
    var termUnitSizing: List[TermUnitSizingData]
    var autoSizedValue: Float64
    var curSysNum: Int
    var sizingDesRunThisAirSys: Bool
    var overrideSizeString: Bool
    var isCoilReportObject: Bool
    var coilReportNum: Int
    var dataPltSizHeatNum: Int
    var dataWaterLoopNum: Int
    
    fn __init__(inout self):
        self.sizingType = "HeatingWaterDesCoilWaterVolFlowUsedForUASizing"
        self.sizingString = "Design Water Volume Flow Rate Used for UA Sizing [m3/s]"
        self.curZoneEqNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.termUnitSingDuct = False
        self.zoneEqFanCoil = False
        self.termUnitPIU = False
        self.termUnitIU = False
        self.curTermUnitSizingNum = 0
        self.dataWaterFlowUsedForSizing = 0.0
        self.termUnitSizing = List[TermUnitSizingData]()
        self.autoSizedValue = 0.0
        self.curSysNum = 0
        self.sizingDesRunThisAirSys = False
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.coilReportNum = 0
        self.dataPltSizHeatNum = 0
        self.dataWaterLoopNum = 0
    
    fn size(inout self, state: AnyType, originalValue: Float64, inout errorsFound: List[Bool]) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        
        self.preSize(state, originalValue)
        
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitSingDuct or self.zoneEqFanCoil:
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing
                elif (self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.termUnitSizing[self.curTermUnitSizingNum - 1].ReheatLoadMult
                else:
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                self.autoSizedValue = self.dataWaterFlowUsedForSizing
        
        if self.overrideSizeString:
            self.sizingString = "Design Water Volume Flow Rate Used for UA Sizing [m3/s]"
        
        self.selectSizerOutput(state, errorsFound)
        
        if self.isCoilReportObject:
            setCoilWaterFlowPltSizNum(
                state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized,
                self.dataPltSizHeatNum, self.dataWaterLoopNum
            )
            if self.termUnitSingDuct or self.zoneEqFanCoil or ((self.termUnitPIU or self.termUnitIU) and self.curTermUnitSizingNum > 0):
                setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
        
        return self.autoSizedValue
