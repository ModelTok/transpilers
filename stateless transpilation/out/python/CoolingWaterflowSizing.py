# EXTERNAL DEPS (to wire in glue):
# - BaseSizerWithFanHeatInputs: base class from EnergyPlus.Autosizing.BaseSizerWithFanHeatInputs
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData
# - Psychrometrics.PsyHFnTdbW: from EnergyPlus.Psychrometrics
# - HVAC.SmallLoad, HVAC.CoilType: from EnergyPlus.DataHVACGlobals
# - Constant.CWInitConvTemp: from EnergyPlus constant definitions
# - ReportCoilSelection: (setCoilWaterFlowPltSizNum, setCoilWaterDeltaT, setCoilEntWaterTemp, setCoilLvgWaterTemp) from EnergyPlus.ReportCoilSelection
# - ShowSevereError: from EnergyPlus error reporting
# - BaseSizerWithFanHeatInputs.calcFanDesHeatGain: static method

from typing import Any, TYPE_CHECKING

if TYPE_CHECKING:
    from EnergyPlus.Data.EnergyPlusData import EnergyPlusData


class CoolingWaterflowSizer:
    """
    Autosizer for cooling water flow rate.
    Inherits from BaseSizerWithFanHeatInputs and must be wired to external base class.
    """
    
    def __init__(self):
        self.sizingType = "CoolingWaterflowSizing"
        self.sizingString = "Design Water Flow Rate [m3/s]"
        # Base class members (initialized by parent)
        self.dataWaterCoilSizCoolDeltaT = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.dataConstantUsedForSizing = 0.0
        self.curZoneEqNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.termUnitIU = False
        self.curTermUnitSizingNum = 0
        self.termUnitSizing = None
        self.zoneEqFanCoil = False
        self.zoneEqUnitVent = False
        self.zoneEqVentedSlab = False
        self.zoneEqSizing = None
        self.dataWaterLoopNum = 0
        self.curSysNum = 0
        self.sizingDesRunThisAirSys = False
        self.curOASysNum = 0
        self.dataCapacityUsedForSizing = 0.0
        self.overrideSizeString = False
        self.coilType = None
        self.autoSizedValue = 0.0
        self.isCoilReportObject = False
        self.coilReportNum = 0
        self.dataPltSizCoolNum = 0
        self.dataDesInletWaterTemp = 0.0
        self.compName = ""
        self.compType = ""
        self.finalZoneSizing = None
        self.finalSysSizing = None
        self.callingRoutine = ""
        self.errorType = None
    
    def size(self, state: 'EnergyPlusData', original_value: float, errors_found: list) -> float:
        """
        Size cooling water flow rate based on design conditions.
        """
        # Import here to avoid circular deps and match external interface
        from EnergyPlus.Psychrometrics import PsyHFnTdbW
        from EnergyPlus.DataHVACGlobals import SmallLoad, CoilType
        from EnergyPlus.Autosizing.BaseSizerWithFanHeatInputs import BaseSizerWithFanHeatInputs
        from EnergyPlus.ReportCoilSelection import (
            setCoilWaterFlowPltSizNum, setCoilWaterDeltaT, 
            setCoilEntWaterTemp, setCoilLvgWaterTemp
        )
        from EnergyPlus.error import ShowSevereError
        
        CWInitConvTemp = 5.0
        
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        
        coil_des_water_delta_t = self.dataWaterCoilSizCoolDeltaT
        
        if self.dataFractionUsedForSizing > 0.0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = original_value
                else:
                    if self.termUnitIU and (self.curTermUnitSizingNum > 0):
                        self.autoSizedValue = self.termUnitSizing[self.curTermUnitSizingNum - 1].MaxCWVolFlow
                    elif self.zoneEqFanCoil or self.zoneEqUnitVent or self.zoneEqVentedSlab:
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].MaxCWVolFlow
                    else:
                        coil_in_temp = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolCoilInTemp
                        coil_out_temp = self.finalZoneSizing[self.curZoneEqNum - 1].CoolDesTemp
                        coil_out_hum_rat = self.finalZoneSizing[self.curZoneEqNum - 1].CoolDesHumRat
                        coil_in_hum_rat = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolCoilInHumRat
                        
                        des_coil_load = (
                            self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolMassFlow *
                            (PsyHFnTdbW(coil_in_temp, coil_in_hum_rat) - 
                             PsyHFnTdbW(coil_out_temp, coil_out_hum_rat))
                        )
                        
                        des_vol_flow = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolMassFlow / state.dataEnvrn.StdRhoAir
                        
                        des_coil_load += BaseSizerWithFanHeatInputs.calcFanDesHeatGain(des_vol_flow)
                        
                        if des_coil_load >= SmallLoad:
                            if (self.dataWaterLoopNum > 0 and 
                                self.dataWaterLoopNum <= len(state.dataPlnt.PlantLoop) and
                                self.dataWaterCoilSizCoolDeltaT > 0.0):
                                
                                cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getSpecificHeat(
                                    state, CWInitConvTemp, self.callingRoutine)
                                rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getDensity(
                                    state, CWInitConvTemp, self.callingRoutine)
                                self.autoSizedValue = des_coil_load / (coil_des_water_delta_t * cp * rho)
                            else:
                                self.autoSizedValue = 0.0
                                msg = (f"Developer Error: For autosizing of {self.compType} {self.compName}, "
                                      "certain inputs are required. Add PlantLoop, Plant loop number, "
                                      "coil capacity and/or Water Coil water delta T.")
                                self.errorType = "ErrorType1"
                                self.addErrorMessage(msg)
                                ShowSevereError(state, msg)
                        else:
                            self.autoSizedValue = 0.0
            
            elif self.curSysNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                    self.autoSizedValue = original_value
                else:
                    if self.curOASysNum > 0:
                        coil_des_water_delta_t *= 0.5
                    
                    if self.dataCapacityUsedForSizing >= SmallLoad:
                        if (self.dataWaterLoopNum > 0 and 
                            self.dataWaterLoopNum <= len(state.dataPlnt.PlantLoop) and
                            coil_des_water_delta_t > 0.0):
                            
                            cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getSpecificHeat(
                                state, CWInitConvTemp, self.callingRoutine)
                            rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum - 1].glycol.getDensity(
                                state, CWInitConvTemp, self.callingRoutine)
                            self.autoSizedValue = self.dataCapacityUsedForSizing / (coil_des_water_delta_t * cp * rho)
                        else:
                            self.autoSizedValue = 0.0
                            msg = (f"Developer Error: For autosizing of {self.compType} {self.compName}, "
                                  "certain inputs are required. Add PlantLoop, Plant loop number, "
                                  "coil capacity and/or Water Coil water delta T.")
                            self.errorType = "ErrorType1"
                            self.addErrorMessage(msg)
                            ShowSevereError(state, msg)
                    else:
                        self.autoSizedValue = 0.0
        
        if self.overrideSizeString:
            if self.coilType == CoilType.CoolingWaterDetailed:
                self.sizingString = "Maximum Water Flow Rate [m3/s]"
            else:
                self.sizingString = "Design Water Flow Rate [m3/s]"
        
        self.selectSizerOutput(state, errors_found)
        
        if self.isCoilReportObject:
            setCoilWaterFlowPltSizNum(
                state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized, 
                self.dataPltSizCoolNum, self.dataWaterLoopNum)
            setCoilWaterDeltaT(state, self.coilReportNum, coil_des_water_delta_t)
            
            if self.dataDesInletWaterTemp > 0.0:
                setCoilEntWaterTemp(state, self.coilReportNum, self.dataDesInletWaterTemp)
                setCoilLvgWaterTemp(state, self.coilReportNum, self.dataDesInletWaterTemp + coil_des_water_delta_t)
            else:
                setCoilEntWaterTemp(state, self.coilReportNum, CWInitConvTemp)
                setCoilLvgWaterTemp(state, self.coilReportNum, CWInitConvTemp + coil_des_water_delta_t)
            
            self.calcCoilWaterFlowRates(
                state,
                self.compName,
                self.compType,
                self.autoSizedValue,
                self.dataWaterLoopNum,
                self.curZoneEqNum,
                self.curSysNum,
                self.curOASysNum,
                self.finalZoneSizing,
                self.finalSysSizing)
        
        return self.autoSizedValue
    
    def clear_state(self):
        """Clear state for next sizing."""
        self.clearState()
    
    def checkInitialized(self, state: 'EnergyPlusData', errors_found: list) -> bool:
        """Check if sizer is initialized. Override in subclass or wire to base."""
        raise NotImplementedError("Must be implemented by BaseSizerWithFanHeatInputs")
    
    def preSize(self, state: 'EnergyPlusData', original_value: float):
        """Pre-sizing setup. Override in subclass or wire to base."""
        raise NotImplementedError("Must be implemented by BaseSizerWithFanHeatInputs")
    
    def selectSizerOutput(self, state: 'EnergyPlusData', errors_found: list):
        """Select and apply sizing output. Override in subclass or wire to base."""
        raise NotImplementedError("Must be implemented by BaseSizerWithFanHeatInputs")
    
    def addErrorMessage(self, msg: str):
        """Add error message to list. Override in subclass or wire to base."""
        raise NotImplementedError("Must be implemented by BaseSizerWithFanHeatInputs")
    
    def calcCoilWaterFlowRates(self, state: 'EnergyPlusData', comp_name: str, comp_type: str,
                               auto_sized_value: float, water_loop_num: int, cur_zone_eq_num: int,
                               cur_sys_num: int, cur_oa_sys_num: int, final_zone_sizing: Any,
                               final_sys_sizing: Any):
        """Calculate coil water flow rates. Override in subclass or wire to base."""
        raise NotImplementedError("Must be implemented by BaseSizerWithFanHeatInputs")
    
    def clearState(self):
        """Clear internal state. Override in subclass or wire to base."""
        raise NotImplementedError("Must be implemented by BaseSizerWithFanHeatInputs")
