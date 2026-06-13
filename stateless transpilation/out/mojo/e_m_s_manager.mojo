from enum import IntEnum
from math import floor


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state object, passed as parameter)
# - OutputProcessor.VariableType (enum)
# - OutputProcessor.StoreType (enum)
# - OutputProcessor.TimeStepType (enum)
# - HVAC.CtrlVarType (enum)
# - Sched.Schedule (class)
# - DataRuntimeLanguage types (Value, PtrDataType, EMSActuatorAvailableType, etc.)
# - Constant.Units (enum)
# - RuntimeLanguageProcessor functions
# - PluginManagement functions
# - Utility functions (Util.makeUPPER, Util.SameString, Util.FindItemInList)
# - Error reporting (ShowWarningError, ShowSevereError, ShowContinueError, ShowFatalError)
# - GetMeterIndex, GetInternalVariableValue, GetInstantMeterValue functions
# - Input processor and file I/O via state


struct EMSCallFrom:
    alias Invalid = -1
    alias ZoneSizing = 0
    alias SystemSizing = 1
    alias BeginNewEnvironment = 2
    alias BeginNewEnvironmentAfterWarmUp = 3
    alias BeginTimestepBeforePredictor = 4
    alias BeforeHVACManagers = 5
    alias AfterHVACManagers = 6
    alias HVACIterationLoop = 7
    alias EndSystemTimestepBeforeHVACReporting = 8
    alias EndSystemTimestepAfterHVACReporting = 9
    alias EndZoneTimestepBeforeZoneReporting = 10
    alias EndZoneTimestepAfterZoneReporting = 11
    alias SetupSimulation = 12
    alias ExternalInterface = 13
    alias ComponentGetInput = 14
    alias UserDefinedComponentModel = 15
    alias UnitarySystemSizing = 16
    alias BeginZoneTimestepBeforeInitHeatBalance = 17
    alias BeginZoneTimestepAfterInitHeatBalance = 18
    alias BeginZoneTimestepBeforeSetCurrentWeather = 19
    alias Num = 20


fn get_ems_call_from_names_uc() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("ENDOFZONESIZING")
    names.append("ENDOFSYSTEMSIZING")
    names.append("BEGINNEWENVIRONMENT")
    names.append("AFTERNEWENVIRONMENTWARMUPISCOMPLETE")
    names.append("BEGINTIMESTEPBEFOREPREDICTOR")
    names.append("AFTERPREDICTORBEFOREHVACMANAGERS")
    names.append("AFTERPREDICTORAFTERHVACMANAGERS")
    names.append("INSIDEHVACSYSTEMITERATIONLOOP")
    names.append("ENDOFSYSTEMTIMESTEPBEFOREHVACREPORTING")
    names.append("ENDOFSYSTEMTIMESTEPAFTERHVACREPORTING")
    names.append("ENDOFZONETIMESTEPBEFOREZONEREPORTING")
    names.append("ENDOFZONETIMESTEPAFTERZONEREPORTING")
    names.append("SETUPSIMULATION")
    names.append("EXTERNALINTERFACE")
    names.append("AFTERCOMPONENTINPUTREADIN")
    names.append("USERDEFINEDCOMPONENTMODEL")
    names.append("UNITARYSYSTEMSIZING")
    names.append("BEGINZONETIMESTEPBEFOREINITHEATBALANCE")
    names.append("BEGINZONETIMESTEPAFTERINITHEATBALANCE")
    names.append("BEGINZONETIMESTEPBEFORESETCURRENTWEATHER")
    return names


fn get_control_type_names() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("Temperature Setpoint")
    names.append("Temperature Minimum Setpoint")
    names.append("Temperature Maximum Setpoint")
    names.append("Humidity Ratio Setpoint")
    names.append("Humidity Ratio Minimum Setpoint")
    names.append("Humidity Ratio Maximum Setpoint")
    names.append("Mass Flow Rate Setpoint")
    names.append("Mass Flow Rate Minimum Available Setpoint")
    names.append("Mass Flow Rate Maximum Available Setpoint")
    return names


struct EMSManagerData:
    var get_ems_user_input: Bool
    var zone_thermostat_actuators_have_been_setup: Bool
    var finish_processing_user_input: Bool
    var l_dummy: Bool
    var l_dummy2: Bool

    fn __init__(inout self):
        self.get_ems_user_input = True
        self.zone_thermostat_actuators_have_been_setup = False
        self.finish_processing_user_input = True
        self.l_dummy = False
        self.l_dummy2 = False

    fn init_constant_state(inout self, state: LifetimePointer[EnergyPlusData]) -> None:
        pass

    fn init_state(inout self, state: LifetimePointer[EnergyPlusData]) -> None:
        check_if_any_ems(state)

    fn clear_state(inout self) -> None:
        self.get_ems_user_input = True
        self.zone_thermostat_actuators_have_been_setup = False
        self.finish_processing_user_input = True
        self.l_dummy = False
        self.l_dummy2 = False


