from typing import Protocol, Callable
import math

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state object from EnergyPlus core
# BaseSizer: base class from EnergyPlus.Autosizing.Base
# AutoSizingType: enum from EnergyPlus.Autosizing
# AutoSizingResultType: enum from EnergyPlus.Autosizing
# WaterCoils: module with CalcSimpleHeatingCoil(state, coil_num, fan_op, value, sim_calc)
# General: module with SolveRoot(state, acc, max_iter, sol_fla, x_val, f, x_min, x_max)
#          and constants SOLVEROOT_ERROR_ITER, SOLVEROOT_ERROR_INIT
# HVAC: module with SmallLoad constant
# ReportCoilSelection: module with setCoilUA(state, coil_report_num, auto_sized_value, ...)
# UtilityRoutines: module with ShowSevereError, ShowContinueError, ShowWarningError


class BaseSizer:
    def checkInitialized(self, state, errors_found):
        raise NotImplementedError
    
    def preSize(self, state, original_value):
        raise NotImplementedError
    
    def addErrorMessage(self, msg):
        raise NotImplementedError
    
    def selectSizerOutput(self, state, errors_found):
        raise NotImplementedError


class WaterHeatingCoilUASizer(BaseSizer):
    
    def __init__(self):
        self.sizingType = "WaterHeatingCoilUASizing"
        self.sizingString = "U-Factor Times Area Value [W/K]"
        # Members inherited from BaseSizer
        self.curZoneEqNum = 0
        self.curSysNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.sizingDesRunThisAirSys = False
        self.autoSizedValue = 0.0
        self.dataCapacityUsedForSizing = 0.0
        self.dataWaterFlowUsedForSizing = 0.0
        self.dataFlowUsedForSizing = 0.0
        self.dataCoilNum = 0
        self.dataFanOp = 0
        self.compName = ""
        self.finalZoneSizing = None
        self.dataDesInletAirTemp = 0.0
        self.dataDesInletAirHumRat = 0.0
        self.dataDesignCoilCapacity = 0.0
        self.dataNomCapInpMeth = False
        self.termUnitSingDuct = False
        self.termUnitPIU = False
        self.termUnitIU = False
        self.zoneEqFanCoil = False
        self.dataDesOutletAirTemp = 0.0
        self.dataDesOutletAirHumRat = 0.0
        self.errorType = None
        self.dataErrorsFound = False
        self.plantSizData = None
        self.dataPltSizHeatNum = 0
        self.dataWaterCoilSizHeatDeltaT = 0.0
        self.finalSysSizing = None
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.coilReportNum = 0
    
    def size(self, state, original_value, errors_found):
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = original_value
            else:
                if (self.dataCapacityUsedForSizing > 0.0 and 
                    self.dataWaterFlowUsedForSizing > 0.0 and 
                    self.dataFlowUsedForSizing > 0.0):
                    
                    UA0 = 0.001 * self.dataCapacityUsedForSizing
                    UA1 = self.dataCapacityUsedForSizing
                    
                    def f(UA):
                        state.dataWaterCoils.WaterCoil[self.dataCoilNum].UACoilVariable = UA
                        import WaterCoils
                        WaterCoils.CalcSimpleHeatingCoil(state, self.dataCoilNum, self.dataFanOp, 1.0, state.dataWaterCoils.SimCalc)
                        state.dataSize.DataDesignCoilCapacity = state.dataWaterCoils.WaterCoil[self.dataCoilNum].TotWaterHeatingCoilRate
                        return ((self.dataCapacityUsedForSizing - 
                                state.dataWaterCoils.WaterCoil[self.dataCoilNum].TotWaterHeatingCoilRate) / 
                               self.dataCapacityUsedForSizing)
                    
                    Acc = 0.0001
                    sol_fla = [0]
                    import General
                    General.SolveRoot(state, Acc, 500, sol_fla, self.autoSizedValue, f, UA0, UA1)
                    sol_fla = sol_fla[0]
                    
                    if sol_fla == General.SOLVEROOT_ERROR_ITER:
                        errors_found[0] = True
                        msg = f'Autosizing of heating coil UA failed for Coil:Heating:Water "{self.compName}"'
                        self.addErrorMessage(msg)
                        import UtilityRoutines
                        UtilityRoutines.ShowSevereError(state, msg)
                        msg = "  Iteration limit exceeded in calculating coil UA"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Lower UA estimate = {UA0:.6f} W/m2-K (0.1% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Upper UA estimate = {UA1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Final UA estimate when iterations exceeded limit = {self.autoSizedValue:.6f} W/m2-K"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = (f'  Zone "{self.finalZoneSizing(self.curZoneEqNum).ZoneName}" '
                               "coil sizing conditions (may be different than Sizing inputs):")
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air temperature     = {self.dataDesInletAirTemp:.3f} C"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air humidity ratio  = {self.dataDesInletAirHumRat:.3f} kgWater/kgDryAir"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air mass flow rate  = {self.dataFlowUsedForSizing:.6f} kg/s"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Design Coil Capacity           = {self.dataDesignCoilCapacity:.3f} W"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        if self.dataNomCapInpMeth:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air temperature    = {self.dataDesOutletAirTemp:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.dataDesOutletAirHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        elif self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        else:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air temperature    = {self.finalZoneSizing(self.curZoneEqNum).HeatDesTemp:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.finalZoneSizing(self.curZoneEqNum).HeatDesHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        self.dataErrorsFound = True
                    
                    elif sol_fla == General.SOLVEROOT_ERROR_INIT:
                        self.errorType = "ErrorType1"
                        errors_found[0] = True
                        msg = f'Autosizing of heating coil UA failed for Coil:Heating:Water "{self.compName}"'
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowSevereError(state, msg)
                        msg = "  Bad starting values for UA"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Lower UA estimate = {UA0:.6f} W/m2-K (0.1% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Upper UA estimate = {UA1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = (f'  Zone "{self.finalZoneSizing(self.curZoneEqNum).ZoneName}" '
                               "coil sizing conditions (may be different than Sizing inputs):")
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air temperature     = {self.dataDesInletAirTemp:.3f} C"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air humidity ratio  = {self.dataDesInletAirHumRat:.3f} kgWater/kgDryAir"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air mass flow rate  = {self.dataFlowUsedForSizing:.6f} kg/s"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Design Coil Capacity           = {self.dataDesignCoilCapacity:.3f} W"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        if self.dataNomCapInpMeth:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air temperature    = {self.dataDesOutletAirTemp:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.dataDesOutletAirHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        elif self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        else:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air temperature    = {self.finalZoneSizing(self.curZoneEqNum).HeatDesTemp:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.finalZoneSizing(self.curZoneEqNum).HeatDesHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        if self.dataDesignCoilCapacity < self.dataCapacityUsedForSizing:
                            msg = "  Inadequate water side capacity: in Plant Sizing for this hot water loop"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = "  increase design loop exit temperature and/or decrease design loop delta T"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Plant Sizing object = {self.plantSizData(self.dataPltSizHeatNum).PlantLoopName}"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Plant design loop exit temperature = {self.plantSizData(self.dataPltSizHeatNum).ExitTemp:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Plant design loop delta T          = {self.dataWaterCoilSizHeatDeltaT:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        self.dataErrorsFound = True
                else:
                    self.autoSizedValue = 1.0
                    if self.dataWaterFlowUsedForSizing > 0.0 and self.dataCapacityUsedForSizing == 0.0:
                        msg = f"The design coil load used for UA sizing is zero for Coil:Heating:Water {self.compName}"
                        self.addErrorMessage(msg)
                        import UtilityRoutines
                        UtilityRoutines.ShowWarningError(state, msg)
                        msg = "An autosize value for UA cannot be calculated"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = "Input a value for UA, change the heating design day, or raise"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = "  the zone heating design supply air temperature"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = "Water coil UA is set to 1 and the simulation continues."
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
        
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = original_value
            else:
                import HVAC
                if (self.dataCapacityUsedForSizing >= HVAC.SmallLoad and 
                    self.dataWaterFlowUsedForSizing > 0.0 and 
                    self.dataFlowUsedForSizing > 0.0):
                    
                    UA0 = 0.001 * self.dataCapacityUsedForSizing
                    UA1 = self.dataCapacityUsedForSizing
                    
                    def f(UA):
                        state.dataWaterCoils.WaterCoil[self.dataCoilNum].UACoilVariable = UA
                        import WaterCoils
                        WaterCoils.CalcSimpleHeatingCoil(state, self.dataCoilNum, self.dataFanOp, 1.0, state.dataWaterCoils.SimCalc)
                        state.dataSize.DataDesignCoilCapacity = state.dataWaterCoils.WaterCoil[self.dataCoilNum].TotWaterHeatingCoilRate
                        return ((self.dataCapacityUsedForSizing - 
                                state.dataWaterCoils.WaterCoil[self.dataCoilNum].TotWaterHeatingCoilRate) / 
                               self.dataCapacityUsedForSizing)
                    
                    Acc = 0.0001
                    sol_fla = [0]
                    import General
                    General.SolveRoot(state, Acc, 500, sol_fla, self.autoSizedValue, f, UA0, UA1)
                    sol_fla = sol_fla[0]
                    
                    if sol_fla == General.SOLVEROOT_ERROR_ITER:
                        errors_found[0] = True
                        msg = f'Autosizing of heating coil UA failed for Coil:Heating:Water "{self.compName}"'
                        self.addErrorMessage(msg)
                        import UtilityRoutines
                        UtilityRoutines.ShowSevereError(state, msg)
                        msg = "  Iteration limit exceeded in calculating coil UA"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Lower UA estimate = {UA0:.6f} W/m2-K (1% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Upper UA estimate = {UA1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Final UA estimate when iterations exceeded limit = {self.autoSizedValue:.6f} W/m2-K"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = (f'  AirloopHVAC "{self.finalSysSizing(self.curSysNum).AirPriLoopName}" '
                               "coil sizing conditions (may be different than Sizing inputs):")
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air temperature     = {self.dataDesInletAirTemp:.3f} C"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air humidity ratio  = {self.dataDesInletAirHumRat:.3f} kgWater/kgDryAir"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air mass flow rate  = {self.dataFlowUsedForSizing:.6f} kg/s"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Design Coil Capacity           = {self.dataDesignCoilCapacity:.3f} W"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        if self.dataNomCapInpMeth:
                            msg = f"  Coil outlet air temperature    = {self.dataDesOutletAirTemp:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.dataDesOutletAirHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        self.dataErrorsFound = True
                    
                    elif sol_fla == General.SOLVEROOT_ERROR_INIT:
                        self.errorType = "ErrorType1"
                        errors_found[0] = True
                        msg = f'Autosizing of heating coil UA failed for Coil:Heating:Water "{self.compName}"'
                        self.addErrorMessage(msg)
                        import UtilityRoutines
                        UtilityRoutines.ShowSevereError(state, msg)
                        msg = "  Bad starting values for UA"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Lower UA estimate = {UA0:.6f} W/m2-K (1% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Upper UA estimate = {UA1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = (f'  AirloopHVAC "{self.finalSysSizing(self.curSysNum).AirPriLoopName}" '
                               "coil sizing conditions (may be different than Sizing inputs):")
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air temperature     = {self.dataDesInletAirTemp:.3f} C"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air humidity ratio  = {self.dataDesInletAirHumRat:.3f} kgWater/kgDryAir"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Coil inlet air mass flow rate  = {self.dataFlowUsedForSizing:.6f} kg/s"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Design Coil Capacity           = {self.dataDesignCoilCapacity:.3f} W"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        if self.dataNomCapInpMeth:
                            msg = f"  Coil outlet air temperature    = {self.dataDesOutletAirTemp:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.dataDesOutletAirHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        if self.dataDesignCoilCapacity < self.dataCapacityUsedForSizing and not self.dataNomCapInpMeth:
                            msg = "  Inadequate water side capacity: in Plant Sizing for this hot water loop"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = "  increase design loop exit temperature and/or decrease design loop delta T"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Plant Sizing object = {self.plantSizData(self.dataPltSizHeatNum).PlantLoopName}"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Plant design loop exit temperature = {self.plantSizData(self.dataPltSizHeatNum).ExitTemp:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                            msg = f"  Plant design loop delta T          = {self.dataWaterCoilSizHeatDeltaT:.3f} C"
                            self.addErrorMessage(msg)
                            UtilityRoutines.ShowContinueError(state, msg)
                        self.dataErrorsFound = True
                else:
                    self.autoSizedValue = 1.0
                    if self.dataWaterFlowUsedForSizing > 0.0 and self.dataCapacityUsedForSizing < HVAC.SmallLoad:
                        msg = f"The design coil load used for UA sizing is zero for Coil:Heating:Water {self.compName}"
                        self.addErrorMessage(msg)
                        import UtilityRoutines
                        UtilityRoutines.ShowWarningError(state, msg)
                        msg = "An autosize value for UA cannot be calculated"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = "Input a value for UA, change the heating design day, or raise"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = "  the zone heating design supply air temperature"
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
                        msg = "Water coil UA is set to 1 and the simulation continues."
                        self.addErrorMessage(msg)
                        UtilityRoutines.ShowContinueError(state, msg)
        
        if self.dataErrorsFound:
            state.dataSize.DataErrorsFound = True
        
        if self.overrideSizeString:
            self.sizingString = "U-Factor Times Area Value [W/K]"
        
        self.selectSizerOutput(state, errors_found)
        
        if self.isCoilReportObject and self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys:
            import ReportCoilSelection
            ReportCoilSelection.setCoilUA(state,
                                         self.coilReportNum,
                                         self.autoSizedValue,
                                         self.dataCapacityUsedForSizing,
                                         self.wasAutoSized,
                                         self.curSysNum,
                                         self.curZoneEqNum)
        
        return self.autoSizedValue
