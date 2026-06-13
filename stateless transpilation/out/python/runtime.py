from typing import Callable, Optional, Protocol, cast
from ctypes import c_void_p, c_int, c_char_p
import ctypes


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: from EnergyPlus/Data/EnergyPlusData.hh (state object)
# - PluginManagement.registerNewCallback: from EnergyPlus/PluginManager.hh
# - PluginManagement.registerUserDefinedCallback: from EnergyPlus/PluginManager.hh
# - EMSManager.EMSCallFrom enum: from EnergyPlus (simulation point markers)
# - runEnergyPlusAsLibrary: from EnergyPlus/api/EnergyPlusPgm.hh
# - ShowWarningError, ShowSevereError, ShowContinueError: from EnergyPlus/UtilityRoutines.hh
# - DataStringGlobals.exeDirectoryPath: from EnergyPlus/DataStringGlobals.hh


class EnergyPlusData(Protocol):
    ready: bool
    printConsoleOutput: bool
    stopSimulation: bool
    installRootOverride: bool
    progressCallback: Optional[Callable[[int], None]]
    messageCallback: Optional[Callable[[str], None]]
    externalHVACManager: Optional[Callable[["EnergyPlusState"], None]]


class DataGlobalProperties(Protocol):
    stopSimulation: bool
    printConsoleOutput: bool
    installRootOverride: bool
    progressCallback: Optional[Callable[[int], None]]
    messageCallback: Optional[Callable[[str], None]]
    externalHVACManager: Optional[Callable[["EnergyPlusState"], None]]


class DataStringGlobalsProperties(Protocol):
    exeDirectoryPath: str


class PluginManagement(Protocol):
    @staticmethod
    def registerNewCallback(state: EnergyPlusData, emsCallFrom: int, 
                           callback: Callable[["EnergyPlusState"], None]) -> None: ...
    
    @staticmethod
    def registerUserDefinedCallback(state: EnergyPlusData, 
                                   callback: Callable[["EnergyPlusState"], None],
                                   programName: str) -> None: ...


class EMSManager(Protocol):
    class EMSCallFrom:
        BeginNewEnvironment: int
        BeginNewEnvironmentAfterWarmUp: int
        BeginZoneTimestepBeforeSetCurrentWeather: int
        BeginZoneTimestepBeforeInitHeatBalance: int
        BeginZoneTimestepAfterInitHeatBalance: int
        BeginTimestepBeforePredictor: int
        BeforeHVACManagers: int
        AfterHVACManagers: int
        HVACIterationLoop: int
        EndZoneTimestepBeforeZoneReporting: int
        EndZoneTimestepAfterZoneReporting: int
        EndSystemTimestepBeforeHVACReporting: int
        EndSystemTimestepAfterHVACReporting: int
        ZoneSizing: int
        SystemSizing: int
        ComponentGetInput: int
        UnitarySystemSizing: int


EnergyPlusState = c_void_p


def _show_warning_error(state: EnergyPlusState, message: str) -> None:
    pass


def _show_severe_error(state: EnergyPlusState, message: str) -> None:
    pass


def _show_continue_error(state: EnergyPlusState, message: str) -> None:
    pass


def _run_energy_plus_as_library(this_state: EnergyPlusData, args: list[str]) -> int:
    return 0


def _plugin_management_register_new_callback(
    state: EnergyPlusData, 
    emsCallFrom: int, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    pass


def _plugin_management_register_user_defined_callback(
    state: EnergyPlusData,
    f: Callable[[EnergyPlusState], None],
    programName: str
) -> None:
    pass


def energyplus(state: EnergyPlusState, argc: int, argv: list[str]) -> int:
    this_state = cast(state, EnergyPlusData)
    if not this_state.ready:
        import sys
        sys.stderr.write(
            "Attempted to re-run EnergyPlus using a state that was not yet cleared, "
            "call stateReset() on this instance and try again\n"
        )
        return 1
    this_state.ready = False
    return _run_energy_plus_as_library(this_state, argv)


def stopSimulation(state: EnergyPlusState) -> None:
    this_state = cast(state, EnergyPlusData)
    this_state.stopSimulation = True


def setConsoleOutputState(state: EnergyPlusState, outputStatus: int) -> None:
    this_state = cast(state, EnergyPlusData)
    this_state.printConsoleOutput = (outputStatus != 0)


def setEnergyPlusRootDirectory(state: EnergyPlusState, path: str) -> None:
    this_state = cast(state, EnergyPlusData)
    this_state.installRootOverride = True


def issueWarning(state: EnergyPlusState, message: str) -> None:
    this_state = cast(state, EnergyPlusData)
    _show_warning_error(state, message)


def issueSevere(state: EnergyPlusState, message: str) -> None:
    this_state = cast(state, EnergyPlusData)
    _show_severe_error(state, message)


def issueText(state: EnergyPlusState, message: str) -> None:
    this_state = cast(state, EnergyPlusData)
    _show_continue_error(state, message)


def registerProgressCallback(state: EnergyPlusState, f: Callable[[int], None]) -> None:
    this_state = cast(state, EnergyPlusData)
    this_state.progressCallback = f


def registerStdOutCallback(state: EnergyPlusState, f: Callable[[str], None]) -> None:
    this_state = cast(state, EnergyPlusData)
    this_state.messageCallback = f


def registerExternalHVACManager(state: EnergyPlusState, f: Callable[[EnergyPlusState], None]) -> None:
    this_state = cast(state, EnergyPlusData)
    this_state.externalHVACManager = f


def callbackBeginNewEnvironment(state: EnergyPlusState, f: Callable[[EnergyPlusState], None]) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state, 
        EMSManager.EMSCallFrom.BeginNewEnvironment, 
        f
    )


def callbackBeginZoneTimestepBeforeSetCurrentWeather(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.BeginZoneTimestepBeforeSetCurrentWeather,
        f
    )


def callbackAfterNewEnvironmentWarmupComplete(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.BeginNewEnvironmentAfterWarmUp,
        f
    )


def callbackBeginZoneTimeStepBeforeInitHeatBalance(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.BeginZoneTimestepBeforeInitHeatBalance,
        f
    )


def callbackBeginZoneTimeStepAfterInitHeatBalance(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.BeginZoneTimestepAfterInitHeatBalance,
        f
    )


def callbackBeginTimeStepBeforePredictor(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.BeginTimestepBeforePredictor,
        f
    )


def callbackAfterPredictorBeforeHVACManagers(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.BeforeHVACManagers,
        f
    )


def callbackAfterPredictorAfterHVACManagers(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.AfterHVACManagers,
        f
    )


def callbackInsideSystemIterationLoop(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.HVACIterationLoop,
        f
    )


def callbackEndOfZoneTimeStepBeforeZoneReporting(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.EndZoneTimestepBeforeZoneReporting,
        f
    )


def callbackEndOfZoneTimeStepAfterZoneReporting(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.EndZoneTimestepAfterZoneReporting,
        f
    )


def callbackEndOfSystemTimeStepBeforeHVACReporting(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.EndSystemTimestepBeforeHVACReporting,
        f
    )


def callbackEndOfSystemTimeStepAfterHVACReporting(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.EndSystemTimestepAfterHVACReporting,
        f
    )


def callbackEndOfZoneSizing(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.ZoneSizing,
        f
    )


def callbackEndOfSystemSizing(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.SystemSizing,
        f
    )


def callbackEndOfAfterComponentGetInput(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.ComponentGetInput,
        f
    )


def callbackUserDefinedComponentModel(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None],
    programName: str
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_user_defined_callback(this_state, f, programName)


def callbackUnitarySystemSizing(
    state: EnergyPlusState, 
    f: Callable[[EnergyPlusState], None]
) -> None:
    this_state = cast(state, EnergyPlusData)
    _plugin_management_register_new_callback(
        this_state,
        EMSManager.EMSCallFrom.UnitarySystemSizing,
        f
    )
