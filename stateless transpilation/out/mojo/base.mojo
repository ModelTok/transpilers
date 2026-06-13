# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object (EnergyPlus)
# - DataSizing: enum OAControl, data structures ZoneSizingInputData, ZoneEqSizingData, TermUnitSizingData,
#   TermUnitZoneSizingData, ZoneSizingData, SystemSizingData, SystemSizingInputData, PlantSizingData
# - DataAirLoop: structures OutsideAirSysProps, AirLoopControlData
# - DataAirSystems: structure DefinePrimaryAirSystem
# - AirLoopHVACDOAS: structure AirLoopDOAS
# - HVAC: enums CoilType, FanType, AirDuctType, FanPlace, FanOp; array coilTypeNamesUC
# - DataPlant: structure PlantLoop, enum PlantEquipmentType, array PlantEquipTypeNames
# - ReportCoilSelection.getReportIndex(state, name, coil_type) -> Int
# - OutputReportPredefined: AddCompSizeTableEntry, AddCompSizeTableStrEntry functions
# - Psychrometrics.PsyRhoAirFnPbTdbW(state, press, tdb, w) -> Float64
# - Util: SameString, FindItemInList, makeUPPER functions
# - ShowSevereError, ShowFatalError, ShowContinueError, ShowMessage functions
# - getEnumValue(mapping, name) -> Int
# - DataEnvironment: constants and state members

from math import abs, pow, min

struct AutoSizingType:
    alias Invalid = -1
    alias CoolingAirFlowSizing = 1
    alias CoolingWaterflowSizing = 2
    alias HeatingWaterflowSizing = 3
    alias CoolingWaterDesAirInletTempSizing = 4
    alias CoolingWaterDesAirInletHumRatSizing = 5
    alias CoolingWaterDesWaterInletTempSizing = 6
    alias CoolingWaterDesAirOutletTempSizing = 7
    alias CoolingWaterDesAirOutletHumRatSizing = 8
    alias CoolingWaterNumofTubesPerRowSizing = 9
    alias HeatingWaterDesAirInletTempSizing = 10
    alias HeatingWaterDesAirInletHumRatSizing = 11
    alias HeatingWaterDesCoilLoadUsedForUASizing = 12
    alias HeatingWaterDesCoilWaterVolFlowUsedForUASizing = 13
    alias HeatingAirFlowSizing = 14
    alias HeatingAirflowUASizing = 15
    alias SystemAirFlowSizing = 16
    alias CoolingCapacitySizing = 17
    alias HeatingCapacitySizing = 18
    alias WaterHeatingCapacitySizing = 19
    alias WaterHeatingCoilUASizing = 20
    alias SystemCapacitySizing = 21
    alias CoolingSHRSizing = 22
    alias HeatingDefrostSizing = 23
    alias MaxHeaterOutletTempSizing = 24
    alias AutoCalculateSizing = 25
    alias ZoneCoolingLoadSizing = 26
    alias ZoneHeatingLoadSizing = 27
    alias MinSATempCoolingSizing = 28
    alias MaxSATempHeatingSizing = 29
    alias ASHRAEMinSATCoolingSizing = 30
    alias ASHRAEMaxSATHeatingSizing = 31
    alias HeatingCoilDesAirInletTempSizing = 32
    alias HeatingCoilDesAirOutletTempSizing = 33
    alias HeatingCoilDesAirInletHumRatSizing = 34
    alias DesiccantDehumidifierBFPerfDataFaceVelocitySizing = 35
    alias Num = 36


struct AutoSizingResultType:
    alias Invalid = -1
    alias NoError = 0
    alias ErrorType1 = 1
    alias ErrorType2 = 2
    alias Num = 3


