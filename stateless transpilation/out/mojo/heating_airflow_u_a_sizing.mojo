# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state container (from EnergyPlus/EnergyPlusData.hh)
# - BaseSizer: parent struct/trait providing method implementations (from EnergyPlus/Autosizing/Base.hh)
#   - Methods: checkInitialized, preSize, selectSizerOutput, addErrorMessage, initializeFromAPI
#   - Fields: sizingType, sizingString, zoneSizingRunDone, curZoneEqNum, termUnitSingDuct, 
#     curTermUnitSizingNum, termUnitSizing, zoneEqFanCoil, finalZoneSizing, curSysNum, curOASysNum,
#     outsideAirSys, airloopDOAS, finalSysSizing, stdRhoAir, wasAutoSized, sizingDesRunThisZone,
#     termUnitPIU, termUnitIU, zoneEqSizing, otherEqType, curDuctType, errorType, autoSizedValue,
#     sizingDesRunThisAirSys, overrideSizeString
# - AutoSizingType: struct with HeatingAirflowUASizing constant (from EnergyPlus/Autosizing/Base.hh)
# - AutoSizingResultType: struct with ErrorType1 constant (from EnergyPlus/Autosizing/Base.hh)
# - HVAC: namespace with AirDuctType struct (Main, Cooling, Heating) and SmallAirVolFlow constant
#   (from EnergyPlus/DataHVACGlobals.hh)


