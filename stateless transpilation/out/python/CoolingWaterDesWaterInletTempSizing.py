# EXTERNAL DEPS (to wire in glue):
# - BaseSizer (from EnergyPlus.Autosizing.Base)
# - AutoSizingType enum (from EnergyPlus.Autosizing.Base)
# - AutoSizingResultType enum (from EnergyPlus.Autosizing.Base)
# - EnergyPlusData (from EnergyPlus.Data.EnergyPlusData)
# - ReportCoilSelection (from EnergyPlus)


class BaseSizer:
    def __init__(self):
        self.sizingType = None
        self.sizingString = ""
        self.wasAutoSized = False
        self.dataPltSizCoolNum = 0
        self.plantSizData = []
        self.autoSizedValue = 0.0
        self.errorType = None
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.coilReportNum = 0
    
    def checkInitialized(self, state, errors_found):
        raise NotImplementedError
    
    def preSize(self, state, original_value):
        raise NotImplementedError
    
    def selectSizerOutput(self, state, errors_found):
        raise NotImplementedError


class AutoSizingType:
    CoolingWaterDesWaterInletTempSizing = None


class AutoSizingResultType:
    ErrorType1 = None


class ReportCoilSelection:
    @staticmethod
    def setCoilEntWaterTemp(state, coil_report_num, value):
        raise NotImplementedError


class CoolingWaterDesWaterInletTempSizer(BaseSizer):
    def __init__(self):
        super().__init__()
        self.sizingType = AutoSizingType.CoolingWaterDesWaterInletTempSizing
        self.sizingString = "Design Inlet Water Temperature [C]"
    
    def size(self, state, original_value, errors_found):
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        
        if not self.wasAutoSized and (self.dataPltSizCoolNum == 0 or len(self.plantSizData) == 0):
            self.autoSizedValue = original_value
        elif not self.wasAutoSized and self.dataPltSizCoolNum <= len(self.plantSizData):
            self.autoSizedValue = self.plantSizData[self.dataPltSizCoolNum - 1].ExitTemp
        elif self.wasAutoSized and self.dataPltSizCoolNum > 0 and self.dataPltSizCoolNum <= len(self.plantSizData):
            self.autoSizedValue = self.plantSizData[self.dataPltSizCoolNum - 1].ExitTemp
        else:
            self.errorType = AutoSizingResultType.ErrorType1
        
        if self.overrideSizeString:
            self.sizingString = "Design Inlet Water Temperature [C]"
        
        self.selectSizerOutput(state, errors_found)
        
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilEntWaterTemp(state, self.coilReportNum, self.autoSizedValue)
        
        return self.autoSizedValue
