from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataStringGlobals import DataStrGlobals
from EnergyPlus.PluginManager import PluginManagement
from EnergyPlus.UtilityRoutines import ShowWarningError, ShowSevereError, ShowContinueError
from EnergyPlusPgm import runEnergyPlusAsLibrary
from EnergyPlus.api.TypeDefs import EnergyPlusState
from EnergyPlus.EMSManager import EMSCallFrom
from sys import stderr

def energyplus(state: EnergyPlusState, argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    let thisState = Pointer[EnergyPlusData](state)
    if not thisState[].ready:
        stderr.write("Attempted to re-run EnergyPlus using a state that was not yet cleared, call stateReset() on this instance and try again\n")
        return 1
    thisState[].ready = False
    var args = List[String]()
    for i in range(argc):
        args.append(String(argv[i]))
    return runEnergyPlusAsLibrary(thisState[], args)

def stopSimulation(state: EnergyPlusState):
    let thisState = Pointer[EnergyPlusData](state)
    thisState[].dataGlobal[].stopSimulation = True

def setConsoleOutputState(state: EnergyPlusState, outputStatus: Int):
    let thisState = Pointer[EnergyPlusData](state)
    thisState[].dataGlobal[].printConsoleOutput = outputStatus != 0

def setEnergyPlusRootDirectory(state: EnergyPlusState, path: Pointer[UInt8]):
    let thisState = Pointer[EnergyPlusData](state)
    thisState[].dataGlobal[].installRootOverride = True
    thisState[].dataStrGlobals[].exeDirectoryPath = String(path)

def issueWarning(state: EnergyPlusState, message: Pointer[UInt8]):
    let thisState = Pointer[EnergyPlusData](state)
    ShowWarningError(thisState[], message)

def issueSevere(state: EnergyPlusState, message: Pointer[UInt8]):
    let thisState = Pointer[EnergyPlusData](state)
    ShowSevereError(thisState[], message)

def issueText(state: EnergyPlusState, message: Pointer[UInt8]):
    let thisState = Pointer[EnergyPlusData](state)
    ShowContinueError(thisState[], message)

def registerProgressCallback(state: EnergyPlusState, f: (Int) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    thisState[].dataGlobal[].progressCallback = f

def registerProgressCallback(state: EnergyPlusState, f: fn(Int) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    thisState[].dataGlobal[].progressCallback = f

def registerStdOutCallback(state: EnergyPlusState, f: (String) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    thisState[].dataGlobal[].messageCallback = f

def registerStdOutCallback(state: EnergyPlusState, f: fn(Pointer[UInt8]) -> Void):
    let stdf = fn(message: String): f(message.c_str())
    registerStdOutCallback(state, stdf)

def registerExternalHVACManager(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    thisState[].dataGlobal[].externalHVACManager = f

def registerExternalHVACManager(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    thisState[].dataGlobal[].externalHVACManager = f

def callbackBeginNewEnvironment(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginNewEnvironment, f)

def callbackBeginNewEnvironment(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginNewEnvironment, f)

def callbackBeginZoneTimestepBeforeSetCurrentWeather(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginZoneTimestepBeforeSetCurrentWeather, f)

def callbackBeginZoneTimestepBeforeSetCurrentWeather(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginZoneTimestepBeforeSetCurrentWeather, f)

def callbackAfterNewEnvironmentWarmupComplete(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginNewEnvironmentAfterWarmUp, f)

def callbackAfterNewEnvironmentWarmupComplete(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginNewEnvironmentAfterWarmUp, f)

def callbackBeginZoneTimeStepBeforeInitHeatBalance(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginZoneTimestepBeforeInitHeatBalance, f)

def callbackBeginZoneTimeStepBeforeInitHeatBalance(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginZoneTimestepBeforeInitHeatBalance, f)

def callbackBeginZoneTimeStepAfterInitHeatBalance(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginZoneTimestepAfterInitHeatBalance, f)

def callbackBeginZoneTimeStepAfterInitHeatBalance(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginZoneTimestepAfterInitHeatBalance, f)

def callbackBeginTimeStepBeforePredictor(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginTimestepBeforePredictor, f)

def callbackBeginTimeStepBeforePredictor(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeginTimestepBeforePredictor, f)

def callbackAfterPredictorBeforeHVACManagers(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeforeHVACManagers, f)

def callbackAfterPredictorBeforeHVACManagers(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.BeforeHVACManagers, f)

def callbackAfterPredictorAfterHVACManagers(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.AfterHVACManagers, f)

def callbackAfterPredictorAfterHVACManagers(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.AfterHVACManagers, f)

def callbackInsideSystemIterationLoop(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.HVACIterationLoop, f)

def callbackInsideSystemIterationLoop(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.HVACIterationLoop, f)

def callbackEndOfZoneTimeStepBeforeZoneReporting(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.EndZoneTimestepBeforeZoneReporting, f)

def callbackEndOfZoneTimeStepBeforeZoneReporting(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.EndZoneTimestepBeforeZoneReporting, f)

def callbackEndOfZoneTimeStepAfterZoneReporting(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.EndZoneTimestepAfterZoneReporting, f)

def callbackEndOfZoneTimeStepAfterZoneReporting(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.EndZoneTimestepAfterZoneReporting, f)

def callbackEndOfSystemTimeStepBeforeHVACReporting(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.EndSystemTimestepBeforeHVACReporting, f)

def callbackEndOfSystemTimeStepBeforeHVACReporting(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.EndSystemTimestepBeforeHVACReporting, f)

def callbackEndOfSystemTimeStepAfterHVACReporting(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.EndSystemTimestepAfterHVACReporting, f)

def callbackEndOfSystemTimeStepAfterHVACReporting(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.EndSystemTimestepAfterHVACReporting, f)

def callbackEndOfZoneSizing(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.ZoneSizing, f)

def callbackEndOfZoneSizing(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.ZoneSizing, f)

def callbackEndOfSystemSizing(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.SystemSizing, f)

def callbackEndOfSystemSizing(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.SystemSizing, f)

def callbackEndOfAfterComponentGetInput(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.ComponentGetInput, f)

def callbackEndOfAfterComponentGetInput(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.ComponentGetInput, f)

def callbackUserDefinedComponentModel(state: EnergyPlusState, f: (EnergyPlusState) -> Void, programNameInInputFile: Pointer[UInt8]):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerUserDefinedCallback(thisState[], f, programNameInInputFile)

def callbackUserDefinedComponentModel(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void, programNameInInputFile: Pointer[UInt8]):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerUserDefinedCallback(thisState[], f, programNameInInputFile)

def callbackUnitarySystemSizing(state: EnergyPlusState, f: (EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.UnitarySystemSizing, f)

def callbackUnitarySystemSizing(state: EnergyPlusState, f: fn(EnergyPlusState) -> Void):
    let thisState = Pointer[EnergyPlusData](state)
    PluginManagement.registerNewCallback(thisState[], EMSCallFrom.UnitarySystemSizing, f)