# LINK_WITH_PYTHON is not defined in Mojo, so all Python-related code is omitted
# The following is a faithful 1:1 translation of the non-Python parts

from EnergyPlus.EMSManager import EMSCallFrom
from EnergyPlus.EnergyPlus import EnergyPlusData
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataGlobalConstants import Constant
from EnergyPlus.DataStringGlobals import DataStringGlobals
from EnergyPlus.FileSystem import FileSystem
from EnergyPlus.Formatters import Formatters
from EnergyPlus.InputProcessing.InputProcessor import InputProcessor
from EnergyPlus.OutputProcessor import OutputProcessor
from EnergyPlus.UtilityRoutines import Util
from EnergyPlus.UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError, ShowWarningMessage, ShowMessage, ShowSevereMessage
from EnergyPlus.UtilityRoutines import get_environment_variable
from EnergyPlus.UtilityRoutines import pow2, pow_2
from EnergyPlus.UtilityRoutines import getEnumValue
from EnergyPlus.UtilityRoutines import SetupOutputVariable
from EnergyPlus.UtilityRoutines import BaseGlobalStruct

from pathlib import Path as fs_path
from typing import Callable, Dict, List, Optional, Tuple
import sys

# Forward declarations
struct _object:

type PyObject = _object

# Constants
programName = "python"

# PluginTrendVariable struct
struct PluginTrendVariable:
    var name: String
    var numValues: Int
    var values: deque[Float64]
    var times: deque[Float64]
    var indexOfPluginVariable: Int

    def __init__(inout self, state: EnergyPlusData, _name: String, _numValues: Int, _indexOfPluginVariable: Int):
        self.name = _name
        self.numValues = _numValues
        self.indexOfPluginVariable = _indexOfPluginVariable
        for i in range(1, self.numValues + 1):
            self.values.append(0.0)
            self.times.append(-i * state.dataGlobal.TimeStepZone)

    def reset(inout self):
        self.values.clear()
        for i in range(1, self.numValues + 1):
            self.values.append(0.0)

# PluginInstance struct
struct PluginInstance:
    var modulePath: fs_path
    var className: String
    var emsAlias: String
    var runDuringWarmup: Bool
    var stringIdentifier: String
    var sHookBeginNewEnvironment: String = "on_begin_new_environment"
    var sHookBeginZoneTimestepBeforeSetCurrentWeather: String = "on_begin_zone_timestep_before_set_current_weather"
    var sHookAfterNewEnvironmentWarmUpIsComplete: String = "on_after_new_environment_warmup_is_complete"
    var sHookBeginZoneTimestepBeforeInitHeatBalance: String = "on_begin_zone_timestep_before_init_heat_balance"
    var sHookBeginZoneTimestepAfterInitHeatBalance: String = "on_begin_zone_timestep_after_init_heat_balance"
    var sHookBeginTimestepBeforePredictor: String = "on_begin_timestep_before_predictor"
    var sHookAfterPredictorBeforeHVACManagers: String = "on_after_predictor_before_hvac_managers"
    var sHookAfterPredictorAfterHVACManagers: String = "on_after_predictor_after_hvac_managers"
    var sHookInsideHVACSystemIterationLoop: String = "on_inside_hvac_system_iteration_loop"
    var sHookEndOfZoneTimestepBeforeZoneReporting: String = "on_end_of_zone_timestep_before_zone_reporting"
    var sHookEndOfZoneTimestepAfterZoneReporting: String = "on_end_of_zone_timestep_after_zone_reporting"
    var sHookEndOfSystemTimestepBeforeHVACReporting: String = "on_end_of_system_timestep_before_hvac_reporting"
    var sHookEndOfSystemTimestepAfterHVACReporting: String = "on_end_of_system_timestep_after_hvac_reporting"
    var sHookEndOfZoneSizing: String = "on_end_of_zone_sizing"
    var sHookEndOfSystemSizing: String = "on_end_of_system_sizing"
    var sHookAfterComponentInputReadIn: String = "on_end_of_component_input_read_in"
    var sHookUserDefinedComponentModel: String = "on_user_defined_component_model"
    var sHookUnitarySystemSizing: String = "on_unitary_system_sizing"
    var bHasBeginNewEnvironment: Bool = False
    var bHasBeginZoneTimestepBeforeSetCurrentWeather: Bool = False
    var bHasAfterNewEnvironmentWarmUpIsComplete: Bool = False
    var bHasBeginZoneTimestepBeforeInitHeatBalance: Bool = False
    var bHasBeginZoneTimestepAfterInitHeatBalance: Bool = False
    var bHasBeginTimestepBeforePredictor: Bool = False
    var bHasAfterPredictorBeforeHVACManagers: Bool = False
    var bHasAfterPredictorAfterHVACManagers: Bool = False
    var bHasInsideHVACSystemIterationLoop: Bool = False
    var bHasEndOfZoneTimestepBeforeZoneReporting: Bool = False
    var bHasEndOfZoneTimestepAfterZoneReporting: Bool = False
    var bHasEndOfSystemTimestepBeforeHVACReporting: Bool = False
    var bHasEndOfSystemTimestepAfterHVACReporting: Bool = False
    var bHasEndOfZoneSizing: Bool = False
    var bHasEndOfSystemSizing: Bool = False
    var bHasAfterComponentInputReadIn: Bool = False
    var bHasUserDefinedComponentModel: Bool = False
    var bHasUnitarySystemSizing: Bool = False
    # Python-related fields omitted (not available in Mojo)
    var pModule: PyObject = None
    var pClassInstance: PyObject = None
    var pBeginNewEnvironment: PyObject = None
    var pBeginZoneTimestepBeforeSetCurrentWeather: PyObject = None
    var pAfterNewEnvironmentWarmUpIsComplete: PyObject = None
    var pBeginZoneTimestepBeforeInitHeatBalance: PyObject = None
    var pBeginZoneTimestepAfterInitHeatBalance: PyObject = None
    var pBeginTimestepBeforePredictor: PyObject = None
    var pAfterPredictorBeforeHVACManagers: PyObject = None
    var pAfterPredictorAfterHVACManagers: PyObject = None
    var pInsideHVACSystemIterationLoop: PyObject = None
    var pEndOfZoneTimestepBeforeZoneReporting: PyObject = None
    var pEndOfZoneTimestepAfterZoneReporting: PyObject = None
    var pEndOfSystemTimestepBeforeHVACReporting: PyObject = None
    var pEndOfSystemTimestepAfterHVACReporting: PyObject = None
    var pEndOfZoneSizing: PyObject = None
    var pEndOfSystemSizing: PyObject = None
    var pAfterComponentInputReadIn: PyObject = None
    var pUserDefinedComponentModel: PyObject = None
    var pUnitarySystemSizing: PyObject = None

    def __init__(inout self, _modulePath: fs_path, _className: String, emsName: String, runPluginDuringWarmup: Bool):
        self.modulePath = _modulePath
        self.className = _className
        self.emsAlias = emsName
        self.runDuringWarmup = runPluginDuringWarmup
        self.stringIdentifier = FileSystem.toString(_modulePath) + "." + _className

    def setup(inout self, state: EnergyPlusData):
        # Python-specific implementation omitted

    def shutdown(self):
        # Python-specific implementation omitted

    @staticmethod
    def reportPythonError(state: EnergyPlusData):
        # Python-specific implementation omitted

    def run(self, state: EnergyPlusData, iCallingPoint: EMSCallFrom) -> Bool:
        # Python-specific implementation omitted
        return False

# PluginManager class
class PluginManager:
    var maxGlobalVariableIndex: Int = -1
    var maxTrendVariableIndex: Int = -1
    var eplusRunningViaPythonAPI: Bool = False

    def __init__(inout self, state: EnergyPlusData):
        self.eplusRunningViaPythonAPI = state.dataPluginManager.eplusRunningViaPythonAPI
        var sPlugins: String = "PythonPlugin:Instance"
        if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, sPlugins) == 0:
            return
        # Python-specific initialization omitted

    def __del__(owned self):
        # Python-specific cleanup omitted

    @staticmethod
    def numActiveCallbacks(state: EnergyPlusData) -> Int:
        return len(state.dataPluginManager.callbacks) + len(state.dataPluginManager.userDefinedCallbacks)

    @staticmethod
    def addToPythonPath(state: EnergyPlusData, includePath: fs_path, userDefinedPath: Bool):
        # Python-specific implementation omitted

    @staticmethod
    def setupOutputVariables(state: EnergyPlusData):
        # Python-specific implementation omitted

    def addGlobalVariable(inout self, state: EnergyPlusData, name: String):
        # Python-specific implementation omitted

    @staticmethod
    def getGlobalVariableHandle(state: EnergyPlusData, name: String, suppress_warning: Bool = False) -> Int:
        # Python-specific implementation omitted
        return -1

    @staticmethod
    def getGlobalVariableValue(state: EnergyPlusData, handle: Int) -> Float64:
        # Python-specific implementation omitted
        return 0.0

    @staticmethod
    def setGlobalVariableValue(state: EnergyPlusData, handle: Int, value: Float64):
        # Python-specific implementation omitted

    @staticmethod
    def getTrendVariableHandle(state: EnergyPlusData, name: String) -> Int:
        # Python-specific implementation omitted
        return -1

    @staticmethod
    def getTrendVariableValue(state: EnergyPlusData, handle: Int, timeIndex: Int) -> Float64:
        # Python-specific implementation omitted
        return 0.0

    @staticmethod
    def getTrendVariableHistorySize(state: EnergyPlusData, handle: Int) -> Int:
        # Python-specific implementation omitted
        return 0

    @staticmethod
    def getTrendVariableAverage(state: EnergyPlusData, handle: Int, count: Int) -> Float64:
        # Python-specific implementation omitted
        return 0.0

    @staticmethod
    def getTrendVariableMin(state: EnergyPlusData, handle: Int, count: Int) -> Float64:
        # Python-specific implementation omitted
        return 0.0

    @staticmethod
    def getTrendVariableMax(state: EnergyPlusData, handle: Int, count: Int) -> Float64:
        # Python-specific implementation omitted
        return 0.0

    @staticmethod
    def getTrendVariableSum(state: EnergyPlusData, handle: Int, count: Int) -> Float64:
        # Python-specific implementation omitted
        return 0.0

    @staticmethod
    def getTrendVariableDirection(state: EnergyPlusData, handle: Int, count: Int) -> Float64:
        # Python-specific implementation omitted
        return 0.0

    @staticmethod
    def updatePluginValues(state: EnergyPlusData):
        # Python-specific implementation omitted

    @staticmethod
    def getLocationOfUserDefinedPlugin(state: EnergyPlusData, _programName: String) -> Int:
        # Python-specific implementation omitted
        return -1

    @staticmethod
    def getUserDefinedCallbackIndex(state: EnergyPlusData, callbackProgramName: String) -> Int:
        for i in range(len(state.dataPluginManager.userDefinedCallbackNames)):
            if state.dataPluginManager.userDefinedCallbackNames[i] == callbackProgramName:
                return i
        return -1

    @staticmethod
    def runSingleUserDefinedPlugin(state: EnergyPlusData, index: Int):
        # Python-specific implementation omitted

    @staticmethod
    def runSingleUserDefinedCallback(state: EnergyPlusData, index: Int):
        if state.dataGlobal.KickOffSimulation:
            return
        state.dataPluginManager.userDefinedCallbacks[index](state)

    @staticmethod
    def anyUnexpectedPluginObjects(state: EnergyPlusData) -> Bool:
        # Python-specific implementation omitted
        return False

    @staticmethod
    def currentPythonPath() -> List[String]:
        # Python-specific implementation omitted
        return List[String]()

# Free functions
def registerNewCallback(state: EnergyPlusData, iCalledFrom: EMSCallFrom, f: Callable[[None], None]):
    state.dataPluginManager.callbacks[iCalledFrom].append(f)

def registerUserDefinedCallback(state: EnergyPlusData, f: Callable[[None], None], programNameInInputFile: String):
    state.dataPluginManager.userDefinedCallbackNames.append(Util.makeUPPER(programNameInInputFile))
    state.dataPluginManager.userDefinedCallbacks.append(f)

def runAnyRegisteredCallbacks(state: EnergyPlusData, iCalledFrom: EMSCallFrom, anyRan: Bool):
    if state.dataGlobal.KickOffSimulation:
        return
    for cb in state.dataPluginManager.callbacks[iCalledFrom]:
        if iCalledFrom == EMSCallFrom.UserDefinedComponentModel:
            continue
        cb(state)
        anyRan = True
    # Python-specific plugin running omitted

def onBeginEnvironment(state: EnergyPlusData):
    for v in state.dataPluginManager.globalVariableValues:
        v = 0.0
    for tr in state.dataPluginManager.trends:
        tr.reset()

def pythonStringForUsage(state: EnergyPlusData) -> String:
    # Python-specific implementation omitted
    return "This version of EnergyPlus not linked to Python library."

def clear_state():
    # Python-specific cleanup omitted

# PluginManagerData struct
struct PluginManagerData(BaseGlobalStruct):
    var callbacks: Dict[EMSCallFrom, List[Callable[[None], None]]]
    var userDefinedCallbackNames: List[String]
    var userDefinedCallbacks: List[Callable[[None], None]]
    var pluginManager: Optional[PluginManager]
    var trends: List[PluginTrendVariable]
    var plugins: List[PluginInstance]
    var globalVariableNames: List[String]
    var globalVariableValues: List[Float64]
    var fullyReady: Bool = False
    var apiErrorFlag: Bool = False
    var objectsToFind: List[String] = List[String](
        "PythonPlugin:OutputVariable", "PythonPlugin:SearchPaths", "PythonPlugin:Instance", "PythonPlugin:Variables", "PythonPlugin:TrendVariable"
    )
    var eplusRunningViaPythonAPI: Bool = False

    def __init__(inout self):
        self.callbacks = Dict[EMSCallFrom, List[Callable[[None], None]]]()
        self.userDefinedCallbackNames = List[String]()
        self.userDefinedCallbacks = List[Callable[[None], None]]()
        self.pluginManager = None
        self.trends = List[PluginTrendVariable]()
        self.plugins = List[PluginInstance]()
        self.globalVariableNames = List[String]()
        self.globalVariableValues = List[Float64]()

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.callbacks.clear()
        self.userDefinedCallbackNames.clear()
        self.userDefinedCallbacks.clear()
        # Python-specific cleanup omitted
        self.trends.clear()
        self.globalVariableNames.clear()
        self.globalVariableValues.clear()
        self.plugins.clear()
        self.fullyReady = False
        self.apiErrorFlag = False
        self.pluginManager = None