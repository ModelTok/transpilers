from rs0005 import Schema, ProductInformation, Description, GridVariables, LookupVariables, PerformanceMap, Performance, RS0005
from loadobject_205 import *
from nlohmann.json import json
from Btwxt import InterpolationMethod
import "Courierr" as Courierr

@value
struct Schema:
    var schema_title: StringLiteral = "Motor"
    var schema_version: StringLiteral = "1.0.0"
    var schema_description: StringLiteral = "Schema for ASHRAE 205 annex RS0005: Motor"

@value
struct ProductInformation:
    var manufacturer: String
    var manufacturer_is_set: Bool
    var model_number: ashrae205_ns.Pattern
    var model_number_is_set: Bool
    var nominal_voltage: Float64
    var nominal_voltage_is_set: Bool
    var nominal_frequency: Float64
    var nominal_frequency_is_set: Bool
    
    var manufacturer_units: StringLiteral = ""
    var model_number_units: StringLiteral = ""
    var nominal_voltage_units: StringLiteral = "V"
    var nominal_frequency_units: StringLiteral = "Hz"
    var manufacturer_description: StringLiteral = "Manufacturer name"
    var model_number_description: StringLiteral = "Model number"
    var nominal_voltage_description: StringLiteral = "Nominal voltage"
    var nominal_frequency_description: StringLiteral = "Nominal frequency"
    var manufacturer_name: StringLiteral = "manufacturer"
    var model_number_name: StringLiteral = "model_number"
    var nominal_voltage_name: StringLiteral = "nominal_voltage"
    var nominal_frequency_name: StringLiteral = "nominal_frequency"

@value
struct Description:
    var product_information: ProductInformation
    var product_information_is_set: Bool
    
    var product_information_units: StringLiteral = ""
    var product_information_description: StringLiteral = "Data group describing product information"
    var product_information_name: StringLiteral = "product_information"

@value
struct GridVariables:
    var shaft_power: List[Float64]
    var shaft_power_is_set: Bool
    var shaft_rotational_speed: List[Float64]
    var shaft_rotational_speed_is_set: Bool
    
    var shaft_power_units: StringLiteral = "W"
    var shaft_rotational_speed_units: StringLiteral = "rev/s"
    var shaft_power_description: StringLiteral = "Delivered rotational shaft power"
    var shaft_rotational_speed_description: StringLiteral = "Rotational speed of shaft"
    var shaft_power_name: StringLiteral = "shaft_power"
    var shaft_rotational_speed_name: StringLiteral = "shaft_rotational_speed"

    def populate_performance_map(inout self, performance_map: PerformanceMapBase):
        add_grid_axis(performance_map, self.shaft_power)
        add_grid_axis(performance_map, self.shaft_rotational_speed)
        performance_map.finalize_grid(RS0005.logger)

@value
struct LookupVariables:
    var efficiency: List[Float64]
    var efficiency_is_set: Bool
    var power_factor: List[Float64]
    var power_factor_is_set: Bool
    
    var efficiency_units: StringLiteral = "-"
    var power_factor_units: StringLiteral = "-"
    var efficiency_description: StringLiteral = "Efficiency of motor"
    var power_factor_description: StringLiteral = "Power factor of the motor"
    var efficiency_name: StringLiteral = "efficiency"
    var power_factor_name: StringLiteral = "power_factor"

    def populate_performance_map(inout self, performance_map: PerformanceMapBase):
        add_data_table(performance_map, self.efficiency)
        add_data_table(performance_map, self.power_factor)

@value
struct PerformanceMap(PerformanceMapBase):
    var grid_variables: GridVariables
    var grid_variables_is_set: Bool
    var lookup_variables: LookupVariables
    var lookup_variables_is_set: Bool
    
    var grid_variables_units: StringLiteral = ""
    var lookup_variables_units: StringLiteral = ""
    var grid_variables_description: StringLiteral = "Data group describing grid variables for motor performance"
    var lookup_variables_description: StringLiteral = "Data group describing lookup variables for motor performance"
    var grid_variables_name: StringLiteral = "grid_variables"
    var lookup_variables_name: StringLiteral = "lookup_variables"

    def initialize(inout self, j: json):
        a205_json_get[GridVariables](j, RS0005.logger, "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
        self.grid_variables.populate_performance_map(self)
        a205_json_get[LookupVariables](j, RS0005.logger, "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
        self.lookup_variables.populate_performance_map(self)

    def calculate_performance(self, shaft_power: Float64, shaft_rotational_speed: Float64, performance_interpolation_method: Btwxt.InterpolationMethod) -> LookupVariablesStruct:
        var target: List[Float64] = List[Float64](shaft_power, shaft_rotational_speed)
        var v = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
        var s = LookupVariablesStruct(v[0], v[1])
        return s

@value
struct Performance:
    var maximum_power: Float64
    var maximum_power_is_set: Bool
    var standby_power: Float64
    var standby_power_is_set: Bool
    var number_of_poles: Int
    var number_of_poles_is_set: Bool
    var drive_representation: rs0006_ns.RS0006
    var drive_representation_is_set: Bool
    var performance_map: PerformanceMap
    var performance_map_is_set: Bool
    
    var maximum_power_units: StringLiteral = "W"
    var standby_power_units: StringLiteral = "W"
    var number_of_poles_units: StringLiteral = ""
    var drive_representation_units: StringLiteral = ""
    var performance_map_units: StringLiteral = ""
    var maximum_power_description: StringLiteral = "Maximum operational input power to the motor"
    var standby_power_description: StringLiteral = "Power draw when motor is not operating"
    var number_of_poles_description: StringLiteral = "Number of poles"
    var drive_representation_description: StringLiteral = "The corresponding Standard 205 drive representation"
    var performance_map_description: StringLiteral = "Data group describing motor performance when operating"
    var maximum_power_name: StringLiteral = "maximum_power"
    var standby_power_name: StringLiteral = "standby_power"
    var number_of_poles_name: StringLiteral = "number_of_poles"
    var drive_representation_name: StringLiteral = "drive_representation"
    var performance_map_name: StringLiteral = "performance_map"

@value
struct RS0005:
    var metadata: ashrae205_ns.Metadata
    var metadata_is_set: Bool
    var description: Description
    var description_is_set: Bool
    var performance: Performance
    var performance_is_set: Bool
    
    var logger: Courierr.Courierr
    
    var metadata_units: StringLiteral = ""
    var description_units: StringLiteral = ""
    var performance_units: StringLiteral = ""
    var metadata_description: StringLiteral = "Metadata data group"
    var description_description: StringLiteral = "Data group describing product and rating information"
    var performance_description: StringLiteral = "Data group containing performance information"
    var metadata_name: StringLiteral = "metadata"
    var description_name: StringLiteral = "description"
    var performance_name: StringLiteral = "performance"

    def __init__(inout self, logger: Courierr.Courierr):
        self.logger = logger

    def initialize(inout self, j: json):
        a205_json_get[ashrae205_ns.Metadata](j, self.logger, "metadata", self.metadata, self.metadata_is_set, True)
        a205_json_get[Description](j, self.logger, "description", self.description, self.description_is_set, False)
        a205_json_get[Performance](j, self.logger, "performance", self.performance, self.performance_is_set, True)

def from_json_product_information(j: json, logger: Courierr.Courierr, inout x: ProductInformation):
    a205_json_get[String](j, logger, "manufacturer", x.manufacturer, x.manufacturer_is_set, False)
    a205_json_get[ashrae205_ns.Pattern](j, logger, "model_number", x.model_number, x.model_number_is_set, False)
    a205_json_get[Float64](j, logger, "nominal_voltage", x.nominal_voltage, x.nominal_voltage_is_set, False)
    a205_json_get[Float64](j, logger, "nominal_frequency", x.nominal_frequency, x.nominal_frequency_is_set, False)

def from_json_description(j: json, logger: Courierr.Courierr, inout x: Description):
    a205_json_get[ProductInformation](j, logger, "product_information", x.product_information, x.product_information_is_set, False)

def from_json_grid_variables(j: json, logger: Courierr.Courierr, inout x: GridVariables):
    a205_json_get[List[Float64]](j, logger, "shaft_power", x.shaft_power, x.shaft_power_is_set, True)
    a205_json_get[List[Float64]](j, logger, "shaft_rotational_speed", x.shaft_rotational_speed, x.shaft_rotational_speed_is_set, True)

def from_json_lookup_variables(j: json, logger: Courierr.Courierr, inout x: LookupVariables):
    a205_json_get[List[Float64]](j, logger, "efficiency", x.efficiency, x.efficiency_is_set, True)
    a205_json_get[List[Float64]](j, logger, "power_factor", x.power_factor, x.power_factor_is_set, True)

def from_json_performance_map(j: json, logger: Courierr.Courierr, inout x: PerformanceMap):
    a205_json_get[GridVariables](j, logger, "grid_variables", x.grid_variables, x.grid_variables_is_set, True)
    x.grid_variables.populate_performance_map(x)
    a205_json_get[LookupVariables](j, logger, "lookup_variables", x.lookup_variables, x.lookup_variables_is_set, True)
    x.lookup_variables.populate_performance_map(x)

def from_json_performance(j: json, logger: Courierr.Courierr, inout x: Performance):
    a205_json_get[Float64](j, logger, "maximum_power", x.maximum_power, x.maximum_power_is_set, True)
    a205_json_get[Float64](j, logger, "standby_power", x.standby_power, x.standby_power_is_set, True)
    a205_json_get[Int](j, logger, "number_of_poles", x.number_of_poles, x.number_of_poles_is_set, True)
    a205_json_get[rs0006_ns.RS0006](j, logger, "drive_representation", x.drive_representation, x.drive_representation_is_set, False)
    a205_json_get[PerformanceMap](j, logger, "performance_map", x.performance_map, x.performance_map_is_set, False)

def from_json_rs0005(j: json, logger: Courierr.Courierr, inout x: RS0005):
    a205_json_get[ashrae205_ns.Metadata](j, logger, "metadata", x.metadata, x.metadata_is_set, True)
    a205_json_get[Description](j, logger, "description", x.description, x.description_is_set, False)
    a205_json_get[Performance](j, logger, "performance", x.performance, x.performance_is_set, True)