from math import max

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state object (state parameter)
# - DataDefineEquip.ZnAirLoopEquipType enum
# - DataDefineEquip.AirDistUnit array
# - Util.FindItemInList, Util.makeUPPER
# - ShowFatalError, ShowSevereError, ShowContinueError
# - ValidateComponent
# - Node.GetOnlySingleNode, Node.SetUpCompSets
# - SetupOutputVariable
# - DualDuct.SimulateDualDuct, DualDuct.GetDualDuctOutdoorAirRecircUse
# - SingleDuct.SimulateSingleDuct, SingleDuct.GetATMixers
# - PoweredInductionUnits.SimPIU
# - HVACSingleDuctInduc.SimIndUnit
# - HVACCooledBeam.SimCoolBeam
# - HVACFourPipeBeam.HVACFourPipeBeam.fourPipeBeamFactory
# - UserDefinedComponents.SimAirTerminalUserDefined
# - Psychrometrics.PsyDeltaHSenFnTdb2W2Tdb1W1, PsyCpAirFnW
# - DataLoopNode, DataZoneEquipment, DataSizing, DataHeatBalance, DataAirLoop, DataPowerInductionUnits

alias ZnAirLoopEquipTypeNamesUC = InlineArray[StringRef, 17](
    "AIRTERMINAL:DUALDUCT:CONSTANTVOLUME",
    "AIRTERMINAL:DUALDUCT:VAV",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:COOLEDBEAM",
    "AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR",
    "AIRTERMINAL:SINGLEDUCT:USERDEFINED",
    "AIRTERMINAL:SINGLEDUCT:MIXER",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEBEAM",
)


struct ZoneAirLoopEquipmentManagerData:
    var get_air_dist_units_flag: Bool
    var init_air_dist_units_flag: Bool
    var num_adu_initialized: Int32

    fn __init__(inout self):
        self.get_air_dist_units_flag = True
        self.init_air_dist_units_flag = True
        self.num_adu_initialized = 0

    fn init_constant_state(inout self, state: EnergyPlusData):
        pass

    fn init_state(inout self, state: EnergyPlusData):
        pass

    fn clear_state(inout self):
        self.get_air_dist_units_flag = True
        self.init_air_dist_units_flag = True
        self.num_adu_initialized = 0


fn manage_zone_air_loop_equipment(
    inout state: EnergyPlusData,
    zone_air_loop_equip_name: StringRef,
    first_hvac_iteration: Bool,
    inout sys_output_provided: Float64,
    inout non_air_sys_output: Float64,
    inout lat_output_provided: Float64,
    controlled_zone_num: Int32,
    inout comp_index: Int32,
):
    if state.dataZoneAirLoopEquipmentManager.get_air_dist_units_flag:
        get_zone_air_loop_equipment(state)
        state.dataZoneAirLoopEquipmentManager.get_air_dist_units_flag = False

    var air_dist_unit_num: Int32

    if comp_index == 0:
        air_dist_unit_num = util_find_item_in_list(
            zone_air_loop_equip_name, state.dataDefineEquipment.AirDistUnit
        )
        if air_dist_unit_num == 0:
            show_fatal_error(
                state,
                "ManageZoneAirLoopEquipment: Unit not found=" + zone_air_loop_equip_name,
            )
        comp_index = air_dist_unit_num
    else:
        air_dist_unit_num = comp_index
        if (
            air_dist_unit_num
            > len(state.dataDefineEquipment.AirDistUnit)
            or air_dist_unit_num < 1
        ):
            show_fatal_error(
                state,
                "ManageZoneAirLoopEquipment:  Invalid CompIndex passed="
                + str(air_dist_unit_num)
                + ", Number of Units="
                + str(len(state.dataDefineEquipment.AirDistUnit))
                + ", Entered Unit name="
                + zone_air_loop_equip_name,
            )
        if (
            zone_air_loop_equip_name
            != state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1].Name
        ):
            show_fatal_error(
                state,
                "ManageZoneAirLoopEquipment: Invalid CompIndex passed="
                + str(air_dist_unit_num)
                + ", Unit name="
                + zone_air_loop_equip_name
                + ", stored Unit Name for that index="
                + state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1].Name,
            )

    state.dataSize.CurTermUnitSizingNum = state.dataDefineEquipment.AirDistUnit[
        air_dist_unit_num - 1
    ].TermUnitSizingNum
    init_zone_air_loop_equipment(state, air_dist_unit_num, controlled_zone_num)
    init_zone_air_loop_equipment_time_step(state, air_dist_unit_num)
    sim_zone_air_loop_equipment(
        state,
        air_dist_unit_num,
        sys_output_provided,
        non_air_sys_output,
        lat_output_provided,
        first_hvac_iteration,
        controlled_zone_num,
    )
    init_zone_air_loop_equipment(state, air_dist_unit_num, controlled_zone_num)


