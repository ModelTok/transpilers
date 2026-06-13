from typing import Protocol, List, Optional
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state container from EnergyPlus.Data.EnergyPlusData
# - SetupOutputVariable: function from EnergyPlus.OutputProcessor
# - Constant.Units: enum class from EnergyPlus.Constant
# - Constant.eResource: enum class from EnergyPlus.Constant
# - OutputProcessor.TimeStepType: enum class from EnergyPlus.OutputProcessor
# - OutputProcessor.StoreType: enum class from EnergyPlus.OutputProcessor
# - OutputProcessor.Group: enum class from EnergyPlus.OutputProcessor
# - OutputProcessor.EndUseCat: enum class from EnergyPlus.OutputProcessor
# - state.dataHeatBal.Zone: zone array with Multiplier, ListMultiplier, IsControlled properties
# - state.dataHVACGlobal.TimeStepSysSec: float, time step in seconds
# - state.dataHeatBalFanSys.LoadCorrectionFactor: array indexed by zone number
# - state.dataHeatBal.DoLatentSizing: boolean flag


class ZoneSystemDemandData(ABC):
    """Base class for zone system demand data."""

    def __init__(self):
        self.remaining_output_required = 0.0
        self.unadj_remaining_output_required = 0.0
        self.total_output_required = 0.0
        self.num_zone_equipment = 0
        self.supply_air_adjust_factor = 1.0
        self.stage_num = 0

    @abstractmethod
    def begin_environment_init(self):
        """Initialize at beginning of environment."""
        pass

    @abstractmethod
    def set_up_output_vars(
        self,
        state,
        prefix: str,
        name: str,
        staged: bool,
        attach_meters: bool,
        zone_mult: int,
        list_mult: int,
    ):
        """Set up output variables."""
        pass


