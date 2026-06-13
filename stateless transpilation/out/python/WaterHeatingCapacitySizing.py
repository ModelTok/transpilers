# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: struct from EnergyPlus/Data/EnergyPlusData.hh
# - AutoSizingType: enum from EnergyPlus/Autosizing/Base.hh
# - BaseSizer: base class from EnergyPlus/Autosizing/Base.hh
# - Constant.HWInitConvTemp: float constant from EnergyPlus (60.0)
# - Psychrometrics.PsyCpAirFnW: function from EnergyPlus/Psychrometrics.hh
# - ReportCoilSelection.setCoilWaterHeaterCapacityPltSizNum: function from EnergyPlus/ReportCoilSelection.hh
# - ShowWarningMessage: function from EnergyPlus/UtilityRoutines.hh
# - ShowContinueError: function from EnergyPlus/UtilityRoutines.hh

class WaterHeatingCapacitySizer:
    def __init__(self):
        self.sizingType = "WaterHeatingCapacitySizing"
        self.sizingString = "Rated Capacity [W]"
        self.curZoneEqNum = 0
        self.curSysNum = 0
        self.curTermUnitSizingNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.sizingDesRunThisAirSys = False
        self.termUnitSingDuct = False
        self.termUnitPIU = False
        self.termUnitIU = False
        self.zoneEqFanCoil = False
        self.zoneEqUnitHeater = False
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.dataWaterLoopNum = 0
        self.dataWaterCoilSizHeatDeltaT = 0.0
        self.dataHeatSizeRatio = 1.0
        self.callingRoutine = ""
        self.compType = ""
        self.compName = ""
        self.coilReportNum = 0
        self.dataPltSizHeatNum = 0
        self.autoSizedValue = 0.0
    
    def checkInitialized(self, state, errors_found):
        pass
    
    def preSize(self, state, original_value):
        pass
    
    def selectSizerOutput(self, state, errors_found):
        pass
    
    def addErrorMessage(self, msg):
        pass
    
    def setOAFracForZoneEqSizing(self, state, mass_flow, zone_eq_sizing):
        pass
    
    def setHeatCoilInletTempForZoneEqSizing(self, oa_frac, zone_eq_sizing, final_zone_sizing):
        pass
    
    def termUnitSizing(self, index):
        pass
    
    def zoneEqSizing(self, index):
        pass
    
    def finalZoneSizing(self, index):
        pass
    
    def size(self, state, original_value, errors_found):
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = original_value
            else:
                des_mass_flow = 0.0
                nominal_capacity_des = 0.0
                coil_in_temp = 0.0
                coil_out_temp = 0.0
                coil_out_hum_rat = 0.0
                
                if (self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    des_mass_flow = self.termUnitSizing(self.curTermUnitSizingNum).MaxHWVolFlow
                    cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(
                        state, 60.0, self.callingRoutine)
                    rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(
                        state, 60.0, self.callingRoutine)
                    nominal_capacity_des = des_mass_flow * self.dataWaterCoilSizHeatDeltaT * cp * rho
                
                elif self.zoneEqFanCoil or self.zoneEqUnitHeater:
                    des_mass_flow = self.zoneEqSizing(self.curZoneEqNum).MaxHWVolFlow
                    cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(
                        state, 60.0, self.callingRoutine)
                    rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(
                        state, 60.0, self.callingRoutine)
                    nominal_capacity_des = des_mass_flow * self.dataWaterCoilSizHeatDeltaT * cp * rho
                
                else:
                    if self.zoneEqSizing(self.curZoneEqNum).SystemAirFlow:
                        des_mass_flow = self.zoneEqSizing(self.curZoneEqNum).AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                        des_mass_flow = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        des_mass_flow = self.finalZoneSizing(self.curZoneEqNum).DesHeatMassFlow
                    
                    coil_in_temp = self.setHeatCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, des_mass_flow, self.zoneEqSizing(self.curZoneEqNum)),
                        self.zoneEqSizing(self.curZoneEqNum),
                        self.finalZoneSizing(self.curZoneEqNum))
                    
                    coil_out_temp = self.finalZoneSizing(self.curZoneEqNum).HeatDesTemp
                    coil_out_hum_rat = self.finalZoneSizing(self.curZoneEqNum).HeatDesHumRat
                    nominal_capacity_des = Psychrometrics_PsyCpAirFnW(coil_out_hum_rat) * des_mass_flow * (coil_out_temp - coil_in_temp)
                
                self.autoSizedValue = nominal_capacity_des * self.dataHeatSizeRatio
                
                if state.dataGlobal.DisplayExtraWarnings and self.autoSizedValue <= 0.0:
                    msg = self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName
                    self.addErrorMessage(msg)
                    ShowWarningMessage(state, msg)
                    
                    msg = f"...Rated Total Heating Capacity = {self.autoSizedValue:.2f} [W]"
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    
                    msg = f"...Air flow rate used for sizing = {des_mass_flow / state.dataEnvrn.StdRhoAir:.5f} [m3/s]"
                    self.addErrorMessage(msg)
                    ShowContinueError(state, msg)
                    
                    if self.termUnitSingDuct or self.termUnitPIU or self.termUnitIU or self.zoneEqFanCoil or self.zoneEqUnitHeater:
                        msg = f"...Air flow rate used for sizing = {des_mass_flow / state.dataEnvrn.StdRhoAir:.5f} [m3/s]"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        
                        msg = f"...Plant loop temperature difference = {self.dataWaterCoilSizHeatDeltaT:.2f} [C]"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                    else:
                        msg = f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        
                        msg = f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
                        
                        msg = f"...Coil outlet air humidity ratio used for sizing = {coil_out_hum_rat:.2f} [kgWater/kgDryAir]"
                        self.addErrorMessage(msg)
                        ShowContinueError(state, msg)
        
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = original_value
        
        if self.overrideSizeString:
            self.sizingString = "Rated Capacity [W]"
        
        self.selectSizerOutput(state, errors_found)
        
        if self.isCoilReportObject:
            ReportCoilSelection_setCoilWaterHeaterCapacityPltSizNum(
                state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized, 
                self.dataPltSizHeatNum, self.dataWaterLoopNum)
        
        return self.autoSizedValue


def Psychrometrics_PsyCpAirFnW(humidity_ratio):
    pass


def ReportCoilSelection_setCoilWaterHeaterCapacityPltSizNum(state, coil_report_num, auto_sized_value, was_auto_sized, data_plt_siz_heat_num, data_water_loop_num):
    pass


def ShowWarningMessage(state, msg):
    pass


def ShowContinueError(state, msg):
    pass
