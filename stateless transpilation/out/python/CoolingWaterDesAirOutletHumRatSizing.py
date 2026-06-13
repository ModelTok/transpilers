# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: base class from EnergyPlus/Autosizing/Base.hh with methods:
#   checkInitialized(state, errorsFound), preSize(state, value),
#   addErrorMessage(msg), selectSizerOutput(state, errorsFound)
# - EnergyPlusData: state object from EnergyPlus/Data/EnergyPlusData.hh
# - Psychrometrics: module from EnergyPlus/Psychrometrics.hh
# - Util.SameString: function from EnergyPlus/UtilityRoutines.hh
# - ShowWarningError: function from EnergyPlus/UtilityRoutines.hh
# - ShowContinueError: function from EnergyPlus/UtilityRoutines.hh
# - ReportCoilSelection.setCoilLvgAirHumRat: function from EnergyPlus/CoilSelectionReporter

from EnergyPlus.Autosizing.Base import BaseSizer
from EnergyPlus import Psychrometrics, Util, UtilityRoutines, ReportCoilSelection


class CoolingWaterDesAirOutletHumRatSizer(BaseSizer):
    def __init__(self):
        super().__init__()
        self.sizingType = "CoolingWaterDesAirOutletHumRatSizing"
        self.sizingString = "Design Outlet Air Humidity Ratio [kgWater/kgDryAir]"

    def size(self, state, original_value, errors_found):
        if not self.checkInitialized(state, errors_found):
            return 0.0
        self.preSize(state, original_value)

        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = original_value
            else:
                if self.termUnitIU:
                    t_dp_in = Psychrometrics.PsyTdpFnWPb(state, self.dataDesInletAirHumRat, state.dataEnvrn.StdBaroPress)
                    if t_dp_in <= self.dataDesInletWaterTemp:
                        self.autoSizedValue = self.dataDesInletAirHumRat
                    else:
                        self.autoSizedValue = min(
                            Psychrometrics.PsyWFnTdbRhPb(state, self.dataDesOutletAirTemp, 0.9, state.dataEnvrn.StdBaroPress),
                            self.dataDesInletAirHumRat
                        )
                else:
                    self.autoSizedValue = self.finalZoneSizing[self.curZoneEqNum].CoolDesHumRat
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = original_value
            else:
                if self.curOASysNum > 0:
                    if self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                        self.autoSizedValue = self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].PrecoolHumRat
                    else:
                        self.autoSizedValue = self.finalSysSizing[self.curSysNum].PrecoolHumRat
                elif self.dataDesOutletAirHumRat > 0.0:
                    self.autoSizedValue = self.dataDesOutletAirHumRat
                else:
                    self.autoSizedValue = self.finalSysSizing[self.curSysNum].CoolSupHumRat

        if self.wasAutoSized:
            if self.autoSizedValue > self.dataDesInletAirHumRat and \
                    (Util.SameString(self.compType, "COIL:COOLING:WATER") or
                     Util.SameString(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY")):
                msg = self.callingRoutine + ":" + " Coil=\"" + self.compName + \
                      "\", Cooling Coil has leaving humidity ratio > entering humidity ratio."
                self.addErrorMessage(msg)
                UtilityRoutines.ShowWarningError(state, msg)
                msg = f"    Wair,in =  {self.dataDesInletAirHumRat:.3E} [kgWater/kgDryAir]"
                self.addErrorMessage(msg)
                UtilityRoutines.ShowContinueError(state, msg)
                msg = f"    Wair,out = {self.autoSizedValue:.3E} [kgWater/kgDryAir]"
                self.addErrorMessage(msg)
                UtilityRoutines.ShowContinueError(state, msg)
                if self.dataDesInletAirHumRat > 0.016:
                    self.autoSizedValue = 0.5 * self.dataDesInletAirHumRat
                else:
                    self.autoSizedValue = self.dataDesInletAirHumRat
                msg = "....coil leaving humidity ratio will be reset to:"
                self.addErrorMessage(msg)
                UtilityRoutines.ShowContinueError(state, msg)
                msg = f"    Wair,out = {self.autoSizedValue:.3E} [kgWater/kgDryAir]"
                self.addErrorMessage(msg)
                UtilityRoutines.ShowContinueError(state, msg)

            des_sat_enth_at_water_in_temp = Psychrometrics.PsyHFnTdbW(
                self.dataDesInletWaterTemp,
                Psychrometrics.PsyWFnTdpPb(state, self.dataDesInletWaterTemp, state.dataEnvrn.StdBaroPress)
            )
            des_hum_rat_at_water_in_temp = Psychrometrics.PsyWFnTdbH(
                state, self.dataDesInletWaterTemp, des_sat_enth_at_water_in_temp, self.callingRoutine
            )
            if self.autoSizedValue < self.dataDesInletAirHumRat and des_hum_rat_at_water_in_temp > self.dataDesInletAirHumRat:
                if self.autoSizedValue < self.dataDesInletAirHumRat and \
                        (Util.SameString(self.compType, "COIL:COOLING:WATER") or
                         Util.SameString(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY")):
                    msg = self.callingRoutine + ":" + " Coil=\"" + self.compName + \
                          "\", Cooling Coil is running dry for sizing and has minimum humidity ratio at saturation for inlet chilled water " \
                          "temperature > design air entering humidity ratio."
                    self.addErrorMessage(msg)
                    UtilityRoutines.ShowWarningError(state, msg)
                    msg = f"    Wair,in =  {self.dataDesInletAirHumRat:.3E} [kgWater/kgDryAir]"
                    self.addErrorMessage(msg)
                    UtilityRoutines.ShowContinueError(state, msg)
                    msg = f"    Wair,out = {self.autoSizedValue:.3E} [kgWater/kgDryAir]"
                    self.addErrorMessage(msg)
                    UtilityRoutines.ShowContinueError(state, msg)
                    msg = f"    Inlet chilled water temperature = {self.dataDesInletWaterTemp:.3f} [C]"
                    self.addErrorMessage(msg)
                    UtilityRoutines.ShowContinueError(state, msg)
                    msg = f"    Minimum humidity ratio at saturation for inlet chilled water temperature = {des_hum_rat_at_water_in_temp:.3E} [kgWater/kgDryAir]"
                    self.addErrorMessage(msg)
                    UtilityRoutines.ShowContinueError(state, msg)
                    self.autoSizedValue = self.dataDesInletAirHumRat
                    msg = "....coil leaving humidity ratio will be reset to:"
                    self.addErrorMessage(msg)
                    UtilityRoutines.ShowContinueError(state, msg)
                    msg = f"    Wair,out = {self.autoSizedValue:.3E} [kgWater/kgDryAir]"
                    self.addErrorMessage(msg)
                    UtilityRoutines.ShowContinueError(state, msg)

        if self.overrideSizeString:
            self.sizingString = "Design Outlet Air Humidity Ratio [kgWater/kgDryAir]"
        self.selectSizerOutput(state, errors_found)
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilLvgAirHumRat(state, self.coilReportNum, self.autoSizedValue)
        return self.autoSizedValue
