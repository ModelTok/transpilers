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

from enum import IntEnum
from dataclasses import dataclass
from typing import Protocol, Optional, Any, Tuple, List
import math


class ModuleType(IntEnum):
    INVALID = -1
    STANDARD = 0
    PREMIUM = 1
    THIN_FILM = 2
    Num = 3


class ArrayType(IntEnum):
    INVALID = -1
    FIXED_OPEN_RACK = 0
    FIXED_ROOF_MOUNTED = 1
    ONE_AXIS = 2
    ONE_AXIS_BACKTRACKING = 3
    TWO_AXIS = 4
    Num = 5


class GeometryType(IntEnum):
    INVALID = -1
    TILT_AZIMUTH = 0
    SURFACE = 1
    Num = 2


@dataclass
class DCPowerOutput:
    poa: float
    tpoa: float
    pvt: float
    dc: float


@dataclass
class IrradianceOutput:
    solazi: float
    solzen: float
    solalt: float
    aoi: float
    stilt: float
    sazi: float
    rot: float
    btd: float
    ibeam: float
    iskydiff: float
    ignddiff: float
    sunup: int


class SurfaceData(Protocol):
    Tilt: float
    Azimuth: float


class SurfaceContainer(Protocol):
    def __call__(self, index: int) -> SurfaceData: ...
    def __len__(self) -> int: ...


class DataSurface(Protocol):
    Surface: SurfaceContainer


class WeatherHourlyRecord(Protocol):
    Albedo: float


class DataWeather(Protocol):
    WeatherFileLatitude: float
    WeatherFileLongitude: float
    WeatherFileTimeZone: float
    wvarsHrTsToday: Any


class DataGlobal(Protocol):
    TimeStepZone: float
    HourOfDay: int
    TimeStep: int
    TimeStepsInHour: int
    MinutesInTimeStep: float


class DataEnvrn(Protocol):
    Year: int
    Month: int
    DayOfMonth: int
    BeamSolarRad: float
    DifSolarRad: float
    OutDryBulbTemp: float
    WindSpeed: float


class DataHVACGlobals(Protocol):
    TimeStepSysSec: float


class DataHeatBal(Protocol):
    SurfSunlitFrac: Any


class InputProcessor(Protocol):
    def getObjectItem(self,
                      state: Any,
                      object_type: str,
                      obj_num: int,
                      c_alpha_args: List[str],
                      num_alphas: int,
                      r_numeric_args: List[float],
                      num_nums: int,
                      io_stat: int,
                      l_numeric_field_blanks: List[bool],
                      l_alpha_field_blanks: List[bool],
                      c_alpha_field_names: List[str],
                      c_numeric_field_names: List[str]) -> None: ...


class DataInputProcessing(Protocol):
    inputProcessor: InputProcessor


class EnergyPlusData(Protocol):
    dataSurface: DataSurface
    dataWeather: DataWeather
    dataGlobal: DataGlobal
    dataEnvrn: DataEnvrn
    dataHVACGlobal: DataHVACGlobals
    dataHeatBal: DataHeatBal
    dataInputProcessing: DataInputProcessing


class PVWattsGenerator:
    class _AlphaFields:
        NAME = 0
        VERSION = 1
        MODULE_TYPE = 2
        ARRAY_TYPE = 3
        GEOMETRY_TYPE = 4
        SURFACE_NAME = 5

    class _NumFields:
        DC_SYSTEM_CAPACITY = 0
        SYSTEM_LOSSES = 1
        TILT_ANGLE = 2
        AZIMUTH_ANGLE = 3
        GROUND_COVERAGE_RATIO = 4

    def __init__(self,
                 state: EnergyPlusData,
                 name: str,
                 dc_system_capacity: float,
                 module_type: ModuleType,
                 array_type: ArrayType,
                 system_losses: float = 0.14,
                 geometry_type: GeometryType = GeometryType.TILT_AZIMUTH,
                 tilt: float = 20.0,
                 azimuth: float = 180.0,
                 surface_num: int = 0,
                 ground_coverage_ratio: float = 0.4):
        
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
        self.pvwatts_module_: Any = None
        self.pvwatts_data_: dict = {}
        self.num_time_steps_today_ = 0.0
        
        errors_found = False
        
        if not name:
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
            if surface_num == 0 or surface_num > len(state.dataSurface.Surface):
                errors_found = True
            else:
                self.surface_num_ = surface_num
                self.tilt_ = self.get_surface(state).Tilt
                self.azimuth_ = self.get_surface(state).Azimuth
        else:
            assert False
        
        if ground_coverage_ratio > 1.0 or ground_coverage_ratio < 0.0:
            errors_found = True
        self.ground_coverage_ratio_ = ground_coverage_ratio
        
        if errors_found:
            pass
        
        self.pvwatts_data_ = {
            "lat": state.dataWeather.WeatherFileLatitude,
            "lon": state.dataWeather.WeatherFileLongitude,
            "tz": state.dataWeather.WeatherFileTimeZone,
            "time_step": state.dataGlobal.TimeStepZone,
            "system_capacity": dc_system_capacity * 0.001,
            "module_type": int(module_type),
            "dc_ac_ratio": self.dc_to_ac_ratio_,
            "inv_eff": self.inverter_efficiency_ * 100.0,
            "losses": system_losses * 100.0,
            "array_type": int(array_type),
            "tilt": self.tilt_,
            "azimuth": self.azimuth_,
            "gcr": ground_coverage_ratio,
            "shaded_percent": self.shaded_percent_,
        }

    @staticmethod
    def create_from_idf_obj(state: EnergyPlusData, obj_num: int) -> 'PVWattsGenerator':
        max_alphas = 6
        max_numeric = 5
        c_alpha_field_names = [''] * max_alphas
        c_numeric_field_names = [''] * max_numeric
        l_numeric_field_blanks = [False] * max_numeric
        l_alpha_field_blanks = [False] * max_alphas
        c_alpha_args = [''] * max_alphas
        r_numeric_args = [0.0] * max_numeric
        num_alphas = 0
        num_nums = 0
        io_stat = 0
        errors_found = False
        
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            "Generator:PVWatts",
            obj_num,
            c_alpha_args,
            num_alphas,
            r_numeric_args,
            num_nums,
            io_stat,
            l_numeric_field_blanks,
            l_alpha_field_blanks,
            c_alpha_field_names,
            c_numeric_field_names)
        
        name = c_alpha_args[PVWattsGenerator._AlphaFields.NAME]
        dc_system_capacity = r_numeric_args[PVWattsGenerator._NumFields.DC_SYSTEM_CAPACITY]
        
        module_type_map = {
            "STANDARD": ModuleType.STANDARD,
            "PREMIUM": ModuleType.PREMIUM,
            "THINFILM": ModuleType.THIN_FILM,
        }
        module_type = ModuleType.INVALID
        if c_alpha_args[PVWattsGenerator._AlphaFields.MODULE_TYPE] in module_type_map:
            module_type = module_type_map[c_alpha_args[PVWattsGenerator._AlphaFields.MODULE_TYPE]]
        else:
            errors_found = True
        
        array_type_map = {
            "FIXEDOPENRACK": ArrayType.FIXED_OPEN_RACK,
            "FIXEDROOFMOUNTED": ArrayType.FIXED_ROOF_MOUNTED,
            "ONEAXIS": ArrayType.ONE_AXIS,
            "ONEAXISBACKTRACKING": ArrayType.ONE_AXIS_BACKTRACKING,
            "TWOAXIS": ArrayType.TWO_AXIS,
        }
        array_type = ArrayType.INVALID
        if c_alpha_args[PVWattsGenerator._AlphaFields.ARRAY_TYPE] in array_type_map:
            array_type = array_type_map[c_alpha_args[PVWattsGenerator._AlphaFields.ARRAY_TYPE]]
        else:
            errors_found = True
        
        system_losses = r_numeric_args[PVWattsGenerator._NumFields.SYSTEM_LOSSES]
        
        geometry_type_map = {
            "TILTAZIMUTH": GeometryType.TILT_AZIMUTH,
            "SURFACE": GeometryType.SURFACE,
        }
        geometry_type = GeometryType.INVALID
        if c_alpha_args[PVWattsGenerator._AlphaFields.GEOMETRY_TYPE] in geometry_type_map:
            geometry_type = geometry_type_map[c_alpha_args[PVWattsGenerator._AlphaFields.GEOMETRY_TYPE]]
        else:
            errors_found = True
        
        tilt = r_numeric_args[PVWattsGenerator._NumFields.TILT_ANGLE]
        azimuth = r_numeric_args[PVWattsGenerator._NumFields.AZIMUTH_ANGLE]
        
        surface_num = 0
        if not l_alpha_field_blanks[PVWattsGenerator._AlphaFields.SURFACE_NAME]:
            pass
        
        if errors_found:
            pass
        
        if num_nums < PVWattsGenerator._NumFields.GROUND_COVERAGE_RATIO + 1:
            return PVWattsGenerator(
                state, name, dc_system_capacity, module_type, array_type,
                system_losses, geometry_type, tilt, azimuth, surface_num, 0.4)
        
        ground_coverage_ratio = r_numeric_args[PVWattsGenerator._NumFields.GROUND_COVERAGE_RATIO]
        
        return PVWattsGenerator(
            state, name, dc_system_capacity, module_type, array_type,
            system_losses, geometry_type, tilt, azimuth, surface_num, ground_coverage_ratio)

    def setup_output_variables(self, state: EnergyPlusData) -> None:
        pass

    def get_dc_system_capacity(self) -> float:
        return self.dc_system_capacity_

    def get_module_type(self) -> ModuleType:
        return self.module_type_

    def get_array_type(self) -> ArrayType:
        return self.array_type_

    def get_system_losses(self) -> float:
        return self.system_losses_

    def get_geometry_type(self) -> GeometryType:
        return self.geometry_type_

    def get_tilt(self) -> float:
        return self.tilt_

    def get_azimuth(self) -> float:
        return self.azimuth_

    def get_surface(self, state: EnergyPlusData) -> SurfaceData:
        return state.dataSurface.Surface(self.surface_num_)

    def get_ground_coverage_ratio(self) -> float:
        return self.ground_coverage_ratio_

    def get_cell_temperature(self) -> float:
        return self.cell_temperature_

    def set_cell_temperature(self, cell_temp: float) -> None:
        self.cell_temperature_ = cell_temp

    def get_plane_of_array_irradiance(self) -> float:
        return self.plane_of_array_irradiance_

    def set_plane_of_array_irradiance(self, poa: float) -> None:
        self.plane_of_array_irradiance_ = poa

    def set_dc_to_ac_ratio(self, dc2ac: float) -> None:
        self.dc_to_ac_ratio_ = dc2ac

    def set_inverter_efficiency(self, inverter_efficiency: float) -> None:
        self.inverter_efficiency_ = inverter_efficiency

    def calc(self, state: EnergyPlusData) -> None:
        time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec
        
        num_time_steps_today_loc = (state.dataGlobal.HourOfDay * state.dataGlobal.TimeStepsInHour +
                                     state.dataGlobal.TimeStep)
        
        if self.num_time_steps_today_ != num_time_steps_today_loc:
            self.num_time_steps_today_ = num_time_steps_today_loc
        else:
            self.output_dc_energy_ = self.output_dc_power_ * time_step_sys_sec
            self.output_ac_energy_ = self.output_ac_power_ * time_step_sys_sec
            return
        
        self.pvwatts_data_["year"] = state.dataEnvrn.Year
        self.pvwatts_data_["month"] = state.dataEnvrn.Month
        self.pvwatts_data_["day"] = state.dataEnvrn.DayOfMonth
        self.pvwatts_data_["hour"] = state.dataGlobal.HourOfDay - 1
        self.pvwatts_data_["minute"] = ((state.dataGlobal.TimeStep - 0.5) *
                                         state.dataGlobal.MinutesInTimeStep)
        
        self.pvwatts_data_["beam"] = state.dataEnvrn.BeamSolarRad
        self.pvwatts_data_["diffuse"] = state.dataEnvrn.DifSolarRad
        self.pvwatts_data_["tamb"] = state.dataEnvrn.OutDryBulbTemp
        self.pvwatts_data_["wspd"] = state.dataEnvrn.WindSpeed
        
        albedo = state.dataWeather.wvarsHrTsToday(state.dataGlobal.TimeStep,
                                                    state.dataGlobal.HourOfDay).Albedo
        if not (math.isfinite(albedo) and albedo > 0.0 and albedo < 1.0):
            albedo = 0.2
        self.pvwatts_data_["alb"] = albedo
        
        self.pvwatts_data_["tcell"] = self.cell_temperature_
        self.pvwatts_data_["poa"] = self.plane_of_array_irradiance_
        
        if self.geometry_type_ == GeometryType.SURFACE:
            self.shaded_percent_ = ((1.0 - state.dataHeatBal.SurfSunlitFrac(
                state.dataGlobal.HourOfDay, state.dataGlobal.TimeStep, self.surface_num_)) * 100.0)
            self.pvwatts_data_["shaded_percent"] = self.shaded_percent_
        
        if not self.pvwatts_module_:
            return
        
        pass

    def get_results(self) -> Tuple[float, float, float, float]:
        return (self.output_dc_power_, self.output_dc_energy_,
                0.0, 0.0)
