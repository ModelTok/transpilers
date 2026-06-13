from a205_json_helpers import a205_json_get
from ashrae205_ns import (
    CompressorType,
    LiquidMixture,
    Metadata,
    Pattern,
    SpeedControlType,
)
from btwxt import InterpolationMethod
from courierr import Courierr
from performance_map_base import PerformanceMapBase, add_grid_axis, add_data_table

# Forward declarations for nested structs used in member types
struct ProductInformation:
    var manufacturer: String
    var model_number: Pattern
    var nominal_voltage: Float64
    var nominal_frequency: Float64
    var compressor_type: CompressorType
    var liquid_data_source: String
    var refrigerant: String
    var hot_gas_bypass_installed: Bool
    var manufacturer_is_set: Bool = False
    var model_number_is_set: Bool = False
    var nominal_voltage_is_set: Bool = False
    var nominal_frequency_is_set: Bool = False
    var compressor_type_is_set: Bool = False
    var liquid_data_source_is_set: Bool = False
    var refrigerant_is_set: Bool = False
    var hot_gas_bypass_installed_is_set: Bool = False

    static var manufacturer_units: StringLiteral = ""
    static var model_number_units: StringLiteral = ""
    static var nominal_voltage_units: StringLiteral = "V"
    static var nominal_frequency_units: StringLiteral = "Hz"
    static var compressor_type_units: StringLiteral = ""
    static var liquid_data_source_units: StringLiteral = ""
    static var refrigerant_units: StringLiteral = ""
    static var hot_gas_bypass_installed_units: StringLiteral = ""
    static var manufacturer_description: StringLiteral = "Manufacturer name"
    static var model_number_description: StringLiteral = "Model number"
    static var nominal_voltage_description: StringLiteral = "Unit nominal voltage"
    static var nominal_frequency_description: StringLiteral = "Unit nominal frequency"
    static var compressor_type_description: StringLiteral = "Type of compressor"
    static var liquid_data_source_description: StringLiteral = "Source of the liquid properties data"
    static var refrigerant_description: StringLiteral = "Refrigerant used in the chiller"
    static var hot_gas_bypass_installed_description: StringLiteral = "Indicates if a hot-gas bypass valve is installed on the chiller"
    static var manufacturer_name: StringLiteral = "manufacturer"
    static var model_number_name: StringLiteral = "model_number"
    static var nominal_voltage_name: StringLiteral = "nominal_voltage"
    static var nominal_frequency_name: StringLiteral = "nominal_frequency"
    static var compressor_type_name: StringLiteral = "compressor_type"
    static var liquid_data_source_name: StringLiteral = "liquid_data_source"
    static var refrigerant_name: StringLiteral = "refrigerant"
    static var hot_gas_bypass_installed_name: StringLiteral = "hot_gas_bypass_installed"

struct RatingAHRI550590PartLoadPoint:
    var percent_full_load_capacity: Float64
    var cooling_capacity: Float64
    var input_power: Float64
    var evaporator_liquid_volumetric_flow_rate: Float64
    var evaporator_liquid_entering_temperature: Float64
    var evaporator_liquid_leaving_temperature: Float64
    var evaporator_liquid_differential_pressure: Float64
    var evaporator_fouling_factor: Float64
    var condenser_liquid_volumetric_flow_rate: Float64
    var condenser_liquid_entering_temperature: Float64
    var condenser_liquid_leaving_temperature: Float64
    var condenser_liquid_differential_pressure: Float64
    var condenser_fouling_factor: Float64
    var percent_full_load_capacity_is_set: Bool = False
    var cooling_capacity_is_set: Bool = False
    var input_power_is_set: Bool = False
    var evaporator_liquid_volumetric_flow_rate_is_set: Bool = False
    var evaporator_liquid_entering_temperature_is_set: Bool = False
    var evaporator_liquid_leaving_temperature_is_set: Bool = False
    var evaporator_liquid_differential_pressure_is_set: Bool = False
    var evaporator_fouling_factor_is_set: Bool = False
    var condenser_liquid_volumetric_flow_rate_is_set: Bool = False
    var condenser_liquid_entering_temperature_is_set: Bool = False
    var condenser_liquid_leaving_temperature_is_set: Bool = False
    var condenser_liquid_differential_pressure_is_set: Bool = False
    var condenser_fouling_factor_is_set: Bool = False

    static var percent_full_load_capacity_units: StringLiteral = "%"
    static var cooling_capacity_units: StringLiteral = "Btu/h"
    static var input_power_units: StringLiteral = "kW"
    static var evaporator_liquid_volumetric_flow_rate_units: StringLiteral = "gpm"
    static var evaporator_liquid_entering_temperature_units: StringLiteral = "F"
    static var evaporator_liquid_leaving_temperature_units: StringLiteral = "F"
    static var evaporator_liquid_differential_pressure_units: StringLiteral = "ft of water"
    static var evaporator_fouling_factor_units: StringLiteral = "h-ft2-F/Btu"
    static var condenser_liquid_volumetric_flow_rate_units: StringLiteral = "gpm"
    static var condenser_liquid_entering_temperature_units: StringLiteral = "F"
    static var condenser_liquid_leaving_temperature_units: StringLiteral = "F"
    static var condenser_liquid_differential_pressure_units: StringLiteral = "ft of water"
    static var condenser_fouling_factor_units: StringLiteral = "h-ft2-F/Btu"
    static var percent_full_load_capacity_description: StringLiteral = "Percent full load cooling capacity"
    static var cooling_capacity_description: StringLiteral = "The actual cooling capacity"
    static var input_power_description: StringLiteral = "Combined power input of all components of the unit, including auxiliary power and excluding integral pumps"
    static var evaporator_liquid_volumetric_flow_rate_description: StringLiteral = "Evaporator liquid volumetric flow rate"
    static var evaporator_liquid_entering_temperature_description: StringLiteral = "Liquid temperature at the entry flange of the evaporator"
    static var evaporator_liquid_leaving_temperature_description: StringLiteral = "Liquid temperature at the exit flange of the evaporator"
    static var evaporator_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the evaporator"
    static var evaporator_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to evaporator heat exchanger fouling layer"
    static var condenser_liquid_volumetric_flow_rate_description: StringLiteral = "Condenser liquid volumetric flow rate"
    static var condenser_liquid_entering_temperature_description: StringLiteral = "Liquid temperature at the entry flange of the condenser"
    static var condenser_liquid_leaving_temperature_description: StringLiteral = "Liquid temperature at the exit flange of the condenser"
    static var condenser_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the condenser"
    static var condenser_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to condenser heat exchanger fouling layer"
    static var percent_full_load_capacity_name: StringLiteral = "percent_full_load_capacity"
    static var cooling_capacity_name: StringLiteral = "cooling_capacity"
    static var input_power_name: StringLiteral = "input_power"
    static var evaporator_liquid_volumetric_flow_rate_name: StringLiteral = "evaporator_liquid_volumetric_flow_rate"
    static var evaporator_liquid_entering_temperature_name: StringLiteral = "evaporator_liquid_entering_temperature"
    static var evaporator_liquid_leaving_temperature_name: StringLiteral = "evaporator_liquid_leaving_temperature"
    static var evaporator_liquid_differential_pressure_name: StringLiteral = "evaporator_liquid_differential_pressure"
    static var evaporator_fouling_factor_name: StringLiteral = "evaporator_fouling_factor"
    static var condenser_liquid_volumetric_flow_rate_name: StringLiteral = "condenser_liquid_volumetric_flow_rate"
    static var condenser_liquid_entering_temperature_name: StringLiteral = "condenser_liquid_entering_temperature"
    static var condenser_liquid_leaving_temperature_name: StringLiteral = "condenser_liquid_leaving_temperature"
    static var condenser_liquid_differential_pressure_name: StringLiteral = "condenser_liquid_differential_pressure"
    static var condenser_fouling_factor_name: StringLiteral = "condenser_fouling_factor"

struct RatingAHRI550590:
    var certified_reference_number: String
    var test_standard_year: AHRI550590TestStandardYear
    var rating_source: String
    var net_refrigerating_capacity: Float64
    var input_power: Float64
    var cop: Float64
    var part_load_value: Float64
    var part_load_rating_points: List[RatingAHRI550590PartLoadPoint]
    var full_load_evaporator_liquid_volumetric_flow_rate: Float64
    var full_load_evaporator_liquid_entering_temperature: Float64
    var full_load_evaporator_liquid_leaving_temperature: Float64
    var full_load_evaporator_liquid_differential_pressure: Float64
    var full_load_evaporator_fouling_factor: Float64
    var full_load_condenser_liquid_volumetric_flow_rate: Float64
    var full_load_condenser_liquid_entering_temperature: Float64
    var full_load_condenser_liquid_leaving_temperature: Float64
    var full_load_condenser_liquid_differential_pressure: Float64
    var full_load_condenser_fouling_factor: Float64
    var rating_recalculatable_from_performance_data: Bool
    var rating_recalculatable_explanation: String
    var certified_reference_number_is_set: Bool = False
    var test_standard_year_is_set: Bool = False
    var rating_source_is_set: Bool = False
    var net_refrigerating_capacity_is_set: Bool = False
    var input_power_is_set: Bool = False
    var cop_is_set: Bool = False
    var part_load_value_is_set: Bool = False
    var part_load_rating_points_is_set: Bool = False
    var full_load_evaporator_liquid_volumetric_flow_rate_is_set: Bool = False
    var full_load_evaporator_liquid_entering_temperature_is_set: Bool = False
    var full_load_evaporator_liquid_leaving_temperature_is_set: Bool = False
    var full_load_evaporator_liquid_differential_pressure_is_set: Bool = False
    var full_load_evaporator_fouling_factor_is_set: Bool = False
    var full_load_condenser_liquid_volumetric_flow_rate_is_set: Bool = False
    var full_load_condenser_liquid_entering_temperature_is_set: Bool = False
    var full_load_condenser_liquid_leaving_temperature_is_set: Bool = False
    var full_load_condenser_liquid_differential_pressure_is_set: Bool = False
    var full_load_condenser_fouling_factor_is_set: Bool = False
    var rating_recalculatable_from_performance_data_is_set: Bool = False
    var rating_recalculatable_explanation_is_set: Bool = False

    static var certified_reference_number_units: StringLiteral = ""
    static var test_standard_year_units: StringLiteral = ""
    static var rating_source_units: StringLiteral = ""
    static var net_refrigerating_capacity_units: StringLiteral = "Btu/h"
    static var input_power_units: StringLiteral = "kW"
    static var cop_units: StringLiteral = "-"
    static var part_load_value_units: StringLiteral = "-"
    static var part_load_rating_points_units: StringLiteral = ""
    static var full_load_evaporator_liquid_volumetric_flow_rate_units: StringLiteral = "gpm"
    static var full_load_evaporator_liquid_entering_temperature_units: StringLiteral = "F"
    static var full_load_evaporator_liquid_leaving_temperature_units: StringLiteral = "F"
    static var full_load_evaporator_liquid_differential_pressure_units: StringLiteral = "ft of water"
    static var full_load_evaporator_fouling_factor_units: StringLiteral = "h-ft2-F/Btu"
    static var full_load_condenser_liquid_volumetric_flow_rate_units: StringLiteral = "gpm"
    static var full_load_condenser_liquid_entering_temperature_units: StringLiteral = "F"
    static var full_load_condenser_liquid_leaving_temperature_units: StringLiteral = "F"
    static var full_load_condenser_liquid_differential_pressure_units: StringLiteral = "ft of water"
    static var full_load_condenser_fouling_factor_units: StringLiteral = "h-ft2-F/Btu"
    static var rating_recalculatable_from_performance_data_units: StringLiteral = ""
    static var rating_recalculatable_explanation_units: StringLiteral = ""
    static var certified_reference_number_description: StringLiteral = "AHRI certified reference number"
    static var test_standard_year_description: StringLiteral = "Year of the AHRI test standard"
    static var rating_source_description: StringLiteral = "Source of this rating data"
    static var net_refrigerating_capacity_description: StringLiteral = "Rated net refrigeration capacity"
    static var input_power_description: StringLiteral = "Combined power input of all components of the unit, including auxiliary power and excluding integral pumps"
    static var cop_description: StringLiteral = "Ratio of the net refrigerating capacity to the total input power at the rating conditions"
    static var part_load_value_description: StringLiteral = "Rated part-load efficiency on the basis of weighted operation at various partial load capacities"
    static var part_load_rating_points_description: StringLiteral = "The four measured data points used to calculate the part load rating value"
    static var full_load_evaporator_liquid_volumetric_flow_rate_description: StringLiteral = "Evaporator liquid volumetric flow rate at the full load design point rating condition"
    static var full_load_evaporator_liquid_entering_temperature_description: StringLiteral = "Liquid temperature at the entry flange of the evaporator at the full load design rating conditions"
    static var full_load_evaporator_liquid_leaving_temperature_description: StringLiteral = "Liquid temperature at the exit flange of the evaporator at the full load design rating conditions"
    static var full_load_evaporator_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the evaporator at the full load design rating conditions"
    static var full_load_evaporator_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to evaporator heat exchanger fouling layer at the full load design rating condition"
    static var full_load_condenser_liquid_volumetric_flow_rate_description: StringLiteral = "Condenser liquid volumetric flow rate at the full load design rating conditions"
    static var full_load_condenser_liquid_entering_temperature_description: StringLiteral = "Liquid temperature at the entry flange of the condenser at the full load design rating conditions"
    static var full_load_condenser_liquid_leaving_temperature_description: StringLiteral = "Liquid temperature at the exit flange of the condenser at the full load design rating conditions"
    static var full_load_condenser_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the condenser at the full load design rating conditions"
    static var full_load_condenser_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to condenser heat exchanger fouling layer at the full load design rating conditions"
    static var rating_recalculatable_from_performance_data_description: StringLiteral = "Whether this rating can be recalculated using the performance data in the representation"
    static var rating_recalculatable_explanation_description: StringLiteral = "An explanation of the value for `rating_recalculatable_from_performance_data`"
    static var certified_reference_number_name: StringLiteral = "certified_reference_number"
    static var test_standard_year_name: StringLiteral = "test_standard_year"
    static var rating_source_name: StringLiteral = "rating_source"
    static var net_refrigerating_capacity_name: StringLiteral = "net_refrigerating_capacity"
    static var input_power_name: StringLiteral = "input_power"
    static var cop_name: StringLiteral = "cop"
    static var part_load_value_name: StringLiteral = "part_load_value"
    static var part_load_rating_points_name: StringLiteral = "part_load_rating_points"
    static var full_load_evaporator_liquid_volumetric_flow_rate_name: StringLiteral = "full_load_evaporator_liquid_volumetric_flow_rate"
    static var full_load_evaporator_liquid_entering_temperature_name: StringLiteral = "full_load_evaporator_liquid_entering_temperature"
    static var full_load_evaporator_liquid_leaving_temperature_name: StringLiteral = "full_load_evaporator_liquid_leaving_temperature"
    static var full_load_evaporator_liquid_differential_pressure_name: StringLiteral = "full_load_evaporator_liquid_differential_pressure"
    static var full_load_evaporator_fouling_factor_name: StringLiteral = "full_load_evaporator_fouling_factor"
    static var full_load_condenser_liquid_volumetric_flow_rate_name: StringLiteral = "full_load_condenser_liquid_volumetric_flow_rate"
    static var full_load_condenser_liquid_entering_temperature_name: StringLiteral = "full_load_condenser_liquid_entering_temperature"
    static var full_load_condenser_liquid_leaving_temperature_name: StringLiteral = "full_load_condenser_liquid_leaving_temperature"
    static var full_load_condenser_liquid_differential_pressure_name: StringLiteral = "full_load_condenser_liquid_differential_pressure"
    static var full_load_condenser_fouling_factor_name: StringLiteral = "full_load_condenser_fouling_factor"
    static var rating_recalculatable_from_performance_data_name: StringLiteral = "rating_recalculatable_from_performance_data"
    static var rating_recalculatable_explanation_name: StringLiteral = "rating_recalculatable_explanation"

struct RatingAHRI551591PartLoadPoint:
    var percent_full_load_capacity: Float64
    var cooling_capacity: Float64
    var input_power: Float64
    var evaporator_liquid_volumetric_flow_rate: Float64
    var evaporator_liquid_entering_temperature: Float64
    var evaporator_liquid_leaving_temperature: Float64
    var evaporator_liquid_differential_pressure: Float64
    var evaporator_fouling_factor: Float64
    var condenser_liquid_volumetric_flow_rate: Float64
    var condenser_liquid_entering_temperature: Float64
    var condenser_liquid_leaving_temperature: Float64
    var condenser_liquid_differential_pressure: Float64
    var condenser_fouling_factor: Float64
    var percent_full_load_capacity_is_set: Bool = False
    var cooling_capacity_is_set: Bool = False
    var input_power_is_set: Bool = False
    var evaporator_liquid_volumetric_flow_rate_is_set: Bool = False
    var evaporator_liquid_entering_temperature_is_set: Bool = False
    var evaporator_liquid_leaving_temperature_is_set: Bool = False
    var evaporator_liquid_differential_pressure_is_set: Bool = False
    var evaporator_fouling_factor_is_set: Bool = False
    var condenser_liquid_volumetric_flow_rate_is_set: Bool = False
    var condenser_liquid_entering_temperature_is_set: Bool = False
    var condenser_liquid_leaving_temperature_is_set: Bool = False
    var condenser_liquid_differential_pressure_is_set: Bool = False
    var condenser_fouling_factor_is_set: Bool = False

    static var percent_full_load_capacity_units: StringLiteral = "%"
    static var cooling_capacity_units: StringLiteral = "kW"
    static var input_power_units: StringLiteral = "kW"
    static var evaporator_liquid_volumetric_flow_rate_units: StringLiteral = "l/s"
    static var evaporator_liquid_entering_temperature_units: StringLiteral = "C"
    static var evaporator_liquid_leaving_temperature_units: StringLiteral = "C"
    static var evaporator_liquid_differential_pressure_units: StringLiteral = "kPa"
    static var evaporator_fouling_factor_units: StringLiteral = "m2-K/kW"
    static var condenser_liquid_volumetric_flow_rate_units: StringLiteral = "l/s"
    static var condenser_liquid_entering_temperature_units: StringLiteral = "C"
    static var condenser_liquid_leaving_temperature_units: StringLiteral = "C"
    static var condenser_liquid_differential_pressure_units: StringLiteral = "kPa"
    static var condenser_fouling_factor_units: StringLiteral = "m2-K/kW"
    static var percent_full_load_capacity_description: StringLiteral = "Percent full load cooling capacity"
    static var cooling_capacity_description: StringLiteral = "The actual cooling capacity"
    static var input_power_description: StringLiteral = "Combined power input of all components of the unit, including auxiliary power and excluding integral pumps"
    static var evaporator_liquid_volumetric_flow_rate_description: StringLiteral = "Evaporator liquid volumetric flow rate"
    static var evaporator_liquid_entering_temperature_description: StringLiteral = "Liquid temperature at the entry flange of the evaporator"
    static var evaporator_liquid_leaving_temperature_description: StringLiteral = "Liquid temperature at the exit flange of the evaporator"
    static var evaporator_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the evaporator"
    static var evaporator_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to evaporator heat exchanger fouling layer"
    static var condenser_liquid_volumetric_flow_rate_description: StringLiteral = "Condenser liquid volumetric flow rate"
    static var condenser_liquid_entering_temperature_description: StringLiteral = "Liquid temperature at the entry flange of the condenser"
    static var condenser_liquid_leaving_temperature_description: StringLiteral = "Liquid temperature at the exit flange of the condenser"
    static var condenser_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the condenser"
    static var condenser_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to condenser heat exchanger fouling layer"
    static var percent_full_load_capacity_name: StringLiteral = "percent_full_load_capacity"
    static var cooling_capacity_name: StringLiteral = "cooling_capacity"
    static var input_power_name: StringLiteral = "input_power"
    static var evaporator_liquid_volumetric_flow_rate_name: StringLiteral = "evaporator_liquid_volumetric_flow_rate"
    static var evaporator_liquid_entering_temperature_name: StringLiteral = "evaporator_liquid_entering_temperature"
    static var evaporator_liquid_leaving_temperature_name: StringLiteral = "evaporator_liquid_leaving_temperature"
    static var evaporator_liquid_differential_pressure_name: StringLiteral = "evaporator_liquid_differential_pressure"
    static var evaporator_fouling_factor_name: StringLiteral = "evaporator_fouling_factor"
    static var condenser_liquid_volumetric_flow_rate_name: StringLiteral = "condenser_liquid_volumetric_flow_rate"
    static var condenser_liquid_entering_temperature_name: StringLiteral = "condenser_liquid_entering_temperature"
    static var condenser_liquid_leaving_temperature_name: StringLiteral = "condenser_liquid_leaving_temperature"
    static var condenser_liquid_differential_pressure_name: StringLiteral = "condenser_liquid_differential_pressure"
    static var condenser_fouling_factor_name: StringLiteral = "condenser_fouling_factor"

struct RatingAHRI551591:
    var certified_reference_number: String
    var test_standard_year: AHRI551591TestStandardYear
    var rating_source: String
    var net_refrigerating_capacity: Float64
    var input_power: Float64
    var cop: Float64
    var part_load_value: Float64
    var part_load_rating_points: List[RatingAHRI551591PartLoadPoint]
    var full_load_evaporator_liquid_volumetric_flow_rate: Float64
    var full_load_evaporator_liquid_entering_temperature: Float64
    var full_load_evaporator_liquid_leaving_temperature: Float64
    var full_load_evaporator_liquid_differential_pressure: Float64
    var full_load_evaporator_fouling_factor: Float64
    var full_load_condenser_liquid_volumetric_flow_rate: Float64
    var full_load_condenser_liquid_entering_temperature: Float64
    var full_load_condenser_liquid_leaving_temperature: Float64
    var full_load_condenser_liquid_differential_pressure: Float64
    var full_load_condenser_fouling_factor: Float64
    var rating_recalculatable_from_performance_data: Bool
    var rating_recalculatable_explanation: String
    var certified_reference_number_is_set: Bool = False
    var test_standard_year_is_set: Bool = False
    var rating_source_is_set: Bool = False
    var net_refrigerating_capacity_is_set: Bool = False
    var input_power_is_set: Bool = False
    var cop_is_set: Bool = False
    var part_load_value_is_set: Bool = False
    var part_load_rating_points_is_set: Bool = False
    var full_load_evaporator_liquid_volumetric_flow_rate_is_set: Bool = False
    var full_load_evaporator_liquid_entering_temperature_is_set: Bool = False
    var full_load_evaporator_liquid_leaving_temperature_is_set: Bool = False
    var full_load_evaporator_liquid_differential_pressure_is_set: Bool = False
    var full_load_evaporator_fouling_factor_is_set: Bool = False
    var full_load_condenser_liquid_volumetric_flow_rate_is_set: Bool = False
    var full_load_condenser_liquid_entering_temperature_is_set: Bool = False
    var full_load_condenser_liquid_leaving_temperature_is_set: Bool = False
    var full_load_condenser_liquid_differential_pressure_is_set: Bool = False
    var full_load_condenser_fouling_factor_is_set: Bool = False
    var rating_recalculatable_from_performance_data_is_set: Bool = False
    var rating_recalculatable_explanation_is_set: Bool = False

    static var certified_reference_number_units: StringLiteral = ""
    static var test_standard_year_units: StringLiteral = ""
    static var rating_source_units: StringLiteral = ""
    static var net_refrigerating_capacity_units: StringLiteral = "kW"
    static var input_power_units: StringLiteral = "kW"
    static var cop_units: StringLiteral = "-"
    static var part_load_value_units: StringLiteral = "-"
    static var part_load_rating_points_units: StringLiteral = ""
    static var full_load_evaporator_liquid_volumetric_flow_rate_units: StringLiteral = "l/s"
    static var full_load_evaporator_liquid_entering_temperature_units: StringLiteral = "C"
    static var full_load_evaporator_liquid_leaving_temperature_units: StringLiteral = "C"
    static var full_load_evaporator_liquid_differential_pressure_units: StringLiteral = "kPa"
    static var full_load_evaporator_fouling_factor_units: StringLiteral = "m2-K/kW"
    static var full_load_condenser_liquid_volumetric_flow_rate_units: StringLiteral = "l/s"
    static var full_load_condenser_liquid_entering_temperature_units: StringLiteral = "C"
    static var full_load_condenser_liquid_leaving_temperature_units: StringLiteral = "C"
    static var full_load_condenser_liquid_differential_pressure_units: StringLiteral = "kPa"
    static var full_load_condenser_fouling_factor_units: StringLiteral = "m2-K/kW"
    static var rating_recalculatable_from_performance_data_units: StringLiteral = ""
    static var rating_recalculatable_explanation_units: StringLiteral = ""
    static var certified_reference_number_description: StringLiteral = "AHRI certified reference number"
    static var test_standard_year_description: StringLiteral = "Year of the AHRI test standard"
    static var rating_source_description: StringLiteral = "Source of this rating data"
    static var net_refrigerating_capacity_description: StringLiteral = "Rated net refrigeration capacity"
    static var input_power_description: StringLiteral = "Combined power input of all components of the unit, including auxiliary power and excluding integral pumps"
    static var cop_description: StringLiteral = "Ratio of the net refrigerating capacity to the total input power at the rating conditions"
    static var part_load_value_description: StringLiteral = "Rated part-load efficiency on the basis of weighted operation at various partial load capacities"
    static var part_load_rating_points_description: StringLiteral = "The four measured data points used to calculate the part load rating value"
    static var full_load_evaporator_liquid_volumetric_flow_rate_description: StringLiteral = "Evaporator liquid volumetric flow rate at the full load design rating conditions"
    static var full_load_evaporator_liquid_entering_temperature_description: StringLiteral = "Liquid temperature at the entry flange of the evaporator at the full load design rating conditions"
    static var full_load_evaporator_liquid_leaving_temperature_description: StringLiteral = "Liquid temperature at the exit flange of the evaporator at the full load design rating conditions"
    static var full_load_evaporator_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the evaporator at the full load design rating conditions"
    static var full_load_evaporator_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to evaporator heat exchanger fouling layer at the full load design rating conditions"
    static var full_load_condenser_liquid_volumetric_flow_rate_description: StringLiteral = "Condenser liquid volumetric flow rate at the full load design rating conditions"
    static var full_load_condenser_liquid_entering_temperature_description: StringLiteral = "Liquid temperature at the entry flange of the condenser at the full load design rating conditions"
    static var full_load_condenser_liquid_leaving_temperature_description: StringLiteral = "Liquid temperature at the exit flange of the condenser at the full load design rating conditions"
    static var full_load_condenser_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the condenser at the full load design rating conditions"
    static var full_load_condenser_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to condenser heat exchanger fouling layer at the full load design rating conditions"
    static var rating_recalculatable_from_performance_data_description: StringLiteral = "Whether this rating can be recalculated using the performance data in the representation"
    static var rating_recalculatable_explanation_description: StringLiteral = "An explanation of the value for `rating_recalculatable_from_performance_data`"
    static var certified_reference_number_name: StringLiteral = "certified_reference_number"
    static var test_standard_year_name: StringLiteral = "test_standard_year"
    static var rating_source_name: StringLiteral = "rating_source"
    static var net_refrigerating_capacity_name: StringLiteral = "net_refrigerating_capacity"
    static var input_power_name: StringLiteral = "input_power"
    static var cop_name: StringLiteral = "cop"
    static var part_load_value_name: StringLiteral = "part_load_value"
    static var part_load_rating_points_name: StringLiteral = "part_load_rating_points"
    static var full_load_evaporator_liquid_volumetric_flow_rate_name: StringLiteral = "full_load_evaporator_liquid_volumetric_flow_rate"
    static var full_load_evaporator_liquid_entering_temperature_name: StringLiteral = "full_load_evaporator_liquid_entering_temperature"
    static var full_load_evaporator_liquid_leaving_temperature_name: StringLiteral = "full_load_evaporator_liquid_leaving_temperature"
    static var full_load_evaporator_liquid_differential_pressure_name: StringLiteral = "full_load_evaporator_liquid_differential_pressure"
    static var full_load_evaporator_fouling_factor_name: StringLiteral = "full_load_evaporator_fouling_factor"
    static var full_load_condenser_liquid_volumetric_flow_rate_name: StringLiteral = "full_load_condenser_liquid_volumetric_flow_rate"
    static var full_load_condenser_liquid_entering_temperature_name: StringLiteral = "full_load_condenser_liquid_entering_temperature"
    static var full_load_condenser_liquid_leaving_temperature_name: StringLiteral = "full_load_condenser_liquid_leaving_temperature"
    static var full_load_condenser_liquid_differential_pressure_name: StringLiteral = "full_load_condenser_liquid_differential_pressure"
    static var full_load_condenser_fouling_factor_name: StringLiteral = "full_load_condenser_fouling_factor"
    static var rating_recalculatable_from_performance_data_name: StringLiteral = "rating_recalculatable_from_performance_data"
    static var rating_recalculatable_explanation_name: StringLiteral = "rating_recalculatable_explanation"

struct Description:
    var product_information: ProductInformation
    var rating_ahri_550_590: RatingAHRI550590
    var rating_ahri_551_591: RatingAHRI551591
    var product_information_is_set: Bool = False
    var rating_ahri_550_590_is_set: Bool = False
    var rating_ahri_551_591_is_set: Bool = False

    static var product_information_units: StringLiteral = ""
    static var rating_ahri_550_590_units: StringLiteral = ""
    static var rating_ahri_551_591_units: StringLiteral = ""
    static var product_information_description: StringLiteral = "Data group describing product information"
    static var rating_ahri_550_590_description: StringLiteral = "Data group containing information relevant to products rated under AHRI 550/590"
    static var rating_ahri_551_591_description: StringLiteral = "Data group containing information relevant to products rated under AHRI 551/591"
    static var product_information_name: StringLiteral = "product_information"
    static var rating_ahri_550_590_name: StringLiteral = "rating_ahri_550_590"
    static var rating_ahri_551_591_name: StringLiteral = "rating_ahri_551_591"

struct GridVariablesCooling:
    var evaporator_liquid_volumetric_flow_rate: List[Float64]
    var evaporator_liquid_leaving_temperature: List[Float64]
    var condenser_liquid_volumetric_flow_rate: List[Float64]
    var condenser_liquid_entering_temperature: List[Float64]
    var compressor_sequence_number: List[Int]
    var evaporator_liquid_volumetric_flow_rate_is_set: Bool = False
    var evaporator_liquid_leaving_temperature_is_set: Bool = False
    var condenser_liquid_volumetric_flow_rate_is_set: Bool = False
    var condenser_liquid_entering_temperature_is_set: Bool = False
    var compressor_sequence_number_is_set: Bool = False

    def populate_performance_map(inout self, performance_map: PerformanceMapBase):
        add_grid_axis(performance_map, self.evaporator_liquid_volumetric_flow_rate)
        add_grid_axis(performance_map, self.evaporator_liquid_leaving_temperature)
        add_grid_axis(performance_map, self.condenser_liquid_volumetric_flow_rate)
        add_grid_axis(performance_map, self.condenser_liquid_entering_temperature)
        add_grid_axis(performance_map, self.compressor_sequence_number)
        performance_map.finalize_grid(RS0001.logger)

    static var evaporator_liquid_volumetric_flow_rate_units: StringLiteral = "m3/s"
    static var evaporator_liquid_leaving_temperature_units: StringLiteral = "K"
    static var condenser_liquid_volumetric_flow_rate_units: StringLiteral = "m3/s"
    static var condenser_liquid_entering_temperature_units: StringLiteral = "K"
    static var compressor_sequence_number_units: StringLiteral = "-"
    static var evaporator_liquid_volumetric_flow_rate_description: StringLiteral = "Chilled liquid (evaporator) flow"
    static var evaporator_liquid_leaving_temperature_description: StringLiteral = "Leaving evaporator liquid temperature"
    static var condenser_liquid_volumetric_flow_rate_description: StringLiteral = "Condenser liquid flow"
    static var condenser_liquid_entering_temperature_description: StringLiteral = "Entering condenser liquid temperature"
    static var compressor_sequence_number_description: StringLiteral = "Index indicating the relative capacity order of the compressor speed/stage expressed in order from lowest capacity (starting at 1) to highest capacity"
    static var evaporator_liquid_volumetric_flow_rate_name: StringLiteral = "evaporator_liquid_volumetric_flow_rate"
    static var evaporator_liquid_leaving_temperature_name: StringLiteral = "evaporator_liquid_leaving_temperature"
    static var condenser_liquid_volumetric_flow_rate_name: StringLiteral = "condenser_liquid_volumetric_flow_rate"
    static var condenser_liquid_entering_temperature_name: StringLiteral = "condenser_liquid_entering_temperature"
    static var compressor_sequence_number_name: StringLiteral = "compressor_sequence_number"

struct LookupVariablesCooling:
    var input_power: List[Float64]
    var net_evaporator_capacity: List[Float64]
    var net_condenser_capacity: List[Float64]
    var evaporator_liquid_entering_temperature: List[Float64]
    var condenser_liquid_leaving_temperature: List[Float64]
    var evaporator_liquid_differential_pressure: List[Float64]
    var condenser_liquid_differential_pressure: List[Float64]
    var oil_cooler_heat: List[Float64]
    var auxiliary_heat: List[Float64]
    var input_power_is_set: Bool = False
    var net_evaporator_capacity_is_set: Bool = False
    var net_condenser_capacity_is_set: Bool = False
    var evaporator_liquid_entering_temperature_is_set: Bool = False
    var condenser_liquid_leaving_temperature_is_set: Bool = False
    var evaporator_liquid_differential_pressure_is_set: Bool = False
    var condenser_liquid_differential_pressure_is_set: Bool = False
    var oil_cooler_heat_is_set: Bool = False
    var auxiliary_heat_is_set: Bool = False

    def populate_performance_map(inout self, performance_map: PerformanceMapBase):
        add_data_table(performance_map, self.input_power)
        add_data_table(performance_map, self.net_evaporator_capacity)
        add_data_table(performance_map, self.net_condenser_capacity)
        add_data_table(performance_map, self.evaporator_liquid_entering_temperature)
        add_data_table(performance_map, self.condenser_liquid_leaving_temperature)
        add_data_table(performance_map, self.evaporator_liquid_differential_pressure)
        add_data_table(performance_map, self.condenser_liquid_differential_pressure)
        add_data_table(performance_map, self.oil_cooler_heat)
        add_data_table(performance_map, self.auxiliary_heat)

    static var input_power_units: StringLiteral = "W"
    static var net_evaporator_capacity_units: StringLiteral = "W"
    static var net_condenser_capacity_units: StringLiteral = "W"
    static var evaporator_liquid_entering_temperature_units: StringLiteral = "K"
    static var condenser_liquid_leaving_temperature_units: StringLiteral = "K"
    static var evaporator_liquid_differential_pressure_units: StringLiteral = "Pa"
    static var condenser_liquid_differential_pressure_units: StringLiteral = "Pa"
    static var oil_cooler_heat_units: StringLiteral = "W"
    static var auxiliary_heat_units: StringLiteral = "W"
    static var input_power_description: StringLiteral = "Total power input"
    static var net_evaporator_capacity_description: StringLiteral = "Refrigeration capacity"
    static var net_condenser_capacity_description: StringLiteral = "Condenser heat rejection"
    static var evaporator_liquid_entering_temperature_description: StringLiteral = "Entering evaporator liquid temperature"
    static var condenser_liquid_leaving_temperature_description: StringLiteral = "Leaving condenser liquid temperature"
    static var evaporator_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the evaporator"
    static var condenser_liquid_differential_pressure_description: StringLiteral = "Pressure difference across the condenser"
    static var oil_cooler_heat_description: StringLiteral = "Heat transferred to another liquid crossing the control volume boundary from the chiller oil cooler."
    static var auxiliary_heat_description: StringLiteral = "Heat transferred to another liquid crossing the control volume boundary from the chiller auxiliaries (motor, motor controller, inverter drive, starter, etc)."
    static var input_power_name: StringLiteral = "input_power"
    static var net_evaporator_capacity_name: StringLiteral = "net_evaporator_capacity"
    static var net_condenser_capacity_name: StringLiteral = "net_condenser_capacity"
    static var evaporator_liquid_entering_temperature_name: StringLiteral = "evaporator_liquid_entering_temperature"
    static var condenser_liquid_leaving_temperature_name: StringLiteral = "condenser_liquid_leaving_temperature"
    static var evaporator_liquid_differential_pressure_name: StringLiteral = "evaporator_liquid_differential_pressure"
    static var condenser_liquid_differential_pressure_name: StringLiteral = "condenser_liquid_differential_pressure"
    static var oil_cooler_heat_name: StringLiteral = "oil_cooler_heat"
    static var auxiliary_heat_name: StringLiteral = "auxiliary_heat"

struct LookupVariablesCoolingStruct:
    var f0: Float64
    var f1: Float64
    var f2: Float64
    var f3: Float64
    var f4: Float64
    var f5: Float64
    var f6: Float64
    var f7: Float64
    var f8: Float64

struct PerformanceMapCooling(PerformanceMapBase):
    var grid_variables: GridVariablesCooling
    var lookup_variables: LookupVariablesCooling
    var grid_variables_is_set: Bool = False
    var lookup_variables_is_set: Bool = False

    static var grid_variables_units: StringLiteral = ""
    static var lookup_variables_units: StringLiteral = ""
    static var grid_variables_description: StringLiteral = "Data group defining the grid variables for cooling performance"
    static var lookup_variables_description: StringLiteral = "Data group defining the lookup variables for cooling performance"
    static var grid_variables_name: StringLiteral = "grid_variables"
    static var lookup_variables_name: StringLiteral = "lookup_variables"

    def __init__(inout self):

    def initialize(inout self, j: JSON):
        a205_json_get[GridVariablesCooling](j, *RS0001.logger, "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
        self.grid_variables.populate_performance_map(self)
        a205_json_get[LookupVariablesCooling](j, *RS0001.logger, "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
        self.lookup_variables.populate_performance_map(self)

    def calculate_performance(self, evaporator_liquid_volumetric_flow_rate: Float64, evaporator_liquid_leaving_temperature: Float64, condenser_liquid_volumetric_flow_rate: Float64, condenser_liquid_entering_temperature: Float64, compressor_sequence_number: Float64, performance_interpolation_method: InterpolationMethod) -> LookupVariablesCoolingStruct:
        var target: List[Float64] = [evaporator_liquid_volumetric_flow_rate, evaporator_liquid_leaving_temperature, condenser_liquid_volumetric_flow_rate, condenser_liquid_entering_temperature, compressor_sequence_number]
        var v = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
        var s = LookupVariablesCoolingStruct(v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8])
        return s

struct GridVariablesStandby:
    var environment_dry_bulb_temperature: List[Float64]
    var environment_dry_bulb_temperature_is_set: Bool = False

    def populate_performance_map(inout self, performance_map: PerformanceMapBase):
        add_grid_axis(performance_map, self.environment_dry_bulb_temperature)
        performance_map.finalize_grid(RS0001.logger)

    static var environment_dry_bulb_temperature_units: StringLiteral = "K"
    static var environment_dry_bulb_temperature_description: StringLiteral = "Dry bulb temperature of the air in the environment of the chiller"
    static var environment_dry_bulb_temperature_name: StringLiteral = "environment_dry_bulb_temperature"

struct LookupVariablesStandby:
    var input_power: List[Float64]
    var input_power_is_set: Bool = False

    def populate_performance_map(inout self, performance_map: PerformanceMapBase):
        add_data_table(performance_map, self.input_power)

    static var input_power_units: StringLiteral = "W"
    static var input_power_description: StringLiteral = "Total power consumed in standby operation"
    static var input_power_name: StringLiteral = "input_power"

struct LookupVariablesStandbyStruct:
    var f0: Float64

struct PerformanceMapStandby(PerformanceMapBase):
    var grid_variables: GridVariablesStandby
    var lookup_variables: LookupVariablesStandby
    var grid_variables_is_set: Bool = False
    var lookup_variables_is_set: Bool = False

    static var grid_variables_units: StringLiteral = ""
    static var lookup_variables_units: StringLiteral = ""
    static var grid_variables_description: StringLiteral = "Data group defining the grid variables for standby performance"
    static var lookup_variables_description: StringLiteral = "Data group defining the lookup variables for standby performance"
    static var grid_variables_name: StringLiteral = "grid_variables"
    static var lookup_variables_name: StringLiteral = "lookup_variables"

    def __init__(inout self):

    def initialize(inout self, j: JSON):
        a205_json_get[GridVariablesStandby](j, *RS0001.logger, "grid_variables", self.grid_variables, self.grid_variables_is_set, True)
        self.grid_variables.populate_performance_map(self)
        a205_json_get[LookupVariablesStandby](j, *RS0001.logger, "lookup_variables", self.lookup_variables, self.lookup_variables_is_set, True)
        self.lookup_variables.populate_performance_map(self)

    def calculate_performance(self, environment_dry_bulb_temperature: Float64, performance_interpolation_method: InterpolationMethod) -> LookupVariablesStandbyStruct:
        var target: List[Float64] = [environment_dry_bulb_temperature]
        var v = PerformanceMapBase.calculate_performance(self, target, performance_interpolation_method)
        var s = LookupVariablesStandbyStruct(v[0])
        return s

struct Performance:
    var evaporator_liquid_type: LiquidMixture
    var condenser_liquid_type: LiquidMixture
    var evaporator_fouling_factor: Float64
    var condenser_fouling_factor: Float64
    var compressor_speed_control_type: SpeedControlType
    var maximum_power: Float64
    var cycling_degradation_coefficient: Float64
    var performance_map_cooling: PerformanceMapCooling
    var performance_map_standby: PerformanceMapStandby
    var evaporator_liquid_type_is_set: Bool = False
    var condenser_liquid_type_is_set: Bool = False
    var evaporator_fouling_factor_is_set: Bool = False
    var condenser_fouling_factor_is_set: Bool = False
    var compressor_speed_control_type_is_set: Bool = False
    var maximum_power_is_set: Bool = False
    var cycling_degradation_coefficient_is_set: Bool = False
    var performance_map_cooling_is_set: Bool = False
    var performance_map_standby_is_set: Bool = False

    static var evaporator_liquid_type_units: StringLiteral = ""
    static var condenser_liquid_type_units: StringLiteral = ""
    static var evaporator_fouling_factor_units: StringLiteral = "m2-K/W"
    static var condenser_fouling_factor_units: StringLiteral = "m2-K/W"
    static var compressor_speed_control_type_units: StringLiteral = ""
    static var maximum_power_units: StringLiteral = "W"
    static var cycling_degradation_coefficient_units: StringLiteral = "-"
    static var performance_map_cooling_units: StringLiteral = ""
    static var performance_map_standby_units: StringLiteral = ""
    static var evaporator_liquid_type_description: StringLiteral = "Type of liquid in evaporator"
    static var condenser_liquid_type_description: StringLiteral = "Type of liquid in condenser"
    static var evaporator_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to heat exchanger fouling layer"
    static var condenser_fouling_factor_description: StringLiteral = "Factor of heat transfer inhibition due to heat exchanger fouling layer"
    static var compressor_speed_control_type_description: StringLiteral = "Type of compressor speed control"
    static var maximum_power_description: StringLiteral = "Maximum input power at which the chiller operates reliably and continuously"
    static var cycling_degradation_coefficient_description: StringLiteral = "Cycling degradation coefficient (C~D~) as described in AHRI 550/590 or AHRI 551/591"
    static var performance_map_cooling_description: StringLiteral = "Data group describing cooling performance over a range of conditions"
    static var performance_map_standby_description: StringLiteral = "Data group describing standby performance"
    static var evaporator_liquid_type_name: StringLiteral = "evaporator_liquid_type"
    static var condenser_liquid_type_name: StringLiteral = "condenser_liquid_type"
    static var evaporator_fouling_factor_name: StringLiteral = "evaporator_fouling_factor"
    static var condenser_fouling_factor_name: StringLiteral = "condenser_fouling_factor"
    static var compressor_speed_control_type_name: StringLiteral = "compressor_speed_control_type"
    static var maximum_power_name: StringLiteral = "maximum_power"
    static var cycling_degradation_coefficient_name: StringLiteral = "cycling_degradation_coefficient"
    static var performance