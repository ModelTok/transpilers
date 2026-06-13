# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data members
# - ShowFatalError, ShowContinueError, ShowSevereError, ShowSevereItemNotFound
# - Util.FindItemInList
# - Node.CheckUniqueNodeNumbers, Node.EndUniqueNodeCheck, Node.GetNodeNums, Node.GetOnlySingleNode, Node.InitUniqueNodeCheck
# - PoweredInductionUnits.PIUInducesPlenumAir
# - PurchasedAirManager.CheckPurchasedAirForReturnPlenum
# - Psychrometrics.PsyHFnTdbW
# - DataZoneEquipment.AirLoopHVACZone enum, EquipConfiguration
# - InputProcessor.getObjectDefMaxArgs, getNumObjectsFound, getObjectItem
# - ErrorObjectHeader

from math import max, fabs

enum AirLoopHVACZone:
    ReturnPlenum = 1
    SupplyPlenum = 2

struct ZoneReturnPlenumConditions:
    var zone_plenum_name: String
    var zone_name: String
    var zone_node_name: String
    var zone_temp: Float64
    var zone_hum_rat: Float64
    var zone_enthalpy: Float64
    var outlet_temp: Float64
    var outlet_hum_rat: Float64
    var outlet_enthalpy: Float64
    var outlet_pressure: Float64
    var zone_node_num: Int32
    var actual_zone_num: Int32
    var outlet_node: Int32
    var outlet_mass_flow_rate: Float64
    var outlet_mass_flow_rate_max_avail: Float64
    var outlet_mass_flow_rate_min_avail: Float64
    var num_induced_nodes: Int32
    var induced_node: List[Int32]
    var induced_mass_flow_rate: List[Float64]
    var induced_mass_flow_rate_max_avail: List[Float64]
    var induced_mass_flow_rate_min_avail: List[Float64]
    var induced_temp: List[Float64]
    var induced_hum_rat: List[Float64]
    var induced_enthalpy: List[Float64]
    var induced_pressure: List[Float64]
    var induced_co2: List[Float64]
    var induced_gen_contam: List[Float64]
    var init_flag: Bool
    var num_inlet_nodes: Int32
    var inlet_node: List[Int32]
    var inlet_mass_flow_rate: List[Float64]
    var inlet_mass_flow_rate_max_avail: List[Float64]
    var inlet_mass_flow_rate_min_avail: List[Float64]
    var inlet_temp: List[Float64]
    var inlet_hum_rat: List[Float64]
    var inlet_enthalpy: List[Float64]
    var inlet_pressure: List[Float64]
    var adu_index: List[Int32]
    var num_adus: Int32
    var zone_eq_num: List[Int32]
    var check_equip_name: Bool

    fn __init__(inout self):
        self.zone_plenum_name = ""
        self.zone_name = ""
        self.zone_node_name = ""
        self.zone_temp = 0.0
        self.zone_hum_rat = 0.0
        self.zone_enthalpy = 0.0
        self.outlet_temp = 0.0
        self.outlet_hum_rat = 0.0
        self.outlet_enthalpy = 0.0
        self.outlet_pressure = 0.0
        self.zone_node_num = 0
        self.actual_zone_num = 0
        self.outlet_node = 0
        self.outlet_mass_flow_rate = 0.0
        self.outlet_mass_flow_rate_max_avail = 0.0
        self.outlet_mass_flow_rate_min_avail = 0.0
        self.num_induced_nodes = 0
        self.induced_node = List[Int32]()
        self.induced_mass_flow_rate = List[Float64]()
        self.induced_mass_flow_rate_max_avail = List[Float64]()
        self.induced_mass_flow_rate_min_avail = List[Float64]()
        self.induced_temp = List[Float64]()
        self.induced_hum_rat = List[Float64]()
        self.induced_enthalpy = List[Float64]()
        self.induced_pressure = List[Float64]()
        self.induced_co2 = List[Float64]()
        self.induced_gen_contam = List[Float64]()
        self.init_flag = False
        self.num_inlet_nodes = 0
        self.inlet_node = List[Int32]()
        self.inlet_mass_flow_rate = List[Float64]()
        self.inlet_mass_flow_rate_max_avail = List[Float64]()
        self.inlet_mass_flow_rate_min_avail = List[Float64]()
        self.inlet_temp = List[Float64]()
        self.inlet_hum_rat = List[Float64]()
        self.inlet_enthalpy = List[Float64]()
        self.inlet_pressure = List[Float64]()
        self.adu_index = List[Int32]()
        self.num_adus = 0
        self.zone_eq_num = List[Int32]()
        self.check_equip_name = True

struct ZoneSupplyPlenumConditions:
    var zone_plenum_name: String
    var zone_name: String
    var zone_node_name: String
    var zone_temp: Float64
    var zone_hum_rat: Float64
    var zone_enthalpy: Float64
    var inlet_temp: Float64
    var inlet_hum_rat: Float64
    var inlet_enthalpy: Float64
    var inlet_pressure: Float64
    var zone_node_num: Int32
    var actual_zone_num: Int32
    var inlet_node: Int32
    var inlet_mass_flow_rate: Float64
    var inlet_mass_flow_rate_max_avail: Float64
    var inlet_mass_flow_rate_min_avail: Float64
    var init_flag: Bool
    var num_outlet_nodes: Int32
    var outlet_node: List[Int32]
    var outlet_mass_flow_rate: List[Float64]
    var outlet_mass_flow_rate_max_avail: List[Float64]
    var outlet_mass_flow_rate_min_avail: List[Float64]
    var outlet_temp: List[Float64]
    var outlet_hum_rat: List[Float64]
    var outlet_enthalpy: List[Float64]
    var outlet_pressure: List[Float64]
    var check_equip_name: Bool

    fn __init__(inout self):
        self.zone_plenum_name = ""
        self.zone_name = ""
        self.zone_node_name = ""
        self.zone_temp = 0.0
        self.zone_hum_rat = 0.0
        self.zone_enthalpy = 0.0
        self.inlet_temp = 0.0
        self.inlet_hum_rat = 0.0
        self.inlet_enthalpy = 0.0
        self.inlet_pressure = 0.0
        self.zone_node_num = 0
        self.actual_zone_num = 0
        self.inlet_node = 0
        self.inlet_mass_flow_rate = 0.0
        self.inlet_mass_flow_rate_max_avail = 0.0
        self.inlet_mass_flow_rate_min_avail = 0.0
        self.init_flag = False
        self.num_outlet_nodes = 0
        self.outlet_node = List[Int32]()
        self.outlet_mass_flow_rate = List[Float64]()
        self.outlet_mass_flow_rate_max_avail = List[Float64]()
        self.outlet_mass_flow_rate_min_avail = List[Float64]()
        self.outlet_temp = List[Float64]()
        self.outlet_hum_rat = List[Float64]()
        self.outlet_enthalpy = List[Float64]()
        self.outlet_pressure = List[Float64]()
        self.check_equip_name = True

struct ZonePlenumData:
    var get_input_flag: Bool
    var num_zone_return_plenums: Int32
    var num_zone_supply_plenums: Int32
    var init_air_zone_return_plenum_envrn_flag: Bool
    var init_air_zone_return_plenum_one_time_flag: Bool
    var my_envrn_flag: Bool
    var zone_ret_plen_cond: List[ZoneReturnPlenumConditions]
    var zone_sup_plen_cond: List[ZoneSupplyPlenumConditions]

    fn __init__(inout self):
        self.get_input_flag = True
        self.num_zone_return_plenums = 0
        self.num_zone_supply_plenums = 0
        self.init_air_zone_return_plenum_envrn_flag = True
        self.init_air_zone_return_plenum_one_time_flag = True
        self.my_envrn_flag = True
        self.zone_ret_plen_cond = List[ZoneReturnPlenumConditions]()
        self.zone_sup_plen_cond = List[ZoneSupplyPlenumConditions]()

fn sim_air_zone_plenum(
    state: AnyType,
    comp_name: String,
    i_comp_type: Int32,
    comp_index: Pointer[Int32],
    first_hvac_iteration: Pointer[Bool] = Pointer[Bool](),
    first_call: Pointer[Bool] = Pointer[Bool](),
    plenum_inlet_changed: Pointer[Bool] = Pointer[Bool](),
) -> None:
    if state.data_zone_plenum.get_input_flag:
        get_zone_plenum_input(state)
        state.data_zone_plenum.get_input_flag = False

    var zone_plenum_num: Int32 = 0

    if i_comp_type == AirLoopHVACZone.ReturnPlenum.value:
        if comp_index[] == 0:
            zone_plenum_num = state.util.find_item_in_list(
                comp_name,
                state.data_zone_plenum.zone_ret_plen_cond,
                "zone_plenum_name",
            )
            if zone_plenum_num == 0:
                state.show_fatal_error(
                    String("SimAirZonePlenum: AirLoopHVAC:ReturnPlenum not found=") + comp_name
                )
            comp_index[] = zone_plenum_num
        else:
            zone_plenum_num = comp_index[]
            if (
                zone_plenum_num > state.data_zone_plenum.num_zone_return_plenums
                or zone_plenum_num < 1
            ):
                state.show_fatal_error(
                    String("SimAirZonePlenum: Invalid CompIndex passed=")
                    + String(zone_plenum_num)
                    + String(", Number of AirLoopHVAC:ReturnPlenum=")
                    + String(state.data_zone_plenum.num_zone_return_plenums)
                    + String(", AirLoopHVAC:ReturnPlenum name=")
                    + comp_name
                )
            var ret_plenum: ZoneReturnPlenumConditions = state.data_zone_plenum.zone_ret_plen_cond[
                zone_plenum_num - 1
            ]
            if ret_plenum.check_equip_name:
                if comp_name != ret_plenum.zone_plenum_name:
                    state.show_fatal_error(
                        String("SimAirZonePlenum: Invalid CompIndex passed=")
                        + String(zone_plenum_num)
                        + String(", AirLoopHVAC:ReturnPlenum name=")
                        + comp_name
                        + String(", stored AirLoopHVAC:ReturnPlenum Name for that index=")
                        + ret_plenum.zone_plenum_name
                    )
                ret_plenum.check_equip_name = False

        init_air_zone_return_plenum(state, zone_plenum_num)
        calc_air_zone_return_plenum(state, zone_plenum_num)
        update_air_zone_return_plenum(state, zone_plenum_num)

    elif i_comp_type == AirLoopHVACZone.SupplyPlenum.value:
        if comp_index[] == 0:
            zone_plenum_num = state.util.find_item_in_list(
                comp_name,
                state.data_zone_plenum.zone_sup_plen_cond,
                "zone_plenum_name",
            )
            if zone_plenum_num == 0:
                state.show_fatal_error(
                    String("SimAirZonePlenum: AirLoopHVAC:SupplyPlenum not found=") + comp_name
                )
            comp_index[] = zone_plenum_num
        else:
            zone_plenum_num = comp_index[]
            if (
                zone_plenum_num > state.data_zone_plenum.num_zone_supply_plenums
                or zone_plenum_num < 1
            ):
                state.show_fatal_error(
                    String("SimAirZonePlenum: Invalid CompIndex passed=")
                    + String(zone_plenum_num)
                    + String(", Number of AirLoopHVAC:SupplyPlenum=")
                    + String(state.data_zone_plenum.num_zone_supply_plenums)
                    + String(", AirLoopHVAC:SupplyPlenum name=")
                    + comp_name
                )
            var sup_plenum: ZoneSupplyPlenumConditions = state.data_zone_plenum.zone_sup_plen_cond[
                zone_plenum_num - 1
            ]
            if sup_plenum.check_equip_name:
                if comp_name != sup_plenum.zone_plenum_name:
                    state.show_fatal_error(
                        String("SimAirZonePlenum: Invalid CompIndex passed=")
                        + String(zone_plenum_num)
                        + String(", AirLoopHVAC:SupplyPlenum name=")
                        + comp_name
                        + String(", stored AirLoopHVAC:SupplyPlenum Name for that index=")
                        + sup_plenum.zone_plenum_name
                    )
                sup_plenum.check_equip_name = False

        init_air_zone_supply_plenum(state, zone_plenum_num, first_hvac_iteration[] if first_hvac_iteration != Pointer[Bool]() else False, first_call[] if first_call != Pointer[Bool]() else False)
        calc_air_zone_supply_plenum(state, zone_plenum_num, first_call[] if first_call != Pointer[Bool]() else False)
        update_air_zone_supply_plenum(state, zone_plenum_num, plenum_inlet_changed, first_call[] if first_call != Pointer[Bool]() else False)
    else:
        state.show_severe_error(String("SimAirZonePlenum: Errors in Plenum=") + comp_name)
        state.show_continue_error(String("ZonePlenum: Unhandled plenum type found:") + String(i_comp_type))
        state.show_fatal_error("Preceding conditions cause termination.")

fn get_zone_plenum_input(state: AnyType) -> None:
    var max_nums: Int32 = 0
    var max_alphas: Int32 = 0
    var num_args: Int32 = 0
    var num_alphas: Int32 = 0
    var num_nums: Int32 = 0

    state.data_input_processing.input_processor.get_object_def_max_args(state, "AirLoopHVAC:ReturnPlenum", num_args, num_alphas, num_nums)
    max_nums = num_nums
    max_alphas = num_alphas

    state.data_input_processing.input_processor.get_object_def_max_args(state, "AirLoopHVAC:SupplyPlenum", num_args, num_alphas, num_nums)
    max_nums = max(num_nums, max_nums)
    max_alphas = max(num_alphas, max_alphas)

    var alph_array: List[String] = List[String]()
    var c_alpha_fields: List[String] = List[String]()
    var c_numeric_fields: List[String] = List[String]()
    var num_array: List[Float64] = List[Float64]()
    var l_alpha_blanks: List[Bool] = List[Bool]()
    var l_numeric_blanks: List[Bool] = List[Bool]()

    for _ in range(max_alphas):
        alph_array.append("")
        c_alpha_fields.append("")
        l_alpha_blanks.append(True)
    for _ in range(max_nums):
        num_array.append(0.0)
        c_numeric_fields.append("")
        l_numeric_blanks.append(True)

    state.data_input_processing.input_processor.get_object_def_max_args(state, "NodeList", num_args, num_alphas, num_nums)
    var node_nums: List[Int32] = List[Int32]()
    for _ in range(num_args):
        node_nums.append(0)

    state.data_zone_plenum.num_zone_return_plenums = state.data_input_processing.input_processor.get_num_objects_found(state, "AirLoopHVAC:ReturnPlenum")
    state.data_zone_plenum.num_zone_supply_plenums = state.data_input_processing.input_processor.get_num_objects_found(state, "AirLoopHVAC:SupplyPlenum")

    if state.data_zone_plenum.num_zone_return_plenums > 0:
        for _ in range(state.data_zone_plenum.num_zone_return_plenums):
            state.data_zone_plenum.zone_ret_plen_cond.append(ZoneReturnPlenumConditions())
    if state.data_zone_plenum.num_zone_supply_plenums > 0:
        for _ in range(state.data_zone_plenum.num_zone_supply_plenums):
            state.data_zone_plenum.zone_sup_plen_cond.append(ZoneSupplyPlenumConditions())

    state.node.init_unique_node_check(state, "AirLoopHVAC:ReturnPlenum")
    var current_module_object: String = "AirLoopHVAC:ReturnPlenum"

    for zone_plenum_num in range(state.data_zone_plenum.num_zone_return_plenums):
        state.data_input_processing.input_processor.get_object_item(state, current_module_object, zone_plenum_num + 1, alph_array, num_alphas, num_array, num_nums, l_numeric_blanks, l_alpha_blanks, c_alpha_fields, c_numeric_fields)

        var ret_plenum: ZoneReturnPlenumConditions = state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num]
        ret_plenum.zone_plenum_name = alph_array[0]

        var io_stat: Int32 = state.util.find_item_in_list(alph_array[1], state.data_zone_plenum.zone_ret_plen_cond, "zone_name", zone_plenum_num - 1)
        if io_stat != 0:
            state.show_severe_error(String("GetZonePlenumInput: ") + c_alpha_fields[1] + String(" \"") + alph_array[1] + String("\" is used more than once as a ") + current_module_object + String("."))
            state.show_continue_error(String("..Only one ") + current_module_object + String(" object may be connected to a given zone."))
            state.show_continue_error(String("..occurs in ") + current_module_object + String(" = ") + alph_array[0])

        ret_plenum.zone_name = alph_array[1]
        ret_plenum.actual_zone_num = state.util.find_item_in_list(alph_array[1], state.data_heat_bal.zone)
        if ret_plenum.actual_zone_num == 0:
            state.show_severe_item_not_found(state, "GetZonePlenumInput", c_alpha_fields[1], alph_array[1])
            continue

        var zone_obj = state.data_heat_bal.zone[ret_plenum.actual_zone_num - 1]
        zone_obj.is_return_plenum = True
        zone_obj.plenum_cond_num = zone_plenum_num + 1

        var zone_equip_config_loop: Int32 = state.util.find_item_in_list(alph_array[1], state.data_zone_equip.zone_equip_config, "zone_name")
        if zone_equip_config_loop != 0:
            state.show_severe_error(String("GetZonePlenumInput: ") + c_alpha_fields[1] + String(" \"") + alph_array[1] + String("\" is a controlled zone. It cannot be used as a ") + current_module_object)
            state.show_continue_error(String("..occurs in ") + current_module_object + String(" = ") + alph_array[0])

        ret_plenum.zone_node_name = alph_array[2]
        ret_plenum.zone_node_num = state.node.get_only_single_node(state, alph_array[2], "AirLoopHVACReturnPlenum", alph_array[0], "Air", "ZoneNode", "Primary", False)
        zone_obj = state.data_heat_bal.zone[ret_plenum.actual_zone_num - 1]
        zone_obj.system_zone_node_number = ret_plenum.zone_node_num
        for space_num in zone_obj.space_indexes:
            state.data_heat_bal.space[space_num - 1].system_zone_node_number = ret_plenum.zone_node_num

        ret_plenum.outlet_node = state.node.get_only_single_node(state, alph_array[3], "AirLoopHVACReturnPlenum", alph_array[0], "Air", "Outlet", "Primary", False)

        var induced_node_list_name: String = alph_array[4]
        var node_list_error: Bool = False
        var num_nodes: Int32 = 0
        state.node.get_node_nums(state, induced_node_list_name, num_nodes, node_nums, node_list_error, "Air", "AirLoopHVACReturnPlenum", ret_plenum.zone_plenum_name, "InducedAir", "Primary", False, c_alpha_fields[4])

        if not node_list_error:
            ret_plenum.num_induced_nodes = num_nodes
            for _ in range(ret_plenum.num_induced_nodes):
                ret_plenum.induced_node.append(0)
                ret_plenum.induced_mass_flow_rate.append(0.0)
                ret_plenum.induced_mass_flow_rate_max_avail.append(0.0)
                ret_plenum.induced_mass_flow_rate_min_avail.append(0.0)
                ret_plenum.induced_temp.append(0.0)
                ret_plenum.induced_hum_rat.append(0.0)
                ret_plenum.induced_enthalpy.append(0.0)
                ret_plenum.induced_pressure.append(0.0)
                ret_plenum.induced_co2.append(0.0)
                ret_plenum.induced_gen_contam.append(0.0)

            for node_num in range(num_nodes):
                ret_plenum.induced_node[node_num] = node_nums[node_num]
                if not state.purchased_air_manager.check_purchased_air_for_return_plenum(state, zone_plenum_num + 1):
                    state.node.check_unique_node_numbers(state, "Return Plenum Induced Air Nodes", node_nums[node_num], current_module_object)
                    state.powered_induction_units.piu_induces_plenum_air(state, ret_plenum.induced_node[node_num], zone_plenum_num + 1)
        else:
            state.show_continue_error(String("Invalid Induced Air Outlet Node or NodeList name in AirLoopHVAC:ReturnPlenum object = ") + ret_plenum.zone_plenum_name)

        ret_plenum.num_inlet_nodes = num_alphas - 5

        for e in state.data_zone_plenum.zone_ret_plen_cond:
            e.init_flag = True

        for _ in range(ret_plenum.num_inlet_nodes):
            ret_plenum.inlet_node.append(0)
            ret_plenum.inlet_mass_flow_rate.append(0.0)
            ret_plenum.inlet_mass_flow_rate_max_avail.append(0.0)
            ret_plenum.inlet_mass_flow_rate_min_avail.append(0.0)
            ret_plenum.inlet_temp.append(0.0)
            ret_plenum.inlet_hum_rat.append(0.0)
            ret_plenum.inlet_enthalpy.append(0.0)
            ret_plenum.inlet_pressure.append(0.0)
            ret_plenum.zone_eq_num.append(0)

        for node_num in range(ret_plenum.num_inlet_nodes):
            ret_plenum.inlet_node[node_num] = state.node.get_only_single_node(state, alph_array[5 + node_num], "AirLoopHVACReturnPlenum", alph_array[0], "Air", "Inlet", "Primary", False)

    state.node.end_unique_node_check(state, "AirLoopHVAC:ReturnPlenum")
    current_module_object = "AirLoopHVAC:SupplyPlenum"

    for zone_plenum_num in range(state.data_zone_plenum.num_zone_supply_plenums):
        state.data_input_processing.input_processor.get_object_item(state, current_module_object, zone_plenum_num + 1, alph_array, num_alphas, num_array, num_nums, l_numeric_blanks, l_alpha_blanks, c_alpha_fields, c_numeric_fields)

        var sup_plenum: ZoneSupplyPlenumConditions = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num]
        sup_plenum.zone_plenum_name = alph_array[0]

        io_stat = state.util.find_item_in_list(alph_array[1], state.data_zone_plenum.zone_sup_plen_cond, "zone_name", zone_plenum_num - 1)
        if io_stat != 0:
            state.show_severe_error(String("GetZonePlenumInput: ") + c_alpha_fields[1] + String(" \"") + alph_array[1] + String("\" is used more than once as a ") + current_module_object + String("."))
            state.show_continue_error(String("..Only one ") + current_module_object + String(" object may be connected to a given zone."))
            state.show_continue_error(String("..occurs in ") + current_module_object + String(" = ") + alph_array[0])

        if state.data_zone_plenum.num_zone_return_plenums > 0:
            io_stat = state.util.find_item_in_list(alph_array[1], state.data_zone_plenum.zone_ret_plen_cond, "zone_name")
            if io_stat != 0:
                state.show_severe_error(String("GetZonePlenumInput: ") + c_alpha_fields[1] + String(" \"") + alph_array[1] + String("\" is used more than once as a ") + current_module_object + String(" or AirLoopHVAC:ReturnPlenum."))
                state.show_continue_error(String("..Only one ") + current_module_object + String(" or AirLoopHVAC:ReturnPlenum object may be connected to a given zone."))
                state.show_continue_error(String("..occurs in ") + current_module_object + String(" = ") + alph_array[0])

        sup_plenum.zone_name = alph_array[1]
        sup_plenum.actual_zone_num = state.util.find_item_in_list(alph_array[1], state.data_heat_bal.zone)
        if sup_plenum.actual_zone_num == 0:
            state.show_severe_item_not_found(state, "GetZonePlenumInput", c_alpha_fields[1], alph_array[1])
            continue

        zone_obj = state.data_heat_bal.zone[sup_plenum.actual_zone_num - 1]
        zone_obj.is_supply_plenum = True
        zone_obj.plenum_cond_num = zone_plenum_num + 1

        if any(e.is_controlled for e in state.data_zone_equip.zone_equip_config):
            zone_equip_config_loop = state.util.find_item_in_list(alph_array[1], state.data_zone_equip.zone_equip_config, "zone_name")
            if zone_equip_config_loop != 0:
                state.show_severe_error(String("GetZonePlenumInput: ") + c_alpha_fields[1] + String(" \"") + alph_array[1] + String("\" is a controlled zone. It cannot be used as a ") + current_module_object + String(" or AirLoopHVAC:ReturnPlenum."))
                state.show_continue_error(String("..occurs in ") + current_module_object + String(" = ") + alph_array[0])

        sup_plenum.zone_node_name = alph_array[2]
        sup_plenum.zone_node_num = state.node.get_only_single_node(state, alph_array[2], "AirLoopHVACSupplyPlenum", alph_array[0], "Air", "ZoneNode", "Primary", False)
        zone_obj = state.data_heat_bal.zone[sup_plenum.actual_zone_num - 1]
        zone_obj.system_zone_node_number = sup_plenum.zone_node_num
        for space_num in zone_obj.space_indexes:
            state.data_heat_bal.space[space_num - 1].system_zone_node_number = sup_plenum.zone_node_num

        sup_plenum.inlet_node = state.node.get_only_single_node(state, alph_array[3], "AirLoopHVACSupplyPlenum", alph_array[0], "Air", "Inlet", "Primary", False)

        sup_plenum.num_outlet_nodes = num_alphas - 4

        for e in state.data_zone_plenum.zone_sup_plen_cond:
            e.init_flag = True

        for _ in range(sup_plenum.num_outlet_nodes):
            sup_plenum.outlet_node.append(0)
            sup_plenum.outlet_mass_flow_rate.append(0.0)
            sup_plenum.outlet_mass_flow_rate_max_avail.append(0.0)
            sup_plenum.outlet_mass_flow_rate_min_avail.append(0.0)
            sup_plenum.outlet_temp.append(0.0)
            sup_plenum.outlet_hum_rat.append(0.0)
            sup_plenum.outlet_enthalpy.append(0.0)
            sup_plenum.outlet_pressure.append(0.0)

        for node_num in range(sup_plenum.num_outlet_nodes):
            sup_plenum.outlet_node[node_num] = state.node.get_only_single_node(state, alph_array[4 + node_num], "AirLoopHVACSupplyPlenum", alph_array[0], "Air", "Outlet", "Primary", False)

fn init_air_zone_return_plenum(state: AnyType, zone_plenum_num: Int32) -> None:
    if state.data_zone_plenum.init_air_zone_return_plenum_one_time_flag:
        for zone_plenum_loop in range(state.data_zone_plenum.num_zone_return_plenums):
            var num_adus_to_plen: Int32 = 0
            if state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_loop].num_inlet_nodes > 0:
                for inlet_node_loop in range(state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_loop].num_inlet_nodes):
                    var inlet_node: Int32 = state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_loop].inlet_node[inlet_node_loop]
                    for zone_equip_config_loop in range(state.data_global.num_of_zones):
                        if not state.data_zone_equip.zone_equip_config[zone_equip_config_loop].is_controlled:
                            continue
                        for ret_node in range(state.data_zone_equip.zone_equip_config[zone_equip_config_loop].num_return_nodes):
                            if state.data_zone_equip.zone_equip_config[zone_equip_config_loop].return_node[ret_node] == inlet_node:
                                state.data_zone_equip.zone_equip_config[zone_equip_config_loop].return_node_plenum_num = zone_plenum_loop + 1
                                state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_loop].zone_eq_num[inlet_node_loop] = zone_equip_config_loop + 1
                    for adu_num in range(len(state.data_define_equipment.air_dist_unit)):
                        if state.data_define_equipment.air_dist_unit[adu_num].zone_eq_num == state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_loop].zone_eq_num[inlet_node_loop]:
                            state.data_define_equipment.air_dist_unit[adu_num].ret_plenum_num = zone_plenum_loop + 1
                            num_adus_to_plen += 1

            for _ in range(num_adus_to_plen):
                state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_loop].adu_index.append(0)
            state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_loop].num_adus = num_adus_to_plen
            if num_adus_to_plen > 0:
                var adus_to_plen_index: Int32 = 0
                for adu_num in range(len(state.data_define_equipment.air_dist_unit)):
                    if state.data_define_equipment.air_dist_unit[adu_num].ret_plenum_num == zone_plenum_loop + 1:
                        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_loop].adu_index[adus_to_plen_index] = adu_num + 1
                        adus_to_plen_index += 1

        for adu_num in range(len(state.data_define_equipment.air_dist_unit)):
            var this_adu = state.data_define_equipment.air_dist_unit[adu_num]
            if this_adu.down_stream_leak and this_adu.ret_plenum_num == 0:
                state.show_warning_error(String("No return plenum found for simple duct leakage for ZoneHVAC:AirDistributionUnit=") + this_adu.name + String(" in Zone=") + state.data_zone_equip.zone_equip_config[this_adu.zone_eq_num - 1].zone_name)
                state.show_continue_error("Leakage will be ignored for this ADU.")
                this_adu.up_stream_leak = False
                this_adu.down_stream_leak = False
                this_adu.up_stream_leak_frac = 0.0
                this_adu.down_stream_leak_frac = 0.0

        state.data_zone_plenum.init_air_zone_return_plenum_one_time_flag = False

    if state.data_zone_plenum.init_air_zone_return_plenum_envrn_flag and state.data_global.begin_envrn_flag:
        for plenum_zone_num in range(state.data_zone_plenum.num_zone_return_plenums):
            var zone_node_num: Int32 = state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].zone_node_num
            state.data_loop_nodes.node[zone_node_num - 1].temp = 20.0
            state.data_loop_nodes.node[zone_node_num - 1].mass_flow_rate = 0.0
            state.data_loop_nodes.node[zone_node_num - 1].quality = 1.0
            state.data_loop_nodes.node[zone_node_num - 1].press = state.data_envrn.out_baro_press
            state.data_loop_nodes.node[zone_node_num - 1].hum_rat = state.data_envrn.out_hum_rat
            state.data_loop_nodes.node[zone_node_num - 1].enthalpy = state.psychrometrics.psy_h_fn_tdb_w(state.data_loop_nodes.node[zone_node_num - 1].temp, state.data_loop_nodes.node[zone_node_num - 1].hum_rat)

            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].zone_temp = 20.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].zone_hum_rat = 0.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].zone_enthalpy = 0.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].inlet_temp = 0.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].inlet_hum_rat = 0.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].inlet_enthalpy = 0.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].inlet_pressure = 0.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].inlet_mass_flow_rate = 0.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].inlet_mass_flow_rate_max_avail = 0.0
            state.data_zone_plenum.zone_ret_plen_cond[plenum_zone_num].inlet_mass_flow_rate_min_avail = 0.0

        state.data_zone_plenum.init_air_zone_return_plenum_envrn_flag = False

    if not state.data_global.begin_envrn_flag:
        state.data_zone_plenum.init_air_zone_return_plenum_envrn_flag = True

    var zone_plenum_num_idx: Int32 = zone_plenum_num - 1
    for node_num in range(state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].num_inlet_nodes):
        var inlet_node: Int32 = state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].inlet_node[node_num]
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].inlet_mass_flow_rate[node_num] = state.data_loop_nodes.node[inlet_node - 1].mass_flow_rate
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].inlet_mass_flow_rate_max_avail[node_num] = state.data_loop_nodes.node[inlet_node - 1].mass_flow_rate_max_avail
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].inlet_mass_flow_rate_min_avail[node_num] = state.data_loop_nodes.node[inlet_node - 1].mass_flow_rate_min_avail
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].inlet_pressure[node_num] = state.data_loop_nodes.node[inlet_node - 1].press

    var zone_node_num: Int32 = state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].zone_node_num
    for node_num in range(state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].num_induced_nodes):
        var induced_node: Int32 = state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_node[node_num]
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_mass_flow_rate[node_num] = state.data_loop_nodes.node[induced_node - 1].mass_flow_rate
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_mass_flow_rate_max_avail[node_num] = state.data_loop_nodes.node[induced_node - 1].mass_flow_rate_max_avail
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_mass_flow_rate_min_avail[node_num] = state.data_loop_nodes.node[induced_node - 1].mass_flow_rate_min_avail

        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_temp[node_num] = state.data_loop_nodes.node[zone_node_num - 1].temp
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_hum_rat[node_num] = state.data_loop_nodes.node[zone_node_num - 1].hum_rat
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_enthalpy[node_num] = state.data_loop_nodes.node[zone_node_num - 1].enthalpy
        state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_pressure[node_num] = state.data_loop_nodes.node[zone_node_num - 1].press
        if state.data_contaminant_balance.contaminant.co2_simulation:
            state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_co2[node_num] = state.data_loop_nodes.node[zone_node_num - 1].co2
        if state.data_contaminant_balance.contaminant.generic_contam_simulation:
            state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].induced_gen_contam[node_num] = state.data_loop_nodes.node[zone_node_num - 1].gen_contam

    state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].zone_temp = state.data_loop_nodes.node[zone_node_num - 1].temp
    state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].zone_hum_rat = state.data_loop_nodes.node[zone_node_num - 1].hum_rat
    state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx].zone_enthalpy = state.data_loop_nodes.node[zone_node_num - 1].enthalpy

fn init_air_zone_supply_plenum(state: AnyType, zone_plenum_num: Int32, first_hvac_iteration: Bool, first_call: Bool) -> None:
    if state.data_zone_plenum.my_envrn_flag and state.data_global.begin_envrn_flag:
        for plenum_zone_num in range(state.data_zone_plenum.num_zone_supply_plenums):
            var zone_node_num: Int32 = state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].zone_node_num
            var node = state.data_loop_nodes.node[zone_node_num - 1]
            node.temp = 20.0
            node.mass_flow_rate = 0.0
            node.quality = 1.0
            node.press = state.data_envrn.out_baro_press
            node.hum_rat = state.data_envrn.out_hum_rat
            node.enthalpy = state.psychrometrics.psy_h_fn_tdb_w(node.temp, node.hum_rat)

            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].zone_temp = 20.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].zone_hum_rat = 0.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].zone_enthalpy = 0.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].inlet_temp = 0.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].inlet_hum_rat = 0.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].inlet_enthalpy = 0.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].inlet_pressure = 0.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].inlet_mass_flow_rate = 0.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].inlet_mass_flow_rate_max_avail = 0.0
            state.data_zone_plenum.zone_sup_plen_cond[plenum_zone_num].inlet_mass_flow_rate_min_avail = 0.0

        state.data_zone_plenum.my_envrn_flag = False

    if not state.data_global.begin_envrn_flag:
        state.data_zone_plenum.my_envrn_flag = True

    var zone_plenum_num_idx: Int32 = zone_plenum_num - 1
    var inlet_node: Int32 = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].inlet_node
    var inlet_node_obj = state.data_loop_nodes.node[inlet_node - 1]
    var zone_node_num: Int32 = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].zone_node_num
    var zone_node = state.data_loop_nodes.node[zone_node_num - 1]

    if first_hvac_iteration and first_call:
        if inlet_node_obj.mass_flow_rate > 0.0:
            zone_node.mass_flow_rate = inlet_node_obj.mass_flow_rate
            for node_index in range(state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].num_outlet_nodes):
                var outlet_node: Int32 = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].outlet_node[node_index]
                state.data_loop_nodes.node[outlet_node - 1].mass_flow_rate = inlet_node_obj.mass_flow_rate / state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].num_outlet_nodes
        if inlet_node_obj.mass_flow_rate_max_avail > 0.0:
            zone_node.mass_flow_rate_max_avail = inlet_node_obj.mass_flow_rate_max_avail
            for node_index in range(state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].num_outlet_nodes):
                var outlet_node: Int32 = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].outlet_node[node_index]
                state.data_loop_nodes.node[outlet_node - 1].mass_flow_rate_max_avail = inlet_node_obj.mass_flow_rate_max_avail / state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].num_outlet_nodes

    if first_call:
        if inlet_node_obj.mass_flow_rate_max_avail == 0.0:
            for node_index in range(state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].num_outlet_nodes):
                var outlet_node: Int32 = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].outlet_node[node_index]
                var outlet_node_obj = state.data_loop_nodes.node[outlet_node - 1]
                outlet_node_obj.mass_flow_rate = 0.0
                outlet_node_obj.mass_flow_rate_max_avail = 0.0
                outlet_node_obj.mass_flow_rate_min_avail = 0.0

            zone_node.mass_flow_rate = 0.0
            zone_node.mass_flow_rate_max_avail = 0.0
            zone_node.mass_flow_rate_min_avail = 0.0

        state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].zone_temp = zone_node.temp
        state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].zone_hum_rat = zone_node.hum_rat
        state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].zone_enthalpy = zone_node.enthalpy

        for node_index in range(state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].num_outlet_nodes):
            var outlet_node: Int32 = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].outlet_node[node_index]
            var outlet_node_obj = state.data_loop_nodes.node[outlet_node - 1]
            outlet_node_obj.press = inlet_node_obj.press
            outlet_node_obj.quality = inlet_node_obj.quality

        zone_node.press = inlet_node_obj.press
        zone_node.quality = inlet_node_obj.quality

    else:
        for node_index in range(state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].num_outlet_nodes):
            var outlet_node: Int32 = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].outlet_node[node_index]
            var outlet_node_obj = state.data_loop_nodes.node[outlet_node - 1]
            state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].outlet_mass_flow_rate[node_index] = outlet_node_obj.mass_flow_rate
            state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].outlet_mass_flow_rate_max_avail[node_index] = outlet_node_obj.mass_flow_rate_max_avail
            state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx].outlet_mass_flow_rate_min_avail[node_index] = outlet_node_obj.mass_flow_rate_min_avail

fn calc_air_zone_return_plenum(state: AnyType, zone_plenum_num: Int32) -> None:
    var zone_plenum_num_idx: Int32 = zone_plenum_num - 1
    var ret_cond = state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx]

    ret_cond.outlet_mass_flow_rate = 0.0
    ret_cond.outlet_mass_flow_rate_max_avail = 0.0
    ret_cond.outlet_mass_flow_rate_min_avail = 0.0
    ret_cond.outlet_temp = 0.0
    ret_cond.outlet_hum_rat = 0.0
    ret_cond.outlet_pressure = 0.0
    ret_cond.outlet_enthalpy = 0.0
    var tot_ind_mass_flow_rate: Float64 = 0.0

    for inlet_node_num in range(ret_cond.num_inlet_nodes):
        ret_cond.outlet_mass_flow_rate += ret_cond.inlet_mass_flow_rate[inlet_node_num]
        ret_cond.outlet_mass_flow_rate_max_avail += ret_cond.inlet_mass_flow_rate_max_avail[inlet_node_num]
        ret_cond.outlet_mass_flow_rate_min_avail += ret_cond.inlet_mass_flow_rate_min_avail[inlet_node_num]

    if ret_cond.outlet_mass_flow_rate > 0.0:
        for inlet_node_num in range(ret_cond.num_inlet_nodes):
            ret_cond.outlet_pressure += ret_cond.inlet_pressure[inlet_node_num] * ret_cond.inlet_mass_flow_rate[inlet_node_num] / ret_cond.outlet_mass_flow_rate
    else:
        ret_cond.outlet_pressure = ret_cond.inlet_pressure[0]

    for adu_list_index in range(ret_cond.num_adus):
        var adu_num: Int32 = ret_cond.adu_index[adu_list_index] - 1
        var adu = state.data_define_equipment.air_dist_unit[adu_num]
        if adu.up_stream_leak or adu.down_stream_leak or adu.mass_flow_rate_parallel_piu_lk > 0:
            ret_cond.outlet_mass_flow_rate += adu.mass_flow_rate_up_str_lk + adu.mass_flow_rate_dn_str_lk + adu.mass_flow_rate_parallel_piu_lk
            ret_cond.outlet_mass_flow_rate_max_avail += adu.max_avail_delta
            ret_cond.outlet_mass_flow_rate_min_avail += adu.min_avail_delta

    for ind_num in range(ret_cond.num_induced_nodes):
        tot_ind_mass_flow_rate += ret_cond.induced_mass_flow_rate[ind_num]

    ret_cond.outlet_mass_flow_rate -= tot_ind_mass_flow_rate

    ret_cond.outlet_hum_rat = ret_cond.zone_hum_rat
    ret_cond.outlet_enthalpy = ret_cond.zone_enthalpy
    ret_cond.outlet_temp = ret_cond.zone_temp
    ret_cond.outlet_mass_flow_rate_max_avail = max(ret_cond.outlet_mass_flow_rate_max_avail, ret_cond.outlet_mass_flow_rate)

fn calc_air_zone_supply_plenum(state: AnyType, zone_plenum_num: Int32, first_call: Bool) -> None:
    var zone_plenum_num_idx: Int32 = zone_plenum_num - 1
    var sup_cond = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx]

    if first_call:
        for node_index in range(sup_cond.num_outlet_nodes):
            sup_cond.outlet_hum_rat[node_index] = sup_cond.zone_hum_rat

        for node_index in range(sup_cond.num_outlet_nodes):
            sup_cond.outlet_enthalpy[node_index] = sup_cond.zone_enthalpy

        for node_index in range(sup_cond.num_outlet_nodes):
            sup_cond.outlet_temp[node_index] = sup_cond.zone_temp

    else:
        sup_cond.inlet_mass_flow_rate = 0.0
        sup_cond.inlet_mass_flow_rate_max_avail = 0.0
        sup_cond.inlet_mass_flow_rate_min_avail = 0.0
        for node_index in range(sup_cond.num_outlet_nodes):
            sup_cond.inlet_mass_flow_rate += sup_cond.outlet_mass_flow_rate[node_index]
            sup_cond.inlet_mass_flow_rate_max_avail += sup_cond.outlet_mass_flow_rate_max_avail[node_index]
            sup_cond.inlet_mass_flow_rate_min_avail += sup_cond.outlet_mass_flow_rate_min_avail[node_index]

fn update_air_zone_return_plenum(state: AnyType, zone_plenum_num: Int32) -> None:
    var zone_plenum_num_idx: Int32 = zone_plenum_num - 1
    var zone_ret_plen_cond = state.data_zone_plenum.zone_ret_plen_cond[zone_plenum_num_idx]
    var outlet_node = state.data_loop_nodes.node[zone_ret_plen_cond.outlet_node - 1]
    var inlet_node = state.data_loop_nodes.node[zone_ret_plen_cond.inlet_node[0] - 1]
    var zone_node = state.data_loop_nodes.node[zone_ret_plen_cond.zone_node_num - 1]

    outlet_node.mass_flow_rate = zone_ret_plen_cond.outlet_mass_flow_rate
    outlet_node.mass_flow_rate_max_avail = zone_ret_plen_cond.outlet_mass_flow_rate_max_avail
    outlet_node.mass_flow_rate_min_avail = zone_ret_plen_cond.outlet_mass_flow_rate_min_avail

    zone_node.mass_flow_rate = zone_ret_plen_cond.outlet_mass_flow_rate
    zone_node.mass_flow_rate_max_avail = zone_ret_plen_cond.outlet_mass_flow_rate_max_avail
    zone_node.mass_flow_rate_min_avail = zone_ret_plen_cond.outlet_mass_flow_rate_min_avail
    zone_node.press = zone_ret_plen_cond.outlet_pressure

    outlet_node.temp = zone_ret_plen_cond.outlet_temp
    outlet_node.hum_rat = zone_ret_plen_cond.outlet_hum_rat
    outlet_node.enthalpy = zone_ret_plen_cond.outlet_enthalpy
    outlet_node.press = zone_ret_plen_cond.outlet_pressure

    for ind_num in range(zone_ret_plen_cond.num_induced_nodes):
        var induced_node = state.data_loop_nodes.node[zone_ret_plen_cond.induced_node[ind_num] - 1]
        induced_node.temp = zone_ret_plen_cond.induced_temp[ind_num]
        induced_node.hum_rat = zone_ret_plen_cond.induced_hum_rat[ind_num]
        induced_node.enthalpy = zone_ret_plen_cond.induced_enthalpy[ind_num]
        induced_node.press = zone_ret_plen_cond.induced_pressure[ind_num]
        if state.data_contaminant_balance.contaminant.co2_simulation:
            induced_node.co2 = zone_ret_plen_cond.induced_co2[ind_num]
        if state.data_contaminant_balance.contaminant.generic_contam_simulation:
            induced_node.gen_contam = zone_ret_plen_cond.induced_gen_contam[ind_num]
        induced_node.quality = inlet_node.quality

    outlet_node.quality = inlet_node.quality
    zone_node.quality = inlet_node.quality

    if state.data_contaminant_balance.contaminant.co2_simulation:
        if zone_ret_plen_cond.outlet_mass_flow_rate > 0.0:
            outlet_node.co2 = 0.0
            for inlet_node_num in range(zone_ret_plen_cond.num_inlet_nodes):
                outlet_node.co2 += state.data_loop_nodes.node[zone_ret_plen_cond.inlet_node[inlet_node_num] - 1].co2 * zone_ret_plen_cond.inlet_mass_flow_rate[inlet_node_num] / zone_ret_plen_cond.outlet_mass_flow_rate
            zone_node.co2 = outlet_node.co2
        else:
            outlet_node.co2 = zone_node.co2

    if state.data_contaminant_balance.contaminant.generic_contam_simulation:
        if zone_ret_plen_cond.outlet_mass_flow_rate > 0.0:
            outlet_node.gen_contam = 0.0
            for inlet_node_num in range(zone_ret_plen_cond.num_inlet_nodes):
                outlet_node.gen_contam += state.data_loop_nodes.node[zone_ret_plen_cond.inlet_node[inlet_node_num] - 1].gen_contam * zone_ret_plen_cond.inlet_mass_flow_rate[inlet_node_num] / zone_ret_plen_cond.outlet_mass_flow_rate
            zone_node.gen_contam = outlet_node.gen_contam
        else:
            outlet_node.gen_contam = zone_node.gen_contam

fn update_air_zone_supply_plenum(state: AnyType, zone_plenum_num: Int32, plenum_inlet_changed: Pointer[Bool], first_call: Bool) -> None:
    var FLOW_RATE_TOLER: Float64 = 0.01
    var zone_plenum_num_idx: Int32 = zone_plenum_num - 1
    var zone_sup_plen_con = state.data_zone_plenum.zone_sup_plen_cond[zone_plenum_num_idx]
    var inlet_node = state.data_loop_nodes.node[zone_sup_plen_con.inlet_node - 1]
    var zone_node = state.data_loop_nodes.node[zone_sup_plen_con.zone_node_num - 1]

    if first_call:
        for node_index in range(zone_sup_plen_con.num_outlet_nodes):
            var outlet_node_num: Int32 = zone_sup_plen_con.outlet_node[node_index]
            var outlet_node = state.data_loop_nodes.node[outlet_node_num - 1]
            outlet_node.temp = zone_sup_plen_con.outlet_temp[node_index]
            outlet_node.hum_rat = zone_sup_plen_con.outlet_hum_rat[node_index]
            outlet_node.enthalpy = zone_sup_plen_con.outlet_enthalpy[node_index]
            if state.data_contaminant_balance.contaminant.co2_simulation:
                outlet_node.co2 = inlet_node.co2
            if state.data_contaminant_balance.contaminant.generic_contam_simulation:
                outlet_node.gen_contam = inlet_node.gen_contam

        if state.data_contaminant_balance.contaminant.co2_simulation:
            zone_node.co2 = inlet_node.co2
        if state.data_contaminant_balance.contaminant.generic_contam_simulation:
            zone_node.gen_contam = inlet_node.gen_contam

    else:
        if fabs(inlet_node.mass_flow_rate - zone_sup_plen_con.inlet_mass_flow_rate) > FLOW_RATE_TOLER:
            if plenum_inlet_changed != Pointer[Bool]():
                plenum_inlet_changed[] = True

        inlet_node.mass_flow_rate = zone_sup_plen_con.inlet_mass_flow_rate
        inlet_node.mass_flow_rate_max_avail = zone_sup_plen_con.inlet_mass_flow_rate_max_avail
        inlet_node.mass_flow_rate_min_avail = zone_sup_plen_con.inlet_mass_flow_rate_min_avail

        zone_node.mass_flow_rate = zone_sup_plen_con.inlet_mass_flow_rate
        zone_node.mass_flow_rate_max_avail = zone_sup_plen_con.inlet_mass_flow_rate_max_avail
        zone_node.mass_flow_rate_min_avail = zone_sup_plen_con.inlet_mass_flow_rate_min_avail

fn get_return_plenum_index(state: AnyType, ex_node_num: Int32) -> Int32:
    if state.data_zone_plenum.get_input_flag:
        get_zone_plenum_input(state)
        state.data_zone_plenum.get_input_flag = False

    var which_plenum: Int32 = 0
    if state.data_zone_plenum.num_zone_return_plenums > 0:
        for plenum_num in range(state.data_zone_plenum.num_zone_return_plenums):
            if ex_node_num == state.data_zone_plenum.zone_ret_plen_cond[plenum_num].outlet_node:
                which_plenum = plenum_num + 1
                break
        if which_plenum == 0:
            for plenum_num in range(state.data_zone_plenum.num_zone_return_plenums):
                for induced_node_num in range(state.data_zone_plenum.zone_ret_plen_cond[plenum_num].num_induced_nodes):
                    if ex_node_num == state.data_zone_plenum.zone_ret_plen_cond[plenum_num].induced_node[induced_node_num]:
                        which_plenum = plenum_num + 1
                        break
                if which_plenum > 0:
                    break

    return which_plenum

fn get_return_plenum_name(state: AnyType, return_plenum_index: Int32) -> String:
    if state.data_zone_plenum.get_input_flag:
        get_zone_plenum_input(state)
        state.data_zone_plenum.get_input_flag = False

    var return_plenum_name: String = " "
    if state.data_zone_plenum.num_zone_return_plenums > 0:
        return_plenum_name = state.data_zone_plenum.zone_ret_plen_cond[return_plenum_index - 1].zone_plenum_name
    return return_plenum_name

fn get_return_plenum_index_from_inlet_node(state: AnyType, in_node_num: Int32) -> Int32:
    if state.data_zone_plenum.get_input_flag:
        get_zone_plenum_input(state)
        state.data_zone_plenum.get_input_flag = False

    var this_plenum: Int32 = 0
    if state.data_zone_plenum.num_zone_return_plenums > 0:
        for plenum_num in range(state.data_zone_plenum.num_zone_return_plenums):
            for in_node_ctr in range(state.data_zone_plenum.zone_ret_plen_cond[plenum_num].num_inlet_nodes):
                if in_node_num == state.data_zone_plenum.zone_ret_plen_cond[plenum_num].inlet_node[in_node_ctr]:
                    this_plenum = plenum_num + 1
                    break
            if this_plenum > 0:
                break

    return this_plenum

fn validate_induced_node(state: AnyType, induce_node_num: Int32, num_return_nodes: Int32, return_node: List[Int32]) -> Bool:
    var nodefound: Bool = False

    if state.data_zone_plenum.get_input_flag:
        get_zone_plenum_input(state)
        state.data_zone_plenum.get_input_flag = False

    if state.data_zone_plenum.num_zone_return_plenums > 0:
        for plenum_num in range(state.data_zone_plenum.num_zone_return_plenums):
            for induce_node_ctr in range(state.data_zone_plenum.zone_ret_plen_cond[plenum_num].num_induced_nodes):
                if induce_node_num == state.data_zone_plenum.zone_ret_plen_cond[plenum_num].induced_node[induce_node_ctr]:
                    for in_node_ctr in range(state.data_zone_plenum.zone_ret_plen_cond[plenum_num].num_inlet_nodes):
                        for return_node_num in range(num_return_nodes):
                            if return_node[return_node_num] == state.data_zone_plenum.zone_ret_plen_cond[plenum_num].inlet_node[in_node_ctr]:
                                nodefound = True
                                break
                        if nodefound:
                            break
                if nodefound:
                    break
            if nodefound:
                break

    return nodefound
