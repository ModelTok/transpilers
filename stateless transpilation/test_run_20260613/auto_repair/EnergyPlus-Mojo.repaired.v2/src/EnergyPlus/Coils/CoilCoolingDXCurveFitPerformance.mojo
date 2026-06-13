from CoilCoolingDXCurveFitOperatingMode import CoilCoolingDXCurveFitOperatingMode
from CoilCoolingDXPerformanceBase import CoilCoolingDXPerformanceBase, CapControlMethod
from ...DataGlobalConstants import Constant
from ...ScheduleManager import Sched, Schedule as ScheduleType? # Actually Sched is a module, import Schedule struct, etc.
from ...StandardRatings import StandardRatings
from ...CurveManager import Curve
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataEnvironment import DataEnvironment as Envrn? # We'll import specific items
from ...DataHVACGlobals import HVAC, Node, NodeData? # Need Node from somewhere; assume Node module
from ...GeneralRoutines import CalcComponentSensibleLatentOutput
from ...InputProcessing.InputProcessor import InputProcessor
from ...Psychrometrics import Psychrometrics
from ...UtilityRoutines import (
    ShowSevereError, ShowContinueError, ShowFatalError, ShowSevereItemNotFound,
    ErrorObjectHeader, Util
)
from .. import Real64, Int, Bool, String, StringLiteral, Optional, List, StaticTuple
struct CoilCoolingDXCurveFitPerformanceInputSpecification:
    var name: String
    var crankcase_heater_capacity: Real64
    var minimum_outdoor_dry_bulb_temperature_for_compressor_operation: Real64
    var maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation: Real64
    var unit_internal_static_air_pressure: Real64
    var basin_heater_capacity: Real64
    var basin_heater_setpoint_temperature: Real64
    var basin_heater_operating_schedule_name: String
    var compressor_fuel_type: String
    var base_operating_mode_name: String
    var alternate_operating_mode_name: String
    var alternate_operating_mode2_name: String
    var outdoor_temperature_dependent_crankcase_heater_capacity_curve_name: String
    var capacity_control: String
struct CoilCoolingDXCurveFitPerformance @inherits(CoilCoolingDXPerformanceBase):
    static let object_name: String = "Coil:Cooling:DX:CurveFit:Performance"
    var parentName: String
    def instantiateFromInputSpec(inout self, state: EnergyPlusData, input_data: CoilCoolingDXCurveFitPerformanceInputSpecification):
        static let routineName: String = "CoilCoolingDXCurveFitPerformance::instantiateFromInputSpec: "
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, self.object_name, input_data.name)
        var errorsFound: Bool = False
        self.original_input_specs = input_data
        self.name = input_data.name
        self.minOutdoorDrybulb = input_data.minimum_outdoor_dry_bulb_temperature_for_compressor_operation
        self.maxOutdoorDrybulbForBasin = input_data.maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation
        self.crankcaseHeaterCap = input_data.crankcase_heater_capacity
        self.normalMode = CoilCoolingDXCurveFitOperatingMode(state, input_data.base_operating_mode_name)
        self.normalMode.oneTimeInit(state) 
        if Util.SameString(input_data.capacity_control, "CONTINUOUS"):
            self.capControlMethod = CapControlMethod.CONTINUOUS
        elif Util.SameString(input_data.capacity_control, "DISCRETE"):
            self.capControlMethod = CapControlMethod.DISCRETE
        else:
            ShowSevereError(state, String.format("{}{}=\"{}\", invalid", routineName, self.object_name, self.name))
            ShowContinueError(state, String.format("...Capacity Control Method=\"{}\":", input_data.capacity_control))
            ShowContinueError(state, "...must be Discrete or Continuous.")
            errorsFound = True
        self.evapCondBasinHeatCap = input_data.basin_heater_capacity
        self.evapCondBasinHeatSetpoint = input_data.basin_heater_setpoint_temperature
        if input_data.basin_heater_operating_schedule_name.empty():
            self.evapCondBasinHeatSched = Sched.GetScheduleAlwaysOn(state)
        elif Sched.GetSchedule(state, input_data.basin_heater_operating_schedule_name) == None? or not?:
            var schedOpt = Sched.GetSchedule(state, input_data.basin_heater_operating_schedule_name)
            if schedOpt is None:
                self.evapCondBasinHeatSched = None
                ShowSevereItemNotFound(state, eoh, "Evaporative Condenser Basin Heater Operating Schedule Name", input_data.basin_heater_operating_schedule_name)
                errorsFound = True
            else:
                self.evapCondBasinHeatSched = schedOpt.value()
        else:
            self.evapCondBasinHeatSched = Sched.GetSchedule(state, input_data.basin_heater_operating_schedule_name).value()
        if not input_data.alternate_operating_mode_name.empty() and input_data.alternate_operating_mode2_name.empty():
            self.maxAvailCoilMode = HVAC.CoilMode.Enhanced
            self.alternateMode = CoilCoolingDXCurveFitOperatingMode(state, input_data.alternate_operating_mode_name)
            self.alternateMode.oneTimeInit(state) 
        self.compressorFuelType = Int(Constant.eFuelNamesUC.index(Util.makeUPPER(input_data.compressor_fuel_type))) # Assuming getEnumValue equivalent
        if self.compressorFuelType == Int(Constant.eFuel.Invalid):
            ShowSevereError(state, String.format("{} {} =\"{}\" invalid", String(routineName), self.object_name, self.name))
            ShowContinueError(state, String.format("...Compressor Fuel Type=\"{}\".", input_data.compressor_fuel_type))
            errorsFound = True
        if not input_data.alternate_operating_mode2_name.empty() and not input_data.alternate_operating_mode_name.empty():
            self.maxAvailCoilMode = HVAC.CoilMode.SubcoolReheat
            self.alternateMode = CoilCoolingDXCurveFitOperatingMode(state, input_data.alternate_operating_mode_name)
            self.alternateMode2 = CoilCoolingDXCurveFitOperatingMode(state, input_data.alternate_operating_mode2_name)
            setOperMode(state, self.normalMode, 1)
            setOperMode(state, self.alternateMode, 2)
            setOperMode(state, self.alternateMode2, 3)
        if not input_data.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name.empty():
            self.crankcaseHeaterCapacityCurveIndex = Curve.GetCurveIndex(state, input_data.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name)
            if self.crankcaseHeaterCapacityCurveIndex == 0:
                ShowSevereError(state, String.format("{} = {}:  {} not found = {}", self.object_name, self.name, "Crankcase Heater Capacity Function of Temperature Curve Name", input_data.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name))
                errorsFound = True
            else:
                errorsFound = errorsFound or Curve.CheckCurveDims(state, self.crankcaseHeaterCapacityCurveIndex, {1}, routineName, self.object_name, self.name, input_data.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name)
        if errorsFound:
            ShowFatalError(state, String.format("{} Errors found in getting {} input. Preceding condition(s) causes termination.", String(routineName), self.object_name))
    def __init__(inout self, state: EnergyPlusData, name_to_find: String):
        CoilCoolingDXPerformanceBase.__init__(self)
        let objectName: String = CoilCoolingDXCurveFitPerformance.object_name
        var inputProcessor: InputProcessor = state.dataInputProcessing.inputProcessor.get()
        var performanceInstances = inputProcessor.epJSON.find(objectName)
        if performanceInstances == inputProcessor.epJSON.end():

        var performanceSchemaProps = inputProcessor.getObjectSchemaProps(state, objectName)
        var found_it: Bool = False
        for var performanceInstance in performanceInstances.value().items():
            var performanceName = Util.makeUPPER(performanceInstance.key())
            var performanceFields = performanceInstance.value()
            if not Util.SameString(name_to_find, performanceName):
                continue
            found_it = True
            var input_specs: CoilCoolingDXCurveFitPerformanceInputSpecification
            input_specs.name = performanceName
            input_specs.crankcase_heater_capacity = inputProcessor.getRealFieldValue(performanceFields, performanceSchemaProps, "crankcase_heater_capacity")
            input_specs.minimum_outdoor_dry_bulb_temperature_for_compressor_operation = inputProcessor.getRealFieldValue(performanceFields, performanceSchemaProps, "minimum_outdoor_dry_bulb_temperature_for_compressor_operation")
            input_specs.maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation = inputProcessor.getRealFieldValue(performanceFields, performanceSchemaProps, "maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation")
            input_specs.unit_internal_static_air_pressure = inputProcessor.getRealFieldValue(performanceFields, performanceSchemaProps, "unit_internal_static_air_pressure")
            input_specs.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name = inputProcessor.getAlphaFieldValue(performanceFields, performanceSchemaProps, "crankcase_heater_capacity_function_of_temperature_curve_name")
            input_specs.capacity_control = inputProcessor.getAlphaFieldValue(performanceFields, performanceSchemaProps, "capacity_control_method")
            input_specs.basin_heater_capacity = inputProcessor.getRealFieldValue(performanceFields, performanceSchemaProps, "evaporative_condenser_basin_heater_capacity")
            input_specs.basin_heater_setpoint_temperature = inputProcessor.getRealFieldValue(performanceFields, performanceSchemaProps, "evaporative_condenser_basin_heater_setpoint_temperature")
            input_specs.basin_heater_operating_schedule_name = inputProcessor.getAlphaFieldValue(performanceFields, performanceSchemaProps, "evaporative_condenser_basin_heater_operating_schedule_name")
            input_specs.compressor_fuel_type = inputProcessor.getAlphaFieldValue(performanceFields, performanceSchemaProps, "compressor_fuel_type")
            input_specs.base_operating_mode_name = inputProcessor.getAlphaFieldValue(performanceFields, performanceSchemaProps, "base_operating_mode")
            input_specs.alternate_operating_mode_name = inputProcessor.getAlphaFieldValue(performanceFields, performanceSchemaProps, "alternative_operating_mode_1")
            input_specs.alternate_operating_mode2_name = inputProcessor.getAlphaFieldValue(performanceFields, performanceSchemaProps, "alternative_operating_mode_2")
            self.instantiateFromInputSpec(state, input_specs)
            inputProcessor.markObjectAsUsed(objectName, performanceInstance.key())
            break
        if not found_it:
            ShowFatalError(state, String.format("Could not find Coil:Cooling:DX:Performance object with name: {}", name_to_find))
    def simulate(inout self, state: EnergyPlusData, inletNode: Node.NodeData, outletNode: Node.NodeData, currentCoilMode: HVAC.CoilMode, speedNum: Int, speedRatio: Real64, fanOp: HVAC.FanOp, condInletNode: Node.NodeData, condOutletNode: Node.NodeData, singleMode: Bool, LoadSHR: Real64):
        static let RoutineName: String = "CoilCoolingDXCurveFitPerformance::simulate"
        var reportingConstant: Real64 = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        self.recoveredEnergyRate = 0.0
        self.NormalSHR = 0.0
        if currentCoilMode == HVAC.CoilMode.SubcoolReheat:
            var totalCoolingRate: Real64
            var sensNorRate: Real64
            var sensSubRate: Real64
            var sensRehRate: Real64
            var latRate: Real64
            var SysNorSHR: Real64
            var SysSubSHR: Real64
            var SysRehSHR: Real64
            var HumRatNorOut: Real64
            var TempNorOut: Real64
            var EnthalpyNorOut: Real64
            var modeRatio: Real64
            self.calculate(state, self.normalMode, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
            CalcComponentSensibleLatentOutput(outletNode.MassFlowRate, inletNode.Temp, inletNode.HumRat, outletNode.Temp, outletNode.HumRat, sensNorRate, latRate, totalCoolingRate)
            if totalCoolingRate > 1.0E-10:
                self.OperatingMode = 1
                self.NormalSHR = sensNorRate / totalCoolingRate
                self.powerUse = self.normalMode.OpModePower
                self.RTF = self.normalMode.OpModeRTF
                self.wasteHeatRate = self.normalMode.OpModeWasteHeat
            if (speedRatio != 0.0) and (LoadSHR != 0.0):
                if totalCoolingRate == 0.0:
                    SysNorSHR = 1.0
                else:
                    SysNorSHR = sensNorRate / totalCoolingRate
                HumRatNorOut = outletNode.HumRat
                TempNorOut = outletNode.Temp
                EnthalpyNorOut = outletNode.Enthalpy
                self.recoveredEnergyRate = sensNorRate
                if LoadSHR < SysNorSHR:
                    outletNode.MassFlowRate = inletNode.MassFlowRate
                    self.calculate(state, self.alternateMode, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
                    CalcComponentSensibleLatentOutput(outletNode.MassFlowRate, inletNode.Temp, inletNode.HumRat, outletNode.Temp, outletNode.HumRat, sensSubRate, latRate, totalCoolingRate)
                    SysSubSHR = sensSubRate / totalCoolingRate
                    if LoadSHR < SysSubSHR:
                        outletNode.MassFlowRate = inletNode.MassFlowRate
                        self.calculate(state, self.alternateMode2, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
                        CalcComponentSensibleLatentOutput(outletNode.MassFlowRate, inletNode.Temp, inletNode.HumRat, outletNode.Temp, outletNode.HumRat, sensRehRate, latRate, totalCoolingRate)
                        SysRehSHR = sensRehRate / totalCoolingRate
                        if LoadSHR > SysRehSHR:
                            modeRatio = (LoadSHR - SysNorSHR) / (SysRehSHR - SysNorSHR)
                            self.OperatingMode = 3
                            outletNode.HumRat = HumRatNorOut * (1.0 - modeRatio) + modeRatio * outletNode.HumRat
                            outletNode.Enthalpy = EnthalpyNorOut * (1.0 - modeRatio) + modeRatio * outletNode.Enthalpy
                            outletNode.Temp = Psychrometrics.PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
                            self.ModeRatio = modeRatio
                            self.powerUse = self.normalMode.OpModePower * (1.0 - modeRatio) + modeRatio * self.alternateMode2.OpModePower
                            self.RTF = self.normalMode.OpModeRTF * (1.0 - modeRatio) + modeRatio * self.alternateMode2.OpModeRTF
                            self.wasteHeatRate = self.normalMode.OpModeWasteHeat * (1.0 - modeRatio) + modeRatio * self.alternateMode2.OpModeWasteHeat
                            self.recoveredEnergyRate = (self.recoveredEnergyRate - sensRehRate) * self.ModeRatio
                        else:
                            self.ModeRatio = 1.0
                            self.OperatingMode = 3
                            self.recoveredEnergyRate = (self.recoveredEnergyRate - sensRehRate) * self.ModeRatio
                    else:
                        modeRatio = (LoadSHR - SysNorSHR) / (SysSubSHR - SysNorSHR)
                        self.OperatingMode = 2
                        outletNode.HumRat = HumRatNorOut * (1.0 - modeRatio) + modeRatio * outletNode.HumRat
                        outletNode.Enthalpy = EnthalpyNorOut * (1.0 - modeRatio) + modeRatio * outletNode.Enthalpy
                        outletNode.Temp = Psychrometrics.PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
                        self.ModeRatio = modeRatio
                        self.powerUse = self.normalMode.OpModePower * (1.0 - modeRatio) + modeRatio * self.alternateMode.OpModePower
                        self.RTF = self.normalMode.OpModeRTF * (1.0 - modeRatio) + modeRatio * self.alternateMode.OpModeRTF
                        self.wasteHeatRate = self.normalMode.OpModeWasteHeat * (1.0 - modeRatio) + modeRatio * self.alternateMode.OpModeWasteHeat
                        self.recoveredEnergyRate = (self.recoveredEnergyRate - sensSubRate) * self.ModeRatio
                else:
                    self.ModeRatio = 0.0
                    self.OperatingMode = 1
                    self.recoveredEnergyRate = 0.0
                Real64 tsat = Psychrometrics.PsyTsatFnHPb(state, outletNode.Enthalpy, inletNode.Press, RoutineName)
                if outletNode.Temp < tsat:
                    outletNode.Temp = tsat
                    outletNode.HumRat = Psychrometrics.PsyWFnTdbH(state, tsat, outletNode.Enthalpy)
        elif currentCoilMode == HVAC.CoilMode.Enhanced:
            self.calculate(state, self.alternateMode, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
            self.OperatingMode = 2
            self.powerUse = self.alternateMode.OpModePower
            self.RTF = self.alternateMode.OpModeRTF
            self.wasteHeatRate = self.alternateMode.OpModeWasteHeat
        else:
            self.calculate(state, self.normalMode, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
            self.OperatingMode = 1
            self.powerUse = self.normalMode.OpModePower
            self.RTF = self.normalMode.OpModeRTF
            self.wasteHeatRate = self.normalMode.OpModeWasteHeat
        if state.dataEnvrn.OutDryBulbTemp < self.maxOutdoorDrybulbForBasin:
            self.crankcaseHeaterPower = self.crankcaseHeaterCap
            if self.crankcaseHeaterCapacityCurveIndex > 0:
                self.crankcaseHeaterPower *= Curve.CurveValue(state, self.crankcaseHeaterCapacityCurveIndex, state.dataEnvrn.OutDryBulbTemp)
        else:
            self.crankcaseHeaterPower = 0.0
        self.crankcaseHeaterPower = self.crankcaseHeaterPower * (1.0 - self.RTF)
        self.crankcaseHeaterElectricityConsumption = self.crankcaseHeaterPower * reportingConstant
        if self.evapCondBasinHeatSched is not None:
            var currentBasinHeaterAvail: Real64 = self.evapCondBasinHeatSched.getCurrentVal()
            if self.evapCondBasinHeatCap > 0.0 and currentBasinHeaterAvail > 0.0:
                self.basinHeaterPower = max(0.0, self.evapCondBasinHeatCap * (self.evapCondBasinHeatSetpoint - state.dataEnvrn.OutDryBulbTemp))
        else:
            if self.evapCondBasinHeatCap > 0.0:
                self.basinHeaterPower = max(0.0, self.evapCondBasinHeatCap * (self.evapCondBasinHeatSetpoint - state.dataEnvrn.OutDryBulbTemp))
        self.basinHeaterPower *= (1.0 - self.RTF)
        self.electricityConsumption = self.powerUse * reportingConstant
        if self.compressorFuelType != Int(Constant.eFuel.Electricity):
            self.compressorFuelRate = self.powerUse
            self.compressorFuelConsumption = self.electricityConsumption
            self.powerUse = 0.0
            self.electricityConsumption = 0.0
    def size(inout self, state: EnergyPlusData):
        if not state.dataGlobal.SysSizingCalc and self.mySizeFlag:
            self.normalMode.parentName = self.parentName
            self.normalMode.size(state)
            if self.maxAvailCoilMode == HVAC.CoilMode.Enhanced:
                self.alternateMode.size(state)
            if self.maxAvailCoilMode == HVAC.CoilMode.SubcoolReheat:
                self.alternateMode.size(state)
                self.alternateMode2.size(state)
            self.mySizeFlag = False
        self.oneTimeAvailSchedSetup()
        self.oneTimeMinOATSetup()
    def calculate(inout self, state: EnergyPlusData, currentMode: CoilCoolingDXCurveFitOperatingMode, inletNode: Node.NodeData, outletNode: Node.NodeData, speedNum: Int, speedRatio: Real64, fanOp: HVAC.FanOp, condInletNode: Node.NodeData, condOutletNode: Node.NodeData, singleMode: Bool):
        currentMode.CalcOperatingMode(state, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
    def calcStandardRatings210240(inout self, state: EnergyPlusData):
        Int NumOfReducedCap = 4
        var TotCapFlowModFac: Real64 = 0.0
        var EIRFlowModFac: Real64 = 0.0
        var TotCapTempModFac: Real64 = 0.0
        var EIRTempModFac: Real64 = 0.0
        var TotCoolingCapAHRI: Real64 = 0.0
        var NetCoolingCapAHRI: Real64 = 0.0
        var NetCoolingCapAHRI2023: Real64 = 0.0
        var TotalElecPower: Real64 = 0.0
        var TotalElecPower2023: Real64 = 0.0
        var TotalElecPowerRated: Real64 = 0.0
        var TotalElecPowerRated2023: Real64 = 0.0
        var EIR: Real64 = 0.0
        var PartLoadFactor: Real64 = 0.0
        var EERReduced: Real64 = 0.0
        var ElecPowerReducedCap: Real64 = 0.0
        var NetCoolingCapReduced: Real64 = 0.0
        var LoadFactor: Real64 = 0.0
        var DegradationCoeff: Real64 = 0.0
        var OutdoorUnitInletAirDryBulbTempReduced: Real64
        Real64 DefaultFanPowerPerEvapAirFlowRate = 773.3
        Real64 DefaultFanPowerPerEvapAirFlowRate2023 = 934.4
        Real64 CoolingCoilInletAirWetBulbTempRated = 19.44
        Real64 OutdoorUnitInletAirDryBulbTemp = 27.78
        Real64 OutdoorUnitInletAirDryBulbTempRated = 35.0
        Real64 AirMassFlowRatioRated = 1.0
        Real64 PLRforSEER = 0.5
        static var ReducedPLR: StaticTuple[Real64, 4] = StaticTuple(1.0, 0.75, 0.50, 0.25)
        static var IEERWeightingFactor: StaticTuple[Real64, 4] = StaticTuple(0.020, 0.617, 0.238, 0.125)
        Real64 OADBTempLowReducedCapacityTest = 18.3
        Real64 CyclicDegradationCoefficient = 0.20
        var mode = self.normalMode
        var speed = mode.speeds.back()
        var FanPowerPerEvapAirFlowRate: Real64 = DefaultFanPowerPerEvapAirFlowRate
        if speed.rated_evap_fan_power_per_volume_flow_rate > 0.0:
            FanPowerPerEvapAirFlowRate = speed.rated_evap_fan_power_per_volume_flow_rate
        var FanPowerPerEvapAirFlowRate2023: Real64 = DefaultFanPowerPerEvapAirFlowRate2023
        if speed.rated_evap_fan_power_per_volume_flow_rate_2023 > 0.0:
            FanPowerPerEvapAirFlowRate2023 = speed.rated_evap_fan_power_per_volume_flow_rate_2023
        if mode.ratedGrossTotalCap > 0.0:
            TotCapFlowModFac = Curve.CurveValue(state, speed.indexCapFFF, AirMassFlowRatioRated)
            TotCapTempModFac = Curve.CurveValue(state, speed.indexCapFT, CoolingCoilInletAirWetBulbTempRated, OutdoorUnitInletAirDryBulbTemp)
            TotCoolingCapAHRI = mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac
            self.standardRatingCoolingCapacity = TotCoolingCapAHRI - FanPowerPerEvapAirFlowRate * mode.ratedEvapAirFlowRate
            self.standardRatingCoolingCapacity2023 = TotCoolingCapAHRI - FanPowerPerEvapAirFlowRate2023 * mode.ratedEvapAirFlowRate
            TotCapTempModFac = Curve.CurveValue(state, speed.indexCapFT, CoolingCoilInletAirWetBulbTempRated, OutdoorUnitInletAirDryBulbTemp)
            TotCoolingCapAHRI = mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac
            EIRTempModFac = Curve.CurveValue(state, speed.indexEIRFT, CoolingCoilInletAirWetBulbTempRated, OutdoorUnitInletAirDryBulbTemp)
            EIRFlowModFac = Curve.CurveValue(state, speed.indexEIRFFF, AirMassFlowRatioRated)
            if speed.ratedCOP > 0.0:
                EIR = EIRTempModFac * EIRFlowModFac / speed.ratedCOP
            else:
                EIR = 0.0
            NetCoolingCapAHRI = TotCoolingCapAHRI - FanPowerPerEvapAirFlowRate * mode.ratedEvapAirFlowRate
            TotalElecPower = EIR * TotCoolingCapAHRI + FanPowerPerEvapAirFlowRate * mode.ratedEvapAirFlowRate
            NetCoolingCapAHRI2023 = TotCoolingCapAHRI - FanPowerPerEvapAirFlowRate2023 * mode.ratedEvapAirFlowRate
            TotalElecPower2023 = EIR * TotCoolingCapAHRI + FanPowerPerEvapAirFlowRate2023 * mode.ratedEvapAirFlowRate
            PartLoadFactor = Curve.CurveValue(state, speed.indexPLRFPLF, PLRforSEER)
            var PartLoadFactorStandard: Real64 = 1.0 - (1 - PLRforSEER) * CyclicDegradationCoefficient
            if TotalElecPower > 0.0:
                self.standardRatingSEER = (NetCoolingCapAHRI / TotalElecPower) * PartLoadFactor
                self.standardRatingSEER_Standard = (NetCoolingCapAHRI / TotalElecPower) * PartLoadFactorStandard
            else:
                self.standardRatingSEER = 0.0
                self.standardRatingSEER2_Standard = 0.0
            if TotalElecPower2023 > 0.0:
                self.standardRatingSEER2_User = (NetCoolingCapAHRI2023 / TotalElecPower2023) * PartLoadFactor
                self.standardRatingSEER2_Standard = (NetCoolingCapAHRI2023 / TotalElecPower2023) * PartLoadFactorStandard
            else:
                self.standardRatingSEER2_User = 0.0
                self.standardRatingSEER2_Standard = 0.0
            TotCapTempModFac = Curve.CurveValue(state, speed.indexCapFT, CoolingCoilInletAirWetBulbTempRated, OutdoorUnitInletAirDryBulbTempRated)
            self.standardRatingCoolingCapacity = mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac - FanPowerPerEvapAirFlowRate * mode.ratedEvapAirFlowRate
            self.standardRatingCoolingCapacity2023 = mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac - FanPowerPerEvapAirFlowRate2023 * mode.ratedEvapAirFlowRate
            EIRTempModFac = Curve.CurveValue(state, speed.indexEIRFT, CoolingCoilInletAirWetBulbTempRated, OutdoorUnitInletAirDryBulbTempRated)
            if speed.ratedCOP > 0.0:
                EIR = EIRTempModFac * EIRFlowModFac / speed.ratedCOP
            else:
                EIR = 0.0
            TotalElecPowerRated = EIR * (mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac) + FanPowerPerEvapAirFlowRate * mode.ratedEvapAirFlowRate
            if TotalElecPowerRated > 0.0:
                self.standardRatingEER = self.standardRatingCoolingCapacity / TotalElecPowerRated
            else:
                self.standardRatingEER = 0.0
            TotalElecPowerRated2023 = EIR * (mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac) + FanPowerPerEvapAirFlowRate2023 * mode.ratedEvapAirFlowRate
            if TotalElecPowerRated2023 > 0.0:
                self.standardRatingEER2 = self.standardRatingCoolingCapacity2023 / TotalElecPowerRated2023
            else:
                self.standardRatingEER2 = 0.0
            if mode.condenserType == CoilCoolingDXCurveFitOperatingMode.CondenserType.AIRCOOLED:
                (self.standardRatingCoolingCapacity2023, self.standardRatingSEER2_User, self.standardRatingSEER2_Standard, self.standardRatingEER2) = StandardRatings.SEER2CalculationCurveFit(state, HVAC.CoilType.CoolingDXCurveFit, self.normalMode)
            self.standardRatingIEER = 0.0
            TotCapTempModFac = Curve.CurveValue(state, speed.indexCapFT, CoolingCoilInletAirWetBulbTempRated, OutdoorUnitInletAirDryBulbTempRated)
            self.standardRatingCoolingCapacity = mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac - FanPowerPerEvapAirFlowRate * mode.ratedEvapAirFlowRate
            for RedCapNum in range(NumOfReducedCap):
                if ReducedPLR[RedCapNum] > 0.444:
                    OutdoorUnitInletAirDryBulbTempReduced = 5.0 + 30.0 * ReducedPLR[RedCapNum]
                else:
                    OutdoorUnitInletAirDryBulbTempReduced = OADBTempLowReducedCapacityTest
                TotCapTempModFac = Curve.CurveValue(state, speed.indexCapFT, CoolingCoilInletAirWetBulbTempRated, OutdoorUnitInletAirDryBulbTempReduced)
                NetCoolingCapReduced = mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac - FanPowerPerEvapAirFlowRate * mode.ratedEvapAirFlowRate
                EIRTempModFac = Curve.CurveValue(state, speed.indexEIRFT, CoolingCoilInletAirWetBulbTempRated, OutdoorUnitInletAirDryBulbTempReduced)
                EIRFlowModFac = Curve.CurveValue(state, speed.indexEIRFFF, AirMassFlowRatioRated)
                if speed.ratedCOP > 0.0:
                    EIR = EIRTempModFac * EIRFlowModFac / speed.ratedCOP
                else:
                    EIR = 0.0
                if NetCoolingCapReduced > 0.0:
                    LoadFactor = ReducedPLR[RedCapNum] * self.standardRatingCoolingCapacity / NetCoolingCapReduced
                else:
                    LoadFactor = 1.0
                DegradationCoeff = 1.130 - 0.130 * LoadFactor
                ElecPowerReducedCap = DegradationCoeff * EIR * (mode.ratedGrossTotalCap * TotCapTempModFac * TotCapFlowModFac)
                EERReduced = (LoadFactor * NetCoolingCapReduced) / (LoadFactor * ElecPowerReducedCap + FanPowerPerEvapAirFlowRate * mode.ratedEvapAirFlowRate)
                self.standardRatingIEER += IEERWeightingFactor[RedCapNum] * EERReduced
            (self.standardRatingIEER2, self.standardRatingCoolingCapacity2023, self.standardRatingEER2) = StandardRatings.IEERCalculationCurveFit(state, HVAC.CoilType.CoolingDXCurveFit, self.normalMode)
        else:
            ShowSevereError(state, String.format("Standard Ratings: Coil:Cooling:DX {} has zero rated total cooling capacity. Standard ratings cannot be calculated.", self.name))
    def setOperMode(inout self, state: EnergyPlusData, currentMode: CoilCoolingDXCurveFitOperatingMode, mode: Int):
        var numSpeeds: Int
        var errorsFound: Bool = False
        numSpeeds = int(currentMode.speeds.size())
        for speedNum in range(numSpeeds):
            currentMode.speeds[speedNum].parentOperatingMode = mode
            if mode == 2:
                if currentMode.speeds[speedNum].indexSHRFT == 0:
                    ShowSevereError(state, String.format("{}=\"{}\", Curve check:", currentMode.speeds[speedNum].object_name, currentMode.speeds[speedNum].name))
                    ShowContinueError(state, "The input of Sensible Heat Ratio Modifier Function of Temperature Curve Name is required, but not available for SubcoolReheat mode. Please input")
                    errorsFound = True
                if currentMode.speeds[speedNum].indexSHRFFF == 0:
                    ShowSevereError(state, String.format("{}=\"{}\", Curve check:", currentMode.speeds[speedNum].object_name, currentMode.speeds[speedNum].name))
                    ShowContinueError(state, "The input of Sensible Heat Ratio Modifier Function of Flow Fraction Curve Name is required, but not available for SubcoolReheat mode. Please input")
                    errorsFound = True
            if mode == 3:
                if currentMode.speeds[speedNum].indexSHRFT == 0:
                    ShowSevereError(state, String.format("{}=\"{}\", Curve check:", currentMode.speeds[speedNum].object_name, currentMode.speeds[speedNum].name))
                    ShowContinueError(state, "The input of Sensible Heat Ratio Modifier Function of Temperature Curve Name is required, but not available for SubcoolReheat mode. Please input")
                    errorsFound = True
                if currentMode.speeds[speedNum].indexSHRFFF == 0:
                    ShowSevereError(state, String.format("{}=\"{}\", Curve check:", currentMode.speeds[speedNum].object_name, currentMode.speeds[speedNum].name))
                    ShowContinueError(state, "The input of Sensible Heat Ratio Modifier Function of Flow Fraction Curve Name is required, but not available for SubcoolReheat mode. Please input")
                    errorsFound = True
        if errorsFound:
            ShowFatalError(state, String.format("CoilCoolingDXCurveFitPerformance: Errors found in getting {} input. Preceding condition(s) causes termination.", self.object_name))
    def oneTimeAvailSchedSetup(inout self):
        if self.myOneTimeAvailSchedInitFlag:
            self.normalMode.coilCoolingDXAvailSched = static_cast[CoilCoolingDXPerformanceBase](self).coilCoolingDXAvailSched
            self.alternateMode.coilCoolingDXAvailSched = self.normalMode.coilCoolingDXAvailSched
            self.alternateMode2.coilCoolingDXAvailSched = self.normalMode.coilCoolingDXAvailSched
            self.myOneTimeAvailSchedInitFlag = False
    def oneTimeMinOATSetup(inout self):
        if self.myOneTimeMinOATFlag:
            self.normalMode.minOutdoorDrybulb = static_cast[CoilCoolingDXPerformanceBase](self).minOutdoorDrybulb
            self.alternateMode.minOutdoorDrybulb = self.normalMode.minOutdoorDrybulb
            self.alternateMode2.minOutdoorDrybulb = self.normalMode.minOutdoorDrybulb
            self.myOneTimeMinOATFlag = False
    def ratedCBF(self, state: EnergyPlusData) -> Real64:
        return self.normalMode.speeds[self.normalMode.nominalSpeedIndex].RatedCBF
    def grossRatedSHR(self, state: EnergyPlusData) -> Real64:
        return self.normalMode.speeds[self.normalMode.nominalSpeedIndex].grossRatedSHR
    def grossRatedCoolingCOPAtMaxSpeed(self, state: EnergyPlusData) -> Real64:
        return self.normalMode.speeds.back().original_input_specs.gross_rated_cooling_COP
    def nameAtSpeed(self, speed: Int) -> String:
        return self.normalMode.speeds[speed].name
    def ratedAirMassFlowRateMaxSpeed(self, state: EnergyPlusData, mode: HVAC.CoilMode) -> Real64:
        if mode != HVAC.CoilMode.Normal:
            return self.alternateMode.speeds.back().RatedAirMassFlowRate
        return self.normalMode.speeds.back().RatedAirMassFlowRate
    def ratedAirMassFlowRateMinSpeed(self, state: EnergyPlusData, mode: HVAC.CoilMode) -> Real64:
        if mode != HVAC.CoilMode.Normal:
            return self.alternateMode.speeds.front().RatedAirMassFlowRate
        return self.normalMode.speeds.front().RatedAirMassFlowRate
    def ratedCondAirMassFlowRateNomSpeed(self, state: EnergyPlusData, mode: HVAC.CoilMode) -> Real64:
        if mode != HVAC.CoilMode.Normal:
            return self.alternateMode.speeds[self.alternateMode.nominalSpeedIndex].RatedCondAirMassFlowRate
        return self.normalMode.speeds[self.normalMode.nominalSpeedIndex].RatedCondAirMassFlowRate
    def ratedEvapAirMassFlowRate(self, state: EnergyPlusData) -> Real64:
        return self.normalMode.ratedEvapAirMassFlowRate
    def ratedEvapAirFlowRate(self, state: EnergyPlusData) -> Real64:
        return self.normalMode.ratedEvapAirFlowRate
    def ratedGrossTotalCap(self) -> Real64:
        return self.normalMode.ratedGrossTotalCap
    def indexCapFT(self, mode: HVAC.CoilMode) -> Int:
        if mode != HVAC.CoilMode.Normal:
            return self.alternateMode.speeds[self.alternateMode.nominalSpeedIndex].indexCapFT
        return self.normalMode.speeds[self.normalMode.nominalSpeedIndex].indexCapFT
    def subcoolReheatFlag(self) -> Bool:
        return (not self.original_input_specs.base_operating_mode_name.empty() and not self.original_input_specs.alternate_operating_mode_name.empty() and not self.original_input_specs.alternate_operating_mode2_name.empty())
    def numSpeeds(self) -> Int:
        return int(self.normalMode.speeds.size())
    def setToHundredPercentDOAS(inout self):
        for speed in self.normalMode.speeds:
            speed.minRatedVolFlowPerRatedTotCap = HVAC.MinRatedVolFlowPerRatedTotCap2
            speed.maxRatedVolFlowPerRatedTotCap = HVAC.MaxRatedVolFlowPerRatedTotCap2
        if self.maxAvailCoilMode != HVAC.CoilMode.Normal:
            for speed in self.alternateMode.speeds:
                speed.minRatedVolFlowPerRatedTotCap = HVAC.MinRatedVolFlowPerRatedTotCap2
                speed.maxRatedVolFlowPerRatedTotCap = HVAC.MaxRatedVolFlowPerRatedTotCap2
    def evapAirFlowRateAtSpeedIndex(self, state: EnergyPlusData, index: Int) -> Real64:
        return self.normalMode.speeds[index].evap_air_flow_rate
    def ratedTotalCapacityAtSpeedIndex(self, state: EnergyPlusData, index: Int) -> Real64:
        return self.normalMode.speeds[index].rated_total_capacity
    def currentEvapCondPumpPowerAtSpeed(self, state: EnergyPlusData, speed: Int) -> Real64:
        return self.normalMode.getCurrentEvapCondPumpPower(speed)
    def evapCondenserEffectivenessAtSpeedIndex(self, state: EnergyPlusData, index: Int) -> Real64:
        return self.normalMode.speeds[index].evap_condenser_effectiveness
    def evapAirFlowFraction(self, state: EnergyPlusData) -> Real64:
        return self.normalMode.speeds.front().original_input_specs.evaporator_air_flow_fraction
    var maxOutdoorDrybulbForBasin: Real64 = 0.0
    var mySizeFlag: Bool = True
    var evapCondBasinHeatSetpoint: Real64 = 0.0
    var evapCondBasinHeatSched: Optional[Sched.Schedule] = None
    var oneTimeEIOHeaderWrite: Bool = True
    var wasteHeatRate: Real64 = 0.0
    var normalMode: CoilCoolingDXCurveFitOperatingMode
    var alternateMode: CoilCoolingDXCurveFitOperatingMode
    var alternateMode2: CoilCoolingDXCurveFitOperatingMode
    var myOneTimeAvailSchedInitFlag: Bool = True
    var myOneTimeMinOATFlag: Bool = True
    var original_input_specs: CoilCoolingDXCurveFitPerformanceInputSpecification
    def __init__(inout self):
        CoilCoolingDXPerformanceBase.__init__(self)
        self.original_input_specs = CoilCoolingDXCurveFitPerformanceInputSpecification()
        self.normalMode = CoilCoolingDXCurveFitOperatingMode()
        self.alternateMode = CoilCoolingDXCurveFitOperatingMode()
        self.alternateMode2 = CoilCoolingDXCurveFitOperatingMode()
        self.myOneTimeAvailSchedInitFlag = True
        self.myOneTimeMinOATFlag = True
        self.oneTimeEIOHeaderWrite = True
        self.mySizeFlag = True
        self.maxOutdoorDrybulbForBasin = 0.0
        self.evapCondBasinHeatSetpoint = 0.0
        self.wasteHeatRate = 0.0