# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - state object (from EnergyPlus.Data.EnergyPlusData)
# Node.NodeData - node data with Temp, HumRat, Enthalpy, Press, MassFlowRate
# HVAC - CoilMode enum (Normal, Enhanced, SubcoolReheat), FanOp enum, MinRatedVolFlowPerRatedTotCap2, MaxRatedVolFlowPerRatedTotCap2
# Constant - eFuel enum (Invalid, Electricity), eFuelNamesUC, rSecsInHour, getEnumValue()
# Sched.Schedule - schedule object with getCurrentVal()
# Sched - GetScheduleAlwaysOn(), GetSchedule()
# CoilCoolingDXPerformanceBase - base class (parent)
# CoilCoolingDXCurveFitOperatingMode - operating mode class with CalcOperatingMode, oneTimeInit, size, speeds, etc.
# Curve - GetCurveIndex(), CurveValue(), CheckCurveDims()
# Psychrometrics - PsyTdbFnHW(), PsyTsatFnHPb(), PsyWFnTdbH()
# StandardRatings - SEER2CalculationCurveFit(), IEERCalculationCurveFit()
# InputProcessing.InputProcessor - input processor object
# Util - SameString(), makeUPPER()
# GeneralRoutines - CalcComponentSensibleLatentOutput()
# UtilityRoutines - ShowSevereError(), ShowContinueError(), ShowFatalError(), ShowSevereItemNotFound()
# ErrorObjectHeader - error tracking class

from dataclasses import dataclass, field
from typing import Optional, Any, List
import math


@dataclass
class CoilCoolingDXCurveFitPerformanceInputSpecification:
    name: str = ""
    crankcase_heater_capacity: float = 0.0
    minimum_outdoor_dry_bulb_temperature_for_compressor_operation: float = 0.0
    maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation: float = 0.0
    unit_internal_static_air_pressure: float = 0.0
    basin_heater_capacity: float = 0.0
    basin_heater_setpoint_temperature: float = 0.0
    basin_heater_operating_schedule_name: str = ""
    compressor_fuel_type: str = ""
    base_operating_mode_name: str = ""
    alternate_operating_mode_name: str = ""
    alternate_operating_mode2_name: str = ""
    outdoor_temperature_dependent_crankcase_heater_capacity_curve_name: str = ""
    capacity_control: str = ""


class CoilCoolingDXCurveFitPerformance:
    object_name = "Coil:Cooling:DX:CurveFit:Performance"

    def __init__(self):
        self.name: str = ""
        self.parentName: str = ""
        self.minOutdoorDrybulb: float = 0.0
        self.maxOutdoorDrybulbForBasin: float = 0.0
        self.crankcaseHeaterCap: float = 0.0
        self.capControlMethod: Any = None
        self.evapCondBasinHeatCap: float = 0.0
        self.evapCondBasinHeatSetpoint: float = 0.0
        self.evapCondBasinHeatSched: Optional[Any] = None
        self.maxAvailCoilMode: Any = None
        self.compressorFuelType: Any = None
        self.crankcaseHeaterCapacityCurveIndex: int = 0
        self.recoveredEnergyRate: float = 0.0
        self.NormalSHR: float = 0.0
        self.OperatingMode: int = 0
        self.powerUse: float = 0.0
        self.RTF: float = 0.0
        self.wasteHeatRate: float = 0.0
        self.ModeRatio: float = 0.0
        self.crankcaseHeaterPower: float = 0.0
        self.crankcaseHeaterElectricityConsumption: float = 0.0
        self.basinHeaterPower: float = 0.0
        self.electricityConsumption: float = 0.0
        self.compressorFuelRate: float = 0.0
        self.compressorFuelConsumption: float = 0.0
        self.original_input_specs: CoilCoolingDXCurveFitPerformanceInputSpecification = CoilCoolingDXCurveFitPerformanceInputSpecification()
        self.normalMode: Any = None
        self.alternateMode: Any = None
        self.alternateMode2: Any = None
        self.myOneTimeAvailSchedInitFlag: bool = True
        self.myOneTimeMinOATFlag: bool = True
        self.mySizeFlag: bool = True
        self.oneTimeEIOHeaderWrite: bool = True
        self.coilCoolingDXAvailSched: Any = None
        self.standardRatingCoolingCapacity: float = 0.0
        self.standardRatingCoolingCapacity2023: float = 0.0
        self.standardRatingSEER: float = 0.0
        self.standardRatingSEER_Standard: float = 0.0
        self.standardRatingSEER2_User: float = 0.0
        self.standardRatingSEER2_Standard: float = 0.0
        self.standardRatingEER: float = 0.0
        self.standardRatingEER2: float = 0.0
        self.standardRatingIEER: float = 0.0
        self.standardRatingIEER2: float = 0.0

    def instantiateFromInputSpec(self, state: Any, input_data: CoilCoolingDXCurveFitPerformanceInputSpecification) -> None:
        routine_name = "CoilCoolingDXCurveFitPerformance::instantiateFromInputSpec: "
        errors_found = False
        self.original_input_specs = input_data
        self.name = input_data.name
        self.minOutdoorDrybulb = input_data.minimum_outdoor_dry_bulb_temperature_for_compressor_operation
        self.maxOutdoorDrybulbForBasin = input_data.maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation
        self.crankcaseHeaterCap = input_data.crankcase_heater_capacity
        
        # Import CoilCoolingDXCurveFitOperatingMode from external deps
        from CoilCoolingDXCurveFitOperatingMode import CoilCoolingDXCurveFitOperatingMode
        self.normalMode = CoilCoolingDXCurveFitOperatingMode(state, input_data.base_operating_mode_name)
        self.normalMode.oneTimeInit(state)

        from Util import SameString
        if SameString(input_data.capacity_control, "CONTINUOUS"):
            from HVAC import CapControlMethod
            self.capControlMethod = CapControlMethod.CONTINUOUS
        elif SameString(input_data.capacity_control, "DISCRETE"):
            from HVAC import CapControlMethod
            self.capControlMethod = CapControlMethod.DISCRETE
        else:
            from UtilityRoutines import ShowSevereError, ShowContinueError
            ShowSevereError(state, f"{routine_name}{self.object_name}=\"{self.name}\", invalid")
            ShowContinueError(state, f"...Capacity Control Method=\"{input_data.capacity_control}\":")
            ShowContinueError(state, "...must be Discrete or Continuous.")
            errors_found = True

        self.evapCondBasinHeatCap = input_data.basin_heater_capacity
        self.evapCondBasinHeatSetpoint = input_data.basin_heater_setpoint_temperature
        
        from Sched import GetScheduleAlwaysOn, GetSchedule
        if input_data.basin_heater_operating_schedule_name == "":
            self.evapCondBasinHeatSched = GetScheduleAlwaysOn(state)
        else:
            self.evapCondBasinHeatSched = GetSchedule(state, input_data.basin_heater_operating_schedule_name)
            if self.evapCondBasinHeatSched is None:
                from UtilityRoutines import ShowSevereItemNotFound
                from ErrorObjectHeader import ErrorObjectHeader
                eoh = ErrorObjectHeader(routine_name, self.object_name, input_data.name)
                ShowSevereItemNotFound(state, eoh, "Evaporative Condenser Basin Heater Operating Schedule Name", 
                                      input_data.basin_heater_operating_schedule_name)
                errors_found = True

        if input_data.alternate_operating_mode_name != "" and input_data.alternate_operating_mode2_name == "":
            from HVAC import CoilMode
            self.maxAvailCoilMode = CoilMode.Enhanced
            self.alternateMode = CoilCoolingDXCurveFitOperatingMode(state, input_data.alternate_operating_mode_name)
            self.alternateMode.oneTimeInit(state)

        from Util import makeUPPER
        from Constant import getEnumValue, eFuelNamesUC, eFuel
        self.compressorFuelType = getEnumValue(eFuelNamesUC, makeUPPER(input_data.compressor_fuel_type))
        if self.compressorFuelType == eFuel.Invalid:
            from UtilityRoutines import ShowSevereError, ShowContinueError
            ShowSevereError(state, f"{routine_name}{self.object_name}=\"{self.name}\" invalid")
            ShowContinueError(state, f"...Compressor Fuel Type=\"{input_data.compressor_fuel_type}\".")
            errors_found = True

        if input_data.alternate_operating_mode2_name != "" and input_data.alternate_operating_mode_name != "":
            from HVAC import CoilMode
            self.maxAvailCoilMode = CoilMode.SubcoolReheat
            self.alternateMode = CoilCoolingDXCurveFitOperatingMode(state, input_data.alternate_operating_mode_name)
            self.alternateMode2 = CoilCoolingDXCurveFitOperatingMode(state, input_data.alternate_operating_mode2_name)
            self.setOperMode(state, self.normalMode, 1)
            self.setOperMode(state, self.alternateMode, 2)
            self.setOperMode(state, self.alternateMode2, 3)

        if input_data.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name != "":
            from Curve import GetCurveIndex, CheckCurveDims
            self.crankcaseHeaterCapacityCurveIndex = GetCurveIndex(state, input_data.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name)
            if self.crankcaseHeaterCapacityCurveIndex == 0:
                from UtilityRoutines import ShowSevereError
                ShowSevereError(state, 
                    f"{self.object_name} = {self.name}:  Crankcase Heater Capacity Function of Temperature Curve Name not found = {input_data.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name}")
                errors_found = True
            else:
                errors_found |= CheckCurveDims(state, self.crankcaseHeaterCapacityCurveIndex, [1], routine_name, self.object_name, self.name,
                                              input_data.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name)

        if errors_found:
            from UtilityRoutines import ShowFatalError
            ShowFatalError(state, f"{routine_name}Errors found in getting {self.object_name} input. Preceding condition(s) causes termination.")

    def __init_from_input__(self, state: Any, name_to_find: str) -> None:
        object_name = CoilCoolingDXCurveFitPerformance.object_name
        input_processor = state.dataInputProcessing.inputProcessor
        
        performance_instances = input_processor.epJSON.get(object_name)
        if performance_instances is None:
            return
        
        performance_schema_props = input_processor.getObjectSchemaProps(state, object_name)
        found_it = False
        
        for performance_name, performance_fields in performance_instances.items():
            from Util import SameString, makeUPPER
            perf_name_upper = makeUPPER(performance_name)
            if not SameString(name_to_find, perf_name_upper):
                continue
            
            found_it = True
            input_specs = CoilCoolingDXCurveFitPerformanceInputSpecification()
            input_specs.name = perf_name_upper
            input_specs.crankcase_heater_capacity = input_processor.getRealFieldValue(performance_fields, performance_schema_props, "crankcase_heater_capacity")
            input_specs.minimum_outdoor_dry_bulb_temperature_for_compressor_operation = input_processor.getRealFieldValue(
                performance_fields, performance_schema_props, "minimum_outdoor_dry_bulb_temperature_for_compressor_operation")
            input_specs.maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation = input_processor.getRealFieldValue(
                performance_fields, performance_schema_props, "maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation")
            input_specs.unit_internal_static_air_pressure = input_processor.getRealFieldValue(
                performance_fields, performance_schema_props, "unit_internal_static_air_pressure")
            input_specs.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name = input_processor.getAlphaFieldValue(
                performance_fields, performance_schema_props, "crankcase_heater_capacity_function_of_temperature_curve_name")
            input_specs.capacity_control = input_processor.getAlphaFieldValue(
                performance_fields, performance_schema_props, "capacity_control_method")
            input_specs.basin_heater_capacity = input_processor.getRealFieldValue(
                performance_fields, performance_schema_props, "evaporative_condenser_basin_heater_capacity")
            input_specs.basin_heater_setpoint_temperature = input_processor.getRealFieldValue(
                performance_fields, performance_schema_props, "evaporative_condenser_basin_heater_setpoint_temperature")
            input_specs.basin_heater_operating_schedule_name = input_processor.getAlphaFieldValue(
                performance_fields, performance_schema_props, "evaporative_condenser_basin_heater_operating_schedule_name")
            input_specs.compressor_fuel_type = input_processor.getAlphaFieldValue(
                performance_fields, performance_schema_props, "compressor_fuel_type")
            input_specs.base_operating_mode_name = input_processor.getAlphaFieldValue(
                performance_fields, performance_schema_props, "base_operating_mode")
            input_specs.alternate_operating_mode_name = input_processor.getAlphaFieldValue(
                performance_fields, performance_schema_props, "alternative_operating_mode_1")
            input_specs.alternate_operating_mode2_name = input_processor.getAlphaFieldValue(
                performance_fields, performance_schema_props, "alternative_operating_mode_2")

            self.instantiateFromInputSpec(state, input_specs)
            input_processor.markObjectAsUsed(object_name, performance_name)
            break

        if not found_it:
            from UtilityRoutines import ShowFatalError
            ShowFatalError(state, f"Could not find Coil:Cooling:DX:Performance object with name: {name_to_find}")

    def simulate(
        self,
        state: Any,
        inletNode: Any,
        outletNode: Any,
        currentCoilMode: Any,
        speedNum: int,
        speedRatio: float,
        fanOp: Any,
        condInletNode: Any,
        condOutletNode: Any,
        singleMode: bool,
        LoadSHR: float = 0.0,
    ) -> None:
        from Constant import rSecsInHour
        from HVAC import CoilMode
        from Psychrometrics import PsyTdbFnHW, PsyTsatFnHPb, PsyWFnTdbH
        from GeneralRoutines import CalcComponentSensibleLatentOutput
        from Curve import CurveValue

        reporting_constant = state.dataHVACGlobal.TimeStepSys * rSecsInHour
        self.recoveredEnergyRate = 0.0
        self.NormalSHR = 0.0

        if currentCoilMode == CoilMode.SubcoolReheat:
            total_cooling_rate = 0.0
            sens_nor_rate = 0.0
            sens_sub_rate = 0.0
            sens_reh_rate = 0.0
            lat_rate = 0.0
            sys_nor_shr = 0.0
            sys_sub_shr = 0.0
            sys_reh_shr = 0.0
            hum_rat_nor_out = 0.0
            temp_nor_out = 0.0
            enthalpy_nor_out = 0.0
            mode_ratio = 0.0

            self.calculate(state, self.normalMode, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
            CalcComponentSensibleLatentOutput(
                outletNode.MassFlowRate, inletNode.Temp, inletNode.HumRat, outletNode.Temp, outletNode.HumRat, sens_nor_rate, lat_rate, total_cooling_rate)
            
            if total_cooling_rate > 1.0e-10:
                self.OperatingMode = 1
                self.NormalSHR = sens_nor_rate / total_cooling_rate
                self.powerUse = self.normalMode.OpModePower
                self.RTF = self.normalMode.OpModeRTF
                self.wasteHeatRate = self.normalMode.OpModeWasteHeat

            if speedRatio != 0.0 and LoadSHR != 0.0:
                if total_cooling_rate == 0.0:
                    sys_nor_shr = 1.0
                else:
                    sys_nor_shr = sens_nor_rate / total_cooling_rate
                
                hum_rat_nor_out = outletNode.HumRat
                temp_nor_out = outletNode.Temp
                enthalpy_nor_out = outletNode.Enthalpy
                self.recoveredEnergyRate = sens_nor_rate

                if LoadSHR < sys_nor_shr:
                    outletNode.MassFlowRate = inletNode.MassFlowRate
                    self.calculate(state, self.alternateMode, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
                    CalcComponentSensibleLatentOutput(outletNode.MassFlowRate, inletNode.Temp, inletNode.HumRat, outletNode.Temp, outletNode.HumRat,
                                                      sens_sub_rate, lat_rate, total_cooling_rate)
                    sys_sub_shr = sens_sub_rate / total_cooling_rate
                    
                    if LoadSHR < sys_sub_shr:
                        outletNode.MassFlowRate = inletNode.MassFlowRate
                        self.calculate(state, self.alternateMode2, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)
                        CalcComponentSensibleLatentOutput(outletNode.MassFlowRate, inletNode.Temp, inletNode.HumRat, outletNode.Temp, outletNode.HumRat,
                                                          sens_reh_rate, lat_rate, total_cooling_rate)
                        sys_reh_shr = sens_reh_rate / total_cooling_rate
                        
                        if LoadSHR > sys_reh_shr:
                            mode_ratio = (LoadSHR - sys_nor_shr) / (sys_reh_shr - sys_nor_shr)
                            self.OperatingMode = 3
                            outletNode.HumRat = hum_rat_nor_out * (1.0 - mode_ratio) + mode_ratio * outletNode.HumRat
                            outletNode.Enthalpy = enthalpy_nor_out * (1.0 - mode_ratio) + mode_ratio * outletNode.Enthalpy
                            outletNode.Temp = PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
                            self.ModeRatio = mode_ratio
                            self.powerUse = self.normalMode.OpModePower * (1.0 - mode_ratio) + mode_ratio * self.alternateMode2.OpModePower
                            self.RTF = self.normalMode.OpModeRTF * (1.0 - mode_ratio) + mode_ratio * self.alternateMode2.OpModeRTF
                            self.wasteHeatRate = self.normalMode.OpModeWasteHeat * (1.0 - mode_ratio) + mode_ratio * self.alternateMode2.OpModeWasteHeat
                            self.recoveredEnergyRate = (self.recoveredEnergyRate - sens_reh_rate) * self.ModeRatio
                        else:
                            self.ModeRatio = 1.0
                            self.OperatingMode = 3
                            self.recoveredEnergyRate = (self.recoveredEnergyRate - sens_reh_rate) * self.ModeRatio
                    else:
                        mode_ratio = (LoadSHR - sys_nor_shr) / (sys_sub_shr - sys_nor_shr)
                        self.OperatingMode = 2
                        outletNode.HumRat = hum_rat_nor_out * (1.0 - mode_ratio) + mode_ratio * outletNode.HumRat
                        outletNode.Enthalpy = enthalpy_nor_out * (1.0 - mode_ratio) + mode_ratio * outletNode.Enthalpy
                        outletNode.Temp = PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)
                        self.ModeRatio = mode_ratio
                        self.powerUse = self.normalMode.OpModePower * (1.0 - mode_ratio) + mode_ratio * self.alternateMode.OpModePower
                        self.RTF = self.normalMode.OpModeRTF * (1.0 - mode_ratio) + mode_ratio * self.alternateMode.OpModeRTF
                        self.wasteHeatRate = self.normalMode.OpModeWasteHeat * (1.0 - mode_ratio) + mode_ratio * self.alternateMode.OpModeWasteHeat
                        self.recoveredEnergyRate = (self.recoveredEnergyRate - sens_sub_rate) * self.ModeRatio
                else:
                    self.ModeRatio = 0.0
                    self.OperatingMode = 1
                    self.recoveredEnergyRate = 0.0

                tsat = PsyTsatFnHPb(state, outletNode.Enthalpy, inletNode.Press)
                if outletNode.Temp < tsat:
                    outletNode.Temp = tsat
                    outletNode.HumRat = PsyWFnTdbH(state, tsat, outletNode.Enthalpy)

        elif currentCoilMode == CoilMode.Enhanced:
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
                self.crankcaseHeaterPower *= CurveValue(state, self.crankcaseHeaterCapacityCurveIndex, state.dataEnvrn.OutDryBulbTemp)
        else:
            self.crankcaseHeaterPower = 0.0
        
        self.crankcaseHeaterPower = self.crankcaseHeaterPower * (1.0 - self.RTF)
        self.crankcaseHeaterElectricityConsumption = self.crankcaseHeaterPower * reporting_constant

        if self.evapCondBasinHeatSched is not None:
            current_basin_heater_avail = self.evapCondBasinHeatSched.getCurrentVal()
            if self.evapCondBasinHeatCap > 0.0 and current_basin_heater_avail > 0.0:
                self.basinHeaterPower = max(0.0, self.evapCondBasinHeatCap * (self.evapCondBasinHeatSetpoint - state.dataEnvrn.OutDryBulbTemp))
        else:
            if self.evapCondBasinHeatCap > 0.0:
                self.basinHeaterPower = max(0.0, self.evapCondBasinHeatCap * (self.evapCondBasinHeatSetpoint - state.dataEnvrn.OutDryBulbTemp))
        
        self.basinHeaterPower *= (1.0 - self.RTF)
        self.electricityConsumption = self.powerUse * reporting_constant

        from Constant import eFuel
        if self.compressorFuelType != eFuel.Electricity:
            self.compressorFuelRate = self.powerUse
            self.compressorFuelConsumption = self.electricityConsumption
            self.powerUse = 0.0
            self.electricityConsumption = 0.0

    def size(self, state: Any) -> None:
        if not state.dataGlobal.SysSizingCalc and self.mySizeFlag:
            self.normalMode.parentName = self.parentName
            self.normalMode.size(state)
            
            from HVAC import CoilMode
            if self.maxAvailCoilMode == CoilMode.Enhanced:
                self.alternateMode.size(state)
            if self.maxAvailCoilMode == CoilMode.SubcoolReheat:
                self.alternateMode.size(state)
                self.alternateMode2.size(state)
            self.mySizeFlag = False
        
        self.oneTimeAvailSchedSetup()
        self.oneTimeMinOATSetup()

    def calculate(
        self,
        state: Any,
        currentMode: Any,
        inletNode: Any,
        outletNode: Any,
        speedNum: int,
        speedRatio: float,
        fanOp: Any,
        condInletNode: Any,
        condOutletNode: Any,
        singleMode: bool,
    ) -> None:
        currentMode.CalcOperatingMode(state, inletNode, outletNode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode)

    def calcStandardRatings210240(self, state: Any) -> None:
        num_of_reduced_cap = 4
        tot_cap_flow_mod_fac = 0.0
        eir_flow_mod_fac = 0.0
        tot_cap_temp_mod_fac = 0.0
        eir_temp_mod_fac = 0.0
        tot_cooling_cap_ahri = 0.0
        net_cooling_cap_ahri = 0.0
        net_cooling_cap_ahri2023 = 0.0
        total_elec_power = 0.0
        total_elec_power2023 = 0.0
        total_elec_power_rated = 0.0
        total_elec_power_rated2023 = 0.0
        eir = 0.0
        part_load_factor = 0.0
        eer_reduced = 0.0
        elec_power_reduced_cap = 0.0
        net_cooling_cap_reduced = 0.0
        load_factor = 0.0
        degradation_coeff = 0.0
        outdoor_unit_inlet_air_dry_bulb_temp_reduced = 0.0

        default_fan_power_per_evap_air_flow_rate = 773.3
        default_fan_power_per_evap_air_flow_rate2023 = 934.4
        cooling_coil_inlet_air_wet_bulb_temp_rated = 19.44
        outdoor_unit_inlet_air_dry_bulb_temp = 27.78
        outdoor_unit_inlet_air_dry_bulb_temp_rated = 35.0
        air_mass_flow_ratio_rated = 1.0
        plr_for_seer = 0.5
        reduced_plr = [1.0, 0.75, 0.50, 0.25]
        ieer_weighting_factor = [0.020, 0.617, 0.238, 0.125]
        oa_db_temp_low_reduced_capacity_test = 18.3
        cyclic_degradation_coefficient = 0.20

        mode = self.normalMode
        speed = mode.speeds[-1]

        fan_power_per_evap_air_flow_rate = default_fan_power_per_evap_air_flow_rate
        if speed.rated_evap_fan_power_per_volume_flow_rate > 0.0:
            fan_power_per_evap_air_flow_rate = speed.rated_evap_fan_power_per_volume_flow_rate

        fan_power_per_evap_air_flow_rate2023 = default_fan_power_per_evap_air_flow_rate2023
        if speed.rated_evap_fan_power_per_volume_flow_rate_2023 > 0.0:
            fan_power_per_evap_air_flow_rate2023 = speed.rated_evap_fan_power_per_volume_flow_rate_2023

        from Curve import CurveValue
        from StandardRatings import SEER2CalculationCurveFit, IEERCalculationCurveFit
        from HVAC import CoilType

        if mode.ratedGrossTotalCap > 0.0:
            tot_cap_flow_mod_fac = CurveValue(state, speed.indexCapFFF, air_mass_flow_ratio_rated)
            tot_cap_temp_mod_fac = CurveValue(state, speed.indexCapFT, cooling_coil_inlet_air_wet_bulb_temp_rated, outdoor_unit_inlet_air_dry_bulb_temp)
            tot_cooling_cap_ahri = mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac
            self.standardRatingCoolingCapacity = tot_cooling_cap_ahri - fan_power_per_evap_air_flow_rate * mode.ratedEvapAirFlowRate
            self.standardRatingCoolingCapacity2023 = tot_cooling_cap_ahri - fan_power_per_evap_air_flow_rate2023 * mode.ratedEvapAirFlowRate

            tot_cap_temp_mod_fac = CurveValue(state, speed.indexCapFT, cooling_coil_inlet_air_wet_bulb_temp_rated, outdoor_unit_inlet_air_dry_bulb_temp)
            tot_cooling_cap_ahri = mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac
            eir_temp_mod_fac = CurveValue(state, speed.indexEIRFT, cooling_coil_inlet_air_wet_bulb_temp_rated, outdoor_unit_inlet_air_dry_bulb_temp)
            eir_flow_mod_fac = CurveValue(state, speed.indexEIRFFF, air_mass_flow_ratio_rated)
            if speed.ratedCOP > 0.0:
                eir = eir_temp_mod_fac * eir_flow_mod_fac / speed.ratedCOP
            else:
                eir = 0.0

            net_cooling_cap_ahri = tot_cooling_cap_ahri - fan_power_per_evap_air_flow_rate * mode.ratedEvapAirFlowRate
            total_elec_power = eir * tot_cooling_cap_ahri + fan_power_per_evap_air_flow_rate * mode.ratedEvapAirFlowRate
            net_cooling_cap_ahri2023 = tot_cooling_cap_ahri - fan_power_per_evap_air_flow_rate2023 * mode.ratedEvapAirFlowRate
            total_elec_power2023 = eir * tot_cooling_cap_ahri + fan_power_per_evap_air_flow_rate2023 * mode.ratedEvapAirFlowRate

            part_load_factor = CurveValue(state, speed.indexPLRFPLF, plr_for_seer)
            part_load_factor_standard = 1.0 - (1.0 - plr_for_seer) * cyclic_degradation_coefficient
            
            if total_elec_power > 0.0:
                self.standardRatingSEER = (net_cooling_cap_ahri / total_elec_power) * part_load_factor
                self.standardRatingSEER_Standard = (net_cooling_cap_ahri / total_elec_power) * part_load_factor_standard
            else:
                self.standardRatingSEER = 0.0
                self.standardRatingSEER2_Standard = 0.0

            if total_elec_power2023 > 0.0:
                self.standardRatingSEER2_User = (net_cooling_cap_ahri2023 / total_elec_power2023) * part_load_factor
                self.standardRatingSEER2_Standard = (net_cooling_cap_ahri2023 / total_elec_power2023) * part_load_factor_standard
            else:
                self.standardRatingSEER2_User = 0.0
                self.standardRatingSEER2_Standard = 0.0

            tot_cap_temp_mod_fac = CurveValue(state, speed.indexCapFT, cooling_coil_inlet_air_wet_bulb_temp_rated, outdoor_unit_inlet_air_dry_bulb_temp_rated)
            self.standardRatingCoolingCapacity = mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac - fan_power_per_evap_air_flow_rate * mode.ratedEvapAirFlowRate
            self.standardRatingCoolingCapacity2023 = mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac - fan_power_per_evap_air_flow_rate2023 * mode.ratedEvapAirFlowRate
            eir_temp_mod_fac = CurveValue(state, speed.indexEIRFT, cooling_coil_inlet_air_wet_bulb_temp_rated, outdoor_unit_inlet_air_dry_bulb_temp_rated)
            if speed.ratedCOP > 0.0:
                eir = eir_temp_mod_fac * eir_flow_mod_fac / speed.ratedCOP
            else:
                eir = 0.0
            
            total_elec_power_rated = eir * (mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac) + fan_power_per_evap_air_flow_rate * mode.ratedEvapAirFlowRate
            if total_elec_power_rated > 0.0:
                self.standardRatingEER = self.standardRatingCoolingCapacity / total_elec_power_rated
            else:
                self.standardRatingEER = 0.0
            
            total_elec_power_rated2023 = eir * (mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac) + fan_power_per_evap_air_flow_rate2023 * mode.ratedEvapAirFlowRate
            if total_elec_power_rated2023 > 0.0:
                self.standardRatingEER2 = self.standardRatingCoolingCapacity2023 / total_elec_power_rated2023
            else:
                self.standardRatingEER2 = 0.0

            from CoilCoolingDXCurveFitOperatingMode import CoilCoolingDXCurveFitOperatingMode
            if mode.condenserType == CoilCoolingDXCurveFitOperatingMode.CondenserType.AIRCOOLED:
                self.standardRatingCoolingCapacity2023, self.standardRatingSEER2_User, self.standardRatingSEER2_Standard, self.standardRatingEER2 = \
                    SEER2CalculationCurveFit(state, CoilType.CoolingDXCurveFit, self.normalMode)

            self.standardRatingIEER = 0.0
            tot_cap_temp_mod_fac = CurveValue(state, speed.indexCapFT, cooling_coil_inlet_air_wet_bulb_temp_rated, outdoor_unit_inlet_air_dry_bulb_temp_rated)
            self.standardRatingCoolingCapacity = mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac - fan_power_per_evap_air_flow_rate * mode.ratedEvapAirFlowRate
            
            for red_cap_num in range(num_of_reduced_cap):
                if reduced_plr[red_cap_num] > 0.444:
                    outdoor_unit_inlet_air_dry_bulb_temp_reduced = 5.0 + 30.0 * reduced_plr[red_cap_num]
                else:
                    outdoor_unit_inlet_air_dry_bulb_temp_reduced = oa_db_temp_low_reduced_capacity_test
                
                tot_cap_temp_mod_fac = CurveValue(state, speed.indexCapFT, cooling_coil_inlet_air_wet_bulb_temp_rated, outdoor_unit_inlet_air_dry_bulb_temp_reduced)
                net_cooling_cap_reduced = mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac - fan_power_per_evap_air_flow_rate * mode.ratedEvapAirFlowRate
                eir_temp_mod_fac = CurveValue(state, speed.indexEIRFT, cooling_coil_inlet_air_wet_bulb_temp_rated, outdoor_unit_inlet_air_dry_bulb_temp_reduced)
                eir_flow_mod_fac = CurveValue(state, speed.indexEIRFFF, air_mass_flow_ratio_rated)
                if speed.ratedCOP > 0.0:
                    eir = eir_temp_mod_fac * eir_flow_mod_fac / speed.ratedCOP
                else:
                    eir = 0.0
                
                if net_cooling_cap_reduced > 0.0:
                    load_factor = reduced_plr[red_cap_num] * self.standardRatingCoolingCapacity / net_cooling_cap_reduced
                else:
                    load_factor = 1.0
                
                degradation_coeff = 1.130 - 0.130 * load_factor
                elec_power_reduced_cap = degradation_coeff * eir * (mode.ratedGrossTotalCap * tot_cap_temp_mod_fac * tot_cap_flow_mod_fac)
                eer_reduced = (load_factor * net_cooling_cap_reduced) / (load_factor * elec_power_reduced_cap + fan_power_per_evap_air_flow_rate * mode.ratedEvapAirFlowRate)
                self.standardRatingIEER += ieer_weighting_factor[red_cap_num] * eer_reduced

            self.standardRatingIEER2, self.standardRatingCoolingCapacity2023, self.standardRatingEER2 = \
                IEERCalculationCurveFit(state, CoilType.CoolingDXCurveFit, self.normalMode)

        else:
            from UtilityRoutines import ShowSevereError
            ShowSevereError(state,
                f"Standard Ratings: Coil:Cooling:DX {self.name} has zero rated total cooling capacity. Standard ratings cannot be calculated.")

    def setOperMode(self, state: Any, currentMode: Any, mode: int) -> None:
        from UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError
        
        errors_found = False
        num_speeds = len(currentMode.speeds)
        
        for speed_num in range(num_speeds):
            currentMode.speeds[speed_num].parentOperatingMode = mode
            if mode == 2:
                if currentMode.speeds[speed_num].indexSHRFT == 0:
                    ShowSevereError(state,
                        f"{currentMode.speeds[speed_num].object_name}=\"{currentMode.speeds[speed_num].name}\", Curve check:")
                    ShowContinueError(state,
                        "The input of Sensible Heat Ratio Modifier Function of Temperature Curve Name is required, but not available for SubcoolReheat mode. Please input")
                    errors_found = True
                if currentMode.speeds[speed_num].indexSHRFFF == 0:
                    ShowSevereError(state,
                        f"{currentMode.speeds[speed_num].object_name}=\"{currentMode.speeds[speed_num].name}\", Curve check:")
                    ShowContinueError(state,
                        "The input of Sensible Heat Ratio Modifier Function of Flow Fraction Curve Name is required, but not available for SubcoolReheat mode. Please input")
                    errors_found = True
            if mode == 3:
                if currentMode.speeds[speed_num].indexSHRFT == 0:
                    ShowSevereError(state,
                        f"{currentMode.speeds[speed_num].object_name}=\"{currentMode.speeds[speed_num].name}\", Curve check:")
                    ShowContinueError(state,
                        "The input of Sensible Heat Ratio Modifier Function of Temperature Curve Name is required, but not available for SubcoolReheat mode. Please input")
                    errors_found = True
                if currentMode.speeds[speed_num].indexSHRFFF == 0:
                    ShowSevereError(state,
                        f"{currentMode.speeds[speed_num].object_name}=\"{currentMode.speeds[speed_num].name}\", Curve check:")
                    ShowContinueError(state,
                        "The input of Sensible Heat Ratio Modifier Function of Flow Fraction Curve Name is required, but not available for SubcoolReheat mode. Please input")
                    errors_found = True
        
        if errors_found:
            ShowFatalError(state,
                f"CoilCoolingDXCurveFitPerformance: Errors found in getting {self.object_name} input. Preceding condition(s) causes termination.")

    def oneTimeAvailSchedSetup(self) -> None:
        if self.myOneTimeAvailSchedInitFlag:
            self.normalMode.coilCoolingDXAvailSched = self.coilCoolingDXAvailSched
            self.alternateMode.coilCoolingDXAvailSched = self.normalMode.coilCoolingDXAvailSched
            self.alternateMode2.coilCoolingDXAvailSched = self.normalMode.coilCoolingDXAvailSched
            self.myOneTimeAvailSchedInitFlag = False

    def oneTimeMinOATSetup(self) -> None:
        if self.myOneTimeMinOATFlag:
            self.normalMode.minOutdoorDrybulb = self.minOutdoorDrybulb
            self.alternateMode.minOutdoorDrybulb = self.normalMode.minOutdoorDrybulb
            self.alternateMode2.minOutdoorDrybulb = self.normalMode.minOutdoorDrybulb
            self.myOneTimeMinOATFlag = False

    def ratedCBF(self, state: Any) -> float:
        return self.normalMode.speeds[self.normalMode.nominalSpeedIndex].RatedCBF

    def grossRatedSHR(self, state: Any) -> float:
        return self.normalMode.speeds[self.normalMode.nominalSpeedIndex].grossRatedSHR

    def grossRatedCoolingCOPAtMaxSpeed(self, state: Any) -> float:
        return self.normalMode.speeds[-1].original_input_specs.gross_rated_cooling_COP

    def nameAtSpeed(self, speed: int) -> str:
        return self.normalMode.speeds[speed].name

    def ratedAirMassFlowRateMaxSpeed(self, state: Any, mode: Any) -> float:
        from HVAC import CoilMode
        if mode != CoilMode.Normal:
            return self.alternateMode.speeds[-1].RatedAirMassFlowRate
        return self.normalMode.speeds[-1].RatedAirMassFlowRate

    def ratedAirMassFlowRateMinSpeed(self, state: Any, mode: Any) -> float:
        from HVAC import CoilMode
        if mode != CoilMode.Normal:
            return self.alternateMode.speeds[0].RatedAirMassFlowRate
        return self.normalMode.speeds[0].RatedAirMassFlowRate

    def ratedCondAirMassFlowRateNomSpeed(self, state: Any, mode: Any) -> float:
        from HVAC import CoilMode
        if mode != CoilMode.Normal:
            return self.alternateMode.speeds[self.alternateMode.nominalSpeedIndex].RatedCondAirMassFlowRate
        return self.normalMode.speeds[self.normalMode.nominalSpeedIndex].RatedCondAirMassFlowRate

    def ratedEvapAirMassFlowRate(self, state: Any) -> float:
        return self.normalMode.ratedEvapAirMassFlowRate

    def ratedEvapAirFlowRate(self, state: Any) -> float:
        return self.normalMode.ratedEvapAirFlowRate

    def ratedGrossTotalCap(self) -> float:
        return self.normalMode.ratedGrossTotalCap

    def indexCapFT(self, mode: Any) -> int:
        from HVAC import CoilMode
        if mode != CoilMode.Normal:
            return self.alternateMode.speeds[self.alternateMode.nominalSpeedIndex].indexCapFT
        return self.normalMode.speeds[self.normalMode.nominalSpeedIndex].indexCapFT

    def subcoolReheatFlag(self) -> bool:
        return (
            self.original_input_specs.base_operating_mode_name != "" and
            self.original_input_specs.alternate_operating_mode_name != "" and
            self.original_input_specs.alternate_operating_mode2_name != ""
        )

    def numSpeeds(self) -> int:
        return len(self.normalMode.speeds)

    def setToHundredPercentDOAS(self) -> None:
        from HVAC import MinRatedVolFlowPerRatedTotCap2, MaxRatedVolFlowPerRatedTotCap2, CoilMode
        
        for speed in self.normalMode.speeds:
            speed.minRatedVolFlowPerRatedTotCap = MinRatedVolFlowPerRatedTotCap2
            speed.maxRatedVolFlowPerRatedTotCap = MaxRatedVolFlowPerRatedTotCap2
        
        if self.maxAvailCoilMode != CoilMode.Normal:
            for speed in self.alternateMode.speeds:
                speed.minRatedVolFlowPerRatedTotCap = MinRatedVolFlowPerRatedTotCap2
                speed.maxRatedVolFlowPerRatedTotCap = MaxRatedVolFlowPerRatedTotCap2

    def evapAirFlowRateAtSpeedIndex(self, state: Any, index: int) -> float:
        return self.normalMode.speeds[index].evap_air_flow_rate

    def ratedTotalCapacityAtSpeedIndex(self, state: Any, index: int) -> float:
        return self.normalMode.speeds[index].rated_total_capacity

    def currentEvapCondPumpPowerAtSpeed(self, state: Any, speed: int) -> float:
        return self.normalMode.getCurrentEvapCondPumpPower(speed)

    def evapCondenserEffectivenessAtSpeedIndex(self, state: Any, index: int) -> float:
        return self.normalMode.speeds[index].evap_condenser_effectiveness

    def evapAirFlowFraction(self, state: Any) -> float:
        return self.normalMode.speeds[0].original_input_specs.evaporator_air_flow_fraction
