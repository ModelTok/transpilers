from collections import InlineArray
from math import min, max, abs

struct CoilSelectionData:
    var coil_name_: String
    var coil_type: Int
    var is_cooling: Bool
    var is_heating: Bool
    var coil_location: String
    var des_day_name_at_sens_peak: String
    var coil_sense_peak_hr_min: String
    var des_day_name_at_total_peak: String
    var coil_total_peak_hr_min: String
    var des_day_name_at_air_flow_peak: String
    var air_peak_hr_min: String
    
    var coil_num: Int
    var airloop_num: Int
    var oa_controller_num: Int
    var zone_eq_num: Int
    var oa_sys_num: Int
    var zone_num: DynamicVector[Int]
    var zone_name: DynamicVector[String]
    var type_hvac_name: String
    var user_name_for_hvac_system: String
    var zone_hvac_type_num: Int
    var zone_hvac_index: Int
    var typeof_coil: Int
    
    var coil_sizing_method_concurrence: Int
    var coil_sizing_method_concurrence_name: String
    
    var coil_sizing_method_capacity: Int
    var coil_sizing_method_capacity_name: String
    
    var coil_sizing_method_air_flow: Int
    var coil_sizing_method_air_flow_name: String
    
    var is_coil_sizing_for_total_load: Bool
    var coil_peak_load_type_to_size_on_name: String
    
    var cap_is_autosized: Bool
    var coil_cap_auto_msg: String
    
    var vol_flow_is_autosized: Bool
    var coil_vol_flow_auto_msg: String
    var coil_water_flow_user: Float64
    var coil_water_flow_auto_msg: String
    
    var oa_pretreated: Bool
    var coil_oa_pretreat_msg: String
    
    var is_supplemental_heater: Bool
    var coil_tot_cap_final: Float64
    var coil_sens_cap_final: Float64
    var coil_ref_air_vol_flow_final: Float64
    var coil_ref_water_vol_flow_final: Float64
    
    var coil_tot_cap_at_peak: Float64
    var coil_sens_cap_at_peak: Float64
    var coil_des_mass_flow: Float64
    var coil_des_vol_flow: Float64
    var coil_des_ent_temp: Float64
    var coil_des_ent_wet_bulb: Float64
    var coil_des_ent_hum_rat: Float64
    var coil_des_ent_enth: Float64
    var coil_des_lvg_temp: Float64
    var coil_des_lvg_wet_bulb: Float64
    var coil_des_lvg_hum_rat: Float64
    var coil_des_lvg_enth: Float64
    var coil_des_water_mass_flow: Float64
    var coil_des_water_ent_temp: Float64
    var coil_des_water_lvg_temp: Float64
    var coil_des_water_temp_diff: Float64
    
    var plt_siz_num: Int
    var water_loop_num: Int
    var plant_loop_name: String
    var oa_peak_temp: Float64
    var oa_peak_hum_rat: Float64
    var oa_peak_wet_bulb: Float64
    var oa_peak_vol_flow: Float64
    var oa_peak_vol_frac: Float64
    var oa_doa_temp: Float64
    var oa_doa_hum_rat: Float64
    var ra_peak_temp: Float64
    var ra_peak_hum_rat: Float64
    var rm_peak_temp: Float64
    var rm_peak_hum_rat: Float64
    var rm_peak_rel_hum: Float64
    var rm_sensible_at_peak: Float64
    var rm_latent_at_peak: Float64
    var coil_ideal_siz_cap_over_sim_peak_cap: Float64
    var coil_ideal_siz_cap_under_sim_peak_cap: Float64
    var reheat_load_mult: Float64
    var min_ratio: Float64
    var max_ratio: Float64
    var cp_moist_air: Float64
    var cp_dry_air: Float64
    var rho_stand_air: Float64
    var rho_fluid: Float64
    var cp_fluid: Float64
    var coil_cap_ft_ideal_peak: Float64
    var coil_rated_tot_cap: Float64
    var coil_rated_sens_cap: Float64
    var rated_air_mass_flow: Float64
    var rated_coil_in_db: Float64
    var rated_coil_in_wb: Float64
    var rated_coil_in_hum_rat: Float64
    var rated_coil_in_enth: Float64
    var rated_coil_out_db: Float64
    var rated_coil_out_wb: Float64
    var rated_coil_out_hum_rat: Float64
    var rated_coil_out_enth: Float64
    var rated_coil_eff: Float64
    var rated_coil_bp_factor: Float64
    var rated_coil_app_dew_pt: Float64
    var rated_coil_oadb_ref: Float64
    var rated_coil_oawb_ref: Float64
    
    var fan_associated_with_coil_name: String
    var fan_type_name: String
    var sup_fan_type: Int
    var sup_fan_num: Int
    var fan_size_max_air_volume_flow: Float64
    var fan_size_max_air_mass_flow: Float64
    var fan_heat_gain_ideal_peak: Float64
    var coil_and_fan_net_total_capacity_ideal_peak: Float64
    
    var plant_des_max_mass_flow_rate: Float64
    var plant_des_ret_temp: Float64
    var plant_des_sup_temp: Float64
    var plant_des_delta_temp: Float64
    var plant_des_capacity: Float64
    var coil_cap_prcnt_plant_cap: Float64
    var coil_flow_prcnt_plant_flow: Float64
    
    var coil_ua: Float64
    
    fn __init__(inout self, coil_name: String):
        self.coil_name_ = coil_name
        self.coil_type = 0
        self.is_cooling = False
        self.is_heating = False
        self.coil_location = "unknown"
        self.des_day_name_at_sens_peak = "unknown"
        self.coil_sense_peak_hr_min = "unknown"
        self.des_day_name_at_total_peak = "unknown"
        self.coil_total_peak_hr_min = "unknown"
        self.des_day_name_at_air_flow_peak = "unknown"
        self.air_peak_hr_min = "unknown"
        
        self.coil_num = -999
        self.airloop_num = -999
        self.oa_controller_num = -999
        self.zone_eq_num = -999
        self.oa_sys_num = -999
        self.zone_num = DynamicVector[Int]()
        self.zone_name = DynamicVector[String]()
        self.type_hvac_name = "unknown"
        self.user_name_for_hvac_system = "unknown"
        self.zone_hvac_type_num = 0
        self.zone_hvac_index = 0
        self.typeof_coil = -999
        
        self.coil_sizing_method_concurrence = 0
        self.coil_sizing_method_concurrence_name = "N/A"
        self.coil_sizing_method_capacity = -999
        self.coil_sizing_method_capacity_name = "N/A"
        self.coil_sizing_method_air_flow = -999
        self.coil_sizing_method_air_flow_name = "N/A"
        self.is_coil_sizing_for_total_load = False
        self.coil_peak_load_type_to_size_on_name = "N/A"
        self.cap_is_autosized = False
        self.coil_cap_auto_msg = "unknown"
        self.vol_flow_is_autosized = False
        self.coil_vol_flow_auto_msg = "unknown"
        self.coil_water_flow_user = -999.0
        self.coil_water_flow_auto_msg = "unknown"
        self.oa_pretreated = False
        self.coil_oa_pretreat_msg = "unknown"
        self.is_supplemental_heater = False
        self.coil_tot_cap_final = -999.0
        self.coil_sens_cap_final = -999.0
        self.coil_ref_air_vol_flow_final = -999.0
        self.coil_ref_water_vol_flow_final = -999.0
        
        self.coil_tot_cap_at_peak = -999.0
        self.coil_sens_cap_at_peak = -999.0
        self.coil_des_mass_flow = -999.0
        self.coil_des_vol_flow = -999.0
        self.coil_des_ent_temp = -999.0
        self.coil_des_ent_wet_bulb = -999.0
        self.coil_des_ent_hum_rat = -999.0
        self.coil_des_ent_enth = -999.0
        self.coil_des_lvg_temp = -999.0
        self.coil_des_lvg_wet_bulb = -999.0
        self.coil_des_lvg_hum_rat = -999.0
        self.coil_des_lvg_enth = -999.0
        self.coil_des_water_mass_flow = -999.0
        self.coil_des_water_ent_temp = -999.0
        self.coil_des_water_lvg_temp = -999.0
        self.coil_des_water_temp_diff = -999.0
        
        self.plt_siz_num = -999
        self.water_loop_num = -999
        self.plant_loop_name = "unknown"
        self.oa_peak_temp = -999.0
        self.oa_peak_hum_rat = -999.0
        self.oa_peak_wet_bulb = -999.0
        self.oa_peak_vol_flow = -999.0
        self.oa_peak_vol_frac = -999.0
        self.oa_doa_temp = -999.0
        self.oa_doa_hum_rat = -999.0
        self.ra_peak_temp = -999.0
        self.ra_peak_hum_rat = -999.0
        self.rm_peak_temp = -999.0
        self.rm_peak_hum_rat = -999.0
        self.rm_peak_rel_hum = -999.0
        self.rm_sensible_at_peak = -999.0
        self.rm_latent_at_peak = 0.0
        self.coil_ideal_siz_cap_over_sim_peak_cap = -999.0
        self.coil_ideal_siz_cap_under_sim_peak_cap = -999.0
        self.reheat_load_mult = -999.0
        self.min_ratio = -999.0
        self.max_ratio = -999.0
        self.cp_moist_air = -999.0
        self.cp_dry_air = -999.0
        self.rho_stand_air = -999.0
        self.rho_fluid = -999.0
        self.cp_fluid = -999.0
        self.coil_cap_ft_ideal_peak = 1.0
        self.coil_rated_tot_cap = -999.0
        self.coil_rated_sens_cap = -999.0
        self.rated_air_mass_flow = -999.0
        self.rated_coil_in_db = -999.0
        self.rated_coil_in_wb = -999.0
        self.rated_coil_in_hum_rat = -999.0
        self.rated_coil_in_enth = -999.0
        self.rated_coil_out_db = -999.0
        self.rated_coil_out_wb = -999.0
        self.rated_coil_out_hum_rat = -999.0
        self.rated_coil_out_enth = -999.0
        self.rated_coil_eff = -999.0
        self.rated_coil_bp_factor = -999.0
        self.rated_coil_app_dew_pt = -999.0
        self.rated_coil_oadb_ref = -999.0
        self.rated_coil_oawb_ref = -999.0
        
        self.fan_associated_with_coil_name = "unknown"
        self.fan_type_name = "unknown"
        self.sup_fan_type = 0
        self.sup_fan_num = 0
        self.fan_size_max_air_volume_flow = -999.0
        self.fan_size_max_air_mass_flow = -999.0
        self.fan_heat_gain_ideal_peak = -999.0
        self.coil_and_fan_net_total_capacity_ideal_peak = -999.0
        
        self.plant_des_max_mass_flow_rate = -999.0
        self.plant_des_ret_temp = -999.0
        self.plant_des_sup_temp = -999.0
        self.plant_des_delta_temp = -999.0
        self.plant_des_capacity = -999.0
        self.coil_cap_prcnt_plant_cap = -999.0
        self.coil_flow_prcnt_plant_flow = -999.0
        
        self.coil_ua = -999.0


