from math import abs as math_abs, max as math_max, min as math_min


struct ZoneSystemDemandData:
    """Base struct for zone system demand data."""
    var remaining_output_required: Float64
    var unadj_remaining_output_required: Float64
    var total_output_required: Float64
    var num_zone_equipment: Int32
    var supply_air_adjust_factor: Float64
    var stage_num: Int32

    fn __init__(inout self):
        self.remaining_output_required = 0.0
        self.unadj_remaining_output_required = 0.0
        self.total_output_required = 0.0
        self.num_zone_equipment = 0
        self.supply_air_adjust_factor = 1.0
        self.stage_num = 0

    fn begin_environment_init(inout self):
        """Initialize at beginning of environment."""
        pass

    fn set_up_output_vars(
        inout self,
        state: AnyType,
        prefix: StringRef,
        name: StringRef,
        staged: Bool,
        attach_meters: Bool,
        zone_mult: Int32,
        list_mult: Int32,
    ):
        """Set up output variables."""
        pass


struct ZoneSystemSensibleDemand(ZoneSystemDemandData):
    """Sensible cooling/heating loads in watts."""
    var output_required_to_heating_sp: Float64
    var output_required_to_cooling_sp: Float64
    var remaining_output_req_to_heat_sp: Float64
    var remaining_output_req_to_cool_sp: Float64
    var unadj_remaining_output_req_to_heat_sp: Float64
    var unadj_remaining_output_req_to_cool_sp: Float64
    var sequenced_output_required: List[Float64]
    var sequenced_output_required_to_heating_sp: List[Float64]
    var sequenced_output_required_to_cooling_sp: List[Float64]
    var predicted_rate: Float64
    var predicted_hsp_rate: Float64
    var predicted_csp_rate: Float64
    var air_sys_heat_rate: Float64
    var air_sys_cool_rate: Float64
    var air_sys_heat_energy: Float64
    var air_sys_cool_energy: Float64

    fn __init__(inout self):
        super().__init__()
        self.output_required_to_heating_sp = 0.0
        self.output_required_to_cooling_sp = 0.0
        self.remaining_output_req_to_heat_sp = 0.0
        self.remaining_output_req_to_cool_sp = 0.0
        self.unadj_remaining_output_req_to_heat_sp = 0.0
        self.unadj_remaining_output_req_to_cool_sp = 0.0
        self.sequenced_output_required = List[Float64]()
        self.sequenced_output_required_to_heating_sp = List[Float64]()
        self.sequenced_output_required_to_cooling_sp = List[Float64]()
        self.predicted_rate = 0.0
        self.predicted_hsp_rate = 0.0
        self.predicted_csp_rate = 0.0
        self.air_sys_heat_rate = 0.0
        self.air_sys_cool_rate = 0.0
        self.air_sys_heat_energy = 0.0
        self.air_sys_cool_energy = 0.0

    fn begin_environment_init(inout self):
        """Initialize sensible demand at beginning of environment."""
        self.remaining_output_required = 0.0
        self.total_output_required = 0.0
        if self.sequenced_output_required.size() > 0:
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

    fn set_up_output_vars(
        inout self,
        state: AnyType,
        prefix: StringRef,
        name: StringRef,
        staged: Bool,
        attach_meters: Bool,
        zone_mult: Int32,
        list_mult: Int32,
    ):
        """Set up sensible output variables."""
        if attach_meters:
            setup_output_variable(
                state,
                String(prefix) + " Air System Sensible Heating Energy",
                "J",
                self.air_sys_heat_energy,
                "System",
                "Sum",
                name,
                "EnergyTransfer",
                "Building",
                "Heating",
                "",
                name,
                zone_mult,
                list_mult,
            )
            setup_output_variable(
                state,
                String(prefix) + " Air System Sensible Cooling Energy",
                "J",
                self.air_sys_cool_energy,
                "System",
                "Sum",
                name,
                "EnergyTransfer",
                "Building",
                "Cooling",
                "",
                name,
                zone_mult,
                list_mult,
            )
        else:
            setup_output_variable(
                state,
                String(prefix) + " Air System Sensible Heating Energy",
                "J",
                self.air_sys_heat_energy,
                "System",
                "Sum",
                name,
            )
            setup_output_variable(
                state,
                String(prefix) + " Air System Sensible Cooling Energy",
                "J",
                self.air_sys_cool_energy,
                "System",
                "Sum",
                name,
            )
        setup_output_variable(
            state,
            String(prefix) + " Air System Sensible Heating Rate",
            "W",
            self.air_sys_heat_rate,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix) + " Air System Sensible Cooling Rate",
            "W",
            self.air_sys_cool_rate,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix) + " Predicted Sensible Load to Setpoint Heat Transfer Rate",
            "W",
            self.predicted_rate,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix) + " Predicted Sensible Load to Heating Setpoint Heat Transfer Rate",
            "W",
            self.predicted_hsp_rate,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix) + " Predicted Sensible Load to Cooling Setpoint Heat Transfer Rate",
            "W",
            self.predicted_csp_rate,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix) + " System Predicted Sensible Load to Setpoint Heat Transfer Rate",
            "W",
            self.total_output_required,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix) + " System Predicted Sensible Load to Heating Setpoint Heat Transfer Rate",
            "W",
            self.output_required_to_heating_sp,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix) + " System Predicted Sensible Load to Cooling Setpoint Heat Transfer Rate",
            "W",
            self.output_required_to_cooling_sp,
            "System",
            "Average",
            name,
        )
        if staged:
            setup_output_variable(
                state,
                String(prefix) + " Thermostat Staged Number",
                "None",
                self.stage_num,
                "System",
                "Average",
                name,
            )

    fn report_zone_air_system_sensible_loads(
        inout self, state: AnyType, sn_load: Float64
    ):
        """Report sensible heating/cooling rates and energy."""
        self.air_sys_heat_rate = max(sn_load, 0.0)
        self.air_sys_cool_rate = abs(min(sn_load, 0.0))
        self.air_sys_heat_energy = self.air_sys_heat_rate * state.dataHVACGlobal.time_step_sys_sec
        self.air_sys_cool_energy = self.air_sys_cool_rate * state.dataHVACGlobal.time_step_sys_sec

    fn report_sensible_loads_zone_multiplier(
        inout self,
        state: AnyType,
        zone_num: Int32,
        total_load: Float64,
        load_to_heating_set_point: Float64,
        load_to_cooling_set_point: Float64,
    ):
        """Report sensible loads with zone multiplier applied."""
        var load_corr_factor: Float64 = state.dataHeatBalFanSys.load_correction_factor(zone_num)

        self.predicted_rate = total_load * load_corr_factor
        self.predicted_hsp_rate = load_to_heating_set_point * load_corr_factor
        self.predicted_csp_rate = load_to_cooling_set_point * load_corr_factor

        var zone_mult_fac: Float64 = (
            state.dataHeatBal.zone(zone_num).multiplier
            * state.dataHeatBal.zone(zone_num).list_multiplier
        )
        self.total_output_required = self.predicted_rate * zone_mult_fac
        self.output_required_to_heating_sp = self.predicted_hsp_rate * zone_mult_fac
        self.output_required_to_cooling_sp = self.predicted_csp_rate * zone_mult_fac

        if (
            state.dataHeatBal.zone(zone_num).is_controlled
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


struct ZoneSystemMoistureDemand(ZoneSystemDemandData):
    """Humidification/dehumidification loads in kg water per second."""
    var output_required_to_humidifying_sp: Float64
    var output_required_to_dehumidifying_sp: Float64
    var remaining_output_req_to_humid_sp: Float64
    var remaining_output_req_to_dehumid_sp: Float64
    var unadj_remaining_output_req_to_humid_sp: Float64
    var unadj_remaining_output_req_to_dehumid_sp: Float64
    var sequenced_output_required: List[Float64]
    var sequenced_output_required_to_humid_sp: List[Float64]
    var sequenced_output_required_to_dehumid_sp: List[Float64]
    var predicted_rate: Float64
    var predicted_hum_sp_rate: Float64
    var predicted_dehum_sp_rate: Float64
    var air_sys_heat_rate: Float64
    var air_sys_cool_rate: Float64
    var air_sys_heat_energy: Float64
    var air_sys_cool_energy: Float64
    var air_sys_sensible_heat_ratio: Float64
    var vapor_pressure_difference: Float64

    fn __init__(inout self):
        super().__init__()
        self.output_required_to_humidifying_sp = 0.0
        self.output_required_to_dehumidifying_sp = 0.0
        self.remaining_output_req_to_humid_sp = 0.0
        self.remaining_output_req_to_dehumid_sp = 0.0
        self.unadj_remaining_output_req_to_humid_sp = 0.0
        self.unadj_remaining_output_req_to_dehumid_sp = 0.0
        self.sequenced_output_required = List[Float64]()
        self.sequenced_output_required_to_humid_sp = List[Float64]()
        self.sequenced_output_required_to_dehumid_sp = List[Float64]()
        self.predicted_rate = 0.0
        self.predicted_hum_sp_rate = 0.0
        self.predicted_dehum_sp_rate = 0.0
        self.air_sys_heat_rate = 0.0
        self.air_sys_cool_rate = 0.0
        self.air_sys_heat_energy = 0.0
        self.air_sys_cool_energy = 0.0
        self.air_sys_sensible_heat_ratio = 0.0
        self.vapor_pressure_difference = 0.0

    fn begin_environment_init(inout self):
        """Initialize moisture demand at beginning of environment."""
        self.remaining_output_required = 0.0
        self.total_output_required = 0.0
        if self.sequenced_output_required.size() > 0:
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

    fn set_up_output_vars(
        inout self,
        state: AnyType,
        prefix: StringRef,
        name: StringRef,
        staged: Bool = False,
        attach_meters: Bool = False,
        zone_mult: Int32 = 0,
        list_mult: Int32 = 0,
    ):
        """Set up moisture output variables."""
        if state.dataHeatBal.do_latent_sizing:
            setup_output_variable(
                state,
                String(prefix) + " Air System Latent Heating Energy",
                "J",
                self.air_sys_heat_energy,
                "System",
                "Sum",
                name,
            )
            setup_output_variable(
                state,
                String(prefix) + " Air System Latent Cooling Energy",
                "J",
                self.air_sys_cool_energy,
                "System",
                "Sum",
                name,
            )
            setup_output_variable(
                state,
                String(prefix) + " Air System Latent Heating Rate",
                "W",
                self.air_sys_heat_rate,
                "System",
                "Average",
                name,
            )
            setup_output_variable(
                state,
                String(prefix) + " Air System Latent Cooling Rate",
                "W",
                self.air_sys_cool_rate,
                "System",
                "Average",
                name,
            )
            setup_output_variable(
                state,
                String(prefix) + " Air System Sensible Heat Ratio",
                "None",
                self.air_sys_sensible_heat_ratio,
                "System",
                "Average",
                name,
            )
            setup_output_variable(
                state,
                String(prefix) + " Air Vapor Pressure Difference",
                "Pa",
                self.vapor_pressure_difference,
                "System",
                "Average",
                name,
            )
        setup_output_variable(
            state,
            String(prefix) + " Predicted Moisture Load Moisture Transfer Rate",
            "kgWater/s",
            self.predicted_rate,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix)
            + " Predicted Moisture Load to Humidifying Setpoint Moisture Transfer Rate",
            "kgWater/s",
            self.predicted_hum_sp_rate,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix)
            + " Predicted Moisture Load to Dehumidifying Setpoint Moisture Transfer Rate",
            "kgWater/s",
            self.predicted_dehum_sp_rate,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix) + " System Predicted Moisture Load Moisture Transfer Rate",
            "kgWater/s",
            self.total_output_required,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix)
            + " System Predicted Moisture Load to Humidifying Setpoint Moisture Transfer Rate",
            "kgWater/s",
            self.output_required_to_humidifying_sp,
            "System",
            "Average",
            name,
        )
        setup_output_variable(
            state,
            String(prefix)
            + " System Predicted Moisture Load to Dehumidifying Setpoint Moisture Transfer Rate",
            "kgWater/s",
            self.output_required_to_dehumidifying_sp,
            "System",
            "Average",
            name,
        )

    fn report_zone_air_system_moisture_loads(
        inout self,
        state: AnyType,
        latent_gain: Float64,
        sensible_load: Float64,
        vapor_pressure_diff: Float64,
    ):
        """Report moisture rates and energy."""
        self.air_sys_heat_rate = abs(min(latent_gain, 0.0))
        self.air_sys_cool_rate = max(latent_gain, 0.0)
        self.air_sys_heat_energy = (
            self.air_sys_heat_rate * state.dataHVACGlobal.time_step_sys_sec
        )
        self.air_sys_cool_energy = (
            self.air_sys_cool_rate * state.dataHVACGlobal.time_step_sys_sec
        )
        if (sensible_load + latent_gain) != 0.0:
            self.air_sys_sensible_heat_ratio = sensible_load / (
                sensible_load + latent_gain
            )
        elif sensible_load != 0.0:
            self.air_sys_sensible_heat_ratio = 1.0
        else:
            self.air_sys_sensible_heat_ratio = 0.0
        self.vapor_pressure_difference = vapor_pressure_diff

    fn report_moist_loads_zone_multiplier(
        inout self,
        state: AnyType,
        zone_num: Int32,
        total_load: Float64,
        load_to_humidify_set_point: Float64,
        load_to_dehumidify_set_point: Float64,
    ):
        """Report moisture loads with zone multiplier applied."""
        self.predicted_rate = total_load
        self.predicted_hum_sp_rate = load_to_humidify_set_point
        self.predicted_dehum_sp_rate = load_to_dehumidify_set_point

        var zone_mult_fac: Float64 = (
            state.dataHeatBal.zone(zone_num).multiplier
            * state.dataHeatBal.zone(zone_num).list_multiplier
        )

        self.total_output_required = total_load * zone_mult_fac
        self.output_required_to_humidifying_sp = (
            load_to_humidify_set_point * zone_mult_fac
        )
        self.output_required_to_dehumidifying_sp = (
            load_to_dehumidify_set_point * zone_mult_fac
        )

        if (
            state.dataHeatBal.zone(zone_num).is_controlled
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


struct DataZoneEnergyDemandsData:
    """Container for all zone energy demand data."""
    var dead_band_or_setback: List[Bool]
    var setback: List[Bool]
    var cur_dead_band_or_setback: List[Bool]
    var zone_sys_energy_demand: List[ZoneSystemSensibleDemand]
    var zone_sys_moisture_demand: List[ZoneSystemMoistureDemand]
    var space_sys_energy_demand: List[ZoneSystemSensibleDemand]
    var space_sys_moisture_demand: List[ZoneSystemMoistureDemand]

    fn __init__(inout self):
        self.dead_band_or_setback = List[Bool]()
        self.setback = List[Bool]()
        self.cur_dead_band_or_setback = List[Bool]()
        self.zone_sys_energy_demand = List[ZoneSystemSensibleDemand]()
        self.zone_sys_moisture_demand = List[ZoneSystemMoistureDemand]()
        self.space_sys_energy_demand = List[ZoneSystemSensibleDemand]()
        self.space_sys_moisture_demand = List[ZoneSystemMoistureDemand]()

    fn init_constant_state(inout self, state: AnyType):
        """Initialize constant state."""
        pass

    fn init_state(inout self, state: AnyType):
        """Initialize state."""
        pass

    fn clear_state(inout self):
        """Clear state."""
        self.dead_band_or_setback = List[Bool]()
        self.setback = List[Bool]()
        self.cur_dead_band_or_setback = List[Bool]()
        self.zone_sys_energy_demand = List[ZoneSystemSensibleDemand]()
        self.zone_sys_moisture_demand = List[ZoneSystemMoistureDemand]()
        self.space_sys_energy_demand = List[ZoneSystemSensibleDemand]()
        self.space_sys_moisture_demand = List[ZoneSystemMoistureDemand]()


fn setup_output_variable(state: AnyType, *args: AnyType) -> None:
    """Stub for setup_output_variable."""
    pass
