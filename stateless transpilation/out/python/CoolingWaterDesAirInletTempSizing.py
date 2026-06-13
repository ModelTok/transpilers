# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

# EXTERNAL DEPS (to wire in glue):
# - BaseSizerWithFanHeatInputs: parent class from EnergyPlus/Autosizing/
# - EnergyPlusData: state object from EnergyPlus/Data/ (state.dataEnvrn with StdRhoAir)
# - Psychrometrics.PsyCpAirFnW: from EnergyPlus/Psychrometrics.hh
# - ReportCoilSelection.setCoilEntAirTemp: from EnergyPlus/ReportCoilSelection.hh
# - HVAC.FanPlace enum and constants


class AutoSizingType:
    CoolingWaterDesAirInletTempSizing = 0


class HVACFanPlace:
    BlowThru = 0


class BaseSizerWithFanHeatInputs:
    def __init__(self):
        self.sizingType = None
        self.sizingString = ""
        self.curZoneEqNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.autoSizedValue = 0.0
        self.termUnitIU = False
        self.zoneEqFanCoil = False
        self.dataFanPlacement = None
        self.dataAirFlowUsedForSizing = 0.0
        self.dataDesInletAirHumRat = 0.0
        self.curSysNum = 0
        self.sizingDesRunThisAirSys = False
        self.curOASysNum = 0
        self.dataDesInletAirTemp = 0.0
        self.dataFlowUsedForSizing = 0.0
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.numPrimaryAirSys = 0
        self.coilReportNum = 0
        self.airloopDOAS = []

    def checkInitialized(self, state, errorsFound):
        return True

    def preSize(self, state, originalValue):
        pass

    def finalZoneSizing(self, idx):
        return {}

    def setCoolCoilInletTempForZoneEqSizing(self, oaFrac, zoneEqSizing, finalZoneSizing):
        return 0.0

    def setOAFracForZoneEqSizing(self, state, massFlow, zoneEqSizing):
        return 0.0

    def zoneEqSizing(self, idx):
        return {}

    def calcFanDesHeatGain(self, airFlow):
        return 0.0

    def outsideAirSys(self, idx):
        class OutsideAirSysObj:
            AirLoopDOASNum = -1
        return OutsideAirSysObj()

    def finalSysSizing(self, idx):
        return {}

    def primaryAirSystem(self, idx):
        class PrimaryAirSystemObj:
            supFanPlace = None
            NumOACoolCoils = 0
        return PrimaryAirSystemObj()

    def selectSizerOutput(self, state, errorsFound):
        pass

    def setDataDesAccountForFanHeat(self, state, value):
        pass

    def clearState(self):
        pass


class Psychrometrics:
    @staticmethod
    def PsyCpAirFnW(humRat):
        return 0.0


class ReportCoilSelection:
    @staticmethod
    def setCoilEntAirTemp(state, value, sysNum, zoneNum):
        pass


class CoolingWaterDesAirInletTempSizer(BaseSizerWithFanHeatInputs):
    def __init__(self):
        super().__init__()
        self.sizingType = AutoSizingType.CoolingWaterDesAirInletTempSizing
        self.sizingString = "Design Inlet Air Temperature [C]"

    def size(self, state, originalValue, errorsFound):
        if not self.checkInitialized(state, errorsFound):
            return 0.0

        self.preSize(state, originalValue)

        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitIU:
                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).get('ZoneTempAtCoolPeak', 0.0)
                elif self.zoneEqFanCoil:
                    desMassFlow = self.finalZoneSizing(self.curZoneEqNum).get('DesCoolMassFlow', 0.0)
                    self.autoSizedValue = self.setCoolCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, desMassFlow, self.zoneEqSizing(self.curZoneEqNum)),
                        self.zoneEqSizing(self.curZoneEqNum),
                        self.finalZoneSizing(self.curZoneEqNum)
                    )
                else:
                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).get('DesCoolCoilInTemp', 0.0)

                fanDeltaT = 0.0
                if self.dataFanPlacement == HVACFanPlace.BlowThru:
                    FanCoolLoad = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                    if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                        CpAir = Psychrometrics.PsyCpAirFnW(self.dataDesInletAirHumRat)
                        fanDeltaT = FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing)

                self.autoSizedValue += fanDeltaT

        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.curOASysNum > 0:
                    if self.outsideAirSys(self.curOASysNum).AirLoopDOASNum > -1:
                        self.autoSizedValue = self.airloopDOAS[self.outsideAirSys(self.curOASysNum).AirLoopDOASNum].get('SizingCoolOATemp', 0.0)
                    else:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).get('OutTempAtCoolPeak', 0.0)
                else:
                    if self.primaryAirSystem(self.curSysNum).NumOACoolCoils == 0:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).get('MixTempAtCoolPeak', 0.0)
                    elif self.dataDesInletAirTemp > 0.0:
                        self.autoSizedValue = self.dataDesInletAirTemp
                    else:
                        OutAirFrac = 1.0
                        if self.dataFlowUsedForSizing > 0.0:
                            OutAirFrac = self.finalSysSizing(self.curSysNum).get('DesOutAirVolFlow', 0.0) / self.dataFlowUsedForSizing

                        OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                        self.autoSizedValue = (OutAirFrac * self.finalSysSizing(self.curSysNum).get('PrecoolTemp', 0.0) +
                                             (1.0 - OutAirFrac) * self.finalSysSizing(self.curSysNum).get('RetTempAtCoolPeak', 0.0))

                    fanDeltaT = 0.0
                    if self.primaryAirSystem(self.curSysNum).supFanPlace == HVACFanPlace.BlowThru:
                        FanCoolLoad = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                        if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                            CpAir = Psychrometrics.PsyCpAirFnW(self.dataDesInletAirHumRat)
                            fanDeltaT = FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing)
                            self.setDataDesAccountForFanHeat(state, False)

                    self.autoSizedValue += fanDeltaT

        if self.overrideSizeString:
            self.sizingString = "Design Inlet Air Temperature [C]"

        self.selectSizerOutput(state, errorsFound)

        if self.isCoilReportObject:
            if self.curSysNum <= self.numPrimaryAirSys:
                ReportCoilSelection.setCoilEntAirTemp(state, self.autoSizedValue, self.curSysNum, self.curZoneEqNum)

        return self.autoSizedValue

    def clearState(self):
        super().clearState()
