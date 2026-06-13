# Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# and other contributors. All rights reserved.
#
# EnergyPlus translation from C++ to Python

from typing import Optional, List, Protocol, Any
from dataclasses import dataclass, field
from enum import IntEnum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: Main state object passed to functions
# - DataHeatBalance.IntGainType: Enum for internal gain component types
# - DataHeatBalance.IntGainTypeNamesCC: List mapping IntGainType to display names
# - Util.makeUPPER: Function to convert string to uppercase
# - ShowSevereError: Function to report severe errors
# - ShowContinueError: Function to report error continuation messages


class IntGainDevice:
    def __init__(self):
        self.CompObjectName: str = ""
        self.CompType: Any = None
        self.spaceGainFrac: float = 0.0
        self.PtrConvectGainRate: Optional[float] = None
        self.PtrReturnAirConvGainRate: Optional[float] = None
        self.PtrRadiantGainRate: Optional[float] = None
        self.PtrLatentGainRate: Optional[float] = None
        self.PtrReturnAirLatentGainRate: Optional[float] = None
        self.PtrCarbonDioxideGainRate: Optional[float] = None
        self.PtrGenericContamGainRate: Optional[float] = None
        self.ReturnAirNodeNum: int = 0


class SpaceIntGainDevices:
    def __init__(self):
        self.device: List[IntGainDevice] = []
        self.numberOfDevices: int = 0
        self.maxNumberOfDevices: int = 0

    def allocate(self, size: int) -> None:
        self.device = [IntGainDevice() for _ in range(size)]
        self.maxNumberOfDevices = size

    def redimension(self, new_size: int) -> None:
        old_device = self.device
        self.device = [IntGainDevice() for _ in range(new_size)]
        for i in range(len(old_device)):
            self.device[i] = old_device[i]


class DataHeatBalProtocol(Protocol):
    Zone: List[Any]
    space: List[Any]
    spaceIntGainDevices: List[SpaceIntGainDevices]
    zeroPointerVal: float


class EnergyPlusDataProtocol(Protocol):
    dataHeatBal: DataHeatBalProtocol


ADJUST_TANK_LOSS_MULTIPLIERS: List[Any] = []


def setup_zone_internal_gain(
    state: EnergyPlusDataProtocol,
    zone_num: int,
    c_component_name: str,
    int_gain_comp_type: Any,
    convection_gain_rate: Optional[float] = None,
    return_air_convection_gain_rate: Optional[float] = None,
    thermal_radiation_gain_rate: Optional[float] = None,
    latent_gain_rate: Optional[float] = None,
    return_air_latent_gain_rate: Optional[float] = None,
    carbon_dioxide_gain_rate: Optional[float] = None,
    generic_contam_gain_rate: Optional[float] = None,
    ret_node_num: int = 0,
) -> None:
    gain_frac = 1.0
    for space_num in state.dataHeatBal.Zone[zone_num - 1].spaceIndexes:
        if state.dataHeatBal.Zone[zone_num - 1].numSpaces > 1:
            gain_frac = state.dataHeatBal.space[space_num - 1].FloorArea / state.dataHeatBal.Zone[zone_num - 1].FloorArea
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


def setup_space_internal_gain(
    state: EnergyPlusDataProtocol,
    space_num: int,
    space_gain_fraction: float,
    c_component_name: str,
    int_gain_comp_type: Any,
    convection_gain_rate: Optional[float] = None,
    return_air_convection_gain_rate: Optional[float] = None,
    thermal_radiation_gain_rate: Optional[float] = None,
    latent_gain_rate: Optional[float] = None,
    return_air_latent_gain_rate: Optional[float] = None,
    carbon_dioxide_gain_rate: Optional[float] = None,
    generic_contam_gain_rate: Optional[float] = None,
    ret_node_num: int = 0,
) -> None:
    DEVICE_ALLOC_INC = 100

    found_duplicate = False
    upper_case_object_name = c_component_name.upper()

    this_int_gain = state.dataHeatBal.spaceIntGainDevices[space_num - 1]
    for int_gains_num in range(this_int_gain.numberOfDevices):
        if (this_int_gain.device[int_gains_num].CompType == int_gain_comp_type and
            this_int_gain.device[int_gains_num].CompObjectName == upper_case_object_name):
            found_duplicate = True
            break

    if found_duplicate:
        # Error handling would be via ShowSevereError and ShowContinueError
        # which are external dependencies
        return

    if this_int_gain.numberOfDevices == 0:
        this_int_gain.allocate(DEVICE_ALLOC_INC)
    else:
        if this_int_gain.numberOfDevices + 1 > this_int_gain.maxNumberOfDevices:
            this_int_gain.maxNumberOfDevices += DEVICE_ALLOC_INC
            this_int_gain.redimension(this_int_gain.maxNumberOfDevices)

    this_int_gain.numberOfDevices += 1

    this_int_gain.device[this_int_gain.numberOfDevices - 1].CompObjectName = upper_case_object_name
    this_int_gain.device[this_int_gain.numberOfDevices - 1].CompType = int_gain_comp_type

    if int_gain_comp_type in ADJUST_TANK_LOSS_MULTIPLIERS:
        zone_num = state.dataHeatBal.space[space_num - 1].zoneNum
        multiplier = state.dataHeatBal.Zone[zone_num - 1].Multiplier * state.dataHeatBal.Zone[zone_num - 1].ListMultiplier
        if multiplier > 1:
            space_gain_fraction /= multiplier

    this_int_gain.device[this_int_gain.numberOfDevices - 1].spaceGainFrac = space_gain_fraction

    if convection_gain_rate is not None:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrConvectGainRate = convection_gain_rate
    else:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrConvectGainRate = state.dataHeatBal.zeroPointerVal

    if return_air_convection_gain_rate is not None:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrReturnAirConvGainRate = return_air_convection_gain_rate
    else:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrReturnAirConvGainRate = state.dataHeatBal.zeroPointerVal

    if thermal_radiation_gain_rate is not None:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrRadiantGainRate = thermal_radiation_gain_rate
    else:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrRadiantGainRate = state.dataHeatBal.zeroPointerVal

    if latent_gain_rate is not None:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrLatentGainRate = latent_gain_rate
    else:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrLatentGainRate = state.dataHeatBal.zeroPointerVal

    if return_air_latent_gain_rate is not None:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrReturnAirLatentGainRate = return_air_latent_gain_rate
    else:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrReturnAirLatentGainRate = state.dataHeatBal.zeroPointerVal

    if carbon_dioxide_gain_rate is not None:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrCarbonDioxideGainRate = carbon_dioxide_gain_rate
    else:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrCarbonDioxideGainRate = state.dataHeatBal.zeroPointerVal

    if generic_contam_gain_rate is not None:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrGenericContamGainRate = generic_contam_gain_rate
    else:
        this_int_gain.device[this_int_gain.numberOfDevices - 1].PtrGenericContamGainRate = state.dataHeatBal.zeroPointerVal

    this_int_gain.device[this_int_gain.numberOfDevices - 1].ReturnAirNodeNum = ret_node_num


class HeatBalInternalHeatGainsData:
    def init_constant_state(self, state: EnergyPlusDataProtocol) -> None:
        pass

    def init_state(self, state: EnergyPlusDataProtocol) -> None:
        pass

    def clear_state(self) -> None:
        pass
