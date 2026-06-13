from rs0003 import Schema, ProductInformation, Description, AssemblyComponent, SystemCurve, Performance, RS0003, GridVariablesContinuous, LookupVariablesContinuous, PerformanceMapContinuous, GridVariablesDiscrete, LookupVariablesDiscrete, PerformanceMapDiscrete, LookupVariablesContinuousStruct, LookupVariablesDiscreteStruct
from loadobject_205 import a205_json_get, add_grid_axis, add_data_table
from ashrae205_ns import Pattern, UUID, Metadata, SpeedControlType
from rs0005_ns import RS0005
from rs0007_ns import RS0007
from btwxt import InterpolationMethod
from courierr import Courierr
from nlohmann import json
from memory import unique_ptr
from vector import vector
from string import string_view
from utility import make_unique

@value
struct Schema:
    var schema_title: String = "Fan Assembly"
    var schema_version: String = "1.0.0"
    var schema_description: String = "Schema for ASHRAE 205 annex RS0003: Fan Assembly"

@value
struct ProductInformation:
    var manufacturer: String
    var manufacturer_is_set: Bool
    var model_number: Pattern
    var model_number_is_set: Bool
    var impeller_type: ImpellerType
    var impeller_type_is_set: Bool
    var number_of_impellers: Int
    var number_of_impellers_is_set: Bool

    var manufacturer_units: String = ""
    var model_number_units: String = ""
    var impeller_type_units: String = ""
    var number_of_impellers_units: String = ""
    var manufacturer_description: String = "Assembly/unit manufacturer name"
    var model_number_description: String = "Assembly/unit model number"
    var impeller_type_description: String = "Type of impeller in fan assembly"
    var number_of_impellers_description: String = "Number of impellers included in the fan assembly"
    var manufacturer_name: String = "manufacturer"
    var model_number_name: String = "model_number"
    var impeller_type_name: String = "impeller_type"
    var number_of_impellers_name: String = "number_of_impellers"

@value
struct Description:
    var product_information: ProductInformation
    var product_information_is_set: Bool

    var product_information_units: String = ""
    var product_information_description: String = "Data group describing product information"
    var product_information_name: String = "product_information"

@value
struct AssemblyComponent:
    var component_type: ComponentType
    var component_type_is_set: Bool
    var component_description: String
    var component_description_is_set: Bool
    var component_id: UUID
    var component_id_is_set: Bool
    var wet_pressure_difference: Float64
    var wet_pressure_difference_is_set: Bool

    var component_type_units: String = ""
    var component_description_units: String = ""
    var component_id_units: String = ""
    var wet_pressure_difference_units: String = "Pa"
    var component_type_description: String = "Type of component"
    var component_description_description: String = "Informative description of the component"
    var component_id_description: String = "Identifier of the corresponding Standard 205 representation"
    var wet_pressure_difference_description: String = "Additional static pressure difference if the component is wet (e.g., because of condensate collection or wetting evaporative media)"
    var component_type_name: String = "component_type"
    var component_description_name: String = "component_description"
    var component_id_name: String = "component_id"
    var wet_pressure_difference_name: String = "wet_pressure_difference"

@value
struct SystemCurve:
    var standard_air_volumetric_flow_rate: Vector[Float64]
    var standard_air_volumetric_flow_rate_is_set: Bool
    var static_pressure_difference: Vector[Float64]
    var static_pressure_difference_is_set: Bool

    var standard_air_volumetric_flow_rate_units: String = "m3/s"
    var static_pressure_difference_units: String = "Pa"
    var standard_air_volumetric_flow_rate_description: String = "Volumetric air flow rate through an air distribution system at standard air conditions"
    var static_pressure_difference_description: String = "Static pressure difference of an air distribution system"
    var standard_air_volumetric_flow_rate_name: String = "standard_air_volumetric_flow_rate"
    var static_pressure_difference_name: String = "static_pressure_difference"

@value
struct Performance:
    var nominal_standard_air_volumetric_flow_rate: Float64
    var nominal_standard_air_volumetric_flow_rate_is_set: Bool
    var is_enclosed: Bool
    var is_enclosed_is_set: Bool
    var assembly_components: Vector[AssemblyComponent]
    var assembly_components_is_set: Bool
    var heat_loss_fraction: Float64
    var heat_loss_fraction_is_set: Bool
    var maximum_impeller_rotational_speed: Float64
    var maximum_impeller_rotational_speed_is_set: Bool
    var minimum_impeller_rotational_speed: Float64
    var minimum_impeller_rotational_speed_is_set: Bool
    var stability_curve: SystemCurve
    var stability_curve_is_set: Bool
    var operation_speed_control_type: SpeedControlType
    var operation_speed_control_type_is_set: Bool
    var installation_speed_control_type: InstallationSpeedControlType
    var installation_speed_control_type_is_set: Bool
    var motor_representation: RS0005
    var motor_representation_is_set: Bool
    var mechanical_drive_representation: RS0007
    var mechanical_drive_representation_is_set: Bool
    var performance_map: UniquePointer[PerformanceMapBase]
    var performance_map_is_set: Bool

    var nominal_standard_air_volumetric_flow_rate_units: String = "m3/s"
    var is_enclosed_units: String = ""
    var assembly_components_units: String = ""
    var heat_loss_fraction_units: String = "-"
    var maximum_impeller_rotational_speed_units: String = "rev/s"
    var minimum_impeller_rotational_speed_units: String = "rev/s"
    var stability_curve_units: String = ""
    var operation_speed_control_type_units: String = ""
    var installation_speed_control_type_units: String = ""
    var motor_representation_units: String = ""
    var mechanical_drive_representation_units: String = ""
    var performance_map_units: String = ""
    var nominal_standard_air_volumetric_flow_rate_description: String = "Nominal or rated air flow rate at standard air conditions"
    var is_enclosed_description: String = "Fan assembly is enclosed"
    var assembly_components_description: String = "An array of components included in the fan assembly air stream, not including any fans"
    var heat_loss_fraction_description: String = "Fraction of efficiency losses transferred into the air stream"
    var maximum_impeller_rotational_speed_description: String = "Maximum impeller rotational speed"
    var minimum_impeller_rotational_speed_description: String = "Minimum impeller rotational speed"
    var stability_curve_description: String = "The system curve defining the stability area for system selection"
    var operation_speed_control_type_description: String = "Type of performance map"
    var installation_speed_control_type_description: String = "Type of fan impeller speed control"
    var motor_representation_description: String = "The corresponding Standard 205 motor representation"
    var mechanical_drive_representation_description: String = "The corresponding Standard 205 mechanical drive representation"
    var performance_map_description: String = "Data group describing fan assembly performance when operating"
    var nominal_standard_air_volumetric_flow_rate_name: String = "nominal_standard_air_volumetric_flow_rate"
    var is_enclosed_name: String = "is_enclosed"
    var assembly_components_name: String = "assembly_components"
    var heat_loss_fraction_name: String = "heat_loss_fraction"
    var maximum_impeller_rotational_speed_name: String = "maximum_impeller_rotational_speed"
    var minimum_impeller_rotational_speed_name: String = "minimum_impeller_rotational_speed"
    var stability_curve_name: String = "stability_curve"
    var operation_speed_control_type_name: String = "operation_speed_control_type"
    var installation_speed_control_type_name: String = "installation_speed_control_type"
    var motor_representation_name: String = "motor_representation"
    var mechanical_drive_representation_name: String = "mechanical_drive_representation"
    var performance_map_name: String = "performance_map"

@value
struct RS0003:
    var metadata: Metadata
    var metadata_is_set: Bool
    var description: Description
    var description_is_set: Bool
    var performance: Performance
    var performance_is_set: Bool

    var logger: SharedPointer[Courierr] = SharedPointer[Courierr]()
    var metadata_units: String = ""
    var description_units: String = ""
    var performance_units: String = ""
    var metadata_description: String = "Metadata data group"
    var description_description: String = "Data group describing product and rating information"
    var performance_description: String = "Data group containing performance information"
    var metadata_name: String = "metadata"
    var description_name: String = "description"
    var performance_name: String = "performance"

@value
struct GridVariablesContinuous:
    var standard_air_volumetric_flow_rate: Vector[Float64]
    var standard_air_volumetric_flow_rate_is_set: Bool
    var static_pressure_difference: Vector[Float64]
    var static_pressure_difference_is_set: Bool

    var standard_air_volumetric_flow_rate_units: String = "m3/s"
    var static_pressure_difference_units: String = "Pa"
    var standard_air_volumetric_flow_rate_description: String = "Volumetric air flow rate through fan assembly at standard air conditions"
    var static_pressure_difference_description: String = "External static pressure across fan assembly at dry coil conditions"
    var standard_air_volumetric_flow_rate_name: String = "standard_air_volumetric_flow_rate"
    var static_pressure_difference_name: String = "static_pressure_difference"

@value
struct LookupVariablesContinuous:
    var impeller_rotational_speed: Vector[Float64]
    var impeller_rotational_speed_is_set: Bool
    var shaft_power: Vector[Float64]
    var shaft_power_is_set: Bool

    var impeller_rotational_speed_units: String = "rev/s"
    var shaft_power_units: String = "W"
    var impeller_rotational_speed_description: String = "Rotational speed of fan impeller"
    var shaft_power_description: String = "Mechanical shaft power input to fan assembly"
    var impeller_rotational_speed_name: String = "impeller_rotational_speed"
    var shaft_power_name: String = "shaft_power"

@value
struct PerformanceMapContinuous:
    var grid_variables: GridVariablesContinuous
    var grid_variables_is_set: Bool
    var lookup_variables: LookupVariablesContinuous
    var lookup_variables_is_set: Bool

    var grid_variables_units: String = ""
    var lookup_variables_units: String = ""
    var grid_variables_description: String = "Data group describing grid variables for continuous fan performance"
    var lookup_variables_description: String = "Data group describing lookup variables for continuous fan performance"
    var grid_variables_name: String = "grid_variables"
    var lookup_variables_name: String = "lookup_variables"

@value
struct GridVariablesDiscrete:
    var speed_number: Vector[Int]
    var speed_number_is_set: Bool
    var static_pressure_difference: Vector[Float64]
    var static_pressure_difference_is_set: Bool

    var speed_number_units: String = "-"
    var static_pressure_difference_units: String = "Pa"
    var speed_number_description: String = "Number indicating discrete speed of fan impeller in rank order (with 1 being the lowest speed)"
    var static_pressure_difference_description: String = "External static pressure across fan assembly at dry coil conditions"
    var speed_number_name: String = "speed_number"
    var static_pressure_difference_name: String = "static_pressure_difference"

@value
struct LookupVariablesDiscrete:
    var standard_air_volumetric_flow_rate: Vector[Float64]
    var standard_air_volumetric_flow_rate_is_set: Bool
    var shaft_power: Vector[Float64]
    var shaft_power_is_set: Bool
    var impeller_rotational_speed: Vector[Float64]
    var impeller_rotational_speed_is_set: Bool

    var standard_air_volumetric_flow_rate_units: String = "m3/s"
    var shaft_power_units: String = "W"
    var impeller_rotational_speed_units: String = "rev/s"
    var standard_air_volumetric_flow_rate_description: String = "Volumetric air flow rate through fan assembly at standard air conditions"
    var shaft_power_description: String = "Mechanical shaft power input to fan assembly"
    var impeller_rotational_speed_description: String = "Rotational speed of fan impeller"
    var standard_air_volumetric_flow_rate_name: String = "standard_air_volumetric_flow_rate"
    var shaft_power_name: String = "shaft_power"
    var impeller_rotational_speed_name: String = "impeller_rotational_speed"

@value
struct PerformanceMapDiscrete:
    var grid_variables: GridVariablesDiscrete
    var grid_variables_is_set: Bool
    var lookup_variables: LookupVariablesDiscrete
    var lookup_variables_is_set: Bool

    var grid_variables_units: String = ""
    var lookup_variables_units: String = ""
    var grid_variables_description: String = "Data group describing grid variables for discrete fan performance"
    var lookup_variables_description: String = "Data group describing lookup variables for discrete fan performance"
    var grid_variables_name: String = "grid_variables"
    var lookup_variables_name: String = "lookup_variables"

@value
struct LookupVariablesContinuousStruct:
    var impeller_rotational_speed: Float64
    var shaft_power: Float64

@value
struct LookupVariablesDiscreteStruct:
    var standard_air_volumetric_flow_rate: Float64
    var shaft_power: Float64
    var impeller_rotational_speed: Float64

def from_json(j: json, x: inout ProductInformation):
    a205_json_get[String](j, RS0003.logger, "manufacturer", x.manufacturer, x.manufacturer_is_set, False)
    a205_json_get[Pattern](j, RS0003.logger, "model_number", x.model_number, x.model_number_is_set, False)
    a205_json_get[ImpellerType](j, RS0003.logger, "impeller_type", x.impeller_type, x.impeller_type_is_set, False)
    a205_json_get[Int](j, RS0003.logger, "number_of_impellers", x.number_of_impellers, x.number_of_impellers_is_set, False)

def from_json(j: json, x: inout Description):
    a205_json_get[ProductInformation](j, RS0003.logger, "product_information", x.product_information, x.product_information_is_set, False)

def from_json(j: json, x: inout AssemblyComponent):
    a205_json_get[ComponentType](j, RS0003.logger, "component_type", x.component_type, x.component_type_is_set, True)
    a205_json_get[String](j, RS0003.logger, "component_description", x.component_description, x.component_description_is_set, False)
    a205_json_get[UUID](j, RS0003.logger, "component_id", x.component_id, x.component_id_is_set, False)
    a205_json_get[Float64](j, RS0003.logger, "wet_pressure_difference", x.wet_pressure_difference, x.wet_pressure_difference_is_set, True)

def from_json(j: json, x: inout SystemCurve):
    a205_json_get[Vector[Float64]](j, RS0003.logger, "standard_air_volumetric_flow_rate", x.standard_air_volumetric_flow_rate, x.standard_air_volumetric_flow_rate_is_set, True)
    a205_json_get[Vector[Float64]](j, RS0003.logger, "static_pressure_difference", x.static_pressure_difference, x.static_pressure_difference_is_set, True)

def from_json(j: json, x: inout Performance):
    a205_json_get[Float64](j, RS0003.logger, "nominal_standard_air_volumetric_flow_rate", x.nominal_standard_air_volumetric_flow_rate, x.nominal_standard_air_volumetric_flow_rate_is_set, True)
    a205_json_get[Bool](j, RS0003.logger, "is_enclosed", x.is_enclosed, x.is_enclosed_is_set, True)
    a205_json_get[Vector[AssemblyComponent]](j, RS0003.logger, "assembly_components", x.assembly_components, x.assembly_components_is_set, True)
    a205_json_get[Float64](j, RS0003.logger, "heat_loss_fraction", x.heat_loss_fraction, x.heat_loss_fraction_is_set, True)
    a205_json_get[Float64](j, RS0003.logger, "maximum_impeller_rotational_speed", x.maximum_impeller_rotational_speed, x.maximum_impeller_rotational_speed_is_set, True)
    a205_json_get[Float64](j, RS0003.logger, "minimum_impeller_rotational_speed", x.minimum_impeller_rotational_speed, x.minimum_impeller_rotational_speed_is_set, True)
    a205_json_get[SystemCurve](j, RS0003.logger, "stability_curve", x.stability_curve, x.stability_curve_is_set, False)
    a205_json_get[SpeedControlType](j, RS0003.logger, "operation_speed_control_type", x.operation_speed_control_type, x.operation_speed_control_type_is_set, True)
    a205_json_get[InstallationSpeedControlType](j, RS0003.logger, "installation_speed_control_type", x.installation_speed_control_type, x.installation_speed_control_type_is_set, True)
    a205_json_get[RS0005](j, RS0003.logger, "motor_representation", x.motor_representation, x.motor_representation_is_set, False)
    a205_json_get[RS0007](j, RS0003.logger, "mechanical_drive_representation", x.mechanical_drive_representation, x.mechanical_drive_representation_is_set, False)
    if x.operation_speed_control_type == SpeedControlType.CONTINUOUS:
        x.performance_map = make_unique[PerformanceMapContinuous]()
        if x.performance_map:
            x.performance_map.initialize(j.at("performance_map"))
    if x.operation_speed_control_type == SpeedControlType.DISCRETE:
        x.performance_map = make_unique[PerformanceMapDiscrete]()
        if x.performance_map:
            x.performance_map.initialize(j.at("performance_map"))

def from_json(j: json, x: inout RS0003):
    a205_json_get[Metadata](j, RS0003.logger, "metadata", x.metadata, x.metadata_is_set, True)
    a205_json_get[Description](j, RS0003.logger, "description", x.description, x.description_is_set, False)
    a205_json_get[Performance](j, RS0003.logger, "performance", x.performance, x.performance_is_set, True)

def RS0003.initialize(inout self, j: json):
    a205_json_get[Metadata](j, RS0003.logger, "metadata", self.metadata, self.metadata_is_set, True)
    a205_json_get[Description](j, RS0003.logger, "description", self.description, self.description_is_set, False)
    a205_json_get[Performance](j, RS0003.logger, "performance", self.performance, self.performance_is_set, True)

def from_json(j: json, x: inout GridVariablesContinuous):
    a205_json_get[Vector[Float64]](j, RS0003.logger, "standard_air_volumetric_flow_rate", x.standard_air_volumetric_flow_rate, x.standard_air_volumetric_flow_rate_is_set, True)
    a205_json_get[Vector[Float64]](j, RS0003.logger, "static_pressure_difference", x.static_pressure_difference, x.static_pressure_difference_is_set, True)

def GridVariablesContinuous.populate_performance_map(inout self, performance_map: inout PerformanceMapBase):
    add_grid_axis(performance_map, self.standard_air_volumetric_flow_rate)
    add_grid_axis(performance_map, self.static_pressure_difference)
    performance_map.finalize_grid(RS0003.logger)

def from_json(j: json, x: inout LookupVariablesContinuous):
    a205_json_get[Vector[Float64]](j, RS0003.logger, "impeller_rotational_speed", x.impeller_rotational_speed, x.impeller_rotational_speed_is_set, True)
    a205_json_get[Vector[Float64]](j, RS0003.logger, "shaft_power", x.shaft_power, x.shaft_power_is_set, True)

def LookupVariablesContinuous.populate_performance_map(inout self, performance_map: inout PerformanceMapBase):
    add_data_table(performance_map, self.impeller_rotational_speed)
    add_data_table(performance_map, self.shaft_power)

def from_json(j: json, x: inout PerformanceMapContinuous):
    a205_json_get[GridVariablesContinuous](j, RS0003.logger, "grid_variables", x.grid_variables, x.grid_variables_is_set, True)
    x.grid_variables.populate_performance_map(x)
    a205_json_get[LookupVariablesContinuous](j, RS0003.logger, "lookup_variables", x.lookup_variables, x.lookup_variables_is_set, True)
    x.lookup_variables.populate_performance_map(x)

def PerformanceMapContinuous.initialize(inout self, j: json):
    a205_json_get[GridVariablesContinuous](j, RS0003.logger, "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
    self.grid_variables.populate_performance_map(self)
    a205_json_get[LookupVariablesContinuous](j, RS0003.logger, "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
    self.lookup_variables.populate_performance_map(self)

def PerformanceMapContinuous.calculate_performance(inout self, standard_air_volumetric_flow_rate: Float64, static_pressure_difference: Float64, performance_interpolation_method: InterpolationMethod) -> LookupVariablesContinuousStruct:
    var target: Vector[Float64] = Vector[Float64](standard_air_volumetric_flow_rate, static_pressure_difference)
    var v: Vector[Float64] = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
    var s: LookupVariablesContinuousStruct = LookupVariablesContinuousStruct(v[0], v[1])
    return s

def from_json(j: json, x: inout GridVariablesDiscrete):
    a205_json_get[Vector[Int]](j, RS0003.logger, "speed_number", x.speed_number, x.speed_number_is_set, True)
    a205_json_get[Vector[Float64]](j, RS0003.logger, "static_pressure_difference", x.static_pressure_difference, x.static_pressure_difference_is_set, True)

def GridVariablesDiscrete.populate_performance_map(inout self, performance_map: inout PerformanceMapBase):
    add_grid_axis(performance_map, self.speed_number)
    add_grid_axis(performance_map, self.static_pressure_difference)
    performance_map.finalize_grid(RS0003.logger)

def from_json(j: json, x: inout LookupVariablesDiscrete):
    a205_json_get[Vector[Float64]](j, RS0003.logger, "standard_air_volumetric_flow_rate", x.standard_air_volumetric_flow_rate, x.standard_air_volumetric_flow_rate_is_set, True)
    a205_json_get[Vector[Float64]](j, RS0003.logger, "shaft_power", x.shaft_power, x.shaft_power_is_set, True)
    a205_json_get[Vector[Float64]](j, RS0003.logger, "impeller_rotational_speed", x.impeller_rotational_speed, x.impeller_rotational_speed_is_set, True)

def LookupVariablesDiscrete.populate_performance_map(inout self, performance_map: inout PerformanceMapBase):
    add_data_table(performance_map, self.standard_air_volumetric_flow_rate)
    add_data_table(performance_map, self.shaft_power)
    add_data_table(performance_map, self.impeller_rotational_speed)

def from_json(j: json, x: inout PerformanceMapDiscrete):
    a205_json_get[GridVariablesDiscrete](j, RS0003.logger, "grid_variables", x.grid_variables, x.grid_variables_is_set, True)
    x.grid_variables.populate_performance_map(x)
    a205_json_get[LookupVariablesDiscrete](j, RS0003.logger, "lookup_variables", x.lookup_variables, x.lookup_variables_is_set, True)
    x.lookup_variables.populate_performance_map(x)

def PerformanceMapDiscrete.initialize(inout self, j: json):
    a205_json_get[GridVariablesDiscrete](j, RS0003.logger, "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
    self.grid_variables.populate_performance_map(self)
    a205_json_get[LookupVariablesDiscrete](j, RS0003.logger, "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
    self.lookup_variables.populate_performance_map(self)

def PerformanceMapDiscrete.calculate_performance(inout self, speed_number: Float64, static_pressure_difference: Float64, performance_interpolation_method: InterpolationMethod) -> LookupVariablesDiscreteStruct:
    var target: Vector[Float64] = Vector[Float64](speed_number, static_pressure_difference)
    var v: Vector[Float64] = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
    var s: LookupVariablesDiscreteStruct = LookupVariablesDiscreteStruct(v[0], v[1], v[2])
    return s