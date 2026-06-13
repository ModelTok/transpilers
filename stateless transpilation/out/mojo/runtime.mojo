from utils.inlinable import Inlinable
from collections import InlineArray


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: from EnergyPlus/Data/EnergyPlusData.hh (state object)
# - PluginManagement.registerNewCallback: from EnergyPlus/PluginManager.hh
# - PluginManagement.registerUserDefinedCallback: from EnergyPlus/PluginManager.hh
# - EMSManager.EMSCallFrom enum: from EnergyPlus (simulation point markers)
# - runEnergyPlusAsLibrary: from EnergyPlus/api/EnergyPlusPgm.hh
# - ShowWarningError, ShowSevereError, ShowContinueError: from EnergyPlus/UtilityRoutines.hh


alias EnergyPlusState = DTypePointer[DType.uint8]
alias EnergyPlusCallback = fn (EnergyPlusState) -> None
alias ProgressCallback = fn (Int) -> None
alias StdOutCallback = fn (StringRef) -> None


struct EMSCallFrom:
    var BeginNewEnvironment: Int
    var BeginNewEnvironmentAfterWarmUp: Int
    var BeginZoneTimestepBeforeSetCurrentWeather: Int
    var BeginZoneTimestepBeforeInitHeatBalance: Int
    var BeginZoneTimestepAfterInitHeatBalance: Int
    var BeginTimestepBeforePredictor: Int
    var BeforeHVACManagers: Int
    var AfterHVACManagers: Int
    var HVACIterationLoop: Int
    var EndZoneTimestepBeforeZoneReporting: Int
    var EndZoneTimestepAfterZoneReporting: Int
    var EndSystemTimestepBeforeHVACReporting: Int
    var EndSystemTimestepAfterHVACReporting: Int
    var ZoneSizing: Int
    var SystemSizing: Int
    var ComponentGetInput: Int
    var UnitarySystemSizing: Int


struct EnergyPlusDataStub:
    var ready: Bool
    var print_console_output: Bool
    var stop_simulation: Bool
    var install_root_override: Bool
    var progress_callback: UnsafePointer[EnergyPlusCallback]
    var message_callback: UnsafePointer[StdOutCallback]
    var external_hvac_manager: UnsafePointer[EnergyPlusCallback]


fn _show_warning_error(state: EnergyPlusState, message: StringRef) -> None:
    pass


fn _show_severe_error(state: EnergyPlusState, message: StringRef) -> None:
    pass


fn _show_continue_error(state: EnergyPlusState, message: StringRef) -> None:
    pass


fn _run_energy_plus_as_library(this_state: EnergyPlusDataStub, args: List[String]) -> Int:
    return 0


fn _plugin_management_register_new_callback(
    state: EnergyPlusDataStub, 
    ems_call_from: Int, 
    f: EnergyPlusCallback
) -> None:
    pass


fn _plugin_management_register_user_defined_callback(
    state: EnergyPlusDataStub,
    f: EnergyPlusCallback,
    program_name: StringRef
) -> None:
    pass


@export
fn energyplus(state: EnergyPlusState, argc: Int, argv: List[String]) -> Int:
    var this_state = rebind[EnergyPlusDataStub](state)
    if not this_state.ready:
        var stderr = __import__("sys").stderr
        stderr.write(
            "Attempted to re-run EnergyPlus using a state that was not yet cleared, "
            "call stateReset() on this instance and try again\n"
        )
        return 1
    this_state.ready = False
    return _run_energy_plus_as_library(this_state, argv)


@export
fn stopSimulation(state: EnergyPlusState) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    this_state.stop_simulation = True


@export
fn setConsoleOutputState(state: EnergyPlusState, output_status: Int) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    this_state.print_console_output = (output_status != 0)


@export
fn setEnergyPlusRootDirectory(state: EnergyPlusState, path: StringRef) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    this_state.install_root_override = True


@export
fn issueWarning(state: EnergyPlusState, message: StringRef) -> None:
    _show_warning_error(state, message)


@export
fn issueSevere(state: EnergyPlusState, message: StringRef) -> None:
    _show_severe_error(state, message)


@export
fn issueText(state: EnergyPlusState, message: StringRef) -> None:
    _show_continue_error(state, message)


@export
fn registerProgressCallback(state: EnergyPlusState, f: ProgressCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    this_state.progress_callback = UnsafePointer.address_of(f)


@export
fn registerStdOutCallback(state: EnergyPlusState, f: StdOutCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    this_state.message_callback = UnsafePointer.address_of(f)


@export
fn registerExternalHVACManager(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    this_state.external_hvac_manager = UnsafePointer.address_of(f)


@export
fn callbackBeginNewEnvironment(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(this_state, ems_call_from.BeginNewEnvironment, f)


@export
fn callbackBeginZoneTimestepBeforeSetCurrentWeather(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.BeginZoneTimestepBeforeSetCurrentWeather, 
        f
    )


@export
fn callbackAfterNewEnvironmentWarmupComplete(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.BeginNewEnvironmentAfterWarmUp, 
        f
    )


@export
fn callbackBeginZoneTimeStepBeforeInitHeatBalance(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.BeginZoneTimestepBeforeInitHeatBalance, 
        f
    )


@export
fn callbackBeginZoneTimeStepAfterInitHeatBalance(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.BeginZoneTimestepAfterInitHeatBalance, 
        f
    )


@export
fn callbackBeginTimeStepBeforePredictor(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.BeginTimestepBeforePredictor, 
        f
    )


@export
fn callbackAfterPredictorBeforeHVACManagers(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.BeforeHVACManagers, 
        f
    )


@export
fn callbackAfterPredictorAfterHVACManagers(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.AfterHVACManagers, 
        f
    )


@export
fn callbackInsideSystemIterationLoop(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.HVACIterationLoop, 
        f
    )


@export
fn callbackEndOfZoneTimeStepBeforeZoneReporting(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.EndZoneTimestepBeforeZoneReporting, 
        f
    )


@export
fn callbackEndOfZoneTimeStepAfterZoneReporting(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.EndZoneTimestepAfterZoneReporting, 
        f
    )


@export
fn callbackEndOfSystemTimeStepBeforeHVACReporting(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.EndSystemTimestepBeforeHVACReporting, 
        f
    )


@export
fn callbackEndOfSystemTimeStepAfterHVACReporting(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.EndSystemTimestepAfterHVACReporting, 
        f
    )


@export
fn callbackEndOfZoneSizing(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.ZoneSizing, 
        f
    )


@export
fn callbackEndOfSystemSizing(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.SystemSizing, 
        f
    )


@export
fn callbackEndOfAfterComponentGetInput(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.ComponentGetInput, 
        f
    )


@export
fn callbackUserDefinedComponentModel(
    state: EnergyPlusState, 
    f: EnergyPlusCallback, 
    program_name: StringRef
) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    _plugin_management_register_user_defined_callback(this_state, f, program_name)


@export
fn callbackUnitarySystemSizing(state: EnergyPlusState, f: EnergyPlusCallback) -> None:
    var this_state = rebind[EnergyPlusDataStub](state)
    var ems_call_from = EMSCallFrom()
    _plugin_management_register_new_callback(
        this_state, 
        ems_call_from.UnitarySystemSizing, 
        f
    )
