# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: base class from EnergyPlus.Autosizing.Base
# - EnergyPlusData: state object with dataEnvrn, dataPlnt, etc.
# - Psychrometrics.PsyCpAirFnW(humidity_ratio: float) -> float
# - HVAC.SmallLoad: constant float threshold
# - Constant.HWInitConvTemp: float constant
# - ReportCoilSelection module with:
#   - setCoilWaterFlowPltSizNum(state, coilReportNum, value, wasAutoSized, dataPltSizHeatNum, dataWaterLoopNum)
#   - setCoilEntWaterTemp(state, coilReportNum, temp)
#   - setCoilWaterDeltaT(state, coilReportNum, deltaT)
#   - setCoilLvgWaterTemp(state, coilReportNum, temp)
# - ShowSevereError(state, message)
# - AutoSizingType enum with HeatingWaterflowSizing member
# - AutoSizingResultType enum with ErrorType1 member


class HeatingWaterflowSizer(BaseSizer):
    
    def __init__(self):
        super().__init__()
        self.sizingType = AutoSizingType.HeatingWaterflowSizing
        self.sizingString = "Maximum Water Flow Rate [m3/s]"
    
    def size(self, state, originalValue, errorsFound):
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.dataFractionUsedForSizing > 0.0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = originalValue
                else:
                    if ((self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU) and 
                        (self.curTermUnitSizingNum > 0)):
                        self.autoSizedValue = self.termUnitSizing[self.curTermUnitSizingNum - 1].MaxHWVolFlow
                    elif self.zoneEqFanCoil:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].MaxHWVolFlow
                    elif self.zoneEqUnitHeater or self.zoneEqVentedSlab:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].MaxHWVolFlow
                    else:
                        desMassFlow = self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatMassFlow
                        if self.zoneEqSizing[self.curZoneEqNum - 1].SystemAirFlow:
                            desMassFlow = self.zoneEqSizing[self.curZoneEqNum - 1].AirVolFlow * state.dataEnvrn.StdRhoAir
                        elif self.zoneEqSizing[self.curZoneEqNum - 1].HeatingAirFlow:
                            desMassFlow = self.zoneEqSizing[self.curZoneEqNum - 1].HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                        coilInTemp = self.setHeatCoilInletTempForZoneEqSizing(
                            self.setOAFracForZoneEqSizing(state, desMassFlow, self.zoneEqSizing[self.curZoneEqNum - 1]),
                            self.zoneEqSizing[self.curZoneEqNum - 1],
                            self.finalZoneSizing[self.curZoneEqNum - 1])
                        coilOutTemp = self.finalZoneSizing[self.curZoneEqNum - 1].HeatDesTemp
                        coilOutHumRat = self.finalZoneSizing[self.curZoneEqNum - 1].HeatDesHumRat
                        desCoilLoad = Psychrometrics.PsyCpAirFnW(coilOutHumRat) * desMassFlow * (coilOutTemp - coilInTemp)
                        if desCoilLoad >= HVAC.SmallLoad:
                            if (self.dataWaterLoopNum > 0 and self.dataWaterLoopNum <= len(state.dataPlnt.PlantLoop) and
                                self.dataWaterCoilSizHeatDeltaT > 0.0):
                                cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getSpecificHeat(
                                    state, Constant.HWInitConvTemp, self.callingRoutine)
                                rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getDensity(
                                    state, Constant.HWInitConvTemp, self.callingRoutine)
                                self.autoSizedValue = desCoilLoad / (self.dataWaterCoilSizHeatDeltaT * cp * rho)
                            else:
                                msg = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", certain inputs are required. Add PlantLoop, Plant loop number and/or Water Coil water delta T."
                                self.errorType = AutoSizingResultType.ErrorType1
                                self.addErrorMessage(msg)
                                ShowSevereError(state, msg)
                        else:
                            self.autoSizedValue = 0.0
            elif self.curSysNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                    self.autoSizedValue = originalValue
                else:
                    if self.dataCapacityUsedForSizing >= HVAC.SmallLoad:
                        if (self.dataWaterLoopNum > 0 and self.dataWaterLoopNum <= len(state.dataPlnt.PlantLoop) and
                            self.dataWaterCoilSizHeatDeltaT > 0.0):
                            cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getSpecificHeat(
                                state, Constant.HWInitConvTemp, self.callingRoutine)
                            rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getDensity(
                                state, Constant.HWInitConvTemp, self.callingRoutine)
                            self.autoSizedValue = self.dataCapacityUsedForSizing / (self.dataWaterCoilSizHeatDeltaT * cp * rho)
                        else:
                            self.autoSizedValue = 0.0
                            msg = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", certain inputs are required. Add PlantLoop, Plant loop number, coil capacity and/or Water Coil water delta T."
                            self.errorType = AutoSizingResultType.ErrorType1
                            self.addErrorMessage(msg)
                            ShowSevereError(state, msg)
                    else:
                        self.autoSizedValue = 0.0
        if self.overrideSizeString:
            self.sizingString = "Maximum Water Flow Rate [m3/s]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilWaterFlowPltSizNum(
                state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized, self.dataPltSizHeatNum, self.dataWaterLoopNum)
            ReportCoilSelection.setCoilEntWaterTemp(state, self.coilReportNum, Constant.HWInitConvTemp)
            if self.plantSizData and self.dataPltSizHeatNum > 0:
                ReportCoilSelection.setCoilWaterDeltaT(state, self.coilReportNum, self.plantSizData[self.dataPltSizHeatNum - 1].DeltaT)
                ReportCoilSelection.setCoilLvgWaterTemp(
                    state, self.coilReportNum, Constant.HWInitConvTemp - self.plantSizData[self.dataPltSizHeatNum - 1].DeltaT)
            self.calcCoilWaterFlowRates(
                state,
                self.compName,
                self.compType,
                self.autoSizedValue,
                self.dataWaterLoopNum,
                self.curZoneEqNum,
                self.curSysNum,
                self.curOASysNum,
                self.finalZoneSizing,
                self.finalSysSizing)
        return self.autoSizedValue
