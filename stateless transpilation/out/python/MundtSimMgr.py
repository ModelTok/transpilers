from __future__ import annotations
from dataclasses import dataclass, field
from typing import Protocol, List, Optional, Any
from enum import IntEnum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData.dataGlobal.NumOfZones, Multiplier, ListMultiplier, OutDryBulbTemp
# - EnergyPlusData.dataHeatBal.Zone, space, MundtFirstTimeFlag
# - EnergyPlusData.dataHeatBalFanSys.SumConvHTRadSys, SumConvPool, zoneTstatSetpts, TempTstatAir
# - EnergyPlusData.dataHeatBalSurface.SurfTempIn, SurfHConvInt
# - EnergyPlusData.dataRoomAir.AirModel, AirNode, TotNumOfZoneAirNodes, ConvectiveFloorSplit, InfiltratFloorSplit
# - EnergyPlusData.dataSurface.Surface, SurfTAirRef, SurfTAirRefRpt
# - EnergyPlusData.dataZoneEquip.ZoneEquipConfig
# - EnergyPlusData.dataZoneTempPredictorCorrector.zoneHeatBalance
# - EnergyPlusData.dataLoopNodes.Node
# - EnergyPlusData.dataEnvrn.OutBaroPress
# - EnergyPlusData.dataMundtSimMgr (instance being managed)
# - ShowFatalError(state, msg)
# - ShowSevereError(state, msg)
# - SetupOutputVariable(state, name, units, var_ref, timestep, storetype, key_name)
# - Util.SameString(str1, str2)
# - InternalHeatGains.zoneSumAllInternalConvectionGains(state, zone_num)
# - InternalHeatGains.zoneSumAllReturnAirConvectionGains(state, zone_num, ???)
# - Psychrometrics.PsyCpAirFnW(humidity_ratio)
# - Psychrometrics.PsyRhoAirFnPbTdbW(state, pressure, temp, humidity_ratio)
# - Psychrometrics.PsyWFnTdpPb(state, dew_point_temp, pressure)
# - format(msg, args...) for string formatting

CP_AIR = 1005.0
MIN_SLOPE = 0.001
MAX_SLOPE = 5.0

class AirNodeType(IntEnum):
    Invalid = 0
    Inlet = 1
    Floor = 2
    Control = 3
    Ceiling = 4
    Mundt = 5
    Return = 6


@dataclass
class DefineLinearModelNode:
    air_node_name: str = ""
    class_type: int = AirNodeType.Invalid
    height: float = 0.0
    temp: float = 0.0
    surf_mask: List[bool] = field(default_factory=list)


@dataclass
class DefineSurfaceSettings:
    area: float = 0.0
    temp: float = 0.0
    hc: float = 0.0
    t_mean_air: float = 0.0


@dataclass
class DefineZoneData:
    num_of_surfs: int = 0
    mundt_zone_index: int = 0
    hb_surface_indexes: List[int] = field(default_factory=list)


@dataclass
class MundtSimMgrData:
    floor_surf_set_ids: List[int] = field(default_factory=list)
    these_surf_ids: List[int] = field(default_factory=list)
    mundt_ceil_air_id: int = 0
    mundt_foot_air_id: int = 0
    supply_node_id: int = 0
    tstat_node_id: int = 0
    return_node_id: int = 0
    num_room_nodes: int = 0
    num_floor_surfs: int = 0
    room_node_ids: List[int] = field(default_factory=list)
    id_1d_surf: List[int] = field(default_factory=list)
    mundt_zone_num: int = 0
    zone_height: float = 0.0
    zone_floor_area: float = 0.0
    qvent_cool: float = 0.0
    conv_int_gain: float = 0.0
    supply_air_temp: float = 0.0
    supply_air_volume_rate: float = 0.0
    zone_air_density: float = 0.0
    qsys_cool_tot: float = 0.0
    zone_data: List[DefineZoneData] = field(default_factory=list)
    line_node: List[List[DefineLinearModelNode]] = field(default_factory=list)
    mundt_air_surf: List[List[DefineSurfaceSettings]] = field(default_factory=list)
    floor_surf: List[DefineSurfaceSettings] = field(default_factory=list)

    def clear_state(self) -> None:
        self.floor_surf_set_ids.clear()
        self.these_surf_ids.clear()
        self.mundt_ceil_air_id = 0
        self.mundt_foot_air_id = 0
        self.supply_node_id = 0
        self.tstat_node_id = 0
        self.return_node_id = 0
        self.num_room_nodes = 0
        self.num_floor_surfs = 0
        self.room_node_ids.clear()
        self.id_1d_surf.clear()
        self.mundt_zone_num = 0
        self.zone_height = 0.0
        self.zone_floor_area = 0.0
        self.qvent_cool = 0.0
        self.conv_int_gain = 0.0
        self.supply_air_temp = 0.0
        self.supply_air_volume_rate = 0.0
        self.zone_air_density = 0.0
        self.qsys_cool_tot = 0.0
        self.zone_data.clear()
        self.line_node.clear()
        self.mundt_air_surf.clear()
        self.floor_surf.clear()


class EnergyPlusDataProto(Protocol):
    dataGlobal: Any
    dataHeatBal: Any
    dataRoomAir: Any
    dataMundtSimMgr: MundtSimMgrData
    dataSurface: Any
    dataZoneEquip: Any
    dataZoneTempPredictorCorrector: Any
    dataLoopNodes: Any
    dataEnvrn: Any
    dataHeatBalFanSys: Any
    dataHeatBalSurf: Any


def manage_disp_vent_1_node(state: EnergyPlusDataProto, zone_num: int) -> None:
    from UtilityRoutines import ShowFatalError

    if state.dataHeatBal.MundtFirstTimeFlag:
        init_disp_vent_1_node(state)
        state.dataHeatBal.MundtFirstTimeFlag = False

    state.dataMundtSimMgr.mundt_zone_num = state.dataMundtSimMgr.zone_data[zone_num - 1].mundt_zone_index

    get_surf_hb_data_for_disp_vent_1_node(state, zone_num)

    if state.dataMundtSimMgr.supply_air_volume_rate > 0.0001 and state.dataMundtSimMgr.qsys_cool_tot > 0.0001:
        errors_found = False
        setup_disp_vent_1_node(state, zone_num, errors_found)
        if errors_found:
            ShowFatalError(state, "ManageMundtModel: Errors in setting up Mundt Model. Preceding condition(s) cause termination.")

        calc_disp_vent_1_node(state, zone_num)

    set_surf_hb_data_for_disp_vent_1_node(state, zone_num)


def init_disp_vent_1_node(state: EnergyPlusDataProto) -> None:
    from UtilityRoutines import ShowFatalError, ShowSevereError
    from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType
    from utilities import Util

    state.dataMundtSimMgr.zone_data = [DefineZoneData() for _ in range(state.dataGlobal.NumOfZones)]

    num_of_mundt_zones = 0
    max_num_of_surfs = 0
    max_num_of_floor_surfs = 0
    max_num_of_air_nodes = 0
    max_num_of_room_nodes = 0
    errors_found = False

    for zone_index in range(1, state.dataGlobal.NumOfZones + 1):
        this_zone = state.dataHeatBal.Zone[zone_index - 1]
        if state.dataRoomAir.AirModel[zone_index - 1].AirModel == "DispVent1Node":
            num_of_mundt_zones += 1
            num_of_surfs = 0
            for space_num in this_zone.spaceIndexes:
                this_space = state.dataHeatBal.space[space_num - 1]
                for surf_num in range(this_space.HTSurfaceFirst - 1, this_space.HTSurfaceLast):
                    state.dataMundtSimMgr.zone_data[zone_index - 1].hb_surface_indexes.append(surf_num + 1)
                    num_of_surfs += 1
                max_num_of_surfs = max(max_num_of_surfs, num_of_surfs)
                num_of_air_nodes = state.dataRoomAir.TotNumOfZoneAirNodes[zone_index - 1]
                max_num_of_air_nodes = max(max_num_of_air_nodes, num_of_air_nodes)
                state.dataMundtSimMgr.zone_data[zone_index - 1].num_of_surfs = num_of_surfs
                state.dataMundtSimMgr.zone_data[zone_index - 1].mundt_zone_index = num_of_mundt_zones

    state.dataMundtSimMgr.id_1d_surf = [i + 1 for i in range(max_num_of_surfs)]
    state.dataMundtSimMgr.these_surf_ids = [0] * max_num_of_surfs
    state.dataMundtSimMgr.mundt_air_surf = [[DefineSurfaceSettings() for _ in range(num_of_mundt_zones)] for _ in range(max_num_of_surfs)]
    state.dataMundtSimMgr.line_node = [[DefineLinearModelNode() for _ in range(num_of_mundt_zones)] for _ in range(max_num_of_air_nodes)]

    for surf_num in range(max_num_of_surfs):
        state.dataMundtSimMgr.id_1d_surf[surf_num] = surf_num + 1

    for i in range(max_num_of_surfs):
        for j in range(num_of_mundt_zones):
            state.dataMundtSimMgr.mundt_air_surf[i][j].area = 0.0
            state.dataMundtSimMgr.mundt_air_surf[i][j].temp = 25.0
            state.dataMundtSimMgr.mundt_air_surf[i][j].hc = 0.0
            state.dataMundtSimMgr.mundt_air_surf[i][j].t_mean_air = 25.0

    for i in range(max_num_of_air_nodes):
        for j in range(num_of_mundt_zones):
            state.dataMundtSimMgr.line_node[i][j].air_node_name = ""
            state.dataMundtSimMgr.line_node[i][j].class_type = AirNodeType.Invalid
            state.dataMundtSimMgr.line_node[i][j].height = 0.0
            state.dataMundtSimMgr.line_node[i][j].temp = 25.0

    for mundt_zone_index in range(1, num_of_mundt_zones + 1):
        for zone_index in range(1, state.dataGlobal.NumOfZones + 1):
            this_zone = state.dataHeatBal.Zone[zone_index - 1]
            if state.dataMundtSimMgr.zone_data[zone_index - 1].mundt_zone_index == mundt_zone_index:
                for surf_num in range(1, state.dataMundtSimMgr.zone_data[zone_index - 1].num_of_surfs + 1):
                    surf_index = state.dataMundtSimMgr.zone_data[zone_index - 1].hb_surface_indexes[surf_num - 1]
                    state.dataMundtSimMgr.mundt_air_surf[surf_num - 1][mundt_zone_index - 1].area = \
                        state.dataSurface.Surface[surf_index - 1].Area

                room_nodes_count = 0
                floor_surf_count = 0
                air_node_begin_num = 1

                for node_num in range(1, state.dataRoomAir.TotNumOfZoneAirNodes[zone_index - 1] + 1):
                    state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].surf_mask = \
                        [False] * state.dataMundtSimMgr.zone_data[zone_index - 1].num_of_surfs

                    if node_num == 1:
                        air_node_begin_num = node_num

                    if air_node_begin_num > state.dataRoomAir.TotNumOfAirNodes:
                        ShowFatalError(state, "An array bound exceeded. Error in InitMundtModel subroutine of MundtSimMgr.")

                    air_node_found_flag = False
                    for air_node_num in range(air_node_begin_num, state.dataRoomAir.TotNumOfAirNodes + 1):
                        if Util.SameString(state.dataRoomAir.AirNode[air_node_num - 1].ZoneName, this_zone.Name):
                            state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].class_type = \
                                state.dataRoomAir.AirNode[air_node_num - 1].ClassType
                            state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].air_node_name = \
                                state.dataRoomAir.AirNode[air_node_num - 1].Name
                            state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].height = \
                                state.dataRoomAir.AirNode[air_node_num - 1].Height
                            state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].surf_mask = \
                                state.dataRoomAir.AirNode[air_node_num - 1].SurfMask

                            SetupOutputVariable(
                                state,
                                "Room Air Node Air Temperature",
                                "C",
                                state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].temp,
                                TimeStepType.System,
                                StoreType.Average,
                                state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].air_node_name
                            )

                            air_node_begin_num = air_node_num + 1
                            air_node_found_flag = True
                            break

                    if not air_node_found_flag:
                        ShowSevereError(state, f"InitMundtModel: Air Node in Zone=\"{this_zone.Name}\" is not found.")
                        errors_found = True
                        continue

                    if state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].class_type == AirNodeType.Mundt:
                        room_nodes_count += 1

                    if state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].class_type == AirNodeType.Floor:
                        floor_surf_count += sum(1 for x in state.dataMundtSimMgr.line_node[node_num - 1][mundt_zone_index - 1].surf_mask if x)

                max_num_of_room_nodes = max(max_num_of_room_nodes, room_nodes_count)
                max_num_of_floor_surfs = max(max_num_of_floor_surfs, floor_surf_count)

                if air_node_found_flag:
                    break

    if errors_found:
        ShowFatalError(state, "InitMundtModel: Preceding condition(s) cause termination.")

    state.dataMundtSimMgr.room_node_ids = [0] * max_num_of_room_nodes
    state.dataMundtSimMgr.floor_surf_set_ids = [0] * max_num_of_floor_surfs
    state.dataMundtSimMgr.floor_surf = [DefineSurfaceSettings() for _ in range(max_num_of_floor_surfs)]


def get_surf_hb_data_for_disp_vent_1_node(state: EnergyPlusDataProto, zone_num: int) -> None:
    from Psychrometrics import PsyCpAirFnW, PsyRhoAirFnPbTdbW, PsyWFnTdpPb
    from InternalHeatGains import zoneSumAllInternalConvectionGains, zoneSumAllReturnAirConvectionGains

    zone = state.dataHeatBal.Zone[zone_num - 1]
    zone_equip_config_num = zone_num

    if not zone.IsControlled:
        from UtilityRoutines import ShowFatalError
        ShowFatalError(state, f"Zones must be controlled for Mundt air model. No system serves zone {zone.Name}")
        return

    state.dataMundtSimMgr.zone_height = zone.CeilingHeight
    state.dataMundtSimMgr.zone_floor_area = zone.FloorArea
    zone_mult = zone.Multiplier * zone.ListMultiplier

    zone_node = zone.SystemZoneNodeNumber
    zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1]
    
    w_humidity = PsyWFnTdpPb(state, zone_hb.MAT, state.dataEnvrn.OutBaroPress)
    state.dataMundtSimMgr.zone_air_density = PsyRhoAirFnPbTdbW(
        state,
        state.dataEnvrn.OutBaroPress,
        zone_hb.MAT,
        w_humidity
    )
    
    zone_mass_flow_rate = state.dataLoopNodes.Node[zone_node - 1].MassFlowRate
    state.dataMundtSimMgr.supply_air_volume_rate = zone_mass_flow_rate / state.dataMundtSimMgr.zone_air_density

    if zone_mass_flow_rate <= 0.0001:
        state.dataMundtSimMgr.qsys_cool_tot = 0.0
    else:
        sum_sys_m_cp = 0.0
        sum_sys_m_cp_t = 0.0
        for node_num in range(1, state.dataZoneEquip.ZoneEquipConfig[zone_equip_config_num - 1].NumInletNodes + 1):
            inlet_node_index = state.dataZoneEquip.ZoneEquipConfig[zone_equip_config_num - 1].InletNode[node_num - 1]
            node_temp = state.dataLoopNodes.Node[inlet_node_index - 1].Temp
            mass_flow_rate = state.dataLoopNodes.Node[inlet_node_index - 1].MassFlowRate
            cp_air = PsyCpAirFnW(zone_hb.airHumRat)
            sum_sys_m_cp += mass_flow_rate * cp_air
            sum_sys_m_cp_t += mass_flow_rate * cp_air * node_temp

        if sum_sys_m_cp <= 0.0:
            inlet_node_index = state.dataZoneEquip.ZoneEquipConfig[zone_equip_config_num - 1].InletNode[0]
            state.dataMundtSimMgr.supply_air_temp = state.dataLoopNodes.Node[inlet_node_index - 1].Temp
        else:
            state.dataMundtSimMgr.supply_air_temp = sum_sys_m_cp_t / sum_sys_m_cp

        cp_air = PsyCpAirFnW(zone_hb.airHumRat)
        state.dataMundtSimMgr.qsys_cool_tot = -(
            sum_sys_m_cp_t - zone_mass_flow_rate * cp_air * zone_hb.MAT
        )

    state.dataMundtSimMgr.conv_int_gain = zoneSumAllInternalConvectionGains(state, zone_num)
    state.dataMundtSimMgr.conv_int_gain += (
        state.dataHeatBalFanSys.SumConvHTRadSys[zone_num - 1] +
        state.dataHeatBalFanSys.SumConvPool[zone_num - 1] +
        zone_hb.SysDepZoneLoadsLagged +
        zone_hb.NonAirSystemResponse / zone_mult
    )

    if zone.NoHeatToReturnAir:
        ret_air_conv_gain = zoneSumAllReturnAirConvectionGains(state, zone_num, 0)
        state.dataMundtSimMgr.conv_int_gain += ret_air_conv_gain

    state.dataMundtSimMgr.qvent_cool = -zone_hb.MCPI * (zone.OutDryBulbTemp - zone_hb.MAT)

    for surf_num in range(1, state.dataMundtSimMgr.zone_data[zone_num - 1].num_of_surfs + 1):
        hb_surface_index = state.dataMundtSimMgr.zone_data[zone_num - 1].hb_surface_indexes[surf_num - 1] - 1
        state.dataMundtSimMgr.mundt_air_surf[surf_num - 1][state.dataMundtSimMgr.mundt_zone_num - 1].temp = \
            state.dataHeatBalSurf.SurfTempIn[hb_surface_index]
        state.dataMundtSimMgr.mundt_air_surf[surf_num - 1][state.dataMundtSimMgr.mundt_zone_num - 1].hc = \
            state.dataHeatBalSurf.SurfHConvInt[hb_surface_index]


def setup_disp_vent_1_node(state: EnergyPlusDataProto, zone_num: int, errors_found: bool) -> None:
    from UtilityRoutines import ShowSevereError, ShowFatalError

    state.dataMundtSimMgr.num_room_nodes = 0

    for node_num in range(1, state.dataRoomAir.TotNumOfZoneAirNodes[zone_num - 1] + 1):
        class_type = state.dataMundtSimMgr.line_node[node_num - 1][state.dataMundtSimMgr.mundt_zone_num - 1].class_type

        if class_type == AirNodeType.Inlet:
            state.dataMundtSimMgr.supply_node_id = node_num
        elif class_type == AirNodeType.Floor:
            state.dataMundtSimMgr.mundt_foot_air_id = node_num
        elif class_type == AirNodeType.Control:
            state.dataMundtSimMgr.tstat_node_id = node_num
        elif class_type == AirNodeType.Ceiling:
            state.dataMundtSimMgr.mundt_ceil_air_id = node_num
        elif class_type == AirNodeType.Mundt:
            state.dataMundtSimMgr.num_room_nodes += 1
            state.dataMundtSimMgr.room_node_ids[state.dataMundtSimMgr.num_room_nodes - 1] = node_num
        elif class_type == AirNodeType.Return:
            state.dataMundtSimMgr.return_node_id = node_num
        else:
            ShowSevereError(state, "SetupMundtModel: Non-Standard Type of Air Node for Mundt Model")
            errors_found = True

    if state.dataMundtSimMgr.mundt_foot_air_id > 0:
        mask = state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.mundt_foot_air_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].surf_mask
        state.dataMundtSimMgr.num_floor_surfs = sum(1 for x in mask if x)
        state.dataMundtSimMgr.floor_surf_set_ids = [
            state.dataMundtSimMgr.id_1d_surf[i] for i in range(len(mask)) if mask[i]
        ]

        for e in state.dataMundtSimMgr.floor_surf:
            e.temp = 25.0
            e.hc = 0.0
            e.area = 0.0

        for surf_num in range(1, state.dataMundtSimMgr.num_floor_surfs + 1):
            floor_surf_id = state.dataMundtSimMgr.floor_surf_set_ids[surf_num - 1] - 1
            state.dataMundtSimMgr.floor_surf[surf_num - 1].temp = \
                state.dataMundtSimMgr.mundt_air_surf[floor_surf_id][state.dataMundtSimMgr.mundt_zone_num - 1].temp
            state.dataMundtSimMgr.floor_surf[surf_num - 1].hc = \
                state.dataMundtSimMgr.mundt_air_surf[floor_surf_id][state.dataMundtSimMgr.mundt_zone_num - 1].hc
            state.dataMundtSimMgr.floor_surf[surf_num - 1].area = \
                state.dataMundtSimMgr.mundt_air_surf[floor_surf_id][state.dataMundtSimMgr.mundt_zone_num - 1].area
    else:
        ShowSevereError(state, f"SetupMundtModel: Mundt model has no FloorAirNode, Zone={state.dataHeatBal.Zone[zone_num - 1].Name}")
        errors_found = True


def calc_disp_vent_1_node(state: EnergyPlusDataProto, zone_num: int) -> None:
    qequip_conv_floor = state.dataRoomAir.ConvectiveFloorSplit[zone_num - 1] * state.dataMundtSimMgr.conv_int_gain
    q_sens_infil_floor = -state.dataRoomAir.InfiltratFloorSplit[zone_num - 1] * state.dataMundtSimMgr.qvent_cool

    floor_sum_hat = 0.0
    floor_sum_ha = 0.0
    for s in state.dataMundtSimMgr.floor_surf:
        floor_sum_hat += s.area * s.hc * s.temp
        floor_sum_ha += s.area * s.hc

    t_air_foot = (
        (state.dataMundtSimMgr.zone_air_density * CP_AIR * state.dataMundtSimMgr.supply_air_volume_rate * state.dataMundtSimMgr.supply_air_temp) +
        floor_sum_hat + qequip_conv_floor + q_sens_infil_floor
    ) / (
        (state.dataMundtSimMgr.zone_air_density * CP_AIR * state.dataMundtSimMgr.supply_air_volume_rate) + floor_sum_ha
    )

    if state.dataMundtSimMgr.qsys_cool_tot <= 0.0:
        t_leaving = state.dataMundtSimMgr.supply_air_temp
    else:
        t_leaving = (
            (state.dataMundtSimMgr.qsys_cool_tot / (state.dataMundtSimMgr.zone_air_density * CP_AIR * state.dataMundtSimMgr.supply_air_volume_rate)) +
            state.dataMundtSimMgr.supply_air_temp
        )

    slope = (t_leaving - t_air_foot) / (
        state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.return_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height -
        state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.mundt_foot_air_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height
    )

    if slope > MAX_SLOPE:
        slope = MAX_SLOPE
        t_air_foot = t_leaving - (
            slope * (
                state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.return_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height -
                state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.mundt_foot_air_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height
            )
        )

    if slope < MIN_SLOPE:
        slope = MIN_SLOPE
        t_air_foot = t_leaving

    t_air_ceil = t_leaving - (
        slope * (
            state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.return_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height -
            state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.mundt_ceil_air_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height
        )
    )

    t_control_point = t_leaving - (
        slope * (
            state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.return_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height -
            state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.tstat_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height
        )
    )

    set_node_result(state, state.dataMundtSimMgr.supply_node_id, state.dataMundtSimMgr.supply_air_temp)
    set_node_result(state, state.dataMundtSimMgr.return_node_id, t_leaving)
    set_node_result(state, state.dataMundtSimMgr.mundt_ceil_air_id, t_air_ceil)
    set_node_result(state, state.dataMundtSimMgr.mundt_foot_air_id, t_air_foot)
    set_node_result(state, state.dataMundtSimMgr.tstat_node_id, t_control_point)

    for surf_num in range(1, state.dataMundtSimMgr.num_floor_surfs + 1):
        set_surf_tmean_air(state, state.dataMundtSimMgr.floor_surf_set_ids[surf_num - 1], t_air_foot)

    mask_ceil = state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.mundt_ceil_air_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].surf_mask
    surf_counted = sum(1 for x in mask_ceil if x)
    these_surf_ids_ceil = [state.dataMundtSimMgr.id_1d_surf[i] for i in range(len(mask_ceil)) if mask_ceil[i]]
    for surf_num in range(1, surf_counted + 1):
        set_surf_tmean_air(state, these_surf_ids_ceil[surf_num - 1], t_air_ceil)

    for node_num in range(1, state.dataMundtSimMgr.num_room_nodes + 1):
        t_this_node = t_leaving - (
            slope * (
                state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.return_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height -
                state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.room_node_ids[node_num - 1] - 1][state.dataMundtSimMgr.mundt_zone_num - 1].height
            )
        )
        set_node_result(state, state.dataMundtSimMgr.room_node_ids[node_num - 1], t_this_node)

        mask_room = state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.room_node_ids[node_num - 1] - 1][state.dataMundtSimMgr.mundt_zone_num - 1].surf_mask
        surf_counted = sum(1 for x in mask_room if x)
        these_surf_ids_room = [state.dataMundtSimMgr.id_1d_surf[i] for i in range(len(mask_room)) if mask_room[i]]
        for surf_num in range(1, surf_counted + 1):
            set_surf_tmean_air(state, these_surf_ids_room[surf_num - 1], t_this_node)


def set_node_result(state: EnergyPlusDataProto, node_id: int, temp_result: float) -> None:
    state.dataMundtSimMgr.line_node[node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].temp = temp_result


def set_surf_tmean_air(state: EnergyPlusDataProto, surf_id: int, teff_air: float) -> None:
    state.dataMundtSimMgr.mundt_air_surf[surf_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].t_mean_air = teff_air


def set_surf_hb_data_for_disp_vent_1_node(state: EnergyPlusDataProto, zone_num: int) -> None:
    num_of_surfs = state.dataMundtSimMgr.zone_data[zone_num - 1].num_of_surfs

    if state.dataMundtSimMgr.supply_air_volume_rate > 0.0001 and state.dataMundtSimMgr.qsys_cool_tot > 0.0001:
        if state.dataRoomAir.AirModel[zone_num - 1].TempCoupleScheme == "Direct":
            for surf_num in range(1, num_of_surfs + 1):
                hb_surf_num = state.dataMundtSimMgr.zone_data[zone_num - 1].hb_surface_indexes[surf_num - 1] - 1
                state.dataHeatBal.SurfTempEffBulkAir[hb_surf_num] = \
                    state.dataMundtSimMgr.mundt_air_surf[surf_num - 1][state.dataMundtSimMgr.mundt_zone_num - 1].t_mean_air
                state.dataSurface.SurfTAirRef[hb_surf_num] = "AdjacentAirTemp"
                state.dataSurface.SurfTAirRefRpt[hb_surf_num] = "AdjacentAirTemp"

            zone_node_num = state.dataHeatBal.Zone[zone_num - 1].SystemZoneNodeNumber - 1
            state.dataLoopNodes.Node[zone_node_num].Temp = \
                state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.return_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].temp
            state.dataHeatBalFanSys.TempTstatAir[zone_num - 1] = \
                state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.tstat_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].temp
        else:
            for surf_num in range(1, num_of_surfs + 1):
                hb_surf_num = state.dataMundtSimMgr.zone_data[zone_num - 1].hb_surface_indexes[surf_num - 1] - 1
                delta_temp = (
                    state.dataMundtSimMgr.mundt_air_surf[surf_num - 1][state.dataMundtSimMgr.mundt_zone_num - 1].t_mean_air -
                    state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.tstat_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].temp
                )
                state.dataHeatBal.SurfTempEffBulkAir[hb_surf_num] = \
                    state.dataHeatBalFanSys.zoneTstatSetpts[zone_num - 1].setpt + delta_temp
                state.dataSurface.SurfTAirRef[hb_surf_num] = "AdjacentAirTemp"
                state.dataSurface.SurfTAirRefRpt[hb_surf_num] = "AdjacentAirTemp"

            zone_node_num = state.dataHeatBal.Zone[zone_num - 1].SystemZoneNodeNumber - 1
            delta_temp = (
                state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.return_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].temp -
                state.dataMundtSimMgr.line_node[state.dataMundtSimMgr.tstat_node_id - 1][state.dataMundtSimMgr.mundt_zone_num - 1].temp
            )
            state.dataLoopNodes.Node[zone_node_num].Temp = \
                state.dataHeatBalFanSys.zoneTstatSetpts[zone_num - 1].setpt + delta_temp
            state.dataHeatBalFanSys.TempTstatAir[zone_num - 1] = \
                state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].ZT

        state.dataRoomAir.AirModel[zone_num - 1].SimAirModel = True
    else:
        for surf_num in range(1, num_of_surfs + 1):
            hb_surf_num = state.dataMundtSimMgr.zone_data[zone_num - 1].hb_surface_indexes[surf_num - 1] - 1
            state.dataHeatBal.SurfTempEffBulkAir[hb_surf_num] = \
                state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].MAT
            state.dataSurface.SurfTAirRef[hb_surf_num] = "ZoneMeanAirTemp"
            state.dataSurface.SurfTAirRefRpt[hb_surf_num] = "ZoneMeanAirTemp"

        state.dataRoomAir.AirModel[zone_num - 1].SimAirModel = False
