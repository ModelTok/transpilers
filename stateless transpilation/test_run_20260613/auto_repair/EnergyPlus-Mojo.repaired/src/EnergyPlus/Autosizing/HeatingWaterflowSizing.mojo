from HeatingWaterflowSizing import HeatingWaterflowSizer
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import state.dataEnvrn
from DataHVACGlobals import HVAC
from FluidProperties import getSpecificHeat, getDensity
from Psychrometrics import PsyCpAirFnW
from Constant import HWInitConvTemp
from ReportCoilSelection import ReportCoilSelection
@value
struct HeatingWaterflowSizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.HeatingWaterflowSizing
        self.sizingString = "Maximum Water Flow Rate [m3/s]"
    def __del__(owned self):

    def size(inout self, inout state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.dataFractionUsedForSizing > 0.0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = _originalValue
                else:
                    if (self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                        self.autoSizedValue = self.termUnitSizing[self.curTermUnitSizingNum].MaxHWVolFlow
                    elif self.zoneEqFanCoil:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum].MaxHWVolFlow
                    elif self.zoneEqUnitHeater or self.zoneEqVentedSlab:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum].MaxHWVolFlow
                    else:
                        var DesMassFlow: Float64 = self.finalZoneSizing[self.curZoneEqNum].DesHeatMassFlow
                        if self.zoneEqSizing[self.curZoneEqNum].SystemAirFlow:
                            DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].AirVolFlow * state.dataEnvrn.StdRhoAir
                        elif self.zoneEqSizing[self.curZoneEqNum].HeatingAirFlow:
                            DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                        var CoilInTemp: Float64 = self.setHeatCoilInletTempForZoneEqSizing(
                            self.setOAFracForZoneEqSizing(state, DesMassFlow, self.zoneEqSizing[self.curZoneEqNum]),
                            self.zoneEqSizing[self.curZoneEqNum],
                            self.finalZoneSizing[self.curZoneEqNum])
                        var CoilOutTemp: Float64 = self.finalZoneSizing[self.curZoneEqNum].HeatDesTemp
                        var CoilOutHumRat: Float64 = self.finalZoneSizing[self.curZoneEqNum].HeatDesHumRat
                        var DesCoilLoad: Float64 = Psychrometrics.PsyCpAirFnW(CoilOutHumRat) * DesMassFlow * (CoilOutTemp - CoilInTemp)
                        if DesCoilLoad >= HVAC.SmallLoad:
                            if self.dataWaterLoopNum > 0 and self.dataWaterLoopNum <= (state.dataPlnt.PlantLoop.size) and self.dataWaterCoilSizHeatDeltaT > 0.0:
                                var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, HWInitConvTemp, self.callingRoutine)
                                var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, HWInitConvTemp, self.callingRoutine)
                                self.autoSizedValue = DesCoilLoad / (self.dataWaterCoilSizHeatDeltaT * Cp * rho)
                            else:
                                var msg: String = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", certain inputs are required. Add PlantLoop, Plant loop number and/or Water Coil water delta T."
                                self.errorType = AutoSizingResultType.ErrorType1
                                self.addErrorMessage(msg)
                                ShowSevereError(state, msg)
                        else:
                            self.autoSizedValue = 0.0
            elif self.curSysNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                    self.autoSizedValue = _originalValue
                else:
                    if self.dataCapacityUsedForSizing >= HVAC.SmallLoad:
                        if self.dataWaterLoopNum > 0 and self.dataWaterLoopNum <= (state.dataPlnt.PlantLoop.size) and self.dataWaterCoilSizHeatDeltaT > 0.0:
                            var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, HWInitConvTemp, self.callingRoutine)
                            var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, HWInitConvTemp, self.callingRoutine)
                            self.autoSizedValue = self.dataCapacityUsedForSizing / (self.dataWaterCoilSizHeatDeltaT * Cp * rho)
                        else:
                            self.autoSizedValue = 0.0
                            var msg: String = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", certain inputs are required. Add PlantLoop, Plant loop number, coil capacity and/or Water Coil water delta T."
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
            ReportCoilSelection.setCoilEntWaterTemp(state, self.coilReportNum, HWInitConvTemp)
            if not self.plantSizData.empty and self.dataPltSizHeatNum > 0:
                ReportCoilSelection.setCoilWaterDeltaT(state, self.coilReportNum, self.plantSizData[self.dataPltSizHeatNum].DeltaT)
                ReportCoilSelection.setCoilLvgWaterTemp(
                    state, self.coilReportNum, HWInitConvTemp - self.plantSizData[self.dataPltSizHeatNum].DeltaT)
            self.calcCoilWaterFlowRates(state,
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