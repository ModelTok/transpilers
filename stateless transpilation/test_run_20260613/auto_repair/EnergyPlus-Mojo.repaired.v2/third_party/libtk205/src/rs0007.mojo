from loadobject_205 import a205_json_get, PerformanceMapBase, add_grid_axis, add_data_table
from ashrae205_ns import Pattern as ashrae205_ns_Pattern, Metadata as ashrae205_ns_Metadata
from Btwxt import InterpolationMethod
from Courierr import Courierr
from nlohmann import Json

struct rs0007_ns:
    struct DriveType:
        var value: String

    @staticmethod
    def from_json(j: Json, x: inout DriveType):
        x.value = j.get_str()

    struct Schema:
        static let schema_title: StringLiteral = "Mechanical Drive"
        static let schema_version: StringLiteral = "1.0.0"
        static let schema_description: StringLiteral = "Schema for ASHRAE 205 annex RS0007: Mechanical Drive"

    struct ProductInformation:
        var manufacturer: String
        var manufacturer_is_set: Bool
        var model_number: ashrae205_ns_Pattern
        var model_number_is_set: Bool
        var drive_type: DriveType
        var drive_type_is_set: Bool

        static let manufacturer_units: StringLiteral = ""
        static let model_number_units: StringLiteral = ""
        static let drive_type_units: StringLiteral = ""
        static let manufacturer_description: StringLiteral = "Manufacturer name"
        static let model_number_description: StringLiteral = "Model number"
        static let drive_type_description: StringLiteral = "Type of mechanical drive"
        static let manufacturer_name: StringLiteral = "manufacturer"
        static let model_number_name: StringLiteral = "model_number"
        static let drive_type_name: StringLiteral = "drive_type"

    @staticmethod
    def from_json(j: Json, x: inout ProductInformation):
        a205_json_get[String](j, RS0007.logger[], "manufacturer", x.manufacturer, x.manufacturer_is_set, False)
        a205_json_get[ashrae205_ns_Pattern](j, RS0007.logger[], "model_number", x.model_number, x.model_number_is_set, False)
        a205_json_get[DriveType](j, RS0007.logger[], "drive_type", x.drive_type, x.drive_type_is_set, False)

    struct Description:
        var product_information: ProductInformation
        var product_information_is_set: Bool

        static let product_information_units: StringLiteral = ""
        static let product_information_description: StringLiteral = "Data group describing product information"
        static let product_information_name: StringLiteral = "product_information"

    @staticmethod
    def from_json(j: Json, x: inout Description):
        a205_json_get[ProductInformation](j, RS0007.logger[], "product_information", x.product_information, x.product_information_is_set, False)

    struct GridVariables:
        var output_power: List[Float64]
        var output_power_is_set: Bool

        static let output_power_units: StringLiteral = "W"
        static let output_power_description: StringLiteral = "Output shaft power"
        static let output_power_name: StringLiteral = "output_power"

        def populate_performance_map(self, performance_map: inout PerformanceMapBase):
            add_grid_axis(performance_map, self.output_power)
            performance_map.finalize_grid(RS0007.logger[])

    @staticmethod
    def from_json(j: Json, x: inout GridVariables):
        a205_json_get[List[Float64]](j, RS0007.logger[], "output_power", x.output_power, x.output_power_is_set, True)

    struct LookupVariables:
        var efficiency: List[Float64]
        var efficiency_is_set: Bool

        static let efficiency_units: StringLiteral = "-"
        static let efficiency_description: StringLiteral = "Efficiency of drive"
        static let efficiency_name: StringLiteral = "efficiency"

        def populate_performance_map(self, performance_map: inout PerformanceMapBase):
            add_data_table(performance_map, self.efficiency)

    @staticmethod
    def from_json(j: Json, x: inout LookupVariables):
        a205_json_get[List[Float64]](j, RS0007.logger[], "efficiency", x.efficiency, x.efficiency_is_set, True)

    struct LookupVariablesStruct:
        var efficiency: Float64

    struct PerformanceMap: PerformanceMapBase:
        var grid_variables: GridVariables
        var grid_variables_is_set: Bool
        var lookup_variables: LookupVariables
        var lookup_variables_is_set: Bool

        static let grid_variables_units: StringLiteral = ""
        static let lookup_variables_units: StringLiteral = ""
        static let grid_variables_description: StringLiteral = "Data group describing grid variables for drive performance"
        static let lookup_variables_description: StringLiteral = "Data group describing lookup variables for drive performance"
        static let grid_variables_name: StringLiteral = "grid_variables"
        static let lookup_variables_name: StringLiteral = "lookup_variables"

        def initialize(self, j: Json):
            a205_json_get[GridVariables](j, RS0007.logger[], "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
            self.grid_variables.populate_performance_map(self)
            a205_json_get[LookupVariables](j, RS0007.logger[], "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
            self.lookup_variables.populate_performance_map(self)

        def calculate_performance(self, output_power: Float64, performance_interpolation_method: InterpolationMethod) -> LookupVariablesStruct:
            var target = List[Float64](output_power)
            var v = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
            var s = LookupVariablesStruct(efficiency=v[0])
            return s

    @staticmethod
    def from_json(j: Json, x: inout PerformanceMap):
        a205_json_get[GridVariables](j, RS0007.logger[], "grid_variables", x.grid_variables, x.grid_variables_is_set, True)
        x.grid_variables.populate_performance_map(x)
        a205_json_get[LookupVariables](j, RS0007.logger[], "lookup_variables", x.lookup_variables, x.lookup_variables_is_set, True)
        x.lookup_variables.populate_performance_map(x)

    struct Performance:
        var speed_ratio: Float64
        var speed_ratio_is_set: Bool
        var performance_map: PerformanceMap
        var performance_map_is_set: Bool

        static let speed_ratio_units: StringLiteral = "-"
        static let performance_map_units: StringLiteral = ""
        static let speed_ratio_description: StringLiteral = "Ratio of input shaft speed to output shaft speed"
        static let performance_map_description: StringLiteral = "Data group describing drive performance when operating"
        static let speed_ratio_name: StringLiteral = "speed_ratio"
        static let performance_map_name: StringLiteral = "performance_map"

    @staticmethod
    def from_json(j: Json, x: inout Performance):
        a205_json_get[Float64](j, RS0007.logger[], "speed_ratio", x.speed_ratio, x.speed_ratio_is_set, True)
        a205_json_get[PerformanceMap](j, RS0007.logger[], "performance_map", x.performance_map, x.performance_map_is_set, True)

    struct RS0007:
        var metadata: ashrae205_ns_Metadata
        var metadata_is_set: Bool
        var description: Description
        var description_is_set: Bool
        var performance: Performance
        var performance_is_set: Bool

        static var logger: Pointer[Courierr] = Pointer[Courierr]()

        static let metadata_units: StringLiteral = ""
        static let description_units: StringLiteral = ""
        static let performance_units: StringLiteral = ""
        static let metadata_description: StringLiteral = "Metadata data group"
        static let description_description: StringLiteral = "Data group describing product and rating information"
        static let performance_description: StringLiteral = "Data group containing performance information"
        static let metadata_name: StringLiteral = "metadata"
        static let description_name: StringLiteral = "description"
        static let performance_name: StringLiteral = "performance"

        def initialize(self, j: Json):
            a205_json_get[ashrae205_ns_Metadata](j, RS0007.logger[], "metadata", self.metadata, self.metadata_is_set, True)
            a205_json_get[Description](j, RS0007.logger[], "description", self.description, self.description_is_set, False)
            a205_json_get[Performance](j, RS0007.logger[], "performance", self.performance, self.performance_is_set, True)

    @staticmethod
    def from_json(j: Json, x: inout RS0007):
        a205_json_get[ashrae205_ns_Metadata](j, RS0007.logger[], "metadata", x.metadata, x.metadata_is_set, True)
        a205_json_get[Description](j, RS0007.logger[], "description", x.description, x.description_is_set, False)
        a205_json_get[Performance](j, RS0007.logger[], "performance", x.performance, x.performance_is_set, True)
