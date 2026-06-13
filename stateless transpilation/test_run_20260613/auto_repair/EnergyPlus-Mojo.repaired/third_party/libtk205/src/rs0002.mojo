# Import necessary modules
from loadobject_205 import a205_json_get
from ashrae205 import ashrae205_ns  # Assumes module with Pattern, Metadata etc.
from rs0003 import rs0003_ns
from rs0004 import rs0004_ns

# Global logger for RS0002 (static variable)
var _RS0002_logger: Courierr.Courierr = Courierr.Courierr()

# Namespace tk205::rs0002_ns
struct tk205:
    struct rs0002_ns:
        # --- Schema ---
        struct Schema:
            @staticmethod
            def schema_title() -> String:
                return "Unitary Cooling Air-Conditioning Equipment"
            @staticmethod
            def schema_version() -> String:
                return "1.0.0"
            @staticmethod
            def schema_description() -> String:
                return "Schema for ASHRAE 205 annex RS0002: Unitary Cooling Air-Conditioning Equipment"

        # --- ProductInformation ---
        struct ProductInformation:
            var manufacturer: String
            var manufacturer_is_set: Bool
            var model_number: ashrae205_ns.Pattern
            var model_number_is_set: Bool

            @staticmethod
            def manufacturer_units() -> String:
                return ""
            @staticmethod
            def manufacturer_description() -> String:
                return "Package manufacturer name"
            @staticmethod
            def manufacturer_name() -> String:
                return "manufacturer"
            @staticmethod
            def model_number_units() -> String:
                return ""
            @staticmethod
            def model_number_description() -> String:
                return "Package model number"
            @staticmethod
            def model_number_name() -> String:
                return "model_number"

        # --- RatingAHRI210240 ---
        struct RatingAHRI210240:
            var certified_reference_number: String
            var certified_reference_number_is_set: Bool
            var test_standard_year: rs0002_ns.AHRI210240TestStandardYear
            var test_standard_year_is_set: Bool
            var rating_source: String
            var rating_source_is_set: Bool
            var staging_type: rs0002_ns.AHRI210240CompressorStagingType
            var staging_type_is_set: Bool
            var seer: Float64
            var seer_is_set: Bool
            var eer_a_full: Float64
            var eer_a_full_is_set: Bool
            var eer_b_full: Float64
            var eer_b_full_is_set: Bool
            var cooling_a_full_capacity: Float64
            var cooling_a_full_capacity_is_set: Bool
            var cooling_b_full_capacity: Float64
            var cooling_b_full_capacity_is_set: Bool
            var cooling_b_low_capacity: Float64
            var cooling_b_low_capacity_is_set: Bool
            var cooling_f_low_capacity: Float64
            var cooling_f_low_capacity_is_set: Bool
            var cooling_g_low_capacity: Float64
            var cooling_g_low_capacity_is_set: Bool
            var cooling_i_low_capacity: Float64
            var cooling_i_low_capacity_is_set: Bool
            var cooling_a_full_power: Float64
            var cooling_a_full_power_is_set: Bool
            var cooling_b_full_power: Float64
            var cooling_b_full_power_is_set: Bool
            var cooling_b_low_power: Float64
            var cooling_b_low_power_is_set: Bool
            var cooling_f_low_power: Float64
            var cooling_f_low_power_is_set: Bool
            var cooling_g_low_power: Float64
            var cooling_g_low_power_is_set: Bool
            var cooling_i_low_power: Float64
            var cooling_i_low_power_is_set: Bool
            var cooling_full_fan_power: Float64
            var cooling_full_fan_power_is_set: Bool
            var cooling_full_air_volumetric_flow_rate: Float64
            var cooling_full_air_volumetric_flow_rate_is_set: Bool
            var cooling_low_fan_power: Float64
            var cooling_low_fan_power_is_set: Bool
            var cooling_low_air_volumetric_flow_rate: Float64
            var cooling_low_air_volumetric_flow_rate_is_set: Bool
            var rating_recalculatable_from_performance_data: Bool
            var rating_recalculatable_from_performance_data_is_set: Bool
            var rating_recalculatable_explanation: String
            var rating_recalculatable_explanation_is_set: Bool

            # Static constants
            @staticmethod
            def certified_reference_number_units() -> String: return ""
            @staticmethod
            def test_standard_year_units() -> String: return ""
            @staticmethod
            def rating_source_units() -> String: return ""
            @staticmethod
            def staging_type_units() -> String: return ""
            @staticmethod
            def seer_units() -> String: return "Btu/W-h"
            @staticmethod
            def eer_a_full_units() -> String: return "Btu/W-h"
            @staticmethod
            def eer_b_full_units() -> String: return "Btu/W-h"
            @staticmethod
            def cooling_a_full_capacity_units() -> String: return "Btu/h"
            @staticmethod
            def cooling_b_full_capacity_units() -> String: return "Btu/h"
            @staticmethod
            def cooling_b_low_capacity_units() -> String: return "Btu/h"
            @staticmethod
            def cooling_f_low_capacity_units() -> String: return "Btu/h"
            @staticmethod
            def cooling_g_low_capacity_units() -> String: return "Btu/h"
            @staticmethod
            def cooling_i_low_capacity_units() -> String: return "Btu/h"
            @staticmethod
            def cooling_a_full_power_units() -> String: return "W"
            @staticmethod
            def cooling_b_full_power_units() -> String: return "W"
            @staticmethod
            def cooling_b_low_power_units() -> String: return "W"
            @staticmethod
            def cooling_f_low_power_units() -> String: return "W"
            @staticmethod
            def cooling_g_low_power_units() -> String: return "W"
            @staticmethod
            def cooling_i_low_power_units() -> String: return "W"
            @staticmethod
            def cooling_full_fan_power_units() -> String: return "W"
            @staticmethod
            def cooling_full_air_volumetric_flow_rate_units() -> String: return "cfm"
            @staticmethod
            def cooling_low_fan_power_units() -> String: return "W"
            @staticmethod
            def cooling_low_air_volumetric_flow_rate_units() -> String: return "cfm"
            @staticmethod
            def rating_recalculatable_from_performance_data_units() -> String: return ""
            @staticmethod
            def rating_recalculatable_explanation_units() -> String: return ""

            @staticmethod
            def certified_reference_number_description() -> String: return "AHRI certified reference number"
            @staticmethod
            def test_standard_year_description() -> String: return "Year of the AHRI test standard"
            @staticmethod
            def rating_source_description() -> String: return "Source of this rating data"
            @staticmethod
            def staging_type_description() -> String: return "Type of compressor staging"
            @staticmethod
            def seer_description() -> String: return "Seasonal Energy Efficiency Ratio"
            @staticmethod
            def eer_a_full_description() -> String: return "Full stage Energy Efficiency Ratio (at 'A' operating conditions)"
            @staticmethod
            def eer_b_full_description() -> String: return "Full stage Energy Efficiency Ratio (at 'B' operating conditions)"
            @staticmethod
            def cooling_a_full_capacity_description() -> String: return "Full stage net total cooling capacity (at 'A' operating conditions)"
            @staticmethod
            def cooling_b_full_capacity_description() -> String: return "Full stage net total cooling capacity (at 'B' operating conditions)"
            @staticmethod
            def cooling_b_low_capacity_description() -> String: return "Low stage net total cooling capacity (at 'B' operating conditions)"
            @staticmethod
            def cooling_f_low_capacity_description() -> String: return "Low stage net total cooling capacity (at 'F' operating conditions)"
            @staticmethod
            def cooling_g_low_capacity_description() -> String: return "Low stage net total cooling capacity (at 'G' operating conditions)"
            @staticmethod
            def cooling_i_low_capacity_description() -> String: return "Low stage net total cooling capacity (at 'I' operating conditions)"
            @staticmethod
            def cooling_a_full_power_description() -> String: return "Full stage net total cooling power (at 'A' operating conditions)"
            @staticmethod
            def cooling_b_full_power_description() -> String: return "Full stage net total cooling power (at 'B' operating conditions)"
            @staticmethod
            def cooling_b_low_power_description() -> String: return "Low stage net total cooling power (at 'B' operating conditions)"
            @staticmethod
            def cooling_f_low_power_description() -> String: return "Low stage net total cooling power (at 'F' operating conditions)"
            @staticmethod
            def cooling_g_low_power_description() -> String: return "Low stage net total cooling power (at 'G' operating conditions)"
            @staticmethod
            def cooling_i_low_power_description() -> String: return "Low stage net total cooling power (at 'I' operating conditions)"
            @staticmethod
            def cooling_full_fan_power_description() -> String: return "Power of the indoor fan at full load"
            @staticmethod
            def cooling_full_air_volumetric_flow_rate_description() -> String: return "Standard air volumetric rate of the indoor fan at full load"
            @staticmethod
            def cooling_low_fan_power_description() -> String: return "Power of the indoor fan at low stage"
            @staticmethod
            def cooling_low_air_volumetric_flow_rate_description() -> String: return "Standard air volumetric rate of the indoor fan at low stage"
            @staticmethod
            def rating_recalculatable_from_performance_data_description() -> String: return "Whether this rating can be recalculated using the performance data in the representation"
            @staticmethod
            def rating_recalculatable_explanation_description() -> String: return "An explanation of the value for `rating_recalculatable_from_performance_data`"

            @staticmethod
            def certified_reference_number_name() -> String: return "certified_reference_number"
            @staticmethod
            def test_standard_year_name() -> String: return "test_standard_year"
            @staticmethod
            def rating_source_name() -> String: return "rating_source"
            @staticmethod
            def staging_type_name() -> String: return "staging_type"
            @staticmethod
            def seer_name() -> String: return "seer"
            @staticmethod
            def eer_a_full_name() -> String: return "eer_a_full"
            @staticmethod
            def eer_b_full_name() -> String: return "eer_b_full"
            @staticmethod
            def cooling_a_full_capacity_name() -> String: return "cooling_a_full_capacity"
            @staticmethod
            def cooling_b_full_capacity_name() -> String: return "cooling_b_full_capacity"
            @staticmethod
            def cooling_b_low_capacity_name() -> String: return "cooling_b_low_capacity"
            @staticmethod
            def cooling_f_low_capacity_name() -> String: return "cooling_f_low_capacity"
            @staticmethod
            def cooling_g_low_capacity_name() -> String: return "cooling_g_low_capacity"
            @staticmethod
            def cooling_i_low_capacity_name() -> String: return "cooling_i_low_capacity"
            @staticmethod
            def cooling_a_full_power_name() -> String: return "cooling_a_full_power"
            @staticmethod
            def cooling_b_full_power_name() -> String: return "cooling_b_full_power"
            @staticmethod
            def cooling_b_low_power_name() -> String: return "cooling_b_low_power"
            @staticmethod
            def cooling_f_low_power_name() -> String: return "cooling_f_low_power"
            @staticmethod
            def cooling_g_low_power_name() -> String: return "cooling_g_low_power"
            @staticmethod
            def cooling_i_low_power_name() -> String: return "cooling_i_low_power"
            @staticmethod
            def cooling_full_fan_power_name() -> String: return "cooling_full_fan_power"
            @staticmethod
            def cooling_full_air_volumetric_flow_rate_name() -> String: return "cooling_full_air_volumetric_flow_rate"
            @staticmethod
            def cooling_low_fan_power_name() -> String: return "cooling_low_fan_power"
            @staticmethod
            def cooling_low_air_volumetric_flow_rate_name() -> String: return "cooling_low_air_volumetric_flow_rate"
            @staticmethod
            def rating_recalculatable_from_performance_data_name() -> String: return "rating_recalculatable_from_performance_data"
            @staticmethod
            def rating_recalculatable_explanation_name() -> String: return "rating_recalculatable_explanation"

        # --- RatingAHRI340360CoolingPartLoadPoint ---
        struct RatingAHRI340360CoolingPartLoadPoint:
            var capacity: Float64
            var capacity_is_set: Bool
            var net_power: Float64
            var net_power_is_set: Bool
            var indoor_fan_power: Float64
            var indoor_fan_power_is_set: Bool
            var auxiliary_power: Float64
            var auxiliary_power_is_set: Bool
            var air_volumetric_flow_rate: Float64
            var air_volumetric_flow_rate_is_set: Bool

            @staticmethod
            def capacity_units() -> String: return "Btu/h"
            @staticmethod
            def net_power_units() -> String: return "W"
            @staticmethod
            def indoor_fan_power_units() -> String: return "W"
            @staticmethod
            def auxiliary_power_units() -> String: return "W"
            @staticmethod
            def air_volumetric_flow_rate_units() -> String: return "cfm"

            @staticmethod
            def capacity_description() -> String: return "Net total cooling capacity"
            @staticmethod
            def net_power_description() -> String: return "Net cooling power (including the indoor fan motor, controls, and other auxiliary loads)"
            @staticmethod
            def indoor_fan_power_description() -> String: return "Power of the indoor fan motor"
            @staticmethod
            def auxiliary_power_description() -> String: return "Power of the control circuit and any other auxiliary loads"
            @staticmethod
            def air_volumetric_flow_rate_description() -> String: return "Standard air volumetric rate of the indoor fan"

            @staticmethod
            def capacity_name() -> String: return "capacity"
            @staticmethod
            def net_power_name() -> String: return "net_power"
            @staticmethod
            def indoor_fan_power_name() -> String: return "indoor_fan_power"
            @staticmethod
            def auxiliary_power_name() -> String: return "auxiliary_power"
            @staticmethod
            def air_volumetric_flow_rate_name() -> String: return "air_volumetric_flow_rate"

        # --- RatingAHRI340360 ---
        struct RatingAHRI340360:
            var certified_reference_number: String
            var certified_reference_number_is_set: Bool
            var test_standard_year: rs0002_ns.AHRI340360TestStandardYear
            var test_standard_year_is_set: Bool
            var rating_source: String
            var rating_source_is_set: Bool
            var capacity_control_type: rs0002_ns.AHRI340360CapacityControlType
            var capacity_control_type_is_set: Bool
            var ieer: Float64
            var ieer_is_set: Bool
            var eer: Float64
            var eer_is_set: Bool
            var cooling_capacity: Float64
            var cooling_capacity_is_set: Bool
            var part_load_points: List[rs0002_ns.RatingAHRI340360CoolingPartLoadPoint]
            var part_load_points_is_set: Bool
            var rating_recalculatable_from_performance_data: Bool
            var rating_recalculatable_from_performance_data_is_set: Bool
            var rating_recalculatable_explanation: String
            var rating_recalculatable_explanation_is_set: Bool

            @staticmethod
            def certified_reference_number_units() -> String: return ""
            @staticmethod
            def test_standard_year_units() -> String: return ""
            @staticmethod
            def rating_source_units() -> String: return ""
            @staticmethod
            def capacity_control_type_units() -> String: return ""
            @staticmethod
            def ieer_units() -> String: return "Btu/W-h"
            @staticmethod
            def eer_units() -> String: return "Btu/W-h"
            @staticmethod
            def cooling_capacity_units() -> String: return "Btu/h"
            @staticmethod
            def part_load_points_units() -> String: return ""
            @staticmethod
            def rating_recalculatable_from_performance_data_units() -> String: return ""
            @staticmethod
            def rating_recalculatable_explanation_units() -> String: return ""

            @staticmethod
            def certified_reference_number_description() -> String: return "AHRI Certified Reference Number"
            @staticmethod
            def test_standard_year_description() -> String: return "Name and version of the AHRI test standard"
            @staticmethod
            def rating_source_description() -> String: return "Source of this rating data"
            @staticmethod
            def capacity_control_type_description() -> String: return "Type of capacity control"
            @staticmethod
            def ieer_description() -> String: return "Integrated Energy Efficiency Ratio"
            @staticmethod
            def eer_description() -> String: return "Energy Efficiency Ratio at Standard Rating Conditions"
            @staticmethod
            def cooling_capacity_description() -> String: return "Net total cooling capacity at Standard Rating Conditions"
            @staticmethod
            def part_load_points_description() -> String: return "Four part load rating points"
            @staticmethod
            def rating_recalculatable_from_performance_data_description() -> String: return "Whether this rating can be recalculated using the performance data in the representation"
            @staticmethod
            def rating_recalculatable_explanation_description() -> String: return "An explanation of the value for `rating_recalculatable_from_performance_data`"

            @staticmethod
            def certified_reference_number_name() -> String: return "certified_reference_number"
            @staticmethod
            def test_standard_year_name() -> String: return "test_standard_year"
            @staticmethod
            def rating_source_name() -> String: return "rating_source"
            @staticmethod
            def capacity_control_type_name() -> String: return "capacity_control_type"
            @staticmethod
            def ieer_name() -> String: return "ieer"
            @staticmethod
            def eer_name() -> String: return "eer"
            @staticmethod
            def cooling_capacity_name() -> String: return "cooling_capacity"
            @staticmethod
            def part_load_points_name() -> String: return "part_load_points"
            @staticmethod
            def rating_recalculatable_from_performance_data_name() -> String: return "rating_recalculatable_from_performance_data"
            @staticmethod
            def rating_recalculatable_explanation_name() -> String: return "rating_recalculatable_explanation"

        # --- Description ---
        struct Description:
            var product_information: rs0002_ns.ProductInformation
            var product_information_is_set: Bool
            var rating_ahri_210_240: rs0002_ns.RatingAHRI210240
            var rating_ahri_210_240_is_set: Bool
            var rating_ahri_340_360: rs0002_ns.RatingAHRI340360
            var rating_ahri_340_360_is_set: Bool

            @staticmethod
            def product_information_units() -> String: return ""
            @staticmethod
            def rating_ahri_210_240_units() -> String: return ""
            @staticmethod
            def rating_ahri_340_360_units() -> String: return ""

            @staticmethod
            def product_information_description() -> String: return "Data group describing product information"
            @staticmethod
            def rating_ahri_210_240_description() -> String: return "Data group containing information relevant to products rated under AHRI 210/240"
            @staticmethod
            def rating_ahri_340_360_description() -> String: return "Data group containing information relevant to products rated under AHRI 340/360"

            @staticmethod
            def product_information_name() -> String: return "product_information"
            @staticmethod
            def rating_ahri_210_240_name() -> String: return "rating_ahri_210_240"
            @staticmethod
            def rating_ahri_340_360_name() -> String: return "rating_ahri_340_360"

        # --- Performance ---
        struct Performance:
            var standby_power: Float64
            var standby_power_is_set: Bool
            var indoor_fan_representation: rs0003_ns.RS0003
            var indoor_fan_representation_is_set: Bool
            var fan_position: rs0002_ns.FanPosition
            var fan_position_is_set: Bool
            var dx_system_representation: rs0004_ns.RS0004
            var dx_system_representation_is_set: Bool

            @staticmethod
            def standby_power_units() -> String: return "W"
            @staticmethod
            def indoor_fan_representation_units() -> String: return ""
            @staticmethod
            def fan_position_units() -> String: return ""
            @staticmethod
            def dx_system_representation_units() -> String: return ""

            @staticmethod
            def standby_power_description() -> String: return "Continuous unit power draw regardless of fan or DX system operation"
            @staticmethod
            def indoor_fan_representation_description() -> String: return "The corresponding Standard 205 fan assembly representation"
            @staticmethod
            def fan_position_description() -> String: return "Position of the fan relative to the cooling coil"
            @staticmethod
            def dx_system_representation_description() -> String: return "The corresponding Standard 205 direct expansion system representation"

            @staticmethod
            def standby_power_name() -> String: return "standby_power"
            @staticmethod
            def indoor_fan_representation_name() -> String: return "indoor_fan_representation"
            @staticmethod
            def fan_position_name() -> String: return "fan_position"
            @staticmethod
            def dx_system_representation_name() -> String: return "dx_system_representation"

        # --- RS0002 ---
        struct RS0002:
            var metadata: ashrae205_ns.Metadata
            var metadata_is_set: Bool
            var description: rs0002_ns.Description
            var description_is_set: Bool
            var performance: rs0002_ns.Performance
            var performance_is_set: Bool

            @staticmethod
            def logger() -> ref Courierr.Courierr:
                return _RS0002_logger

            @staticmethod
            def metadata_units() -> String: return ""
            @staticmethod
            def description_units() -> String: return ""
            @staticmethod
            def performance_units() -> String: return ""

            @staticmethod
            def metadata_description() -> String: return "Metadata data group"
            @staticmethod
            def description_description() -> String: return "Data group describing product and rating information"
            @staticmethod
            def performance_description() -> String: return "Data group containing performance information"

            @staticmethod
            def metadata_name() -> String: return "metadata"
            @staticmethod
            def description_name() -> String: return "description"
            @staticmethod
            def performance_name() -> String: return "performance"

            def initialize(self_ref, j: Dict[String, Any]):
                a205_json_get[ashrae205_ns.Metadata](j, *RS0002.logger(), "metadata", self_ref.metadata, self_ref.metadata_is_set, True)
                a205_json_get[rs0002_ns.Description](j, *RS0002.logger(), "description", self_ref.description, self_ref.description_is_set, False)
                a205_json_get[rs0002_ns.Performance](j, *RS0002.logger(), "performance", self_ref.performance, self_ref.performance_is_set, True)

        # --- Free functions (namespace scope) ---
        @staticmethod
        def from_json(j: Dict[String, Any], x: ref rs0002_ns.ProductInformation):
            a205_json_get[String](j, *RS0002.logger(), "manufacturer", x.manufacturer, x.manufacturer_is_set, False)
            a205_json_get[ashrae205_ns.Pattern](j, *RS0002.logger(), "model_number", x.model_number, x.model_number_is_set, False)

        @staticmethod
        def from_json(j: Dict[String, Any], x: ref rs0002_ns.RatingAHRI210240):
            a205_json_get[String](j, *RS0002.logger(), "certified_reference_number", x.certified_reference_number, x.certified_reference_number_is_set, True)
            a205_json_get[rs0002_ns.AHRI210240TestStandardYear](j, *RS0002.logger(), "test_standard_year", x.test_standard_year, x.test_standard_year_is_set, True)
            a205_json_get[String](j, *RS0002.logger(), "rating_source", x.rating_source, x.rating_source_is_set, False)
            a205_json_get[rs0002_ns.AHRI210240CompressorStagingType](j, *RS0002.logger(), "staging_type", x.staging_type, x.staging_type_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "seer", x.seer, x.seer_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "eer_a_full", x.eer_a_full, x.eer_a_full_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "eer_b_full", x.eer_b_full, x.eer_b_full_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_a_full_capacity", x.cooling_a_full_capacity, x.cooling_a_full_capacity_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_b_full_capacity", x.cooling_b_full_capacity, x.cooling_b_full_capacity_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_b_low_capacity", x.cooling_b_low_capacity, x.cooling_b_low_capacity_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_f_low_capacity", x.cooling_f_low_capacity, x.cooling_f_low_capacity_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_g_low_capacity", x.cooling_g_low_capacity, x.cooling_g_low_capacity_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_i_low_capacity", x.cooling_i_low_capacity, x.cooling_i_low_capacity_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_a_full_power", x.cooling_a_full_power, x.cooling_a_full_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_b_full_power", x.cooling_b_full_power, x.cooling_b_full_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_b_low_power", x.cooling_b_low_power, x.cooling_b_low_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_f_low_power", x.cooling_f_low_power, x.cooling_f_low_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_g_low_power", x.cooling_g_low_power, x.cooling_g_low_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_i_low_power", x.cooling_i_low_power, x.cooling_i_low_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_full_fan_power", x.cooling_full_fan_power, x.cooling_full_fan_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_full_air_volumetric_flow_rate", x.cooling_full_air_volumetric_flow_rate, x.cooling_full_air_volumetric_flow_rate_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_low_fan_power", x.cooling_low_fan_power, x.cooling_low_fan_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_low_air_volumetric_flow_rate", x.cooling_low_air_volumetric_flow_rate, x.cooling_low_air_volumetric_flow_rate_is_set, True)
            a205_json_get[Bool](j, *RS0002.logger(), "rating_recalculatable_from_performance_data", x.rating_recalculatable_from_performance_data, x.rating_recalculatable_from_performance_data_is_set, True)
            a205_json_get[String](j, *RS0002.logger(), "rating_recalculatable_explanation", x.rating_recalculatable_explanation, x.rating_recalculatable_explanation_is_set, False)

        @staticmethod
        def from_json(j: Dict[String, Any], x: ref rs0002_ns.RatingAHRI340360CoolingPartLoadPoint):
            a205_json_get[Float64](j, *RS0002.logger(), "capacity", x.capacity, x.capacity_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "net_power", x.net_power, x.net_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "indoor_fan_power", x.indoor_fan_power, x.indoor_fan_power_is_set, False)
            a205_json_get[Float64](j, *RS0002.logger(), "auxiliary_power", x.auxiliary_power, x.auxiliary_power_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "air_volumetric_flow_rate", x.air_volumetric_flow_rate, x.air_volumetric_flow_rate_is_set, True)

        @staticmethod
        def from_json(j: Dict[String, Any], x: ref rs0002_ns.RatingAHRI340360):
            a205_json_get[String](j, *RS0002.logger(), "certified_reference_number", x.certified_reference_number, x.certified_reference_number_is_set, True)
            a205_json_get[rs0002_ns.AHRI340360TestStandardYear](j, *RS0002.logger(), "test_standard_year", x.test_standard_year, x.test_standard_year_is_set, True)
            a205_json_get[String](j, *RS0002.logger(), "rating_source", x.rating_source, x.rating_source_is_set, False)
            a205_json_get[rs0002_ns.AHRI340360CapacityControlType](j, *RS0002.logger(), "capacity_control_type", x.capacity_control_type, x.capacity_control_type_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "ieer", x.ieer, x.ieer_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "eer", x.eer, x.eer_is_set, True)
            a205_json_get[Float64](j, *RS0002.logger(), "cooling_capacity", x.cooling_capacity, x.cooling_capacity_is_set, True)
            a205_json_get[List[rs0002_ns.RatingAHRI340360CoolingPartLoadPoint]](j, *RS0002.logger(), "part_load_points", x.part_load_points, x.part_load_points_is_set, False)
            a205_json_get[Bool](j, *RS0002.logger(), "rating_recalculatable_from_performance_data", x.rating_recalculatable_from_performance_data, x.rating_recalculatable_from_performance_data_is_set, True)
            a205_json_get[String](j, *RS0002.logger(), "rating_recalculatable_explanation", x.rating_recalculatable_explanation, x.rating_recalculatable_explanation_is_set, False)

        @staticmethod
        def from_json(j: Dict[String, Any], x: ref rs0002_ns.Description):
            a205_json_get[rs0002_ns.ProductInformation](j, *RS0002.logger(), "product_information", x.product_information, x.product_information_is_set, False)
            a205_json_get[rs0002_ns.RatingAHRI210240](j, *RS0002.logger(), "rating_ahri_210_240", x.rating_ahri_210_240, x.rating_ahri_210_240_is_set, False)
            a205_json_get[rs0002_ns.RatingAHRI340360](j, *RS0002.logger(), "rating_ahri_340_360", x.rating_ahri_340_360, x.rating_ahri_340_360_is_set, False)

        @staticmethod
        def from_json(j: Dict[String, Any], x: ref rs0002_ns.Performance):
            a205_json_get[Float64](j, *RS0002.logger(), "standby_power", x.standby_power, x.standby_power_is_set, True)
            a205_json_get[rs0003_ns.RS0003](j, *RS0002.logger(), "indoor_fan_representation", x.indoor_fan_representation, x.indoor_fan_representation_is_set, False)
            a205_json_get[rs0002_ns.FanPosition](j, *RS0002.logger(), "fan_position", x.fan_position, x.fan_position_is_set, True)
            a205_json_get[rs0004_ns.RS0004](j, *RS0002.logger(), "dx_system_representation", x.dx_system_representation, x.dx_system_representation_is_set, False)

        @staticmethod
        def from_json(j: Dict[String, Any], x: ref rs0002_ns.RS0002):
            a205_json_get[ashrae205_ns.Metadata](j, *RS0002.logger(), "metadata", x.metadata, x.metadata_is_set, True)
            a205_json_get[rs0002_ns.Description](j, *RS0002.logger(), "description", x.description, x.description_is_set, False)
            a205_json_get[rs0002_ns.Performance](j, *RS0002.logger(), "performance", x.performance, x.performance_is_set, True)