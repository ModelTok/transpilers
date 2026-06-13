import math
from utils.list import List
from sys.info import num_physical_cores

alias REAL64 = Float64
alias INT32 = Int32
alias CPAIR = REAL64(1005.0)
alias MIN_SLOPE = REAL64(0.001)
alias MAX_SLOPE = REAL64(5.0)

struct AirNodeType:
    var invalid: Int32 = 0
    var inlet: Int32 = 1
    var floor: Int32 = 2
    var control: Int32 = 3
    var ceiling: Int32 = 4
    var mundt: Int32 = 5
    var return_: Int32 = 6

struct DefineLinearModelNode:
    var air_node_name: String
    var class_type: Int32
    var height: REAL64
    var temp: REAL64
    var surf_mask: List[Bool]

    fn __init__(inout self) -> None:
        self.air_node_name = ""
        self.class_type = 0
        self.height = 0.0
        self.temp = 0.0
        self.surf_mask = List[Bool]()

    fn __init__(inout self, name: String, ctype: Int32, h: REAL64, t: REAL64) -> None:
        self.air_node_name = name
        self.class_type = ctype
        self.height = h
        self.temp = t
        self.surf_mask = List[Bool]()


struct DefineSurfaceSettings:
    var area: REAL64
    var temp: REAL64
    var hc: REAL64
    var t_mean_air: REAL64

    fn __init__(inout self) -> None:
        self.area = 0.0
        self.temp = 0.0
        self.hc = 0.0
        self.t_mean_air = 0.0


struct DefineZoneData:
    var num_of_surfs: Int32
    var mundt_zone_index: Int32
    var hb_surface_indexes: List[Int32]

    fn __init__(inout self) -> None:
        self.num_of_surfs = 0
        self.mundt_zone_index = 0
        self.hb_surface_indexes = List[Int32]()


struct MundtSimMgrData:
    var floor_surf_set_ids: List[Int32]
    var these_surf_ids: List[Int32]
    var mundt_ceil_air_id: Int32
    var mundt_foot_air_id: Int32
    var supply_node_id: Int32
    var tstat_node_id: Int32
    var return_node_id: Int32
    var num_room_nodes: Int32
    var num_floor_surfs: Int32
    var room_node_ids: List[Int32]
    var id_1d_surf: List[Int32]
    var mundt_zone_num: Int32
    var zone_height: REAL64
    var zone_floor_area: REAL64
    var qvent_cool: REAL64
    var conv_int_gain: REAL64
    var supply_air_temp: REAL64
    var supply_air_volume_rate: REAL64
    var zone_air_density: REAL64
    var qsys_cool_tot: REAL64
    var zone_data: List[DefineZoneData]
    var line_node: List[List[DefineLinearModelNode]]
    var mundt_air_surf: List[List[DefineSurfaceSettings]]
    var floor_surf: List[DefineSurfaceSettings]

    fn __init__(inout self) -> None:
        self.floor_surf_set_ids = List[Int32]()
        self.these_surf_ids = List[Int32]()
        self.mundt_ceil_air_id = 0
        self.mundt_foot_air_id = 0
        self.supply_node_id = 0
        self.tstat_node_id = 0
        self.return_node_id = 0
        self.num_room_nodes = 0
        self.num_floor_surfs = 0
        self.room_node_ids = List[Int32]()
        self.id_1d_surf = List[Int32]()
        self.mundt_zone_num = 0
        self.zone_height = 0.0
        self.zone_floor_area = 0.0
        self.qvent_cool = 0.0
        self.conv_int_gain = 0.0
        self.supply_air_temp = 0.0
        self.supply_air_volume_rate = 0.0
        self.zone_air_density = 0.0
        self.qsys_cool_tot = 0.0
        self.zone_data = List[DefineZoneData]()
        self.line_node = List[List[DefineLinearModelNode]]()
        self.mundt_air_surf = List[List[DefineSurfaceSettings]]()
        self.floor_surf = List[DefineSurfaceSettings]()

    fn clear_state(inout self) -> None:
        self.floor_surf_set_ids = List[Int32]()
        self.these_surf_ids = List[Int32]()
        self.mundt_ceil_air_id = 0
        self.mundt_foot_air_id = 0
        self.supply_node_id = 0
        self.tstat_node_id = 0
        self.return_node_id = 0
        self.num_room_nodes = 0
        self.num_floor_surfs = 0
        self.room_node_ids = List[Int32]()
        self.id_1d_surf = List[Int32]()
        self.mundt_zone_num = 0
        self.zone_height = 0.0
        self.zone_floor_area = 0.0
        self.qvent_cool = 0.0
        self.conv_int_gain = 0.0
        self.supply_air_temp = 0.0
        self.supply_air_volume_rate = 0.0
        self.zone_air_density = 0.0
        self.qsys_cool_tot = 0.0
        self.zone_data = List[DefineZoneData]()
        self.line_node = List[List[DefineLinearModelNode]]()
        self.mundt_air_surf = List[List[DefineSurfaceSettings]]()
        self.floor_surf = List[DefineSurfaceSettings]()


trait EnergyPlusDataProto:
    fn get_num_of_zones(self) -> Int32:
        ...
    fn get_out_dry_bulb_temp(self) -> REAL64:
        ...
    fn get_out_baro_press(self) -> REAL64:
        ...


fn manage_disp_vent_1_node(inout state: EnergyPlusDataProto, zone_num: Int32) -> None:
    if state.get_num_of_zones() >= 1:
        pass


fn init_disp_vent_1_node(inout state: EnergyPlusDataProto) -> None:
    pass


fn get_surf_hb_data_for_disp_vent_1_node(inout state: EnergyPlusDataProto, zone_num: Int32) -> None:
    pass


fn setup_disp_vent_1_node(inout state: EnergyPlusDataProto, zone_num: Int32, inout errors_found: Bool) -> None:
    pass


fn calc_disp_vent_1_node(inout state: EnergyPlusDataProto, zone_num: Int32) -> None:
    pass


fn set_node_result(inout state: EnergyPlusDataProto, node_id: Int32, temp_result: REAL64) -> None:
    pass


fn set_surf_tmean_air(inout state: EnergyPlusDataProto, surf_id: Int32, teff_air: REAL64) -> None:
    pass


fn set_surf_hb_data_for_disp_vent_1_node(inout state: EnergyPlusDataProto, zone_num: Int32) -> None:
    pass
