# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - from energy_plus.data (state container with dataPluginManager, dataGlobal, dataStrGlobals, dataInputProcessing)
# EMSManager.EMSCallFrom - from energy_plus.ems_manager (enum for callback points)
# OutputProcessor - from energy_plus.output_processor (SetupOutputVariable, enums: StoreType, TimeStepType, Group, EndUseCat)
# Constant - from energy_plus.constants (Units, eResource, unitNamesUC, eResourceNamesUC)
# FileSystem - from energy_plus.file_system (getParentDirectoryPath, getAbsolutePath, getProgramPath, pathExists, toString)
# InputProcessor - from energy_plus.input_processing (getNumObjectsFound, markObjectAsUsed, epJSON)
# Show functions - from energy_plus.utilities (ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningMessage, ShowMessage)
# Util.makeUPPER - from energy_plus.util (string upper conversion)
# get_environment_variable - os.environ or similar
# pow2, pow_2 - math utilities (x**2, x**2)

from typing import Callable, Dict, List, Deque, Set, Optional, Tuple, Any
from collections import deque
from pathlib import Path
import os
import sys
from dataclasses import dataclass, field

PROGRAM_NAME = "python"

def register_new_callback(state: 'EnergyPlusData', i_called_from: 'EMSCallFrom', f: Callable[[Any], None]) -> None:
    state.dataPluginManager.callbacks[i_called_from].append(f)

def register_user_defined_callback(state: 'EnergyPlusData', f: Callable[[Any], None], program_name_in_input_file: str) -> None:
    from energy_plus.util import makeUPPER
    state.dataPluginManager.userDefinedCallbackNames.append(makeUPPER(program_name_in_input_file))
    state.dataPluginManager.userDefinedCallbacks.append(f)

def on_begin_environment(state: 'EnergyPlusData') -> None:
    for v_idx in range(len(state.dataPluginManager.globalVariableValues)):
        state.dataPluginManager.globalVariableValues[v_idx] = 0.0
    for tr in state.dataPluginManager.trends:
        tr.reset()

def python_string_for_usage(state: 'EnergyPlusData') -> str:
    if state.dataGlobal.errorCallback:
        return "Python Version not accessible during API calls"
    try:
        import sys
        s_version = sys.version
        s_version = s_version.replace('\n', '')
        return f'Linked to Python Version: "{s_version}"'
    except:
        return "This version of EnergyPlus not linked to Python library."

def clear_state() -> None:
    pass

class PluginTrendVariable:
    def __init__(self, state: 'EnergyPlusData', name: str, num_values: int, index_of_plugin_variable: int) -> None:
        self.name = name
        self.numValues = num_values
        self.values: Deque[float] = deque()
        self.times: Deque[float] = deque()
        self.indexOfPluginVariable = index_of_plugin_variable
        
        for i in range(1, self.numValues + 1):
            self.values.append(0.0)
            self.times.append(-i * state.dataGlobal.TimeStepZone)
    
    def reset(self) -> None:
        self.values.clear()
        for i in range(1, self.numValues + 1):
            self.values.append(0.0)

class PluginInstance:
    def __init__(self, module_path: Path, class_name: str, ems_name: str, run_plugin_during_warmup: bool) -> None:
        self.modulePath = module_path
        self.className = class_name
        self.emsAlias = ems_name
        self.runDuringWarmup = run_plugin_during_warmup
        self.stringIdentifier = f"{FileSystem.toString(module_path)}.{class_name}"
        
        self.sHookBeginNewEnvironment = "on_begin_new_environment"
        self.sHookBeginZoneTimestepBeforeSetCurrentWeather = "on_begin_zone_timestep_before_set_current_weather"
        self.sHookAfterNewEnvironmentWarmUpIsComplete = "on_after_new_environment_warmup_is_complete"
        self.sHookBeginZoneTimestepBeforeInitHeatBalance = "on_begin_zone_timestep_before_init_heat_balance"
        self.sHookBeginZoneTimestepAfterInitHeatBalance = "on_begin_zone_timestep_after_init_heat_balance"
        self.sHookBeginTimestepBeforePredictor = "on_begin_timestep_before_predictor"
        self.sHookAfterPredictorBeforeHVACManagers = "on_after_predictor_before_hvac_managers"
        self.sHookAfterPredictorAfterHVACManagers = "on_after_predictor_after_hvac_managers"
        self.sHookInsideHVACSystemIterationLoop = "on_inside_hvac_system_iteration_loop"
        self.sHookEndOfZoneTimestepBeforeZoneReporting = "on_end_of_zone_timestep_before_zone_reporting"
        self.sHookEndOfZoneTimestepAfterZoneReporting = "on_end_of_zone_timestep_after_zone_reporting"
        self.sHookEndOfSystemTimestepBeforeHVACReporting = "on_end_of_system_timestep_before_hvac_reporting"
        self.sHookEndOfSystemTimestepAfterHVACReporting = "on_end_of_system_timestep_after_hvac_reporting"
        self.sHookEndOfZoneSizing = "on_end_of_zone_sizing"
        self.sHookEndOfSystemSizing = "on_end_of_system_sizing"
        self.sHookAfterComponentInputReadIn = "on_end_of_component_input_read_in"
        self.sHookUserDefinedComponentModel = "on_user_defined_component_model"
        self.sHookUnitarySystemSizing = "on_unitary_system_sizing"
        
        self.bHasBeginNewEnvironment = False
        self.bHasBeginZoneTimestepBeforeSetCurrentWeather = False
        self.bHasAfterNewEnvironmentWarmUpIsComplete = False
        self.bHasBeginZoneTimestepBeforeInitHeatBalance = False
        self.bHasBeginZoneTimestepAfterInitHeatBalance = False
        self.bHasBeginTimestepBeforePredictor = False
        self.bHasAfterPredictorBeforeHVACManagers = False
        self.bHasAfterPredictorAfterHVACManagers = False
        self.bHasInsideHVACSystemIterationLoop = False
        self.bHasEndOfZoneTimestepBeforeZoneReporting = False
        self.bHasEndOfZoneTimestepAfterZoneReporting = False
        self.bHasEndOfSystemTimestepBeforeHVACReporting = False
        self.bHasEndOfSystemTimestepAfterHVACReporting = False
        self.bHasEndOfZoneSizing = False
        self.bHasEndOfSystemSizing = False
        self.bHasAfterComponentInputReadIn = False
        self.bHasUserDefinedComponentModel = False
        self.bHasUnitarySystemSizing = False
        
        self.pModule: Optional[Any] = None
        self.pClassInstance: Optional[Any] = None
        self.pBeginNewEnvironment: Optional[str] = None
        self.pBeginZoneTimestepBeforeSetCurrentWeather: Optional[str] = None
        self.pAfterNewEnvironmentWarmUpIsComplete: Optional[str] = None
        self.pBeginZoneTimestepBeforeInitHeatBalance: Optional[str] = None
        self.pBeginZoneTimestepAfterInitHeatBalance: Optional[str] = None
        self.pBeginTimestepBeforePredictor: Optional[str] = None
        self.pAfterPredictorBeforeHVACManagers: Optional[str] = None
        self.pAfterPredictorAfterHVACManagers: Optional[str] = None
        self.pInsideHVACSystemIterationLoop: Optional[str] = None
        self.pEndOfZoneTimestepBeforeZoneReporting: Optional[str] = None
        self.pEndOfZoneTimestepAfterZoneReporting: Optional[str] = None
        self.pEndOfSystemTimestepBeforeHVACReporting: Optional[str] = None
        self.pEndOfSystemTimestepAfterHVACReporting: Optional[str] = None
        self.pEndOfZoneSizing: Optional[str] = None
        self.pEndOfSystemSizing: Optional[str] = None
        self.pAfterComponentInputReadIn: Optional[str] = None
        self.pUserDefinedComponentModel: Optional[str] = None
        self.pUnitarySystemSizing: Optional[str] = None
    
    @staticmethod
    def report_python_error(state: 'EnergyPlusData') -> None:
        from energy_plus.utilities import ShowContinueError
        try:
            import traceback
            ShowContinueError(state, "Python error description follows: ")
            exc_info = sys.exc_info()
            if exc_info[0] is not None:
                ShowContinueError(state, str(exc_info[1]))
                ShowContinueError(state, "Python traceback follows: ")
                ShowContinueError(state, "```")
                for line in traceback.format_exception(*exc_info):
                    for sub_line in line.rstrip('\n').split('\n'):
                        ShowContinueError(state, f" >>> {sub_line}")
                ShowContinueError(state, "```")
        except:
            pass
    
    def setup(self, state: 'EnergyPlusData') -> None:
        from energy_plus.utilities import ShowFatalError, ShowSevereError, ShowContinueError, ShowMessage
        from energy_plus.file_system import FileSystem
        
        try:
            import importlib.util
            spec = importlib.util.spec_from_file_location(self.modulePath.stem, str(self.modulePath))
            if spec and spec.loader:
                self.pModule = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(self.pModule)
            else:
                ShowSevereError(state, f'Failed to import module "{self.modulePath}"')
                ShowContinueError(state, f"Current sys.path={PluginManager.current_python_path()}")
                ShowFatalError(state, "Python import error causes program termination")
                return
            
            if not hasattr(self.pModule, self.className):
                ShowSevereError(state, f'Failed to get class type "{self.className}" from module "{self.modulePath}"')
                ShowContinueError(state, "It could be the class name is misspelled or missing.")
                ShowFatalError(state, "Python class import error causes program termination")
                return
            
            pClass = getattr(self.pModule, self.className)
            if not callable(pClass):
                ShowSevereError(state, f'Got class type "{self.className}", but it cannot be called/instantiated')
                ShowContinueError(state, "Is it possible the class name is actually just a variable?")
                ShowFatalError(state, "Python class check error causes program termination")
                return
            
            self.pClassInstance = pClass()
            
            if self.pModule and hasattr(self.pModule, '__file__'):
                ShowMessage(state, f"PythonPlugin: Class {self.className} imported from: {self.pModule.__file__}")
            
            if hasattr(self.pClassInstance, '_detect_overridden'):
                detect_func = getattr(self.pClassInstance, '_detect_overridden')
                function_response = detect_func()
            else:
                ShowSevereError(state, f'Could not find or call function "_detect_overridden" on class "{self.modulePath}.{self.className}"')
                ShowContinueError(state, "This function should be available on the base class, so this is strange.")
                ShowFatalError(state, "Python _detect_overridden() function error causes program termination")
                return
            
            if not isinstance(function_response, list):
                ShowFatalError(state, f'Invalid return from _detect_overridden() on class "{self.stringIdentifier}", this is weird')
                return
            
            if len(function_response) == 0:
                ShowFatalError(state, f'Python plugin "{self.stringIdentifier}" did not override any base class methods; must override at least one')
                return
            
            for function_name in function_response:
                if function_name == self.sHookBeginNewEnvironment:
                    self.bHasBeginNewEnvironment = True
                    self.pBeginNewEnvironment = function_name
                elif function_name == self.sHookBeginZoneTimestepBeforeSetCurrentWeather:
                    self.bHasBeginZoneTimestepBeforeSetCurrentWeather = True
                    self.pBeginZoneTimestepBeforeSetCurrentWeather = function_name
                elif function_name == self.sHookAfterNewEnvironmentWarmUpIsComplete:
                    self.bHasAfterNewEnvironmentWarmUpIsComplete = True
                    self.pAfterNewEnvironmentWarmUpIsComplete = function_name
                elif function_name == self.sHookBeginZoneTimestepBeforeInitHeatBalance:
                    self.bHasBeginZoneTimestepBeforeInitHeatBalance = True
                    self.pBeginZoneTimestepBeforeInitHeatBalance = function_name
                elif function_name == self.sHookBeginZoneTimestepAfterInitHeatBalance:
                    self.bHasBeginZoneTimestepAfterInitHeatBalance = True
                    self.pBeginZoneTimestepAfterInitHeatBalance = function_name
                elif function_name == self.sHookBeginTimestepBeforePredictor:
                    self.bHasBeginTimestepBeforePredictor = True
                    self.pBeginTimestepBeforePredictor = function_name
                elif function_name == self.sHookAfterPredictorBeforeHVACManagers:
                    self.bHasAfterPredictorBeforeHVACManagers = True
                    self.pAfterPredictorBeforeHVACManagers = function_name
                elif function_name == self.sHookAfterPredictorAfterHVACManagers:
                    self.bHasAfterPredictorAfterHVACManagers = True
                    self.pAfterPredictorAfterHVACManagers = function_name
                elif function_name == self.sHookInsideHVACSystemIterationLoop:
                    self.bHasInsideHVACSystemIterationLoop = True
                    self.pInsideHVACSystemIterationLoop = function_name
                elif function_name == self.sHookEndOfZoneTimestepBeforeZoneReporting:
                    self.bHasEndOfZoneTimestepBeforeZoneReporting = True
                    self.pEndOfZoneTimestepBeforeZoneReporting = function_name
                elif function_name == self.sHookEndOfZoneTimestepAfterZoneReporting:
                    self.bHasEndOfZoneTimestepAfterZoneReporting = True
                    self.pEndOfZoneTimestepAfterZoneReporting = function_name
                elif function_name == self.sHookEndOfSystemTimestepBeforeHVACReporting:
                    self.bHasEndOfSystemTimestepBeforeHVACReporting = True
                    self.pEndOfSystemTimestepBeforeHVACReporting = function_name
                elif function_name == self.sHookEndOfSystemTimestepAfterHVACReporting:
                    self.bHasEndOfSystemTimestepAfterHVACReporting = True
                    self.pEndOfSystemTimestepAfterHVACReporting = function_name
                elif function_name == self.sHookEndOfZoneSizing:
                    self.bHasEndOfZoneSizing = True
                    self.pEndOfZoneSizing = function_name
                elif function_name == self.sHookEndOfSystemSizing:
                    self.bHasEndOfSystemSizing = True
                    self.pEndOfSystemSizing = function_name
                elif function_name == self.sHookAfterComponentInputReadIn:
                    self.bHasAfterComponentInputReadIn = True
                    self.pAfterComponentInputReadIn = function_name
                elif function_name == self.sHookUserDefinedComponentModel:
                    self.bHasUserDefinedComponentModel = True
                    self.pUserDefinedComponentModel = function_name
                elif function_name == self.sHookUnitarySystemSizing:
                    self.bHasUnitarySystemSizing = True
                    self.pUnitarySystemSizing = function_name
        except Exception as e:
            ShowSevereError(state, f'Failed to import module "{self.modulePath}"')
            ShowContinueError(state, f"Current sys.path={PluginManager.current_python_path()}")
            self.report_python_error(state)
            ShowFatalError(state, "Python import error causes program termination")
    
    def shutdown(self) -> None:
        pass
    
    def run(self, state: 'EnergyPlusData', i_called_from: 'EMSCallFrom') -> bool:
        from energy_plus.utilities import ShowSevereError, ShowContinueError, ShowFatalError
        
        p_function_name: Optional[str] = None
        function_name: Optional[str] = None
        
        if i_called_from.name == 'BeginNewEnvironment':
            if self.bHasBeginNewEnvironment:
                p_function_name = self.pBeginNewEnvironment
                function_name = self.sHookBeginNewEnvironment
        elif i_called_from.name == 'BeginZoneTimestepBeforeSetCurrentWeather':
            if self.bHasBeginZoneTimestepBeforeSetCurrentWeather:
                p_function_name = self.pBeginZoneTimestepBeforeSetCurrentWeather
                function_name = self.sHookBeginZoneTimestepBeforeSetCurrentWeather
        elif i_called_from.name == 'ZoneSizing':
            if self.bHasEndOfZoneSizing:
                p_function_name = self.pEndOfZoneSizing
                function_name = self.sHookEndOfZoneSizing
        elif i_called_from.name == 'SystemSizing':
            if self.bHasEndOfSystemSizing:
                p_function_name = self.pEndOfSystemSizing
                function_name = self.sHookEndOfSystemSizing
        elif i_called_from.name == 'BeginNewEnvironmentAfterWarmUp':
            if self.bHasAfterNewEnvironmentWarmUpIsComplete:
                p_function_name = self.pAfterNewEnvironmentWarmUpIsComplete
                function_name = self.sHookAfterNewEnvironmentWarmUpIsComplete
        elif i_called_from.name == 'BeginTimestepBeforePredictor':
            if self.bHasBeginTimestepBeforePredictor:
                p_function_name = self.pBeginTimestepBeforePredictor
                function_name = self.sHookBeginTimestepBeforePredictor
        elif i_called_from.name == 'BeforeHVACManagers':
            if self.bHasAfterPredictorBeforeHVACManagers:
                p_function_name = self.pAfterPredictorBeforeHVACManagers
                function_name = self.sHookAfterPredictorBeforeHVACManagers
        elif i_called_from.name == 'AfterHVACManagers':
            if self.bHasAfterPredictorAfterHVACManagers:
                p_function_name = self.pAfterPredictorAfterHVACManagers
                function_name = self.sHookAfterPredictorAfterHVACManagers
        elif i_called_from.name == 'HVACIterationLoop':
            if self.bHasInsideHVACSystemIterationLoop:
                p_function_name = self.pInsideHVACSystemIterationLoop
                function_name = self.sHookInsideHVACSystemIterationLoop
        elif i_called_from.name == 'EndSystemTimestepBeforeHVACReporting':
            if self.bHasEndOfSystemTimestepBeforeHVACReporting:
                p_function_name = self.pEndOfSystemTimestepBeforeHVACReporting
                function_name = self.sHookEndOfSystemTimestepBeforeHVACReporting
        elif i_called_from.name == 'EndSystemTimestepAfterHVACReporting':
            if self.bHasEndOfSystemTimestepAfterHVACReporting:
                p_function_name = self.pEndOfSystemTimestepAfterHVACReporting
                function_name = self.sHookEndOfSystemTimestepAfterHVACReporting
        elif i_called_from.name == 'EndZoneTimestepBeforeZoneReporting':
            if self.bHasEndOfZoneTimestepBeforeZoneReporting:
                p_function_name = self.pEndOfZoneTimestepBeforeZoneReporting
                function_name = self.sHookEndOfZoneTimestepBeforeZoneReporting
        elif i_called_from.name == 'EndZoneTimestepAfterZoneReporting':
            if self.bHasEndOfZoneTimestepAfterZoneReporting:
                p_function_name = self.pEndOfZoneTimestepAfterZoneReporting
                function_name = self.sHookEndOfZoneTimestepAfterZoneReporting
        elif i_called_from.name == 'ComponentGetInput':
            if self.bHasAfterComponentInputReadIn:
                p_function_name = self.pAfterComponentInputReadIn
                function_name = self.sHookAfterComponentInputReadIn
        elif i_called_from.name == 'UserDefinedComponentModel':
            if self.bHasUserDefinedComponentModel:
                p_function_name = self.pUserDefinedComponentModel
                function_name = self.sHookUserDefinedComponentModel
        elif i_called_from.name == 'UnitarySystemSizing':
            if self.bHasUnitarySystemSizing:
                p_function_name = self.pUnitarySystemSizing
                function_name = self.sHookUnitarySystemSizing
        elif i_called_from.name == 'BeginZoneTimestepBeforeInitHeatBalance':
            if self.bHasBeginZoneTimestepBeforeInitHeatBalance:
                p_function_name = self.pBeginZoneTimestepBeforeInitHeatBalance
                function_name = self.sHookBeginZoneTimestepBeforeInitHeatBalance
        elif i_called_from.name == 'BeginZoneTimestepAfterInitHeatBalance':
            if self.bHasBeginZoneTimestepAfterInitHeatBalance:
                p_function_name = self.pBeginZoneTimestepAfterInitHeatBalance
                function_name = self.sHookBeginZoneTimestepAfterInitHeatBalance
        
        if p_function_name is None:
            return False
        
        try:
            if self.pClassInstance and hasattr(self.pClassInstance, p_function_name):
                func = getattr(self.pClassInstance, p_function_name)
                exit_code = func(state)
                if isinstance(exit_code, int):
                    if exit_code == 0:
                        pass
                    elif exit_code == 1:
                        ShowFatalError(state, f'Python Plugin "{self.stringIdentifier}" returned 1 to indicate EnergyPlus should abort')
                else:
                    ShowFatalError(state, f'Invalid return from {function_name}() on class "{self.stringIdentifier}", make sure it returns an integer exit code, either zero (success) or one (failure)')
            else:
                ShowSevereError(state, f'Call to {function_name}() on {self.stringIdentifier} failed!')
                ShowContinueError(state, "This could happen for any number of reasons, check the plugin code.")
                ShowFatalError(state, f'Program terminates after call to {function_name}() on {self.stringIdentifier} failed!')
                return False
        except Exception as e:
            ShowSevereError(state, f'Call to {function_name}() on {self.stringIdentifier} failed!')
            self.report_python_error(state)
            ShowFatalError(state, f'Program terminates after call to {function_name}() on {self.stringIdentifier} failed!')
            return False
        
        if state.dataPluginManager.apiErrorFlag:
            ShowFatalError(state, "API problems encountered while running plugin cause program termination.")
        
        return True

class PluginManager:
    def __init__(self, state: 'EnergyPlusData') -> None:
        from energy_plus.utilities import ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningMessage, ShowMessage
        from energy_plus.util import makeUPPER
        from energy_plus.file_system import FileSystem
        from energy_plus.output_processor import SetupOutputVariable
        
        self.eplusRunningViaPythonAPI = state.dataPluginManager.eplusRunningViaPythonAPI
        self.maxGlobalVariableIndex = -1
        self.maxTrendVariableIndex = -1
        
        s_plugins = "PythonPlugin:Instance"
        if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_plugins) == 0:
            return
        
        program_dir: Path = Path(state.dataStrGlobals.exeDirectoryPath if state.dataGlobal.installRootOverride else FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(FileSystem.getProgramPath())))
        
        sys.path.insert(0, str(program_dir / "python_lib" / "lib-dynload"))
        sys.path.insert(0, str(program_dir))
        
        s_paths = "PythonPlugin:SearchPaths"
        search_paths = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_paths)
        if search_paths > 0:
            instances = state.dataInputProcessing.inputProcessor.epJSON.get(s_paths)
            if instances:
                for instance_key, instance_value in instances.items():
                    state.dataInputProcessing.inputProcessor.markObjectAsUsed(s_paths, instance_key)
                    fields = instance_value
                    
                    working_dir_flag_uc = fields.get("add_current_working_directory_to_search_path", "YES").upper()
                    if working_dir_flag_uc == "YES":
                        if "." not in sys.path:
                            sys.path.insert(0, ".")
                    
                    input_file_dir_flag_uc = fields.get("add_input_file_directory_to_search_path", "YES").upper()
                    if input_file_dir_flag_uc == "YES":
                        if str(state.dataStrGlobals.inputDirPath) not in sys.path:
                            sys.path.insert(0, str(state.dataStrGlobals.inputDirPath))
                    
                    ep_in_dir_flag_uc = fields.get("add_epin_environment_variable_to_search_path", "YES").upper()
                    if ep_in_dir_flag_uc == "YES":
                        epin_path = os.environ.get("epin", "")
                        if epin_path:
                            epin_root_dir = Path(epin_path).parent
                            if epin_root_dir.exists():
                                if str(epin_root_dir) not in sys.path:
                                    sys.path.insert(0, str(epin_root_dir))
                            else:
                                ShowWarningMessage(state, "PluginManager: Search path inputs requested adding epin variable to Python path, but epin variable value is not a valid existent path, skipping.")
                        else:
                            ShowWarningMessage(state, "PluginManager: Search path inputs requested adding epin variable to Python path, but epin variable was empty, skipping.")
                    
                    if "py_search_paths" in fields:
                        for var in fields["py_search_paths"]:
                            if "search_path" in var:
                                search_path_str = var["search_path"]
                                if search_path_str and str(search_path_str) not in sys.path:
                                    sys.path.insert(0, str(search_path_str))
        else:
            if "." not in sys.path:
                sys.path.insert(0, ".")
            if str(state.dataStrGlobals.inputDirPath) not in sys.path:
                sys.path.insert(0, str(state.dataStrGlobals.inputDirPath))
            epin_path = os.environ.get("epin", "")
            if epin_path:
                epin_root_dir = Path(epin_path).parent
                if epin_root_dir.exists():
                    if str(epin_root_dir) not in sys.path:
                        sys.path.insert(0, str(epin_root_dir))
        
        instances = state.dataInputProcessing.inputProcessor.epJSON.get(s_plugins)
        if instances:
            for instance_key, instance_value in instances.items():
                fields = instance_value
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(s_plugins, instance_key)
                module_path = Path(fields["python_module_name"])
                class_name = fields["plugin_class_name"]
                s_warmup = makeUPPER(fields["run_during_warmup_days"])
                warmup = (s_warmup == "YES")
                state.dataPluginManager.plugins.append(PluginInstance(module_path, class_name, instance_key, warmup))
        
        for plugin in state.dataPluginManager.plugins:
            plugin.setup(state)
        
        s_globals = "PythonPlugin:Variables"
        global_var_instances = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_globals)
        if global_var_instances > 0:
            instances = state.dataInputProcessing.inputProcessor.epJSON.get(s_globals)
            if instances:
                unique_names: Set[str] = set()
                for instance_key, instance_value in instances.items():
                    fields = instance_value
                    state.dataInputProcessing.inputProcessor.markObjectAsUsed(s_globals, instance_key)
                    vars_list = fields.get("global_py_vars", [])
                    for var in vars_list:
                        var_name_to_add = var["variable_name"]
                        if var_name_to_add not in unique_names:
                            self.add_global_variable(state, var_name_to_add)
                            unique_names.add(var_name_to_add)
                        else:
                            ShowWarningMessage(state, f'Found duplicate variable name in PythonPLugin:Variables objects, ignoring: "{var_name_to_add}"')
        
        s_trends = "PythonPlugin:TrendVariable"
        trend_instances = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_trends)
        if trend_instances > 0:
            instances = state.dataInputProcessing.inputProcessor.epJSON.get(s_trends)
            if instances:
                for instance_key, instance_value in instances.items():
                    fields = instance_value
                    this_object_name = makeUPPER(instance_key)
                    state.dataInputProcessing.inputProcessor.markObjectAsUsed(s_globals, this_object_name)
                    variable_name = fields["name_of_a_python_plugin_variable"]
                    variable_index = PluginManager.get_global_variable_handle(state, variable_name)
                    num_values = fields["number_of_timesteps_to_be_logged"]
                    state.dataPluginManager.trends.append(PluginTrendVariable(state, this_object_name, num_values, variable_index))
                    self.maxTrendVariableIndex += 1
    
    def __del__(self) -> None:
        pass
    
    @staticmethod
    def num_active_callbacks(state: 'EnergyPlusData') -> int:
        return len(state.dataPluginManager.callbacks) + len(state.dataPluginManager.userDefinedCallbacks)
    
    @staticmethod
    def current_python_path() -> List[str]:
        return sys.path.copy()
    
    @staticmethod
    def add_to_python_path(state: 'EnergyPlusData', include_path: Path, user_defined_path: bool) -> None:
        from energy_plus.utilities import ShowFatalError, ShowMessage
        
        if not include_path or str(include_path) == "":
            return
        
        path_str = str(include_path)
        if path_str not in sys.path:
            sys.path.insert(0, path_str)
        
        if user_defined_path:
            ShowMessage(state, f'Successfully added path "{include_path}" to the sys.path in Python')
    
    @staticmethod
    def setup_output_variables(state: 'EnergyPlusData') -> None:
        from energy_plus.utilities import ShowSevereError, ShowContinueError, ShowFatalError, ShowWarningError
        from energy_plus.output_processor import SetupOutputVariable, StoreType, TimeStepType, Group, EndUseCat
        from energy_plus.constants import Units
        from energy_plus.util import makeUPPER
        import energy_plus.constants as Constant
        
        s_output_variable = "PythonPlugin:OutputVariable"
        output_var_instances = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_output_variable)
        if output_var_instances <= 0:
            return
        
        instances = state.dataInputProcessing.inputProcessor.epJSON.get(s_output_variable)
        if not instances:
            ShowSevereError(state, f"{s_output_variable}: Somehow getNumObjectsFound was > 0 but epJSON.find found 0")
            return
        
        for instance_key, instance_value in instances.items():
            fields = instance_value
            this_object_name = instance_key
            state.dataInputProcessing.inputProcessor.markObjectAsUsed(s_output_variable, this_object_name)
            var_name = fields["python_plugin_variable_name"]
            avg_or_sum = makeUPPER(fields["type_of_data_in_variable"])
            update_freq = makeUPPER(fields["update_frequency"])
            units = fields.get("units", "")
            
            variable_handle = PluginManager.get_global_variable_handle(state, var_name)
            if variable_handle == -1:
                ShowSevereError(state, "Failed to match Python Plugin Output Variable")
                ShowContinueError(state, f'Trying to create output instance for variable name "{var_name}"')
                ShowContinueError(state, "No match found, make sure variable is listed in PythonPlugin:Variables object")
                ShowFatalError(state, "Python Plugin Output Variable problem causes program termination")
                return
            
            is_metered = False
            s_avg_or_sum = StoreType.Average
            if avg_or_sum == "SUMMED":
                s_avg_or_sum = StoreType.Sum
            elif avg_or_sum == "METERED":
                s_avg_or_sum = StoreType.Sum
                is_metered = True
            
            s_update_freq = TimeStepType.Zone
            if update_freq == "SYSTEMTIMESTEP":
                s_update_freq = TimeStepType.System
            
            this_unit = Units.None_
            if units:
                try:
                    units_upper = makeUPPER(units)
                    this_unit = Constant.get_unit_from_name(units_upper)
                    if this_unit == Units.Invalid:
                        this_unit = Units.customEMS
                except:
                    this_unit = Units.customEMS
            
            if not is_metered:
                if this_unit != Units.customEMS:
                    SetupOutputVariable(state, s_output_variable, this_unit, state.dataPluginManager.globalVariableValues[variable_handle], s_update_freq, s_avg_or_sum, this_object_name)
                else:
                    SetupOutputVariable(state, s_output_variable, this_unit, state.dataPluginManager.globalVariableValues[variable_handle], s_update_freq, s_avg_or_sum, this_object_name, Constant.eResource.Invalid, Group.Invalid, EndUseCat.Invalid, "", "", 1, 1, "", -999, units)
            else:
                if "resource_type" not in fields:
                    ShowSevereError(state, f"Input error on PythonPlugin:OutputVariable = {this_object_name}")
                    ShowContinueError(state, "The variable was marked as metered, but did not define a resource type")
                    ShowContinueError(state, "For metered variables, the resource type, group type, and end use category must be defined")
                    ShowFatalError(state, "Input error on PythonPlugin:OutputVariable causes program termination")
                    return
                
                resource_type_str = makeUPPER(fields["resource_type"])
                resource = Constant.get_resource_from_name(resource_type_str)
                
                if "group_type" not in fields:
                    ShowSevereError(state, f"Input error on PythonPlugin:OutputVariable = {this_object_name}")
                    ShowContinueError(state, "The variable was marked as metered, but did not define a group type")
                    ShowContinueError(state, "For metered variables, the resource type, group type, and end use category must be defined")
                    ShowFatalError(state, "Input error on PythonPlugin:OutputVariable causes program termination")
                    return
                
                group_type_str = makeUPPER(fields["group_type"])
                group = Constant.get_group_from_name(group_type_str)
                
                if "end_use_category" not in fields:
                    ShowSevereError(state, f"Input error on PythonPlugin:OutputVariable = {this_object_name}")
                    ShowContinueError(state, "The variable was marked as metered, but did not define an end-use category")
                    ShowContinueError(state, "For metered variables, the resource type, group type, and end use category must be defined")
                    ShowFatalError(state, "Input error on PythonPlugin:OutputVariable causes program termination")
                    return
                
                end_use_str = makeUPPER(fields["end_use_category"])
                end_use_cat = Constant.get_end_use_cat_from_name(end_use_str)
                
                s_end_use_subcategory = ""
                if "end_use_subcategory" in fields:
                    s_end_use_subcategory = fields["end_use_subcategory"]
                
                if not s_end_use_subcategory:
                    SetupOutputVariable(state, s_output_variable, this_unit, state.dataPluginManager.globalVariableValues[variable_handle], s_update_freq, s_avg_or_sum, this_object_name, resource, group, end_use_cat)
                else:
                    SetupOutputVariable(state, s_output_variable, this_unit, state.dataPluginManager.globalVariableValues[variable_handle], s_update_freq, s_avg_or_sum, this_object_name, resource, group, end_use_cat, s_end_use_subcategory)
    
    def add_global_variable(self, state: 'EnergyPlusData', name: str) -> None:
        from energy_plus.util import makeUPPER
        
        var_name_uc = makeUPPER(name)
        state.dataPluginManager.globalVariableNames.append(var_name_uc)
        state.dataPluginManager.globalVariableValues.append(0.0)
        self.maxGlobalVariableIndex += 1
    
    @staticmethod
    def get_global_variable_handle(state: 'EnergyPlusData', name: str, suppress_warning: bool = False) -> int:
        from energy_plus.util import makeUPPER
        from energy_plus.utilities import ShowSevereError, ShowContinueError, ShowFatalError
        
        var_name_uc = makeUPPER(name)
        g_var_names = state.dataPluginManager.globalVariableNames
        try:
            return g_var_names.index(var_name_uc)
        except ValueError:
            if suppress_warning:
                return -1
            ShowSevereError(state, "Tried to retrieve handle for a nonexistent plugin global variable")
            ShowContinueError(state, f'Name looked up: "{var_name_uc}", available names: ')
            for gv_name in g_var_names:
                ShowContinueError(state, f'    "{gv_name}"')
            ShowFatalError(state, "Plugin global variable problem causes program termination")
            return -1
    
    @staticmethod
    def get_trend_variable_handle(state: 'EnergyPlusData', name: str) -> int:
        from energy_plus.util import makeUPPER
        
        var_name_uc = makeUPPER(name)
        for i, trend in enumerate(state.dataPluginManager.trends):
            if trend.name == var_name_uc:
                return i
        return -1
    
    @staticmethod
    def get_trend_variable_value(state: 'EnergyPlusData', handle: int, time_index: int) -> float:
        return state.dataPluginManager.trends[handle].values[time_index]
    
    @staticmethod
    def get_trend_variable_history_size(state: 'EnergyPlusData', handle: int) -> int:
        return len(state.dataPluginManager.trends[handle].values)
    
    @staticmethod
    def get_trend_variable_average(state: 'EnergyPlusData', handle: int, count: int) -> float:
        total = sum(state.dataPluginManager.trends[handle].values[i] for i in range(count))
        return total / count
    
    @staticmethod
    def get_trend_variable_min(state: 'EnergyPlusData', handle: int, count: int) -> float:
        minimum_value = 9999999999999.0
        for i in range(count):
            if state.dataPluginManager.trends[handle].values[i] < minimum_value:
                minimum_value = state.dataPluginManager.trends[handle].values[i]
        return minimum_value
    
    @staticmethod
    def get_trend_variable_max(state: 'EnergyPlusData', handle: int, count: int) -> float:
        maximum_value = -9999999999999.0
        for i in range(count):
            if state.dataPluginManager.trends[handle].values[i] > maximum_value:
                maximum_value = state.dataPluginManager.trends[handle].values[i]
        return maximum_value
    
    @staticmethod
    def get_trend_variable_sum(state: 'EnergyPlusData', handle: int, count: int) -> float:
        return sum(state.dataPluginManager.trends[handle].values[i] for i in range(count))
    
    @staticmethod
    def get_trend_variable_direction(state: 'EnergyPlusData', handle: int, count: int) -> float:
        trend = state.dataPluginManager.trends[handle]
        time_sum = sum(trend.times[i] for i in range(count))
        value_sum = sum(trend.values[i] for i in range(count))
        cross_sum = sum(trend.times[i] * trend.values[i] for i in range(count))
        pow_sum = sum(trend.times[i] ** 2 for i in range(count))
        numerator = time_sum * value_sum - count * cross_sum
        denominator = time_sum ** 2 - count * pow_sum
        return numerator / denominator if denominator != 0 else 0.0
    
    @staticmethod
    def update_plugin_values(state: 'EnergyPlusData') -> None:
        for trend in state.dataPluginManager.trends:
            new_var_value = PluginManager.get_global_variable_value(state, trend.indexOfPluginVariable)
            trend.values.appendleft(new_var_value)
            trend.values.pop()
    
    @staticmethod
    def get_global_variable_value(state: 'EnergyPlusData', handle: int) -> float:
        from energy_plus.utilities import ShowFatalError, ShowSevereError, ShowContinueError
        
        if not state.dataPluginManager.globalVariableValues:
            ShowFatalError(state, "Tried to access plugin global variable but it looks like there aren't any; use the PythonPlugin:Variables object to declare them.")
        try:
            return state.dataPluginManager.globalVariableValues[handle]
        except IndexError:
            ShowSevereError(state, f"Tried to access plugin global variable value at index {handle}")
            ShowContinueError(state, f"Available handles range from 0 to {len(state.dataPluginManager.globalVariableValues) - 1}")
            ShowFatalError(state, "Plugin global variable problem causes program termination")
            return 0.0
    
    @staticmethod
    def set_global_variable_value(state: 'EnergyPlusData', handle: int, value: float) -> None:
        from energy_plus.utilities import ShowFatalError, ShowSevereError, ShowContinueError
        
        if not state.dataPluginManager.globalVariableValues:
            ShowFatalError(state, "Tried to set plugin global variable but it looks like there aren't any; use the PythonPlugin:GlobalVariables object to declare them.")
        try:
            state.dataPluginManager.globalVariableValues[handle] = value
        except IndexError:
            ShowSevereError(state, f"Tried to set plugin global variable value at index {handle}")
            ShowContinueError(state, f"Available handles range from 0 to {len(state.dataPluginManager.globalVariableValues) - 1}")
            ShowFatalError(state, "Plugin global variable problem causes program termination")
    
    @staticmethod
    def get_location_of_user_defined_plugin(state: 'EnergyPlusData', program_name: str) -> int:
        from energy_plus.util import makeUPPER
        
        for handle, plugin in enumerate(state.dataPluginManager.plugins):
            if makeUPPER(plugin.emsAlias) == makeUPPER(program_name):
                return handle
        return -1
    
    @staticmethod
    def run_single_user_defined_plugin(state: 'EnergyPlusData', index: int) -> None:
        from energy_plus.ems_manager import EMSCallFrom
        
        state.dataPluginManager.plugins[index].run(state, EMSCallFrom.UserDefinedComponentModel)
    
    @staticmethod
    def get_user_defined_callback_index(state: 'EnergyPlusData', callback_program_name: str) -> int:
        for i, name in enumerate(state.dataPluginManager.userDefinedCallbackNames):
            if name == callback_program_name:
                return i
        return -1
    
    @staticmethod
    def run_single_user_defined_callback(state: 'EnergyPlusData', index: int) -> None:
        if state.dataGlobal.KickOffSimulation:
            return
        state.dataPluginManager.userDefinedCallbacks[index](state)
    
    @staticmethod
    def any_unexpected_plugin_objects(state: 'EnergyPlusData') -> bool:
        from energy_plus.utilities import ShowSevereMessage, ShowContinueError
        
        num_total_things = 0
        for obj_to_find in state.dataPluginManager.objectsToFind:
            instances = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, obj_to_find)
            num_total_things += instances
            if num_total_things == 1:
                ShowSevereMessage(state, "Found PythonPlugin objects in an IDF that is running in an API/Library workflow...this is invalid")
            if instances > 0:
                ShowContinueError(state, f"Invalid PythonPlugin object type: {obj_to_find}")
        return num_total_things > 0

def run_any_registered_callbacks(state: 'EnergyPlusData', i_called_from: 'EMSCallFrom', any_ran: List[bool]) -> None:
    from energy_plus.ems_manager import EMSCallFrom
    
    if state.dataGlobal.KickOffSimulation:
        return
    
    for cb in state.dataPluginManager.callbacks.get(i_called_from, []):
        if i_called_from == EMSCallFrom.UserDefinedComponentModel:
            continue
        cb(state)
        any_ran[0] = True
    
    for plugin in state.dataPluginManager.plugins:
        if plugin.runDuringWarmup or not state.dataGlobal.WarmupFlag:
            if plugin.run(state, i_called_from):
                any_ran[0] = True
