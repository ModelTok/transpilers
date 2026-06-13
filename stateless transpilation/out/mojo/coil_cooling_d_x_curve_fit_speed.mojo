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

from math import log, exp, fabs, pow
import math

@export
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
    
    fn __init__(inout self):
        self.name = ""
        self.gross_rated_total_cooling_capacity_ratio_to_nominal = 0.0
        self.gross_rated_sensible_heat_ratio = 0.0
        self.gross_rated_cooling_COP = 0.0
        self.evaporator_air_flow_fraction = 0.0
        self.condenser_air_flow_fraction = 0.0
        self.active_fraction_of_coil_face_area = 0.0
        self.rated_evaporative_condenser_pump_power_fraction = 0.0
        self.rated_evaporator_fan_power_per_volume_flow_rate = 0.0
        self.rated_evaporator_fan_power_per_volume_flow_rate_2023 = 0.0
        self.evaporative_condenser_effectiveness = 0.0
        self.total_cooling_capacity_function_of_temperature_curve_name = ""
        self.total_cooling_capacity_function_of_air_flow_fraction_curve_name = ""
        self.energy_input_ratio_function_of_temperature_curve_name = ""
        self.energy_input_ratio_function_of_air_flow_fraction_curve_name = ""
        self.part_load_fraction_correlation_curve_name = ""
        self.rated_waste_heat_fraction_of_power_input = 0.0
        self.waste_heat_function_of_temperature_curve_name = ""
        self.sensible_heat_ratio_modifier_function_of_temperature_curve_name = ""
        self.sensible_heat_ratio_modifier_function_of_flow_fraction_curve_name = ""

@export
struct CoilCoolingDXCurveFitSpeed:
    var object_name: String
    var parentName: String
    var original_input_specs: CoilCoolingDXCurveFitSpeedInputSpecification
    
    var indexCapFT: Int32
    var indexCapFFF: Int32
    var indexEIRFT: Int32
    var indexEIRFFF: Int32
    var indexPLRFPLF: Int32
    var indexWHFT: Int32
    var indexSHRFT: Int32
    var indexSHRFFF: Int32
    
    var name: String
    var RatedAirMassFlowRate: Float64
    var RatedCondAirMassFlowRate: Float64
    var grossRatedSHR: Float64
    var ratedGrossTotalCapIsAutosized: Bool
    var ratedEvapAirFlowRateIsAutosized: Bool
    var RatedCBF: Float64
    var RatedEIR: Float64
    var ratedCOP: Float64
    var rated_total_capacity: Float64
    var rated_evap_fan_power_per_volume_flow_rate: Float64
    var rated_evap_fan_power_per_volume_flow_rate_2023: Float64
    var ratedWasteHeatFractionOfPowerInput: Float64
    var evap_condenser_pump_power_fraction: Float64
    var evap_condenser_effectiveness: Float64
    
    var parentModeRatedGrossTotalCap: Float64
    var parentModeRatedEvapAirFlowRate: Float64
    var parentModeRatedCondAirFlowRate: Float64
    var parentOperatingMode: Int32
    var parentModeTimeForCondensateRemoval: Float64
    var parentModeEvapRateRatio: Float64
    var parentModeMaxCyclingRate: Float64
    var parentModeLatentTimeConst: Float64
    var doLatentDegradation: Bool
    
    var ambPressure: Float64
    var PLR: Float64
    var AirFF: Float64
    var fullLoadPower: Float64
    var fullLoadWasteHeat: Float64
    var RTF: Float64
    var AirMassFlow: Float64
    var evap_air_flow_rate: Float64
    var condenser_air_flow_rate: Float64
    var active_fraction_of_face_coil_area: Float64
    var adjustForFaceArea: Bool
    var ratedLatentCapacity: Float64
    
    var RatedInletAirTemp: Float64
    var RatedInletWetBulbTemp: Float64
    var RatedInletAirHumRat: Float64
    var RatedOutdoorAirTemp: Float64
    var DryCoilOutletHumRatioMin: Float64
    
    var minRatedVolFlowPerRatedTotCap: Float64
    var maxRatedVolFlowPerRatedTotCap: Float64
    
    fn __init__(inout self):
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
        self.minRatedVolFlowPerRatedTotCap = 0.0
        self.maxRatedVolFlowPerRatedTotCap = 0.0
    
    fn instantiateFromInputSpec(inout self, state: EnergyPlusData, input_data: CoilCoolingDXCurveFitSpeedInputSpecification) -> None:
        var errorsFound: Bool = False
        var routineName: String = "CoilCoolingDXCurveFitSpeed::instantiateFromInputSpec: "
        var fieldName: String = "Part Load Fraction Correlation Curve Name"
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
        
        var validDims1 = InlineArray[Int32, 2](1, 2)
        var validDims2 = InlineArray[Int32, 1](1)
        var validDims3 = InlineArray[Int32, 2](1, 2)
        var validDims4 = InlineArray[Int32, 1](1)
        var validDims5 = InlineArray[Int32, 1](2)
        var validDims6 = InlineArray[Int32, 1](1)
        var validDims7 = InlineArray[Int32, 1](2)
        var validDims8 = InlineArray[Int32, 1](1)
        
        errorsFound |= self.processCurve(state, input_data.total_cooling_capacity_function_of_temperature_curve_name, 
                                         validDims1, routineName, 
                                         "Total Cooling Capacity Function of Temperature Curve Name",
                                         self.RatedInletWetBulbTemp, self.RatedOutdoorAirTemp)
        
        errorsFound |= self.processCurve(state, input_data.total_cooling_capacity_function_of_air_flow_fraction_curve_name,
                                         validDims2, routineName,
                                         "Total Cooling Capacity Function of Air Flow Fraction Curve Name", 1.0)
        
        errorsFound |= self.processCurve(state, input_data.energy_input_ratio_function_of_temperature_curve_name,
                                         validDims3, routineName,
                                         "Energy Input Ratio Function of Temperature Curve Name",
                                         self.RatedInletWetBulbTemp, self.RatedOutdoorAirTemp)
        
        errorsFound |= self.processCurve(state, input_data.energy_input_ratio_function_of_air_flow_fraction_curve_name,
                                         validDims4, routineName,
                                         "Energy Input Ratio Function of Air Flow Fraction Curve Name", 1.0)
        
        errorsFound |= self.processCurve(state, input_data.sensible_heat_ratio_modifier_function_of_temperature_curve_name,
                                         validDims5, routineName,
                                         "Sensible Heat Ratio Modifier Function of Temperature Curve Name",
                                         self.RatedInletWetBulbTemp, self.RatedOutdoorAirTemp)
        
        errorsFound |= self.processCurve(state, input_data.sensible_heat_ratio_modifier_function_of_flow_fraction_curve_name,
                                         validDims6, routineName,
                                         "Sensible Heat Ratio Modifier Function of Air Flow Fraction Curve Name", 1.0)
        
        errorsFound |= self.processCurve(state, input_data.waste_heat_function_of_temperature_curve_name,
                                         validDims7, routineName,
                                         "Waste Heat Modifier Function of Temperature Curve Name",
                                         self.RatedOutdoorAirTemp, self.RatedInletAirTemp)
        
        if not errorsFound and input_data.waste_heat_function_of_temperature_curve_name != "":
            var CurveVal: Float64 = Curve.CurveValue(state, self.indexWHFT, self.RatedOutdoorAirTemp, self.RatedInletAirTemp)
            if CurveVal > 1.10 or CurveVal < 0.90:
                ShowWarningError(state, routineName + self.object_name + "=\"" + self.name + "\", curve values")
                ShowContinueError(state, "Waste Heat Modifier Function of Temperature Curve Name = " + input_data.waste_heat_function_of_temperature_curve_name)
                ShowContinueError(state, "...Waste Heat Modifier Function of Temperature Curve Name output is not equal to 1.0 (+ or - 10%) at rated conditions.")
                ShowContinueError(state, f"...Curve output at rated conditions = {CurveVal:.3f}")
        
        errorsFound |= self.processCurve(state, input_data.part_load_fraction_correlation_curve_name,
                                         validDims8, routineName,
                                         "Part Load Fraction Correlation Curve Name", 1.0)
        
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
                ShowWarningError(state, routineName + self.object_name + "=\"" + self.name + "\", invalid")
                ShowContinueError(state, "..." + fieldName + "=\"" + input_data.part_load_fraction_correlation_curve_name + "\" has out of range value.")
                ShowContinueError(state, f"...Curve minimum must be >= 0.7, curve min at PLR = {MinCurvePLR:.2f} is {MinCurveVal:.3f}")
                ShowContinueError(state, "...Setting curve minimum to 0.7 and simulation continues.")
                Curve.SetCurveOutputMinValue(state, self.indexPLRFPLF, errorsFound, 0.7)
            
            if MaxCurveVal > 1.0:
                ShowWarningError(state, routineName + self.object_name + "=\"" + self.name + "\", invalid")
                ShowContinueError(state, "..." + fieldName + "=\"" + input_data.part_load_fraction_correlation_curve_name + "\" has out of range value.")
                ShowContinueError(state, f"...Curve maximum must be <= 1.0, curve max at PLR = {MaxCurvePLR:.2f} is {MaxCurveVal:.3f}")
                ShowContinueError(state, "...Setting curve maximum to 1.0 and simulation continues.")
                Curve.SetCurveOutputMaxValue(state, self.indexPLRFPLF, errorsFound, 1.0)
        
        if errorsFound:
            ShowFatalError(state, routineName + "Errors found in getting " + self.object_name + " input. Preceding condition(s) causes termination.")
    
    fn processCurve(inout self, state: EnergyPlusData, curveName: String, validDims: InlineArray, 
                    routineName: String, fieldName: String, Var1: Float64, Var2: Float64 = 0.0) -> Bool:
        if curveName == "":
            return False
        var curveIndex: Int32 = Curve.GetCurveIndex(state, curveName)
        if curveIndex == 0:
            ShowSevereError(state, routineName + self.object_name + "=\"" + self.name + "\", invalid")
            ShowContinueError(state, "...not found " + fieldName + "=\"" + curveName + "\".")
            return True
        
        var errorFound: Bool = Curve.CheckCurveDims(state, curveIndex, validDims, routineName, self.object_name, self.name, fieldName)
        if not errorFound:
            if Var2 != 0.0:
                Curve.checkCurveIsNormalizedToOne(state, routineName + self.object_name, self.name, curveIndex, fieldName, curveName, Var1, Var2)
            else:
                Curve.checkCurveIsNormalizedToOne(state, routineName + self.object_name, self.name, curveIndex, fieldName, curveName, Var1)
        return errorFound
    
    fn size(inout self, state: EnergyPlusData) -> None:
        var RoutineName: String = "sizeSpeed"
        
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
        
        var stringOverride: String = "Rated Air Flow Rate [m3/s]"
        var preFixString: String = ""
        if self.original_input_specs.evaporator_air_flow_fraction < 1.0:
            state.dataSize.DataDXCoolsLowSpeedsAutozize = True
            state.dataSize.DataFractionUsedForSizing = self.original_input_specs.evaporator_air_flow_fraction
        self.evap_air_flow_rate = CoolingAirFlowSizer.size(state, stringOverride, CompType, CompName, PrintFlag, RoutineName, self.evap_air_flow_rate)
        
        var SizingString: String = preFixString + "Gross Cooling Capacity [W]"
        if self.original_input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal < 1.0:
            state.dataSize.DataDXCoolsLowSpeedsAutozize = True
            state.dataSize.DataConstantUsedForSizing = -999.0
            state.dataSize.DataFlowUsedForSizing = self.parentModeRatedEvapAirFlowRate
            state.dataSize.DataFractionUsedForSizing = self.original_input_specs.gross_rated_total_cooling_capacity_ratio_to_nominal
        self.rated_total_capacity = CoolingCapacitySizer.size(state, SizingString, CompType, CompName, PrintFlag, RoutineName, self.rated_total_capacity)
        
        state.dataSize.DataFlowUsedForSizing = self.evap_air_flow_rate
        state.dataSize.DataCapacityUsedForSizing = self.rated_total_capacity
        var errorFound: Bool = False
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
            self.RatedCBF = self.CalcBypassFactor(state, self.RatedInletAirTemp, self.RatedInletAirHumRat, self.rated_total_capacity, 
                                                   self.grossRatedSHR, Psychrometrics.PsyHFnTdbW(self.RatedInletAirTemp, self.RatedInletAirHumRat), 
                                                   DataEnvironment.StdPressureSeaLevel)
        self.RatedEIR = 1.0 / self.original_input_specs.gross_rated_cooling_COP
        self.ratedLatentCapacity = self.rated_total_capacity * (1.0 - self.grossRatedSHR)
        
        state.dataSize.DataConstantUsedForSizing = 0.0
        state.dataSize.DataDXCoolsLowSpeedsAutozize = False
    
    fn CalcSpeedOutput(inout self, state: EnergyPlusData, inletNode: Node.NodeData, inout outletNode: Node.NodeData, 
                       PLR: Float64, fanOp: HVAC.FanOp, condInletTemp: Float64) -> None:
        var RoutineName: String = "CalcSpeedOutput: "
        
        if (PLR == 0.0) or (self.AirMassFlow == 0.0):
            outletNode.Temp = inletNode.Temp
            outletNode.HumRat = inletNode.HumRat
            outletNode.Enthalpy = inletNode.Enthalpy
            outletNode.Press = inletNode.Press
            self.fullLoadPower = 0.0
            self.fullLoadWasteHeat = 0.0
            self.RTF = 0.0
            return
        
        var CBF: Float64 = 0.0
        if self.RatedCBF > 0.0:
            var A0: Float64 = -log(self.RatedCBF) * self.RatedAirMassFlowRate
            var ADiff: Float64 = -A0 / self.AirMassFlow
            var EXP_LowerLimit: Float64 = DataPrecisionGlobals.EXP_LowerLimit
            if ADiff >= EXP_LowerLimit:
                CBF = exp(ADiff)
            else:
                CBF = 0.0
        else:
            CBF = 0.0
        
        var inletWetBulb: Float64 = Psychrometrics.PsyTwbFnTdbWPb(state, inletNode.Temp, inletNode.HumRat, self.ambPressure)
        var inletw: Float64 = inletNode.HumRat
        
        var Counter: Int32 = 0
        var MaxIter: Int32 = 30
        var Tolerance: Float64 = 0.01
        var RF: Float64 = 0.4
        var TotCap: Float64 = 0.0
        var SHR: Float64 = 0.0
        var hDelta: Float64 = 0.0
        
        while True:
            var TotCapTempModFac: Float64 = 1.0
            if self.indexCapFT > 0:
                if state.dataCurveManager.curves[self.indexCapFT - 1].numDims == 2:
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
                if fabs(werror) > Tolerance:
                    continue
                break
            break
        
        var PLF: Float64 = 1.0
        if self.indexPLRFPLF > 0:
            PLF = Curve.CurveValue(state, self.indexPLRFPLF, PLR)
        if fanOp == HVAC.FanOp.Cycling:
            state.dataHVACGlobal.OnOffFanPartLoadFraction = PLF
        
        var EIRTempModFac: Float64 = 1.0
        if self.indexEIRFT > 0:
            if state.dataCurveManager.curves[self.indexEIRFT - 1].numDims == 2:
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
    
    fn CalcBypassFactor(self, state: EnergyPlusData, tdb: Float64, w: Float64, q: Float64, shr: Float64, h: Float64, p: Float64) -> Float64:
        var RoutineName: String = "CalcBypassFactor: "
        var SmallDifferenceTest: Float64 = 0.00000001
        
        var airMassFlowRate: Float64 = self.evap_air_flow_rate * Psychrometrics.PsyRhoAirFnPbTdbW(state, p, tdb, w)
        var deltaH: Float64 = q / airMassFlowRate
        var outp: Float64 = p
        var outh: Float64 = h - deltaH
        var outw: Float64 = Psychrometrics.PsyWFnTdbH(state, tdb, h - (1.0 - shr) * deltaH)
        var outtdb: Float64 = Psychrometrics.PsyTdbFnHW(outh, outw)
        var outrh: Float64 = Psychrometrics.PsyRhFnTdbWPb(state, outtdb, outw, outp)
        
        if outrh >= 1.0:
            ShowWarningError(state, RoutineName + ": For object = " + self.object_name + ", name = \"" + self.name + "\"")
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
            var outletAirTempSat: Float64 = Psychrometrics.PsyTsatFnHPb(state, outh, outp, RoutineName)
            if outtdb < outletAirTempSat:
                outtdb = outletAirTempSat + 0.005
                outw = Psychrometrics.PsyWFnTdbH(state, outtdb, outh, RoutineName)
                var adjustedSHR: Float64 = (Psychrometrics.PsyHFnTdbW(tdb, outw) - outh) / deltaH
                ShowWarningError(state, RoutineName + self.object_name + " \"" + self.name + "\", SHR adjusted to achieve valid outlet air properties and the simulation continues.")
                ShowContinueError(state, f"Initial SHR = {self.grossRatedSHR:.5f}")
                ShowContinueError(state, f"Adjusted SHR = {adjustedSHR:.5f}")
        
        var adp_tdb: Float64 = Psychrometrics.PsyTdpFnWPb(state, outw, outp)
        
        var deltaT: Float64 = tdb - outtdb
        var deltaHumRat: Float64 = w - outw
        var slopeAtConds: Float64 = 0.0
        if deltaT > 0.0:
            slopeAtConds = deltaHumRat / deltaT
        if slopeAtConds <= 0.0:
            ShowSevereError(state, self.object_name + " \"" + self.name + "\"")
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
        
        var adp_w: Float64 = min(outw, Psychrometrics.PsyWFnTdpPb(state, adp_tdb, DataEnvironment.StdPressureSeaLevel))
        
        var iter: Int32 = 0
        var maxIter: Int32 = 50
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
            elif fabs(error) > fabs(errorLast):
                deltaADPTemp = -deltaADPTemp / 2.0
            errorLast = error
            tolerance = fabs(error)
        
        var adp_h: Float64 = Psychrometrics.PsyHFnTdbW(adp_tdb, adp_w)
        var calcCBF: Float64 = min(1.0, (outh - adp_h) / (h - adp_h))
        
        if iter > maxIter:
            ShowSevereError(state, RoutineName + self.object_name + " \"" + self.name + "\" -- coil bypass factor calculation did not converge after max iterations.")
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
            ShowSevereError(state, RoutineName + self.object_name + " \"" + self.name + "\" -- negative coil bypass factor calculated.")
            ShowContinueErrorTimeStamp(state, "")
            cbfErrors = True
        if cbfErrors:
            ShowFatalError(state, RoutineName + self.object_name + " \"" + self.name + "\" Errors found in calculating coil bypass factors")
        return calcCBF
    
    fn calcEffectiveSHR(self, inletNode: Node.NodeData, inletWetBulb: Float64, SHRss: Float64, RTF: Float64, 
                        QLatRated: Float64, QLatActual: Float64, HeatingRTF: Float64) -> Float64:
        var Twet_Rated: Float64 = self.parentModeTimeForCondensateRemoval
        var Gamma_Rated: Float64 = self.parentModeEvapRateRatio
        var Nmax: Float64 = self.parentModeMaxCyclingRate
        var Tcl: Float64 = self.parentModeLatentTimeConst
        
        if RTF >= 1.0:
            return SHRss
        
        var Twet_max: Float64 = 9999.0
        
        var Twet: Float64 = min(Twet_Rated * QLatRated / (QLatActual + 1.e-10), Twet_max)
        var Gamma: Float64 = Gamma_Rated * QLatRated * (inletNode.Temp - inletWetBulb) / ((26.7 - 19.4) * QLatActual + 1.e-10)
        
        var Ton: Float64 = 3600.0 / (4.0 * Nmax * (1.0 - RTF))
        var Toff: Float64 = 3600.0 / (4.0 * Nmax * RTF)
        
        var Toffa: Float64 = 0.0
        if Gamma > 0.0:
            Toffa = min(Toff, 2.0 * Twet / Gamma)
        else:
            Toffa = Toff
        
        if HeatingRTF > 0.0:
            if HeatingRTF < 1.0 and HeatingRTF > RTF:
                var Ton_heating: Float64 = 3600.0 / (4.0 * Nmax * (1.0 - HeatingRTF))
                var Toff_heating: Float64 = 3600.0 / (4.0 * Nmax * HeatingRTF)
                Ton_heating += max(0.0, min(Ton_heating, (Ton + Toffa) - (Ton_heating + Toff_heating)))
                Toffa = min(Toffa, Ton_heating - Ton)
        
        var aa: Float64 = (Gamma * Toffa) - (0.25 / Twet) * (Gamma * Gamma) * (Toffa * Toffa)
        var To1: Float64 = aa + Tcl
        var Error: Float64 = 1.0
        while Error > 0.001:
            var To2: Float64 = aa - Tcl * math.expm1(min(700.0, -To1 / Tcl))
            Error = fabs((To2 - To1) / To1)
            To1 = To2
        
        aa = exp(max(-700.0, -Ton / Tcl))
        var LHRmult: Float64 = max(((Ton - To1) / (Ton + Tcl * (aa - 1.0))), 0.0)
        
        var SHReff: Float64 = 1.0 - (1.0 - SHRss) * LHRmult
        
        if SHReff < SHRss:
            SHReff = SHRss
        if SHReff > 1.0:
            SHReff = 1.0
        
        return SHReff
