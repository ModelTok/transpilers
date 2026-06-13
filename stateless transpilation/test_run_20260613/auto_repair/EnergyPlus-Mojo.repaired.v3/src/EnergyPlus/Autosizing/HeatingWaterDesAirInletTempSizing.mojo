from Base import BaseSizer
from Data.BaseData import EnergyPlusData
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
struct HeatingWaterDesAirInletTempSizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.HeatingWaterDesAirInletTempSizing
        self.sizingString = "Rated Inlet Air Temperature"
    def __del__(owned self):

    def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitPIU and (self.curTermUnitSizingNum > 0):
                    var MinFlowFrac: Float64 = self.termUnitSizing[self.curTermUnitSizingNum].MinPriFlowFrac
                    if self.termUnitSizing[self.curTermUnitSizingNum].InducesPlenumAir:
                        self.autoSizedValue = (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum].DesHeatCoilInTempTU * MinFlowFrac) + \
                                              (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum].ZoneRetTempAtHeatPeak * (1.0 - MinFlowFrac))
                    else:
                        self.autoSizedValue = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum].DesHeatCoilInTempTU * MinFlowFrac + \
                                              self.finalZoneSizing[self.curZoneEqNum].ZoneTempAtHeatPeak * (1.0 - MinFlowFrac)
                elif self.termUnitIU and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum].ZoneTempAtHeatPeak
                elif self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum].DesHeatCoilInTempTU
                else:
                    var DesMassFlow: Float64
                    if self.zoneEqSizing[self.curZoneEqNum].SystemAirFlow:
                        DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing[self.curZoneEqNum].HeatingAirFlow:
                        DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        DesMassFlow = self.finalZoneSizing[self.curZoneEqNum].DesHeatMassFlow
                    self.autoSizedValue = self.setHeatCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, DesMassFlow, self.zoneEqSizing[self.curZoneEqNum]),
                        self.zoneEqSizing[self.curZoneEqNum],
                        self.finalZoneSizing[self.curZoneEqNum])
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                var OutAirFrac: Float64 = 1.0
                if self.curOASysNum > 0:
                    OutAirFrac = 1.0
                elif self.finalSysSizing[self.curSysNum].HeatOAOption == self.minOA:
                    if self.dataFlowUsedForSizing > 0.0:
                        OutAirFrac = self.finalSysSizing[self.curSysNum].DesOutAirVolFlow / self.dataFlowUsedForSizing
                    else:
                        OutAirFrac = 1.0
                    OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                if self.curOASysNum == 0 and self.primaryAirSystem[self.curSysNum].NumOAHeatCoils > 0:
                    self.autoSizedValue = OutAirFrac * self.finalSysSizing[self.curSysNum].PreheatTemp + \
                                          (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum].HeatRetTemp
                elif self.curOASysNum > 0 and self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                    self.autoSizedValue = self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].HeatOutTemp
                else:
                    self.autoSizedValue = OutAirFrac * self.finalSysSizing[self.curSysNum].HeatOutTemp + \
                                          (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum].HeatRetTemp
        if self.overrideSizeString:
            self.sizingString = "Rated Inlet Air Temperature [C]"
        self.selectSizerOutput(state, errorsFound)
        if self.curSysNum <= self.numPrimaryAirSys:
            if self.isCoilReportObject:
                ReportCoilSelection.setCoilEntAirTemp(state, self.coilReportNum, self.autoSizedValue, self.curSysNum, self.curZoneEqNum)
        return self.autoSizedValue