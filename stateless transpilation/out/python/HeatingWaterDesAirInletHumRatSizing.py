# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: from EnergyPlus.Autosizing.Base
# - EnergyPlusData: from EnergyPlus.Data.EnergyPlusData
# - ReportCoilSelection: from EnergyPlus (module containing setCoilEntAirHumRat)


class HeatingWaterDesAirInletHumRatSizer(BaseSizer):

    def __init__(self):
        self.sizingType = "HeatingWaterDesAirInletHumRatSizing"
        self.sizingString = "Design Inlet Air Humidity Ratio [kgWater/kgDryAir]"

    def size(self, state, original_value, errors_found):
        if not self.checkInitialized(state, errors_found):
            return 0.0
        self.preSize(state, original_value)

        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = original_value
            else:
                if self.termUnitPIU and (self.curTermUnitSizingNum > 0):
                    min_flow_frac = self.termUnitSizing(self.curTermUnitSizingNum).MinPriFlowFrac
                    self.autoSizedValue = (self.termUnitFinalZoneSizing(self.curTermUnitSizingNum).DesHeatCoilInHumRatTU * min_flow_frac +
                                           self.finalZoneSizing(self.curZoneEqNum).ZoneHumRatAtHeatPeak * (1.0 - min_flow_frac))
                elif self.termUnitIU and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.termUnitFinalZoneSizing(self.curTermUnitSizingNum).ZoneHumRatAtHeatPeak
                elif self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.termUnitFinalZoneSizing(self.curTermUnitSizingNum).DesHeatCoilInHumRatTU
                else:
                    des_mass_flow = 0.0
                    if self.zoneEqSizing(self.curZoneEqNum).SystemAirFlow:
                        des_mass_flow = self.zoneEqSizing(self.curZoneEqNum).AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                        des_mass_flow = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        des_mass_flow = self.finalZoneSizing(self.curZoneEqNum).DesHeatMassFlow
                    self.autoSizedValue = self.setHeatCoilInletHumRatForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, des_mass_flow, self.zoneEqSizing(self.curZoneEqNum)),
                        self.zoneEqSizing(self.curZoneEqNum),
                        self.finalZoneSizing(self.curZoneEqNum))
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = original_value
            else:
                out_air_frac = 1.0
                if self.curOASysNum > 0:
                    out_air_frac = 1.0
                elif self.finalSysSizing(self.curSysNum).HeatOAOption == self.minOA:
                    if self.dataFlowUsedForSizing > 0.0:
                        out_air_frac = self.finalSysSizing(self.curSysNum).DesOutAirVolFlow / self.dataFlowUsedForSizing
                        out_air_frac = min(1.0, max(0.0, out_air_frac))
                if self.curOASysNum == 0 and self.primaryAirSystem(self.curSysNum).NumOAHeatCoils > 0:
                    self.autoSizedValue = (out_air_frac * self.finalSysSizing(self.curSysNum).PreheatHumRat +
                                           (1.0 - out_air_frac) * self.finalSysSizing(self.curSysNum).HeatRetHumRat)
                elif self.curOASysNum > 0 and self.outsideAirSys(self.curOASysNum).AirLoopDOASNum > -1:
                    self.autoSizedValue = self.airloopDOAS[self.outsideAirSys(self.curOASysNum).AirLoopDOASNum].HeatOutHumRat
                else:
                    self.autoSizedValue = (out_air_frac * self.finalSysSizing(self.curSysNum).HeatOutHumRat +
                                           (1.0 - out_air_frac) * self.finalSysSizing(self.curSysNum).HeatRetHumRat)
        if self.overrideSizeString:
            self.sizingString = "Design Inlet Air Humidity Ratio [kgWater/kgDryAir]"
        self.selectSizerOutput(state, errors_found)
        if self.isCoilReportObject:
            from EnergyPlus import ReportCoilSelection
            ReportCoilSelection.setCoilEntAirHumRat(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue
