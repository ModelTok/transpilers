from ...AirLoopHVACDOAS import *  // AirLoopHVACDOAS::AirLoopDOAS
from ...Data.BaseData import *     // EnergyPlusData
from ...DataAirLoop import *       // DataAirLoop::OutsideAirSysProps, AirLoopControlData
from ...DataAirSystems import *    // DataAirSystems::DefinePrimaryAirSystem
from ...DataHVACGlobals import *   // HVAC::CoilType, FanType, AirDuctType, FanOp, FanPlace, etc.
from ...DataSizing import *        // DataSizing::SystemSizingInputData, ZoneSizingInputData, ZoneEqSizingData, TermUnitSizingData, TermUnitZoneSizingData, ZoneSizingData, SystemSizingData, PlantSizingData, OAControl, AutoSize, etc.
from ...ReportCoilSelection import * // ReportCoilSelection::getReportIndex
from ...api.TypeDefs import *     // TypeDefs (likely Real64, etc.)
from ......ObjexxFCL.Optional import * // ObjexxFCL::Optional, Optional_string_const
module EnergyPlus:
enum AutoSizingType:
    Invalid = -1
    CoolingAirFlowSizing = 1
    CoolingWaterflowSizing = 2
    HeatingWaterflowSizing = 3
    CoolingWaterDesAirInletTempSizing = 4
    CoolingWaterDesAirInletHumRatSizing = 5
    CoolingWaterDesWaterInletTempSizing = 6
    CoolingWaterDesAirOutletTempSizing = 7
    CoolingWaterDesAirOutletHumRatSizing = 8
    CoolingWaterNumofTubesPerRowSizing = 9
    HeatingWaterDesAirInletTempSizing = 10
    HeatingWaterDesAirInletHumRatSizing = 11
    HeatingWaterDesCoilLoadUsedForUASizing = 12
    HeatingWaterDesCoilWaterVolFlowUsedForUASizing = 13
    HeatingAirFlowSizing = 14
    HeatingAirflowUASizing = 15
    SystemAirFlowSizing = 16
    CoolingCapacitySizing = 17
    HeatingCapacitySizing = 18
    WaterHeatingCapacitySizing = 19
    WaterHeatingCoilUASizing = 20
    SystemCapacitySizing = 21  # not used
    CoolingSHRSizing = 22
    HeatingDefrostSizing = 23  # not used
    MaxHeaterOutletTempSizing = 24
    AutoCalculateSizing = 25
    ZoneCoolingLoadSizing = 26
    ZoneHeatingLoadSizing = 27
    MinSATempCoolingSizing = 28  # not used
    MaxSATempHeatingSizing = 29  # not used
    ASHRAEMinSATCoolingSizing = 30
    ASHRAEMaxSATHeatingSizing = 31
    HeatingCoilDesAirInletTempSizing = 32
    HeatingCoilDesAirOutletTempSizing = 33
    HeatingCoilDesAirInletHumRatSizing = 34
    DesiccantDehumidifierBFPerfDataFaceVelocitySizing = 35
    Num
enum AutoSizingResultType:
    Invalid = -1
    NoError    # no errors found
    ErrorType1 # sizing error
    ErrorType2 # uninitialized sizing type
    Num
struct BaseSizer:
    var stdRhoAir: Float64 = 0.0
    var zoneAirFlowSizMethod: Int = 0
    var dataScalableSizingON: Bool = false
    var dataScalableCapSizingON: Bool = false
    var isCoilReportObject: Bool = false # provides access to coil reporting
    var coilReportNum: Int = -1          # Coil report number for direct access
    var isFanReportObject: Bool = false  # provides access to fan reporting
    var initialized: Bool = false        # indicates initializeWithinEP was called
    var errorType: AutoSizingResultType = AutoSizingResultType.NoError
    var sizingType: AutoSizingType = AutoSizingType.Invalid
    var sizingString: String = ""
    var sizingStringScalable: String = ""
    var overrideSizeString: Bool = true
    var originalValue: Float64 = 0.0
    var autoSizedValue: Float64 = 0.0
    var wasAutoSized: Bool = false
    var hardSizeNoDesignRun: Bool = false
    var sizingDesRunThisAirSys: Bool = false
    var sizingDesRunThisZone: Bool = false
    var sizingDesValueFromParent: Bool = false
    var airLoopSysFlag: Bool = false
    var oaSysFlag: Bool = false
    var coilType: HVAC.CoilType = HVAC.CoilType.Invalid
    var compType: String = ""
    var compName: String = ""
    var isEpJSON: Bool = false
    var sysSizingRunDone: Bool = false
    var zoneSizingRunDone: Bool = false
    var curSysNum: Int = 0
    var curOASysNum: Int = 0
    var curZoneEqNum: Int = 0
    var curDuctType: HVAC.AirDuctType = HVAC.AirDuctType.Invalid
    var curTermUnitSizingNum: Int = 0 # index in zone equipment vector - for single duct, IU, and PIU
    var numPrimaryAirSys: Int = 0
    var numSysSizInput: Int = 0
    var doSystemSizing: Bool = false
    var numZoneSizingInput: Int = 0
    var doZoneSizing: Bool = false
    var autoCalculate: Bool = false # indicator that AutoCalculate is used
    var termUnitSingDuct: Bool = false # single duct terminal unit
    var termUnitPIU: Bool = false      # powered induction unit
    var termUnitIU: Bool = false       # induction terminal unit
    var zoneEqFanCoil: Bool = false    # fan coil zone equipment
    var otherEqType: Bool = false      # this covers the ELSE type switch
    var zoneEqUnitHeater: Bool = false # unit heater zone equipment
    var zoneEqUnitVent: Bool = false   # unit ventilator zone equipment
    var zoneEqVentedSlab: Bool = false # ventilated slab zone equipment
    var minOA: DataSizing.OAControl = DataSizing.OAControl.Invalid
    var dataEMSOverrideON: Bool = false
    var dataEMSOverride: Float64 = 0.0
    var dataAutosizable: Bool = false
    var dataConstantUsedForSizing: Float64 = 0.0
    var dataFractionUsedForSizing: Float64 = 0.0
    var dataDXCoolsLowSpeedsAutozize: Bool = false
    var dataPltSizHeatNum: Int = 0
    var dataWaterLoopNum: Int = 0
    var dataFanIndex: Int = 0
    var dataFanType: HVAC.FanType = HVAC.FanType.Invalid
    var dataWaterCoilSizCoolDeltaT: Float64 = 0.0
    var dataWaterCoilSizHeatDeltaT: Float64 = 0.0
    var dataCapacityUsedForSizing: Float64 = 0.0
    var dataPltSizCoolNum: Int = 0
    var dataDesInletAirHumRat: Float64 = 0.0
    var dataAirFlowUsedForSizing: Float64 = 0.0
    var dataDesInletAirTemp: Float64 = 0.0
    var dataDesAccountForFanHeat: Bool = false
    var dataFanPlacement: HVAC.FanPlace = HVAC.FanPlace.Invalid
    var dataFlowUsedForSizing: Float64 = 0.0
    var dataDesOutletAirHumRat: Float64 = 0.0
    var dataDesInletWaterTemp: Float64 = 0.0
    var dataDesOutletAirTemp: Float64 = 0.0
    var dataWaterFlowUsedForSizing: Float64 = 0.0
    var dataSizingFraction: Float64 = 1.0
    var dataDXSpeedNum: Int = 0
    var dataDesicRegCoil: Bool = false
    var dataHeatSizeRatio: Float64 = 0.0
    var dataZoneUsedForSizing: Int = 0
    var dataDesicDehumNum: Int = 0
    var dataNomCapInpMeth: Bool = false
    var dataCoilNum: Int = 0
    var dataFanOp: HVAC.FanOp = HVAC.FanOp.Invalid
    var dataDesignCoilCapacity: Float64 = 0.0
    var dataErrorsFound: Bool = false
    var dataBypassFrac: Float64 = 0.0
    var dataIsDXCoil: Bool = false
    var dataNonZoneNonAirloopValue: Float64 = 0.0
    var printWarningFlag: Bool = false
    var callingRoutine: String = ""
    var sysSizingInputData: DynamicVector[DataSizing.SystemSizingInputData]
    var zoneSizingInput: DynamicVector[DataSizing.ZoneSizingInputData]
    var unitarySysEqSizing: DynamicVector[DataSizing.ZoneEqSizingData]
    var oaSysEqSizing: DynamicVector[DataSizing.ZoneEqSizingData]
    var zoneEqSizing: DynamicVector[DataSizing.ZoneEqSizingData]
    var outsideAirSys: DynamicVector[DataAirLoop.OutsideAirSysProps]
    var termUnitSizing: DynamicVector[DataSizing.TermUnitSizingData]
    var termUnitFinalZoneSizing: DynamicVector[DataSizing.TermUnitZoneSizingData]
    var finalZoneSizing: DynamicVector[DataSizing.ZoneSizingData]
    var finalSysSizing: DynamicVector[DataSizing.SystemSizingData]
    var plantSizData: DynamicVector[DataSizing.PlantSizingData]
    var primaryAirSystem: DynamicVector[DataAirSystems.DefinePrimaryAirSystem]
    var airloopDOAS: DynamicVector[AirLoopHVACDOAS.AirLoopDOAS]
    var airLoopControlInfo: DynamicVector[DataAirLoop.AirLoopControlData]
    def initializeWithinEP(inout self, inout state: EnergyPlusData, _compType: String, _compName: String, _printWarningFlag: Bool, _callingRoutine: String): ...
    def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64: ...
    def getLastErrorMessages(inout self) -> String: ...
    def overrideSizingString(inout self, string: String): ...
protected:
    var lastErrorMessages: String = ""
    def addErrorMessage(inout self, s: String): ...
    def initializeFromAPI(inout self, inout state: EnergyPlusData, elevation: Float64): ...
    def preSize(inout self, inout state: EnergyPlusData, originalValue: Float64): ...
    def selectSizerOutput(inout self, inout state: EnergyPlusData, inout errorsFound: Bool): ...
    def select2StgDXHumCtrlSizerOutput(inout self, inout state: EnergyPlusData, inout errorsFound: Bool): ...
    def isValidCoilType(inout self, compType: String) -> Bool: ...
    def isValidFanType(inout self, compType: String) -> Bool: ...
    def checkInitialized(inout self, inout state: EnergyPlusData, inout errorsFound: Bool) -> Bool: ...
    def clearState(inout self): ...
public:
    static def reportSizerOutput(inout state: EnergyPlusData, CompType: String, CompName: String, VarDesc: String, VarValue: Float64, UsrDesc: Optional[String] = None, UsrValue: Optional[Float64] = None): ...
    static def reportSizerStrOutput(inout state: EnergyPlusData, CompType: String, CompName: String, VarDesc: String, VarValue: String): ...
    static def setOAFracForZoneEqSizing(state: EnergyPlusData, desMassFlow: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData) -> Float64: ...
    static def setHeatCoilInletTempForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData, finalZoneSizing: DataSizing.ZoneSizingData) -> Float64: ...
    static def setHeatCoilInletHumRatForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData, finalZoneSizing: DataSizing.ZoneSizingData) -> Float64: ...
    static def setCoolCoilInletTempForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData, finalZoneSizing: DataSizing.ZoneSizingData) -> Float64: ...
    static def setCoolCoilInletHumRatForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData, finalZoneSizing: DataSizing.ZoneSizingData) -> Float64: ...
    static def calcCoilWaterFlowRates(inout state: EnergyPlusData, compName: String, compType: String, peakWaterFlow: Float64, loopNum: Int, curZoneEqNum: Int, curSysNum: Int, curOASysNum: Int, finalZoneSizing: DynamicVector[DataSizing.ZoneSizingData], finalSysSizing: DynamicVector[DataSizing.SystemSizingData]): ...
def BaseSizer.initializeWithinEP(inout self, inout state: EnergyPlusData, _compType: String, _compName: String, _printWarningFlag: Bool, _callingRoutine: String):
    self.initialized = true
    self.compType = _compType
    self.compName = _compName
    self.isEpJSON = state.dataGlobal.isEpJSON
    self.printWarningFlag = _printWarningFlag
    self.callingRoutine = _callingRoutine
    self.stdRhoAir = state.dataEnvrn.StdRhoAir
    self.sysSizingRunDone = state.dataSize.SysSizingRunDone
    self.zoneSizingRunDone = state.dataSize.ZoneSizingRunDone
    self.curSysNum = state.dataSize.CurSysNum
    self.curOASysNum = state.dataSize.CurOASysNum
    self.curZoneEqNum = state.dataSize.CurZoneEqNum
    self.curDuctType = state.dataSize.CurDuctType
    self.numPrimaryAirSys = state.dataHVACGlobal.NumPrimaryAirSys
    self.numSysSizInput = state.dataSize.NumSysSizInput
    self.doSystemSizing = state.dataGlobal.DoSystemSizing
    self.numZoneSizingInput = state.dataSize.NumZoneSizingInput
    self.doZoneSizing = state.dataGlobal.DoZoneSizing
    self.curTermUnitSizingNum = state.dataSize.CurTermUnitSizingNum
    self.termUnitSingDuct = state.dataSize.TermUnitSingDuct
    self.termUnitPIU = state.dataSize.TermUnitPIU
    self.termUnitIU = state.dataSize.TermUnitIU
    self.zoneEqFanCoil = state.dataSize.ZoneEqFanCoil
    self.otherEqType = not (self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil)
    self.zoneEqUnitHeater = state.dataSize.ZoneEqUnitHeater
    self.zoneEqUnitVent = state.dataSize.ZoneEqUnitVent
    self.zoneEqVentedSlab = state.dataSize.ZoneEqVentedSlab
    self.zoneSizingInput = state.dataSize.ZoneSizingInput
    self.unitarySysEqSizing = state.dataSize.UnitarySysEqSizing
    self.oaSysEqSizing = state.dataSize.OASysEqSizing
    self.outsideAirSys = state.dataAirLoop.OutsideAirSys
    self.termUnitSizing = state.dataSize.TermUnitSizing
    self.finalZoneSizing = state.dataSize.FinalZoneSizing
    self.termUnitFinalZoneSizing = state.dataSize.TermUnitFinalZoneSizing
    self.zoneEqSizing = state.dataSize.ZoneEqSizing
    self.sysSizingInputData = state.dataSize.SysSizInput
    self.finalSysSizing = state.dataSize.FinalSysSizing
    self.plantSizData = state.dataSize.PlantSizData
    self.primaryAirSystem = state.dataAirSystemsData.PrimaryAirSystems
    self.airLoopControlInfo = state.dataAirLoop.AirLoopControlInfo
    self.airloopDOAS = state.dataAirLoopHVACDOAS.airloopDOAS
    if EnergyPlus.BaseSizer.isValidCoilType(self, self.compType):  # coil reports fail if compType is not one of HVAC::cAllCoilTypes
        self.isCoilReportObject = true
        self.coilReportNum = ReportCoilSelection.getReportIndex(state, self.compName, self.coilType)
    if EnergyPlus.BaseSizer.isValidFanType(self, self.compType):  # fan reports fail if compType is not a valid fan type
        self.isFanReportObject = true
    self.dataEMSOverrideON = state.dataSize.DataEMSOverrideON
    self.dataEMSOverride = state.dataSize.DataEMSOverride
    self.dataAutosizable = state.dataSize.DataAutosizable
    self.minOA = DataSizing.OAControl.MinOA
    self.dataConstantUsedForSizing = state.dataSize.DataConstantUsedForSizing
    self.dataFractionUsedForSizing = state.dataSize.DataFractionUsedForSizing
    state.dataSize.DataConstantUsedForSizing = 0.0  # reset here instead of in component model?
    state.dataSize.DataFractionUsedForSizing = 0.0
    self.dataFanIndex = state.dataSize.DataFanIndex
    self.dataFanType = state.dataSize.DataFanType
    self.dataPltSizHeatNum = state.dataSize.DataPltSizHeatNum
    self.dataWaterLoopNum = state.dataSize.DataWaterLoopNum
    self.dataPltSizCoolNum = state.dataSize.DataPltSizCoolNum
    self.dataWaterCoilSizHeatDeltaT = state.dataSize.DataWaterCoilSizHeatDeltaT
    self.dataWaterCoilSizCoolDeltaT = state.dataSize.DataWaterCoilSizCoolDeltaT
    self.dataCapacityUsedForSizing = state.dataSize.DataCapacityUsedForSizing
    self.dataHeatSizeRatio = state.dataSize.DataHeatSizeRatio
    self.dataAirFlowUsedForSizing = state.dataSize.DataAirFlowUsedForSizing
    self.dataDesInletAirTemp = state.dataSize.DataDesInletAirTemp
    self.dataDesAccountForFanHeat = state.dataSize.DataDesAccountForFanHeat
    self.dataFanPlacement = state.dataSize.DataFanPlacement
    self.dataDesInletAirHumRat = state.dataSize.DataDesInletAirHumRat
    self.dataDesOutletAirHumRat = state.dataSize.DataDesOutletAirHumRat
    self.dataDesOutletAirTemp = state.dataSize.DataDesOutletAirTemp
    self.dataDesInletWaterTemp = state.dataSize.DataDesInletWaterTemp
    self.dataFlowUsedForSizing = state.dataSize.DataFlowUsedForSizing
    self.dataWaterFlowUsedForSizing = state.dataSize.DataWaterFlowUsedForSizing
    self.dataSizingFraction = state.dataSize.DataSizingFraction
    self.dataDXSpeedNum = state.dataSize.DataDXSpeedNum
    self.dataDesicRegCoil = state.dataSize.DataDesicRegCoil
    self.dataZoneUsedForSizing = state.dataSize.DataZoneUsedForSizing
    self.dataDesicDehumNum = state.dataSize.DataDesicDehumNum
    self.dataNomCapInpMeth = state.dataSize.DataNomCapInpMeth
    self.dataCoilNum = state.dataSize.DataCoilNum
    self.dataFanOp = state.dataSize.DataFanOp
    self.dataDesignCoilCapacity = state.dataSize.DataDesignCoilCapacity
    self.dataErrorsFound = state.dataSize.DataErrorsFound
    self.dataBypassFrac = state.dataSize.DataBypassFrac
    self.dataIsDXCoil = state.dataSize.DataIsDXCoil
    self.dataNonZoneNonAirloopValue = state.dataSize.DataNonZoneNonAirloopValue
    self.dataDXCoolsLowSpeedsAutozize = state.dataSize.DataDXCoolsLowSpeedsAutozize
def BaseSizer.initializeFromAPI(inout self, inout state: EnergyPlusData, elevation: Float64):
    self.clearState()
    self.initialized = true
    self.compType = "API_component_type"
    self.compName = "API_component_name"
    self.printWarningFlag = false
    self.callingRoutine = "called_from_API"
    var barometricPressure: Float64 = DataEnvironment.StdPressureSeaLevel * (1.0 - 2.25577e-05 * elevation) ** 5.2559
    self.stdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(state, barometricPressure, 20.0, 0.0)
    self.isCoilReportObject = false
def BaseSizer.addErrorMessage(inout self, s: String):
    self.lastErrorMessages = self.lastErrorMessages + s + "\n"
def BaseSizer.getLastErrorMessages(inout self) -> String:
    var s: String = self.lastErrorMessages
    self.lastErrorMessages = ""
    return s
def BaseSizer.preSize(inout self, inout state: EnergyPlusData, _originalValue: Float64):
    if self.sizingType == AutoSizingType.Invalid:
        var msg: String = "Sizing Library Base Class: preSize, SizingType not defined."
        self.addErrorMessage(msg)
        ShowSevereError(state, msg)
        ShowFatalError(state, "Sizing type causes fatal error.")
    self.originalValue = _originalValue
    self.autoCalculate = false
    self.errorType = EnergyPlus.AutoSizingResultType.NoError
    self.initialized = false  # force use of Init then Size in subsequent calls
    self.hardSizeNoDesignRun = not (self.sysSizingRunDone or self.zoneSizingRunDone)
    self.sizingDesRunThisZone = false
    self.sizingDesRunThisAirSys = false
    if self.dataFractionUsedForSizing == 0.0 and self.dataConstantUsedForSizing > 0.0:
        self.errorType = AutoSizingResultType.ErrorType1
        self.autoCalculate = true
        self.hardSizeNoDesignRun = false
        if self.wasAutoSized:
            self.autoSizedValue = 0.0
            var msg: String = "Sizing Library: DataConstantUsedForSizing and DataFractionUsedForSizing used for autocalculating " + self.sizingString + " must both be greater than 0."
            self.addErrorMessage(msg)
            ShowSevereError(state, msg)
    elif self.dataFractionUsedForSizing > 0.0:
        self.autoCalculate = true
        self.hardSizeNoDesignRun = false
    elif self.sizingType == AutoSizingType.AutoCalculateSizing:
        self.autoCalculate = true
        if self.originalValue == DataSizing.AutoSize and not self.dataEMSOverrideON:
            self.errorType = AutoSizingResultType.ErrorType1
            var msg: String = "Sizing Library: DataConstantUsedForSizing and DataFractionUsedForSizing used for autocalculating " + self.sizingString + " must both be greater than 0."
            self.addErrorMessage(msg)
            ShowSevereError(state, msg)
    if self.curSysNum > 0 and self.curSysNum <= self.numPrimaryAirSys:
        if self.sysSizingRunDone:
            var sysNum: Int = self.curSysNum
            self.sizingDesRunThisAirSys = any(
                [ssid.AirLoopNum == sysNum for ssid in self.sysSizingInputData]
            )
        if allocated(self.unitarySysEqSizing):
            self.airLoopSysFlag = self.unitarySysEqSizing[self.curSysNum].CoolingCapacity or self.unitarySysEqSizing[self.curSysNum].HeatingCapacity
        if self.curOASysNum > 0:
            self.oaSysFlag = self.oaSysEqSizing[self.curOASysNum].CoolingCapacity or self.oaSysEqSizing[self.curOASysNum].HeatingCapacity
    if self.curZoneEqNum > 0:
        if allocated(self.zoneEqSizing):
            self.sizingDesValueFromParent = self.zoneEqSizing[self.curZoneEqNum].DesignSizeFromParent
        if self.zoneSizingRunDone:
            var zoneNum: Int = self.curZoneEqNum
            self.sizingDesRunThisZone = any(
                [zsi.ZoneNum == zoneNum for zsi in self.zoneSizingInput]
            )
        self.hardSizeNoDesignRun = false
    if self.originalValue == DataSizing.AutoSize:
        self.wasAutoSized = true
        self.hardSizeNoDesignRun = false
        if not self.sizingDesRunThisAirSys and self.curSysNum > 0 and not self.autoCalculate:
            if not self.sysSizingRunDone:
                var msg: String = "For autosizing of " + self.compType + ' ' + self.compName + ", a system sizing run must be done."
                self.addErrorMessage(msg)
                ShowSevereError(state, msg)
                if self.numSysSizInput == 0:
                    var msg2: String = "No \"Sizing:System\" objects were entered."
                    self.addErrorMessage(msg2)
                    ShowContinueError(state, msg2)
                if not self.doSystemSizing:
                    var msg2: String = "The \"SimulationControl\" object did not have the field \"Do System Sizing Calculation\" set to Yes."
                    self.addErrorMessage(msg2)
                    ShowContinueError(state, msg2)
                ShowFatalError(state, "Program terminates due to previously shown condition(s).")
        if not self.sizingDesRunThisZone and self.curZoneEqNum > 0 and not self.sizingDesValueFromParent and not self.autoCalculate:
            if not self.zoneSizingRunDone:
                var msg: String = "For autosizing of " + self.compType + ' ' + self.compName + ", a zone sizing run must be done."
                self.addErrorMessage(msg)
                ShowSevereError(state, msg)
                if self.numZoneSizingInput == 0:
                    var msg2: String = "No \"Sizing:Zone\" objects were entered."
                    self.addErrorMessage(msg2)
                    ShowContinueError(state, msg2)
                if not self.doZoneSizing:
                    var msg2: String = "The \"SimulationControl\" object did not have the field \"Do Zone Sizing Calculation\" set to Yes."
                    self.addErrorMessage(msg2)
                    ShowContinueError(state, msg2)
                ShowFatalError(state, "Program terminates due to previously shown condition(s).")
    else:
        self.wasAutoSized = false
def BaseSizer.size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
    raise "BaseSizer.size(): pure function called"
def BaseSizer.reportSizerOutput(inout state: EnergyPlusData, CompType: String, CompName: String, VarDesc: String, VarValue: Float64, UsrDesc: Optional[String] = None, UsrValue: Optional[Float64] = None):
    var Format_990: String = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
    var Format_991: String = " Component Sizing Information, {}, {}, {}, {:#G}\n"
    var Format_991_HumRat: String = " Component Sizing Information, {}, {}, {}, {:.3E}\n"
    var sizingFormat: fn(String) -> String = lambda desc: Format_991_HumRat if "Humidity Ratio" in desc else Format_991
    if state.dataEnvrn.oneTimeCompRptHeaderFlag:
        print(state.files.eio, Format_990)
        state.dataEnvrn.oneTimeCompRptHeaderFlag = false
    print(state.files.eio, sizingFormat(VarDesc), CompType, CompName, VarDesc, VarValue)
    OutputReportPredefined.AddCompSizeTableEntry(state, CompType, CompName, VarDesc, VarValue)
    if UsrDesc is not None and UsrValue is not None:
        print(state.files.eio, sizingFormat(UsrDesc.value), CompType, CompName, UsrDesc.value, UsrValue.value)
        OutputReportPredefined.AddCompSizeTableEntry(state, CompType, CompName, UsrDesc.value, UsrValue.value)
    elif UsrDesc is not None or UsrValue is not None:
        ShowFatalError(state, "ReportSizingOutput: (Developer Error) - called with user-specified description or value but not both.")
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.addSQLiteComponentSizingRecord(CompType, CompName, VarDesc, VarValue)
    if UsrDesc is not None and UsrValue is not None:
        if state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite.addSQLiteComponentSizingRecord(CompType, CompName, UsrDesc.value, UsrValue.value)