fn check_if_any_ems(state: LifetimePointer[EnergyPlusData]) -> None:
    var current_module_object = "EnergyManagementSystem:Sensor"
    state[].dataRuntimeLang.NumSensors = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:Actuator"
    state[].dataRuntimeLang.numActuatorsUsed = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:ProgramCallingManager"
    state[].dataRuntimeLang.NumProgramCallManagers = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:Program"
    state[].dataRuntimeLang.NumErlPrograms = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:Subroutine"
    state[].dataRuntimeLang.NumErlSubroutines = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:GlobalVariable"
    state[].dataRuntimeLang.NumUserGlobalVariables = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:OutputVariable"
    state[].dataRuntimeLang.NumEMSOutputVariables = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:MeteredOutputVariable"
    state[].dataRuntimeLang.NumEMSMeteredOutputVariables = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:CurveOrTableIndexVariable"
    state[].dataRuntimeLang.NumEMSCurveIndices = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "ExternalInterface:Variable"
    state[].dataRuntimeLang.NumExternalInterfaceGlobalVariables = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "ExternalInterface:FunctionalMockupUnitImport:To:Variable"
    state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitImportGlobalVariables = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "ExternalInterface:FunctionalMockupUnitExport:To:Variable"
    state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitExportGlobalVariables = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "ExternalInterface:Actuator"
    state[].dataRuntimeLang.NumExternalInterfaceActuatorsUsed = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "ExternalInterface:FunctionalMockupUnitImport:To:Actuator"
    state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitImportActuatorsUsed = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "ExternalInterface:FunctionalMockupUnitExport:To:Actuator"
    state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitExportActuatorsUsed = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "EnergyManagementSystem:ConstructionIndexVariable"
    state[].dataRuntimeLang.NumEMSConstructionIndices = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    current_module_object = "Output:EnergyManagementSystem"
    var num_output_emss = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)

    var num_python_plugins = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(state, "PythonPlugin:Instance")
    var num_active_callbacks = state[].dataPluginManagement.PluginManager.numActiveCallbacks(state)

    if (
        state[].dataRuntimeLang.NumSensors + state[].dataRuntimeLang.numActuatorsUsed
        + state[].dataRuntimeLang.NumProgramCallManagers + state[].dataRuntimeLang.NumErlPrograms
        + state[].dataRuntimeLang.NumErlSubroutines + state[].dataRuntimeLang.NumUserGlobalVariables
        + state[].dataRuntimeLang.NumEMSOutputVariables + state[].dataRuntimeLang.NumEMSCurveIndices
        + state[].dataRuntimeLang.NumExternalInterfaceGlobalVariables + state[].dataRuntimeLang.NumExternalInterfaceActuatorsUsed
        + state[].dataRuntimeLang.NumEMSConstructionIndices + state[].dataRuntimeLang.NumEMSMeteredOutputVariables
        + state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitImportActuatorsUsed
        + state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitImportGlobalVariables
        + state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitExportActuatorsUsed
        + state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitExportGlobalVariables
        + num_output_emss + num_python_plugins + num_active_callbacks
    ) > 0:
        state[].dataGlobal.AnyEnergyManagementSystemInModel = True
    else:
        state[].dataGlobal.AnyEnergyManagementSystemInModel = False

    state[].dataGlobal.AnyEnergyManagementSystemInModel = (
        state[].dataGlobal.AnyEnergyManagementSystemInModel
        or state[].dataGlobal.externalHVACManager
        or state[].dataGlobal.eplusRunningViaAPI
    )

    if state[].dataGlobal.AnyEnergyManagementSystemInModel:
        state[].dataGeneral.ScanForReports(state, "EnergyManagementSystem", state[].dataRuntimeLang.OutputEDDFile)
        if state[].dataRuntimeLang.OutputEDDFile:
            state[].files.edd.ensure_open(state, "CheckIFAnyEMS", state[].files.outputControl.edd)
    else:
        state[].dataGeneral.ScanForReports(state, "EnergyManagementSystem", state[].dataRuntimeLang.OutputEDDFile)
        if state[].dataRuntimeLang.OutputEDDFile:
            state[].ShowWarningError("CheckIFAnyEMS: No EnergyManagementSystem has been set up in the input file but output is requested.")
            state[].ShowContinueError(
                "No EDD file will be produced. Refer to EMS Application Guide and/or InputOutput Reference to set up your EnergyManagementSystem."
            )


fn manage_ems(
    state: LifetimePointer[EnergyPlusData],
    i_called_from: Int,
    inout any_program_ran: Bool,
    program_manager_to_run: Optional[Int] = None,
) -> None:
    any_program_ran = False
    if not state[].dataGlobal.AnyEnergyManagementSystemInModel:
        return

    if i_called_from == EMSCallFrom.BeginNewEnvironment:
        state[].dataRuntimeLanguageProcessor.BeginEnvrnInitializeRuntimeLanguage(state)
        state[].dataPluginManagement.onBeginEnvironment(state)

    init_ems(state, i_called_from)

    if i_called_from != EMSCallFrom.UserDefinedComponentModel:
        var any_plugins_or_callbacks_ran = False
        state[].dataPluginManagement.runAnyRegisteredCallbacks(state, i_called_from, any_plugins_or_callbacks_ran)
        if any_plugins_or_callbacks_ran:
            any_program_ran = True

    if i_called_from == EMSCallFrom.SetupSimulation:
        process_ems_input(state, True)
        return

    if i_called_from != EMSCallFrom.UserDefinedComponentModel:
        for program_manager_num in range(1, state[].dataRuntimeLang.NumProgramCallManagers + 1):
            if state[].dataRuntimeLang.EMSProgramCallManager[program_manager_num - 1].CallingPoint == i_called_from:
                for erl_program_num in range(
                    1, state[].dataRuntimeLang.EMSProgramCallManager[program_manager_num - 1].NumErlPrograms + 1
                ):
                    state[].dataRuntimeLanguageProcessor.EvaluateStack(
                        state, state[].dataRuntimeLang.EMSProgramCallManager[program_manager_num - 1].ErlProgramARR[erl_program_num - 1]
                    )
                    any_program_ran = True
    else:
        if program_manager_to_run:
            for erl_program_num in range(
                1, state[].dataRuntimeLang.EMSProgramCallManager[program_manager_to_run.value() - 1].NumErlPrograms + 1
            ):
                state[].dataRuntimeLanguageProcessor.EvaluateStack(
                    state, state[].dataRuntimeLang.EMSProgramCallManager[program_manager_to_run.value() - 1].ErlProgramARR[erl_program_num - 1]
                )
                any_program_ran = True

    if i_called_from == EMSCallFrom.ExternalInterface:
        any_program_ran = True

    if not any_program_ran:
        return

    var total_actuators = (
        state[].dataRuntimeLang.numActuatorsUsed
        + state[].dataRuntimeLang.NumExternalInterfaceActuatorsUsed
        + state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitImportActuatorsUsed
        + state[].dataRuntimeLang.NumExternalInterfaceFunctionalMockupUnitExportActuatorsUsed
    )

    for actuator_used_loop in range(1, total_actuators + 1):
        var this_actuator_used = state[].dataRuntimeLang.EMSActuatorUsed[actuator_used_loop - 1]

        var erl_variable_num = this_actuator_used.ErlVariableNum
        if erl_variable_num <= 0:
            continue

        var ems_actuator_variable_num = this_actuator_used.ActuatorVariableNum
        if ems_actuator_variable_num <= 0:
            continue

        var this_erl_var = state[].dataRuntimeLang.ErlVariable[erl_variable_num - 1]
        var this_actuator_avail = state[].dataRuntimeLang.EMSActuatorAvailable[ems_actuator_variable_num - 1]

        if this_erl_var.Value.Type == state[].dataRuntimeLanguage.Value.Null:
            this_actuator_avail.Actuated = False
        else:
            var ptr_var_type = this_actuator_avail.PntrVarTypeUsed
            if ptr_var_type == state[].dataRuntimeLanguage.PtrDataType.Real:
                this_actuator_avail.Actuated = True
                this_actuator_avail.RealValue = this_erl_var.Value.Number
            elif ptr_var_type == state[].dataRuntimeLanguage.PtrDataType.Integer:
                this_actuator_avail.Actuated = True
                var tmp_integer = floor(this_erl_var.Value.Number)
                this_actuator_avail.IntValue = Int(tmp_integer)
            elif ptr_var_type == state[].dataRuntimeLanguage.PtrDataType.Logical:
                this_actuator_avail.Actuated = True
                if this_erl_var.Value.Number == 0.0:
                    this_actuator_avail.LogValue = False
                elif this_erl_var.Value.Number == 1.0:
                    this_actuator_avail.LogValue = True
                else:
                    this_actuator_avail.LogValue = False

    report_ems(state)


fn init_ems(state: LifetimePointer[EnergyPlusData], i_called_from: Int) -> None:
    if state[].dataEMSMgr.get_ems_user_input:
        setup_zone_info_as_internal_data_avail(state)
        setup_window_shading_control_actuators(state)
        setup_surface_convection_actuators(state)
        setup_surface_construction_actuators(state)
        setup_surface_outdoor_boundary_condition_actuators(state)
        setup_zone_outdoor_boundary_condition_actuators(state)
        get_ems_input(state)
        state[].dataEMSMgr.get_ems_user_input = False

    if not state[].dataZoneCtrls.GetZoneAirStatsInputFlag and not state[].dataEMSMgr.zone_thermostat_actuators_have_been_setup:
        setup_thermostat_actuators(state)
        state[].dataEMSMgr.zone_thermostat_actuators_have_been_setup = True

    if (
        state[].dataEMSMgr.finish_processing_user_input
        and not state[].dataGlobal.DoingSizing
        and not state[].dataGlobal.KickOffSimulation
    ):
        setup_node_set_points_as_actuators(state)
        setup_primary_air_system_avail_mgr_as_actuators(state)
        state[].dataEMSMgr.finish_processing_user_input = False

    state[].dataRuntimeLanguageProcessor.InitializeRuntimeLanguage(state)

    if (
        state[].dataGlobal.BeginEnvrnFlag
        or i_called_from == EMSCallFrom.ZoneSizing
        or i_called_from == EMSCallFrom.SystemSizing
        or i_called_from == EMSCallFrom.UserDefinedComponentModel
    ):
        if state[].dataEMSMgr.finish_processing_user_input:
            process_ems_input(state, False)

        for internal_var_used_num in range(1, state[].dataRuntimeLang.NumInternalVariablesUsed + 1):
            var erl_variable_num = state[].dataRuntimeLang.EMSInternalVarsUsed[internal_var_used_num - 1].ErlVariableNum
            var intern_var_avail_num = state[].dataRuntimeLang.EMSInternalVarsUsed[internal_var_used_num - 1].InternVarNum
            if intern_var_avail_num <= 0:
                continue
            if erl_variable_num <= 0:
                continue

            var ptr_var_type = state[].dataRuntimeLang.EMSInternalVarsAvailable[intern_var_avail_num - 1].PntrVarTypeUsed
            if ptr_var_type == state[].dataRuntimeLanguage.PtrDataType.Real:
                state[].dataRuntimeLang.ErlVariable[erl_variable_num - 1].Value = (
                    state[].dataRuntimeLanguageProcessor.SetErlValueNumber(
                        state[].dataRuntimeLang.EMSInternalVarsAvailable[intern_var_avail_num - 1].RealValue
                    )
                )
            elif ptr_var_type == state[].dataRuntimeLanguage.PtrDataType.Integer:
                var tmp_real = Float(state[].dataRuntimeLang.EMSInternalVarsAvailable[intern_var_avail_num - 1].IntValue)
                state[].dataRuntimeLang.ErlVariable[erl_variable_num - 1].Value = (
                    state[].dataRuntimeLanguageProcessor.SetErlValueNumber(tmp_real)
                )

    for sensor_num in range(1, state[].dataRuntimeLang.NumSensors + 1):
        var erl_variable_num = state[].dataRuntimeLang.Sensor[sensor_num - 1].VariableNum
        if erl_variable_num > 0 and state[].dataRuntimeLang.Sensor[sensor_num - 1].Index > -1:
            if state[].dataRuntimeLang.Sensor[sensor_num - 1].sched == None:
                var sensor_value: Float
                if state[].dataRuntimeLang.Sensor[sensor_num - 1].VariableType == state[].dataOutputProcessor.VariableType.Meter:
                    sensor_value = (
                        state[].dataOutputProcessor.GetInstantMeterValue(
                            state, state[].dataRuntimeLang.Sensor[sensor_num - 1].Index, state[].dataOutputProcessor.TimeStepType.Zone
                        )
                        + state[].dataOutputProcessor.GetInstantMeterValue(
                            state, state[].dataRuntimeLang.Sensor[sensor_num - 1].Index, state[].dataOutputProcessor.TimeStepType.System
                        )
                    )
                else:
                    sensor_value = state[].dataOutputProcessor.GetInternalVariableValue(
                        state, state[].dataRuntimeLang.Sensor[sensor_num - 1].VariableType, state[].dataRuntimeLang.Sensor[sensor_num - 1].Index
                    )
                state[].dataRuntimeLang.ErlVariable[erl_variable_num - 1].Value = (
                    state[].dataRuntimeLanguageProcessor.SetErlValueNumber(sensor_value, state[].dataRuntimeLang.ErlVariable[erl_variable_num - 1].Value)
                )
            else:
                state[].dataRuntimeLang.ErlVariable[erl_variable_num - 1].Value = (
                    state[].dataRuntimeLanguageProcessor.SetErlValueNumber(
                        state[].dataRuntimeLang.Sensor[sensor_num - 1].sched.getCurrentVal(),
                        state[].dataRuntimeLang.ErlVariable[erl_variable_num - 1].Value,
                    )
                )


fn report_ems(state: LifetimePointer[EnergyPlusData]) -> None:
    state[].dataRuntimeLanguageProcessor.ReportRuntimeLanguage(state)


fn get_ems_input(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn process_ems_input(state: LifetimePointer[EnergyPlusData], report_errors: Bool) -> None:
    pass


fn get_variable_type_and_index(
    state: LifetimePointer[EnergyPlusData], var_name: StringRef, var_key_name: StringRef
) -> Tuple[Int, Int]:
    return (0, -1)


fn echo_out_actuator_key_choices(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn echo_out_internal_variable_choices(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn setup_node_set_points_as_actuators(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn update_ems_trend_variables(state: LifetimePointer[EnergyPlusData]) -> None:
    if not state[].dataGlobal.AnyEnergyManagementSystemInModel:
        return
    if state[].dataRuntimeLang.NumErlTrendVariables == 0:
        return

    for trend_num in range(1, state[].dataRuntimeLang.NumErlTrendVariables + 1):
        var erl_var_num = state[].dataRuntimeLang.TrendVariable[trend_num - 1].ErlVariablePointer
        var trend_depth = state[].dataRuntimeLang.TrendVariable[trend_num - 1].LogDepth
        if erl_var_num > 0 and trend_depth > 0:
            var current_val = state[].dataRuntimeLang.ErlVariable[erl_var_num - 1].Value.Number
            state[].dataRuntimeLang.TrendVariable[trend_num - 1].tempTrendARR = (
                state[].dataRuntimeLang.TrendVariable[trend_num - 1].TrendValARR
            )
            state[].dataRuntimeLang.TrendVariable[trend_num - 1].TrendValARR[0] = current_val
            for i in range(1, trend_depth):
                if i - 1 < trend_depth - 1:
                    state[].dataRuntimeLang.TrendVariable[trend_num - 1].TrendValARR[i] = (
                        state[].dataRuntimeLang.TrendVariable[trend_num - 1].tempTrendARR[i - 1]
                    )


fn check_if_node_set_point_managed(
    state: LifetimePointer[EnergyPlusData], node_num: Int, ctrl_var: Int, by_handle: Bool = False
) -> Bool:
    var found_control = False
    var c_node_name = state[].dataLoopNodes.NodeID[node_num - 1]
    var c_component_type_name = "System Node Setpoint"
    var control_type_names = get_control_type_names()
    var c_control_type_name = control_type_names[ctrl_var]

    if by_handle:
        for loop in range(1, state[].dataRuntimeLang.numEMSActuatorsAvailable + 1):
            if (
                state[].dataRuntimeLang.EMSActuatorAvailable[loop - 1].handleCount > 0
                and state[].dataUtil.SameString(
                    state[].dataRuntimeLang.EMSActuatorAvailable[loop - 1].ComponentTypeName, c_component_type_name
                )
                and state[].dataUtil.SameString(state[].dataRuntimeLang.EMSActuatorAvailable[loop - 1].UniqueIDName, c_node_name)
                and state[].dataUtil.SameString(state[].dataRuntimeLang.EMSActuatorAvailable[loop - 1].ControlTypeName, c_control_type_name)
            ):
                found_control = True
                break
        if not found_control:
            state[].ShowWarningError(
                f"Missing '{control_type_names[ctrl_var]}' for node named named '{state[].dataLoopNodes.NodeID[node_num - 1]}'."
            )
    else:
        for loop in range(
            1, state[].dataRuntimeLang.numActuatorsUsed + state[].dataRuntimeLang.NumExternalInterfaceActuatorsUsed + 1
        ):
            if (
                state[].dataUtil.SameString(
                    state[].dataRuntimeLang.EMSActuatorUsed[loop - 1].ComponentTypeName, c_component_type_name
                )
                and state[].dataUtil.SameString(state[].dataRuntimeLang.EMSActuatorUsed[loop - 1].UniqueIDName, c_node_name)
                and state[].dataUtil.SameString(state[].dataRuntimeLang.EMSActuatorUsed[loop - 1].ControlTypeName, c_control_type_name)
            ):
                found_control = True
                break

    return found_control


fn check_if_node_set_point_managed_by_ems(
    state: LifetimePointer[EnergyPlusData], node_num: Int, ctrl_var: Int, inout error_flag: Bool
) -> Bool:
    var found_control = check_if_node_set_point_managed(state, node_num, ctrl_var, False)

    if not error_flag and not found_control:
        var num_python_plugins = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(state, "PythonPlugin:Instance")
        var num_active_callbacks = state[].dataPluginManagement.PluginManager.numActiveCallbacks(state)
        if (num_python_plugins + num_active_callbacks) == 0:
            error_flag = True
        else:
            var node_setpoint_check = state[].dataLoopNodes.NodeSetpointCheck[node_num - 1]
            node_setpoint_check.needsSetpointChecking = True
            node_setpoint_check.checkSetPoint[ctrl_var] = True

    return found_control


fn check_if_node_more_info_sensed_by_ems(state: LifetimePointer[EnergyPlusData], node_num: Int, var_name: StringRef) -> Bool:
    var return_value = False
    for loop in range(1, state[].dataRuntimeLang.NumSensors + 1):
        if (
            state[].dataRuntimeLang.Sensor[loop - 1].UniqueKeyName == state[].dataLoopNodes.NodeID[node_num - 1]
            and state[].dataUtil.SameString(state[].dataRuntimeLang.Sensor[loop - 1].OutputVarName, var_name)
        ):
            return_value = True
    return return_value


fn is_schedule_managed(state: LifetimePointer[EnergyPlusData], sched: Any) -> Bool:
    var c_control_type_name = "SCHEDULE VALUE"
    for loop in range(
        1, state[].dataRuntimeLang.numActuatorsUsed + state[].dataRuntimeLang.NumExternalInterfaceActuatorsUsed + 1
    ):
        if (
            state[].dataUtil.SameString(state[].dataRuntimeLang.EMSActuatorUsed[loop - 1].UniqueIDName, sched.Name)
            and state[].dataUtil.SameString(state[].dataRuntimeLang.EMSActuatorUsed[loop - 1].ControlTypeName, c_control_type_name)
        ):
            return True
    return False


fn setup_primary_air_system_avail_mgr_as_actuators(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn setup_window_shading_control_actuators(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn setup_thermostat_actuators(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn setup_surface_convection_actuators(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn setup_surface_construction_actuators(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn setup_surface_outdoor_boundary_condition_actuators(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn setup_zone_info_as_internal_data_avail(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn setup_zone_outdoor_boundary_condition_actuators(state: LifetimePointer[EnergyPlusData]) -> None:
    pass


fn check_for_unused_actuators_at_end(state: LifetimePointer[EnergyPlusData]) -> None:
    for actuator_used_loop in range(1, state[].dataRuntimeLang.numActuatorsUsed + 1):
        if not state[].dataRuntimeLang.EMSActuatorUsed[actuator_used_loop - 1].wasActuated:
            state[].ShowWarningError(
                "checkForUnusedActuatorsAtEnd: Unused EMS Actuator detected, suggesting possible unintended programming error or spelling mistake."
            )
            state[].ShowContinueError(
                f"Check Erl programs related to EMS actuator variable name = {state[].dataRuntimeLang.EMSActuatorUsed[actuator_used_loop - 1].Name}"
            )
            state[].ShowContinueError(
                f"EMS Actuator type name = {state[].dataRuntimeLang.EMSActuatorUsed[actuator_used_loop - 1].ComponentTypeName}"
            )
            state[].ShowContinueError(
                f"EMS Actuator unique component name = {state[].dataRuntimeLang.EMSActuatorUsed[actuator_used_loop - 1].UniqueIDName}"
            )
            state[].ShowContinueError(
                f"EMS Actuator control type = {state[].dataRuntimeLang.EMSActuatorUsed[actuator_used_loop - 1].ControlTypeName}"
            )


fn check_setpoint_nodes_at_end(state: LifetimePointer[EnergyPlusData]) -> None:
    var fatal_error_flag = False

    for node_num in range(1, state[].dataLoopNodes.NumOfNodes + 1):
        var node_setpoint_check = state[].dataLoopNodes.NodeSetpointCheck[node_num - 1]

        if node_setpoint_check.needsSetpointChecking:
            node_setpoint_check.needsSetpointChecking = False

            for i_ctrl_var in range(int(state[].dataHVAC.CtrlVarType.Num)):
                if node_setpoint_check.checkSetPoint[i_ctrl_var]:
                    node_setpoint_check.needsSetpointChecking |= not check_if_node_set_point_managed(
                        state, node_num, i_ctrl_var, True
                    )

            if node_setpoint_check.needsSetpointChecking:
                fatal_error_flag = True

    if fatal_error_flag:
        state[].ShowFatalError(
            "checkSetpointNodesAtEnd: At least one node does not have a setpoint attached, "
            "neither via a SetpointManager, EMS:Actuator, or API"
        )


fn setup_ems_actuator_real(
    state: LifetimePointer[EnergyPlusData],
    component_type_name: StringRef,
    unique_id_name: StringRef,
    control_type_name: StringRef,
    units: StringRef,
    inout ems_actuated: Bool,
    inout r_value: Float,
) -> None:
    var s_lang = state[].dataRuntimeLang
    var obj_type = state[].dataUtil.makeUPPER(component_type_name)
    var obj_name = state[].dataUtil.makeUPPER(unique_id_name)
    var control_name = state[].dataUtil.makeUPPER(control_type_name)

    var tup = (obj_type, obj_name, control_name)

    if tup in s_lang.EMSActuatorAvailableMap:
        return

    if s_lang.numEMSActuatorsAvailable == 0:
        s_lang.numEMSActuatorsAvailable = 1
        s_lang.maxEMSActuatorsAvailable = s_lang.varsAvailableAllocInc
    else:
        if s_lang.numEMSActuatorsAvailable + 1 > s_lang.maxEMSActuatorsAvailable:
            s_lang.maxEMSActuatorsAvailable *= 2
        s_lang.numEMSActuatorsAvailable += 1

    var actuator = s_lang.EMSActuatorAvailable[s_lang.numEMSActuatorsAvailable - 1]
    actuator.ComponentTypeName = component_type_name
    actuator.UniqueIDName = unique_id_name
    actuator.ControlTypeName = control_type_name
    actuator.Units = units
    actuator.Actuated = ems_actuated
    actuator.RealValue = r_value
    actuator.PntrVarTypeUsed = state[].dataRuntimeLanguage.PtrDataType.Real
    s_lang.EMSActuatorAvailableMap[tup] = s_lang.numEMSActuatorsAvailable


fn setup_ems_actuator_int(
    state: LifetimePointer[EnergyPlusData],
    component_type_name: StringRef,
    unique_id_name: StringRef,
    control_type_name: StringRef,
    units: StringRef,
    inout ems_actuated: Bool,
    inout i_value: Int,
) -> None:
    var s_lang = state[].dataRuntimeLang
    var obj_type = state[].dataUtil.makeUPPER(component_type_name)
    var obj_name = state[].dataUtil.makeUPPER(unique_id_name)
    var control_name = state[].dataUtil.makeUPPER(control_type_name)

    var tup = (obj_type, obj_name, control_name)

    if tup not in s_lang.EMSActuatorAvailableMap:
        if s_lang.numEMSActuatorsAvailable == 0:
            s_lang.numEMSActuatorsAvailable = 1
            s_lang.maxEMSActuatorsAvailable = s_lang.varsAvailableAllocInc
        else:
            if s_lang.numEMSActuatorsAvailable + 1 > s_lang.maxEMSActuatorsAvailable:
                s_lang.maxEMSActuatorsAvailable *= 2
            s_lang.numEMSActuatorsAvailable += 1

        var actuator = s_lang.EMSActuatorAvailable[s_lang.numEMSActuatorsAvailable - 1]
        actuator.ComponentTypeName = component_type_name
        actuator.UniqueIDName = unique_id_name
        actuator.ControlTypeName = control_type_name
        actuator.Units = units
        actuator.Actuated = ems_actuated
        actuator.IntValue = i_value
        actuator.PntrVarTypeUsed = state[].dataRuntimeLanguage.PtrDataType.Integer
        s_lang.EMSActuatorAvailableMap[tup] = s_lang.numEMSActuatorsAvailable


fn setup_ems_actuator_bool(
    state: LifetimePointer[EnergyPlusData],
    component_type_name: StringRef,
    unique_id_name: StringRef,
    control_type_name: StringRef,
    units: StringRef,
    inout ems_actuated: Bool,
    inout l_value: Bool,
) -> None:
    var s_lang = state[].dataRuntimeLang
    var obj_type = state[].dataUtil.makeUPPER(component_type_name)
    var obj_name = state[].dataUtil.makeUPPER(unique_id_name)
    var control_name = state[].dataUtil.makeUPPER(control_type_name)

    var tup = (obj_type, obj_name, control_name)

    if tup not in s_lang.EMSActuatorAvailableMap:
        if s_lang.numEMSActuatorsAvailable == 0:
            s_lang.numEMSActuatorsAvailable = 1
            s_lang.maxEMSActuatorsAvailable = s_lang.varsAvailableAllocInc
        else:
            if s_lang.numEMSActuatorsAvailable + 1 > s_lang.maxEMSActuatorsAvailable:
                s_lang.maxEMSActuatorsAvailable *= 2
            s_lang.numEMSActuatorsAvailable += 1

        var actuator = s_lang.EMSActuatorAvailable[s_lang.numEMSActuatorsAvailable - 1]
        actuator.ComponentTypeName = component_type_name
        actuator.UniqueIDName = unique_id_name
        actuator.ControlTypeName = control_type_name
        actuator.Units = units
        actuator.Actuated = ems_actuated
        actuator.LogValue = l_value
        actuator.PntrVarTypeUsed = state[].dataRuntimeLanguage.PtrDataType.Logical
        s_lang.EMSActuatorAvailableMap[tup] = s_lang.numEMSActuatorsAvailable


fn setup_ems_internal_variable_real(
    state: LifetimePointer[EnergyPlusData], data_type_name: StringRef, unique_id_name: StringRef, units: StringRef, inout r_value: Float
) -> None:
    var found_duplicate = False
    for internal_var_avail_num in range(1, state[].dataRuntimeLang.numEMSInternalVarsAvailable + 1):
        if (
            state[].dataUtil.SameString(data_type_name, state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].DataTypeName)
            and state[].dataUtil.SameString(unique_id_name, state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].UniqueIDName)
        ):
            found_duplicate = True
            break

    if found_duplicate:
        state[].ShowSevereError("Duplicate internal variable was sent to SetupEMSInternalVariable")
        state[].ShowContinueError(f"Internal variable type = {data_type_name} ; name = {unique_id_name}")
        state[].ShowContinueError("Called from SetupEMSInternalVariable")
    else:
        if state[].dataRuntimeLang.numEMSInternalVarsAvailable == 0:
            state[].dataRuntimeLang.numEMSInternalVarsAvailable = 1
            state[].dataRuntimeLang.maxEMSInternalVarsAvailable = state[].dataRuntimeLang.varsAvailableAllocInc
        else:
            if state[].dataRuntimeLang.numEMSInternalVarsAvailable + 1 > state[].dataRuntimeLang.maxEMSInternalVarsAvailable:
                state[].dataRuntimeLang.maxEMSInternalVarsAvailable += state[].dataRuntimeLang.varsAvailableAllocInc
            state[].dataRuntimeLang.numEMSInternalVarsAvailable += 1

        var internal_var_avail_num = state[].dataRuntimeLang.numEMSInternalVarsAvailable
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].DataTypeName = data_type_name
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].UniqueIDName = unique_id_name
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].Units = units
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].RealValue = r_value
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].PntrVarTypeUsed = (
            state[].dataRuntimeLanguage.PtrDataType.Real
        )


fn setup_ems_internal_variable_int(
    state: LifetimePointer[EnergyPlusData], data_type_name: StringRef, unique_id_name: StringRef, units: StringRef, inout i_value: Int
) -> None:
    var found_duplicate = False
    for internal_var_avail_num in range(1, state[].dataRuntimeLang.numEMSInternalVarsAvailable + 1):
        if (
            state[].dataUtil.SameString(data_type_name, state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].DataTypeName)
            and state[].dataUtil.SameString(unique_id_name, state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].UniqueIDName)
        ):
            found_duplicate = True
            break

    if found_duplicate:
        state[].ShowSevereError("Duplicate internal variable was sent to SetupEMSInternalVariable.")
        state[].ShowContinueError(f"Internal variable type = {data_type_name} ; name = {unique_id_name}")
        state[].ShowContinueError("called from SetupEMSInternalVariable")
    else:
        if state[].dataRuntimeLang.numEMSInternalVarsAvailable == 0:
            state[].dataRuntimeLang.numEMSInternalVarsAvailable = 1
            state[].dataRuntimeLang.maxEMSInternalVarsAvailable = state[].dataRuntimeLang.varsAvailableAllocInc
        else:
            if state[].dataRuntimeLang.numEMSInternalVarsAvailable + 1 > state[].dataRuntimeLang.maxEMSInternalVarsAvailable:
                state[].dataRuntimeLang.maxEMSInternalVarsAvailable += state[].dataRuntimeLang.varsAvailableAllocInc
            state[].dataRuntimeLang.numEMSInternalVarsAvailable += 1

        var internal_var_avail_num = state[].dataRuntimeLang.numEMSInternalVarsAvailable
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].DataTypeName = data_type_name
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].UniqueIDName = unique_id_name
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].Units = units
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].IntValue = i_value
        state[].dataRuntimeLang.EMSInternalVarsAvailable[internal_var_avail_num - 1].PntrVarTypeUsed = (
            state[].dataRuntimeLanguage.PtrDataType.Integer
        )
