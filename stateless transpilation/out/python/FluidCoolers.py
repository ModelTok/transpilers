# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container (passed as parameter)
# - DataPlant.PlantEquipmentType: enum
# - DataPlant.LoopDemandCalcScheme: enum
# - DataPlant.FlowLock: enum
# - DataBranchAirLoopPlant.MassFlowTolerance: float constant
# - PlantLocation: struct
# - PlantComponent: base class
# - BaseGlobalStruct: base class
# - Node, Psychrometrics, OutAirNodeManager, OutputProcessor, OutputReportPredefined, GlobalNames
# - PlantUtilities, Autosizing.BaseSizer, BranchNodeConnections, UtilityRoutines, General, HVAC
# - Constant (units/resources), DataSizing, DataLoopNode, DataEnvironment, DataHVACGlobals

from enum import IntEnum
from typing import List, Optional, Tuple, Any, Protocol, Callable
from dataclasses import dataclass, field

class PerfInputMethod(IntEnum):
    INVALID = -1
    NOMINAL_CAPACITY = 0
    U_FACTOR = 1
    NUM = 2

@dataclass
class FluidCoolerspecs:
    Name: str = ""
    FluidCoolerType: Any = None
    PerformanceInputMethod_Num: PerfInputMethod = PerfInputMethod.NOMINAL_CAPACITY
    Available: bool = True
    ON: bool = True
    DesignWaterFlowRate: float = 0.0
    DesignWaterFlowRateWasAutoSized: bool = False
    DesWaterMassFlowRate: float = 0.0
    HighSpeedAirFlowRate: float = 0.0
    HighSpeedAirFlowRateWasAutoSized: bool = False
    HighSpeedFanPower: float = 0.0
    HighSpeedFanPowerWasAutoSized: bool = False
    HighSpeedFluidCoolerUA: float = 0.0
    HighSpeedFluidCoolerUAWasAutoSized: bool = False
    LowSpeedAirFlowRate: float = 0.0
    LowSpeedAirFlowRateWasAutoSized: bool = False
    LowSpeedAirFlowRateSizingFactor: float = 0.0
    LowSpeedFanPower: float = 0.0
    LowSpeedFanPowerWasAutoSized: bool = False
    LowSpeedFanPowerSizingFactor: float = 0.0
    LowSpeedFluidCoolerUA: float = 0.0
    LowSpeedFluidCoolerUAWasAutoSized: bool = False
    LowSpeedFluidCoolerUASizingFactor: float = 0.0
    DesignEnteringWaterTemp: float = 0.0
    DesignLeavingWaterTemp: float = 0.0
    DesignEnteringAirTemp: float = 0.0
    DesignEnteringAirWetBulbTemp: float = 0.0
    FluidCoolerMassFlowRateMultiplier: float = 0.0
    FluidCoolerNominalCapacity: float = 0.0
    FluidCoolerLowSpeedNomCap: float = 0.0
    FluidCoolerLowSpeedNomCapWasAutoSized: bool = False
    FluidCoolerLowSpeedNomCapSizingFactor: float = 0.0
    WaterInletNodeNum: int = 0
    WaterOutletNodeNum: int = 0
    OutdoorAirInletNodeNum: int = 0
    HighMassFlowErrorCount: int = 0
    HighMassFlowErrorIndex: int = 0
    OutletWaterTempErrorCount: int = 0
    OutletWaterTempErrorIndex: int = 0
    SmallWaterMassFlowErrorCount: int = 0
    SmallWaterMassFlowErrorIndex: int = 0
    WMFRLessThanMinAvailErrCount: int = 0
    WMFRLessThanMinAvailErrIndex: int = 0
    WMFRGreaterThanMaxAvailErrCount: int = 0
    WMFRGreaterThanMaxAvailErrIndex: int = 0
    plantLoc: Any = None
    oneTimeInitFlag: bool = True
    beginEnvrnInit: bool = True
    InletWaterTemp: float = 0.0
    OutletWaterTemp: float = 0.0
    WaterMassFlowRate: float = 0.0
    Qactual: float = 0.0
    FanPower: float = 0.0
    FanEnergy: float = 0.0
    WaterTemp: float = 0.0
    AirTemp: float = 0.0
    AirHumRat: float = 0.0
    AirPress: float = 0.0
    AirWetBulb: float = 0.0
    indexInArray: int = 0

    def one_time_init(self, state: Any) -> None:
        pass

    def one_time_init_new(self, state: Any) -> None:
        self.setup_output_vars(state)
        errors_found = False
        PlantUtilities.scan_plant_loops_for_object(
            state, self.Name, self.FluidCoolerType, self.plantLoc, errors_found
        )
        if errors_found:
            UtilityRoutines.show_fatal_error(
                state, "InitFluidCooler: Program terminated due to previous condition(s)."
            )

    def init_each_environment(self, state: Any) -> None:
        routine_name = "FluidCoolerspecs::initEachEnvironment"
        rho = self.plantLoc.loop.glycol.get_density(state, Constant.InitConvTemp, routine_name)
        self.DesWaterMassFlowRate = self.DesignWaterFlowRate * rho
        PlantUtilities.init_component_nodes(
            state, 0.0, self.DesWaterMassFlowRate, self.WaterInletNodeNum, self.WaterOutletNodeNum
        )

    def initialize(self, state: Any) -> None:
        if self.beginEnvrnInit and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.init_each_environment(state)
            self.beginEnvrnInit = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.beginEnvrnInit = True

        self.WaterTemp = state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp

        if self.OutdoorAirInletNodeNum != 0:
            self.AirTemp = state.dataLoopNodes.Node(self.OutdoorAirInletNodeNum).Temp
            self.AirHumRat = state.dataLoopNodes.Node(self.OutdoorAirInletNodeNum).HumRat
            self.AirPress = state.dataLoopNodes.Node(self.OutdoorAirInletNodeNum).Press
            self.AirWetBulb = state.dataLoopNodes.Node(self.OutdoorAirInletNodeNum).OutAirWetBulb
        else:
            self.AirTemp = state.dataEnvrn.OutDryBulbTemp
            self.AirHumRat = state.dataEnvrn.OutHumRat
            self.AirPress = state.dataEnvrn.OutBaroPress
            self.AirWetBulb = state.dataEnvrn.OutWetBulbTemp

        self.WaterMassFlowRate = PlantUtilities.regulate_condenser_comp_flow_req_op(
            state, self.plantLoc, self.DesWaterMassFlowRate * self.FluidCoolerMassFlowRateMultiplier
        )

        PlantUtilities.set_component_flow_rate(
            state, self.WaterMassFlowRate, self.WaterInletNodeNum, self.WaterOutletNodeNum, self.plantLoc
        )

    def setup_output_vars(self, state: Any) -> None:
        OutputProcessor.setup_output_variable(
            state, "Cooling Tower Inlet Temperature", Constant.Units.C, self.InletWaterTemp,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.setup_output_variable(
            state, "Cooling Tower Outlet Temperature", Constant.Units.C, self.OutletWaterTemp,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.setup_output_variable(
            state, "Cooling Tower Mass Flow Rate", Constant.Units.kg_s, self.WaterMassFlowRate,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.setup_output_variable(
            state, "Cooling Tower Heat Transfer Rate", Constant.Units.W, self.Qactual,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.setup_output_variable(
            state, "Cooling Tower Fan Electricity Rate", Constant.Units.W, self.FanPower,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name
        )
        OutputProcessor.setup_output_variable(
            state, "Cooling Tower Fan Electricity Energy", Constant.Units.J, self.FanEnergy,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name,
            Constant.eResource.Electricity, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.HeatRejection
        )

    def size(self, state: Any) -> None:
        max_ite = 500
        acc = 0.0001
        called_from = "SizeFluidCooler"

        tmp_design_water_flow_rate = self.DesignWaterFlowRate
        tmp_high_speed_air_flow_rate = self.HighSpeedAirFlowRate
        plt_siz_cond_num = self.plantLoc.loop.PlantSizNum

        def ensure_sizing_plant_exit_temp_is_not_less_than_design_entering_air_temp():
            if (state.dataSize.PlantSizData(plt_siz_cond_num).ExitTemp <= self.DesignEnteringAirTemp and
                state.dataPlnt.PlantFirstSizesOkayToFinalize):
                UtilityRoutines.show_severe_error(
                    state, f"Error when autosizing the UA value for fluid cooler = {self.Name}."
                )
                UtilityRoutines.show_continue_error(
                    state, f"Design Loop Exit Temperature ({state.dataSize.PlantSizData(plt_siz_cond_num).ExitTemp:.2f} C) must be greater than "
                    f"design entering air dry-bulb temperature ({self.DesignEnteringAirTemp:.2f} C) when autosizing the fluid cooler UA."
                )
                UtilityRoutines.show_continue_error(state,
                    "It is recommended that the Design Loop Exit Temperature = design inlet air dry-bulb temp plus the Fluid Cooler "
                    "design approach temperature (e.g., 4 C)."
                )
                UtilityRoutines.show_continue_error(state,
                    "If using HVACTemplate:Plant:ChilledWaterLoop, then check that input field Condenser Water Design Setpoint must be "
                    "> design inlet air dry-bulb temp if autosizing the Fluid Cooler."
                )
                UtilityRoutines.show_fatal_error(state, "Review and revise design input values as appropriate.")

        if self.DesignWaterFlowRateWasAutoSized:
            if plt_siz_cond_num > 0:
                ensure_sizing_plant_exit_temp_is_not_less_than_design_entering_air_temp()
                if state.dataSize.PlantSizData(plt_siz_cond_num).DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                    tmp_design_water_flow_rate = state.dataSize.PlantSizData(plt_siz_cond_num).DesVolFlowRate
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.DesignWaterFlowRate = tmp_design_water_flow_rate
                else:
                    tmp_design_water_flow_rate = 0.0
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.DesignWaterFlowRate = tmp_design_water_flow_rate

                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.report_sizer_output(
                            state, DataPlant.PlantEquipTypeNames[int(self.FluidCoolerType)],
                            self.Name, "Design Water Flow Rate [m3/s]", self.DesignWaterFlowRate
                        )
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.report_sizer_output(
                            state, DataPlant.PlantEquipTypeNames[int(self.FluidCoolerType)],
                            self.Name, "Initial Design Water Flow Rate [m3/s]", self.DesignWaterFlowRate
                        )
                self.DesignLeavingWaterTemp = state.dataSize.PlantSizData(plt_siz_cond_num).ExitTemp
            else:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    UtilityRoutines.show_severe_error(
                        state, f"Autosizing error for fluid cooler object = {self.Name}"
                    )
                    UtilityRoutines.show_fatal_error(
                        state, "Autosizing of fluid cooler condenser flow rate requires a loop Sizing:Plant object."
                    )

        PlantUtilities.register_plant_comp_design_flow(state, self.WaterInletNodeNum, tmp_design_water_flow_rate)

        # High speed fan power autosizing
        if self.HighSpeedFanPowerWasAutoSized:
            if self.PerformanceInputMethod_Num == PerfInputMethod.NOMINAL_CAPACITY:
                tmp_high_speed_fan_power = 0.0105 * self.FluidCoolerNominalCapacity
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.HighSpeedFanPower = tmp_high_speed_fan_power
            else:
                des_fluid_cooler_load = 0.0
                if plt_siz_cond_num > 0:
                    if state.dataSize.PlantSizData(plt_siz_cond_num).DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                        ensure_sizing_plant_exit_temp_is_not_less_than_design_entering_air_temp()
                        rho = self.plantLoc.loop.glycol.get_density(state, Constant.InitConvTemp, called_from)
                        cp = self.plantLoc.loop.glycol.get_specific_heat(
                            state, state.dataSize.PlantSizData(plt_siz_cond_num).ExitTemp, called_from
                        )
                        des_fluid_cooler_load = rho * cp * tmp_design_water_flow_rate * state.dataSize.PlantSizData(plt_siz_cond_num).DeltaT
                        tmp_high_speed_fan_power = 0.0105 * des_fluid_cooler_load
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.HighSpeedFanPower = tmp_high_speed_fan_power
                    else:
                        tmp_high_speed_fan_power = 0.0
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.HighSpeedFanPower = tmp_high_speed_fan_power

            if self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_SingleSpd:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.report_sizer_output(
                            state, DataPlant.PlantEquipTypeNames[int(self.FluidCoolerType)],
                            self.Name, "Fan Power at Design Air Flow Rate [W]", self.HighSpeedFanPower
                        )

        # High speed air flow rate autosizing
        if self.HighSpeedAirFlowRateWasAutoSized:
            if self.PerformanceInputMethod_Num == PerfInputMethod.NOMINAL_CAPACITY:
                tmp_high_speed_air_flow_rate = (
                    self.FluidCoolerNominalCapacity / (self.DesignEnteringWaterTemp - self.DesignEnteringAirTemp) * 4.0
                )
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.HighSpeedAirFlowRate = tmp_high_speed_air_flow_rate

        if self.LowSpeedAirFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedAirFlowRate = self.LowSpeedAirFlowRateSizingFactor * self.HighSpeedAirFlowRate

        if self.LowSpeedFanPowerWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedFanPower = self.LowSpeedFanPowerSizingFactor * self.HighSpeedFanPower

        if self.LowSpeedFluidCoolerUAWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedFluidCoolerUA = self.LowSpeedFluidCoolerUASizingFactor * self.HighSpeedFluidCoolerUA

    def validate_single_speed_inputs(
        self, state: Any, current_module_object: str, alph_array: List[str],
        numeric_field_names: List[str], alpha_field_names: List[str]
    ) -> bool:
        errors_found = False

        if self.DesignEnteringWaterTemp <= 0.0:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object} = \"{alph_array[0]}\", invalid data for \"{numeric_field_names[2]}\", "
                f"entered value <= 0.0, but must be > 0 "
            )
            errors_found = True
        if self.DesignEnteringAirTemp <= 0.0:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object} = \"{alph_array[0]}\", invalid data for \"{numeric_field_names[3]}\", "
                f"entered value <= 0.0, but must be > 0 "
            )
            errors_found = True
        if self.DesignEnteringAirWetBulbTemp <= 0.0:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object} = \"{alph_array[0]}\", invalid data for \"{numeric_field_names[4]}\", "
                f"entered value <= 0.0, but must be > 0 "
            )
            errors_found = True
        if self.DesignEnteringWaterTemp <= self.DesignEnteringAirTemp:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object}= \"{alph_array[0]}\",{numeric_field_names[2]} must be greater than {numeric_field_names[3]}."
            )
            errors_found = True
        if self.DesignEnteringAirTemp <= self.DesignEnteringAirWetBulbTemp:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object}= \"{alph_array[0]}\",{numeric_field_names[3]} must be greater than {numeric_field_names[4]}."
            )
            errors_found = True

        if Util.same_string(alph_array[3], "UFactorTimesAreaAndDesignWaterFlowRate"):
            self.PerformanceInputMethod_Num = PerfInputMethod.U_FACTOR
            if self.HighSpeedFluidCoolerUA <= 0.0 and self.HighSpeedFluidCoolerUA != DataSizing.AutoSize:
                UtilityRoutines.show_severe_error(
                    state, f"{current_module_object} = \"{alph_array[0]}\", invalid data for \"{numeric_field_names[0]}\", "
                    f"entered value <= 0.0, but must be > 0 for {alpha_field_names[3]} = \"{alph_array[3]}\"."
                )
                errors_found = True
        elif Util.same_string(alph_array[3], "NominalCapacity"):
            self.PerformanceInputMethod_Num = PerfInputMethod.NOMINAL_CAPACITY
            if self.FluidCoolerNominalCapacity <= 0.0:
                UtilityRoutines.show_severe_error(
                    state, f"{current_module_object} = \"{alph_array[0]}\", invalid data for \"{numeric_field_names[1]}\", "
                    f"entered value <= 0.0, but must be > 0 for {alpha_field_names[3]} = \"{alph_array[3]}\"."
                )
                errors_found = True
            if self.HighSpeedFluidCoolerUA != 0.0:
                if self.HighSpeedFluidCoolerUA > 0.0:
                    UtilityRoutines.show_warning_error(
                        state, f"{current_module_object}= \"{self.Name}\". Nominal fluid cooler capacity and design fluid cooler UA have been specified."
                    )
                else:
                    UtilityRoutines.show_warning_error(
                        state, f"{current_module_object}= \"{self.Name}\". Nominal fluid cooler capacity has been specified and design fluid cooler UA is being autosized."
                    )
                UtilityRoutines.show_continue_error(state,
                    "Design fluid cooler UA field must be left blank when nominal fluid cooler capacity performance input method is used."
                )
                UtilityRoutines.show_continue_error(state, "Design fluid cooler UA value will be reset to zero and the simulation continuous.")
                self.HighSpeedFluidCoolerUA = 0.0
        else:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object}= \"{alph_array[0]}\", invalid {alpha_field_names[3]} = \"{alph_array[3]}\"."
            )
            UtilityRoutines.show_continue_error(state, "... must be \"UFactorTimesAreaAndDesignWaterFlowRate\" or \"NominalCapacity\".")
            errors_found = True

        return errors_found

    def validate_two_speed_inputs(
        self, state: Any, current_module_object: str, alph_array: List[str],
        numeric_field_names: List[str], alpha_field_names: List[str]
    ) -> bool:
        errors_found = False

        if self.DesignEnteringWaterTemp <= 0.0:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object} = \"{alph_array[0]}\", invalid data for \"{numeric_field_names[6]}\", "
                f"entered value <= 0.0, but must be > 0 "
            )
            errors_found = True
        if self.DesignEnteringAirTemp <= 0.0:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object} = \"{alph_array[0]}\", invalid data for \"{numeric_field_names[7]}\", "
                f"entered value <= 0.0, but must be > 0 "
            )
            errors_found = True
        if self.DesignEnteringAirWetBulbTemp <= 0.0:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object} = \"{alph_array[0]}\", invalid data for \"{numeric_field_names[8]}\", "
                f"entered value <= 0.0, but must be > 0 "
            )
            errors_found = True
        if self.DesignEnteringWaterTemp <= self.DesignEnteringAirTemp:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object} = \"{alph_array[0]}\", {numeric_field_names[6]} must be greater than {numeric_field_names[7]}."
            )
            errors_found = True
        if self.DesignEnteringAirTemp <= self.DesignEnteringAirWetBulbTemp:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object} = \"{alph_array[0]}\", {numeric_field_names[7]} must be greater than {numeric_field_names[8]}."
            )
            errors_found = True

        if Util.same_string(alph_array[3], "UFactorTimesAreaAndDesignWaterFlowRate"):
            self.PerformanceInputMethod_Num = PerfInputMethod.U_FACTOR
        elif Util.same_string(alph_array[3], "NominalCapacity"):
            self.PerformanceInputMethod_Num = PerfInputMethod.NOMINAL_CAPACITY
        else:
            UtilityRoutines.show_severe_error(
                state, f"{current_module_object}= \"{alph_array[0]}\", invalid {alpha_field_names[3]}= \"{alph_array[3]}\"."
            )
            UtilityRoutines.show_continue_error(state, "... must be \"UFactorTimesAreaAndDesignWaterFlowRate\" or \"NominalCapacity\".")
            errors_found = True

        return errors_found

    def calc_single_speed(self, state: Any) -> None:
        routine_name = "SingleSpeedFluidCooler"

        self.Qactual = 0.0
        self.FanPower = 0.0
        self.OutletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp

        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
            temp_set_point = self.plantLoc.side.TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
            temp_set_point = self.plantLoc.side.TempSetPointHi
        else:
            temp_set_point = 0.0

        if self.WaterMassFlowRate <= DataBranchAirLoopPlant.MassFlowTolerance:
            return

        if self.OutletWaterTemp < temp_set_point:
            return

        outlet_water_temp_off = state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp
        self.OutletWaterTemp = outlet_water_temp_off

        ua_design = self.HighSpeedFluidCoolerUA
        air_flow_rate = self.HighSpeedAirFlowRate
        fan_power_on = self.HighSpeedFanPower

        calc_fluid_cooler_outlet(state, self.indexInArray, self.WaterMassFlowRate, air_flow_rate, ua_design, self)

        if self.OutletWaterTemp <= temp_set_point:
            fan_mode_frac = 0.0
            if self.OutletWaterTemp != outlet_water_temp_off:
                fan_mode_frac = (temp_set_point - outlet_water_temp_off) / (self.OutletWaterTemp - outlet_water_temp_off)
            self.FanPower = max(fan_mode_frac * fan_power_on, 0.0)
            self.OutletWaterTemp = temp_set_point
        else:
            self.FanPower = fan_power_on

        cp_water = self.plantLoc.loop.glycol.get_specific_heat(
            state, state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp, routine_name
        )
        self.Qactual = self.WaterMassFlowRate * cp_water * (
            state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp - self.OutletWaterTemp
        )

    def calc_two_speed(self, state: Any) -> None:
        routine_name = "TwoSpeedFluidCooler"

        self.Qactual = 0.0
        self.FanPower = 0.0
        self.OutletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp

        if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
            temp_set_point = self.plantLoc.side.TempSetPoint
        elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
            temp_set_point = self.plantLoc.side.TempSetPointHi
        else:
            temp_set_point = 0.0

        if (self.WaterMassFlowRate <= DataBranchAirLoopPlant.MassFlowTolerance or
            self.plantLoc.side.FlowLock == DataPlant.FlowLock.Unlocked):
            return

        self.WaterMassFlowRate = state.dataLoopNodes.Node(self.WaterInletNodeNum).MassFlowRate
        outlet_water_temp_off = state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp
        outlet_water_temp_1st_stage = outlet_water_temp_off
        outlet_water_temp_2nd_stage = outlet_water_temp_off
        fan_mode_frac = 0.0

        if outlet_water_temp_off < temp_set_point:
            return

        ua_design = self.LowSpeedFluidCoolerUA
        air_flow_rate = self.LowSpeedAirFlowRate
        fan_power_low = self.LowSpeedFanPower

        calc_fluid_cooler_outlet(state, self.indexInArray, self.WaterMassFlowRate, air_flow_rate, ua_design, self)
        outlet_water_temp_1st_stage = self.OutletWaterTemp

        if outlet_water_temp_1st_stage <= temp_set_point:
            if outlet_water_temp_1st_stage != outlet_water_temp_off:
                fan_mode_frac = (temp_set_point - outlet_water_temp_off) / (outlet_water_temp_1st_stage - outlet_water_temp_off)
            self.FanPower = fan_mode_frac * fan_power_low
            self.OutletWaterTemp = temp_set_point
            self.Qactual *= fan_mode_frac
        else:
            ua_design = self.HighSpeedFluidCoolerUA
            air_flow_rate = self.HighSpeedAirFlowRate
            fan_power_high = self.HighSpeedFanPower

            calc_fluid_cooler_outlet(state, self.indexInArray, self.WaterMassFlowRate, air_flow_rate, ua_design, self)
            outlet_water_temp_2nd_stage = self.OutletWaterTemp

            if outlet_water_temp_2nd_stage <= temp_set_point and ua_design > 0.0:
                fan_mode_frac = (temp_set_point - outlet_water_temp_1st_stage) / (outlet_water_temp_2nd_stage - outlet_water_temp_1st_stage)
                self.FanPower = max((fan_mode_frac * fan_power_high) + (1.0 - fan_mode_frac) * fan_power_low, 0.0)
                self.OutletWaterTemp = temp_set_point
            else:
                self.OutletWaterTemp = outlet_water_temp_2nd_stage
                self.FanPower = fan_power_high

        cp_water = self.plantLoc.loop.glycol.get_specific_heat(
            state, state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp, routine_name
        )
        self.Qactual = self.WaterMassFlowRate * cp_water * (
            state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp - self.OutletWaterTemp
        )

    def simulate(self, state: Any, called_from_location: Any, first_hvac_iteration: bool, cur_load: float, run_flag: bool) -> None:
        self.initialize(state)
        if self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_SingleSpd:
            self.calc_single_speed(state)
        else:
            self.calc_two_speed(state)
        self.update(state)
        self.report(state, run_flag)

    def on_init_loop_equip(self, state: Any, called_from_location: Any) -> None:
        self.initialize(state)
        self.size(state)

    def get_design_capacities(
        self, state: Any, called_from_location: Any
    ) -> Tuple[float, float, float]:
        max_load = self.FluidCoolerNominalCapacity
        opt_load = self.FluidCoolerNominalCapacity
        min_load = 0.0
        return max_load, min_load, opt_load

    def update(self, state: Any) -> None:
        water_outlet_node = self.WaterOutletNodeNum
        state.dataLoopNodes.Node(water_outlet_node).Temp = self.OutletWaterTemp

        if (self.plantLoc.side.FlowLock == DataPlant.FlowLock.Unlocked or
            state.dataGlobal.WarmupFlag):
            return

        if state.dataLoopNodes.Node(water_outlet_node).MassFlowRate > self.DesWaterMassFlowRate * self.FluidCoolerMassFlowRateMultiplier:
            self.HighMassFlowErrorCount += 1
            if self.HighMassFlowErrorCount < 2:
                UtilityRoutines.show_warning_error(
                    state, f"{DataPlant.PlantEquipTypeNames[int(self.FluidCoolerType)]} \"{self.Name}\""
                )
                UtilityRoutines.show_continue_error(state, " Condenser Loop Mass Flow Rate is much greater than the fluid coolers design mass flow rate.")
                UtilityRoutines.show_continue_error(state, f" Condenser Loop Mass Flow Rate = {state.dataLoopNodes.Node(water_outlet_node).MassFlowRate:.6f}")
                UtilityRoutines.show_continue_error(state, f" Fluid Cooler Design Mass Flow Rate   = {self.DesWaterMassFlowRate:.6f}")
                UtilityRoutines.show_continue_error_time_stamp(state, "")

        loop_min_temp = self.plantLoc.loop.MinTemp
        if self.OutletWaterTemp < loop_min_temp and self.WaterMassFlowRate > 0.0:
            self.OutletWaterTempErrorCount += 1
            if self.OutletWaterTempErrorCount < 2:
                UtilityRoutines.show_warning_error(
                    state, f"{DataPlant.PlantEquipTypeNames[int(self.FluidCoolerType)]} \"{self.Name}\""
                )
                UtilityRoutines.show_continue_error(
                    state, f" Fluid cooler water outlet temperature ({self.OutletWaterTemp:.2f} C) is below the specified minimum condenser loop temp of {loop_min_temp:.2f} C"
                )
                UtilityRoutines.show_continue_error_time_stamp(state, "")

        if self.WaterMassFlowRate > 0.0 and self.WaterMassFlowRate <= DataBranchAirLoopPlant.MassFlowTolerance:
            self.SmallWaterMassFlowErrorCount += 1
            if self.SmallWaterMassFlowErrorCount < 2:
                UtilityRoutines.show_warning_error(
                    state, f"{DataPlant.PlantEquipTypeNames[int(self.FluidCoolerType)]} \"{self.Name}\""
                )
                UtilityRoutines.show_continue_error(state, " Fluid cooler water mass flow rate near zero.")
                UtilityRoutines.show_continue_error_time_stamp(state, "")
                UtilityRoutines.show_continue_error(state, f"Actual Mass flow = {self.WaterMassFlowRate:.2f}")

    def report(self, state: Any, run_flag: bool) -> None:
        reporting_constant = state.dataHVACGlobal.TimeStepSysSec
        if not run_flag:
            self.InletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp
            self.OutletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp
            self.Qactual = 0.0
            self.FanPower = 0.0
            self.FanEnergy = 0.0
        else:
            self.InletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNodeNum).Temp
            self.FanEnergy = self.FanPower * reporting_constant

    @staticmethod
    def factory(state: Any, type_of: Any, object_name: str) -> Optional["FluidCoolerspecs"]:
        if state.dataFluidCoolers.GetFluidCoolerInputFlag:
            get_fluid_cooler_input(state)
            state.dataFluidCoolers.GetFluidCoolerInputFlag = False

        for cooler in state.dataFluidCoolers.SimpleFluidCooler:
            if cooler.FluidCoolerType == type_of and cooler.Name == object_name:
                return cooler

        UtilityRoutines.show_fatal_error(
            state, f"FluidCooler::factory: Error getting inputs for cooler named: {object_name}"
        )
        return None


@dataclass
class FluidCoolersData:
    GetFluidCoolerInputFlag: bool = True
    NumSimpleFluidCoolers: int = 0
    SimpleFluidCooler: List[FluidCoolerspecs] = field(default_factory=list)
    UniqueSimpleFluidCoolerNames: dict = field(default_factory=dict)


def get_fluid_cooler_input(state: Any) -> None:
    num_single_speed = state.dataInputProcessing.inputProcessor.get_num_objects_found(state, "FluidCooler:SingleSpeed")
    num_two_speed = state.dataInputProcessing.inputProcessor.get_num_objects_found(state, "FluidCooler:TwoSpeed")
    state.dataFluidCoolers.NumSimpleFluidCoolers = num_single_speed + num_two_speed

    if state.dataFluidCoolers.NumSimpleFluidCoolers <= 0:
        UtilityRoutines.show_fatal_error(
            state, "No fluid cooler objects found in input, however, a branch object has specified a fluid cooler. "
            "Search the input for fluid cooler to determine the cause for this error."
        )

    if state.dataFluidCoolers.SimpleFluidCooler:
        return

    state.dataFluidCoolers.GetFluidCoolerInputFlag = False
    state.dataFluidCoolers.SimpleFluidCooler = [FluidCoolerspecs() for _ in range(state.dataFluidCoolers.NumSimpleFluidCoolers)]


def calc_fluid_cooler_outlet(
    state: Any, fluid_cooler_num: int, water_mass_flow_rate: float,
    air_flow_rate: float, ua_design: float, cooler: FluidCoolerspecs
) -> None:
    routine_name = "CalcFluidCoolerOutlet"

    if ua_design == 0.0:
        return

    inlet_water_temp = cooler.WaterTemp
    cooler.OutletWaterTemp = inlet_water_temp
    inlet_air_temp = cooler.AirTemp

    air_density = Psychrometrics.psy_rho_air_fn_pb_tdb_w(state, cooler.AirPress, inlet_air_temp, cooler.AirHumRat)
    air_mass_flow_rate = air_flow_rate * air_density
    cp_air = Psychrometrics.psy_cp_air_fn_w(cooler.AirHumRat)
    cp_water = cooler.plantLoc.loop.glycol.get_specific_heat(state, inlet_water_temp, routine_name)

    mdot_cp_water = water_mass_flow_rate * cp_water
    air_capacity = air_mass_flow_rate * cp_air

    capacity_ratio_min = min(air_capacity, mdot_cp_water)
    capacity_ratio_max = max(air_capacity, mdot_cp_water)
    capacity_ratio = capacity_ratio_min / capacity_ratio_max if capacity_ratio_max > 0 else 0

    num_transfer_units = ua_design / capacity_ratio_min if capacity_ratio_min > 0 else 0
    eta = num_transfer_units ** 0.22
    a = capacity_ratio * num_transfer_units / eta if eta > 0 else 0
    import math
    effectiveness = 1.0 - math.exp(math.expm1(-a) / (capacity_ratio / eta if eta > 0 else 1))

    q_actual = effectiveness * capacity_ratio_min * (inlet_water_temp - inlet_air_temp)

    if q_actual >= 0.0:
        cooler.OutletWaterTemp = inlet_water_temp - q_actual / mdot_cp_water if mdot_cp_water > 0 else inlet_water_temp
    else:
        cooler.OutletWaterTemp = inlet_water_temp


# Stubs for external dependencies
class Util:
    @staticmethod
    def same_string(a: str, b: str) -> bool:
        return a.lower() == b.lower()

class UtilityRoutines:
    @staticmethod
    def show_fatal_error(state: Any, message: str) -> None:
        pass

    @staticmethod
    def show_severe_error(state: Any, message: str) -> None:
        pass

    @staticmethod
    def show_warning_error(state: Any, message: str) -> None:
        pass

    @staticmethod
    def show_continue_error(state: Any, message: str) -> None:
        pass

    @staticmethod
    def show_continue_error_time_stamp(state: Any, message: str) -> None:
        pass

class OutputProcessor:
    class TimeStepType:
        System = 0
    class StoreType:
        Average = 0
        Sum = 1
    class Group:
        Plant = 0
    class EndUseCat:
        HeatRejection = 0

    @staticmethod
    def setup_output_variable(state: Any, *args, **kwargs) -> None:
        pass

class OutputReportPredefined:
    @staticmethod
    def pre_def_table_entry(state: Any, *args, **kwargs) -> None:
        pass

class PlantUtilities:
    @staticmethod
    def scan_plant_loops_for_object(state: Any, *args) -> None:
        pass

    @staticmethod
    def init_component_nodes(state: Any, *args) -> None:
        pass

    @staticmethod
    def regulate_condenser_comp_flow_req_op(state: Any, *args) -> float:
        return 0.0

    @staticmethod
    def set_component_flow_rate(state: Any, *args) -> None:
        pass

    @staticmethod
    def register_plant_comp_design_flow(state: Any, *args) -> None:
        pass

class BaseSizer:
    @staticmethod
    def report_sizer_output(state: Any, *args, **kwargs) -> None:
        pass

class Psychrometrics:
    @staticmethod
    def psy_rho_air_fn_pb_tdb_w(state: Any, *args) -> float:
        return 0.0

    @staticmethod
    def psy_cp_air_fn_w(humidity_ratio: float) -> float:
        return 0.0

    @staticmethod
    def psy_wfn_tdb_twb_pb(state: Any, *args) -> float:
        return 0.0

class Constant:
    InitConvTemp = 20.0
    class Units:
        C = "C"
        W = "W"
        J = "J"
        kg_s = "kg/s"
    class eResource:
        Electricity = 0
    class Group:
        Plant = 0

class DataPlant:
    class PlantEquipmentType:
        Invalid = -1
        FluidCooler_SingleSpd = 0
        FluidCooler_TwoSpd = 1
    class LoopDemandCalcScheme:
        SingleSetPoint = 0
        DualSetPointDeadBand = 1
    class FlowLock:
        Unlocked = 0
        Locked = 1
    PlantEquipTypeNames = ["FluidCooler:SingleSpeed", "FluidCooler:TwoSpeed"]

class DataBranchAirLoopPlant:
    MassFlowTolerance = 0.001

class DataSizing:
    AutoSize = -99999.0

class HVAC:
    SmallWaterVolFlow = 1e-6
    SmallTempDiff = 0.01

class Node:
    @staticmethod
    def get_only_single_node(state: Any, *args) -> int:
        return 0

    @staticmethod
    def test_comp_set(state: Any, *args) -> None:
        pass

class OutAirNodeManager:
    @staticmethod
    def check_out_air_node_number(state: Any, node_num: int) -> bool:
        return True

class GlobalNames:
    @staticmethod
    def verify_unique_inter_object_name(state: Any, *args) -> None:
        pass

class General:
    @staticmethod
    def solve_root(state: Any, acc: float, max_iter: int, sol_fla: int, ua: float, f: Callable, ua0: float, ua1: float) -> Tuple[int, float]:
        return 0, ua

class DataLoopNode:
    pass

class DataEnvironment:
    pass

class DataHVACGlobals:
    pass

class DataIPShortCuts:
    pass

class InputProcessor:
    pass

class BranchNodeConnections:
    pass

class DataSizingData:
    pass

class FluidProperties:
    pass

class Node:
    pass
