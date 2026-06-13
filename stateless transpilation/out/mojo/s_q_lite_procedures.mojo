from math import floor
from sys import exit

alias Real64 = Float64

const REPORT_FREQ_INTS = [-1, 0, 1, 2, 3, 4, 5]

fn logical_to_integer(value: Bool) -> Int32:
    return 1 if value else 0

struct SQLiteProcedures:
    var m_writeOutputToSQLite: Bool
    var m_errorStream: String
    var m_db: String
    
    fn __init__(inout self, error_stream: String, db_connection: String):
        self.m_writeOutputToSQLite = True
        self.m_errorStream = error_stream
        self.m_db = db_connection
    
    fn __init__(inout self, error_stream: String, write_output_to_sqlite: Bool,
               db_name: String, error_file_path: String):
        self.m_writeOutputToSQLite = write_output_to_sqlite
        self.m_errorStream = error_stream
        self.m_db = db_name
    
    fn sqlite_execute_command(self, command_buffer: String) -> Int32:
        return 0
    
    fn sqlite_bind_text(self, index: Int32, text_buffer: String):
        pass
    
    fn sqlite_bind_integer(self, index: Int32, int_to_insert: Int32):
        pass
    
    fn sqlite_bind_double(self, index: Int32, double_to_insert: Real64):
        pass
    
    fn sqlite_bind_null(self, index: Int32):
        pass
    
    fn sqlite_bind_foreign_key(self, index: Int32, int_to_insert: Int32):
        if int_to_insert > 0:
            self.sqlite_bind_integer(index, int_to_insert)
        else:
            self.sqlite_bind_null(index)
    
    fn sqlite_bind_logical(self, index: Int32, value_to_insert: Bool):
        self.sqlite_bind_integer(index, logical_to_integer(value_to_insert))
    
    fn sqlite_step_validity(self, rc: Int32) -> Bool:
        return rc == 0 or rc == 100 or rc == 101
    
    fn sqlite_step_command(self) -> Int32:
        return 0
    
    fn sqlite_reset_command(self):
        pass
    
    fn sqlite_within_transaction(self) -> Bool:
        return False


struct SQLiteData:
    var m_errorStream: String
    var m_db: String


struct Schedule(SQLiteData):
    var number: Int32
    var name: String
    var type: String
    var min_value: Real64
    var max_value: Real64


struct Surface(SQLiteData):
    var number: Int32
    var name: String
    var construction: Int32
    var surface_class: String
    var area: Real64
    var gross_area: Real64
    var perimeter: Real64
    var azimuth: Real64
    var height: Real64
    var reveal: Real64
    var shape: Int32
    var sides: Int32
    var tilt: Real64
    var width: Real64
    var heat_trans_surf: Bool
    var base_surf: Int32
    var zone: Int32
    var ext_bound_cond: Int32
    var ext_solar: Bool
    var ext_wind: Bool


struct Zone(SQLiteData):
    var number: Int32
    var name: String
    var rel_north: Real64
    var origin_x: Real64
    var origin_y: Real64
    var origin_z: Real64
    var centroid_x: Real64
    var centroid_y: Real64
    var centroid_z: Real64
    var of_type: Int32
    var multiplier: Int32
    var list_multiplier: Int32
    var minimum_x: Real64
    var maximum_x: Real64
    var minimum_y: Real64
    var maximum_y: Real64
    var minimum_z: Real64
    var maximum_z: Real64
    var ceiling_height: Real64
    var volume: Real64
    var inside_convection_algo: Int32
    var outside_convection_algo: Int32
    var floor_area: Real64
    var ext_gross_wall_area: Real64
    var ext_net_wall_area: Real64
    var ext_window_area: Real64
    var is_part_of_total_area: Bool


struct ZoneList(SQLiteData):
    var number: Int32
    var name: String
    var zones: DynamicVector[Int32]


struct ZoneGroup(SQLiteData):
    var number: Int32
    var name: String
    var zone_list: Int32
    var multiplier: Int32


struct Material(SQLiteData):
    var number: Int32
    var name: String
    var group: Int32
    var roughness: Int32
    var conductivity: Real64
    var density: Real64
    var porosity: Real64
    var resistance: Real64
    var r_only: Bool
    var spec_heat: Real64
    var thickness: Real64
    var vapor_diffus: Real64


struct ConstructionLayer(SQLiteData):
    var construct_number: Int32
    var layer_number: Int32
    var layer_point: Int32


struct Construction(SQLiteData):
    var number: Int32
    var name: String
    var tot_layers: Int32
    var tot_solid_layers: Int32
    var tot_glass_layers: Int32
    var inside_absorb_vis: Real64
    var outside_absorb_vis: Real64
    var inside_absorb_solar: Real64
    var outside_absorb_solar: Real64
    var inside_absorb_thermal: Real64
    var outside_absorb_thermal: Real64
    var outside_roughness: Int32
    var type_is_window: Bool
    var u_value: Real64
    var construction_layers: DynamicVector[ConstructionLayer]


struct NominalLighting(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var design_level: Real64
    var fraction_return_air: Real64
    var fraction_radiant: Real64
    var fraction_short_wave: Real64
    var fraction_replaceable: Real64
    var fraction_convected: Real64
    var end_use_subcategory: String


struct NominalPeople(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var number_of_people: Real64
    var number_of_people_sched: Int32
    var activity_level_sched: Int32
    var fraction_radiant: Real64
    var fraction_convected: Real64
    var work_eff_sched: Int32
    var clothing_sched: Int32
    var air_velocity_sched: Int32
    var fanger: Bool
    var pierce: Bool
    var ksu: Bool
    var mrt_calc_type: Int32
    var surface_ptr: Int32
    var angle_factor_list_name: String
    var angle_factor_list_ptr: Int32
    var user_spec_sens_frac: Real64
    var show_55_warning: Bool


struct NominalElectricEquipment(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var design_level: Real64
    var fraction_latent: Real64
    var fraction_radiant: Real64
    var fraction_lost: Real64
    var fraction_convected: Real64
    var end_use_subcategory: String


struct NominalGasEquipment(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var design_level: Real64
    var fraction_latent: Real64
    var fraction_radiant: Real64
    var fraction_lost: Real64
    var fraction_convected: Real64
    var end_use_subcategory: String


struct NominalSteamEquipment(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var design_level: Real64
    var fraction_latent: Real64
    var fraction_radiant: Real64
    var fraction_lost: Real64
    var fraction_convected: Real64
    var end_use_subcategory: String


struct NominalHotWaterEquipment(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var design_level: Real64
    var fraction_latent: Real64
    var fraction_radiant: Real64
    var fraction_lost: Real64
    var fraction_convected: Real64
    var end_use_subcategory: String


struct NominalOtherEquipment(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var design_level: Real64
    var fraction_latent: Real64
    var fraction_radiant: Real64
    var fraction_lost: Real64
    var fraction_convected: Real64
    var end_use_subcategory: String


struct NominalBaseboardHeat(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var capat_low_temperature: Real64
    var low_temperature: Real64
    var capat_high_temperature: Real64
    var high_temperature: Real64
    var fraction_radiant: Real64
    var fraction_convected: Real64
    var end_use_subcategory: String


struct Infiltration(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var design_level: Real64


struct Ventilation(SQLiteData):
    var number: Int32
    var name: String
    var zone_ptr: Int32
    var sched_num: Int32
    var design_level: Real64


struct RoomAirModel(SQLiteData):
    var number: Int32
    var air_model_name: String
    var air_model: Int32
    var temp_couple_scheme: Int32
    var sim_air_model: Bool


struct SQLite(SQLiteProcedures):
    const REPORT_NAME_ID = 1
    const REPORT_FOR_STRING_ID = 2
    const TABLE_NAME_ID = 3
    const ROW_NAME_ID = 4
    const COLUMN_NAME_ID = 5
    const UNITS_ID = 6
    
    const LOCAL_REPORT_EACH = -1
    const LOCAL_REPORT_TIME_STEP = 0
    const LOCAL_REPORT_HOURLY = 1
    const LOCAL_REPORT_DAILY = 2
    const LOCAL_REPORT_MONTHLY = 3
    const LOCAL_REPORT_SIM = 4
    const LOCAL_REPORT_YEARLY = 5
    
    var m_writeTabularDataToSQLite: Bool
    var m_sqlDBTimeIndex: Int32
    var m_hourlyReportIndex: Int32
    var m_hourlyDataIndex: Int32
    var m_tabularDataIndex: Int32
    var m_stringIndex: Int32
    var m_errorIndex: Int32
    var m_dataIndex: Int32
    var m_extendedDataIndex: Int32
    var m_zoneSizingIndex: Int32
    var m_systemSizingIndex: Int32
    var m_componentSizingIndex: Int32
    
    var zones: DynamicVector[Zone]
    var zone_lists: DynamicVector[ZoneList]
    var zone_groups: DynamicVector[ZoneGroup]
    var schedules: DynamicVector[Schedule]
    var surfaces: DynamicVector[Surface]
    var materials: DynamicVector[Material]
    var constructions: DynamicVector[Construction]
    var nominal_lightings: DynamicVector[NominalLighting]
    var nominal_peoples: DynamicVector[NominalPeople]
    var nominal_electric_equipments: DynamicVector[NominalElectricEquipment]
    var nominal_gas_equipments: DynamicVector[NominalGasEquipment]
    var nominal_steam_equipments: DynamicVector[NominalSteamEquipment]
    var nominal_hot_water_equipments: DynamicVector[NominalHotWaterEquipment]
    var nominal_other_equipments: DynamicVector[NominalOtherEquipment]
    var nominal_baseboard_heats: DynamicVector[NominalBaseboardHeat]
    var infiltrations: DynamicVector[Infiltration]
    var ventilations: DynamicVector[Ventilation]
    var room_air_models: DynamicVector[RoomAirModel]
    
    fn __init__(inout self, error_stream: String, db_name: String, error_file_path: String,
               write_output_to_sqlite: Bool = False, write_tabular_data_to_sqlite: Bool = False):
        self.m_writeOutputToSQLite = write_output_to_sqlite
        self.m_errorStream = error_stream
        self.m_db = db_name
        self.m_writeTabularDataToSQLite = write_tabular_data_to_sqlite
        self.m_sqlDBTimeIndex = 0
        self.m_hourlyReportIndex = 0
        self.m_hourlyDataIndex = 0
        self.m_tabularDataIndex = 0
        self.m_stringIndex = 1
        self.m_errorIndex = 0
        self.m_dataIndex = 0
        self.m_extendedDataIndex = 0
        self.m_zoneSizingIndex = 0
        self.m_systemSizingIndex = 0
        self.m_componentSizingIndex = 0
        self.zones = DynamicVector[Zone]()
        self.zone_lists = DynamicVector[ZoneList]()
        self.zone_groups = DynamicVector[ZoneGroup]()
        self.schedules = DynamicVector[Schedule]()
        self.surfaces = DynamicVector[Surface]()
        self.materials = DynamicVector[Material]()
        self.constructions = DynamicVector[Construction]()
        self.nominal_lightings = DynamicVector[NominalLighting]()
        self.nominal_peoples = DynamicVector[NominalPeople]()
        self.nominal_electric_equipments = DynamicVector[NominalElectricEquipment]()
        self.nominal_gas_equipments = DynamicVector[NominalGasEquipment]()
        self.nominal_steam_equipments = DynamicVector[NominalSteamEquipment]()
        self.nominal_hot_water_equipments = DynamicVector[NominalHotWaterEquipment]()
        self.nominal_other_equipments = DynamicVector[NominalOtherEquipment]()
        self.nominal_baseboard_heats = DynamicVector[NominalBaseboardHeat]()
        self.infiltrations = DynamicVector[Infiltration]()
        self.ventilations = DynamicVector[Ventilation]()
        self.room_air_models = DynamicVector[RoomAirModel]()
        
        if self.m_writeOutputToSQLite:
            _ = self.sqlite_execute_command("PRAGMA locking_mode = EXCLUSIVE;")
            _ = self.sqlite_execute_command("PRAGMA journal_mode = OFF;")
            _ = self.sqlite_execute_command("PRAGMA synchronous = OFF;")
            _ = self.sqlite_execute_command("PRAGMA encoding=\"UTF-8\";")
            _ = self.sqlite_execute_command("PRAGMA foreign_keys = OFF;")
            
            self.initialize_simulations_table()
            self.initialize_environment_periods_table()
            self.initialize_errors_table()
            self.initialize_time_indices_table()
            self.initialize_zone_info_table()
            self.initialize_zone_list_table()
            self.initialize_zone_group_table()
            self.initialize_zone_info_zone_list_table()
            self.initialize_schedules_table()
            self.initialize_materials_table()
            self.initialize_constructions_tables()
            self.initialize_surfaces_table()
            self.initialize_report_data_dictionary_table()
            self.initialize_report_data_tables()
            self.initialize_nominal_people_table()
            self.initialize_nominal_lighting_table()
            self.initialize_nominal_electric_equipment_table()
            self.initialize_nominal_gas_equipment_table()
            self.initialize_nominal_steam_equipment_table()
            self.initialize_nominal_hot_water_equipment_table()
            self.initialize_nominal_other_equipment_table()
            self.initialize_nominal_baseboard_heat_table()
            self.initialize_nominal_infiltration_table()
            self.initialize_nominal_ventilation_table()
            self.initialize_zone_sizing_table()
            self.initialize_system_sizing_table()
            self.initialize_component_sizing_table()
            self.initialize_room_air_model_table()
            self.initialize_daylight_map_tables()
            self.initialize_views()
            
            if self.m_writeTabularDataToSQLite:
                self.initialize_tabular_data_table()
                self.initialize_tabular_data_view()
    
    fn write_output_to_sqlite(self) -> Bool:
        return self.m_writeOutputToSQLite
    
    fn write_tabular_data_to_sqlite(self) -> Bool:
        return self.m_writeTabularDataToSQLite
    
    fn sqlite_begin(self):
        if self.m_writeOutputToSQLite:
            _ = self.sqlite_execute_command("BEGIN;")
    
    fn sqlite_commit(self):
        if self.m_writeOutputToSQLite:
            _ = self.sqlite_execute_command("COMMIT;")
    
    fn sqlite_rollback(self):
        if self.m_writeOutputToSQLite:
            _ = self.sqlite_execute_command("ROLLBACK;")
    
    fn sqlite_rollback_to_savepoint(self, savepoint_name: String):
        if self.m_writeOutputToSQLite:
            _ = self.sqlite_execute_command("ROLLBACK TO SAVEPOINT " + savepoint_name + ";")
    
    fn sqlite_release_savepoint(self, savepoint_name: String):
        if self.m_writeOutputToSQLite:
            _ = self.sqlite_execute_command("RELEASE SAVEPOINT " + savepoint_name + ";")
    
    fn sqlite_create_savepoint(self, savepoint_name: String):
        if self.m_writeOutputToSQLite:
            _ = self.sqlite_execute_command("SAVEPOINT " + savepoint_name + ";")
    
    fn sqlite_write_message(self, message: String):
        if self.m_writeOutputToSQLite:
            self.m_errorStream += "SQLite3 message, " + message + "\n"
    
    fn initialize_report_data_dictionary_table(self):
        let sql = "CREATE TABLE ReportDataDictionary(ReportDataDictionaryIndex INTEGER PRIMARY KEY, IsMeter INTEGER, Type TEXT, IndexGroup TEXT, TimestepType TEXT, KeyValue TEXT, Name TEXT, ReportingFrequency TEXT, ScheduleName TEXT, Units TEXT);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_report_data_tables(self):
        let sql = "CREATE TABLE ReportData (ReportDataIndex INTEGER PRIMARY KEY, TimeIndex INTEGER, ReportDataDictionaryIndex INTEGER, Value REAL, FOREIGN KEY(TimeIndex) REFERENCES Time(TimeIndex) ON DELETE CASCADE ON UPDATE CASCADE FOREIGN KEY(ReportDataDictionaryIndex) REFERENCES ReportDataDictionary(ReportDataDictionaryIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
        
        let sql2 = "CREATE TABLE ReportExtendedData (ReportExtendedDataIndex INTEGER PRIMARY KEY, ReportDataIndex INTEGER, MaxValue REAL, MaxMonth INTEGER, MaxDay INTEGER, MaxHour INTEGER, MaxStartMinute INTEGER, MaxMinute INTEGER, MinValue REAL, MinMonth INTEGER, MinDay INTEGER, MinHour INTEGER, MinStartMinute INTEGER, MinMinute INTEGER, FOREIGN KEY(ReportDataIndex) REFERENCES ReportData(ReportDataIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql2)
    
    fn initialize_time_indices_table(self):
        let sql = "CREATE TABLE Time (TimeIndex INTEGER PRIMARY KEY, Year INTEGER, Month INTEGER, Day INTEGER, Hour INTEGER, Minute INTEGER, Dst INTEGER, Interval INTEGER, IntervalType INTEGER, SimulationDays INTEGER, DayType TEXT, EnvironmentPeriodIndex INTEGER, WarmupFlag INTEGER);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_zone_info_table(self):
        let sql = "CREATE TABLE Zones (ZoneIndex INTEGER PRIMARY KEY, ZoneName TEXT, RelNorth REAL, OriginX REAL, OriginY REAL, OriginZ REAL, CentroidX REAL, CentroidY REAL, CentroidZ REAL, OfType INTEGER, Multiplier REAL, ListMultiplier REAL, MinimumX REAL, MaximumX REAL, MinimumY REAL, MaximumY REAL, MinimumZ REAL, MaximumZ REAL, CeilingHeight REAL, Volume REAL, InsideConvectionAlgo INTEGER, OutsideConvectionAlgo INTEGER, FloorArea REAL, ExtGrossWallArea REAL, ExtNetWallArea REAL, ExtWindowArea REAL, IsPartOfTotalArea INTEGER);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_zone_info_zone_list_table(self):
        let sql = "CREATE TABLE ZoneInfoZoneLists (ZoneListIndex INTEGER NOT NULL, ZoneIndex INTEGER NOT NULL, PRIMARY KEY(ZoneListIndex, ZoneIndex), FOREIGN KEY(ZoneListIndex) REFERENCES ZoneLists(ZoneListIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_people_table(self):
        let sql = "CREATE TABLE NominalPeople (NominalPeopleIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, NumberOfPeople INTEGER, NumberOfPeopleScheduleIndex INTEGER, ActivityScheduleIndex INTEGER, FractionRadiant REAL, FractionConvected REAL, WorkEfficiencyScheduleIndex INTEGER, ClothingEfficiencyScheduleIndex INTEGER, AirVelocityScheduleIndex INTEGER, Fanger INTEGER, Pierce INTEGER, KSU INTEGER, MRTCalcType INTEGER, SurfaceIndex INTEGER, AngleFactorListName TEXT, AngleFactorList INTEGER, UserSpecifeidSensibleFraction REAL, Show55Warning INTEGER, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(NumberOfPeopleScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE, FOREIGN KEY(ActivityScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE, FOREIGN KEY(WorkEfficiencyScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE, FOREIGN KEY(ClothingEfficiencyScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE, FOREIGN KEY(AirVelocityScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE, FOREIGN KEY(SurfaceIndex) REFERENCES Surfaces(SurfaceIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_lighting_table(self):
        let sql = "CREATE TABLE NominalLighting (NominalLightingIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, ScheduleIndex INTEGER, DesignLevel REAL, FractionReturnAir REAL, FractionRadiant REAL, FractionShortWave REAL, FractionReplaceable REAL, FractionConvected REAL, EndUseSubcategory TEXT, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_electric_equipment_table(self):
        let sql = "CREATE TABLE NominalElectricEquipment (NominalElectricEquipmentIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, ScheduleIndex INTEGER, DesignLevel REAL, FractionLatent REAL, FractionRadiant REAL, FractionLost REAL, FractionConvected REAL, EndUseSubcategory TEXT, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_gas_equipment_table(self):
        let sql = "CREATE TABLE NominalGasEquipment(NominalGasEquipmentIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, ScheduleIndex INTEGER, DesignLevel REAL, FractionLatent REAL, FractionRadiant REAL, FractionLost REAL, FractionConvected REAL, EndUseSubcategory TEXT, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_steam_equipment_table(self):
        let sql = "CREATE TABLE NominalSteamEquipment(NominalSteamEquipmentIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, ScheduleIndex INTEGER, DesignLevel REAL, FractionLatent REAL, FractionRadiant REAL, FractionLost REAL, FractionConvected REAL, EndUseSubcategory TEXT, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_hot_water_equipment_table(self):
        let sql = "CREATE TABLE NominalHotWaterEquipment(NominalHotWaterEquipmentIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, SchedNo INTEGER, DesignLevel REAL, FractionLatent REAL, FractionRadiant REAL, FractionLost REAL, FractionConvected REAL, EndUseSubcategory TEXT, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(SchedNo) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_other_equipment_table(self):
        let sql = "CREATE TABLE NominalOtherEquipment(NominalOtherEquipmentIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, ScheduleIndex INTEGER, DesignLevel REAL, FractionLatent REAL, FractionRadiant REAL, FractionLost REAL, FractionConvected REAL, EndUseSubcategory TEXT, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_baseboard_heat_table(self):
        let sql = "CREATE TABLE NominalBaseboardHeaters(NominalBaseboardHeaterIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, ScheduleIndex INTEGER, CapatLowTemperature REAL, LowTemperature REAL, CapatHighTemperature REAL, HighTemperature REAL, FractionRadiant REAL, FractionConvected REAL, EndUseSubcategory TEXT, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_surfaces_table(self):
        let sql = "CREATE TABLE Surfaces(SurfaceIndex INTEGER PRIMARY KEY, SurfaceName TEXT, ConstructionIndex INTEGER, ClassName TEXT, Area REAL, GrossArea REAL, Perimeter REAL, Azimuth REAL, Height REAL, Reveal REAL, Shape INTEGER, Sides INTEGER, Tilt REAL, Width REAL, HeatTransferSurf INTEGER, BaseSurfaceIndex INTEGER, ZoneIndex INTEGER, ExtBoundCond INTEGER, ExtSolar INTEGER, ExtWind INTEGER, FOREIGN KEY(ConstructionIndex) REFERENCES Constructions(ConstructionIndex) ON UPDATE CASCADE, FOREIGN KEY(BaseSurfaceIndex) REFERENCES Surfaces(SurfaceIndex) ON UPDATE CASCADE, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_constructions_tables(self):
        let sql = "CREATE TABLE Constructions(ConstructionIndex INTEGER PRIMARY KEY, Name TEXT, TotalLayers INTEGER, TotalSolidLayers INTEGER, TotalGlassLayers INTEGER, InsideAbsorpVis REAL, OutsideAbsorpVis REAL, InsideAbsorpSolar REAL, OutsideAbsorpSolar REAL, InsideAbsorpThermal REAL, OutsideAbsorpThermal REAL, OutsideRoughness INTEGER, TypeIsWindow INTEGER, Uvalue REAL);"
        _ = self.sqlite_execute_command(sql)
        
        let sql2 = "CREATE TABLE ConstructionLayers(ConstructionLayersIndex INTEGER PRIMARY KEY, ConstructionIndex INTEGER, LayerIndex INTEGER, MaterialIndex INTEGER, FOREIGN KEY(ConstructionIndex) REFERENCES Constructions(ConstructionIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(MaterialIndex) REFERENCES Materials(MaterialIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql2)
    
    fn initialize_materials_table(self):
        let sql = "CREATE TABLE Materials(MaterialIndex INTEGER PRIMARY KEY, Name TEXT, MaterialType INTEGER, Roughness INTEGER, Conductivity REAL, Density REAL, IsoMoistCap REAL, Porosity REAL, Resistance REAL, ROnly INTEGER, SpecHeat REAL, ThermGradCoef REAL, Thickness REAL, VaporDiffus REAL);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_zone_list_table(self):
        let sql = "CREATE TABLE ZoneLists(ZoneListIndex INTEGER PRIMARY KEY, Name TEXT);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_zone_group_table(self):
        let sql = "CREATE TABLE ZoneGroups(ZoneGroupIndex INTEGER PRIMARY KEY, ZoneGroupName TEXT, ZoneListIndex INTEGER, ZoneListMultiplier INTEGER, FOREIGN KEY(ZoneListIndex) REFERENCES ZoneLists(ZoneListIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_infiltration_table(self):
        let sql = "CREATE TABLE NominalInfiltration(NominalInfiltrationIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, ScheduleIndex INTEGER, DesignLevel REAL, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_nominal_ventilation_table(self):
        let sql = "CREATE TABLE NominalVentilation(NominalVentilationIndex INTEGER PRIMARY KEY, ObjectName TEXT, ZoneIndex INTEGER, ScheduleIndex INTEGER, DesignLevel REAL, FOREIGN KEY(ZoneIndex) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY(ScheduleIndex) REFERENCES Schedules(ScheduleIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_zone_sizing_table(self):
        let sql = "CREATE TABLE ZoneSizes(ZoneSizesIndex INTEGER PRIMARY KEY, ZoneName TEXT, LoadType TEXT, CalcDesLoad REAL, UserDesLoad REAL, CalcDesFlow REAL, UserDesFlow REAL, DesDayName TEXT, PeakHrMin TEXT, PeakTemp REAL, PeakHumRat REAL, CalcOutsideAirFlow REAL, DOASHeatAddRate REAL);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_system_sizing_table(self):
        let sql = "CREATE TABLE SystemSizes(SystemSizesIndex INTEGER PRIMARY KEY, SystemName TEXT, LoadType TEXT, PeakLoadType TEXT, UserDesCap REAL, CalcDesVolFlow REAL, UserDesVolFlow REAL, DesDayName TEXT, PeakHrMin TEXT);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_component_sizing_table(self):
        let sql = "CREATE TABLE ComponentSizes(ComponentSizesIndex INTEGER PRIMARY KEY, CompType TEXT, CompName TEXT, Description TEXT, Value REAL, Units TEXT, StrValue TEXT);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_room_air_model_table(self):
        let sql = "CREATE TABLE RoomAirModels(ZoneIndex INTEGER PRIMARY KEY, AirModelName TEXT, AirModelType INTEGER, TempCoupleScheme INTEGER, SimAirModel INTEGER);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_schedules_table(self):
        let sql = "CREATE TABLE Schedules(ScheduleIndex INTEGER PRIMARY KEY, ScheduleName TEXT, ScheduleType TEXT, ScheduleMinimum REAL, ScheduleMaximum REAL);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_daylight_map_tables(self):
        let sql = "CREATE TABLE DaylightMaps(MapNumber INTEGER PRIMARY KEY, MapName TEXT, Environment TEXT, Zone INTEGER, ReferencePts TEXT, Z REAL, FOREIGN KEY(Zone) REFERENCES Zones(ZoneIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
        
        let sql2 = "CREATE TABLE DaylightMapHourlyReports(HourlyReportIndex INTEGER PRIMARY KEY, MapNumber INTEGER, Year INTEGER, Month INTEGER, DayOfMonth INTEGER, Hour INTEGER, FOREIGN KEY(MapNumber) REFERENCES DaylightMaps(MapNumber) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql2)
        
        let sql3 = "CREATE TABLE DaylightMapHourlyData(HourlyDataIndex INTEGER PRIMARY KEY, HourlyReportIndex INTEGER, X REAL, Y REAL, Illuminance REAL, FOREIGN KEY(HourlyReportIndex) REFERENCES DaylightMapHourlyReports(HourlyReportIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql3)
    
    fn initialize_views(self):
        let sql = "CREATE VIEW ReportVariableWithTime AS SELECT rd.ReportDataIndex, rd.TimeIndex, rd.ReportDataDictionaryIndex, red.ReportExtendedDataIndex, rd.Value, t.Month, t.Day, t.Hour, t.Minute, t.Dst, t.Interval, t.IntervalType, t.SimulationDays, t.DayType, t.EnvironmentPeriodIndex, t.WarmupFlag, rdd.IsMeter, rdd.Type, rdd.IndexGroup, rdd.TimestepType, rdd.KeyValue, rdd.Name, rdd.ReportingFrequency, rdd.ScheduleName, rdd.Units, red.MaxValue, red.MaxMonth, red.MaxDay, red.MaxStartMinute, red.MaxMinute, red.MinValue, red.MinMonth, red.MinDay, red.MinStartMinute, red.MinMinute FROM ReportData As rd INNER JOIN ReportDataDictionary As rdd ON rd.ReportDataDictionaryIndex = rdd.ReportDataDictionaryIndex LEFT OUTER JOIN ReportExtendedData As red ON rd.ReportDataIndex = red.ReportDataIndex INNER JOIN Time As t ON rd.TimeIndex = t.TimeIndex;"
        _ = self.sqlite_execute_command(sql)
        
        let sql2 = "CREATE VIEW ReportVariableData AS SELECT rd.ReportDataIndex As rowid, rd.TimeIndex, rd.ReportDataDictionaryIndex As ReportVariableDataDictionaryIndex, rd.Value As VariableValue, red.ReportExtendedDataIndex As ReportVariableExtendedDataIndex FROM ReportData As rd LEFT OUTER JOIN ReportExtendedData As red ON rd.ReportDataIndex = red.ReportDataIndex;"
        _ = self.sqlite_execute_command(sql2)
        
        let sql3 = "CREATE VIEW ReportVariableDataDictionary AS SELECT rdd.ReportDataDictionaryIndex As ReportVariableDataDictionaryIndex, rdd.Type As VariableType, rdd.IndexGroup, rdd.TimestepType, rdd.KeyValue, rdd.Name As VariableName, rdd.ReportingFrequency, rdd.ScheduleName, rdd.Units As VariableUnits FROM ReportDataDictionary As rdd;"
        _ = self.sqlite_execute_command(sql3)
        
        let sql4 = "CREATE VIEW ReportVariableExtendedData AS SELECT red.ReportExtendedDataIndex As ReportVariableExtendedDataIndex, red.MaxValue, red.MaxMonth, red.MaxDay, red.MaxStartMinute, red.MaxMinute, red.MinValue, red.MinMonth, red.MinDay, red.MinStartMinute, red.MinMinute FROM ReportExtendedData As red;"
        _ = self.sqlite_execute_command(sql4)
        
        let sql5 = "CREATE VIEW ReportMeterData AS SELECT rd.ReportDataIndex As rowid, rd.TimeIndex, rd.ReportDataDictionaryIndex As ReportMeterDataDictionaryIndex, rd.Value As VariableValue, red.ReportExtendedDataIndex As ReportVariableExtendedDataIndex FROM ReportData As rd LEFT OUTER JOIN ReportExtendedData As red ON rd.ReportDataIndex = red.ReportDataIndex INNER JOIN ReportDataDictionary As rdd ON rd.ReportDataDictionaryIndex = rdd.ReportDataDictionaryIndex WHERE rdd.IsMeter = 1;"
        _ = self.sqlite_execute_command(sql5)
        
        let sql6 = "CREATE VIEW ReportMeterDataDictionary AS SELECT rdd.ReportDataDictionaryIndex As ReportMeterDataDictionaryIndex, rdd.Type As VariableType, rdd.IndexGroup, rdd.TimestepType, rdd.KeyValue, rdd.Name As VariableName, rdd.ReportingFrequency, rdd.ScheduleName, rdd.Units As VariableUnits FROM ReportDataDictionary As rdd WHERE rdd.IsMeter = 1;"
        _ = self.sqlite_execute_command(sql6)
        
        let sql7 = "CREATE VIEW ReportMeterExtendedData AS SELECT red.ReportExtendedDataIndex As ReportMeterExtendedDataIndex, red.MaxValue, red.MaxMonth, red.MaxDay, red.MaxStartMinute, red.MaxMinute, red.MinValue, red.MinMonth, red.MinDay, red.MinStartMinute, red.MinMinute FROM ReportExtendedData As red LEFT OUTER JOIN ReportData As rd ON rd.ReportDataIndex = red.ReportDataIndex INNER JOIN ReportDataDictionary As rdd ON rd.ReportDataDictionaryIndex = rdd.ReportDataDictionaryIndex WHERE rdd.IsMeter = 1;"
        _ = self.sqlite_execute_command(sql7)
    
    fn initialize_simulations_table(self):
        let sql = "CREATE TABLE Simulations(SimulationIndex INTEGER PRIMARY KEY, EnergyPlusVersion TEXT, TimeStamp TEXT, NumTimestepsPerHour INTEGER, Completed BOOL, CompletedSuccessfully BOOL);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_errors_table(self):
        let sql = "CREATE TABLE Errors(ErrorIndex INTEGER PRIMARY KEY, SimulationIndex INTEGER, ErrorType INTEGER, ErrorMessage TEXT, Count INTEGER, FOREIGN KEY(SimulationIndex) REFERENCES Simulations(SimulationIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_environment_periods_table(self):
        let sql = "CREATE TABLE EnvironmentPeriods(EnvironmentPeriodIndex INTEGER PRIMARY KEY, SimulationIndex INTEGER, EnvironmentName TEXT, EnvironmentType INTEGER, FOREIGN KEY(SimulationIndex) REFERENCES Simulations(SimulationIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_tabular_data_table(self):
        let sql = "CREATE TABLE StringTypes(StringTypeIndex INTEGER PRIMARY KEY, Value TEXT);"
        _ = self.sqlite_execute_command(sql)
        _ = self.sqlite_execute_command("INSERT INTO StringTypes VALUES(1,'ReportName');")
        _ = self.sqlite_execute_command("INSERT INTO StringTypes VALUES(2,'ReportForString');")
        _ = self.sqlite_execute_command("INSERT INTO StringTypes VALUES(3,'TableName');")
        _ = self.sqlite_execute_command("INSERT INTO StringTypes VALUES(4,'RowName');")
        _ = self.sqlite_execute_command("INSERT INTO StringTypes VALUES(5,'ColumnName');")
        _ = self.sqlite_execute_command("INSERT INTO StringTypes VALUES(6,'Units');")
        
        let sql2 = "CREATE TABLE Strings(StringIndex INTEGER PRIMARY KEY, StringTypeIndex INTEGER, Value TEXT, UNIQUE(StringTypeIndex, Value), FOREIGN KEY(StringTypeIndex) REFERENCES StringTypes(StringTypeIndex) ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql2)
        
        let sql3 = "CREATE TABLE TabularData(TabularDataIndex INTEGER PRIMARY KEY, ReportNameIndex INTEGER, ReportForStringIndex INTEGER, TableNameIndex INTEGER, RowNameIndex INTEGER, ColumnNameIndex INTEGER, UnitsIndex INTEGER, SimulationIndex INTEGER, RowId INTEGER, ColumnId INTEGER, Value TEXT, FOREIGN KEY(ReportNameIndex) REFERENCES Strings(StringIndex) ON UPDATE CASCADE FOREIGN KEY(ReportForStringIndex) REFERENCES Strings(StringIndex) ON UPDATE CASCADE FOREIGN KEY(TableNameIndex) REFERENCES Strings(StringIndex) ON UPDATE CASCADE FOREIGN KEY(RowNameIndex) REFERENCES Strings(StringIndex) ON UPDATE CASCADE FOREIGN KEY(ColumnNameIndex) REFERENCES Strings(StringIndex) ON UPDATE CASCADE FOREIGN KEY(UnitsIndex) REFERENCES Strings(StringIndex) ON UPDATE CASCADE FOREIGN KEY(SimulationIndex) REFERENCES Simulations(SimulationIndex) ON DELETE CASCADE ON UPDATE CASCADE);"
        _ = self.sqlite_execute_command(sql3)
    
    fn initialize_tabular_data_view(self):
        let sql = "CREATE VIEW TabularDataWithStrings AS SELECT td.TabularDataIndex, td.Value As Value, reportn.Value As ReportName, fs.Value As ReportForString, tn.Value As TableName, rn.Value As RowName, cn.Value As ColumnName, u.Value As Units FROM TabularData As td INNER JOIN Strings As reportn ON reportn.StringIndex=td.ReportNameIndex INNER JOIN Strings As fs ON fs.StringIndex=td.ReportForStringIndex INNER JOIN Strings As tn ON tn.StringIndex=td.TableNameIndex INNER JOIN Strings As rn ON rn.StringIndex=td.RowNameIndex INNER JOIN Strings As cn ON cn.StringIndex=td.ColumnNameIndex INNER JOIN Strings As u ON u.StringIndex=td.UnitsIndex;"
        _ = self.sqlite_execute_command(sql)
    
    fn initialize_indexes(self):
        if self.m_writeOutputToSQLite:
            _ = self.sqlite_execute_command("CREATE INDEX rddMTR ON ReportDataDictionary (IsMeter);")
            _ = self.sqlite_execute_command("CREATE INDEX redRD ON ReportExtendedData (ReportDataIndex);")


fn create_sqlite_database(state) -> Optional[SQLite]:
    return None


fn create_sqlite_zone_extended_output(state):
    pass


fn parse_sqlite_input(state, write_output_to_sqlite, write_tabular_data_to_sqlite) -> Bool:
    return False
