from Base import BaseSizer
from Data.BaseData import EnergyPlusData
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import dataEnvrn
from Psychrometrics import PsyTdpFnWPb, PsyWFnTdbRhPb, PsyHFnTdbW, PsyWFnTdpPb, PsyWFnTdbH
from UtilityRoutines import SameString, ShowWarningError, ShowContinueError
from ReportCoilSelection import ReportCoilSelection
from Data.BaseData import AutoSizingType
struct CoolingWaterDesAirOutletHumRatSizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.CoolingWaterDesAirOutletHumRatSizing
        self.sizingString = "Design Outlet Air Humidity Ratio [kgWater/kgDryAir]"
    def __del__(inout self):

    def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitIU:
                    var TDpIn: Float64 = PsyTdpFnWPb(state, self.dataDesInletAirHumRat, state.dataEnvrn.StdBaroPress)
                    if TDpIn <= self.dataDesInletWaterTemp:
                        self.autoSizedValue = self.dataDesInletAirHumRat
                    else:
                        self.autoSizedValue = min(PsyWFnTdbRhPb(state, self.dataDesOutletAirTemp, 0.9, state.dataEnvrn.StdBaroPress),
                                                   self.dataDesInletAirHumRat)
                else:
                    self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).CoolDesHumRat
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.curOASysNum > 0: # coil is in OA stream
                    if self.outsideAirSys(self.curOASysNum).AirLoopDOASNum > -1:
                        self.autoSizedValue = self.airloopDOAS[self.outsideAirSys(self.curOASysNum).AirLoopDOASNum].PrecoolHumRat
                    else:
                        self.autoSizedValue = self.finalSysSizing(self.curSysNum).PrecoolHumRat
                elif self.dataDesOutletAirHumRat > 0.0:
                    self.autoSizedValue = self.dataDesOutletAirHumRat
                else:
                    self.autoSizedValue = self.finalSysSizing(self.curSysNum).CoolSupHumRat
        if self.wasAutoSized:
            if self.autoSizedValue > self.dataDesInletAirHumRat and \
                (SameString(self.compType, "COIL:COOLING:WATER") or SameString(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY")):
                var msg: String = self.callingRoutine + ":" + " Coil=\"" + self.compName + "\", Cooling Coil has leaving humidity ratio > entering humidity ratio."
                self.addErrorMessage(msg)
                ShowWarningError(state, msg)
                msg = String.format("    Wair,in =  {:.3E} [kgWater/kgDryAir]", self.dataDesInletAirHumRat)
                self.addErrorMessage(msg)
                ShowContinueError(state, msg)
                msg = String.format("    Wair,out = {:.3E} [kgWater/kgDryAir]", self.autoSizedValue)
                self.addErrorMessage(msg)
                ShowContinueError(state, msg)
                if self.dataDesInletAirHumRat > 0.016:
                    self.autoSizedValue = 0.5 * self.dataDesInletAirHumRat
                else:
                    self.autoSizedValue = self.dataDesInletAirHumRat
                msg = "....coil leaving humidity ratio will be reset to:"
                self.addErrorMessage(msg)
                ShowContinueError(state, msg)
                msg = String.format("    Wair,out = {:.3E} [kgWater/kgDryAir]", self.autoSizedValue)
                self.addErrorMessage(msg)
                ShowContinueError(state, msg)
            var desSatEnthAtWaterInTemp: Float64 = PsyHFnTdbW(
                self.dataDesInletWaterTemp, PsyWFnTdpPb(state, self.dataDesInletWaterTemp, state.dataEnvrn.StdBaroPress))
            var desHumRatAtWaterInTemp: Float64 = PsyWFnTdbH(state, self.dataDesInletWaterTemp, desSatEnthAtWaterInTemp, self.callingRoutine)
            if self.autoSizedValue < self.dataDesInletAirHumRat and desHumRatAtWaterInTemp > self.dataDesInletAirHumRat:
                if self.autoSizedValue < self.dataDesInletAirHumRat and \
                    (SameString(self.compType, "COIL:COOLING:WATER") or SameString(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY")):
                    var msg: String = self.callingRoutine + ":" + " Coil=\"" + self.compName + \
                                      "\", Cooling Coil is running dry for sizing and has minimum humidity ratio at saturation for inlet chilled water " \
                                      "temperature > design air entering humidity ratio."
                    self.addErrorMessage(msg)
                    ShowWarningError(state, msg)
                    msg = String.format("    Wair,in =  {:.3E} [kgWater/kgDryAir]", self.dataDesInletAirHumRat)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("    Wair,out = {:.3E} [kgWater/kgDryAir]", self.autoSizedValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("    Inlet chilled water temperature = {:.3f} [C]", self.dataDesInletWaterTemp)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("    Minimum humidity ratio at saturation for inlet chilled water temperature = {:.3E} [kgWater/kgDryAir]",
                                        desHumRatAtWaterInTemp)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    self.autoSizedValue = self.dataDesInletAirHumRat
                    msg = "....coil leaving humidity ratio will be reset to:"
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    msg = String.format("    Wair,out = {:.3E} [kgWater/kgDryAir]", self.autoSizedValue)
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
        if self.overrideSizeString:
            self.sizingString = "Design Outlet Air Humidity Ratio [kgWater/kgDryAir]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilLvgAirHumRat(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue