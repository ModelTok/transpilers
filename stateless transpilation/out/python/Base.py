# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object (EnergyPlus)
# - DataSizing: enum OAControl, data classes ZoneSizingInputData, ZoneEqSizingData, TermUnitSizingData, 
#   TermUnitZoneSizingData, ZoneSizingData, SystemSizingData, SystemSizingInputData, PlantSizingData
# - DataAirLoop: class OutsideAirSysProps, AirLoopControlData
# - DataAirSystems: class DefinePrimaryAirSystem
# - AirLoopHVACDOAS: class AirLoopDOAS
# - HVAC: enums CoilType, FanType, AirDuctType, FanPlace, FanOp; mapping coilTypeNamesUC
# - DataPlant: class PlantLoop, enum PlantEquipmentType, mapping PlantEquipTypeNames
# - ReportCoilSelection.getReportIndex(state, name, coil_type) -> int
# - OutputReportPredefined: AddCompSizeTableEntry, AddCompSizeTableStrEntry functions
# - Psychrometrics.PsyRhoAirFnPbTdbW(state, press, tdb, w) -> Real64
# - Util: SameString, FindItemInList, makeUPPER functions
# - ShowSevereError, ShowFatalError, ShowContinueError, ShowMessage functions
# - getEnumValue(mapping, name) -> int
# - DataEnvironment: constants and state data members

from abc import ABC, abstractmethod
from enum import IntEnum
from typing import List, Optional, Tuple
from dataclasses import dataclass, field
from io import TextIOBase
import math


class AutoSizingType(IntEnum):
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
    SystemCapacitySizing = 21
    CoolingSHRSizing = 22
    HeatingDefrostSizing = 23
    MaxHeaterOutletTempSizing = 24
    AutoCalculateSizing = 25
    ZoneCoolingLoadSizing = 26
    ZoneHeatingLoadSizing = 27
    MinSATempCoolingSizing = 28
    MaxSATempHeatingSizing = 29
    ASHRAEMinSATCoolingSizing = 30
    ASHRAEMaxSATHeatingSizing = 31
    HeatingCoilDesAirInletTempSizing = 32
    HeatingCoilDesAirOutletTempSizing = 33
    HeatingCoilDesAirInletHumRatSizing = 34
    DesiccantDehumidifierBFPerfDataFaceVelocitySizing = 35
    Num = 36


class AutoSizingResultType(IntEnum):
    Invalid = -1
    NoError = 0
    ErrorType1 = 1
    ErrorType2 = 2
    Num = 3


