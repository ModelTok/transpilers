from CoilCoolingDXCurveFitSpeed import CoilCoolingDXCurveFitSpeed
from DataLoopNode import NodeData
from . import EnergyPlusData
from Schedule import Schedule as SchedSchedule
from DataSizing import AutoSize, CoolingAirFlowSizer, CoolingCapacitySizer, AutoCalculateSizer
from DataEnvironment import DataEnvironment
from DataHVACGlobals import FanOp, MSHPMassFlowRateHigh, MSHPMassFlowRateLow
from EMSManager import SetupEMSActuator
from InputProcessing.InputProcessor import InputProcessor
from Psychrometrics import PsyRhoAirFnPbTdbW, PsyTwbFnTdbWPb, PsyTdbFnHW, PsyTsatFnHPb, PsyWFnTdbH
from Utility import SameString, makeUPPER
from OutputProcessor import ShowWarningError, ShowContinueError, ShowSevereError, ShowFatalError
struct CoilCoolingDXCurveFitOperatingModeInputSpecification:
    var name: String
    var gross_rated_total_cooling_capacity: Float64 = 0.0
    var rated_evaporator_air_flow_rate: Float64 = 0.0
    var rated_condenser_air_flow_rate: Float64 = 0.0
    var maximum_cycling_rate: Float64 = 0.0
    var ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity: Float64 = 0.0
    var latent_capacity_time_constant: Float64 = 0.0
    var nominal_time_for_condensate_removal_to_begin: Float64 = 0.0
    var apply_part_load_fraction_to_speeds_greater_than_1: String
    var apply_latent_degradation_to_speeds_greater_than_1: String
    var condenser_type: String
    var nominal_evap_condenser_pump_power: Float64 = 0.0
    var nominal_speed_number: Float64 = 0.0
    var speed_data_names: List[String]
struct CoilCoolingDXCurveFitOperatingMode:
    var object_name: String = "Coil:Cooling:DX:CurveFit:OperatingMode"
    var parentName: String
    var coilCoolingDXAvailSched: Optional[SchedSchedule]
    def instantiateFromInputSpec(inout self, state: EnergyPlusData, input_data: CoilCoolingDXCurveFitOperatingModeInputSpecification):
        alias routineName = "CoilCoolingDXCurveFitOperatingMode::instantiateFromInputSpec: "
        var errorsFound: Bool = False
        self.original_input_specs = input_data
        self.name = input_data.name
        self.ratedGrossTotalCap = input_data.gross_rated_total_cooling_capacity
        if self.ratedGrossTotalCap == AutoSize:
            self.ratedGrossTotalCapIsAutosized = True
        self.ratedEvapAirFlowRate = input_data.rated_evaporator_air_flow_rate
        if self.ratedEvapAirFlowRate == AutoSize:
            self.ratedEvapAirFlowRateIsAutosized = True
        self.ratedCondAirFlowRate = input_data.rated_condenser_air_flow_rate
        self.timeForCondensateRemoval = input_data.nominal_time_for_condensate_removal_to_begin
        self.evapRateRatio = input_data.ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity
        self.maxCyclingRate = input_data.maximum_cycling_rate
        self.latentTimeConst = input_data.latent_capacity_time_constant
        if SameString(input_data.apply_part_load_fraction_to_speeds_greater_than_1, "Yes"):
            self.applyPartLoadFractionAllSpeeds = True
        else:
            self.applyPartLoadFractionAllSpeeds = False
        if SameString(input_data.apply_latent_degradation_to_speeds_greater_than_1, "Yes"):
            self.applyLatentDegradationAllSpeeds = True
        else:
            self.applyLatentDegradationAllSpeeds = False
        self.nominalEvaporativePumpPower = input_data.nominal_evap_condenser_pump_power
        if ((self.maxCyclingRate > 0.0 or self.evapRateRatio > 0.0 or self.latentTimeConst > 0.0 or self.timeForCondensateRemoval > 0.0) and
            (self.maxCyclingRate <= 0.0 or self.evapRateRatio <= 0.0 or self.latentTimeConst <= 0.0 or self.timeForCondensateRemoval <= 0.0)):
            ShowWarningError(state, String(routineName) + self.object_name + "=\"" + self.name + "\":")
            ShowContinueError(state, "...At least one of the four input parameters for the latent capacity degradation model")
            ShowContinueError(state, "...is set to zero. Therefore, the latent degradation model will not be used for this simulation.")
            self.latentDegradationActive = False
        elif self.maxCyclingRate > 0.0 and self.evapRateRatio > 0.0 and self.latentTimeConst > 0.0 and self.timeForCondensateRemoval > 0.0:
            self.latentDegradationActive = True
        if SameString(input_data.condenser_type, "AirCooled"):
            self.condenserType = CondenserType.AIRCOOLED
        elif SameString(input_data.condenser_type, "EvaporativelyCooled"):
            self.condenserType = CondenserType.EVAPCOOLED
        else:
            ShowSevereError(state, String(routineName) + self.object_name + "=\"" + self.name + "\", invalid")
            ShowContinueError(state, "...Condenser Type=\"" + input_data.condenser_type + "\":")
            ShowContinueError(state, "...must be AirCooled or EvaporativelyCooled.")
            errorsFound = True
        for speed_name in input_data.speed_data_names:
            self.speeds.append(CoilCoolingDXCurveFitSpeed(state, speed_name))
        self.nominalSpeedIndex = input_data.nominal_speed_number - 1
        if errorsFound:
            ShowFatalError(
                state, String(routineName) + "Errors found in getting " + self.object_name + " input. Preceding condition(s) causes termination.")
    def __init__(inout self, state: EnergyPlusData, name_to_find: String):
        var inputProcessor = state.dataInputProcessing.inputProcessor
        var modeInstances = inputProcessor.epJSON.find(CoilCoolingDXCurveFitOperatingMode.object_name)
        if modeInstances == inputProcessor.epJSON.end():

        var modeSchemaProps = inputProcessor.getObjectSchemaProps(state, CoilCoolingDXCurveFitOperatingMode.object_name)
        var found_it: Bool = False
        for modeInstance in modeInstances.value().items():
            var modeName = makeUPPER(modeInstance.key())
            var modeFields = modeInstance.value()
            if not SameString(name_to_find, modeName):
                continue
            found_it = True
            var input_specs = CoilCoolingDXCurveFitOperatingModeInputSpecification()
            input_specs.name = modeName
            input_specs.gross_rated_total_cooling_capacity = inputProcessor.getRealFieldValue(modeFields, modeSchemaProps, "rated_gross_total_cooling_capacity")
            input_specs.rated_evaporator_air_flow_rate = inputProcessor.getRealFieldValue(modeFields, modeSchemaProps, "rated_evaporator_air_flow_rate")
            input_specs.rated_condenser_air_flow_rate = inputProcessor.getRealFieldValue(modeFields, modeSchemaProps, "rated_condenser_air_flow_rate")
            input_specs.maximum_cycling_rate = inputProcessor.getRealFieldValue(modeFields, modeSchemaProps, "maximum_cycling_rate")
            input_specs.ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity = inputProcessor.getRealFieldValue(
                modeFields, modeSchemaProps, "ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity")
            input_specs.latent_capacity_time_constant = inputProcessor.getRealFieldValue(modeFields, modeSchemaProps, "latent_capacity_time_constant")
            input_specs.nominal_time_for_condensate_removal_to_begin = inputProcessor.getRealFieldValue(modeFields, modeSchemaProps, "nominal_time_for_condensate_removal_to_begin")
            input_specs.apply_part_load_fraction_to_speeds_greater_than_1 = inputProcessor.getAlphaFieldValue(modeFields, modeSchemaProps, "apply_part_load_fraction_to_speeds_greater_than_1")
            input_specs.apply_latent_degradation_to_speeds_greater_than_1 = inputProcessor.getAlphaFieldValue(modeFields, modeSchemaProps, "apply_latent_degradation_to_speeds_greater_than_1")
            input_specs.condenser_type = inputProcessor.getAlphaFieldValue(modeFields, modeSchemaProps, "condenser_type")
            input_specs.nominal_evap_condenser_pump_power = inputProcessor.getRealFieldValue(modeFields, modeSchemaProps, "nominal_evaporative_condenser_pump_power")
            input_specs.nominal_speed_number = inputProcessor.getIntFieldValue(modeFields, modeSchemaProps, "nominal_speed_number")
            for fieldNum in range(1, 11):
                var speedFieldName = String.format("speed_{}_name", fieldNum)
                var speedName = inputProcessor.getAlphaFieldValue(modeFields, modeSchemaProps, speedFieldName)
                if speedName.empty():
                    break
                input_specs.speed_data_names.append(speedName)
            if input_specs.nominal_speed_number == 0:
                input_specs.nominal_speed_number = input_specs.speed_data_names.size()
            self.instantiateFromInputSpec(state, input_specs)
            inputProcessor.markObjectAsUsed(CoilCoolingDXCurveFitOperatingMode.object_name, modeInstance.key())
            break
        if not found_it:
            ShowFatalError(state, "Could not find Coil:Cooling:DX:CurveFit:OperatingMode object with name: " + name_to_find)
    def oneTimeInit(inout self, state: EnergyPlusData):
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state,
                             self.object_name,
                             self.name,
                             "Autosized Rated Air Flow Rate",
                             "[m3/s]",
                             self.ratedAirVolFlowEMSOverrideON,
                             self.ratedAirVolFlowEMSOverrideValue)
            SetupEMSActuator(state,
                             self.object_name,
                             self.name,
                             "Autosized Rated Total Cooling Capacity",
                             "[W]",
                             self.ratedTotCapFlowEMSOverrideON,
                             self.ratedTotCapFlowEMSOverrideValue)
    def size(inout self, state: EnergyPlusData):
        alias RoutineName = "sizeOperatingMode"
        var CompType = self.object_name
        var CompName = self.name
        var PrintFlag = True
        var errorsFound = False
        var TempSize = self.original_input_specs.rated_evaporator_air_flow_rate
        var sizingCoolingAirFlow = CoolingAirFlowSizer()
        var stringOverride = "Rated Evaporator Air Flow Rate [m3/s]"
        sizingCoolingAirFlow.overrideSizingString(stringOverride)
        sizingCoolingAirFlow.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
        self.ratedEvapAirFlowRate = sizingCoolingAirFlow.size(state, TempSize, errorsFound)
        alias ratedInletAirTemp = 26.6667
        alias ratedInletAirHumRat = 0.0111847
        self.ratedEvapAirMassFlowRate = self.ratedEvapAirFlowRate * PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, ratedInletAirTemp, ratedInletAirHumRat, RoutineName)
        var SizingString = "Rated Gross Total Cooling Capacity [W]"
        state.dataSize.DataFlowUsedForSizing = self.ratedEvapAirFlowRate
        state.dataSize.DataTotCapCurveIndex = self.speeds[self.nominalSpeedIndex].indexCapFT
        TempSize = self.original_input_specs.gross_rated_total_cooling_capacity
        var sizerCoolingCapacity = CoolingCapacitySizer()
        sizerCoolingCapacity.overrideSizingString(SizingString)
        sizerCoolingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
        self.ratedGrossTotalCap = sizerCoolingCapacity.size(state, TempSize, errorsFound)
        state.dataSize.DataConstantUsedForSizing = self.ratedGrossTotalCap
        state.dataSize.DataFractionUsedForSizing = 0.000114
        TempSize = self.original_input_specs.rated_condenser_air_flow_rate
        var sizerCondAirFlow = AutoCalculateSizer()
        stringOverride = "Rated Condenser Air Flow Rate [m3/s]"
        sizerCondAirFlow.overrideSizingString(stringOverride)
        sizerCondAirFlow.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
        self.ratedCondAirFlowRate = sizerCondAirFlow.size(state, TempSize, errorsFound)
        if self.condenserType != CondenserType.AIRCOOLED:
            var sizerCondEvapPumpPower = AutoCalculateSizer()
            state.dataSize.DataConstantUsedForSizing = self.ratedGrossTotalCap
            state.dataSize.DataFractionUsedForSizing = 0.004266
            stringOverride = "Nominal Evaporative Condenser Pump Power [W]"
            sizerCondEvapPumpPower.overrideSizingString(stringOverride)
            TempSize = self.original_input_specs.nominal_evap_condenser_pump_power
            sizerCondEvapPumpPower.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
            self.nominalEvaporativePumpPower = sizerCondEvapPumpPower.size(state, TempSize, errorsFound)
        var thisSpeedNum = 0
        for curSpeed in self.speeds:
            curSpeed.parentName = self.parentName
            curSpeed.parentModeRatedGrossTotalCap = self.ratedGrossTotalCap
            curSpeed.ratedGrossTotalCapIsAutosized = self.ratedGrossTotalCapIsAutosized
            curSpeed.parentModeRatedEvapAirFlowRate = self.ratedEvapAirFlowRate
            curSpeed.ratedEvapAirFlowRateIsAutosized = self.ratedEvapAirFlowRateIsAutosized
            curSpeed.parentModeRatedCondAirFlowRate = self.ratedCondAirFlowRate
            curSpeed.doLatentDegradation = False
            if self.latentDegradationActive:
                if (thisSpeedNum == 0) or ((thisSpeedNum > 0) and self.applyLatentDegradationAllSpeeds):
                    curSpeed.parentModeTimeForCondensateRemoval = self.timeForCondensateRemoval
                    curSpeed.parentModeEvapRateRatio = self.evapRateRatio
                    curSpeed.parentModeMaxCyclingRate = self.maxCyclingRate
                    curSpeed.parentModeLatentTimeConst = self.latentTimeConst
                    curSpeed.doLatentDegradation = True
            curSpeed.size(state)
            thisSpeedNum += 1
    def CalcOperatingMode(inout self, state: EnergyPlusData, inletNode: NodeData, inout outletNode: NodeData, speedNum: Int, speedRatio: Float64, fanOp: FanOp, inout condInletNode: NodeData, condOutletNode: NodeData, singleMode: Bool):
        alias RoutineName = "CoilCoolingDXCurveFitOperatingMode::calcOperatingMode"
        var thisspeed = self.speeds[max(speedNum - 1, 0)]
        if ((speedNum == 0) or ((speedNum == 1) and (speedRatio == 0.0)) or (inletNode.MassFlowRate == 0.0) or
            (self.coilCoolingDXAvailSched.value().getCurrentVal() <= 0.0) or (state.dataEnvrn.OutDryBulbTemp < self.minOutdoorDrybulb)):
            outletNode.Temp = inletNode.Temp
            outletNode.HumRat = inletNode.HumRat
            outletNode.Enthalpy = inletNode.Enthalpy
            outletNode.Press = inletNode.Press
            self.OpModeRTF = 0.0
            self.OpModePower = 0.0
            self.OpModeWasteHeat = 0.0
            return
        if condInletNode.Press <= 0.0:
            condInletNode.Press = state.dataEnvrn.OutBaroPress
        if self.condenserType == CondenserType.AIRCOOLED:
            self.condInletTemp = condInletNode.Temp
        elif self.condenserType == CondenserType.EVAPCOOLED:
            self.condInletTemp = PsyTwbFnTdbWPb(
                state, condInletNode.Temp, condInletNode.HumRat, condInletNode.Press, "CoilCoolingDXCurveFitOperatingMode::CalcOperatingMode")
        thisspeed.ambPressure = condInletNode.Press
        thisspeed.AirMassFlow = inletNode.MassFlowRate
        if fanOp == FanOp.Cycling and speedNum == 1:
            if speedRatio > 0.0:
                thisspeed.AirMassFlow = thisspeed.AirMassFlow / speedRatio
            else:
                thisspeed.AirMassFlow = 0.0
        elif speedNum > 1:
            thisspeed.AirMassFlow = state.dataHVACGlobal.MSHPMassFlowRateHigh
        thisspeed.AirMassFlow *= thisspeed.active_fraction_of_face_coil_area
        if thisspeed.RatedAirMassFlowRate > 0.0:
            thisspeed.AirFF = thisspeed.AirMassFlow / thisspeed.RatedAirMassFlowRate
        else:
            thisspeed.AirFF = 0.0
        thisspeed.CalcSpeedOutput(state, inletNode, outletNode, speedRatio, fanOp, self.condInletTemp)
        if thisspeed.adjustForFaceArea:
            thisspeed.AirMassFlow /= thisspeed.active_fraction_of_face_coil_area
            var correctedEnthalpy = (1.0 - thisspeed.active_fraction_of_face_coil_area) * inletNode.Enthalpy + thisspeed.active_fraction_of_face_coil_area * outletNode.Enthalpy
            var correctedHumRat = (1.0 - thisspeed.active_fraction_of_face_coil_area) * inletNode.HumRat + thisspeed.active_fraction_of_face_coil_area * outletNode.HumRat
            var correctedTemp = PsyTdbFnHW(correctedEnthalpy, correctedHumRat)
            if correctedTemp < PsyTsatFnHPb(state, correctedEnthalpy, inletNode.Press, RoutineName):
                correctedTemp = PsyTsatFnHPb(state, correctedEnthalpy, inletNode.Press, RoutineName)
                correctedHumRat = PsyWFnTdbH(state, correctedTemp, correctedEnthalpy, RoutineName)
            outletNode.Temp = correctedTemp
            outletNode.HumRat = correctedHumRat
            outletNode.Enthalpy = correctedEnthalpy
        var outSpeed1HumRat = outletNode.HumRat
        var outSpeed1Enthalpy = outletNode.Enthalpy
        if fanOp == FanOp.Continuous:
            outletNode.HumRat = outletNode.HumRat * speedRatio + (1.0 - speedRatio) * inletNode.HumRat
            outletNode.Enthalpy = outletNode.Enthalpy * speedRatio + (1.0 - speedRatio) * inletNode.Enthalpy
            outletNode.Temp = PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
            var tsat = PsyTsatFnHPb(state, outletNode.Enthalpy, inletNode.Press, RoutineName)
            if outletNode.Temp < tsat:
                outletNode.Temp = tsat
                outletNode.HumRat = PsyWFnTdbH(state, tsat, outletNode.Enthalpy)
        self.OpModeRTF = thisspeed.RTF
        if (not self.applyPartLoadFractionAllSpeeds) and (speedNum > 1):
            self.OpModePower = thisspeed.fullLoadPower * speedRatio
        else:
            self.OpModePower = thisspeed.fullLoadPower * thisspeed.RTF
        self.OpModeWasteHeat = thisspeed.fullLoadWasteHeat * thisspeed.RTF
        if (speedNum > 1) and (speedRatio < 1.0) and not singleMode:
            var lowerspeed = self.speeds[max(speedNum - 2, 0)]
            lowerspeed.AirMassFlow = state.dataHVACGlobal.MSHPMassFlowRateLow * lowerspeed.active_fraction_of_face_coil_area
            lowerspeed.CalcSpeedOutput(state, inletNode, outletNode, 1.0, fanOp, condInletTemp)
            if lowerspeed.adjustForFaceArea:
                lowerspeed.AirMassFlow /= lowerspeed.active_fraction_of_face_coil_area
                var correctedEnthalpy = (1.0 - lowerspeed.active_fraction_of_face_coil_area) * inletNode.Enthalpy + lowerspeed.active_fraction_of_face_coil_area * outletNode.Enthalpy
                var correctedHumRat = (1.0 - lowerspeed.active_fraction_of_face_coil_area) * inletNode.HumRat + lowerspeed.active_fraction_of_face_coil_area * outletNode.HumRat
                var correctedTemp = PsyTdbFnHW(correctedEnthalpy, correctedHumRat)
                if correctedTemp < PsyTsatFnHPb(state, correctedEnthalpy, inletNode.Press, RoutineName):
                    correctedTemp = PsyTsatFnHPb(state, correctedEnthalpy, inletNode.Press, RoutineName)
                    correctedHumRat = PsyWFnTdbH(state, correctedTemp, correctedEnthalpy, RoutineName)
                outletNode.Temp = correctedTemp
                outletNode.HumRat = correctedHumRat
                outletNode.Enthalpy = correctedEnthalpy
            outletNode.HumRat = (outSpeed1HumRat * speedRatio * thisspeed.AirMassFlow + (1.0 - speedRatio) * outletNode.HumRat * lowerspeed.AirMassFlow) / inletNode.MassFlowRate
            outletNode.Enthalpy = (outSpeed1Enthalpy * speedRatio * thisspeed.AirMassFlow + (1.0 - speedRatio) * outletNode.Enthalpy * lowerspeed.AirMassFlow) / inletNode.MassFlowRate
            outletNode.Temp = PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
            if not self.applyPartLoadFractionAllSpeeds:
                self.OpModePower += (1.0 - speedRatio) * lowerspeed.fullLoadPower
            else:
                self.OpModePower += (1.0 - thisspeed.RTF) * lowerspeed.fullLoadPower
            self.OpModeWasteHeat += (1.0 - thisspeed.RTF) * lowerspeed.fullLoadWasteHeat
            self.OpModeRTF = 1.0
    def getCurrentEvapCondPumpPower(self, speedNum: Int) -> Float64:
        var thisspeed = self.speeds[max(speedNum - 1, 0)]
        var powerFraction = thisspeed.evap_condenser_pump_power_fraction
        return self.nominalEvaporativePumpPower * powerFraction
    var original_input_specs: CoilCoolingDXCurveFitOperatingModeInputSpecification
    var name: String
    var ratedGrossTotalCap: Float64 = 0.0
    var ratedEvapAirFlowRate: Float64 = 0.0
    var ratedCondAirFlowRate: Float64 = 0.0
    var ratedEvapAirMassFlowRate: Float64 = 0.0
    var ratedGrossTotalCapIsAutosized: Bool = False
    var ratedEvapAirFlowRateIsAutosized: Bool = False
    var timeForCondensateRemoval: Float64 = 0.0
    var evapRateRatio: Float64 = 0.0
    var maxCyclingRate: Float64 = 0.0
    var latentTimeConst: Float64 = 0.0
    var latentDegradationActive: Bool = False
    var applyPartLoadFractionAllSpeeds: Bool = False
    var applyLatentDegradationAllSpeeds: Bool = False
    var OpModePower: Float64 = 0.0
    var OpModeRTF: Float64 = 0.0
    var OpModeWasteHeat: Float64 = 0.0
    var nominalEvaporativePumpPower: Float64 = 0.0
    var nominalSpeedIndex: Int = 0
    var ratedAirVolFlowEMSOverrideON: Bool = False
    var ratedAirVolFlowEMSOverrideValue: Float64 = 0.0
    var ratedTotCapFlowEMSOverrideON: Bool = False
    var ratedTotCapFlowEMSOverrideValue: Float64 = 0.0
    var minOutdoorDrybulb: Float64 = -25.0
    enum CondenserType:
        Invalid = -1
        AIRCOOLED
        EVAPCOOLED
        Num
    var condenserType: CondenserType = CondenserType.AIRCOOLED
    var condInletTemp: Float64 = 0.0
    var speeds: List[CoilCoolingDXCurveFitSpeed]