from Base import BaseSizer
from ...DataHVACGlobals import HVAC
struct HeatingAirflowUASizer(
    BaseSizer
):
    def __init__(self):
        self.sizingType = AutoSizingType.HeatingAirflowUASizing
        self.sizingString = "Heating Coil Airflow for UA"
    def initializeForSingleDuctZoneTerminal(
        self,
        state: EnergyPlusData,
        elevation: Float64,
        mainFlowRate: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.curZoneEqNum = 1
        self.termUnitSingDuct = True
        self.curTermUnitSizingNum = 1
        self.termUnitSizing.allocate(1)
        self.termUnitSizing[0].AirVolFlow = mainFlowRate
    def initializeForZoneInductionUnit(
        self,
        state: EnergyPlusData,
        elevation: Float64,
        mainFlowRate: Float64,
        reheatMultiplier: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.curZoneEqNum = 1
        self.termUnitIU = True
        self.termUnitPIU = True // probably don't need to set both, but whatever
        self.curTermUnitSizingNum = 1
        self.termUnitSizing.allocate(1)
        self.termUnitSizing[0].AirVolFlow = mainFlowRate
        self.termUnitSizing[0].ReheatAirFlowMult = reheatMultiplier
    def initializeForZoneFanCoil(
        self,
        state: EnergyPlusData,
        elevation: Float64,
        designHeatVolumeFlowRate: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.zoneEqFanCoil = True
        self.curZoneEqNum = 1
        self.finalZoneSizing.allocate(1)
        self.finalZoneSizing[0].DesHeatVolFlow = designHeatVolumeFlowRate
    def initializeForSystemOutdoorAir(
        self,
        state: EnergyPlusData,
        elevation: Float64,
        overallSystemMassFlowRate: Float64,
        DOAS: Bool,
    ):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
        self.curOASysNum = 1
        if DOAS:
            self.outsideAirSys[0].AirLoopDOASNum = 0 // the DOAS structure is a zero-based vector, w00t!
            self.airloopDOAS.emplace_back()
            self.airloopDOAS[0].SizingMassFlow = overallSystemMassFlowRate
        else:
            self.finalSysSizing.allocate(1)
            self.finalSysSizing[0].DesOutAirVolFlow = 0.0 // TODO: what do I do here?
            self.autoSizedValue = self.finalSysSizing[self.curSysNum].DesOutAirVolFlow
    def initializeForSystemMainDuct(
        self,
        state: EnergyPlusData,
        elevation: Float64,
        overallSystemVolFlow: Float64,
        minFlowRateRatio: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
        self.curDuctType = HVAC.AirDuctType.Main
        self.finalSysSizing.allocate(1)
        self.finalSysSizing[0].SysAirMinFlowRat = minFlowRateRatio
        self.finalSysSizing[0].DesMainVolFlow = overallSystemVolFlow
    def initializeForSystemCoolingDuct(
        self,
        state: EnergyPlusData,
        elevation: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
    def initializeForSystemHeatingDuct(
        self,
        state: EnergyPlusData,
        elevation: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
    def initializeForSystemOtherDuct(
        self,
        state: EnergyPlusData,
        elevation: Float64,
    ):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
    def size(
        self,
        state: EnergyPlusData,
        _originalValue: Float64,
        errorsFound: Bool,
    ) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, _originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = _originalValue
            else:
                if self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.stdRhoAir * self.termUnitSizing[self.curTermUnitSizingNum].AirVolFlow
                elif (self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = (
                        self.stdRhoAir
                        * self.termUnitSizing[self.curTermUnitSizingNum].AirVolFlow
                        * self.termUnitSizing[self.curTermUnitSizingNum].ReheatAirFlowMult
                    )
                elif self.zoneEqFanCoil:
                    self.autoSizedValue = self.stdRhoAir * self.finalZoneSizing[self.curZoneEqNum].DesHeatVolFlow
                elif self.otherEqType:
                    if self.zoneEqSizing[self.curZoneEqNum].SystemAirFlow:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum].AirVolFlow * self.stdRhoAir
                    elif self.zoneEqSizing[self.curZoneEqNum].HeatingAirFlow:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum].HeatingAirVolFlow * self.stdRhoAir
                    else:
                        self.autoSizedValue = self.finalZoneSizing[self.curZoneEqNum].DesHeatMassFlow
                else:
                    self.errorType = AutoSizingResultType.ErrorType1
                    errorsFound = True
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = _originalValue
            else:
                if self.curOASysNum > 0:
                    if self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                        self.autoSizedValue = (
                            self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].SizingMassFlow / self.stdRhoAir
                        )
                    else:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum].DesOutAirVolFlow
                else:
                    if self.curDuctType == HVAC.AirDuctType.Main:
                        if self.finalSysSizing[self.curSysNum].SysAirMinFlowRat > 0.0:
                            self.autoSizedValue = (
                                self.finalSysSizing[self.curSysNum].SysAirMinFlowRat
                                * self.finalSysSizing[self.curSysNum].DesMainVolFlow
                            )
                        else:
                            self.autoSizedValue = self.finalSysSizing[self.curSysNum].DesMainVolFlow
                    elif self.curDuctType == HVAC.AirDuctType.Cooling:
                        if self.finalSysSizing[self.curSysNum].SysAirMinFlowRat > 0.0:
                            self.autoSizedValue = (
                                self.finalSysSizing[self.curSysNum].SysAirMinFlowRat
                                * self.finalSysSizing[self.curSysNum].DesCoolVolFlow
                            )
                        else:
                            self.autoSizedValue = self.finalSysSizing[self.curSysNum].DesCoolVolFlow
                    elif self.curDuctType == HVAC.AirDuctType.Heating:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum].DesHeatVolFlow
                    else:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum].DesMainVolFlow
                self.autoSizedValue *= self.stdRhoAir
        if self.autoSizedValue < HVAC.SmallAirVolFlow:
            self.addErrorMessage("Autosized value was zero or less than zero")
            self.autoSizedValue = 0.0
        if self.overrideSizeString:
            self.sizingString = "Heating Coil Airflow for UA [m3/s]"
        self.selectSizerOutput(state, errorsFound)
        return self.autoSizedValue