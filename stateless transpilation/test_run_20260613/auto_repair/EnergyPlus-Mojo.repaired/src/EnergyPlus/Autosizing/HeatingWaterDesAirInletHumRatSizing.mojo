from Base import BaseSizer
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataEnvironment import DataEnvironment
from ...ReportCoilSelection import ReportCoilSelection
struct HeatingWaterDesAirInletHumRatSizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.HeatingWaterDesAirInletHumRatSizing
        self.sizingString = "Design Inlet Air Humidity Ratio [kgWater/kgDryAir]"
    def size(inout self, inout state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                if self.termUnitPIU and (self.curTermUnitSizingNum > 0):
                    var MinFlowFrac: Float64 = self.termUnitSizing(self.curTermUnitSizingNum).MinPriFlowFrac
                    self.autoSizedValue = self.termUnitFinalZoneSizing(self.curTermUnitSizingNum).DesHeatCoilInHumRatTU * MinFlowFrac + self.finalZoneSizing(self.curZoneEqNum).ZoneHumRatAtHeatPeak * (1.0 - MinFlowFrac)
                elif self.termUnitIU and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.termUnitFinalZoneSizing(self.curTermUnitSizingNum).ZoneHumRatAtHeatPeak
                elif self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.termUnitFinalZoneSizing(self.curTermUnitSizingNum).DesHeatCoilInHumRatTU
                else:
                    var desMassFlow: Float64 = 0.0
                    if self.zoneEqSizing(self.curZoneEqNum).SystemAirFlow != 0.0:
                        desMassFlow = self.zoneEqSizing(self.curZoneEqNum).AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow != 0.0:
                        desMassFlow = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        desMassFlow = self.finalZoneSizing(self.curZoneEqNum).DesHeatMassFlow
                    self.autoSizedValue = self.setHeatCoilInletHumRatForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, desMassFlow, self.zoneEqSizing(self.curZoneEqNum)),
                        self.zoneEqSizing(self.curZoneEqNum),
                        self.finalZoneSizing(self.curZoneEqNum))
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                var OutAirFrac: Float64 = 1.0
                if self.curOASysNum > 0:
                    OutAirFrac = 1.0
                elif self.finalSysSizing(self.curSysNum).HeatOAOption == self.minOA:
                    if self.dataFlowUsedForSizing > 0.0:
                        OutAirFrac = self.finalSysSizing(self.curSysNum).DesOutAirVolFlow / self.dataFlowUsedForSizing
                        OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                if self.curOASysNum == 0 and self.primaryAirSystem(self.curSysNum).NumOAHeatCoils > 0:
                    self.autoSizedValue = OutAirFrac * self.finalSysSizing(self.curSysNum).PreheatHumRat + (1.0 - OutAirFrac) * self.finalSysSizing(self.curSysNum).HeatRetHumRat
                elif self.curOASysNum > 0 and self.outsideAirSys(self.curOASysNum).AirLoopDOASNum > -1:
                    self.autoSizedValue = self.airloopDOAS[self.outsideAirSys(self.curOASysNum).AirLoopDOASNum].HeatOutHumRat
                else:
                    self.autoSizedValue = OutAirFrac * self.finalSysSizing(self.curSysNum).HeatOutHumRat + (1.0 - OutAirFrac) * self.finalSysSizing(self.curSysNum).HeatRetHumRat
        if self.overrideSizeString:
            self.sizingString = "Design Inlet Air Humidity Ratio [kgWater/kgDryAir]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilEntAirHumRat(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue