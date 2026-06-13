from dataclasses import dataclass, field
from typing import Protocol, List, Optional
from enum import Enum

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

ZN_AIR_LOOP_EQUIP_TYPE_NAMES_UC = [
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
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEBEAM"
]


@dataclass
class ZoneAirLoopEquipmentManagerData:
    GetAirDistUnitsFlag: bool = True
    InitAirDistUnitsFlag: bool = True
    numADUInitialized: int = 0

    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        self.GetAirDistUnitsFlag = True
        self.InitAirDistUnitsFlag = True
        self.numADUInitialized = 0


def manage_zone_air_loop_equipment(
    state,
    zone_air_loop_equip_name: str,
    first_hvac_iteration: bool,
    sys_output_provided: List[float],
    non_air_sys_output: List[float],
    lat_output_provided: List[float],
    controlled_zone_num: int,
    comp_index: List[int],
):
    if state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag:
        get_zone_air_loop_equipment(state)
        state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False

    if comp_index[0] == 0:
        air_dist_unit_num = Util_FindItemInList(
            zone_air_loop_equip_name, state.dataDefineEquipment.AirDistUnit
        )
        if air_dist_unit_num == 0:
            ShowFatalError(
                state,
                f"ManageZoneAirLoopEquipment: Unit not found={zone_air_loop_equip_name}",
            )
        comp_index[0] = air_dist_unit_num
    else:
        air_dist_unit_num = comp_index[0]
        if (
            air_dist_unit_num > len(state.dataDefineEquipment.AirDistUnit)
            or air_dist_unit_num < 1
        ):
            ShowFatalError(
                state,
                f"ManageZoneAirLoopEquipment:  Invalid CompIndex passed={air_dist_unit_num}, "
                f"Number of Units={len(state.dataDefineEquipment.AirDistUnit)}, "
                f"Entered Unit name={zone_air_loop_equip_name}",
            )
        if (
            zone_air_loop_equip_name
            != state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1].Name
        ):
            ShowFatalError(
                state,
                f"ManageZoneAirLoopEquipment: Invalid CompIndex passed={air_dist_unit_num}, "
                f"Unit name={zone_air_loop_equip_name}, "
                f"stored Unit Name for that index="
                f"{state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1].Name}",
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


def get_zone_air_loop_equipment(state):
    ROUTINE_NAME = "GetZoneAirLoopEquipment: "
    CURRENT_MODULE_OBJECT = "ZoneHVAC:AirDistributionUnit"

    errors_found = False
    alph_array = [""] * 5
    num_array = [0.0] * 2
    c_alpha_fields = [""] * 5
    c_numeric_fields = [""] * 2
    l_alpha_blanks = [False] * 5
    l_numeric_blanks = [False] * 2

    num_air_dist_units = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, CURRENT_MODULE_OBJECT
    )

    state.dataDefineEquipment.AirDistUnit = [None] * num_air_dist_units

    if num_air_dist_units > 0:
        for air_dist_unit_num in range(1, num_air_dist_units + 1):
            air_dist_unit = state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1]

            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                CURRENT_MODULE_OBJECT,
                air_dist_unit_num,
                alph_array,
                num_array,
                l_numeric_blanks,
                l_alpha_blanks,
                c_alpha_fields,
                c_numeric_fields,
            )

            air_dist_unit.Name = alph_array[0]
            air_dist_unit.OutletNodeNum = GetOnlySingleNode(
                state,
                alph_array[1],
                errors_found,
                "ZoneHVAC:AirDistributionUnit",
                alph_array[0],
            )
            air_dist_unit.InletNodeNum = 0
            air_dist_unit.NumComponents = 1
            air_dist_comp_unit_num = 1
            air_dist_unit.EquipType[air_dist_comp_unit_num - 1] = alph_array[2]
            air_dist_unit.EquipName[air_dist_comp_unit_num - 1] = alph_array[3]
            is_not_ok = False
            ValidateComponent(
                state,
                alph_array[2],
                alph_array[3],
                is_not_ok,
                CURRENT_MODULE_OBJECT,
            )
            if is_not_ok:
                ShowContinueError(
                    state, f"In {CURRENT_MODULE_OBJECT} = {alph_array[0]}"
                )
                errors_found = True

            air_dist_unit.UpStreamLeakFrac = num_array[0]
            air_dist_unit.DownStreamLeakFrac = num_array[1]

            if air_dist_unit.DownStreamLeakFrac <= 0.0:
                air_dist_unit.LeakLoadMult = 1.0
            elif 0.0 < air_dist_unit.DownStreamLeakFrac < 1.0:
                air_dist_unit.LeakLoadMult = 1.0 / (1.0 - air_dist_unit.DownStreamLeakFrac)
            else:
                ShowSevereError(
                    state,
                    f"Error found in {CURRENT_MODULE_OBJECT} = {air_dist_unit.Name}",
                )
                ShowContinueError(
                    state, f"{c_numeric_fields[1]} must be less than 1.0"
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
                air_dist_unit.AirTerminalSizingSpecIndex = Util_FindItemInList(
                    alph_array[4], state.dataSize.AirTerminalSizingSpec
                )
                if air_dist_unit.AirTerminalSizingSpecIndex == 0:
                    ShowSevereError(
                        state, f"{c_alpha_fields[4]} = {alph_array[4]} not found."
                    )
                    ShowContinueError(
                        state,
                        f"Occurs in {CURRENT_MODULE_OBJECT} = {air_dist_unit.Name}",
                    )
                    errors_found = True

            type_name_uc = Util_makeUPPER(
                air_dist_unit.EquipType[air_dist_comp_unit_num - 1]
            )
            air_dist_unit.EquipTypeEnum[air_dist_comp_unit_num - 1] = get_enum_value(
                ZN_AIR_LOOP_EQUIP_TYPE_NAMES_UC, type_name_uc
            )

            equip_type_enum = air_dist_unit.EquipTypeEnum[air_dist_comp_unit_num - 1]

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
                    ShowSevereError(
                        state,
                        f"Error found in {CURRENT_MODULE_OBJECT} = {air_dist_unit.Name}",
                    )
                    ShowContinueError(
                        state,
                        f"Simple duct leakage model not available for "
                        f"{c_alpha_fields[2]} = {air_dist_unit.EquipType[air_dist_comp_unit_num - 1]}",
                    )
                    errors_found = True
            elif equip_type_enum == "SingleDuctConstVolFourPipeBeam":
                air_dist_unit.airTerminalPtr = HVACFourPipeBeam_fourPipeBeamFactory(
                    state, air_dist_unit.EquipName[0]
                )
                if air_dist_unit.UpStreamLeak or air_dist_unit.DownStreamLeak:
                    ShowSevereError(
                        state,
                        f"Error found in {CURRENT_MODULE_OBJECT} = {air_dist_unit.Name}",
                    )
                    ShowContinueError(
                        state,
                        f"Simple duct leakage model not available for "
                        f"{c_alpha_fields[2]} = {air_dist_unit.EquipType[air_dist_comp_unit_num - 1]}",
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
                ShowSevereError(
                    state,
                    f"Error found in {CURRENT_MODULE_OBJECT} = {air_dist_unit.Name}",
                )
                ShowContinueError(
                    state,
                    f"Invalid {c_alpha_fields[2]} = {air_dist_unit.EquipType[air_dist_comp_unit_num - 1]}",
                )
                errors_found = True

            if equip_type_enum in ["DualDuctConstVolume", "DualDuctVAV"]:
                SetUpCompSets(
                    state,
                    CURRENT_MODULE_OBJECT,
                    air_dist_unit.Name,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1] + ":HEAT",
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    "UNDEFINED",
                    alph_array[1],
                )
                SetUpCompSets(
                    state,
                    CURRENT_MODULE_OBJECT,
                    air_dist_unit.Name,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1] + ":COOL",
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    "UNDEFINED",
                    alph_array[1],
                )
            elif equip_type_enum == "DualDuctVAVOutdoorAir":
                SetUpCompSets(
                    state,
                    CURRENT_MODULE_OBJECT,
                    air_dist_unit.Name,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1] + ":OutdoorAir",
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    "UNDEFINED",
                    alph_array[1],
                )
                dual_duct_recirc_is_used = False
                GetDualDuctOutdoorAirRecircUse(
                    state,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1],
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    dual_duct_recirc_is_used,
                )
                if dual_duct_recirc_is_used:
                    SetUpCompSets(
                        state,
                        CURRENT_MODULE_OBJECT,
                        air_dist_unit.Name,
                        air_dist_unit.EquipType[air_dist_comp_unit_num - 1]
                        + ":RecirculatedAir",
                        air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                        "UNDEFINED",
                        alph_array[1],
                    )
            else:
                SetUpCompSets(
                    state,
                    CURRENT_MODULE_OBJECT,
                    air_dist_unit.Name,
                    air_dist_unit.EquipType[air_dist_comp_unit_num - 1],
                    air_dist_unit.EquipName[air_dist_comp_unit_num - 1],
                    "UNDEFINED",
                    alph_array[1],
                )

        for air_dist_unit_num in range(1, len(state.dataDefineEquipment.AirDistUnit) + 1):
            air_dist_unit = state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1]
            SetupOutputVariable(
                state,
                "Zone Air Terminal Sensible Heating Energy",
                "J",
                air_dist_unit.HeatGain,
                "System",
                "Sum",
                air_dist_unit.Name,
            )
            SetupOutputVariable(
                state,
                "Zone Air Terminal Sensible Cooling Energy",
                "J",
                air_dist_unit.CoolGain,
                "System",
                "Sum",
                air_dist_unit.Name,
            )
            SetupOutputVariable(
                state,
                "Zone Air Terminal Sensible Heating Rate",
                "W",
                air_dist_unit.HeatRate,
                "System",
                "Average",
                air_dist_unit.Name,
            )
            SetupOutputVariable(
                state,
                "Zone Air Terminal Sensible Cooling Rate",
                "W",
                air_dist_unit.CoolRate,
                "System",
                "Average",
                air_dist_unit.Name,
            )

    if errors_found:
        ShowFatalError(
            state,
            f"{ROUTINE_NAME}Errors found in getting {CURRENT_MODULE_OBJECT} Input",
        )


def init_zone_air_loop_equipment(
    state, air_dist_unit_num: int, controlled_zone_num: int
):
    if not state.dataZoneAirLoopEquipmentManager.InitAirDistUnitsFlag:
        return

    air_dist_unit = state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1]

    if air_dist_unit.EachOnceFlag and (air_dist_unit.TermUnitSizingNum > 0):
        air_dist_unit.ZoneNum = controlled_zone_num
        zone_eq_config = state.dataZoneEquip.ZoneEquipConfig[controlled_zone_num - 1]

        for inlet_num in range(1, zone_eq_config.NumInletNodes + 1):
            if zone_eq_config.InletNode[inlet_num - 1] == air_dist_unit.OutletNodeNum:
                zone_eq_config.InletNodeADUNum[inlet_num - 1] = air_dist_unit_num

        term_unit_sizing_data = state.dataSize.TermUnitSizing[
            air_dist_unit.TermUnitSizingNum - 1
        ]
        term_unit_sizing_data.ADUName = air_dist_unit.Name

        if air_dist_unit.AirTerminalSizingSpecIndex > 0:
            air_term_sizing_spec = state.dataSize.AirTerminalSizingSpec[
                air_dist_unit.AirTerminalSizingSpecIndex - 1
            ]
            term_unit_sizing_data.SpecDesCoolSATRatio = (
                air_term_sizing_spec.DesCoolSATRatio
            )
            term_unit_sizing_data.SpecDesHeatSATRatio = (
                air_term_sizing_spec.DesHeatSATRatio
            )
            term_unit_sizing_data.SpecDesSensCoolingFrac = (
                air_term_sizing_spec.DesSensCoolingFrac
            )
            term_unit_sizing_data.SpecDesSensHeatingFrac = (
                air_term_sizing_spec.DesSensHeatingFrac
            )
            term_unit_sizing_data.SpecMinOAFrac = air_term_sizing_spec.MinOAFrac

        if (
            air_dist_unit.ZoneNum != 0
            and state.dataHeatBal.Zone[air_dist_unit.ZoneNum - 1].HasAdjustedReturnTempByITE
        ):
            for air_dist_comp_num in range(
                1, air_dist_unit.NumComponents + 1
            ):
                if air_dist_unit.EquipTypeEnum[air_dist_comp_num - 1] not in [
                    "SingleDuctVAVReheat",
                    "SingleDuctVAVNoReheat",
                ]:
                    ShowSevereError(
                        state,
                        "The FlowControlWithApproachTemperatures only works with ITE zones with single duct VAV terminal unit.",
                    )
                    ShowContinueError(
                        state, "The return air temperature of the ITE will not be overwritten."
                    )
                    ShowFatalError(state, "Preceding condition causes termination.")

        air_dist_unit.EachOnceFlag = False
        state.dataZoneAirLoopEquipmentManager.numADUInitialized += 1
        if (
            state.dataZoneAirLoopEquipmentManager.numADUInitialized
            == len(state.dataDefineEquipment.AirDistUnit)
        ):
            state.dataZoneAirLoopEquipmentManager.InitAirDistUnitsFlag = False


def init_zone_air_loop_equipment_time_step(state, air_dist_unit_num: int):
    air_dist_unit = state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1]
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


def sim_zone_air_loop_equipment(
    state,
    air_dist_unit_num: int,
    sys_output_provided: List[float],
    non_air_sys_output: List[float],
    lat_output_provided: List[float],
    first_hvac_iteration: bool,
    controlled_zone_num: int,
):
    controlled_zone_air_node = state.dataZoneEquip.ZoneEquipConfig[
        controlled_zone_num - 1
    ].ZoneNode

    provide_sys_output = True
    air_dist_unit = state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1]

    for air_dist_comp_num in range(1, air_dist_unit.NumComponents + 1):
        non_air_sys_output[0] = 0.0

        in_node_num = air_dist_unit.InletNodeNum
        out_node_num = air_dist_unit.OutletNodeNum
        mass_flow_rate_max_avail = 0.0
        mass_flow_rate_min_avail = 0.0
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
                    air_loop_num = air_dist_unit.AirLoopNum
                    if air_loop_num > 0:
                        des_flow_ratio = state.dataAirLoop.AirLoopFlow[
                            air_loop_num - 1
                        ].SysToZoneDesFlowRatio
                    else:
                        des_flow_ratio = 1.0
                    mass_flow_rate_up_stream_leak_max = max(
                        air_dist_unit.UpStreamLeakFrac
                        * state.dataLoopNodes.Node[in_node_num - 1].MassFlowRateMax
                        * des_flow_ratio,
                        0.0,
                    )
                else:
                    mass_flow_rate_up_stream_leak_max = max(
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

        equip_type_enum = air_dist_unit.EquipTypeEnum[air_dist_comp_num - 1]

        if equip_type_enum == "DualDuctConstVolume":
            SimulateDualDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "DualDuctVAV":
            SimulateDualDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "DualDuctVAVOutdoorAir":
            SimulateDualDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctVAVReheat":
            SimulateSingleDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctCBVAVReheat":
            SimulateSingleDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctVAVNoReheat":
            SimulateSingleDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctCBVAVNoReheat":
            SimulateSingleDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctConstVolReheat":
            SimulateSingleDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctConstVolNoReheat":
            SimulateSingleDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuct_SeriesPIU_Reheat":
            SimPIU(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuct_ParallelPIU_Reheat":
            SimPIU(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
            piu_num = Util_FindItemInList(
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                state.dataPowerInductionUnits.PIU,
            )
            if piu_num > 0:
                air_dist_unit.parallelPIUTerminalLeakFrac = state.dataPowerInductionUnits.PIU[
                    piu_num - 1
                ].leakFrac
                if (
                    state.dataPowerInductionUnits.PIU[piu_num - 1].damperLeakageZoneNum
                    > 0
                    and air_dist_unit.piuLkZoneNum <= 0
                ):
                    air_dist_unit.piuLkZoneNum = state.dataPowerInductionUnits.PIU[
                        piu_num - 1
                    ].damperLeakageZoneNum

        elif equip_type_enum == "SingleDuct_ConstVol_4PipeInduc":
            SimIndUnit(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctVAVReheatVSFan":
            SimulateSingleDuct(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctConstVolCooledBeam":
            SimCoolBeam(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
                non_air_sys_output,
            )
        elif equip_type_enum == "SingleDuctConstVolFourPipeBeam":
            air_dist_unit.airTerminalPtr.simulate(state, first_hvac_iteration, non_air_sys_output)
        elif equip_type_enum == "SingleDuctUserDefined":
            SimAirTerminalUserDefined(
                state,
                air_dist_unit.EquipName[air_dist_comp_num - 1],
                first_hvac_iteration,
                controlled_zone_num,
                controlled_zone_air_node,
                air_dist_unit.EquipIndex[air_dist_comp_num - 1],
            )
        elif equip_type_enum == "SingleDuctATMixer":
            GetATMixers(state)
            provide_sys_output = False
        else:
            ShowSevereError(
                state,
                f"Error found in ZoneHVAC:AirDistributionUnit={air_dist_unit.Name}",
            )
            ShowContinueError(
                state,
                f"Invalid Component={air_dist_unit.EquipType[air_dist_comp_num - 1]}",
            )
            ShowFatalError(state, "Preceding condition causes termination.")

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
                state.dataLoopNodes.Node[
                    in_node_num - 1
                ].MassFlowRate = air_dist_unit.MassFlowRateSup
                state.dataLoopNodes.Node[
                    out_node_num - 1
                ].MassFlowRate = air_dist_unit.MassFlowRateZSup
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
                term_unit_type = air_dist_unit.EquipTypeEnum[air_dist_comp_num - 1]
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
        outlet_node_num = air_dist_unit.OutletNodeNum
        spec_hum_out = state.dataLoopNodes.Node[outlet_node_num - 1].HumRat
        spec_hum_in = state.dataLoopNodes.Node[controlled_zone_air_node - 1].HumRat

        sys_output_provided[0] = (
            state.dataLoopNodes.Node[outlet_node_num - 1].MassFlowRate
            * PsyDeltaHSenFnTdb2W2Tdb1W1(
                state.dataLoopNodes.Node[outlet_node_num - 1].Temp,
                spec_hum_out,
                state.dataLoopNodes.Node[controlled_zone_air_node - 1].Temp,
                spec_hum_in,
            )
        )

        lat_output_provided[0] = (
            state.dataLoopNodes.Node[outlet_node_num - 1].MassFlowRate
            * (spec_hum_out - spec_hum_in)
        )
    else:
        sys_output_provided[0] = 0.0
        lat_output_provided[0] = 0.0


def Util_FindItemInList(item: str, items_list):
    for i, item_name in enumerate(items_list):
        if item_name.Name == item:
            return i + 1
    return 0


def Util_makeUPPER(s: str):
    return s.upper()


def get_enum_value(enum_list, value: str):
    try:
        return enum_list.index(value) + 1
    except ValueError:
        return 0


def GetOnlySingleNode(state, node_name, errors_found, *args):
    return 0


def ValidateComponent(state, *args):
    pass


def ShowFatalError(state, msg: str):
    raise RuntimeError(msg)


def ShowSevereError(state, msg: str):
    print(f"SEVERE ERROR: {msg}")


def ShowContinueError(state, msg: str):
    print(f"CONTINUE ERROR: {msg}")


def SetUpCompSets(state, *args):
    pass


def GetDualDuctOutdoorAirRecircUse(state, *args):
    pass


def SetupOutputVariable(state, *args):
    pass


def SimulateDualDuct(state, *args):
    pass


def SimulateSingleDuct(state, *args):
    pass


def SimPIU(state, *args):
    pass


def SimIndUnit(state, *args):
    pass


def SimCoolBeam(state, *args):
    pass


def SimAirTerminalUserDefined(state, *args):
    pass


def GetATMixers(state):
    pass


def HVACFourPipeBeam_fourPipeBeamFactory(state, name):
    return None


def PsyDeltaHSenFnTdb2W2Tdb1W1(t2, w2, t1, w1):
    return 0.0
