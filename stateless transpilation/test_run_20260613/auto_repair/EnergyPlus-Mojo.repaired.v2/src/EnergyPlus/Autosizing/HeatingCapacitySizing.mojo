from BaseSizerWithScalableInputs import BaseSizerWithScalableInputs
from CurveManager import *
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHVACGlobals import *
from General import *
from Psychrometrics import PsyCpAirFnW
from ReportCoilSelection import ReportCoilSelection
from DataSizing import *
from HVAC import *
from Util import SameString
struct HeatingCapacitySizer(BaseSizerWithScalableInputs):
    def __init__(inout self):
        self.sizingType = AutoSizingType.HeatingCapacitySizing
        self.sizingString = "Heating Capacity [W]"
    def __del__(inout self):

    def size(inout self, inout state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        var DesVolFlow: Float64 = 0.0
        var CoilInTemp: Float64 = -999.0
        var CoilInHumRat: Float64 = -999.0
        var CoilOutTemp: Float64 = -999.0
        var CoilOutHumRat: Float64 = -999.0
        var DXFlowPerCapMinRatio: Float64 = 1.0
        var DXFlowPerCapMaxRatio: Float64 = 1.0
        var NominalCapacityDes: Float64 = 0.0
        var DesMassFlow: Float64 = 0.0
        var DesCoilLoad: Float64 = 0.0
        var OutAirFrac: Float64 = 0.0
        var const CpAirStd: Float64 = PsyCpAirFnW(0.0)
        if self.dataEMSOverrideON:
            self.autoSizedValue = self.dataEMSOverride
        elif self.dataConstantUsedForSizing >= 0 and self.dataFractionUsedForSizing > 0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = _originalValue
                elif self.zoneEqSizing[self.curZoneEqNum - 1].DesignSizeFromParent:
                    self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].DesHeatingLoad
                else:
                    if self.dataCoilIsSuppHeater and self.suppHeatCap > 0.0:
                        NominalCapacityDes = self.suppHeatCap
                        if self.dataFlowUsedForSizing > 0.0:
                            DesVolFlow = self.dataFlowUsedForSizing
                    elif self.zoneEqSizing[self.curZoneEqNum - 1].HeatingCapacity:
                        NominalCapacityDes = self.zoneEqSizing[self.curZoneEqNum - 1].DesHeatingLoad
                        if self.dataFlowUsedForSizing > 0.0:
                            DesVolFlow = self.dataFlowUsedForSizing
                    elif self.dataCoolCoilCap > 0.0 and self.dataFlowUsedForSizing > 0.0:
                        NominalCapacityDes = self.dataCoolCoilCap
                        DesVolFlow = self.dataFlowUsedForSizing
                    elif len(self.finalZoneSizing) > 0 and self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatMassFlow >= HVAC.SmallMassFlow:
                        if self.dataFlowUsedForSizing > 0.0:
                            DesVolFlow = self.dataFlowUsedForSizing
                        if self.termUnitPIU and (self.curTermUnitSizingNum > 0):
                            var const MinPriFlowFrac: Float64 = self.termUnitSizing[self.curTermUnitSizingNum - 1].MinPriFlowFrac
                            if self.termUnitSizing[self.curTermUnitSizingNum - 1].InducesPlenumAir:
                                CoilInTemp = (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatCoilInTempTU * MinPriFlowFrac) + \
                                             (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].ZoneRetTempAtHeatPeak * (1.0 - MinPriFlowFrac))
                            else:
                                CoilInTemp = (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatCoilInTempTU * MinPriFlowFrac) + \
                                             (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].ZoneTempAtHeatPeak * (1.0 - MinPriFlowFrac))
                        elif self.termUnitIU and (self.curTermUnitSizingNum > 0):
                            CoilInTemp = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].ZoneTempAtHeatPeak
                            CoilInHumRat = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].ZoneHumRatAtHeatPeak
                        elif self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                            CoilInTemp = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatCoilInTempTU
                            CoilInHumRat = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatCoilInHumRatTU
                        else:
                            if DesVolFlow > 0.0:
                                DesMassFlow = DesVolFlow * state.dataEnvrn.StdRhoAir
                            else:
                                DesMassFlow = self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatMassFlow
                            CoilInTemp = self.setHeatCoilInletTempForZoneEqSizing(
                                self.setOAFracForZoneEqSizing(state, DesMassFlow, self.zoneEqSizing[self.curZoneEqNum - 1]),
                                self.zoneEqSizing[self.curZoneEqNum - 1],
                                self.finalZoneSizing[self.curZoneEqNum - 1])
                            CoilInHumRat = self.setHeatCoilInletHumRatForZoneEqSizing(
                                self.setOAFracForZoneEqSizing(state, DesMassFlow, self.zoneEqSizing[self.curZoneEqNum - 1]),
                                self.zoneEqSizing[self.curZoneEqNum - 1],
                                self.finalZoneSizing[self.curZoneEqNum - 1])
                        if (self.termUnitSingDuct or self.termUnitPIU) and (self.curTermUnitSizingNum > 0):
                            CoilOutTemp = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].HeatDesTemp
                            CoilOutHumRat = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].HeatDesHumRat
                            var const CpAir: Float64 = PsyCpAirFnW(CoilOutHumRat)
                            DesCoilLoad = CpAir * state.dataEnvrn.StdRhoAir * self.termUnitSizing[self.curTermUnitSizingNum - 1].AirVolFlow * \
                                          (CoilOutTemp - CoilInTemp)
                            DesVolFlow = self.termUnitSizing[self.curTermUnitSizingNum - 1].AirVolFlow
                        elif self.termUnitIU and (self.curTermUnitSizingNum > 0):
                            if self.termUnitSizing[self.curTermUnitSizingNum - 1].InducRat > 0.01:
                                DesVolFlow = self.termUnitSizing[self.curTermUnitSizingNum - 1].AirVolFlow / \
                                             self.termUnitSizing[self.curTermUnitSizingNum - 1].InducRat
                                var const CpAir: Float64 = PsyCpAirFnW(self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].HeatDesHumRat)
                                DesCoilLoad = self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatLoad - \
                                              (CpAir * state.dataEnvrn.StdRhoAir * DesVolFlow * \
                                               (self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].DesHeatCoilInTempTU - \
                                                self.termUnitFinalZoneSizing[self.curTermUnitSizingNum - 1].ZoneTempAtHeatPeak))
                            else:
                                DesCoilLoad = 0.0
                        else:
                            CoilOutTemp = self.finalZoneSizing[self.curZoneEqNum - 1].HeatDesTemp
                            CoilOutHumRat = self.finalZoneSizing[self.curZoneEqNum - 1].HeatDesHumRat
                            var const CpAir: Float64 = PsyCpAirFnW(CoilOutHumRat)
                            DesCoilLoad = CpAir * self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatMassFlow * (CoilOutTemp - CoilInTemp)
                            DesVolFlow = self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatMassFlow / state.dataEnvrn.StdRhoAir
                        NominalCapacityDes = max(0.0, DesCoilLoad)
                    else:
                        NominalCapacityDes = 0.0
                        CoilOutTemp = -999.0
                    if self.dataCoolCoilCap > 0.0:
                        self.autoSizedValue = NominalCapacityDes * self.dataHeatSizeRatio
                    else:
                        self.autoSizedValue = NominalCapacityDes * self.dataHeatSizeRatio * self.dataFracOfAutosizedHeatingCapacity
                    if state.dataGlobal.DisplayExtraWarnings and self.autoSizedValue <= 0.0:
                        ShowWarningMessage(state,
                                           self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName)
                        ShowContinueError(state, f"...Rated Total Heating Capacity = {self.autoSizedValue:.2f} [W]")
                        if self.zoneEqSizing[self.curZoneEqNum - 1].HeatingCapacity or \
                           (self.dataCoolCoilCap > 0.0 and self.dataFlowUsedForSizing > 0.0):
                            ShowContinueError(
                                state, f"...Capacity passed by parent object to size child component = {NominalCapacityDes:.2f} [W]")
                        else:
                            if CoilOutTemp > -999.0:
                                ShowContinueError(state, f"...Air flow rate used for sizing = {DesVolFlow:.5f} [m3/s]")
                                ShowContinueError(state, f"...Coil inlet air temperature used for sizing = {CoilInTemp:.2f} [C]")
                                ShowContinueError(state, f"...Coil outlet air temperature used for sizing = {CoilOutTemp:.2f} [C]")
                            else:
                                ShowContinueError(state, "...Capacity used to size child component set to 0 [W]")
            elif self.curSysNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                    self.autoSizedValue = _originalValue
                else:
                    if self.curOASysNum > 0:
                        if self.oaSysEqSizing[self.curOASysNum - 1].AirFlow:
                            DesVolFlow = self.oaSysEqSizing[self.curOASysNum - 1].AirVolFlow
                        elif self.oaSysEqSizing[self.curOASysNum - 1].HeatingAirFlow:
                            DesVolFlow = self.oaSysEqSizing[self.curOASysNum - 1].HeatingAirVolFlow
                        elif self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum > -1:
                            DesVolFlow = \
                                self.airloopDOAS[self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum].SizingMassFlow / state.dataEnvrn.StdRhoAir
                        else:
                            DesVolFlow = self.finalSysSizing[self.curSysNum - 1].DesOutAirVolFlow
                    else:
                        if self.finalSysSizing[self.curSysNum - 1].HeatingCapMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                            self.dataFracOfAutosizedHeatingCapacity = self.finalSysSizing[self.curSysNum - 1].FractionOfAutosizedHeatingCapacity
                        if self.dataFlowUsedForSizing > 0.0:
                            DesVolFlow = self.dataFlowUsedForSizing
                        elif self.unitarySysEqSizing[self.curSysNum - 1].AirFlow:
                            DesVolFlow = self.unitarySysEqSizing[self.curSysNum - 1].AirVolFlow
                        elif self.unitarySysEqSizing[self.curSysNum - 1].HeatingAirFlow:
                            DesVolFlow = self.unitarySysEqSizing[self.curSysNum - 1].HeatingAirVolFlow
                        else:
                            if self.curDuctType == HVAC.AirDuctType.Main:
                                if self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat > 0.0 and not self.dataDesicRegCoil:
                                    DesVolFlow = \
                                        self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat * self.finalSysSizing[self.curSysNum - 1].DesMainVolFlow
                                else:
                                    DesVolFlow = self.finalSysSizing[self.curSysNum - 1].DesMainVolFlow
                            elif self.curDuctType == HVAC.AirDuctType.Cooling:
                                if self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat > 0.0 and not self.dataDesicRegCoil:
                                    DesVolFlow = \
                                        self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat * self.finalSysSizing[self.curSysNum - 1].DesCoolVolFlow
                                else:
                                    DesVolFlow = self.finalSysSizing[self.curSysNum - 1].DesCoolVolFlow
                            elif self.curDuctType == HVAC.AirDuctType.Heating:
                                DesVolFlow = self.finalSysSizing[self.curSysNum - 1].DesHeatVolFlow
                            else:
                                DesVolFlow = self.finalSysSizing[self.curSysNum - 1].DesMainVolFlow
                    DesMassFlow = state.dataEnvrn.StdRhoAir * DesVolFlow
                    if self.curOASysNum > 0:
                        OutAirFrac = 1.0
                    elif self.finalSysSizing[self.curSysNum - 1].HeatOAOption == DataSizing.OAControl.MinOA:
                        if DesVolFlow > 0.0:
                            OutAirFrac = self.finalSysSizing[self.curSysNum - 1].DesOutAirVolFlow / DesVolFlow
                        else:
                            OutAirFrac = 1.0
                        OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                    else:
                        OutAirFrac = 1.0
                    if self.curOASysNum == 0 and self.primaryAirSystem[self.curSysNum - 1].NumOAHeatCoils > 0:
                        CoilInTemp = OutAirFrac * self.finalSysSizing[self.curSysNum - 1].PreheatTemp + \
                                     (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum - 1].HeatRetTemp
                        CoilInHumRat = OutAirFrac * self.finalSysSizing[self.curSysNum - 1].PreheatHumRat + \
                                       (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum - 1].HeatRetHumRat # include humrat for coil sizing reports
                    elif self.curOASysNum > 0 and self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum > -1:
                        CoilInTemp = self.airloopDOAS[self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum].HeatOutTemp
                    else:
                        CoilInTemp = OutAirFrac * self.finalSysSizing[self.curSysNum - 1].HeatOutTemp + \
                                     (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum - 1].HeatRetTemp
                        CoilInHumRat = OutAirFrac * self.finalSysSizing[self.curSysNum - 1].HeatOutHumRat + \
                                       (1.0 - OutAirFrac) * self.finalSysSizing[self.curSysNum - 1].HeatRetHumRat # include humrat for coil sizing reports
                    if self.curOASysNum > 0:
                        if self.oaSysEqSizing[self.curOASysNum - 1].HeatingCapacity:
                            DesCoilLoad = self.oaSysEqSizing[self.curOASysNum - 1].DesHeatingLoad
                        elif self.dataDesicRegCoil:
                            DesCoilLoad = CpAirStd * DesMassFlow * (self.dataDesOutletAirTemp - self.dataDesInletAirTemp)
                            CoilOutTemp = self.dataDesOutletAirTemp
                        elif self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum > -1:
                            DesCoilLoad = CpAirStd * DesMassFlow * \
                                          (self.airloopDOAS[self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum].PreheatTemp - CoilInTemp)
                            CoilOutTemp = self.airloopDOAS[self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum].PreheatTemp
                        else:
                            DesCoilLoad = CpAirStd * DesMassFlow * (self.finalSysSizing[self.curSysNum - 1].PreheatTemp - CoilInTemp)
                            CoilOutTemp = self.finalSysSizing[self.curSysNum - 1].PreheatTemp
                            CoilOutHumRat = self.finalSysSizing[self.curSysNum - 1].PreheatHumRat
                    else:
                        if self.unitarySysEqSizing[self.curSysNum - 1].HeatingCapacity:
                            DesCoilLoad = self.unitarySysEqSizing[self.curSysNum - 1].DesHeatingLoad
                            CoilOutTemp = self.finalSysSizing[self.curSysNum - 1].HeatSupTemp
                            CoilOutHumRat = self.finalSysSizing[self.curSysNum - 1].HeatSupHumRat
                        elif self.dataDesicRegCoil:
                            DesCoilLoad = CpAirStd * DesMassFlow * (self.dataDesOutletAirTemp - self.dataDesInletAirTemp)
                            CoilOutTemp = self.dataDesOutletAirTemp
                        else:
                            DesCoilLoad = CpAirStd * DesMassFlow * (self.finalSysSizing[self.curSysNum - 1].HeatSupTemp - CoilInTemp)
                            CoilOutTemp = self.finalSysSizing[self.curSysNum - 1].HeatSupTemp
                            CoilOutHumRat = self.finalSysSizing[self.curSysNum - 1].HeatSupHumRat
                    if self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys and self.airLoopControlInfo[self.curSysNum - 1].UnitarySys:
                        if self.dataCoilIsSuppHeater:
                            NominalCapacityDes = self.suppHeatCap
                        elif self.dataCoolCoilCap > 0.0:
                            NominalCapacityDes = self.dataCoolCoilCap
                        else:
                            if self.airLoopControlInfo[self.curSysNum - 1].UnitarySysSimulating and \
                               not SameString(self.compType, "COIL:HEATING:WATER"):
                                NominalCapacityDes = self.unitaryHeatCap
                            else:
                                if DesCoilLoad >= HVAC.SmallLoad:
                                    NominalCapacityDes = DesCoilLoad
                                else:
                                    NominalCapacityDes = 0.0
                        DesCoilLoad = NominalCapacityDes
                    elif self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys and \
                         self.finalSysSizing[self.curSysNum - 1].HeatingCapMethod == DataSizing.CapacityPerFloorArea:
                        NominalCapacityDes = self.finalSysSizing[self.curSysNum - 1].HeatingTotalCapacity
                    elif self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys and \
                         self.finalSysSizing[self.curSysNum - 1].HeatingCapMethod == DataSizing.HeatingDesignCapacity and \
                         self.finalSysSizing[self.curSysNum - 1].HeatingTotalCapacity > 0.0:
                        NominalCapacityDes = self.finalSysSizing[self.curSysNum - 1].HeatingTotalCapacity
                    else:
                        if self.dataCoolCoilCap > 0.0: # this line can't get executed with same logic above else
                            NominalCapacityDes = self.dataCoolCoilCap
                        elif DesCoilLoad >= HVAC.SmallLoad:
                            NominalCapacityDes = DesCoilLoad
                        else:
                            NominalCapacityDes = 0.0
                    self.autoSizedValue = NominalCapacityDes * self.dataHeatSizeRatio
                    if self.curOASysNum > 0:
                        if not self.oaSysEqSizing[self.curOASysNum - 1].HeatingCapacity:
                            self.autoSizedValue = self.autoSizedValue * self.dataFracOfAutosizedHeatingCapacity
                    else:
                        if not self.unitarySysEqSizing[self.curSysNum - 1].HeatingCapacity:
                            self.autoSizedValue = self.autoSizedValue * self.dataFracOfAutosizedHeatingCapacity
                    if state.dataGlobal.DisplayExtraWarnings and self.autoSizedValue <= 0.0:
                        ShowWarningMessage(state,
                                           self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName)
                        ShowContinueError(state, f"...Rated Total Heating Capacity = {self.autoSizedValue:.2f} [W]")
                        if CoilOutTemp > -999.0:
                            ShowContinueError(state, f"...Air flow rate used for sizing = {DesVolFlow:.5f} [m3/s]")
                            ShowContinueError(state, f"...Outdoor air fraction used for sizing = {OutAirFrac:.2f}")
                            ShowContinueError(state, f"...Coil inlet air temperature used for sizing = {CoilInTemp:.2f} [C]")
                            ShowContinueError(state, f"...Coil outlet air temperature used for sizing = {CoilOutTemp:.2f} [C]")
                        else:
                            ShowContinueError(state,
                                              f"...Capacity passed by parent object to size child component = {DesCoilLoad:.2f} [W]")
            elif self.dataNonZoneNonAirloopValue > 0:
                self.autoSizedValue = self.dataNonZoneNonAirloopValue
            elif not self.wasAutoSized:
                self.autoSizedValue = self.originalValue
            else:
                var msg: String = self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                ShowSevereError(state, msg)
                self.addErrorMessage(msg)
                msg = f"SizingString = {self.sizingString}, SizingResult = {self.autoSizedValue:.1f}"
                ShowContinueError(state, msg)
                self.addErrorMessage(msg)
                errorsFound = True
        if not self.hardSizeNoDesignRun or self.dataScalableSizingON or self.dataScalableCapSizingON:
            if self.wasAutoSized and self.dataFractionUsedForSizing == 0.0:
                var FlagCheckVolFlowPerRatedTotCap: Bool = True
                if SameString(self.compType, "Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl") or \
                   SameString(self.compType, "Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl"):
                    FlagCheckVolFlowPerRatedTotCap = False
                if self.dataIsDXCoil and FlagCheckVolFlowPerRatedTotCap and self.autoSizedValue > 0.0:
                    var RatedVolFlowPerRatedTotCap: Float64 = DesVolFlow / self.autoSizedValue
                    if RatedVolFlowPerRatedTotCap < HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag:
                            ShowWarningError(state, self.callingRoutine + ' ' + self.compType + ' ' + self.compName)
                            ShowContinueError(
                                state, "..." + self.sizingString + " will be limited by the minimum rated volume flow per rated total capacity ratio.")
                            ShowContinueError(state, f"...DX coil volume flow rate [m3/s] = {DesVolFlow:.6f}")
                            ShowContinueError(state, f"...Requested capacity [W] = {self.autoSizedValue:.3f}")
                            ShowContinueError(state, f"...Requested flow/capacity ratio [m3/s/W] = {RatedVolFlowPerRatedTotCap:#G}")
                            ShowContinueError(state,
                                              f"...Minimum flow/capacity ratio [m3/s/W] = {HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:#G}")
                        DXFlowPerCapMinRatio = (DesVolFlow / HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]) / \
                                               self.autoSizedValue # set DX Coil Capacity Increase Ratio from Too Low Flow/Capacity Ratio
                        self.autoSizedValue = DesVolFlow / HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag:
                            ShowContinueError(state, f"...Adjusted capacity [W] = {self.autoSizedValue:.3f}")
                    elif RatedVolFlowPerRatedTotCap > HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag:
                            ShowWarningError(state, self.callingRoutine + ' ' + self.compType + ' ' + self.compName)
                            ShowContinueError(
                                state, "..." + self.sizingString + " will be limited by the maximum rated volume flow per rated total capacity ratio.")
                            ShowContinueError(state, f"...DX coil volume flow rate [m3/s] = {DesVolFlow:.6f}")
                            ShowContinueError(state, f"...Requested capacity [W] = {self.autoSizedValue:.3f}")
                            ShowContinueError(state, f"...Requested flow/capacity ratio [m3/s/W] = {RatedVolFlowPerRatedTotCap:#G}")
                            ShowContinueError(state,
                                              f"...Maximum flow/capacity ratio [m3/s/W] = {HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:#G}")
                        DXFlowPerCapMaxRatio = DesVolFlow / HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)] / \
                                               self.autoSizedValue # set DX Coil Capacity Decrease Ratio from Too High Flow/Capacity Ratio
                        self.autoSizedValue = DesVolFlow / HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag:
                            ShowContinueError(state, f"...Adjusted capacity [W] = {self.autoSizedValue:.3f}")
        if self.overrideSizeString:
            self.sizingString = "Heating Capacity [W]"
        if self.dataScalableCapSizingON:
            switch self.zoneEqSizing[self.curZoneEqNum - 1].SizingMethod(HVAC.HeatingCapacitySizing):
                case DataSizing.CapacityPerFloorArea:
                    self.sizingStringScalable = "(scaled by capacity / area) "
                case DataSizing.FractionOfAutosizedHeatingCapacity:
                    self.sizingStringScalable = "(scaled by fractional multiplier) "
                case DataSizing.FractionOfAutosizedCoolingCapacity:
                    self.sizingStringScalable = "(scaled by fractional multiplier) "
                otherwise:

        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            if CoilInTemp > -999.0: # set inlet air properties used during capacity sizing if available, allow for negative winter temps
                ReportCoilSelection.setCoilEntAirTemp(state, self.coilReportNum, CoilInTemp, self.curSysNum, self.curZoneEqNum)
                ReportCoilSelection.setCoilEntAirHumRat(state, self.coilReportNum, CoilInHumRat)
            if CoilOutTemp > -999.0: # set outlet air properties used during capacity sizing if available
                ReportCoilSelection.setCoilLvgAirTemp(state, self.coilReportNum, CoilOutTemp)
                ReportCoilSelection.setCoilLvgAirHumRat(state, self.coilReportNum, CoilOutHumRat)
            ReportCoilSelection.setCoilAirFlow(state, self.coilReportNum, DesVolFlow, self.wasAutoSized)
            var FanCoolLoad: Float64 = 0.0
            var TotCapTempModFac: Float64 = 1.0
            ReportCoilSelection.setCoilHeatingCapacity(state,
                                                        self.coilReportNum,
                                                        self.autoSizedValue,
                                                        self.wasAutoSized,
                                                        self.curSysNum,
                                                        self.curZoneEqNum,
                                                        self.curOASysNum,
                                                        FanCoolLoad,
                                                        TotCapTempModFac,
                                                        DXFlowPerCapMinRatio,
                                                        DXFlowPerCapMaxRatio)
        return self.autoSizedValue
    def clearState(inout self):
        BaseSizerWithScalableInputs.clearState(self)