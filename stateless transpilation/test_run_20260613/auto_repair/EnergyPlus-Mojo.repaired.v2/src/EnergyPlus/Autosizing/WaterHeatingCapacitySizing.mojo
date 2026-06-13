from Base import BaseSizer
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from FluidProperties import FluidProperties
from General import General
from Psychrometrics import Psychrometrics
struct WaterHeatingCapacitySizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.WaterHeatingCapacitySizing
        self.sizingString = "Rated Capacity [W]"
    def __del__(inout self):

    def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                var DesMassFlow: Float64 = 0.0
                var NominalCapacityDes: Float64 = 0.0
                var CoilInTemp: Float64 = 0.0
                var CoilOutTemp: Float64 = 0.0
                var CoilOutHumRat: Float64 = 0.0
                if (self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    DesMassFlow = self.termUnitSizing[self.curTermUnitSizingNum].MaxHWVolFlow
                    var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, self.callingRoutine)
                    var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, Constant.HWInitConvTemp, self.callingRoutine)
                    NominalCapacityDes = DesMassFlow * self.dataWaterCoilSizHeatDeltaT * Cp * rho
                elif self.zoneEqFanCoil or self.zoneEqUnitHeater:
                    DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].MaxHWVolFlow
                    var Cp: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, self.callingRoutine)
                    var rho: Float64 = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(state, Constant.HWInitConvTemp, self.callingRoutine)
                    NominalCapacityDes = DesMassFlow * self.dataWaterCoilSizHeatDeltaT * Cp * rho
                else:
                    if self.zoneEqSizing[self.curZoneEqNum].SystemAirFlow:
                        DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing[self.curZoneEqNum].HeatingAirFlow:
                        DesMassFlow = self.zoneEqSizing[self.curZoneEqNum].HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        DesMassFlow = self.finalZoneSizing[self.curZoneEqNum].DesHeatMassFlow
                    CoilInTemp = self.setHeatCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, DesMassFlow, self.zoneEqSizing[self.curZoneEqNum]),
                        self.zoneEqSizing[self.curZoneEqNum],
                        self.finalZoneSizing[self.curZoneEqNum])
                    CoilOutTemp = self.finalZoneSizing[self.curZoneEqNum].HeatDesTemp
                    CoilOutHumRat = self.finalZoneSizing[self.curZoneEqNum].HeatDesHumRat
                    NominalCapacityDes = Psychrometrics.PsyCpAirFnW(CoilOutHumRat) * DesMassFlow * (CoilOutTemp - CoilInTemp)
                self.autoSizedValue = NominalCapacityDes * self.dataHeatSizeRatio
                if state.dataGlobal.DisplayExtraWarnings and self.autoSizedValue <= 0.0:
                    var msg: String = self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName
                    self.addErrorMessage(msg)
                    ShowWarningMessage(state, msg)
                    msg = String.format("...Rated Total Heating Capacity = {:.2f} [W]", self.autoSizedValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("...Air flow rate used for sizing = {:.5f} [m3/s]", DesMassFlow / state.dataEnvrn.StdRhoAir)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    if self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil or self.zoneEqUnitHeater:
                        msg = String.format("...Air flow rate used for sizing = {:.5f} [m3/s]", DesMassFlow / state.dataEnvrn.StdRhoAir)
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = String.format("...Plant loop temperature difference = {:.2f} [C]", self.dataWaterCoilSizHeatDeltaT)
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                    else:
                        msg = String.format("...Coil inlet air temperature used for sizing = {:.2f} [C]", CoilInTemp)
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = String.format("...Coil outlet air temperature used for sizing = {:.2f} [C]", CoilOutTemp)
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = String.format("...Coil outlet air humidity ratio used for sizing = {:.2f} [kgWater/kgDryAir]", CoilOutHumRat)
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:

        if self.overrideSizeString:
            self.sizingString = "Rated Capacity [W]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilWaterHeaterCapacityPltSizNum(
                state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized, self.dataPltSizHeatNum, self.dataWaterLoopNum)
        return self.autoSizedValue