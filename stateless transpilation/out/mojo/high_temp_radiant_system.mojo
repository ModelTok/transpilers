# EXTERNAL DEPS (to wire in glue):
# - state.dataHighTempRadSys: Container for HighTempRadiantSystemData array and global flags
# - state.dataInputProcessing.inputProcessor: Input processor for reading object items
# - state.dataIPShortCut: Short cuts for input processing (cAlphaArgs, rNumericArgs, etc.)
# - state.dataHeatBal: Heat balance data including Zone array
# - state.dataSurface: Surface data
# - state.dataHeatBalFanSys: Heat balance fan system data with radiant distribution arrays
# - state.dataZoneTempPredictorCorrector: Zone heat balance state (MAT, MRT)
# - state.dataHVACGlobal: Global HVAC state (SysTimeElapsed, TimeStepSys, TimeStepZone)
# - state.dataGlobal: Global state flags and NumOfZones
# - state.dataSize: Sizing arrays and methods
# - state.dataZoneEquip: Zone equipment state
# - Constant: Resource type enumeration (NaturalGas, Electricity, eResourceNamesUC)
# - DataSizing: Sizing type enumeration (DesignSizingType, DesignSizingTypeNamesUC)
# - Sched: Schedule interface (GetScheduleAlwaysOn, GetSchedule, Schedule)
# - Util: Utility functions (FindItemInList)
# - HeatBalanceIntRadExchange: GetRadiantSystemSurface function
# - HeatBalanceSurfaceManager: CalcHeatBalanceOutsideSurf, CalcHeatBalanceInsideSurf
# - OutputProcessor: Output variable setup and units
# - Error reporting: ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, etc.
# - HeatingCapacitySizer: Sizing class for heating capacity
# - HVAC: Sizing method constants

from math import fabs

alias RadControlType = Int32

alias RAD_CONTROL_INVALID = -1
alias RAD_CONTROL_MAT = 0
alias RAD_CONTROL_MRT = 1
alias RAD_CONTROL_OPERATIVE = 2
alias RAD_CONTROL_MAT_SP = 3
alias RAD_CONTROL_MRT_SP = 4
alias RAD_CONTROL_OPERATIVE_SP = 5
alias RAD_CONTROL_NUM = 6

fn get_rad_control_type_from_string(name: String) -> RadControlType:
    var names = List[String](6)
    names[0] = "MEANAIRTEMPERATURE"
    names[1] = "MEANRADIANTTEMPERATURE"
    names[2] = "OPERATIVETEMPERATURE"
    names[3] = "MEANAIRTEMPERATURESETPOINT"
    names[4] = "MEANRADIANTTEMPERATURESETPOINT"
    names[5] = "OPERATIVETEMPERATURESETPOINT"
    
    var name_upper = name.upper()
    for i in range(6):
        if names[i] == name_upper:
            return i
    return RAD_CONTROL_INVALID


struct HighTempRadiantSystemData:
    var name: String
    var avail_sched: DTypePointer[UInt8]
    var zone_ptr: Int32
    var heater_type: String
    var max_power_capac: Float64
    var combustion_effic: Float64
    var frac_radiant: Float64
    var frac_latent: Float64
    var frac_lost: Float64
    var frac_convect: Float64
    var control_type: RadControlType
    var throttl_range: Float64
    var setpt_sched: DTypePointer[UInt8]
    var frac_distrib_person: Float64
    var tot_surf_to_distrib: Int32
    var surface_name: List[String]
    var surface_ptr: List[Int32]
    var frac_distrib_to_surf: List[Float64]
    
    var zero_htr_source_sum_hatsurf: Float64
    var qhtr_rad_source: Float64
    var qhtr_rad_src_avg: Float64
    var last_sys_time_elapsed: Float64
    var last_time_step_sys: Float64
    var last_qhtr_rad_src: Float64
    
    var elec_power: Float64
    var elec_energy: Float64
    var gas_power: Float64
    var gas_energy: Float64
    var heat_power: Float64
    var heat_energy: Float64
    var heating_cap_method: Int32
    var scaled_heating_capacity: Float64
    
    fn __init__(inout self):
        self.name = ""
        self.avail_sched = DTypePointer[UInt8]()
        self.zone_ptr = 0
        self.heater_type = ""
        self.max_power_capac = 0.0
        self.combustion_effic = 0.0
        self.frac_radiant = 0.0
        self.frac_latent = 0.0
        self.frac_lost = 0.0
        self.frac_convect = 0.0
        self.control_type = RAD_CONTROL_INVALID
        self.throttl_range = 0.0
        self.setpt_sched = DTypePointer[UInt8]()
        self.frac_distrib_person = 0.0
        self.tot_surf_to_distrib = 0
        self.surface_name = List[String]()
        self.surface_ptr = List[Int32]()
        self.frac_distrib_to_surf = List[Float64]()
        
        self.zero_htr_source_sum_hatsurf = 0.0
        self.qhtr_rad_source = 0.0
        self.qhtr_rad_src_avg = 0.0
        self.last_sys_time_elapsed = 0.0
        self.last_time_step_sys = 0.0
        self.last_qhtr_rad_src = 0.0
        
        self.elec_power = 0.0
        self.elec_energy = 0.0
        self.gas_power = 0.0
        self.gas_energy = 0.0
        self.heat_power = 0.0
        self.heat_energy = 0.0
        self.heating_cap_method = -1
        self.scaled_heating_capacity = 0.0


struct HighTempRadSysNumericFieldData:
    var field_names: List[String]
    
    fn __init__(inout self):
        self.field_names = List[String]()


fn sim_high_temp_radiant_system(inout state, comp_name: String, first_hvac_iteration: Bool):
    """Main manager subroutine for high temperature radiant system."""
    
    if state.data_high_temp_rad_sys.get_input_flag:
        var errors_found = False
        get_high_temp_radiant_system(state, errors_found)
        if errors_found:
            state.show_fatal_error(state, "GetHighTempRadiantSystem: Errors found in input. Preceding condition(s) cause termination.")
        state.data_high_temp_rad_sys.get_input_flag = False
    
    # Find system by name
    var rad_sys_num: Int32 = -1
    for i in range(state.data_high_temp_rad_sys.high_temp_rad_sys.size):
        if state.data_high_temp_rad_sys.high_temp_rad_sys[i].name == comp_name:
            rad_sys_num = i
            break
    
    if rad_sys_num < 0:
        state.show_fatal_error(state, "SimHighTempRadiantSystem: Unit not found=" + comp_name)
    
    init_high_temp_radiant_system(state, first_hvac_iteration, rad_sys_num)
    
    var rad_sys = state.data_high_temp_rad_sys.high_temp_rad_sys[rad_sys_num]
    
    if rad_sys.control_type == RAD_CONTROL_MAT or rad_sys.control_type == RAD_CONTROL_MRT or rad_sys.control_type == RAD_CONTROL_OPERATIVE:
        calc_high_temp_radiant_system(state, rad_sys_num)
    elif rad_sys.control_type == RAD_CONTROL_MAT_SP or rad_sys.control_type == RAD_CONTROL_MRT_SP or rad_sys.control_type == RAD_CONTROL_OPERATIVE_SP:
        calc_high_temp_radiant_system_sp(state, first_hvac_iteration, rad_sys_num)
    
    var load_met = update_high_temp_radiant_system(state, rad_sys_num)
    report_high_temp_radiant_system(state, rad_sys_num)


