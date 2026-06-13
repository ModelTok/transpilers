from EnergyPlus.Autosizing.BaseSizerWithScalableInputs import BaseSizerWithScalableInputs
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import HVAC
from EnergyPlus.OutputReportPredefined import OutputReportPredefined
from EnergyPlus.UtilityRoutines import Util
from EnergyPlus.ReportCoilSelection import ReportCoilSelection
from EnergyPlus.DataSizing import DataSizing
alias Real64 = Float64
struct HeatingAirFlowSizer(BaseSizerWithScalableInputs):
    def __init__(inout self):
        self.sizingType = AutoSizingType.HeatingAirFlowSizing
        self.sizingString = "Heating Supply Air Flow Rate [m3/s]"
    def size(inout self, state: EnergyPlusData, _originalValue: Real64, inout errorsFound: Bool) -> Real64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.dataEMSOverrideON:
            self.autoSizedValue = self.dataEMSOverride
        elif self.dataConstantUsedForSizing > 0 and self.dataFractionUsedForSizing > 0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = _originalValue
                elif self.zoneEqSizing(self.curZoneEqNum).DesignSizeFromParent:
                    self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).AirVolFlow
                else:
                    match self.zoneEqSizing(self.curZoneEqNum).SizingMethod(HVAC.HeatingAirflowSizing):
                        case DataSizing.SupplyAirFlowRate | DataSizing.None | DataSizing.FlowPerFloorArea:
                            if self.zoneEqSizing(self.curZoneEqNum).SystemAirFlow:
                                self.autoSizedValue = max(
                                    self.zoneEqSizing(self.curZoneEqNum).AirVolFlow,
                                    self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                    self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                )
                            else:
                                if state.dataSize.ZoneCoolingOnlyFan:
                                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                                elif state.dataSize.ZoneHeatingOnlyFan:
                                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                    self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = max(
                                        self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                        self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                    )
                                else:
                                    self.autoSizedValue = max(
                                        self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                        self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                    )
                        case DataSizing.FractionOfAutosizedCoolingAirflow:
                            if state.dataSize.ZoneCoolingOnlyFan:
                                self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                            elif state.dataSize.ZoneHeatingOnlyFan:
                                self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = max(
                                    self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                    self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                )
                            else:
                                self.autoSizedValue = max(
                                    self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                    self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                )
                        case DataSizing.FractionOfAutosizedHeatingAirflow:
                            if state.dataSize.ZoneCoolingOnlyFan:
                                self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                            elif state.dataSize.ZoneHeatingOnlyFan:
                                self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = max(
                                    self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                    self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                )
                            else:
                                self.autoSizedValue = max(
                                    self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                    self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                )
                        case DataSizing.FlowPerCoolingCapacity:
                            if state.dataSize.ZoneCoolingOnlyFan:
                                self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            elif state.dataSize.ZoneHeatingOnlyFan:
                                self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = max(
                                    self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                    self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                )
                            else:
                                self.autoSizedValue = max(
                                    self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                    self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                )
                        case DataSizing.FlowPerHeatingCapacity:
                            if state.dataSize.ZoneCoolingOnlyFan:
                                self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            elif state.dataSize.ZoneHeatingOnlyFan:
                                self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = max(
                                    self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                    self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                )
                            else:
                                self.autoSizedValue = max(
                                    self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                    self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                )
                        case _:
                            if self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            elif state.dataSize.ZoneCoolingOnlyFan:  # probably shouldn't be here
                                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                            elif self.termUnitIU and (self.curTermUnitSizingNum > 0):
                                self.autoSizedValue = self.termUnitSizing(self.curTermUnitSizingNum).AirVolFlow
                            elif self.zoneEqFanCoil:
                                self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).AirVolFlow
                            elif self.zoneHeatingOnlyFan:
                                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            else:
                                self.autoSizedValue = max(
                                    self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                    self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                )
            elif self.curSysNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                    self.autoSizedValue = _originalValue
                else:
                    if self.curOASysNum > 0:
                        if self.oaSysEqSizing(self.curOASysNum).AirFlow:
                            self.autoSizedValue = self.oaSysEqSizing(self.curOASysNum).AirVolFlow
                        elif self.oaSysEqSizing(self.curOASysNum).HeatingAirFlow:
                            self.autoSizedValue = self.oaSysEqSizing(self.curOASysNum).HeatingAirVolFlow
                        elif outsideAirSys(self.curOASysNum).AirLoopDOASNum > -1:
                            self.autoSizedValue = self.airloopDOAS[outsideAirSys(self.curOASysNum).AirLoopDOASNum].SizingMassFlow / state.dataEnvrn.StdRhoAir
                        else:
                            self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesOutAirVolFlow
                    else:
                        if self.unitarySysEqSizing(self.curSysNum).AirFlow:
                            self.autoSizedValue = self.unitarySysEqSizing(self.curSysNum).AirVolFlow
                        elif self.unitarySysEqSizing(self.curSysNum).HeatingAirFlow:
                            self.autoSizedValue = self.unitarySysEqSizing(self.curSysNum).HeatingAirVolFlow
                        else:
                            if self.curDuctType == HVAC.AirDuctType.Main:
                                if Util.SameString(self.compType, "COIL:HEATING:WATER"):
                                    if self.finalSysSizing(self.curSysNum).SysAirMinFlowRat > 0.0 and not self.dataDesicRegCoil:
                                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).SysAirMinFlowRat * self.finalSysSizing(self.curSysNum).DesMainVolFlow
                                    else:
                                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesMainVolFlow
                                else:
                                    self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesMainVolFlow
                            elif self.curDuctType == HVAC.AirDuctType.Cooling:
                                if Util.SameString(self.compType, "COIL:HEATING:WATER"):
                                    if self.finalSysSizing(self.curSysNum).SysAirMinFlowRat > 0.0 and not self.dataDesicRegCoil:
                                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).SysAirMinFlowRat * self.finalSysSizing(self.curSysNum).DesCoolVolFlow
                                    else:
                                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesCoolVolFlow
                                else:
                                    self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesCoolVolFlow
                            elif self.curDuctType == HVAC.AirDuctType.Heating:
                                self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesHeatVolFlow
                            elif self.curDuctType == HVAC.AirDuctType.Other:
                                self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesMainVolFlow
                            else:
                                self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesMainVolFlow
            elif self.dataNonZoneNonAirloopValue > 0:
                self.autoSizedValue = self.dataNonZoneNonAirloopValue
            elif not self.wasAutoSized:
                self.autoSizedValue = self.originalValue
            else:
                var msg: String = self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                ShowSevereError(state, msg)
                self.addErrorMessage(msg)
                msg = String.format("SizingString = {}, SizingResult = {:.1f}", self.sizingString, self.autoSizedValue)
                ShowContinueError(state, msg)
                self.addErrorMessage(msg)
                errorsFound = True
            if self.overrideSizeString:
                self.sizingString = "Heating Supply Air Flow Rate [m3/s]"
            if self.dataScalableSizingON:
                if self.zoneAirFlowSizMethod == DataSizing.SupplyAirFlowRate or self.zoneAirFlowSizMethod == DataSizing.None:
                    self.sizingStringScalable = "(scaled by flow / zone) "
                elif self.zoneAirFlowSizMethod == DataSizing.FlowPerFloorArea:
                    self.sizingStringScalable = "(scaled by flow / area) "
                elif self.zoneAirFlowSizMethod == DataSizing.FractionOfAutosizedCoolingAirflow or self.zoneAirFlowSizMethod == DataSizing.FractionOfAutosizedHeatingAirflow:
                    self.sizingStringScalable = "(scaled by fractional multiplier) "
                elif self.zoneAirFlowSizMethod == DataSizing.FlowPerCoolingCapacity or self.zoneAirFlowSizMethod == DataSizing.FlowPerHeatingCapacity:
                    self.sizingStringScalable = "(scaled by flow / capacity) "
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilAirFlow(state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized)
        if self.isFanReportObject:
            var DDNameFanPeak: String
            var dateTimeFanPeak: String
            if self.dataScalableSizingON:
                DDNameFanPeak = "Scaled size, not from any peak"
                dateTimeFanPeak = "Scaled size, not from any peak"
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanDesDay, self.compName, DDNameFanPeak)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanPkTime, self.compName, dateTimeFanPeak)
        return self.autoSizedValue
    def clearState(inout self):
        BaseSizerWithScalableInputs.clearState(self)