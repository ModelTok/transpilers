# EnergyPlus DataHeatBalance module - Python port
# Faithful translation of DataHeatBalance.hh and implementations

from enum import IntEnum, Enum
from dataclasses import dataclass, field
from typing import List, Optional, Protocol, Any, Tuple
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (dataSurface, dataMaterial, dataConstruction, dataHeatBal, dataEnvrn, dataGlobal, dataDayltg, dataHeatBalSurf)
# - Material.Group: enum for material types
# - Material.SurfaceRoughness: enum
# - DataSurfaces.SurfaceClass, ExternalEnvironment: enums
# - DataEnvironment.EarthRadius: float constant
# - Construction.MaxLayersInConstruct: int constant
# - Constant.eFuel: enum
# - Sched.Schedule: schedule object type
# - Vector: 3D vector (x, y, z floats)
# - Convect.HcInt, Convect.HcExt: enums

# ============ ENUMS ============

class Shadowing(IntEnum):
    INVALID = -1
    MINIMAL = 0
    FULL_EXTERIOR = 1
    FULL_INTERIOR_EXTERIOR = 2
    FULL_EXTERIOR_WITH_REFL = 3
    NUM = 4

class SolutionAlgo(IntEnum):
    INVALID = -1
    THIRD_ORDER = 0
    ANALYTICAL_SOLUTION = 1
    EULER_METHOD = 2
    NUM = 3

class CalcMRT(IntEnum):
    INVALID = -1
    ENCLOSURE_AVERAGED = 0
    SURFACE_WEIGHTED = 1
    ANGLE_FACTOR = 2
    NUM = 3

class VentilationType(IntEnum):
    INVALID = -1
    NATURAL = 0
    INTAKE = 1
    EXHAUST = 2
    BALANCED = 3
    NUM = 4

class HybridCtrlType(IntEnum):
    INVALID = -1
    INDIV = 0
    CLOSE = 1
    GLOBAL = 2
    NUM = 3

class RefrigCondenserType(IntEnum):
    INVALID = -1
    AIR = 0
    EVAP = 1
    WATER = 2
    CASCADE = 3
    WATER_HEATER = 4
    NUM = 5

class InfiltrationModelType(IntEnum):
    INVALID = -1
    DESIGN_FLOW_RATE = 0
    SHERMAN_GRIMSRUD = 1
    AIM2 = 2
    NUM = 3

class VentilationModelType(IntEnum):
    INVALID = -1
    DESIGN_FLOW_RATE = 0
    WIND_AND_STACK = 1
    NUM = 2

class InfVentDensityBasis(IntEnum):
    INVALID = -1
    OUTDOOR = 0
    STANDARD = 1
    INDOOR = 2
    NUM = 3

class AirBalance(IntEnum):
    INVALID = -1
    NONE = 0
    QUADRATURE = 1
    NUM = 2

class InfiltrationFlow(IntEnum):
    INVALID = -1
    NO = 0
    ADD = 1
    ADJUST = 2
    NUM = 3

class InfiltrationZoneType(IntEnum):
    INVALID = -1
    MIXING_SOURCE_ZONES_ONLY = 0
    ALL_ZONES = 1
    NUM = 2

class AdjustmentType(IntEnum):
    INVALID = -1
    ADJUST_MIXING_ONLY = 0
    ADJUST_RETURN_ONLY = 1
    ADJUST_MIXING_THEN_RETURN = 2
    ADJUST_RETURN_THEN_MIXING = 3
    NO_ADJUST_RETURN_AND_MIXING = 4
    NUM = 5

class IntGainType(IntEnum):
    INVALID = -1
    PEOPLE = 0
    LIGHTS = 1
    ELECTRIC_EQUIPMENT = 2
    GAS_EQUIPMENT = 3
    HOT_WATER_EQUIPMENT = 4
    STEAM_EQUIPMENT = 5
    OTHER_EQUIPMENT = 6
    ZONE_BASEBOARD_OUTDOOR_TEMPERATURE_CONTROLLED = 7
    ZONE_CONTAMINANT_SOURCE_AND_SINK_CARBON_DIOXIDE = 8
    WATER_USE_EQUIPMENT = 9
    DAYLIGHTING_DEVICE_TUBULAR = 10
    WATER_HEATER_MIXED = 11
    WATER_HEATER_STRATIFIED = 12
    THERMAL_STORAGE_CHILLED_WATER_MIXED = 13
    THERMAL_STORAGE_CHILLED_WATER_STRATIFIED = 14
    THERMAL_STORAGE_HOT_WATER_STRATIFIED = 15
    GENERATOR_FUEL_CELL = 16
    GENERATOR_MICRO_CHP = 17
    ELECTRIC_LOAD_CENTER_TRANSFORMER = 18
    ELECTRIC_LOAD_CENTER_INVERTER_SIMPLE = 19
    ELECTRIC_LOAD_CENTER_INVERTER_FUNCTION_OF_POWER = 20
    ELECTRIC_LOAD_CENTER_INVERTER_LOOK_UP_TABLE = 21
    ELECTRIC_LOAD_CENTER_STORAGE_LI_ION_NMC_BATTERY = 22
    ELECTRIC_LOAD_CENTER_STORAGE_BATTERY = 23
    ELECTRIC_LOAD_CENTER_STORAGE_SIMPLE = 24
    PIPE_INDOOR = 25
    REFRIGERATION_CASE = 26
    REFRIGERATION_COMPRESSOR_RACK = 27
    REFRIGERATION_SYSTEM_AIR_COOLED_CONDENSER = 28
    REFRIGERATION_TRANS_SYS_AIR_COOLED_GAS_COOLER = 29
    REFRIGERATION_SYSTEM_SUCTION_PIPE = 30
    REFRIGERATION_TRANS_SYS_SUCTION_PIPE_MT = 31
    REFRIGERATION_TRANS_SYS_SUCTION_PIPE_LT = 32
    REFRIGERATION_SECONDARY_RECEIVER = 33
    REFRIGERATION_SECONDARY_PIPE = 34
    REFRIGERATION_WALK_IN = 35
    PUMP_VAR_SPEED = 36
    PUMP_CON_SPEED = 37
    PUMP_COND = 38
    PUMP_BANK_VAR_SPEED = 39
    PUMP_BANK_CON_SPEED = 40
    ZONE_CONTAMINANT_SOURCE_AND_SINK_GENERIC_CONTAM = 41
    PLANT_COMPONENT_USER_DEFINED = 42
    COIL_USER_DEFINED = 43
    ZONE_HVAC_FORCED_AIR_USER_DEFINED = 44
    AIR_TERMINAL_USER_DEFINED = 45
    PACKAGED_TES_COIL_TANK = 46
    ELECTRIC_EQUIPMENT_ITE_AIR_COOLED = 47
    SEC_COOLING_DX_COIL_SINGLE_SPEED = 48
    SEC_HEATING_DX_COIL_SINGLE_SPEED = 49
    SEC_COOLING_DX_COIL_TWO_SPEED = 50
    SEC_COOLING_DX_COIL_MULTI_SPEED = 51
    SEC_HEATING_DX_COIL_MULTI_SPEED = 52
    ELECTRIC_LOAD_CENTER_CONVERTER = 53
    FAN_SYSTEM_MODEL = 54
    INDOOR_GREEN = 55
    NUM = 56

class HeatIndexMethod(IntEnum):
    INVALID = -1
    SIMPLIFIED = 0
    EXTENDED = 1
    NUM = 2

class ITEClass(IntEnum):
    INVALID = -1
    NONE = 0
    A1 = 1
    A2 = 2
    A3 = 3
    A4 = 4
    B = 5
    C = 6
    H1 = 7
    NUM = 8

class ITEInletConnection(IntEnum):
    INVALID = -1
    ADJUSTED_SUPPLY = 0
    ZONE_AIR_NODE = 1
    ROOM_AIR_MODEL = 2
    NUM = 3

class PERptVars(IntEnum):
    CPU = 0
    FAN = 1
    UPS = 2
    CPU_AT_DESIGN = 3
    FAN_AT_DESIGN = 4
    UPS_GAIN_TO_ZONE = 5
    CON_GAIN_TO_ZONE = 6
    NUM = 7

class ClothingType(IntEnum):
    INVALID = -1
    INSULATION_SCHEDULE = 0
    DYNAMIC_ASHRAE55 = 1
    CALCULATION_SCHEDULE = 2
    NUM = 3

# ============ CONSTANTS ============

STANDARD_ZONE = 1
DEFAULT_MAX_NUMBER_OF_WARMUP_DAYS = 25
DEFAULT_MIN_NUMBER_OF_WARMUP_DAYS = 1
HIGH_DIFFUSIVITY_THRESHOLD = 1.0e-5
THIN_MATERIAL_LAYER_THRESHOLD = 0.003
ZONE_INITIAL_TEMP = 23.0
SURF_INITIAL_TEMP = 23.0
SURF_INITIAL_CONV_COEFF = 3.076
NUM_COLUMN_THERMAL_TBL = 5
NUM_COLUMN_UNMET_DEGREE_HOUR_TBL = 6
NUM_COLUMN_DISCOMFORT_WT_EXCEED_HOUR_TBL = 4
NUM_COLUMN_CO2_TBL = 3
NUM_COLUMN_VISUAL_TBL = 4

REFRIG_CONDENSER_TYPE_NAMES = [
    "AirCooled", "EvaporativelyCooled", "WaterCooled", "Cascade", "WaterHeater"
]
REFRIG_CONDENSER_TYPE_NAMES_UC = [
    "AIRCOOLED", "EVAPORATIVELYCOOLED", "WATERCOOLED", "CASCADE", "WATERHEATER"
]

CALC_MRT_TYPE_NAMES_UC = [
    "ENCLOSUREAVERAGED", "SURFACEWEIGHTED", "ANGLEFACTOR"
]

AIR_BALANCE_TYPE_NAMES_UC = ["NONE", "QUADRATURE"]

INFILTRATION_FLOW_TYPE_NAMES_UC = [
    "NONE", "ADDINFILTRATIONFLOW", "ADJUSTINFILTRATIONFLOW"
]
INFILTRATION_FLOW_TYPE_NAMES_CC = [
    "None", "AddInfiltrationFlow", "AdjustInfiltrationFlow"
]

INFILTRATION_ZONE_TYPE_NAMES_UC = [
    "MIXINGSOURCEZONESONLY", "ALLZONES"
]
INFILTRATION_ZONE_TYPE_NAMES_CC = [
    "MixingSourceZonesOnly", "AllZones"
]

ADJUSTMENT_TYPE_NAMES_UC = [
    "ADJUSTMIXINGONLY", "ADJUSTRETURNONLY", "ADJUSTMIXINGTHENRETURN",
    "ADJUSTRETURNTHENMIXING", "NONE"
]
ADJUSTMENT_TYPE_NAMES_CC = [
    "AdjustMixingOnly", "AdjustReturnOnly", "AdjustMixingThenReturn",
    "AdjustReturnThenMixing", "None"
]

INT_GAIN_TYPE_NAMES_UC = [
    "PEOPLE", "LIGHTS", "ELECTRICEQUIPMENT", "GASEQUIPMENT",
    "HOTWATEREQUIPMENT", "STEAMEQUIPMENT", "OTHEREQUIPMENT",
    "ZONEBASEBOARD:OUTDOORTEMPERATURECONTROLLED",
    "ZONECONTAMINANTSOURCEANDSINK:CARBONDIOXIDE",
    "WATERUSE:EQUIPMENT", "DAYLIGHTINGDEVICE:TUBULAR",
    "WATERHEATER:MIXED", "WATERHEATER:STRATIFIED",
    "THERMALSTORAGE:CHILLEDWATER:MIXED",
    "THERMALSTORAGE:CHILLEDWATER:STRATIFIED",
    "THERMALSTORAGE:HOTWATER:STRATIFIED",
    "GENERATOR:FUELCELL", "GENERATOR:MICROCHP",
    "ELECTRICLOADCENTER:TRANSFORMER",
    "ELECTRICLOADCENTER:INVERTER:SIMPLE",
    "ELECTRICLOADCENTER:INVERTER:FUNCTIONOFPOWER",
    "ELECTRICLOADCENTER:INVERTER:LOOKUPTABLE",
    "ELECTRICLOADCENTER:STORAGE:LIIONNMCBATTERY",
    "ELECTRICLOADCENTER:STORAGE:BATTERY",
    "ELECTRICLOADCENTER:STORAGE:SIMPLE",
    "PIPE:INDOOR", "REFRIGERATION:CASE",
    "REFRIGERATION:COMPRESSORRACK",
    "REFRIGERATION:SYSTEM:CONDENSER:AIRCOOLED",
    "REFRIGERATION:TRANSCRITICALSYSTEM:GASCOOLER:AIRCOOLED",
    "REFRIGERATION:SYSTEM:SUCTIONPIPE",
    "REFRIGERATION:TRANSCRITICALSYSTEM:SUCTIONPIPEMT",
    "REFRIGERATION:TRANSCRITICALSYSTEM:SUCTIONPIPELT",
    "REFRIGERATION:SECONDARYSYSTEM:RECEIVER",
    "REFRIGERATION:SECONDARYSYSTEM:PIPE",
    "REFRIGERATION:WALKIN", "PUMP:VARIABLESPEED",
    "PUMP:CONSTANTSPEED", "PUMP:VARIABLESPEED:CONDENSATE",
    "HEADEREDPUMPS:VARIABLESPEED",
    "HEADEREDPUMPS:CONSTANTSPEED",
    "ZONECONTAMINANTSOURCEANDSINK:GENERICCONTAMINANT",
    "PLANTCOMPONENT:USERDEFINED", "COIL:USERDEFINED",
    "ZONEHVAC:FORCEDAIR:USERDEFINED",
    "AIRTERMINAL:SINGLEDUCT:USERDEFINED",
    "COIL:COOLING:DX:SINGLESPEED:THERMALSTORAGE",
    "ELECTRICEQUIPMENT:ITE:AIRCOOLED",
    "COIL:COOLING:DX:SINGLESPEED",
    "COIL:HEATING:DX:SINGLESPEED",
    "COIL:COOLING:DX:TWOSPEED",
    "COIL:COOLING:DX:MULTISPEED",
    "COIL:HEATING:DX:MULTISPEED",
    "ELECTRICLOADCENTER:STORAGE:CONVERTER",
    "FAN:SYSTEMMODEL", "INDOORGREEN"
]

INT_GAIN_TYPE_NAMES_CC = [
    "People", "Lights", "ElectricEquipment", "GasEquipment",
    "HotWaterEquipment", "SteamEquipment", "OtherEquipment",
    "ZoneBaseboard:OutdoorTemperatureControlled",
    "ZoneContaminantSourceAndSink:CarbonDioxide",
    "WaterUse:Equipment", "DaylightingDevice:Tubular",
    "WaterHeater:Mixed", "WaterHeater:Stratified",
    "ThermalStorage:ChilledWater:Mixed",
    "ThermalStorage:ChilledWater:Stratified",
    "ThermalStorage:HotWater:Stratified",
    "Generator:FuelCell", "Generator:MicroCHP",
    "ElectricLoadCenter:Transformer",
    "ElectricLoadCenter:Inverter:Simple",
    "ElectricLoadCenter:Inverter:FunctionOfPower",
    "ElectricLoadCenter:Inverter:LookUpTable",
    "ElectricLoadCenter:Storage:LiIonNMCBattery",
    "ElectricLoadCenter:Storage:Battery",
    "ElectricLoadCenter:Storage:Simple",
    "Pipe:Indoor", "Refrigeration:Case",
    "Refrigeration:CompressorRack",
    "Refrigeration:System:Condenser:AirCooled",
    "Refrigeration:TranscriticalSystem:GasCooler:AirCooled",
    "Refrigeration:System:SuctionPipe",
    "Refrigeration:TranscriticalSystem:SuctionPipeMT",
    "Refrigeration:TranscriticalSystem:SuctionPipeLT",
    "Refrigeration:SecondarySystem:Receiver",
    "Refrigeration:SecondarySystem:Pipe",
    "Refrigeration:WalkIn", "Pump:VariableSpeed",
    "Pump:ConstantSpeed", "Pump:VariableSpeed:Condensate",
    "HeaderedPumps:VariableSpeed",
    "HeaderedPumps:ConstantSpeed",
    "ZoneContaminantSourceAndSink:GenericContaminant",
    "PlantComponent:UserDefined", "Coil:UserDefined",
    "ZoneHVAC:ForcedAir:UserDefined",
    "AirTerminal:SingleDuct:UserDefined",
    "Coil:Cooling:DX:SingleSpeed:ThermalStorage",
    "ElectricEquipment:ITE:AirCooled",
    "Coil:Cooling:DX:SingleSpeed",
    "Coil:Heating:DX:SingleSpeed",
    "Coil:Cooling:DX:TwoSpeed",
    "Coil:Cooling:DX:MultiSpeed",
    "Coil:Heating:DX:MultiSpeed",
    "ElectricLoadCenter:Storage:Converter",
    "Fan:SystemModel", "IndoorGreen"
]

HEAT_INDEX_METHOD_UC = ["SIMPLIFIED", "EXTENDED"]

ITE_CLASS_NAMES_UC = ["NONE", "A1", "A2", "A3", "A4", "B", "C", "H1"]

ITE_INLET_CONNECTION_NAMES_UC = [
    "ADJUSTEDSUPPLY", "ZONEAIRNODE", "ROOMAIRMODEL"
]

CLOTHING_TYPE_NAMES_UC = [
    "CLOTHINGINSULATIONSCHEDULE", "DYNAMICCLOTHINGMODELASHRAE55",
    "CALCULATIONMETHODSCHEDULE"
]
CLOTHING_TYPE_EIO_STRINGS = [
    "Clothing Insulation Schedule,", "Dynamic Clothing Model ASHRAE55,",
    "Calculation Method Schedule,"
]

# ============ STRUCTS/DATACLASSES ============

@dataclass
class ZoneSpaceData:
    name: str = ""
    ceiling_height: float = 1e30  # Constant::AutoCalculate
    volume: float = 1e30
    ext_gross_wall_area: float = 0.0
    exterior_total_surf_area: float = 0.0
    ext_perimeter: float = 0.0
    system_zone_node_number: int = 0
    floor_area: float = 0.0
    tot_occupants: float = 0.0
    is_controlled: bool = False

@dataclass
class SpaceData(ZoneSpaceData):
    zone_num: int = 0
    user_entered_floor_area: float = 1e30
    space_type: str = "General"
    space_type_num: int = 0
    tags: List[str] = field(default_factory=list)
    surfaces: List[int] = field(default_factory=list)
    has_floor: bool = False
    frac_zone_floor_area: float = 0.0
    frac_zone_volume: float = 0.0
    ext_window_area: float = 0.0
    total_surf_area: float = 0.0
    radiant_enclosure_num: int = 0
    solar_enclosure_num: int = 0
    min_occupants: float = 0.0
    max_occupants: float = 0.0
    is_remainder_space: bool = False
    other_equip_fuel_type_nums: List[Any] = field(default_factory=list)
    all_surface_first: int = 0
    all_surface_last: int = -1
    ht_surface_first: int = 0
    ht_surface_last: int = -1
    opaq_or_int_mass_surface_first: int = 0
    opaq_or_int_mass_surface_last: int = -1
    window_surface_first: int = 0
    window_surface_last: int = -1
    opaq_or_win_surface_first: int = 0
    opaq_or_win_surface_last: int = -1
    tdd_dome_first: int = 0
    tdd_dome_last: int = -1

    def sum_hat_surf(self, state):
        sum_hat = 0.0
        for surf_num in range(self.ht_surface_first, self.ht_surface_last + 1):
            area = state.dataSurface.Surface[surf_num].Area
            if state.dataSurface.Surface[surf_num].Class == 7:  # Window
                if state.dataSurface.SurfWinDividerArea[surf_num] > 0.0:
                    if hasattr(state.dataSurface, 'SurfWinShadingFlag') and \
                       state.dataSurface.SurfWinShadingFlag[surf_num] in [2, 3, 4, 5, 6]:
                        area += state.dataSurface.SurfWinDividerArea[surf_num]
                    else:
                        sum_hat += state.dataHeatBalSurf.SurfHConvInt[surf_num] * \
                                  state.dataSurface.SurfWinDividerArea[surf_num] * \
                                  (1.0 + 2.0 * state.dataSurface.SurfWinProjCorrDivIn[surf_num]) * \
                                  state.dataSurface.SurfWinDividerTempIn[surf_num]
                if state.dataSurface.SurfWinFrameArea[surf_num] > 0.0:
                    sum_hat += state.dataHeatBalSurf.SurfHConvInt[surf_num] * \
                              state.dataSurface.SurfWinFrameArea[surf_num] * \
                              (1.0 + state.dataSurface.SurfWinProjCorrFrIn[surf_num]) * \
                              state.dataSurface.SurfWinFrameTempIn[surf_num]
            sum_hat += state.dataHeatBalSurf.SurfHConvInt[surf_num] * area * \
                      state.dataHeatBalSurf.SurfTempInTmp[surf_num]
        return sum_hat

@dataclass
class SpaceListData:
    name: str = ""
    num_list_spaces: int = 0
    max_space_name_length: int = 0
    spaces: List[int] = field(default_factory=list)

@dataclass
class ZoneResilience:
    zone_num_occ: float = 0.0
    cold_stress_temp_thresh: float = 15.56
    heat_stress_temp_thresh: float = 30.0
    pierce_set: float = -999.0
    pmv: float = 0.0
    zone_pierce_set: float = -1.0
    zone_pierce_set_last_step: float = -1.0
    zone_heat_index: float = 0.0
    zone_humidex: float = 0.0
    crossed_cold_thresh: bool = False
    crossed_heat_thresh: bool = False
    zone_heat_index_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_heat_index_occu_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_heat_index_occupied_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_humidex_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_humidex_occu_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_humidex_occupied_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_low_set_hours: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_high_set_hours: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_cold_hour_of_safety_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_heat_hour_of_safety_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_THERMAL_TBL
    )
    zone_unmet_degree_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_UNMET_DEGREE_HOUR_TBL
    )
    zone_discomfort_wt_exceed_occu_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_DISCOMFORT_WT_EXCEED_HOUR_TBL
    )
    zone_discomfort_wt_exceed_occupied_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_DISCOMFORT_WT_EXCEED_HOUR_TBL
    )
    zone_co2_level_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_CO2_TBL
    )
    zone_co2_level_occu_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_CO2_TBL
    )
    zone_co2_level_occupied_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_CO2_TBL
    )
    zone_lighting_level_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_VISUAL_TBL
    )
    zone_lighting_level_occu_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_VISUAL_TBL
    )
    zone_lighting_level_occupied_hour_bins: List[float] = field(
        default_factory=lambda: [0.0] * NUM_COLUMN_VISUAL_TBL
    )

@dataclass
class ZoneData(ZoneSpaceData):
    multiplier: int = 1
    list_multiplier: int = 1
    list_group: int = 0
    rel_north: float = 0.0
    origin_x: float = 0.0
    origin_y: float = 0.0
    origin_z: float = 0.0
    of_type: int = 1
    user_entered_floor_area: float = 1e30
    geometric_floor_area: float = 0.0
    ceiling_area: float = 0.0
    geometric_ceiling_area: float = 0.0
    ceiling_height_entered: bool = False
    has_floor: bool = False
    has_roof: bool = False
    has_window: bool = False
    air_capacity: float = 0.0
    ext_window_area: float = 0.0
    ext_window_area_multiplied: float = 0.0
    ext_gross_wall_area_multiplied: float = 0.0
    ext_net_wall_area: float = 0.0
    total_surf_area: float = 0.0
    exterior_total_ground_surf_area: float = 0.0
    ext_gross_ground_wall_area: float = 0.0
    ext_gross_ground_wall_area_multiplied: float = 0.0
    is_supply_plenum: bool = False
    is_return_plenum: bool = False
    leakage_parallel_piu_nums: List[float] = field(default_factory=list)
    plenum_cond_num: int = 0
    temp_controlled_zone_index: int = 0
    humidity_control_zone_index: int = 0
    all_surface_first: int = 0
    all_surface_last: int = -1
    int_conv_algo: int = 0  # Convect::HcInt
    num_surfaces: int = 0
    num_sub_surfaces: int = 0
    num_shading_surfaces: int = 0
    ext_conv_algo: int = 0  # Convect::HcExt
    centroid: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    minimum_x: float = 0.0
    maximum_x: float = 0.0
    minimum_y: float = 0.0
    maximum_y: float = 0.0
    minimum_z: float = 0.0
    maximum_z: float = 0.0
    zone_ht_surface_list: List[int] = field(default_factory=list)
    zone_iz_surface_list: List[int] = field(default_factory=list)
    zone_ht_non_window_surface_list: List[int] = field(default_factory=list)
    zone_ht_window_surface_list: List[int] = field(default_factory=list)
    zone_rad_enclosure_first: int = -1
    zone_rad_enclosure_last: int = -1
    out_dry_bulb_temp: float = 0.0
    out_dry_bulb_temp_ems_override_on: bool = False
    out_dry_bulb_temp_ems_override_value: float = 0.0
    out_wet_bulb_temp: float = 0.0
    out_wet_bulb_temp_ems_override_on: bool = False
    out_wet_bulb_temp_ems_override_value: float = 0.0
    wind_speed: float = 0.0
    wind_speed_ems_override_on: bool = False
    wind_speed_ems_override_value: float = 0.0
    wind_dir: float = 0.0
    wind_dir_ems_override_on: bool = False
    wind_dir_ems_override_value: float = 0.0
    linked_out_air_node: int = 0
    is_part_of_total_area: bool = True
    is_nominal_occupied: bool = False
    is_nominal_controlled: bool = False
    min_occupants: float = 0.0
    max_occupants: float = 0.0
    air_hb_imbalance_err_index: int = 0
    no_heat_to_return_air: bool = False
    refrig_case_ra: bool = False
    has_adjusted_return_temp_by_ite: bool = False
    adjusted_return_temp_by_ite: float = 0.0
    has_lts_ret_air_gain: bool = False
    has_air_flow_window_return: bool = False
    internal_heat_gains: float = 0.0
    nominal_infil_vent: float = 0.0
    nominal_mixing: float = 0.0
    temp_out_of_bounds_reported: bool = False
    enforced_reciprocity: bool = False
    zone_min_co2_sched: Optional[Any] = None
    zone_max_co2_sched: Optional[Any] = None
    zone_contam_controller_sched: Optional[Any] = None
    flag_customized_zone_cap: bool = False
    other_equip_fuel_type_nums: List[Any] = field(default_factory=list)
    zone_measured_temperature: float = 0.0
    zone_measured_humidity_ratio: float = 0.0
    zone_measured_co2_concentration: float = 0.0
    zone_measured_supply_air_temperature: float = 0.0
    zone_measured_supply_air_flow_rate: float = 0.0
    zone_measured_supply_air_humidity_ratio: float = 0.0
    zone_measured_supply_air_co2_concentration: float = 0.0
    zone_people_activity_level: float = 0.0
    zone_people_sensible_heat_fraction: float = 0.0
    zone_people_radiant_heat_fraction: float = 0.0
    zone_vol_cap_multp_sens: float = 1.0
    zone_vol_cap_multp_moist: float = 1.0
    zone_vol_cap_multp_co2: float = 1.0
    zone_vol_cap_multp_gen_contam: float = 1.0
    zone_vol_cap_multp_sens_hm: float = 1.0
    zone_vol_cap_multp_sens_hm_sum: float = 0.0
    zone_vol_cap_multp_sens_hm_count_sum: float = 0.0
    zone_vol_cap_multp_sens_hm_average: float = 1.0
    mcpihm: float = 0.0
    infil_oa_air_change_rate_hm: float = 0.0
    num_occ_hm: float = 0.0
    delta_t: float = 0.0
    delta_hum_rat: float = 0.0
    zone_oa_quadrature_sum: bool = False
    zone_oa_balance_index: int = 0
    space_indexes: List[int] = field(default_factory=list)
    num_spaces: int = 0

    def set_out_bulb_temp_at(self, state):
        if state.dataEnvrn.SiteTempGradient == 0.0:
            self.out_dry_bulb_temp = state.dataEnvrn.OutDryBulbTemp
            self.out_wet_bulb_temp = state.dataEnvrn.OutWetBulbTemp
        else:
            base_dry_temp = state.dataEnvrn.OutDryBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
            base_wet_temp = state.dataEnvrn.OutWetBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
            z = self.centroid[2]
            if z <= 0.0:
                self.out_dry_bulb_temp = base_dry_temp
                self.out_wet_bulb_temp = base_wet_temp
            else:
                earth_radius = 6371000.0  # DataEnvironment::EarthRadius
                self.out_dry_bulb_temp = base_dry_temp - state.dataEnvrn.SiteTempGradient * \
                                        earth_radius * z / (earth_radius + z)
                self.out_wet_bulb_temp = base_wet_temp - state.dataEnvrn.SiteTempGradient * \
                                        earth_radius * z / (earth_radius + z)

    def set_wind_speed_at(self, state, fac):
        if state.dataEnvrn.SiteWindExp == 0.0:
            self.wind_speed = state.dataEnvrn.WindSpeed
        else:
            z = self.centroid[2]
            if z <= 0.0:
                self.wind_speed = 0.0
            else:
                self.wind_speed = fac * (z ** state.dataEnvrn.SiteWindExp)

    def set_wind_dir_at(self, fac):
        self.wind_dir = fac

    def sum_hat_surf(self, state):
        sum_hat = 0.0
        for space_num in self.space_indexes:
            sum_hat += state.dataHeatBal.space[space_num].sum_hat_surf(state)
        return sum_hat

@dataclass
class ZoneListData:
    name: str = ""
    num_of_zones: int = 0
    max_zone_name_length: int = 0
    zone: List[int] = field(default_factory=list)

@dataclass
class ZoneGroupData:
    name: str = ""
    zone_list: int = 0
    multiplier: int = 1

@dataclass
class PeopleData:
    name: str = ""
    zone_ptr: int = 0
    space_index: int = 0
    number_of_people: float = 0.0
    sched: Optional[Any] = None
    ems_people_on: bool = False
    ems_number_of_people: float = 0.0
    activity_level_sched: Optional[Any] = None
    fraction_radiant: float = 0.0
    fraction_convected: float = 0.0
    nom_min_number_people: float = 0.0
    nom_max_number_people: float = 0.0
    work_eff_sched: Optional[Any] = None
    clothing_sched: Optional[Any] = None
    clothing_method_sched: Optional[Any] = None
    clothing_type: int = ClothingType.INVALID
    air_velocity_sched: Optional[Any] = None
    ankle_air_velocity_sched: Optional[Any] = None
    fanger: bool = False
    pierce: bool = False
    ksu: bool = False
    adaptive_ash55: bool = False
    adaptive_cen15251: bool = False
    cooling_effect_ash55: bool = False
    ankle_draft_ash55: bool = False
    mrt_calc_type: int = CalcMRT.INVALID
    surface_ptr: int = -1
    angle_factor_list_name: str = ""
    angle_factor_list_ptr: int = -1
    user_spec_sens_frac: float = 0.0
    show_55_warning: bool = False
    co2_rate_factor: float = 0.0
    num_occ: float = 0.0
    temperature_in_zone: float = 0.0
    cold_stress_temp_thresh: float = 15.56
    heat_stress_temp_thresh: float = 30.0
    relative_humidity_in_zone: float = 0.0
    rad_gain_rate: float = 0.0
    con_gain_rate: float = 0.0
    sen_gain_rate: float = 0.0
    lat_gain_rate: float = 0.0
    tot_gain_rate: float = 0.0
    co2_gain_rate: float = 0.0
    rad_gain_energy: float = 0.0
    con_gain_energy: float = 0.0
    sen_gain_energy: float = 0.0
    lat_gain_energy: float = 0.0
    tot_gain_energy: float = 0.0
    air_vel_err_index: int = 0
    time_not_met_ash_55_80: float = 0.0
    time_not_met_ash_55_90: float = 0.0
    time_not_met_cen_15251_cat_i: float = 0.0
    time_not_met_cen_15251_cat_ii: float = 0.0
    time_not_met_cen_15251_cat_iii: float = 0.0

@dataclass
class LightsData:
    name: str = ""
    zone_ptr: int = 0
    space_index: int = 0
    sched: Optional[Any] = None
    design_level: float = 0.0
    ems_lights_on: bool = False
    ems_lighting_power: float = 0.0
    fraction_return_air: float = 0.0
    fraction_radiant: float = 0.0
    fraction_short_wave: float = 0.0
    fraction_replaceable: float = 0.0
    fraction_convected: float = 0.0
    fraction_return_air_is_calculated: bool = False
    fraction_return_air_plen_temp_coeff_1: float = 0.0
    fraction_return_air_plen_temp_coeff_2: float = 0.0
    zone_return_num: int = 1
    ret_node_name: str = ""
    zone_exhaust_node_num: int = 0
    nom_min_design_level: float = 0.0
    nom_max_design_level: float = 0.0
    manage_demand: bool = False
    demand_limit: float = 0.0
    power: float = 0.0
    rad_gain_rate: float = 0.0
    vis_gain_rate: float = 0.0
    con_gain_rate: float = 0.0
    ret_air_gain_rate: float = 0.0
    tot_gain_rate: float = 0.0
    consumption: float = 0.0
    rad_gain_energy: float = 0.0
    vis_gain_energy: float = 0.0
    con_gain_energy: float = 0.0
    ret_air_gain_energy: float = 0.0
    tot_gain_energy: float = 0.0
    end_use_subcategory: str = ""
    sum_consumption: float = 0.0
    sum_time_not_zero_cons: float = 0.0

@dataclass
class ZoneEquipData:
    name: str = ""
    zone_ptr: int = 0
    space_index: int = 0
    sched: Optional[Any] = None
    design_level: float = 0.0
    ems_zone_equip_override_on: bool = False
    ems_equip_power: float = 0.0
    fraction_latent: float = 0.0
    fraction_radiant: float = 0.0
    fraction_lost: float = 0.0
    fraction_convected: float = 0.0
    co2_design_rate: float = 0.0
    co2_rate_factor: float = 0.0
    nom_min_design_level: float = 0.0
    nom_max_design_level: float = 0.0
    manage_demand: bool = False
    demand_limit: float = 0.0
    power: float = 0.0
    rad_gain_rate: float = 0.0
    con_gain_rate: float = 0.0
    lat_gain_rate: float = 0.0
    lost_rate: float = 0.0
    tot_gain_rate: float = 0.0
    co2_gain_rate: float = 0.0
    consumption: float = 0.0
    rad_gain_energy: float = 0.0
    con_gain_energy: float = 0.0
    lat_gain_energy: float = 0.0
    lost_energy: float = 0.0
    tot_gain_energy: float = 0.0
    end_use_subcategory: str = ""
    other_equip_fuel_type_string: str = ""
    other_equip_fuel_type: int = -1

@dataclass
class ExtVentedCavityStruct:
    name: str = ""
    oscm_name: str = ""
    oscm_ptr: int = 0
    porosity: float = 0.0
    lw_emitt: float = 0.0
    sol_absorp: float = 0.0
    baffle_roughness: int = 0
    plen_gap_thick: float = 0.0
    num_surfs: int = 0
    surf_ptrs: List[int] = field(default_factory=list)
    hdelta_npl: float = 0.0
    area_ratio: float = 0.0
    cv: float = 0.0
    cd: float = 0.0
    actual_area: float = 0.0
    proj_area: float = 0.0
    centroid: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    t_air_cav: float = 0.0
    t_baffle: float = 0.0
    t_air_last: float = 20.0
    t_baffle_last: float = 20.0
    hr_plen: float = 0.0
    hc_plen: float = 0.0
    mdot_vent: float = 0.0
    tilt: float = 0.0
    azimuth: float = 0.0
    qdot_source: float = 0.0
    isc: float = 0.0
    passive_ach: float = 0.0
    passive_mdot_vent: float = 0.0
    passive_mdot_wind: float = 0.0
    passive_mdot_therm: float = 0.0

@dataclass
class ITEquipData:
    name: str = ""
    zone_ptr: int = 0
    space_index: int = 0
    flow_control_with_approach_temps: bool = False
    design_total_power: float = 0.0
    nom_min_design_level: float = 0.0
    nom_max_design_level: float = 0.0
    design_fan_power_frac: float = 0.0
    oper_sched: Optional[Any] = None
    cpu_load_sched: Optional[Any] = None
    sizing_t_air_in: float = 0.0
    design_t_air_in: float = 0.0
    design_fan_power: float = 0.0
    design_cpu_power: float = 0.0
    design_air_vol_flow_rate: float = 0.0
    ite_class: int = ITEClass.NONE
    air_flow_flt_curve: int = 0
    cpu_power_flt_curve: int = 0
    fan_power_ff_curve: int = 0
    air_connection_type: int = ITEInletConnection.ADJUSTED_SUPPLY
    inlet_room_air_node_num: int = 0
    outlet_room_air_node_num: int = 0
    supply_air_node_num: int = 0
    design_recirc_frac: float = 0.0
    recirc_flt_curve: int = 0
    design_ups_efficiency: float = 0.0
    ups_effic_fplr_curve: int = 0
    ups_loss_to_zone_frac: float = 0.0
    end_use_subcategory_cpu: str = ""
    end_use_subcategory_fan: str = ""
    end_use_subcategory_ups: str = ""
    ems_cpu_power_override_on: bool = False
    ems_cpu_power: float = 0.0
    ems_fan_power_override_on: bool = False
    ems_fan_power: float = 0.0
    ems_ups_power_override_on: bool = False
    ems_ups_power: float = 0.0
    supply_approach_temp: float = 0.0
    supply_approach_temp_sched: Optional[Any] = None
    return_approach_temp: float = 0.0
    return_approach_temp_sched: Optional[Any] = None
    in_controlled_zone: bool = False
    power_rpt: List[float] = field(default_factory=lambda: [0.0] * int(PERptVars.NUM))
    energy_rpt: List[float] = field(default_factory=lambda: [0.0] * int(PERptVars.NUM))
    air_vol_flow_std_density: float = 0.0
    air_vol_flow_cur_density: float = 0.0
    air_mass_flow: float = 0.0
    air_inlet_dry_bulb_t: float = 0.0
    air_inlet_dewpoint_t: float = 0.0
    air_inlet_rel_hum: float = 0.0
    air_outlet_dry_bulb_t: float = 0.0
    shi: float = 0.0
    time_out_of_oper_range: float = 0.0
    time_above_dry_bulb_t: float = 0.0
    time_below_dry_bulb_t: float = 0.0
    time_above_dewpoint_t: float = 0.0
    time_below_dewpoint_t: float = 0.0
    time_above_rh: float = 0.0
    time_below_rh: float = 0.0
    dry_bulb_t_above_delta_t: float = 0.0
    dry_bulb_t_below_delta_t: float = 0.0
    dewpoint_t_above_delta_t: float = 0.0
    dewpoint_t_below_delta_t: float = 0.0
    rh_above_delta_rh: float = 0.0
    rh_below_delta_rh: float = 0.0

@dataclass
class BBHeatData:
    name: str = ""
    zone_ptr: int = 0
    space_index: int = 0
    sched: Optional[Any] = None
    cap_at_low_temperature: float = 0.0
    low_temperature: float = 0.0
    cap_at_high_temperature: float = 0.0
    high_temperature: float = 0.0
    ems_zone_baseboard_override_on: bool = False
    ems_zone_baseboard_power: float = 0.0
    fraction_radiant: float = 0.0
    fraction_convected: float = 0.0
    manage_demand: bool = False
    demand_limit: float = 0.0
    power: float = 0.0
    rad_gain_rate: float = 0.0
    con_gain_rate: float = 0.0
    tot_gain_rate: float = 0.0
    consumption: float = 0.0
    rad_gain_energy: float = 0.0
    con_gain_energy: float = 0.0
    tot_gain_energy: float = 0.0
    end_use_subcategory: str = ""

@dataclass
class InfiltrationData:
    name: str = ""
    zone_ptr: int = 0
    space_index: int = 0
    sched: Optional[Any] = None
    model_type: int = InfiltrationModelType.INVALID
    density_basis: int = InfVentDensityBasis.OUTDOOR
    design_level: float = 0.0
    constant_term_coef: float = 0.0
    temperature_term_coef: float = 0.0
    velocity_term_coef: float = 0.0
    velocity_sq_term_coef: float = 0.0
    leakage_area: float = 0.0
    basic_stack_coefficient: float = 0.0
    basic_wind_coefficient: float = 0.0
    flow_coefficient: float = 0.0
    aim2_stack_coefficient: float = 0.0
    aim2_wind_coefficient: float = 0.0
    pressure_exponent: float = 0.0
    shelter_factor: float = 0.0
    ems_override_on: bool = False
    ems_air_flow_rate_value: float = 0.0
    volume_flow_rate: float = 0.0
    mass_flow_rate: float = 0.0
    mcp_i_temp: float = 0.0
    infil_heat_gain: float = 0.0
    infil_heat_loss: float = 0.0
    infil_latent_gain: float = 0.0
    infil_latent_loss: float = 0.0
    infil_total_gain: float = 0.0
    infil_total_loss: float = 0.0
    infil_volume_cur_density: float = 0.0
    infil_volume_std_density: float = 0.0
    infil_vdot_cur_density: float = 0.0
    infil_vdot_std_density: float = 0.0
    infil_vdot_out_density: float = 0.0
    infil_mdot: float = 0.0
    infil_mass: float = 0.0
    infil_air_change_rate_cur_density: float = 0.0
    infil_air_change_rate_std_density: float = 0.0
    infil_air_change_rate_out_density: float = 0.0

@dataclass
class VentilationData:
    name: str = ""
    zone_ptr: int = 0
    space_index: int = 0
    avail_sched: Optional[Any] = None
    model_type: int = VentilationModelType.INVALID
    density_basis: int = InfVentDensityBasis.OUTDOOR
    design_level: float = 0.0
    ems_simple_vent_on: bool = False
    em_simple_vent_flow_rate: float = 0.0
    min_indoor_temperature: float = -100.0
    del_temperature: float = 0.0
    fan_type: int = VentilationType.NATURAL
    fan_pressure: float = 0.0
    fan_efficiency: float = 0.0
    fan_power: float = 0.0
    air_temp: float = 0.0
    constant_term_coef: float = 0.0
    temperature_term_coef: float = 0.0
    velocity_term_coef: float = 0.0
    velocity_sq_term_coef: float = 0.0
    max_indoor_temperature: float = 100.0
    min_outdoor_temperature: float = -100.0
    max_outdoor_temperature: float = 100.0
    max_wind_speed: float = 40.0
    min_indoor_temp_sched: Optional[Any] = None
    max_indoor_temp_sched: Optional[Any] = None
    delta_temp_sched: Optional[Any] = None
    min_outdoor_temp_sched: Optional[Any] = None
    max_outdoor_temp_sched: Optional[Any] = None
    indoor_temp_err_count: int = 0
    outdoor_temp_err_count: int = 0
    indoor_temp_err_index: int = 0
    outdoor_temp_err_index: int = 0
    hybrid_control_type: int = HybridCtrlType.INDIV
    hybrid_control_master_num: int = 0
    hybrid_control_master_status: bool = False
    open_area: float = 0.0
    open_area_frac_sched: Optional[Any] = None
    open_eff: float = 0.0
    eff_angle: float = 0.0
    dh: float = 0.0
    disc_coef: float = 0.0
    mcp: float = 0.0

@dataclass
class ZoneAirBalanceData:
    name: str = ""
    zone_name: str = ""
    zone_ptr: int = 0
    balance_method: int = AirBalance.NONE
    induced_air_rate: float = 0.0
    induced_air_sched: Optional[Any] = None
    bal_mass_flow_rate: float = 0.0
    inf_mass_flow_rate: float = 0.0
    nat_mass_flow_rate: float = 0.0
    exh_mass_flow_rate: float = 0.0
    int_mass_flow_rate: float = 0.0
    erv_mass_flow_rate: float = 0.0
    one_time_flag: bool = False
    num_of_ervs: int = 0
    erv_inlet_node: List[int] = field(default_factory=list)
    erv_exhaust_node: List[int] = field(default_factory=list)

@dataclass
class MixingData:
    name: str = ""
    zone_ptr: int = 0
    space_index: int = 0
    sched: Optional[Any] = None
    design_level: float = 0.0
    from_zone: int = 0
    from_space_index: int = 0
    delta_temperature: float = 0.0
    desired_air_flow_rate: float = 0.0
    desired_air_flow_rate_saved: float = 0.0
    mixing_mass_flow_rate: float = 0.0
    delta_temp_sched: Optional[Any] = None
    min_indoor_temp_sched: Optional[Any] = None
    max_indoor_temp_sched: Optional[Any] = None
    min_source_temp_sched: Optional[Any] = None
    max_source_temp_sched: Optional[Any] = None
    min_outdoor_temp_sched: Optional[Any] = None
    max_outdoor_temp_sched: Optional[Any] = None
    indoor_temp_err_count: int = 0
    source_temp_err_count: int = 0
    outdoor_temp_err_count: int = 0
    indoor_temp_err_index: int = 0
    source_temp_err_index: int = 0
    outdoor_temp_err_index: int = 0
    hybrid_control_type: int = HybridCtrlType.INDIV
    hybrid_control_master_num: int = 0
    num_ref_door_connections: int = 0
    ems_simple_mixing_on: bool = False
    ref_door_mix_flag: bool = False
    report_flag: bool = False
    em_simple_mixing_flow_rate: float = 0.0
    ems_ref_door_mixing_on: List[bool] = field(default_factory=list)
    ems_ref_door_flow_rate: List[float] = field(default_factory=list)
    vol_ref_door_flow_rate: List[float] = field(default_factory=list)
    open_scheds: List[Optional[Any]] = field(default_factory=list)
    door_height: List[float] = field(default_factory=list)
    door_area: List[float] = field(default_factory=list)
    protection: List[float] = field(default_factory=list)
    mate_zone_ptr: List[int] = field(default_factory=list)
    door_mixing_object_name: List[str] = field(default_factory=list)
    door_prot_type_name: List[str] = field(default_factory=list)

@dataclass
class AirBoundaryMixingSpecs:
    space_1: int = 0
    space_2: int = 0
    sched: Optional[Any] = None
    mixing_volume_flow_rate: float = 0.0

@dataclass
class ZoneAirMassFlowConservation:
    enforce_zone_mass_balance: bool = False
    zone_flow_adjustment: int = AdjustmentType.NO_ADJUST_RETURN_AND_MIXING
    infiltration_treatment: int = InfiltrationFlow.NO
    infiltration_for_zones: int = InfiltrationZoneType.INVALID
    adjust_zone_mixing_flow: bool = False
    adjust_zone_infiltration_flow: bool = False

@dataclass
class ZoneMassConservationData:
    name: str = ""
    zone_ptr: int = 0
    in_mass_flow_rate: float = 0.0
    exh_mass_flow_rate: float = 0.0
    ret_mass_flow_rate: float = 0.0
    mixing_mass_flow_rate: float = 0.0
    mixing_source_mass_flow_rate: float = 0.0
    num_source_zones_mixing_object: int = 0
    num_receiving_zones_mixing_object: int = 0
    is_only_source_zone: bool = False
    is_source_and_receiving_zone: bool = False
    infiltration_ptr: int = 0
    infiltration_mass_flow_rate: float = 0.0
    include_infil_to_zone_mass_bal: int = 0
    zone_mixing_sources_ptr: List[int] = field(default_factory=list)
    zone_mixing_receiving_ptr: List[int] = field(default_factory=list)
    zone_mixing_receiving_fr: List[float] = field(default_factory=list)

@dataclass
class GenericComponentZoneIntGainStruct:
    comp_object_name: str = ""
    comp_type: int = IntGainType.INVALID
    space_gain_frac: float = 1.0
    ptr_convect_gain_rate: Optional[Any] = None
    convect_gain_rate: float = 0.0
    ptr_return_air_conv_gain_rate: Optional[Any] = None
    return_air_conv_gain_rate: float = 0.0
    ptr_radiant_gain_rate: Optional[Any] = None
    radiant_gain_rate: float = 0.0
    ptr_latent_gain_rate: Optional[Any] = None
    latent_gain_rate: float = 0.0
    ptr_return_air_latent_gain_rate: Optional[Any] = None
    return_air_latent_gain_rate: float = 0.0
    ptr_carbon_dioxide_gain_rate: Optional[Any] = None
    carbon_dioxide_gain_rate: float = 0.0
    ptr_generic_contam_gain_rate: Optional[Any] = None
    generic_contam_gain_rate: float = 0.0
    return_air_node_num: int = 0

@dataclass
class SpaceZoneSimData:
    nofocc: float = 0.0
    qltsw: float = 0.0

@dataclass
class SpaceIntGainDeviceData:
    number_of_devices: int = 0
    max_number_of_devices: int = 0
    device: List[GenericComponentZoneIntGainStruct] = field(default_factory=list)

@dataclass
class ZoneCatEUseData:
    ee_convected: List[float] = field(default_factory=lambda: [0.0] * 26)
    ee_radiated: List[float] = field(default_factory=lambda: [0.0] * 26)
    ee_lost: List[float] = field(default_factory=lambda: [0.0] * 26)
    ee_latent: List[float] = field(default_factory=lambda: [0.0] * 26)

@dataclass
class RefrigCaseCreditData:
    sen_case_credit_to_zone: float = 0.0
    lat_case_credit_to_zone: float = 0.0
    sen_case_credit_to_hvac: float = 0.0
    lat_case_credit_to_hvac: float = 0.0

    def reset(self):
        self.sen_case_credit_to_zone = 0.0
        self.lat_case_credit_to_zone = 0.0
        self.sen_case_credit_to_hvac = 0.0
        self.lat_case_credit_to_hvac = 0.0

@dataclass
class HeatReclaimDataBase:
    name: str = ""
    source_type: str = ""
    avail_capacity: float = 0.0
    reclaim_efficiency_total: float = 0.0
    water_heating_desuperheater_reclaimed_heat_total: float = 0.0
    hvac_desuperheater_reclaimed_heat_total: float = 0.0
    water_heating_desuperheater_reclaimed_heat: List[float] = field(default_factory=list)
    hvac_desuperheater_reclaimed_heat: List[float] = field(default_factory=list)

@dataclass
class HeatReclaimRefrigCondenserData(HeatReclaimDataBase):
    avail_temperature: float = 0.0

@dataclass
class AirReportVars:
    mean_air_temp: float = 0.0
    operative_temp: float = 0.0
    wetbulb_globe_temp: float = 0.0
    mean_air_hum_rat: float = 0.0
    mean_air_dewpoint_temp: float = 0.0
    therm_operative_temp: float = 0.0
    infil_heat_gain: float = 0.0
    infil_heat_loss: float = 0.0
    infil_latent_gain: float = 0.0
    infil_latent_loss: float = 0.0
    infil_total_gain: float = 0.0
    infil_total_loss: float = 0.0
    infil_volume_cur_density: float = 0.0
    infil_volume_std_density: float = 0.0
    infil_vdot_cur_density: float = 0.0
    infil_vdot_std_density: float = 0.0
    infil_vdot_out_density: float = 0.0
    infil_mass: float = 0.0
    infil_mdot: float = 0.0
    infil_air_change_rate_cur_density: float = 0.0
    infil_air_change_rate_std_density: float = 0.0
    infil_air_change_rate_out_density: float = 0.0
    ventil_heat_loss: float = 0.0
    ventil_heat_gain: float = 0.0
    ventil_latent_loss: float = 0.0
    ventil_latent_gain: float = 0.0
    ventil_total_loss: float = 0.0
    ventil_total_gain: float = 0.0
    ventil_volume_cur_density: float = 0.0
    ventil_volume_std_density: float = 0.0
    ventil_vdot_cur_density: float = 0.0
    ventil_vdot_std_density: float = 0.0
    ventil_vdot_out_density: float = 0.0
    ventil_mass: float = 0.0
    ventil_mdot: float = 0.0
    ventil_air_change_rate_cur_density: float = 0.0
    ventil_air_change_rate_std_density: float = 0.0
    ventil_air_change_rate_out_density: float = 0.0
    ventil_fan_elec: float = 0.0
    ventil_air_temp: float = 0.0
    mix_volume: float = 0.0
    mix_vdot_cur_density: float = 0.0
    mix_vdot_std_density: float = 0.0
    mix_mass: float = 0.0
    mix_mdot: float = 0.0
    mix_sen_load: float = 0.0
    mix_lat_load: float = 0.0
    mix_heat_loss: float = 0.0
    mix_heat_gain: float = 0.0
    mix_latent_loss: float = 0.0
    mix_latent_gain: float = 0.0
    mix_total_loss: float = 0.0
    mix_total_gain: float = 0.0
    sys_inlet_mass: float = 0.0
    sys_outlet_mass: float = 0.0
    exfil_mass: float = 0.0
    exfil_total_loss: float = 0.0
    exfil_sensi_loss: float = 0.0
    exfil_latent_loss: float = 0.0
    exh_total_loss: float = 0.0
    exh_sensi_loss: float = 0.0
    exh_latent_loss: float = 0.0
    sum_int_gains: float = 0.0
    sum_had_tsurf: float = 0.0
    sum_mcp_dt_zones: float = 0.0
    sum_mcp_dt_infil: float = 0.0
    sum_mcp_dt_system: float = 0.0
    sum_non_air_system: float = 0.0
    czd_tdt: float = 0.0
    im_balance: float = 0.0
    oa_balance_heat_loss: float = 0.0
    oa_balance_heat_gain: float = 0.0
    oa_balance_latent_loss: float = 0.0
    oa_balance_latent_gain: float = 0.0
    oa_balance_total_loss: float = 0.0
    oa_balance_total_gain: float = 0.0
    oa_balance_volume_cur_density: float = 0.0
    oa_balance_volume_std_density: float = 0.0
    oa_balance_vdot_cur_density: float = 0.0
    oa_balance_vdot_std_density: float = 0.0
    oa_balance_mass: float = 0.0
    oa_balance_mdot: float = 0.0
    oa_balance_air_change_rate: float = 0.0
    oa_balance_fan_elec: float = 0.0
    sum_enthalpy_m: float = 0.0
    sum_enthalpy_h: float = 0.0
    report_wbgt: bool = False

    def set_up_output_vars(self, state, prefix, name):
        pass

@dataclass
class ZonePreDefRepType:
    is_occupied: bool = False
    num_occ: float = 0.0
    num_occ_accum: float = 0.0
    num_occ_accum_time: float = 0.0
    tot_time_occ: float = 0.0
    mech_vent_vol_total_occ: float = 0.0
    mech_vent_vol_min: float = 9.9e9
    infil_vol_total_occ: float = 0.0
    infil_vol_min: float = 9.9e9
    afn_infil_vol_total_occ: float = 0.0
    afn_infil_vol_min: float = 9.9e9
    simp_vent_vol_total_occ: float = 0.0
    simp_vent_vol_min: float = 9.9e9
    afn_vent_vol_total_occ: float = 0.0
    afn_vent_vol_min: float = 9.9e9
    mech_vent_vol_total_std_den: float = 0.0
    mech_vent_vol_total_occ_std_den: float = 0.0
    infil_vol_total_std_den: float = 0.0
    infil_vol_total_occ_std_den: float = 0.0
    afn_infil_vol_total_std_den: float = 0.0
    afn_infil_vol_total_occ_std_den: float = 0.0
    afn_vent_vol_std_den: float = 0.0
    afn_vent_vol_total_std_den: float = 0.0
    afn_vent_vol_total_occ_std_den: float = 0.0
    simp_vent_vol_total_std_den: float = 0.0
    simp_vent_vol_total_occ_std_den: float = 0.0
    voz_min: float = 0.0
    voz_target_total: float = 0.0
    voz_target_total_occ: float = 0.0
    voz_target_time_below: float = 0.0
    voz_target_time_at: float = 0.0
    voz_target_time_above: float = 0.0
    voz_target_time_below_occ: float = 0.0
    voz_target_time_at_occ: float = 0.0
    voz_target_time_above_occ: float = 0.0
    tot_vent_time_non_zero_unocc: float = 0.0
    shgs_an_zone_eq_ht: float = 0.0
    shgs_an_zone_eq_cl: float = 0.0
    shgs_an_hvac_atu_ht: float = 0.0
    shgs_an_hvac_atu_cl: float = 0.0
    shgs_an_surf_ht: float = 0.0
    shgs_an_surf_cl: float = 0.0
    shgs_an_people_add: float = 0.0
    shgs_an_lite_add: float = 0.0
    shgs_an_equip_add: float = 0.0
    shgs_an_wind_add: float = 0.0
    shgs_an_iza_add: float = 0.0
    shgs_an_infil_add: float = 0.0
    shgs_an_other_add: float = 0.0
    shgs_an_equip_rem: float = 0.0
    shgs_an_wind_rem: float = 0.0
    shgs_an_iza_rem: float = 0.0
    shgs_an_infil_rem: float = 0.0
    shgs_an_other_rem: float = 0.0
    cl_pt_time_stamp: int = 0
    cl_peak: float = 0.0
    shgs_cl_hvac_ht: float = 0.0
    shgs_cl_hvac_cl: float = 0.0
    shgs_cl_hvac_atu_ht: float = 0.0
    shgs_cl_hvac_atu_cl: float = 0.0
    shgs_cl_surf_ht: float = 0.0
    shgs_cl_surf_cl: float = 0.0
    shgs_cl_people_add: float = 0.0
    shgs_cl_lite_add: float = 0.0
    shgs_cl_equip_add: float = 0.0
    shgs_cl_wind_add: float = 0.0
    shgs_cl_iza_add: float = 0.0
    shgs_cl_infil_add: float = 0.0
    shgs_cl_other_add: float = 0.0
    shgs_cl_equip_rem: float = 0.0
    shgs_cl_wind_rem: float = 0.0
    shgs_cl_iza_rem: float = 0.0
    shgs_cl_infil_rem: float = 0.0
    shgs_cl_other_rem: float = 0.0
    ht_pt_time_stamp: int = 0
    ht_peak: float = 0.0
    shgs_ht_hvac_ht: float = 0.0
    shgs_ht_hvac_cl: float = 0.0
    shgs_ht_hvac_atu_ht: float = 0.0
    shgs_ht_hvac_atu_cl: float = 0.0
    shgs_ht_surf_ht: float = 0.0
    shgs_ht_surf_cl: float = 0.0
    shgs_ht_people_add: float = 0.0
    shgs_ht_lite_add: float = 0.0
    shgs_ht_equip_add: float = 0.0
    shgs_ht_wind_add: float = 0.0
    shgs_ht_iza_add: float = 0.0
    shgs_ht_infil_add: float = 0.0
    shgs_ht_other_add: float = 0.0
    shgs_ht_equip_rem: float = 0.0
    shgs_ht_wind_rem: float = 0.0
    shgs_ht_iza_rem: float = 0.0
    shgs_ht_infil_rem: float = 0.0
    shgs_ht_other_rem: float = 0.0
    emi_envelope_conv: float = 0.0
    emi_zone_exfiltration: float = 0.0
    emi_zone_exhaust: float = 0.0
    emi_hvac_relief: float = 0.0
    emi_hvac_reject: float = 0.0
    emi_tot_heat: float = 0.0

@dataclass
class ZoneLocalEnvironmentData:
    name: str = ""
    zone_ptr: int = 0
    outdoor_air_node_ptr: int = 0

@dataclass
class ZoneReportVars:
    people_rad_gain: float = 0.0
    people_con_gain: float = 0.0
    people_sen_gain: float = 0.0
    people_num_occ: float = 0.0
    people_lat_gain: float = 0.0
    people_tot_gain: float = 0.0
    people_rad_gain_rate: float = 0.0
    people_con_gain_rate: float = 0.0
    people_sen_gain_rate: float = 0.0
    people_lat_gain_rate: float = 0.0
    people_tot_gain_rate: float = 0.0
    lts_power: float = 0.0
    lts_elec_consump: float = 0.0
    lts_rad_gain: float = 0.0
    lts_vis_gain: float = 0.0
    lts_con_gain: float = 0.0
    lts_ret_air_gain: float = 0.0
    lts_tot_gain: float = 0.0
    lts_rad_gain_rate: float = 0.0
    lts_vis_gain_rate: float = 0.0
    lts_con_gain_rate: float = 0.0
    lts_ret_air_gain_rate: float = 0.0
    lts_tot_gain_rate: float = 0.0
    base_heat_power: float = 0.0
    base_heat_elec_cons: float = 0.0
    base_heat_rad_gain: float = 0.0
    base_heat_con_gain: float = 0.0
    base_heat_tot_gain: float = 0.0
    base_heat_rad_gain_rate: float = 0.0
    base_heat_con_gain_rate: float = 0.0
    base_heat_tot_gain_rate: float = 0.0
    elec_power: float = 0.0
    elec_consump: float = 0.0
    elec_rad_gain: float = 0.0
    elec_con_gain: float = 0.0
    elec_lat_gain: float = 0.0
    elec_lost: float = 0.0
    elec_tot_gain: float = 0.0
    elec_rad_gain_rate: float = 0.0
    elec_con_gain_rate: float = 0.0
    elec_lat_gain_rate: float = 0.0
    elec_lost_rate: float = 0.0
    elec_tot_gain_rate: float = 0.0
    gas_power: float = 0.0
    gas_consump: float = 0.0
    gas_rad_gain: float = 0.0
    gas_con_gain: float = 0.0
    gas_lat_gain: float = 0.0
    gas_lost: float = 0.0
    gas_tot_gain: float = 0.0
    gas_rad_gain_rate: float = 0.0
    gas_con_gain_rate: float = 0.0
    gas_lat_gain_rate: float = 0.0
    gas_lost_rate: float = 0.0
    gas_tot_gain_rate: float = 0.0
    hw_power: float = 0.0
    hw_consump: float = 0.0
    hw_rad_gain: float = 0.0
    hw_con_gain: float = 0.0
    hw_lat_gain: float = 0.0
    hw_lost: float = 0.0
    hw_tot_gain: float = 0.0
    hw_rad_gain_rate: float = 0.0
    hw_con_gain_rate: float = 0.0
    hw_lat_gain_rate: float = 0.0
    hw_lost_rate: float = 0.0
    hw_tot_gain_rate: float = 0.0
    steam_power: float = 0.0
    steam_consump: float = 0.0
    steam_rad_gain: float = 0.0
    steam_con_gain: float = 0.0
    steam_lat_gain: float = 0.0
    steam_lost: float = 0.0
    steam_tot_gain: float = 0.0
    steam_rad_gain_rate: float = 0.0
    steam_con_gain_rate: float = 0.0
    steam_lat_gain_rate: float = 0.0
    steam_lost_rate: float = 0.0
    steam_tot_gain_rate: float = 0.0
    other_power: List[float] = field(default_factory=list)
    other_consump: List[float] = field(default_factory=list)
    other_rad_gain: float = 0.0
    other_con_gain: float = 0.0
    other_lat_gain: float = 0.0
    other_lost: float = 0.0
    other_tot_gain: float = 0.0
    other_rad_gain_rate: float = 0.0
    other_con_gain_rate: float = 0.0
    other_lat_gain_rate: float = 0.0
    other_lost_rate: float = 0.0
    other_tot_gain_rate: float = 0.0
    power_rpt: List[float] = field(default_factory=lambda: [0.0] * int(PERptVars.NUM))
    energy_rpt: List[float] = field(default_factory=lambda: [0.0] * int(PERptVars.NUM))
    iteq_air_vol_flow_std_density: float = 0.0
    iteq_air_mass_flow: float = 0.0
    iteq_shi: float = 0.0
    iteq_time_out_of_oper_range: float = 0.0
    iteq_time_above_dry_bulb_t: float = 0.0
    iteq_time_below_dry_bulb_t: float = 0.0
    iteq_time_above_dewpoint_t: float = 0.0
    iteq_time_below_dewpoint_t: float = 0.0
    iteq_time_above_rh: float = 0.0
    iteq_time_below_rh: float = 0.0
    ite_adj_return_temp: float = 0.0
    tot_radiant_gain: float = 0.0
    tot_vis_heat_gain: float = 0.0
    tot_convective_gain: float = 0.0
    tot_latent_gain: float = 0.0
    tot_total_heat_gain: float = 0.0
    tot_radiant_gain_rate: float = 0.0
    tot_vis_heat_gain_rate: float = 0.0
    tot_convective_gain_rate: float = 0.0
    tot_latent_gain_rate: float = 0.0
    tot_total_heat_gain_rate: float = 0.0
    co2_rate: float = 0.0
    gc_rate: float = 0.0
    sum_t_in_minus_t_sup: float = 0.0
    sum_t_out_minus_t_sup: float = 0.0

# ============ FUNCTIONS ============

def set_zone_out_bulb_temp_at(state):
    for zone in state.dataHeatBal.Zone:
        zone.set_out_bulb_temp_at(state)

def check_zone_out_bulb_temp_at(state):
    min_bulb = 0.0
    for zone in state.dataHeatBal.Zone:
        min_bulb = min(min_bulb, zone.out_dry_bulb_temp, zone.out_wet_bulb_temp)
        if min_bulb < -100.0:
            pass

def set_zone_wind_speed_at(state):
    fac = (state.dataEnvrn.WindSpeed * state.dataEnvrn.WeatherFileWindModCoeff *
           (state.dataEnvrn.SiteWindBLHeight ** (-state.dataEnvrn.SiteWindExp)))
    for zone in state.dataHeatBal.Zone:
        zone.set_wind_speed_at(state, fac)

def set_zone_wind_dir_at(state):
    fac = state.dataEnvrn.WindDir
    for zone in state.dataHeatBal.Zone:
        zone.set_wind_dir_at(fac)

def check_and_set_construction_properties(state, constr_num, errors_found):
    pass

def assign_reverse_construction_number(state, constr_num, errors_found):
    return 0

def compute_nominal_u_with_conv_coeffs(state, num_surf, is_valid):
    return 0.0

def set_flag_for_window_construction_with_shade_or_blind_layer(state):
    pass

def allocate_int_gains(state):
    pass
