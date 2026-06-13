from Base import BaseSizer, AutoSizingType
from ...Data.EnergyPlusData import EnergyPlusData
from ReportCoilSelection import ReportCoilSelection
struct CoolingWaterDesAirInletHumRatSizer : BaseSizer:
    def __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterDesAirInletHumRatSizing
        self.sizingString = "Design Inlet Air Humidity Ratio [kgWater/kgDryAir]"
    def size(
        inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool
    ) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitIU:
                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).ZoneHumRatAtCoolPeak
                elif self.zoneEqFanCoil:
                    var desMassFlow = self.finalZoneSizing(self.curZoneEqNum).DesCoolMassFlow
                    self.autoSizedValue = self.setCoolCoilInletHumRatForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, desMassFlow, self.zoneEqSizing(self.curZoneEqNum)),
                        self.zoneEqSizing(self.curZoneEqNum),
                        self.finalZoneSizing(self.curZoneEqNum)
                    )
                else:
                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesCoolCoilInHumRat
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.curOASysNum > 0:  # coil is in OA stream
                    if self.outsideAirSys(self.curOASysNum).AirLoopDOASNum > -1:
                        self.autoSizedValue = self.airloopDOAS[self.outsideAirSys(self.curOASysNum).AirLoopDOASNum].SizingCoolOAHumRat
                    else:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).OutHumRatAtCoolPeak
                elif self.dataDesInletAirHumRat > 0.0:
                    self.autoSizedValue = self.dataDesInletAirHumRat
                else:  # coil is in main air loop
                    if self.primaryAirSystem(self.curSysNum).NumOACoolCoils == 0:  # there is no precooling of the OA stream
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).MixHumRatAtCoolPeak
                    else:  # there is precooling of the OA stream
                        var OutAirFrac: Float64 = 1.0
                        if self.dataFlowUsedForSizing > 0.0:
                            OutAirFrac = self.finalSysSizing(self.curSysNum).DesOutAirVolFlow / self.dataFlowUsedForSizing
                            OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                        self.autoSizedValue = (
                            OutAirFrac * self.finalSysSizing(self.curSysNum).PrecoolHumRat
                            + (1.0 - OutAirFrac) * self.finalSysSizing(self.curSysNum).RetHumRatAtCoolPeak
                        )
        if self.overrideSizeString:
            self.sizingString = "Design Inlet Air Humidity Ratio [kgWater/kgDryAir]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilEntAirHumRat(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue