from Base import BaseSizer, AutoSizingType, AutoSizingResultType
from EnergyPlusData import EnergyPlusData
struct CoolingWaterNumofTubesPerRowSizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterNumofTubesPerRowSizing
        self.sizingString = "Number of Tubes per Row"
    def __del__(owned self):

    def size(inout self, state: EnergyPlusData, originalValue: Float64, errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if not self.wasAutoSized and (self.dataPltSizCoolNum == 0 or self.plantSizData.size() == 0):
            self.autoSizedValue = originalValue
        elif not self.wasAutoSized and self.dataPltSizCoolNum <= self.plantSizData.size():
            self.autoSizedValue = Int(max(3.0, 13750.0 * self.dataWaterFlowUsedForSizing + 1.0))
        elif self.wasAutoSized and self.dataPltSizCoolNum > 0 and self.dataPltSizCoolNum <= self.plantSizData.size():
            self.autoSizedValue = Int(max(3.0, 13750.0 * self.dataWaterFlowUsedForSizing + 1.0))
        else:
            self.errorType = AutoSizingResultType.ErrorType1
        if self.overrideSizeString:
            self.sizingString = "Number of Tubes per Row"
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue