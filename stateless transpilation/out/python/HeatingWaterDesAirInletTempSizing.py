# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: base class from EnergyPlus.Autosizing.Base
# - AutoSizingType: enum from EnergyPlus.Autosizing.Base
# - EnergyPlusData: type from EnergyPlus.Data.EnergyPlusData with dataEnvrn
# - ReportCoilSelection: module with setCoilEntAirTemp function

class AutoSizingType:
    HeatingWaterDesAirInletTempSizing = "HeatingWaterDesAirInletTempSizing"

class HeatingWaterDesAirInletTempSizer:
    def __init__(self):
        self.sizingType = AutoSizingType.HeatingWaterDesAirInletTempSizing
        self.sizingString = "Rated Inlet Air Temperature"

    def size(self, state, _originalValue, errorsFound):
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)

        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                if self.termUnitPIU and (self.curTermUnitSizingNum > 0):
                    MinFlowFrac = self.termUnitSizing[self.curTermUnitSizingNum - 1].MinPriFlowFrac
                    if self.termUnitSizing[self.curTermUnitSizingNum - 1].InducesPlenumAir:
                        self.autoSizedValue = (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatCoilInTempTU * MinFlowFrac) + \
                                             (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].ZoneRetTempAtHeatPeak * (1.0 - MinFlowFrac))
                    else:
                        self.autoSizedValue = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatCoilInTempTU * MinFlowFrac + \
                                             self.finalZoneSizing[self.curZoneEqNum - 1].ZoneTempAtHeatPeak * (1.0 - MinFlowFrac)
                elif self.termUnitIU and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].ZoneTempAtHeatPeak
                elif self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatCoilInTempTU
                else:
                    if self.zoneEqSizing[self.curZoneEqNum - 1].SystemAirFlow:
                        DesMassFlow = self.zoneEqSizing[self.curZoneEqNum - 1].AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing[self.curZoneEqNum - 1].HeatingAirFlow:
                        DesMassFlow = self.zoneEqSizing[self.curZoneEqNum - 1].HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        DesMassFlow = self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatMassFlow
                    self.autoSizedValue = self.setHeatCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, DesMassFlow, self.zoneEqSizing[self.curZoneEqNum - 1]),
                        self.zoneEqSizing[self.curZoneEqNum - 1],
                        self.finalZoneSizing[self.curZoneEqNum - 1])
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                OutAirFrac = 1.0
                if self.curOASysNum > 0:
                    OutAirFrac = 1.0
                elif self.finalSysSizing[self.curSysNum - 1].HeatOAOption == self.minOA:
                    if self.dataFlowUsedForSizing > 0.0:
                        OutAirFrac = self.finalSysSizing[self.curSysNum - 1].DesOutAirVolFlow / self.dataFlowUsedForSizing
                    else:
                        OutAirFrac = 1.0
                    OutAirFrac = min(1.0, max(0.0, OutAirFrac))

                if self.curOASysNum == 0 and self.primaryAirSystem[self.curSysNum - 1].NumOAHeatCoils > 0:
                    self.autoSizedValue = OutAirFrac * self.finalSysSizing[self.curSysNum - 1].PreheatTemp + \
                                         (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum - 1].HeatRetTemp
                elif self.curOASysNum > 0 and self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum > -1:
                    self.autoSizedValue = self.airloopDOAS[self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum].HeatOutTemp
                else:
                    self.autoSizedValue = OutAirFrac * self.finalSysSizing[self.curSysNum - 1].HeatOutTemp + \
                                         (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum - 1].HeatRetTemp

        if self.overrideSizeString:
            self.sizingString = "Rated Inlet Air Temperature [C]"
        self.selectSizerOutput(state, errorsFound)

        if self.curSysNum <= self.numPrimaryAirSys:
            if self.isCoilReportObject:
                ReportCoilSelection.setCoilEntAirTemp(state, self.coilReportNum, self.autoSizedValue, self.curSysNum, self.curZoneEqNum)

        return self.autoSizedValue
