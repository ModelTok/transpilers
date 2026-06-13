from ..Coils.CoilCoolingDXPerformanceBase import CoilCoolingDXPerformanceBase
from ..DataGlobalConstants import Constant, eFuel
from ..DataLoopNode import NodeData
from ..EnergyPlus import EnergyPlusData
from ..CurveManager import CurveManager
from ..Data.EnergyPlusData import EnergyPlusData
from ..DataEnvironment import DataEnvironment
from ..DataHVACGlobals import HVACGlobals
from ..DataIPShortCuts import DataIPShortCut
from ..DataSystemVariables import DataSystemVariables
from ..EnergyPlusLogger import EnergyPlusLogger
from ..Fans import Fans
from ..General import SolveRoot
from ..GeneralRoutines import GeneralRoutines
from ..InputProcessing.InputProcessor import InputProcessor
from ..OutputReportPredefined import OutputReportPredefined
from ..Psychrometrics import PsyWFnTdbTwbPb, PsyRhFnTdbWPb, PsyCpAirFnW, PsyTdbFnHW, PsyTsatFnHPb
from ..ScheduleManager import ScheduleManager
from ..UtilityRoutines import ShowSevereError, ShowFatalError, SameString, makeUPPER
from rs0004 import RS0004, LookupVariablesCoolingStruct, SpeedControlType
from rs0004_factory import RSInstanceFactory, RS0004Factory
from Btwxt import InterpolationMethod
from Btwxt import Btwxt  // for interpolation type
import String
import Dict
import List
import Pointer
import Tuple
var InterpMethods: Dict[String, InterpolationMethod] = {
    "LINEAR": InterpolationMethod.linear,
    "CUBIC": InterpolationMethod.cubic,
}
struct CoilCoolingDX205Performance(CoilCoolingDXPerformanceBase):
    @static constant object_name: String = "Coil:DX:ASHRAE205:Performance"
    var representation: Pointer[RS0004]  // shared_ptr equivalent
    var logger_context: Tuple[Pointer[EnergyPlusData], String]
    var interpolation_type: InterpolationMethod = InterpolationMethod.linear
    var rated_total_cooling_capacity: Float64
    var rated_steady_state_heating_capacity: Float64
    struct CoilSpeedParameters:
        var evaporator_air_mass_flow: Float64
        var evaporator_air_volumetric_flow: Float64
    var speeds: List[CoilSpeedParameters]
    @static constant outdoor_coil_entering_dry_bulb_temperature_K: Float64 = 308.15  // 95F
    @static constant indoor_coil_entering_dry_bulb_temperature_K: Float64 = 299.82  // 80F
    @static constant reference_wb_temperature: Float64 = 292.59  // 67F
    @static constant reference_pressure_sea_level: Float64 = 101325.0
    @static constant rating_flow: Float64 = 400.0  // cfm/ton
    var rating_humidity_ratio: Float64 = 0.0
    var rating_indoor_coil_entering_relative_humidity: Float64 = 0.0
    var rating_rho_air: Float64 = 0.0
    var nominal_speed_index: Int = 0
    def __init__(inout self, state: Pointer[EnergyPlusData], name_to_find: String):
        let routineName: String = "CoilCoolingDX205Performance::CoilCoolingDX205Performance"
        RSInstanceFactory.register_factory("RS0004", RS0004Factory())
        var errorsFound: Bool = false
        state.dataIPShortCut.cCurrentModuleObject = CoilCoolingDX205Performance.object_name
        var ip: Pointer[InputProcessor] = state.dataInputProcessing.inputProcessor
        var numPerformances: Int = ip.getNumObjectsFound(state, CoilCoolingDX205Performance.object_name)
        if numPerformances <= 0:
            ShowSevereError(state, String.format("No {} equipment specified in input file", state.dataIPShortCut.cCurrentModuleObject))
            errorsFound = true
        var Coil205PerformanceInstances = ip.epJSON.find(state.dataIPShortCut.cCurrentModuleObject).value()
        var objectSchemaProps = ip.getObjectSchemaProps(state, state.dataIPShortCut.cCurrentModuleObject)
        for var instance in Coil205PerformanceInstances.items():
            let fields = instance.value()
            self.name = instance.key()
            if not SameString(name_to_find, self.name):
                ShowFatalError(state, String.format("Could not find Coil:Cooling:DX:Performance object with name: {}", name_to_find))
            let rep_file_name: String = ip.getAlphaFieldValue(fields, objectSchemaProps, "representation_file_name")
            var rep_file_path: String = DataSystemVariables.CheckForActualFilePath(state, String(rep_file_name), String(routineName))
            if len(rep_file_path) == 0:
                errorsFound = true
                ShowFatalError(state, "Program terminates due to the missing ASHRAE 205 RS0004 representation file.")
            var coil_logger: Pointer[EnergyPlusLogger] = Pointer[EnergyPlusLogger](EnergyPlusLogger())
            self.logger_context = (state, String.format("{} \"{}\"", state.dataIPShortCut.cCurrentModuleObject, name))
            coil_logger.set_message_context(&self.logger_context)
            self.representation = Pointer[RS0004](RSInstanceFactory.create("RS0004", rep_file_path.string().c_str(), coil_logger))
            if self.representation == None:
                ShowSevereError(state, String.format("{} is not an instance of an ASHRAE205 Coil.", rep_file_path.string()))
                errorsFound = true
            else:
                self.representation.performance.performance_map_cooling.get_logger().set_message_context(&self.logger_context)
                self.representation.performance.performance_map_standby.get_logger().set_message_context(&self.logger_context)
            self.interpolation_type = InterpMethods[makeUPPER(ip.getAlphaFieldValue(fields, objectSchemaProps, "performance_interpolation_method"))]
            self.compressorFuelType = eFuel.Electricity
            self.rating_humidity_ratio = PsyWFnTdbTwbPb(state,
                                                               indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin,
                                                               reference_wb_temperature - Constant.Kelvin,
                                                               reference_pressure_sea_level)
            self.rating_indoor_coil_entering_relative_humidity = PsyRhFnTdbWPb(
                state, indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin, rating_humidity_ratio, reference_pressure_sea_level)
            self.rating_rho_air = state.dataEnvrn.StdRhoAir
            self.speeds = List[CoilSpeedParameters]()
            self.speeds.resize(self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number.size())
            self.nominal_speed_index = len(self.speeds) - 1
            self.rated_total_cooling_capacity = self.ratedTotalCapacityAtSpeedIndex(state, self.nominal_speed_index)
            if errorsFound:
                ShowFatalError(state,
                               String.format("{} Errors found in getting {} input. Preceding condition(s) causes termination.",
                                           String(routineName),
                                           object_name))
    def calculate_rated_capacities(self, state: Pointer[EnergyPlusData], speed_index: Int) -> LookupVariablesCoolingStruct:
        var indoor_coil_entering_relative_humidity = PsyRhFnTdbWPb(
            state, indoor_coil_entering_dry_bulb_temperature_K - Constant.Kelvin, self.rating_humidity_ratio, reference_pressure_sea_level)
        var max_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate.back()
        var lookup_variables = self.representation.performance.performance_map_cooling.calculate_performance(
            outdoor_coil_entering_dry_bulb_temperature_K,
            indoor_coil_entering_relative_humidity,
            indoor_coil_entering_dry_bulb_temperature_K,
            max_available_flow,
            self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number[speed_index],
            reference_pressure_sea_level,
            self.interpolation_type)
        return lookup_variables
    def calculate_air_mass_flow(inout self, state: Pointer[EnergyPlusData], speed_index: Int):
        let accuracy: Float64 = 0.0001
        let maxIter: Int = 500
        var solFla: Int = 0
        var min_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate.front()
        var max_available_flow = self.representation.performance.performance_map_cooling.grid_variables.indoor_coil_air_mass_flow_rate.back()
        var iterated_mass_flow_rate: Float64 = 1.0
        var f = fn(available_mass_flow: Float64) -> Float64:
            var gross_capacity =
                self.representation.performance.performance_map_cooling
                    .calculate_performance(outdoor_coil_entering_dry_bulb_temperature_K,
                                           self.rating_indoor_coil_entering_relative_humidity,
                                           indoor_coil_entering_dry_bulb_temperature_K,
                                           available_mass_flow,
                                           self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number[speed_index],
                                           reference_pressure_sea_level,
                                           self.interpolation_type)
                    .gross_total_capacity
            var available_volumetric_flow_cfm = 2118.88 * available_mass_flow / self.rating_rho_air
            var capacity_tons = gross_capacity * 0.00028
            return self.rating_flow - available_volumetric_flow_cfm / capacity_tons
        SolveRoot(state, accuracy, maxIter, solFla, &iterated_mass_flow_rate, f, min_available_flow, max_available_flow)
        self.speeds[speed_index].evaporator_air_mass_flow = iterated_mass_flow_rate
        self.speeds[speed_index].evaporator_air_volumetric_flow = iterated_mass_flow_rate / self.rating_rho_air
    def size(inout self, state: Pointer[EnergyPlusData]):
        for var index in range(len(self.speeds)):
            self.calculate_air_mass_flow(state, index)
    def simulate(inout self,
                state: Pointer[EnergyPlusData],
                inletNode: NodeData,
                outletNode: Pointer[NodeData],
                coilMode: HVAC.CoilMode,
                speedNum: Int,
                speedRatio: Float64,
                fanOpMode: HVAC.FanOp,
                condInletNode: NodeData,
                condOutletNode: Pointer[NodeData],
                singleMode: Bool,
                LoadSHR: Float64 = 0.0):
        var reportingConstant = state.dataHVACGlobal.TimeStepSys * Constant.iSecsInHour
        self.recoveredEnergyRate = 0.0
        self.NormalSHR = 0.0
        self.calculate(state, inletNode, outletNode, speedNum, speedRatio, fanOpMode, condInletNode, condOutletNode)
        self.OperatingMode = 1
        self.basinHeaterPower *= (1.0 - self.RTF)
        self.electricityConsumption = self.powerUse * reportingConstant
        if self.compressorFuelType != eFuel.Electricity:
            self.compressorFuelRate = self.powerUse
            self.compressorFuelConsumption = self.electricityConsumption
            self.powerUse = 0.0
            self.electricityConsumption = 0.0
    def calculate(inout self,
                 state: Pointer[EnergyPlusData],
                 inletNode: NodeData,
                 outletNode: Pointer[NodeData],
                 speedNum: Int,
                 ratio: Float64,
                 fanOpMode: HVAC.FanOp,
                 condInletNode: NodeData,
                 condOutletNode: Pointer[NodeData]):
        var this_speed = max(speedNum, 1)
        self.wasteHeatRate = 0
        var air_mass_flow_rate = inletNode.MassFlowRate
        if fanOpMode == HVAC.FanOp.Cycling and this_speed == 1:
            if ratio > 0.0:
                air_mass_flow_rate = inletNode.MassFlowRate / ratio
            else:
                air_mass_flow_rate = 0.0
        if (this_speed == 1 and ratio == 0.0) or inletNode.MassFlowRate == 0.0:
            var outdoor_coil_dry_bulb_temperature_K = condInletNode.Temp + Constant.Kelvin
            self.powerUse = self.representation.performance.performance_map_standby.calculate_performance(outdoor_coil_dry_bulb_temperature_K).gross_power
            self.RTF = 0
            self.set_output_node_conditions(state, inletNode, outletNode, 0.0, 0.0, air_mass_flow_rate)
            return
        var is_continuous = self.representation.performance.compressor_speed_control_type == SpeedControlType.CONTINUOUS
        var outdoor_coil_entering_dry_bulb_temperature_K = condInletNode.Temp + Constant.Kelvin
        var indoor_coil_entering_dry_bulb_temperature_K = inletNode.Temp + Constant.Kelvin
        var ambient_pressure = state.dataEnvrn.OutBaroPress
        var indoor_coil_entering_relative_humidity = PsyRhFnTdbWPb(state, inletNode.Temp, inletNode.HumRat, ambient_pressure)
        if this_speed == 1:
            var (gross_total_capacity, gross_sensible_capacity, gross_power) =
                self.representation.performance.performance_map_cooling.calculate_performance(outdoor_coil_entering_dry_bulb_temperature_K,
                                                                                          indoor_coil_entering_relative_humidity,
                                                                                          indoor_coil_entering_dry_bulb_temperature_K,
                                                                                          air_mass_flow_rate,
                                                                                          this_speed,
                                                                                          ambient_pressure,
                                                                                          self.interpolation_type)
            self.set_output_node_conditions(state, inletNode, outletNode, gross_total_capacity, gross_sensible_capacity, air_mass_flow_rate)
            self.calculate_cycling_capcacity(state, inletNode, outletNode, gross_power, ratio, fanOpMode)
        else:
            self.RTF = 1.0
            if is_continuous:
                var (gross_total_capacity, gross_sensible_capacity, gross_power) =
                    self.representation.performance.performance_map_cooling.calculate_performance(outdoor_coil_entering_dry_bulb_temperature_K,
                                                                                              indoor_coil_entering_relative_humidity,
                                                                                              indoor_coil_entering_dry_bulb_temperature_K,
                                                                                              air_mass_flow_rate,
                                                                                              this_speed - 1 + ratio,
                                                                                              ambient_pressure,
                                                                                              self.interpolation_type)
            else:
                var mass_flow_rate_upperspeed = self.speeds[this_speed - 1].evaporator_air_mass_flow
                var (gross_total_capacity, gross_sensible_capacity, gross_power) =
                    self.representation.performance.performance_map_cooling.calculate_performance(outdoor_coil_entering_dry_bulb_temperature_K,
                                                                                              indoor_coil_entering_relative_humidity,
                                                                                              indoor_coil_entering_dry_bulb_temperature_K,
                                                                                              mass_flow_rate_upperspeed,
                                                                                              this_speed,
                                                                                              ambient_pressure,
                                                                                              self.interpolation_type)
                self.set_output_node_conditions(state, inletNode, outletNode, gross_total_capacity, gross_sensible_capacity, mass_flow_rate_upperspeed)
                if ratio < 1.0:
                    var lowerspeed = this_speed - 1
                    var mass_flow_rate_lowerspeed = self.speeds[lowerspeed - 1].evaporator_air_mass_flow
                    var (gross_capacity_lower_speed, gross_sensible_capacity_lower_speed, power_lower_speed) =
                        self.representation.performance.performance_map_cooling.calculate_performance(outdoor_coil_entering_dry_bulb_temperature_K,
                                                                                                  indoor_coil_entering_relative_humidity,
                                                                                                  indoor_coil_entering_dry_bulb_temperature_K,
                                                                                                  mass_flow_rate_lowerspeed,
                                                                                                  lowerspeed,
                                                                                                  ambient_pressure,
                                                                                                  self.interpolation_type)
                    var upperspeed_outlet_humrat = outletNode.HumRat
                    var upperspeed_outlet_enthalpy = outletNode.Enthalpy
                    self.set_output_node_conditions(
                        state, inletNode, outletNode, gross_capacity_lower_speed, gross_sensible_capacity_lower_speed, mass_flow_rate_lowerspeed)
                    outletNode.HumRat =
                        (upperspeed_outlet_humrat * ratio * mass_flow_rate_upperspeed + (1.0 - ratio) * outletNode.HumRat * mass_flow_rate_lowerspeed) /
                        inletNode.MassFlowRate
                    outletNode.Enthalpy = (upperspeed_outlet_enthalpy * ratio * mass_flow_rate_upperspeed +
                                           (1.0 - ratio) * outletNode.Enthalpy * mass_flow_rate_lowerspeed) /
                                          inletNode.MassFlowRate
                    outletNode.Temp = PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
                    self.powerUse = ratio * gross_power + (1.0 - ratio) * power_lower_speed
                else:
                    self.powerUse = gross_power
    def calculate_cycling_capcacity(inout self,
                                   state: Pointer[EnergyPlusData],
                                   inletNode: NodeData,
                                   outletNode: Pointer[NodeData],
                                   gross_power: Float64,
                                   ratio: Float64,
                                   fanOpMode: HVAC.FanOp):
        var cd = self.representation.performance.cycling_degradation_coefficient
        var part_load_factor = (1.0 - cd) + (cd * ratio)
        self.RTF = ratio / part_load_factor
        self.powerUse = gross_power * self.RTF
        if fanOpMode == HVAC.FanOp.Continuous:
            outletNode.HumRat = outletNode.HumRat * ratio + (1.0 - ratio) * inletNode.HumRat
            outletNode.Enthalpy = outletNode.Enthalpy * ratio + (1.0 - ratio) * inletNode.Enthalpy
            outletNode.Temp = PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
            var tsat = PsyTsatFnHPb(state, outletNode.Enthalpy, inletNode.Press)
            if outletNode.Temp < tsat:
                outletNode.Temp = tsat
                outletNode.HumRat = PsyWFnTdbH(state, tsat, outletNode.Enthalpy)
    def set_output_node_conditions(self,
                                   state: Pointer[EnergyPlusData],
                                   inletNode: NodeData,
                                   outletNode: Pointer[NodeData],
                                   gross_total_capacity: Float64,
                                   gross_sensible_capacity: Float64,
                                   air_mass_flow_rate: Float64) const:
        var delta_enthalpy = air_mass_flow_rate == 0.0 ? 0.0 : gross_total_capacity / air_mass_flow_rate
        outletNode.Enthalpy = inletNode.Enthalpy - delta_enthalpy
        var delta_temperature =
            air_mass_flow_rate == 0.0 ? 0.0 : gross_sensible_capacity / air_mass_flow_rate / PsyCpAirFnW(inletNode.HumRat)
        outletNode.Temp = inletNode.Temp - delta_temperature
        outletNode.HumRat = PsyWFnTdbH(state, outletNode.Temp, outletNode.Enthalpy)
        outletNode.Press = inletNode.Press
        return
    def grossRatedSHR(self, state: Pointer[EnergyPlusData]) -> Float64:
        var lookup_variables = self.calculate_rated_capacities(state, self.nominal_speed_index)
        return lookup_variables.gross_sensible_capacity / lookup_variables.gross_total_capacity
    def ratedTotalCapacityAtSpeedIndex(self, state: Pointer[EnergyPlusData], index: Int) -> Float64:
        return self.calculate_rated_capacities(state, index).gross_total_capacity
    def numSpeeds(self) -> Int:
        return len(self.representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number)
    def ratedCBF(self, state: Pointer[EnergyPlusData]) -> Float64:
        return 0.001
    def grossRatedSHR(self, state: Pointer[EnergyPlusData]) -> Float64:
        var lookup_variables = self.calculate_rated_capacities(state, self.nominal_speed_index)
        return lookup_variables.gross_sensible_capacity / lookup_variables.gross_total_capacity
    def evapAirFlowRateAtSpeedIndex(self, state: Pointer[EnergyPlusData], index: Int) -> Float64: // Volumetric
        return self.speeds[index].evaporator_air_volumetric_flow
    def ratedTotalCapacityAtSpeedIndex(self, state: Pointer[EnergyPlusData], index: Int) -> Float64:
        return self.calculate_rated_capacities(state, index).gross_total_capacity
    def ratedEvapAirMassFlowRate(self, state: Pointer[EnergyPlusData]) -> Float64:
        return self.speeds[self.nominal_speed_index].evaporator_air_mass_flow
    def ratedEvapAirFlowRate(self, state: Pointer[EnergyPlusData]) -> Float64:
        return self.evapAirFlowRateAtSpeedIndex(state, self.nominal_speed_index)
    def ratedGrossTotalCap(self) -> Float64:
        return self.rated_total_cooling_capacity