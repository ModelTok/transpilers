from typing import Protocol
from enum import Enum
import math
from dataclasses import dataclass

# EXTERNAL DEPS (to wire in glue):
# - BaseSizerWithScalableInputs: base class from Autosizing module
# - EnergyPlusData: state parameter containing data.dataSize, data.dataEnvrn, data.dataGlobal, data.dataHVACGlobal,
#     data.dataCurveManager, data.dataFans, data.dataLoopNodes
# - Util.SameString: case-insensitive string comparison from Utilities
# - Psychrometrics module: PsyHFnTdbW, PsyTwbFnTdbWPb, PsyCpAirFnW, PsyTdpFnWPb
# - Curve module: CurveValue function
# - VariableSpeedCoils module: GetVSCoilRatedSourceTemp function
# - HVAC module: SmallAirVolFlow, CoilType enum, FanPlace enum, FanType enum, MinRatedVolFlowPerRatedTotCap, MaxRatedVolFlowPerRatedTotCap
# - DataSizing module: FractionOfAutosizedCoolingCapacity, CapacityPerFloorArea, CoolingDesignCapacity, FractionOfAutosizedHeatingCapacity constants
# - SimAirServingZones module: CompType enum with Fan_ComponentModel, Fan_System_Object
# - ShowWarningMessage, ShowContinueError, ShowSevereError: error reporting functions
# - ReportCoilSelection module: isCompTypeCoil, setCoilEntAirHumRat, setCoilEntAirTemp, setCoilLvgAirTemp, setCoilLvgAirHumRat, setCoilCoolingCapacity
# - CheckSysSizing: function to check system sizing


class BaseSizerWithScalableInputs:
    def __init__(self):
        self.sizingType = None
        self.sizingString = ""
        self.autoSizedValue = 0.0
        self.originalValue = 0.0
        
    def checkInitialized(self, state, errors_found):
        pass
    
    def preSize(self, state, original_value):
        pass
    
    def clearState(self):
        pass
    
    def selectSizerOutput(self, state, errors_found):
        pass
    
    def calcFanDesHeatGain(self, vol_flow):
        return 0.0
    
    def addErrorMessage(self, msg):
        pass


class CoolingCapacitySizer(BaseSizerWithScalableInputs):
    def __init__(self):
        super().__init__()
        self.sizingType = "CoolingCapacitySizing"
        self.sizingString = "Cooling Design Capacity [W]"
        
        self.dataEMSOverrideON = False
        self.dataEMSOverride = 0.0
        self.dataConstantUsedForSizing = 0.0
        self.dataFractionUsedForSizing = 0.0
        self.curZoneEqNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.zoneEqSizing = {}
        self.termUnitIU = False
        self.curTermUnitSizingNum = 0
        self.termUnitSizing = {}
        self.zoneEqFanCoil = False
        self.finalZoneSizing = {}
        self.compType = ""
        self.compName = ""
        self.dataFlowUsedForSizing = 0.0
        self.dataDesAccountForFanHeat = False
        self.dataCoolCoilType = None
        self.dataCoolCoilIndex = 0
        self.dataTotCapCurveIndex = 0
        self.dataTotCapCurveValue = 0.0
        self.dataFracOfAutosizedCoolingCapacity = 1.0
        self.callingRoutine = ""
        self.curSysNum = 0
        self.sizingDesRunThisAirSys = False
        self.oaSysFlag = False
        self.curOASysNum = 0
        self.oaSysEqSizing = {}
        self.airLoopSysFlag = False
        self.unitarySysEqSizing = {}
        self.coilReportNum = 0
        self.outsideAirSys = {}
        self.airloopDOAS = {}
        self.deltaP = 0.0
        self.motEff = 0.0
        self.totEff = 0.0
        self.motInAirFrac = 0.0
        self.fanShaftPow = 0.0
        self.motInPower = 0.0
        self.fanCompModel = None
        self.dataFanType = None
        self.dataFanIndex = 0
        self.primaryAirSystem = {}
        self.finalSysSizing = {}
        self.dataNonZoneNonAirloopValue = 0.0
        self.dataIsDXCoil = False
        self.printWarningFlag = False
        self.hardSizeNoDesignRun = False
        self.dataScalableSizingON = False
        self.dataScalableCapSizingON = False
        self.overrideSizeString = False
        self.sizingStringScalable = ""
        self.isCoilReportObject = False
        self.dataAirFlowUsedForSizing = 0.0
        self.dataDesOutletAirTemp = 0.0
        self.dataDesOutletAirHumRat = 0.0
        self.dataDesInletAirTemp = 0.0
        self.dataDesInletAirHumRat = 0.0
        self.dataDXCoolsLowSpeedsAutozize = False

    def size(self, state, original_value, errors_found):
        if not self.checkInitialized(state, errors_found):
            return 0.0
        
        self.preSize(state, original_value)
        
        des_vol_flow = 0.0
        coil_in_temp = -999.0
        coil_in_hum_rat = -999.0
        coil_out_temp = -999.0
        coil_out_hum_rat = -999.0
        fan_cool_load = 0.0
        tot_cap_temp_mod_fac = 1.0
        dx_flow_per_cap_min_ratio = 1.0
        dx_flow_per_cap_max_ratio = 1.0

        if self.dataEMSOverrideON:
            self.autoSizedValue = self.dataEMSOverride
        elif self.dataConstantUsedForSizing >= 0 and self.dataFractionUsedForSizing > 0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = original_value
                elif self.zoneEqSizing.get(self.curZoneEqNum, {}).get('DesignSizeFromParent', False):
                    self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum]['DesCoolingLoad']
                else:
                    if self.zoneEqSizing.get(self.curZoneEqNum, {}).get('CoolingCapacity', False):
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum]['DesCoolingLoad']
                        des_vol_flow = self.dataFlowUsedForSizing
                        coil_in_temp = state.dataSize.DataCoilSizingAirInTemp
                        coil_in_hum_rat = state.dataSize.DataCoilSizingAirInHumRat
                        coil_out_temp = state.dataSize.DataCoilSizingAirOutTemp
                        coil_out_hum_rat = state.dataSize.DataCoilSizingAirOutHumRat
                        fan_cool_load = state.dataSize.DataCoilSizingFanCoolLoad
                        tot_cap_temp_mod_fac = state.dataSize.DataCoilSizingCapFT
                    else:
                        if (same_string(self.compType, "COIL:COOLING:WATER") or
                            same_string(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY") or
                            same_string(self.compType, "ZONEHVAC:IDEALLOADSAIRSYSTEM")):
                            if self.termUnitIU and self.curTermUnitSizingNum > 0:
                                self.autoSizedValue = self.termUnitSizing[self.curTermUnitSizingNum]['DesCoolingLoad']
                            elif self.zoneEqFanCoil:
                                self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum]['DesCoolingLoad']
                            else:
                                coil_in_temp = self.finalZoneSizing[self.curZoneEqNum]['DesCoolCoilInTemp']
                                coil_in_hum_rat = self.finalZoneSizing[self.curZoneEqNum]['DesCoolCoilInHumRat']
                                coil_out_temp = min(coil_in_temp, self.finalZoneSizing[self.curZoneEqNum]['CoolDesTemp'])
                                coil_out_hum_rat = min(coil_in_hum_rat, self.finalZoneSizing[self.curZoneEqNum]['CoolDesHumRat'])
                                self.autoSizedValue = (
                                    self.finalZoneSizing[self.curZoneEqNum]['DesCoolMassFlow'] *
                                    (psy_h_fn_tdb_w(coil_in_temp, coil_in_hum_rat) - psy_h_fn_tdb_w(coil_out_temp, coil_out_hum_rat))
                                )
                                des_vol_flow = self.finalZoneSizing[self.curZoneEqNum]['DesCoolMassFlow'] / state.dataEnvrn.StdRhoAir
                                fan_cool_load += self.calcFanDesHeatGain(des_vol_flow)
                                self.autoSizedValue += fan_cool_load
                        else:
                            des_vol_flow = self.dataFlowUsedForSizing
                            if des_vol_flow >= state.HVAC.SmallAirVolFlow:
                                if state.dataSize.ZoneEqDXCoil:
                                    if self.zoneEqSizing[self.curZoneEqNum].get('ATMixerVolFlow', 0.0) > 0.0:
                                        des_mass_flow = des_vol_flow * state.dataEnvrn.StdRhoAir
                                        coil_in_temp = set_cool_coil_inlet_temp_for_zone_eq_sizing(
                                            set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zoneEqSizing[self.curZoneEqNum]),
                                            self.zoneEqSizing[self.curZoneEqNum],
                                            self.finalZoneSizing[self.curZoneEqNum]
                                        )
                                        coil_in_hum_rat = set_cool_coil_inlet_hum_rat_for_zone_eq_sizing(
                                            set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zoneEqSizing[self.curZoneEqNum]),
                                            self.zoneEqSizing[self.curZoneEqNum],
                                            self.finalZoneSizing[self.curZoneEqNum]
                                        )
                                    elif self.zoneEqSizing[self.curZoneEqNum].get('OAVolFlow', 0.0) > 0.0:
                                        coil_in_temp = self.finalZoneSizing[self.curZoneEqNum]['DesCoolCoilInTemp']
                                        coil_in_hum_rat = self.finalZoneSizing[self.curZoneEqNum]['DesCoolCoilInHumRat']
                                    else:
                                        coil_in_temp = self.finalZoneSizing[self.curZoneEqNum]['ZoneRetTempAtCoolPeak']
                                        coil_in_hum_rat = self.finalZoneSizing[self.curZoneEqNum]['ZoneHumRatAtCoolPeak']
                                elif self.zoneEqFanCoil:
                                    des_mass_flow = self.finalZoneSizing[self.curZoneEqNum]['DesCoolMassFlow']
                                    coil_in_temp = set_cool_coil_inlet_temp_for_zone_eq_sizing(
                                        set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zoneEqSizing[self.curZoneEqNum]),
                                        self.zoneEqSizing[self.curZoneEqNum],
                                        self.finalZoneSizing[self.curZoneEqNum]
                                    )
                                    coil_in_hum_rat = set_cool_coil_inlet_hum_rat_for_zone_eq_sizing(
                                        set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, self.zoneEqSizing[self.curZoneEqNum]),
                                        self.zoneEqSizing[self.curZoneEqNum],
                                        self.finalZoneSizing[self.curZoneEqNum]
                                    )
                                else:
                                    coil_in_temp = self.finalZoneSizing[self.curZoneEqNum]['DesCoolCoilInTemp']
                                    coil_in_hum_rat = self.finalZoneSizing[self.curZoneEqNum]['DesCoolCoilInHumRat']
                                
                                coil_out_temp = min(coil_in_temp, self.finalZoneSizing[self.curZoneEqNum]['CoolDesTemp'])
                                coil_out_hum_rat = min(coil_in_hum_rat, self.finalZoneSizing[self.curZoneEqNum]['CoolDesHumRat'])
                                time_step_num_at_max = self.finalZoneSizing[self.curZoneEqNum]['TimeStepNumAtCoolMax']
                                dd_num = self.finalZoneSizing[self.curZoneEqNum]['CoolDDNum']
                                out_temp = 0.0
                                if dd_num > 0 and time_step_num_at_max > 0:
                                    out_temp = state.dataSize.DesDayWeath[dd_num].Temp[time_step_num_at_max]
                                
                                if self.dataCoolCoilType == state.HVAC.CoilType.CoolingWAHPVariableSpeedEquationFit:
                                    out_temp = get_vs_coil_rated_source_temp(state, self.dataCoolCoilIndex)
                                
                                coil_in_enth = psy_h_fn_tdb_w(coil_in_temp, coil_in_hum_rat)
                                coil_out_enth = psy_h_fn_tdb_w(coil_out_temp, coil_out_hum_rat)
                                peak_coil_load = max(0.0, state.dataEnvrn.StdRhoAir * des_vol_flow * (coil_in_enth - coil_out_enth))
                                fan_cool_load += self.calcFanDesHeatGain(des_vol_flow)
                                peak_coil_load += fan_cool_load
                                
                                cp_air = psy_cp_air_fn_w(coil_in_hum_rat)
                                if self.dataDesAccountForFanHeat:
                                    if state.dataSize.DataFanPlacement == state.HVAC.FanPlace.BlowThru:
                                        coil_in_temp += fan_cool_load / (cp_air * state.dataEnvrn.StdRhoAir * des_vol_flow)
                                    elif state.dataSize.DataFanPlacement == state.HVAC.FanPlace.DrawThru:
                                        coil_out_temp -= fan_cool_load / (cp_air * state.dataEnvrn.StdRhoAir * des_vol_flow)
                                
                                coil_in_wet_bulb = psy_twb_fn_tdb_w_pb(state, coil_in_temp, coil_in_hum_rat, state.dataEnvrn.StdBaroPress, self.callingRoutine)
                                
                                if self.dataTotCapCurveIndex > 0:
                                    num_dims = state.dataCurveManager.curves[self.dataTotCapCurveIndex].numDims
                                    if num_dims == 1:
                                        tot_cap_temp_mod_fac = curve_value(state, self.dataTotCapCurveIndex, coil_in_wet_bulb)
                                    else:
                                        tot_cap_temp_mod_fac = curve_value(state, self.dataTotCapCurveIndex, coil_in_wet_bulb, out_temp)
                                elif self.dataTotCapCurveValue > 0:
                                    tot_cap_temp_mod_fac = self.dataTotCapCurveValue
                                else:
                                    tot_cap_temp_mod_fac = 1.0
                                
                                if tot_cap_temp_mod_fac > 0.0:
                                    self.autoSizedValue = peak_coil_load / tot_cap_temp_mod_fac
                                else:
                                    self.autoSizedValue = peak_coil_load
                                
                                state.dataSize.DataCoilSizingAirInTemp = coil_in_temp
                                state.dataSize.DataCoilSizingAirInHumRat = coil_in_hum_rat
                                state.dataSize.DataCoilSizingAirOutTemp = coil_out_temp
                                state.dataSize.DataCoilSizingAirOutHumRat = coil_out_hum_rat
                                state.dataSize.DataCoilSizingFanCoolLoad = fan_cool_load
                                state.dataSize.DataCoilSizingCapFT = tot_cap_temp_mod_fac
                            else:
                                self.autoSizedValue = 0.0
                                coil_out_temp = -999.0
                    
                    self.autoSizedValue = self.autoSizedValue * self.dataFracOfAutosizedCoolingCapacity
                    self.dataDesAccountForFanHeat = True
                    
                    if state.dataGlobal.DisplayExtraWarnings and self.autoSizedValue <= 0.0:
                        show_warning_message(state, self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName)
                        show_continue_error(state, f"...Rated Total Cooling Capacity = {self.autoSizedValue:.2f} [W]")
                        
                        if self.zoneEqSizing.get(self.curZoneEqNum, {}).get('CoolingCapacity', False):
                            show_continue_error(state, f"...Capacity passed by parent object to size child component = {self.autoSizedValue:.2f} [W]")
                        else:
                            if (same_string(self.compType, "COIL:COOLING:WATER") or
                                same_string(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY") or
                                same_string(self.compType, "ZONEHVAC:IDEALLOADSAIRSYSTEM")):
                                if self.termUnitIU or self.zoneEqFanCoil:
                                    show_continue_error(state, f"...Capacity passed by parent object to size child component = {self.autoSizedValue:.2f} [W]")
                                else:
                                    show_continue_error(state, f"...Air flow rate used for sizing = {des_vol_flow:.5f} [m3/s]")
                                    show_continue_error(state, f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]")
                                    show_continue_error(state, f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]")
                            else:
                                if coil_out_temp > -999.0:
                                    show_continue_error(state, f"...Air flow rate used for sizing = {des_vol_flow:.5f} [m3/s]")
                                    show_continue_error(state, f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]")
                                    show_continue_error(state, f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]")
                                else:
                                    show_continue_error(state, "...Capacity used to size child component set to 0 [W]")
            
            elif self.curSysNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                    self.autoSizedValue = original_value
                else:
                    out_air_frac = 0.0
                    self.dataFracOfAutosizedCoolingCapacity = 1.0
                    
                    if self.oaSysFlag:
                        self.autoSizedValue = self.oaSysEqSizing[self.curOASysNum]['DesCoolingLoad']
                        des_vol_flow = self.dataFlowUsedForSizing
                    elif self.airLoopSysFlag:
                        self.autoSizedValue = self.unitarySysEqSizing[self.curSysNum]['DesCoolingLoad']
                        des_vol_flow = self.dataFlowUsedForSizing
                        coil_in_temp = state.dataSize.DataCoilSizingAirInTemp
                        coil_in_hum_rat = state.dataSize.DataCoilSizingAirInHumRat
                        coil_out_temp = state.dataSize.DataCoilSizingAirOutTemp
                        coil_out_hum_rat = state.dataSize.DataCoilSizingAirOutHumRat
                        fan_cool_load = state.dataSize.DataCoilSizingFanCoolLoad
                        tot_cap_temp_mod_fac = state.dataSize.DataCoilSizingCapFT
                        
                        if is_comp_type_coil(self.compType):
                            set_coil_ent_air_hum_rat(state, self.coilReportNum, coil_in_hum_rat)
                            set_coil_ent_air_temp(state, self.coilReportNum, coil_in_temp, self.curSysNum, self.curZoneEqNum)
                            set_coil_lvg_air_temp(state, self.coilReportNum, coil_out_temp)
                            set_coil_lvg_air_hum_rat(state, self.coilReportNum, coil_out_hum_rat)
                    
                    elif self.curOASysNum > 0 and self.outsideAirSys[self.curOASysNum].get('AirLoopDOASNum', -1) > -1:
                        this_airloop_doas = self.airloopDOAS[self.outsideAirSys[self.curOASysNum]['AirLoopDOASNum']]
                        des_vol_flow = this_airloop_doas['SizingMassFlow'] / state.dataEnvrn.StdRhoAir
                        coil_in_temp = this_airloop_doas['SizingCoolOATemp']
                        coil_out_temp = this_airloop_doas['PrecoolTemp']
                        
                        if this_airloop_doas['m_FanIndex'] > 0:
                            fan_index = this_airloop_doas['m_FanIndex']
                            state.dataFans.fans[fan_index].getInputsForDesignHeatGain(
                                state, self.deltaP, self.motEff, self.totEff, self.motInAirFrac,
                                self.fanShaftPow, self.motInPower, self.fanCompModel
                            )
                            
                            if this_airloop_doas['m_FanTypeNum'] == state.SimAirServingZones.CompType.Fan_ComponentModel:
                                fan_cool_load = self.fanShaftPow + (self.motInPower - self.fanShaftPow) * self.motInAirFrac
                            elif this_airloop_doas['m_FanTypeNum'] == state.SimAirServingZones.CompType.Fan_System_Object:
                                fan_power_tot = (des_vol_flow * self.deltaP) / self.totEff
                                fan_cool_load = self.motEff * fan_power_tot + (fan_power_tot - self.motEff * fan_power_tot) * self.motInAirFrac
                            
                            self.dataFanType = state.dataFans.fans[fan_index].type
                            self.dataFanIndex = fan_index
                            
                            cp_air = psy_cp_air_fn_w(state.dataLoopNodes.Node[this_airloop_doas['m_FanInletNodeNum']].HumRat)
                            delta_t = fan_cool_load / (this_airloop_doas['SizingMassFlow'] * cp_air)
                            
                            if this_airloop_doas['FanBeforeCoolingCoilFlag']:
                                coil_in_temp += delta_t
                            else:
                                coil_out_temp -= delta_t
                                coil_out_temp = max(coil_out_temp, psy_tdp_fn_w_pb(state, this_airloop_doas['PrecoolHumRat'], state.dataEnvrn.StdBaroPress))
                        
                        coil_in_hum_rat = this_airloop_doas['SizingCoolOAHumRat']
                        coil_out_hum_rat = this_airloop_doas['PrecoolHumRat']
                        self.autoSizedValue = (
                            des_vol_flow * state.dataEnvrn.StdRhoAir *
                            (psy_h_fn_tdb_w(coil_in_temp, coil_in_hum_rat) - psy_h_fn_tdb_w(coil_out_temp, coil_out_hum_rat))
                        )
                    
                    else:
                        check_sys_sizing(state, self.compType, self.compName)
                        this_final_sys_sizing = self.finalSysSizing[self.curSysNum]
                        des_vol_flow = self.dataFlowUsedForSizing
                        nominal_capacity_des = 0.0
                        
                        if this_final_sys_sizing.get('CoolingCapMethod') == state.DataSizing.FractionOfAutosizedCoolingCapacity:
                            self.dataFracOfAutosizedCoolingCapacity = this_final_sys_sizing['FractionOfAutosizedCoolingCapacity']
                        
                        if this_final_sys_sizing.get('CoolingCapMethod') == state.DataSizing.CapacityPerFloorArea:
                            nominal_capacity_des = this_final_sys_sizing['CoolingTotalCapacity']
                            self.autoSizedValue = nominal_capacity_des
                        elif (this_final_sys_sizing.get('CoolingCapMethod') == state.DataSizing.CoolingDesignCapacity and
                              this_final_sys_sizing.get('CoolingTotalCapacity', 0.0) > 0.0):
                            nominal_capacity_des = this_final_sys_sizing['CoolingTotalCapacity']
                            self.autoSizedValue = nominal_capacity_des
                        elif des_vol_flow >= state.HVAC.SmallAirVolFlow:
                            if des_vol_flow > 0.0:
                                out_air_frac = this_final_sys_sizing['DesOutAirVolFlow'] / des_vol_flow
                            else:
                                out_air_frac = 1.0
                            out_air_frac = min(1.0, max(0.0, out_air_frac))
                            
                            if self.curOASysNum > 0:
                                coil_in_temp = this_final_sys_sizing['OutTempAtCoolPeak']
                                coil_in_hum_rat = this_final_sys_sizing['OutHumRatAtCoolPeak']
                                coil_out_temp = this_final_sys_sizing['PrecoolTemp']
                                coil_out_hum_rat = this_final_sys_sizing['PrecoolHumRat']
                            else:
                                if self.dataAirFlowUsedForSizing > 0.0:
                                    des_vol_flow = self.dataAirFlowUsedForSizing
                                if self.dataDesOutletAirTemp > 0.0:
                                    coil_out_temp = self.dataDesOutletAirTemp
                                else:
                                    coil_out_temp = this_final_sys_sizing['CoolSupTemp']
                                if self.dataDesOutletAirHumRat > 0.0:
                                    coil_out_hum_rat = self.dataDesOutletAirHumRat
                                else:
                                    coil_out_hum_rat = this_final_sys_sizing['CoolSupHumRat']
                                
                                if self.primaryAirSystem[self.curSysNum].get('NumOACoolCoils', 0) == 0:
                                    coil_in_temp = this_final_sys_sizing['MixTempAtCoolPeak']
                                    coil_in_hum_rat = this_final_sys_sizing['MixHumRatAtCoolPeak']
                                else:
                                    if des_vol_flow > 0.0:
                                        out_air_frac = this_final_sys_sizing['DesOutAirVolFlow'] / des_vol_flow
                                    else:
                                        out_air_frac = 1.0
                                    out_air_frac = min(1.0, max(0.0, out_air_frac))
                                    coil_in_temp = (out_air_frac * this_final_sys_sizing['PrecoolTemp'] +
                                                    (1.0 - out_air_frac) * this_final_sys_sizing['RetTempAtCoolPeak'])
                                    coil_in_hum_rat = (out_air_frac * this_final_sys_sizing['PrecoolHumRat'] +
                                                       (1.0 - out_air_frac) * this_final_sys_sizing['RetHumRatAtCoolPeak'])
                                
                                if self.dataDesInletAirTemp > 0.0:
                                    coil_in_temp = self.dataDesInletAirTemp
                                if self.dataDesInletAirHumRat > 0.0:
                                    coil_in_hum_rat = self.dataDesInletAirHumRat
                            
                            out_temp = this_final_sys_sizing['OutTempAtCoolPeak']
                            if self.dataCoolCoilType == state.HVAC.CoilType.CoolingWAHPVariableSpeedEquationFit:
                                out_temp = get_vs_coil_rated_source_temp(state, self.dataCoolCoilIndex)
                            
                            coil_out_temp = min(coil_in_temp, coil_out_temp)
                            coil_out_hum_rat = min(coil_in_hum_rat, coil_out_hum_rat)
                            
                            coil_in_enth = psy_h_fn_tdb_w(coil_in_temp, coil_in_hum_rat)
                            coil_in_wet_bulb = psy_twb_fn_tdb_w_pb(state, coil_in_temp, coil_in_hum_rat, state.dataEnvrn.StdBaroPress, self.callingRoutine)
                            coil_out_enth = psy_h_fn_tdb_w(coil_out_temp, coil_out_hum_rat)
                            
                            if self.curOASysNum > 0:
                                pass
                            else:
                                if self.primaryAirSystem[self.curSysNum].get('supFanType') != state.HVAC.FanType.Invalid:
                                    fan_cool_load = self.calcFanDesHeatGain(des_vol_flow)
                                if self.primaryAirSystem[self.curSysNum].get('retFanType') != state.HVAC.FanType.Invalid:
                                    fan_cool_load += (1.0 - out_air_frac) * self.calcFanDesHeatGain(des_vol_flow)
                                self.primaryAirSystem[self.curSysNum]['FanDesCoolLoad'] = fan_cool_load
                            
                            peak_coil_load = max(0.0, state.dataEnvrn.StdRhoAir * des_vol_flow * (coil_in_enth - coil_out_enth))
                            cp_air = psy_cp_air_fn_w(coil_in_hum_rat)
                            
                            if self.dataDesAccountForFanHeat:
                                peak_coil_load = max(0.0, state.dataEnvrn.StdRhoAir * des_vol_flow * (coil_in_enth - coil_out_enth) + fan_cool_load)
                                if self.primaryAirSystem[self.curSysNum].get('supFanPlace') == state.HVAC.FanPlace.BlowThru:
                                    coil_in_temp += fan_cool_load / (cp_air * state.dataEnvrn.StdRhoAir * des_vol_flow)
                                    coil_in_wet_bulb = psy_twb_fn_tdb_w_pb(state, coil_in_temp, coil_in_hum_rat, state.dataEnvrn.StdBaroPress, self.callingRoutine)
                                elif self.primaryAirSystem[self.curSysNum].get('supFanPlace') == state.HVAC.FanPlace.DrawThru:
                                    coil_out_temp -= fan_cool_load / (cp_air * state.dataEnvrn.StdRhoAir * des_vol_flow)
                            
                            if self.dataTotCapCurveIndex > 0:
                                num_dims = state.dataCurveManager.curves[self.dataTotCapCurveIndex].numDims
                                if num_dims == 1:
                                    tot_cap_temp_mod_fac = curve_value(state, self.dataTotCapCurveIndex, coil_in_wet_bulb)
                                else:
                                    tot_cap_temp_mod_fac = curve_value(state, self.dataTotCapCurveIndex, coil_in_wet_bulb, out_temp)
                            else:
                                tot_cap_temp_mod_fac = 1.0
                            
                            if tot_cap_temp_mod_fac > 0.0:
                                nominal_capacity_des = peak_coil_load / tot_cap_temp_mod_fac
                            else:
                                nominal_capacity_des = peak_coil_load
                            
                            state.dataSize.DataCoilSizingAirInTemp = coil_in_temp
                            state.dataSize.DataCoilSizingAirInHumRat = coil_in_hum_rat
                            state.dataSize.DataCoilSizingAirOutTemp = coil_out_temp
                            state.dataSize.DataCoilSizingAirOutHumRat = coil_out_hum_rat
                            state.dataSize.DataCoilSizingFanCoolLoad = fan_cool_load
                            state.dataSize.DataCoilSizingCapFT = tot_cap_temp_mod_fac
                        else:
                            nominal_capacity_des = 0.0
                        
                        self.autoSizedValue = nominal_capacity_des * self.dataFracOfAutosizedCoolingCapacity
                    
                    self.dataDesAccountForFanHeat = True
                    
                    if state.dataGlobal.DisplayExtraWarnings and self.autoSizedValue <= 0.0:
                        show_warning_message(state, self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName)
                        show_continue_error(state, f"...Rated Total Cooling Capacity = {self.autoSizedValue:.2f} [W]")
                        
                        if (self.oaSysFlag or self.airLoopSysFlag or
                            this_final_sys_sizing.get('CoolingCapMethod') == state.DataSizing.CapacityPerFloorArea or
                            (this_final_sys_sizing.get('CoolingCapMethod') == state.DataSizing.CoolingDesignCapacity and
                             this_final_sys_sizing.get('CoolingTotalCapacity', 0.0) != 0.0)):
                            show_continue_error(state, f"...Capacity passed by parent object to size child component = {self.autoSizedValue:.2f} [W]")
                        else:
                            show_continue_error(state, f"...Air flow rate used for sizing = {des_vol_flow:.5f} [m3/s]")
                            show_continue_error(state, f"...Outdoor air fraction used for sizing = {out_air_frac:.2f}")
                            show_continue_error(state, f"...Coil inlet air temperature used for sizing = {coil_in_temp:.2f} [C]")
                            show_continue_error(state, f"...Coil outlet air temperature used for sizing = {coil_out_temp:.2f} [C]")
            
            elif self.dataNonZoneNonAirloopValue > 0:
                self.autoSizedValue = self.dataNonZoneNonAirloopValue
            elif not self.wasAutoSized:
                self.autoSizedValue = self.originalValue
            else:
                msg = self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                show_severe_error(state, msg)
                self.addErrorMessage(msg)
                msg = f"SizingString = {self.sizingString}, SizingResult = {self.autoSizedValue:.1f}"
                show_continue_error(state, msg)
                self.addErrorMessage(msg)
                errors_found[0] = True
        
        if self.dataDXCoolsLowSpeedsAutozize:
            self.autoSizedValue *= self.dataFractionUsedForSizing
        
        if not self.hardSizeNoDesignRun or self.dataScalableSizingON or self.dataScalableCapSizingON:
            if self.wasAutoSized:
                flag_check_vol_flow_per_rated_tot_cap = True
                if (same_string(self.compType, "Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl") or
                    same_string(self.compType, "Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl")):
                    flag_check_vol_flow_per_rated_tot_cap = False
                
                if self.dataIsDXCoil and flag_check_vol_flow_per_rated_tot_cap:
                    rated_vol_flow_per_rated_tot_cap = 0.0
                    if self.autoSizedValue > 0.0:
                        rated_vol_flow_per_rated_tot_cap = des_vol_flow / self.autoSizedValue
                    
                    if rated_vol_flow_per_rated_tot_cap < state.HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag:
                            show_warning_error(state, self.callingRoutine + ' ' + self.compType + ' ' + self.compName)
                            show_continue_error(state, "..." + self.sizingString + " will be limited by the minimum rated volume flow per rated total capacity ratio.")
                            show_continue_error(state, f"...DX coil volume flow rate [m3/s] = {des_vol_flow:.6f}")
                            show_continue_error(state, f"...Requested capacity [W] = {self.autoSizedValue:.3f}")
                            show_continue_error(state, f"...Requested flow/capacity ratio [m3/s/W] = {rated_vol_flow_per_rated_tot_cap:.6e}")
                            show_continue_error(state, f"...Minimum flow/capacity ratio [m3/s/W] = {state.HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:.6e}")
                        
                        dx_flow_per_cap_min_ratio = ((des_vol_flow / state.HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]) /
                                                      self.autoSizedValue)
                        self.autoSizedValue = des_vol_flow / state.HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
                        
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag:
                            show_continue_error(state, f"...Adjusted capacity [W] = {self.autoSizedValue:.3f}")
                    
                    elif rated_vol_flow_per_rated_tot_cap > state.HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag:
                            show_warning_error(state, self.callingRoutine + ' ' + self.compType + ' ' + self.compName)
                            show_continue_error(state, "..." + self.sizingString + " will be limited by the maximum rated volume flow per rated total capacity ratio.")
                            show_continue_error(state, f"...DX coil volume flow rate [m3/s] = {des_vol_flow:.6f}")
                            show_continue_error(state, f"...Requested capacity [W] = {self.autoSizedValue:.3f}")
                            show_continue_error(state, f"...Requested flow/capacity ratio [m3/s/W] = {rated_vol_flow_per_rated_tot_cap:.6e}")
                            show_continue_error(state, f"...Maximum flow/capacity ratio [m3/s/W] = {state.HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:.6e}")
                        
                        dx_flow_per_cap_max_ratio = ((des_vol_flow / state.HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]) /
                                                      self.autoSizedValue)
                        self.autoSizedValue = des_vol_flow / state.HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
                        
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag:
                            show_continue_error(state, f"...Adjusted capacity [W] = {self.autoSizedValue:.3f}")
        
        if self.overrideSizeString:
            self.sizingString = "Cooling Design Capacity [W]"
        
        if self.dataScalableCapSizingON:
            select_case_var = self.zoneEqSizing[self.curZoneEqNum]['SizingMethod'][state.HVAC.CoolingCapacitySizing]
            if select_case_var == state.DataSizing.CapacityPerFloorArea:
                self.sizingStringScalable = "(scaled by capacity / area) "
            elif (select_case_var == state.DataSizing.FractionOfAutosizedHeatingCapacity or
                  select_case_var == state.DataSizing.FractionOfAutosizedCoolingCapacity):
                self.sizingStringScalable = "(scaled by fractional multiplier) "
        
        self.selectSizerOutput(state, errors_found)
        
        if self.isCoilReportObject and self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys:
            if coil_in_temp > -999.0:
                set_coil_ent_air_temp(state, self.coilReportNum, coil_in_temp, self.curSysNum, self.curZoneEqNum)
                set_coil_ent_air_hum_rat(state, self.coilReportNum, coil_in_hum_rat)
            if coil_out_temp > -999.0:
                set_coil_lvg_air_temp(state, self.coilReportNum, coil_out_temp)
                set_coil_lvg_air_hum_rat(state, self.coilReportNum, coil_out_hum_rat)
            set_coil_cooling_capacity(state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized,
                                     self.curSysNum, self.curZoneEqNum, self.curOASysNum,
                                     fan_cool_load, tot_cap_temp_mod_fac,
                                     dx_flow_per_cap_min_ratio, dx_flow_per_cap_max_ratio)
        
        return self.autoSizedValue
    
    def clearState(self):
        super().clearState()