fn finish_coil_summary_report_table(state: UnsafePointer[EnergyPlusState]) -> None:
    do_final_processing_of_coil_data(state)
    write_coil_selection_output(state)
    write_coil_selection_output2(state)


fn set_coil_final_sizes(
    state: UnsafePointer[EnergyPlusState],
    coil_num: Int,
    tot_gross_cap: Float64,
    sens_gross_cap: Float64,
    air_flow_rate: Float64,
    water_flow_rate: Float64
) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_tot_cap_final = tot_gross_cap
            c[].coil_sens_cap_final = sens_gross_cap
            c[].coil_ref_air_vol_flow_final = air_flow_rate
            c[].coil_ref_water_vol_flow_final = water_flow_rate


fn do_air_loop_setup(state: UnsafePointer[EnergyPlusState], coil_vec_index: Int) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_vec_index >= 0 and coil_vec_index < len(coils):
        let c = coils[coil_vec_index]
        if c and c[].airloop_num > 0 and c[].airloop_num <= len(state[].dataAirSystemsData.PrimaryAirSystems):
            if state[].dataAirSystemsData.PrimaryAirSystems[c[].airloop_num].OASysExists:
                for loop in range(1, state[].dataMixedAir.NumOAControllers + 1):
                    if (state[].dataAirSystemsData.PrimaryAirSystems[c[].airloop_num].OASysInletNodeNum ==
                        state[].dataMixedAir.OAController[loop].RetNode):
                        c[].oa_controller_num = loop
            
            if state[].dataAirLoop.AirToZoneNodeInfo:
                if state[].dataAirLoop.AirToZoneNodeInfo[c[].airloop_num].NumZonesCooled > 0:
                    let zone_count = state[].dataAirLoop.AirToZoneNodeInfo[c[].airloop_num].NumZonesCooled
                    c[].zone_num.clear()
                    c[].zone_name.clear()
                    for loop_zone in range(1, zone_count + 1):
                        c[].zone_num.push_back(state[].dataAirLoop.AirToZoneNodeInfo[c[].airloop_num].CoolCtrlZoneNums[loop_zone])
                        c[].zone_name.push_back(state[].dataHeatBal.Zone[c[].zone_num[loop_zone - 1]].Name)
                
                if state[].dataAirLoop.AirToZoneNodeInfo[c[].airloop_num].NumZonesHeated > 0:
                    let zone_count = state[].dataAirLoop.AirToZoneNodeInfo[c[].airloop_num].NumZonesHeated
                    for loop_zone in range(1, zone_count + 1):
                        let zone_index = state[].dataAirLoop.AirToZoneNodeInfo[c[].airloop_num].HeatCtrlZoneNums[loop_zone]
                        var found = False
                        for z in c[].zone_num:
                            if z == zone_index:
                                found = True
                                break
                        if not found:
                            c[].zone_num.push_back(zone_index)
                            c[].zone_name.push_back(state[].dataHeatBal.Zone[zone_index].Name)


fn do_zone_eq_setup(state: UnsafePointer[EnergyPlusState], coil_num: Int) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_location = "Zone"
            c[].zone_num.clear()
            c[].zone_num.push_back(c[].zone_eq_num)
            c[].zone_name.clear()
            c[].zone_name.push_back(state[].dataHeatBal.Zone[c[].zone_num[0]].Name)
            c[].type_hvac_name = "Zone Equipment"
            
            if c[].airloop_num > 0:
                if state[].dataAirSystemsData.PrimaryAirSystems[c[].airloop_num].OASysExists:
                    for loop in range(1, state[].dataMixedAir.NumOAControllers + 1):
                        if (state[].dataAirSystemsData.PrimaryAirSystems[c[].airloop_num].OASysInletNodeNum ==
                            state[].dataMixedAir.OAController[loop].RetNode):
                            c[].oa_controller_num = loop
                
                let fan = state[].dataFans.fans[state[].dataAirSystemsData.PrimaryAirSystems[c[].airloop_num].supFanNum]
                set_coil_supply_fan_info(state, coil_num, fan[].Name, fan[].type,
                                        state[].dataAirSystemsData.PrimaryAirSystems[c[].airloop_num].supFanNum)
            
            if c[].zone_eq_num > 0:
                associate_zone_coil_with_parent(state, c)


