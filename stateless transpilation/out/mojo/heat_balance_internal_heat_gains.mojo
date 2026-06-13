# Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# and other contributors. All rights reserved.
#
# EnergyPlus translation from C++ to Mojo

from collections import InlineArray

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: Main state object passed to functions
# - DataHeatBalance.IntGainType: Type for internal gain component types
# - DataHeatBalance.IntGainTypeNamesCC: Array mapping IntGainType to display names
# - Util.makeUPPER: Function to convert string to uppercase
# - ShowSevereError: Function to report severe errors
# - ShowContinueError: Function to report error continuation messages


struct IntGainDevice:
    var comp_object_name: String
    var comp_type: UInt32
    var space_gain_frac: Float64
    var ptr_convect_gain_rate: Pointer[Float64]
    var ptr_return_air_conv_gain_rate: Pointer[Float64]
    var ptr_radiant_gain_rate: Pointer[Float64]
    var ptr_latent_gain_rate: Pointer[Float64]
    var ptr_return_air_latent_gain_rate: Pointer[Float64]
    var ptr_carbon_dioxide_gain_rate: Pointer[Float64]
    var ptr_generic_contam_gain_rate: Pointer[Float64]
    var return_air_node_num: Int32

    fn __init__(inout self) -> None:
        self.comp_object_name = String()
        self.comp_type = 0
        self.space_gain_frac = 0.0
        self.ptr_convect_gain_rate = Pointer[Float64]()
        self.ptr_return_air_conv_gain_rate = Pointer[Float64]()
        self.ptr_radiant_gain_rate = Pointer[Float64]()
        self.ptr_latent_gain_rate = Pointer[Float64]()
        self.ptr_return_air_latent_gain_rate = Pointer[Float64]()
        self.ptr_carbon_dioxide_gain_rate = Pointer[Float64]()
        self.ptr_generic_contam_gain_rate = Pointer[Float64]()
        self.return_air_node_num = 0


struct SpaceIntGainDevices:
    var device: DynamicVector[IntGainDevice]
    var number_of_devices: Int32
    var max_number_of_devices: Int32

    fn __init__(inout self) -> None:
        self.device = DynamicVector[IntGainDevice]()
        self.number_of_devices = 0
        self.max_number_of_devices = 0

    fn allocate(inout self, size: Int) -> None:
        self.device.clear()
        for _ in range(size):
            self.device.push_back(IntGainDevice())
        self.max_number_of_devices = Int32(size)

    fn redimension(inout self, new_size: Int) -> None:
        let old_size = self.device.size
        let old_device = self.device
        self.device.clear()
        for i in range(new_size):
            if i < old_size:
                self.device.push_back(old_device[i])
            else:
                self.device.push_back(IntGainDevice())
        self.max_number_of_devices = Int32(new_size)


struct ZoneData:
    var space_indexes: DynamicVector[Int32]
    var num_spaces: Int32
    var floor_area: Float64
    var multiplier: Int32
    var list_multiplier: Int32


struct SpaceData:
    var floor_area: Float64
    var zone_num: Int32


struct DataHeatBalData:
    var zone: DynamicVector[ZoneData]
    var space: DynamicVector[SpaceData]
    var space_int_gain_devices: DynamicVector[SpaceIntGainDevices]
    var zero_pointer_val: Float64


struct EnergyPlusData:
    var data_heat_bal: DataHeatBalData


var ADJUST_TANK_LOSS_MULTIPLIERS: InlineArray[UInt32, 4] = InlineArray[UInt32, 4](fill=0)


@export
fn setup_zone_internal_gain(
    inout state: EnergyPlusData,
    zone_num: Int32,
    c_component_name: StringRef,
    int_gain_comp_type: UInt32,
    convection_gain_rate: Pointer[Float64] = Pointer[Float64](),
    return_air_convection_gain_rate: Pointer[Float64] = Pointer[Float64](),
    thermal_radiation_gain_rate: Pointer[Float64] = Pointer[Float64](),
    latent_gain_rate: Pointer[Float64] = Pointer[Float64](),
    return_air_latent_gain_rate: Pointer[Float64] = Pointer[Float64](),
    carbon_dioxide_gain_rate: Pointer[Float64] = Pointer[Float64](),
    generic_contam_gain_rate: Pointer[Float64] = Pointer[Float64](),
    ret_node_num: Int32 = 0,
) -> None:
    var gain_frac: Float64 = 1.0
    let zone_idx = Int(zone_num - 1)
    for space_num in state.data_heat_bal.zone[zone_idx].space_indexes:
        if state.data_heat_bal.zone[zone_idx].num_spaces > 1:
            gain_frac = state.data_heat_bal.space[Int(space_num - 1)].floor_area / state.data_heat_bal.zone[zone_idx].floor_area
        setup_space_internal_gain(
            state,
            space_num,
            gain_frac,
            c_component_name,
            int_gain_comp_type,
            convection_gain_rate,
            return_air_convection_gain_rate,
            thermal_radiation_gain_rate,
            latent_gain_rate,
            return_air_latent_gain_rate,
            carbon_dioxide_gain_rate,
            generic_contam_gain_rate,
            ret_node_num,
        )


@export
fn setup_space_internal_gain(
    inout state: EnergyPlusData,
    space_num: Int32,
    space_gain_fraction: Float64,
    c_component_name: StringRef,
    int_gain_comp_type: UInt32,
    convection_gain_rate: Pointer[Float64] = Pointer[Float64](),
    return_air_convection_gain_rate: Pointer[Float64] = Pointer[Float64](),
    thermal_radiation_gain_rate: Pointer[Float64] = Pointer[Float64](),
    latent_gain_rate: Pointer[Float64] = Pointer[Float64](),
    return_air_latent_gain_rate: Pointer[Float64] = Pointer[Float64](),
    carbon_dioxide_gain_rate: Pointer[Float64] = Pointer[Float64](),
    generic_contam_gain_rate: Pointer[Float64] = Pointer[Float64](),
    ret_node_num: Int32 = 0,
) -> None:
    let DEVICE_ALLOC_INC = 100

    var found_duplicate: Bool = False
    var upper_case_object_name = String(c_component_name)
    upper_case_object_name = upper_case_object_name.upper()

    let space_idx = Int(space_num - 1)
    var this_int_gain = state.data_heat_bal.space_int_gain_devices[space_idx]

    for int_gains_num in range(Int(this_int_gain.number_of_devices)):
        if (this_int_gain.device[int_gains_num].comp_type == int_gain_comp_type and
            this_int_gain.device[int_gains_num].comp_object_name == upper_case_object_name):
            found_duplicate = True
            break

    if found_duplicate:
        return

    if this_int_gain.number_of_devices == 0:
        this_int_gain.allocate(DEVICE_ALLOC_INC)
    else:
        if this_int_gain.number_of_devices + 1 > this_int_gain.max_number_of_devices:
            this_int_gain.max_number_of_devices += Int32(DEVICE_ALLOC_INC)
            this_int_gain.redimension(Int(this_int_gain.max_number_of_devices))

    this_int_gain.number_of_devices += 1

    let device_idx = Int(this_int_gain.number_of_devices - 1)
    this_int_gain.device[device_idx].comp_object_name = upper_case_object_name
    this_int_gain.device[device_idx].comp_type = int_gain_comp_type

    var adjusted_gain_fraction = space_gain_fraction
    var found_tank_loss = False
    for i in range(4):
        if ADJUST_TANK_LOSS_MULTIPLIERS[i] == int_gain_comp_type:
            found_tank_loss = True
            break

    if found_tank_loss:
        let zone_num = state.data_heat_bal.space[space_idx].zone_num
        let zone_idx = Int(zone_num - 1)
        let multiplier = state.data_heat_bal.zone[zone_idx].multiplier * state.data_heat_bal.zone[zone_idx].list_multiplier
        if multiplier > 1:
            adjusted_gain_fraction /= Float64(multiplier)

    this_int_gain.device[device_idx].space_gain_frac = adjusted_gain_fraction

    if convection_gain_rate.address != 0:
        this_int_gain.device[device_idx].ptr_convect_gain_rate = convection_gain_rate
    else:
        this_int_gain.device[device_idx].ptr_convect_gain_rate = Pointer[Float64].address_of(state.data_heat_bal.zero_pointer_val)

    if return_air_convection_gain_rate.address != 0:
        this_int_gain.device[device_idx].ptr_return_air_conv_gain_rate = return_air_convection_gain_rate
    else:
        this_int_gain.device[device_idx].ptr_return_air_conv_gain_rate = Pointer[Float64].address_of(state.data_heat_bal.zero_pointer_val)

    if thermal_radiation_gain_rate.address != 0:
        this_int_gain.device[device_idx].ptr_radiant_gain_rate = thermal_radiation_gain_rate
    else:
        this_int_gain.device[device_idx].ptr_radiant_gain_rate = Pointer[Float64].address_of(state.data_heat_bal.zero_pointer_val)

    if latent_gain_rate.address != 0:
        this_int_gain.device[device_idx].ptr_latent_gain_rate = latent_gain_rate
    else:
        this_int_gain.device[device_idx].ptr_latent_gain_rate = Pointer[Float64].address_of(state.data_heat_bal.zero_pointer_val)

    if return_air_latent_gain_rate.address != 0:
        this_int_gain.device[device_idx].ptr_return_air_latent_gain_rate = return_air_latent_gain_rate
    else:
        this_int_gain.device[device_idx].ptr_return_air_latent_gain_rate = Pointer[Float64].address_of(state.data_heat_bal.zero_pointer_val)

    if carbon_dioxide_gain_rate.address != 0:
        this_int_gain.device[device_idx].ptr_carbon_dioxide_gain_rate = carbon_dioxide_gain_rate
    else:
        this_int_gain.device[device_idx].ptr_carbon_dioxide_gain_rate = Pointer[Float64].address_of(state.data_heat_bal.zero_pointer_val)

    if generic_contam_gain_rate.address != 0:
        this_int_gain.device[device_idx].ptr_generic_contam_gain_rate = generic_contam_gain_rate
    else:
        this_int_gain.device[device_idx].ptr_generic_contam_gain_rate = Pointer[Float64].address_of(state.data_heat_bal.zero_pointer_val)

    this_int_gain.device[device_idx].return_air_node_num = ret_node_num

    state.data_heat_bal.space_int_gain_devices[space_idx] = this_int_gain


struct HeatBalInternalHeatGainsData:
    fn init_constant_state(inout self, inout state: EnergyPlusData) -> None:
        pass

    fn init_state(inout self, inout state: EnergyPlusData) -> None:
        pass

    fn clear_state(inout self) -> None:
        pass
