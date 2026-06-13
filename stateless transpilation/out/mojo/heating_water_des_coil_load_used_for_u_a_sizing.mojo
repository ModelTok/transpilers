# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data structures (from EnergyPlus.Data.EnergyPlusData)
# - BaseSizerWithScalableInputs: base struct (from EnergyPlus.Autosizing.BaseSizerWithScalableInputs)
# - AutoSizingType: enum (from EnergyPlus.Autosizing)
# - Constant: module with constants (from EnergyPlus)
# - Psychrometrics: module with functions (from EnergyPlus.Psychrometrics)
# - ReportCoilSelection: module with functions (from EnergyPlus.ReportCoilSelection)
# - DataSizing: enum/constants module (from EnergyPlus.DataSizing)

from math import max, min

trait Glycol:
    fn getSpecificHeat(self, state: EnergyPlusData, temp: Float64, routine: String) -> Float64:
        ...
    fn getDensity(self, state: EnergyPlusData, temp: Float64, routine: String) -> Float64:
        ...

struct PlantLoop:
    var glycol: Glycol

struct DataPlnt:
    var PlantLoop: DynamicVector[PlantLoop]

struct TermUnitSizing:
    var ReheatLoadMult: Float64

struct ZoneEqSizing:
    var SystemAirFlow: Bool
    var AirVolFlow: Float64
    var HeatingAirFlow: Bool
    var HeatingAirVolFlow: Float64

struct FinalZoneSizing:
    var DesHeatMassFlow: Float64
    var HeatDesTemp: Float64
    var HeatDesHumRat: Float64

struct PrimaryAirSystem:
    var NumOAHeatCoils: Int

struct OutsideAirSys:
    var AirLoopDOASNum: Int

struct AirloopDOAS:
    var HeatOutTemp: Float64
    var PreheatTemp: Float64

struct FinalSysSizing:
    var HeatOAOption: Int
    var DesOutAirVolFlow: Float64
    var PreheatTemp: Float64
    var HeatRetTemp: Float64
    var HeatOutTemp: Float64
    var HeatingCapMethod: Int
    var FractionOfAutosizedHeatingCapacity: Float64
    var HeatSupTemp: Float64

struct DataEnvrn:
    var StdRhoAir: Float64

struct EnergyPlusData:
    var dataPlnt: DataPlnt
    var dataEnvrn: DataEnvrn

struct Psychrometrics:
    @staticmethod
    fn PsyCpAirFnW(hum_rat: Float64) -> Float64:
        return 0.0

struct ReportCoilSelection:
    @staticmethod
    fn setCoilReheatMultiplier(state: EnergyPlusData, coil_num: Int, mult: Float64):
        pass
    
    @staticmethod
    fn setCoilHeatingCapacity(state: EnergyPlusData, coil_num: Int, capacity: Float64,
                             was_auto_sized: Bool, sys_num: Int, zone_eq_num: Int,
                             oa_sys_num: Int, fan_cool_load: Float64,
                             tot_cap_temp_mod_fac: Float64, dx_flow_per_cap_min_ratio: Float64,
                             dx_flow_per_cap_max_ratio: Float64):
        pass

struct Constant:
    alias HWInitConvTemp = 19.0

struct DataSizing:
    alias FractionOfAutosizedHeatingCapacity = 1

struct AutoSizingType:
    alias HeatingWaterDesCoilLoadUsedForUASizing = "HeatingWaterDesCoilLoadUsedForUASizing"

struct BaseSizerWithScalableInputs:
    fn checkInitialized(self, state: EnergyPlusData, inout errors_found: DynamicVector[Bool]) -> Bool:
        return True
    
    fn preSize(self, state: EnergyPlusData, value: Float64):
        pass
    
    fn selectSizerOutput(self, state: EnergyPlusData, inout errors_found: DynamicVector[Bool]):
        pass
    
    fn setOAFracForZoneEqSizing(self, state: EnergyPlusData, des_mass_flow: Float64,
                                zone_eq_sizing: ZoneEqSizing) -> Float64:
        return 0.0
    
    fn setHeatCoilInletTempForZoneEqSizing(self, oa_frac: Float64,
                                           zone_eq_sizing: ZoneEqSizing,
                                           final_zone_sizing: FinalZoneSizing) -> Float64:
        return 0.0