struct BaseSizer:
    var stdRhoAir: Float64
    var zoneAirFlowSizMethod: Int32
    var dataScalableSizingON: Bool
    var dataScalableCapSizingON: Bool
    var isCoilReportObject: Bool
    var coilReportNum: Int32
    var isFanReportObject: Bool
    var initialized: Bool
    var errorType: Int32
    var sizingType: Int32
    var sizingString: String
    var sizingStringScalable: String
    var overrideSizeString: Bool
    var originalValue: Float64
    var autoSizedValue: Float64
    var wasAutoSized: Bool
    var hardSizeNoDesignRun: Bool
    var sizingDesRunThisAirSys: Bool
    var sizingDesRunThisZone: Bool
    var sizingDesValueFromParent: Bool
    var airLoopSysFlag: Bool
    var oaSysFlag: Bool
    var coilType: Int32
    var compType: String
    var compName: String
    var isEpJSON: Bool
    var sysSizingRunDone: Bool
    var zoneSizingRunDone: Bool
    var curSysNum: Int32
    var curOASysNum: Int32
    var curZoneEqNum: Int32
    var curDuctType: Int32
    var curTermUnitSizingNum: Int32
    var numPrimaryAirSys: Int32
    var numSysSizInput: Int32
    var doSystemSizing: Bool
    var numZoneSizingInput: Int32
    var doZoneSizing: Bool
    var autoCalculate: Bool
    var termUnitSingDuct: Bool
    var termUnitPIU: Bool
    var termUnitIU: Bool
    var zoneEqFanCoil: Bool
    var otherEqType: Bool
    var zoneEqUnitHeater: Bool
    var zoneEqUnitVent: Bool
    var zoneEqVentedSlab: Bool
    var minOA: Int32
    var dataEMSOverrideON: Bool
    var dataEMSOverride: Float64
    var dataAutosizable: Bool
    var dataConstantUsedForSizing: Float64
    var dataFractionUsedForSizing: Float64
    var dataDXCoolsLowSpeedsAutozize: Bool
    var dataPltSizHeatNum: Int32
    var dataWaterLoopNum: Int32
    var dataFanIndex: Int32
    var dataFanType: Int32
    var dataWaterCoilSizCoolDeltaT: Float64
    var dataWaterCoilSizHeatDeltaT: Float64
    var dataCapacityUsedForSizing: Float64
    var dataPltSizCoolNum: Int32
    var dataDesInletAirHumRat: Float64
    var dataAirFlowUsedForSizing: Float64
    var dataDesInletAirTemp: Float64
    var dataDesAccountForFanHeat: Bool
    var dataFanPlacement: Int32
    var dataFlowUsedForSizing: Float64
    var dataDesOutletAirHumRat: Float64
    var dataDesInletWaterTemp: Float64
    var dataDesOutletAirTemp: Float64
    var dataWaterFlowUsedForSizing: Float64
    var dataSizingFraction: Float64
    var dataDXSpeedNum: Int32
    var dataDesicRegCoil: Bool
    var dataHeatSizeRatio: Float64
    var dataZoneUsedForSizing: Int32
    var dataDesicDehumNum: Int32
    var dataNomCapInpMeth: Bool
    var dataCoilNum: Int32
    var dataFanOp: Int32
    var dataDesignCoilCapacity: Float64
    var dataErrorsFound: Bool
    var dataBypassFrac: Float64
    var dataIsDXCoil: Bool
    var dataNonZoneNonAirloopValue: Float64
    var printWarningFlag: Bool
    var callingRoutine: String
    var lastErrorMessages: String

    fn __init__(inout self) -> None:
        self.stdRhoAir = 0.0
        self.zoneAirFlowSizMethod = 0
        self.dataScalableSizingON = False
        self.dataScalableCapSizingON = False
        self.isCoilReportObject = False
        self.coilReportNum = -1
        self.isFanReportObject = False
        self.initialized = False
        self.errorType = AutoSizingResultType.NoError
        self.sizingType = AutoSizingType.Invalid
        self.sizingString = ""
        self.sizingStringScalable = ""
        self.overrideSizeString = True
        self.originalValue = 0.0
        self.autoSizedValue = 0.0
        self.wasAutoSized = False
        self.hardSizeNoDesignRun = False
        self.sizingDesRunThisAirSys = False
        self.sizingDesRunThisZone = False
        self.sizingDesValueFromParent = False
        self.airLoopSysFlag = False
        self.oaSysFlag = False
        self.coilType = -1
        self.compType = ""
        self.compName = ""
        self.isEpJSON = False
        self.sysSizingRunDone = False
        self.zoneSizingRunDone = False
        self.curSysNum = 0
        self.curOASysNum = 0
        self.curZoneEqNum = 0
        self.curDuctType = -1
        self.curTermUnitSizingNum = 0
        self.numPrimaryAirSys = 0
        self.numSysSizInput = 0
        self.doSystemSizing = False
        self.numZoneSizingInput = 0
        self.doZoneSizing = False
        self.autoCalculate = False
        self.termUnitSingDuct = False
        self.termUnitPIU = False
        self.termUnitIU = False
        self.zoneEqFanCoil = False
        self.otherEqType = False
        self.zoneEqUnitHeater = False
        self.zoneEqUnitVent = False
        self.zoneEqVentedSlab = False
        self.minOA = -1
        self.dataEMSOverrideON = False
        self.dataEMSOverride = 0.0
        self.dataAutosizable = False
        self.dataConstantUsedForSizing = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.dataDXCoolsLowSpeedsAutozize = False
        self.dataPltSizHeatNum = 0
        self.dataWaterLoopNum = 0
        self.dataFanIndex = 0
        self.dataFanType = -1
        self.dataWaterCoilSizCoolDeltaT = 0.0
        self.dataWaterCoilSizHeatDeltaT = 0.0
        self.dataCapacityUsedForSizing = 0.0
        self.dataPltSizCoolNum = 0
        self.dataDesInletAirHumRat = 0.0
        self.dataAirFlowUsedForSizing = 0.0
        self.dataDesInletAirTemp = 0.0
        self.dataDesAccountForFanHeat = False
        self.dataFanPlacement = -1
        self.dataFlowUsedForSizing = 0.0
        self.dataDesOutletAirHumRat = 0.0
        self.dataDesInletWaterTemp = 0.0
        self.dataDesOutletAirTemp = 0.0
        self.dataWaterFlowUsedForSizing = 0.0
        self.dataSizingFraction = 1.0
        self.dataDXSpeedNum = 0
        self.dataDesicRegCoil = False
        self.dataHeatSizeRatio = 0.0
        self.dataZoneUsedForSizing = 0
        self.dataDesicDehumNum = 0
        self.dataNomCapInpMeth = False
        self.dataCoilNum = 0
        self.dataFanOp = -1
        self.dataDesignCoilCapacity = 0.0
        self.dataErrorsFound = False
        self.dataBypassFrac = 0.0
        self.dataIsDXCoil = False
        self.dataNonZoneNonAirloopValue = 0.0
        self.printWarningFlag = False
        self.callingRoutine = ""
        self.lastErrorMessages = ""

    fn initializeWithinEP(inout self, state: AnyType, _compType: String, _compName: String, 
                          _printWarningFlag: Bool, _callingRoutine: String) -> None:
        self.initialized = True
        self.compType = _compType
        self.compName = _compName
        self.printWarningFlag = _printWarningFlag
        self.callingRoutine = _callingRoutine
        self.stdRhoAir = 1.225
        self.sysSizingRunDone = False
        self.zoneSizingRunDone = False
        self.curSysNum = 0
        self.curOASysNum = 0
        self.curZoneEqNum = 0
        self.curDuctType = -1
        self.numPrimaryAirSys = 0
        self.numSysSizInput = 0
        self.doSystemSizing = False
        self.numZoneSizingInput = 0
        self.doZoneSizing = False
        self.curTermUnitSizingNum = 0
        self.termUnitSingDuct = False
        self.termUnitPIU = False
        self.termUnitIU = False
        self.zoneEqFanCoil = False
        self.otherEqType = not (self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil)
        self.zoneEqUnitHeater = False
        self.zoneEqUnitVent = False
        self.zoneEqVentedSlab = False
        self.isCoilReportObject = self.isValidCoilType(_compType)
        self.isFanReportObject = self.isValidFanType(_compType)
        self.dataEMSOverrideON = False
        self.dataEMSOverride = 0.0
        self.dataAutosizable = False
        self.minOA = -1
        self.dataConstantUsedForSizing = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.dataFanIndex = 0
        self.dataFanType = -1
        self.dataPltSizHeatNum = 0
        self.dataWaterLoopNum = 0
        self.dataPltSizCoolNum = 0
        self.dataWaterCoilSizHeatDeltaT = 0.0
        self.dataWaterCoilSizCoolDeltaT = 0.0
        self.dataCapacityUsedForSizing = 0.0
        self.dataHeatSizeRatio = 0.0
        self.dataAirFlowUsedForSizing = 0.0
        self.dataDesInletAirTemp = 0.0
        self.dataDesAccountForFanHeat = False
        self.dataFanPlacement = -1
        self.dataDesInletAirHumRat = 0.0
        self.dataDesOutletAirHumRat = 0.0
        self.dataDesOutletAirTemp = 0.0
        self.dataDesInletWaterTemp = 0.0
        self.dataFlowUsedForSizing = 0.0
        self.dataWaterFlowUsedForSizing = 0.0
        self.dataSizingFraction = 1.0
        self.dataDXSpeedNum = 0
        self.dataDesicRegCoil = False
        self.dataZoneUsedForSizing = 0
        self.dataDesicDehumNum = 0
        self.dataNomCapInpMeth = False
        self.dataCoilNum = 0
        self.dataFanOp = -1
        self.dataDesignCoilCapacity = 0.0
        self.dataErrorsFound = False
        self.dataBypassFrac = 0.0
        self.dataIsDXCoil = False
        self.dataNonZoneNonAirloopValue = 0.0
        self.dataDXCoolsLowSpeedsAutozize = False

    fn initializeFromAPI(inout self, state: AnyType, elevation: Float64) -> None:
        self.clearState()
        self.initialized = True
        self.compType = "API_component_type"
        self.compName = "API_component_name"
        self.printWarningFlag = False
        self.callingRoutine = "called_from_API"
        let barometricPressure = 101325.0 * pow(1.0 - 2.25577e-05 * elevation, 5.2559)
        self.stdRhoAir = 1.225
        self.isCoilReportObject = False

    fn addErrorMessage(inout self, s: String) -> None:
        self.lastErrorMessages = self.lastErrorMessages + s + "\n"

    fn getLastErrorMessages(inout self) -> String:
        let s = self.lastErrorMessages
        self.lastErrorMessages = ""
        return s

    fn preSize(inout self, state: AnyType, original_value: Float64) -> None:
        if self.sizingType == AutoSizingType.Invalid:
            let msg = "Sizing Library Base Class: preSize, SizingType not defined."
            self.addErrorMessage(msg)
        
        self.originalValue = original_value
        self.autoCalculate = False
        self.errorType = AutoSizingResultType.NoError
        self.initialized = False
        self.hardSizeNoDesignRun = not (self.sysSizingRunDone or self.zoneSizingRunDone)
        self.sizingDesRunThisZone = False
        self.sizingDesRunThisAirSys = False
        
        if self.dataFractionUsedForSizing == 0.0 and self.dataConstantUsedForSizing > 0.0:
            self.errorType = AutoSizingResultType.ErrorType1
            self.autoCalculate = True
            self.hardSizeNoDesignRun = False
            if self.wasAutoSized:
                self.autoSizedValue = 0.0
        elif self.dataFractionUsedForSizing > 0.0:
            self.autoCalculate = True
            self.hardSizeNoDesignRun = False
        elif self.sizingType == AutoSizingType.AutoCalculateSizing:
            self.autoCalculate = True
            if self.originalValue == -99999.0 and not self.dataEMSOverrideON:
                self.errorType = AutoSizingResultType.ErrorType1

    fn isValidCoilType(self, _compType: String) -> Bool:
        return True

    fn isValidFanType(self, _compType: String) -> Bool:
        if self._sameString(_compType, "Fan:SystemModel"):
            return True
        if self._sameString(_compType, "Fan:ComponentModel"):
            return True
        if self._sameString(_compType, "Fan:OnOff"):
            return True
        if self._sameString(_compType, "Fan:ConstantVolume"):
            return True
        if self._sameString(_compType, "Fan:VariableVolume"):
            return True
        return False

    fn overrideSizingString(inout self, string: String) -> None:
        var result = ""
        var i = 0
        let chars = string.as_bytes()
        let n = chars.size()
        
        var word = ""
        var word_started = False
        for j in range(n):
            let ch = chars[j]
            if ch == ord("_"):
                if word == "for" or word == "per" or word == "at":
                    result = result + word
                elif word == "ua":
                    for k in range(word.size()):
                        result = result + String(chr(ord(word[k]) - 32))
                else:
                    if word.size() > 0:
                        result = result + String(chr(ord(word[0]) - 32)) + word[1:]
                if j < n - 1:
                    result = result + " "
                word = ""
                word_started = False
            else:
                word = word + String(chr(ch))
                word_started = True
        
        if word.size() > 0:
            if word == "for" or word == "per" or word == "at":
                result = result + word
            elif word == "ua":
                for k in range(word.size()):
                    result = result + String(chr(ord(word[k]) - 32))
            else:
                if word.size() > 0:
                    result = result + String(chr(ord(word[0]) - 32)) + word[1:]
        
        self.sizingString = result
        self.overrideSizeString = False

    @staticmethod
    fn setOAFracForZoneEqSizing(state: AnyType, desMassFlow: Float64, zoneEqSizing: AnyType) -> Float64:
        var outAirFrac: Float64 = 0.0
        if desMassFlow <= 0.0:
            return outAirFrac
        let StdRhoAir: Float64 = 1.225
        return outAirFrac

    @staticmethod
    fn setHeatCoilInletTempForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: AnyType, 
                                            finalZoneSizing: AnyType) -> Float64:
        return 20.0

    @staticmethod
    fn setHeatCoilInletHumRatForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: AnyType,
                                              finalZoneSizing: AnyType) -> Float64:
        return 0.008

    @staticmethod
    fn setCoolCoilInletTempForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: AnyType,
                                            finalZoneSizing: AnyType) -> Float64:
        return 26.0

    @staticmethod
    fn setCoolCoilInletHumRatForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: AnyType,
                                              finalZoneSizing: AnyType) -> Float64:
        return 0.012

    @staticmethod
    fn calcCoilWaterFlowRates(state: AnyType, compName: String, compType: String, 
                              peakWaterFlow: Float64, loopNum: Int32, curZoneEqNum: Int32,
                              curSysNum: Int32, curOASysNum: Int32, finalZoneSizing: AnyType,
                              finalSysSizing: AnyType) -> None:
        pass

    fn clearState(inout self) -> None:
        self.stdRhoAir = 0.0
        self.zoneAirFlowSizMethod = 0
        self.dataScalableSizingON = False
        self.dataScalableCapSizingON = False
        self.isCoilReportObject = False
        self.coilReportNum = -1
        self.isFanReportObject = False
        self.initialized = False
        self.errorType = AutoSizingResultType.NoError
        self.sizingType = AutoSizingType.Invalid
        self.sizingString = ""
        self.sizingStringScalable = ""
        self.overrideSizeString = True
        self.originalValue = 0.0
        self.autoSizedValue = 0.0
        self.wasAutoSized = False
        self.hardSizeNoDesignRun = False
        self.sizingDesRunThisAirSys = False
        self.sizingDesRunThisZone = False
        self.sizingDesValueFromParent = False
        self.airLoopSysFlag = False
        self.oaSysFlag = False
        self.coilType = -1
        self.compType = ""
        self.compName = ""
        self.isEpJSON = False
        self.sysSizingRunDone = False
        self.zoneSizingRunDone = False
        self.curSysNum = 0
        self.curOASysNum = 0
        self.curZoneEqNum = 0
        self.curDuctType = -1
        self.curTermUnitSizingNum = 0
        self.numPrimaryAirSys = 0
        self.numSysSizInput = 0
        self.doSystemSizing = False
        self.numZoneSizingInput = 0
        self.doZoneSizing = False
        self.autoCalculate = False
        self.termUnitSingDuct = False
        self.termUnitPIU = False
        self.termUnitIU = False
        self.zoneEqFanCoil = False
        self.otherEqType = False
        self.zoneEqUnitHeater = False
        self.zoneEqUnitVent = False
        self.zoneEqVentedSlab = False
        self.minOA = -1
        self.dataEMSOverrideON = False
        self.dataEMSOverride = 0.0
        self.dataAutosizable = False
        self.dataConstantUsedForSizing = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.dataDXCoolsLowSpeedsAutozize = False
        self.dataPltSizHeatNum = 0
        self.dataWaterLoopNum = 0
        self.dataFanIndex = -1
        self.dataFanType = -1
        self.dataWaterCoilSizCoolDeltaT = 0.0
        self.dataWaterCoilSizHeatDeltaT = 0.0
        self.dataCapacityUsedForSizing = 0.0
        self.dataPltSizCoolNum = 0
        self.dataDesInletAirHumRat = 0.0
        self.dataFlowUsedForSizing = 0.0
        self.dataDesOutletAirHumRat = 0.0
        self.dataDesInletWaterTemp = 0.0
        self.dataDesOutletAirTemp = 0.0
        self.dataWaterFlowUsedForSizing = 0.0
        self.dataSizingFraction = 1.0
        self.dataDXSpeedNum = 0
        self.dataAirFlowUsedForSizing = 0.0
        self.dataDesInletAirTemp = 0.0
        self.dataDesAccountForFanHeat = False
        self.dataFanPlacement = -1
        self.dataDesicRegCoil = False
        self.dataHeatSizeRatio = 0.0
        self.dataZoneUsedForSizing = 0
        self.dataDesicDehumNum = 0
        self.dataNomCapInpMeth = False
        self.dataCoilNum = 0
        self.dataFanOp = -1
        self.dataDesignCoilCapacity = 0.0
        self.dataErrorsFound = False
        self.dataBypassFrac = 0.0
        self.dataIsDXCoil = False
        self.dataNonZoneNonAirloopValue = 0.0
        self.printWarningFlag = False
        self.callingRoutine = ""

    fn _sameString(self, s1: String, s2: String) -> Bool:
        return s1.lower() == s2.lower()
