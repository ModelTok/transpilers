# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - state container with dataPluginManager, dataGlobal, dataStrGlobals, dataInputProcessing
# EMSCallFrom - enum for callback points
# OutputProcessor - SetupOutputVariable, enums: StoreType, TimeStepType, Group, EndUseCat
# Constant - Units, eResource, unitNamesUC, eResourceNamesUC
# FileSystem - getParentDirectoryPath, getAbsolutePath, getProgramPath, pathExists, toString
# InputProcessor - getNumObjectsFound, markObjectAsUsed, epJSON
# Show functions - ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningMessage, ShowMessage
# Util.makeUPPER - string upper conversion
# get_environment_variable - environment variable access
# pow - math power function

from collections import Dict, List, Deque
from pathlib import Path
import os

alias PROGRAM_NAME = "python"
alias Real64 = Float64

struct PluginTrendVariable:
    var name: String
    var numValues: Int
    var values: Deque[Real64]
    var times: Deque[Real64]
    var indexOfPluginVariable: Int
    
    fn __init__(inout self, state: EnergyPlusData, name: String, num_values: Int, index_of_plugin_variable: Int):
        self.name = name
        self.numValues = num_values
        self.indexOfPluginVariable = index_of_plugin_variable
        self.values = Deque[Real64]()
        self.times = Deque[Real64]()
        
        for i in range(1, self.numValues + 1):
            self.values.append(0.0)
            self.times.append(-Float64(i) * state.dataGlobal.TimeStepZone)
    
    fn reset(inout self):
        self.values.clear()
        for i in range(1, self.numValues + 1):
            self.values.append(0.0)

struct PluginInstance:
    var modulePath: Path
    var className: String
    var emsAlias: String
    var runDuringWarmup: Bool
    var stringIdentifier: String
    
    var sHookBeginNewEnvironment: StringLiteral
    var sHookBeginZoneTimestepBeforeSetCurrentWeather: StringLiteral
    var sHookAfterNewEnvironmentWarmUpIsComplete: StringLiteral
    var sHookBeginZoneTimestepBeforeInitHeatBalance: StringLiteral
    var sHookBeginZoneTimestepAfterInitHeatBalance: StringLiteral
    var sHookBeginTimestepBeforePredictor: StringLiteral
    var sHookAfterPredictorBeforeHVACManagers: StringLiteral
    var sHookAfterPredictorAfterHVACManagers: StringLiteral
    var sHookInsideHVACSystemIterationLoop: StringLiteral
    var sHookEndOfZoneTimestepBeforeZoneReporting: StringLiteral
    var sHookEndOfZoneTimestepAfterZoneReporting: StringLiteral
    var sHookEndOfSystemTimestepBeforeHVACReporting: StringLiteral
    var sHookEndOfSystemTimestepAfterHVACReporting: StringLiteral
    var sHookEndOfZoneSizing: StringLiteral
    var sHookEndOfSystemSizing: StringLiteral
    var sHookAfterComponentInputReadIn: StringLiteral
    var sHookUserDefinedComponentModel: StringLiteral
    var sHookUnitarySystemSizing: StringLiteral
    
    var bHasBeginNewEnvironment: Bool
    var bHasBeginZoneTimestepBeforeSetCurrentWeather: Bool
    var bHasAfterNewEnvironmentWarmUpIsComplete: Bool
    var bHasBeginZoneTimestepBeforeInitHeatBalance: Bool
    var bHasBeginZoneTimestepAfterInitHeatBalance: Bool
    var bHasBeginTimestepBeforePredictor: Bool
    var bHasAfterPredictorBeforeHVACManagers: Bool
    var bHasAfterPredictorAfterHVACManagers: Bool
    var bHasInsideHVACSystemIterationLoop: Bool
    var bHasEndOfZoneTimestepBeforeZoneReporting: Bool
    var bHasEndOfZoneTimestepAfterZoneReporting: Bool
    var bHasEndOfSystemTimestepBeforeHVACReporting: Bool
    var bHasEndOfSystemTimestepAfterHVACReporting: Bool
    var bHasEndOfZoneSizing: Bool
    var bHasEndOfSystemSizing: Bool
    var bHasAfterComponentInputReadIn: Bool
    var bHasUserDefinedComponentModel: Bool
    var bHasUnitarySystemSizing: Bool
    
    var pModule: UnsafeMutableRawPointer
    var pClassInstance: UnsafeMutableRawPointer
    var pBeginNewEnvironment: UnsafeMutableRawPointer
    var pBeginZoneTimestepBeforeSetCurrentWeather: UnsafeMutableRawPointer
    var pAfterNewEnvironmentWarmUpIsComplete: UnsafeMutableRawPointer
    var pBeginZoneTimestepBeforeInitHeatBalance: UnsafeMutableRawPointer
    var pBeginZoneTimestepAfterInitHeatBalance: UnsafeMutableRawPointer
    var pBeginTimestepBeforePredictor: UnsafeMutableRawPointer
    var pAfterPredictorBeforeHVACManagers: UnsafeMutableRawPointer
    var pAfterPredictorAfterHVACManagers: UnsafeMutableRawPointer
    var pInsideHVACSystemIterationLoop: UnsafeMutableRawPointer
    var pEndOfZoneTimestepBeforeZoneReporting: UnsafeMutableRawPointer
    var pEndOfZoneTimestepAfterZoneReporting: UnsafeMutableRawPointer
    var pEndOfSystemTimestepBeforeHVACReporting: UnsafeMutableRawPointer
    var pEndOfSystemTimestepAfterHVACReporting: UnsafeMutableRawPointer
    var pEndOfZoneSizing: UnsafeMutableRawPointer
    var pEndOfSystemSizing: UnsafeMutableRawPointer
    var pAfterComponentInputReadIn: UnsafeMutableRawPointer
    var pUserDefinedComponentModel: UnsafeMutableRawPointer
    var pUnitarySystemSizing: UnsafeMutableRawPointer
    
    fn __init__(inout self, module_path: Path, class_name: String, ems_name: String, run_plugin_during_warmup: Bool):
        self.modulePath = module_path
        self.className = class_name
        self.emsAlias = ems_name
        self.runDuringWarmup = run_plugin_during_warmup
        self.stringIdentifier = FileSystem.toString(module_path) + "." + class_name
        
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
        
        self.pModule = UnsafeMutableRawPointer.get_null()
        self.pClassInstance = UnsafeMutableRawPointer.get_null()
        self.pBeginNewEnvironment = UnsafeMutableRawPointer.get_null()
        self.pBeginZoneTimestepBeforeSetCurrentWeather = UnsafeMutableRawPointer.get_null()
        self.pAfterNewEnvironmentWarmUpIsComplete = UnsafeMutableRawPointer.get_null()
        self.pBeginZoneTimestepBeforeInitHeatBalance = UnsafeMutableRawPointer.get_null()
        self.pBeginZoneTimestepAfterInitHeatBalance = UnsafeMutableRawPointer.get_null()
        self.pBeginTimestepBeforePredictor = UnsafeMutableRawPointer.get_null()
        self.pAfterPredictorBeforeHVACManagers = UnsafeMutableRawPointer.get_null()
        self.pAfterPredictorAfterHVACManagers = UnsafeMutableRawPointer.get_null()
        self.pInsideHVACSystemIterationLoop = UnsafeMutableRawPointer.get_null()
        self.pEndOfZoneTimestepBeforeZoneReporting = UnsafeMutableRawPointer.get_null()
        self.pEndOfZoneTimestepAfterZoneReporting = UnsafeMutableRawPointer.get_null()
        self.pEndOfSystemTimestepBeforeHVACReporting = UnsafeMutableRawPointer.get_null()
        self.pEndOfSystemTimestepAfterHVACReporting = UnsafeMutableRawPointer.get_null()
        self.pEndOfZoneSizing = UnsafeMutableRawPointer.get_null()
        self.pEndOfSystemSizing = UnsafeMutableRawPointer.get_null()
        self.pAfterComponentInputReadIn = UnsafeMutableRawPointer.get_null()
        self.pUserDefinedComponentModel = UnsafeMutableRawPointer.get_null()
        self.pUnitarySystemSizing = UnsafeMutableRawPointer.get_null()
    
    @staticmethod
    fn report_python_error(state: EnergyPlusData):
        pass
    
    fn setup(inout self, state: EnergyPlusData):
        pass
    
    fn shutdown(self):
        pass
    
    fn run(self, state: EnergyPlusData, i_called_from: EMSCallFrom) -> Bool:
        return False

struct PluginManager:
    var eplusRunningViaPythonAPI: Bool
    var maxGlobalVariableIndex: Int
    var maxTrendVariableIndex: Int
    
    fn __init__(inout self, state: EnergyPlusData):
        self.eplusRunningViaPythonAPI = state.dataPluginManager.eplusRunningViaPythonAPI
        self.maxGlobalVariableIndex = -1
        self.maxTrendVariableIndex = -1
        
        let s_plugins = "PythonPlugin:Instance"
        if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_plugins) == 0:
            return
    
    fn __del__(owned self):
        pass
    
    @staticmethod
    fn num_active_callbacks(state: EnergyPlusData) -> Int:
        return state.dataPluginManager.callbacks.size() + state.dataPluginManager.userDefinedCallbacks.size()
    
    @staticmethod
    fn current_python_path() -> List[String]:
        return List[String]()
    
    @staticmethod
    fn add_to_python_path(state: EnergyPlusData, include_path: Path, user_defined_path: Bool):
        pass
    
    @staticmethod
    fn setup_output_variables(state: EnergyPlusData):
        pass
    
    fn add_global_variable(inout self, state: EnergyPlusData, name: String):
        self.maxGlobalVariableIndex += 1
    
    @staticmethod
    fn get_global_variable_handle(state: EnergyPlusData, name: String, suppress_warning: Bool = False) -> Int:
        return -1
    
    @staticmethod
    fn get_trend_variable_handle(state: EnergyPlusData, name: String) -> Int:
        return -1
    
    @staticmethod
    fn get_trend_variable_value(state: EnergyPlusData, handle: Int, time_index: Int) -> Real64:
        return 0.0
    
    @staticmethod
    fn get_trend_variable_history_size(state: EnergyPlusData, handle: Int) -> Int:
        return 0
    
    @staticmethod
    fn get_trend_variable_average(state: EnergyPlusData, handle: Int, count: Int) -> Real64:
        return 0.0
    
    @staticmethod
    fn get_trend_variable_min(state: EnergyPlusData, handle: Int, count: Int) -> Real64:
        return 0.0
    
    @staticmethod
    fn get_trend_variable_max(state: EnergyPlusData, handle: Int, count: Int) -> Real64:
        return 0.0
    
    @staticmethod
    fn get_trend_variable_sum(state: EnergyPlusData, handle: Int, count: Int) -> Real64:
        return 0.0
    
    @staticmethod
    fn get_trend_variable_direction(state: EnergyPlusData, handle: Int, count: Int) -> Real64:
        return 0.0
    
    @staticmethod
    fn update_plugin_values(state: EnergyPlusData):
        pass
    
    @staticmethod
    fn get_global_variable_value(state: EnergyPlusData, handle: Int) -> Real64:
        return 0.0
    
    @staticmethod
    fn set_global_variable_value(state: EnergyPlusData, handle: Int, value: Real64):
        pass
    
    @staticmethod
    fn get_location_of_user_defined_plugin(state: EnergyPlusData, program_name: String) -> Int:
        return -1
    
    @staticmethod
    fn run_single_user_defined_plugin(state: EnergyPlusData, index: Int):
        pass
    
    @staticmethod
    fn get_user_defined_callback_index(state: EnergyPlusData, callback_program_name: String) -> Int:
        return -1
    
    @staticmethod
    fn run_single_user_defined_callback(state: EnergyPlusData, index: Int):
        pass
    
    @staticmethod
    fn any_unexpected_plugin_objects(state: EnergyPlusData) -> Bool:
        return False

fn register_new_callback(state: EnergyPlusData, i_called_from: EMSCallFrom, f: fn(UnsafeMutableRawPointer) -> None):
    pass

fn register_user_defined_callback(state: EnergyPlusData, f: fn(UnsafeMutableRawPointer) -> None, program_name_in_input_file: String):
    pass

fn on_begin_environment(state: EnergyPlusData):
    pass

fn python_string_for_usage(state: EnergyPlusData) -> String:
    if state.dataGlobal.errorCallback:
        return "Python Version not accessible during API calls"
    return "This version of EnergyPlus not linked to Python library."

fn clear_state():
    pass

fn run_any_registered_callbacks(state: EnergyPlusData, i_called_from: EMSCallFrom, any_ran: UnsafeMutableRawPointer):
    pass

struct FileSystem:
    @staticmethod
    fn toString(path: Path) -> String:
        return String(path)
    
    @staticmethod
    fn getParentDirectoryPath(path: Path) -> Path:
        return path.parent
    
    @staticmethod
    fn getAbsolutePath(path: Path) -> Path:
        return path
    
    @staticmethod
    fn getProgramPath() -> Path:
        return Path("")
    
    @staticmethod
    fn pathExists(path: Path) -> Bool:
        return False
