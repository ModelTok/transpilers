from rs0006 import Schema, ProductInformation, Description, GridVariables, LookupVariables, PerformanceMap, Performance, RS0006
from loadobject_205 import PerformanceMapBase, add_grid_axis, add_data_table, a205_json_get
from ashrae205_ns import Metadata, Pattern
from nlohmann import json
from Courierr import Courierr
from Btwxt import InterpolationMethod
from memory import Pointer
from utils import StringRef

@value
struct Schema:
    var schema_title: StringRef = "Electronic Motor Drive"
    var schema_version: StringRef = "1.0.0"
    var schema_description: StringRef = "Schema for ASHRAE 205 annex RS0006: Electronic Motor Drive"

@value
struct ProductInformation:
    var manufacturer: String
    var manufacturer_is_set: Bool
    var model_number: Pattern
    var model_number_is_set: Bool
    var manufacturer_units: StringRef = ""
    var model_number_units: StringRef = ""
    var manufacturer_description: StringRef = "Manufacturer name"
    var model_number_description: StringRef = "Model number"
    var manufacturer_name: StringRef = "manufacturer"
    var model_number_name: StringRef = "model_number"

    def from_json(j: json, x: Pointer[ProductInformation]):
        a205_json_get[String](j, RS0006.logger[], "manufacturer", x[].manufacturer, x[].manufacturer_is_set, False)
        a205_json_get[Pattern](j, RS0006.logger[], "model_number", x[].model_number, x[].model_number_is_set, False)

@value
struct Description:
    var product_information: ProductInformation
    var product_information_is_set: Bool
    var product_information_units: StringRef = ""
    var product_information_description: StringRef = "Data group describing product information"
    var product_information_name: StringRef = "product_information"

    def from_json(j: json, x: Pointer[Description]):
        a205_json_get[ProductInformation](j, RS0006.logger[], "product_information", x[].product_information, x[].product_information_is_set, False)

@value
struct GridVariables:
    var output_power: List[Float64]
    var output_power_is_set: Bool
    var output_frequency: List[Float64]
    var output_frequency_is_set: Bool
    var output_power_units: StringRef = "W"
    var output_frequency_units: StringRef = "Hz"
    var output_power_description: StringRef = "Power delivered to the motor"
    var output_frequency_description: StringRef = "Frequency delivered to the motor"
    var output_power_name: StringRef = "output_power"
    var output_frequency_name: StringRef = "output_frequency"

    def from_json(j: json, x: Pointer[GridVariables]):
        a205_json_get[List[Float64]](j, RS0006.logger[], "output_power", x[].output_power, x[].output_power_is_set, True)
        a205_json_get[List[Float64]](j, RS0006.logger[], "output_frequency", x[].output_frequency, x[].output_frequency_is_set, True)

    def populate_performance_map(self, performance_map: Pointer[PerformanceMapBase]):
        add_grid_axis(performance_map, self.output_power)
        add_grid_axis(performance_map, self.output_frequency)
        performance_map[].finalize_grid(RS0006.logger)

@value
struct LookupVariables:
    var efficiency: List[Float64]
    var efficiency_is_set: Bool
    var efficiency_units: StringRef = "-"
    var efficiency_description: StringRef = "Efficiency of drive"
    var efficiency_name: StringRef = "efficiency"

    def from_json(j: json, x: Pointer[LookupVariables]):
        a205_json_get[List[Float64]](j, RS0006.logger[], "efficiency", x[].efficiency, x[].efficiency_is_set, True)

    def populate_performance_map(self, performance_map: Pointer[PerformanceMapBase]):
        add_data_table(performance_map, self.efficiency)

@value
struct PerformanceMap(PerformanceMapBase):
    var grid_variables: GridVariables
    var grid_variables_is_set: Bool
    var lookup_variables: LookupVariables
    var lookup_variables_is_set: Bool
    var grid_variables_units: StringRef = ""
    var lookup_variables_units: StringRef = ""
    var grid_variables_description: StringRef = "Data group describing grid variables for drive performance"
    var lookup_variables_description: StringRef = "Data group describing lookup variables for drive performance"
    var grid_variables_name: StringRef = "grid_variables"
    var lookup_variables_name: StringRef = "lookup_variables"

    def from_json(j: json, x: Pointer[PerformanceMap]):
        a205_json_get[GridVariables](j, RS0006.logger[], "grid_variables", x[].grid_variables, x[].grid_variables_is_set, True)
        x[].grid_variables.populate_performance_map(x)
        a205_json_get[LookupVariables](j, RS0006.logger[], "lookup_variables", x[].lookup_variables, x[].lookup_variables_is_set, True)
        x[].lookup_variables.populate_performance_map(x)

    def initialize(self, j: json):
        a205_json_get[GridVariables](j, RS0006.logger[], "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
        self.grid_variables.populate_performance_map(Pointer[PerformanceMapBase](addressof(self)))
        a205_json_get[LookupVariables](j, RS0006.logger[], "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
        self.lookup_variables.populate_performance_map(Pointer[PerformanceMapBase](addressof(self)))

    def calculate_performance(self, output_power: Float64, output_frequency: Float64, performance_interpolation_method: InterpolationMethod) -> LookupVariablesStruct:
        var target: List[Float64] = List[Float64](output_power, output_frequency)
        var v: List[Float64] = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
        var s: LookupVariablesStruct = LookupVariablesStruct(v[0])
        return s

@value
struct LookupVariablesStruct:
    var efficiency: Float64

@value
struct Performance:
    var maximum_power: Float64
    var maximum_power_is_set: Bool
    var standby_power: Float64
    var standby_power_is_set: Bool
    var cooling_method: CoolingMethod
    var cooling_method_is_set: Bool
    var performance_map: PerformanceMap
    var performance_map_is_set: Bool
    var maximum_power_units: StringRef = "W"
    var standby_power_units: StringRef = "W"
    var cooling_method_units: StringRef = ""
    var performance_map_units: StringRef = ""
    var maximum_power_description: StringRef = "Maximum power draw of the drive"
    var standby_power_description: StringRef = "Power draw when the motor is not operating"
    var cooling_method_description: StringRef = "Method used to cool the drive"
    var performance_map_description: StringRef = "Data group describing drive performance when operating"
    var maximum_power_name: StringRef = "maximum_power"
    var standby_power_name: StringRef = "standby_power"
    var cooling_method_name: StringRef = "cooling_method"
    var performance_map_name: StringRef = "performance_map"

    def from_json(j: json, x: Pointer[Performance]):
        a205_json_get[Float64](j, RS0006.logger[], "maximum_power", x[].maximum_power, x[].maximum_power_is_set, True)
        a205_json_get[Float64](j, RS0006.logger[], "standby_power", x[].standby_power, x[].standby_power_is_set, True)
        a205_json_get[CoolingMethod](j, RS0006.logger[], "cooling_method", x[].cooling_method, x[].cooling_method_is_set, True)
        a205_json_get[PerformanceMap](j, RS0006.logger[], "performance_map", x[].performance_map, x[].performance_map_is_set, True)

@value
enum CoolingMethod:
    case Air
    case Liquid
    case Other

@value
struct RS0006:
    var metadata: Metadata
    var metadata_is_set: Bool
    var description: Description
    var description_is_set: Bool
    var performance: Performance
    var performance_is_set: Bool
    var logger: Pointer[Courierr] = Pointer[Courierr]()
    var metadata_units: StringRef = ""
    var description_units: StringRef = ""
    var performance_units: StringRef = ""
    var metadata_description: StringRef = "Metadata data group"
    var description_description: StringRef = "Data group describing product and rating information"
    var performance_description: StringRef = "Data group containing performance information"
    var metadata_name: StringRef = "metadata"
    var description_name: StringRef = "description"
    var performance_name: StringRef = "performance"

    def from_json(j: json, x: Pointer[RS0006]):
        a205_json_get[Metadata](j, RS0006.logger[], "metadata", x[].metadata, x[].metadata_is_set, True)
        a205_json_get[Description](j, RS0006.logger[], "description", x[].description, x[].description_is_set, False)
        a205_json_get[Performance](j, RS0006.logger[], "performance", x[].performance, x[].performance_is_set, True)

    def initialize(self, j: json):
        a205_json_get[Metadata](j, RS0006.logger[], "metadata", self.metadata, self.metadata_is_set, True)
        a205_json_get[Description](j, RS0006.logger[], "description", self.description, self.description_is_set, False)
        a205_json_get[Performance](j, RS0006.logger[], "performance", self.performance, self.performance_is_set, True)