class ZoneSystemSensibleDemand(ZoneSystemDemandData):
    """Sensible cooling/heating loads in watts."""

    def __init__(self):
        super().__init__()
        self.output_required_to_heating_sp = 0.0
        self.output_required_to_cooling_sp = 0.0
        self.remaining_output_req_to_heat_sp = 0.0
        self.remaining_output_req_to_cool_sp = 0.0
        self.unadj_remaining_output_req_to_heat_sp = 0.0
        self.unadj_remaining_output_req_to_cool_sp = 0.0
        self.sequenced_output_required: List[float] = []
        self.sequenced_output_required_to_heating_sp: List[float] = []
        self.sequenced_output_required_to_cooling_sp: List[float] = []
        self.predicted_rate = 0.0
        self.predicted_hsp_rate = 0.0
        self.predicted_csp_rate = 0.0
        self.air_sys_heat_rate = 0.0
        self.air_sys_cool_rate = 0.0
        self.air_sys_heat_energy = 0.0
        self.air_sys_cool_energy = 0.0

    def begin_environment_init(self):
        """Initialize sensible demand at beginning of environment."""
        self.remaining_output_required = 0.0
        self.total_output_required = 0.0
        if self.sequenced_output_required:
            for equip_num in range(self.num_zone_equipment):
                self.sequenced_output_required[equip_num] = 0.0
                self.sequenced_output_required_to_heating_sp[equip_num] = 0.0
                self.sequenced_output_required_to_cooling_sp[equip_num] = 0.0
        self.air_sys_heat_energy = 0.0
        self.air_sys_cool_energy = 0.0
        self.air_sys_heat_rate = 0.0
        self.air_sys_cool_rate = 0.0
        self.predicted_rate = 0.0
        self.predicted_hsp_rate = 0.0
        self.predicted_csp_rate = 0.0

    def set_up_output_vars(
        self,
        state,
        prefix: str,
        name: str,
        staged: bool,
        attach_meters: bool,
        zone_mult: int,
        list_mult: int,
    ):
        """Set up sensible output variables."""
        if attach_meters:
            SetupOutputVariable(
                state,
                f"{prefix} Air System Sensible Heating Energy",
                Constant.Units.J,
                self.air_sys_heat_energy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name,
                Constant.eResource.EnergyTransfer,
                OutputProcessor.Group.Building,
                OutputProcessor.EndUseCat.Heating,
                "",
                name,
                zone_mult,
                list_mult,
            )
            SetupOutputVariable(
                state,
                f"{prefix} Air System Sensible Cooling Energy",
                Constant.Units.J,
                self.air_sys_cool_energy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name,
                Constant.eResource.EnergyTransfer,
                OutputProcessor.Group.Building,
                OutputProcessor.EndUseCat.Cooling,
                "",
                name,
                zone_mult,
                list_mult,
            )
        else:
            SetupOutputVariable(
                state,
                f"{prefix} Air System Sensible Heating Energy",
                Constant.Units.J,
                self.air_sys_heat_energy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name,
            )
            SetupOutputVariable(
                state,
                f"{prefix} Air System Sensible Cooling Energy",
                Constant.Units.J,
                self.air_sys_cool_energy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name,
            )
        SetupOutputVariable(
            state,
            f"{prefix} Air System Sensible Heating Rate",
            Constant.Units.W,
            self.air_sys_heat_rate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} Air System Sensible Cooling Rate",
            Constant.Units.W,
            self.air_sys_cool_rate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} Predicted Sensible Load to Setpoint Heat Transfer Rate",
            Constant.Units.W,
            self.predicted_rate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} Predicted Sensible Load to Heating Setpoint Heat Transfer Rate",
            Constant.Units.W,
            self.predicted_hsp_rate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} Predicted Sensible Load to Cooling Setpoint Heat Transfer Rate",
            Constant.Units.W,
            self.predicted_csp_rate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} System Predicted Sensible Load to Setpoint Heat Transfer Rate",
            Constant.Units.W,
            self.total_output_required,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} System Predicted Sensible Load to Heating Setpoint Heat Transfer Rate",
            Constant.Units.W,
            self.output_required_to_heating_sp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} System Predicted Sensible Load to Cooling Setpoint Heat Transfer Rate",
            Constant.Units.W,
            self.output_required_to_cooling_sp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        if staged:
            SetupOutputVariable(
                state,
                f"{prefix} Thermostat Staged Number",
                Constant.Units.None,
                self.stage_num,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name,
            )

    def report_zone_air_system_sensible_loads(self, state, sn_load: float):
        """Report sensible heating/cooling rates and energy."""
        self.air_sys_heat_rate = max(sn_load, 0.0)
        self.air_sys_cool_rate = abs(min(sn_load, 0.0))
        self.air_sys_heat_energy = self.air_sys_heat_rate * state.dataHVACGlobal.TimeStepSysSec
        self.air_sys_cool_energy = self.air_sys_cool_rate * state.dataHVACGlobal.TimeStepSysSec

    def report_sensible_loads_zone_multiplier(
        self,
        state,
        zone_num: int,
        total_load: float,
        load_to_heating_set_point: float,
        load_to_cooling_set_point: float,
    ):
        """Report sensible loads with zone multiplier applied."""
        load_corr_factor = state.dataHeatBalFanSys.LoadCorrectionFactor(zone_num)

        self.predicted_rate = total_load * load_corr_factor
        self.predicted_hsp_rate = load_to_heating_set_point * load_corr_factor
        self.predicted_csp_rate = load_to_cooling_set_point * load_corr_factor

        zone_mult_fac = (
            state.dataHeatBal.Zone(zone_num).Multiplier
            * state.dataHeatBal.Zone(zone_num).ListMultiplier
        )
        self.total_output_required = self.predicted_rate * zone_mult_fac
        self.output_required_to_heating_sp = self.predicted_hsp_rate * zone_mult_fac
        self.output_required_to_cooling_sp = self.predicted_csp_rate * zone_mult_fac

        if (
            state.dataHeatBal.Zone(zone_num).IsControlled
            and self.num_zone_equipment > 0
        ):
            for equip_num in range(self.num_zone_equipment):
                self.sequenced_output_required[equip_num] = self.total_output_required
                self.sequenced_output_required_to_heating_sp[
                    equip_num
                ] = self.output_required_to_heating_sp
                self.sequenced_output_required_to_cooling_sp[
                    equip_num
                ] = self.output_required_to_cooling_sp


class ZoneSystemMoistureDemand(ZoneSystemDemandData):
    """Humidification/dehumidification loads in kg water per second."""

    def __init__(self):
        super().__init__()
        self.output_required_to_humidifying_sp = 0.0
        self.output_required_to_dehumidifying_sp = 0.0
        self.remaining_output_req_to_humid_sp = 0.0
        self.remaining_output_req_to_dehumid_sp = 0.0
        self.unadj_remaining_output_req_to_humid_sp = 0.0
        self.unadj_remaining_output_req_to_dehumid_sp = 0.0
        self.sequenced_output_required: List[float] = []
        self.sequenced_output_required_to_humid_sp: List[float] = []
        self.sequenced_output_required_to_dehumid_sp: List[float] = []
        self.predicted_rate = 0.0
        self.predicted_hum_sp_rate = 0.0
        self.predicted_dehum_sp_rate = 0.0
        self.air_sys_heat_rate = 0.0
        self.air_sys_cool_rate = 0.0
        self.air_sys_heat_energy = 0.0
        self.air_sys_cool_energy = 0.0
        self.air_sys_sensible_heat_ratio = 0.0
        self.vapor_pressure_difference = 0.0

    def begin_environment_init(self):
        """Initialize moisture demand at beginning of environment."""
        self.remaining_output_required = 0.0
        self.total_output_required = 0.0
        if self.sequenced_output_required:
            for equip_num in range(self.num_zone_equipment):
                self.sequenced_output_required[equip_num] = 0.0
                self.sequenced_output_required_to_humid_sp[equip_num] = 0.0
                self.sequenced_output_required_to_dehumid_sp[equip_num] = 0.0
        self.air_sys_heat_energy = 0.0
        self.air_sys_cool_energy = 0.0
        self.air_sys_heat_rate = 0.0
        self.air_sys_cool_rate = 0.0
        self.air_sys_sensible_heat_ratio = 0.0
        self.vapor_pressure_difference = 0.0
        self.predicted_rate = 0.0
        self.predicted_hum_sp_rate = 0.0
        self.predicted_dehum_sp_rate = 0.0

    def set_up_output_vars(
        self,
        state,
        prefix: str,
        name: str,
        staged: bool = False,
        attach_meters: bool = False,
        zone_mult: int = 0,
        list_mult: int = 0,
    ):
        """Set up moisture output variables."""
        if state.dataHeatBal.DoLatentSizing:
            SetupOutputVariable(
                state,
                f"{prefix} Air System Latent Heating Energy",
                Constant.Units.J,
                self.air_sys_heat_energy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name,
            )
            SetupOutputVariable(
                state,
                f"{prefix} Air System Latent Cooling Energy",
                Constant.Units.J,
                self.air_sys_cool_energy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name,
            )
            SetupOutputVariable(
                state,
                f"{prefix} Air System Latent Heating Rate",
                Constant.Units.W,
                self.air_sys_heat_rate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name,
            )
            SetupOutputVariable(
                state,
                f"{prefix} Air System Latent Cooling Rate",
                Constant.Units.W,
                self.air_sys_cool_rate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name,
            )
            SetupOutputVariable(
                state,
                f"{prefix} Air System Sensible Heat Ratio",
                Constant.Units.None,
                self.air_sys_sensible_heat_ratio,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name,
            )
            SetupOutputVariable(
                state,
                f"{prefix} Air Vapor Pressure Difference",
                Constant.Units.Pa,
                self.vapor_pressure_difference,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name,
            )
        SetupOutputVariable(
            state,
            f"{prefix} Predicted Moisture Load Moisture Transfer Rate",
            Constant.Units.kgWater_s,
            self.predicted_rate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} Predicted Moisture Load to Humidifying Setpoint Moisture Transfer Rate",
            Constant.Units.kgWater_s,
            self.predicted_hum_sp_rate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} Predicted Moisture Load to Dehumidifying Setpoint Moisture Transfer Rate",
            Constant.Units.kgWater_s,
            self.predicted_dehum_sp_rate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} System Predicted Moisture Load Moisture Transfer Rate",
            Constant.Units.kgWater_s,
            self.total_output_required,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} System Predicted Moisture Load to Humidifying Setpoint Moisture Transfer Rate",
            Constant.Units.kgWater_s,
            self.output_required_to_humidifying_sp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )
        SetupOutputVariable(
            state,
            f"{prefix} System Predicted Moisture Load to Dehumidifying Setpoint Moisture Transfer Rate",
            Constant.Units.kgWater_s,
            self.output_required_to_dehumidifying_sp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name,
        )

    def report_zone_air_system_moisture_loads(
        self, state, latent_gain: float, sensible_load: float, vapor_pressure_diff: float
    ):
        """Report moisture rates and energy."""
        self.air_sys_heat_rate = abs(min(latent_gain, 0.0))
        self.air_sys_cool_rate = max(latent_gain, 0.0)
        self.air_sys_heat_energy = self.air_sys_heat_rate * state.dataHVACGlobal.TimeStepSysSec
        self.air_sys_cool_energy = self.air_sys_cool_rate * state.dataHVACGlobal.TimeStepSysSec
        if (sensible_load + latent_gain) != 0.0:
            self.air_sys_sensible_heat_ratio = sensible_load / (sensible_load + latent_gain)
        elif sensible_load != 0.0:
            self.air_sys_sensible_heat_ratio = 1.0
        else:
            self.air_sys_sensible_heat_ratio = 0.0
        self.vapor_pressure_difference = vapor_pressure_diff

    def report_moist_loads_zone_multiplier(
        self,
        state,
        zone_num: int,
        total_load: float,
        load_to_humidify_set_point: float,
        load_to_dehumidify_set_point: float,
    ):
        """Report moisture loads with zone multiplier applied."""
        self.predicted_rate = total_load
        self.predicted_hum_sp_rate = load_to_humidify_set_point
        self.predicted_dehum_sp_rate = load_to_dehumidify_set_point

        zone_mult_fac = (
            state.dataHeatBal.Zone(zone_num).Multiplier
            * state.dataHeatBal.Zone(zone_num).ListMultiplier
        )

        self.total_output_required = total_load * zone_mult_fac
        self.output_required_to_humidifying_sp = (
            load_to_humidify_set_point * zone_mult_fac
        )
        self.output_required_to_dehumidifying_sp = (
            load_to_dehumidify_set_point * zone_mult_fac
        )

        if (
            state.dataHeatBal.Zone(zone_num).IsControlled
            and self.num_zone_equipment > 0
        ):
            for equip_num in range(self.num_zone_equipment):
                self.sequenced_output_required[equip_num] = self.total_output_required
                self.sequenced_output_required_to_humid_sp[
                    equip_num
                ] = self.output_required_to_humidifying_sp
                self.sequenced_output_required_to_dehumid_sp[
                    equip_num
                ] = self.output_required_to_dehumidifying_sp


@dataclass
class DataZoneEnergyDemandsData:
    """Container for all zone energy demand data."""

    dead_band_or_setback: List[bool] = field(default_factory=list)
    setback: List[bool] = field(default_factory=list)
    cur_dead_band_or_setback: List[bool] = field(default_factory=list)
    zone_sys_energy_demand: List[ZoneSystemSensibleDemand] = field(
        default_factory=list
    )
    zone_sys_moisture_demand: List[ZoneSystemMoistureDemand] = field(
        default_factory=list
    )
    space_sys_energy_demand: List[ZoneSystemSensibleDemand] = field(
        default_factory=list
    )
    space_sys_moisture_demand: List[ZoneSystemMoistureDemand] = field(
        default_factory=list
    )

    def init_constant_state(self, state):
        """Initialize constant state."""
        pass

    def init_state(self, state):
        """Initialize state."""
        pass

    def clear_state(self):
        """Clear state."""
        self.dead_band_or_setback.clear()
        self.setback.clear()
        self.cur_dead_band_or_setback.clear()
        self.zone_sys_energy_demand.clear()
        self.zone_sys_moisture_demand.clear()
        self.space_sys_energy_demand.clear()
        self.space_sys_moisture_demand.clear()


# Stub implementations for external dependencies
def SetupOutputVariable(state, name: str, units, variable, *args, **kwargs):
    """Stub for SetupOutputVariable."""
    pass


class Constant:
    """Stub for Constant namespace."""

    class Units:
        J = "J"
        W = "W"
        Pa = "Pa"
        kgWater_s = "kgWater/s"
        None = "None"

    class eResource:
        EnergyTransfer = "EnergyTransfer"


class OutputProcessor:
    """Stub for OutputProcessor namespace."""

    class TimeStepType:
        System = "System"

    class StoreType:
        Sum = "Sum"
        Average = "Average"

    class Group:
        Building = "Building"

    class EndUseCat:
        Heating = "Heating"
        Cooling = "Cooling"
