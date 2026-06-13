from rs0004 import Schema, ProductInformation, Description, GridVariablesCooling, LookupVariablesCooling, PerformanceMapCooling, GridVariablesStandby, LookupVariablesStandby, PerformanceMapStandby, Performance, RS0004
from loadobject_205 import loadobject_205
from ashrae205 import ashrae205_ns
from nlohmann import json
from Btwxt import Btwxt
from Courierr import Courierr
from memory import Pointer
from utils import StringRef, String

@value
struct Schema:
    var schema_title: StringRef = "Air-to-Air Direct Expansion Refrigerant System"
    var schema_version: StringRef = "1.0.0"
    var schema_description: StringRef = "Schema for ASHRAE 205 annex RS0004: Air-to-Air Direct Expansion Refrigerant System"

@value
struct ProductInformation:
    var outdoor_unit_manufacturer: String
    var outdoor_unit_manufacturer_is_set: Bool
    var outdoor_unit_model_number: ashrae205_ns.Pattern
    var outdoor_unit_model_number_is_set: Bool
    var indoor_unit_manufacturer: String
    var indoor_unit_manufacturer_is_set: Bool
    var indoor_unit_model_number: ashrae205_ns.Pattern
    var indoor_unit_model_number_is_set: Bool
    var refrigerant: String
    var refrigerant_is_set: Bool
    var compressor_type: ashrae205_ns.CompressorType
    var compressor_type_is_set: Bool

    var outdoor_unit_manufacturer_units: StringRef = ""
    var outdoor_unit_model_number_units: StringRef = ""
    var indoor_unit_manufacturer_units: StringRef = ""
    var indoor_unit_model_number_units: StringRef = ""
    var refrigerant_units: StringRef = ""
    var compressor_type_units: StringRef = ""
    var outdoor_unit_manufacturer_description: StringRef = "Outdoor unit manufacturer name"
    var outdoor_unit_model_number_description: StringRef = "Outdoor unit model number"
    var indoor_unit_manufacturer_description: StringRef = "Indoor unit manufacturer name"
    var indoor_unit_model_number_description: StringRef = "Indoor unit model number"
    var refrigerant_description: StringRef = "Refrigerant used"
    var compressor_type_description: StringRef = "Type of compressor"
    var outdoor_unit_manufacturer_name: StringRef = "outdoor_unit_manufacturer"
    var outdoor_unit_model_number_name: StringRef = "outdoor_unit_model_number"
    var indoor_unit_manufacturer_name: StringRef = "indoor_unit_manufacturer"
    var indoor_unit_model_number_name: StringRef = "indoor_unit_model_number"
    var refrigerant_name: StringRef = "refrigerant"
    var compressor_type_name: StringRef = "compressor_type"

@value
struct Description:
    var product_information: ProductInformation
    var product_information_is_set: Bool

    var product_information_units: StringRef = ""
    var product_information_description: StringRef = "Data group describing product information"
    var product_information_name: StringRef = "product_information"

@value
struct GridVariablesCooling:
    var outdoor_coil_entering_dry_bulb_temperature: List[Float64]
    var outdoor_coil_entering_dry_bulb_temperature_is_set: Bool
    var indoor_coil_entering_relative_humidity: List[Float64]
    var indoor_coil_entering_relative_humidity_is_set: Bool
    var indoor_coil_entering_dry_bulb_temperature: List[Float64]
    var indoor_coil_entering_dry_bulb_temperature_is_set: Bool
    var indoor_coil_air_mass_flow_rate: List[Float64]
    var indoor_coil_air_mass_flow_rate_is_set: Bool
    var compressor_sequence_number: List[Int32]
    var compressor_sequence_number_is_set: Bool
    var ambient_absolute_air_pressure: List[Float64]
    var ambient_absolute_air_pressure_is_set: Bool

    var outdoor_coil_entering_dry_bulb_temperature_units: StringRef = "K"
    var indoor_coil_entering_relative_humidity_units: StringRef = "-"
    var indoor_coil_entering_dry_bulb_temperature_units: StringRef = "K"
    var indoor_coil_air_mass_flow_rate_units: StringRef = "kg/s"
    var compressor_sequence_number_units: StringRef = "-"
    var ambient_absolute_air_pressure_units: StringRef = "Pa"
    var outdoor_coil_entering_dry_bulb_temperature_description: StringRef = "Dry bulb temperature of the air entering the outdoor coil"
    var indoor_coil_entering_relative_humidity_description: StringRef = "Relative humidity of the air entering the indoor coil"
    var indoor_coil_entering_dry_bulb_temperature_description: StringRef = "Dry bulb temperature of the air entering the indoor coil"
    var indoor_coil_air_mass_flow_rate_description: StringRef = "Mass flow rate of air entering the indoor coil"
    var compressor_sequence_number_description: StringRef = "Index indicating the relative capacity order of the compressor speed/stage expressed in order from lowest capacity (starting at 1) to highest capacity"
    var ambient_absolute_air_pressure_description: StringRef = "Ambient absolute air pressure"
    var outdoor_coil_entering_dry_bulb_temperature_name: StringRef = "outdoor_coil_entering_dry_bulb_temperature"
    var indoor_coil_entering_relative_humidity_name: StringRef = "indoor_coil_entering_relative_humidity"
    var indoor_coil_entering_dry_bulb_temperature_name: StringRef = "indoor_coil_entering_dry_bulb_temperature"
    var indoor_coil_air_mass_flow_rate_name: StringRef = "indoor_coil_air_mass_flow_rate"
    var compressor_sequence_number_name: StringRef = "compressor_sequence_number"
    var ambient_absolute_air_pressure_name: StringRef = "ambient_absolute_air_pressure"

@value
struct LookupVariablesCooling:
    var gross_total_capacity: List[Float64]
    var gross_total_capacity_is_set: Bool
    var gross_sensible_capacity: List[Float64]
    var gross_sensible_capacity_is_set: Bool
    var gross_power: List[Float64]
    var gross_power_is_set: Bool

    var gross_total_capacity_units: StringRef = "W"
    var gross_sensible_capacity_units: StringRef = "W"
    var gross_power_units: StringRef = "W"
    var gross_total_capacity_description: StringRef = "Total heat removed by the indoor coil"
    var gross_sensible_capacity_description: StringRef = "Sensible heat removed by the indoor coil"
    var gross_power_description: StringRef = "Gross power draw (of the outdoor unit)"
    var gross_total_capacity_name: StringRef = "gross_total_capacity"
    var gross_sensible_capacity_name: StringRef = "gross_sensible_capacity"
    var gross_power_name: StringRef = "gross_power"

@value
struct PerformanceMapCooling:
    var grid_variables: GridVariablesCooling
    var grid_variables_is_set: Bool
    var lookup_variables: LookupVariablesCooling
    var lookup_variables_is_set: Bool

    var grid_variables_units: StringRef = ""
    var lookup_variables_units: StringRef = ""
    var grid_variables_description: StringRef = "Data group defining the grid variables for cooling performance"
    var lookup_variables_description: StringRef = "Data group defining the lookup variables for cooling performance"
    var grid_variables_name: StringRef = "grid_variables"
    var lookup_variables_name: StringRef = "lookup_variables"

@value
struct LookupVariablesCoolingStruct:
    var gross_total_capacity: Float64
    var gross_sensible_capacity: Float64
    var gross_power: Float64

@value
struct GridVariablesStandby:
    var outdoor_coil_environment_dry_bulb_temperature: List[Float64]
    var outdoor_coil_environment_dry_bulb_temperature_is_set: Bool

    var outdoor_coil_environment_dry_bulb_temperature_units: StringRef = "K"
    var outdoor_coil_environment_dry_bulb_temperature_description: StringRef = "Dry bulb temperature of the air in the environment of the outdoor coil"
    var outdoor_coil_environment_dry_bulb_temperature_name: StringRef = "outdoor_coil_environment_dry_bulb_temperature"

@value
struct LookupVariablesStandby:
    var gross_power: List[Float64]
    var gross_power_is_set: Bool

    var gross_power_units: StringRef = "W"
    var gross_power_description: StringRef = "Gross power draw (of the outdoor unit)"
    var gross_power_name: StringRef = "gross_power"

@value
struct PerformanceMapStandby:
    var grid_variables: GridVariablesStandby
    var grid_variables_is_set: Bool
    var lookup_variables: LookupVariablesStandby
    var lookup_variables_is_set: Bool

    var grid_variables_units: StringRef = ""
    var lookup_variables_units: StringRef = ""
    var grid_variables_description: StringRef = "Data group defining the grid variables for standby performance"
    var lookup_variables_description: StringRef = "Data group defining the lookup variables for standby performance"
    var grid_variables_name: StringRef = "grid_variables"
    var lookup_variables_name: StringRef = "lookup_variables"

@value
struct LookupVariablesStandbyStruct:
    var gross_power: Float64

@value
struct Performance:
    var compressor_speed_control_type: ashrae205_ns.SpeedControlType
    var compressor_speed_control_type_is_set: Bool
    var cycling_degradation_coefficient: Float64
    var cycling_degradation_coefficient_is_set: Bool
    var performance_map_cooling: PerformanceMapCooling
    var performance_map_cooling_is_set: Bool
    var performance_map_standby: PerformanceMapStandby
    var performance_map_standby_is_set: Bool

    var compressor_speed_control_type_units: StringRef = ""
    var cycling_degradation_coefficient_units: StringRef = "-"
    var performance_map_cooling_units: StringRef = ""
    var performance_map_standby_units: StringRef = ""
    var compressor_speed_control_type_description: StringRef = "Method used to control different speeds of the compressor"
    var cycling_degradation_coefficient_description: StringRef = "Cycling degradation coefficient (C~D~) as described in AHRI 210/240"
    var performance_map_cooling_description: StringRef = "Data group describing cooling performance over a range of conditions"
    var performance_map_standby_description: StringRef = "Data group describing standby performance"
    var compressor_speed_control_type_name: StringRef = "compressor_speed_control_type"
    var cycling_degradation_coefficient_name: StringRef = "cycling_degradation_coefficient"
    var performance_map_cooling_name: StringRef = "performance_map_cooling"
    var performance_map_standby_name: StringRef = "performance_map_standby"

@value
struct RS0004:
    var metadata: ashrae205_ns.Metadata
    var metadata_is_set: Bool
    var description: Description
    var description_is_set: Bool
    var performance: Performance
    var performance_is_set: Bool

    var metadata_units: StringRef = ""
    var description_units: StringRef = ""
    var performance_units: StringRef = ""
    var metadata_description: StringRef = "Metadata data group"
    var description_description: StringRef = "Data group describing product and rating information"
    var performance_description: StringRef = "Data group containing performance information"
    var metadata_name: StringRef = "metadata"
    var description_name: StringRef = "description"
    var performance_name: StringRef = "performance"

    var logger: Pointer[Courierr.Courierr] = Pointer[Courierr.Courierr]()

def from_json(j: json, x: Pointer[ProductInformation]):
    a205_json_get[String](j, *RS0004.logger, "outdoor_unit_manufacturer", x.outdoor_unit_manufacturer, x.outdoor_unit_manufacturer_is_set, False)
    a205_json_get[ashrae205_ns.Pattern](j, *RS0004.logger, "outdoor_unit_model_number", x.outdoor_unit_model_number, x.outdoor_unit_model_number_is_set, False)
    a205_json_get[String](j, *RS0004.logger, "indoor_unit_manufacturer", x.indoor_unit_manufacturer, x.indoor_unit_manufacturer_is_set, False)
    a205_json_get[ashrae205_ns.Pattern](j, *RS0004.logger, "indoor_unit_model_number", x.indoor_unit_model_number, x.indoor_unit_model_number_is_set, False)
    a205_json_get[String](j, *RS0004.logger, "refrigerant", x.refrigerant, x.refrigerant_is_set, False)
    a205_json_get[ashrae205_ns.CompressorType](j, *RS0004.logger, "compressor_type", x.compressor_type, x.compressor_type_is_set, False)

def from_json(j: json, x: Pointer[Description]):
    a205_json_get[ProductInformation](j, *RS0004.logger, "product_information", x.product_information, x.product_information_is_set, False)

def from_json(j: json, x: Pointer[GridVariablesCooling]):
    a205_json_get[List[Float64]](j, *RS0004.logger, "outdoor_coil_entering_dry_bulb_temperature", x.outdoor_coil_entering_dry_bulb_temperature, x.outdoor_coil_entering_dry_bulb_temperature_is_set, True)
    a205_json_get[List[Float64]](j, *RS0004.logger, "indoor_coil_entering_relative_humidity", x.indoor_coil_entering_relative_humidity, x.indoor_coil_entering_relative_humidity_is_set, True)
    a205_json_get[List[Float64]](j, *RS0004.logger, "indoor_coil_entering_dry_bulb_temperature", x.indoor_coil_entering_dry_bulb_temperature, x.indoor_coil_entering_dry_bulb_temperature_is_set, True)
    a205_json_get[List[Float64]](j, *RS0004.logger, "indoor_coil_air_mass_flow_rate", x.indoor_coil_air_mass_flow_rate, x.indoor_coil_air_mass_flow_rate_is_set, True)
    a205_json_get[List[Int32]](j, *RS0004.logger, "compressor_sequence_number", x.compressor_sequence_number, x.compressor_sequence_number_is_set, True)
    a205_json_get[List[Float64]](j, *RS0004.logger, "ambient_absolute_air_pressure", x.ambient_absolute_air_pressure, x.ambient_absolute_air_pressure_is_set, True)

def GridVariablesCooling.populate_performance_map(self: Pointer[GridVariablesCooling], performance_map: Pointer[PerformanceMapBase]):
    add_grid_axis(performance_map, self.outdoor_coil_entering_dry_bulb_temperature)
    add_grid_axis(performance_map, self.indoor_coil_entering_relative_humidity)
    add_grid_axis(performance_map, self.indoor_coil_entering_dry_bulb_temperature)
    add_grid_axis(performance_map, self.indoor_coil_air_mass_flow_rate)
    add_grid_axis(performance_map, self.compressor_sequence_number)
    add_grid_axis(performance_map, self.ambient_absolute_air_pressure)
    performance_map.finalize_grid(RS0004.logger)

def from_json(j: json, x: Pointer[LookupVariablesCooling]):
    a205_json_get[List[Float64]](j, *RS0004.logger, "gross_total_capacity", x.gross_total_capacity, x.gross_total_capacity_is_set, True)
    a205_json_get[List[Float64]](j, *RS0004.logger, "gross_sensible_capacity", x.gross_sensible_capacity, x.gross_sensible_capacity_is_set, True)
    a205_json_get[List[Float64]](j, *RS0004.logger, "gross_power", x.gross_power, x.gross_power_is_set, True)

def LookupVariablesCooling.populate_performance_map(self: Pointer[LookupVariablesCooling], performance_map: Pointer[PerformanceMapBase]):
    add_data_table(performance_map, self.gross_total_capacity)
    add_data_table(performance_map, self.gross_sensible_capacity)
    add_data_table(performance_map, self.gross_power)

def from_json(j: json, x: Pointer[PerformanceMapCooling]):
    a205_json_get[GridVariablesCooling](j, *RS0004.logger, "grid_variables", x.grid_variables, x.grid_variables_is_set, True)
    x.grid_variables.populate_performance_map(x)
    a205_json_get[LookupVariablesCooling](j, *RS0004.logger, "lookup_variables", x.lookup_variables, x.lookup_variables_is_set, True)
    x.lookup_variables.populate_performance_map(x)

def PerformanceMapCooling.initialize(self: Pointer[PerformanceMapCooling], j: json):
    a205_json_get[GridVariablesCooling](j, *RS0004.logger, "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
    self.grid_variables.populate_performance_map(self)
    a205_json_get[LookupVariablesCooling](j, *RS0004.logger, "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
    self.lookup_variables.populate_performance_map(self)

def PerformanceMapCooling.calculate_performance(self: Pointer[PerformanceMapCooling], outdoor_coil_entering_dry_bulb_temperature: Float64, indoor_coil_entering_relative_humidity: Float64, indoor_coil_entering_dry_bulb_temperature: Float64, indoor_coil_air_mass_flow_rate: Float64, compressor_sequence_number: Float64, ambient_absolute_air_pressure: Float64, performance_interpolation_method: Btwxt.InterpolationMethod) -> LookupVariablesCoolingStruct:
    var target: List[Float64] = List[Float64](outdoor_coil_entering_dry_bulb_temperature, indoor_coil_entering_relative_humidity, indoor_coil_entering_dry_bulb_temperature, indoor_coil_air_mass_flow_rate, compressor_sequence_number, ambient_absolute_air_pressure)
    var v: List[Float64] = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
    var s: LookupVariablesCoolingStruct = LookupVariablesCoolingStruct(v[0], v[1], v[2])
    return s

def from_json(j: json, x: Pointer[GridVariablesStandby]):
    a205_json_get[List[Float64]](j, *RS0004.logger, "outdoor_coil_environment_dry_bulb_temperature", x.outdoor_coil_environment_dry_bulb_temperature, x.outdoor_coil_environment_dry_bulb_temperature_is_set, True)

def GridVariablesStandby.populate_performance_map(self: Pointer[GridVariablesStandby], performance_map: Pointer[PerformanceMapBase]):
    add_grid_axis(performance_map, self.outdoor_coil_environment_dry_bulb_temperature)
    performance_map.finalize_grid(RS0004.logger)

def from_json(j: json, x: Pointer[LookupVariablesStandby]):
    a205_json_get[List[Float64]](j, *RS0004.logger, "gross_power", x.gross_power, x.gross_power_is_set, True)

def LookupVariablesStandby.populate_performance_map(self: Pointer[LookupVariablesStandby], performance_map: Pointer[PerformanceMapBase]):
    add_data_table(performance_map, self.gross_power)

def from_json(j: json, x: Pointer[PerformanceMapStandby]):
    a205_json_get[GridVariablesStandby](j, *RS0004.logger, "grid_variables", x.grid_variables, x.grid_variables_is_set, True)
    x.grid_variables.populate_performance_map(x)
    a205_json_get[LookupVariablesStandby](j, *RS0004.logger, "lookup_variables", x.lookup_variables, x.lookup_variables_is_set, True)
    x.lookup_variables.populate_performance_map(x)

def PerformanceMapStandby.initialize(self: Pointer[PerformanceMapStandby], j: json):
    a205_json_get[GridVariablesStandby](j, *RS0004.logger, "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
    self.grid_variables.populate_performance_map(self)
    a205_json_get[LookupVariablesStandby](j, *RS0004.logger, "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
    self.lookup_variables.populate_performance_map(self)

def PerformanceMapStandby.calculate_performance(self: Pointer[PerformanceMapStandby], outdoor_coil_environment_dry_bulb_temperature: Float64, performance_interpolation_method: Btwxt.InterpolationMethod) -> LookupVariablesStandbyStruct:
    var target: List[Float64] = List[Float64](outdoor_coil_environment_dry_bulb_temperature)
    var v: List[Float64] = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
    var s: LookupVariablesStandbyStruct = LookupVariablesStandbyStruct(v[0])
    return s

def from_json(j: json, x: Pointer[Performance]):
    a205_json_get[ashrae205_ns.SpeedControlType](j, *RS0004.logger, "compressor_speed_control_type", x.compressor_speed_control_type, x.compressor_speed_control_type_is_set, True)
    a205_json_get[Float64](j, *RS0004.logger, "cycling_degradation_coefficient", x.cycling_degradation_coefficient, x.cycling_degradation_coefficient_is_set, True)
    a205_json_get[PerformanceMapCooling](j, *RS0004.logger, "performance_map_cooling", x.performance_map_cooling, x.performance_map_cooling_is_set, True)
    a205_json_get[PerformanceMapStandby](j, *RS0004.logger, "performance_map_standby", x.performance_map_standby, x.performance_map_standby_is_set, True)

def from_json(j: json, x: Pointer[RS0004]):
    a205_json_get[ashrae205_ns.Metadata](j, *RS0004.logger, "metadata", x.metadata, x.metadata_is_set, True)
    a205_json_get[Description](j, *RS0004.logger, "description", x.description, x.description_is_set, False)
    a205_json_get[Performance](j, *RS0004.logger, "performance", x.performance, x.performance_is_set, True)

def RS0004.initialize(self: Pointer[RS0004], j: json):
    a205_json_get[ashrae205_ns.Metadata](j, *RS0004.logger, "metadata", self.metadata, self.metadata_is_set, True)
    a205_json_get[Description](j, *RS0004.logger, "description", self.description, self.description_is_set, False)
    a205_json_get[Performance](j, *RS0004.logger, "performance", self.performance, self.performance_is_set, True)