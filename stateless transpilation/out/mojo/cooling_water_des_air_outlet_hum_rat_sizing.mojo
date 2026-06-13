# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: base struct from EnergyPlus/Autosizing/Base.mojo with methods:
#   checkInitialized(state, errorsFound), preSize(state, value),
#   addErrorMessage(msg), selectSizerOutput(state, errorsFound)
# - EnergyPlusData: state struct from EnergyPlus/Data/EnergyPlusData.mojo
# - Psychrometrics: module from EnergyPlus/Psychrometrics.mojo
# - Util.SameString: function from EnergyPlus/UtilityRoutines.mojo
# - ShowWarningError: function from EnergyPlus/UtilityRoutines.mojo
# - ShowContinueError: function from EnergyPlus/UtilityRoutines.mojo
# - ReportCoilSelection.setCoilLvgAirHumRat: function from EnergyPlus/CoilSelectionReporter.mojo

from EnergyPlus.Autosizing.Base import BaseSizer
from EnergyPlus import Psychrometrics, Util, UtilityRoutines, ReportCoilSelection


struct CoolingWaterDesAirOutletHumRatSizer(BaseSizer):
    var sizingType: String
    var sizingString: String
    
    fn __init__(inout self):
        self.sizingType = "CoolingWaterDesAirOutletHumRatSizing"
        self.sizingString = "Design Outlet Air Humidity Ratio [kgWater/kgDryAir]"
    
    fn size(inout self, state: EnergyPlusData, original_value: Float64, inout errors_found: Bool) -> Float64:
        if not self.checkInitialized(state, errors_found):
            return 0.0
        self.preSize(state, original_value)
        
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = original_value
            else:
                if self.termUnitIU:
                    var t_dp_in = Psychrometrics.PsyTdpFnWPb(state, self.dataDesInletAirHumRat, state.dataEnvrn.StdBaroPress)
                    if t_dp_in <= self.dataDesInletWaterTemp:
                        self.autoSizedValue = self.dataDesInletAirHumRat
                    else:
                        var psy_result = Psychrometrics.PsyWFnTdbRhPb(state, self.dataDesOutletAirTemp, 0.9, state.dataEnvrn.StdBaroPress)
                        self.autoSizedValue = min(psy_result, self.dataDesInletAirHumRat)
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
                var msg = self.callingRoutine + ":" + " Coil=\"" + self.compName + \
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
            
            var tdp_pb = Psychrometrics.PsyWFnTdpPb(state, self.dataDesInletWaterTemp, state.dataEnvrn.StdBaroPress)
            var des_sat_enth_at_water_in_temp = Psychrometrics.PsyHFnTdbW(self.dataDesInletWaterTemp, tdp_pb)
            var des_hum_rat_at_water_in_temp = Psychrometrics.PsyWFnTdbH(
                state, self.dataDesInletWaterTemp, des_sat_enth_at_water_in_temp, self.callingRoutine
            )
            if self.autoSizedValue < self.dataDesInletAirHumRat and des_hum_rat_at_water_in_temp > self.dataDesInletAirHumRat:
                if self.autoSizedValue < self.dataDesInletAirHumRat and \
                        (Util.SameString(self.compType, "COIL:COOLING:WATER") or
                         Util.SameString(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY")):
                    var msg = self.callingRoutine + ":" + " Coil=\"" + self.compName + \
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
