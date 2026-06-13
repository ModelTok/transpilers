# EXTERNAL DEPS (to wire in glue):
# - BaseSizer (from EnergyPlus.Autosizing.Base)
# - AutoSizingType enum (from EnergyPlus.Autosizing.Base)
# - AutoSizingResultType enum (from EnergyPlus.Autosizing.Base)
# - EnergyPlusData (from EnergyPlus.Data.EnergyPlusData)
# - ReportCoilSelection (from EnergyPlus)


struct AutoSizingType:
    alias CoolingWaterDesWaterInletTempSizing = Int32(0)


struct AutoSizingResultType:
    alias ErrorType1 = Int32(0)


struct EnergyPlusData:
    pass


struct PlantSizData:
    var ExitTemp: Float64


struct ReportCoilSelection:
    @staticmethod
    fn setCoilEntWaterTemp(state: EnergyPlusData, coil_report_num: Int32, value: Float64):
        pass


struct CoolingWaterDesWaterInletTempSizer:
    var sizingType: Int32
    var sizingString: String
    var wasAutoSized: Bool
    var dataPltSizCoolNum: Int32
    var plantSizData: List[PlantSizData]
    var autoSizedValue: Float64
    var errorType: Int32
    var overrideSizeString: Bool
    var isCoilReportObject: Bool
    var coilReportNum: Int32
    
    fn __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterDesWaterInletTempSizing
        self.sizingString = "Design Inlet Water Temperature [C]"
        self.wasAutoSized = False
        self.dataPltSizCoolNum = 0
        self.plantSizData = List[PlantSizData]()
        self.autoSizedValue = 0.0
        self.errorType = 0
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.coilReportNum = 0
    
    fn checkInitialized(self, state: EnergyPlusData, errors_found: List[Bool]) -> Bool:
        return True
    
    fn preSize(inout self, state: EnergyPlusData, original_value: Float64):
        pass
    
    fn selectSizerOutput(inout self, state: EnergyPlusData, errors_found: List[Bool]):
        pass
    
    fn size(inout self, state: EnergyPlusData, original_value: Float64, errors_found: List[Bool]) -> Float64:
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