fn do_final_processing_of_coil_data(state: UnsafePointer[EnergyPlusState]) -> None:
    let coils = state[].dataRptCoilSelection.coils
    for c in coils:
        if c:
            if c[].zone_eq_num > 0:
                associate_zone_coil_with_parent(state, c)
            
            if c[].airloop_num > state[].dataHVACGlobal.NumPrimaryAirSys and c[].oa_sys_num > 0:
                c[].coil_location = "DOAS AirLoop"
                c[].type_hvac_name = "AirLoopHVAC:DedicatedOutdoorAirSystem"
                let doas_sys_num = state[].dataAirLoop.OutsideAirSys[c[].oa_sys_num].AirLoopDOASNum
                c[].user_name_for_hvac_system = state[].dataAirLoopHVACDOAS.airloopDOAS[doas_sys_num].Name
            elif c[].airloop_num > 0 and c[].zone_eq_num == 0:
                c[].coil_location = "AirLoop"
                c[].type_hvac_name = "AirLoopHVAC"
                c[].user_name_for_hvac_system = state[].dataAirSystemsData.PrimaryAirSystems[c[].airloop_num].Name
            elif c[].zone_eq_num > 0 and c[].airloop_num > 0:
                c[].user_name_for_hvac_system += " on air system named " + state[].dataAirSystemsData.PrimaryAirSystems[c[].airloop_num].Name
                c[].coil_location = "Zone Equipment"
            
            if c[].coil_des_vol_flow > 0:
                c[].oa_peak_vol_frac = (c[].oa_peak_vol_flow / c[].coil_des_vol_flow) * 100.0
            else:
                c[].oa_peak_vol_frac = -999.0
            
            c[].cp_dry_air = Psychrometrics.PsyCpAirFnW(0.0)
            c[].rho_stand_air = state[].dataEnvrn.StdRhoAir


fn get_report_index(state: UnsafePointer[EnergyPlusState], coil_name: String, coil_type: Int) -> Int:
    let coils = state[].dataRptCoilSelection.coils
    for i in range(len(coils)):
        let c = coils[i]
        if c:
            if Util.SameString(c[].coil_name_, coil_name):
                if c[].coil_type == coil_type:
                    return i
                Util.ShowWarningError(state, 
                    "check for unique coil names across different coil types: " + coil_name +
                    " occurs in both " + HVAC.coilTypeNamesUC[coil_type] +
                    " and " + HVAC.coilTypeNamesUC[c[].coil_type])
    
    let c = CoilSelectionData(coil_name)
    state[].dataRptCoilSelection.coils.push_back(c)
    state[].dataRptCoilSelection.coils[len(state[].dataRptCoilSelection.coils) - 1][].coil_type = coil_type
    state[].dataRptCoilSelection.coils[len(state[].dataRptCoilSelection.coils) - 1][].is_cooling = HVAC.coilTypeIsCooling[coil_type]
    state[].dataRptCoilSelection.coils[len(state[].dataRptCoilSelection.coils) - 1][].is_heating = HVAC.coilTypeIsHeating[coil_type]
    
    return len(state[].dataRptCoilSelection.coils) - 1


fn set_coil_air_flow(state: UnsafePointer[EnergyPlusState], coil_num: Int, air_vdot: Float64, is_auto_sized: Bool) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_des_vol_flow = air_vdot
            c[].vol_flow_is_autosized = is_auto_sized
            c[].coil_des_mass_flow = air_vdot * state[].dataEnvrn.StdRhoAir


fn get_time_text(state: UnsafePointer[EnergyPlusState], time_step_at_peak: Int) -> String:
    if time_step_at_peak == 0:
        return ""
    
    var minutes = 0
    var time_step_index = 0
    for hour_counter in range(1, 25):
        for time_step_counter in range(1, state[].dataGlobal.TimeStepsInHour + 1):
            time_step_index += 1
            minutes += state[].dataGlobal.MinutesInTimeStep
            var hour_print: Int
            if minutes == 60:
                minutes = 0
                hour_print = hour_counter
            else:
                hour_print = hour_counter - 1
            if time_step_index == time_step_at_peak:
                return String(hour_print) + ":" + String(minutes)
    
    return ""


fn is_comp_type_fan(comp_type: String) -> Bool:
    return getEnumValue(HVAC.fanTypeNamesUC, Util.makeUPPER(comp_type)) != -1


fn is_comp_type_coil(comp_type: String) -> Bool:
    return getEnumValue(HVAC.coilTypeNamesUC, Util.makeUPPER(comp_type)) != -1


fn write_coil_selection_output(state: UnsafePointer[EnergyPlusState]) -> None:
    pass


fn write_coil_selection_output2(state: UnsafePointer[EnergyPlusState]) -> None:
    pass


