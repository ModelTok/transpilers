# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state parameter): from EnergyPlus/Data/EnergyPlusData.hh
# - BaseSizerWithFanHeatInputs: base class from EnergyPlus/Autosizing/BaseSizerWithFanHeatInputs.hh
# - AutoSizingType enum: from EnergyPlus/Autosizing/...
# - HVAC.FanPlace enum: from EnergyPlus/HVAC/...
# - Constant.CWInitConvTemp: from EnergyPlus/Constant.hh
# - Psychrometrics.PsyCpAirFnW: from EnergyPlus/Psychrometrics.hh
# - ShowWarningError, ShowContinueError: from EnergyPlus/UtilityRoutines.hh
# - ReportCoilSelection.setCoilLvgAirTemp: from EnergyPlus/CoilReportingUtility.hh


struct CoolingWaterDesAirOutletTempSizer(BaseSizerWithFanHeatInputs):
    fn __init__(inout self):
        BaseSizerWithFanHeatInputs.__init__(self)
        self.sizingType = AutoSizingType.CoolingWaterDesAirOutletTempSizing
        self.sizingString = "Design Outlet Air Temperature [C]"

    fn size(
        inout self, state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool
    ) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitIU:
                    let Cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getSpecificHeat(
                        state, Constant.CWInitConvTemp, self.callingRoutine
                    )
                    let rho = state.dataPlnt.PlantLoop[
                        self.dataWaterLoopNum - 1
                    ].glycol.getDensity(state, Constant.CWInitConvTemp, self.callingRoutine)
                    let DesCoilLoad = (
                        self.dataWaterFlowUsedForSizing
                        * self.dataWaterCoilSizCoolDeltaT
                        * Cp
                        * rho
                    )
                    let T1Out = (
                        self.dataDesInletAirTemp
                        - DesCoilLoad
                        / (
                            state.dataEnvrn.StdRhoAir
                            * Psychrometrics.PsyCpAirFnW(self.dataDesInletAirHumRat)
                            * self.dataAirFlowUsedForSizing
                        )
                    )
                    let T2Out = (
                        self.plantSizData[self.dataPltSizCoolNum - 1].ExitTemp + 2.0
                    )
                    self.autoSizedValue = max(T1Out, T2Out)
                else:
                    self.autoSizedValue = (
                        self.finalZoneSizing[self.curZoneEqNum - 1].CoolDesTemp
                    )
                var fanDeltaT: Float64 = 0.0
                if self.dataFanPlacement == HVAC.FanPlace.DrawThru:
                    let FanCoolLoad = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                    if (
                        self.dataDesInletAirHumRat > 0.0
                        and self.dataAirFlowUsedForSizing > 0.0
                    ):
                        let CpAir = Psychrometrics.PsyCpAirFnW(self.dataDesInletAirHumRat)
                        fanDeltaT = FanCoolLoad / (
                            CpAir
                            * state.dataEnvrn.StdRhoAir
                            * self.dataAirFlowUsedForSizing
                        )
                        self.setDataDesAccountForFanHeat(state, False)
                self.autoSizedValue -= fanDeltaT
                if (
                    self.autoSizedValue < self.dataDesInletWaterTemp
                    and self.dataWaterFlowUsedForSizing > 0.0
                ):
                    var msg = (
                        self.callingRoutine
                        + ":"
                        + " Coil=\""
                        + self.compName
                        + "\", Cooling Coil has leaving air temperature < entering water temperature."
                    )
                    self.addErrorMessage(msg)
                    ShowWarningError(state, msg)
                    msg = String.format(
                        "    Tair,out  =  {:.3f}", self.autoSizedValue
                    )
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format(
                        "    Twater,in = {:.3f}", self.dataDesInletWaterTemp
                    )
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    self.autoSizedValue = self.dataDesInletWaterTemp + 0.5
                    msg = "....coil leaving air temperature will be reset to:"
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format(
                        "    Tair,out = {:.3f}", self.autoSizedValue
                    )
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.curOASysNum > 0:
                    if self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum > -1:
                        self.autoSizedValue = (
                            self.airloopDOAS[
                                self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum
                            ].PrecoolTemp
                        )
                    else:
                        self.autoSizedValue = (
                            self.finalSysSizing[self.curSysNum - 1].PrecoolTemp
                        )
                elif self.dataDesOutletAirTemp > 0.0:
                    self.autoSizedValue = self.dataDesOutletAirTemp
                    var fanDeltaT: Float64 = 0.0
                    if (
                        self.primaryAirSystem[self.curSysNum - 1].supFanPlace
                        == HVAC.FanPlace.DrawThru
                    ):
                        let FanCoolLoad = self.calcFanDesHeatGain(
                            self.dataAirFlowUsedForSizing
                        )
                        if (
                            self.dataDesInletAirHumRat > 0.0
                            and self.dataAirFlowUsedForSizing > 0.0
                        ):
                            let CpAir = Psychrometrics.PsyCpAirFnW(
                                self.dataDesInletAirHumRat
                            )
                            fanDeltaT = FanCoolLoad / (
                                CpAir
                                * state.dataEnvrn.StdRhoAir
                                * self.dataAirFlowUsedForSizing
                            )
                            self.setDataDesAccountForFanHeat(state, False)
                    self.autoSizedValue -= fanDeltaT
                else:
                    self.autoSizedValue = (
                        self.finalSysSizing[self.curSysNum - 1].CoolSupTemp
                    )
                    var fanDeltaT: Float64 = 0.0
                    if (
                        self.primaryAirSystem[self.curSysNum - 1].supFanPlace
                        == HVAC.FanPlace.DrawThru
                    ):
                        let FanCoolLoad = self.calcFanDesHeatGain(
                            self.dataAirFlowUsedForSizing
                        )
                        if (
                            self.dataDesInletAirHumRat > 0.0
                            and self.dataAirFlowUsedForSizing > 0.0
                        ):
                            let CpAir = Psychrometrics.PsyCpAirFnW(
                                self.dataDesInletAirHumRat
                            )
                            fanDeltaT = FanCoolLoad / (
                                CpAir
                                * state.dataEnvrn.StdRhoAir
                                * self.dataAirFlowUsedForSizing
                            )
                            self.setDataDesAccountForFanHeat(state, False)
                    self.autoSizedValue -= fanDeltaT
                if (
                    self.autoSizedValue < self.dataDesInletWaterTemp
                    and self.dataWaterFlowUsedForSizing > 0.0
                ):
                    var msg = (
                        self.callingRoutine
                        + ":"
                        + " Coil=\""
                        + self.compName
                        + "\", Cooling Coil has leaving air temperature < entering water temperature."
                    )
                    self.addErrorMessage(msg)
                    ShowWarningError(state, msg)
                    msg = String.format(
                        "    Tair,out  =  {:.3f}", self.autoSizedValue
                    )
                    ShowContinueError(state, msg)
                    msg = String.format(
                        "    Twater,in = {:.3f}", self.dataDesInletWaterTemp
                    )
                    ShowContinueError(state, msg)
                    self.autoSizedValue = self.dataDesInletWaterTemp + 0.5
                    msg = "....coil leaving air temperature will be reset to:"
                    ShowContinueError(state, msg)
                    msg = String.format(
                        "    Tair,out = {:.3f}", self.autoSizedValue
                    )
                    ShowContinueError(state, msg)
        if self.overrideSizeString:
            self.sizingString = "Design Outlet Air Temperature [C]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilLvgAirTemp(
                state, self.coilReportNum, self.autoSizedValue
            )
        return self.autoSizedValue

    fn clearState(inout self):
        BaseSizerWithFanHeatInputs.clearState(self)
