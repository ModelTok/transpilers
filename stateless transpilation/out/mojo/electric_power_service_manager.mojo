from memory import Span, UnsafePointer
from collections import InlineArray, Dict
from math import pow, sqrt, floor, ceil, sin, cos, exp, log, abs, min, max

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container (wire from EnergyPlus core)
# - Schedule, Curve: managed references to schedule/curve objects in state
# - OutputProcessor: meter and output variable registration
# - EMSManager: EMS setup functions
# - PVWatts: PVWattsGenerator class
# - battery_t, battery_state, lifetime_t, etc.: SSC battery library types


fn nint(x: Float64) -> Int64:
    """Round to nearest integer, away from zero (Fortran NINT semantics)."""
    if x >= 0.0:
        return Int64(floor(x + 0.5))
    else:
        return Int64(ceil(x - 0.5))


@export
alias GeneratorType = Int32


fn get_generator_type_from_name(name: StringRef) -> GeneratorType:
    """Map generator type name to enum value."""
    if name == "GENERATOR:INTERNALCOMBUSTIONENGINE":
        return 0
    elif name == "GENERATOR:COMBUSTIONTURBINE":
        return 1
    elif name == "GENERATOR:PHOTOVOLTAIC":
        return 2
    elif name == "GENERATOR:FUELCELL":
        return 3
    elif name == "GENERATOR:MICROCHP":
        return 4
    elif name == "GENERATOR:MICROTURBINE":
        return 5
    elif name == "GENERATOR:WINDTURBINE":
        return 6
    elif name == "GENERATOR:PVWATTS":
        return 7
    else:
        return -1


struct GeneratorTypeNames:
    alias DATA: InlineArray[StringRef, 8] = InlineArray[StringRef, 8](
        "Generator:InternalCombustionEngine",
        "Generator:CombustionTurbine",
        "Generator:Photovoltaic",
        "Generator:FuelCell",
        "Generator:MicroCHP",
        "Generator:MicroTurbine",
        "Generator:WindTurbine",
        "Generator:PVWatts",
    )


struct GeneratorTypeNamesUC:
    alias DATA: InlineArray[StringRef, 8] = InlineArray[StringRef, 8](
        "GENERATOR:INTERNALCOMBUSTIONENGINE",
        "GENERATOR:COMBUSTIONTURBINE",
        "GENERATOR:PHOTOVOLTAIC",
        "GENERATOR:FUELCELL",
        "GENERATOR:MICROCHP",
        "GENERATOR:MICROTURBINE",
        "GENERATOR:WINDTURBINE",
        "GENERATOR:PVWATTS",
    )


struct ThermalLossDestination:
    alias INVALID = -1
    alias ZONE_GAINS = 0
    alias LOST_TO_OUTSIDE = 1
    alias NUM = 2


struct DCtoACInverter:
    alias InverterModelType_INVALID = -1
    alias InverterModelType_CEC_LOOKUP_TABLE_MODEL = 0
    alias InverterModelType_CURVE_FUNC_OF_POWER = 1
    alias InverterModelType_SIMPLE_CONSTANT_EFF = 2
    alias InverterModelType_PVWATTS = 3
    alias InverterModelType_NUM = 4

    var name_: String
    var ac_power_out_: Float64
    var ac_energy_out_: Float64
    var efficiency_: Float64
    var dc_power_in_: Float64
    var dc_energy_in_: Float64
    var conversion_loss_power_: Float64
    var conversion_loss_energy_: Float64
    var conversion_loss_energy_decrement_: Float64
    var therm_loss_rate_: Float64
    var therm_loss_energy_: Float64
    var qdot_conv_zone_: Float64
    var qdot_rad_zone_: Float64
    var ancill_ac_use_rate_: Float64
    var ancill_ac_use_energy_: Float64
    var model_type_: Int32
    var avail_sched_: UnsafePointer[UInt8]  # Schedule*
    var heat_losses_destination_: Int32
    var zone_num_: Int32
    var zone_rad_fract_: Float64
    var nominal_voltage_: Float64
    var nom_volt_efficiency_arr_: InlineArray[Float64, 6]
    var eff_curve_: UnsafePointer[UInt8]  # Curve*
    var rated_power_: Float64
    var min_power_: Float64
    var max_power_: Float64
    var min_efficiency_: Float64
    var max_efficiency_: Float64
    var standby_power_: Float64
    var pvwatts_dc_to_ac_size_ratio_: Float64
    var pvwatts_inverter_efficiency_: Float64

    fn __init__(inout self, object_name: String) -> None:
        self.name_ = object_name
        self.ac_power_out_ = 0.0
        self.ac_energy_out_ = 0.0
        self.efficiency_ = 0.0
        self.dc_power_in_ = 0.0
        self.dc_energy_in_ = 0.0
        self.conversion_loss_power_ = 0.0
        self.conversion_loss_energy_ = 0.0
        self.conversion_loss_energy_decrement_ = 0.0
        self.therm_loss_rate_ = 0.0
        self.therm_loss_energy_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0
        self.ancill_ac_use_rate_ = 0.0
        self.ancill_ac_use_energy_ = 0.0
        self.model_type_ = Self.InverterModelType_INVALID
        self.avail_sched_ = UnsafePointer[UInt8]()
        self.heat_losses_destination_ = ThermalLossDestination.INVALID
        self.zone_num_ = 0
        self.zone_rad_fract_ = 0.0
        self.nominal_voltage_ = 0.0
        self.nom_volt_efficiency_arr_ = InlineArray[Float64, 6](fill=0.0)
        self.eff_curve_ = UnsafePointer[UInt8]()
        self.rated_power_ = 0.0
        self.min_power_ = 0.0
        self.max_power_ = 0.0
        self.min_efficiency_ = 0.0
        self.max_efficiency_ = 0.0
        self.standby_power_ = 0.0
        self.pvwatts_dc_to_ac_size_ratio_ = 0.0
        self.pvwatts_inverter_efficiency_ = 0.0

    fn simulate(inout self, state: UnsafePointer[UInt8], power_into_inverter: Float64) -> None:
        self.dc_power_in_ = power_into_inverter
        self.dc_energy_in_ = self.dc_power_in_ * 900.0  # Placeholder for TimeStepSysSec
        # Check availability schedule (placeholder)
        # if avail_sched_.getCurrentVal() > 0.0:
        self.calc_efficiency(state)
        self.ac_power_out_ = self.efficiency_ * self.dc_power_in_
        self.ac_energy_out_ = self.ac_power_out_ * 900.0
        if self.ac_power_out_ == 0.0:
            self.ancill_ac_use_energy_ = self.standby_power_ * 900.0
            self.ancill_ac_use_rate_ = self.standby_power_
        else:
            self.ancill_ac_use_rate_ = 0.0
            self.ancill_ac_use_energy_ = 0.0
        self.conversion_loss_power_ = self.dc_power_in_ - self.ac_power_out_
        self.conversion_loss_energy_ = self.conversion_loss_power_ * 900.0
        self.conversion_loss_energy_decrement_ = -1.0 * self.conversion_loss_energy_
        self.therm_loss_rate_ = self.dc_power_in_ - self.ac_power_out_ + self.ancill_ac_use_rate_
        self.therm_loss_energy_ = self.therm_loss_rate_ * 900.0
        self.qdot_conv_zone_ = self.therm_loss_rate_ * (1.0 - self.zone_rad_fract_)
        self.qdot_rad_zone_ = self.therm_loss_rate_ * self.zone_rad_fract_

    fn reinit_at_begin_environment(inout self) -> None:
        self.ancill_ac_use_rate_ = 0.0
        self.ancill_ac_use_energy_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    fn reinit_zone_gains_at_begin_environment(inout self) -> None:
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    fn set_pvwatts_dc_capacity(inout self, state: UnsafePointer[UInt8], dc_capacity: Float64) -> None:
        if self.model_type_ != Self.InverterModelType_PVWATTS:
            # Error: Setting DC capacity only works with PVWatts inverters
            return
        self.rated_power_ = dc_capacity / self.pvwatts_dc_to_ac_size_ratio_

    fn pvwatts_dc_capacity(self) -> Float64:
        return self.rated_power_ * self.pvwatts_dc_to_ac_size_ratio_

    fn pvwatts_inverter_efficiency(self) -> Float64:
        return self.pvwatts_inverter_efficiency_

    fn pvwatts_dc_to_ac_size_ratio(self) -> Float64:
        return self.pvwatts_dc_to_ac_size_ratio_

    fn ac_power_out(self) -> Float64:
        return self.ac_power_out_

    fn model_type(self) -> Int32:
        return self.model_type_

    fn name(self) -> String:
        return self.name_

    fn get_loss_rate_for_output_power(inout self, state: UnsafePointer[UInt8],
                                     power_out_of_inverter: Float64) -> Float64:
        if self.efficiency_ > 0.0:
            self.dc_power_in_ = power_out_of_inverter / self.efficiency_
        else:
            self.dc_power_in_ = power_out_of_inverter
            self.calc_efficiency(state)
            self.dc_power_in_ = power_out_of_inverter / self.efficiency_
        self.calc_efficiency(state)
        if self.efficiency_ > 0.0:
            self.dc_power_in_ = power_out_of_inverter / self.efficiency_
        self.calc_efficiency(state)
        return (1.0 - self.efficiency_) * self.dc_power_in_

    fn calc_efficiency(inout self, state: UnsafePointer[UInt8]) -> None:
        if self.model_type_ == Self.InverterModelType_CEC_LOOKUP_TABLE_MODEL:
            let normalized_power = self.dc_power_in_ / self.rated_power_
            if normalized_power <= 0.1:
                self.efficiency_ = self.nom_volt_efficiency_arr_[0]
            elif normalized_power > 0.1 and normalized_power < 0.2:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[0] +
                                   ((normalized_power - 0.1) / 0.1) *
                                   (self.nom_volt_efficiency_arr_[1] - self.nom_volt_efficiency_arr_[0]))
            elif normalized_power == 0.2:
                self.efficiency_ = self.nom_volt_efficiency_arr_[1]
            elif normalized_power > 0.2 and normalized_power < 0.3:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[1] +
                                   ((normalized_power - 0.2) / 0.1) *
                                   (self.nom_volt_efficiency_arr_[2] - self.nom_volt_efficiency_arr_[1]))
            elif normalized_power == 0.3:
                self.efficiency_ = self.nom_volt_efficiency_arr_[2]
            elif normalized_power > 0.3 and normalized_power < 0.5:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[2] +
                                   ((normalized_power - 0.3) / 0.2) *
                                   (self.nom_volt_efficiency_arr_[3] - self.nom_volt_efficiency_arr_[2]))
            elif normalized_power == 0.5:
                self.efficiency_ = self.nom_volt_efficiency_arr_[3]
            elif normalized_power > 0.5 and normalized_power < 0.75:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[3] +
                                   ((normalized_power - 0.5) / 0.25) *
                                   (self.nom_volt_efficiency_arr_[4] - self.nom_volt_efficiency_arr_[3]))
            elif normalized_power == 0.75:
                self.efficiency_ = self.nom_volt_efficiency_arr_[4]
            elif normalized_power > 0.75 and normalized_power < 1.0:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[4] +
                                   ((normalized_power - 0.75) / 0.25) *
                                   (self.nom_volt_efficiency_arr_[5] - self.nom_volt_efficiency_arr_[4]))
            elif normalized_power >= 1.0:
                self.efficiency_ = self.nom_volt_efficiency_arr_[5]
            self.efficiency_ = max(self.efficiency_, 0.0)
            self.efficiency_ = min(self.efficiency_, 1.0)
        elif self.model_type_ == Self.InverterModelType_CURVE_FUNC_OF_POWER:
            let normalized_power = self.dc_power_in_ / self.rated_power_
            # Placeholder for curve evaluation
            self.efficiency_ = max(self.efficiency_, self.min_efficiency_)
            self.efficiency_ = min(self.efficiency_, self.max_efficiency_)
        elif self.model_type_ == Self.InverterModelType_PVWATTS:
            let etaref = 0.9637
            let A = -0.0162
            let B = -0.0059
            let C = 0.9858
            let pdc0 = self.rated_power_ / self.pvwatts_inverter_efficiency_
            let plr = self.dc_power_in_ / pdc0
            var ac = 0.0
            if plr > 0:
                let eta = (A * plr + B / plr + C) * self.pvwatts_inverter_efficiency_ / etaref
                ac = self.dc_power_in_ * eta
                if ac > self.rated_power_:
                    ac = self.rated_power_
                if ac < 0:
                    ac = 0
                self.efficiency_ = ac / self.dc_power_in_
            else:
                self.efficiency_ = 1.0


struct ACtoDCConverter:
    alias ConverterModelType_INVALID = -1
    alias ConverterModelType_CURVE_FUNC_OF_POWER = 0
    alias ConverterModelType_SIMPLE_CONSTANT_EFF = 1
    alias ConverterModelType_NUM = 2

    var name_: String
    var efficiency_: Float64
    var ac_power_in_: Float64
    var ac_energy_in_: Float64
    var dc_power_out_: Float64
    var dc_energy_out_: Float64
    var conversion_loss_power_: Float64
    var conversion_loss_energy_: Float64
    var conversion_loss_energy_decrement_: Float64
    var therm_loss_rate_: Float64
    var therm_loss_energy_: Float64
    var qdot_conv_zone_: Float64
    var qdot_rad_zone_: Float64
    var ancill_ac_use_rate_: Float64
    var ancill_ac_use_energy_: Float64
    var avail_sched_: UnsafePointer[UInt8]
    var model_type_: Int32
    var eff_curve_: UnsafePointer[UInt8]
    var heat_losses_destination_: Int32
    var zone_num_: Int32
    var zone_rad_fract_: Float64
    var standby_power_: Float64
    var max_power_: Float64

    fn __init__(inout self, object_name: String) -> None:
        self.name_ = object_name
        self.efficiency_ = 0.0
        self.ac_power_in_ = 0.0
        self.ac_energy_in_ = 0.0
        self.dc_power_out_ = 0.0
        self.dc_energy_out_ = 0.0
        self.conversion_loss_power_ = 0.0
        self.conversion_loss_energy_ = 0.0
        self.conversion_loss_energy_decrement_ = 0.0
        self.therm_loss_rate_ = 0.0
        self.therm_loss_energy_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0
        self.ancill_ac_use_rate_ = 0.0
        self.ancill_ac_use_energy_ = 0.0
        self.avail_sched_ = UnsafePointer[UInt8]()
        self.model_type_ = Self.ConverterModelType_INVALID
        self.eff_curve_ = UnsafePointer[UInt8]()
        self.heat_losses_destination_ = ThermalLossDestination.INVALID
        self.zone_num_ = 0
        self.zone_rad_fract_ = 0.0
        self.standby_power_ = 0.0
        self.max_power_ = 0.0

    fn simulate(inout self, state: UnsafePointer[UInt8], power_out_from_converter: Float64) -> None:
        # Placeholder implementation
        pass

    fn reinit_at_begin_environment(inout self) -> None:
        self.ancill_ac_use_rate_ = 0.0
        self.ancill_ac_use_energy_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    fn reinit_zone_gains_at_begin_environment(inout self) -> None:
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    fn ac_power_in(self) -> Float64:
        return self.ac_power_in_

    fn get_loss_rate_for_input_power(inout self, state: UnsafePointer[UInt8],
                                    power_into_converter: Float64) -> Float64:
        self.ac_power_in_ = power_into_converter
        self.calc_efficiency(state)
        return (1.0 - self.efficiency_) * self.ac_power_in_

    fn name(self) -> String:
        return self.name_

    fn calc_efficiency(inout self, state: UnsafePointer[UInt8]) -> None:
        if self.model_type_ == Self.ConverterModelType_SIMPLE_CONSTANT_EFF:
            pass
        elif self.model_type_ == Self.ConverterModelType_CURVE_FUNC_OF_POWER:
            let normalized_power = self.ac_power_in_ / self.max_power_
            # Placeholder for curve evaluation
            pass


struct ElectricStorage:
    alias StorageModelType_INVALID = -1
    alias StorageModelType_SIMPLE_BUCKET_STORAGE = 0
    alias StorageModelType_KIBAM_BATTERY = 1
    alias StorageModelType_LIION_NMC_BATTERY = 2
    alias StorageModelType_NUM = 3

    var name_: String
    var stored_power_: Float64
    var stored_energy_: Float64
    var drawn_power_: Float64
    var drawn_energy_: Float64
    var decremented_energy_stored_: Float64
    var max_rainflow_array_bounds_: Int32
    var my_warm_up_flag_: Bool
    var storage_model_mode_: Int32
    var heat_losses_destination_: Int32
    var zone_num_: Int32
    var zone_rad_fract_: Float64
    var avail_sched_: UnsafePointer[UInt8]

    fn __init__(inout self, object_name: String) -> None:
        self.name_ = object_name
        self.stored_power_ = 0.0
        self.stored_energy_ = 0.0
        self.drawn_power_ = 0.0
        self.drawn_energy_ = 0.0
        self.decremented_energy_stored_ = 0.0
        self.max_rainflow_array_bounds_ = 100
        self.my_warm_up_flag_ = False
        self.storage_model_mode_ = Self.StorageModelType_INVALID
        self.heat_losses_destination_ = ThermalLossDestination.INVALID
        self.zone_num_ = 0
        self.zone_rad_fract_ = 0.0
        self.avail_sched_ = UnsafePointer[UInt8]()

    fn drawn_power(self) -> Float64:
        return self.drawn_power_

    fn stored_power(self) -> Float64:
        return self.stored_power_

    fn drawn_energy(self) -> Float64:
        return self.drawn_energy_

    fn stored_energy(self) -> Float64:
        return self.stored_energy_

    fn state_of_charge_fraction(self) -> Float64:
        return 0.0

    fn battery_temperature(self) -> Float64:
        return 0.0

    fn name(self) -> String:
        return self.name_

    fn time_check_and_update(inout self, state: UnsafePointer[UInt8]) -> None:
        pass

    fn simulate(inout self, state: UnsafePointer[UInt8], power_charge: Float64,
               power_discharge: Float64, charging: Bool, discharging: Bool,
               control_soc_max_frac_limit: Float64, control_soc_min_frac_limit: Float64) -> None:
        pass

    fn reinit_at_begin_environment(inout self) -> None:
        self.stored_power_ = 0.0
        self.stored_energy_ = 0.0
        self.drawn_power_ = 0.0
        self.drawn_energy_ = 0.0
        self.decremented_energy_stored_ = 0.0
        self.my_warm_up_flag_ = True

    fn reinit_zone_gains_at_begin_environment(inout self) -> None:
        pass

    fn reinit_at_end_warmup(inout self) -> None:
        self.my_warm_up_flag_ = False


struct ElectricTransformer:
    alias TransformerUse_INVALID = -1
    alias TransformerUse_POWER_IN_FROM_GRID = 0
    alias TransformerUse_POWER_OUT_FROM_BLDG_TO_GRID = 1
    alias TransformerUse_POWER_BETWEEN_LOAD_CENTER_AND_BLDG = 2
    alias TransformerUse_NUM = 3

    alias TransformerPerformanceInput_INVALID = -1
    alias TransformerPerformanceInput_LOSSES_METHOD = 0
    alias TransformerPerformanceInput_EFFICIENCY_METHOD = 1
    alias TransformerPerformanceInput_NUM = 2

    var name_: String
    var my_one_time_flag_: Bool
    var usage_mode_: Int32
    var heat_losses_destination_: Int32
    var zone_num_: Int32
    var zone_rad_frac_: Float64
    var rated_capacity_: Float64
    var factor_temp_coeff_: Float64
    var temp_rise_: Float64
    var eddy_frac_: Float64
    var performance_input_mode_: Int32
    var rated_efficiency_: Float64
    var rated_pul_: Float64
    var rated_temp_: Float64
    var max_pul_: Float64
    var consider_losses_: Bool
    var rated_nl_: Float64
    var rated_ll_: Float64
    var overload_error_index_: Int32
    var efficiency_: Float64
    var power_in_: Float64
    var energy_in_: Float64
    var power_out_: Float64
    var energy_out_: Float64
    var no_load_loss_rate_: Float64
    var no_load_loss_energy_: Float64
    var load_loss_rate_: Float64
    var load_loss_energy_: Float64
    var total_loss_rate_: Float64
    var thermal_loss_rate_: Float64
    var thermal_loss_energy_: Float64
    var elec_use_metered_utility_losses_: Float64
    var power_conversion_metered_losses_: Float64
    var qdot_conv_zone_: Float64
    var qdot_rad_zone_: Float64
    var avail_sched_: UnsafePointer[UInt8]

    fn __init__(inout self, object_name: String) -> None:
        self.name_ = object_name
        self.my_one_time_flag_ = True
        self.usage_mode_ = Self.TransformerUse_INVALID
        self.heat_losses_destination_ = ThermalLossDestination.INVALID
        self.zone_num_ = 0
        self.zone_rad_frac_ = 0.0
        self.rated_capacity_ = 0.0
        self.factor_temp_coeff_ = 0.0
        self.temp_rise_ = 0.0
        self.eddy_frac_ = 0.0
        self.performance_input_mode_ = Self.TransformerPerformanceInput_INVALID
        self.rated_efficiency_ = 0.0
        self.rated_pul_ = 0.0
        self.rated_temp_ = 0.0
        self.max_pul_ = 0.0
        self.consider_losses_ = True
        self.rated_nl_ = 0.0
        self.rated_ll_ = 0.0
        self.overload_error_index_ = 0
        self.efficiency_ = 0.0
        self.power_in_ = 0.0
        self.energy_in_ = 0.0
        self.power_out_ = 0.0
        self.energy_out_ = 0.0
        self.no_load_loss_rate_ = 0.0
        self.no_load_loss_energy_ = 0.0
        self.load_loss_rate_ = 0.0
        self.load_loss_energy_ = 0.0
        self.total_loss_rate_ = 0.0
        self.thermal_loss_rate_ = 0.0
        self.thermal_loss_energy_ = 0.0
        self.elec_use_metered_utility_losses_ = 0.0
        self.power_conversion_metered_losses_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0
        self.avail_sched_ = UnsafePointer[UInt8]()

    fn get_loss_rate_for_output_power(inout self, state: UnsafePointer[UInt8],
                                     power_out_of_transformer: Float64) -> Float64:
        self.manage_transformers(state, power_out_of_transformer)
        return self.total_loss_rate_

    fn get_loss_rate_for_input_power(inout self, state: UnsafePointer[UInt8],
                                    power_into_transformer: Float64) -> Float64:
        self.manage_transformers(state, power_into_transformer)
        return self.total_loss_rate_

    fn manage_transformers(inout self, state: UnsafePointer[UInt8],
                          surplus_power_out_from_load_centers: Float64) -> None:
        let amb_temp_ref = 20.0
        if self.my_one_time_flag_:
            if self.performance_input_mode_ == Self.TransformerPerformanceInput_EFFICIENCY_METHOD:
                let res_ref = self.factor_temp_coeff_ + self.temp_rise_ + amb_temp_ref
                let res_specified = self.factor_temp_coeff_ + self.rated_temp_
                let res_ratio = res_specified / res_ref
                let factor_temp_corr = ((1.0 - self.eddy_frac_) * res_ratio +
                                       self.eddy_frac_ * (1.0 / res_ratio))
                let numerator = self.rated_capacity_ * self.rated_pul_ * (1.0 - self.rated_efficiency_)
                let denominator = self.rated_efficiency_ * (1.0 + pow(self.rated_pul_ / self.max_pul_, 2))
                self.rated_nl_ = numerator / denominator
                self.rated_ll_ = self.rated_nl_ / (factor_temp_corr * pow(self.max_pul_, 2))
            self.my_one_time_flag_ = False

    fn setup_meter_indices(inout self, state: UnsafePointer[UInt8]) -> None:
        pass

    fn reinit_at_begin_environment(inout self) -> None:
        self.efficiency_ = 0.0
        self.power_in_ = 0.0
        self.energy_in_ = 0.0
        self.power_out_ = 0.0
        self.energy_out_ = 0.0
        self.no_load_loss_rate_ = 0.0
        self.no_load_loss_energy_ = 0.0
        self.load_loss_rate_ = 0.0
        self.load_loss_energy_ = 0.0
        self.thermal_loss_rate_ = 0.0
        self.thermal_loss_energy_ = 0.0
        self.elec_use_metered_utility_losses_ = 0.0
        self.power_conversion_metered_losses_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    fn reinit_zone_gains_at_begin_environment(inout self) -> None:
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    fn name(self) -> String:
        return self.name_


struct GeneratorController:
    var name: String
    var generator_type: Int32
    var comp_plant_type: Int32
    var comp_plant_name: String
    var generator_index: Int32
    var max_power_out: Float64
    var avail_sched: UnsafePointer[UInt8]
    var power_request_this_timestep: Float64
    var on_this_timestep: Bool
    var ems_power_request: Float64
    var ems_request_on: Bool
    var plant_info_found: Bool
    var cogen_location: UnsafePointer[UInt8]
    var nominal_therm_elect_ratio: Float64
    var dc_electricity_prod: Float64
    var dc_elect_prod_rate: Float64
    var electricity_prod: Float64
    var elect_prod_rate: Float64
    var thermal_prod: Float64
    var therm_prod_rate: Float64
    var pvwatts_generator: UnsafePointer[UInt8]
    var err_count_neg_elect_prod_: Int32

    fn __init__(inout self, object_name: String, object_type: String,
               rated_elec_power_output: Float64, avail_sched_name: String,
               thermal_to_elect_ratio: Float64) -> None:
        self.name = object_name
        self.generator_type = -1
        self.comp_plant_type = -1
        self.comp_plant_name = ""
        self.generator_index = 0
        self.max_power_out = rated_elec_power_output
        self.avail_sched = UnsafePointer[UInt8]()
        self.power_request_this_timestep = 0.0
        self.on_this_timestep = False
        self.ems_power_request = 0.0
        self.ems_request_on = False
        self.plant_info_found = False
        self.cogen_location = UnsafePointer[UInt8]()
        self.nominal_therm_elect_ratio = thermal_to_elect_ratio
        self.dc_electricity_prod = 0.0
        self.dc_elect_prod_rate = 0.0
        self.electricity_prod = 0.0
        self.elect_prod_rate = 0.0
        self.thermal_prod = 0.0
        self.therm_prod_rate = 0.0
        self.pvwatts_generator = UnsafePointer[UInt8]()
        self.err_count_neg_elect_prod_ = 0

    fn sim_generator_get_power_output(inout self, state: UnsafePointer[UInt8],
                                     run_flag: Bool, my_elec_load_request: Float64,
                                     first_hvac_iteration: Bool) -> Tuple[Float64, Float64]:
        return 0.0, 0.0

    fn reinit_at_begin_environment(inout self) -> None:
        self.on_this_timestep = False
        self.dc_electricity_prod = 0.0
        self.dc_elect_prod_rate = 0.0
        self.electricity_prod = 0.0
        self.elect_prod_rate = 0.0
        self.thermal_prod = 0.0
        self.therm_prod_rate = 0.0


struct ElectPowerLoadCenter:
    var name_: String
    var generator_list_name_: String
    var num_generators: Int32
    var buss_type: Int32
    var thermal_prod: Float64
    var thermal_prod_rate: Float64
    var inverter_present: Bool
    var inverter_name: String
    var inverter_obj: UnsafePointer[DCtoACInverter]
    var subpanel_feed_in_request: Float64
    var subpanel_feed_in_rate: Float64
    var subpanel_draw_rate: Float64
    var gen_elec_prod: Float64
    var gen_elec_prod_rate: Float64
    var storage_obj: UnsafePointer[ElectricStorage]
    var converter_obj: UnsafePointer[ACtoDCConverter]
    var transformer_obj: UnsafePointer[ElectricTransformer]

    fn __init__(inout self) -> None:
        self.name_ = ""
        self.generator_list_name_ = ""
        self.num_generators = 0
        self.buss_type = -1
        self.thermal_prod = 0.0
        self.thermal_prod_rate = 0.0
        self.inverter_present = False
        self.inverter_name = ""
        self.inverter_obj = UnsafePointer[DCtoACInverter]()
        self.subpanel_feed_in_request = 0.0
        self.subpanel_feed_in_rate = 0.0
        self.subpanel_draw_rate = 0.0
        self.gen_elec_prod = 0.0
        self.gen_elec_prod_rate = 0.0
        self.storage_obj = UnsafePointer[ElectricStorage]()
        self.converter_obj = UnsafePointer[ACtoDCConverter]()
        self.transformer_obj = UnsafePointer[ElectricTransformer]()

    fn manage_elec_load_center(inout self, state: UnsafePointer[UInt8],
                              first_hvac_iteration: Bool,
                              remaining_whole_power_demand: inout Float64) -> None:
        pass

    fn setup_load_center_meter_indices(inout self, state: UnsafePointer[UInt8]) -> None:
        pass

    fn reinit_at_begin_environment(inout self) -> None:
        self.gen_elec_prod = 0.0
        self.gen_elec_prod_rate = 0.0
        self.thermal_prod = 0.0
        self.thermal_prod_rate = 0.0

    fn reinit_zone_gains_at_begin_environment(inout self) -> None:
        pass

    fn generator_list_name(self) -> String:
        return self.generator_list_name_

    fn update_load_center_generator_records(inout self, state: UnsafePointer[UInt8]) -> None:
        pass

    fn dispatch_generators(inout self, state: UnsafePointer[UInt8],
                          first_hvac_iteration: Bool,
                          remaining_whole_power_demand: inout Float64) -> None:
        pass

    fn dispatch_storage(inout self, state: UnsafePointer[UInt8],
                       original_feed_in_request: Float64) -> None:
        pass

    fn calc_load_center_thermal_load(inout self, state: UnsafePointer[UInt8]) -> Float64:
        return 0.0


struct ElectricPowerServiceManager:
    var new_environment_internal_gains_flag: Bool
    var num_elec_storage_devices: Int32
    var get_input_flag_: Bool
    var new_environment_flag_: Bool
    var num_load_centers_: Int32
    var num_transformers_: Int32
    var setup_meter_index_flag_: Bool
    var elec_facility_meter_index_: Int32
    var elec_produced_cogen_meter_index_: Int32
    var elec_produced_pv_meter_index_: Int32
    var elec_produced_wt_meter_index_: Int32
    var elec_produced_storage_meter_index_: Int32
    var elec_produced_power_conversion_meter_index_: Int32
    var name_: String
    var facility_power_in_transformer_present_: Bool
    var num_power_out_transformers_: Int32
    var whole_bldg_remaining_load_: Float64
    var electricity_prod_: Float64
    var elec_prod_rate_: Float64
    var electricity_purch_: Float64
    var elec_purch_rate_: Float64
    var elec_surplus_rate_: Float64
    var electricity_surplus_: Float64
    var electricity_net_rate_: Float64
    var electricity_net_: Float64
    var total_bldg_elec_demand_: Float64
    var total_hvac_elec_demand_: Float64
    var total_electric_demand_: Float64
    var elec_produced_pv_rate_: Float64
    var elec_produced_wt_rate_: Float64
    var elec_produced_storage_rate_: Float64
    var elec_produced_power_conversion_rate_: Float64
    var elec_produced_cogen_rate_: Float64
    var pv_total_capacity_: Float64
    var wind_total_capacity_: Float64

    fn __init__(inout self) -> None:
        self.new_environment_internal_gains_flag = True
        self.num_elec_storage_devices = 0
        self.get_input_flag_ = True
        self.new_environment_flag_ = True
        self.num_load_centers_ = 0
        self.num_transformers_ = 0
        self.setup_meter_index_flag_ = True
        self.elec_facility_meter_index_ = -1
        self.elec_produced_cogen_meter_index_ = -1
        self.elec_produced_pv_meter_index_ = -1
        self.elec_produced_wt_meter_index_ = -1
        self.elec_produced_storage_meter_index_ = -1
        self.elec_produced_power_conversion_meter_index_ = -1
        self.name_ = "Whole Building"
        self.facility_power_in_transformer_present_ = False
        self.num_power_out_transformers_ = 0
        self.whole_bldg_remaining_load_ = 0.0
        self.electricity_prod_ = 0.0
        self.elec_prod_rate_ = 0.0
        self.electricity_purch_ = 0.0
        self.elec_purch_rate_ = 0.0
        self.elec_surplus_rate_ = 0.0
        self.electricity_surplus_ = 0.0
        self.electricity_net_rate_ = 0.0
        self.electricity_net_ = 0.0
        self.total_bldg_elec_demand_ = 0.0
        self.total_hvac_elec_demand_ = 0.0
        self.total_electric_demand_ = 0.0
        self.elec_produced_pv_rate_ = 0.0
        self.elec_produced_wt_rate_ = 0.0
        self.elec_produced_storage_rate_ = 0.0
        self.elec_produced_power_conversion_rate_ = 0.0
        self.elec_produced_cogen_rate_ = 0.0
        self.pv_total_capacity_ = 0.0
        self.wind_total_capacity_ = 0.0

    fn manage_electric_power_service(inout self, state: UnsafePointer[UInt8],
                                    first_hvac_iteration: Bool, update_meters_only: Bool) -> Bool:
        if self.get_input_flag_:
            self.get_power_manager_input(state)
            self.get_input_flag_ = False
        if self.setup_meter_index_flag_:
            self.setup_meter_indices(state)
            self.setup_meter_index_flag_ = False
        if self.new_environment_flag_:
            self.reinit_at_begin_environment()
            self.new_environment_flag_ = False
        self.update_whole_building_records(state)
        if update_meters_only:
            return False
        return False

    fn reinit_zone_gains_at_begin_environment(inout self) -> None:
        pass

    fn get_power_manager_input(inout self, state: UnsafePointer[UInt8]) -> None:
        pass

    fn setup_meter_indices(inout self, state: UnsafePointer[UInt8]) -> None:
        pass

    fn reinit_at_begin_environment(inout self) -> None:
        self.whole_bldg_remaining_load_ = 0.0
        self.electricity_prod_ = 0.0
        self.elec_prod_rate_ = 0.0
        self.electricity_purch_ = 0.0
        self.elec_purch_rate_ = 0.0
        self.elec_surplus_rate_ = 0.0
        self.electricity_surplus_ = 0.0
        self.electricity_net_rate_ = 0.0
        self.electricity_net_ = 0.0
        self.total_bldg_elec_demand_ = 0.0
        self.total_hvac_elec_demand_ = 0.0
        self.total_electric_demand_ = 0.0
        self.elec_produced_pv_rate_ = 0.0
        self.elec_produced_wt_rate_ = 0.0
        self.elec_produced_storage_rate_ = 0.0
        self.elec_produced_cogen_rate_ = 0.0

    fn verify_custom_meters_elec_power_mgr(inout self, state: UnsafePointer[UInt8]) -> None:
        pass

    fn update_whole_building_records(inout self, state: UnsafePointer[UInt8]) -> None:
        self.total_bldg_elec_demand_ = 0.0
        self.total_hvac_elec_demand_ = 0.0
        self.total_electric_demand_ = self.total_bldg_elec_demand_ + self.total_hvac_elec_demand_
        self.elec_prod_rate_ = (self.elec_produced_cogen_rate_ + self.elec_produced_pv_rate_ +
                               self.elec_produced_wt_rate_ + self.elec_produced_storage_rate_ +
                               self.elec_produced_power_conversion_rate_)
        self.electricity_prod_ = self.elec_prod_rate_ * 900.0
        self.elec_purch_rate_ = self.total_electric_demand_ - self.elec_prod_rate_
        if abs(self.elec_purch_rate_) < 0.0001:
            self.elec_purch_rate_ = 0.0
        if self.elec_purch_rate_ < 0.0:
            self.elec_purch_rate_ = 0.0
        self.electricity_purch_ = self.elec_purch_rate_ * 900.0
        self.elec_surplus_rate_ = self.elec_prod_rate_ - self.total_electric_demand_
        if abs(self.elec_surplus_rate_) < 0.0001:
            self.elec_surplus_rate_ = 0.0
        if self.elec_surplus_rate_ < 0.0:
            self.elec_surplus_rate_ = 0.0
        self.electricity_surplus_ = self.elec_surplus_rate_ * 900.0
        self.electricity_net_rate_ = self.total_electric_demand_ - self.elec_prod_rate_
        self.electricity_net_ = self.electricity_net_rate_ * 900.0

    fn report_pv_and_wind_capacity(inout self, state: UnsafePointer[UInt8]) -> None:
        self.pv_total_capacity_ = 0.0
        self.wind_total_capacity_ = 0.0

    fn sum_up_number_of_storage_devices(inout self) -> None:
        self.num_elec_storage_devices = 0

    fn check_load_centers(inout self, state: UnsafePointer[UInt8]) -> None:
        pass


fn create_facility_electric_power_service_object(state: UnsafePointer[UInt8]) -> ElectricPowerServiceManager:
    return ElectricPowerServiceManager()


fn initialize_electric_power_service_zone_gains(state: UnsafePointer[UInt8]) -> None:
    pass


fn check_user_efficiency_input(state: UnsafePointer[UInt8], user_input_value: Float64,
                              is_charging: Bool, device_name: StringRef) -> Tuple[Float64, Bool]:
    let min_charge_efficiency = 0.001
    let min_discharge_efficiency = 0.001
    var errors_found = False
    if is_charging:
        if user_input_value < min_charge_efficiency:
            errors_found = True
            return min_charge_efficiency, errors_found
        return user_input_value, errors_found
    if user_input_value < min_discharge_efficiency:
        errors_found = True
        return min_discharge_efficiency, errors_found
    return user_input_value, errors_found


fn check_charge_discharge_voltage_curves(state: UnsafePointer[UInt8], name_batt: StringRef,
                                        e0c: Float64, e0d: Float64, charge_curve: UnsafePointer[UInt8],
                                        discharge_curve: UnsafePointer[UInt8]) -> None:
    pass
