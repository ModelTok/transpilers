from typing import Protocol, Tuple, Optional, List, Callable, Dict, Any
from dataclasses import dataclass, field
from enum import Enum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): main simulation state object (EnergyPlus/Data/EnergyPlusData.hh)
# - Node.NodeData: node state with Temp, MassFlowRate, HumRat, Enthalpy, Press (EnergyPlus/DataLoopNode.hh)
# - HVAC.CoilMode, HVAC.FanOp: enums (EnergyPlus/DataHVACGlobals.hh)
# - Psychrometrics: functions (EnergyPlus/Psychrometrics.hh)
# - Constant.*: constants (EnergyPlus/DataGlobalConstants.hh)
# - tk205.rs0004_ns.RS0004: ASHRAE205 type (rs0004.h)
# - tk205.ashrae205_ns.SpeedControlType: enum
# - Btwxt.InterpolationMethod: enum
# - General.SolveRoot: root solver (EnergyPlus/General.hh)
# - ShowSevereError, ShowFatalError: logging (EnergyPlus/UtilityRoutines.hh)
# - Util.SameString, Util.makeUPPER: string utilities (EnergyPlus/UtilityRoutines.hh)
# - DataSystemVariables.CheckForActualFilePath: file path utility (EnergyPlus/DataSystemVariables.hh)
# - RSInstanceFactory: factory pattern for RS0004 creation (rs0004_factory.h)
# - EnergyPlusLogger: logging context (EnergyPlus/EnergyPlusLogger.hh)

class InterpolationMethod(Enum):
    linear = 0
    cubic = 1

class SpeedControlType(Enum):
    CONTINUOUS = 0
    DISCRETE = 1

class FanOp(Enum):
    Cycling = 0
    Continuous = 1

class eFuel(Enum):
    Electricity = 0

class Constant:
    Kelvin = 273.15
    iSecsInHour = 3600
    eFuel = eFuel

class NodeData(Protocol):
    Temp: float
    MassFlowRate: float
    HumRat: float
    Enthalpy: float
    Press: float

class DataEnvironment(Protocol):
    StdRhoAir: float
    OutBaroPress: float

class DataHVACGlobal(Protocol):
    TimeStepSys: float

class Psychrometrics:
    @staticmethod
    def PsyWFnTdbTwbPb(state: Any, tdb: float, twb: float, pb: float) -> float:
        pass

    @staticmethod
    def PsyRhFnTdbWPb(state: Any, tdb: float, w: float, pb: float) -> float:
        pass

    @staticmethod
    def PsyTdbFnHW(h: float, w: float) -> float:
        pass

    @staticmethod
    def PsyWFnTdbH(state: Any, tdb: float, h: float) -> float:
        pass

    @staticmethod
    def PsyTsatFnHPb(state: Any, h: float, pb: float) -> float:
        pass

    @staticmethod
    def PsyCpAirFnW(w: float) -> float:
        pass

class General:
    @staticmethod
    def SolveRoot(state: Any, accuracy: float, max_iter: int, sol_fla_ref: List[int],
                  x_ref: List[float], f: Callable[[float], float], x_min: float, x_max: float) -> None:
        pass

class LookupVariablesCoolingStruct:
    def __init__(self):
        self.gross_total_capacity = 0.0
        self.gross_sensible_capacity = 0.0
        self.gross_power = 0.0

class RS0004Performance:
    class GridVariables:
        compressor_sequence_number: List[float]
        indoor_coil_air_mass_flow_rate: List[float]

    class PerformanceMap:
        grid_variables: RS0004Performance.GridVariables

        def calculate_performance(self, tdb_outdoor: float, rh_indoor: float, tdb_indoor: float,
                                   mfr: float, comp_seq: float, pressure: float,
                                   interp_method: InterpolationMethod) -> LookupVariablesCoolingStruct:
            pass

        def get_logger(self) -> Any:
            pass

    performance_map_cooling: PerformanceMap
    performance_map_standby: PerformanceMap
    compressor_speed_control_type: SpeedControlType
    cycling_degradation_coefficient: float

class RS0004:
    performance: RS0004Performance

class EnergyPlusData(Protocol):
    dataEnvrn: DataEnvironment
    dataHVACGlobal: DataHVACGlobal

@dataclass
class CoilSpeedParameters:
    evaporator_air_mass_flow: float = 0.0
    evaporator_air_volumetric_flow: float = 0.0

class CoilCoolingDXPerformanceBase:
    pass

class CoilCoolingDX205Performance(CoilCoolingDXPerformanceBase):
    object_name = "Coil:DX:ASHRAE205:Performance"

    outdoor_coil_entering_dry_bulb_temperature_K = 308.15
    indoor_coil_entering_dry_bulb_temperature_K = 299.82
    reference_wb_temperature = 292.59
    reference_pressure_sea_level = 101325.0
    rating_flow = 400.0

    def __init__(self, state: EnergyPlusData, name_to_find: str):
        self.name = ""
        self.representation: Optional[RS0004] = None
        self.logger_context: Optional[Tuple[EnergyPlusData, str]] = None
        self.interpolation_type = InterpolationMethod.linear
        self.rated_total_cooling_capacity = 0.0
        self.rated_steady_state_heating_capacity = 0.0
        self.rating_humidity_ratio = 0.0
        self.rating_indoor_coil_entering_relative_humidity = 0.0
        self.rating_rho_air = 0.0
        self.nominal_speed_index = 0
        self.speeds: List[CoilSpeedParameters] = []
        self.compressorFuelType = Constant.eFuel.Electricity
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

        interp_methods = {
            "LINEAR": InterpolationMethod.linear,
            "CUBIC": InterpolationMethod.cubic
        }

        errors_found = False
        routine_name = "CoilCoolingDX205Performance::CoilCoolingDX205Performance"

        ip = state.dataInputProcessing.inputProcessor
        num_performances = ip.getNumObjectsFound(state, self.object_name)

        if num_performances <= 0:
            ShowSevereError(state, f"No {self.object_name} equipment specified in input file")
            errors_found = True

        coil_205_performance_instances = ip.epJSON.get(self.object_name, {})
        object_schema_props = ip.getObjectSchemaProps(state, self.object_name)

        for instance_key, fields in coil_205_performance_instances.items():
            self.name = instance_key

            if not Util.SameString(name_to_find, self.name):
                ShowFatalError(state, f"Could not find Coil:Cooling:DX:Performance object with name: {name_to_find}")

            rep_file_name = ip.getAlphaFieldValue(fields, object_schema_props, "representation_file_name")
            rep_file_path = DataSystemVariables.CheckForActualFilePath(state, rep_file_name, routine_name)

            if not rep_file_path:
                errors_found = True
                ShowFatalError(state, "Program terminates due to the missing ASHRAE 205 RS0004 representation file.")

            coil_logger = EnergyPlusLogger()
            self.logger_context = (state, f"{self.object_name} \"{self.name}\"")
            coil_logger.set_message_context(self.logger_context)

            self.representation = RSInstanceFactory.create("RS0004", rep_file_path, coil_logger)

            if self.representation is None:
                ShowSevereError(state, f"{rep_file_path} is not an instance of an ASHRAE205 Coil.")
                errors_found = True
            else:
                self.representation.performance.performance_map_cooling.get_logger().set_message_context(self.logger_context)
                self.representation.performance.performance_map_standby.get_logger().set_message_context(self.logger_context)

            interp_method_str = ip.getAlphaFieldValue(fields, object_schema_props, "performance_interpolation_method")
            self.interpolation_type = interp_methods.get(Util.makeUPPER(interp_method_str), InterpolationMethod.linear)

            self.compressorFuelType = Constant.eFuel.Electricity

            self.rating_humidity_ratio = Psychrometrics.PsyWFnTdbTwbPb(
                state,
                self.indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin,
                self.reference_wb_temperature - Constant.Kelvin,
                self.reference_pressure_sea_level
            )

            self.rating_indoor_coil_entering_relative_humidity = Psychrometrics.PsyRhFnTdbWPb(
                state,
                self.indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin,
                self.rating_humidity_ratio,
                self.reference_pressure_sea_level
            )

            self.rating_rho_air = state.dataEnvrn.StdRhoAir

            num_speeds = len(self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number)
            self.speeds = [CoilSpeedParameters() for _ in range(num_speeds)]
            self.nominal_speed_index = len(self.speeds) - 1
            self.rated_total_cooling_capacity = self.ratedTotalCapacityAtSpeedIndex(state, self.nominal_speed_index)

            if errors_found:
                ShowFatalError(state, f"{routine_name} Errors found in getting {self.object_name} input. Preceding condition(s) causes termination.")

    def num_speeds(self) -> int:
        return len(self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number)

    def rated_cbf(self, state: EnergyPlusData) -> float:
        return 0.001

    def gross_rated_shr(self, state: EnergyPlusData) -> float:
        lookup_variables = self.calculate_rated_capacities(state, self.nominal_speed_index)
        return lookup_variables.gross_sensible_capacity / lookup_variables.gross_total_capacity

    def evap_air_flow_rate_at_speed_index(self, state: EnergyPlusData, index: int) -> float:
        return self.speeds[index].evaporator_air_volumetric_flow

    def ratedTotalCapacityAtSpeedIndex(self, state: EnergyPlusData, index: int) -> float:
        return self.calculate_rated_capacities(state, index).gross_total_capacity

    def rated_evap_air_mass_flow_rate(self, state: EnergyPlusData) -> float:
        return self.speeds[self.nominal_speed_index].evaporator_air_mass_flow

    def rated_evap_air_flow_rate(self, state: EnergyPlusData) -> float:
        return self.evap_air_flow_rate_at_speed_index(state, self.nominal_speed_index)

    def rated_gross_total_cap(self) -> float:
        return self.rated_total_cooling_capacity

    def size(self, state: EnergyPlusData):
        for index in range(len(self.speeds)):
            self.calculate_air_mass_flow(state, index)

    def simulate(self, state: EnergyPlusData, inlet_node: NodeData, outlet_node: NodeData,
                 coil_mode: Any, speed_num: int, speed_ratio: float, fan_op_mode: FanOp,
                 cond_inlet_node: NodeData, cond_outlet_node: NodeData,
                 single_mode: bool = False, load_shr: float = 0.0):
        reporting_constant = state.dataHVACGlobal.TimeStepSys * Constant.iSecsInHour
        self.recoveredEnergyRate = 0.0
        self.NormalSHR = 0.0

        self.calculate(state, inlet_node, outlet_node, speed_num, speed_ratio, fan_op_mode, cond_inlet_node, cond_outlet_node)
        self.OperatingMode = 1

        self.basinHeaterPower *= (1.0 - self.RTF)
        self.electricityConsumption = self.powerUse * reporting_constant

        if self.compressorFuelType != Constant.eFuel.Electricity:
            self.compressorFuelRate = self.powerUse
            self.compressorFuelConsumption = self.electricityConsumption
            self.powerUse = 0.0
            self.electricityConsumption = 0.0

    def calculate(self, state: EnergyPlusData, inlet_node: NodeData, outlet_node: NodeData,
                  speed_num: int, ratio: float, fan_op_mode: FanOp,
                  cond_inlet_node: NodeData, cond_outlet_node: NodeData):

        this_speed = max(speed_num, 1)
        self.wasteHeatRate = 0

        air_mass_flow_rate = inlet_node.MassFlowRate

        if fan_op_mode == FanOp.Cycling and this_speed == 1:
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

        is_continuous = self.representation.performance.compressor_speed_control_type == SpeedControlType.CONTINUOUS
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

    def calculate_cycling_capcacity(self, state: EnergyPlusData, inlet_node: NodeData, outlet_node: NodeData,
                                    gross_power: float, ratio: float, fan_op_mode: FanOp):
        cd = self.representation.performance.cycling_degradation_coefficient
        part_load_factor = (1.0 - cd) + (cd * ratio)
        self.RTF = ratio / part_load_factor
        self.powerUse = gross_power * self.RTF

        if fan_op_mode == FanOp.Continuous:
            outlet_node.HumRat = outlet_node.HumRat * ratio + (1.0 - ratio) * inlet_node.HumRat
            outlet_node.Enthalpy = outlet_node.Enthalpy * ratio + (1.0 - ratio) * inlet_node.Enthalpy
            outlet_node.Temp = Psychrometrics.PsyTdbFnHW(outlet_node.Enthalpy, outlet_node.HumRat)

            tsat = Psychrometrics.PsyTsatFnHPb(state, outlet_node.Enthalpy, inlet_node.Press)
            if outlet_node.Temp < tsat:
                outlet_node.Temp = tsat
                outlet_node.HumRat = Psychrometrics.PsyWFnTdbH(state, tsat, outlet_node.Enthalpy)

    def set_output_node_conditions(self, state: EnergyPlusData, inlet_node: NodeData, outlet_node: NodeData,
                                   gross_total_capacity: float, gross_sensible_capacity: float,
                                   air_mass_flow_rate: float):
        delta_enthalpy = 0.0 if air_mass_flow_rate == 0.0 else gross_total_capacity / air_mass_flow_rate
        outlet_node.Enthalpy = inlet_node.Enthalpy - delta_enthalpy

        cp_air = Psychrometrics.PsyCpAirFnW(inlet_node.HumRat)
        delta_temperature = 0.0 if air_mass_flow_rate == 0.0 else gross_sensible_capacity / air_mass_flow_rate / cp_air
        outlet_node.Temp = inlet_node.Temp - delta_temperature

        outlet_node.HumRat = Psychrometrics.PsyWFnTdbH(state, outlet_node.Temp, outlet_node.Enthalpy)

        outlet_node.Press = inlet_node.Press

    def calculate_rated_capacities(self, state: EnergyPlusData, speed_index: int) -> LookupVariablesCoolingStruct:
        indoor_coil_entering_relative_humidity = Psychrometrics.PsyRhFnTdbWPb(
            state,
            self.indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin,
            self.rating_humidity_ratio,
            self.reference_pressure_sea_level
        )

        max_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate[-1]

        lookup_variables = self.representation.performance.performance_map_cooling.calculate_performance(
            self.outdoor_coil_entering_dry_bulb_temperature_K,
            indoor_coil_entering_relative_humidity,
            self.indoor_coil_entering_dry_bulb_temperature_K,
            max_available_flow,
            self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number[speed_index],
            self.reference_pressure_sea_level,
            self.interpolation_type
        )
        return lookup_variables

    def calculate_air_mass_flow(self, state: EnergyPlusData, speed_index: int):
        accuracy = 0.0001
        max_iter = 500
        sol_fla = [0]
        min_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate[0]
        max_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate[-1]
        iterated_mass_flow_rate = [1.0]

        def f(available_mass_flow: float) -> float:
            gross_capacity = self.representation.performance.performance_map_cooling.calculate_performance(
                self.outdoor_coil_entering_dry_bulb_temperature_K,
                self.rating_indoor_coil_entering_relative_humidity,
                self.indoor_coil_entering_dry_bulb_temperature_K,
                available_mass_flow,
                self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number[speed_index],
                self.reference_pressure_sea_level,
                self.interpolation_type
            ).gross_total_capacity

            available_volumetric_flow_cfm = 2118.88 * available_mass_flow / self.rating_rho_air
            capacity_tons = gross_capacity * 0.00028

            return self.rating_flow - available_volumetric_flow_cfm / capacity_tons

        General.SolveRoot(state, accuracy, max_iter, sol_fla, iterated_mass_flow_rate, f, min_available_flow, max_available_flow)

        self.speeds[speed_index].evaporator_air_mass_flow = iterated_mass_flow_rate[0]
        self.speeds[speed_index].evaporator_air_volumetric_flow = iterated_mass_flow_rate[0] / self.rating_rho_air


class Util:
    @staticmethod
    def SameString(a: str, b: str) -> bool:
        return a.lower() == b.lower()

    @staticmethod
    def makeUPPER(s: str) -> str:
        return s.upper()


class DataSystemVariables:
    @staticmethod
    def CheckForActualFilePath(state: Any, file_path: str, routine_name: str) -> str:
        pass


class RSInstanceFactory:
    @staticmethod
    def create(rs_type: str, file_path: str, logger: Any) -> Optional[RS0004]:
        pass


class EnergyPlusLogger:
    def set_message_context(self, context: Any) -> None:
        pass


def ShowSevereError(state: Any, message: str) -> None:
    pass


def ShowFatalError(state: Any, message: str) -> None:
    pass
