# EXTERNAL DEPS (to wire in glue):
# - BaseSizerWithFanHeatInputs: base struct from EnergyPlus.Autosizing.BaseSizerWithFanHeatInputs
# - EnergyPlusData: state struct from EnergyPlus.Data.EnergyPlusData
# - Psychrometrics.PsyHFnTdbW: from EnergyPlus.Psychrometrics
# - HVAC.SmallLoad, HVAC.CoilType: from EnergyPlus.DataHVACGlobals
# - Constant.CWInitConvTemp: from EnergyPlus constant definitions
# - ReportCoilSelection: (setCoilWaterFlowPltSizNum, setCoilWaterDeltaT, setCoilEntWaterTemp, setCoilLvgWaterTemp) from EnergyPlus.ReportCoilSelection
# - ShowSevereError: from EnergyPlus error reporting
# - BaseSizerWithFanHeatInputs.calcFanDesHeatGain: static fn

from utils.inlinable import always_inline
from math import max as math_max


alias CWInitConvTemp = 5.0
alias SmallLoad = 0.0


struct CoolingWaterflowSizer:
    """
    Autosizer for cooling water flow rate.
    Inherits from BaseSizerWithFanHeatInputs and must be wired to external base.
    """
    var sizingType: String
    var sizingString: String
    var dataWaterCoilSizCoolDeltaT: Float64
    var dataFractionUsedForSizing: Float64
    var dataConstantUsedForSizing: Float64
    var curZoneEqNum: Int32
    var wasAutoSized: Bool
    var sizingDesRunThisZone: Bool
    var termUnitIU: Bool
    var curTermUnitSizingNum: Int32
    var termUnitSizing: UnsafePointer[UInt8]
    var zoneEqFanCoil: Bool
    var zoneEqUnitVent: Bool
    var zoneEqVentedSlab: Bool
    var zoneEqSizing: UnsafePointer[UInt8]
    var dataWaterLoopNum: Int32
    var curSysNum: Int32
    var sizingDesRunThisAirSys: Bool
    var curOASysNum: Int32
    var dataCapacityUsedForSizing: Float64
    var overrideSizeString: Bool
    var coilType: Int32
    var autoSizedValue: Float64
    var isCoilReportObject: Bool
    var coilReportNum: Int32
    var dataPltSizCoolNum: Int32
    var dataDesInletWaterTemp: Float64
    var compName: String
    var compType: String
    var finalZoneSizing: UnsafePointer[UInt8]
    var finalSysSizing: UnsafePointer[UInt8]
    var callingRoutine: String
    var errorType: String
    
    fn __init__(inout self):
        self.sizingType = "CoolingWaterflowSizing"
        self.sizingString = "Design Water Flow Rate [m3/s]"
        self.dataWaterCoilSizCoolDeltaT = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.dataConstantUsedForSizing = 0.0
        self.curZoneEqNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.termUnitIU = False
        self.curTermUnitSizingNum = 0
        self.termUnitSizing = UnsafePointer[UInt8]()
        self.zoneEqFanCoil = False
        self.zoneEqUnitVent = False
        self.zoneEqVentedSlab = False
        self.zoneEqSizing = UnsafePointer[UInt8]()
        self.dataWaterLoopNum = 0
        self.curSysNum = 0
        self.sizingDesRunThisAirSys = False
        self.curOASysNum = 0
        self.dataCapacityUsedForSizing = 0.0
        self.overrideSizeString = False
        self.coilType = 0
        self.autoSizedValue = 0.0
        self.isCoilReportObject = False
        self.coilReportNum = 0
        self.dataPltSizCoolNum = 0
        self.dataDesInletWaterTemp = 0.0
        self.compName = ""
        self.compType = ""
        self.finalZoneSizing = UnsafePointer[UInt8]()
        self.finalSysSizing = UnsafePointer[UInt8]()
        self.callingRoutine = ""
        self.errorType = ""
    
    fn size(inout self, state: UnsafePointer[UInt8], original_value: Float64, 
            inout errors_found: UnsafePointer[Bool]) -> Float64:
        """
        Size cooling water flow rate based on design conditions.
        """
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        
        var coil_des_water_delta_t = self.dataWaterCoilSizCoolDeltaT
        
        if self.dataFractionUsedForSizing > 0.0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = original_value
                else:
                    if self.termUnitIU and (self.curTermUnitSizingNum > 0):
                        self.autoSizedValue = self._getTermUnitMaxCWVolFlow(self.curTermUnitSizingNum - 1)
                    elif self.zoneEqFanCoil or self.zoneEqUnitVent or self.zoneEqVentedSlab:
                        self.autoSizedValue = self._getZoneEqMaxCWVolFlow(self.curZoneEqNum - 1)
                    else:
                        var coil_in_temp = self._getFinalZoneSizingDesCoolCoilInTemp(self.curZoneEqNum - 1)
                        var coil_out_temp = self._getFinalZoneSizingCoolDesTemp(self.curZoneEqNum - 1)
                        var coil_out_hum_rat = self._getFinalZoneSizingCoolDesHumRat(self.curZoneEqNum - 1)
                        var coil_in_hum_rat = self._getFinalZoneSizingDesCoolCoilInHumRat(self.curZoneEqNum - 1)
                        
                        var des_coil_load = (
                            self._getFinalZoneSizingDesCoolMassFlow(self.curZoneEqNum - 1) *
                            (self._psyHFnTdbW(coil_in_temp, coil_in_hum_rat) - 
                             self._psyHFnTdbW(coil_out_temp, coil_out_hum_rat))
                        )
                        
                        var des_vol_flow = self._getFinalZoneSizingDesCoolMassFlow(self.curZoneEqNum - 1) / 
                                          self._getStateDataEnvrnStdRhoAir(state)
                        
                        des_coil_load += self._calcFanDesHeatGain(des_vol_flow)
                        
                        if des_coil_load >= SmallLoad:
                            if (self.dataWaterLoopNum > 0 and 
                                self.dataWaterLoopNum <= self._getPlantLoopSize(state) and
                                self.dataWaterCoilSizCoolDeltaT > 0.0):
                                
                                var cp = self._getPlantLoopGlycolSpecificHeat(state, self.dataWaterLoopNum - 1)
                                var rho = self._getPlantLoopGlycolDensity(state, self.dataWaterLoopNum - 1)
                                self.autoSizedValue = des_coil_load / (coil_des_water_delta_t * cp * rho)
                            else:
                                self.autoSizedValue = 0.0
                                var msg = "Developer Error: For autosizing of " + self.compType + " " + 
                                         self.compName + ", certain inputs are required. Add PlantLoop, " +
                                         "Plant loop number, coil capacity and/or Water Coil water delta T."
                                self.errorType = "ErrorType1"
                                self.addErrorMessage(msg)
                                self._showSevereError(state, msg)
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
                            self.dataWaterLoopNum <= self._getPlantLoopSize(state) and
                            coil_des_water_delta_t > 0.0):
                            
                            var cp = self._getPlantLoopGlycolSpecificHeat(state, self.dataWaterLoopNum - 1)
                            var rho = self._getPlantLoopGlycolDensity(state, self.dataWaterLoopNum - 1)
                            self.autoSizedValue = self.dataCapacityUsedForSizing / (coil_des_water_delta_t * cp * rho)
                        else:
                            self.autoSizedValue = 0.0
                            var msg = "Developer Error: For autosizing of " + self.compType + " " + 
                                     self.compName + ", certain inputs are required. Add PlantLoop, " +
                                     "Plant loop number, coil capacity and/or Water Coil water delta T."
                            self.errorType = "ErrorType1"
                            self.addErrorMessage(msg)
                            self._showSevereError(state, msg)
                    else:
                        self.autoSizedValue = 0.0
        
        if self.overrideSizeString:
            if self.coilType == 1:
                self.sizingString = "Maximum Water Flow Rate [m3/s]"
            else:
                self.sizingString = "Design Water Flow Rate [m3/s]"
        
        self.selectSizerOutput(state, errors_found)
        
        if self.isCoilReportObject:
            self._setCoilWaterFlowPltSizNum(state, self.coilReportNum, self.autoSizedValue, 
                                           self.wasAutoSized, self.dataPltSizCoolNum, 
                                           self.dataWaterLoopNum)
            self._setCoilWaterDeltaT(state, self.coilReportNum, coil_des_water_delta_t)
            
            if self.dataDesInletWaterTemp > 0.0:
                self._setCoilEntWaterTemp(state, self.coilReportNum, self.dataDesInletWaterTemp)
                self._setCoilLvgWaterTemp(state, self.coilReportNum, 
                                         self.dataDesInletWaterTemp + coil_des_water_delta_t)
            else:
                self._setCoilEntWaterTemp(state, self.coilReportNum, CWInitConvTemp)
                self._setCoilLvgWaterTemp(state, self.coilReportNum, CWInitConvTemp + coil_des_water_delta_t)
            
            self._calcCoilWaterFlowRates(state, self.compName, self.compType, self.autoSizedValue,
                                        self.dataWaterLoopNum, self.curZoneEqNum, self.curSysNum,
                                        self.curOASysNum, self.finalZoneSizing, self.finalSysSizing)
        
        return self.autoSizedValue
    
    fn clear_state(inout self):
        """Clear state for next sizing."""
        self.clearState()
    
    fn checkInitialized(inout self, state: UnsafePointer[UInt8], 
                       inout errors_found: UnsafePointer[Bool]) -> Bool:
        """Check if sizer is initialized. Must be wired to base implementation."""
        return False
    
    fn preSize(inout self, state: UnsafePointer[UInt8], original_value: Float64):
        """Pre-sizing setup. Must be wired to base implementation."""
        pass
    
    fn selectSizerOutput(inout self, state: UnsafePointer[UInt8], 
                        inout errors_found: UnsafePointer[Bool]):
        """Select and apply sizing output. Must be wired to base implementation."""
        pass
    
    fn addErrorMessage(inout self, msg: String):
        """Add error message to list. Must be wired to base implementation."""
        pass
    
    fn clearState(inout self):
        """Clear internal state. Must be wired to base implementation."""
        pass
    
    @always_inline
    fn _psyHFnTdbW(self, tdb: Float64, w: Float64) -> Float64:
        """Psychrometric enthalpy calculation. Wire to Psychrometrics::PsyHFnTdbW"""
        return 0.0
    
    @always_inline
    fn _calcFanDesHeatGain(self, des_vol_flow: Float64) -> Float64:
        """Calculate fan design heat gain. Wire to BaseSizerWithFanHeatInputs::calcFanDesHeatGain"""
        return 0.0
    
    @always_inline
    fn _getTermUnitMaxCWVolFlow(self, idx: Int32) -> Float64:
        """Get terminal unit max CW volume flow. Wire to termUnitSizing array access."""
        return 0.0
    
    @always_inline
    fn _getZoneEqMaxCWVolFlow(self, idx: Int32) -> Float64:
        """Get zone equipment max CW volume flow. Wire to zoneEqSizing array access."""
        return 0.0
    
    @always_inline
    fn _getFinalZoneSizingDesCoolCoilInTemp(self, idx: Int32) -> Float64:
        """Get final zone sizing design cool coil inlet temp."""
        return 0.0
    
    @always_inline
    fn _getFinalZoneSizingCoolDesTemp(self, idx: Int32) -> Float64:
        """Get final zone sizing cool design temp."""
        return 0.0
    
    @always_inline
    fn _getFinalZoneSizingCoolDesHumRat(self, idx: Int32) -> Float64:
        """Get final zone sizing cool design humidity ratio."""
        return 0.0
    
    @always_inline
    fn _getFinalZoneSizingDesCoolCoilInHumRat(self, idx: Int32) -> Float64:
        """Get final zone sizing design cool coil inlet humidity ratio."""
        return 0.0
    
    @always_inline
    fn _getFinalZoneSizingDesCoolMassFlow(self, idx: Int32) -> Float64:
        """Get final zone sizing design cool mass flow."""
        return 0.0
    
    @always_inline
    fn _getStateDataEnvrnStdRhoAir(self, state: UnsafePointer[UInt8]) -> Float64:
        """Get standard density of air from state. Wire to state.dataEnvrn.StdRhoAir"""
        return 1.2
    
    @always_inline
    fn _getPlantLoopSize(self, state: UnsafePointer[UInt8]) -> Int32:
        """Get size of plant loop array."""
        return 0
    
    @always_inline
    fn _getPlantLoopGlycolSpecificHeat(self, state: UnsafePointer[UInt8], loop_idx: Int32) -> Float64:
        """Get plant loop glycol specific heat."""
        return 0.0
    
    @always_inline
    fn _getPlantLoopGlycolDensity(self, state: UnsafePointer[UInt8], loop_idx: Int32) -> Float64:
        """Get plant loop glycol density."""
        return 0.0
    
    @always_inline
    fn _showSevereError(self, state: UnsafePointer[UInt8], msg: String):
        """Show severe error message. Wire to ShowSevereError."""
        pass
    
    @always_inline
    fn _setCoilWaterFlowPltSizNum(inout self, state: UnsafePointer[UInt8], coil_report_num: Int32,
                                 auto_sized_value: Float64, was_auto_sized: Bool, 
                                 plt_siz_cool_num: Int32, water_loop_num: Int32):
        """Set coil water flow plant size number. Wire to ReportCoilSelection::setCoilWaterFlowPltSizNum"""
        pass
    
    @always_inline
    fn _setCoilWaterDeltaT(inout self, state: UnsafePointer[UInt8], coil_report_num: Int32, 
                          delta_t: Float64):
        """Set coil water delta T. Wire to ReportCoilSelection::setCoilWaterDeltaT"""
        pass
    
    @always_inline
    fn _setCoilEntWaterTemp(inout self, state: UnsafePointer[UInt8], coil_report_num: Int32, 
                           temp: Float64):
        """Set coil entering water temperature. Wire to ReportCoilSelection::setCoilEntWaterTemp"""
        pass
    
    @always_inline
    fn _setCoilLvgWaterTemp(inout self, state: UnsafePointer[UInt8], coil_report_num: Int32, 
                           temp: Float64):
        """Set coil leaving water temperature. Wire to ReportCoilSelection::setCoilLvgWaterTemp"""
        pass
    
    @always_inline
    fn _calcCoilWaterFlowRates(inout self, state: UnsafePointer[UInt8], comp_name: String, 
                              comp_type: String, auto_sized_value: Float64, water_loop_num: Int32,
                              cur_zone_eq_num: Int32, cur_sys_num: Int32, cur_oa_sys_num: Int32,
                              final_zone_sizing: UnsafePointer[UInt8], 
                              final_sys_sizing: UnsafePointer[UInt8]):
        """Calculate coil water flow rates. Wire to base implementation."""
        pass
