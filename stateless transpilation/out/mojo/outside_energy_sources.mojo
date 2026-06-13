# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from math import fabs, copysign, max as math_max, min as math_min

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object carrying all module data
# - PlantComponent: abstract base trait for plant equipment
# - BaseGlobalStruct: abstract base trait for global data structs
# - DataPlant.PlantEquipmentType: enum for equipment types
# - DataPlant.PlantLocation: location struct for plant loop topology
# - PlantUtilities: InitComponentNodes, SetComponentFlowRate, ScanPlantLoopsForObject, RegisterPlantCompDesignFlow
# - Sched.Schedule: schedule object type
# - Sched.GetScheduleAlwaysOn, Sched.GetSchedule: schedule retrieval
# - Node.GetOnlySingleNode, Node.TestCompSet: node management
# - Node.ConnectionObjectType, Node.FluidType, Node.ConnectionType, Node.CompFluidStream: node enums
# - InputProcessor: getNumObjectsFound, getObjectItem
# - OutputProcessor: SetupOutputVariable, EndUseCat
# - GlobalNames.VerifyUniqueInterObjectName: name verification
# - FluidProperties: glycol/steam property objects with methods
# - ScheduleManager: GetScheduleAlwaysOn, GetSchedule
# - EnergyPlus utilities: ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowMessage, ShowContinueError, ShowWarningBadMin
# - Constant: InitConvTemp, eResource, Units enum values
# - DataSizing.AutoSize, DataEnvironment.StdPressureSeaLevel, DataHVACGlobals.TimeStepSysSec
# - BaseSizer.reportSizerOutput
# - Array1D: 1-D array type
# - ErrorObjectHeader: error tracking structure
# - Clusive enum: for inclusive/exclusive comparisons


trait PlantComponent:
    fn simulate(
        inout self,
        state: Reference[EnergyPlusData],
        called_from_location: PlantLocation,
        first_hvac_iteration: Bool,
        cur_load: Float64,
        run_flag: Bool,
    ):
        ...

    fn onInitLoopEquip(
        inout self, state: Reference[EnergyPlusData], called_from_location: PlantLocation
    ):
        ...

    fn getDesignCapacities(
        inout self,
        state: Reference[EnergyPlusData],
        called_from_location: PlantLocation,
    ) -> Tuple[Float64, Float64, Float64]:
        ...

    fn oneTimeInit(inout self, state: Reference[EnergyPlusData]):
        ...

    fn oneTimeInit_new(inout self, state: Reference[EnergyPlusData]):
        ...


trait BaseGlobalStruct:
    fn init_constant_state(inout self, state: Reference[EnergyPlusData]):
        ...

    fn init_state(inout self, state: Reference[EnergyPlusData]):
        ...

    fn clear_state(inout self):
        ...


struct OutsideEnergySourceSpecs(PlantComponent):
    var Name: String
    var NomCap: Float64
    var NomCapWasAutoSized: Bool
    var capFractionSched: AnyPointer
    var InletNodeNum: Int32
    var OutletNodeNum: Int32
    var EnergyTransfer: Float64
    var EnergyRate: Float64
    var EnergyType: AnyPointer
    var plantLoc: PlantLocation
    var BeginEnvrnInitFlag: Bool
    var CheckEquipName: Bool
    var MassFlowRate: Float64
    var InletTemp: Float64
    var OutletTemp: Float64
    var OutletSteamQuality: Float64

    fn __init__(inout self):
        self.Name = String()
        self.NomCap = 0.0
        self.NomCapWasAutoSized = False
        self.capFractionSched = AnyPointer()
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.EnergyTransfer = 0.0
        self.EnergyRate = 0.0
        self.EnergyType = AnyPointer()
        self.plantLoc = PlantLocation()
        self.BeginEnvrnInitFlag = True
        self.CheckEquipName = True
        self.MassFlowRate = 0.0
        self.InletTemp = 0.0
        self.OutletTemp = 0.0
        self.OutletSteamQuality = 0.0

    @staticmethod
    fn factory(
        state: Reference[EnergyPlusData],
        object_type: AnyPointer,
        object_name: StringRef,
    ) -> AnyPointer:
        if state.dataOutsideEnergySrcs.SimOutsideEnergyGetInputFlag:
            GetOutsideEnergySourcesInput(state)
            state.dataOutsideEnergySrcs.SimOutsideEnergyGetInputFlag = False

        # Scan through energy sources and return matching one
        for i in range(len(state.dataOutsideEnergySrcs.EnergySource)):
            var source = state.dataOutsideEnergySrcs.EnergySource[i]
            if source.EnergyType == object_type and source.Name == String(object_name):
                return __address_of(source)

        ShowFatalError(
            state,
            "OutsideEnergySourceSpecsFactory: Error getting inputs for source named: "
            + String(object_name),
        )
        return AnyPointer()

    fn simulate(
        inout self,
        state: Reference[EnergyPlusData],
        called_from_location: PlantLocation,
        first_hvac_iteration: Bool,
        cur_load: Float64,
        run_flag: Bool,
    ):
        self.initialize(state, cur_load)
        self.calculate(state, run_flag, cur_load)

    fn onInitLoopEquip(
        inout self, state: Reference[EnergyPlusData], called_from_location: PlantLocation
    ):
        self.initialize(state, 0.0)
        self.size(state)

    fn getDesignCapacities(
        inout self,
        state: Reference[EnergyPlusData],
        called_from_location: PlantLocation,
    ) -> Tuple[Float64, Float64, Float64]:
        var min_load: Float64 = 0.0
        var max_load: Float64 = self.NomCap
        var opt_load: Float64 = self.NomCap
        return (max_load, min_load, opt_load)

    fn initialize(inout self, state: Reference[EnergyPlusData], my_load: Float64):
        var loop_num = self.plantLoc.loopNum
        var loop = state.dataPlnt.PlantLoop[loop_num]

        if state.dataGlobal.BeginEnvrnFlag and self.BeginEnvrnInitFlag:
            PlantUtilities_InitComponentNodes(
                state,
                loop.MinMassFlowRate,
                loop.MaxMassFlowRate,
                self.InletNodeNum,
                self.OutletNodeNum,
            )
            self.BeginEnvrnInitFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.BeginEnvrnInitFlag = True

        var temp_plant_mass_flow: Float64 = 0.0
        if fabs(my_load) > 0.0:
            temp_plant_mass_flow = loop.MaxMassFlowRate

        PlantUtilities_SetComponentFlowRate(
            state, temp_plant_mass_flow, self.InletNodeNum, self.OutletNodeNum, self.plantLoc
        )

        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum].Temp
        self.MassFlowRate = temp_plant_mass_flow

    fn size(inout self, state: Reference[EnergyPlusData]):
        var errors_found: Bool = False

        var type_name = get_plant_equip_type_name(self.EnergyType)

        var loop_num = self.plantLoc.loopNum
        var loop = state.dataPlnt.PlantLoop[loop_num]
        var plt_siz_num = loop.PlantSizNum

        if plt_siz_num > 0:
            var nom_cap_des: Float64 = 0.0

            if (self.EnergyType == get_purch_chilled_water_type()
                or self.EnergyType == get_purch_hot_water_type()
            ):
                var rho = loop.glycol.getDensity(
                    state, get_init_conv_temp(), "Size " + type_name
                )
                var cp = loop.glycol.getSpecificHeat(
                    state, get_init_conv_temp(), "Size " + type_name
                )
                nom_cap_des = (
                    cp
                    * rho
                    * state.dataSize.PlantSizData[plt_siz_num].DeltaT
                    * state.dataSize.PlantSizData[plt_siz_num].DesVolFlowRate
                )
            else:
                var temp_steam = loop.steam.getSatTemperature(
                    state, get_std_baro_press(), "Size " + type_name
                )
                var rho_steam = loop.steam.getSatDensity(
                    state, temp_steam, 1.0, "Size " + type_name
                )
                var enth_steam_dry = loop.steam.getSatEnthalpy(
                    state, temp_steam, 1.0, "Size " + type_name
                )
                var enth_steam_wet = loop.steam.getSatEnthalpy(
                    state, temp_steam, 0.0, "Size " + type_name
                )
                var latent_heat_steam = enth_steam_dry - enth_steam_wet
                nom_cap_des = (
                    rho_steam
                    * state.dataSize.PlantSizData[plt_siz_num].DesVolFlowRate
                    * latent_heat_steam
                )

            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCapWasAutoSized:
                    self.NomCap = nom_cap_des
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer_reportSizerOutput(
                            state,
                            type_name,
                            self.Name,
                            "Design Size Nominal Capacity [W]",
                            nom_cap_des,
                        )
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer_reportSizerOutput(
                            state,
                            type_name,
                            self.Name,
                            "Initial Design Size Nominal Capacity [W]",
                            nom_cap_des,
                        )
                else:
                    if self.NomCap > 0.0 and nom_cap_des > 0.0:
                        var nom_cap_user = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer_reportSizerOutput(
                                state,
                                type_name,
                                self.Name,
                                "Design Size Nominal Capacity [W]",
                                nom_cap_des,
                                "User-Specified Nominal Capacity [W]",
                                nom_cap_user,
                            )
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (
                                    fabs(nom_cap_des - nom_cap_user) / nom_cap_user
                                    > state.dataSize.AutoVsHardSizingThreshold
                                ):
                                    ShowMessage(
                                        state,
                                        "Size "
                                        + type_name
                                        + ": Potential issue with equipment sizing for "
                                        + self.Name,
                                    )
                                    ShowContinueError(
                                        state,
                                        "User-Specified Nominal Capacity of "
                                        + String(nom_cap_user)
                                        + " [W]",
                                    )
                                    ShowContinueError(
                                        state,
                                        "differs from Design Size Nominal Capacity of "
                                        + String(nom_cap_des)
                                        + " [W]",
                                    )
                                    ShowContinueError(
                                        state,
                                        "This may, or may not, indicate mismatched component sizes.",
                                    )
                                    ShowContinueError(
                                        state,
                                        "Verify that the value entered is intended and is consistent with other components.",
                                    )
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(
                    state,
                    "Autosizing of "
                    + type_name
                    + " nominal capacity requires a loop Sizing:Plant object",
                )
                ShowContinueError(
                    state,
                    "Occurs in " + type_name + " object=" + self.Name,
                )
                errors_found = True
            if (
                not self.NomCapWasAutoSized
                and self.NomCap > 0.0
                and state.dataPlnt.PlantFinalSizesOkayToReport
            ):
                BaseSizer_reportSizerOutput(
                    state,
                    type_name,
                    self.Name,
                    "User-Specified Nominal Capacity [W]",
                    self.NomCap,
                )

        if errors_found:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    fn calculate(inout self, state: Reference[EnergyPlusData], run_flag: Bool, my_load: Float64):
        var loop_num = self.plantLoc.loopNum
        var loop = state.dataPlnt.PlantLoop[loop_num]

        var loop_min_temp = state.dataPlnt.PlantLoop[loop_num].MinTemp
        var loop_max_temp = state.dataPlnt.PlantLoop[loop_num].MaxTemp
        var loop_min_mdot = state.dataPlnt.PlantLoop[loop_num].MinMassFlowRate
        var loop_max_mdot = state.dataPlnt.PlantLoop[loop_num].MaxMassFlowRate

        var cap_fraction = self.capFractionSched.getCurrentVal()
        cap_fraction = math_max(0.0, cap_fraction)
        var current_cap = self.NomCap * cap_fraction
        if fabs(my_load) > current_cap:
            my_load = copysign(current_cap, my_load)

        if self.EnergyType == get_purch_chilled_water_type():
            if my_load > 0.0:
                my_load = 0.0
        elif (
            self.EnergyType == get_purch_hot_water_type()
            or self.EnergyType == get_purch_steam_type()
        ):
            if my_load < 0.0:
                my_load = 0.0

        if self.MassFlowRate > 0.0 and run_flag:
            if (self.EnergyType == get_purch_chilled_water_type()
                or self.EnergyType == get_purch_hot_water_type()
            ):
                var cp = state.dataPlnt.PlantLoop[loop_num].glycol.getSpecificHeat(
                    state, self.InletTemp, "SimDistrictEnergy"
                )
                self.OutletTemp = (
                    my_load + self.MassFlowRate * cp * self.InletTemp
                ) / (self.MassFlowRate * cp)

                if self.OutletTemp < loop_min_temp:
                    self.OutletTemp = math_max(self.OutletTemp, loop_min_temp)
                    my_load = self.MassFlowRate * cp * (self.OutletTemp - self.InletTemp)
                if self.OutletTemp > loop_max_temp:
                    self.OutletTemp = math_min(self.OutletTemp, loop_max_temp)
                    my_load = self.MassFlowRate * cp * (self.OutletTemp - self.InletTemp)

            elif self.EnergyType == get_purch_steam_type():
                var sat_temp_atm_press = loop.steam.getSatTemperature(
                    state, get_std_pressure_sea_level(), "SimDistrictEnergy"
                )
                var cp_condensate = loop.glycol.getSpecificHeat(
                    state, self.InletTemp, "SimDistrictEnergy"
                )
                var delta_t_sensible = sat_temp_atm_press - self.InletTemp
                var enth_steam_in_dry = loop.steam.getSatEnthalpy(
                    state, self.InletTemp, 1.0, "SimDistrictEnergy"
                )
                var enth_steam_out_wet = loop.steam.getSatEnthalpy(
                    state, self.InletTemp, 0.0, "SimDistrictEnergy"
                )
                var latent_heat_steam = enth_steam_in_dry - enth_steam_out_wet
                self.MassFlowRate = my_load / (
                    latent_heat_steam + (cp_condensate * delta_t_sensible)
                )
                PlantUtilities_SetComponentFlowRate(
                    state,
                    self.MassFlowRate,
                    self.InletNodeNum,
                    self.OutletNodeNum,
                    self.plantLoc,
                )
                self.OutletTemp = state.dataLoopNodes.Node[
                    loop.TempSetPointNodeNum
                ].TempSetPoint
                self.OutletSteamQuality = 0.0

                if self.MassFlowRate < loop_min_mdot:
                    self.MassFlowRate = math_max(self.MassFlowRate, loop_min_mdot)
                    PlantUtilities_SetComponentFlowRate(
                        state,
                        self.MassFlowRate,
                        self.InletNodeNum,
                        self.OutletNodeNum,
                        self.plantLoc,
                    )
                    my_load = self.MassFlowRate * latent_heat_steam
                if self.MassFlowRate > loop_max_mdot:
                    self.MassFlowRate = math_min(self.MassFlowRate, loop_max_mdot)
                    PlantUtilities_SetComponentFlowRate(
                        state,
                        self.MassFlowRate,
                        self.InletNodeNum,
                        self.OutletNodeNum,
                        self.plantLoc,
                    )
                    my_load = self.MassFlowRate * latent_heat_steam

                state.dataLoopNodes.Node[self.OutletNodeNum].Quality = 1.0
        else:
            self.OutletTemp = self.InletTemp
            my_load = 0.0

        var outlet_node = self.OutletNodeNum
        state.dataLoopNodes.Node[outlet_node].Temp = self.OutletTemp
        self.EnergyRate = fabs(my_load)
        self.EnergyTransfer = self.EnergyRate * state.dataHVACGlobal.TimeStepSysSec

    fn oneTimeInit(inout self, state: Reference[EnergyPlusData]):
        pass

    fn oneTimeInit_new(inout self, state: Reference[EnergyPlusData]):
        var err_flag: Bool = False
        PlantUtilities_ScanPlantLoopsForObject(
            state, self.Name, self.EnergyType, self.plantLoc, err_flag
        )

        if err_flag:
            ShowFatalError(
                state,
                "InitSimVars: Program terminated due to previous condition(s).",
            )

        var loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum]
        get_plant_component(state, self.plantLoc).MinOutletTemp = loop.MinTemp
        get_plant_component(state, self.plantLoc).MaxOutletTemp = loop.MaxTemp
        PlantUtilities_RegisterPlantCompDesignFlow(
            state, self.InletNodeNum, loop.MaxVolFlowRate
        )

        var report_var_prefix = "District Heating Water "
        var heating_or_cooling = get_heating_end_use_cat()
        var meter_type_key = get_district_heating_water_resource()

        if self.EnergyType == get_purch_chilled_water_type():
            report_var_prefix = "District Cooling Water "
            heating_or_cooling = get_cooling_end_use_cat()
            meter_type_key = get_district_cooling_resource()
        elif self.EnergyType == get_purch_steam_type():
            report_var_prefix = "District Heating Steam "
            heating_or_cooling = get_heating_end_use_cat()
            meter_type_key = get_district_heating_steam_resource()

        SetupOutputVariable(
            state,
            report_var_prefix + "Energy",
            "J",
            self.EnergyTransfer,
            "System",
            "Sum",
            self.Name,
            meter_type_key,
            "Plant",
            heating_or_cooling,
        )
        SetupOutputVariable(
            state,
            report_var_prefix + "Rate",
            "W",
            self.EnergyRate,
            "System",
            "Average",
            self.Name,
        )
        SetupOutputVariable(
            state,
            report_var_prefix + "Inlet Temperature",
            "C",
            self.InletTemp,
            "System",
            "Average",
            self.Name,
        )
        SetupOutputVariable(
            state,
            report_var_prefix + "Outlet Temperature",
            "C",
            self.OutletTemp,
            "System",
            "Average",
            self.Name,
        )
        SetupOutputVariable(
            state,
            report_var_prefix + "Mass Flow Rate",
            "kg/s",
            self.MassFlowRate,
            "System",
            "Average",
            self.Name,
        )


fn GetOutsideEnergySourcesInput(state: Reference[EnergyPlusData]):
    var num_district_units_heat_water = InputProcessor_getNumObjectsFound(
        state, "DistrictHeating:Water"
    )
    var num_district_units_cool = InputProcessor_getNumObjectsFound(
        state, "DistrictCooling"
    )
    var num_district_units_heat_steam = InputProcessor_getNumObjectsFound(
        state, "DistrictHeating:Steam"
    )
    state.dataOutsideEnergySrcs.NumDistrictUnits = (
        num_district_units_heat_water
        + num_district_units_cool
        + num_district_units_heat_steam
    )

    if len(state.dataOutsideEnergySrcs.EnergySource) > 0:
        return

    # Allocate array of energy sources
    for _ in range(state.dataOutsideEnergySrcs.NumDistrictUnits):
        state.dataOutsideEnergySrcs.EnergySource.append(OutsideEnergySourceSpecs())

    var errors_found: Bool = False
    var heat_water_index: Int32 = 0
    var cool_index: Int32 = 0
    var heat_steam_index: Int32 = 0

    for energy_source_num in range(state.dataOutsideEnergySrcs.NumDistrictUnits):
        var current_module_object: String
        var obj_type: AnyPointer
        var node_names: String
        var energy_type: AnyPointer
        var this_index: Int32

        if energy_source_num < num_district_units_heat_water:
            current_module_object = "DistrictHeating:Water"
            obj_type = get_connection_object_type_heat_water()
            node_names = "Hot Water Nodes"
            energy_type = get_purch_hot_water_type()
            heat_water_index += 1
            this_index = heat_water_index
        elif energy_source_num < num_district_units_heat_water + num_district_units_cool:
            current_module_object = "DistrictCooling"
            obj_type = get_connection_object_type_cool()
            node_names = "Chilled Water Nodes"
            energy_type = get_purch_chilled_water_type()
            cool_index += 1
            this_index = cool_index
        else:
            current_module_object = "DistrictHeating:Steam"
            obj_type = get_connection_object_type_heat_steam()
            node_names = "Steam Nodes"
            energy_type = get_purch_steam_type()
            heat_steam_index += 1
            this_index = heat_steam_index

        var alpha_args: List[String] = List[String]()
        var num_alphas: Int32 = 0
        var num_nums: Int32 = 0

        InputProcessor_getObjectItem(state, current_module_object, this_index, alpha_args, num_alphas, num_nums)

        var eoh = ErrorObjectHeader(current_module_object, alpha_args[0])

        if energy_source_num > 0:
            GlobalNames_VerifyUniqueInterObjectName(
                state,
                state.dataOutsideEnergySrcs.EnergySourceUniqueNames,
                alpha_args[0],
                current_module_object,
                errors_found,
            )

        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].Name = alpha_args[0]

        if energy_source_num < num_district_units_heat_water + num_district_units_cool:
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].InletNodeNum = (
                Node_GetOnlySingleNode(
                    state,
                    alpha_args[1],
                    errors_found,
                    obj_type,
                    alpha_args[0],
                    get_fluid_type_water(),
                    get_connection_type_inlet(),
                    get_comp_fluid_stream_primary(),
                )
            )
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].OutletNodeNum = (
                Node_GetOnlySingleNode(
                    state,
                    alpha_args[2],
                    errors_found,
                    obj_type,
                    alpha_args[0],
                    get_fluid_type_water(),
                    get_connection_type_outlet(),
                    get_comp_fluid_stream_primary(),
                )
            )
        else:
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].InletNodeNum = (
                Node_GetOnlySingleNode(
                    state,
                    alpha_args[1],
                    errors_found,
                    obj_type,
                    alpha_args[0],
                    get_fluid_type_steam(),
                    get_connection_type_inlet(),
                    get_comp_fluid_stream_primary(),
                )
            )
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].OutletNodeNum = (
                Node_GetOnlySingleNode(
                    state,
                    alpha_args[2],
                    errors_found,
                    obj_type,
                    alpha_args[0],
                    get_fluid_type_steam(),
                    get_connection_type_outlet(),
                    get_comp_fluid_stream_primary(),
                )
            )

        Node_TestCompSet(
            state,
            current_module_object,
            alpha_args[0],
            alpha_args[1],
            alpha_args[2],
            node_names,
        )

        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].NomCap = (
            get_numeric_arg(state, 0)
        )
        if (
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].NomCap
            == get_auto_size()
        ):
            state.dataOutsideEnergySrcs.EnergySource[
                energy_source_num
            ].NomCapWasAutoSized = True

        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].EnergyTransfer = 0.0
        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].EnergyRate = 0.0
        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].EnergyType = energy_type

        if is_alpha_field_blank(state, 3):
            state.dataOutsideEnergySrcs.EnergySource[
                energy_source_num
            ].capFractionSched = Sched_GetScheduleAlwaysOn(state)
        else:
            var sched = Sched_GetSchedule(state, alpha_args[3])
            if sched == AnyPointer():
                ShowSevereItemNotFound(
                    state, eoh, "Capacity Fraction Schedule Name", alpha_args[3]
                )
                errors_found = True
            else:
                state.dataOutsideEnergySrcs.EnergySource[
                    energy_source_num
                ].capFractionSched = sched
                if not sched.checkMinVal(state, 0.0):
                    Sched_ShowWarningBadMin(
                        state,
                        eoh,
                        "Capacity Fraction Schedule Name",
                        alpha_args[3],
                        0.0,
                        "Negative values will be treated as zero, and the simulation continues.",
                    )

    if errors_found:
        ShowFatalError(
            state,
            "Errors found in processing input for " + current_module_object + ", "
            "Preceding condition caused termination.",
        )