struct HeatingWaterDesCoilLoadUsedForUASizer(BaseSizerWithScalableInputs):
    var sizingType: String
    var sizingString: String
    var autoSizedValue: Float64
    var wasAutoSized: Bool
    var sizingDesRunThisZone: Bool
    var curZoneEqNum: Int
    var termUnitSingDuct: Bool
    var curTermUnitSizingNum: Int
    var dataWaterLoopNum: Int
    var dataWaterFlowUsedForSizing: Float64
    var dataWaterCoilSizHeatDeltaT: Float64
    var coilReportNum: Int
    var termUnitPIU: Bool
    var termUnitIU: Bool
    var termUnitSizing: DynamicVector[TermUnitSizing]
    var zoneEqFanCoil: Bool
    var zoneEqUnitHeater: Bool
    var zoneEqSizing: DynamicVector[ZoneEqSizing]
    var finalZoneSizing: DynamicVector[FinalZoneSizing]
    var sizingDesRunThisAirSys: Bool
    var curSysNum: Int
    var curOASysNum: Int
    var dataAirFlowUsedForSizing: Float64
    var primaryAirSystem: DynamicVector[PrimaryAirSystem]
    var outsideAirSys: DynamicVector[OutsideAirSys]
    var airloopDOAS: DynamicVector[AirloopDOAS]
    var dataDesicRegCoil: Bool
    var dataDesOutletAirTemp: Float64
    var dataDesInletAirTemp: Float64
    var finalSysSizing: DynamicVector[FinalSysSizing]
    var dataFracOfAutosizedHeatingCapacity: Float64
    var dataHeatSizeRatio: Float64
    var overrideSizeString: Bool
    var isCoilReportObject: Bool
    var numPrimaryAirSys: Int
    var callingRoutine: String
    var minOA: Int
    
    fn __init__(inout self):
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
        self.termUnitSizing = DynamicVector[TermUnitSizing]()
        self.zoneEqFanCoil = False
        self.zoneEqUnitHeater = False
        self.zoneEqSizing = DynamicVector[ZoneEqSizing]()
        self.finalZoneSizing = DynamicVector[FinalZoneSizing]()
        self.sizingDesRunThisAirSys = False
        self.curSysNum = 0
        self.curOASysNum = 0
        self.dataAirFlowUsedForSizing = 0.0
        self.primaryAirSystem = DynamicVector[PrimaryAirSystem]()
        self.outsideAirSys = DynamicVector[OutsideAirSys]()
        self.airloopDOAS = DynamicVector[AirloopDOAS]()
        self.dataDesicRegCoil = False
        self.dataDesOutletAirTemp = 0.0
        self.dataDesInletAirTemp = 0.0
        self.finalSysSizing = DynamicVector[FinalSysSizing]()
        self.dataFracOfAutosizedHeatingCapacity = 1.0
        self.dataHeatSizeRatio = 1.0
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.numPrimaryAirSys = 0
        self.callingRoutine = ""
        self.minOA = 0
    
    fn size(inout self, state: EnergyPlusData, original_value: Float64, inout errors_found: DynamicVector[Bool]) -> Float64:
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = original_value
            else:
                if self.termUnitSingDuct and (self.curTermUnitSizingNum > 0):
                    var cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    var rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * cp * rho
                    ReportCoilSelection.setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
                elif (self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    var cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    var rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    self.autoSizedValue = (self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * cp * rho *
                                          self.termUnitSizing[self.curTermUnitSizingNum].ReheatLoadMult)
                elif self.zoneEqFanCoil or self.zoneEqUnitHeater:
                    var cp = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getSpecificHeat(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    var rho = state.dataPlnt.PlantLoop[self.dataWaterLoopNum].glycol.getDensity(
                        state, Constant.HWInitConvTemp, self.callingRoutine
                    )
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.dataWaterCoilSizHeatDeltaT * cp * rho
                    ReportCoilSelection.setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
                else:
                    var des_mass_flow: Float64 = 0.0
                    if self.zoneEqSizing[self.curZoneEqNum].SystemAirFlow:
                        des_mass_flow = self.zoneEqSizing[self.curZoneEqNum].AirVolFlow * state.dataEnvrn.StdRhoAir
                    elif self.zoneEqSizing[self.curZoneEqNum].HeatingAirFlow:
                        des_mass_flow = self.zoneEqSizing[self.curZoneEqNum].HeatingAirVolFlow * state.dataEnvrn.StdRhoAir
                    else:
                        des_mass_flow = self.finalZoneSizing[self.curZoneEqNum].DesHeatMassFlow
                    
                    var coil_in_temp = self.setHeatCoilInletTempForZoneEqSizing(
                        self.setOAFracForZoneEqSizing(state, des_mass_flow, self.zoneEqSizing[self.curZoneEqNum]),
                        self.zoneEqSizing[self.curZoneEqNum],
                        self.finalZoneSizing[self.curZoneEqNum]
                    )
                    var coil_out_temp = self.finalZoneSizing[self.curZoneEqNum].HeatDesTemp
                    var coil_out_hum_rat = self.finalZoneSizing[self.curZoneEqNum].HeatDesHumRat
                    self.autoSizedValue = Psychrometrics.PsyCpAirFnW(coil_out_hum_rat) * des_mass_flow * (coil_out_temp - coil_in_temp)
        
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = original_value
            else:
                var out_air_frac: Float64 = 1.0
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
                
                var coil_in_temp: Float64 = 0.0
                if self.curOASysNum == 0 and self.primaryAirSystem[self.curSysNum].NumOAHeatCoils > 0:
                    coil_in_temp = (out_air_frac * self.finalSysSizing[self.curSysNum].PreheatTemp +
                                   (1.0 - out_air_frac) * self.finalSysSizing[self.curSysNum].HeatRetTemp)
                elif self.curOASysNum > 0 and self.outsideAirSys[self.curOASysNum].AirLoopDOASNum > -1:
                    coil_in_temp = self.airloopDOAS[self.outsideAirSys[self.curOASysNum].AirLoopDOASNum].HeatOutTemp
                else:
                    coil_in_temp = (out_air_frac * self.finalSysSizing[self.curSysNum].HeatOutTemp +
                                   (1.0 - out_air_frac) * self.finalSysSizing[self.curSysNum].HeatRetTemp)
                
                var cp_air_std = Psychrometrics.PsyCpAirFnW(0.0)
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
            var fan_cool_load: Float64 = 0.0
            var tot_cap_temp_mod_fac: Float64 = 1.0
            var dx_flow_per_cap_min_ratio: Float64 = 1.0
            var dx_flow_per_cap_max_ratio: Float64 = 1.0
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