fn get_zone_air_loop_equipment(inout state: EnergyPlusData):
    var routine_name = "GetZoneAirLoopEquipment: "
    var current_module_object = "ZoneHVAC:AirDistributionUnit"

    var errors_found = False
    var alph_array = InlineArray[String, 5]()
    var num_array = InlineArray[Float64, 2]()
    var c_alpha_fields = InlineArray[String, 5]()
    var c_numeric_fields = InlineArray[String, 2]()
    var l_alpha_blanks = InlineArray[Bool, 5](fill=False)
    var l_numeric_blanks = InlineArray[Bool, 2](fill=False)

    var num_air_dist_units = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    if num_air_dist_units > 0:
        for air_dist_unit_num in range(1, num_air_dist_units + 1):
            var air_dist_unit = state.dataDefineEquipment.AirDistUnit[
                air_dist_unit_num - 1
            ]

            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                current_module_object,
                air_dist_unit_num,
                alph_array,
                num_array,
                l_numeric_blanks,
                l_alpha_blanks,
                c_alpha_fields,
                c_numeric_fields,
            )

            air_dist_unit.Name = alph_array[0]
            air_dist_unit.OutletNodeNum = get_only_single_node(
                state,
                alph_array[1],
                errors_found,
                "ZoneHVAC:AirDistributionUnit",
                alph_array[0],
            )
            air_dist_unit.InletNodeNum = 0
            air_dist_unit.NumComponents = 1
            var air_dist_comp_unit_num = 1
            air_dist_unit.EquipType[air_dist_comp_unit_num - 1] = alph_array[2]
            air_dist_unit.EquipName[air_dist_comp_unit_num - 1] = alph_array[3]
            var is_not_ok = False
            validate_component(
                state,
                alph_array[2],
                alph_array[3],
                is_not_ok,
                current_module_object,
            )
            if is_not_ok:
                show_continue_error(
                    state, "In " + current_module_object + " = " + alph_array[0]
                )
                errors_found = True

            air_dist_unit.UpStreamLeakFrac = num_array[0]
            air_dist_unit.DownStreamLeakFrac = num_array[1]

            if air_dist_unit.DownStreamLeakFrac <= 0.0:
                air_dist_unit.LeakLoadMult = 1.0
            elif 0.0 < air_dist_unit.DownStreamLeakFrac and air_dist_unit.DownStreamLeakFrac < 1.0:
                air_dist_unit.LeakLoadMult = 1.0 / (
                    1.0 - air_dist_unit.DownStreamLeakFrac
                )
            else:
                show_severe_error(
                    state,
                    "Error found in " + current_module_object + " = " + air_dist_unit.Name,
                )
                show_continue_error(
                    state, c_numeric_fields[1] + " must be less than 1.0"
                )
                errors_found = True

            if air_dist_unit.UpStreamLeakFrac > 0.0:
                air_dist_unit.UpStreamLeak = True
            else:
                air_dist_unit.UpStreamLeak = False

            if air_dist_unit.DownStreamLeakFrac > 0.0:
                air_dist_unit.DownStreamLeak = True
            else:
                air_dist_unit.DownStreamLeak = False

            air_dist_unit.AirTerminalSizingSpecIndex = 0
            if not l_alpha_blanks[4]:
                air_dist_unit.AirTerminalSizingSpecIndex = util_find_item_in_list(
                    alph_array[4], state.dataSize.AirTerminalSizingSpec
                )
                if air_dist_unit.AirTerminalSizingSpecIndex == 0:
                    show_severe_error(
                        state,
                        c_alpha_fields[4] + " = " + alph_array[4] + " not found.",
                    )
                    show_continue_error(
                        state,
                        "Occurs in " + current_module_object + " = " + air_dist_unit.Name,
                    )
                    errors_found = True

            var type_name_uc = util_make_upper(air_dist_unit.EquipType[air_dist_comp_unit_num - 1])
            air_dist_unit.EquipTypeEnum[air_dist_comp_unit_num - 1] = get_enum_value(
                ZnAirLoopEquipTypeNamesUC, type_name_uc
            )

            var equip_type_enum = air_dist_unit.EquipTypeEnum[
                air_dist_comp_unit_num - 1
            ]

            if equip_type_enum in [
                "DualDuctConstVolume",
                "DualDuctVAV",
                "DualDuctVAVOutdoorAir",
                "SingleDuct_SeriesPIU_Reheat",
                "SingleDuct_ParallelPIU_Reheat",
                "SingleDuct_ConstVol_4PipeInduc",
                "SingleDuctVAVReheatVSFan",
                "SingleDuctConstVolCooledBeam",
                "SingleDuctUserDefined",
                "SingleDuctATMixer",
            ]:
                if air_dist_unit.UpStreamLeak or air_dist_unit.DownStreamLeak:
                    show_severe_error(
                        state,
                        "Error found in " + current_module_object + " = " + air_dist_unit.Name,
                    )
                    show_continue_error(
                        state,
                        "Simple duct leakage model not available for "
                        + c_alpha_fields[2]
                        + " = "
                        + air_dist_unit.EquipType[air_dist_comp_unit_num - 1],
                    )
                    errors_found = True
            elif equip_type_enum == "SingleDuctConstVolFourPipeBeam":
                air_dist_unit.airTerminalPtr = hvac_four_pipe_beam_factory(
                    state, air_dist_unit.EquipName[0]
                )
                if air_dist_unit.UpStreamLeak or air_dist_unit.DownStreamLeak:
                    show_severe_error(
                        state,
                        "Error found in " + current_module_object + " = " + air_dist_unit.Name,
                    )
                    show_continue_error(
                        state,
                        "Simple duct leakage model not available for "
                        + c_alpha_fields[2]
                        + " = "
                        + air_dist_unit.EquipType[air_dist_comp_unit_num - 1],
                    )
                    errors_found = True
            elif equip_type_enum in [
                "SingleDuctConstVolReheat",
                "SingleDuctConstVolNoReheat",
            ]:
                pass
            elif equip_type_enum in [
                "SingleDuctVAVReheat",
                "SingleDuctVAVNoReheat",
                "SingleDuctCBVAVReheat",
                "SingleDuctCBVAVNoReheat",
            ]:
                air_dist_unit.IsConstLeakageRate = True
            else:
                show_severe_error(
                    state,
                    "Error found in " + current_module_object + " = " + air_dist_unit.Name,
                )
                show_continue_error(
                    state,
                    "Invalid " + c_alpha_fields[2] + " = " + air_dist_unit.EquipType[air_dist_comp_unit_num - 1],
                )
                errors_found = True

            if equip_type_enum in ["DualDuctConstVolume", "DualDuctVAV"]:
                set_up_comp_sets(
                    state,
                    current_module_object,
                    air_dist_unit.Name,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1] + ":HEAT",
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    "UNDEFINED",
                    alph_array[1],
                )
                set_up_comp_sets(
                    state,
                    current_module_object,
                    air_dist_unit.Name,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1] + ":COOL",
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    "UNDEFINED",
                    alph_array[1],
                )
            elif equip_type_enum == "DualDuctVAVOutdoorAir":
                set_up_comp_sets(
                    state,
                    current_module_object,
                    air_dist_unit.Name,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1] + ":OutdoorAir",
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    "UNDEFINED",
                    alph_array[1],
                )
                var dual_duct_recirc_is_used = False
                get_dual_duct_outdoor_air_recirc_use(
                    state,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1],
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    dual_duct_recirc_is_used,
                )
                if dual_duct_recirc_is_used:
                    set_up_comp_sets(
                        state,
                        current_module_object,
                        air_dist_unit.Name,
                        air_dist_unit.EquipType[air_dist_comp_unit_num - 1]
                        + ":RecirculatedAir",
                        air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                        "UNDEFINED",
                        alph_array[1],
                    )
            else:
                set_up_comp_sets(
                    state,
                    current_module_object,
                    air_dist_unit.Name,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1],
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    "UNDEFINED",
                    alph_array[1],
                )

        for air_dist_unit_num in range(
            1, len(state.dataDefineEquipment.AirDistUnit) + 1
        ):
            var air_dist_unit = state.dataDefineEquipment.AirDistUnit[
                air_dist_unit_num - 1
            ]
            setup_output_variable(
                state,
                "Zone Air Terminal Sensible Heating Energy",
                "J",
                air_dist_unit.HeatGain,
                "System",
                "Sum",
                air_dist_unit.Name,
            )
            setup_output_variable(
                state,
                "Zone Air Terminal Sensible Cooling Energy",
                "J",
                air_dist_unit.CoolGain,
                "System",
                "Sum",
                air_dist_unit.Name,
            )
            setup_output_variable(
                state,
                "Zone Air Terminal Sensible Heating Rate",
                "W",
                air_dist_unit.HeatRate,
                "System",
                "Average",
                air_dist_unit.Name,
            )
            setup_output_variable(
                state,
                "Zone Air Terminal Sensible Cooling Rate",
                "W",
                air_dist_unit.CoolRate,
                "System",
                "Average",
                air_dist_unit.Name,
            )

    if errors_found:
        show_fatal_error(
            state,
            routine_name + "Errors found in getting " + current_module_object + " Input",
        )


fn init_zone_air_loop_equipment(
    inout state: EnergyPlusData,
    air_dist_unit_num: Int32,
    controlled_zone_num: Int32,
):
    if not state.dataZoneAirLoopEquipmentManager.init_air_dist_units_flag:
        return

    var air_dist_unit = state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1]

    if air_dist_unit.EachOnceFlag and (air_dist_unit.TermUnitSizingNum > 0):
        air_dist_unit.ZoneNum = controlled_zone_num
        var zone_eq_config = state.dataZoneEquip.ZoneEquipConfig[controlled_zone_num - 1]

        for inlet_num in range(1, zone_eq_config.NumInletNodes + 1):
            if zone_eq_config.InletNode[inlet_num - 1] == air_dist_unit.OutletNodeNum:
                zone_eq_config.InletNodeADUNum[inlet_num - 1] = air_dist_unit_num

        var term_unit_sizing_data = state.dataSize.TermUnitSizing[
            air_dist_unit.TermUnitSizingNum - 1
        ]
        term_unit_sizing_data.ADUName = air_dist_unit.Name

        if air_dist_unit.AirTerminalSizingSpecIndex > 0:
            var air_term_sizing_spec = state.dataSize.AirTerminalSizingSpec[
                air_dist_unit.AirTerminalSizingSpecIndex - 1
            ]
            term_unit_sizing_data.SpecDesCoolSATRatio = air_term_sizing_spec.DesCoolSATRatio
            term_unit_sizing_data.SpecDesHeatSATRatio = air_term_sizing_spec.DesHeatSATRatio
            term_unit_sizing_data.SpecDesSensCoolingFrac = air_term_sizing_spec.DesSensCoolingFrac
            term_unit_sizing_data.SpecDesSensHeatingFrac = air_term_sizing_spec.DesSensHeatingFrac
            term_unit_sizing_data.SpecMinOAFrac = air_term_sizing_spec.MinOAFrac

        if (
            air_dist_unit.ZoneNum != 0
            and state.dataHeatBal.Zone[air_dist_unit.ZoneNum - 1].HasAdjustedReturnTempByITE
        ):
            for air_dist_comp_num in range(1, air_dist_unit.NumComponents + 1):
                if air_dist_unit.EquipTypeEnum[air_dist_comp_num - 1] not in [
                    "SingleDuctVAVReheat",
                    "SingleDuctVAVNoReheat",
                ]:
                    show_severe_error(
                        state,
                        "The FlowControlWithApproachTemperatures only works with ITE zones with single duct VAV terminal unit.",
                    )
                    show_continue_error(
                        state,
                        "The return air temperature of the ITE will not be overwritten.",
                    )
                    show_fatal_error(state, "Preceding condition causes termination.")

        air_dist_unit.EachOnceFlag = False
        state.dataZoneAirLoopEquipmentManager.num_adu_initialized += 1
        if (
            state.dataZoneAirLoopEquipmentManager.num_adu_initialized
            == len(state.dataDefineEquipment.AirDistUnit)
        ):
            state.dataZoneAirLoopEquipmentManager.init_air_dist_units_flag = False


fn init_zone_air_loop_equipment_time_step(
    inout state: EnergyPlusData, air_dist_unit_num: Int32
):
    var air_dist_unit = state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1]
    air_dist_unit.MassFlowRateDnStrLk = 0.0
    air_dist_unit.MassFlowRateUpStrLk = 0.0
    air_dist_unit.parallelPIUTerminalLeakFrac = 0.0
    air_dist_unit.massFlowRateParallelPIULk = 0.0
    air_dist_unit.MassFlowRateTU = 0.0
    air_dist_unit.MassFlowRateZSup = 0.0
    air_dist_unit.MassFlowRateSup = 0.0
    air_dist_unit.HeatRate = 0.0
    air_dist_unit.CoolRate = 0.0
    air_dist_unit.HeatGain = 0.0
    air_dist_unit.CoolGain = 0.0


fn sim_zone_air_loop_equipment(
    inout state: EnergyPlusData,
    air_dist_unit_num: Int32,
    inout sys_output_provided: Float64,
    inout non_air_sys_output: Float64,
    inout lat_output_provided: Float64,
    first_hvac_iteration: Bool,
    controlled_zone_num: Int32,
):
    var controlled_zone_air_node = state.dataZoneEquip.ZoneEquipConfig[
        controlled_zone_num - 1
    ].ZoneNode

    var provide_sys_output = True
    var air_dist_unit = state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1]

    for air_dist_comp_num in range(1, air_dist_unit.NumComponents + 1):
        non_air_sys_output = 0.0

        var in_node_num = air_dist_unit.InletNodeNum
        var out_node_num = air_dist_unit.OutletNodeNum
        var mass_flow_rate_max_avail = 0.0
        var mass_flow_rate_min_avail = 0.0
        air_dist_unit.parallelPIUTerminalLeakFrac = 0.0

        if (
            air_dist_unit.UpStreamLeak
            or air_dist_unit.DownStreamLeak
            or air_dist_unit.EquipTypeEnum[air_dist_comp_num - 1]
            == "SingleDuct_ParallelPIU_Reheat"
        ):
            if in_node_num > 0:
                mass_flow_rate_max_avail = state.dataLoopNodes.Node[
                    in_node_num - 1
                ].MassFlowRateMaxAvail
                mass_flow_rate_min_avail = state.dataLoopNodes.Node[
                    in_node_num - 1
                ].MassFlowRateMinAvail

                if air_dist_unit.IsConstLeakageRate:
                    var air_loop_num = air_dist_unit.AirLoopNum
                    var des_flow_ratio: Float64
                    if air_loop_num > 0:
                        des_flow_ratio = state.dataAirLoop.AirLoopFlow[
                            air_loop_num - 1
                        ].SysToZoneDesFlowRatio
                    else:
                        des_flow_ratio = 1.0

                    var mass_flow_rate_up_stream_leak_max = max(
                        air_dist_unit.UpStreamLeakFrac
                        * state.dataLoopNodes.Node[in_node_num - 1].MassFlowRateMax
                        * des_flow_ratio,
                        0.0,
                    )
                else:
                    var mass_flow_rate_up_stream_leak_max = max(
                        air_dist_unit.UpStreamLeakFrac * mass_flow_rate_max_avail, 0.0
                    )

                if mass_flow_rate_max_avail > mass_flow_rate_up_stream_leak_max:
                    air_dist_unit.MassFlowRateUpStrLk = mass_flow_rate_up_stream_leak_max
                    state.dataLoopNodes.Node[
                        in_node_num - 1
                    ].MassFlowRateMaxAvail = (
                        mass_flow_rate_max_avail - mass_flow_rate_up_stream_leak_max
                    )
                else:
                    air_dist_unit.MassFlowRateUpStrLk = mass_flow_rate_max_avail
                    state.dataLoopNodes.Node[in_node_num - 1].MassFlowRateMaxAvail = 0.0

                state.dataLoopNodes.Node[in_node_num - 1].MassFlowRateMinAvail = max(
                    0.0,
                    mass_flow_rate_min_avail - air_dist_unit.MassFlowRateUpStrLk,
                )

        var equip_type_enum = air_dist_unit.EquipTypeEnum[air_dist_comp_num - 1]

        if equip_type_enum == "DualDuctConstVolume":
            simulate_dual_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "DualDuctVAV":
            simulate_dual_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "DualDuctVAVOutdoorAir":
            simulate_dual_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctVAVReheat":
            simulate_single_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctCBVAVReheat":
            simulate_single_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctVAVNoReheat":
            simulate_single_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctCBVAVNoReheat":
            simulate_single_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctConstVolReheat":
            simulate_single_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctConstVolNoReheat":
            simulate_single_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuct_SeriesPIU_Reheat":
            sim_piu(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuct_ParallelPIU_Reheat":
            sim_piu(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
            var piu_num = util_find_item_in_list(
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                state.dataPowerInductionUnits.PIU,
            )
            if piu_num > 0:
                air_dist_unit.parallelPIUTerminalLeakFrac = (
                    state.dataPowerInductionUnits.PIU[piu_num - 1].leakFrac
                )
                if (
                    state.dataPowerInductionUnits.PIU[piu_num - 1].damperLeakageZoneNum > 0
                    and air_dist_unit.piuLkZoneNum <= 0
                ):
                    air_dist_unit.piuLkZoneNum = (
                        state.dataPowerInductionUnits.PIU[piu_num - 1].damperLeakageZoneNum
                    )

        elif equip_type_enum == "SingleDuct_ConstVol_4PipeInduc":
            sim_ind_unit(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctVAVReheatVSFan":
            simulate_single_duct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctConstVolCooledBeam":
            sim_cool_beam(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
                non_air_sys_output,
            )
        elif equip_type_enum == "SingleDuctConstVolFourPipeBeam":
            air_dist_unit.airTerminalPtr.simulate(
                state, first_hvac_iteration, non_air_sys_output
            )
        elif equip_type_enum == "SingleDuctUserDefined":
            sim_air_terminal_user_defined(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctATMixer":
            get_at_mixers(state)
            provide_sys_output = False
        else:
            show_severe_error(
                state,
                "Error found in ZoneHVAC:AirDistributionUnit=" + air_dist_unit.Name,
            )
            show_continue_error(
                state,
                "Invalid Component=" + air_dist_unit.EquipType[air_dist_comp_num - 1],
            )
            show_fatal_error(state, "Preceding condition causes termination.")

        if in_node_num > 0:
            in_node_num = air_dist_unit.InletNodeNum
            if air_dist_unit.UpStreamLeak:
                state.dataLoopNodes.Node[
                    in_node_num - 1
                ].MassFlowRateMaxAvail = mass_flow_rate_max_avail
                state.dataLoopNodes.Node[
                    in_node_num - 1
                ].MassFlowRateMinAvail = mass_flow_rate_min_avail

            if (
                (
                    air_dist_unit.UpStreamLeak
                    or air_dist_unit.DownStreamLeak
                    or air_dist_unit.parallelPIUTerminalLeakFrac > 0.0
                )
                and mass_flow_rate_max_avail > 0.0
            ):
                air_dist_unit.MassFlowRateTU = state.dataLoopNodes.Node[
                    in_node_num - 1
                ].MassFlowRate
                air_dist_unit.MassFlowRateZSup = max(
                    air_dist_unit.MassFlowRateTU
                    * (
                        1.0
                        - air_dist_unit.DownStreamLeakFrac
                        - air_dist_unit.parallelPIUTerminalLeakFrac
                    ),
                    0.0,
                )
                air_dist_unit.MassFlowRateDnStrLk = (
                    air_dist_unit.MassFlowRateTU * air_dist_unit.DownStreamLeakFrac
                )
                air_dist_unit.massFlowRateParallelPIULk = (
                    air_dist_unit.MassFlowRateTU
                    * air_dist_unit.parallelPIUTerminalLeakFrac
                )
                air_dist_unit.MassFlowRateSup = (
                    air_dist_unit.MassFlowRateTU + air_dist_unit.MassFlowRateUpStrLk
                )
                state.dataLoopNodes.Node[in_node_num - 1].MassFlowRate = (
                    air_dist_unit.MassFlowRateSup
                )
                state.dataLoopNodes.Node[out_node_num - 1].MassFlowRate = (
                    air_dist_unit.MassFlowRateZSup
                )
                state.dataLoopNodes.Node[out_node_num - 1].MassFlowRateMaxAvail = max(
                    0.0,
                    mass_flow_rate_max_avail
                    - air_dist_unit.MassFlowRateDnStrLk
                    - air_dist_unit.MassFlowRateUpStrLk
                    - air_dist_unit.massFlowRateParallelPIULk,
                )
                state.dataLoopNodes.Node[out_node_num - 1].MassFlowRateMinAvail = max(
                    0.0,
                    mass_flow_rate_min_avail
                    - air_dist_unit.MassFlowRateDnStrLk
                    - air_dist_unit.MassFlowRateUpStrLk
                    - air_dist_unit.massFlowRateParallelPIULk,
                )
                air_dist_unit.MaxAvailDelta = (
                    mass_flow_rate_max_avail
                    - state.dataLoopNodes.Node[out_node_num - 1].MassFlowRateMaxAvail
                )
                air_dist_unit.MinAvailDelta = (
                    mass_flow_rate_min_avail
                    - state.dataLoopNodes.Node[out_node_num - 1].MassFlowRateMinAvail
                )
            else:
                var term_unit_type = air_dist_unit.EquipTypeEnum[air_dist_comp_num - 1]
                if term_unit_type in [
                    "DualDuctConstVolume",
                    "DualDuctVAV",
                    "DualDuctVAVOutdoorAir",
                ]:
                    air_dist_unit.MassFlowRateTU = state.dataLoopNodes.Node[
                        out_node_num - 1
                    ].MassFlowRate
                    air_dist_unit.MassFlowRateZSup = state.dataLoopNodes.Node[
                        out_node_num - 1
                    ].MassFlowRate
                    air_dist_unit.MassFlowRateSup = state.dataLoopNodes.Node[
                        out_node_num - 1
                    ].MassFlowRate
                else:
                    air_dist_unit.MassFlowRateTU = state.dataLoopNodes.Node[
                        in_node_num - 1
                    ].MassFlowRate
                    air_dist_unit.MassFlowRateZSup = state.dataLoopNodes.Node[
                        in_node_num - 1
                    ].MassFlowRate
                    air_dist_unit.MassFlowRateSup = state.dataLoopNodes.Node[
                        in_node_num - 1
                    ].MassFlowRate

    if provide_sys_output:
        var outlet_node_num = air_dist_unit.OutletNodeNum
        var spec_hum_out = state.dataLoopNodes.Node[outlet_node_num - 1].HumRat
        var spec_hum_in = state.dataLoopNodes.Node[controlled_zone_air_node - 1].HumRat

        sys_output_provided = (
            state.dataLoopNodes.Node[outlet_node_num - 1].MassFlowRate
            * psy_delta_h_sen_fn_tdb2_w2_tdb1_w1(
                state.dataLoopNodes.Node[outlet_node_num - 1].Temp,
                spec_hum_out,
                state.dataLoopNodes.Node[controlled_zone_air_node - 1].Temp,
                spec_hum_in,
            )
        )

        lat_output_provided = (
            state.dataLoopNodes.Node[outlet_node_num - 1].MassFlowRate
            * (spec_hum_out - spec_hum_in)
        )
    else:
        sys_output_provided = 0.0
        lat_output_provided = 0.0


fn util_find_item_in_list(item: StringRef, items_list) -> Int32:
    for i in range(len(items_list)):
        if items_list[i].Name == item:
            return Int32(i + 1)
    return 0


fn util_make_upper(s: StringRef) -> String:
    return String(s).upper()


fn get_enum_value(enum_list, value: StringRef) -> Int32:
    for i in range(len(enum_list)):
        if enum_list[i] == value:
            return Int32(i + 1)
    return 0


fn get_only_single_node(state, *args) -> Int32:
    return 0


fn validate_component(state, *args):
    pass


fn show_fatal_error(state, msg: StringRef):
    raise msg


fn show_severe_error(state, msg: StringRef):
    print("SEVERE ERROR: " + msg)


fn show_continue_error(state, msg: StringRef):
    print("CONTINUE ERROR: " + msg)


fn set_up_comp_sets(state, *args):
    pass


fn get_dual_duct_outdoor_air_recirc_use(state, *args):
    pass


fn setup_output_variable(state, *args):
    pass


fn simulate_dual_duct(state, *args):
    pass


fn simulate_single_duct(state, *args):
    pass


fn sim_piu(state, *args):
    pass


fn sim_ind_unit(state, *args):
    pass


fn sim_cool_beam(state, *args):
    pass


fn sim_air_terminal_user_defined(state, *args):
    pass


fn get_at_mixers(state):
    pass


fn hvac_four_pipe_beam_factory(state, name: StringRef):
    return None


fn psy_delta_h_sen_fn_tdb2_w2_tdb1_w1(t2, w2, t1, w1) -> Float64:
    return 0.0
