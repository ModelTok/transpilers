# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object from EnergyPlus.Data.EnergyPlusData
# - Node.NodeData: from EnergyPlus.DataLoopNode
# - Curve: CurveValue, GetCurveIndex, CheckCurveDims, checkCurveIsNormalizedToOne, SetCurveOutputMinValue, SetCurveOutputMaxValue from EnergyPlus.CurveManager
# - HVAC.FanOp: enum from EnergyPlus.DataHVACGlobals
# - HVAC.MinRatedVolFlowPerRatedTotCap1, HVAC.MaxRatedVolFlowPerRatedTotCap1: from EnergyPlus.DataHVACGlobals
# - Psychrometrics: PsyRhoAirFnPbTdbW, PsyTwbFnTdbWPb, PsyTsatFnHPb, PsyWFnTdbH, PsyHFnTdbW, PsyTdbFnHW, PsyRhFnTdbWPb, PsyWFnTdpPb, PsyTdpFnWPb from EnergyPlus.Psychrometrics
# - DataSizing: AutoSize, DataDXCoolsLowSpeedsAutozize, DataFractionUsedForSizing, DataConstantUsedForSizing, DataFlowUsedForSizing, DataCapacityUsedForSizing, DataSizingFraction, DataTotCapCurveIndex from EnergyPlus.DataSizing
# - DataEnvironment: StdPressureSeaLevel, StdBaroPress from EnergyPlus.DataEnvironment
# - DataPrecisionGlobals: EXP_LowerLimit from EnergyPlus.DataPrecisionGlobals
# - Util: makeUPPER, SameString from EnergyPlus.InputProcessing.InputProcessor
# - ShowWarningError, ShowContinueError, ShowFatalError, ShowSevereError, ShowContinueErrorTimeStamp from EnergyPlus.General

from dataclasses import dataclass, field
from typing import Protocol, Optional, List
import math

@dataclass
class CoilCoolingDXCurveFitSpeedInputSpecification:
    name: str = ""
    gross_rated_total_cooling_capacity_ratio_to_nominal: float = 0.0
    gross_rated_sensible_heat_ratio: float = 0.0
    gross_rated_cooling_COP: float = 0.0
    evaporator_air_flow_fraction: float = 0.0
    condenser_air_flow_fraction: float = 0.0
    active_fraction_of_coil_face_area: float = 0.0
    rated_evaporative_condenser_pump_power_fraction: float = 0.0
    rated_evaporator_fan_power_per_volume_flow_rate: float = 0.0
    rated_evaporator_fan_power_per_volume_flow_rate_2023: float = 0.0
    evaporative_condenser_effectiveness: float = 0.0
    total_cooling_capacity_function_of_temperature_curve_name: str = ""
    total_cooling_capacity_function_of_air_flow_fraction_curve_name: str = ""
    energy_input_ratio_function_of_temperature_curve_name: str = ""
    energy_input_ratio_function_of_air_flow_fraction_curve_name: str = ""
    part_load_fraction_correlation_curve_name: str = ""
    rated_waste_heat_fraction_of_power_input: float = 0.0
    waste_heat_function_of_temperature_curve_name: str = ""
    sensible_heat_ratio_modifier_function_of_temperature_curve_name: str = ""
    sensible_heat_ratio_modifier_function_of_flow_fraction_curve_name: str = ""

@dataclass
class CoilCoolingDXCurveFitSpeed:
    object_name: str = "Coil:Cooling:DX:CurveFit:Speed"
    parentName: str = ""
    original_input_specs: CoilCoolingDXCurveFitSpeedInputSpecification = field(default_factory=CoilCoolingDXCurveFitSpeedInputSpecification)
    
    indexCapFT: int = 0
    indexCapFFF: int = 0
    indexEIRFT: int = 0
    indexEIRFFF: int = 0
    indexPLRFPLF: int = 0
    indexWHFT: int = 0
    indexSHRFT: int = 0
    indexSHRFFF: int = 0
    
    name: str = ""
    RatedAirMassFlowRate: float = 0.0
    RatedCondAirMassFlowRate: float = 0.0
    grossRatedSHR: float = 0.0
    ratedGrossTotalCapIsAutosized: bool = False
    ratedEvapAirFlowRateIsAutosized: bool = False
    RatedCBF: float = 0.0
    RatedEIR: float = 0.0
    ratedCOP: float = 0.0
    rated_total_capacity: float = 0.0
    rated_evap_fan_power_per_volume_flow_rate: float = 0.0
    rated_evap_fan_power_per_volume_flow_rate_2023: float = 0.0
    ratedWasteHeatFractionOfPowerInput: float = 0.0
    evap_condenser_pump_power_fraction: float = 0.0
    evap_condenser_effectiveness: float = 0.0
    
    parentModeRatedGrossTotalCap: float = 0.0
    parentModeRatedEvapAirFlowRate: float = 0.0
    parentModeRatedCondAirFlowRate: float = 0.0
    parentOperatingMode: int = 0
    parentModeTimeForCondensateRemoval: float = 0.0
    parentModeEvapRateRatio: float = 0.0
    parentModeMaxCyclingRate: float = 0.0
    parentModeLatentTimeConst: float = 0.0
    doLatentDegradation: bool = False
    
    ambPressure: float = 0.0
    PLR: float = 0.0
    AirFF: float = 0.0
    fullLoadPower: float = 0.0
    fullLoadWasteHeat: float = 0.0
    RTF: float = 0.0
    AirMassFlow: float = 0.0
    evap_air_flow_rate: float = 0.0
    condenser_air_flow_rate: float = 0.0
    active_fraction_of_face_coil_area: float = 0.0
    adjustForFaceArea: bool = False
    ratedLatentCapacity: float = 0.0
    
    RatedInletAirTemp: float = 26.6667
    RatedInletWetBulbTemp: float = 19.4444
    RatedInletAirHumRat: float = 0.0111847
    RatedOutdoorAirTemp: float = 35.0
    DryCoilOutletHumRatioMin: float = 0.00001
    
    minRatedVolFlowPerRatedTotCap: float = 0.0
    maxRatedVolFlowPerRatedTotCap: float = 0.0

def instantiateFromInputSpec(self, state, input_data: CoilCoolingDXCurveFitSpeedInputSpecification) -> None:
    errorsFound = False
    routineName = "CoilCoolingDXCurveFitSpeed::instantiateFromInputSpec: "
    fieldName = "Part Load Fraction Correlation Curve Name"
    self.original_input_specs = input_data
    self.name = input_data.name
    self.active_fraction_of_face_coil_area = input_data.active_fraction_of_coil_face_area
    if self.active_fraction_of_face_coil_area < 1.0:
        self.adjustForFaceArea = True
    self.rated_evap_fan_power_per_volume_flow_rate = input_data.rated_evaporator_fan_power_per_volume_flow_rate
    self.rated_evap_fan_power_per_volume_flow_rate_2023 = input_data.rated_evaporator_fan_power_per_volume_flow_rate_2023
    self.evap_condenser_pump_power_fraction = input_data.rated_evaporative_condenser_pump_power_fraction
    self.evap_condenser_effectiveness = input_data.evaporative_condenser_effectiveness
    self.ratedWasteHeatFractionOfPowerInput = input_data.rated_waste_heat_fraction_of_power_input
    self.ratedCOP = input_data.gross_rated_cooling_COP
    
    errorsFound |= processCurve(self, state, input_data.total_cooling_capacity_function_of_temperature_curve_name, 
                                indexCapFT_ref := [0], [1, 2], routineName, 
                                "Total Cooling Capacity Function of Temperature Curve Name",
                                self.RatedInletWetBulbTemp, self.RatedOutdoorAirTemp)
    self.indexCapFT = indexCapFT_ref[0]
    
    errorsFound |= processCurve(self, state, input_data.total_cooling_capacity_function_of_air_flow_fraction_curve_name,
                                indexCapFFF_ref := [0], [1], routineName,
                                "Total Cooling Capacity Function of Air Flow Fraction Curve Name", 1.0)
    self.indexCapFFF = indexCapFFF_ref[0]
    
    errorsFound |= processCurve(self, state, input_data.energy_input_ratio_function_of_temperature_curve_name,
                                indexEIRFT_ref := [0], [1, 2], routineName,
                                "Energy Input Ratio Function of Temperature Curve Name",
                                self.RatedInletWetBulbTemp, self.RatedOutdoorAirTemp)
    self.indexEIRFT = indexEIRFT_ref[0]
    
    errorsFound |= processCurve(self, state, input_data.energy_input_ratio_function_of_air_flow_fraction_curve_name,
                                indexEIRFFF_ref := [0], [1], routineName,
                                "Energy Input Ratio Function of Air Flow Fraction Curve Name", 1.0)
    self.indexEIRFFF = indexEIRFFF_ref[0]
    
    errorsFound |= processCurve(self, state, input_data.sensible_heat_ratio_modifier_function_of_temperature_curve_name,
                                indexSHRFT_ref := [0], [2], routineName,
                                "Sensible Heat Ratio Modifier Function of Temperature Curve Name",
                                self.RatedInletWetBulbTemp, self.RatedOutdoorAirTemp)
    self.indexSHRFT = indexSHRFT_ref[0]
    
    errorsFound |= processCurve(self, state, input_data.sensible_heat_ratio_modifier_function_of_flow_fraction_curve_name,
                                indexSHRFFF_ref := [0], [1], routineName,
                                "Sensible Heat Ratio Modifier Function of Air Flow Fraction Curve Name", 1.0)
    self.indexSHRFFF = indexSHRFFF_ref[0]
    
    errorsFound |= processCurve(self, state, input_data.waste_heat_function_of_temperature_curve_name,
                                indexWHFT_ref := [0], [2], routineName,
                                "Waste Heat Modifier Function of Temperature Curve Name",
                                self.RatedOutdoorAirTemp, self.RatedInletAirTemp)
    self.indexWHFT = indexWHFT_ref[0]
    
    if not errorsFound and input_data.waste_heat_function_of_temperature_curve_name:
        CurveVal = Curve.CurveValue(state, self.indexWHFT, self.RatedOutdoorAirTemp, self.RatedInletAirTemp)
        if CurveVal > 1.10 or CurveVal < 0.90:
            ShowWarningError(state, f"{routineName}{self.object_name}=\"{self.name}\", curve values")
            ShowContinueError(state, f"Waste Heat Modifier Function of Temperature Curve Name = {input_data.waste_heat_function_of_temperature_curve_name}")
            ShowContinueError(state, "...Waste Heat Modifier Function of Temperature Curve Name output is not equal to 1.0 (+ or - 10%) at rated conditions.")
            ShowContinueError(state, f"...Curve output at rated conditions = {CurveVal:.3f}")
    
    errorsFound |= processCurve(self, state, input_data.part_load_fraction_correlation_curve_name,
                                indexPLRFPLF_ref := [0], [1], routineName,
                                "Part Load Fraction Correlation Curve Name", 1.0)
    self.indexPLRFPLF = indexPLRFPLF_ref[0]
    
    if self.indexPLRFPLF > 0 and not errorsFound:
        MinCurveVal = 999.0
        MaxCurveVal = -999.0
        CurveInput = 0.0
        MinCurvePLR = 0.0
        MaxCurvePLR = 0.0
        while CurveInput <= 1.0:
            CurveVal = Curve.CurveValue(state, self.indexPLRFPLF, CurveInput)
            if CurveVal < MinCurveVal:
                MinCurveVal = CurveVal
                MinCurvePLR = CurveInput
            if CurveVal > MaxCurveVal:
                MaxCurveVal = CurveVal
                MaxCurvePLR = CurveInput
            CurveInput += 0.01
        if MinCurveVal < 0.7:
            ShowWarningError(state, f"{routineName}{self.object_name}=\"{self.name}\", invalid")
            ShowContinueError(state, f"...{fieldName}=\"{input_data.part_load_fraction_correlation_curve_name}\" has out of range value.")
            ShowContinueError(state, f"...Curve minimum must be >= 0.7, curve min at PLR = {MinCurvePLR:.2f} is {MinCurveVal:.3f}")
            ShowContinueError(state, "...Setting curve minimum to 0.7 and simulation continues.")
            Curve.SetCurveOutputMinValue(state, self.indexPLRFPLF, errorsFound, 0.7)
        if MaxCurveVal > 1.0:
            ShowWarningError(state, f"{routineName}{self.object_name}=\"{self.name}\", invalid")
            ShowContinueError(state, f"...{fieldName}=\"{input_data.part_load_fraction_correlation_curve_name}\" has out of range value.")
            ShowContinueError(state, f"...Curve maximum must be <= 1.0, curve max at PLR = {MaxCurvePLR:.2f} is {MaxCurveVal:.3f}")
            ShowContinueError(state, "...Setting curve maximum to 1.0 and simulation continues.")
            Curve.SetCurveOutputMaxValue(state, self.indexPLRFPLF, errorsFound, 1.0)
    
    if errorsFound:
        ShowFatalError(state, f"{routineName}Errors found in getting {self.object_name} input. Preceding condition(s) causes termination.")

def processCurve(self, state, curveName: str, curveIndex_ref: List[int], validDims: List[int], 
                 routineName: str, fieldName: str, Var1: float, Var2: Optional[float] = None) -> bool:
    if not curveName:
        return False
    curveIndex = Curve.GetCurveIndex(state, curveName)
    if curveIndex == 0:
        ShowSevereError(state, f"{routineName}{self.object_name}=\"{self.name}\", invalid")
        ShowContinueError(state, f"...not found {fieldName}=\"{curveName}\".")
        return True
    curveIndex_ref[0] = curveIndex
    
    errorFound = Curve.CheckCurveDims(state, curveIndex, validDims, routineName, self.object_name, self.name, fieldName)
    if not errorFound:
        if Var2 is not None:
            Curve.checkCurveIsNormalizedToOne(state, f"{routineName}{self.object_name}", self.name, curveIndex, fieldName, curveName, Var1, Var2)
        else:
            Curve.checkCurveIsNormalizedToOne(state, f"{routineName}{self.object_name}", self.name, curveIndex, fieldName, curveName, Var1)
    return errorFound

def __init__(self, state, name_to_find: str) -> None:
    self.object_name = "Coil:Cooling:DX:CurveFit:Speed"
    self.parentName = ""
    self.original_input_specs = CoilCoolingDXCurveFitSpeedInputSpecification()
    self.indexCapFT = 0
    self.indexCapFFF = 0
    self.indexEIRFT = 0
    self.indexEIRFFF = 0
    self.indexPLRFPLF = 0
    self.indexWHFT = 0
    self.indexSHRFT = 0
    self.indexSHRFFF = 0
    self.name = ""
    self.RatedAirMassFlowRate = 0.0
    self.RatedCondAirMassFlowRate = 0.0
    self.grossRatedSHR = 0.0
    self.ratedGrossTotalCapIsAutosized = False
    self.ratedEvapAirFlowRateIsAutosized = False
    self.RatedCBF = 0.0
    self.RatedEIR = 0.0
    self.ratedCOP = 0.0
    self.rated_total_capacity = 0.0
    self.rated_evap_fan_power_per_volume_flow_rate = 0.0
    self.rated_evap_fan_power_per_volume_flow_rate_2023 = 0.0
    self.ratedWasteHeatFractionOfPowerInput = 0.0
    self.evap_condenser_pump_power_fraction = 0.0
    self.evap_condenser_effectiveness = 0.0
    self.parentModeRatedGrossTotalCap = 0.0
    self.parentModeRatedEvapAirFlowRate = 0.0
    self.parentModeRatedCondAirFlowRate = 0.0
    self.parentOperatingMode = 0
    self.parentModeTimeForCondensateRemoval = 0.0
    self.parentModeEvapRateRatio = 0.0
    self.parentModeMaxCyclingRate = 0.0
    self.parentModeLatentTimeConst = 0.0
    self.doLatentDegradation = False
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
    self.adjustForFaceArea = False
    self.ratedLatentCapacity = 0.0
    self.RatedInletAirTemp = 26.6667
    self.RatedInletWetBulbTemp = 19.4444
    self.RatedInletAirHumRat = 0.0111847
    self.RatedOutdoorAirTemp = 35.0
    self.DryCoilOutletHumRatioMin = 0.00001
    
    inputProcessor = state.dataInputProcessing.inputProcessor
    speedInstances = inputProcessor.epJSON.get(self.object_name)
    if speedInstances is None:
        pass
    speedSchemaProps = inputProcessor.getObjectSchemaProps(state, self.object_name)
    found_it = False
    for speedName, speedFields in speedInstances.items():
        speedNameUpper = Util.makeUPPER(speedName)
        if not Util.SameString(name_to_find, speedNameUpper):
            continue
        found_it = True
        
        input_specs = CoilCoolingDXCurveFitSpeedInputSpecification()
        input_specs.name = speedNameUpper
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
        
        instantiateFromInputSpec(self, state, input_specs)
        inputProcessor.markObjectAsUsed(self.object_name, speedName)
        break
    
    if not found_it:
        ShowFatalError(state, f"Could not find Coil:Cooling:DX:CurveFit:Speed object with name: {name_to_find}")

def size(self, state) -> None:
    RoutineName = "sizeSpeed"
    
    self.rated_total_capacity = self.original_input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal * self.parentModeRatedGrossTotalCap
    self.evap_air_flow_rate = self.original_input_specs.evaporator_air_flow_fraction * self.parentModeRatedEvapAirFlowRate
    self.condenser_air_flow_rate = self.original_input_specs.condenser_air_flow_fraction * self.parentModeRatedCondAirFlowRate
    self.grossRatedSHR = self.original_input_specs.gross_rated_sensible_heat_ratio
    
    self.RatedAirMassFlowRate = self.evap_air_flow_rate * Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, self.RatedInletAirTemp, self.RatedInletAirHumRat, RoutineName)
    self.RatedCondAirMassFlowRate = self.condenser_air_flow_rate * Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, self.RatedInletAirTemp, self.RatedInletAirHumRat, RoutineName)
    
    PrintFlag = True
    errorsFound = False
    CompType = self.object_name
    CompName = self.name
    
    stringOverride = "Rated Air Flow Rate [m3/s]"
    preFixString = ""
    if self.original_input_specs.evaporator_air_flow_fraction < 1.0:
        state.dataSize.DataDXCoolsLowSpeedsAutozize = True
        state.dataSize.DataFractionUsedForSizing = self.original_input_specs.evaporator_air_flow_fraction
    self.evap_air_flow_rate = CoolingAirFlowSizer.size(state, stringOverride, CompType, CompName, PrintFlag, RoutineName, self.evap_air_flow_rate)
    
    SizingString = preFixString + "Gross Cooling Capacity [W]"
    if self.original_input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal < 1.0:
        state.dataSize.DataDXCoolsLowSpeedsAutozize = True
        state.dataSize.DataConstantUsedForSizing = -999.0
        state.dataSize.DataFlowUsedForSizing = self.parentModeRatedEvapAirFlowRate
        state.dataSize.DataFractionUsedForSizing = self.original_input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal
    self.rated_total_capacity = CoolingCapacitySizer.size(state, SizingString, CompType, CompName, PrintFlag, RoutineName, self.rated_total_capacity)
    
    state.dataSize.DataFlowUsedForSizing = self.evap_air_flow_rate
    state.dataSize.DataCapacityUsedForSizing = self.rated_total_capacity
    errorFound = False
    if self.grossRatedSHR == DataSizing.AutoSize and self.parentOperatingMode == 2:
        state.dataSize.DataSizingFraction = 0.667
        self.grossRatedSHR = CoolingSHRSizer.size(state, CompType, CompName, PrintFlag, RoutineName, self.grossRatedSHR)
    elif self.grossRatedSHR == DataSizing.AutoSize and self.parentOperatingMode == 3:
        state.dataSize.DataSizingFraction = 0.333
        self.grossRatedSHR = CoolingSHRSizer.size(state, CompType, CompName, PrintFlag, RoutineName, self.grossRatedSHR)
    else:
        self.grossRatedSHR = CoolingSHRSizer.size(state, CompType, CompName, PrintFlag, RoutineName, self.grossRatedSHR)
    state.dataSize.DataFlowUsedForSizing = 0.0
    state.dataSize.DataCapacityUsedForSizing = 0.0
    state.dataSize.DataTotCapCurveIndex = 0
    state.dataSize.DataSizingFraction = 1.0
    
    if self.indexSHRFT > 0 and self.indexSHRFFF > 0:
        self.RatedCBF = 0.001
    else:
        self.RatedCBF = CalcBypassFactor(self, state, self.RatedInletAirTemp, self.RatedInletAirHumRat, self.rated_total_capacity, 
                                         self.grossRatedSHR, Psychrometrics.PsyHFnTdbW(self.RatedInletAirTemp, self.RatedInletAirHumRat), 
                                         DataEnvironment.StdPressureSeaLevel)
    self.RatedEIR = 1.0 / self.original_input_specs.gross_rated_cooling_COP
    self.ratedLatentCapacity = self.rated_total_capacity * (1.0 - self.grossRatedSHR)
    
    state.dataSize.DataConstantUsedForSizing = 0.0
    state.dataSize.DataDXCoolsLowSpeedsAutozize = False

