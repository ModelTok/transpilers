from BaseSizerWithScalableInputs import BaseSizerWithScalableInputs
from Data.BaseData import *
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from FluidProperties import *
from Psychrometrics import *
from Constant import *
from ReportCoilSelection import *
from DataSizing import *
struct HeatingWaterDesCoilLoadUsedForUASizer(BaseSizerWithScalableInputs):
    def __init__(inout self):
        self.sizingType = AutoSizingType.HeatingWaterDesCoilLoadUsedForUASizing
        self.sizingString = "Water Heating Design Coil Load for UA Sizing [W]"
    def __del__(owned self):

    def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, self.callingRoutine)
                    var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, Constant.HWInitConvTemp, self.callingRoutine)
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * Cp * rho
                    ReportCoilSelection.setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
                elif (self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, self.callingRoutine)
                    var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, Constant.HWInitConvTemp, self.callingRoutine)
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * Cp * rho * self.termUnitSizing[self.curTermUnitSizingNum].ReheatLoadMult
                elif self.zoneEqFanCoil or self.zoneEqUnitHeater:
                    var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, self.callingRoutine)
                    var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, Constant.HWInitConvTemp, self.callingRoutine)
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * Cp * rho
                    ReportCoilSelection.setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
                else:
                    var DesMassFlow: Float64 = 0.0
                    if self.zoneEqSizing[self.curZoneEqNum].SystemAirFlow:
                        DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing[self.curZoneEqNum].HeatingAirFlow:
                        DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        DesMassFlow = self.finalZoneSizing[self.curZoneEqNum].DesHeatMassFlow
                    var CoilInTemp: Float64 = self.setHeatCoilInletTempForZoneEqSizing(setOAFracForZoneEqSizing(state, DesMassFlow, self.zoneEqSizing[self.curZoneEqNum]), self.zoneEqSizing[self.curZoneEqNum], self.finalZoneSizing[self.curZoneEqNum])
                    var CoilOutTemp: Float64 = self.finalZoneSizing[self.curZoneEqNum].HeatDesTemp
                    var CoilOutHumRat: Float64 = self.finalZoneSizing[self.curZoneEqNum].HeatDesHumRat
                    self.autoSizedValue = Psychrometrics.PsyCpAirFnW(CoilOutHumRat) * DesMassFlow * (CoilOutTemp - CoilInTemp)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                var OutAirFrac: Float64 = 1.0
                if self.curOASysNum > 0:
                    OutAirFrac = 1.0
                elif self.finalSysSizing[self.curSysNum].HeatOAOption == self.minOA:
                    if self.dataAirFlowUsedForSizing > 0.0:
                        OutAirFrac = self.finalSysSizing[self.curSysNum].DesOutAirVolFlow / self.dataAirFlowUsedForSizing
                        OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                    else:
                        OutAirFrac = 1.0
                else:
                    OutAirFrac = 1.0
                var CoilInTemp: Float64 = 0.0
                if self.curOASysNum == 0 and self.primaryAirSystem[self.curSysNum].NumOAHeatCoils > 0:
                    CoilInTemp = OutAirFrac * self.finalSysSizing[self.curSysNum].PreheatTemp + (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum].HeatRetTemp
                elif self.curOASysNum > 0 and self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                    CoilInTemp = self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].HeatOutTemp
                else:
                    CoilInTemp = OutAirFrac * self.finalSysSizing[self.curSysNum].HeatOutTemp + (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum].HeatRetTemp
                var CpAirStd: Float64 = Psychrometrics.PsyCpAirFnW(0.0)
                if self.curOASysNum > 0:
                    if self.dataDesicRegCoil:
                        self.autoSizedValue = CpAirStd * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing * (self.dataDesOutletAirTemp - self.dataDesInletAirTemp)
                    elif self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                        self.autoSizedValue = CpAirStd * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing * (self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].PreheatTemp - CoilInTemp)
                    else:
                        self.autoSizedValue = CpAirStd * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing * (self.finalSysSizing[self.curSysNum].PreheatTemp - CoilInTemp)
                else:
                    if self.finalSysSizing[self.curSysNum].HeatingCapMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                        self.dataFracOfAutosizedHeatingCapacity = self.finalSysSizing[self.curSysNum].FractionOfAutosizedHeatingCapacity
                    if self.dataDesicRegCoil:
                        self.autoSizedValue = CpAirStd * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing * (self.dataDesOutletAirTemp - self.dataDesInletAirTemp)
                    else:
                        self.autoSizedValue = CpAirStd * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing * (self.finalSysSizing[self.curSysNum].HeatSupTemp - CoilInTemp)
        self.autoSizedValue = max(0.0, self.autoSizedValue) * self.dataHeatSizeRatio * self.dataFracOfAutosizedHeatingCapacity
        if self.overrideSizeString:
            self.sizingString = "Water Heating Design Coil Load for UA Sizing [W]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject and self.curSysNum <= self.numPrimaryAirSys:
            var FanCoolLoad: Float64 = 0.0
            var TotCapTempModFac: Float64 = 1.0
            var DXFlowPerCapMinRatio: Float64 = 1.0
            var DXFlowPerCapMaxRatio: Float64 = 1.0
            ReportCoilSelection.setCoilHeatingCapacity(state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized, self.curSysNum, self.curZoneEqNum, self.curOASysNum, FanCoolLoad, TotCapTempModFac, DXFlowPerCapMinRatio, DXFlowPerCapMaxRatio)
        return self.autoSizedValue