struct HeatingAirflowUASizer(BaseSizer):
    fn __init__(inout self):
        BaseSizer.__init__(self)
        self.sizingType = AutoSizingType.HeatingAirflowUASizing
        self.sizingString = "Heating Coil Airflow for UA"

    fn initializeForSingleDuctZoneTerminal(
        inout self, state: EnergyPlusData, elevation: Float64, mainFlowRate: Float64
    ):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.curZoneEqNum = 1
        self.termUnitSingDuct = True
        self.curTermUnitSizingNum = 1
        self.termUnitSizing = DynamicVector[TermUnitSizingData](1)
        self.termUnitSizing[0] = TermUnitSizingData()
        self.termUnitSizing[0].AirVolFlow = mainFlowRate

    fn initializeForZoneInductionUnit(
        inout self,
        state: EnergyPlusData,
        elevation: Float64,
        mainFlowRate: Float64,
        reheatMultiplier: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.curZoneEqNum = 1
        self.termUnitIU = True
        self.termUnitPIU = True
        self.curTermUnitSizingNum = 1
        self.termUnitSizing = DynamicVector[TermUnitSizingData](1)
        self.termUnitSizing[0] = TermUnitSizingData()
        self.termUnitSizing[0].AirVolFlow = mainFlowRate
        self.termUnitSizing[0].ReheatAirFlowMult = reheatMultiplier

    fn initializeForZoneFanCoil(
        inout self, state: EnergyPlusData, elevation: Float64, designHeatVolumeFlowRate: Float64
    ):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.zoneEqFanCoil = True
        self.curZoneEqNum = 1
        self.finalZoneSizing = DynamicVector[FinalZoneSizingData](1)
        self.finalZoneSizing[0] = FinalZoneSizingData()
        self.finalZoneSizing[0].DesHeatVolFlow = designHeatVolumeFlowRate

    fn initializeForSystemOutdoorAir(
        inout self,
        state: EnergyPlusData,
        elevation: Float64,
        overallSystemMassFlowRate: Float64,
        DOAS: Bool,
    ):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
        self.curOASysNum = 1
        if DOAS:
            self.outsideAirSys[0].AirLoopDOASNum = 0
            var doas_obj = AirloopDOASData()
            doas_obj.SizingMassFlow = overallSystemMassFlowRate
            self.airloopDOAS.push_back(doas_obj)
        else:
            self.finalSysSizing = DynamicVector[FinalSysSizingData](1)
            self.finalSysSizing[0] = FinalSysSizingData()
            self.finalSysSizing[0].DesOutAirVolFlow = 0.0
            self.autoSizedValue = self.finalSysSizing[0].DesOutAirVolFlow

    fn initializeForSystemMainDuct(
        inout self,
        state: EnergyPlusData,
        elevation: Float64,
        overallSystemVolFlow: Float64,
        minFlowRateRatio: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
        self.curDuctType = HVAC.AirDuctType.Main
        self.finalSysSizing = DynamicVector[FinalSysSizingData](1)
        self.finalSysSizing[0] = FinalSysSizingData()
        self.finalSysSizing[0].SysAirMinFlowRat = minFlowRateRatio
        self.finalSysSizing[0].DesMainVolFlow = overallSystemVolFlow

    fn initializeForSystemCoolingDuct(inout self, state: EnergyPlusData, elevation: Float64):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1

    fn initializeForSystemHeatingDuct(inout self, state: EnergyPlusData, elevation: Float64):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1

    fn initializeForSystemOtherDuct(inout self, state: EnergyPlusData, elevation: Float64):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1

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
                if self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = (
                        self.stdRhoAir * self.termUnitSizing[self.curTermUnitSizingNum - 1].AirVolFlow
                    )
                elif (self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = (
                        self.stdRhoAir
                        * self.termUnitSizing[self.curTermUnitSizingNum - 1].AirVolFlow
                        * self.termUnitSizing[self.curTermUnitSizingNum - 1].ReheatAirFlowMult
                    )
                elif self.zoneEqFanCoil:
                    self.autoSizedValue = (
                        self.stdRhoAir * self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatVolFlow
                    )
                elif self.otherEqType:
                    if self.zoneEqSizing[self.curZoneEqNum - 1].SystemAirFlow:
                        self.autoSizedValue = (
                            self.zoneEqSizing[self.curZoneEqNum - 1].AirVolFlow * self.stdRhoAir
                        )
                    elif self.zoneEqSizing[self.curZoneEqNum - 1].HeatingAirFlow:
                        self.autoSizedValue = (
                            self.zoneEqSizing[self.curZoneEqNum - 1].HeatingAirVolFlow * self.stdRhoAir
                        )
                    else:
                        self.autoSizedValue = self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatMassFlow
                else:
                    self.errorType = AutoSizingResultType.ErrorType1
                    errorsFound = True
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.curOASysNum > 0:
                    if self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum > -1:
                        self.autoSizedValue = (
                            self.airloopDOAS[self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum]
                            .SizingMassFlow
                            / self.stdRhoAir
                        )
                    else:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum - 1].DesOutAirVolFlow
                else:
                    if self.curDuctType == HVAC.AirDuctType.Main:
                        if self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat > 0.0:
                            self.autoSizedValue = (
                                self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat
                                * self.finalSysSizing[self.curSysNum - 1].DesMainVolFlow
                            )
                        else:
                            self.autoSizedValue = self.finalSysSizing[self.curSysNum - 1].DesMainVolFlow
                    elif self.curDuctType == HVAC.AirDuctType.Cooling:
                        if self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat > 0.0:
                            self.autoSizedValue = (
                                self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat
                                * self.finalSysSizing[self.curSysNum - 1].DesCoolVolFlow
                            )
                        else:
                            self.autoSizedValue = self.finalSysSizing[self.curSysNum - 1].DesCoolVolFlow
                    elif self.curDuctType == HVAC.AirDuctType.Heating:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum - 1].DesHeatVolFlow
                    else:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum - 1].DesMainVolFlow
                self.autoSizedValue *= self.stdRhoAir
        if self.autoSizedValue < HVAC.SmallAirVolFlow:
            self.addErrorMessage("Autosized value was zero or less than zero")
            self.autoSizedValue = 0.0
        if self.overrideSizeString:
            self.sizingString = "Heating Coil Airflow for UA [m3/s]"
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue
