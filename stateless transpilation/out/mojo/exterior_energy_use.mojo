# EXTERNAL DEPS (to wire in glue):
# Schedule (ScheduleManager) — Schedule type and GetSchedule() function
# Constant.eFuel enum and eFuelNamesUC, eFuelNames mappings, eFuel2eResource (DataGlobalConstants)
# Constant.Units, Constant.eResource, Constant.KindOfSim enums (DataGlobalConstants)
# OutputProcessor.SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat (OutputProcessor)
# OutputReportPredefined.PreDefTableEntry and pdchExLtPower, pdchExLtClock, pdchExLtSchd (OutputReportPredefined)
# EMSManager.SetupEMSActuator (EMSManager)
# InputProcessor interface with getNumObjectsFound, epJSON, getObjectSchemaProps, getAlphaFieldValue, getRealFieldValue, markObjectAsUsed (InputProcessing)
# GlobalNames.VerifyUniqueInterObjectName (GlobalNames)
# Util.makeUPPER, Util.SameString (UtilityRoutines)
# Error functions: ShowSevereEmptyField, ShowSevereItemNotFound, ShowSevereCustom, ShowSevereInvalidKey, ShowFatalError (UtilityRoutines)
# ErrorObjectHeader (UtilityRoutines)
# EnergyPlusData state with .dataExteriorEnergyUse, .dataInputProcessing, .dataGlobal, .dataEnvrn, .dataOutRptPredefined (Data.EnergyPlusData)

from collections import List, Dict
from memory import HeapArray


alias INT_MIN_VALUE = -2147483648


struct LightControlType:
    alias Invalid = -1
    alias ScheduleOnly = 1
    alias AstroClockOverride = 2
    alias Num = 3


struct ExteriorLightUsage:
    var name: String
    var sched: UnsafePointer[ScheduleType]
    var design_level: Float64
    var power: Float64
    var current_use: Float64
    var control_mode: Int32
    var manage_demand: Bool
    var demand_limit: Float64
    var power_actuator_on: Bool
    var power_actuator_value: Float64
    var sum_consumption: Float64
    var sum_time_not_zero_cons: Float64

    fn __init__(inout self):
        self.name = String()
        self.sched = UnsafePointer[ScheduleType]()
        self.design_level = 0.0
        self.power = 0.0
        self.current_use = 0.0
        self.control_mode = LightControlType.ScheduleOnly
        self.manage_demand = False
        self.demand_limit = 0.0
        self.power_actuator_on = False
        self.power_actuator_value = 0.0
        self.sum_consumption = 0.0
        self.sum_time_not_zero_cons = 0.0


struct ExteriorEquipmentUsage:
    var name: String
    var fuel_type: Int32
    var sched: UnsafePointer[ScheduleType]
    var design_level: Float64
    var power: Float64
    var current_use: Float64
    var manage_demand: Bool
    var demand_limit: Float64

    fn __init__(inout self):
        self.name = String()
        self.fuel_type = -1
        self.sched = UnsafePointer[ScheduleType]()
        self.design_level = 0.0
        self.power = 0.0
        self.current_use = 0.0
        self.manage_demand = False
        self.demand_limit = 0.0


struct ExteriorEnergyUseData:
    var num_exterior_lights: Int32
    var num_exterior_eqs: Int32
    var exterior_lights: List[ExteriorLightUsage]
    var exterior_equipment: List[ExteriorEquipmentUsage]
    var unique_exterior_equip_names: Dict[String, String]
    var get_exterior_energy_input_flag: Bool
    var sum_design_level: Float64

    fn __init__(inout self):
        self.num_exterior_lights = 0
        self.num_exterior_eqs = 0
        self.exterior_lights = List[ExteriorLightUsage]()
        self.exterior_equipment = List[ExteriorEquipmentUsage]()
        self.unique_exterior_equip_names = Dict[String, String]()
        self.get_exterior_energy_input_flag = True
        self.sum_design_level = 0.0

    fn clear_state(inout self):
        self.num_exterior_lights = 0
        self.num_exterior_eqs = 0
        self.exterior_lights.clear()
        self.exterior_equipment.clear()
        self.unique_exterior_equip_names.clear()
        self.get_exterior_energy_input_flag = True
        self.sum_design_level = 0.0


struct ScheduleType:
    pass


fn manage_exterior_energy_use(inout state: EnergyPlusDataType) -> None:
    if state.data_exterior_energy_use.get_exterior_energy_input_flag:
        get_exterior_energy_use_input(state)
        state.data_exterior_energy_use.get_exterior_energy_input_flag = False

    report_exterior_energy_use(state)


fn get_exterior_energy_use_input(inout state: EnergyPlusDataType) -> None:
    var routine_name: String = "GetExteriorEnergyUseInput"

    var errors_found: Bool = False
    var end_use_subcategory_name: String = String()
    var input_processor = state.data_input_processing.input_processor

    state.data_exterior_energy_use.num_exterior_lights = input_processor.get_num_objects_found(state, "Exterior:Lights")
    
    var i: Int32
    for i in range(state.data_exterior_energy_use.num_exterior_lights):
        state.data_exterior_energy_use.exterior_lights.push_back(ExteriorLightUsage())

    var num_fuel_eq = input_processor.get_num_objects_found(state, "Exterior:FuelEquipment")
    var num_wtr_eq = input_processor.get_num_objects_found(state, "Exterior:WaterEquipment")
    
    for i in range(num_fuel_eq + num_wtr_eq):
        state.data_exterior_energy_use.exterior_equipment.push_back(ExteriorEquipmentUsage())

    state.data_exterior_energy_use.get_exterior_energy_input_flag = False
    state.data_exterior_energy_use.num_exterior_eqs = 0

    # Get Exterior Lights
    var current_module_object: String = "Exterior:Lights"
    var exterior_lights_schema_props = input_processor.get_object_schema_props(state, current_module_object)
    var exterior_lights_objects = input_processor.ep_json.get(current_module_object)
    
    if exterior_lights_objects:
        var item: Int32 = 0
        var light_name: String
        var light_fields: JSONType
        for light_name_raw, light_fields in exterior_lights_objects.items():
            light_name = make_upper(light_name_raw)
            var schedule_name = input_processor.get_alpha_field_value(light_fields, exterior_lights_schema_props, "schedule_name")
            var control_option = String()
            if light_fields.contains("control_option"):
                control_option = input_processor.get_alpha_field_value(light_fields, exterior_lights_schema_props, "control_option")

            input_processor.mark_object_as_used(current_module_object, light_name_raw)

            var eoh = (routine_name, current_module_object, light_name)

            state.data_exterior_energy_use.exterior_lights[item].name = light_name

            if schedule_name.is_empty():
                show_severe_empty_field(state, eoh, "schedule_name")
                errors_found = True
            else:
                var sched = get_schedule(state, schedule_name)
                if not sched:
                    show_severe_item_not_found(state, eoh, "schedule_name", schedule_name)
                    errors_found = True
                else:
                    state.data_exterior_energy_use.exterior_lights[item].sched = sched
                    var sch_min = sched.get_min_val(state)
                    if sch_min < 0.0:
                        show_severe_custom(state, eoh, String("schedule_name = ") + schedule_name + String(" minimum is [") + String(sch_min) + String("]. Values must be >= 0.0."))
                        errors_found = True

            if control_option.is_empty():
                state.data_exterior_energy_use.exterior_lights[item].control_mode = LightControlType.ScheduleOnly
            elif same_string(control_option, "ScheduleNameOnly"):
                state.data_exterior_energy_use.exterior_lights[item].control_mode = LightControlType.ScheduleOnly
            elif same_string(control_option, "AstronomicalClock"):
                state.data_exterior_energy_use.exterior_lights[item].control_mode = LightControlType.AstroClockOverride
            else:
                show_severe_invalid_key(state, eoh, "control_option", control_option)

            if light_fields.contains("end_use_subcategory"):
                end_use_subcategory_name = input_processor.get_alpha_field_value(light_fields, exterior_lights_schema_props, "end_use_subcategory")
            else:
                end_use_subcategory_name = "General"

            state.data_exterior_energy_use.exterior_lights[item].design_level = input_processor.get_real_field_value(light_fields, exterior_lights_schema_props, "design_level")
            
            if state.data_global.any_energy_management_system_in_model:
                setup_ems_actuator(state,
                                    "ExteriorLights",
                                    state.data_exterior_energy_use.exterior_lights[item].name,
                                    "Electricity Rate",
                                    "W",
                                    state.data_exterior_energy_use.exterior_lights[item].power_actuator_on,
                                    state.data_exterior_energy_use.exterior_lights[item].power_actuator_value)

            setup_output_variable(state,
                                 "Exterior Lights Electricity Rate",
                                 "W",
                                 state.data_exterior_energy_use.exterior_lights[item].power,
                                 "Zone",
                                 "Average",
                                 state.data_exterior_energy_use.exterior_lights[item].name)

            setup_output_variable(state,
                                 "Exterior Lights Electricity Energy",
                                 "J",
                                 state.data_exterior_energy_use.exterior_lights[item].current_use,
                                 "Zone",
                                 "Sum",
                                 state.data_exterior_energy_use.exterior_lights[item].name,
                                 "Electricity",
                                 "Invalid",
                                 "ExteriorLights",
                                 end_use_subcategory_name)

            pre_def_table_entry(state,
                               state.data_out_rpt_predefined.pdch_ex_lt_power,
                               state.data_exterior_energy_use.exterior_lights[item].name,
                               state.data_exterior_energy_use.exterior_lights[item].design_level)
            state.data_exterior_energy_use.sum_design_level += state.data_exterior_energy_use.exterior_lights[item].design_level
            
            if state.data_exterior_energy_use.exterior_lights[item].control_mode == LightControlType.AstroClockOverride:
                pre_def_table_entry(state,
                                   state.data_out_rpt_predefined.pdch_ex_lt_clock,
                                   state.data_exterior_energy_use.exterior_lights[item].name,
                                   "AstronomicalClock")
                pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_ex_lt_schd, state.data_exterior_energy_use.exterior_lights[item].name, "-")
            else:
                pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_ex_lt_clock, state.data_exterior_energy_use.exterior_lights[item].name, "Schedule")
                pre_def_table_entry(state,
                                   state.data_out_rpt_predefined.pdch_ex_lt_schd,
                                   state.data_exterior_energy_use.exterior_lights[item].name,
                                   state.data_exterior_energy_use.exterior_lights[item].sched[].name)
            item += 1

    pre_def_table_entry(state, state.data_out_rpt_predefined.pdch_ex_lt_power, "Exterior Lighting Total", state.data_exterior_energy_use.sum_design_level)

    # Get Exterior Fuel Equipment
    current_module_object = "Exterior:FuelEquipment"
    var exterior_fuel_schema_props = input_processor.get_object_schema_props(state, current_module_object)
    var exterior_fuel_objects = input_processor.ep_json.get(current_module_object)
    
    if exterior_fuel_objects:
        var fuel_equip_name_raw: String
        var fuel_equip_fields: JSONType
        for fuel_equip_name_raw, fuel_equip_fields in exterior_fuel_objects.items():
            var equip_name = make_upper(fuel_equip_name_raw)
            var fuel_use_type = input_processor.get_alpha_field_value(fuel_equip_fields, exterior_fuel_schema_props, "fuel_use_type")
            var schedule_name = input_processor.get_alpha_field_value(fuel_equip_fields, exterior_fuel_schema_props, "schedule_name")

            input_processor.mark_object_as_used(current_module_object, fuel_equip_name_raw)
            verify_unique_inter_object_name(state, state.data_exterior_energy_use.unique_exterior_equip_names, equip_name, current_module_object, "Name", errors_found)

            var eoh = (routine_name, current_module_object, equip_name)

            state.data_exterior_energy_use.num_exterior_eqs += 1

            var exterior_equip = state.data_exterior_energy_use.exterior_equipment[state.data_exterior_energy_use.num_exterior_eqs - 1]
            exterior_equip.name = equip_name

            if fuel_equip_fields.contains("end_use_subcategory"):
                end_use_subcategory_name = input_processor.get_alpha_field_value(fuel_equip_fields, exterior_fuel_schema_props, "end_use_subcategory")
            else:
                end_use_subcategory_name = "General"

            if fuel_use_type.is_empty():
                show_severe_empty_field(state, eoh, "fuel_use_type")
                errors_found = True
            else:
                var fuel_type_val = get_enum_value(eFuel_names_uc, fuel_use_type)
                if fuel_type_val == -1:
                    show_severe_invalid_key(state, eoh, "fuel_use_type", fuel_use_type)
                    errors_found = True
                else:
                    exterior_equip.fuel_type = fuel_type_val
                    if exterior_equip.fuel_type != 1:
                        setup_output_variable(state,
                                             "Exterior Equipment Fuel Rate",
                                             "W",
                                             exterior_equip.power,
                                             "Zone",
                                             "Average",
                                             exterior_equip.name)
                        var fuel_name = eFuel_names[exterior_equip.fuel_type]
                        setup_output_variable(state,
                                             String("Exterior Equipment ") + fuel_name + String(" Energy"),
                                             "J",
                                             exterior_equip.current_use,
                                             "Zone",
                                             "Sum",
                                             exterior_equip.name,
                                             eFuel2eResource[exterior_equip.fuel_type],
                                             "Invalid",
                                             "ExteriorEquipment",
                                             end_use_subcategory_name)
                    else:
                        setup_output_variable(state,
                                             "Exterior Equipment Water Volume Flow Rate",
                                             "m3/s",
                                             exterior_equip.power,
                                             "Zone",
                                             "Average",
                                             exterior_equip.name)
                        var fuel_name = eFuel_names[exterior_equip.fuel_type]
                        setup_output_variable(state,
                                             String("Exterior Equipment ") + fuel_name + String(" Volume"),
                                             "m3",
                                             exterior_equip.current_use,
                                             "Zone",
                                             "Sum",
                                             exterior_equip.name,
                                             eFuel2eResource[exterior_equip.fuel_type],
                                             "Invalid",
                                             "ExteriorEquipment",
                                             end_use_subcategory_name)

            if schedule_name.is_empty():
                show_severe_empty_field(state, eoh, "schedule_name")
                errors_found = True
            else:
                var sched = get_schedule(state, schedule_name)
                if not sched:
                    show_severe_item_not_found(state, eoh, "schedule_name", schedule_name)
                    errors_found = True
                else:
                    exterior_equip.sched = sched
                    var sch_min = sched.get_min_val(state)
                    if sch_min < 0.0:
                        show_severe_custom(state, eoh, String("schedule_name = ") + schedule_name + String(" minimum is [") + String(sch_min) + String("]. Values must be >= 0.0."))
                        errors_found = True
            
            exterior_equip.design_level = input_processor.get_real_field_value(fuel_equip_fields, exterior_fuel_schema_props, "design_level")

    # Get Exterior Water Equipment
    current_module_object = "Exterior:WaterEquipment"
    var exterior_water_schema_props = input_processor.get_object_schema_props(state, current_module_object)
    var exterior_water_objects = input_processor.ep_json.get(current_module_object)
    
    if exterior_water_objects:
        var water_equip_name_raw: String
        var water_equip_fields: JSONType
        for water_equip_name_raw, water_equip_fields in exterior_water_objects.items():
            var equip_name = make_upper(water_equip_name_raw)
            var schedule_name = input_processor.get_alpha_field_value(water_equip_fields, exterior_water_schema_props, "schedule_name")

            input_processor.mark_object_as_used(current_module_object, water_equip_name_raw)

            var eoh = (routine_name, current_module_object, equip_name)

            verify_unique_inter_object_name(state, state.data_exterior_energy_use.unique_exterior_equip_names, equip_name, current_module_object, "Name", errors_found)

            state.data_exterior_energy_use.num_exterior_eqs += 1

            var exterior_equip = state.data_exterior_energy_use.exterior_equipment[state.data_exterior_energy_use.num_exterior_eqs - 1]
            exterior_equip.name = equip_name
            exterior_equip.fuel_type = 1

            if schedule_name.is_empty():
                show_severe_empty_field(state, eoh, "schedule_name")
                errors_found = True
            else:
                var sched = get_schedule(state, schedule_name)
                if not sched:
                    show_severe_item_not_found(state, eoh, "schedule_name", schedule_name)
                    errors_found = True
                else:
                    exterior_equip.sched = sched
                    var sch_min = sched.get_min_val(state)
                    if sch_min < 0.0:
                        show_severe_custom(state, eoh, String("schedule_name = ") + schedule_name + String(" minimum is [") + String(sch_min) + String("]. Values must be >= 0.0."))
                        errors_found = True

            if water_equip_fields.contains("end_use_subcategory"):
                end_use_subcategory_name = input_processor.get_alpha_field_value(water_equip_fields, exterior_water_schema_props, "end_use_subcategory")
            else:
                end_use_subcategory_name = "General"

            exterior_equip.design_level = input_processor.get_real_field_value(water_equip_fields, exterior_water_schema_props, "design_level")

            setup_output_variable(state,
                                 "Exterior Equipment Water Volume Flow Rate",
                                 "m3/s",
                                 exterior_equip.power,
                                 "Zone",
                                 "Average",
                                 exterior_equip.name)

            setup_output_variable(state,
                                 "Exterior Equipment Water Volume",
                                 "m3",
                                 exterior_equip.current_use,
                                 "Zone",
                                 "Sum",
                                 exterior_equip.name,
                                 "Water",
                                 "Invalid",
                                 "ExteriorEquipment",
                                 end_use_subcategory_name)
            setup_output_variable(state,
                                 "Exterior Equipment Mains Water Volume",
                                 "m3",
                                 exterior_equip.current_use,
                                 "Zone",
                                 "Sum",
                                 exterior_equip.name,
                                 "MainsWater",
                                 "Invalid",
                                 "ExteriorEquipment",
                                 end_use_subcategory_name)

    if errors_found:
        show_fatal_error(state, routine_name + "Errors found in input.  Program terminates.")


fn report_exterior_energy_use(inout state: EnergyPlusDataType) -> None:
    var item: Int32
    for item in range(state.data_exterior_energy_use.num_exterior_lights):
        var control_mode = state.data_exterior_energy_use.exterior_lights[item].control_mode
        
        if control_mode == LightControlType.ScheduleOnly:
            state.data_exterior_energy_use.exterior_lights[item].power = (
                state.data_exterior_energy_use.exterior_lights[item].design_level *
                state.data_exterior_energy_use.exterior_lights[item].sched[].get_current_val()
            )
            state.data_exterior_energy_use.exterior_lights[item].current_use = (
                state.data_exterior_energy_use.exterior_lights[item].power *
                state.data_global.time_step_zone_sec
            )
        elif control_mode == LightControlType.AstroClockOverride:
            if state.data_envrn.sun_is_up:
                state.data_exterior_energy_use.exterior_lights[item].power = 0.0
                state.data_exterior_energy_use.exterior_lights[item].current_use = 0.0
            else:
                state.data_exterior_energy_use.exterior_lights[item].power = (
                    state.data_exterior_energy_use.exterior_lights[item].design_level *
                    state.data_exterior_energy_use.exterior_lights[item].sched[].get_current_val()
                )
                state.data_exterior_energy_use.exterior_lights[item].current_use = (
                    state.data_exterior_energy_use.exterior_lights[item].power *
                    state.data_global.time_step_zone_sec
                )

        if (state.data_exterior_energy_use.exterior_lights[item].manage_demand and
            state.data_exterior_energy_use.exterior_lights[item].power > state.data_exterior_energy_use.exterior_lights[item].demand_limit):
            state.data_exterior_energy_use.exterior_lights[item].power = state.data_exterior_energy_use.exterior_lights[item].demand_limit
            state.data_exterior_energy_use.exterior_lights[item].current_use = (
                state.data_exterior_energy_use.exterior_lights[item].power *
                state.data_global.time_step_zone_sec
            )
        
        if state.data_exterior_energy_use.exterior_lights[item].power_actuator_on:
            state.data_exterior_energy_use.exterior_lights[item].power = state.data_exterior_energy_use.exterior_lights[item].power_actuator_value

        state.data_exterior_energy_use.exterior_lights[item].current_use = (
            state.data_exterior_energy_use.exterior_lights[item].power *
            state.data_global.time_step_zone_sec
        )

        if not state.data_global.warmup_flag:
            if (state.data_global.do_output_reporting and
                state.data_global.kind_of_sim == 1):
                state.data_exterior_energy_use.exterior_lights[item].sum_consumption += state.data_exterior_energy_use.exterior_lights[item].current_use
                if state.data_exterior_energy_use.exterior_lights[item].current_use > 0.01:
                    state.data_exterior_energy_use.exterior_lights[item].sum_time_not_zero_cons += state.data_global.time_step_zone

    for item in range(state.data_exterior_energy_use.num_exterior_eqs):
        state.data_exterior_energy_use.exterior_equipment[item].power = (
            state.data_exterior_energy_use.exterior_equipment[item].design_level *
            state.data_exterior_energy_use.exterior_equipment[item].sched[].get_current_val()
        )
        state.data_exterior_energy_use.exterior_equipment[item].current_use = (
            state.data_exterior_energy_use.exterior_equipment[item].power *
            state.data_global.time_step_zone_sec
        )


fn get_schedule(state: EnergyPlusDataType, schedule_name: String) -> UnsafePointer[ScheduleType]:
    return UnsafePointer[ScheduleType]()

fn setup_output_variable(state: EnergyPlusDataType, args: VariadicList[AnyType]) -> None:
    pass

fn setup_ems_actuator(state: EnergyPlusDataType, args: VariadicList[AnyType]) -> None:
    pass

fn pre_def_table_entry(state: EnergyPlusDataType, args: VariadicList[AnyType]) -> None:
    pass

fn show_severe_empty_field(state: EnergyPlusDataType, eoh: AnyType, field: String) -> None:
    pass

fn show_severe_item_not_found(state: EnergyPlusDataType, eoh: AnyType, field: String, value: String) -> None:
    pass

fn show_severe_custom(state: EnergyPlusDataType, eoh: AnyType, msg: String) -> None:
    pass

fn show_severe_invalid_key(state: EnergyPlusDataType, eoh: AnyType, field: String, value: String) -> None:
    pass

fn show_fatal_error(state: EnergyPlusDataType, msg: String) -> None:
    pass

fn verify_unique_inter_object_name(state: EnergyPlusDataType, names_dict: Dict[String, String], name: String, module: String, field: String, inout errors_found: Bool) -> None:
    pass

fn same_string(s1: String, s2: String) -> Bool:
    return s1.upper() == s2.upper()

fn get_enum_value(names_uc: Dict[String, Int32], name: String) -> Int32:
    return names_uc.get(name.upper(), -1)

fn make_upper(s: String) -> String:
    return s.upper()

struct JSONType:
    pass

struct EnergyPlusDataType:
    pass
