"""
RoomAirModelManager.py
Conversion of EnergyPlus RoomAirModelManager.cc

EXTERNAL DEPS (to wire in glue):
  - EnergyPlusData: Root simulation state object
    - state.dataRoomAir, state.dataInputProcessing, state.dataGlobal
    - state.dataHeatBal, state.dataSurface, state.dataZoneEquip
    - state.dataZoneTempPredictorCorrector, state.afn, state.dataEnvrn
    - state.dataHVACVarRefFlow, state.dataHVACStandAloneERV, state.dataFanCoilUnits
    - state.dataOutdoorAirUnit, state.dataUnitarySystems, state.dataUnitHeaters
    - state.dataUnitVentilators, state.dataVentilatedSlab, state.dataWindowAC
    - state.dataZoneDehumidifier, state.dataPurchasedAirMgr, state.dataHybridUnitaryAC
    - state.dataWaterThermalTanks, state.dataLoopNodes, state.dataHeatBalFanSys
    - state.dataErrTracking, state.dataIPShortCut
  - DataZoneEquipment.ZoneEquipType: Enum for zone equipment types
  - DataHeatBalance.IntGainType: Enum for internal gain types
  - Various manager modules: HVACVariableRefrigerantFlow, HVACStandAloneERV, FanCoilUnits,
    OutdoorAirUnit, UnitarySystems, UnitHeater, UnitVentilator, VentilatedSlab,
    WindowAC, ZoneDehumidifier, PurchasedAirManager, HybridUnitaryAirConditioners,
    WaterThermalTanks
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Protocol, Optional, List, Dict, Any
import math


class RoomAirModel(IntEnum):
    UserDefined = 1
    Mixing = 2
    DispVent1Node = 3
    DispVent3Node = 4
    CrossVent = 5
    UFADInt = 6
    UFADExt = 7
    AirflowNetwork = 8
    Num = 8


class AirNodeType(IntEnum):
    Inlet = 1
    Floor = 2
    Control = 3
    Ceiling = 4
    Mundt = 5
    Return = 6
    AirflowNetwork = 7
    Plume = 8
    Rees = 9
    Num = 9
    Invalid = -1


class Comfort(IntEnum):
    Jet = 1
    Recirculation = 2
    Num = 2
    Invalid = -1


class Diffuser(IntEnum):
    Swirl = 1
    VariableArea = 2
    HorizontalSwirl = 3
    LinearBarGrille = 4
    Custom = 5
    Num = 5
    Invalid = -1


class UserDefinedPatternMode(IntEnum):
    OutdoorDryBulb = 1
    SensibleCooling = 2
    SensibleHeating = 3
    ZoneAirTemp = 4
    DeltaOutdoorZone = 5
    Num = 5
    Invalid = -1


class UserDefinedPatternType(IntEnum):
    ConstGradTemp = 1
    TwoGradInterp = 2
    NonDimenHeight = 3
    SurfMapTemp = 4


ROOM_AIR_MODEL_NAMES_UC = [
    "USERDEFINED", "MIXING", "MUNDT", "UCSD_DV", "UCSD_CV", "UCSD_UFI", "UCSD_UFE", "AIRFLOWNETWORK"
]

AIR_NODE_TYPE_NAMES_UC = [
    "INLET", "FLOOR", "CONTROL", "CEILING", "MUNDTROOM", "RETURN", "AIRFLOWNETWORK", "PLUME", "REESROOM"
]

COMFORT_NAMES_UC = ["JET", "RECIRCULATION"]

DIFFUSER_NAMES_UC = [
    "SWIRL", "VARIABLEAREA", "HORIZONTALSWIRL", "LINEARBARGRILLE", "CUSTOM"
]

USER_DEFINED_PATTERN_MODE_NAMES_UC = [
    "OUTDOORDRYBULBTEMPERATURE", "SENSIBLECOOLINGLOAD", "SENSIBLEHEATINGLOAD",
    "ZONEDRYBULBTEMPERATURE", "ZONEANDOUTDOORTEMPERATUREDIFFERENCE"
]

TEMP_PATTERN_CONST_GRADIENT_OBJECT = "RoomAirTemperaturePattern:ConstantGradient"
TEMP_PATTERN_TWO_GRADIENT_OBJECT = "RoomAirTemperaturePattern:TwoGradientInterpolated"
TEMP_PATTERN_ND_HEIGHT_OBJECT = "RoomAirTemperaturePattern:NondimensionalHeight"
TEMP_PATTERN_SURF_MAP_OBJECT = "RoomAirTemperaturePattern:SurfaceMapping"
USER_DEFINED_CONTROL_OBJECT = "RoomAir:TemperaturePattern:UserDefined"


def manage_air_model(state: Any, zone_num: int) -> None:
    """
    Manage room air models for a zone.
    """
    if state.dataRoomAir.GetAirModelData:
        get_air_model_datas(state)
        state.dataRoomAir.GetAirModelData = False

    if not state.dataRoomAir.anyNonMixingRoomAirModel:
        return

    if state.dataRoomAir.UCSDModelUsed:
        shared_dvcvuf_data_init(state, zone_num)

    air_model_type = state.dataRoomAir.AirModel[zone_num - 1].AirModel

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


def get_air_model_datas(state: Any) -> None:
    """
    Get all room air model data by calling individual retrieval routines.
    """
    errors_found = False

    get_air_node_data(state, errors_found)
    get_mundt_data(state, errors_found)
    get_room_airflow_network_data(state, errors_found)
    get_displacement_vent_data(state, errors_found)
    get_cross_vent_data(state, errors_found)
    get_user_defined_pattern_data(state, errors_found)
    get_ufad_zone_data(state, errors_found)

    if errors_found:
        state.ShowFatalError(state, "GetAirModelData: Errors found getting air model input.  Program terminates.")


def get_user_defined_pattern_data(state: Any, errors_found: bool) -> None:
    """
    Get user-defined temperature pattern data for RoomAir model.
    """
    ipsc = state.dataIPShortCut

    num_temp_dist_ctrld_zones = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, USER_DEFINED_CONTROL_OBJECT
    )

    num_constant_gradient = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, TEMP_PATTERN_CONST_GRADIENT_OBJECT
    )
    num_two_gradient_interp = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, TEMP_PATTERN_TWO_GRADIENT_OBJECT
    )
    num_non_dimensional_height = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, TEMP_PATTERN_ND_HEIGHT_OBJECT
    )
    num_surface_mapping = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, TEMP_PATTERN_SURF_MAP_OBJECT
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

    ipsc.cCurrentModuleObject = USER_DEFINED_CONTROL_OBJECT

    if num_temp_dist_ctrld_zones == 0:
        if state.dataRoomAir.NumAirTempPatterns != 0:
            state.ShowWarningError(
                state,
                f"Missing {ipsc.cCurrentModuleObject} object needed to use roomair temperature patterns"
            )
        return

    if not hasattr(state.dataRoomAir, 'AirPatternZoneInfo') or state.dataRoomAir.AirPatternZoneInfo is None:
        state.dataRoomAir.AirPatternZoneInfo = [None] * state.dataGlobal.NumOfZones

    for obj_num in range(1, num_temp_dist_ctrld_zones + 1):
        num_alphas = 0
        num_numbers = 0
        status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, obj_num,
            ipsc.cAlphaArgs, num_alphas,
            ipsc.rNumericArgs, num_numbers,
            status
        )

        zone_num = state.util.FindItemInList(ipsc.cAlphaArgs[1], state.dataHeatBal.Zone)
        if zone_num == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            errors_found = True
            return

        air_pattern_zone_info = state.dataRoomAir.AirPatternZoneInfo[zone_num - 1]
        air_pattern_zone_info['IsUsed'] = True
        air_pattern_zone_info['Name'] = ipsc.cAlphaArgs[0]
        air_pattern_zone_info['ZoneName'] = ipsc.cAlphaArgs[1]

        if ipsc.lAlphaFieldBlanks[2]:
            air_pattern_zone_info['availSched'] = state.Sched.GetScheduleAlwaysOn(state)
        else:
            sched = state.Sched.GetSchedule(state, ipsc.cAlphaArgs[2])
            if sched is None:
                state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
                errors_found = True
            air_pattern_zone_info['availSched'] = sched

        if not ipsc.lAlphaFieldBlanks[3]:
            pattern_sched = state.Sched.GetSchedule(state, ipsc.cAlphaArgs[3])
            if pattern_sched is None:
                state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[3], ipsc.cAlphaArgs[3])
                errors_found = True
            air_pattern_zone_info['patternSched'] = pattern_sched

        air_pattern_zone_info['ZoneID'] = zone_num

        tot_num_surfs = 0
        for space_num in state.dataHeatBal.Zone[zone_num - 1]['spaceIndexes']:
            this_space = state.dataHeatBal.space[space_num - 1]
            tot_num_surfs += this_space['HTSurfaceLast'] - this_space['HTSurfaceFirst'] + 1

        air_pattern_zone_info['totNumSurfs'] = tot_num_surfs
        air_pattern_zone_info['Surf'] = [None] * tot_num_surfs

        this_surf_in_zone = 0
        for space_num in state.dataHeatBal.Zone[zone_num - 1]['spaceIndexes']:
            this_space = state.dataHeatBal.space[space_num - 1]
            for this_hb_surf_id in range(this_space['HTSurfaceFirst'], this_space['HTSurfaceLast'] + 1):
                this_surf_in_zone += 1
                if state.dataSurface.Surface[this_hb_surf_id - 1]['Class'] == 'IntMass':
                    air_pattern_zone_info['Surf'][this_surf_in_zone - 1] = {
                        'SurfID': this_hb_surf_id,
                        'Zeta': 0.5
                    }
                    continue

                air_pattern_zone_info['Surf'][this_surf_in_zone - 1] = {
                    'SurfID': this_hb_surf_id,
                    'Zeta': state.FigureNDheightInZone(state, this_hb_surf_id)
                }

    for i_zone in range(state.dataGlobal.NumOfZones):
        if state.dataRoomAir.AirModel[i_zone]['AirModel'] != RoomAirModel.UserDefined:
            continue
        if state.dataRoomAir.AirPatternZoneInfo[i_zone] and state.dataRoomAir.AirPatternZoneInfo[i_zone].get('IsUsed'):
            continue
        state.ShowSevereError(
            state,
            f"AirModel for Zone=[{state.dataHeatBal.Zone[i_zone]['Name']}] is indicated as \"User Defined\"."
        )
        state.ShowContinueError(state, f"...but missing a {ipsc.cCurrentModuleObject} object for control.")
        errors_found = True

    if not hasattr(state.dataRoomAir, 'AirPattern') or state.dataRoomAir.AirPattern is None:
        state.dataRoomAir.AirPattern = [None] * state.dataRoomAir.NumAirTempPatterns

    ipsc.cCurrentModuleObject = TEMP_PATTERN_CONST_GRADIENT_OBJECT
    for obj_num in range(1, num_constant_gradient + 1):
        this_pattern = obj_num - 1
        num_alphas = 0
        num_numbers = 0
        status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, obj_num,
            ipsc.cAlphaArgs, num_alphas,
            ipsc.rNumericArgs, num_numbers,
            status
        )

        room_air_pattern = state.dataRoomAir.AirPattern[this_pattern]
        room_air_pattern['Name'] = ipsc.cAlphaArgs[0]
        room_air_pattern['PatrnID'] = ipsc.rNumericArgs[0]
        room_air_pattern['PatternMode'] = UserDefinedPatternType.ConstGradTemp
        room_air_pattern['DeltaTstat'] = ipsc.rNumericArgs[1]
        room_air_pattern['DeltaTleaving'] = ipsc.rNumericArgs[2]
        room_air_pattern['DeltaTexhaust'] = ipsc.rNumericArgs[3]
        room_air_pattern['GradPatrn'] = {'Gradient': ipsc.rNumericArgs[4]}

    ipsc.cCurrentModuleObject = TEMP_PATTERN_TWO_GRADIENT_OBJECT
    for obj_num in range(1, num_two_gradient_interp + 1):
        this_pattern = num_constant_gradient + obj_num - 1
        num_alphas = 0
        num_numbers = 0
        status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, obj_num,
            ipsc.cAlphaArgs, num_alphas,
            ipsc.rNumericArgs, num_numbers,
            status
        )

        room_air_pattern = state.dataRoomAir.AirPattern[this_pattern]
        room_air_pattern['PatternMode'] = UserDefinedPatternType.TwoGradInterp
        room_air_pattern['Name'] = ipsc.cAlphaArgs[0]
        room_air_pattern['PatrnID'] = ipsc.rNumericArgs[0]
        room_air_pattern['TwoGradPatrn'] = {
            'TstatHeight': ipsc.rNumericArgs[1],
            'TleavingHeight': ipsc.rNumericArgs[2],
            'TexhaustHeight': ipsc.rNumericArgs[3],
            'LowGradient': ipsc.rNumericArgs[4],
            'HiGradient': ipsc.rNumericArgs[5],
            'InterpolationMode': UserDefinedPatternMode(
                _get_enum_value(USER_DEFINED_PATTERN_MODE_NAMES_UC, ipsc.cAlphaArgs[1].upper())
            ),
            'UpperBoundTempScale': ipsc.rNumericArgs[6],
            'LowerBoundTempScale': ipsc.rNumericArgs[7],
            'UpperBoundHeatRateScale': ipsc.rNumericArgs[8],
            'LowerBoundHeatRateScale': ipsc.rNumericArgs[9]
        }

        if room_air_pattern['TwoGradPatrn']['InterpolationMode'] == UserDefinedPatternMode.Invalid:
            state.ShowSevereInvalidKey(state, None, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            errors_found = True

        if room_air_pattern['TwoGradPatrn']['HiGradient'] == room_air_pattern['TwoGradPatrn']['LowGradient']:
            state.ShowWarningError(
                state,
                f"Upper and lower gradients equal, use {TEMP_PATTERN_CONST_GRADIENT_OBJECT} instead"
            )
            state.ShowContinueError(state, f"Entered in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")

        if ((room_air_pattern['TwoGradPatrn']['UpperBoundTempScale'] ==
             room_air_pattern['TwoGradPatrn']['LowerBoundTempScale']) and
            ((room_air_pattern['TwoGradPatrn']['InterpolationMode'] == UserDefinedPatternMode.OutdoorDryBulb) or
             (room_air_pattern['TwoGradPatrn']['InterpolationMode'] == UserDefinedPatternMode.ZoneAirTemp) or
             (room_air_pattern['TwoGradPatrn']['InterpolationMode'] == UserDefinedPatternMode.DeltaOutdoorZone))):
            state.ShowSevereError(
                state,
                f"Error in temperature scale in {ipsc.cCurrentModuleObject}: {ipsc.cAlphaArgs[0]}"
            )
            errors_found = True

        if ((room_air_pattern['TwoGradPatrn']['HiGradient'] ==
             room_air_pattern['TwoGradPatrn']['LowGradient']) and
            ((room_air_pattern['TwoGradPatrn']['InterpolationMode'] == UserDefinedPatternMode.SensibleCooling) or
             (room_air_pattern['TwoGradPatrn']['InterpolationMode'] == UserDefinedPatternMode.SensibleHeating))):
            state.ShowSevereError(
                state,
                f"Error in load scale in {ipsc.cCurrentModuleObject}: {ipsc.cAlphaArgs[0]}"
            )
            errors_found = True

    ipsc.cCurrentModuleObject = TEMP_PATTERN_ND_HEIGHT_OBJECT
    for obj_num in range(1, num_non_dimensional_height + 1):
        this_pattern = num_constant_gradient + num_two_gradient_interp + obj_num - 1
        num_alphas = 0
        num_numbers = 0
        status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, obj_num,
            ipsc.cAlphaArgs, num_alphas,
            ipsc.rNumericArgs, num_numbers,
            status
        )

        room_air_pattern = state.dataRoomAir.AirPattern[this_pattern]
        room_air_pattern['PatternMode'] = UserDefinedPatternType.NonDimenHeight
        room_air_pattern['Name'] = ipsc.cAlphaArgs[0]
        room_air_pattern['PatrnID'] = ipsc.rNumericArgs[0]
        room_air_pattern['DeltaTstat'] = ipsc.rNumericArgs[1]
        room_air_pattern['DeltaTleaving'] = ipsc.rNumericArgs[2]
        room_air_pattern['DeltaTexhaust'] = ipsc.rNumericArgs[3]

        num_pairs = int((num_numbers - 4) / 2.0)

        zeta_patrn = [0.0] * num_pairs
        delta_tai_patrn = [0.0] * num_pairs

        for i in range(num_pairs):
            zeta_patrn[i] = ipsc.rNumericArgs[2 * i + 4]
            delta_tai_patrn[i] = ipsc.rNumericArgs[2 * i + 5]

        room_air_pattern['VertPatrn'] = {
            'ZetaPatrn': zeta_patrn,
            'DeltaTaiPatrn': delta_tai_patrn
        }

        for i in range(1, num_pairs):
            if zeta_patrn[i] < zeta_patrn[i - 1]:
                state.ShowSevereError(
                    state,
                    f"Zeta values not in increasing order in {ipsc.cCurrentModuleObject}: {ipsc.cAlphaArgs[0]}"
                )
                errors_found = True

    ipsc.cCurrentModuleObject = TEMP_PATTERN_SURF_MAP_OBJECT
    for obj_num in range(1, num_surface_mapping + 1):
        this_pattern = (num_constant_gradient + num_two_gradient_interp +
                       num_non_dimensional_height + obj_num - 1)

        num_alphas = 0
        num_numbers = 0
        status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, obj_num,
            ipsc.cAlphaArgs, num_alphas,
            ipsc.rNumericArgs, num_numbers,
            status
        )

        room_air_pattern = state.dataRoomAir.AirPattern[this_pattern]
        room_air_pattern['PatternMode'] = UserDefinedPatternType.SurfMapTemp
        room_air_pattern['Name'] = ipsc.cAlphaArgs[0]
        room_air_pattern['PatrnID'] = ipsc.rNumericArgs[0]
        room_air_pattern['DeltaTstat'] = ipsc.rNumericArgs[1]
        room_air_pattern['DeltaTleaving'] = ipsc.rNumericArgs[2]
        room_air_pattern['DeltaTexhaust'] = ipsc.rNumericArgs[3]

        num_pairs = num_numbers - 4

        if num_pairs != (num_alphas - 1):
            state.ShowSevereError(
                state,
                f"Error in number of entries in {ipsc.cCurrentModuleObject} object: {ipsc.cAlphaArgs[0]}"
            )
            errors_found = True

        surf_name = [''] * num_pairs
        delta_tai = [0.0] * num_pairs
        surf_id = [0] * num_pairs

        for i in range(num_pairs):
            surf_name[i] = ipsc.cAlphaArgs[i + 1]
            delta_tai[i] = ipsc.rNumericArgs[i + 4]
            surf_id[i] = state.util.FindItemInList(ipsc.cAlphaArgs[i + 1], state.dataSurface.Surface)
            if surf_id[i] == 0:
                state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[i + 1], ipsc.cAlphaArgs[i + 1])
                errors_found = True

        room_air_pattern['MapPatrn'] = {
            'SurfName': surf_name,
            'DeltaTai': delta_tai,
            'SurfID': surf_id,
            'NumSurfs': num_pairs
        }

    if state.dataErrTracking.TotalRoomAirPatternTooLow > 0:
        state.ShowWarningError(
            state,
            f"GetUserDefinedPatternData: RoomAirModelUserTempPattern: "
            f"{state.dataErrTracking.TotalRoomAirPatternTooLow} problem(s) in non-dimensional height calculations, "
            f"too low surface height(s) in relation to floor height of zone(s)."
        )
        state.ShowContinueError(state, "...Use OutputDiagnostics,DisplayExtraWarnings; to see details.")
        state.dataErrTracking.TotalWarningErrors += state.dataErrTracking.TotalRoomAirPatternTooLow

    if state.dataErrTracking.TotalRoomAirPatternTooHigh > 0:
        state.ShowWarningError(
            state,
            f"GetUserDefinedPatternData: RoomAirModelUserTempPattern: "
            f"{state.dataErrTracking.TotalRoomAirPatternTooHigh} problem(s) in non-dimensional height calculations, "
            f"too high surface height(s) in relation to ceiling height of zone(s)."
        )
        state.ShowContinueError(state, "...Use OutputDiagnostics,DisplayExtraWarnings; to see details.")
        state.dataErrTracking.TotalWarningErrors += state.dataErrTracking.TotalRoomAirPatternTooHigh

    for i in range(state.dataGlobal.NumOfZones):
        if state.dataRoomAir.AirPatternZoneInfo[i] and state.dataRoomAir.AirPatternZoneInfo[i].get('IsUsed'):
            zone_equip_config_list = state.dataZoneEquip.ZoneEquipConfig
            found = 0
            for idx, config in enumerate(zone_equip_config_list):
                if config.get('ZoneName') == state.dataRoomAir.AirPatternZoneInfo[i]['ZoneName']:
                    found = idx
                    break

            if found != 0:
                state.dataRoomAir.AirPatternZoneInfo[i]['ZoneNodeID'] = zone_equip_config_list[found].get('ZoneNode')
                if 'ExhaustNode' in zone_equip_config_list[found] and zone_equip_config_list[found]['ExhaustNode']:
                    state.dataRoomAir.AirPatternZoneInfo[i]['ExhaustAirNodeID'] = zone_equip_config_list[found]['ExhaustNode']

            state.dataRoomAir.AirPatternZoneInfo[i]['ZoneHeight'] = state.dataHeatBal.Zone[i].get('CeilingHeight', 0.0)


def get_air_node_data(state: Any, errors_found: bool) -> None:
    """Get AirNode data for all zones."""
    if not state.dataRoomAir.DispVent1NodeModelUsed:
        return

    ipsc = state.dataIPShortCut

    state.dataRoomAir.TotNumOfZoneAirNodes = [0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.TotNumOfAirNodes = 0
    ipsc.cCurrentModuleObject = "RoomAir:Node"
    state.dataRoomAir.TotNumOfAirNodes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, ipsc.cCurrentModuleObject
    )

    if state.dataRoomAir.TotNumOfAirNodes <= 0:
        state.ShowSevereError(state, f"No {ipsc.cCurrentModuleObject} objects found in input.")
        state.ShowContinueError(state, f"The OneNodeDisplacementVentilation model requires {ipsc.cCurrentModuleObject} objects")
        errors_found = True
        return

    state.dataRoomAir.AirNode = [None] * state.dataRoomAir.TotNumOfAirNodes

    for air_node_num in range(1, state.dataRoomAir.TotNumOfAirNodes + 1):
        num_alphas = 0
        num_numbers = 0
        status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, air_node_num,
            ipsc.cAlphaArgs, num_alphas,
            ipsc.rNumericArgs, num_numbers,
            status
        )

        air_node = {}
        air_node['Name'] = ipsc.cAlphaArgs[0]
        air_node['ZoneName'] = ipsc.cAlphaArgs[2]
        air_node['ZonePtr'] = state.util.FindItemInList(air_node['ZoneName'], state.dataHeatBal.Zone)

        if air_node['ZonePtr'] == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
            errors_found = True
        else:
            num_of_surfs = 0
            for space_num in state.dataHeatBal.Zone[air_node['ZonePtr'] - 1].get('spaceIndexes', []):
                this_space = state.dataHeatBal.space[space_num - 1]
                num_of_surfs += this_space.get('HTSurfaceLast', 0) - this_space.get('HTSurfaceFirst', 0) + 1
            air_node['SurfMask'] = [False] * num_of_surfs

        air_node['ClassType'] = AirNodeType(
            _get_enum_value(AIR_NODE_TYPE_NAMES_UC, ipsc.cAlphaArgs[1].upper())
        )

        if air_node['ClassType'] == AirNodeType.Invalid:
            state.ShowSevereInvalidKey(state, None, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            errors_found = True

        air_node['Height'] = ipsc.rNumericArgs[0]
        num_surfs_involved = num_alphas - 3

        air_node['SurfMask'] = [False] * len(air_node.get('SurfMask', []))

        if num_surfs_involved <= 0:
            if (air_node['ClassType'] in [AirNodeType.Floor, AirNodeType.Ceiling, AirNodeType.Mundt,
                                          AirNodeType.Plume, AirNodeType.Rees]):
                state.ShowSevereError(
                    state,
                    f"GetAirNodeData: {ipsc.cCurrentModuleObject}=\"{air_node['Name']}\" invalid air node specification."
                )
                state.ShowContinueError(
                    state,
                    f"Mundt Room Air Model: No surface names specified. Air node=\"{air_node['Name']}\" requires surfaces associated with it."
                )
                errors_found = True
            state.dataRoomAir.AirNode[air_node_num - 1] = air_node
            continue

        if air_node['ClassType'] in [AirNodeType.Inlet, AirNodeType.Control, AirNodeType.Return, AirNodeType.Plume]:
            state.ShowWarningError(state, f"GetAirNodeData: {ipsc.cCurrentModuleObject}=\"{air_node['Name']}\" invalid linkage")
            state.ShowContinueError(
                state,
                f"Mundt Room Air Model: No surface names needed. Air node=\"{air_node['Name']}\" does not relate to any surfaces."
            )
            state.dataRoomAir.AirNode[air_node_num - 1] = air_node
            continue

        zone = state.dataHeatBal.Zone[air_node['ZonePtr'] - 1]
        num_of_surfs = 0
        for space_num in zone.get('spaceIndexes', []):
            this_space = state.dataHeatBal.space[space_num - 1]
            num_of_surfs += this_space.get('HTSurfaceLast', 0) - this_space.get('HTSurfaceFirst', 0) + 1

        if num_surfs_involved > num_of_surfs:
            state.ShowFatalError(
                state,
                f"GetAirNodeData: Mundt Room Air Model: Number of surfaces connected to {air_node['Name']} "
                f"is greater than number of surfaces in {zone.get('Name', '')}"
            )
            return

        surf_count = 0
        for list_surf_num in range(3, num_alphas):
            this_surf_in_zone = 0
            for space_num in zone.get('spaceIndexes', []):
                this_space = state.dataHeatBal.space[space_num - 1]
                for surf_num in range(this_space.get('HTSurfaceFirst', 0), this_space.get('HTSurfaceLast', 0) + 1):
                    this_surf_in_zone += 1
                    if ipsc.cAlphaArgs[list_surf_num] == state.dataSurface.Surface[surf_num - 1].get('Name', ''):
                        if 'SurfMask' in air_node:
                            air_node['SurfMask'][this_surf_in_zone - 1] = True
                        surf_count += 1
                        break
                if surf_count > 0:
                    break

        if num_surfs_involved != surf_count:
            state.ShowWarningError(
                state,
                f"GetAirNodeData: Mundt Room Air Model: Some surface names specified for {air_node['Name']} "
                f"are not in {zone.get('Name', '')}"
            )

        state.dataRoomAir.AirNode[air_node_num - 1] = air_node

    for air_node_num in range(1, state.dataRoomAir.TotNumOfAirNodes + 1):
        air_node = state.dataRoomAir.AirNode[air_node_num - 1]
        if state.dataRoomAir.AirModel[air_node['ZonePtr'] - 1]['AirModel'] == RoomAirModel.DispVent1Node:
            state.dataRoomAir.TotNumOfZoneAirNodes[air_node['ZonePtr'] - 1] += 1


def get_mundt_data(state: Any, errors_found: bool) -> None:
    """Get Mundt model controls for all zones."""
    if not state.dataRoomAir.DispVent1NodeModelUsed:
        return

    ipsc = state.dataIPShortCut

    state.dataRoomAir.ConvectiveFloorSplit = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.InfiltratFloorSplit = [0.0] * state.dataGlobal.NumOfZones
    ipsc.cCurrentModuleObject = "RoomAirSettings:OneNodeDisplacementVentilation"
    num_of_mundt_cntrl = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)

    if num_of_mundt_cntrl > state.dataGlobal.NumOfZones:
        state.ShowSevereError(state, f"Too many {ipsc.cCurrentModuleObject} objects in input file")
        state.ShowContinueError(state, f"There cannot be more {ipsc.cCurrentModuleObject} objects than number of zones.")
        errors_found = True

    if num_of_mundt_cntrl == 0:
        state.ShowWarningError(
            state,
            f"No {ipsc.cCurrentModuleObject} objects found, program assumes no convection or infiltration gains near floors"
        )
        return

    for control_num in range(1, num_of_mundt_cntrl + 1):
        num_alphas = 0
        num_numbers = 0
        status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, control_num,
            ipsc.cAlphaArgs, num_alphas,
            ipsc.rNumericArgs, num_numbers,
            status
        )

        zone_num = state.util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)
        if zone_num == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            errors_found = True
            continue

        if state.dataRoomAir.AirModel[zone_num - 1]['AirModel'] != RoomAirModel.DispVent1Node:
            state.ShowSevereError(state, f"Zone specified=\"{ipsc.cAlphaArgs[0]}\", Air Model type is not OneNodeDisplacementVentilation.")
            state.ShowContinueError(
                state,
                f"Air Model Type for zone={ROOM_AIR_MODEL_NAMES_UC[int(state.dataRoomAir.AirModel[zone_num - 1]['AirModel']) - 1]}"
            )
            errors_found = True
            continue

        state.dataRoomAir.ConvectiveFloorSplit[zone_num - 1] = ipsc.rNumericArgs[0]
        state.dataRoomAir.InfiltratFloorSplit[zone_num - 1] = ipsc.rNumericArgs[1]


def get_displacement_vent_data(state: Any, errors_found: bool) -> None:
    """Get UCSD Displacement ventilation model controls."""
    if not state.dataRoomAir.UCSDModelUsed:
        return

    ipsc = state.dataIPShortCut
    ipsc.cCurrentModuleObject = "RoomAirSettings:ThreeNodeDisplacementVentilation"
    state.dataRoomAir.TotDispVent3Node = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, ipsc.cCurrentModuleObject
    )

    if state.dataRoomAir.TotDispVent3Node <= 0:
        return

    state.dataRoomAir.ZoneDispVent3Node = [None] * state.dataRoomAir.TotDispVent3Node

    for loop in range(1, state.dataRoomAir.TotDispVent3Node + 1):
        num_alpha = 0
        num_number = 0
        io_stat = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, loop,
            ipsc.cAlphaArgs, num_alpha,
            ipsc.rNumericArgs, num_number,
            io_stat
        )

        zone_dv3n = {}
        zone_dv3n['ZonePtr'] = state.util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)

        if zone_dv3n['ZonePtr'] == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            errors_found = True
        else:
            state.dataRoomAir.IsZoneDispVent3Node[zone_dv3n['ZonePtr'] - 1] = True

        if ipsc.lAlphaFieldBlanks[1]:
            state.ShowSevereEmptyField(state, None, ipsc.cAlphaFieldNames[1])
            errors_found = True
        else:
            gains_sched = state.Sched.GetSchedule(state, ipsc.cAlphaArgs[1])
            if gains_sched is None:
                state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
                errors_found = True
            zone_dv3n['gainsSched'] = gains_sched

        zone_dv3n['NumPlumesPerOcc'] = ipsc.rNumericArgs[0]
        zone_dv3n['ThermostatHeight'] = ipsc.rNumericArgs[1]
        zone_dv3n['ComfortHeight'] = ipsc.rNumericArgs[2]
        zone_dv3n['TempTrigger'] = ipsc.rNumericArgs[3]

        state.dataRoomAir.ZoneDispVent3Node[loop - 1] = zone_dv3n


def get_cross_vent_data(state: Any, errors_found: bool) -> None:
    """Get UCSD Cross ventilation model controls."""
    if not state.dataRoomAir.UCSDModelUsed:
        return

    ipsc = state.dataIPShortCut
    ipsc.cCurrentModuleObject = "RoomAirSettings:CrossVentilation"
    state.dataRoomAir.TotCrossVent = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, ipsc.cCurrentModuleObject
    )

    if state.dataRoomAir.TotCrossVent <= 0:
        return

    state.dataRoomAir.ZoneCrossVent = [None] * state.dataRoomAir.TotCrossVent

    for loop in range(1, state.dataRoomAir.TotCrossVent + 1):
        num_alpha = 0
        num_number = 0
        io_stat = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, loop,
            ipsc.cAlphaArgs, num_alpha,
            ipsc.rNumericArgs, num_number,
            io_stat
        )

        zone_cv = {}
        zone_cv['ZonePtr'] = state.util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)

        if zone_cv['ZonePtr'] == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            errors_found = True
        else:
            state.dataRoomAir.IsZoneCrossVent[zone_cv['ZonePtr'] - 1] = True

        if ipsc.lAlphaFieldBlanks[1]:
            state.ShowSevereEmptyField(state, None, ipsc.cAlphaFieldNames[1])
            errors_found = True
        else:
            gains_sched = state.Sched.GetSchedule(state, ipsc.cAlphaArgs[1])
            if gains_sched is None:
                state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
                errors_found = True
            zone_cv['gainsSched'] = gains_sched

        if ipsc.lAlphaFieldBlanks[2]:
            for loop2 in range(1, state.dataHeatBal.TotPeople + 1):
                if state.dataHeatBal.People[loop2 - 1].get('ZonePtr') != zone_cv['ZonePtr']:
                    continue
                if not state.dataHeatBal.People[loop2 - 1].get('Fanger', False):
                    continue
                state.ShowSevereEmptyField(state, None, ipsc.cAlphaFieldNames[2])
                errors_found = True
        else:
            zone_cv['VforComfort'] = Comfort(
                _get_enum_value(COMFORT_NAMES_UC, ipsc.cAlphaArgs[2].upper())
            )
            if zone_cv['VforComfort'] == Comfort.Invalid:
                state.ShowSevereInvalidKey(state, None, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
                errors_found = True

        if zone_cv['ZonePtr'] == 0:
            state.dataRoomAir.ZoneCrossVent[loop - 1] = zone_cv
            continue

        if state.util.FindItemInList(
            state.dataHeatBal.Zone[zone_cv['ZonePtr'] - 1].get('Name', ''),
            state.afn.MultizoneZoneData
        ) == 0:
            state.ShowSevereError(state, f"Problem with {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
            state.ShowContinueError(state, "AirflowNetwork airflow model must be active in this zone")
            errors_found = True

        for i_link in range(1, state.afn.NumOfLinksMultiZone + 1):
            mz_surface_data = state.afn.MultizoneSurfaceData[i_link - 1]
            node_num1 = mz_surface_data.get('NodeNums', [0, 0])[0]
            node_num2 = mz_surface_data.get('NodeNums', [0, 0])[1]

            if (state.dataSurface.Surface[mz_surface_data.get('SurfNum', 1) - 1].get('Zone') == zone_cv['ZonePtr'] or
                (state.afn.AirflowNetworkNodeData[node_num2 - 1].get('EPlusZoneNum') == zone_cv['ZonePtr'] and
                 state.afn.AirflowNetworkNodeData[node_num1 - 1].get('EPlusZoneNum', 0) > 0) or
                (state.afn.AirflowNetworkNodeData[node_num2 - 1].get('EPlusZoneNum', 0) > 0 and
                 state.afn.AirflowNetworkNodeData[node_num1 - 1].get('EPlusZoneNum') == zone_cv['ZonePtr'])):

                comp_num = state.afn.AirflowNetworkLinkageData[i_link - 1].get('CompNum')
                type_num = state.afn.AirflowNetworkCompData[comp_num - 1].get('TypeNum')

                if state.afn.AirflowNetworkCompData[comp_num - 1].get('CompTypeNum') == 4:  # SCR
                    if state.afn.MultizoneSurfaceCrackData[type_num - 1].get('exponent', 0) != 0.50:
                        state.dataRoomAir.AirModel[zone_cv['ZonePtr'] - 1]['AirModel'] = RoomAirModel.Mixing
                        state.ShowWarningError(state, f"Problem with {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
                        state.ShowWarningError(state, f"Roomair model will not be applied for Zone={ipsc.cAlphaArgs[0]}.")
                        state.ShowContinueError(
                            state,
                            f"AirflowNetwrok:Multizone:Surface crack object must have an air flow coefficient = 0.5, value was={state.afn.MultizoneSurfaceCrackData[type_num - 1].get('exponent', 0):.2f}"
                        )

        state.dataRoomAir.ZoneCrossVent[loop - 1] = zone_cv


def get_ufad_zone_data(state: Any, errors_found: bool) -> None:
    """Get UCSD UFAD interior and exterior zone model controls."""
    if not state.dataRoomAir.UCSDModelUsed:
        state.dataRoomAir.TotUFADInt = 0
        state.dataRoomAir.TotUFADExt = 0
        return

    ipsc = state.dataIPShortCut

    ipsc.cCurrentModuleObject = "RoomAirSettings:UnderFloorAirDistributionInterior"
    state.dataRoomAir.TotUFADInt = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, ipsc.cCurrentModuleObject
    )
    ipsc.cCurrentModuleObject = "RoomAirSettings:UnderFloorAirDistributionExterior"
    state.dataRoomAir.TotUFADExt = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, ipsc.cCurrentModuleObject
    )

    if state.dataRoomAir.TotUFADInt <= 0 and state.dataRoomAir.TotUFADExt <= 0:
        return

    state.dataRoomAir.ZoneUFAD = [None] * (state.dataRoomAir.TotUFADInt + state.dataRoomAir.TotUFADExt)
    state.dataRoomAir.ZoneUFADPtr = [0] * state.dataGlobal.NumOfZones

    ipsc.cCurrentModuleObject = "RoomAirSettings:UnderFloorAirDistributionInterior"
    for loop in range(1, state.dataRoomAir.TotUFADInt + 1):
        num_alpha = 0
        num_number = 0
        io_stat = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, loop,
            ipsc.cAlphaArgs, num_alpha,
            ipsc.rNumericArgs, num_number,
            io_stat
        )

        zone_ui = {}
        zone_ui['ZoneName'] = ipsc.cAlphaArgs[0]
        zone_ui['ZonePtr'] = state.util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)

        if zone_ui['ZonePtr'] == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            errors_found = True
        else:
            state.dataRoomAir.IsZoneUFAD[zone_ui['ZonePtr'] - 1] = True
            state.dataRoomAir.ZoneUFADPtr[zone_ui['ZonePtr'] - 1] = loop

        zone_ui['DiffuserType'] = Diffuser(
            _get_enum_value(DIFFUSER_NAMES_UC, ipsc.cAlphaArgs[1].upper())
        )
        if zone_ui['DiffuserType'] == Diffuser.Invalid:
            state.ShowSevereInvalidKey(state, None, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            errors_found = True

        zone_ui['DiffusersPerZone'] = ipsc.rNumericArgs[0]
        zone_ui['PowerPerPlume'] = ipsc.rNumericArgs[1]
        zone_ui['DiffArea'] = ipsc.rNumericArgs[2]
        zone_ui['DiffAngle'] = ipsc.rNumericArgs[3]
        zone_ui['ThermostatHeight'] = ipsc.rNumericArgs[4]
        zone_ui['ComfortHeight'] = ipsc.rNumericArgs[5]
        zone_ui['TempTrigger'] = ipsc.rNumericArgs[6]
        zone_ui['TransHeight'] = ipsc.rNumericArgs[7]
        zone_ui['A_Kc'] = ipsc.rNumericArgs[8]
        zone_ui['B_Kc'] = ipsc.rNumericArgs[9]
        zone_ui['C_Kc'] = ipsc.rNumericArgs[10]
        zone_ui['D_Kc'] = ipsc.rNumericArgs[11]
        zone_ui['E_Kc'] = ipsc.rNumericArgs[12]

        state.dataRoomAir.ZoneUFAD[loop - 1] = zone_ui

    ipsc.cCurrentModuleObject = "RoomAirSettings:UnderFloorAirDistributionExterior"
    for loop in range(1, state.dataRoomAir.TotUFADExt + 1):
        num_alpha = 0
        num_number = 0
        io_stat = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, loop,
            ipsc.cAlphaArgs, num_alpha,
            ipsc.rNumericArgs, num_number,
            io_stat
        )

        zone_ue = {}
        zone_ue['ZoneName'] = ipsc.cAlphaArgs[0]
        zone_ue['ZonePtr'] = state.util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)

        if zone_ue['ZonePtr'] == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            errors_found = True
        else:
            state.dataRoomAir.IsZoneUFAD[zone_ue['ZonePtr'] - 1] = True
            state.dataRoomAir.ZoneUFADPtr[zone_ue['ZonePtr'] - 1] = loop + state.dataRoomAir.TotUFADInt

        zone_ue['DiffuserType'] = Diffuser(
            _get_enum_value(DIFFUSER_NAMES_UC, ipsc.cAlphaArgs[1].upper())
        )
        if zone_ue['DiffuserType'] == Diffuser.Invalid:
            state.ShowSevereInvalidKey(state, None, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            errors_found = True

        zone_ue['DiffusersPerZone'] = ipsc.rNumericArgs[0]
        zone_ue['PowerPerPlume'] = ipsc.rNumericArgs[1]
        zone_ue['DiffArea'] = ipsc.rNumericArgs[2]
        zone_ue['DiffAngle'] = ipsc.rNumericArgs[3]
        zone_ue['ThermostatHeight'] = ipsc.rNumericArgs[4]
        zone_ue['ComfortHeight'] = ipsc.rNumericArgs[5]
        zone_ue['TempTrigger'] = ipsc.rNumericArgs[6]
        zone_ue['TransHeight'] = ipsc.rNumericArgs[7]
        zone_ue['A_Kc'] = ipsc.rNumericArgs[8]
        zone_ue['B_Kc'] = ipsc.rNumericArgs[9]
        zone_ue['C_Kc'] = ipsc.rNumericArgs[10]
        zone_ue['D_Kc'] = ipsc.rNumericArgs[11]
        zone_ue['E_Kc'] = ipsc.rNumericArgs[12]

        state.dataRoomAir.ZoneUFAD[loop + state.dataRoomAir.TotUFADInt - 1] = zone_ue


def get_room_airflow_network_data(state: Any, errors_found: bool) -> None:
    """Get RoomAirflowNetwork data for all zones."""
    ipsc = state.dataIPShortCut
    ipsc.cCurrentModuleObject = "RoomAirSettings:AirflowNetwork"
    state.dataRoomAir.NumOfRoomAFNControl = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, ipsc.cCurrentModuleObject
    )

    if state.dataRoomAir.NumOfRoomAFNControl == 0:
        return

    if state.dataRoomAir.NumOfRoomAFNControl > state.dataGlobal.NumOfZones:
        state.ShowSevereError(state, f"Too many {ipsc.cCurrentModuleObject} objects in input file")
        state.ShowContinueError(state, f"There cannot be more {ipsc.cCurrentModuleObject} objects than number of zones.")
        errors_found = True

    if not hasattr(state.dataRoomAir, 'AFNZoneInfo') or state.dataRoomAir.AFNZoneInfo is None:
        state.dataRoomAir.AFNZoneInfo = [None] * state.dataGlobal.NumOfZones

    for loop in range(1, state.dataRoomAir.NumOfRoomAFNControl + 1):
        num_alphas = 0
        num_numbers = 0
        status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, ipsc.cCurrentModuleObject, loop,
            ipsc.cAlphaArgs, num_alphas,
            ipsc.rNumericArgs, num_numbers,
            status
        )

        zone_num = state.util.FindItemInList(ipsc.cAlphaArgs[1], state.dataHeatBal.Zone)

        if zone_num == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            errors_found = True
            continue

        if state.dataRoomAir.AirModel[zone_num - 1]['AirModel'] != RoomAirModel.AirflowNetwork:
            state.ShowSevereError(
                state,
                f"GetRoomAirflowNetworkData: Zone specified='{ipsc.cAlphaArgs[0]}', Air Model type is not AirflowNetwork."
            )
            state.ShowContinueError(
                state,
                f"Air Model Type for zone ={ROOM_AIR_MODEL_NAMES_UC[int(state.dataRoomAir.AirModel[zone_num - 1]['AirModel']) - 1]}"
            )
            errors_found = True
            continue

        room_afn_zone_info = {}
        room_afn_zone_info['ZoneID'] = zone_num
        room_afn_zone_info['IsUsed'] = True
        room_afn_zone_info['Name'] = ipsc.cAlphaArgs[0]
        room_afn_zone_info['ZoneName'] = ipsc.cAlphaArgs[1]
        room_afn_zone_info['NumOfAirNodes'] = num_alphas - 3

        if room_afn_zone_info['NumOfAirNodes'] > 0:
            room_afn_zone_info['Node'] = [{'Name': ipsc.cAlphaArgs[i + 3]} for i in range(room_afn_zone_info['NumOfAirNodes'])]
        else:
            state.ShowSevereError(
                state,
                f"GetRoomAirflowNetworkData: Incomplete input in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}"
            )
            errors_found = True

        room_afn_zone_info['ControlAirNodeID'] = state.util.FindItemInList(
            ipsc.cAlphaArgs[2],
            [node.get('Name', '') for node in room_afn_zone_info.get('Node', [])]
        )

        if room_afn_zone_info['ControlAirNodeID'] == 0:
            state.ShowSevereItemNotFound(state, None, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
            errors_found = True
            continue

        room_afn_zone_info['totNumSurfs'] = 0
        for space_num in state.dataHeatBal.Zone[zone_num - 1].get('spaceIndexes', []):
            this_space = state.dataHeatBal.space[space_num - 1]
            room_afn_zone_info['totNumSurfs'] += this_space.get('HTSurfaceLast', 0) - this_space.get('HTSurfaceFirst', 0) + 1

        state.dataRoomAir.AFNZoneInfo[zone_num - 1] = room_afn_zone_info

    ipsc.cCurrentModuleObject = "RoomAir:Node:AirflowNetwork"
    state.dataRoomAir.TotNumOfRoomAFNNodes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, ipsc.cCurrentModuleObject
    )


def shared_dvcvuf_data_init(state: Any, zone_num: int) -> None:
    """Initialize data shared between UCSD models."""
    if state.dataRoomAir.MyOneTimeFlag:
        state.dataRoomAir.MyEnvrnFlag = [True] * state.dataGlobal.NumOfZones

        state.dataRoomAir.APos_Wall = [0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.APos_Floor = [0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.APos_Ceiling = [0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.PosZ_Wall = [{'beg': 0, 'end': 0}] * state.dataGlobal.NumOfZones
        state.dataRoomAir.PosZ_Floor = [{'beg': 0, 'end': 0}] * state.dataGlobal.NumOfZones
        state.dataRoomAir.PosZ_Ceiling = [{'beg': 0, 'end': 0}] * state.dataGlobal.NumOfZones
        state.dataRoomAir.APos_Window = [0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.APos_Door = [0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.APos_Internal = [0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.PosZ_Window = [{'beg': 0, 'end': 0}] * state.dataGlobal.NumOfZones
        state.dataRoomAir.PosZ_Door = [{'beg': 0, 'end': 0}] * state.dataGlobal.NumOfZones
        state.dataRoomAir.PosZ_Internal = [{'beg': 0, 'end': 0}] * state.dataGlobal.NumOfZones
        state.dataRoomAir.HCeiling = [0.0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.HWall = [0.0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.HFloor = [0.0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.HInternal = [0.0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.HWindow = [0.0] * state.dataSurface.TotSurfaces
        state.dataRoomAir.HDoor = [0.0] * state.dataSurface.TotSurfaces

        state.dataRoomAir.ZoneCeilingHeight1 = [0.0] * state.dataGlobal.NumOfZones
        state.dataRoomAir.ZoneCeilingHeight2 = [0.0] * state.dataGlobal.NumOfZones

        state.dataRoomAir.MyOneTimeFlag = False


def get_rafn_node_num(state: Any, rafn_node_name: str) -> tuple:
    """
    Find zone number and node number based on RoomAir node name.
    Returns (zone_num, rafn_node_num, errors_found)
    """
    if state.dataRoomAir.GetAirModelData:
        get_air_model_datas(state)
        state.dataRoomAir.GetAirModelData = False

    errors_found = False
    rafn_node_num = 0

    for i in range(1, state.dataGlobal.NumOfZones + 1):
        afn_zone_info = state.dataRoomAir.AFNZoneInfo[i - 1]
        if afn_zone_info and afn_zone_info.get('NumOfAirNodes', 0) > 0:
            for node_idx, node in enumerate(afn_zone_info.get('Node', [])):
                if node.get('Name', '') == rafn_node_name:
                    rafn_node_num = node_idx + 1
                    return i, rafn_node_num, errors_found

    errors_found = True
    state.ShowSevereError(
        state,
        f"Could not find RoomAir:Node:AirflowNetwork number with AirflowNetwork:IntraZone:Node Name='{rafn_node_name}"
    )
    return 0, 0, errors_found


def check_equip_name(
    state: Any,
    equip_name: str,
    zone_equip_type: int
) -> tuple:
    """
    Check equipment name and return supply/return node names.
    Returns (equip_found, supply_node_name, return_node_name)
    """
    equip_find = False
    supply_node_num = 0
    return_node_num = 0
    supply_node_name = ""
    return_node_name = ""

    if zone_equip_type < 0:
        return equip_find, supply_node_name, return_node_name

    switch_map = {
        1: lambda: _check_vrf_terminal(state, equip_name),
        2: lambda: _check_erv(state, equip_name),
        3: lambda: _check_fan_coil(state, equip_name),
        4: lambda: _check_outdoor_air_unit(state, equip_name),
        5: lambda: _check_ptac(state, equip_name),
        6: lambda: _check_pthp(state, equip_name),
        7: lambda: _check_unit_heater(state, equip_name),
        8: lambda: _check_unit_ventilator(state, equip_name),
        9: lambda: _check_ventilated_slab(state, equip_name),
        10: lambda: _check_wshp(state, equip_name),
        11: lambda: _check_window_ac(state, equip_name),
        12: lambda: ("", ""),
        13: lambda: ("", ""),
        14: lambda: ("", ""),
        15: lambda: ("", ""),
        16: lambda: _check_dehumidifier(state, equip_name),
        17: lambda: _check_purchased_air(state, equip_name),
        18: lambda: ("", ""),
        19: lambda: _check_hybrid_ac(state, equip_name),
        20: lambda: ("", ""),
        21: lambda: ("", ""),
        22: lambda: ("", ""),
        23: lambda: ("", ""),
        24: lambda: ("", ""),
        25: lambda: _check_water_heater(state, equip_name),
        26: lambda: _check_water_heater(state, equip_name),
    }

    if zone_equip_type in switch_map:
        supply_node_num, return_node_num = switch_map[zone_equip_type]()

    if supply_node_num > 0:
        supply_node_name = state.dataLoopNodes.NodeID[supply_node_num - 1]
        equip_find = True
    if return_node_num > 0:
        return_node_name = state.dataLoopNodes.NodeID[return_node_num - 1]
    else:
        return_node_name = ""

    return equip_find, supply_node_name, return_node_name


def _get_enum_value(names_list: List[str], target: str) -> int:
    """Get enum value from uppercase names list."""
    try:
        return names_list.index(target) + 1
    except ValueError:
        return -1


def _check_vrf_terminal(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getVRFTUIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    return state.dataHVACVarRefFlow.VRFTU[eq_index - 1].get('VRFTUOutletNodeNum', 0), 0


def _check_erv(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getStandAloneERVIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    return state.dataHVACStandAloneERV.StandAloneERV[eq_index - 1].get('SupplyAirInletNode', 0), 0


def _check_fan_coil(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getFanCoilIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    fc = state.dataFanCoilUnits.FanCoil[eq_index - 1]
    return fc.get('AirOutNode', 0), fc.get('AirInNode', 0)


def _check_outdoor_air_unit(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getOutdoorAirUnitIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    ou = state.dataOutdoorAirUnit.OutAirUnit[eq_index - 1]
    return ou.get('AirOutletNode', 0), ou.get('AirInletNode', 0)


def _check_ptac(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getUnitarySystemIndex', lambda s, n, t: -1)(state, equip_name, 5)
    if eq_index == -1:
        return 0, 0
    us = state.dataUnitarySystems.unitarySys[eq_index]
    return us.get('AirOutNode', 0), us.get('AirInNode', 0)


def _check_pthp(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getUnitarySystemIndex', lambda s, n, t: -1)(state, equip_name, 6)
    if eq_index == -1:
        return 0, 0
    us = state.dataUnitarySystems.unitarySys[eq_index]
    return us.get('AirOutNode', 0), us.get('AirInNode', 0)


def _check_unit_heater(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getUnitHeaterIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    uh = state.dataUnitHeaters.UnitHeat[eq_index - 1]
    return uh.get('AirOutNode', 0), uh.get('AirInNode', 0)


def _check_unit_ventilator(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getUnitVentilatorIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    uv = state.dataUnitVentilators.UnitVent[eq_index - 1]
    return uv.get('AirOutNode', 0), uv.get('AirInNode', 0)


def _check_ventilated_slab(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getVentilatedSlabIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    vs = state.dataVentilatedSlab.VentSlab[eq_index - 1]
    return vs.get('ZoneAirInNode', 0), vs.get('ReturnAirNode', 0)


def _check_wshp(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getUnitarySystemIndex', lambda s, n, t: -1)(state, equip_name, 10)
    if eq_index == -1:
        return 0, 0
    us = state.dataUnitarySystems.unitarySys[eq_index]
    return us.get('AirOutNode', 0), us.get('AirInNode', 0)


def _check_window_ac(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getWindowACIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    wac = state.dataWindowAC.WindAC[eq_index - 1]
    return wac.get('AirOutNode', 0), wac.get('AirInNode', 0)


def _check_dehumidifier(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getZoneDehumidifierIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    zd = state.dataZoneDehumidifier.ZoneDehumid[eq_index - 1]
    return zd.get('AirOutletNodeNum', 0), zd.get('AirInletNodeNum', 0)


def _check_purchased_air(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getPurchasedAirIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    pa = state.dataPurchasedAirMgr.PurchAir[eq_index - 1]
    return pa.get('ZoneSupplyAirNodeNum', 0), pa.get('ZoneExhaustAirNodeNum', 0)


def _check_hybrid_ac(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getHybridUnitaryACIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    hac = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[eq_index - 1]
    return hac.get('OutletNode', 0), hac.get('InletNode', 0)


def _check_water_heater(state: Any, equip_name: str) -> tuple:
    eq_index = getattr(state, 'getHeatPumpWaterHeaterIndex', lambda s, n: 0)(state, equip_name)
    if eq_index == 0:
        return 0, 0
    hpwh = state.dataWaterThermalTanks.HPWaterHeater[eq_index - 1]
    return hpwh.get('HeatPumpAirOutletNode', 0), hpwh.get('HeatPumpAirInletNode', 0)
