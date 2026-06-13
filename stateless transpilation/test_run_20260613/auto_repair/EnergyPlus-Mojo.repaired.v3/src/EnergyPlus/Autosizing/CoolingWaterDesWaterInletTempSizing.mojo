from Base import BaseSizer
from Data.EnergyPlusData import EnergyPlusData
from Base import AutoSizingType, AutoSizingResultType
from ReportCoilSelection import ReportCoilSelection
struct CoolingWaterDesWaterInletTempSizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterDesWaterInletTempSizing
        self.sizingString = "Design Inlet Water Temperature [C]"
    def __del__(owned self):

    def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if not self.wasAutoSized and (self.dataPltSizCoolNum == 0 or len(self.plantSizData) == 0):
            self.autoSizedValue = originalValue
        elif not self.wasAutoSized and self.dataPltSizCoolNum <= len(self.plantSizData):
            self.autoSizedValue = self.plantSizData[self.dataPltSizCoolNum - 1].ExitTemp
        elif self.wasAutoSized and self.dataPltSizCoolNum > 0 and self.dataPltSizCoolNum <= len(self.plantSizData):
            self.autoSizedValue = self.plantSizData[self.dataPltSizCoolNum - 1].ExitTemp
        else:
            self.errorType = AutoSizingResultType.ErrorType1
        if self.overrideSizeString:
            self.sizingString = "Design Inlet Water Temperature [C]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilEntWaterTemp(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue