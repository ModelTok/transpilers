# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

# EXTERNAL DEPS (to wire in glue):
# - BaseSizerWithFanHeatInputs: parent struct from EnergyPlus/Autosizing/
# - EnergyPlusData: state object from EnergyPlus/Data/ (state.dataEnvrn with StdRhoAir)
# - Psychrometrics.PsyCpAirFnW: from EnergyPlus/Psychrometrics.hh
# - ReportCoilSelection.setCoilEntAirTemp: from EnergyPlus/ReportCoilSelection.hh
# - HVAC.FanPlace enum and constants

from math import min, max


struct AutoSizingType:
    alias CoolingWaterDesAirInletTempSizing = 0


struct HVACFanPlace:
    alias BlowThru = 0


struct OutsideAirSysObj:
    var AirLoopDOASNum: Int32

    fn __init__(inout self):
        self.AirLoopDOASNum = -1


struct PrimaryAirSystemObj:
    var supFanPlace: Int32
    var NumOACoolCoils: Int32

    fn __init__(inout self):
        self.supFanPlace = 0
        self.NumOACoolCoils = 0


struct ZoneSizingData:
    var ZoneTempAtCoolPeak: Float64
    var DesCoolMassFlow: Float64
    var DesCoolCoilInTemp: Float64

    fn __init__(inout self):
        self.ZoneTempAtCoolPeak = 0.0
        self.DesCoolMassFlow = 0.0
        self.DesCoolCoilInTemp = 0.0


struct ZoneEqSizingData:
    fn __init__(inout self):
        pass


struct SysSizingData:
    var OutTempAtCoolPeak: Float64
    var MixTempAtCoolPeak: Float64
    var DesOutAirVolFlow: Float64
    var PrecoolTemp: Float64
    var RetTempAtCoolPeak: Float64

    fn __init__(inout self):
        self.OutTempAtCoolPeak = 0.0
        self.MixTempAtCoolPeak = 0.0
        self.DesOutAirVolFlow = 0.0
        self.PrecoolTemp = 0.0
        self.RetTempAtCoolPeak = 0.0


struct AirloopDOASObj:
    var SizingCoolOATemp: Float64

    fn __init__(inout self):
        self.SizingCoolOATemp = 0.0


struct BaseSizerWithFanHeatInputs:
    var sizingType: Int32
    var sizingString: String
    var curZoneEqNum: Int32
    var wasAutoSized: Bool
    var sizingDesRunThisZone: Bool
    var autoSizedValue: Float64
    var termUnitIU: Bool
    var zoneEqFanCoil: Bool
    var dataFanPlacement: Int32
    var dataAirFlowUsedForSizing: Float64
    var dataDesInletAirHumRat: Float64
    var curSysNum: Int32
    var sizingDesRunThisAirSys: Bool
    var curOASysNum: Int32
    var dataDesInletAirTemp: Float64
    var dataFlowUsedForSizing: Float64
    var overrideSizeString: Bool
    var isCoilReportObject: Bool
    var numPrimaryAirSys: Int32
    var coilReportNum: Int32

    fn __init__(inout self):
        self.sizingType = 0
        self.sizingString = ""
        self.curZoneEqNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.autoSizedValue = 0.0
        self.termUnitIU = False
        self.zoneEqFanCoil = False
        self.dataFanPlacement = 0
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

    fn checkInitialized(inout self, state: AnyType, inout errorsFound: Bool) -> Bool:
        return True

    fn preSize(inout self, state: AnyType, originalValue: Float64):
        pass

    fn finalZoneSizing(inout self, idx: Int32) -> ZoneSizingData:
        var result = ZoneSizingData()
        return result

    fn setCoolCoilInletTempForZoneEqSizing(inout self, oaFrac: Float64, zoneEqSizing: ZoneEqSizingData, finalZoneSizing: ZoneSizingData) -> Float64:
        return 0.0

    fn setOAFracForZoneEqSizing(inout self, state: AnyType, massFlow: Float64, zoneEqSizing: ZoneEqSizingData) -> Float64:
        return 0.0

    fn zoneEqSizing(inout self, idx: Int32) -> ZoneEqSizingData:
        var result = ZoneEqSizingData()
        return result

    fn calcFanDesHeatGain(inout self, airFlow: Float64) -> Float64:
        return 0.0

    fn outsideAirSys(inout self, idx: Int32) -> OutsideAirSysObj:
        var result = OutsideAirSysObj()
        return result

    fn finalSysSizing(inout self, idx: Int32) -> SysSizingData:
        var result = SysSizingData()
        return result

    fn primaryAirSystem(inout self, idx: Int32) -> PrimaryAirSystemObj:
        var result = PrimaryAirSystemObj()
        return result

    fn selectSizerOutput(inout self, state: AnyType, inout errorsFound: Bool):
        pass

    fn setDataDesAccountForFanHeat(inout self, state: AnyType, value: Bool):
        pass

    fn clearState(inout self):
        pass


struct CoolingWaterDesAirInletTempSizer(BaseSizerWithFanHeatInputs):
    fn __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterDesAirInletTempSizing
        self.sizingString = "Design Inlet Air Temperature [C]"

    fn size(inout self, state: AnyType, originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0

        self.preSize(state, originalValue)

        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitIU:
                    var zoneSizing = self.finalZoneSizing(self.curZoneEqNum)
                    self.autoSizedValue = zoneSizing.ZoneTempAtCoolPeak
                elif self.zoneEqFanCoil:
                    var zoneSizing = self.finalZoneSizing(self.curZoneEqNum)
                    var desMassFlow = zoneSizing.DesCoolMassFlow
                    var zoneEqSizingData = self.zoneEqSizing(self.curZoneEqNum)
                    var oaFrac = self.setOAFracForZoneEqSizing(state, desMassFlow, zoneEqSizingData)
                    self.autoSizedValue = self.setCoolCoilInletTempForZoneEqSizing(
                        oaFrac,
                        zoneEqSizingData,
                        zoneSizing
                    )
                else:
                    var zoneSizing = self.finalZoneSizing(self.curZoneEqNum)
                    self.autoSizedValue = zoneSizing.DesCoolCoilInTemp

                var fanDeltaT: Float64 = 0.0
                if self.dataFanPlacement == HVACFanPlace.BlowThru:
                    var FanCoolLoad = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                    if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                        var CpAir = Psychrometrics.PsyCpAirFnW(self.dataDesInletAirHumRat)
                        var stdRhoAir = self._getStdRhoAir(state)
                        fanDeltaT = FanCoolLoad / (CpAir * stdRhoAir * self.dataAirFlowUsedForSizing)

                self.autoSizedValue += fanDeltaT

        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.curOASysNum > 0:
                    var outsideAirSysObj = self.outsideAirSys(self.curOASysNum)
                    if outsideAirSysObj.AirLoopDOASNum > -1:
                        self.autoSizedValue = self._getAirloopDOASSizingCoolOATemp(outsideAirSysObj.AirLoopDOASNum)
                    else:
                        var sysSizing = self.finalSysSizing(self.curSysNum)
                        self.autoSizedValue = sysSizing.OutTempAtCoolPeak
                else:
                    var sysSizing = self.finalSysSizing(self.curSysNum)
                    var primaryAirSystemObj = self.primaryAirSystem(self.curSysNum)
                    if primaryAirSystemObj.NumOACoolCoils == 0:
                        self.autoSizedValue = sysSizing.MixTempAtCoolPeak
                    elif self.dataDesInletAirTemp > 0.0:
                        self.autoSizedValue = self.dataDesInletAirTemp
                    else:
                        var OutAirFrac: Float64 = 1.0
                        if self.dataFlowUsedForSizing > 0.0:
                            OutAirFrac = sysSizing.DesOutAirVolFlow / self.dataFlowUsedForSizing

                        OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                        self.autoSizedValue = (OutAirFrac * sysSizing.PrecoolTemp +
                                             (1.0 - OutAirFrac) * sysSizing.RetTempAtCoolPeak)

                    var fanDeltaT: Float64 = 0.0
                    if primaryAirSystemObj.supFanPlace == HVACFanPlace.BlowThru:
                        var FanCoolLoad = self.calcFanDesHeatGain(self.dataAirFlowUsedForSizing)
                        if self.dataDesInletAirHumRat > 0.0 and self.dataAirFlowUsedForSizing > 0.0:
                            var CpAir = Psychrometrics.PsyCpAirFnW(self.dataDesInletAirHumRat)
                            var stdRhoAir = self._getStdRhoAir(state)
                            fanDeltaT = FanCoolLoad / (CpAir * stdRhoAir * self.dataAirFlowUsedForSizing)
                            self.setDataDesAccountForFanHeat(state, False)

                    self.autoSizedValue += fanDeltaT

        if self.overrideSizeString:
            self.sizingString = "Design Inlet Air Temperature [C]"

        self.selectSizerOutput(state, errorsFound)

        if self.isCoilReportObject:
            if self.curSysNum <= self.numPrimaryAirSys:
                ReportCoilSelection.setCoilEntAirTemp(state, self.autoSizedValue, self.curSysNum, self.curZoneEqNum)

        return self.autoSizedValue

    fn _getStdRhoAir(inout self, state: AnyType) -> Float64:
        return 1.2

    fn _getAirloopDOASSizingCoolOATemp(inout self, idx: Int32) -> Float64:
        return 0.0

    fn clearState(inout self):
        BaseSizerWithFanHeatInputs.clearState(self)


struct Psychrometrics:
    @staticmethod
    fn PsyCpAirFnW(humRat: Float64) -> Float64:
        return 0.0


struct ReportCoilSelection:
    @staticmethod
    fn setCoilEntAirTemp(state: AnyType, value: Float64, sysNum: Int32, zoneNum: Int32):
        pass
