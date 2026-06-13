# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state container (from EnergyPlus/EnergyPlusData.hh)
# - BaseSizer: parent class providing method implementations (from EnergyPlus/Autosizing/Base.hh)
#   - Methods: checkInitialized, preSize, selectSizerOutput, addErrorMessage, initializeFromAPI
#   - Properties: sizingType, sizingString, zoneSizingRunDone, curZoneEqNum, termUnitSingDuct, 
#     curTermUnitSizingNum, termUnitSizing, zoneEqFanCoil, finalZoneSizing, curSysNum, curOASysNum,
#     outsideAirSys, airloopDOAS, finalSysSizing, stdRhoAir, wasAutoSized, sizingDesRunThisZone,
#     termUnitPIU, termUnitIU, zoneEqSizing, otherEqType, curDuctType, errorType, autoSizedValue,
#     sizingDesRunThisAirSys, overrideSizeString
# - AutoSizingType: enum with HeatingAirflowUASizing constant (from EnergyPlus/Autosizing/Base.hh)
# - AutoSizingResultType: enum with ErrorType1 constant (from EnergyPlus/Autosizing/Base.hh)
# - HVAC: namespace with AirDuctType enum (Main, Cooling, Heating) and SmallAirVolFlow constant
#   (from EnergyPlus/DataHVACGlobals.hh)


class HeatingAirflowUASizer(BaseSizer):
    def __init__(self):
        super().__init__()
        self.sizingType = AutoSizingType.HeatingAirflowUASizing
        self.sizingString = "Heating Coil Airflow for UA"

    def initializeForSingleDuctZoneTerminal(self, state, elevation, mainFlowRate):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.curZoneEqNum = 1
        self.termUnitSingDuct = True
        self.curTermUnitSizingNum = 1
        self.termUnitSizing = [None] * 1
        self.termUnitSizing[0] = type('obj', (), {'AirVolFlow': mainFlowRate})()

    def initializeForZoneInductionUnit(self, state, elevation, mainFlowRate, reheatMultiplier):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.curZoneEqNum = 1
        self.termUnitIU = True
        self.termUnitPIU = True
        self.curTermUnitSizingNum = 1
        self.termUnitSizing = [None] * 1
        self.termUnitSizing[0] = type('obj', (), {
            'AirVolFlow': mainFlowRate,
            'ReheatAirFlowMult': reheatMultiplier
        })()

    def initializeForZoneFanCoil(self, state, elevation, designHeatVolumeFlowRate):
        self.initializeFromAPI(state, elevation)
        self.zoneSizingRunDone = True
        self.zoneEqFanCoil = True
        self.curZoneEqNum = 1
        self.finalZoneSizing = [None] * 1
        self.finalZoneSizing[0] = type('obj', (), {'DesHeatVolFlow': designHeatVolumeFlowRate})()

    def initializeForSystemOutdoorAir(self, state, elevation, overallSystemMassFlowRate, DOAS):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
        self.curOASysNum = 1
        if DOAS:
            self.outsideAirSys[0].AirLoopDOASNum = 0
            doas_obj = type('obj', (), {'SizingMassFlow': overallSystemMassFlowRate})()
            if not hasattr(self, 'airloopDOAS'):
                self.airloopDOAS = []
            if len(self.airloopDOAS) == 0:
                self.airloopDOAS.append(doas_obj)
            else:
                self.airloopDOAS[0] = doas_obj
        else:
            self.finalSysSizing = [None] * 1
            self.finalSysSizing[0] = type('obj', (), {'DesOutAirVolFlow': 0.0})()
            self.autoSizedValue = self.finalSysSizing[0].DesOutAirVolFlow

    def initializeForSystemMainDuct(self, state, elevation, overallSystemVolFlow, minFlowRateRatio):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1
        self.curDuctType = HVAC.AirDuctType.Main
        self.finalSysSizing = [None] * 1
        self.finalSysSizing[0] = type('obj', (), {
            'SysAirMinFlowRat': minFlowRateRatio,
            'DesMainVolFlow': overallSystemVolFlow
        })()

    def initializeForSystemCoolingDuct(self, state, elevation):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1

    def initializeForSystemHeatingDuct(self, state, elevation):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1

    def initializeForSystemOtherDuct(self, state, elevation):
        self.initializeFromAPI(state, elevation)
        self.curSysNum = 1

    def size(self, state, originalValue, errorsFound):
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.stdRhoAir * self.termUnitSizing[self.curTermUnitSizingNum - 1].AirVolFlow
                elif ((self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0)):
                    self.autoSizedValue = (self.stdRhoAir * self.termUnitSizing[self.curTermUnitSizingNum - 1].AirVolFlow *
                                          self.termUnitSizing[self.curTermUnitSizingNum - 1].ReheatAirFlowMult)
                elif self.zoneEqFanCoil:
                    self.autoSizedValue = self.stdRhoAir * self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatVolFlow
                elif self.otherEqType:
                    if self.zoneEqSizing[self.curZoneEqNum - 1].SystemAirFlow:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].AirVolFlow * self.stdRhoAir
                    elif self.zoneEqSizing[self.curZoneEqNum - 1].HeatingAirFlow:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].HeatingAirVolFlow * self.stdRhoAir
                    else:
                        self.autoSizedValue = self.finalZoneSizing[self.curZoneEqNum - 1].DesHeatMassFlow
                else:
                    self.errorType = AutoSizingResultType.ErrorType1
                    errorsFound[0] = True
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.curOASysNum > 0:
                    if self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum > -1:
                        self.autoSizedValue = (self.airloopDOAS[self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum].SizingMassFlow /
                                              self.stdRhoAir)
                    else:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum - 1].DesOutAirVolFlow
                else:
                    if self.curDuctType == HVAC.AirDuctType.Main:
                        if self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat > 0.0:
                            self.autoSizedValue = (self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat *
                                                  self.finalSysSizing[self.curSysNum - 1].DesMainVolFlow)
                        else:
                            self.autoSizedValue = self.finalSysSizing[self.curSysNum - 1].DesMainVolFlow
                    elif self.curDuctType == HVAC.AirDuctType.Cooling:
                        if self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat > 0.0:
                            self.autoSizedValue = (self.finalSysSizing[self.curSysNum - 1].SysAirMinFlowRat *
                                                  self.finalSysSizing[self.curSysNum - 1].DesCoolVolFlow)
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