struct OutsideEnergySourcesData(BaseGlobalStruct):
    var NumDistrictUnits: Int32
    var SimOutsideEnergyGetInputFlag: Bool
    var EnergySource: List[OutsideEnergySourceSpecs]
    var EnergySourceUniqueNames: Dict[String, String]

    fn __init__(inout self):
        self.NumDistrictUnits = 0
        self.SimOutsideEnergyGetInputFlag = True
        self.EnergySource = List[OutsideEnergySourceSpecs]()
        self.EnergySourceUniqueNames = Dict[String, String]()

    fn init_constant_state(inout self, state: Reference[EnergyPlusData]):
        pass

    fn init_state(inout self, state: Reference[EnergyPlusData]):
        pass

    fn clear_state(inout self):
        self.NumDistrictUnits = 0
        self.SimOutsideEnergyGetInputFlag = True
        self.EnergySource = List[OutsideEnergySourceSpecs]()
        self.EnergySourceUniqueNames = Dict[String, String]()


fn InitSimVars(energy_source_num: Int32, my_load: Float64):
    pass


fn PlantUtilities_InitComponentNodes(
    state: Reference[EnergyPlusData],
    min_mass_flow: Float64,
    max_mass_flow: Float64,
    inlet_node: Int32,
    outlet_node: Int32,
):
    pass


fn PlantUtilities_SetComponentFlowRate(
    state: Reference[EnergyPlusData],
    flow_rate: Float64,
    inlet_node: Int32,
    outlet_node: Int32,
    plant_loc: PlantLocation,
):
    pass


fn PlantUtilities_ScanPlantLoopsForObject(
    state: Reference[EnergyPlusData],
    name: String,
    equip_type: AnyPointer,
    plant_loc: inout PlantLocation,
    err_flag: inout Bool,
):
    pass


fn PlantUtilities_RegisterPlantCompDesignFlow(
    state: Reference[EnergyPlusData], node_num: Int32, design_vol_flow: Float64
):
    pass


fn InputProcessor_getNumObjectsFound(
    state: Reference[EnergyPlusData], obj_name: String
) -> Int32:
    return 0


fn InputProcessor_getObjectItem(
    state: Reference[EnergyPlusData],
    obj_type: String,
    obj_index: Int32,
    alpha_args: inout List[String],
    num_alphas: inout Int32,
    num_nums: inout Int32,
):
    pass


fn Node_GetOnlySingleNode(
    state: Reference[EnergyPlusData],
    node_name: String,
    errors_found: inout Bool,
    obj_type: AnyPointer,
    obj_name: String,
    fluid_type: AnyPointer,
    connection_type: AnyPointer,
    comp_fluid_stream: AnyPointer,
) -> Int32:
    return 0