fn get_high_temp_radiant_system(inout state, inout errors_found: Bool):
    """Read high temperature radiant system input from input file."""
    
    let MAX_COMBUSTION_EFFIC = 1.0
    let MAX_FRACTION = 1.0
    let MIN_COMBUSTION_EFFIC = 0.01
    let MIN_FRACTION = 0.0
    let MIN_THROTTLING_RANGE = 0.5
    
    var num_of_systems = state.data_input_processing.input_processor.get_num_objects_found(state, "ZoneHVAC:HighTemperatureRadiant")
    
    state.data_high_temp_rad_sys.num_of_high_temp_rad_sys = num_of_systems
    for _ in range(num_of_systems):
        state.data_high_temp_rad_sys.high_temp_rad_sys.append(HighTempRadiantSystemData())
    state.data_high_temp_rad_sys.check_equip_name = List[Bool](num_of_systems)
    for i in range(num_of_systems):
        state.data_high_temp_rad_sys.check_equip_name[i] = True
    
    for i in range(num_of_systems):
        state.data_high_temp_rad_sys.high_temp_rad_sys_numeric_fields.append(HighTempRadSysNumericFieldData())
    
    for item_idx in range(num_of_systems):
        var high_temp_rad_sys = state.data_high_temp_rad_sys.high_temp_rad_sys[item_idx]
        
        # Get object item from input processor (abstract interface)
        var alpha_args = List[String]()
        var num_args = List[Float64]()
        state.data_input_processing.input_processor.get_object_item(
            state, "ZoneHVAC:HighTemperatureRadiant", item_idx, alpha_args, num_args
        )
        
        # System name
        if alpha_args.size > 0:
            high_temp_rad_sys.name = alpha_args[0]
        
        # Availability schedule
        if alpha_args.size > 1 and alpha_args[1] != "":
            high_temp_rad_sys.avail_sched = state.sched_get_schedule(state, alpha_args[1])
        else:
            high_temp_rad_sys.avail_sched = state.sched_get_schedule_always_on(state)
        
        # Zone pointer
        if alpha_args.size > 2:
            high_temp_rad_sys.zone_ptr = state.util_find_item_in_list(alpha_args[2], state.data_heat_bal.zone)
            if high_temp_rad_sys.zone_ptr < 0:
                errors_found = True
        
        # Heating capacity method
        if alpha_args.size > 3:
            high_temp_rad_sys.heating_cap_method = get_enum_value_string(
                state.data_sizing.design_sizing_type_names_uc, alpha_args[3]
            )
            
            # Process heating capacity based on method
            if high_temp_rad_sys.heating_cap_method == 0:  # HeatingDesignCapacity
                if num_args.size > 0 and num_args[0] != 0.0:
                    high_temp_rad_sys.scaled_heating_capacity = num_args[0]
                else:
                    errors_found = True
            elif high_temp_rad_sys.heating_cap_method == 1:  # CapacityPerFloorArea
                if num_args.size > 1 and num_args[1] != 0.0:
                    high_temp_rad_sys.scaled_heating_capacity = num_args[1]
                else:
                    errors_found = True
            elif high_temp_rad_sys.heating_cap_method == 2:  # FractionOfAutosizedHeatingCapacity
                if num_args.size > 2 and num_args[2] != 0.0:
                    high_temp_rad_sys.scaled_heating_capacity = num_args[2]
                else:
                    errors_found = True
        
        # Heater type
        if alpha_args.size > 4:
            high_temp_rad_sys.heater_type = alpha_args[4]
            
            if high_temp_rad_sys.heater_type == "NaturalGas":
                if num_args.size > 3:
                    high_temp_rad_sys.combustion_effic = num_args[3]
                    if high_temp_rad_sys.combustion_effic < MIN_COMBUSTION_EFFIC:
                        high_temp_rad_sys.combustion_effic = MIN_COMBUSTION_EFFIC
                    if high_temp_rad_sys.combustion_effic > MAX_COMBUSTION_EFFIC:
                        high_temp_rad_sys.combustion_effic = MAX_COMBUSTION_EFFIC
            else:
                high_temp_rad_sys.combustion_effic = MAX_COMBUSTION_EFFIC
        
        # Fraction radiant
        if num_args.size > 4:
            high_temp_rad_sys.frac_radiant = num_args[4]
            if high_temp_rad_sys.frac_radiant < MIN_FRACTION:
                high_temp_rad_sys.frac_radiant = MIN_FRACTION
            if high_temp_rad_sys.frac_radiant > MAX_FRACTION:
                high_temp_rad_sys.frac_radiant = MAX_FRACTION
        
        # Fraction latent
        if num_args.size > 5:
            high_temp_rad_sys.frac_latent = num_args[5]
            if high_temp_rad_sys.frac_latent < MIN_FRACTION:
                high_temp_rad_sys.frac_latent = MIN_FRACTION
            if high_temp_rad_sys.frac_latent > MAX_FRACTION:
                high_temp_rad_sys.frac_latent = MAX_FRACTION
        
        # Fraction lost
        if num_args.size > 6:
            high_temp_rad_sys.frac_lost = num_args[6]
            if high_temp_rad_sys.frac_lost < MIN_FRACTION:
                high_temp_rad_sys.frac_lost = MIN_FRACTION
            if high_temp_rad_sys.frac_lost > MAX_FRACTION:
                high_temp_rad_sys.frac_lost = MAX_FRACTION
        
        # Compute fraction convective
        var all_fracs_summed = high_temp_rad_sys.frac_radiant + high_temp_rad_sys.frac_latent + high_temp_rad_sys.frac_lost
        if all_fracs_summed > MAX_FRACTION:
            errors_found = True
            high_temp_rad_sys.frac_convect = 0.0
        else:
            high_temp_rad_sys.frac_convect = 1.0 - all_fracs_summed
        
        # Control type
        if alpha_args.size > 5:
            high_temp_rad_sys.control_type = get_rad_control_type_from_string(alpha_args[5])
        else:
            high_temp_rad_sys.control_type = RAD_CONTROL_OPERATIVE
        
        # Throttling range
        if num_args.size > 7:
            high_temp_rad_sys.throttl_range = num_args[7]
            if high_temp_rad_sys.throttl_range < MIN_THROTTLING_RANGE:
                high_temp_rad_sys.throttl_range = 1.0
        
        # Setpoint schedule
        if alpha_args.size > 6:
            high_temp_rad_sys.setpt_sched = state.sched_get_schedule(state, alpha_args[6])
        
        # Fraction to people
        if num_args.size > 8:
            high_temp_rad_sys.frac_distrib_person = num_args[8]
            if high_temp_rad_sys.frac_distrib_person < MIN_FRACTION:
                high_temp_rad_sys.frac_distrib_person = MIN_FRACTION
            if high_temp_rad_sys.frac_distrib_person > MAX_FRACTION:
                high_temp_rad_sys.frac_distrib_person = MAX_FRACTION
        
        # Surfaces to distribute to
        high_temp_rad_sys.tot_surf_to_distrib = num_args.size() - 9
        
        all_fracs_summed = high_temp_rad_sys.frac_distrib_person
        for surf_num_idx in range(high_temp_rad_sys.tot_surf_to_distrib):
            if alpha_args.size > 7 + surf_num_idx:
                high_temp_rad_sys.surface_name.append(alpha_args[7 + surf_num_idx])
            
            if num_args.size > 9 + surf_num_idx:
                var frac = num_args[9 + surf_num_idx]
                if frac < MIN_FRACTION:
                    frac = MIN_FRACTION
                if frac > MAX_FRACTION:
                    frac = MAX_FRACTION
                high_temp_rad_sys.frac_distrib_to_surf.append(frac)
                all_fracs_summed += frac
            else:
                high_temp_rad_sys.frac_distrib_to_surf.append(0.0)
                high_temp_rad_sys.surface_ptr.append(0)
                continue
            
            var surf_ptr = state.heat_balance_int_rad_exchange_get_radiant_system_surface(
                state, "ZoneHVAC:HighTemperatureRadiant", high_temp_rad_sys.name,
                high_temp_rad_sys.zone_ptr, high_temp_rad_sys.surface_name[surf_num_idx]
            )
            high_temp_rad_sys.surface_ptr.append(surf_ptr)
            
            if surf_ptr > 0:
                state.data_surface.set_gets_radiant_heat(surf_ptr)
        
        if all_fracs_summed > (MAX_FRACTION + 0.01):
            errors_found = True
        if all_fracs_summed < (MAX_FRACTION - 0.01):
            errors_found = True
    
    # Setup output variables
    for item_idx in range(num_of_systems):
        var high_temp_rad_sys = state.data_high_temp_rad_sys.high_temp_rad_sys[item_idx]
        state.setup_output_variable(state, "Zone Radiant HVAC Heating Rate", "W", high_temp_rad_sys.name)
        state.setup_output_variable(state, "Zone Radiant HVAC Heating Energy", "J", high_temp_rad_sys.name)
        
        if high_temp_rad_sys.heater_type == "NaturalGas":
            state.setup_output_variable(state, "Zone Radiant HVAC NaturalGas Rate", "W", high_temp_rad_sys.name)
            state.setup_output_variable(state, "Zone Radiant HVAC NaturalGas Energy", "J", high_temp_rad_sys.name)
        elif high_temp_rad_sys.heater_type == "Electricity":
            state.setup_output_variable(state, "Zone Radiant HVAC Electricity Rate", "W", high_temp_rad_sys.name)
            state.setup_output_variable(state, "Zone Radiant HVAC Electricity Energy", "J", high_temp_rad_sys.name)


fn init_high_temp_radiant_system(inout state, first_hvac_iteration: Bool, rad_sys_num: Int32):
    """Initialize high temperature radiant system variables."""
    
    if state.data_high_temp_rad_sys.first_time:
        state.data_high_temp_rad_sys.my_size_flag = List[Bool](state.data_high_temp_rad_sys.num_of_high_temp_rad_sys)
        for i in range(state.data_high_temp_rad_sys.num_of_high_temp_rad_sys):
            state.data_high_temp_rad_sys.my_size_flag[i] = True
        state.data_high_temp_rad_sys.first_time = False
    
    # Check zone equipment list
    if not state.data_high_temp_rad_sys.zone_equipment_list_checked and state.data_zone_equip.zone_equip_inputs_filled:
        state.data_high_temp_rad_sys.zone_equipment_list_checked = True
        for i in range(state.data_high_temp_rad_sys.high_temp_rad_sys.size):
            var this_htr_sys = state.data_high_temp_rad_sys.high_temp_rad_sys[i]
            if not state.check_zone_equipment_list(state, "ZoneHVAC:HighTemperatureRadiant", this_htr_sys.name):
                state.show_severe_error(state,
                    "InitHighTempRadiantSystem: Unit=[ZoneHVAC:HighTemperatureRadiant," + this_htr_sys.name + "] is not on any ZoneHVAC:EquipmentList.")
    
    # Do sizing once
    if not state.data_global.sys_sizing_calc and state.data_high_temp_rad_sys.my_size_flag[rad_sys_num]:
        size_high_temp_radiant_system(state, rad_sys_num)
        state.data_high_temp_rad_sys.my_size_flag[rad_sys_num] = False
    
    # Initialize environment variables
    if state.data_global.begin_envrnflag and state.data_high_temp_rad_sys.my_envrnflag:
        for i in range(state.data_high_temp_rad_sys.high_temp_rad_sys.size):
            var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[i]
            this_htr.zero_htr_source_sum_hatsurf = 0.0
            this_htr.qhtr_rad_source = 0.0
            this_htr.qhtr_rad_src_avg = 0.0
            this_htr.last_qhtr_rad_src = 0.0
            this_htr.last_sys_time_elapsed = 0.0
            this_htr.last_time_step_sys = 0.0
        state.data_high_temp_rad_sys.my_envrnflag = False
    
    if not state.data_global.begin_envrnflag:
        state.data_high_temp_rad_sys.my_envrnflag = True
    
    # Initialize timestep variables
    if state.data_global.begin_time_step_flag and first_hvac_iteration:
        var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[rad_sys_num]
        this_htr.zero_htr_source_sum_hatsurf = state.data_heat_bal.zone[this_htr.zone_ptr].sum_hatsurf(state)
        this_htr.qhtr_rad_source = 0.0
        this_htr.qhtr_rad_src_avg = 0.0
        this_htr.last_qhtr_rad_src = 0.0
        this_htr.last_sys_time_elapsed = 0.0
        this_htr.last_time_step_sys = 0.0


fn size_high_temp_radiant_system(inout state, rad_sys_num: Int32):
    """Size high temperature radiant system heating capacity."""
    
    var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[rad_sys_num]
    
    var cur_zone_eq_num = state.data_size.cur_zone_eq_num
    
    if cur_zone_eq_num > 0:
        var cap_sizing_method = this_htr.heating_cap_method
        
        if cap_sizing_method >= 0 and cap_sizing_method < 3:
            var comp_type = "ZoneHVAC:HighTemperatureRadiant"
            var comp_name = this_htr.name
            
            var temp_size: Float64 = 0.0
            
            if cap_sizing_method == 0:  # HeatingDesignCapacity
                if this_htr.scaled_heating_capacity == state.data_sizing.auto_size:
                    state.check_zone_sizing(state, comp_type, comp_name)
                    temp_size = (
                        state.data_size.final_zone_sizing[cur_zone_eq_num].non_air_sys_des_heat_load /
                        (this_htr.frac_radiant + this_htr.frac_convect)
                    )
                else:
                    temp_size = this_htr.scaled_heating_capacity
            elif cap_sizing_method == 1:  # CapacityPerFloorArea
                temp_size = (
                    this_htr.scaled_heating_capacity *
                    state.data_heat_bal.zone[state.data_size.data_zone_number].floor_area
                )
                state.data_size.data_scalable_cap_sizing_on = True
            elif cap_sizing_method == 2:  # FractionOfAutosizedHeatingCapacity
                state.check_zone_sizing(state, comp_type, comp_name)
                state.data_size.data_frac_of_autosized_heating_capacity = this_htr.scaled_heating_capacity
                temp_size = (
                    state.data_size.final_zone_sizing[cur_zone_eq_num].non_air_sys_des_heat_load /
                    (this_htr.frac_radiant + this_htr.frac_convect)
                )
                state.data_size.data_scalable_cap_sizing_on = True
            
            # Use heating capacity sizer
            this_htr.max_power_capac = state.size_heating_capacity(state, temp_size, comp_type, comp_name)
            state.data_size.data_scalable_cap_sizing_on = False


fn calc_high_temp_radiant_system(inout state, rad_sys_num: Int32):
    """Calculate high temperature radiant system output with control."""
    
    var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[rad_sys_num]
    
    var zone_num = this_htr.zone_ptr
    var heat_frac: Float64 = 0.0
    
    if this_htr.avail_sched.get_current_val() <= 0.0:
        this_htr.qhtr_rad_source = 0.0
    else:
        var set_pt_temp = this_htr.setpt_sched.get_current_val()
        var off_temp = set_pt_temp + 0.5 * this_htr.throttl_range
        
        var zone_hb = state.data_zone_temp_predictor_corrector.zone_heat_balance[zone_num]
        var mat = zone_hb.mat
        var mrt = zone_hb.mrt
        
        if this_htr.control_type == RAD_CONTROL_MAT:
            heat_frac = (off_temp - mat) / this_htr.throttl_range
        elif this_htr.control_type == RAD_CONTROL_MRT:
            heat_frac = (off_temp - mrt) / this_htr.throttl_range
        elif this_htr.control_type == RAD_CONTROL_OPERATIVE:
            var op_temp = 0.5 * (mat + mrt)
            heat_frac = (off_temp - op_temp) / this_htr.throttl_range
        
        if heat_frac < 0.0:
            heat_frac = 0.0
        if heat_frac > 1.0:
            heat_frac = 1.0
        
        this_htr.qhtr_rad_source = heat_frac * this_htr.max_power_capac


fn calc_high_temp_radiant_system_sp(inout state, first_hvac_iteration: Bool, rad_sys_num: Int32):
    """Calculate high temperature radiant system with setpoint control."""
    
    var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[rad_sys_num]
    
    let TEMP_CONV_TOLER: Float32 = 0.1
    let MAX_ITERATIONS = 10
    
    var zone_num = this_htr.zone_ptr
    this_htr.qhtr_rad_source = 0.0
    
    if this_htr.avail_sched.get_current_val() > 0.0:
        var set_pt_temp = this_htr.setpt_sched.get_current_val()
        
        distribute_ht_rad_gains(state)
        state.calc_heat_balance_outside_surf(state, zone_num)
        state.calc_heat_balance_inside_surf(state, zone_num)
        
        var zone_hb = state.data_zone_temp_predictor_corrector.zone_heat_balance[zone_num]
        
        var zone_temp: Float64 = 0.0
        if this_htr.control_type == RAD_CONTROL_MAT_SP:
            zone_temp = zone_hb.mat
        elif this_htr.control_type == RAD_CONTROL_MRT_SP:
            zone_temp = zone_hb.mrt
        elif this_htr.control_type == RAD_CONTROL_OPERATIVE_SP:
            zone_temp = 0.5 * (zone_hb.mat + zone_hb.mrt)
        
        if zone_temp < (set_pt_temp - TEMP_CONV_TOLER):
            var iter_num = 0
            var converg_flag = False
            var heat_frac_max: Float32 = 1.0
            var heat_frac_min: Float32 = 0.0
            
            while iter_num <= MAX_ITERATIONS and not converg_flag:
                var heat_frac: Float32 = 0.0
                if iter_num == 0:
                    heat_frac = 1.0
                else:
                    heat_frac = (heat_frac_min + heat_frac_max) / 2.0
                
                this_htr.qhtr_rad_source = heat_frac * this_htr.max_power_capac
                
                distribute_ht_rad_gains(state)
                state.calc_heat_balance_outside_surf(state, zone_num)
                state.calc_heat_balance_inside_surf(state, zone_num)
                
                var zone_hb_mod = state.data_zone_temp_predictor_corrector.zone_heat_balance[zone_num]
                
                if this_htr.control_type == RAD_CONTROL_MAT_SP:
                    zone_temp = zone_hb_mod.mat
                elif this_htr.control_type == RAD_CONTROL_MRT_SP:
                    zone_temp = zone_hb_mod.mrt
                elif this_htr.control_type == RAD_CONTROL_OPERATIVE_SP:
                    zone_temp = 0.5 * (zone_hb_mod.mat + zone_hb_mod.mrt)
                
                if fabs(zone_temp - set_pt_temp) <= TEMP_CONV_TOLER:
                    converg_flag = True
                elif zone_temp < set_pt_temp:
                    if iter_num == 0:
                        converg_flag = True
                    else:
                        heat_frac_min = heat_frac
                else:
                    if iter_num > 0:
                        heat_frac_max = heat_frac
                
                iter_num += 1


