from BaseSizerWithFanHeatInputs import BaseSizerWithFanHeatInputs
from Data.BaseData import EnergyPlusData
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from Psychrometrics import Psychrometrics
from HVAC import HVAC
struct CoolingWaterDesAirInletTempSizer(BaseSizerWithFanHeatInputs):
    def __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterDesAirInletTempSizing
        self.sizingString = "Design Inlet Air Temperature [C]"
    def __del__(owned self):

    def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitIU:
                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).ZoneTempAtCoolPeak
                elif self.zoneEqFanCoil:
                    var DesMassFlow: Float64 = self.finalZoneSizing(self.curZoneEqNum).DesCoolMassFlow
                    self.autoSizedValue = self.setCoolCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, DesMassFlow, self.zoneEqSizing(self.curZoneEqNum)),
                        self.zoneEqSizing(self.curZoneEqNum),
                        self.finalZoneSizing(self.curZoneEqNum))
                else:
                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesCoolCoilInTemp
                var fanDeltaT: Float64 = 0.0
                if self.dataFanPlacement == HVAC.FanPlace.BlowThru:
                    var FanCoolLoad: Float64 = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                    if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                        var CpAir: Float64 = Psychrometrics.PsyCpAirFnW(self.dataDesInletAirHumRat)
                        fanDeltaT = FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing)
                self.autoSizedValue += fanDeltaT
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.curOASysNum > 0:
                    if self.outsideAirSys(self.curOASysNum).AirLoopDOASNum > -1:
                        self.autoSizedValue = self.airloopDOAS[self.outsideAirSys(self.curOASysNum).AirLoopDOASNum].SizingCoolOATemp
                    else:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).OutTempAtCoolPeak
                else:
                    if self.primaryAirSystem(self.curSysNum).NumOACoolCoils == 0:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).MixTempAtCoolPeak
                    elif self.dataDesInletAirTemp > 0.0:
                        self.autoSizedValue = self.dataDesInletAirTemp
                    else:
                        var OutAirFrac: Float64 = 1.0
                        if self.dataFlowUsedForSizing > 0.0:
                            OutAirFrac = self.finalSysSizing(self.curSysNum).DesOutAirVolFlow / self.dataFlowUsedForSizing
                        OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                        self.autoSizedValue = OutAirFrac * self.finalSysSizing(self.curSysNum).PrecoolTemp + (1.0 - OutAirFrac) * self.finalSysSizing(self.curSysNum).RetTempAtCoolPeak
                var fanDeltaT: Float64 = 0.0
                if self.primaryAirSystem(self.curSysNum).supFanPlace == HVAC.FanPlace.BlowThru:
                    var FanCoolLoad: Float64 = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                    if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                        var CpAir: Float64 = Psychrometrics.PsyCpAirFnW(self.dataDesInletAirHumRat)
                        fanDeltaT = FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing)
                        self.setDataDesAccountForFanHeat(state, False)
                self.autoSizedValue += fanDeltaT
        if self.overrideSizeString:
            self.sizingString = "Design Inlet Air Temperature [C]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            if self.curSysNum <= self.numPrimaryAirSys:
                ReportCoilSelection.setCoilEntAirTemp(state, self.coilReportNum, self.autoSizedValue, self.curSysNum, self.curZoneEqNum)
        return self.autoSizedValue
    def clearState(inout self):
        BaseSizerWithFanHeatInputs.clearState(self)