def CalcSpeedOutput(self, state, inletNode, outletNode, PLR: float, fanOp, condInletTemp: float) -> None:
    RoutineName = "CalcSpeedOutput: "
    
    if (PLR == 0.0) or (self.AirMassFlow == 0.0):
        outletNode.Temp = inletNode.Temp
        outletNode.HumRat = inletNode.HumRat
        outletNode.Enthalpy = inletNode.Enthalpy
        outletNode.Press = inletNode.Press
        self.fullLoadPower = 0.0
        self.fullLoadWasteHeat = 0.0
        self.RTF = 0.0
        return
    
    if self.RatedCBF > 0.0:
        A0 = -math.log(self.RatedCBF) * self.RatedAirMassFlowRate
        ADiff = -A0 / self.AirMassFlow
        EXP_LowerLimit = DataPrecisionGlobals.EXP_LowerLimit
        if ADiff >= EXP_LowerLimit:
            CBF = math.exp(ADiff)
        else:
            CBF = 0.0
    else:
        CBF = 0.0
    
    assert self.ambPressure > 0.0
    inletWetBulb = Psychrometrics.PsyTwbFnTdbWPb(state, inletNode.Temp, inletNode.HumRat, self.ambPressure)
    inletw = inletNode.HumRat
    
    Counter = 0
    MaxIter = 30
    Tolerance = 0.01
    RF = 0.4
    TotCap = 0.0
    SHR = 0.0
    
    while True:
        TotCapTempModFac = 1.0
        if self.indexCapFT > 0:
            if state.dataCurveManager.curves[self.indexCapFT - 1].numDims == 2:
                TotCapTempModFac = Curve.CurveValue(state, self.indexCapFT, inletWetBulb, condInletTemp)
            else:
                TotCapTempModFac = Curve.CurveValue(state, self.indexCapFT, condInletTemp)
        
        TotCapFlowModFac = 1.0
        if self.indexCapFFF > 0:
            TotCapFlowModFac = Curve.CurveValue(state, self.indexCapFFF, self.AirFF)
        
        TotCap = self.rated_total_capacity * TotCapFlowModFac * TotCapTempModFac
        hDelta = TotCap / self.AirMassFlow
        
        if self.indexSHRFT > 0 and self.indexSHRFFF > 0:
            SHRTempModFrac = max(Curve.CurveValue(state, self.indexSHRFT, inletWetBulb, inletNode.Temp), 0.0)
            SHRFlowModFrac = max(Curve.CurveValue(state, self.indexSHRFFF, self.AirFF), 0.0)
            SHR = self.grossRatedSHR * SHRTempModFrac * SHRFlowModFrac
            SHR = max(min(SHR, 1.0), 0.0)
            break
        
        hADP = inletNode.Enthalpy - hDelta / (1.0 - CBF)
        tADP = Psychrometrics.PsyTsatFnHPb(state, hADP, self.ambPressure, RoutineName)
        wADP = Psychrometrics.PsyWFnTdbH(state, tADP, hADP, RoutineName)
        hTinwADP = Psychrometrics.PsyHFnTdbW(inletNode.Temp, wADP)
        if (inletNode.Enthalpy - hADP) > 1.e-10:
            SHR = min((hTinwADP - hADP) / (inletNode.Enthalpy - hADP), 1.0)
        else:
            SHR = 1.0
        
        if wADP > inletw or (Counter >= 1 and Counter < MaxIter):
            if inletw == 0.0:
                inletw = 0.00001
            werror = (inletw - wADP) / inletw
            inletw = RF * wADP + (1.0 - RF) * inletw
            inletWetBulb = Psychrometrics.PsyTwbFnTdbWPb(state, inletNode.Temp, inletw, self.ambPressure)
            Counter += 1
            if abs(werror) > Tolerance:
                continue
            break
        break
    
    assert SHR >= 0.0
    
    PLF = 1.0
    if self.indexPLRFPLF > 0:
        PLF = Curve.CurveValue(state, self.indexPLRFPLF, PLR)
    if fanOp == HVAC.FanOp.Cycling:
        state.dataHVACGlobal.OnOffFanPartLoadFraction = PLF
    
    EIRTempModFac = 1.0
    if self.indexEIRFT > 0:
        if state.dataCurveManager.curves[self.indexEIRFT - 1].numDims == 2:
            EIRTempModFac = Curve.CurveValue(state, self.indexEIRFT, inletWetBulb, condInletTemp)
        else:
            EIRTempModFac = Curve.CurveValue(state, self.indexEIRFT, condInletTemp)
    
    EIRFlowModFac = 1.0
    if self.indexEIRFFF > 0:
        EIRFlowModFac = Curve.CurveValue(state, self.indexEIRFFF, self.AirFF)
    
    wasteHeatTempModFac = 1.0
    if self.indexWHFT > 0:
        wasteHeatTempModFac = Curve.CurveValue(state, self.indexWHFT, condInletTemp, inletNode.Temp)
    
    EIR = self.RatedEIR * EIRFlowModFac * EIRTempModFac
    self.RTF = PLR / PLF
    self.fullLoadPower = TotCap * EIR
    self.fullLoadWasteHeat = self.ratedWasteHeatFractionOfPowerInput * wasteHeatTempModFac * self.fullLoadPower
    
    outletNode.Enthalpy = inletNode.Enthalpy - hDelta
    hTinwout = inletNode.Enthalpy - ((1.0 - SHR) * hDelta)
    outletNode.HumRat = Psychrometrics.PsyWFnTdbH(state, inletNode.Temp, hTinwout)
    outletNode.Temp = Psychrometrics.PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
    
    if self.doLatentDegradation and (fanOp == HVAC.FanOp.Continuous):
        QLatActual = TotCap * (1.0 - SHR)
        HeatingRTF = 0.0
        SHR = calcEffectiveSHR(self, inletNode, inletWetBulb, SHR, self.RTF, self.ratedLatentCapacity, QLatActual, HeatingRTF)
        if SHR > 1.0:
            SHR = 1.0
        hTinwout = inletNode.Enthalpy - (1.0 - SHR) * hDelta
        if SHR < 1.0:
            outletNode.HumRat = Psychrometrics.PsyWFnTdbH(state, inletNode.Temp, hTinwout, RoutineName)
        else:
            outletNode.HumRat = inletNode.HumRat
        outletNode.Temp = Psychrometrics.PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
    
    tsat = Psychrometrics.PsyTsatFnHPb(state, outletNode.Enthalpy, inletNode.Press, RoutineName)
    if outletNode.Temp < tsat:
        outletNode.Temp = tsat
        outletNode.HumRat = Psychrometrics.PsyWFnTdbH(state, tsat, outletNode.Enthalpy)

def CalcBypassFactor(self, state, tdb: float, w: float, q: float, shr: float, h: float, p: float) -> float:
    RoutineName = "CalcBypassFactor: "
    SmallDifferenceTest = 0.00000001
    
    airMassFlowRate = self.evap_air_flow_rate * Psychrometrics.PsyRhoAirFnPbTdbW(state, p, tdb, w)
    deltaH = q / airMassFlowRate
    outp = p
    outh = h - deltaH
    outw = Psychrometrics.PsyWFnTdbH(state, tdb, h - (1.0 - shr) * deltaH)
    outtdb = Psychrometrics.PsyTdbFnHW(outh, outw)
    outrh = Psychrometrics.PsyRhFnTdbWPb(state, outtdb, outw, outp)
    
    if outrh >= 1.0:
        ShowWarningError(state, f"{RoutineName}: For object = {self.object_name}, name = \"{self.name}\"")
        ShowContinueError(state, "Calculated outlet air relative humidity greater than 1. The combination of")
        ShowContinueError(state, "rated air volume flow rate, total cooling capacity and sensible heat ratio yields coil exiting")
        ShowContinueError(state, "air conditions above the saturation curve. Possible fixes are to reduce the rated total cooling")
        ShowContinueError(state, "capacity, increase the rated air volume flow rate, or reduce the rated sensible heat ratio for this coil.")
        ShowContinueError(state, "If autosizing, it is recommended that all three of these values be autosized.")
        ShowContinueError(state, "...Inputs used for calculating cooling coil bypass factor.")
        ShowContinueError(state, f"...Inlet Air Temperature     = {tdb:.2f} C")
        ShowContinueError(state, f"...Outlet Air Temperature    = {outtdb:.2f} C")
        ShowContinueError(state, f"...Inlet Air Humidity Ratio  = {w:.3E} kgWater/kgDryAir")
        ShowContinueError(state, f"...Outlet Air Humidity Ratio = {outw:.3E} kgWater/kgDryAir")
        ShowContinueError(state, f"...Total Cooling Capacity used in calculation = {q:.2f} W")
        ShowContinueError(state, f"...Air Mass Flow Rate used in calculation     = {airMassFlowRate:.6f} kg/s")
        ShowContinueError(state, f"...Air Volume Flow Rate used in calculation   = {self.evap_air_flow_rate:.6f} m3/s")
        if q > 0.0:
            if (((self.minRatedVolFlowPerRatedTotCap - self.evap_air_flow_rate / q) > SmallDifferenceTest) or
                ((self.evap_air_flow_rate / q - self.maxRatedVolFlowPerRatedTotCap) > SmallDifferenceTest)):
                ShowContinueError(state, f"...Air Volume Flow Rate per Watt of Rated Cooling Capacity is also out of bounds at = {self.evap_air_flow_rate / q:.15G} m3/s/W")
        outletAirTempSat = Psychrometrics.PsyTsatFnHPb(state, outh, outp, RoutineName)
        if outtdb < outletAirTempSat:
            outtdb = outletAirTempSat + 0.005
            outw = Psychrometrics.PsyWFnTdbH(state, outtdb, outh, RoutineName)
            adjustedSHR = (Psychrometrics.PsyHFnTdbW(tdb, outw) - outh) / deltaH
            ShowWarningError(state, f"{RoutineName}{self.object_name} \"{self.name}\", SHR adjusted to achieve valid outlet air properties and the simulation continues.")
            ShowContinueError(state, f"Initial SHR = {self.grossRatedSHR:.5f}")
            ShowContinueError(state, f"Adjusted SHR = {adjustedSHR:.5f}")
    
    adp_tdb = Psychrometrics.PsyTdpFnWPb(state, outw, outp)
    
    deltaT = tdb - outtdb
    deltaHumRat = w - outw
    slopeAtConds = 0.0
    if deltaT > 0.0:
        slopeAtConds = deltaHumRat / deltaT
    if slopeAtConds <= 0.0:
        ShowSevereError(state, f"{self.object_name} \"{self.name}\"")
        ShowContinueError(state, "...Invalid slope or outlet air condition when calculating cooling coil bypass factor.")
        ShowContinueError(state, f"...Slope = {slopeAtConds:.8f}")
        ShowContinueError(state, f"...Inlet Air Temperature     = {tdb:.2f} C")
        ShowContinueError(state, f"...Outlet Air Temperature    = {outtdb:.2f} C")
        ShowContinueError(state, f"...Inlet Air Humidity Ratio  = {w:.3E} kgWater/kgDryAir")
        ShowContinueError(state, f"...Outlet Air Humidity Ratio = {outw:.3E} kgWater/kgDryAir")
        ShowContinueError(state, f"...Total Cooling Capacity used in calculation = {q:.2f} W")
        ShowContinueError(state, f"...Air Mass Flow Rate used in calculation     = {airMassFlowRate:.6f} kg/s")
        ShowContinueError(state, f"...Air Volume Flow Rate used in calculation   = {self.evap_air_flow_rate:.6f} m3/s")
        if q > 0.0:
            if (((self.minRatedVolFlowPerRatedTotCap - self.evap_air_flow_rate / q) > SmallDifferenceTest) or
                ((self.evap_air_flow_rate / q - self.maxRatedVolFlowPerRatedTotCap) > SmallDifferenceTest)):
                ShowContinueError(state, f"...Air Volume Flow Rate per Watt of Rated Cooling Capacity is also out of bounds at = {self.evap_air_flow_rate / q:.15G} m3/s/W")
        ShowFatalError(state, "Errors found in calculating coil bypass factors")
    
    adp_w = min(outw, Psychrometrics.PsyWFnTdpPb(state, adp_tdb, DataEnvironment.StdPressureSeaLevel))
    
    iter = 0
    maxIter = 50
    errorLast = 100.0
    deltaADPTemp = 5.0
    tolerance = 1.0
    cbfErrors = False
    
    while (iter <= maxIter) and (tolerance > 0.001):
        if iter > 0:
            adp_tdb += deltaADPTemp
        iter += 1
        adp_w = min(outw, Psychrometrics.PsyWFnTdpPb(state, adp_tdb, DataEnvironment.StdPressureSeaLevel))
        slope = (w - adp_w) / max(0.001, (tdb - adp_tdb))
        error = (slope - slopeAtConds) / slopeAtConds
        if (error > 0.0) and (errorLast < 0.0):
            deltaADPTemp = -deltaADPTemp / 2.0
        elif (error < 0.0) and (errorLast > 0.0):
            deltaADPTemp = -deltaADPTemp / 2.0
        elif abs(error) > abs(errorLast):
            deltaADPTemp = -deltaADPTemp / 2.0
        errorLast = error
        tolerance = abs(error)
    
    adp_h = Psychrometrics.PsyHFnTdbW(adp_tdb, adp_w)
    calcCBF = min(1.0, (outh - adp_h) / (h - adp_h))
    
    if iter > maxIter:
        ShowSevereError(state, f"{RoutineName}{self.object_name} \"{self.name}\" -- coil bypass factor calculation did not converge after max iterations.")
        ShowContinueError(state, f"The RatedSHR of [{self.grossRatedSHR:.3f}], entered by the user or autosized (see *.eio file),")
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
        ShowSevereError(state, f"{RoutineName}{self.object_name} \"{self.name}\" -- negative coil bypass factor calculated.")
        ShowContinueErrorTimeStamp(state, "")
        cbfErrors = True
    if cbfErrors:
        ShowFatalError(state, f"{RoutineName}{self.object_name} \"{self.name}\" Errors found in calculating coil bypass factors")
    return calcCBF

def calcEffectiveSHR(self, inletNode, inletWetBulb: float, SHRss: float, RTF: float, QLatRated: float, QLatActual: float, HeatingRTF: float) -> float:
    Twet_Rated = self.parentModeTimeForCondensateRemoval
    Gamma_Rated = self.parentModeEvapRateRatio
    Nmax = self.parentModeMaxCyclingRate
    Tcl = self.parentModeLatentTimeConst
    
    if RTF >= 1.0:
        return SHRss
    
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
    
    aa = (Gamma * Toffa) - (0.25 / Twet) * (Gamma ** 2) * (Toffa ** 2)
    To1 = aa + Tcl
    Error = 1.0
    while Error > 0.001:
        To2 = aa - Tcl * math.expm1(min(700.0, -To1 / Tcl))
        Error = abs((To2 - To1) / To1)
        To1 = To2
    
    aa = math.exp(max(-700.0, -Ton / Tcl))
    LHRmult = max(((Ton - To2) / (Ton + Tcl * (aa - 1.0))), 0.0)
    
    SHReff = 1.0 - (1.0 - SHRss) * LHRmult
    
    if SHReff < SHRss:
        SHReff = SHRss
    if SHReff > 1.0:
        SHReff = 1.0
    
    return SHReff