fn update_high_temp_radiant_system(inout state, rad_sys_num: Int32) -> Float64:
    """Update high temperature radiant system and return load met."""
    
    var sys_time_elapsed = state.data_hvac_global.sys_time_elapsed
    var time_step_sys = state.data_hvac_global.time_step_sys
    var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[rad_sys_num]
    
    # Update running average
    if this_htr.last_sys_time_elapsed == sys_time_elapsed:
        this_htr.qhtr_rad_src_avg -= (
            this_htr.last_qhtr_rad_src * this_htr.last_time_step_sys / state.data_global.time_step_zone
        )
    
    this_htr.qhtr_rad_src_avg += (
        this_htr.qhtr_rad_source * time_step_sys / state.data_global.time_step_zone
    )
    
    this_htr.last_qhtr_rad_src = this_htr.qhtr_rad_source
    this_htr.last_sys_time_elapsed = sys_time_elapsed
    this_htr.last_time_step_sys = time_step_sys
    
    # Recalculate heat balance for non-SP controls
    if this_htr.control_type == RAD_CONTROL_MAT or this_htr.control_type == RAD_CONTROL_MRT or this_htr.control_type == RAD_CONTROL_OPERATIVE:
        distribute_ht_rad_gains(state)
        var zone_num = this_htr.zone_ptr
        state.calc_heat_balance_outside_surf(state, zone_num)
        state.calc_heat_balance_inside_surf(state, zone_num)
    
    # Calculate load met
    var load_met: Float64 = 0.0
    if this_htr.qhtr_rad_source > 0.0:
        var zone_num = this_htr.zone_ptr
        load_met = (
            state.data_heat_bal.zone[zone_num].sum_hatsurf(state) - this_htr.zero_htr_source_sum_hatsurf +
            state.data_heat_bal_fan_sys.sum_conv_ht_rad_sys[zone_num]
        )
    
    return load_met


fn update_ht_rad_source_val_avg(inout state) -> Bool:
    """Transfer average radiant source to heat balance and return whether system is on."""
    
    var high_temp_rad_sys_on = False
    
    if state.data_high_temp_rad_sys.num_of_high_temp_rad_sys == 0:
        return high_temp_rad_sys_on
    
    for i in range(state.data_high_temp_rad_sys.high_temp_rad_sys.size):
        var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[i]
        this_htr.qhtr_rad_source = this_htr.qhtr_rad_src_avg
        if this_htr.qhtr_rad_src_avg != 0.0:
            high_temp_rad_sys_on = True
    
    distribute_ht_rad_gains(state)
    
    return high_temp_rad_sys_on


