from DataHVACGlobals import *
from DataLoopNode import *
from . import *
from Optional import Optional
from Autosizing.CoolingAirFlowSizing import CoolingAirFlowSizer
from Autosizing.CoolingCapacitySizing import CoolingCapacitySizer
from Autosizing.CoolingSHRSizing import CoolingSHRSizer
from CurveManager import Curve
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DataPrecisionGlobals import DataPrecisionGlobals
from DataSizing import DataSizing
from General import General
from InputProcessing.InputProcessor import InputProcessor
from Psychrometrics import Psychrometrics
struct CoilCoolingDXCurveFitSpeedInputSpecification:
    var name: String
    var gross_rated_total_cooling_capacity_ratio_to_nominal: Float64
    var gross_rated_sensible_heat_ratio: Float64
    var gross_rated_cooling_COP: Float64
    var evaporator_air_flow_fraction: Float64
    var condenser_air_flow_fraction: Float64
    var active_fraction_of_coil_face_area: Float64
    var rated_evaporative_condenser_pump_power_fraction: Float64
    var rated_evaporator_fan_power_per_volume_flow_rate: Float64
    var rated_evaporator_fan_power_per_volume_flow_rate_2023: Float64
    var evaporative_condenser_effectiveness: Float64
    var total_cooling_capacity_function_of_temperature_curve_name: String
    var total_cooling_capacity_function_of_air_flow_fraction_curve_name: String
    var energy_input_ratio_function_of_temperature_curve_name: String
    var energy_input_ratio_function_of_air_flow_fraction_curve_name: String
    var part_load_fraction_correlation_curve_name: String
    var rated_waste_heat_fraction_of_power_input: Float64
    var waste_heat_function_of_temperature_curve_name: String
    var sensible_heat_ratio_modifier_function_of_temperature_curve_name: String
    var sensible_heat_ratio_modifier_function_of_flow_fraction_curve_name: String
struct CoilCoolingDXCurveFitSpeed:
    var object_name: String = "Coil:Cooling:DX:CurveFit:Speed"
    var parentName: String
    var original_input_specs: CoilCoolingDXCurveFitSpeedInputSpecification
    var indexCapFT: Int = 0
    var indexCapFFF: Int = 0
    var indexEIRFT: Int = 0
    var indexEIRFFF: Int = 0
    var indexPLRFPLF: Int = 0
    var indexWHFT: Int = 0
    var indexSHRFT: Int = 0
    var indexSHRFFF: Int = 0
    var name: String
    var RatedAirMassFlowRate: Float64 = 0.0     # rated air mass flow rate at speed {kg/s}
    var RatedCondAirMassFlowRate: Float64 = 0.0 # rated condenser air mass flow rate at speed {kg/s}
    var grossRatedSHR: Float64 = 0.0            # rated sensible heat ratio at speed
    var ratedGrossTotalCapIsAutosized: Bool = false
    var ratedEvapAirFlowRateIsAutosized: Bool = false
    var RatedCBF: Float64 = 0.0 # rated coil bypass factor at speed
    var RatedEIR: Float64 = 0.0 # rated energy input ratio at speed {W/W}
    var ratedCOP: Float64 = 0.0
    var rated_total_capacity: Float64 = 0.0
    var rated_evap_fan_power_per_volume_flow_rate: Float64 = 0.0
    var rated_evap_fan_power_per_volume_flow_rate_2023: Float64 = 0.0
    var ratedWasteHeatFractionOfPowerInput: Float64 = 0.0 # rated waste heat fraction of power input
    var evap_condenser_pump_power_fraction: Float64 = 0.0
    var evap_condenser_effectiveness: Float64 = 0.0
    var parentModeRatedGrossTotalCap: Float64 = 0.0   # [W]
    var parentModeRatedEvapAirFlowRate: Float64 = 0.0 # [m3/s]
    var parentModeRatedCondAirFlowRate: Float64 = 0.0 # [m3/s]
    var parentOperatingMode: Int = 0
    var parentModeTimeForCondensateRemoval: Float64 = 0.0
    var parentModeEvapRateRatio: Float64 = 0.0
    var parentModeMaxCyclingRate: Float64 = 0.0
    var parentModeLatentTimeConst: Float64 = 0.0
    var doLatentDegradation: Bool = false # True if latent degradation is enabled for this speed
    var ambPressure: Float64 = 0.0 # outdoor pressure {Pa]
    var PLR: Float64 = 0.0
    var AirFF: Float64 = 0.0                   # ratio of air mass flow rate to rated air mass flow rate
    var fullLoadPower: Float64 = 0.0           # full load power at speed {W}
    var fullLoadWasteHeat: Float64 = 0.0       # full load waste heat at speed {W}
    var RTF: Float64 = 0.0                     # coil runtime fraction at speed
    var AirMassFlow: Float64 = 0.0             # coil inlet air mass flow rate {kg/s}
    var evap_air_flow_rate: Float64 = 0.0      # evaporator air volume flow rate [m3/s]
    var condenser_air_flow_rate: Float64 = 0.0 # condenser air volume flow rate [m3/s]
    var active_fraction_of_face_coil_area: Float64 = 0.0
    var adjustForFaceArea: Bool = false
    var ratedLatentCapacity: Float64 = 0.0 # Latent capacity at rated conditions {W}
    var RatedInletAirTemp: Float64 = 26.6667        # 26.6667C or 80F
    var RatedInletWetBulbTemp: Float64 = 19.4444    # 19.44 or 67F
    var RatedInletAirHumRat: Float64 = 0.0111847    # Humidity ratio corresponding to 80F dry bulb/67F wet bulb
    var RatedOutdoorAirTemp: Float64 = 35.0         # 35 C or 95F
    var DryCoilOutletHumRatioMin: Float64 = 0.00001 # dry coil outlet minimum hum ratio kgH2O/kgdry air
    var minRatedVolFlowPerRatedTotCap: Float64 = HVAC.MinRatedVolFlowPerRatedTotCap1
    var maxRatedVolFlowPerRatedTotCap: Float64 = HVAC.MaxRatedVolFlowPerRatedTotCap1
    def __init__(inout self, state: EnergyPlusData, name_to_find: String):
        self.indexCapFT = 0
        self.indexCapFFF = 0
        self.indexEIRFT = 0
        self.indexEIRFFF = 0
        self.indexPLRFPLF = 0
        self.indexWHFT = 0
        self.indexSHRFT = 0
        self.indexSHRFFF = 0
        self.RatedAirMassFlowRate = 0.0
        self.RatedCondAirMassFlowRate = 0.0
        self.grossRatedSHR = 0.0
        self.RatedCBF = 0.0
        self.RatedEIR = 0.0
        self.ratedCOP = 0.0
        self.rated_total_capacity = 0.0
        self.rated_evap_fan_power_per_volume_flow_rate = 0.0
        self.ratedWasteHeatFractionOfPowerInput = 0.0
        self.evap_condenser_pump_power_fraction = 0.0
        self.evap_condenser_effectiveness = 0.0
        self.parentModeRatedGrossTotalCap = 0.0
        self.parentModeRatedEvapAirFlowRate = 0.0
        self.parentModeRatedCondAirFlowRate = 0.0
        self.parentOperatingMode = 0
        self.ambPressure = 0.0
        self.PLR = 0.0
        self.AirFF = 0.0
        self.fullLoadPower = 0.0
        self.fullLoadWasteHeat = 0.0
        self.RTF = 0.0
        self.AirMassFlow = 0.0
        self.evap_air_flow_rate = 0.0
        self.condenser_air_flow_rate = 0.0
        self.active_fraction_of_face_coil_area = 0.0
        self.ratedLatentCapacity = 0.0
        self.RatedInletAirTemp = 26.6667
        self.RatedInletWetBulbTemp = 19.4444
        self.RatedInletAirHumRat = 0.0111847
        self.RatedOutdoorAirTemp = 35.0
        self.DryCoilOutletHumRatioMin = 0.00001
        var inputProcessor = state.dataInputProcessing.inputProcessor
        var speedInstances = inputProcessor.epJSON.find(CoilCoolingDXCurveFitSpeed.object_name)
        if speedInstances == inputProcessor.epJSON.end():

        var speedSchemaProps = inputProcessor.getObjectSchemaProps(state, CoilCoolingDXCurveFitSpeed.object_name)
        var found_it: Bool = false
        for speedInstance in speedInstances.value().items():
            var speedName = Util.makeUPPER(speedInstance.key())
            var speedFields = speedInstance.value()
            if not Util.SameString(name_to_find, speedName):
                continue
            found_it = true
            var input_specs = CoilCoolingDXCurveFitSpeedInputSpecification()
            input_specs.name = speedName
            input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "gross_total_cooling_capacity_fraction")
            input_specs.evaporator_air_flow_fraction = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "evaporator_air_flow_rate_fraction")
            input_specs.condenser_air_flow_fraction = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "condenser_air_flow_rate_fraction")
            input_specs.gross_rated_sensible_heat_ratio = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "gross_sensible_heat_ratio")
            input_specs.gross_rated_cooling_COP = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "gross_cooling_cop")
            input_specs.active_fraction_of_coil_face_area = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "active_fraction_of_coil_face_area")
            input_specs.rated_evaporator_fan_power_per_volume_flow_rate = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "2017_rated_evaporator_fan_power_per_volume_flow_rate")
            input_specs.rated_evaporator_fan_power_per_volume_flow_rate_2023 = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "2023_rated_evaporator_fan_power_per_volume_flow_rate")
            input_specs.rated_evaporative_condenser_pump_power_fraction = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "evaporative_condenser_pump_power_fraction")
            input_specs.evaporative_condenser_effectiveness = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "evaporative_condenser_effectiveness")
            input_specs.total_cooling_capacity_function_of_temperature_curve_name = inputProcessor.getAlphaFieldValue(speedFields, speedSchemaProps, "total_cooling_capacity_modifier_function_of_temperature_curve_name")
            input_specs.total_cooling_capacity_function_of_air_flow_fraction_curve_name = inputProcessor.getAlphaFieldValue(speedFields, speedSchemaProps, "total_cooling_capacity_modifier_function_of_air_flow_fraction_curve_name")
            input_specs.energy_input_ratio_function_of_temperature_curve_name = inputProcessor.getAlphaFieldValue(speedFields, speedSchemaProps, "energy_input_ratio_modifier_function_of_temperature_curve_name")
            input_specs.energy_input_ratio_function_of_air_flow_fraction_curve_name = inputProcessor.getAlphaFieldValue(speedFields, speedSchemaProps, "energy_input_ratio_modifier_function_of_air_flow_fraction_curve_name")
            input_specs.part_load_fraction_correlation_curve_name = inputProcessor.getAlphaFieldValue(speedFields, speedSchemaProps, "part_load_fraction_correlation_curve_name")
            input_specs.rated_waste_heat_fraction_of_power_input = inputProcessor.getRealFieldValue(speedFields, speedSchemaProps, "rated_waste_heat_fraction_of_power_input")
            input_specs.waste_heat_function_of_temperature_curve_name = inputProcessor.getAlphaFieldValue(speedFields, speedSchemaProps, "waste_heat_modifier_function_of_temperature_curve_name")
            input_specs.sensible_heat_ratio_modifier_function_of_temperature_curve_name = inputProcessor.getAlphaFieldValue(speedFields, speedSchemaProps, "sensible_heat_ratio_modifier_function_of_temperature_curve_name")
            input_specs.sensible_heat_ratio_modifier_function_of_flow_fraction_curve_name = inputProcessor.getAlphaFieldValue(speedFields, speedSchemaProps, "sensible_heat_ratio_modifier_function_of_flow_fraction_curve_name")
            self.instantiateFromInputSpec(state, input_specs)
            inputProcessor.markObjectAsUsed(CoilCoolingDXCurveFitSpeed.object_name, speedInstance.key())
            break
        if not found_it:
            ShowFatalError(state, "Could not find Coil:Cooling:DX:CurveFit:Speed object with name: " + name_to_find)
    def instantiateFromInputSpec(inout self, state: EnergyPlusData, input_data: CoilCoolingDXCurveFitSpeedInputSpecification):
        var errorsFound: Bool = false
        let routineName: StringLiteral = "CoilCoolingDXCurveFitSpeed::instantiateFromInputSpec: "
        let fieldName: StringLiteral = "Part Load Fraction Correlation Curve Name"
        self.original_input_specs = input_data
        self.name = input_data.name
        self.active_fraction_of_face_coil_area = input_data.active_fraction_of_coil_face_area
        if self.active_fraction_of_face_coil_area < 1.0:
            self.adjustForFaceArea = true
        self.rated_evap_fan_power_per_volume_flow_rate = input_data.rated_evaporator_fan_power_per_volume_flow_rate
        self.rated_evap_fan_power_per_volume_flow_rate_2023 = input_data.rated_evaporator_fan_power_per_volume_flow_rate_2023
        self.evap_condenser_pump_power_fraction = input_data.rated_evaporative_condenser_pump_power_fraction
        self.evap_condenser_effectiveness = input_data.evaporative_condenser_effectiveness
        self.ratedWasteHeatFractionOfPowerInput = input_data.rated_waste_heat_fraction_of_power_input
        self.ratedCOP = input_data.gross_rated_cooling_COP
        errorsFound |= self.processCurve(state,
                                          input_data.total_cooling_capacity_function_of_temperature_curve_name,
                                          self.indexCapFT,
                                          [1, 2],
                                          routineName,
                                          "Total Cooling Capacity Function of Temperature Curve Name",
                                          self.RatedInletWetBulbTemp,
                                          self.RatedOutdoorAirTemp)
        errorsFound |= self.processCurve(state,
                                          input_data.total_cooling_capacity_function_of_air_flow_fraction_curve_name,
                                          self.indexCapFFF,
                                          [1],
                                          routineName,
                                          "Total Cooling Capacity Function of Air Flow Fraction Curve Name",
                                          1.0)
        errorsFound |= self.processCurve(state,
                                          input_data.energy_input_ratio_function_of_temperature_curve_name,
                                          self.indexEIRFT,
                                          [1, 2],
                                          routineName,
                                          "Energy Input Ratio Function of Temperature Curve Name",
                                          self.RatedInletWetBulbTemp,
                                          self.RatedOutdoorAirTemp)
        errorsFound |= self.processCurve(state,
                                          input_data.energy_input_ratio_function_of_air_flow_fraction_curve_name,
                                          self.indexEIRFFF,
                                          [1],
                                          routineName,
                                          "Energy Input Ratio Function of Air Flow Fraction Curve Name",
                                          1.0)
        errorsFound |= self.processCurve(state,
                                          input_data.sensible_heat_ratio_modifier_function_of_temperature_curve_name,
                                          self.indexSHRFT,
                                          [2],
                                          routineName,
                                          "Sensible Heat Ratio Modifier Function of Temperature Curve Name",
                                          self.RatedInletWetBulbTemp,
                                          self.RatedOutdoorAirTemp)
        errorsFound |= self.processCurve(state,
                                          input_data.sensible_heat_ratio_modifier_function_of_flow_fraction_curve_name,
                                          self.indexSHRFFF,
                                          [1],
                                          routineName,
                                          "Sensible Heat Ratio Modifier Function of Air Flow Fraction Curve Name",
                                          1.0)
        errorsFound |= self.processCurve(state,
                                          input_data.waste_heat_function_of_temperature_curve_name,
                                          self.indexWHFT,
                                          [2],
                                          routineName,
                                          "Waste Heat Modifier Function of Temperature Curve Name",
                                          self.RatedOutdoorAirTemp,
                                          self.RatedInletAirTemp)
        if not errorsFound and not input_data.waste_heat_function_of_temperature_curve_name.empty():
            var CurveVal: Float64 = Curve.CurveValue(state, self.indexWHFT, self.RatedOutdoorAirTemp, self.RatedInletAirTemp)
            if CurveVal > 1.10 or CurveVal < 0.90:
                ShowWarningError(state, String(routineName) + self.object_name + "=\"" + self.name + "\", curve values")
                ShowContinueError(state,
                                  "Waste Heat Modifier Function of Temperature Curve Name = " + input_data.waste_heat_function_of_temperature_curve_name)
                ShowContinueError(
                    state, "...Waste Heat Modifier Function of Temperature Curve Name output is not equal to 1.0 (+ or - 10%) at rated conditions.")
                ShowContinueError(state, format("...Curve output at rated conditions = {:.3f}", CurveVal))
        errorsFound |= self.processCurve(state,
                                          input_data.part_load_fraction_correlation_curve_name,
                                          self.indexPLRFPLF,
                                          [1],
                                          routineName,
                                          "Part Load Fraction Correlation Curve Name",
                                          1.0)
        if self.indexPLRFPLF > 0 and not errorsFound:
            var MinCurveVal: Float64 = 999.0
            var MaxCurveVal: Float64 = -999.0
            var CurveInput: Float64 = 0.0
            var MinCurvePLR: Float64 = 0.0
            var MaxCurvePLR: Float64 = 0.0
            while CurveInput <= 1.0:
                var CurveVal: Float64 = Curve.CurveValue(state, self.indexPLRFPLF, CurveInput)
                if CurveVal < MinCurveVal:
                    MinCurveVal = CurveVal
                    MinCurvePLR = CurveInput
                if CurveVal > MaxCurveVal:
                    MaxCurveVal = CurveVal
                    MaxCurvePLR = CurveInput
                CurveInput += 0.01
            if MinCurveVal < 0.7:
                ShowWarningError(state, format("{}{}=\"{}\", invalid", routineName, self.object_name, self.name))
                ShowContinueError(state,
                                  format("...{}=\"{}\" has out of range value.", fieldName, input_data.part_load_fraction_correlation_curve_name))
                ShowContinueError(state, format("...Curve minimum must be >= 0.7, curve min at PLR = {:.2f} is {:.3f}", MinCurvePLR, MinCurveVal))
                ShowContinueError(state, "...Setting curve minimum to 0.7 and simulation continues.")
                Curve.SetCurveOutputMinValue(state, self.indexPLRFPLF, errorsFound, 0.7)
            if MaxCurveVal > 1.0:
                ShowWarningError(state, format("{}{}=\"{}\", invalid", routineName, self.object_name, self.name))
                ShowContinueError(state,
                                  format("...{}=\"{}\" has out of range value.", fieldName, input_data.part_load_fraction_correlation_curve_name))
                ShowContinueError(state, format("...Curve maximum must be <= 1.0, curve max at PLR = {:.2f} is {:.3f}", MaxCurvePLR, MaxCurveVal))
                ShowContinueError(state, "...Setting curve maximum to 1.0 and simulation continues.")
                Curve.SetCurveOutputMaxValue(state, self.indexPLRFPLF, errorsFound, 1.0)
        if errorsFound:
            ShowFatalError(
                state, String(routineName) + "Errors found in getting " + self.object_name + " input. Preceding condition(s) causes termination.")
    def processCurve(inout self, state: EnergyPlusData, curveName: String, inout curveIndex: Int, validDims: List[Int], routineName: StringLiteral, fieldName: String, Var1: Float64, Var2: Optional[Float64] = None) -> Bool:
        if curveName.empty():
            return False
        curveIndex = Curve.GetCurveIndex(state, curveName)
        if curveIndex == 0:
            ShowSevereError(state, String(routineName) + self.object_name + "=\"" + self.name + "\", invalid")
            ShowContinueError(state, "...not found " + fieldName + "=\"" + curveName + "\".")
            return True
        var errorFound: Bool = Curve.CheckCurveDims(state,
                                                    curveIndex,
                                                    validDims,
                                                    routineName,
                                                    self.object_name,
                                                    self.name,
                                                    fieldName)
        if not errorFound:
            if Var2 is not None:
                Curve.checkCurveIsNormalizedToOne(
                    state, String(routineName) + self.object_name, self.name, curveIndex, fieldName, curveName, Var1, Var2.value())
            else:
                Curve.checkCurveIsNormalizedToOne(
                    state, String(routineName) + self.object_name, self.name, curveIndex, fieldName, curveName, Var1)
        return errorFound
    def size(inout self, state: EnergyPlusData):
        let RoutineName: StringLiteral = "sizeSpeed"
        self.rated_total_capacity = self.original_input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal * self.parentModeRatedGrossTotalCap
        self.evap_air_flow_rate = self.original_input_specs.evaporator_air_flow_fraction * self.parentModeRatedEvapAirFlowRate
        self.condenser_air_flow_rate = self.original_input_specs.condenser_air_flow_fraction * self.parentModeRatedCondAirFlowRate
        self.grossRatedSHR = self.original_input_specs.gross_rated_sensible_heat_ratio
        self.RatedAirMassFlowRate = self.evap_air_flow_rate * Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, self.RatedInletAirTemp, self.RatedInletAirHumRat, RoutineName)
        self.RatedCondAirMassFlowRate = self.condenser_air_flow_rate * Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, self.RatedInletAirTemp, self.RatedInletAirHumRat, RoutineName)
        var PrintFlag: Bool = True
        var errorsFound: Bool = False
        var CompType: String = self.object_name
        var CompName: String = self.name
        var sizingCoolingAirFlow = CoolingAirFlowSizer()
        var stringOverride: String = "Rated Air Flow Rate [m3/s]"
        var preFixString: String
        sizingCoolingAirFlow.overrideSizingString(stringOverride)
        if self.original_input_specs.evaporator_air_flow_fraction < 1.0:
            state.dataSize.DataDXCoolsLowSpeedsAutozize = True
            state.dataSize.DataFractionUsedForSizing = self.original_input_specs.evaporator_air_flow_fraction
        sizingCoolingAirFlow.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
        self.evap_air_flow_rate = sizingCoolingAirFlow.size(state, self.evap_air_flow_rate, errorsFound)
        var SizingString: String = preFixString + "Gross Cooling Capacity [W]"
        var sizerCoolingCapacity = CoolingCapacitySizer()
        sizerCoolingCapacity.overrideSizingString(SizingString)
        if self.original_input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal < 1.0:
            state.dataSize.DataDXCoolsLowSpeedsAutozize = True
            state.dataSize.DataConstantUsedForSizing = -999.0
            state.dataSize.DataFlowUsedForSizing = self.parentModeRatedEvapAirFlowRate
            state.dataSize.DataFractionUsedForSizing = self.original_input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal
        sizerCoolingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
        self.rated_total_capacity = sizerCoolingCapacity.size(state, self.rated_total_capacity, errorsFound)
        state.dataSize.DataFlowUsedForSizing = self.evap_air_flow_rate
        state.dataSize.DataCapacityUsedForSizing = self.rated_total_capacity
        var errorFound: Bool = False
        var sizerCoolingSHR = CoolingSHRSizer()
        sizerCoolingSHR.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
        if self.grossRatedSHR == DataSizing.AutoSize and self.parentOperatingMode == 2:
            state.dataSize.DataSizingFraction = 0.667
            self.grossRatedSHR = sizerCoolingSHR.size(state, self.grossRatedSHR, errorFound)
        elif self.grossRatedSHR == DataSizing.AutoSize and self.parentOperatingMode == 3:
            state.dataSize.DataSizingFraction = 0.333
            self.grossRatedSHR = sizerCoolingSHR.size(state, self.grossRatedSHR, errorFound)
        else:
            self.grossRatedSHR = sizerCoolingSHR.size(state, self.grossRatedSHR, errorFound)
        state.dataSize.DataFlowUsedForSizing = 0.0
        state.dataSize.DataCapacityUsedForSizing = 0.0
        state.dataSize.DataTotCapCurveIndex = 0
        state.dataSize.DataSizingFraction = 1.0
        if self.indexSHRFT > 0 and self.indexSHRFFF > 0:
            self.RatedCBF = 0.001
        else:
            self.RatedCBF = self.CalcBypassFactor(state,
                                                  self.RatedInletAirTemp,
                                                  self.RatedInletAirHumRat,
                                                  self.rated_total_capacity,
                                                  self.grossRatedSHR,
                                                  Psychrometrics.PsyHFnTdbW(self.RatedInletAirTemp, self.RatedInletAirHumRat),
                                                  DataEnvironment.StdPressureSeaLevel)
        self.RatedEIR = 1.0 / self.original_input_specs.gross_rated_cooling_COP
        self.ratedLatentCapacity = self.rated_total_capacity * (1.0 - self.grossRatedSHR)
        state.dataSize.DataConstantUsedForSizing = 0.0
        state.dataSize.DataDXCoolsLowSpeedsAutozize = False
    def CalcSpeedOutput(inout self, state: EnergyPlusData, inletNode: NodeData, inout outletNode: NodeData, PLR: Float64, fanOp: HVAC.FanOp, condInletTemp: Float64):
        let RoutineName: StringLiteral = "CalcSpeedOutput: "
        if (PLR == 0.0) or (self.AirMassFlow == 0.0):
            outletNode.Temp = inletNode.Temp
            outletNode.HumRat = inletNode.HumRat
            outletNode.Enthalpy = inletNode.Enthalpy
            outletNode.Press = inletNode.Press
            self.fullLoadPower = 0.0
            self.fullLoadWasteHeat = 0.0
            self.RTF = 0.0
            return
        var hDelta: Float64
        var A0: Float64
        var CBF: Float64
        if self.RatedCBF > 0.0:
            A0 = -math.log(self.RatedCBF) * self.RatedAirMassFlowRate
            var ADiff: Float64 = -A0 / self.AirMassFlow
            if ADiff >= DataPrecisionGlobals.EXP_LowerLimit:
                CBF = math.exp(ADiff)
            else:
                CBF = 0.0
        else:
            CBF = 0.0
        assert(self.ambPressure > 0.0)
        var inletWetBulb: Float64 = Psychrometrics.PsyTwbFnTdbWPb(state, inletNode.Temp, inletNode.HumRat, self.ambPressure)
        var inletw: Float64 = inletNode.HumRat
        var Counter: Int = 0
        let MaxIter: Int = 30
        let Tolerance: Float64 = 0.01
        var RF: Float64 = 0.4
        var TotCap: Float64
        var SHR: Float64
        while True:
            var TotCapTempModFac: Float64 = 1.0
            if self.indexCapFT > 0:
                if state.dataCurveManager.curves[self.indexCapFT].numDims == 2:
                    TotCapTempModFac = Curve.CurveValue(state, self.indexCapFT, inletWetBulb, condInletTemp)
                else:
                    TotCapTempModFac = Curve.CurveValue(state, self.indexCapFT, condInletTemp)
            var TotCapFlowModFac: Float64 = 1.0
            if self.indexCapFFF > 0:
                TotCapFlowModFac = Curve.CurveValue(state, self.indexCapFFF, self.AirFF)
            TotCap = self.rated_total_capacity * TotCapFlowModFac * TotCapTempModFac
            hDelta = TotCap / self.AirMassFlow
            if self.indexSHRFT > 0 and self.indexSHRFFF > 0:
                var SHRTempModFrac: Float64 = max(Curve.CurveValue(state, self.indexSHRFT, inletWetBulb, inletNode.Temp), 0.0)
                var SHRFlowModFrac: Float64 = max(Curve.CurveValue(state, self.indexSHRFFF, self.AirFF), 0.0)
                SHR = self.grossRatedSHR * SHRTempModFrac * SHRFlowModFrac
                SHR = max(min(SHR, 1.0), 0.0)
                break
            var hADP: Float64 = inletNode.Enthalpy - hDelta / (1.0 - CBF)
            var tADP: Float64 = Psychrometrics.PsyTsatFnHPb(state, hADP, self.ambPressure, RoutineName)
            var wADP: Float64 = Psychrometrics.PsyWFnTdbH(state, tADP, hADP, RoutineName)
            var hTinwADP: Float64 = Psychrometrics.PsyHFnTdbW(inletNode.Temp, wADP)
            if (inletNode.Enthalpy - hADP) > 1.e-10:
                SHR = min((hTinwADP - hADP) / (inletNode.Enthalpy - hADP), 1.0)
            else:
                SHR = 1.0
            if wADP > inletw or (Counter >= 1 and Counter < MaxIter):
                if inletw == 0.0:
                    inletw = 0.00001
                var werror: Float64 = (inletw - wADP) / inletw
                inletw = RF * wADP + (1.0 - RF) * inletw
                inletWetBulb = Psychrometrics.PsyTwbFnTdbWPb(state, inletNode.Temp, inletw, self.ambPressure)
                Counter += 1
                if math.abs(werror) > Tolerance:
                    continue
                break
            break
        assert(SHR >= 0.0)
        var PLF: Float64 = 1.0
        if self.indexPLRFPLF > 0:
            PLF = Curve.CurveValue(state, self.indexPLRFPLF, PLR)
        if fanOp == HVAC.FanOp.Cycling:
            state.dataHVACGlobal.OnOffFanPartLoadFraction = PLF
        var EIRTempModFac: Float64 = 1.0
        if self.indexEIRFT > 0:
            if state.dataCurveManager.curves[self.indexEIRFT].numDims == 2:
                EIRTempModFac = Curve.CurveValue(state, self.indexEIRFT, inletWetBulb, condInletTemp)
            else:
                EIRTempModFac = Curve.CurveValue(state, self.indexEIRFT, condInletTemp)
        var EIRFlowModFac: Float64 = 1.0
        if self.indexEIRFFF > 0:
            EIRFlowModFac = Curve.CurveValue(state, self.indexEIRFFF, self.AirFF)
        var wasteHeatTempModFac: Float64 = 1.0
        if self.indexWHFT > 0:
            wasteHeatTempModFac = Curve.CurveValue(state, self.indexWHFT, condInletTemp, inletNode.Temp)
        var EIR: Float64 = self.RatedEIR * EIRFlowModFac * EIRTempModFac
        self.RTF = PLR / PLF
        self.fullLoadPower = TotCap * EIR
        self.fullLoadWasteHeat = self.ratedWasteHeatFractionOfPowerInput * wasteHeatTempModFac * self.fullLoadPower
        outletNode.Enthalpy = inletNode.Enthalpy - hDelta
        var hTinwout: Float64 = inletNode.Enthalpy - ((1.0 - SHR) * hDelta)
        outletNode.HumRat = Psychrometrics.PsyWFnTdbH(state, inletNode.Temp, hTinwout)
        outletNode.Temp = Psychrometrics.PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
        if self.doLatentDegradation and (fanOp == HVAC.FanOp.Continuous):
            var QLatActual: Float64 = TotCap * (1.0 - SHR)
            var HeatingRTF: Float64 = 0.0
            SHR = self.calcEffectiveSHR(inletNode, inletWetBulb, SHR, self.RTF, self.ratedLatentCapacity, QLatActual, HeatingRTF)
            if SHR > 1.0:
                SHR = 1.0
            hTinwout = inletNode.Enthalpy - (1.0 - SHR) * hDelta
            if SHR < 1.0:
                outletNode.HumRat = Psychrometrics.PsyWFnTdbH(state, inletNode.Temp, hTinwout, RoutineName)
            else:
                outletNode.HumRat = inletNode.HumRat
            outletNode.Temp = Psychrometrics.PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
        var tsat: Float64 = Psychrometrics.PsyTsatFnHPb(state, outletNode.Enthalpy, inletNode.Press, RoutineName)
        if outletNode.Temp < tsat:
            outletNode.Temp = tsat
            outletNode.HumRat = Psychrometrics.PsyWFnTdbH(state, tsat, outletNode.Enthalpy)
    def CalcBypassFactor(inout self, state: EnergyPlusData, tdb: Float64, w: Float64, q: Float64, shr: Float64, h: Float64, p: Float64) -> Float64:
        let RoutineName: StringLiteral = "CalcBypassFactor: "
        let SmallDifferenceTest: Float64 = 0.00000001
        var calcCBF: Float64
        var airMassFlowRate: Float64 = self.evap_air_flow_rate * Psychrometrics.PsyRhoAirFnPbTdbW(state, p, tdb, w)
        var deltaH: Float64 = q / airMassFlowRate
        var outp: Float64 = p
        var outh: Float64 = h - deltaH
        var outw: Float64 = Psychrometrics.PsyWFnTdbH(state, tdb, h - (1.0 - shr) * deltaH)
        var outtdb: Float64 = Psychrometrics.PsyTdbFnHW(outh, outw)
        var outrh: Float64 = Psychrometrics.PsyRhFnTdbWPb(state, outtdb, outw, outp)
        if outrh >= 1.0:
            ShowWarningError(state, String(RoutineName) + ": For object = " + self.object_name + ", name = \"" + self.name + "\"")
            ShowContinueError(state, "Calculated outlet air relative humidity greater than 1. The combination of")
            ShowContinueError(state, "rated air volume flow rate, total cooling capacity and sensible heat ratio yields coil exiting")
            ShowContinueError(state, "air conditions above the saturation curve. Possible fixes are to reduce the rated total cooling")
            ShowContinueError(state, "capacity, increase the rated air volume flow rate, or reduce the rated sensible heat ratio for this coil.")
            ShowContinueError(state, "If autosizing, it is recommended that all three of these values be autosized.")
            ShowContinueError(state, "...Inputs used for calculating cooling coil bypass factor.")
            ShowContinueError(state, format("...Inlet Air Temperature     = {:.2f} C", tdb))
            ShowContinueError(state, format("...Outlet Air Temperature    = {:.2f} C", outtdb))
            ShowContinueError(state, format("...Inlet Air Humidity Ratio  = {:.3E} kgWater/kgDryAir", w))
            ShowContinueError(state, format("...Outlet Air Humidity Ratio = {:.3E} kgWater/kgDryAir", outw))
            ShowContinueError(state, format("...Total Cooling Capacity used in calculation = {:.2f} W", q))
            ShowContinueError(state, format("...Air Mass Flow Rate used in calculation     = {:.6f} kg/s", airMassFlowRate))
            ShowContinueError(state, format("...Air Volume Flow Rate used in calculation   = {:.6f} m3/s", self.evap_air_flow_rate))
            if q > 0.0:
                if ((self.minRatedVolFlowPerRatedTotCap - self.evap_air_flow_rate / q) > SmallDifferenceTest) or ((self.evap_air_flow_rate / q - self.maxRatedVolFlowPerRatedTotCap) > SmallDifferenceTest):
                    ShowContinueError(state,
                                      format("...Air Volume Flow Rate per Watt of Rated Cooling Capacity is also out of bounds at = {:#G} m3/s/W",
                                              self.evap_air_flow_rate / q))
            var outletAirTempSat: Float64 = Psychrometrics.PsyTsatFnHPb(state, outh, outp, RoutineName)
            if outtdb < outletAirTempSat:
                outtdb = outletAirTempSat + 0.005
                outw = Psychrometrics.PsyWFnTdbH(state, outtdb, outh, RoutineName)
                var adjustedSHR: Float64 = (Psychrometrics.PsyHFnTdbW(tdb, outw) - outh) / deltaH
                ShowWarningError(state,
                                 String(RoutineName) + self.object_name + " \"" + self.name +
                                     "\", SHR adjusted to achieve valid outlet air properties and the simulation continues.")
                ShowContinueError(state, format("Initial SHR = {:.5f}", self.grossRatedSHR))
                ShowContinueError(state, format("Adjusted SHR = {:.5f}", adjustedSHR))
        var adp_tdb: Float64 = Psychrometrics.PsyTdpFnWPb(state, outw, outp)
        var deltaT: Float64 = tdb - outtdb
        var deltaHumRat: Float64 = w - outw
        var slopeAtConds: Float64 = 0.0
        if deltaT > 0.0:
            slopeAtConds = deltaHumRat / deltaT
        if slopeAtConds <= 0.0:
            ShowSevereError(state, self.object_name + " \"" + self.name + "\"")
            ShowContinueError(state, "...Invalid slope or outlet air condition when calculating cooling coil bypass factor.")
            ShowContinueError(state, format("...Slope = {:.8f}", slopeAtConds))
            ShowContinueError(state, format("...Inlet Air Temperature     = {:.2f} C", tdb))
            ShowContinueError(state, format("...Outlet Air Temperature    = {:.2f} C", outtdb))
            ShowContinueError(state, format("...Inlet Air Humidity Ratio  = {:.3E} kgWater/kgDryAir", w))
            ShowContinueError(state, format("...Outlet Air Humidity Ratio = {:.3E} kgWater/kgDryAir", outw))
            ShowContinueError(state, format("...Total Cooling Capacity used in calculation = {:.2f} W", q))
            ShowContinueError(state, format("...Air Mass Flow Rate used in calculation     = {:.6f} kg/s", airMassFlowRate))
            ShowContinueError(state, format("...Air Volume Flow Rate used in calculation   = {:.6f} m3/s", self.evap_air_flow_rate))
            if q > 0.0:
                if ((self.minRatedVolFlowPerRatedTotCap - self.evap_air_flow_rate / q) > SmallDifferenceTest) or ((self.evap_air_flow_rate / q - self.maxRatedVolFlowPerRatedTotCap) > SmallDifferenceTest):
                    ShowContinueError(state,
                                      format("...Air Volume Flow Rate per Watt of Rated Cooling Capacity is also out of bounds at = {:#G} m3/s/W",
                                              self.evap_air_flow_rate / q))
            ShowFatalError(state, "Errors found in calculating coil bypass factors")
        var adp_w: Float64 = min(outw, Psychrometrics.PsyWFnTdpPb(state, adp_tdb, DataEnvironment.StdPressureSeaLevel))
        var iter: Int = 0
        let maxIter: Int = 50
        var errorLast: Float64 = 100.0
        var deltaADPTemp: Float64 = 5.0
        var tolerance: Float64 = 1.0
        var cbfErrors: Bool = False
        while (iter <= maxIter) and (tolerance > 0.001):
            if iter > 0:
                adp_tdb += deltaADPTemp
            iter += 1
            adp_w = min(outw, Psychrometrics.PsyWFnTdpPb(state, adp_tdb, DataEnvironment.StdPressureSeaLevel))
            var slope: Float64 = (w - adp_w) / max(0.001, (tdb - adp_tdb))
            var error: Float64 = (slope - slopeAtConds) / slopeAtConds
            if (error > 0.0) and (errorLast < 0.0):
                deltaADPTemp = -deltaADPTemp / 2.0
            elif (error < 0.0) and (errorLast > 0.0):
                deltaADPTemp = -deltaADPTemp / 2.0
            elif math.abs(error) > math.abs(errorLast):
                deltaADPTemp = -deltaADPTemp / 2.0
            errorLast = error
            tolerance = math.abs(error)
        var adp_h: Float64 = Psychrometrics.PsyHFnTdbW(adp_tdb, adp_w)
        calcCBF = min(1.0, (outh - adp_h) / (h - adp_h))
        if iter > maxIter:
            ShowSevereError(state,
                            String(RoutineName) + self.object_name + " \"" + self.name +
                                "\" -- coil bypass factor calculation did not converge after max iterations.")
            ShowContinueError(state, format("The RatedSHR of [{:.3f}], entered by the user or autosized (see *.eio file),", self.grossRatedSHR))
            ShowContinueError(state, "may be causing this. The line defined by the coil rated inlet air conditions")
            ShowContinueError(state, "(26.7C drybulb and 19.4C wetbulb) and the RatedSHR (i.e., slope of the line) must intersect")
            ShowContinueError(state, "the saturation curve of the psychrometric chart. If the RatedSHR is too low, then this")
            ShowContinueError(state, "intersection may not occur and the coil bypass factor calculation will not converge.")
            ShowContinueError(state, "If autosizing the SHR, recheck the design supply air humidity ratio and design supply air")
            ShowContinueError(state, "temperature values in the Sizing:System and Sizing:Zone objects. In general, the temperatures")
            ShowContinueError(state, "and humidity ratios specified in these two objects should be the same for each system")
            ShowContinueError(state, "and the zones that it serves.")
            ShowContinueErrorTimeStamp(state, "")
            cbfErrors = True
        if calcCBF < 0.0:
            ShowSevereError(state, String(RoutineName) + self.object_name + " \"" + self.name + "\" -- negative coil bypass factor calculated.")
            ShowContinueErrorTimeStamp(state, "")
            cbfErrors = True
        if cbfErrors:
            ShowFatalError(state, String(RoutineName) + self.object_name + " \"" + self.name + "\" Errors found in calculating coil bypass factors")
        return calcCBF
    def calcEffectiveSHR(inout self, inletNode: NodeData, inletWetBulb: Float64, SHRss: Float64, RTF: Float64, QLatRated: Float64, QLatActual: Float64, HeatingRTF: Float64) -> Float64:
        var SHReff: Float64
        var Twet: Float64
        var Gamma: Float64
        var Twet_max: Float64
        var Ton: Float64
        var Toff: Float64
        var Toffa: Float64
        var aa: Float64
        var To1: Float64
        var To2: Float64
        var Error: Float64
        var LHRmult: Float64
        var Ton_heating: Float64
        var Toff_heating: Float64
        var Twet_Rated: Float64 = self.parentModeTimeForCondensateRemoval
        var Gamma_Rated: Float64 = self.parentModeEvapRateRatio
        var Nmax: Float64 = self.parentModeMaxCyclingRate
        var Tcl: Float64 = self.parentModeLatentTimeConst
        if RTF >= 1.0:
            SHReff = SHRss
            return SHReff
        Twet_max = 9999.0
        Twet = min(Twet_Rated * QLatRated / (QLatActual + 1.e-10), Twet_max)
        Gamma = Gamma_Rated * QLatRated * (inletNode.Temp - inletWetBulb) / ((26.7 - 19.4) * QLatActual + 1.e-10)
        Ton = 3600.0 / (4.0 * Nmax * (1.0 - RTF))
        Toff = 3600.0 / (4.0 * Nmax * RTF)
        if Gamma > 0.0:
            Toffa = min(Toff, 2.0 * Twet / Gamma)
        else:
            Toffa = Toff
        if HeatingRTF > 0.0:
            if HeatingRTF < 1.0 and HeatingRTF > RTF:
                Ton_heating = 3600.0 / (4.0 * Nmax * (1.0 - HeatingRTF))
                Toff_heating = 3600.0 / (4.0 * Nmax * HeatingRTF)
                Ton_heating += max(0.0, min(Ton_heating, (Ton + Toffa) - (Ton_heating + Toff_heating)))
                Toffa = min(Toffa, Ton_heating - Ton)
        aa = (Gamma * Toffa) - (0.25 / Twet) * math.pow(Gamma, 2) * math.pow(Toffa, 2)
        To1 = aa + Tcl
        Error = 1.0
        while Error > 0.001:
            To2 = aa - Tcl * math.expm1(min(700.0, -To1 / Tcl))
            Error = math.abs((To2 - To1) / To1)
            To1 = To2
        aa = math.exp(max(-700.0, -Ton / Tcl))
        LHRmult = max(((Ton - To2) / (Ton + Tcl * (aa - 1.0))), 0.0)
        SHReff = 1.0 - (1.0 - SHRss) * LHRmult
        if SHReff < SHRss:
            SHReff = SHRss
        if SHReff > 1.0:
            SHReff = 1.0
        return SHReff