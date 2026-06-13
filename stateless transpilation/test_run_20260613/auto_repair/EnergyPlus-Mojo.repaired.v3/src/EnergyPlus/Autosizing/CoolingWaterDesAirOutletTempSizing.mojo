from BaseSizerWithFanHeatInputs import BaseSizerWithFanHeatInputs
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import dataEnvrn
from DataSizing import dataPlnt, dataWaterLoopNum, dataWaterFlowUsedForSizing, dataWaterCoilSizCoolDeltaT, dataDesInletAirTemp, dataDesInletAirHumRat, dataAirFlowUsedForSizing, plantSizData, dataPltSizCoolNum, finalZoneSizing, curZoneEqNum, curSysNum, curOASysNum, outsideAirSys, airloopDOAS, finalSysSizing, dataDesOutletAirTemp, primaryAirSystem, dataDesInletWaterTemp, overrideSizeString, sizingString, selectSizerOutput, isCoilReportObject, coilReportNum, autoSizedValue, wasAutoSized, sizingDesRunThisZone, sizingDesRunThisAirSys, termUnitIU, compName, callingRoutine, addErrorMessage, setDataDesAccountForFanHeat, calcFanDesHeatGain, checkInitialized, preSize
from FluidProperties import getSpecificHeat, getDensity
from General import ShowWarningError, ShowContinueError
from Psychrometrics import PsyCpAirFnW
from Constant import CWInitConvTemp
from HVAC import FanPlace
from ReportCoilSelection import ReportCoilSelection
struct CoolingWaterDesAirOutletTempSizer(BaseSizerWithFanHeatInputs):
    def __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterDesAirOutletTempSizing
        self.sizingString = "Design Outlet Air Temperature [C]"
    def __del__(inout self):

    def size(inout self, inout state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                if self.termUnitIU:
                    var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, CWInitConvTemp, self.callingRoutine)
                    var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, CWInitConvTemp, self.callingRoutine)
                    var DesCoilLoad: Float64 = self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizCoolDeltaT * Cp * rho
                    var T1Out: Float64 = self.dataDesInletAirTemp - DesCoilLoad / (state.dataEnvrn.StdRhoAir * PsyCpAirFnW(self.dataDesInletAirHumRat) * self.dataAirFlowUsedForSizing)
                    var T2Out: Float64 = self.plantSizData[self.dataPltSizCoolNum].ExitTemp + 2.0
                    self.autoSizedValue = max(T1Out, T2Out)
                else:
                    self.autoSizedValue = self.finalZoneSizing[self.curZoneEqNum].CoolDesTemp
                var fanDeltaT: Float64 = 0.0
                if self.dataFanPlacement == FanPlace.DrawThru:
                    var FanCoolLoad: Float64 = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                    if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                        var CpAir: Float64 = PsyCpAirFnW(self.dataDesInletAirHumRat)
                        fanDeltaT = FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing)
                        self.setDataDesAccountForFanHeat(state, False)
                self.autoSizedValue -= fanDeltaT
                if self.autoSizedValue < self.dataDesInletWaterTemp and self.dataWaterFlowUsedForSizing > 0.0:
                    var msg: String = self.callingRoutine + ":" + " Coil=\"" + self.compName + "\", Cooling Coil has leaving air temperature < entering water temperature."
                    self.addErrorMessage(msg)
                    ShowWarningError(state, msg)
                    msg = String.format("    Tair,out  =  {:.3f}", self.autoSizedValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("    Twater,in = {:.3f}", self.dataDesInletWaterTemp)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    self.autoSizedValue = self.dataDesInletWaterTemp + 0.5
                    msg = "....coil leaving air temperature will be reset to:"
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("    Tair,out = {:.3f}", self.autoSizedValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                if self.curOASysNum > 0:
                    if self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                        self.autoSizedValue = self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].PrecoolTemp
                    else:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum].PrecoolTemp
                elif self.dataDesOutletAirTemp > 0.0:
                    self.autoSizedValue = self.dataDesOutletAirTemp
                    var fanDeltaT: Float64 = 0.0
                    if self.primaryAirSystem[self.curSysNum].supFanPlace == FanPlace.DrawThru:
                        var FanCoolLoad: Float64 = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                        if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                            var CpAir: Float64 = PsyCpAirFnW(self.dataDesInletAirHumRat)
                            fanDeltaT = FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing)
                            self.setDataDesAccountForFanHeat(state, False)
                    self.autoSizedValue -= fanDeltaT
                else:
                    self.autoSizedValue = self.finalSysSizing[self.curSysNum].CoolSupTemp
                    var fanDeltaT: Float64 = 0.0
                    if self.primaryAirSystem[self.curSysNum].supFanPlace == FanPlace.DrawThru:
                        var FanCoolLoad: Float64 = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                        if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                            var CpAir: Float64 = PsyCpAirFnW(self.dataDesInletAirHumRat)
                            fanDeltaT = FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing)
                            self.setDataDesAccountForFanHeat(state, False)
                    self.autoSizedValue -= fanDeltaT
            if self.autoSizedValue < self.dataDesInletWaterTemp and self.dataWaterFlowUsedForSizing > 0.0:
                var msg: String = self.callingRoutine + ":" + " Coil=\"" + self.compName + "\", Cooling Coil has leaving air temperature < entering water temperature."
                self.addErrorMessage(msg)
                ShowWarningError(state, msg)
                msg = String.format("    Tair,out  =  {:.3f}", self.autoSizedValue)
                ShowContinueError(state, msg)
                msg = String.format("    Twater,in = {:.3f}", self.dataDesInletWaterTemp)
                ShowContinueError(state, msg)
                self.autoSizedValue = self.dataDesInletWaterTemp + 0.5
                msg = "....coil leaving air temperature will be reset to:"
                ShowContinueError(state, msg)
                msg = String.format("    Tair,out = {:.3f}", self.autoSizedValue)
                ShowContinueError(state, msg)
        if self.overrideSizeString:
            self.sizingString = "Design Outlet Air Temperature [C]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilLvgAirTemp(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue
    def clearState(inout self):
        BaseSizerWithFanHeatInputs.clearState(self)