def BaseSizer.reportSizerStrOutput(inout state: EnergyPlusData, CompType: String, CompName: String, VarDesc: String, VarValue: String):
    var Format_990: String = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
    var Format_991: String = " Component Sizing Information, {}, {}, {}, {}\n"
    if state.dataEnvrn.oneTimeCompRptHeaderFlag:
        print(state.files.eio, Format_990)
        state.dataEnvrn.oneTimeCompRptHeaderFlag = false
    print(state.files.eio, Format_991, CompType, CompName, VarDesc, VarValue)
    OutputReportPredefined.AddCompSizeTableStrEntry(state, CompType, CompName, VarDesc, VarValue)
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.addSQLiteComponentSizingStrRecord(CompType, CompName, VarDesc, VarValue)
def BaseSizer.selectSizerOutput(inout self, inout state: EnergyPlusData, inout errorsFound: Bool):
    if self.printWarningFlag:
        if self.dataEMSOverrideON:  # EMS overrides value
            self.autoSizedValue = self.dataEMSOverride
            self.reportSizerOutput(
                state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
        elif self.hardSizeNoDesignRun and not self.wasAutoSized and Util.SameString(self.compType, "Fan:ZoneExhaust"):
            self.autoSizedValue = self.originalValue
        elif self.wasAutoSized and self.dataFractionUsedForSizing > 0.0 and self.dataConstantUsedForSizing > 0.0:
            self.autoSizedValue = self.dataFractionUsedForSizing * self.dataConstantUsedForSizing
            self.reportSizerOutput(
                state, self.compType, self.compName, "Design Size " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
        elif not self.wasAutoSized and (self.autoSizedValue == self.originalValue or self.autoSizedValue == 0.0):
            self.autoSizedValue = self.originalValue
            if self.dataAutosizable or (not self.sizingDesRunThisZone and Util.SameString(self.compType, "Fan:ZoneExhaust")):
                self.reportSizerOutput(
                    state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
        elif not self.wasAutoSized and self.autoSizedValue >= 0.0 and self.originalValue == 0.0:
            self.autoSizedValue = self.originalValue
            self.reportSizerOutput(
                state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
        elif self.wasAutoSized and self.autoSizedValue >= 0.0 and self.originalValue <= 0.0:
            if self.dataScalableSizingON and int(self.zoneAirFlowSizMethod) > 0:
                self.reportSizerOutput(
                    state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            else:
                self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingString, self.autoSizedValue)
        elif self.autoSizedValue >= 0.0 and self.originalValue > 0.0:
            if (abs(self.autoSizedValue - self.originalValue) / self.originalValue) > state.dataSize.AutoVsHardSizingThreshold:
                if self.dataAutosizable:
                    self.reportSizerOutput(state,
                        self.compType,
                        self.compName,
                        "Design Size " + self.sizingString,
                        self.autoSizedValue,
                        "User-Specified " + self.sizingStringScalable + self.sizingString,
                        self.originalValue)
            else:
                if self.dataAutosizable:
                    self.reportSizerOutput(state,
                        self.compType,
                        self.compName,
                        "User-Specified " + self.sizingStringScalable + self.sizingString,
                        self.originalValue)
            if state.dataGlobal.DisplayExtraWarnings and self.dataAutosizable:
                if (abs(self.autoSizedValue - self.originalValue) / self.originalValue) > state.dataSize.AutoVsHardSizingThreshold:
                    var msg: String = self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName
                    self.addErrorMessage(msg)
                    ShowMessage(state, msg)
                    msg = "User-Specified " + self.sizingStringScalable + self.sizingString + " = " + str(self.originalValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = "differs from Design Size " + self.sizingString + " = " + str(self.autoSizedValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = "This may, or may not, indicate mismatched component sizes."
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = "Verify that the value entered is intended and is consistent with other components."
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
            if not self.wasAutoSized:
                self.autoSizedValue = self.originalValue
        elif self.wasAutoSized and self.autoSizedValue != DataSizing.AutoSize:
            self.reportSizerOutput(
                state, self.compType, self.compName, "Design Size " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
        else:
            var msg: String = self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
            self.addErrorMessage(msg)
            ShowSevereError(state, msg)
            msg = "SizingString = " + self.sizingString + ", SizingResult = " + str(self.originalValue)
            self.addErrorMessage(msg)
            ShowContinueError(state, msg)
            self.errorType = AutoSizingResultType.ErrorType1
    elif not self.wasAutoSized and not self.autoCalculate:
        self.autoSizedValue = self.originalValue
    self.overrideSizeString = true  # reset for next sizer
    if self.errorType != AutoSizingResultType.NoError:
        var msg: String = "Developer Error: sizing of " + self.sizingString + " failed."
        self.addErrorMessage(msg)
        ShowSevereError(state, msg)
        msg = "Occurs in " + self.compType + " " + self.compName
        self.addErrorMessage(msg)
        ShowContinueError(state, msg)
        errorsFound = true
def BaseSizer.select2StgDXHumCtrlSizerOutput(inout self, inout state: EnergyPlusData, inout errorsFound: Bool):
    if self.printWarningFlag:
        if self.dataEMSOverrideON:  # EMS overrides value
            self.reportSizerOutput(
                state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            if Util.SameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                self.autoSizedValue *= (1 - self.dataBypassFrac)
                self.reportSizerOutput(state,
                    self.compType,
                    self.compName,
                    "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )",
                    self.autoSizedValue)
        elif not self.wasAutoSized and (self.autoSizedValue == self.originalValue or self.autoSizedValue == 0.0):
            self.autoSizedValue = self.originalValue
            self.reportSizerOutput(
                state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            if Util.SameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                self.autoSizedValue *= (1 - self.dataBypassFrac)
                self.reportSizerOutput(state,
                    self.compType,
                    self.compName,
                    "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )",
                    self.autoSizedValue)
        elif not self.wasAutoSized and self.autoSizedValue >= 0.0 and self.originalValue == 0.0:
            self.autoSizedValue = self.originalValue
            self.reportSizerOutput(
                state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            if Util.SameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                self.autoSizedValue *= (1 - self.dataBypassFrac)
                self.reportSizerOutput(state,
                    self.compType,
                    self.compName,
                    "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )",
                    self.autoSizedValue)
        elif self.wasAutoSized and self.autoSizedValue >= 0.0 and self.originalValue <= 0.0:
            if self.dataScalableSizingON and int(self.zoneAirFlowSizMethod) > 0:
                self.reportSizerOutput(
                    state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            else:
                self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingString, self.autoSizedValue)
            if Util.SameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                self.autoSizedValue *= (1 - self.dataBypassFrac)
                self.reportSizerOutput(state,
                    self.compType,
                    self.compName,
                    "Design Size " + self.sizingString + " ( non-bypassed )",
                    self.autoSizedValue)
        elif self.autoSizedValue >= 0.0 and self.originalValue > 0.0:
            if (abs(self.autoSizedValue - self.originalValue) / self.originalValue) > state.dataSize.AutoVsHardSizingThreshold:
                self.reportSizerOutput(state,
                    self.compType,
                    self.compName,
                    "Design Size " + self.sizingString,
                    self.autoSizedValue,
                    "User-Specified " + self.sizingStringScalable + self.sizingString,
                    self.originalValue)
                if Util.SameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                    self.autoSizedValue *= (1 - self.dataBypassFrac)
                    self.originalValue *= (1 - self.dataBypassFrac)
                    self.reportSizerOutput(state,
                        self.compType,
                        self.compName,
                        "Design Size " + self.sizingString + " ( non-bypassed )",
                        self.autoSizedValue,
                        "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )",
                        self.originalValue)
            else:
                if Util.SameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                    self.autoSizedValue /= (1 - self.dataBypassFrac)
                self.reportSizerOutput(
                    state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.originalValue)
                if Util.SameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                    self.autoSizedValue *= (1 - self.dataBypassFrac)
                    self.reportSizerOutput(state,
                        self.compType,
                        self.compName,
                        "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )",
                        self.autoSizedValue)
            if state.dataGlobal.DisplayExtraWarnings:
                if (abs(self.autoSizedValue - self.originalValue) / self.originalValue) > state.dataSize.AutoVsHardSizingThreshold:
                    var msg: String = self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName
                    self.addErrorMessage(msg)
                    ShowMessage(state, msg)
                    msg = "User-Specified " + self.sizingStringScalable + self.sizingString + " = " + str(self.originalValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = "differs from Design Size " + self.sizingString + " = " + str(self.autoSizedValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = "This may, or may not, indicate mismatched component sizes."
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = "Verify that the value entered is intended and is consistent with other components."
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
            if not self.wasAutoSized:
                self.autoSizedValue = self.originalValue
        elif self.wasAutoSized and self.autoSizedValue != DataSizing.AutoSize:
            self.reportSizerOutput(
                state, self.compType, self.compName, "Design Size " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
        else:
            var msg: String = self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
            self.addErrorMessage(msg)
            ShowSevereError(state, msg)
            msg = "SizingString = " + self.sizingString + ", SizingResult = " + str(self.originalValue)
            self.addErrorMessage(msg)
            ShowContinueError(state, msg)
            self.errorType = AutoSizingResultType.ErrorType1
    elif not self.wasAutoSized and not self.autoCalculate:
        self.autoSizedValue = self.originalValue
    self.overrideSizeString = true  # reset for next sizer
    if self.errorType != AutoSizingResultType.NoError:
        var msg: String = "Developer Error: sizing of " + self.sizingString + " failed."
        self.addErrorMessage(msg)
        ShowSevereError(state, msg)
        msg = "Occurs in " + self.compType + " " + self.compName
        self.addErrorMessage(msg)
        ShowContinueError(state, msg)
        errorsFound = true
def BaseSizer.isValidCoilType(inout self, _compType: String) -> Bool:
    self.coilType = int(getEnumValue(HVAC.coilTypeNamesUC, Util.makeUPPER(_compType)))
    return self.coilType != HVAC.CoilType.Invalid
def BaseSizer.isValidFanType(inout self, _compType: String) -> Bool:
    if Util.SameString(_compType, "Fan:SystemModel"):
        return true
    if Util.SameString(_compType, "Fan:ComponentModel"):
        return true
    if Util.SameString(_compType, "Fan:OnOff"):
        return true
    if Util.SameString(_compType, "Fan:ConstantVolume"):
        return true
    if Util.SameString(_compType, "Fan:VariableVolume"):
        return true
    return false
def BaseSizer.checkInitialized(inout self, inout state: EnergyPlusData, inout errorsFound: Bool) -> Bool:
    if not self.initialized:
        errorsFound = true
        self.errorType = AutoSizingResultType.ErrorType2
        self.autoSizedValue = 0.0
        var msg: String = "Developer Error: uninitialized sizing of " + self.sizingString + "."
        self.addErrorMessage(msg)
        ShowSevereError(state, msg)
        msg = "Occurs in " + self.compType + " " + self.compName
        self.addErrorMessage(msg)
        ShowContinueError(state, msg)
        return false
    return true
def BaseSizer.overrideSizingString(inout self, string: String):
    var word: String
    var result: String = ""
    var str: String = string
    var iss = str.split("_")
    for w in iss:
        word = w
        if word == "for" or word == "per" or word == "at":  # don't Capitalize certain words
            result += word
        elif word == "ua":  # Capitalize all letters of certain words
            word = word.upper()
            result += word
        else:
            if len(word) > 0:
                result += word[0].upper()
                result += word[1:]
        if len(result) != len(str):
            result += " "
    self.sizingString = result
    self.overrideSizeString = false
def BaseSizer.setOAFracForZoneEqSizing(state: EnergyPlusData, desMassFlow: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData) -> Float64:
    var outAirFrac: Float64 = 0.0
    if desMassFlow <= 0.0:
        return outAirFrac
    if zoneEqSizing.ATMixerVolFlow > 0.0:
        outAirFrac = min(state.dataEnvrn.StdRhoAir * zoneEqSizing.ATMixerVolFlow / desMassFlow, 1.0)
    elif zoneEqSizing.OAVolFlow > 0.0:
        outAirFrac = min(state.dataEnvrn.StdRhoAir * zoneEqSizing.OAVolFlow / desMassFlow, 1.0)
    return outAirFrac
def BaseSizer.setHeatCoilInletTempForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData, finalZoneSizing: DataSizing.ZoneSizingData) -> Float64:
    var coilInTemp: Float64 = 0.0
    if zoneEqSizing.ATMixerVolFlow > 0.0:
        coilInTemp = (1.0 - outAirFrac) * finalZoneSizing.ZoneRetTempAtHeatPeak + outAirFrac * zoneEqSizing.ATMixerHeatPriDryBulb
    elif zoneEqSizing.OAVolFlow > 0.0:
        coilInTemp = (1.0 - outAirFrac) * finalZoneSizing.ZoneTempAtHeatPeak + outAirFrac * finalZoneSizing.OutTempAtHeatPeak
    else:
        coilInTemp = finalZoneSizing.ZoneTempAtHeatPeak
    return coilInTemp
def BaseSizer.setHeatCoilInletHumRatForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData, finalZoneSizing: DataSizing.ZoneSizingData) -> Float64:
    var coilInHumRat: Float64 = 0.0
    if zoneEqSizing.ATMixerVolFlow > 0.0:
        coilInHumRat = (1.0 - outAirFrac) * finalZoneSizing.ZoneHumRatAtHeatPeak + outAirFrac * zoneEqSizing.ATMixerHeatPriHumRat
    elif zoneEqSizing.OAVolFlow > 0.0:
        coilInHumRat = (1.0 - outAirFrac) * finalZoneSizing.ZoneHumRatAtHeatPeak + outAirFrac * finalZoneSizing.OutHumRatAtHeatPeak
    else:
        coilInHumRat = finalZoneSizing.ZoneHumRatAtHeatPeak
    return coilInHumRat
def BaseSizer.setCoolCoilInletTempForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData, finalZoneSizing: DataSizing.ZoneSizingData) -> Float64:
    var coilInTemp: Float64 = 0.0
    if zoneEqSizing.ATMixerVolFlow > 0.0:
        coilInTemp = (1.0 - outAirFrac) * finalZoneSizing.ZoneRetTempAtCoolPeak + outAirFrac * zoneEqSizing.ATMixerCoolPriDryBulb
    elif zoneEqSizing.OAVolFlow > 0.0:
        coilInTemp = (1.0 - outAirFrac) * finalZoneSizing.ZoneTempAtCoolPeak + outAirFrac * finalZoneSizing.OutTempAtCoolPeak
    else:
        coilInTemp = finalZoneSizing.ZoneTempAtCoolPeak
    return coilInTemp
def BaseSizer.setCoolCoilInletHumRatForZoneEqSizing(outAirFrac: Float64, zoneEqSizing: DataSizing.ZoneEqSizingData, finalZoneSizing: DataSizing.ZoneSizingData) -> Float64:
    var coilInHumRat: Float64 = 0.0
    if zoneEqSizing.ATMixerVolFlow > 0.0:
        coilInHumRat = (1.0 - outAirFrac) * finalZoneSizing.ZoneHumRatAtCoolPeak + outAirFrac * zoneEqSizing.ATMixerCoolPriHumRat
    elif zoneEqSizing.OAVolFlow > 0.0:
        coilInHumRat = (1.0 - outAirFrac) * finalZoneSizing.ZoneHumRatAtCoolPeak + outAirFrac * finalZoneSizing.OutHumRatAtCoolPeak
    else:
        coilInHumRat = finalZoneSizing.ZoneHumRatAtCoolPeak
    return coilInHumRat
def BaseSizer.calcCoilWaterFlowRates(inout state: EnergyPlusData, compName: String, compType: String, peakWaterFlow: Float64, loopNum: Int, curZoneEqNum: Int, curSysNum: Int, curOASysNum: Int, finalZoneSizing: DynamicVector[DataSizing.ZoneSizingData], finalSysSizing: DynamicVector[DataSizing.SystemSizingData]):
    var peakAirFlow: Float64 = 0.0
    var timeStepInDay: Int = 24 * state.dataGlobal.TimeStepsInHour
    if loopNum > 0 and loopNum <= state.dataHVACGlobal.NumPlantLoops and ((curZoneEqNum > 0 and not finalZoneSizing.empty()) or (curSysNum > 0 and not finalSysSizing.empty()) or (curOASysNum > 0 and not finalSysSizing.empty())):
        var heatingLoop: Bool = false
        if not state.dataSize.PlantSizData.empty():
            var plntSizIndex: Int = Util.FindItemInList(state.dataPlnt.PlantLoop[loopNum].Name, state.dataSize.PlantSizData, DataSizing.PlantSizingData.PlantLoopName)
            if plntSizIndex > 0 and state.dataSize.PlantSizData[plntSizIndex].LoopType == DataSizing.TypeOfPlantLoop.Heating:
                heatingLoop = true
        var plntComps = state.dataPlnt.PlantLoop[loopNum].plantCoilObjectNames
        var arrayIndex: Int = -1
        if not plntComps.empty():
            var cmpType = state.dataPlnt.PlantLoop[loopNum].plantCoilObjectTypes
            for i in range(len(plntComps)):
                if plntComps[i] == compName and cmpType[i] == int(getEnumValue(DataPlant.PlantEquipTypeNames, compType)):
                    arrayIndex = i
                    break
        if arrayIndex == -1:
            state.dataPlnt.PlantLoop[loopNum].plantCoilObjectNames.append(compName)
            state.dataPlnt.PlantLoop[loopNum].plantCoilObjectTypes.append(int(getEnumValue(DataPlant.PlantEquipTypeNames, compType)))
        var tmpFlowData: DynamicVector[Float64] = DynamicVector[Float64]()
        tmpFlowData.resize(timeStepInDay)
        if curZoneEqNum > 0:
            if heatingLoop:
                for heatFlowSeq in finalZoneSizing[curZoneEqNum].HeatFlowSeq:
                    if heatFlowSeq > peakAirFlow:
                        peakAirFlow = heatFlowSeq
            else:
                for coolFlowSeq in finalZoneSizing[curZoneEqNum].CoolFlowSeq:
                    if coolFlowSeq > peakAirFlow:
                        peakAirFlow = coolFlowSeq
            if peakAirFlow == 0.0:
                peakAirFlow = 1.0
            for ts in range(len(finalZoneSizing[curZoneEqNum].CoolFlowSeq)):
                if heatingLoop:
                    tmpFlowData[ts] = peakWaterFlow * (finalZoneSizing[curZoneEqNum].HeatFlowSeq[ts] / peakAirFlow)
                else:
                    tmpFlowData[ts] = peakWaterFlow * (finalZoneSizing[curZoneEqNum].CoolFlowSeq[ts] / peakAirFlow)
        elif curSysNum > state.dataHVACGlobal.NumPrimaryAirSys and curOASysNum > 0:
            if heatingLoop:
                for heatFlowSeq in finalSysSizing[state.dataHVACGlobal.NumPrimaryAirSys].HeatFlowSeq:
                    if heatFlowSeq > peakAirFlow:
                        peakAirFlow = heatFlowSeq
            else:
                for coolFlowSeq in finalSysSizing[state.dataHVACGlobal.NumPrimaryAirSys].CoolFlowSeq:
                    if coolFlowSeq > peakAirFlow:
                        peakAirFlow = coolFlowSeq
            if peakAirFlow == 0.0:
                peakAirFlow = 1.0
            for ts in range(len(finalSysSizing[state.dataHVACGlobal.NumPrimaryAirSys].HeatFlowSeq)):
                if heatingLoop:
                    tmpFlowData[ts] = peakWaterFlow * (finalSysSizing[state.dataHVACGlobal.NumPrimaryAirSys].HeatFlowSeq[ts] / peakAirFlow)
                else:
                    tmpFlowData[ts] = peakWaterFlow * (finalSysSizing[state.dataHVACGlobal.NumPrimaryAirSys].CoolFlowSeq[ts] / peakAirFlow)
        elif curOASysNum > 0:
            if heatingLoop:
                for heatFlowSeq in finalSysSizing[state.dataHVACGlobal.NumPrimaryAirSys].HeatFlowSeq:
                    if heatFlowSeq > peakAirFlow:
                        peakAirFlow = heatFlowSeq
            else:
                for coolFlowSeq in finalSysSizing[state.dataHVACGlobal.NumPrimaryAirSys].CoolFlowSeq:
                    if coolFlowSeq > peakAirFlow:
                        peakAirFlow = coolFlowSeq
            if peakAirFlow == 0.0:
                peakAirFlow = 1.0
            for ts in range(len(finalSysSizing[curSysNum].CoolFlowSeq)):
                if heatingLoop:
                    tmpFlowData[ts] = peakWaterFlow * (finalSysSizing[curSysNum].HeatFlowSeq[ts] / peakAirFlow)
                else:
                    tmpFlowData[ts] = peakWaterFlow * (finalSysSizing[curSysNum].CoolFlowSeq[ts] / peakAirFlow)
        elif curSysNum > 0:
            if heatingLoop:
                for heatFlowSeq in finalSysSizing[curSysNum].HeatFlowSeq:
                    if heatFlowSeq > peakAirFlow:
                        peakAirFlow = heatFlowSeq
            else:
                for coolFlowSeq in finalSysSizing[curSysNum].CoolFlowSeq:
                    if coolFlowSeq > peakAirFlow:
                        peakAirFlow = coolFlowSeq
            if peakAirFlow == 0.0:
                peakAirFlow = 1.0
            for ts in range(len(finalSysSizing[curSysNum].CoolFlowSeq)):
                if heatingLoop:
                    tmpFlowData[ts] = peakWaterFlow * (finalSysSizing[curSysNum].HeatFlowSeq[ts] / peakAirFlow)
                else:
                    tmpFlowData[ts] = peakWaterFlow * (finalSysSizing[curSysNum].CoolFlowSeq[ts] / peakAirFlow)
        var plntCoilData = state.dataPlnt.PlantLoop[loopNum].compDesWaterFlowRate
        if arrayIndex == -1:
            arrayIndex = len(plntCoilData) + 1
            plntCoilData.resize(arrayIndex)
            plntCoilData[arrayIndex - 1].tsDesWaterFlowRate = DynamicVector[Float64](timeStepInDay)
            plntCoilData[arrayIndex - 1].tsDesWaterFlowRate = tmpFlowData
        else:
            plntCoilData[arrayIndex].tsDesWaterFlowRate = tmpFlowData
def BaseSizer.clearState(inout self):
    self.stdRhoAir = 0.0
    self.zoneAirFlowSizMethod = 0
    self.dataScalableSizingON = false
    self.dataScalableCapSizingON = false
    self.isCoilReportObject = false
    self.isFanReportObject = false
    self.initialized = false
    self.errorType = AutoSizingResultType.NoError
    self.sizingString = ""
    self.sizingStringScalable = ""
    self.overrideSizeString = true
    self.originalValue = 0.0
    self.autoSizedValue = 0.0
    self.wasAutoSized = false
    self.hardSizeNoDesignRun = false
    self.sizingDesRunThisAirSys = false
    self.sizingDesRunThisZone = false
    self.sizingDesValueFromParent = false
    self.airLoopSysFlag = false
    self.oaSysFlag = false
    self.coilType = HVAC.CoilType.Invalid
    self.compType = ""
    self.compName = ""
    self.isEpJSON = false
    self.sysSizingRunDone = false
    self.zoneSizingRunDone = false
    self.curSysNum = 0
    self.curOASysNum = 0
    self.curZoneEqNum = 0
    self.curDuctType = HVAC.AirDuctType.Invalid
    self.curTermUnitSizingNum = 0
    self.numPrimaryAirSys = 0
    self.numSysSizInput = 0
    self.doSystemSizing = false
    self.numZoneSizingInput = 0
    self.doZoneSizing = false
    self.autoCalculate = false
    self.termUnitSingDuct = false
    self.termUnitPIU = false
    self.termUnitIU = false
    self.zoneEqFanCoil = false
    self.otherEqType = false
    self.zoneEqUnitHeater = false
    self.zoneEqUnitVent = false
    self.zoneEqVentedSlab = false
    self.getLastErrorMessages()
    self.minOA = DataSizing.OAControl.Invalid
    self.dataEMSOverrideON = false
    self.dataEMSOverride = 0.0
    self.dataAutosizable = false
    self.dataConstantUsedForSizing = 0.0
    self.dataFractionUsedForSizing = 0.0
    self.dataDXCoolsLowSpeedsAutozize = false
    self.dataPltSizHeatNum = 0
    self.dataWaterLoopNum = 0
    self.dataFanIndex = -1
    self.dataFanType = HVAC.FanType.Invalid
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
    self.dataDesAccountForFanHeat = false
    self.dataFanPlacement = HVAC.FanPlace.Invalid
    self.dataDesicRegCoil = false
    self.dataHeatSizeRatio = 0.0
    self.dataZoneUsedForSizing = 0
    self.dataDesicDehumNum = 0
    self.dataNomCapInpMeth = false
    self.dataCoilNum = 0
    self.dataFanOp = HVAC.FanOp.Invalid
    self.dataDesignCoilCapacity = 0.0
    self.dataErrorsFound = false
    self.dataBypassFrac = 0.0
    self.dataIsDXCoil = false
    self.dataNonZoneNonAirloopValue = 0.0
    self.printWarningFlag = false
    self.callingRoutine = ""
    self.sysSizingInputData.clear()
    self.zoneSizingInput.clear()
    self.unitarySysEqSizing.clear()
    self.oaSysEqSizing.clear()
    self.zoneEqSizing.clear()
    self.outsideAirSys.clear()
    self.termUnitSizing.clear()
    self.termUnitFinalZoneSizing.clear()
    self.finalZoneSizing.clear()
    self.finalSysSizing.clear()
    self.plantSizData.clear()
    self.primaryAirSystem.clear()
    self.airloopDOAS.clear()