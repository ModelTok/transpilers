from All_Simple_Sizing import (AutoCalculateSizer, MaxHeaterOutletTempSizer, ZoneCoolingLoadSizer, ZoneHeatingLoadSizer, ASHRAEMinSATCoolingSizer, ASHRAEMaxSATHeatingSizer, DesiccantDehumidifierBFPerfDataFaceVelocitySizer, HeatingCoilDesAirInletTempSizer, HeatingCoilDesAirOutletTempSizer, HeatingCoilDesAirInletHumRatSizer)
from EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DesiccantDehumidifiers import DesiccantDehumidifiers
from General import (ShowSevereError, ShowContinueError)
from Psychrometrics import PsyCpAirFnW
from ReportCoilSelection import ReportCoilSelection
alias Real64 = Float64
alias bool = Bool
struct AutoCalculateSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.dataEMSOverrideON:
            self.autoSizedValue = self.dataEMSOverride
        else:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue
struct MaxHeaterOutletTempSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).HeatDesTemp
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                self.autoSizedValue = self.finalSysSizing(self.curSysNum).HeatSupTemp
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue
struct ZoneCoolingLoadSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesCoolLoad
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                self.errorType = AutoSizingResultType.ErrorType1
                self.autoSizedValue = 0.0
                var msg: String = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", Airloop equipment not implemented."
                self.addErrorMessage(msg)
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue
struct ZoneHeatingLoadSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesHeatLoad
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                self.errorType = AutoSizingResultType.ErrorType1
                self.autoSizedValue = 0.0
                var msg: String = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", Airloop equipment not implemented."
                self.addErrorMessage(msg)
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue
struct ASHRAEMinSATCoolingSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                if self.dataCapacityUsedForSizing > 0.0 and self.dataFlowUsedForSizing > 0.0:
                    self.autoSizedValue = (
                        self.finalZoneSizing(self.curZoneEqNum).ZoneTempAtCoolPeak -
                        (self.dataCapacityUsedForSizing / (self.dataFlowUsedForSizing * state.dataEnvrn.StdRhoAir *
                            PsyCpAirFnW(self.finalZoneSizing(self.curZoneEqNum).ZoneHumRatAtCoolPeak)))
                    )
                else:
                    self.errorType = AutoSizingResultType.ErrorType1
                    var msg: String = (
                        self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                    )
                    self.addErrorMessage(msg)
                    ShowSevereError(state, msg)
                    msg = String.format("SizingString = {}, DataCapacityUsedForSizing = {:.1f}", self.sizingString, self.dataCapacityUsedForSizing)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("SizingString = {}, DataFlowUsedForSizing = {:.1f}", self.sizingString, self.dataFlowUsedForSizing)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                if self.dataCapacityUsedForSizing > 0.0 and self.dataFlowUsedForSizing > 0.0 and self.dataZoneUsedForSizing > 0:
                    self.autoSizedValue = (
                        self.finalZoneSizing(self.dataZoneUsedForSizing).ZoneTempAtCoolPeak -
                        (self.dataCapacityUsedForSizing /
                            (self.dataFlowUsedForSizing * state.dataEnvrn.StdRhoAir *
                                PsyCpAirFnW(self.finalZoneSizing(self.dataZoneUsedForSizing).ZoneHumRatAtCoolPeak)))
                    )
                else:
                    self.errorType = AutoSizingResultType.ErrorType1
                    var msg: String = (
                        self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                    )
                    self.addErrorMessage(msg)
                    ShowSevereError(state, msg)
                    msg = String.format("SizingString = {}, DataCapacityUsedForSizing = {:.1f}", self.sizingString, self.dataCapacityUsedForSizing)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("SizingString = {}, DataFlowUsedForSizing = {:.1f}", self.sizingString, self.dataFlowUsedForSizing)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("SizingString = {}, DataZoneUsedForSizing = {:.0f}", self.sizingString, Real64(self.dataZoneUsedForSizing))
                    ShowContinueError(state, msg)
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue
struct ASHRAEMaxSATHeatingSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                if self.dataCapacityUsedForSizing > 0.0 and self.dataFlowUsedForSizing > 0.0:
                    self.autoSizedValue = (
                        self.finalZoneSizing(self.curZoneEqNum).ZoneTempAtHeatPeak +
                        (self.dataCapacityUsedForSizing / (self.dataFlowUsedForSizing * state.dataEnvrn.StdRhoAir *
                            PsyCpAirFnW(self.finalZoneSizing(self.curZoneEqNum).ZoneHumRatAtHeatPeak)))
                    )
                else:
                    self.errorType = AutoSizingResultType.ErrorType1
                    var msg: String = (
                        self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                    )
                    self.addErrorMessage(msg)
                    ShowSevereError(state, msg)
                    msg = String.format("SizingString = {}, DataCapacityUsedForSizing = {:.1f}", self.sizingString, self.dataCapacityUsedForSizing)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("SizingString = {}, DataFlowUsedForSizing = {:.1f}", self.sizingString, self.dataFlowUsedForSizing)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                if self.dataCapacityUsedForSizing > 0.0 and self.dataFlowUsedForSizing > 0.0 and self.dataZoneUsedForSizing > 0:
                    self.autoSizedValue = (
                        self.finalZoneSizing(self.dataZoneUsedForSizing).ZoneTempAtHeatPeak +
                        (self.dataCapacityUsedForSizing /
                            (self.dataFlowUsedForSizing * state.dataEnvrn.StdRhoAir *
                                PsyCpAirFnW(self.finalZoneSizing(self.dataZoneUsedForSizing).ZoneHumRatAtHeatPeak)))
                    )
                else:
                    self.errorType = AutoSizingResultType.ErrorType1
                    var msg: String = (
                        self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                    )
                    self.addErrorMessage(msg)
                    ShowSevereError(state, msg)
                    msg = String.format("SizingString = {}, DataCapacityUsedForSizing = {:.1f}", self.sizingString, self.dataCapacityUsedForSizing)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("SizingString = {}, DataFlowUsedForSizing = {:.1f}", self.sizingString, self.dataFlowUsedForSizing)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("SizingString = {}, DataZoneUsedForSizing = {:.0f}", self.sizingString, Real64(self.dataZoneUsedForSizing))
                    ShowContinueError(state, msg)
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue
struct DesiccantDehumidifierBFPerfDataFaceVelocitySizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.dataEMSOverrideON:
            self.autoSizedValue = self.dataEMSOverride
        else:
            self.autoSizedValue = 4.30551 + 0.01969 * self.dataAirFlowUsedForSizing
            self.autoSizedValue = min(6.0, self.autoSizedValue)
        if self.isEpJSON:
            self.sizingString = "Nominal Air Face Velocity [m/s]"
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue
struct HeatingCoilDesAirInletTempSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                self.errorType = AutoSizingResultType.ErrorType1
                self.autoSizedValue = 0.0
                var msg: String = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", Zone equipment not implemented."
                self.addErrorMessage(msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                if self.dataDesicRegCoil and self.dataDesicDehumNum > 0:
                    if state.dataDesiccantDehumidifiers.DesicDehum[self.dataDesicDehumNum].RegenInletIsOutsideAirNode:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).HeatOutTemp
                    else:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).HeatRetTemp
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilEntAirTemp(state, self.coilReportNum, self.autoSizedValue, self.curSysNum, self.curZoneEqNum)
        return self.autoSizedValue
struct HeatingCoilDesAirOutletTempSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                self.errorType = AutoSizingResultType.ErrorType1
                self.autoSizedValue = 0.0
                var msg: String = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", Zone equipment not implemented."
                self.addErrorMessage(msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                if self.dataDesicRegCoil and self.dataDesicDehumNum > 0:
                    self.autoSizedValue = state.dataDesiccantDehumidifiers.DesicDehum[self.dataDesicDehumNum].RegenSetPointTemp
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilLvgAirTemp(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue
struct HeatingCoilDesAirInletHumRatSizer:
    def size(inout self, inout state: EnergyPlusData, _originalValue: Real64, inout errorsFound: bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                self.errorType = AutoSizingResultType.ErrorType1
                self.autoSizedValue = 0.0
                var msg: String = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", Zone equipment not implemented."
                self.addErrorMessage(msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                if self.dataDesicRegCoil:
                    if state.dataDesiccantDehumidifiers.DesicDehum[self.dataDesicDehumNum].RegenInletIsOutsideAirNode:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).HeatOutHumRat
                    else:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).HeatRetHumRat
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilEntAirHumRat(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue