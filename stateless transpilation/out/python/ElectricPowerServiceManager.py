from dataclasses import dataclass, field
from typing import Optional, List, Protocol, Any
from enum import IntEnum
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container (wire from EnergyPlus core)
# - Schedule, Curve: managed references to schedule/curve objects in state
# - OutputProcessor: meter and output variable registration
# - EMSManager: EMS setup functions
# - PVWatts: PVWattsGenerator class
# - battery_t, battery_state, lifetime_t, etc.: SSC battery library types


class GeneratorType(IntEnum):
    INVALID = -1
    ICENGINE = 0
    COMBTURBINE = 1
    PV = 2
    FUELCELL = 3
    MICROCHP = 4
    MICROTURBINE = 5
    WINDTURBINE = 6
    PVWATTS = 7
    NUM = 8


GENERATOR_TYPE_NAMES = [
    "Generator:InternalCombustionEngine",
    "Generator:CombustionTurbine",
    "Generator:Photovoltaic",
    "Generator:FuelCell",
    "Generator:MicroCHP",
    "Generator:MicroTurbine",
    "Generator:WindTurbine",
    "Generator:PVWatts",
]

GENERATOR_TYPE_NAMES_UC = [
    "GENERATOR:INTERNALCOMBUSTIONENGINE",
    "GENERATOR:COMBUSTIONTURBINE",
    "GENERATOR:PHOTOVOLTAIC",
    "GENERATOR:FUELCELL",
    "GENERATOR:MICROCHP",
    "GENERATOR:MICROTURBINE",
    "GENERATOR:WINDTURBINE",
    "GENERATOR:PVWATTS",
]


class ThermalLossDestination(IntEnum):
    INVALID = -1
    ZONE_GAINS = 0
    LOST_TO_OUTSIDE = 1
    NUM = 2


class DCtoACInverter:
    class InverterModelType(IntEnum):
        INVALID = -1
        CEC_LOOKUP_TABLE_MODEL = 0
        CURVE_FUNC_OF_POWER = 1
        SIMPLE_CONSTANT_EFF = 2
        PVWATTS = 3
        NUM = 4

    def __init__(self, state: Any, object_name: str):
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
        self.model_type_ = self.InverterModelType.INVALID
        self.avail_sched_ = None
        self.heat_losses_destination_ = ThermalLossDestination.INVALID
        self.zone_num_ = 0
        self.zone_rad_fract_ = 0.0
        self.nominal_voltage_ = 0.0
        self.nom_volt_efficiency_arr_ = [0.0] * 6
        self.eff_curve_ = None
        self.rated_power_ = 0.0
        self.min_power_ = 0.0
        self.max_power_ = 0.0
        self.min_efficiency_ = 0.0
        self.max_efficiency_ = 0.0
        self.standby_power_ = 0.0
        self.pvwatts_dc_to_ac_size_ratio_ = 0.0
        self.pvwatts_inverter_efficiency_ = 0.0

    def simulate(self, state: Any, power_into_inverter: float):
        self.dc_power_in_ = power_into_inverter
        self.dc_energy_in_ = self.dc_power_in_ * state.dataHVACGlobal.TimeStepSysSec
        if self.avail_sched_ is not None and self.avail_sched_.getCurrentVal() > 0.0:
            self.calc_efficiency(state)
            self.ac_power_out_ = self.efficiency_ * self.dc_power_in_
            self.ac_energy_out_ = self.ac_power_out_ * state.dataHVACGlobal.TimeStepSysSec
            if self.ac_power_out_ == 0.0:
                self.ancill_ac_use_energy_ = self.standby_power_ * state.dataHVACGlobal.TimeStepSysSec
                self.ancill_ac_use_rate_ = self.standby_power_
            else:
                self.ancill_ac_use_rate_ = 0.0
                self.ancill_ac_use_energy_ = 0.0
        else:
            self.ac_power_out_ = 0.0
            self.ac_energy_out_ = 0.0
            self.ancill_ac_use_rate_ = 0.0
            self.ancill_ac_use_energy_ = 0.0
        self.conversion_loss_power_ = self.dc_power_in_ - self.ac_power_out_
        self.conversion_loss_energy_ = self.conversion_loss_power_ * state.dataHVACGlobal.TimeStepSysSec
        self.conversion_loss_energy_decrement_ = -1.0 * self.conversion_loss_energy_
        self.therm_loss_rate_ = self.dc_power_in_ - self.ac_power_out_ + self.ancill_ac_use_rate_
        self.therm_loss_energy_ = self.therm_loss_rate_ * state.dataHVACGlobal.TimeStepSysSec
        self.qdot_conv_zone_ = self.therm_loss_rate_ * (1.0 - self.zone_rad_fract_)
        self.qdot_rad_zone_ = self.therm_loss_rate_ * self.zone_rad_fract_

    def reinit_at_begin_environment(self):
        self.ancill_ac_use_rate_ = 0.0
        self.ancill_ac_use_energy_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    def reinit_zone_gains_at_begin_environment(self):
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    def set_pvwatts_dc_capacity(self, state: Any, dc_capacity: float):
        if self.model_type_ != self.InverterModelType.PVWATTS:
            raise ValueError("Setting DC capacity only works with PVWatts inverters")
        self.rated_power_ = dc_capacity / self.pvwatts_dc_to_ac_size_ratio_

    def pvwatts_dc_capacity(self) -> float:
        return self.rated_power_ * self.pvwatts_dc_to_ac_size_ratio_

    def pvwatts_inverter_efficiency(self) -> float:
        return self.pvwatts_inverter_efficiency_

    def pvwatts_dc_to_ac_size_ratio(self) -> float:
        return self.pvwatts_dc_to_ac_size_ratio_

    def ac_power_out(self) -> float:
        return self.ac_power_out_

    def model_type(self) -> "DCtoACInverter.InverterModelType":
        return self.model_type_

    def name(self) -> str:
        return self.name_

    def get_loss_rate_for_output_power(self, state: Any, power_out_of_inverter: float) -> float:
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

    def calc_efficiency(self, state: Any):
        if self.model_type_ == self.InverterModelType.CEC_LOOKUP_TABLE_MODEL:
            normalized_power = self.dc_power_in_ / self.rated_power_
            if normalized_power <= 0.1:
                self.efficiency_ = self.nom_volt_efficiency_arr_[0]
            elif 0.1 < normalized_power < 0.2:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[0] +
                                   ((normalized_power - 0.1) / 0.1) *
                                   (self.nom_volt_efficiency_arr_[1] - self.nom_volt_efficiency_arr_[0]))
            elif normalized_power == 0.2:
                self.efficiency_ = self.nom_volt_efficiency_arr_[1]
            elif 0.2 < normalized_power < 0.3:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[1] +
                                   ((normalized_power - 0.2) / 0.1) *
                                   (self.nom_volt_efficiency_arr_[2] - self.nom_volt_efficiency_arr_[1]))
            elif normalized_power == 0.3:
                self.efficiency_ = self.nom_volt_efficiency_arr_[2]
            elif 0.3 < normalized_power < 0.5:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[2] +
                                   ((normalized_power - 0.3) / 0.2) *
                                   (self.nom_volt_efficiency_arr_[3] - self.nom_volt_efficiency_arr_[2]))
            elif normalized_power == 0.5:
                self.efficiency_ = self.nom_volt_efficiency_arr_[3]
            elif 0.5 < normalized_power < 0.75:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[3] +
                                   ((normalized_power - 0.5) / 0.25) *
                                   (self.nom_volt_efficiency_arr_[4] - self.nom_volt_efficiency_arr_[3]))
            elif normalized_power == 0.75:
                self.efficiency_ = self.nom_volt_efficiency_arr_[4]
            elif 0.75 < normalized_power < 1.0:
                self.efficiency_ = (self.nom_volt_efficiency_arr_[4] +
                                   ((normalized_power - 0.75) / 0.25) *
                                   (self.nom_volt_efficiency_arr_[5] - self.nom_volt_efficiency_arr_[4]))
            elif normalized_power >= 1.0:
                self.efficiency_ = self.nom_volt_efficiency_arr_[5]
            self.efficiency_ = max(self.efficiency_, 0.0)
            self.efficiency_ = min(self.efficiency_, 1.0)
        elif self.model_type_ == self.InverterModelType.CURVE_FUNC_OF_POWER:
            normalized_power = self.dc_power_in_ / self.rated_power_
            if self.eff_curve_ is not None:
                self.efficiency_ = self.eff_curve_.value(state, normalized_power)
            self.efficiency_ = max(self.efficiency_, self.min_efficiency_)
            self.efficiency_ = min(self.efficiency_, self.max_efficiency_)
        elif self.model_type_ == self.InverterModelType.PVWATTS:
            etaref = 0.9637
            A = -0.0162
            B = -0.0059
            C = 0.9858
            pdc0 = self.rated_power_ / self.pvwatts_inverter_efficiency_
            plr = self.dc_power_in_ / pdc0
            ac = 0
            if plr > 0:
                eta = (A * plr + B / plr + C) * self.pvwatts_inverter_efficiency_ / etaref
                ac = self.dc_power_in_ * eta
                if ac > self.rated_power_:
                    ac = self.rated_power_
                if ac < 0:
                    ac = 0
                self.efficiency_ = ac / self.dc_power_in_
            else:
                self.efficiency_ = 1.0


class ACtoDCConverter:
    class ConverterModelType(IntEnum):
        INVALID = -1
        CURVE_FUNC_OF_POWER = 0
        SIMPLE_CONSTANT_EFF = 1
        NUM = 2

    CONVERTER_MODEL_TYPE_NAMES = ["FunctionOfPower", "SimpleFixed"]
    CONVERTER_MODEL_TYPE_NAMES_UC = ["FUNCTIONOFPOWER", "SIMPLEFIXED"]

    def __init__(self, state: Any, object_name: str):
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
        self.avail_sched_ = None
        self.model_type_ = self.ConverterModelType.INVALID
        self.eff_curve_ = None
        self.heat_losses_destination_ = ThermalLossDestination.INVALID
        self.zone_num_ = 0
        self.zone_rad_fract_ = 0.0
        self.standby_power_ = 0.0
        self.max_power_ = 0.0

    def simulate(self, state: Any, power_out_from_converter: float):
        if self.avail_sched_ is not None and self.avail_sched_.getCurrentVal() > 0.0:
            self.ac_power_in_ = power_out_from_converter / self.efficiency_
            self.calc_efficiency(state)
            self.ac_power_in_ = power_out_from_converter / self.efficiency_
            self.calc_efficiency(state)
            self.dc_power_out_ = self.ac_power_in_ * self.efficiency_
            if self.dc_power_out_ == 0.0:
                self.ancill_ac_use_energy_ = self.standby_power_ * state.dataHVACGlobal.TimeStepSysSec
                self.ancill_ac_use_rate_ = self.standby_power_
            else:
                self.ancill_ac_use_rate_ = 0.0
                self.ancill_ac_use_energy_ = 0.0
        else:
            self.ac_power_in_ = 0.0
            self.dc_power_out_ = 0.0
            self.ancill_ac_use_rate_ = 0.0
            self.ancill_ac_use_energy_ = 0.0
        self.ac_energy_in_ = self.ac_power_in_ * state.dataHVACGlobal.TimeStepSysSec
        self.dc_energy_out_ = self.dc_power_out_ * state.dataHVACGlobal.TimeStepSysSec
        self.conversion_loss_power_ = self.ac_power_in_ - self.dc_power_out_
        self.conversion_loss_energy_ = self.conversion_loss_power_ * state.dataHVACGlobal.TimeStepSysSec
        self.conversion_loss_energy_decrement_ = -1.0 * self.conversion_loss_energy_
        self.therm_loss_rate_ = self.ac_power_in_ - self.dc_power_out_ + self.ancill_ac_use_rate_
        self.therm_loss_energy_ = self.therm_loss_rate_ * state.dataHVACGlobal.TimeStepSysSec
        self.qdot_conv_zone_ = self.therm_loss_rate_ * (1.0 - self.zone_rad_fract_)
        self.qdot_rad_zone_ = self.therm_loss_rate_ * self.zone_rad_fract_

    def reinit_at_begin_environment(self):
        self.ancill_ac_use_rate_ = 0.0
        self.ancill_ac_use_energy_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    def reinit_zone_gains_at_begin_environment(self):
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    def ac_power_in(self) -> float:
        return self.ac_power_in_

    def get_loss_rate_for_input_power(self, state: Any, power_into_converter: float) -> float:
        self.ac_power_in_ = power_into_converter
        self.calc_efficiency(state)
        return (1.0 - self.efficiency_) * self.ac_power_in_

    def name(self) -> str:
        return self.name_

    def calc_efficiency(self, state: Any):
        if self.model_type_ == self.ConverterModelType.SIMPLE_CONSTANT_EFF:
            pass
        elif self.model_type_ == self.ConverterModelType.CURVE_FUNC_OF_POWER:
            normalized_power = self.ac_power_in_ / self.max_power_
            if self.eff_curve_ is not None:
                self.efficiency_ = self.eff_curve_.value(state, normalized_power)


class ElectricStorage:
    class StorageModelType(IntEnum):
        INVALID = -1
        SIMPLE_BUCKET_STORAGE = 0
        KIBAM_BATTERY = 1
        LIION_NMC_BATTERY = 2
        NUM = 3

    def __init__(self, state: Any, object_name: str):
        self.name_ = object_name
        self.stored_power_ = 0.0
        self.stored_energy_ = 0.0
        self.drawn_power_ = 0.0
        self.drawn_energy_ = 0.0
        self.decremented_energy_stored_ = 0.0
        self.max_rainflow_array_bounds_ = 100
        self.my_warm_up_flag_ = False
        self.storage_model_mode_ = self.StorageModelType.INVALID
        self.heat_losses_destination_ = ThermalLossDestination.INVALID
        self.zone_num_ = 0
        self.zone_rad_fract_ = 0.0
        self.avail_sched_ = None
        # SimpleBucketStorage params
        self.energetic_effic_charge_ = 0.0
        self.energetic_effic_discharge_ = 0.0
        self.max_power_draw_ = 0.0
        self.max_power_store_ = 0.0
        self.max_energy_capacity_ = 0.0
        self.starting_energy_stored_ = 0.0
        # KIBaMBattery params
        self.parallel_num_ = 0
        self.series_num_ = 0
        self.num_battery_ = 0
        self.charge_curve_ = None
        self.discharge_curve_ = None
        self.cycle_bin_num_ = 0
        self.starting_soc_ = 0.0
        self.max_ah_capacity_ = 0.0
        self.available_frac_ = 0.0
        self.charge_conversion_rate_ = 0.0
        self.charged_ocv_ = 0.0
        self.discharged_ocv_ = 0.0
        self.internal_r_ = 0.0
        self.max_discharge_i_ = 0.0
        self.cutoff_v_ = 0.0
        self.max_charge_rate_ = 0.0
        self.life_calculation_ = False
        self.life_curve_ = None
        # Li-ion NMC params
        self.liion_dc_to_dc_charging_eff_ = 0.0
        self.liion_mass_ = 0.0
        self.liion_surface_area_ = 0.0
        self.liion_cp_ = 0.0
        self.liion_heat_transfer_coef_ = 0.0
        self.liion_vfull_ = 0.0
        self.liion_vexp_ = 0.0
        self.liion_vnom_ = 0.0
        self.liion_vnom_default_ = 0.0
        self.liion_qfull_ = 0.0
        self.liion_qexp_ = 0.0
        self.liion_qnom_ = 0.0
        self.liion_c_rate_ = 0.0
        # State vars
        self.this_time_step_state_of_charge_ = 0.0
        self.last_time_step_state_of_charge_ = 0.0
        self.pel_need_from_storage_ = 0.0
        self.pel_from_storage_ = 0.0
        self.pel_into_storage_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0
        self.time_elapsed_ = 0.0
        self.this_time_step_available_ = 0.0
        self.this_time_step_bound_ = 0.0
        self.last_time_step_available_ = 0.0
        self.last_time_step_bound_ = 0.0
        self.last_two_time_step_available_ = 0.0
        self.last_two_time_step_bound_ = 0.0
        self.count0_ = 0
        self.b10_: List[float] = []
        self.x0_: List[float] = []
        self.nmb0_: List[float] = []
        self.one_nmb0_: List[float] = []
        # Report vars
        self.elect_energy_in_storage_ = 0.0
        self.therm_loss_rate_ = 0.0
        self.therm_loss_energy_ = 0.0
        self.storage_mode_ = 0
        self.absolute_soc_ = 0.0
        self.fraction_soc_ = 0.0
        self.battery_current_ = 0.0
        self.battery_voltage_ = 0.0
        self.battery_damage_ = 0.0
        self.battery_temperature_ = 0.0
        self.ssc_battery_ = None
        self.ssc_last_battery_state_ = None
        self.ssc_last_battery_time_step_ = 0.0
        self.ssc_init_battery_state_ = None
        self.ssc_init_battery_time_step_ = 0.0

    def time_check_and_update(self, state: Any):
        if self.my_warm_up_flag_ and not state.dataGlobal.WarmupFlag:
            self.reinit_at_end_warmup()
        time_elapsed_loc = (state.dataGlobal.HourOfDay +
                           state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone +
                           state.dataHVACGlobal.SysTimeElapsed)
        if self.time_elapsed_ != time_elapsed_loc:
            if (self.storage_model_mode_ == self.StorageModelType.KIBAM_BATTERY and
                self.life_calculation_):
                delta_soc1 = (self.this_time_step_available_ + self.this_time_step_bound_ -
                             self.last_time_step_available_ - self.last_time_step_bound_)
                delta_soc1 /= self.max_ah_capacity_
                delta_soc2 = (self.last_time_step_available_ + self.last_time_step_bound_ -
                             self.last_two_time_step_available_ - self.last_two_time_step_bound_)
                delta_soc2 /= self.max_ah_capacity_
                if (delta_soc2 == 0) or ((delta_soc1 * delta_soc2) < 0):
                    input0 = (self.last_time_step_available_ + self.last_time_step_bound_) / self.max_ah_capacity_
                    self.b10_[self.count0_] = input0
                    max_rainflow_array_inc = 100
                    if self.count0_ == self.max_rainflow_array_bounds_:
                        self.b10_.extend([0.0] * max_rainflow_array_inc)
                        self.x0_.extend([0.0] * max_rainflow_array_inc)
                        self.max_rainflow_array_bounds_ += max_rainflow_array_inc
                    self.rainflow(self.cycle_bin_num_, input0, self.b10_, self.x0_,
                                self.count0_, self.nmb0_, self.one_nmb0_)
                    self.battery_damage_ = 0.0
                    for bin_num in range(self.cycle_bin_num_):
                        if self.life_curve_ is not None:
                            damage_factor = float(bin_num) / float(self.cycle_bin_num_)
                            self.battery_damage_ += self.one_nmb0_[bin_num] / self.life_curve_.value(state, damage_factor)
            elif self.storage_model_mode_ == self.StorageModelType.LIION_NMC_BATTERY:
                if self.ssc_battery_ is not None and self.ssc_last_battery_state_ is not None:
                    self.ssc_last_battery_state_ = self.ssc_battery_.get_state()
                    self.ssc_last_battery_time_step_ = self.ssc_battery_.get_params().dt_hr
            self.last_time_step_state_of_charge_ = self.this_time_step_state_of_charge_
            self.last_two_time_step_available_ = self.last_time_step_available_
            self.last_two_time_step_bound_ = self.last_time_step_bound_
            self.last_time_step_available_ = self.this_time_step_available_
            self.last_time_step_bound_ = self.this_time_step_bound_
            self.time_elapsed_ = time_elapsed_loc

    def simulate(self, state: Any, power_charge: float, power_discharge: float,
                 charging: bool, discharging: bool, control_soc_max_frac_limit: float,
                 control_soc_min_frac_limit: float) -> tuple:
        if self.avail_sched_ is not None and self.avail_sched_.getCurrentVal() == 0.0:
            discharging = False
            power_discharge = 0.0
            charging = False
            power_charge = 0.0
        if self.storage_model_mode_ == self.StorageModelType.SIMPLE_BUCKET_STORAGE:
            self.simulate_simple_bucket_model(state, power_charge, power_discharge, charging,
                                            discharging, control_soc_max_frac_limit,
                                            control_soc_min_frac_limit)
        elif self.storage_model_mode_ == self.StorageModelType.KIBAM_BATTERY:
            self.simulate_kinetic_battery_model(state, power_charge, power_discharge, charging,
                                              discharging, control_soc_max_frac_limit,
                                              control_soc_min_frac_limit)
        elif self.storage_model_mode_ == self.StorageModelType.LIION_NMC_BATTERY:
            self.simulate_liion_nmc_battery_model(state, power_charge, power_discharge, charging,
                                                discharging, control_soc_max_frac_limit,
                                                control_soc_min_frac_limit)
        return power_charge, power_discharge, charging, discharging

    def reinit_at_begin_environment(self):
        self.pel_need_from_storage_ = 0.0
        self.pel_from_storage_ = 0.0
        self.pel_into_storage_ = 0.0
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0
        self.time_elapsed_ = 0.0
        self.elect_energy_in_storage_ = 0.0
        self.stored_power_ = 0.0
        self.stored_energy_ = 0.0
        self.decremented_energy_stored_ = 0.0
        self.drawn_power_ = 0.0
        self.drawn_energy_ = 0.0
        self.therm_loss_rate_ = 0.0
        self.therm_loss_energy_ = 0.0
        self.last_time_step_state_of_charge_ = self.starting_energy_stored_
        self.this_time_step_state_of_charge_ = self.starting_energy_stored_
        if self.storage_model_mode_ == self.StorageModelType.KIBAM_BATTERY:
            initial_charge = self.max_ah_capacity_ * self.starting_soc_
            self.last_two_time_step_available_ = initial_charge * self.available_frac_
            self.last_two_time_step_bound_ = initial_charge * (1.0 - self.available_frac_)
            self.last_time_step_available_ = initial_charge * self.available_frac_
            self.last_time_step_bound_ = initial_charge * (1.0 - self.available_frac_)
            self.this_time_step_available_ = initial_charge * self.available_frac_
            self.this_time_step_bound_ = initial_charge * (1.0 - self.available_frac_)
            if self.life_calculation_:
                self.count0_ = 1
                self.b10_ = [0.0] * (self.max_rainflow_array_bounds_ + 1)
                self.x0_ = [0.0] * (self.max_rainflow_array_bounds_ + 1)
                self.nmb0_ = [0.0] * self.cycle_bin_num_
                self.one_nmb0_ = [0.0] * self.cycle_bin_num_
                self.b10_[0] = self.starting_soc_
                self.x0_[0] = 0.0
                self.battery_damage_ = 0.0
        elif self.storage_model_mode_ == self.StorageModelType.LIION_NMC_BATTERY:
            pass
        self.my_warm_up_flag_ = True

    def reinit_zone_gains_at_begin_environment(self):
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    def reinit_at_end_warmup(self):
        self.last_time_step_state_of_charge_ = self.starting_energy_stored_
        self.this_time_step_state_of_charge_ = self.starting_energy_stored_
        if self.storage_model_mode_ == self.StorageModelType.KIBAM_BATTERY:
            initial_charge = self.max_ah_capacity_ * self.starting_soc_
            self.last_two_time_step_available_ = initial_charge * self.available_frac_
            self.last_two_time_step_bound_ = initial_charge * (1.0 - self.available_frac_)
            self.last_time_step_available_ = initial_charge * self.available_frac_
            self.last_time_step_bound_ = initial_charge * (1.0 - self.available_frac_)
            self.this_time_step_available_ = initial_charge * self.available_frac_
            self.this_time_step_bound_ = initial_charge * (1.0 - self.available_frac_)
            if self.life_calculation_:
                self.count0_ = 1
                self.b10_[0] = self.starting_soc_
                self.x0_[0] = 0.0
                for i in range(1, self.max_rainflow_array_bounds_ + 1):
                    self.b10_[i] = 0.0
                    self.x0_[i] = 0.0
                for i in range(self.cycle_bin_num_):
                    self.one_nmb0_[i] = 0.0
                    self.nmb0_[i] = 0.0
                self.battery_damage_ = 0.0
        self.my_warm_up_flag_ = False

    def drawn_power(self) -> float:
        return self.drawn_power_

    def stored_power(self) -> float:
        return self.stored_power_

    def drawn_energy(self) -> float:
        return self.drawn_energy_

    def stored_energy(self) -> float:
        return self.stored_energy_

    def state_of_charge_fraction(self) -> float:
        return self.fraction_soc_

    def battery_temperature(self) -> float:
        assert self.storage_model_mode_ == self.StorageModelType.LIION_NMC_BATTERY
        return self.battery_temperature_

    def name(self) -> str:
        return self.name_

    def simulate_simple_bucket_model(self, state: Any, power_charge: float, power_discharge: float,
                                    charging: bool, discharging: bool,
                                    control_soc_max_frac_limit: float,
                                    control_soc_min_frac_limit: float):
        if charging:
            if self.last_time_step_state_of_charge_ >= (self.max_energy_capacity_ * control_soc_max_frac_limit):
                power_charge = 0.0
                charging = False
            if power_charge > self.max_power_store_:
                power_charge = self.max_power_store_
            if ((self.last_time_step_state_of_charge_ +
                power_charge * state.dataHVACGlobal.TimeStepSysSec * self.energetic_effic_charge_) >=
                (self.max_energy_capacity_ * control_soc_max_frac_limit)):
                power_charge = (((self.max_energy_capacity_ * control_soc_max_frac_limit) -
                               self.last_time_step_state_of_charge_) /
                              (state.dataHVACGlobal.TimeStepSysSec * self.energetic_effic_charge_))
        if discharging:
            if self.last_time_step_state_of_charge_ <= (self.max_energy_capacity_ * control_soc_min_frac_limit):
                power_discharge = 0.0
                discharging = False
            if power_discharge > self.max_power_draw_:
                power_discharge = self.max_power_draw_
            if ((self.last_time_step_state_of_charge_ -
                power_discharge * state.dataHVACGlobal.TimeStepSysSec / self.energetic_effic_discharge_) <=
                (self.max_energy_capacity_ * control_soc_min_frac_limit)):
                power_discharge = (((self.last_time_step_state_of_charge_ -
                                   (self.max_energy_capacity_ * control_soc_min_frac_limit)) *
                                  self.energetic_effic_discharge_) /
                                 state.dataHVACGlobal.TimeStepSysSec)
        if not charging and not discharging:
            self.this_time_step_state_of_charge_ = self.last_time_step_state_of_charge_
            self.pel_into_storage_ = 0.0
            self.pel_from_storage_ = 0.0
        if charging:
            self.pel_into_storage_ = power_charge
            self.pel_from_storage_ = 0.0
            self.this_time_step_state_of_charge_ = (self.last_time_step_state_of_charge_ +
                                                   power_charge * state.dataHVACGlobal.TimeStepSysSec *
                                                   self.energetic_effic_charge_)
        if discharging:
            self.pel_into_storage_ = 0.0
            self.pel_from_storage_ = power_discharge
            self.this_time_step_state_of_charge_ = (self.last_time_step_state_of_charge_ -
                                                   power_discharge * state.dataHVACGlobal.TimeStepSysSec /
                                                   self.energetic_effic_discharge_)
            self.this_time_step_state_of_charge_ = max(self.this_time_step_state_of_charge_, 0.0)
        self.elect_energy_in_storage_ = self.this_time_step_state_of_charge_
        self.stored_power_ = self.pel_into_storage_
        self.stored_energy_ = self.pel_into_storage_ * state.dataHVACGlobal.TimeStepSysSec
        self.decremented_energy_stored_ = -1.0 * self.stored_energy_
        self.drawn_power_ = self.pel_from_storage_
        self.drawn_energy_ = self.pel_from_storage_ * state.dataHVACGlobal.TimeStepSysSec
        charge_loss = self.stored_power_ * (1.0 - self.energetic_effic_charge_)
        discharge_loss = self.drawn_power_ * (1.0 - self.energetic_effic_discharge_)
        self.therm_loss_rate_ = max(charge_loss, discharge_loss)
        self.therm_loss_energy_ = self.therm_loss_rate_ * state.dataHVACGlobal.TimeStepSysSec
        if self.zone_num_ > 0:
            self.qdot_conv_zone_ = (1.0 - self.zone_rad_fract_) * self.therm_loss_rate_
            self.qdot_rad_zone_ = self.zone_rad_fract_ * self.therm_loss_rate_

    def simulate_kinetic_battery_model(self, state: Any, power_charge: float, power_discharge: float,
                                      charging: bool, discharging: bool,
                                      control_soc_max_frac_limit: float,
                                      control_soc_min_frac_limit: float):
        # Placeholder implementation
        pass

    def simulate_liion_nmc_battery_model(self, state: Any, power_charge: float, power_discharge: float,
                                        charging: bool, discharging: bool,
                                        control_soc_max_frac_limit: float,
                                        control_soc_min_frac_limit: float):
        # Placeholder implementation
        pass

    def determine_current_for_battery_discharge(self, state: Any, cur_i0: float, cur_t0: float,
                                              cur_volt: float, pw: float, q0: float, curve: Any,
                                              k: float, c: float, qmax: float, e0c: float,
                                              internal_r: float) -> bool:
        # Placeholder implementation
        return True

    def rainflow(self, numbin: int, input_val: float, b1: List[float], x: List[float],
                count: int, nmb: List[float], one_nmb: List[float]):
        # Placeholder implementation
        pass

    def shift(self, a: List[float], m: int, n: int, b: List[float]):
        for shift_num in range(1, m):
            b[shift_num] = a[shift_num]
        for shift_num in range(m, n + 1):
            b[shift_num] = a[shift_num + 1]


class ElectricTransformer:
    class TransformerUse(IntEnum):
        INVALID = -1
        POWER_IN_FROM_GRID = 0
        POWER_OUT_FROM_BLDG_TO_GRID = 1
        POWER_BETWEEN_LOAD_CENTER_AND_BLDG = 2
        NUM = 3

    class TransformerPerformanceInput(IntEnum):
        INVALID = -1
        LOSSES_METHOD = 0
        EFFICIENCY_METHOD = 1
        NUM = 2

    def __init__(self, state: Any, object_name: str):
        self.name_ = object_name
        self.my_one_time_flag_ = True
        self.usage_mode_ = self.TransformerUse.INVALID
        self.heat_losses_destination_ = ThermalLossDestination.INVALID
        self.zone_num_ = 0
        self.zone_rad_frac_ = 0.0
        self.rated_capacity_ = 0.0
        self.factor_temp_coeff_ = 0.0
        self.temp_rise_ = 0.0
        self.eddy_frac_ = 0.0
        self.performance_input_mode_ = self.TransformerPerformanceInput.INVALID
        self.rated_efficiency_ = 0.0
        self.rated_pul_ = 0.0
        self.rated_temp_ = 0.0
        self.max_pul_ = 0.0
        self.consider_losses_ = True
        self.wired_meter_names_: List[str] = []
        self.wired_meter_ptrs_: List[int] = []
        self.special_meter_: List[bool] = []
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
        self.avail_sched_ = None

    def get_loss_rate_for_output_power(self, state: Any, power_out_of_transformer: float) -> float:
        self.manage_transformers(state, power_out_of_transformer)
        return self.total_loss_rate_

    def get_loss_rate_for_input_power(self, state: Any, power_into_transformer: float) -> float:
        self.manage_transformers(state, power_into_transformer)
        return self.total_loss_rate_

    def manage_transformers(self, state: Any, surplus_power_out_from_load_centers: float):
        amb_temp_ref = 20.0
        if self.my_one_time_flag_:
            if self.performance_input_mode_ == self.TransformerPerformanceInput.EFFICIENCY_METHOD:
                res_ref = self.factor_temp_coeff_ + self.temp_rise_ + amb_temp_ref
                res_specified = self.factor_temp_coeff_ + self.rated_temp_
                res_ratio = res_specified / res_ref
                factor_temp_corr = ((1.0 - self.eddy_frac_) * res_ratio +
                                   self.eddy_frac_ * (1.0 / res_ratio))
                numerator = self.rated_capacity_ * self.rated_pul_ * (1.0 - self.rated_efficiency_)
                denominator = self.rated_efficiency_ * (1.0 + pow(self.rated_pul_ / self.max_pul_, 2))
                self.rated_nl_ = numerator / denominator
                self.rated_ll_ = self.rated_nl_ / (factor_temp_corr * pow(self.max_pul_, 2))
            self.my_one_time_flag_ = False

        elec_load = 0.0
        past_elec_load = 0.0

        if self.usage_mode_ == self.TransformerUse.POWER_IN_FROM_GRID:
            self.power_out_ = elec_load
        elif self.usage_mode_ == self.TransformerUse.POWER_OUT_FROM_BLDG_TO_GRID:
            self.power_in_ = surplus_power_out_from_load_centers
            elec_load = surplus_power_out_from_load_centers
        elif self.usage_mode_ == self.TransformerUse.POWER_BETWEEN_LOAD_CENTER_AND_BLDG:
            self.power_in_ = surplus_power_out_from_load_centers
            elec_load = surplus_power_out_from_load_centers

        if self.rated_capacity_ > 0.0 and self.avail_sched_ is not None and self.avail_sched_.getCurrentVal() > 0.0:
            pul = elec_load / self.rated_capacity_
            if pul > 1.0:
                pul = 1.0
            if past_elec_load / self.rated_capacity_ > 1.0:
                if self.overload_error_index_ == 0:
                    pass
            temp_change = pow(pul, 1.6) * self.temp_rise_
            amb_temp = 20.0
            if self.heat_losses_destination_ == ThermalLossDestination.ZONE_GAINS:
                amb_temp = 20.0
            res_ref = self.factor_temp_coeff_ + self.temp_rise_ + amb_temp_ref
            res_specified = self.factor_temp_coeff_ + temp_change + amb_temp
            res_ratio = res_specified / res_ref
            factor_temp_corr = ((1.0 - self.eddy_frac_) * res_ratio +
                               self.eddy_frac_ * (1.0 / res_ratio))
            self.load_loss_rate_ = self.rated_ll_ * pow(pul, 2) * factor_temp_corr
            self.no_load_loss_rate_ = self.rated_nl_
        else:
            self.load_loss_rate_ = 0.0
            self.no_load_loss_rate_ = 0.0

        self.total_loss_rate_ = self.load_loss_rate_ + self.no_load_loss_rate_

        if self.usage_mode_ == self.TransformerUse.POWER_IN_FROM_GRID:
            self.power_in_ = elec_load + self.total_loss_rate_
            if self.consider_losses_:
                self.elec_use_metered_utility_losses_ = self.total_loss_rate_ * state.dataHVACGlobal.TimeStepSysSec
            else:
                self.elec_use_metered_utility_losses_ = 0.0
        elif (self.usage_mode_ == self.TransformerUse.POWER_OUT_FROM_BLDG_TO_GRID or
              self.usage_mode_ == self.TransformerUse.POWER_BETWEEN_LOAD_CENTER_AND_BLDG):
            self.power_out_ = elec_load - self.total_loss_rate_
            if self.power_out_ < 0:
                self.power_out_ = 0.0
            self.power_conversion_metered_losses_ = -1.0 * self.total_loss_rate_ * state.dataHVACGlobal.TimeStepSysSec
            self.elec_use_metered_utility_losses_ = 0.0

        if self.power_in_ <= 0:
            self.efficiency_ = 1.0
        else:
            self.efficiency_ = self.power_out_ / self.power_in_

        self.no_load_loss_energy_ = self.no_load_loss_rate_ * state.dataHVACGlobal.TimeStepSysSec
        self.load_loss_energy_ = self.load_loss_rate_ * state.dataHVACGlobal.TimeStepSysSec
        self.energy_in_ = self.power_in_ * state.dataHVACGlobal.TimeStepSysSec
        self.energy_out_ = self.power_out_ * state.dataHVACGlobal.TimeStepSysSec
        self.thermal_loss_rate_ = self.power_in_ - self.power_out_
        self.thermal_loss_energy_ = self.thermal_loss_rate_ * state.dataHVACGlobal.TimeStepSysSec

        if self.zone_num_ > 0:
            self.qdot_conv_zone_ = (1.0 - self.zone_rad_frac_) * self.thermal_loss_rate_
            self.qdot_rad_zone_ = self.zone_rad_frac_ * self.thermal_loss_rate_

    def setup_meter_indices(self, state: Any):
        pass

    def reinit_at_begin_environment(self):
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

    def reinit_zone_gains_at_begin_environment(self):
        self.qdot_conv_zone_ = 0.0
        self.qdot_rad_zone_ = 0.0

    def name(self) -> str:
        return self.name_


class GeneratorController:
    def __init__(self, state: Any, object_name: str, object_type: str,
                 rated_elec_power_output: float, avail_sched_name: str,
                 thermal_to_elect_ratio: float):
        self.name = object_name
        self.generator_type = GeneratorType.INVALID
        self.comp_plant_type = None
        self.comp_plant_name = ""
        self.generator_index = 0
        self.max_power_out = rated_elec_power_output
        self.avail_sched = None
        self.power_request_this_timestep = 0.0
        self.on_this_timestep = False
        self.ems_power_request = 0.0
        self.ems_request_on = False
        self.plant_info_found = False
        self.cogen_location = None
        self.nominal_therm_elect_ratio = thermal_to_elect_ratio
        self.dc_electricity_prod = 0.0
        self.dc_elect_prod_rate = 0.0
        self.electricity_prod = 0.0
        self.elect_prod_rate = 0.0
        self.thermal_prod = 0.0
        self.therm_prod_rate = 0.0
        self.pvwatts_generator = None
        self.err_count_neg_elect_prod_ = 0

    def sim_generator_get_power_output(self, state: Any, run_flag: bool,
                                      my_elec_load_request: float, first_hvac_iteration: bool) -> tuple:
        electric_power_output = 0.0
        thermal_power_output = 0.0
        return electric_power_output, thermal_power_output

    def reinit_at_begin_environment(self):
        self.on_this_timestep = False
        self.dc_electricity_prod = 0.0
        self.dc_elect_prod_rate = 0.0
        self.electricity_prod = 0.0
        self.elect_prod_rate = 0.0
        self.thermal_prod = 0.0
        self.therm_prod_rate = 0.0


class ElectPowerLoadCenter:
    class ElectricBussType(IntEnum):
        INVALID = -1
        AC_BUSS = 0
        DC_BUSS_INVERTER = 1
        AC_BUSS_STORAGE = 2
        DC_BUSS_INVERTER_DC_STORAGE = 3
        DC_BUSS_INVERTER_AC_STORAGE = 4
        NUM = 5

    class GeneratorOpScheme(IntEnum):
        INVALID = -1
        BASE_LOAD = 0
        DEMAND_LIMIT = 1
        TRACK_ELECTRICAL = 2
        TRACK_SCHEDULE = 3
        TRACK_METER = 4
        THERMAL_FOLLOW = 5
        THERMAL_FOLLOW_LIMIT_ELECTRICAL = 6
        NUM = 7

    class StorageOpScheme(IntEnum):
        INVALID = -1
        FACILITY_DEMAND_STORE_EXCESS_ON_SITE = 0
        METER_DEMAND_STORE_EXCESS_ON_SITE = 1
        CHARGE_DISCHARGE_SCHEDULES = 2
        FACILITY_DEMAND_LEVELING = 3
        NUM = 4

    def __init__(self, state: Any, object_num: int):
        self.name_ = ""
        self.generator_list_name_ = ""
        self.num_generators = 0
        self.buss_type = self.ElectricBussType.INVALID
        self.thermal_prod = 0.0
        self.thermal_prod_rate = 0.0
        self.inverter_present = False
        self.inverter_name = ""
        self.inverter_obj = None
        self.subpanel_feed_in_request = 0.0
        self.subpanel_feed_in_rate = 0.0
        self.subpanel_draw_rate = 0.0
        self.gen_elec_prod = 0.0
        self.gen_elec_prod_rate = 0.0
        self.stor_op_cv_gen_rate = 0.0
        self.stor_op_cv_draw_rate = 0.0
        self.stor_op_cv_feed_in_rate = 0.0
        self.stor_op_cv_charge_rate = 0.0
        self.stor_op_cv_discharge_rate = 0.0
        self.stor_op_is_charging = False
        self.stor_op_is_discharging = False
        self.gen_operation_scheme_ = self.GeneratorOpScheme.INVALID
        self.demand_meter_ptr_ = 0
        self.generators_present_ = False
        self.demand_limit_ = 0.0
        self.track_sched_ = None
        self.storage_present_ = False
        self.storage_name_ = ""
        self.storage_obj = None
        self.transformer_present_ = False
        self.transformer_name_ = ""
        self.transformer_obj = None
        self.converter_present_ = False
        self.converter_name_ = ""
        self.converter_obj = None
        self.storage_scheme_ = self.StorageOpScheme.INVALID
        self.max_storage_soc_fraction_ = 1.0
        self.min_storage_soc_fraction_ = 0.0
        self.elec_gen_cntrl_obj: List[GeneratorController] = []
        self.total_power_request_ = 0.0
        self.total_thermal_power_request_ = 0.0
        self.gen_elec_prod = 0.0

    def manage_elec_load_center(self, state: Any, first_hvac_iteration: bool,
                               remaining_whole_power_demand: float) -> float:
        self.subpanel_feed_in_request = remaining_whole_power_demand
        if self.generators_present_:
            remaining_whole_power_demand = self.dispatch_generators(state, first_hvac_iteration,
                                                                   remaining_whole_power_demand)
        self.update_load_center_generator_records(state)
        if (self.buss_type == self.ElectricBussType.DC_BUSS_INVERTER or
            self.buss_type == self.ElectricBussType.DC_BUSS_INVERTER_AC_STORAGE):
            if self.inverter_obj is not None:
                self.inverter_obj.simulate(state, self.gen_elec_prod_rate)
        if self.storage_present_:
            if self.storage_obj is not None:
                self.storage_obj.time_check_and_update(state)
            self.dispatch_storage(state, self.subpanel_feed_in_request)
        self.update_load_center_generator_records(state)
        return remaining_whole_power_demand

    def setup_load_center_meter_indices(self, state: Any):
        pass

    def reinit_at_begin_environment(self):
        self.gen_elec_prod = 0.0
        self.gen_elec_prod_rate = 0.0
        self.thermal_prod = 0.0
        self.thermal_prod_rate = 0.0
        self.total_power_request_ = 0.0
        self.total_thermal_power_request_ = 0.0
        self.subpanel_feed_in_rate = 0.0
        self.subpanel_draw_rate = 0.0
        self.stor_op_cv_draw_rate = 0.0
        self.stor_op_cv_feed_in_rate = 0.0
        self.stor_op_cv_charge_rate = 0.0
        self.stor_op_cv_discharge_rate = 0.0

    def reinit_zone_gains_at_begin_environment(self):
        pass

    def generator_list_name(self) -> str:
        return self.generator_list_name_

    def update_load_center_generator_records(self, state: Any):
        self.gen_elec_prod_rate = 0.0
        self.gen_elec_prod = 0.0
        for gc in self.elec_gen_cntrl_obj:
            self.gen_elec_prod_rate += gc.elect_prod_rate
            self.gen_elec_prod += gc.electricity_prod

    def dispatch_generators(self, state: Any, first_hvac_iteration: bool,
                           remaining_whole_power_demand: float) -> float:
        return remaining_whole_power_demand

    def dispatch_storage(self, state: Any, original_feed_in_request: float):
        pass

    def calc_load_center_thermal_load(self, state: Any) -> float:
        return 0.0


class ElectricPowerServiceManager:
    def __init__(self):
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
        self.elec_load_center_objs: List[ElectPowerLoadCenter] = []

    def manage_electric_power_service(self, state: Any, first_hvac_iteration: bool,
                                     update_meters_only: bool) -> bool:
        if self.get_input_flag_:
            self.get_power_manager_input(state)
            self.get_input_flag_ = False

        if state.dataGlobal.MetersHaveBeenInitialized and self.setup_meter_index_flag_:
            self.setup_meter_indices(state)
            self.setup_meter_index_flag_ = False

        if state.dataGlobal.BeginEnvrnFlag and self.new_environment_flag_:
            self.reinit_at_begin_environment()
            self.new_environment_flag_ = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.new_environment_flag_ = True

        self.total_bldg_elec_demand_ = 0.0
        self.total_hvac_elec_demand_ = 0.0
        self.total_electric_demand_ = 0.0

        self.whole_bldg_remaining_load_ = self.total_electric_demand_

        if update_meters_only:
            self.update_whole_building_records(state)
            return False

        for lc in self.elec_load_center_objs:
            lc.manage_elec_load_center(state, first_hvac_iteration, self.whole_bldg_remaining_load_)

        self.update_whole_building_records(state)
        return False

    def reinit_zone_gains_at_begin_environment(self):
        pass

    def get_power_manager_input(self, state: Any):
        pass

    def setup_meter_indices(self, state: Any):
        pass

    def reinit_at_begin_environment(self):
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

    def verify_custom_meters_elec_power_mgr(self, state: Any):
        pass

    def update_whole_building_records(self, state: Any):
        self.total_bldg_elec_demand_ = 0.0
        self.total_hvac_elec_demand_ = 0.0
        self.total_electric_demand_ = self.total_bldg_elec_demand_ + self.total_hvac_elec_demand_
        self.elec_produced_pv_rate_ = 0.0
        self.elec_produced_wt_rate_ = 0.0
        self.elec_produced_storage_rate_ = 0.0
        self.elec_produced_cogen_rate_ = 0.0
        self.elec_produced_power_conversion_rate_ = 0.0

        self.elec_prod_rate_ = (self.elec_produced_cogen_rate_ + self.elec_produced_pv_rate_ +
                               self.elec_produced_wt_rate_ + self.elec_produced_storage_rate_ +
                               self.elec_produced_power_conversion_rate_)
        self.electricity_prod_ = self.elec_prod_rate_ * state.dataHVACGlobal.TimeStepSysSec

        self.elec_purch_rate_ = self.total_electric_demand_ - self.elec_prod_rate_
        if abs(self.elec_purch_rate_) < 0.0001:
            self.elec_purch_rate_ = 0.0
        if self.elec_purch_rate_ < 0.0:
            self.elec_purch_rate_ = 0.0

        self.electricity_purch_ = self.elec_purch_rate_ * state.dataHVACGlobal.TimeStepSysSec

        self.elec_surplus_rate_ = self.elec_prod_rate_ - self.total_electric_demand_
        if abs(self.elec_surplus_rate_) < 0.0001:
            self.elec_surplus_rate_ = 0.0
        if self.elec_surplus_rate_ < 0.0:
            self.elec_surplus_rate_ = 0.0

        self.electricity_surplus_ = self.elec_surplus_rate_ * state.dataHVACGlobal.TimeStepSysSec

        self.electricity_net_rate_ = self.total_electric_demand_ - self.elec_prod_rate_
        self.electricity_net_ = self.electricity_net_rate_ * state.dataHVACGlobal.TimeStepSysSec

    def report_pv_and_wind_capacity(self, state: Any):
        self.pv_total_capacity_ = 0.0
        self.wind_total_capacity_ = 0.0

    def sum_up_number_of_storage_devices(self):
        self.num_elec_storage_devices = 0
        for lc in self.elec_load_center_objs:
            if lc.storage_obj is not None:
                self.num_elec_storage_devices += 1

    def check_load_centers(self, state: Any):
        pass


def create_facility_electric_power_service_object(state: Any):
    return ElectricPowerServiceManager()


def initialize_electric_power_service_zone_gains(state: Any):
    pass


def check_user_efficiency_input(state: Any, user_input_value: float, is_charging: bool,
                               device_name: str) -> tuple:
    min_charge_efficiency = 0.001
    min_discharge_efficiency = 0.001
    errors_found = False
    if is_charging:
        if user_input_value < min_charge_efficiency:
            errors_found = True
            return min_charge_efficiency, errors_found
        return user_input_value, errors_found
    if user_input_value < min_discharge_efficiency:
        errors_found = True
        return min_discharge_efficiency, errors_found
    return user_input_value, errors_found


def check_charge_discharge_voltage_curves(state: Any, name_batt: str, e0c: float, e0d: float,
                                         charge_curve: Any, discharge_curve: Any):
    pass