fn Node_TestCompSet(
    state: Reference[EnergyPlusData],
    obj_type: String,
    obj_name: String,
    inlet: String,
    outlet: String,
    node_names: String,
):
    pass


fn GlobalNames_VerifyUniqueInterObjectName(
    state: Reference[EnergyPlusData],
    name_dict: inout Dict[String, String],
    name: String,
    obj_type: String,
    errors_found: inout Bool,
):
    pass


fn Sched_GetScheduleAlwaysOn(state: Reference[EnergyPlusData]) -> AnyPointer:
    return AnyPointer()


fn Sched_GetSchedule(state: Reference[EnergyPlusData], sched_name: String) -> AnyPointer:
    return AnyPointer()


fn ShowFatalError(state: Reference[EnergyPlusData], msg: String):
    raise Error(msg)


fn ShowSevereError(state: Reference[EnergyPlusData], msg: String):
    pass


fn ShowSevereItemNotFound(
    state: Reference[EnergyPlusData],
    eoh: ErrorObjectHeader,
    field_name: String,
    field_value: String,
):
    pass


fn ShowMessage(state: Reference[EnergyPlusData], msg: String):
    pass


fn ShowContinueError(state: Reference[EnergyPlusData], msg: String):
    pass


fn Sched_ShowWarningBadMin(
    state: Reference[EnergyPlusData],
    eoh: ErrorObjectHeader,
    field_name: String,
    field_value: String,
    min_val: Float64,
    msg: String,
):
    pass


fn BaseSizer_reportSizerOutput(state: Reference[EnergyPlusData], *args):
    pass


fn SetupOutputVariable(state: Reference[EnergyPlusData], *args):
    pass


fn get_plant_location() -> PlantLocation:
    return PlantLocation()


fn get_invalid_equipment_type() -> AnyPointer:
    return AnyPointer()


fn get_purch_hot_water_type() -> AnyPointer:
    return AnyPointer()


fn get_purch_chilled_water_type() -> AnyPointer:
    return AnyPointer()


fn get_purch_steam_type() -> AnyPointer:
    return AnyPointer()


fn get_plant_equip_type_name(equip_type: AnyPointer) -> String:
    return String()


fn get_init_conv_temp() -> Float64:
    return 20.0


fn get_std_baro_press() -> Float64:
    return 101325.0


fn get_std_pressure_sea_level() -> Float64:
    return 101325.0


fn get_heating_end_use_cat() -> AnyPointer:
    return AnyPointer()


fn get_cooling_end_use_cat() -> AnyPointer:
    return AnyPointer()


fn get_district_heating_water_resource() -> AnyPointer:
    return AnyPointer()


fn get_district_cooling_resource() -> AnyPointer:
    return AnyPointer()


fn get_district_heating_steam_resource() -> AnyPointer:
    return AnyPointer()


fn get_connection_object_type_heat_water() -> AnyPointer:
    return AnyPointer()


fn get_connection_object_type_cool() -> AnyPointer:
    return AnyPointer()


fn get_connection_object_type_heat_steam() -> AnyPointer:
    return AnyPointer()


fn get_fluid_type_water() -> AnyPointer:
    return AnyPointer()


fn get_fluid_type_steam() -> AnyPointer:
    return AnyPointer()


fn get_connection_type_inlet() -> AnyPointer:
    return AnyPointer()


fn get_connection_type_outlet() -> AnyPointer:
    return AnyPointer()


fn get_comp_fluid_stream_primary() -> AnyPointer:
    return AnyPointer()


fn get_auto_size() -> Float64:
    return -99999.0


fn get_numeric_arg(state: Reference[EnergyPlusData], index: Int32) -> Float64:
    return 0.0


fn is_alpha_field_blank(state: Reference[EnergyPlusData], index: Int32) -> Bool:
    return False


fn get_plant_component(state: Reference[EnergyPlusData], plant_loc: PlantLocation) -> AnyPointer:
    return AnyPointer()


struct PlantLocation:
    var loopNum: Int32
    var loopSideNum: Int32
    var branchNum: Int32
    var compNum: Int32

    fn __init__(inout self):
        self.loopNum = 0
        self.loopSideNum = 0
        self.branchNum = 0
        self.compNum = 0

    fn __init__(
        inout self,
        loop_num: Int32,
        loop_side_num: Int32,
        branch_num: Int32,
        comp_num: Int32,
    ):
        self.loopNum = loop_num
        self.loopSideNum = loop_side_num
        self.branchNum = branch_num
        self.compNum = comp_num


struct ErrorObjectHeader:
    var ObjectType: String
    var ObjectName: String

    fn __init__(inout self, obj_type: String, obj_name: String):
        self.ObjectType = obj_type
        self.ObjectName = obj_name
