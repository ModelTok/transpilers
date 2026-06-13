# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data structures (from EnergyPlus.Data.EnergyPlusData)
# - BaseSizerWithScalableInputs: base class (from EnergyPlus.Autosizing.BaseSizerWithScalableInputs)
# - AutoSizingType: enum (from EnergyPlus.Autosizing)
# - Constant: module with constants (from EnergyPlus)
# - Psychrometrics: module with functions (from EnergyPlus.Psychrometrics)
# - ReportCoilSelection: module with functions (from EnergyPlus.ReportCoilSelection)
# - DataSizing: enum/constants module (from EnergyPlus.DataSizing)

from typing import Protocol, Any

class Glycol(Protocol):
    def getSpecificHeat(self, state: Any, temp: float, routine: str) -> float: ...
    def getDensity(self, state: Any, temp: float, routine: str) -> float: ...

class PlantLoop(Protocol):
    glycol: Glycol

class DataPlnt(Protocol):
    PlantLoop: list

class TermUnitSizing(Protocol):
    ReheatLoadMult: float

class ZoneEqSizing(Protocol):
    SystemAirFlow: bool
    AirVolFlow: float
    HeatingAirFlow: bool
    HeatingAirVolFlow: float

class FinalZoneSizing(Protocol):
    DesHeatMassFlow: float
    HeatDesTemp: float
    HeatDesHumRat: float

class PrimaryAirSystem(Protocol):
    NumOAHeatCoils: int

class OutsideAirSys(Protocol):
    AirLoopDOASNum: int

class AirloopDOAS(Protocol):
    HeatOutTemp: float
    PreheatTemp: float

class FinalSysSizing(Protocol):
    HeatOAOption: int
    DesOutAirVolFlow: float
    PreheatTemp: float
    HeatRetTemp: float
    HeatOutTemp: float
    HeatingCapMethod: int
    FractionOfAutosizedHeatingCapacity: float
    HeatSupTemp: float

class DataEnvrn(Protocol):
    StdRhoAir: float

class EnergyPlusData(Protocol):
    dataPlnt: DataPlnt
    dataEnvrn: DataEnvrn

class Psychrometrics:
    @staticmethod
    def PsyCpAirFnW(hum_rat: float) -> float: ...

class ReportCoilSelection:
    @staticmethod
    def setCoilReheatMultiplier(state: EnergyPlusData, coil_num: int, mult: float): ...
    
    @staticmethod
    def setCoilHeatingCapacity(state: EnergyPlusData, coil_num: int, capacity: float,
                              was_auto_sized: bool, sys_num: int, zone_eq_num: int,
                              oa_sys_num: int, fan_cool_load: float,
                              tot_cap_temp_mod_fac: float, dx_flow_per_cap_min_ratio: float,
                              dx_flow_per_cap_max_ratio: float): ...

class Constant:
    HWInitConvTemp = 19.0

class DataSizing:
    FractionOfAutosizedHeatingCapacity = 1

class AutoSizingType:
    HeatingWaterDesCoilLoadUsedForUASizing = "HeatingWaterDesCoilLoadUsedForUASizing"

class BaseSizerWithScalableInputs:
    def checkInitialized(self, state: EnergyPlusData, errors_found: list) -> bool:
        return True
    
    def preSize(self, state: EnergyPlusData, value: float):
        pass
    
    def selectSizerOutput(self, state: EnergyPlusData, errors_found: list):
        pass
    
    def setOAFracForZoneEqSizing(self, state: EnergyPlusData, des_mass_flow: float,
                                 zone_eq_sizing: ZoneEqSizing) -> float:
        raise NotImplementedError()
    
    def setHeatCoilInletTempForZoneEqSizing(self, oa_frac: float,
                                            zone_eq_sizing: ZoneEqSizing,
                                            final_zone_sizing: FinalZoneSizing) -> float:
        raise NotImplementedError()

