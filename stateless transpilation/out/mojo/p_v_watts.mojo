# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with nested data objects
#   Source: EnergyPlus/Data/EnergyPlusData.hh
# - ShowSevereError, ShowFatalError, ShowWarningMessage, ShowErrorMessage: logging
#   Source: EnergyPlus/UtilityRoutines.hh
# - SetupOutputVariable: output variable registration
#   Source: EnergyPlus/OutputProcessor.hh
# - Util.FindItemInList: find index of item in list
#   Source: EnergyPlus utilities
# - OutputProcessor constants (TimeStepType, StoreType, Group, EndUseCat)
#   Source: EnergyPlus/OutputProcessor.hh
# - Constant.Units, Constant.eResource: unit and resource enums
#   Source: EnergyPlus/Constant.hh
# - SSC C API: ssc_module_create, ssc_data_create, ssc_data_set_number, ssc_data_get_number, ssc_module_exec, ssc_module_log
#   Source: ../third_party/ssc/ssc/sscapi.h

from math import isfinite

struct ModuleType:
    alias INVALID = -1
    alias STANDARD = 0
    alias PREMIUM = 1
    alias THIN_FILM = 2
    alias Num = 3

struct ArrayType:
    alias INVALID = -1
    alias FIXED_OPEN_RACK = 0
    alias FIXED_ROOF_MOUNTED = 1
    alias ONE_AXIS = 2
    alias ONE_AXIS_BACKTRACKING = 3
    alias TWO_AXIS = 4
    alias Num = 5

struct GeometryType:
    alias INVALID = -1
    alias TILT_AZIMUTH = 0
    alias SURFACE = 1
    alias Num = 2

struct DCPowerOutput:
    var poa: Float64
    var tpoa: Float64
    var pvt: Float64
    var dc: Float64

struct IrradianceOutput:
    var solazi: Float64
    var solzen: Float64
    var solalt: Float64
    var aoi: Float64
    var stilt: Float64
    var sazi: Float64
    var rot: Float64
    var btd: Float64
    var ibeam: Float64
    var iskydiff: Float64
    var ignddiff: Float64
    var sunup: Int32

struct SurfaceData:
    var Tilt: Float64
    var Azimuth: Float64

struct SurfaceContainer:
    fn __call__(self, index: Int) -> SurfaceData:
        return SurfaceData(0.0, 0.0)
    fn __len__(self) -> Int:
        return 0

struct DataSurface:
    var Surface: SurfaceContainer

struct WeatherHourlyRecord:
    var Albedo: Float64

struct DataWeather:
    var WeatherFileLatitude: Float64
    var WeatherFileLongitude: Float64
    var WeatherFileTimeZone: Float64

struct DataGlobal:
    var TimeStepZone: Float64
    var HourOfDay: Int32
    var TimeStep: Int32
    var TimeStepsInHour: Int32
    var MinutesInTimeStep: Float64

struct DataEnvrn:
    var Year: Int32
    var Month: Int32
    var DayOfMonth: Int32
    var BeamSolarRad: Float64
    var DifSolarRad: Float64
    var OutDryBulbTemp: Float64
    var WindSpeed: Float64

struct DataHVACGlobals:
    var TimeStepSysSec: Float64

struct DataHeatBal:
    pass

struct InputProcessor:
    pass

struct DataInputProcessing:
    var inputProcessor: InputProcessor

struct EnergyPlusData:
    var dataSurface: DataSurface
    var dataWeather: DataWeather
    var dataGlobal: DataGlobal
    var dataEnvrn: DataEnvrn
    var dataHVACGlobal: DataHVACGlobals
    var dataHeatBal: DataHeatBal
    var dataInputProcessing: DataInputProcessing

struct PVWattsGenerator:
    struct _AlphaFields:
        alias NAME = 0
        alias VERSION = 1
        alias MODULE_TYPE = 2
        alias ARRAY_TYPE = 3
        alias GEOMETRY_TYPE = 4
        alias SURFACE_NAME = 5

    struct _NumFields:
        alias DC_SYSTEM_CAPACITY = 0
        alias SYSTEM_LOSSES = 1
        alias TILT_ANGLE = 2
        alias AZIMUTH_ANGLE = 3
        alias GROUND_COVERAGE_RATIO = 4

    var name_: String
    var dc_system_capacity_: Float64
    var module_type_: Int32
    var array_type_: Int32
    var system_losses_: Float64
    var geometry_type_: Int32
    var tilt_: Float64
    var azimuth_: Float64
    var surface_num_: Int32
    var ground_coverage_ratio_: Float64
    var dc_to_ac_ratio_: Float64
    var inverter_efficiency_: Float64
    var output_dc_power_: Float64
    var output_dc_energy_: Float64
    var output_ac_power_: Float64
    var output_ac_energy_: Float64
    var cell_temperature_: Float64
    var plane_of_array_irradiance_: Float64
    var shaded_percent_: Float64
    var pvwatts_module_: AnyType
    var pvwatts_data_: DictStringFloat64
    var num_time_steps_today_: Float64

    fn __init__(inout self,
                state: EnergyPlusData,
                name: String,
                dc_system_capacity: Float64,
                module_type: Int32,
                array_type: Int32,
                system_losses: Float64 = 0.14,
                geometry_type: Int32 = GeometryType.TILT_AZIMUTH,
                tilt: Float64 = 20.0,
                azimuth: Float64 = 180.0,
                surface_num: Int32 = 0,
                ground_coverage_ratio: Float64 = 0.4):
        
        self.module_type_ = module_type
        self.array_type_ = array_type
        self.geometry_type_ = geometry_type
        self.dc_to_ac_ratio_ = 1.1
        self.inverter_efficiency_ = 0.96
        self.output_dc_power_ = 1000.0
        self.output_dc_energy_ = 0.0
        self.output_ac_power_ = 0.0
        self.output_ac_energy_ = 0.0
        self.cell_temperature_ = -9999.0
        self.plane_of_array_irradiance_ = -9999.0
        self.shaded_percent_ = 0.0
        self.pvwatts_module_ = AnyType()
        self.pvwatts_data_ = DictStringFloat64()
        self.num_time_steps_today_ = 0.0
        
        var errors_found: Bool = False
        
        if name == "":
            errors_found = True
        self.name_ = name
        
        if dc_system_capacity <= 0:
            errors_found = True
        self.dc_system_capacity_ = dc_system_capacity
        
        if system_losses > 1.0 or system_losses < 0.0:
            errors_found = True
        self.system_losses_ = system_losses
        
        if self.geometry_type_ == GeometryType.TILT_AZIMUTH:
            if tilt < 0 or tilt > 90:
                errors_found = True
            self.tilt_ = tilt
            if azimuth < 0 or azimuth >= 360:
                pass
            self.azimuth_ = azimuth
        elif self.geometry_type_ == GeometryType.SURFACE:
            if surface_num == 0 or surface_num > state.dataSurface.Surface.__len__():
                errors_found = True
            else:
                self.surface_num_ = surface_num
                self.tilt_ = self.get_surface(state).Tilt
                self.azimuth_ = self.get_surface(state).Azimuth
        
        if ground_coverage_ratio > 1.0 or ground_coverage_ratio < 0.0:
            errors_found = True
        self.ground_coverage_ratio_ = ground_coverage_ratio
        
        self.pvwatts_data_ = DictStringFloat64(
            lat=state.dataWeather.WeatherFileLatitude,
            lon=state.dataWeather.WeatherFileLongitude,
            tz=state.dataWeather.WeatherFileTimeZone,
            time_step=state.dataGlobal.TimeStepZone,
            system_capacity=dc_system_capacity * 0.001,
            module_type=Float64(module_type),
            dc_ac_ratio=self.dc_to_ac_ratio_,
            inv_eff=self.inverter_efficiency_ * 100.0,
            losses=system_losses * 100.0,
            array_type=Float64(array_type),
            tilt=self.tilt_,
            azimuth=self.azimuth_,
            gcr=ground_coverage_ratio,
            shaded_percent=self.shaded_percent_
        )

    @staticmethod
    fn create_from_idf_obj(state: EnergyPlusData, obj_num: Int32) -> PVWattsGenerator:
        let max_alphas: Int32 = 6
        let max_numeric: Int32 = 5
        var c_alpha_field_names = DynamicVector[String](max_alphas)
        var c_numeric_field_names = DynamicVector[String](max_numeric)
        var l_numeric_field_blanks = DynamicVector[Bool](max_numeric)
        var l_alpha_field_blanks = DynamicVector[Bool](max_alphas)
        var c_alpha_args = DynamicVector[String](max_alphas)
        var r_numeric_args = DynamicVector[Float64](max_numeric)
        var num_alphas: Int32 = 0
        var num_nums: Int32 = 0
        var io_stat: Int32 = 0
        var errors_found: Bool = False
        
        var name = c_alpha_args[PVWattsGenerator._AlphaFields.NAME]
        var dc_system_capacity = r_numeric_args[PVWattsGenerator._NumFields.DC_SYSTEM_CAPACITY]
        
        var module_type: Int32 = ModuleType.INVALID
        let module_type_str = c_alpha_args[PVWattsGenerator._AlphaFields.MODULE_TYPE]
        if module_type_str == "STANDARD":
            module_type = ModuleType.STANDARD
        elif module_type_str == "PREMIUM":
            module_type = ModuleType.PREMIUM
        elif module_type_str == "THINFILM":
            module_type = ModuleType.THIN_FILM
        else:
            errors_found = True
        
        var array_type: Int32 = ArrayType.INVALID
        let array_type_str = c_alpha_args[PVWattsGenerator._AlphaFields.ARRAY_TYPE]
        if array_type_str == "FIXEDOPENRACK":
            array_type = ArrayType.FIXED_OPEN_RACK
        elif array_type_str == "FIXEDROOFMOUNTED":
            array_type = ArrayType.FIXED_ROOF_MOUNTED
        elif array_type_str == "ONEAXIS":
            array_type = ArrayType.ONE_AXIS
        elif array_type_str == "ONEAXISBACKTRACKING":
            array_type = ArrayType.ONE_AXIS_BACKTRACKING
        elif array_type_str == "TWOAXIS":
            array_type = ArrayType.TWO_AXIS
        else:
            errors_found = True
        
        var system_losses = r_numeric_args[PVWattsGenerator._NumFields.SYSTEM_LOSSES]
        
        var geometry_type: Int32 = GeometryType.INVALID
        let geometry_type_str = c_alpha_args[PVWattsGenerator._AlphaFields.GEOMETRY_TYPE]
        if geometry_type_str == "TILTAZIMUTH":
            geometry_type = GeometryType.TILT_AZIMUTH
        elif geometry_type_str == "SURFACE":
            geometry_type = GeometryType.SURFACE
        else:
            errors_found = True
        
        var tilt = r_numeric_args[PVWattsGenerator._NumFields.TILT_ANGLE]
        var azimuth = r_numeric_args[PVWattsGenerator._NumFields.AZIMUTH_ANGLE]
        
        var surface_num: Int32 = 0
        if not l_alpha_field_blanks[PVWattsGenerator._AlphaFields.SURFACE_NAME]:
            pass
        
        if num_nums < PVWattsGenerator._NumFields.GROUND_COVERAGE_RATIO + 1:
            var gen = PVWattsGenerator(
                state, name, dc_system_capacity, module_type, array_type,
                system_losses, geometry_type, tilt, azimuth, surface_num, 0.4)
            return gen
        
        var ground_coverage_ratio = r_numeric_args[PVWattsGenerator._NumFields.GROUND_COVERAGE_RATIO]
        
        var gen = PVWattsGenerator(
            state, name, dc_system_capacity, module_type, array_type,
            system_losses, geometry_type, tilt, azimuth, surface_num, ground_coverage_ratio)
        return gen

    fn setup_output_variables(inout self, state: EnergyPlusData) -> None:
        pass

    fn get_dc_system_capacity(self) -> Float64:
        return self.dc_system_capacity_

    fn get_module_type(self) -> Int32:
        return self.module_type_

    fn get_array_type(self) -> Int32:
        return self.array_type_

    fn get_system_losses(self) -> Float64:
        return self.system_losses_

    fn get_geometry_type(self) -> Int32:
        return self.geometry_type_

    fn get_tilt(self) -> Float64:
        return self.tilt_

    fn get_azimuth(self) -> Float64:
        return self.azimuth_

    fn get_surface(self, state: EnergyPlusData) -> SurfaceData:
        return state.dataSurface.Surface(self.surface_num_)

    fn get_ground_coverage_ratio(self) -> Float64:
        return self.ground_coverage_ratio_

    fn get_cell_temperature(self) -> Float64:
        return self.cell_temperature_

    fn set_cell_temperature(inout self, cell_temp: Float64) -> None:
        self.cell_temperature_ = cell_temp

    fn get_plane_of_array_irradiance(self) -> Float64:
        return self.plane_of_array_irradiance_

    fn set_plane_of_array_irradiance(inout self, poa: Float64) -> None:
        self.plane_of_array_irradiance_ = poa

    fn set_dc_to_ac_ratio(inout self, dc2ac: Float64) -> None:
        self.dc_to_ac_ratio_ = dc2ac

    fn set_inverter_efficiency(inout self, inverter_efficiency: Float64) -> None:
        self.inverter_efficiency_ = inverter_efficiency

    fn calc(inout self, state: EnergyPlusData) -> None:
        var time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec
        
        var num_time_steps_today_loc = (state.dataGlobal.HourOfDay * state.dataGlobal.TimeStepsInHour +
                                         state.dataGlobal.TimeStep)
        
        if self.num_time_steps_today_ != Float64(num_time_steps_today_loc):
            self.num_time_steps_today_ = Float64(num_time_steps_today_loc)
        else:
            self.output_dc_energy_ = self.output_dc_power_ * time_step_sys_sec
            self.output_ac_energy_ = self.output_ac_power_ * time_step_sys_sec
            return
        
        self.pvwatts_data_["year"] = Float64(state.dataEnvrn.Year)
        self.pvwatts_data_["month"] = Float64(state.dataEnvrn.Month)
        self.pvwatts_data_["day"] = Float64(state.dataEnvrn.DayOfMonth)
        self.pvwatts_data_["hour"] = Float64(state.dataGlobal.HourOfDay - 1)
        self.pvwatts_data_["minute"] = ((Float64(state.dataGlobal.TimeStep) - 0.5) *
                                         state.dataGlobal.MinutesInTimeStep)
        
        self.pvwatts_data_["beam"] = state.dataEnvrn.BeamSolarRad
        self.pvwatts_data_["diffuse"] = state.dataEnvrn.DifSolarRad
        self.pvwatts_data_["tamb"] = state.dataEnvrn.OutDryBulbTemp
        self.pvwatts_data_["wspd"] = state.dataEnvrn.WindSpeed
        
        var albedo = 0.2
        if not (isfinite(albedo) and albedo > 0.0 and albedo < 1.0):
            albedo = 0.2
        self.pvwatts_data_["alb"] = albedo
        
        self.pvwatts_data_["tcell"] = self.cell_temperature_
        self.pvwatts_data_["poa"] = self.plane_of_array_irradiance_
        
        if self.geometry_type_ == GeometryType.SURFACE:
            self.shaded_percent_ = ((1.0 - 0.0) * 100.0)
            self.pvwatts_data_["shaded_percent"] = self.shaded_percent_

    fn get_results(self) -> Tuple[Float64, Float64, Float64, Float64]:
        return (self.output_dc_power_, self.output_dc_energy_, 0.0, 0.0)
