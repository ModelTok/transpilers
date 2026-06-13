from BaseSizerWithScalableInputs import BaseSizerWithScalableInputs
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataEnvironment import DataEnvironment
from ...DataHVACGlobals import HVAC, CoolingAirflowSizing, AirDuctType
from ...DataSizing import DataSizing
from ...General import ShowSevereError, ShowContinueError
from ...OutputReportPredefined import PreDefTableEntry
from ...UtilityRoutines import SameString
from ...WeatherManager import WeatherManager
from ...ReportCoilSelection import ReportCoilSelection
module EnergyPlus:
    struct CoolingAirFlowSizer(BaseSizerWithScalableInputs):
        def __init__(inout self):
            self.sizingType = AutoSizingType.CoolingAirFlowSizing
            self.sizingString = "Cooling Supply Air Flow Rate [m3/s]"
        def __del__(inout self):

        def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
            if not self.checkInitialized(state, errorsFound):
                return 0.0
            self.preSize(state, originalValue)
            var coolingFlow: Bool = False
            var heatingFlow: Bool = False
            if self.dataEMSOverrideON:
                self.autoSizedValue = self.dataEMSOverride
            elif self.dataConstantUsedForSizing > 0 and self.dataFractionUsedForSizing > 0:
                self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
            else:
                if self.curZoneEqNum > 0:
                    if not self.wasAutoSized and not self.sizingDesRunThisZone:
                        self.autoSizedValue = originalValue
                        if SameString(self.compType, "Coil:Cooling:DX:TwoStageWithHumidityControlMode"):
                            self.autoSizedValue /= (1.0 - self.dataBypassFrac) # back out bypass fraction applied in GetInput
                            self.originalValue /= (1.0 - self.dataBypassFrac)  # back out bypass fraction applied in GetInput
                    elif self.zoneEqSizing(self.curZoneEqNum).DesignSizeFromParent:
                        self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).AirVolFlow
                    else:
                        match self.zoneEqSizing(self.curZoneEqNum).SizingMethod(HVAC.CoolingAirflowSizing):
                            case DataSizing.SupplyAirFlowRate | DataSizing.None | DataSizing.FlowPerFloorArea:
                                if self.zoneEqSizing(self.curZoneEqNum).SystemAirFlow:
                                    self.autoSizedValue = max(
                                        self.zoneEqSizing(self.curZoneEqNum).AirVolFlow,
                                        self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                        self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                    )
                                    coolingFlow = True
                                else:
                                    if state.dataSize.ZoneCoolingOnlyFan:
                                        self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                                        coolingFlow = True
                                    elif state.dataSize.ZoneHeatingOnlyFan:
                                        self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                        heatingFlow = True
                                    elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                        self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                                        coolingFlow = True
                                    elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                        self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                        heatingFlow = True
                                    elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                        self.autoSizedValue = max(
                                            self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                            self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                        )
                                        if self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                            coolingFlow = True
                                        elif self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                            heatingFlow = True
                                    else:
                                        self.autoSizedValue = max(
                                            self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                            self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                        )
                                        if self.autoSizedValue == self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                            coolingFlow = True
                                        elif self.autoSizedValue == self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                            heatingFlow = True
                            case DataSizing.FractionOfAutosizedCoolingAirflow:
                                if state.dataSize.ZoneCoolingOnlyFan:
                                    self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                                    coolingFlow = True
                                elif state.dataSize.ZoneHeatingOnlyFan:
                                    self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                    heatingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                    self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                                    coolingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                    heatingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = max(
                                        self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                        self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                    )
                                    if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                        coolingFlow = True
                                    elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                        heatingFlow = True
                                else:
                                    self.autoSizedValue = max(
                                        self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                        self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                    )
                                    if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                        coolingFlow = True
                                    elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                        heatingFlow = True
                            case DataSizing.FractionOfAutosizedHeatingAirflow:
                                if state.dataSize.ZoneCoolingOnlyFan:
                                    self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                                    coolingFlow = True
                                elif state.dataSize.ZoneHeatingOnlyFan:
                                    self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                    heatingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                    self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                                    coolingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                    heatingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = max(
                                        self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                        self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                    )
                                    if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                        coolingFlow = True
                                    elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                        heatingFlow = True
                                else:
                                    self.autoSizedValue = max(
                                        self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                        self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                    )
                                    if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                        coolingFlow = True
                                    elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                        heatingFlow = True
                            case DataSizing.FlowPerCoolingCapacity:
                                if state.dataSize.ZoneCoolingOnlyFan:
                                    self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                                    coolingFlow = True
                                elif state.dataSize.ZoneHeatingOnlyFan:
                                    self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                    heatingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                    self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                                    coolingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                    heatingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = max(
                                        self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                        self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                    )
                                    if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                        coolingFlow = True
                                    elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                        heatingFlow = True
                                else:
                                    self.autoSizedValue = max(
                                        self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                        self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                    )
                                    if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                        coolingFlow = True
                                    elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                        heatingFlow = True
                            case DataSizing.FlowPerHeatingCapacity:
                                if state.dataSize.ZoneCoolingOnlyFan:
                                    self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                                    coolingFlow = True
                                elif state.dataSize.ZoneHeatingOnlyFan:
                                    self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                    heatingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                    self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                                    coolingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                    heatingFlow = True
                                elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = max(
                                        self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                        self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                    )
                                    if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                        coolingFlow = True
                                    elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                        heatingFlow = True
                                else:
                                    self.autoSizedValue = max(
                                        self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                        self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                                    )
                                    if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                        coolingFlow = True
                                    elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                        heatingFlow = True
                            case _:
                                if self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                    self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                                elif state.dataSize.ZoneCoolingOnlyFan:
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
                        self.autoSizedValue = originalValue
                        if SameString(self.compType, "Coil:Cooling:DX:TwoStageWithHumidityControlMode"):
                            self.autoSizedValue /= (1.0 - self.dataBypassFrac) # back out bypass fraction applied in GetInput
                            self.originalValue /= (1.0 - self.dataBypassFrac)  # back out bypass fraction applied in GetInput
                    else:
                        if self.curOASysNum > 0:
                            if self.oaSysEqSizing(self.curOASysNum).AirFlow:
                                self.autoSizedValue = self.oaSysEqSizing(self.curOASysNum).AirVolFlow
                            elif self.oaSysEqSizing(self.curOASysNum).CoolingAirFlow:
                                self.autoSizedValue = self.oaSysEqSizing(self.curOASysNum).CoolingAirVolFlow
                            elif outsideAirSys(self.curOASysNum).AirLoopDOASNum > -1:
                                self.autoSizedValue = self.airloopDOAS[outsideAirSys(self.curOASysNum).AirLoopDOASNum].SizingMassFlow / state.dataEnvrn.StdRhoAir
                            else:
                                self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesOutAirVolFlow
                        elif self.dataAirFlowUsedForSizing > 0.0:
                            self.autoSizedValue = self.dataAirFlowUsedForSizing
                        else:
                            if self.unitarySysEqSizing(self.curSysNum).AirFlow:
                                self.autoSizedValue = self.unitarySysEqSizing(self.curSysNum).AirVolFlow
                            elif self.unitarySysEqSizing(self.curSysNum).CoolingAirFlow:
                                self.autoSizedValue = self.unitarySysEqSizing(self.curSysNum).CoolingAirVolFlow
                            else:
                                if self.curDuctType == HVAC.AirDuctType.Main:
                                    self.autoSizedValue = self.finalSysSizing(self.curSysNum).DesMainVolFlow
                                elif self.curDuctType == HVAC.AirDuctType.Cooling:
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
                    msg = f"SizingString = {self.sizingString}, SizingResult = {self.autoSizedValue:.1f}"
                    ShowContinueError(state, msg)
                    self.addErrorMessage(msg)
                    errorsFound = True
                if self.overrideSizeString:
                    if SameString(self.compType, "ZoneHVAC:FourPipeFanCoil"):
                        self.sizingString = "Maximum Supply Air Flow Rate [m3/s]"
                    elif self.coilType == HVAC.CoilType.CoolingDXTwoSpeed:
                        if self.dataDXSpeedNum == 1: # mode 1 is high speed in DXCoils loop
                            self.sizingString = "High Speed Rated Air Flow Rate [m3/s]"
                        elif self.dataDXSpeedNum == 2:
                            self.sizingString = "Low Speed Rated Air Flow Rate [m3/s]"
                    elif self.isEpJSON:
                        self.sizingString = "Cooling Supply Air Flow Rate [m3/s]"
                if self.dataScalableSizingON:
                    if self.zoneAirFlowSizMethod == DataSizing.SupplyAirFlowRate or self.zoneAirFlowSizMethod == DataSizing.None:
                        self.sizingStringScalable = "(scaled by flow / zone) "
                    elif self.zoneAirFlowSizMethod == DataSizing.FlowPerFloorArea:
                        self.sizingStringScalable = "(scaled by flow / area) "
                    elif self.zoneAirFlowSizMethod == DataSizing.FractionOfAutosizedCoolingAirflow or self.zoneAirFlowSizMethod == DataSizing.FractionOfAutosizedHeatingAirflow:
                        self.sizingStringScalable = "(scaled by fractional multiplier) "
                    elif self.zoneAirFlowSizMethod == DataSizing.FlowPerCoolingCapacity or self.zoneAirFlowSizMethod == DataSizing.FlowPerHeatingCapacity:
                        self.sizingStringScalable = "(scaled by flow / capacity) "
            if self.dataDXCoolsLowSpeedsAutozize:
                self.autoSizedValue *= self.dataFractionUsedForSizing
            self.select2StgDXHumCtrlSizerOutput(state, errorsFound)
            if self.isCoilReportObject:
                ReportCoilSelection.setCoilAirFlow(state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized)
            if self.isFanReportObject:
                var DDNameFanPeak: String
                var dateTimeFanPeak: String
                if self.dataScalableSizingON:
                    DDNameFanPeak = "Scaled size, not from any peak"
                    dateTimeFanPeak = "Scaled size, not from any peak"
                else:
                    if coolingFlow:
                        if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                            DDNameFanPeak = state.dataWeather.DesDayInput(self.finalZoneSizing(self.curZoneEqNum).CoolDDNum).Title
                            dateTimeFanPeak = f"{state.dataWeather.DesDayInput(self.finalZoneSizing(self.curZoneEqNum).CoolDDNum).Month}/{state.dataWeather.DesDayInput(self.finalZoneSizing(self.curZoneEqNum).CoolDDNum).DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                    elif heatingFlow:
                        if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                            DDNameFanPeak = state.dataWeather.DesDayInput(self.finalZoneSizing(self.curZoneEqNum).HeatDDNum).Title
                            dateTimeFanPeak = f"{state.dataWeather.DesDayInput(self.finalZoneSizing(self.curZoneEqNum).HeatDDNum).Month}/{state.dataWeather.DesDayInput(self.finalZoneSizing(self.curZoneEqNum).HeatDDNum).DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanDesDay, self.compName, DDNameFanPeak)
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanPkTime, self.compName, dateTimeFanPeak)
            return self.autoSizedValue
        def clearState(inout self):
            BaseSizerWithScalableInputs.clearState(self)