fn distribute_ht_rad_gains(inout state):
    """Distribute radiant gains from high temperature heaters to surfaces and people."""
    
    let SMALLEST_AREA = 0.001
    
    # Initialize arrays
    for i in range(state.data_global.num_of_zones):
        state.data_heat_bal_fan_sys.sum_conv_ht_rad_sys[i] = 0.0
        state.data_heat_bal_fan_sys.sum_latent_ht_rad_sys[i] = 0.0
    
    for i in range(state.data_high_temp_rad_sys.high_temp_rad_sys.size):
        var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[i]
        for rad_surf_num in range(this_htr.tot_surf_to_distrib):
            var surf_num = this_htr.surface_ptr[rad_surf_num]
            state.data_heat_bal_fan_sys.surf_q_rad_from_hvac[surf_num].ht_rad_sys = 0.0
    
    for i in range(state.data_global.num_of_zones):
        state.data_heat_bal_fan_sys.zone_q_ht_rad_sys_to_person[i] = 0.0
    
    for i in range(state.data_high_temp_rad_sys.high_temp_rad_sys.size):
        var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[i]
        var zone_num = this_htr.zone_ptr
        
        state.data_heat_bal_fan_sys.zone_q_ht_rad_sys_to_person[zone_num] = (
            this_htr.qhtr_rad_source * this_htr.frac_radiant * this_htr.frac_distrib_person
        )
        state.data_heat_bal_fan_sys.sum_conv_ht_rad_sys[zone_num] += (
            this_htr.qhtr_rad_source * this_htr.frac_convect
        )
        state.data_heat_bal_fan_sys.sum_latent_ht_rad_sys[zone_num] += (
            this_htr.qhtr_rad_source * this_htr.frac_latent
        )
        
        for rad_surf_num in range(this_htr.tot_surf_to_distrib):
            var surf_num = this_htr.surface_ptr[rad_surf_num]
            var surf_area = state.data_surface.surface[surf_num].area
            
            if surf_area > SMALLEST_AREA:
                var this_surf_intensity = (
                    this_htr.qhtr_rad_source * this_htr.frac_radiant *
                    this_htr.frac_distrib_to_surf[rad_surf_num] / surf_area
                )
                state.data_heat_bal_fan_sys.surf_q_rad_from_hvac[surf_num].ht_rad_sys += this_surf_intensity
                
                if this_surf_intensity > state.data_heat_bal_fan_sys.max_rad_heat_flux:
                    state.show_severe_error(state, "DistributeHTRadGains: excessive thermal radiation heat flux intensity detected")
                    state.show_fatal_error(state, "DistributeHTRadGains: excessive thermal radiation heat flux intensity detected")
            else:
                state.show_severe_error(state, "DistributeHTRadGains: surface not large enough to receive thermal radiation heat flux")
                state.show_fatal_error(state, "DistributeHTRadGains: surface not large enough to receive thermal radiation heat flux")
    
    # Add radiant energy to people to convective
    for zone_num in range(state.data_global.num_of_zones):
        state.data_heat_bal_fan_sys.sum_conv_ht_rad_sys[zone_num] += state.data_heat_bal_fan_sys.zone_q_ht_rad_sys_to_person[zone_num]


fn report_high_temp_radiant_system(inout state, rad_sys_num: Int32):
    """Report high temperature radiant system output."""
    
    var time_step_sys_sec = state.data_hvac_global.time_step_sys_sec
    var this_htr = state.data_high_temp_rad_sys.high_temp_rad_sys[rad_sys_num]
    
    if this_htr.heater_type == "NaturalGas":
        this_htr.gas_power = this_htr.qhtr_rad_source / this_htr.combustion_effic
        this_htr.gas_energy = this_htr.gas_power * time_step_sys_sec
        this_htr.elec_power = 0.0
        this_htr.elec_energy = 0.0
    elif this_htr.heater_type == "Electricity":
        this_htr.gas_power = 0.0
        this_htr.gas_energy = 0.0
        this_htr.elec_power = this_htr.qhtr_rad_source
        this_htr.elec_energy = this_htr.elec_power * time_step_sys_sec
    else:
        state.show_warning_error(state, "Someone forgot to add a high temperature radiant heater type to the reporting subroutine")
    
    this_htr.heat_power = this_htr.qhtr_rad_source
    this_htr.heat_energy = this_htr.heat_power * time_step_sys_sec


@always_inline
fn get_enum_value_string(names_uc: List[String], name: String) -> Int32:
    """Helper to get enum value from uppercase names list."""
    var name_upper = name.upper()
    for i in range(names_uc.size):
        if names_uc[i] == name_upper:
            return i
    return -1
