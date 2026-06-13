from math import max
from typing import Self

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main simulation state object (EnergyPlus/Data/EnergyPlusData.hh)
# - NodeData: node state with Temp, MassFlowRate, HumRat, Enthalpy, Press (EnergyPlus/DataLoopNode.hh)
# - CoilMode, FanOp: enums (EnergyPlus/DataHVACGlobals.hh)
# - Psychrometrics: functions (EnergyPlus/Psychrometrics.hh)
# - Constant: constants (EnergyPlus/DataGlobalConstants.hh)
# - tk205.rs0004_ns.RS0004: ASHRAE205 type (rs0004.h)
# - tk205.ashrae205_ns.SpeedControlType: enum
# - Btwxt.InterpolationMethod: enum
# - General.SolveRoot: root solver (EnergyPlus/General.hh)
# - ShowSevereError, ShowFatalError: logging (EnergyPlus/UtilityRoutines.hh)
# - Util.SameString, Util.makeUPPER: string utilities (EnergyPlus/UtilityRoutines.hh)
# - DataSystemVariables.CheckForActualFilePath: file path utility (EnergyPlus/DataSystemVariables.hh)
# - RSInstanceFactory: factory pattern for RS0004 creation (rs0004_factory.h)
# - EnergyPlusLogger: logging context (EnergyPlus/EnergyPlusLogger.hh)

struct InterpolationMethod:
    var value: Int
    alias linear = InterpolationMethod(0)
    alias cubic = InterpolationMethod(1)

struct SpeedControlType:
    var value: Int
    alias CONTINUOUS = SpeedControlType(0)
    alias DISCRETE = SpeedControlType(1)

struct FanOp:
    var value: Int
    alias Cycling = FanOp(0)
    alias Continuous = FanOp(1)

struct eFuel:
    var value: Int
    alias Electricity = eFuel(0)

struct Constant:
    alias Kelvin = 273.15
    alias iSecsInHour = 3600
    alias eFuel = eFuel

struct NodeData:
    var Temp: Float64
    var MassFlowRate: Float64
    var HumRat: Float64
    var Enthalpy: Float64
    var Press: Float64

struct DataEnvironment:
    var StdRhoAir: Float64
    var OutBaroPress: Float64

struct DataHVACGlobal:
    var TimeStepSys: Float64

struct Psychrometrics:
    @staticmethod
    fn PsyWFnTdbTwbPb(state: EnergyPlusData, tdb: Float64, twb: Float64, pb: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyRhFnTdbWPb(state: EnergyPlusData, tdb: Float64, w: Float64, pb: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyTdbFnHW(h: Float64, w: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyWFnTdbH(state: EnergyPlusData, tdb: Float64, h: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyTsatFnHPb(state: EnergyPlusData, h: Float64, pb: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyCpAirFnW(w: Float64) -> Float64:
        return 0.0

struct General:
    @staticmethod
    fn SolveRoot(state: EnergyPlusData, accuracy: Float64, max_iter: Int, 
                 sol_fla_ref: DynamicVector[Int], x_ref: DynamicVector[Float64],
                 f: fn(Float64) -> Float64, x_min: Float64, x_max: Float64) -> None:
        pass

struct LookupVariablesCoolingStruct:
    var gross_total_capacity: Float64
    var gross_sensible_capacity: Float64
    var gross_power: Float64

    fn __init__() -> Self:
        return Self(0.0, 0.0, 0.0)

struct GridVariables:
    var compressor_sequence_number: DynamicVector[Float64]
    var indoor_coil_air_mass_flow_rate: DynamicVector[Float64]

struct PerformanceMap:
    var grid_variables: GridVariables

    fn calculate_performance(self, tdb_outdoor: Float64, rh_indoor: Float64, tdb_indoor: Float64,
                             mfr: Float64, comp_seq: Float64, pressure: Float64,
                             interp_method: InterpolationMethod) -> LookupVariablesCoolingStruct:
        return LookupVariablesCoolingStruct()

    fn get_logger(self):
        pass

struct RS0004Performance:
    var performance_map_cooling: PerformanceMap
    var performance_map_standby: PerformanceMap
    var compressor_speed_control_type: SpeedControlType
    var cycling_degradation_coefficient: Float64

struct RS0004:
    var performance: RS0004Performance

struct EnergyPlusData:
    var dataEnvrn: DataEnvironment
    var dataHVACGlobal: DataHVACGlobal

struct CoilSpeedParameters:
    var evaporator_air_mass_flow: Float64
    var evaporator_air_volumetric_flow: Float64

    fn __init__() -> Self:
        return Self(0.0, 0.0)

struct CoilCoolingDXPerformanceBase:
    pass

struct CoilCoolingDX205Performance(CoilCoolingDXPerformanceBase):
    alias object_name = "Coil:DX:ASHRAE205:Performance"
    alias outdoor_coil_entering_dry_bulb_temperature_K = 308.15
    alias indoor_coil_entering_dry_bulb_temperature_K = 299.82
    alias reference_wb_temperature = 292.59
    alias reference_pressure_sea_level = 101325.0
    alias rating_flow = 400.0

    var name: String
    var representation: RS0004
    var logger_context: Tuple[EnergyPlusData, String]
    var interpolation_type: InterpolationMethod
    var rated_total_cooling_capacity: Float64
    var rated_steady_state_heating_capacity: Float64
    var rating_humidity_ratio: Float64
    var rating_indoor_coil_entering_relative_humidity: Float64
    var rating_rho_air: Float64
    var nominal_speed_index: Int
    var speeds: DynamicVector[CoilSpeedParameters]
    var compressorFuelType: eFuel
    var recoveredEnergyRate: Float64
    var NormalSHR: Float64
    var OperatingMode: Int
    var basinHeaterPower: Float64
    var RTF: Float64
    var powerUse: Float64
    var electricityConsumption: Float64
    var compressorFuelRate: Float64
    var compressorFuelConsumption: Float64
    var wasteHeatRate: Float64

    fn __init__(inout self, state: EnergyPlusData, name_to_find: String):
        self.name = ""
        self.interpolation_type = InterpolationMethod.linear
        self.rated_total_cooling_capacity = 0.0
        self.rated_steady_state_heating_capacity = 0.0
        self.rating_humidity_ratio = 0.0
        self.rating_indoor_coil_entering_relative_humidity = 0.0
        self.rating_rho_air = 0.0
        self.nominal_speed_index = 0
        self.speeds = DynamicVector[CoilSpeedParameters]()
        self.compressorFuelType = eFuel.Electricity
        self.recoveredEnergyRate = 0.0
        self.NormalSHR = 0.0
        self.OperatingMode = 0
        self.basinHeaterPower = 0.0
        self.RTF = 0.0
        self.powerUse = 0.0
        self.electricityConsumption = 0.0
        self.compressorFuelRate = 0.0
        self.compressorFuelConsumption = 0.0
        self.wasteHeatRate = 0.0

        routine_name = "CoilCoolingDX205Performance::CoilCoolingDX205Performance"

        errors_found = False

        self.rating_humidity_ratio = Psychrometrics.PsyWFnTdbTwbPb(
            state,
            Self.indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin,
            Self.reference_wb_temperature - Constant.Kelvin,
            Self.reference_pressure_sea_level
        )

        self.rating_indoor_coil_entering_relative_humidity = Psychrometrics.PsyRhFnTdbWPb(
            state,
            Self.indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin,
            self.rating_humidity_ratio,
            Self.reference_pressure_sea_level
        )

        self.rating_rho_air = state.dataEnvrn.StdRhoAir

        num_speeds = len(self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number)
        for _ in range(num_speeds):
            self.speeds.push_back(CoilSpeedParameters())

        self.nominal_speed_index = len(self.speeds) - 1
        self.rated_total_cooling_capacity = self.ratedTotalCapacityAtSpeedIndex(state, self.nominal_speed_index)

    fn num_speeds(self) -> Int:
        return len(self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number)

    fn rated_cbf(self, state: EnergyPlusData) -> Float64:
        return 0.001

    fn gross_rated_shr(self, state: EnergyPlusData) -> Float64:
        lookup_variables = self.calculate_rated_capacities(state, self.nominal_speed_index)
        return lookup_variables.gross_sensible_capacity / lookup_variables.gross_total_capacity

    fn evap_air_flow_rate_at_speed_index(self, state: EnergyPlusData, index: Int) -> Float64:
        return self.speeds[index].evaporator_air_volumetric_flow

    fn ratedTotalCapacityAtSpeedIndex(self, state: EnergyPlusData, index: Int) -> Float64:
        return self.calculate_rated_capacities(state, index).gross_total_capacity

    fn rated_evap_air_mass_flow_rate(self, state: EnergyPlusData) -> Float64:
        return self.speeds[self.nominal_speed_index].evaporator_air_mass_flow

    fn rated_evap_air_flow_rate(self, state: EnergyPlusData) -> Float64:
        return self.evap_air_flow_rate_at_speed_index(state, self.nominal_speed_index)

    fn rated_gross_total_cap(self) -> Float64:
        return self.rated_total_cooling_capacity

    fn size(inout self, state: EnergyPlusData):
        for index in range(len(self.speeds)):
            self.calculate_air_mass_flow(state, index)

    fn simulate(inout self, state: EnergyPlusData, inlet_node: NodeData, outlet_node: inout NodeData,
                coil_mode: Int, speed_num: Int, speed_ratio: Float64, fan_op_mode: FanOp,
                cond_inlet_node: NodeData, cond_outlet_node: inout NodeData,
                single_mode: Bool = False, load_shr: Float64 = 0.0):
        reporting_constant = state.dataHVACGlobal.TimeStepSys * Constant.iSecsInHour
        self.recoveredEnergyRate = 0.0
        self.NormalSHR = 0.0

        self.calculate(state, inlet_node, outlet_node, speed_num, speed_ratio, fan_op_mode, cond_inlet_node, cond_outlet_node)
        self.OperatingMode = 1

        self.basinHeaterPower *= (1.0 - self.RTF)
        self.electricityConsumption = self.powerUse * reporting_constant

        if self.compressorFuelType.value != eFuel.Electricity.value:
            self.compressorFuelRate = self.powerUse
            self.compressorFuelConsumption = self.electricityConsumption
            self.powerUse = 0.0
            self.electricityConsumption = 0.0

    fn calculate(inout self, state: EnergyPlusData, inlet_node: NodeData, outlet_node: inout NodeData,
                 speed_num: Int, ratio: Float64, fan_op_mode: FanOp,
                 cond_inlet_node: NodeData, cond_outlet_node: inout NodeData):

        this_speed = max(speed_num, 1)
        self.wasteHeatRate = 0

        air_mass_flow_rate = inlet_node.MassFlowRate

        if fan_op_mode.value == FanOp.Cycling.value and this_speed == 1:
            if ratio > 0.0:
                air_mass_flow_rate = inlet_node.MassFlowRate / ratio
            else:
                air_mass_flow_rate = 0.0

        if (this_speed == 1 and ratio == 0.0) or inlet_node.MassFlowRate == 0.0:
            outdoor_coil_dry_bulb_temperature_k = cond_inlet_node.Temp + Constant.Kelvin
            perf_result = self.representation.performance.performance_map_standby.calculate_performance(
                outdoor_coil_dry_bulb_temperature_k
            )
            self.powerUse = perf_result.gross_power
            self.RTF = 0
            self.set_output_node_conditions(state, inlet_node, outlet_node, 0.0, 0.0, air_mass_flow_rate)
            return

        is_continuous = self.representation.performance.compressor_speed_control_type.value == SpeedControlType.CONTINUOUS.value
        outdoor_coil_entering_dry_bulb_temperature_k = cond_inlet_node.Temp + Constant.Kelvin
        indoor_coil_entering_dry_bulb_temperature_k = inlet_node.Temp + Constant.Kelvin
        ambient_pressure = state.dataEnvrn.OutBaroPress
        indoor_coil_entering_relative_humidity = Psychrometrics.PsyRhFnTdbWPb(
            state, inlet_node.Temp, inlet_node.HumRat, ambient_pressure
        )

        if this_speed == 1:
            perf = self.representation.performance.performance_map_cooling.calculate_performance(
                outdoor_coil_entering_dry_bulb_temperature_k,
                indoor_coil_entering_relative_humidity,
                indoor_coil_entering_dry_bulb_temperature_k,
                air_mass_flow_rate,
                this_speed,
                ambient_pressure,
                self.interpolation_type
            )
            gross_total_capacity = perf.gross_total_capacity
            gross_sensible_capacity = perf.gross_sensible_capacity
            gross_power = perf.gross_power

            self.set_output_node_conditions(state, inlet_node, outlet_node, gross_total_capacity, gross_sensible_capacity, air_mass_flow_rate)
            self.calculate_cycling_capcacity(state, inlet_node, outlet_node, gross_power, ratio, fan_op_mode)

        else:
            self.RTF = 1.0
            if is_continuous:
                perf = self.representation.performance.performance_map_cooling.calculate_performance(
                    outdoor_coil_entering_dry_bulb_temperature_k,
                    indoor_coil_entering_relative_humidity,
                    indoor_coil_entering_dry_bulb_temperature_k,
                    air_mass_flow_rate,
                    this_speed - 1 + ratio,
                    ambient_pressure,
                    self.interpolation_type
                )
            else:
                mass_flow_rate_upperspeed = self.speeds[this_speed - 1].evaporator_air_mass_flow

                perf = self.representation.performance.performance_map_cooling.calculate_performance(
                    outdoor_coil_entering_dry_bulb_temperature_k,
                    indoor_coil_entering_relative_humidity,
                    indoor_coil_entering_dry_bulb_temperature_k,
                    mass_flow_rate_upperspeed,
                    this_speed,
                    ambient_pressure,
                    self.interpolation_type
                )
                gross_total_capacity = perf.gross_total_capacity
                gross_sensible_capacity = perf.gross_sensible_capacity
                gross_power = perf.gross_power

                self.set_output_node_conditions(state, inlet_node, outlet_node, gross_total_capacity, gross_sensible_capacity, mass_flow_rate_upperspeed)

                if ratio < 1.0:
                    lowerspeed = this_speed - 1
                    mass_flow_rate_lowerspeed = self.speeds[lowerspeed - 1].evaporator_air_mass_flow

                    perf_lower = self.representation.performance.performance_map_cooling.calculate_performance(
                        outdoor_coil_entering_dry_bulb_temperature_k,
                        indoor_coil_entering_relative_humidity,
                        indoor_coil_entering_dry_bulb_temperature_k,
                        mass_flow_rate_lowerspeed,
                        lowerspeed,
                        ambient_pressure,
                        self.interpolation_type
                    )
                    gross_capacity_lower_speed = perf_lower.gross_total_capacity
                    gross_sensible_capacity_lower_speed = perf_lower.gross_sensible_capacity
                    power_lower_speed = perf_lower.gross_power

                    upperspeed_outlet_humrat = outlet_node.HumRat
                    upperspeed_outlet_enthalpy = outlet_node.Enthalpy

                    self.set_output_node_conditions(
                        state, inlet_node, outlet_node, gross_capacity_lower_speed, gross_sensible_capacity_lower_speed, mass_flow_rate_lowerspeed
                    )

                    outlet_node.HumRat = (
                        (upperspeed_outlet_humrat * ratio * mass_flow_rate_upperspeed +
                         (1.0 - ratio) * outlet_node.HumRat * mass_flow_rate_lowerspeed) /
                        inlet_node.MassFlowRate
                    )
                    outlet_node.Enthalpy = (
                        (upperspeed_outlet_enthalpy * ratio * mass_flow_rate_upperspeed +
                         (1.0 - ratio) * outlet_node.Enthalpy * mass_flow_rate_lowerspeed) /
                        inlet_node.MassFlowRate
                    )
                    outlet_node.Temp = Psychrometrics.PsyTdbFnHW(outlet_node.Enthalpy, outlet_node.HumRat)

                    self.powerUse = ratio * gross_power + (1.0 - ratio) * power_lower_speed
                else:
                    self.powerUse = gross_power

    fn calculate_cycling_capcacity(inout self, state: EnergyPlusData, inlet_node: NodeData, outlet_node: inout NodeData,
                                    gross_power: Float64, ratio: Float64, fan_op_mode: FanOp):
        cd = self.representation.performance.cycling_degradation_coefficient
        part_load_factor = (1.0 - cd) + (cd * ratio)
        self.RTF = ratio / part_load_factor
        self.powerUse = gross_power * self.RTF

        if fan_op_mode.value == FanOp.Continuous.value:
            outlet_node.HumRat = outlet_node.HumRat * ratio + (1.0 - ratio) * inlet_node.HumRat
            outlet_node.Enthalpy = outlet_node.Enthalpy * ratio + (1.0 - ratio) * inlet_node.Enthalpy
            outlet_node.Temp = Psychrometrics.PsyTdbFnHW(outlet_node.Enthalpy, outlet_node.HumRat)

            tsat = Psychrometrics.PsyTsatFnHPb(state, outlet_node.Enthalpy, inlet_node.Press)
            if outlet_node.Temp < tsat:
                outlet_node.Temp = tsat
                outlet_node.HumRat = Psychrometrics.PsyWFnTdbH(state, tsat, outlet_node.Enthalpy)

    fn set_output_node_conditions(self, state: EnergyPlusData, inlet_node: NodeData, outlet_node: inout NodeData,
                                   gross_total_capacity: Float64, gross_sensible_capacity: Float64,
                                   air_mass_flow_rate: Float64):
        delta_enthalpy = 0.0 if air_mass_flow_rate == 0.0 else gross_total_capacity / air_mass_flow_rate
        outlet_node.Enthalpy = inlet_node.Enthalpy - delta_enthalpy

        cp_air = Psychrometrics.PsyCpAirFnW(inlet_node.HumRat)
        delta_temperature = 0.0 if air_mass_flow_rate == 0.0 else gross_sensible_capacity / air_mass_flow_rate / cp_air
        outlet_node.Temp = inlet_node.Temp - delta_temperature

        outlet_node.HumRat = Psychrometrics.PsyWFnTdbH(state, outlet_node.Temp, outlet_node.Enthalpy)

        outlet_node.Press = inlet_node.Press

    fn calculate_rated_capacities(self, state: EnergyPlusData, speed_index: Int) -> LookupVariablesCoolingStruct:
        indoor_coil_entering_relative_humidity = Psychrometrics.PsyRhFnTdbWPb(
            state,
            Self.indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin,
            self.rating_humidity_ratio,
            Self.reference_pressure_sea_level
        )

        max_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate[-1]

        lookup_variables = self.representation.performance.performance_map_cooling.calculate_performance(
            Self.outdoor_coil_entering_dry_bulb_temperature_K,
            indoor_coil_entering_relative_humidity,
            Self.indoor_coil_entering_dry_bulb_temperature_K,
            max_available_flow,
            self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number[speed_index],
            Self.reference_pressure_sea_level,
            self.interpolation_type
        )
        return lookup_variables

    fn calculate_air_mass_flow(inout self, state: EnergyPlusData, speed_index: Int):
        accuracy = 0.0001
        max_iter = 500
        sol_fla = DynamicVector[Int]()
        sol_fla.push_back(0)
        min_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate[0]
        max_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate[-1]
        iterated_mass_flow_rate = DynamicVector[Float64]()
        iterated_mass_flow_rate.push_back(1.0)

        fn f(available_mass_flow: Float64) -> Float64:
            gross_capacity = self.representation.performance.performance_map_cooling.calculate_performance(
                Self.outdoor_coil_entering_dry_bulb_temperature_K,
                self.rating_indoor_coil_entering_relative_humidity,
                Self.indoor_coil_entering_dry_bulb_temperature_K,
                available_mass_flow,
                self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number[speed_index],
                Self.reference_pressure_sea_level,
                self.interpolation_type
            ).gross_total_capacity

            available_volumetric_flow_cfm = 2118.88 * available_mass_flow / self.rating_rho_air
            capacity_tons = gross_capacity * 0.00028

            return Self.rating_flow - available_volumetric_flow_cfm / capacity_tons

        General.SolveRoot(state, accuracy, max_iter, sol_fla, iterated_mass_flow_rate, f, min_available_flow, max_available_flow)

        self.speeds[speed_index].evaporator_air_mass_flow = iterated_mass_flow_rate[0]
        self.speeds[speed_index].evaporator_air_volumetric_flow = iterated_mass_flow_rate[0] / self.rating_rho_air