class HeatingWaterDesCoilLoadUsedForUASizer(BaseSizerWithScalableInputs):
    def __init__(self):
        super().__init__()
        self.sizingType = AutoSizingType.HeatingWaterDesCoilLoadUsedForUASizing
        self.sizingString = "Water Heating Design Coil Load for UA Sizing [W]"
        
        self.autoSizedValue = 0.0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.curZoneEqNum = 0
        self.termUnitSingDuct = False
        self.curTermUnitSizingNum = 0
        self.dataWaterLoopNum = 0
        self.dataWaterFlowUsedForSizing = 0.0
        self.dataWaterCoilSizHeatDeltaT = 0.0
        self.coilReportNum = 0
        self.termUnitPIU = False
        self.termUnitIU = False
        self.termUnitSizing = []
        self.zoneEqFanCoil = False
        self.zoneEqUnitHeater = False
        self.zoneEqSizing = []
        self.finalZoneSizing = []
        self.sizingDesRunThisAirSys = False
        self.curSysNum = 0
        self.curOASysNum = 0
        self.dataAirFlowUsedForSizing = 0.0
        self.primaryAirSystem = []
        self.outsideAirSys = []
        self.airloopDOAS = []
        self.dataDesicRegCoil = False
        self.dataDesOutletAirTemp = 0.0
        self.dataDesInletAirTemp = 0.0
        self.finalSysSizing = []
        self.dataFracOfAutosizedHeatingCapacity = 1.0
        self.dataHeatSizeRatio = 1.0
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.numPrimaryAirSys = 0
        self.callingRoutine = ""
        self.minOA = 0
    
    def size(self, state: EnergyPlusData, original_value: float, errors_found: list) -> float:
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = original_value
            else:
                if self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * cp * rho
                    ReportCoilSelection.setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
                elif (self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    self.autoSizedValue = (self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * cp * rho *
                                          self.termUnitSizing[self.curTermUnitSizingNum].ReheatLoadMult)
                elif self.zoneEqFanCoil or self.zoneEqUnitHeater:
                    cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * cp * rho
                    ReportCoilSelection.setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
                else:
                    des_mass_flow = 0.0
                    if self.zoneEqSizing[self.curZoneEqNum].SystemAirFlow:
                        des_mass_flow = self.zoneEqSizing[self.curZoneEqNum].AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing[self.curZoneEqNum].HeatingAirFlow:
                        des_mass_flow = self.zoneEqSizing[self.curZoneEqNum].HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        des_mass_flow = self.finalZoneSizing[self.curZoneEqNum].DesHeatMassFlow
                    
                    coil_in_temp = self.setHeatCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, des_mass_flow, self.zoneEqSizing[self.curZoneEqNum]),
                        self.zoneEqSizing[self.curZoneEqNum],
                        self.finalZoneSizing[self.curZoneEqNum]
                    )
                    coil_out_temp = self.finalZoneSizing[self.curZoneEqNum].HeatDesTemp
                    coil_out_hum_rat = self.finalZoneSizing[self.curZoneEqNum].HeatDesHumRat
                    self.autoSizedValue = Psychrometrics.PsyCpAirFnW(coil_out_hum_rat) * des_mass_flow * (coil_out_temp - coil_in_temp)
        
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = original_value
            else:
                out_air_frac = 1.0
                if self.curOASysNum > 0:
                    out_air_frac = 1.0
                elif self.finalSysSizing[self.curSysNum].HeatOAOption == self.minOA:
                    if self.dataAirFlowUsedForSizing > 0.0:
                        out_air_frac = self.finalSysSizing[self.curSysNum].DesOutAirVolFlow / self.dataAirFlowUsedForSizing
                        out_air_frac = min(1.0, max(0.0, out_air_frac))
                    else:
                        out_air_frac = 1.0
                else:
                    out_air_frac = 1.0
                
                coil_in_temp = 0.0
                if self.curOASysNum == 0 and self.primaryAirSystem[self.curSysNum].NumOAHeatCoils > 0:
                    coil_in_temp = (out_air_frac * self.finalSysSizing[self.curSysNum].PreheatTemp +
                                   (1.0 - out_air_frac) * self.finalSysSizing[self.curSysNum].HeatRetTemp)
                elif self.curOASysNum > 0 and self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                    coil_in_temp = self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].HeatOutTemp
                else:
                    coil_in_temp = (out_air_frac * self.finalSysSizing[self.curSysNum].HeatOutTemp +
                                   (1.0 - out_air_frac) * self.finalSysSizing[self.curSysNum].HeatRetTemp)
                
                cp_air_std = Psychrometrics.PsyCpAirFnW(0.0)
                if self.curOASysNum > 0:
                    if self.dataDesicRegCoil:
                        self.autoSizedValue = (cp_air_std * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing *
                                              (self.dataDesOutletAirTemp - self.dataDesInletAirTemp))
                    elif self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                        self.autoSizedValue = (cp_air_std * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing *
                                              (self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].PreheatTemp - coil_in_temp))
                    else:
                        self.autoSizedValue = (cp_air_std * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing *
                                              (self.finalSysSizing[self.curSysNum].PreheatTemp - coil_in_temp))
                else:
                    if self.finalSysSizing[self.curSysNum].HeatingCapMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                        self.dataFracOfAutosizedHeatingCapacity = self.finalSysSizing[self.curSysNum].FractionOfAutosizedHeatingCapacity
                    if self.dataDesicRegCoil:
                        self.autoSizedValue = (cp_air_std * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing *
                                              (self.dataDesOutletAirTemp - self.dataDesInletAirTemp))
                    else:
                        self.autoSizedValue = (cp_air_std * state.dataEnvrn.StdRhoAir * self.dataAirFlowUsedForSizing *
                                              (self.finalSysSizing[self.curSysNum].HeatSupTemp - coil_in_temp))
        
        self.autoSizedValue = max(0.0, self.autoSizedValue) * self.dataHeatSizeRatio * self.dataFracOfAutosizedHeatingCapacity
        
        if self.overrideSizeString:
            self.sizingString = "Water Heating Design Coil Load for UA Sizing [W]"
        
        self.selectSizerOutput(state, errors_found)
        
        if self.isCoilReportObject and self.curSysNum <= self.numPrimaryAirSys:
            fan_cool_load = 0.0
            tot_cap_temp_mod_fac = 1.0
            dx_flow_per_cap_min_ratio = 1.0
            dx_flow_per_cap_max_ratio = 1.0
            ReportCoilSelection.setCoilHeatingCapacity(
                state,
                self.coilReportNum,
                self.autoSizedValue,
                self.wasAutoSized,
                self.curSysNum,
                self.curZoneEqNum,
                self.curOASysNum,
                fan_cool_load,
                tot_cap_temp_mod_fac,
                dx_flow_per_cap_min_ratio,
                dx_flow_per_cap_max_ratio
            )
        
        return self.autoSizedValue
