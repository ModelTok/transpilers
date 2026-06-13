from BaseSizerWithFanHeatInputs import BaseSizerWithFanHeatInputs
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DataHVACGlobals import DataHVACGlobals
from FluidProperties import FluidProperties
from Psychrometrics import Psychrometrics
from ReportCoilSelection import ReportCoilSelection
from HVAC import HVAC
from Constant import Constant
struct CoolingWaterflowSizer(BaseSizerWithFanHeatInputs):
    def __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterflowSizing
        self.sizingString = "Design Water Flow Rate [m3/s]"
    def __del__(owned self):

    def size(inout self, inout state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        var CoilDesWaterDeltaT: Float64 = self.dataWaterCoilSizCoolDeltaT
        if self.dataFractionUsedForSizing > 0.0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = _originalValue
                else:
                    if self.termUnitIU and (self.curTermUnitSizingNum > 0):
                        self.autoSizedValue = self.termUnitSizing[self.curTermUnitSizingNum].MaxCWVolFlow
                    elif self.zoneEqFanCoil or self.zoneEqUnitVent or self.zoneEqVentedSlab:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum].MaxCWVolFlow
                    else:
                        var CoilInTemp: Float64 = self.finalZoneSizing[self.curZoneEqNum].DesCoolCoilInTemp
                        var CoilOutTemp: Float64 = self.finalZoneSizing[self.curZoneEqNum].CoolDesTemp
                        var CoilOutHumRat: Float64 = self.finalZoneSizing[self.curZoneEqNum].CoolDesHumRat
                        var CoilInHumRat: Float64 = self.finalZoneSizing[self.curZoneEqNum].DesCoolCoilInHumRat
                        var DesCoilLoad: Float64 = (
                            self.finalZoneSizing[self.curZoneEqNum].DesCoolMassFlow *
                            (Psychrometrics.PsyHFnTdbW(CoilInTemp, CoilInHumRat) - Psychrometrics.PsyHFnTdbW(CoilOutTemp, CoilOutHumRat))
                        )
                        var DesVolFlow: Float64 = self.finalZoneSizing[self.curZoneEqNum].DesCoolMassFlow / state.dataEnvrn.StdRhoAir
                        DesCoilLoad += BaseSizerWithFanHeatInputs.calcFanDesHeatGain(DesVolFlow)
                        if DesCoilLoad >= HVAC.SmallLoad:
                            if self.dataWaterLoopNum > 0 and self.dataWaterLoopNum <= (state.dataPlnt.PlantLoop.size) and self.dataWaterCoilSizCoolDeltaT > 0.0:
                                var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, Constant.CWInitConvTemp, self.callingRoutine)
                                var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, Constant.CWInitConvTemp, self.callingRoutine)
                                self.autoSizedValue = DesCoilLoad / (CoilDesWaterDeltaT * Cp * rho)
                            else:
                                self.autoSizedValue = 0.0
                                var msg: String = (
                                    "Developer Error: For autosizing of " + self.compType + ' ' + self.compName +
                                    ", certain inputs are required. Add PlantLoop, Plant loop number, coil capacity and/or Water Coil water delta T."
                                )
                                self.errorType = AutoSizingResultType.ErrorType1
                                self.addErrorMessage(msg)
                                ShowSevereError(state, msg)
                        else:
                            self.autoSizedValue = 0.0
            elif self.curSysNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                    self.autoSizedValue = _originalValue
                else:
                    if self.curOASysNum > 0:
                        CoilDesWaterDeltaT *= 0.5
                    if self.dataCapacityUsedForSizing >= HVAC.SmallLoad:
                        if self.dataWaterLoopNum > 0 and self.dataWaterLoopNum <= (state.dataPlnt.PlantLoop.size) and CoilDesWaterDeltaT > 0.0:
                            var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, Constant.CWInitConvTemp, self.callingRoutine)
                            var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, Constant.CWInitConvTemp, self.callingRoutine)
                            self.autoSizedValue = self.dataCapacityUsedForSizing / (CoilDesWaterDeltaT * Cp * rho)
                        else:
                            self.autoSizedValue = 0.0
                            var msg: String = (
                                "Developer Error: For autosizing of " + self.compType + ' ' + self.compName +
                                ", certain inputs are required. Add PlantLoop, Plant loop number, coil capacity and/or Water Coil water delta T."
                            )
                            self.errorType = AutoSizingResultType.ErrorType1
                            self.addErrorMessage(msg)
                            ShowSevereError(state, msg)
                    else:
                        self.autoSizedValue = 0.0
        if self.overrideSizeString:
            if self.coilType == HVAC.CoilType.CoolingWaterDetailed:
                self.sizingString = "Maximum Water Flow Rate [m3/s]"
            else:
                self.sizingString = "Design Water Flow Rate [m3/s]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilWaterFlowPltSizNum(
                state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized, self.dataPltSizCoolNum, self.dataWaterLoopNum
            )
            ReportCoilSelection.setCoilWaterDeltaT(state, self.coilReportNum, CoilDesWaterDeltaT)
            if self.dataDesInletWaterTemp > 0.0:
                ReportCoilSelection.setCoilEntWaterTemp(state, self.coilReportNum, self.dataDesInletWaterTemp)
                ReportCoilSelection.setCoilLvgWaterTemp(state, self.coilReportNum, self.dataDesInletWaterTemp + CoilDesWaterDeltaT)
            else:
                ReportCoilSelection.setCoilEntWaterTemp(state, self.coilReportNum, Constant.CWInitConvTemp)
                ReportCoilSelection.setCoilLvgWaterTemp(state, self.coilReportNum, Constant.CWInitConvTemp + CoilDesWaterDeltaT)
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
                self.finalSysSizing
            )
        return self.autoSizedValue
    def clearState(inout self):
        BaseSizerWithFanHeatInputs.clearState()