fn set_rated_coil_conditions(
    state: UnsafePointer[EnergyPlusState],
    coil_num: Int,
    rated_coil_tot_cap: Float64,
    rated_coil_sens_cap: Float64,
    rated_air_mass_flow: Float64,
    rated_coil_in_db: Float64,
    rated_coil_in_hum_rat: Float64,
    rated_coil_in_wb: Float64,
    rated_coil_out_db: Float64,
    rated_coil_out_hum_rat: Float64,
    rated_coil_out_wb: Float64,
    rated_coil_oadb_ref: Float64,
    rated_coil_oawb_ref: Float64,
    rated_coil_bp_factor: Float64,
    rated_coil_eff: Float64
) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_rated_tot_cap = rated_coil_tot_cap
            c[].coil_rated_sens_cap = rated_coil_sens_cap
            c[].rated_air_mass_flow = rated_air_mass_flow
            c[].rated_coil_in_db = rated_coil_in_db
            c[].rated_coil_in_wb = rated_coil_in_wb
            c[].rated_coil_in_hum_rat = rated_coil_in_hum_rat
            if (rated_coil_in_db == -999.0) or (rated_coil_in_hum_rat == -999.0):
                c[].rated_coil_in_enth = -999.0
            else:
                c[].rated_coil_in_enth = Psychrometrics.PsyHFnTdbW(rated_coil_in_db, rated_coil_in_hum_rat)
            
            c[].rated_coil_out_db = rated_coil_out_db
            c[].rated_coil_out_wb = rated_coil_out_wb
            c[].rated_coil_out_hum_rat = rated_coil_out_hum_rat
            if (rated_coil_out_db == -999.0) or (rated_coil_out_hum_rat == -999.0):
                c[].rated_coil_out_enth = -999.0
            else:
                c[].rated_coil_out_enth = Psychrometrics.PsyHFnTdbW(rated_coil_out_db, rated_coil_out_hum_rat)
            
            c[].rated_coil_eff = rated_coil_eff
            c[].rated_coil_bp_factor = rated_coil_bp_factor
            c[].rated_coil_oadb_ref = rated_coil_oadb_ref
            c[].rated_coil_oawb_ref = rated_coil_oawb_ref


fn set_coil_water_flow_node_nums(
    state: UnsafePointer[EnergyPlusState],
    coil_num: Int,
    water_vdot: Float64,
    is_auto_sized: Bool,
    inlet_node_num: Int,
    outlet_node_num: Int,
    plant_loop_num: Int
) -> None:
    var plant_siz_num = -999
    if (state[].dataSize.NumPltSizInput > 0) and (inlet_node_num > 0) and (outlet_node_num > 0):
        var errors_found = False
        plant_siz_num = PlantUtilities.MyPlantSizingIndex(
            state, "water coil", 
            state[].dataRptCoilSelection.coils[coil_num][][].coil_name_,
            inlet_node_num, outlet_node_num, errors_found)
    
    set_coil_water_flow_plt_siz_num(state, coil_num, water_vdot, is_auto_sized, plant_siz_num, plant_loop_num)


fn set_coil_water_flow_plt_siz_num(
    state: UnsafePointer[EnergyPlusState],
    coil_num: Int,
    water_vdot: Float64,
    is_auto_sized: Bool,
    plant_siz_num: Int,
    plant_loop_num: Int
) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].plt_siz_num = plant_siz_num
            c[].water_loop_num = plant_loop_num
            if c[].water_loop_num > 0:
                c[].plant_loop_name = state[].dataPlnt.PlantLoop[c[].water_loop_num].Name
            
            if c[].water_loop_num > 0 and c[].plt_siz_num > 0:
                if state[].dataSize.PlantSizData[c[].plt_siz_num].LoopType != DataSizing.TypeOfPlantLoop.Steam:
                    c[].rho_fluid = state[].dataPlnt.PlantLoop[c[].water_loop_num].glycol.getDensity(
                        state, Constant.InitConvTemp, "setCoilWaterFlow")
                    c[].cp_fluid = state[].dataPlnt.PlantLoop[c[].water_loop_num].glycol.getSpecificHeat(
                        state, Constant.InitConvTemp, "setCoilWaterFlow")
                else:
                    c[].rho_fluid = state[].dataPlnt.PlantLoop[c[].water_loop_num].steam.getSatDensity(
                        state, 100.0, 1.0, "setCoilWaterFlow")
                    c[].cp_fluid = state[].dataPlnt.PlantLoop[c[].water_loop_num].steam.getSatSpecificHeat(
                        state, 100.0, 0.0, "setCoilWaterFlow")
            
            if c[].rho_fluid > 0.0:
                c[].coil_des_water_mass_flow = water_vdot * c[].rho_fluid
            
            if is_auto_sized:
                c[].coil_water_flow_auto_msg = "Yes"
            else:
                c[].coil_water_flow_auto_msg = "No"


fn set_coil_ent_air_temp(
    state: UnsafePointer[EnergyPlusState],
    coil_num: Int,
    ent_air_dry_bulb_temp: Float64,
    cur_sys_num: Int,
    cur_zone_eq_num: Int
) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_des_ent_temp = ent_air_dry_bulb_temp
            c[].airloop_num = cur_sys_num
            do_air_loop_setup(state, coil_num)
            c[].zone_eq_num = cur_zone_eq_num


fn set_coil_ent_air_hum_rat(state: UnsafePointer[EnergyPlusState], coil_num: Int, ent_air_humrat: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_des_ent_hum_rat = ent_air_humrat


fn set_coil_ent_water_temp(state: UnsafePointer[EnergyPlusState], coil_num: Int, ent_water_temp: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_des_water_ent_temp = ent_water_temp


fn set_coil_lvg_water_temp(state: UnsafePointer[EnergyPlusState], coil_num: Int, lvg_water_temp: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_des_water_lvg_temp = lvg_water_temp


fn set_coil_water_delta_t(state: UnsafePointer[EnergyPlusState], coil_num: Int, coil_water_delta_t: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_des_water_temp_diff = coil_water_delta_t


fn set_coil_lvg_air_temp(state: UnsafePointer[EnergyPlusState], coil_num: Int, lvg_air_dry_bulb_temp: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_des_lvg_temp = lvg_air_dry_bulb_temp


fn set_coil_lvg_air_hum_rat(state: UnsafePointer[EnergyPlusState], coil_num: Int, lvg_air_hum_rat: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].coil_des_lvg_hum_rat = lvg_air_hum_rat


fn set_coil_reheat_multiplier(state: UnsafePointer[EnergyPlusState], coil_num: Int, multiplier_reheat_load: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].reheat_load_mult = multiplier_reheat_load


fn set_coil_supply_fan_info(
    state: UnsafePointer[EnergyPlusState],
    coil_num: Int,
    fan_name: String,
    fan_type: Int,
    fan_index: Int
) -> None:
    if not fan_name:
        return
    let coils = state[].dataRptCoilSelection.coils
    if coil_num >= 0 and coil_num < len(coils):
        let c = coils[coil_num]
        if c:
            c[].fan_associated_with_coil_name = fan_name
            c[].sup_fan_type = fan_type
            c[].sup_fan_num = fan_index
            if c[].sup_fan_num == 0:
                c[].sup_fan_num = Fans.GetFanIndex(state, fan_name)


fn set_coil_eq_num(
    state: UnsafePointer[EnergyPlusState],
    index: Int,
    cur_sys_num: Int,
    cur_oa_sys_num: Int,
    cur_zone_eq_num: Int
) -> None:
    let coils = state[].dataRptCoilSelection.coils
    if index >= 0 and index < len(coils):
        let c = coils[index]
        if c:
            c[].airloop_num = cur_sys_num
            c[].oa_sys_num = cur_oa_sys_num
            c[].zone_eq_num = cur_zone_eq_num


fn associate_zone_coil_with_parent(state: UnsafePointer[EnergyPlusState], c: UnsafePointer[CoilSelectionData]) -> None:
    c[].coil_location = "Unknown"
    c[].type_hvac_name = "Unknown"
    c[].user_name_for_hvac_system = "Unknown"


fn set_zone_latent_load_cooling_ideal_peak(state: UnsafePointer[EnergyPlusState], zone_index: Int, zone_cooling_latent_load: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    for c in coils:
        if c and c[].is_cooling:
            for z_ind in range(len(c[].zone_num)):
                if zone_index == c[].zone_num[z_ind]:
                    c[].rm_latent_at_peak += zone_cooling_latent_load
                    break


fn set_zone_latent_load_heating_ideal_peak(state: UnsafePointer[EnergyPlusState], zone_index: Int, zone_heating_latent_load: Float64) -> None:
    let coils = state[].dataRptCoilSelection.coils
    for c in coils:
        if c and c[].is_heating:
            for z_ind in range(len(c[].zone_num)):
                if zone_index == c[].zone_num[z_ind]:
                    c[].rm_latent_at_peak += zone_heating_latent_load
                    break
