from Base import BaseSizer
from ...Data.EnergyPlusData import EnergyPlusData
from ...ReportCoilSelection import ReportCoilSelection
from ...Autosizing.Base import AutoSizingType
struct HeatingWaterDesCoilWaterVolFlowUsedForUASizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.HeatingWaterDesCoilWaterVolFlowUsedForUASizing
        self.sizingString = "Design Water Volume Flow Rate Used for UA Sizing [m3/s]"
    def __del__(owned self):

    def size(inout self, state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                if self.termUnitSingDuct or self.zoneEqFanCoil:
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing
                elif (self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.termUnitSizing[self.curTermUnitSizingNum - 1].ReheatLoadMult
                else:
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                self.autoSizedValue = self.dataWaterFlowUsedForSizing
        if self.overrideSizeString:
            self.sizingString = "Design Water Volume Flow Rate Used for UA Sizing [m3/s]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilWaterFlowPltSizNum(
                state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized, self.dataPltSizHeatNum, self.dataWaterLoopNum)
            if self.termUnitSingDuct or self.zoneEqFanCoil or ((self.termUnitPIU or self.termUnitIU) and self.curTermUnitSizingNum > 0):
                ReportCoilSelection.setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
        return self.autoSizedValue