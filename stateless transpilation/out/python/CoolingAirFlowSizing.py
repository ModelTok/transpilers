# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data* members (from EnergyPlus/Data/EnergyPlusData.hh)
# - BaseSizerWithScalableInputs: parent class (from EnergyPlus/Autosizing/BaseSizerWithScalableInputs.hh)
# - HVAC.CoolingAirflowSizing, HVAC.AirDuctType, HVAC.CoilType: enums (from EnergyPlus/DataHVACGlobals.hh)
# - DataSizing: enum module with SupplyAirFlowRate, None, FlowPerFloorArea, FractionOfAutosizedCoolingAirflow, etc.
# - Util.SameString: string comparison function
# - ShowSevereError, ShowContinueError: error reporting functions
# - ReportCoilSelection.setCoilAirFlow, ReportCoilSelection.getTimeText: reporting functions
# - OutputReportPredefined.PreDefTableEntry: reporting function
# - outsideAirSys: global array or indexing function

from typing import Any, Protocol

class BaseSizerWithScalableInputs:
    def checkInitialized(self, state: Any, errorsFound: list) -> bool:
        raise NotImplementedError
    
    def preSize(self, state: Any, originalValue: float) -> None:
        raise NotImplementedError
    
    def select2StgDXHumCtrlSizerOutput(self, state: Any, errorsFound: list) -> None:
        raise NotImplementedError
    
    def clearState(self) -> None:
        raise NotImplementedError
    
    def addErrorMessage(self, msg: str) -> None:
        raise NotImplementedError

class CoolingAirFlowSizer(BaseSizerWithScalableInputs):
    def __init__(self):
        self.sizingType = None
        self.sizingString = "Cooling Supply Air Flow Rate [m3/s]"
        self.dataEMSOverrideON = False
        self.dataEMSOverride = 0.0
        self.dataConstantUsedForSizing = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.autoSizedValue = 0.0
        self.originalValue = 0.0
        self.curZoneEqNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.compType = ""
        self.dataBypassFrac = 0.0
        self.curSysNum = 0
        self.sizingDesRunThisAirSys = False
        self.curOASysNum = 0
        self.dataAirFlowUsedForSizing = 0.0
        self.curDuctType = None
        self.dataNonZoneNonAirloopValue = 0.0
        self.callingRoutine = ""
        self.compName = ""
        self.overrideSizeString = False
        self.coilType = None
        self.dataDXSpeedNum = 0
        self.isEpJSON = False
        self.dataScalableSizingON = False
        self.zoneAirFlowSizMethod = None
        self.sizingStringScalable = ""
        self.dataDXCoolsLowSpeedsAutozize = False
        self.isCoilReportObject = False
        self.coilReportNum = 0
        self.isFanReportObject = False
        self.termUnitIU = False
        self.curTermUnitSizingNum = 0
        self.zoneEqFanCoil = False
        self.zoneHeatingOnlyFan = False
        self.dataFracOfAutosizedCoolingAirflow = 0.0
        self.dataFracOfAutosizedHeatingAirflow = 0.0
        self.dataFlowPerCoolingCapacity = 0.0
        self.dataFlowPerHeatingCapacity = 0.0
        self.dataAutosizedCoolingCapacity = 0.0
        self.dataAutosizedHeatingCapacity = 0.0
        self.airloopDOAS = []
    
    def size(self, state: Any, original_value: float, errors_found: list) -> float:
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        cooling_flow = False
        heating_flow = False
        
        if self.dataEMSOverrideON:
            self.autoSizedValue = self.dataEMSOverride
        elif self.dataConstantUsedForSizing > 0 and self.dataFractionUsedForSizing > 0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = original_value
                    if Util.SameString(self.compType, "Coil:Cooling:DX:TwoStageWithHumidityControlMode"):
                        self.autoSizedValue /= (1.0 - self.dataBypassFrac)
                        self.originalValue /= (1.0 - self.dataBypassFrac)
                elif self.zoneEqSizing(self.curZoneEqNum).DesignSizeFromParent:
                    self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).AirVolFlow
                else:
                    sizing_method = self.zoneEqSizing(self.curZoneEqNum).SizingMethod(HVAC.CoolingAirflowSizing)
                    
                    if sizing_method in [DataSizing.SupplyAirFlowRate, DataSizing.None, DataSizing.FlowPerFloorArea]:
                        if self.zoneEqSizing(self.curZoneEqNum).SystemAirFlow:
                            self.autoSizedValue = max(
                                self.zoneEqSizing(self.curZoneEqNum).AirVolFlow,
                                self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            )
                            cooling_flow = True
                        else:
                            if state.dataSize.ZoneCoolingOnlyFan:
                                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                                cooling_flow = True
                            elif state.dataSize.ZoneHeatingOnlyFan:
                                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                heating_flow = True
                            elif (self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and 
                                  not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow):
                                self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                                cooling_flow = True
                            elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                                  not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                                self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                heating_flow = True
                            elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                                  self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                                self.autoSizedValue = max(
                                    self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                    self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                )
                                if self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                    cooling_flow = True
                                elif self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                    heating_flow = True
                            else:
                                self.autoSizedValue = max(
                                    self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                    self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                )
                                if self.autoSizedValue == self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                    cooling_flow = True
                                elif self.autoSizedValue == self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                    heating_flow = True
                    
                    elif sizing_method == DataSizing.FractionOfAutosizedCoolingAirflow:
                        if state.dataSize.ZoneCoolingOnlyFan:
                            self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                            cooling_flow = True
                        elif state.dataSize.ZoneHeatingOnlyFan:
                            self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            heating_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and 
                              not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow):
                            self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                            cooling_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                              not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                            self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            heating_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                              self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                            self.autoSizedValue = max(
                                self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            )
                            if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                cooling_flow = True
                            elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                heating_flow = True
                        else:
                            self.autoSizedValue = max(
                                self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            )
                            if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                cooling_flow = True
                            elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                heating_flow = True
                    
                    elif sizing_method == DataSizing.FractionOfAutosizedHeatingAirflow:
                        if state.dataSize.ZoneCoolingOnlyFan:
                            self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                            cooling_flow = True
                        elif state.dataSize.ZoneHeatingOnlyFan:
                            self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            heating_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and 
                              not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow):
                            self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                            cooling_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                              not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                            self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            heating_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                              self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                            self.autoSizedValue = max(
                                self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            )
                            if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                cooling_flow = True
                            elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                heating_flow = True
                        else:
                            self.autoSizedValue = max(
                                self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            )
                            if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                cooling_flow = True
                            elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                heating_flow = True
                    
                    elif sizing_method == DataSizing.FlowPerCoolingCapacity:
                        if state.dataSize.ZoneCoolingOnlyFan:
                            self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            cooling_flow = True
                        elif state.dataSize.ZoneHeatingOnlyFan:
                            self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            heating_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and 
                              not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow):
                            self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            cooling_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                              not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                            self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            heating_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                              self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                            self.autoSizedValue = max(
                                self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            )
                            if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                cooling_flow = True
                            elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                heating_flow = True
                        else:
                            self.autoSizedValue = max(
                                self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            )
                            if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                cooling_flow = True
                            elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                heating_flow = True
                    
                    elif sizing_method == DataSizing.FlowPerHeatingCapacity:
                        if state.dataSize.ZoneCoolingOnlyFan:
                            self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            cooling_flow = True
                        elif state.dataSize.ZoneHeatingOnlyFan:
                            self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            heating_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and 
                              not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow):
                            self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            cooling_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                              not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                            self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            heating_flow = True
                        elif (self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and 
                              self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow):
                            self.autoSizedValue = max(
                                self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            )
                            if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                cooling_flow = True
                            elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                heating_flow = True
                        else:
                            self.autoSizedValue = max(
                                self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            )
                            if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                cooling_flow = True
                            elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                heating_flow = True
                    
                    else:
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
                    self.autoSizedValue = original_value
                    if Util.SameString(self.compType, "Coil:Cooling:DX:TwoStageWithHumidityControlMode"):
                        self.autoSizedValue /= (1.0 - self.dataBypassFrac)
                        self.originalValue /= (1.0 - self.dataBypassFrac)
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
                msg = self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                ShowSevereError(state, msg)
                self.addErrorMessage(msg)
                msg = f"SizingString = {self.sizingString}, SizingResult = {self.autoSizedValue:.1f}"
                ShowContinueError(state, msg)
                self.addErrorMessage(msg)
                errors_found[0] = True
        
        if self.overrideSizeString:
            if Util.SameString(self.compType, "ZoneHVAC:FourPipeFanCoil"):
                self.sizingString = "Maximum Supply Air Flow Rate [m3/s]"
            elif self.coilType == HVAC.CoilType.CoolingDXTwoSpeed:
                if self.dataDXSpeedNum == 1:
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
            elif (self.zoneAirFlowSizMethod == DataSizing.FractionOfAutosizedCoolingAirflow or
                  self.zoneAirFlowSizMethod == DataSizing.FractionOfAutosizedHeatingAirflow):
                self.sizingStringScalable = "(scaled by fractional multiplier) "
            elif (self.zoneAirFlowSizMethod == DataSizing.FlowPerCoolingCapacity or
                  self.zoneAirFlowSizMethod == DataSizing.FlowPerHeatingCapacity):
                self.sizingStringScalable = "(scaled by flow / capacity) "
        
        if self.dataDXCoolsLowSpeedsAutozize:
            self.autoSizedValue *= self.dataFractionUsedForSizing
        
        self.select2StgDXHumCtrlSizerOutput(state, errors_found)
        
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilAirFlow(state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized)
        
        if self.isFanReportObject:
            dd_name_fan_peak = ""
            date_time_fan_peak = ""
            
            if self.dataScalableSizingON:
                dd_name_fan_peak = "Scaled size, not from any peak"
                date_time_fan_peak = "Scaled size, not from any peak"
            else:
                if cooling_flow:
                    if (self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and
                        self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays):
                        cool_dd_num = self.finalZoneSizing(self.curZoneEqNum).CoolDDNum
                        dd_name_fan_peak = state.dataWeather.DesDayInput(cool_dd_num).Title
                        date_time_fan_peak = (
                            f"{state.dataWeather.DesDayInput(cool_dd_num).Month}/"
                            f"{state.dataWeather.DesDayInput(cool_dd_num).DayOfMonth} "
                            f"{ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        )
                elif heating_flow:
                    if (self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and
                        self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays):
                        heat_dd_num = self.finalZoneSizing(self.curZoneEqNum).HeatDDNum
                        dd_name_fan_peak = state.dataWeather.DesDayInput(heat_dd_num).Title
                        date_time_fan_peak = (
                            f"{state.dataWeather.DesDayInput(heat_dd_num).Month}/"
                            f"{state.dataWeather.DesDayInput(heat_dd_num).DayOfMonth} "
                            f"{ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        )
            
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanDesDay, self.compName, dd_name_fan_peak)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanPkTime, self.compName, date_time_fan_peak)
        
        return self.autoSizedValue
    
    def clearState(self):
        super().clearState()

    def zoneEqSizing(self, index: int) -> Any:
        raise NotImplementedError
    
    def finalZoneSizing(self, index: int) -> Any:
        raise NotImplementedError
    
    def oaSysEqSizing(self, index: int) -> Any:
        raise NotImplementedError
    
    def termUnitSizing(self, index: int) -> Any:
        raise NotImplementedError
    
    def unitarySysEqSizing(self, index: int) -> Any:
        raise NotImplementedError
    
    def finalSysSizing(self, index: int) -> Any:
        raise NotImplementedError