def same_string(s1: str, s2: str) -> bool:
    return s1.upper() == s2.upper()


def psy_h_fn_tdb_w(tdb: float, w: float) -> float:
    pass


def psy_twb_fn_tdb_w_pb(state, tdb: float, w: float, pb: float, routine: str) -> float:
    pass


def psy_cp_air_fn_w(w: float) -> float:
    pass


def psy_tdp_fn_w_pb(state, w: float, pb: float) -> float:
    pass


def set_cool_coil_inlet_temp_for_zone_eq_sizing(oa_frac, zone_eq_sizing, final_zone_sizing) -> float:
    pass


def set_oa_frac_for_zone_eq_sizing(state, des_mass_flow, zone_eq_sizing) -> float:
    pass


def set_cool_coil_inlet_hum_rat_for_zone_eq_sizing(oa_frac, zone_eq_sizing, final_zone_sizing) -> float:
    pass


def curve_value(state, curve_index: int, *args) -> float:
    pass


def get_vs_coil_rated_source_temp(state, coil_index: int) -> float:
    pass


def show_warning_message(state, msg: str):
    pass


def show_continue_error(state, msg: str):
    pass


def show_severe_error(state, msg: str):
    pass


def show_warning_error(state, msg: str):
    pass


def is_comp_type_coil(comp_type: str) -> bool:
    pass


def set_coil_ent_air_hum_rat(state, report_num: int, hum_rat: float):
    pass


def set_coil_ent_air_temp(state, report_num: int, temp: float, sys_num: int, zone_num: int):
    pass


def set_coil_lvg_air_temp(state, report_num: int, temp: float):
    pass


def set_coil_lvg_air_hum_rat(state, report_num: int, hum_rat: float):
    pass


def set_coil_cooling_capacity(state, report_num: int, capacity: float, was_autosized: bool,
                             sys_num: int, zone_num: int, oa_sys_num: int,
                             fan_cool_load: float, tot_cap_temp_mod_fac: float,
                             dx_flow_per_cap_min_ratio: float, dx_flow_per_cap_max_ratio: float):
    pass


def check_sys_sizing(state, comp_type: str, comp_name: str):
    pass