class BaseSizer(ABC):
    def __init__(self):
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
        self.coilType = None
        self.compType = ""
        self.compName = ""
        self.isEpJSON = False
        self.sysSizingRunDone = False
        self.zoneSizingRunDone = False
        self.curSysNum = 0
        self.curOASysNum = 0
        self.curZoneEqNum = 0
        self.curDuctType = None
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
        self.minOA = None
        self.dataEMSOverrideON = False
        self.dataEMSOverride = 0.0
        self.dataAutosizable = False
        self.dataConstantUsedForSizing = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.dataDXCoolsLowSpeedsAutozize = False
        self.dataPltSizHeatNum = 0
        self.dataWaterLoopNum = 0
        self.dataFanIndex = 0
        self.dataFanType = None
        self.dataWaterCoilSizCoolDeltaT = 0.0
        self.dataWaterCoilSizHeatDeltaT = 0.0
        self.dataCapacityUsedForSizing = 0.0
        self.dataPltSizCoolNum = 0
        self.dataDesInletAirHumRat = 0.0
        self.dataAirFlowUsedForSizing = 0.0
        self.dataDesInletAirTemp = 0.0
        self.dataDesAccountForFanHeat = False
        self.dataFanPlacement = None
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
        self.dataFanOp = None
        self.dataDesignCoilCapacity = 0.0
        self.dataErrorsFound = False
        self.dataBypassFrac = 0.0
        self.dataIsDXCoil = False
        self.dataNonZoneNonAirloopValue = 0.0
        self.printWarningFlag = False
        self.callingRoutine = ""
        self.sysSizingInputData = []
        self.zoneSizingInput = []
        self.unitarySysEqSizing = []
        self.oaSysEqSizing = []
        self.zoneEqSizing = []
        self.outsideAirSys = []
        self.termUnitSizing = []
        self.termUnitFinalZoneSizing = []
        self.finalZoneSizing = []
        self.finalSysSizing = []
        self.plantSizData = []
        self.primaryAirSystem = []
        self.airloopDOAS = []
        self.airLoopControlInfo = []
        self.lastErrorMessages = ""

    @abstractmethod
    def size(self, state, original_value: float) -> Tuple[float, bool]:
        pass

    def initializeWithinEP(self, state, _compType: str, _compName: str, _printWarningFlag: bool, _callingRoutine: str) -> None:
        self.initialized = True
        self.compType = _compType
        self.compName = _compName
        self.isEpJSON = state.dataGlobal.isEpJSON if hasattr(state, 'dataGlobal') else False
        self.printWarningFlag = _printWarningFlag
        self.callingRoutine = _callingRoutine
        self.stdRhoAir = state.dataEnvrn.StdRhoAir if hasattr(state, 'dataEnvrn') else 0.0
        self.sysSizingRunDone = state.dataSize.SysSizingRunDone if hasattr(state, 'dataSize') else False
        self.zoneSizingRunDone = state.dataSize.ZoneSizingRunDone if hasattr(state, 'dataSize') else False
        self.curSysNum = state.dataSize.CurSysNum if hasattr(state, 'dataSize') else 0
        self.curOASysNum = state.dataSize.CurOASysNum if hasattr(state, 'dataSize') else 0
        self.curZoneEqNum = state.dataSize.CurZoneEqNum if hasattr(state, 'dataSize') else 0
        self.curDuctType = state.dataSize.CurDuctType if hasattr(state, 'dataSize') else None
        self.numPrimaryAirSys = state.dataHVACGlobal.NumPrimaryAirSys if hasattr(state, 'dataHVACGlobal') else 0
        self.numSysSizInput = state.dataSize.NumSysSizInput if hasattr(state, 'dataSize') else 0
        self.doSystemSizing = state.dataGlobal.DoSystemSizing if hasattr(state, 'dataGlobal') else False
        self.numZoneSizingInput = state.dataSize.NumZoneSizingInput if hasattr(state, 'dataSize') else 0
        self.doZoneSizing = state.dataGlobal.DoZoneSizing if hasattr(state, 'dataGlobal') else False
        self.curTermUnitSizingNum = state.dataSize.CurTermUnitSizingNum if hasattr(state, 'dataSize') else 0
        self.termUnitSingDuct = state.dataSize.TermUnitSingDuct if hasattr(state, 'dataSize') else False
        self.termUnitPIU = state.dataSize.TermUnitPIU if hasattr(state, 'dataSize') else False
        self.termUnitIU = state.dataSize.TermUnitIU if hasattr(state, 'dataSize') else False
        self.zoneEqFanCoil = state.dataSize.ZoneEqFanCoil if hasattr(state, 'dataSize') else False
        self.otherEqType = not (self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil)
        self.zoneEqUnitHeater = state.dataSize.ZoneEqUnitHeater if hasattr(state, 'dataSize') else False
        self.zoneEqUnitVent = state.dataSize.ZoneEqUnitVent if hasattr(state, 'dataSize') else False
        self.zoneEqVentedSlab = state.dataSize.ZoneEqVentedSlab if hasattr(state, 'dataSize') else False
        self.zoneSizingInput = state.dataSize.ZoneSizingInput if hasattr(state, 'dataSize') else []
        self.unitarySysEqSizing = state.dataSize.UnitarySysEqSizing if hasattr(state, 'dataSize') else []
        self.oaSysEqSizing = state.dataSize.OASysEqSizing if hasattr(state, 'dataSize') else []
        self.outsideAirSys = state.dataAirLoop.OutsideAirSys if hasattr(state, 'dataAirLoop') else []
        self.termUnitSizing = state.dataSize.TermUnitSizing if hasattr(state, 'dataSize') else []
        self.finalZoneSizing = state.dataSize.FinalZoneSizing if hasattr(state, 'dataSize') else []
        self.termUnitFinalZoneSizing = state.dataSize.TermUnitFinalZoneSizing if hasattr(state, 'dataSize') else []
        self.zoneEqSizing = state.dataSize.ZoneEqSizing if hasattr(state, 'dataSize') else []
        self.sysSizingInputData = state.dataSize.SysSizInput if hasattr(state, 'dataSize') else []
        self.finalSysSizing = state.dataSize.FinalSysSizing if hasattr(state, 'dataSize') else []
        self.plantSizData = state.dataSize.PlantSizData if hasattr(state, 'dataSize') else []
        self.primaryAirSystem = state.dataAirSystemsData.PrimaryAirSystems if hasattr(state, 'dataAirSystemsData') else []
        self.airLoopControlInfo = state.dataAirLoop.AirLoopControlInfo if hasattr(state, 'dataAirLoop') else []
        self.airloopDOAS = state.dataAirLoopHVACDOAS.airloopDOAS if hasattr(state, 'dataAirLoopHVACDOAS') else []
        
        if self.isValidCoilType(self.compType):
            self.isCoilReportObject = True
            self.coilReportNum = self._getReportIndex(state, self.compName)
        if self.isValidFanType(self.compType):
            self.isFanReportObject = True
        
        self.dataEMSOverrideON = state.dataSize.DataEMSOverrideON if hasattr(state, 'dataSize') else False
        self.dataEMSOverride = state.dataSize.DataEMSOverride if hasattr(state, 'dataSize') else 0.0
        self.dataAutosizable = state.dataSize.DataAutosizable if hasattr(state, 'dataSize') else False
        self.minOA = None
        self.dataConstantUsedForSizing = state.dataSize.DataConstantUsedForSizing if hasattr(state, 'dataSize') else 0.0
        self.dataFractionUsedForSizing = state.dataSize.DataFractionUsedForSizing if hasattr(state, 'dataSize') else 0.0
        if hasattr(state, 'dataSize'):
            state.dataSize.DataConstantUsedForSizing = 0.0
            state.dataSize.DataFractionUsedForSizing = 0.0
        
        self.dataFanIndex = state.dataSize.DataFanIndex if hasattr(state, 'dataSize') else 0
        self.dataFanType = state.dataSize.DataFanType if hasattr(state, 'dataSize') else None
        
        self.dataPltSizHeatNum = state.dataSize.DataPltSizHeatNum if hasattr(state, 'dataSize') else 0
        self.dataWaterLoopNum = state.dataSize.DataWaterLoopNum if hasattr(state, 'dataSize') else 0
        self.dataPltSizCoolNum = state.dataSize.DataPltSizCoolNum if hasattr(state, 'dataSize') else 0
        self.dataWaterCoilSizHeatDeltaT = state.dataSize.DataWaterCoilSizHeatDeltaT if hasattr(state, 'dataSize') else 0.0
        self.dataWaterCoilSizCoolDeltaT = state.dataSize.DataWaterCoilSizCoolDeltaT if hasattr(state, 'dataSize') else 0.0
        self.dataCapacityUsedForSizing = state.dataSize.DataCapacityUsedForSizing if hasattr(state, 'dataSize') else 0.0
        self.dataHeatSizeRatio = state.dataSize.DataHeatSizeRatio if hasattr(state, 'dataSize') else 0.0
        
        self.dataAirFlowUsedForSizing = state.dataSize.DataAirFlowUsedForSizing if hasattr(state, 'dataSize') else 0.0
        self.dataDesInletAirTemp = state.dataSize.DataDesInletAirTemp if hasattr(state, 'dataSize') else 0.0
        self.dataDesAccountForFanHeat = state.dataSize.DataDesAccountForFanHeat if hasattr(state, 'dataSize') else False
        self.dataFanPlacement = state.dataSize.DataFanPlacement if hasattr(state, 'dataSize') else None
        self.dataDesInletAirHumRat = state.dataSize.DataDesInletAirHumRat if hasattr(state, 'dataSize') else 0.0
        self.dataDesOutletAirHumRat = state.dataSize.DataDesOutletAirHumRat if hasattr(state, 'dataSize') else 0.0
        self.dataDesOutletAirTemp = state.dataSize.DataDesOutletAirTemp if hasattr(state, 'dataSize') else 0.0
        self.dataDesInletWaterTemp = state.dataSize.DataDesInletWaterTemp if hasattr(state, 'dataSize') else 0.0
        self.dataFlowUsedForSizing = state.dataSize.DataFlowUsedForSizing if hasattr(state, 'dataSize') else 0.0
        self.dataWaterFlowUsedForSizing = state.dataSize.DataWaterFlowUsedForSizing if hasattr(state, 'dataSize') else 0.0
        
        self.dataSizingFraction = state.dataSize.DataSizingFraction if hasattr(state, 'dataSize') else 1.0
        self.dataDXSpeedNum = state.dataSize.DataDXSpeedNum if hasattr(state, 'dataSize') else 0
        self.dataDesicRegCoil = state.dataSize.DataDesicRegCoil if hasattr(state, 'dataSize') else False
        self.dataZoneUsedForSizing = state.dataSize.DataZoneUsedForSizing if hasattr(state, 'dataSize') else 0
        self.dataDesicDehumNum = state.dataSize.DataDesicDehumNum if hasattr(state, 'dataSize') else 0
        
        self.dataNomCapInpMeth = state.dataSize.DataNomCapInpMeth if hasattr(state, 'dataSize') else False
        self.dataCoilNum = state.dataSize.DataCoilNum if hasattr(state, 'dataSize') else 0
        self.dataFanOp = state.dataSize.DataFanOp if hasattr(state, 'dataSize') else None
        self.dataDesignCoilCapacity = state.dataSize.DataDesignCoilCapacity if hasattr(state, 'dataSize') else 0.0
        self.dataErrorsFound = state.dataSize.DataErrorsFound if hasattr(state, 'dataSize') else False
        self.dataBypassFrac = state.dataSize.DataBypassFrac if hasattr(state, 'dataSize') else 0.0
        self.dataIsDXCoil = state.dataSize.DataIsDXCoil if hasattr(state, 'dataSize') else False
        self.dataNonZoneNonAirloopValue = state.dataSize.DataNonZoneNonAirloopValue if hasattr(state, 'dataSize') else 0.0
        self.dataDXCoolsLowSpeedsAutozize = state.dataSize.DataDXCoolsLowSpeedsAutozize if hasattr(state, 'dataSize') else False

    def initializeFromAPI(self, state, elevation: float) -> None:
        self.clearState()
        self.initialized = True
        self.compType = "API_component_type"
        self.compName = "API_component_name"
        self.printWarningFlag = False
        self.callingRoutine = "called_from_API"
        barometricPressure = 101325.0 * ((1.0 - 2.25577e-05 * elevation) ** 5.2559)
        self.stdRhoAir = self._psyRhoAirFnPbTdbW(state, barometricPressure, 20.0, 0.0)
        self.isCoilReportObject = False

    def addErrorMessage(self, s: str) -> None:
        self.lastErrorMessages += s + "\n"

    def getLastErrorMessages(self) -> str:
        s = self.lastErrorMessages
        self.lastErrorMessages = ""
        return s

    def preSize(self, state, original_value: float) -> None:
        if self.sizingType == AutoSizingType.Invalid:
            msg = "Sizing Library Base Class: preSize, SizingType not defined."
            self.addErrorMessage(msg)
            self._showSevereError(state, msg)
            self._showFatalError(state, "Sizing type causes fatal error.")
        
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
                msg = "Sizing Library: DataConstantUsedForSizing and DataFractionUsedForSizing used for autocalculating " + self.sizingString + " must both be greater than 0."
                self.addErrorMessage(msg)
                self._showSevereError(state, msg)
        elif self.dataFractionUsedForSizing > 0.0:
            self.autoCalculate = True
            self.hardSizeNoDesignRun = False
        elif self.sizingType == AutoSizingType.AutoCalculateSizing:
            self.autoCalculate = True
            if self.originalValue == -99999.0 and not self.dataEMSOverrideON:
                self.errorType = AutoSizingResultType.ErrorType1
                msg = "Sizing Library: DataConstantUsedForSizing and DataFractionUsedForSizing used for autocalculating " + self.sizingString + " must both be greater than 0."
                self.addErrorMessage(msg)
                self._showSevereError(state, msg)
        
        if self.curSysNum > 0 and self.curSysNum <= self.numPrimaryAirSys:
            if self.sysSizingRunDone:
                sysNum = self.curSysNum
                self.sizingDesRunThisAirSys = any(ssid.AirLoopNum == sysNum for ssid in self.sysSizingInputData if hasattr(ssid, 'AirLoopNum'))
            if len(self.unitarySysEqSizing) > 0:
                if self.curSysNum <= len(self.unitarySysEqSizing):
                    usy = self.unitarySysEqSizing[self.curSysNum - 1]
                    self.airLoopSysFlag = (hasattr(usy, 'CoolingCapacity') and usy.CoolingCapacity) or (hasattr(usy, 'HeatingCapacity') and usy.HeatingCapacity)
            if self.curOASysNum > 0 and len(self.oaSysEqSizing) > 0:
                if self.curOASysNum <= len(self.oaSysEqSizing):
                    osy = self.oaSysEqSizing[self.curOASysNum - 1]
                    self.oaSysFlag = (hasattr(osy, 'CoolingCapacity') and osy.CoolingCapacity) or (hasattr(osy, 'HeatingCapacity') and osy.HeatingCapacity)
        
        if self.curZoneEqNum > 0:
            if len(self.zoneEqSizing) > 0 and self.curZoneEqNum <= len(self.zoneEqSizing):
                zeq = self.zoneEqSizing[self.curZoneEqNum - 1]
                self.sizingDesValueFromParent = hasattr(zeq, 'DesignSizeFromParent') and zeq.DesignSizeFromParent
            if self.zoneSizingRunDone:
                zoneNum = self.curZoneEqNum
                self.sizingDesRunThisZone = any(zsi.ZoneNum == zoneNum for zsi in self.zoneSizingInput if hasattr(zsi, 'ZoneNum'))
            self.hardSizeNoDesignRun = False
        
        if self.originalValue == -99999.0:
            self.wasAutoSized = True
            self.hardSizeNoDesignRun = False
            if not self.sizingDesRunThisAirSys and self.curSysNum > 0 and not self.autoCalculate:
                if not self.sysSizingRunDone:
                    msg = f"For autosizing of {self.compType} {self.compName}, a system sizing run must be done."
                    self.addErrorMessage(msg)
                    self._showSevereError(state, msg)
                    if self.numSysSizInput == 0:
                        msg2 = 'No "Sizing:System" objects were entered.'
                        self.addErrorMessage(msg2)
                        self._showContinueError(state, msg2)
                    if not self.doSystemSizing:
                        msg2 = 'The "SimulationControl" object did not have the field "Do System Sizing Calculation" set to Yes.'
                        self.addErrorMessage(msg2)
                        self._showContinueError(state, msg2)
                    self._showFatalError(state, "Program terminates due to previously shown condition(s).")
            if not self.sizingDesRunThisZone and self.curZoneEqNum > 0 and not self.sizingDesValueFromParent and not self.autoCalculate:
                if not self.zoneSizingRunDone:
                    msg = f"For autosizing of {self.compType} {self.compName}, a zone sizing run must be done."
                    self.addErrorMessage(msg)
                    self._showSevereError(state, msg)
                    if self.numZoneSizingInput == 0:
                        msg2 = 'No "Sizing:Zone" objects were entered.'
                        self.addErrorMessage(msg2)
                        self._showContinueError(state, msg2)
                    if not self.doZoneSizing:
                        msg2 = 'The "SimulationControl" object did not have the field "Do Zone Sizing Calculation" set to Yes.'
                        self.addErrorMessage(msg2)
                        self._showContinueError(state, msg2)
                    self._showFatalError(state, "Program terminates due to previously shown condition(s).")
        else:
            self.wasAutoSized = False

    @staticmethod
    def reportSizerOutput(state, CompType: str, CompName: str, VarDesc: str, VarValue: float, UsrDesc: Optional[str] = None, UsrValue: Optional[float] = None) -> None:
        Format_990 = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        Format_991 = " Component Sizing Information, {}, {}, {}, {}\n"
        Format_991_HumRat = " Component Sizing Information, {}, {}, {}, {:.3E}\n"
        
        sizingFormat = Format_991_HumRat if "Humidity Ratio" in VarDesc else Format_991
        
        if hasattr(state, 'dataEnvrn') and hasattr(state.dataEnvrn, 'oneTimeCompRptHeaderFlag') and state.dataEnvrn.oneTimeCompRptHeaderFlag:
            if hasattr(state, 'files') and hasattr(state.files, 'eio'):
                state.files.eio.write(Format_990)
            state.dataEnvrn.oneTimeCompRptHeaderFlag = False
        
        if hasattr(state, 'files') and hasattr(state.files, 'eio'):
            if "Humidity Ratio" in VarDesc:
                state.files.eio.write(f" Component Sizing Information, {CompType}, {CompName}, {VarDesc}, {VarValue:.3E}\n")
            else:
                state.files.eio.write(f" Component Sizing Information, {CompType}, {CompName}, {VarDesc}, {VarValue}\n")
        
        if UsrDesc is not None and UsrValue is not None:
            if hasattr(state, 'files') and hasattr(state.files, 'eio'):
                if "Humidity Ratio" in UsrDesc:
                    state.files.eio.write(f" Component Sizing Information, {CompType}, {CompName}, {UsrDesc}, {UsrValue:.3E}\n")
                else:
                    state.files.eio.write(f" Component Sizing Information, {CompType}, {CompName}, {UsrDesc}, {UsrValue}\n")
        elif UsrDesc is not None or UsrValue is not None:
            BaseSizer._showFatalError(state, "ReportSizingOutput: (Developer Error) - called with user-specified description or value but not both.")

    @staticmethod
    def reportSizerStrOutput(state, CompType: str, CompName: str, VarDesc: str, VarValue: str) -> None:
        Format_990 = "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        Format_991 = " Component Sizing Information, {}, {}, {}, {}\n"
        
        if hasattr(state, 'dataEnvrn') and hasattr(state.dataEnvrn, 'oneTimeCompRptHeaderFlag') and state.dataEnvrn.oneTimeCompRptHeaderFlag:
            if hasattr(state, 'files') and hasattr(state.files, 'eio'):
                state.files.eio.write(Format_990)
            state.dataEnvrn.oneTimeCompRptHeaderFlag = False
        
        if hasattr(state, 'files') and hasattr(state.files, 'eio'):
            state.files.eio.write(f" Component Sizing Information, {CompType}, {CompName}, {VarDesc}, {VarValue}\n")

    def selectSizerOutput(self, state, errors_found: bool) -> bool:
        if self.printWarningFlag:
            if self.dataEMSOverrideON:
                self.autoSizedValue = self.dataEMSOverride
                self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            elif self.hardSizeNoDesignRun and not self.wasAutoSized and self._sameString(self.compType, "Fan:ZoneExhaust"):
                self.autoSizedValue = self.originalValue
            elif self.wasAutoSized and self.dataFractionUsedForSizing > 0.0 and self.dataConstantUsedForSizing > 0.0:
                self.autoSizedValue = self.dataFractionUsedForSizing * self.dataConstantUsedForSizing
                self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            elif not self.wasAutoSized and (self.autoSizedValue == self.originalValue or self.autoSizedValue == 0.0):
                self.autoSizedValue = self.originalValue
                if self.dataAutosizable or (not self.sizingDesRunThisZone and self._sameString(self.compType, "Fan:ZoneExhaust")):
                    self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            elif not self.wasAutoSized and self.autoSizedValue >= 0.0 and self.originalValue == 0.0:
                self.autoSizedValue = self.originalValue
                self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            elif self.wasAutoSized and self.autoSizedValue >= 0.0 and self.originalValue <= 0.0:
                if self.dataScalableSizingON and int(self.zoneAirFlowSizMethod) > 0:
                    self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
                else:
                    self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingString, self.autoSizedValue)
            elif self.autoSizedValue >= 0.0 and self.originalValue > 0.0:
                threshold = state.dataSize.AutoVsHardSizingThreshold if hasattr(state, 'dataSize') and hasattr(state.dataSize, 'AutoVsHardSizingThreshold') else 0.1
                if (abs(self.autoSizedValue - self.originalValue) / self.originalValue) > threshold:
                    if self.dataAutosizable:
                        self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingString, self.autoSizedValue,
                                             "User-Specified " + self.sizingStringScalable + self.sizingString, self.originalValue)
                else:
                    if self.dataAutosizable:
                        self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.originalValue)
                
                if hasattr(state, 'dataGlobal') and hasattr(state.dataGlobal, 'DisplayExtraWarnings') and state.dataGlobal.DisplayExtraWarnings and self.dataAutosizable:
                    if (abs(self.autoSizedValue - self.originalValue) / self.originalValue) > threshold:
                        msg = f"{self.callingRoutine}: Potential issue with equipment sizing for {self.compType} {self.compName}"
                        self.addErrorMessage(msg)
                        self._showMessage(state, msg)
                        msg = f"User-Specified {self.sizingStringScalable}{self.sizingString} = {self.originalValue}"
                        self.addErrorMessage(msg)
                        self._showContinueError(state, msg)
                        msg = f"differs from Design Size {self.sizingString} = {self.autoSizedValue}"
                        self.addErrorMessage(msg)
                        self._showContinueError(state, msg)
                        msg = "This may, or may not, indicate mismatched component sizes."
                        self.addErrorMessage(msg)
                        self._showContinueError(state, msg)
                        msg = "Verify that the value entered is intended and is consistent with other components."
                        self.addErrorMessage(msg)
                        self._showContinueError(state, msg)
                
                if not self.wasAutoSized:
                    self.autoSizedValue = self.originalValue
            elif self.wasAutoSized and self.autoSizedValue != -99999.0:
                self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            else:
                msg = f"{self.callingRoutine} {self.compType} {self.compName}, Developer Error: Component sizing incomplete."
                self.addErrorMessage(msg)
                self._showSevereError(state, msg)
                msg = f"SizingString = {self.sizingString}, SizingResult = {self.originalValue:.1f}"
                self.addErrorMessage(msg)
                self._showContinueError(state, msg)
                self.errorType = AutoSizingResultType.ErrorType1
        elif not self.wasAutoSized and not self.autoCalculate:
            self.autoSizedValue = self.originalValue
        
        self.overrideSizeString = True
        if self.errorType != AutoSizingResultType.NoError:
            msg = f"Developer Error: sizing of {self.sizingString} failed."
            self.addErrorMessage(msg)
            self._showSevereError(state, msg)
            msg = f"Occurs in {self.compType} {self.compName}"
            self.addErrorMessage(msg)
            self._showContinueError(state, msg)
            errors_found = True
        
        return errors_found

    def select2StgDXHumCtrlSizerOutput(self, state, errors_found: bool) -> bool:
        if self.printWarningFlag:
            if self.dataEMSOverrideON:
                self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
                if self._sameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                    self.autoSizedValue *= (1 - self.dataBypassFrac)
                    self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )", self.autoSizedValue)
            elif not self.wasAutoSized and (self.autoSizedValue == self.originalValue or self.autoSizedValue == 0.0):
                self.autoSizedValue = self.originalValue
                self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
                if self._sameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                    self.autoSizedValue *= (1 - self.dataBypassFrac)
                    self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )", self.autoSizedValue)
            elif not self.wasAutoSized and self.autoSizedValue >= 0.0 and self.originalValue == 0.0:
                self.autoSizedValue = self.originalValue
                self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
                if self._sameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                    self.autoSizedValue *= (1 - self.dataBypassFrac)
                    self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )", self.autoSizedValue)
            elif self.wasAutoSized and self.autoSizedValue >= 0.0 and self.originalValue <= 0.0:
                if self.dataScalableSizingON and int(self.zoneAirFlowSizMethod) > 0:
                    self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
                else:
                    self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingString, self.autoSizedValue)
                if self._sameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                    self.autoSizedValue *= (1 - self.dataBypassFrac)
                    self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingString + " ( non-bypassed )", self.autoSizedValue)
            elif self.autoSizedValue >= 0.0 and self.originalValue > 0.0:
                threshold = state.dataSize.AutoVsHardSizingThreshold if hasattr(state, 'dataSize') else 0.1
                if (abs(self.autoSizedValue - self.originalValue) / self.originalValue) > threshold:
                    self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingString, self.autoSizedValue,
                                         "User-Specified " + self.sizingStringScalable + self.sizingString, self.originalValue)
                    if self._sameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                        self.autoSizedValue *= (1 - self.dataBypassFrac)
                        self.originalValue *= (1 - self.dataBypassFrac)
                        self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingString + " ( non-bypassed )", self.autoSizedValue,
                                             "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )", self.originalValue)
                else:
                    if self._sameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                        self.autoSizedValue /= (1 - self.dataBypassFrac)
                    self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString, self.originalValue)
                    if self._sameString(self.compType, "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"):
                        self.autoSizedValue *= (1 - self.dataBypassFrac)
                        self.reportSizerOutput(state, self.compType, self.compName, "User-Specified " + self.sizingStringScalable + self.sizingString + " ( non-bypassed )", self.autoSizedValue)
                
                if hasattr(state, 'dataGlobal') and hasattr(state.dataGlobal, 'DisplayExtraWarnings') and state.dataGlobal.DisplayExtraWarnings:
                    if (abs(self.autoSizedValue - self.originalValue) / self.originalValue) > threshold:
                        msg = f"{self.callingRoutine}: Potential issue with equipment sizing for {self.compType} {self.compName}"
                        self.addErrorMessage(msg)
                        self._showMessage(state, msg)
                        msg = f"User-Specified {self.sizingStringScalable}{self.sizingString} = {self.originalValue}"
                        self.addErrorMessage(msg)
                        self._showContinueError(state, msg)
                        msg = f"differs from Design Size {self.sizingString} = {self.autoSizedValue}"
                        self.addErrorMessage(msg)
                        self._showContinueError(state, msg)
                        msg = "This may, or may not, indicate mismatched component sizes."
                        self.addErrorMessage(msg)
                        self._showContinueError(state, msg)
                        msg = "Verify that the value entered is intended and is consistent with other components."
                        self.addErrorMessage(msg)
                        self._showContinueError(state, msg)
                
                if not self.wasAutoSized:
                    self.autoSizedValue = self.originalValue
            elif self.wasAutoSized and self.autoSizedValue != -99999.0:
                self.reportSizerOutput(state, self.compType, self.compName, "Design Size " + self.sizingStringScalable + self.sizingString, self.autoSizedValue)
            else:
                msg = f"{self.callingRoutine} {self.compType} {self.compName}, Developer Error: Component sizing incomplete."
                self.addErrorMessage(msg)
                self._showSevereError(state, msg)
                msg = f"SizingString = {self.sizingString}, SizingResult = {self.originalValue:.1f}"
                self.addErrorMessage(msg)
                self._showContinueError(state, msg)
                self.errorType = AutoSizingResultType.ErrorType1
        elif not self.wasAutoSized and not self.autoCalculate:
            self.autoSizedValue = self.originalValue
        
        self.overrideSizeString = True
        if self.errorType != AutoSizingResultType.NoError:
            msg = f"Developer Error: sizing of {self.sizingString} failed."
            self.addErrorMessage(msg)
            self._showSevereError(state, msg)
            msg = f"Occurs in {self.compType} {self.compName}"
            self.addErrorMessage(msg)
            self._showContinueError(state, msg)
            errors_found = True
        
        return errors_found

    def isValidCoilType(self, _compType: str) -> bool:
        return True

    def isValidFanType(self, _compType: str) -> bool:
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

    def checkInitialized(self, state, errors_found: bool) -> Tuple[bool, bool]:
        if not self.initialized:
            errors_found = True
            self.errorType = AutoSizingResultType.ErrorType2
            self.autoSizedValue = 0.0
            msg = f"Developer Error: uninitialized sizing of {self.sizingString}."
            self.addErrorMessage(msg)
            self._showSevereError(state, msg)
            msg = f"Occurs in {self.compType} {self.compName}"
            self.addErrorMessage(msg)
            self._showContinueError(state, msg)
            return False, errors_found
        return True, errors_found

    def overrideSizingString(self, string: str) -> None:
        words = string.split('_')
        result_parts = []
        for word in words:
            if word in ("for", "per", "at"):
                result_parts.append(word)
            elif word == "ua":
                result_parts.append(word.upper())
            else:
                result_parts.append(word[0].upper() + word[1:] if len(word) > 0 else "")
        
        result = " ".join(result_parts)
        if len(result) != len(string):
            self.sizingString = result
        else:
            self.sizingString = result
        self.overrideSizeString = False

    @staticmethod
    def setOAFracForZoneEqSizing(state, desMassFlow: float, zoneEqSizing) -> float:
        outAirFrac = 0.0
        if desMassFlow <= 0.0:
            return outAirFrac
        
        StdRhoAir = state.dataEnvrn.StdRhoAir if hasattr(state, 'dataEnvrn') else 1.225
        
        if hasattr(zoneEqSizing, 'ATMixerVolFlow') and zoneEqSizing.ATMixerVolFlow > 0.0:
            outAirFrac = min(StdRhoAir * zoneEqSizing.ATMixerVolFlow / desMassFlow, 1.0)
        elif hasattr(zoneEqSizing, 'OAVolFlow') and zoneEqSizing.OAVolFlow > 0.0:
            outAirFrac = min(StdRhoAir * zoneEqSizing.OAVolFlow / desMassFlow, 1.0)
        
        return outAirFrac

    @staticmethod
    def setHeatCoilInletTempForZoneEqSizing(outAirFrac: float, zoneEqSizing, finalZoneSizing) -> float:
        coilInTemp = 0.0
        if hasattr(zoneEqSizing, 'ATMixerVolFlow') and zoneEqSizing.ATMixerVolFlow > 0.0:
            coilInTemp = (1.0 - outAirFrac) * finalZoneSizing.ZoneRetTempAtHeatPeak + outAirFrac * zoneEqSizing.ATMixerHeatPriDryBulb
        elif hasattr(zoneEqSizing, 'OAVolFlow') and zoneEqSizing.OAVolFlow > 0.0:
            coilInTemp = (1.0 - outAirFrac) * finalZoneSizing.ZoneTempAtHeatPeak + outAirFrac * finalZoneSizing.OutTempAtHeatPeak
        else:
            coilInTemp = finalZoneSizing.ZoneTempAtHeatPeak
        return coilInTemp

    @staticmethod
    def setHeatCoilInletHumRatForZoneEqSizing(outAirFrac: float, zoneEqSizing, finalZoneSizing) -> float:
        coilInHumRat = 0.0
        if hasattr(zoneEqSizing, 'ATMixerVolFlow') and zoneEqSizing.ATMixerVolFlow > 0.0:
            coilInHumRat = (1.0 - outAirFrac) * finalZoneSizing.ZoneHumRatAtHeatPeak + outAirFrac * zoneEqSizing.ATMixerHeatPriHumRat
        elif hasattr(zoneEqSizing, 'OAVolFlow') and zoneEqSizing.OAVolFlow > 0.0:
            coilInHumRat = (1.0 - outAirFrac) * finalZoneSizing.ZoneHumRatAtHeatPeak + outAirFrac * finalZoneSizing.OutHumRatAtHeatPeak
        else:
            coilInHumRat = finalZoneSizing.ZoneHumRatAtHeatPeak
        return coilInHumRat

    @staticmethod
    def setCoolCoilInletTempForZoneEqSizing(outAirFrac: float, zoneEqSizing, finalZoneSizing) -> float:
        coilInTemp = 0.0
        if hasattr(zoneEqSizing, 'ATMixerVolFlow') and zoneEqSizing.ATMixerVolFlow > 0.0:
            coilInTemp = (1.0 - outAirFrac) * finalZoneSizing.ZoneRetTempAtCoolPeak + outAirFrac * zoneEqSizing.ATMixerCoolPriDryBulb
        elif hasattr(zoneEqSizing, 'OAVolFlow') and zoneEqSizing.OAVolFlow > 0.0:
            coilInTemp = (1.0 - outAirFrac) * finalZoneSizing.ZoneTempAtCoolPeak + outAirFrac * finalZoneSizing.OutTempAtCoolPeak
        else:
            coilInTemp = finalZoneSizing.ZoneTempAtCoolPeak
        return coilInTemp

    @staticmethod
    def setCoolCoilInletHumRatForZoneEqSizing(outAirFrac: float, zoneEqSizing, finalZoneSizing) -> float:
        coilInHumRat = 0.0
        if hasattr(zoneEqSizing, 'ATMixerVolFlow') and zoneEqSizing.ATMixerVolFlow > 0.0:
            coilInHumRat = (1.0 - outAirFrac) * finalZoneSizing.ZoneHumRatAtCoolPeak + outAirFrac * zoneEqSizing.ATMixerCoolPriHumRat
        elif hasattr(zoneEqSizing, 'OAVolFlow') and zoneEqSizing.OAVolFlow > 0.0:
            coilInHumRat = (1.0 - outAirFrac) * finalZoneSizing.ZoneHumRatAtCoolPeak + outAirFrac * finalZoneSizing.OutHumRatAtCoolPeak
        else:
            coilInHumRat = finalZoneSizing.ZoneHumRatAtCoolPeak
        return coilInHumRat

    @staticmethod
    def calcCoilWaterFlowRates(state, compName: str, compType: str, peakWaterFlow: float, loopNum: int, 
                               curZoneEqNum: int, curSysNum: int, curOASysNum: int, 
                               finalZoneSizing, finalSysSizing) -> None:
        peakAirFlow = 0.0
        timeStepInDay = 24 * (state.dataGlobal.TimeStepsInHour if hasattr(state, 'dataGlobal') else 1)
        
        NumPlantLoops = state.dataHVACGlobal.NumPlantLoops if hasattr(state, 'dataHVACGlobal') else 0
        if loopNum <= 0 or loopNum > NumPlantLoops or (curZoneEqNum <= 0 and curSysNum <= 0 and curOASysNum <= 0):
            return
        
        heatingLoop = False
        if len(finalZoneSizing) == 0 and len(finalSysSizing) == 0:
            return
        
        if hasattr(state, 'dataSize') and hasattr(state.dataSize, 'PlantSizData'):
            PlantSizData = state.dataSize.PlantSizData
            if len(PlantSizData) > 0:
                for psd in PlantSizData:
                    if hasattr(psd, 'PlantLoopName') and hasattr(psd, 'LoopType'):
                        if hasattr(state, 'dataPlnt') and hasattr(state.dataPlnt, 'PlantLoop'):
                            if loopNum <= len(state.dataPlnt.PlantLoop):
                                if state.dataPlnt.PlantLoop[loopNum - 1].Name == psd.PlantLoopName:
                                    heatingLoop = psd.LoopType == 1
                                    break
        
        peakAirFlow = 0.0
        if curZoneEqNum > 0 and len(finalZoneSizing) >= curZoneEqNum:
            fzs = finalZoneSizing[curZoneEqNum - 1]
            if heatingLoop and hasattr(fzs, 'HeatFlowSeq'):
                for flow in fzs.HeatFlowSeq:
                    if flow > peakAirFlow:
                        peakAirFlow = flow
            elif hasattr(fzs, 'CoolFlowSeq'):
                for flow in fzs.CoolFlowSeq:
                    if flow > peakAirFlow:
                        peakAirFlow = flow
            
            if peakAirFlow == 0.0:
                peakAirFlow = 1.0
        elif curSysNum > 0 and len(finalSysSizing) >= curSysNum:
            fss = finalSysSizing[curSysNum - 1]
            if heatingLoop and hasattr(fss, 'HeatFlowSeq'):
                for flow in fss.HeatFlowSeq:
                    if flow > peakAirFlow:
                        peakAirFlow = flow
            elif hasattr(fss, 'CoolFlowSeq'):
                for flow in fss.CoolFlowSeq:
                    if flow > peakAirFlow:
                        peakAirFlow = flow
            
            if peakAirFlow == 0.0:
                peakAirFlow = 1.0

    def clearState(self) -> None:
        self.stdRhoAir = 0.0
        self.zoneAirFlowSizMethod = 0
        self.dataScalableSizingON = False
        self.dataScalableCapSizingON = False
        self.isCoilReportObject = False
        self.isFanReportObject = False
        self.initialized = False
        self.errorType = AutoSizingResultType.NoError
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
        self.coilType = None
        self.compType = ""
        self.compName = ""
        self.isEpJSON = False
        self.sysSizingRunDone = False
        self.zoneSizingRunDone = False
        self.curSysNum = 0
        self.curOASysNum = 0
        self.curZoneEqNum = 0
        self.curDuctType = None
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
        self.getLastErrorMessages()
        self.minOA = None
        self.dataEMSOverrideON = False
        self.dataEMSOverride = 0.0
        self.dataAutosizable = False
        self.dataConstantUsedForSizing = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.dataDXCoolsLowSpeedsAutozize = False
        self.dataPltSizHeatNum = 0
        self.dataWaterLoopNum = 0
        self.dataFanIndex = -1
        self.dataFanType = None
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
        self.dataFanPlacement = None
        self.dataDesicRegCoil = False
        self.dataHeatSizeRatio = 0.0
        self.dataZoneUsedForSizing = 0
        self.dataDesicDehumNum = 0
        self.dataNomCapInpMeth = False
        self.dataCoilNum = 0
        self.dataFanOp = None
        self.dataDesignCoilCapacity = 0.0
        self.dataErrorsFound = False
        self.dataBypassFrac = 0.0
        self.dataIsDXCoil = False
        self.dataNonZoneNonAirloopValue = 0.0
        self.printWarningFlag = False
        self.callingRoutine = ""
        self.sysSizingInputData = []
        self.zoneSizingInput = []
        self.unitarySysEqSizing = []
        self.oaSysEqSizing = []
        self.zoneEqSizing = []
        self.outsideAirSys = []
        self.termUnitSizing = []
        self.termUnitFinalZoneSizing = []
        self.finalZoneSizing = []
        self.finalSysSizing = []
        self.plantSizData = []
        self.primaryAirSystem = []
        self.airloopDOAS = []

    def _getReportIndex(self, state, compName: str) -> int:
        return -1

    def _psyRhoAirFnPbTdbW(self, state, pb: float, tdb: float, w: float) -> float:
        return 1.225

    @staticmethod
    def _sameString(s1: str, s2: str) -> bool:
        return s1.upper() == s2.upper()

    @staticmethod
    def _showSevereError(state, msg: str) -> None:
        pass

    @staticmethod
    def _showFatalError(state, msg: str) -> None:
        raise RuntimeError(msg)

    @staticmethod
    def _showContinueError(state, msg: str) -> None:
        pass

    @staticmethod
    def _showMessage(state, msg: str) -> None:
        pass