class Util:
    @staticmethod
    def SameString(a: str, b: str) -> bool:
        raise NotImplementedError

class HVAC:
    class AirDuctType:
        Main = 0
        Cooling = 1
        Heating = 2
        Other = 3
    
    class CoilType:
        CoolingDXTwoSpeed = 0
    
    CoolingAirflowSizing = 0

class DataSizing:
    SupplyAirFlowRate = 0
    None = 1
    FlowPerFloorArea = 2
    FractionOfAutosizedCoolingAirflow = 3
    FractionOfAutosizedHeatingAirflow = 4
    FlowPerCoolingCapacity = 5
    FlowPerHeatingCapacity = 6

class ReportCoilSelection:
    @staticmethod
    def setCoilAirFlow(state: Any, num: int, flow: float, was_autosized: bool) -> None:
        raise NotImplementedError
    
    @staticmethod
    def getTimeText(state: Any, step_num: int) -> str:
        raise NotImplementedError

class OutputReportPredefined:
    @staticmethod
    def PreDefTableEntry(state: Any, entry_type: Any, name: str, value: str) -> None:
        raise NotImplementedError

def ShowSevereError(state: Any, msg: str) -> None:
    raise NotImplementedError

def ShowContinueError(state: Any, msg: str) -> None:
    raise NotImplementedError

def outsideAirSys(index: int) -> Any:
    raise NotImplementedError
