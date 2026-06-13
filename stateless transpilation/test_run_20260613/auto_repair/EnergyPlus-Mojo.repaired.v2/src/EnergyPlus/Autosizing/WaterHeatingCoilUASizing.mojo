from Base import BaseSizer, AutoSizingType, AutoSizingResultType
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataHVACGlobals import HVAC
from ...General import General
from ...UtilityRoutines import ShowSevereError, ShowContinueError, ShowWarningError
from ...WaterCoils import WaterCoils
from ...ReportCoilSelection import ReportCoilSelection
struct WaterHeatingCoilUASizer(BaseSizer):
    def __init__(inout self):
        self.sizingType = AutoSizingType.WaterHeatingCoilUASizing
        self.sizingString = "U-Factor Times Area Value [W/K]"
    def size(inout self, inout state: EnergyPlusData, originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        self.preSize(state, originalValue)
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.dataCapacityUsedForSizing > 0.0 and self.dataWaterFlowUsedForSizing > 0.0 and self.dataFlowUsedForSizing > 0.0:
                    var UA0: Float64 = 0.001 * self.dataCapacityUsedForSizing
                    var UA1: Float64 = self.dataCapacityUsedForSizing
                    var f = fn(UA: Float64) -> Float64:
                        state.dataWaterCoils.WaterCoil(self.dataCoilNum).UACoilVariable = UA
                        WaterCoils.CalcSimpleHeatingCoil(state, self.dataCoilNum, self.dataFanOp, 1.0, state.dataWaterCoils.SimCalc)
                        state.dataSize.DataDesignCoilCapacity = state.dataWaterCoils.WaterCoil(self.dataCoilNum).TotWaterHeatingCoilRate
                        return (self.dataCapacityUsedForSizing - state.dataWaterCoils.WaterCoil(self.dataCoilNum).TotWaterHeatingCoilRate) / self.dataCapacityUsedForSizing
                    const Acc: Float64 = 0.0001  # Accuracy of result
                    var SolFla: Int
                    General.SolveRoot(state, Acc, 500, SolFla, self.autoSizedValue, f, UA0, UA1)
                    if SolFla == General.SOLVEROOT_ERROR_ITER:
                        errorsFound = true
                        var msg: String = "Autosizing of heating coil UA failed for Coil:Heating:Water \"" + self.compName + "\""
                        self.addErrorMessage(msg)
                        ShowSevereError(state, msg)
                        msg = "  Iteration limit exceeded in calculating coil UA"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Lower UA estimate = {UA0:.6f} W/m2-K (0.1% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Upper UA estimate = {UA1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Final UA estimate when iterations exceeded limit = {self.autoSizedValue:.6f} W/m2-K"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "  Zone \"" + self.finalZoneSizing(self.curZoneEqNum).ZoneName + "\" coil sizing conditions (may be different than Sizing inputs):"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air temperature     = {self.dataDesInletAirTemp:.3f} C"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air humidity ratio  = {self.dataDesInletAirHumRat:.3f} kgWater/kgDryAir"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air mass flow rate  = {self.dataFlowUsedForSizing:.6f} kg/s"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Design Coil Capacity           = {self.dataDesignCoilCapacity:.3f} W"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        if self.dataNomCapInpMeth:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air temperature    = {self.dataDesOutletAirTemp:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.dataDesOutletAirHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        elif self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        else:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air temperature    = {self.finalZoneSizing(self.curZoneEqNum).HeatDesTemp:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.finalZoneSizing(self.curZoneEqNum).HeatDesHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        self.dataErrorsFound = true
                    elif SolFla == General.SOLVEROOT_ERROR_INIT:
                        self.errorType = AutoSizingResultType.ErrorType1
                        errorsFound = true
                        var msg: String = "Autosizing of heating coil UA failed for Coil:Heating:Water \"" + self.compName + "\""
                        self.addErrorMessage(msg)
                        ShowSevereError(state, msg)
                        msg = "  Bad starting values for UA"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Lower UA estimate = {UA0:.6f} W/m2-K (0.1% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Upper UA estimate = {UA1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "  Zone \"" + self.finalZoneSizing(self.curZoneEqNum).ZoneName + "\" coil sizing conditions (may be different than Sizing inputs):"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air temperature     = {self.dataDesInletAirTemp:.3f} C"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air humidity ratio  = {self.dataDesInletAirHumRat:.3f} kgWater/kgDryAir"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air mass flow rate  = {self.dataFlowUsedForSizing:.6f} kg/s"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Design Coil Capacity           = {self.dataDesignCoilCapacity:.3f} W"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        if self.dataNomCapInpMeth:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air temperature    = {self.dataDesOutletAirTemp:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.dataDesOutletAirHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        elif self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        else:
                            msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air temperature    = {self.finalZoneSizing(self.curZoneEqNum).HeatDesTemp:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.finalZoneSizing(self.curZoneEqNum).HeatDesHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        if self.dataDesignCoilCapacity < self.dataCapacityUsedForSizing:
                            msg = "  Inadequate water side capacity: in Plant Sizing for this hot water loop"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = "  increase design loop exit temperature and/or decrease design loop delta T"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = "  Plant Sizing object = " + self.plantSizData(self.dataPltSizHeatNum).PlantLoopName
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Plant design loop exit temperature = {self.plantSizData(self.dataPltSizHeatNum).ExitTemp:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Plant design loop delta T          = {self.dataWaterCoilSizHeatDeltaT:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        self.dataErrorsFound = true
                else:
                    self.autoSizedValue = 1.0
                    if self.dataWaterFlowUsedForSizing > 0.0 and self.dataCapacityUsedForSizing == 0.0:
                        var msg: String = "The design coil load used for UA sizing is zero for Coil:Heating:Water " + self.compName
                        self.addErrorMessage(msg)
                        ShowWarningError(state, msg)
                        msg = "An autosize value for UA cannot be calculated"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "Input a value for UA, change the heating design day, or raise"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "  the zone heating design supply air temperature"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "Water coil UA is set to 1 and the simulation continues."
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                if self.dataCapacityUsedForSizing >= HVAC.SmallLoad and self.dataWaterFlowUsedForSizing > 0.0 and self.dataFlowUsedForSizing > 0.0:
                    var UA0: Float64 = 0.001 * self.dataCapacityUsedForSizing
                    var UA1: Float64 = self.dataCapacityUsedForSizing
                    var f = fn(UA: Float64) -> Float64:
                        state.dataWaterCoils.WaterCoil(self.dataCoilNum).UACoilVariable = UA
                        WaterCoils.CalcSimpleHeatingCoil(state, self.dataCoilNum, self.dataFanOp, 1.0, state.dataWaterCoils.SimCalc)
                        state.dataSize.DataDesignCoilCapacity = state.dataWaterCoils.WaterCoil(self.dataCoilNum).TotWaterHeatingCoilRate
                        return (self.dataCapacityUsedForSizing - state.dataWaterCoils.WaterCoil(self.dataCoilNum).TotWaterHeatingCoilRate) / self.dataCapacityUsedForSizing
                    const Acc: Float64 = 0.0001  # Necessary?
                    var SolFla: Int
                    General.SolveRoot(state, Acc, 500, SolFla, self.autoSizedValue, f, UA0, UA1)
                    if SolFla == General.SOLVEROOT_ERROR_ITER:
                        errorsFound = true
                        var msg: String = "Autosizing of heating coil UA failed for Coil:Heating:Water \"" + self.compName + "\""
                        self.addErrorMessage(msg)
                        ShowSevereError(state, msg)
                        msg = "  Iteration limit exceeded in calculating coil UA"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Lower UA estimate = {UA0:.6f} W/m2-K (1% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Upper UA estimate = {UA1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Final UA estimate when iterations exceeded limit = {self.autoSizedValue:.6f} W/m2-K"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "  AirloopHVAC \"" + self.finalSysSizing(self.curSysNum).AirPriLoopName + "\" coil sizing conditions (may be different than Sizing inputs):"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air temperature     = {self.dataDesInletAirTemp:.3f} C"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air humidity ratio  = {self.dataDesInletAirHumRat:.3f} kgWater/kgDryAir"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air mass flow rate  = {self.dataFlowUsedForSizing:.6f} kg/s"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Design Coil Capacity           = {self.dataDesignCoilCapacity:.3f} W"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        if self.dataNomCapInpMeth:
                            msg = f"  Coil outlet air temperature    = {self.dataDesOutletAirTemp:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.dataDesOutletAirHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        self.dataErrorsFound = true
                    elif SolFla == General.SOLVEROOT_ERROR_INIT:
                        self.errorType = AutoSizingResultType.ErrorType1
                        errorsFound = true
                        var msg: String = "Autosizing of heating coil UA failed for Coil:Heating:Water \"" + self.compName + "\""
                        self.addErrorMessage(msg)
                        ShowSevereError(state, msg)
                        msg = "  Bad starting values for UA"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Lower UA estimate = {UA0:.6f} W/m2-K (1% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Upper UA estimate = {UA1:.6f} W/m2-K (100% of Design Coil Load)"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "  AirloopHVAC \"" + self.finalSysSizing(self.curSysNum).AirPriLoopName + "\" coil sizing conditions (may be different than Sizing inputs):"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air temperature     = {self.dataDesInletAirTemp:.3f} C"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air humidity ratio  = {self.dataDesInletAirHumRat:.3f} kgWater/kgDryAir"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Coil inlet air mass flow rate  = {self.dataFlowUsedForSizing:.6f} kg/s"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Design Coil Capacity           = {self.dataDesignCoilCapacity:.3f} W"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = f"  Design Coil Load               = {self.dataCapacityUsedForSizing:.3f} W"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        if self.dataNomCapInpMeth:
                            msg = f"  Coil outlet air temperature    = {self.dataDesOutletAirTemp:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Coil outlet air humidity ratio = {self.dataDesOutletAirHumRat:.3f} kgWater/kgDryAir"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        if self.dataDesignCoilCapacity < self.dataCapacityUsedForSizing and not self.dataNomCapInpMeth:
                            msg = "  Inadequate water side capacity: in Plant Sizing for this hot water loop"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = "  increase design loop exit temperature and/or decrease design loop delta T"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = "  Plant Sizing object = " + self.plantSizData(self.dataPltSizHeatNum).PlantLoopName
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Plant design loop exit temperature = {self.plantSizData(self.dataPltSizHeatNum).ExitTemp:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                            msg = f"  Plant design loop delta T          = {self.dataWaterCoilSizHeatDeltaT:.3f} C"
                            self.addErrorMessage(msg)
                            ShowContinueError(state, msg)
                        self.dataErrorsFound = true
                else:
                    self.autoSizedValue = 1.0
                    if self.dataWaterFlowUsedForSizing > 0.0 and self.dataCapacityUsedForSizing < HVAC.SmallLoad:
                        var msg: String = "The design coil load used for UA sizing is zero for Coil:Heating:Water " + self.compName
                        self.addErrorMessage(msg)
                        ShowWarningError(state, msg)
                        msg = "An autosize value for UA cannot be calculated"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "Input a value for UA, change the heating design day, or raise"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "  the zone heating design supply air temperature"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        msg = "Water coil UA is set to 1 and the simulation continues."
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
        if self.dataErrorsFound:
            state.dataSize.DataErrorsFound = true
        if self.overrideSizeString:
            self.sizingString = "U-Factor Times Area Value [W/K]"
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject and self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys:
            ReportCoilSelection.setCoilUA(state,
                                          self.coilReportNum,
                                          self.autoSizedValue,
                                          self.dataCapacityUsedForSizing,
                                          self.wasAutoSized,
                                          self.curSysNum,
                                          self.curZoneEqNum)
        return self.autoSizedValue