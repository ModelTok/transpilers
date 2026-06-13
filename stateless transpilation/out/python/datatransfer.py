from dataclasses import dataclass
from typing import Optional, List, Protocol, Any
import math
from datetime import datetime

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusState (void*) passed as state parameter
# - state.dataRuntimeLang: EMSActuatorAvailable, EMSInternalVarsAvailable, numEMSActuatorsAvailable,
#   numEMSInternalVarsAvailable, EMSActuatorUsed, ErlVariable, emsVarBuiltInStart, emsVarBuiltInEnd,
#   NumErlVariables
# - state.dataPluginManager: fullyReady, apiErrorFlag, globalVariableNames, trends, pluginManager,
#   maxGlobalVariableIndex, maxTrendVariableIndex
# - state.dataOutputProcessor: outVars, meters, apiVarRequests
# - state.dataEnvrn: Year, Month, DayOfMonth, DayOfWeek, DayOfYear, DSTIndicator, HolidayIndex,
#   SunIsUp, IsRain, CurEnvirNum, wvarsHrTsToday, wvarsHrTsTomorrow
# - state.dataGlobal: TimeStepZone, TimeStepSys, CurrentTime, HourOfDay, TimeStepsInHour, TimeStep,
#   KindOfSim, errorCallback, WarmupFlag, CalendarYear
# - state.dataHVACGlobal: TimeStepSys, SysTimeElapsed
# - state.dataStrGlobals.inputFilePath
# - state.files.inputWeatherFilePath.filePath
# - state.dataInputProcessing.inputProcessor.epJSON
# - state.dataConstruction.Construct
# - Util.makeUPPER(s: str) -> str
# - Util.SameString(a: str, b: str) -> bool
# - Constant.iHoursInDay = 24
# - Constant.unitNames: List[str]
# - Constant.Units.customEMS
# - OutputProcessor.VariableType.Real, Integer
# - DataRuntimeLanguage.PtrDataType.Real, Integer
# - ShowSevereError(state, msg)
# - ShowContinueError(state, msg)
# - ShowWarningError(state, msg)
# - GetMeterIndex(state, name: str) -> int
# - GetCurrentMeterValue(state, handle: int) -> float
# - HeatBalFiniteDiffManager.numNodesInMaterialLayer(state, surf_name: str, mat_name: str) -> int
# - PluginManagement.PluginManager.getTrendVariableHandle(state, name: str) -> int
# - PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle: int) -> int
# - PluginManagement.PluginManager.getTrendVariableValue(state, handle: int, time_index: int) -> float
# - PluginManagement.PluginManager.getTrendVariableAverage(state, handle: int, count: int) -> float
# - PluginManagement.PluginManager.getTrendVariableMin(state, handle: int, count: int) -> float
# - PluginManagement.PluginManager.getTrendVariableMax(state, handle: int, count: int) -> float
# - PluginManagement.PluginManager.getTrendVariableSum(state, handle: int, count: int) -> float
# - PluginManagement.PluginManager.getTrendVariableDirection(state, handle: int, count: int) -> float
# - FileSystem.toGenericString(path) -> str

@dataclass
class APIDataEntry:
    what: str
    name: str
    key: str
    type: str
    unit: str

class UtilProtocol(Protocol):
    @staticmethod
    def makeUPPER(s: str) -> str:
        pass
    
    @staticmethod
    def SameString(a: str, b: str) -> bool:
        pass

def get_api_data(state: Any) -> List[APIDataEntry]:
    local_data_entries: List[APIDataEntry] = []
    
    for avail_actuator in state.dataRuntimeLang.EMSActuatorAvailable:
        if (not avail_actuator.ComponentTypeName and not avail_actuator.UniqueIDName and
                not avail_actuator.ControlTypeName):
            break
        local_data_entries.append(APIDataEntry(
            what="Actuator",
            name=avail_actuator.ComponentTypeName,
            type=avail_actuator.ControlTypeName,
            key=avail_actuator.UniqueIDName,
            unit=avail_actuator.Units
        ))
    
    for avail_variable in state.dataRuntimeLang.EMSInternalVarsAvailable:
        if not avail_variable.DataTypeName and not avail_variable.UniqueIDName:
            break
        local_data_entries.append(APIDataEntry(
            what="InternalVariable",
            name=avail_variable.DataTypeName,
            type="",
            key=avail_variable.UniqueIDName,
            unit=avail_variable.Units
        ))
    
    for g_var_name in state.dataPluginManager.globalVariableNames:
        local_data_entries.append(APIDataEntry(
            what="PluginGlobalVariable",
            name="",
            type="",
            key=g_var_name,
            unit=""
        ))
    
    for trend in state.dataPluginManager.trends:
        local_data_entries.append(APIDataEntry(
            what="PluginTrendVariable",
            name="",
            type="",
            key=trend.name,
            unit=""
        ))
    
    for meter in state.dataOutputProcessor.meters:
        if not meter.Name:
            break
        local_data_entries.append(APIDataEntry(
            what="OutputMeter",
            name="",
            type="",
            key=meter.Name,
            unit=str(state.Constant.unitNames[int(meter.units)])
        ))
    
    for variable in state.dataOutputProcessor.outVars:
        if variable.varType != state.OutputProcessor.VariableType.Real:
            continue
        if not variable.name and not variable.keyUC:
            break
        unit_str = (variable.unitNameCustomEMS if variable.units == state.Constant.Units.customEMS
                    else str(state.Constant.unitNames[int(variable.units)]))
        local_data_entries.append(APIDataEntry(
            what="OutputVariable",
            name=variable.name,
            type="",
            key=variable.keyUC,
            unit=unit_str
        ))
    
    return local_data_entries

def list_all_api_data_csv(state: Any) -> str:
    output = "**ACTUATORS**\n"
    
    for avail_actuator in state.dataRuntimeLang.EMSActuatorAvailable:
        if (not avail_actuator.ComponentTypeName and not avail_actuator.UniqueIDName and
                not avail_actuator.ControlTypeName):
            break
        output += f"Actuator,{avail_actuator.ComponentTypeName},{avail_actuator.ControlTypeName},"
        output += f"{avail_actuator.UniqueIDName},{avail_actuator.Units}\n"
    
    output += "**INTERNAL_VARIABLES**\n"
    for avail_variable in state.dataRuntimeLang.EMSInternalVarsAvailable:
        if not avail_variable.DataTypeName and not avail_variable.UniqueIDName:
            break
        output += f"InternalVariable,{avail_variable.DataTypeName},"
        output += f"{avail_variable.UniqueIDName},{avail_variable.Units}\n"
    
    output += "**PLUGIN_GLOBAL_VARIABLES**\n"
    for g_var_name in state.dataPluginManager.globalVariableNames:
        output += f"PluginGlobalVariable,{g_var_name}\n"
    
    output += "**TRENDS**\n"
    for trend in state.dataPluginManager.trends:
        output += f"PluginTrendVariable,{trend.name}\n"
    
    output += "**METERS**\n"
    for meter in state.dataOutputProcessor.meters:
        if not meter.Name:
            break
        output += f"OutputMeter,{meter.Name},"
        output += f"{state.Constant.unitNames[int(meter.units)]}\n"
    
    output += "**VARIABLES**\n"
    for variable in state.dataOutputProcessor.outVars:
        if variable.varType != state.OutputProcessor.VariableType.Real:
            continue
        if not variable.name and not variable.keyUC:
            break
        unit_str = (variable.unitNameCustomEMS if variable.units == state.Constant.Units.customEMS
                    else state.Constant.unitNames[int(variable.units)])
        output += f"OutputVariable,{variable.name},{variable.keyUC},{unit_str}\n"
    
    return output

def api_data_fully_ready(state: Any) -> int:
    if state.dataPluginManager.fullyReady:
        return 1
    return 0

def api_error_flag(state: Any) -> int:
    if state.dataPluginManager.apiErrorFlag:
        return 1
    return 0

def reset_error_flag(state: Any) -> None:
    state.dataPluginManager.apiErrorFlag = False

def input_file_path(state: Any) -> str:
    return state.dataStrGlobals.inputFilePath

def epw_file_path(state: Any) -> str:
    return state.files.inputWeatherFilePath.filePath

def get_object_names(state: Any, object_type: str) -> List[str]:
    epjson = state.dataInputProcessing.inputProcessor.epJSON
    if object_type not in epjson:
        return []
    instances_value = epjson[object_type]
    return list(instances_value.keys())

def get_num_nodes_in_cond_fd_surface_layer(state: Any, surf_name: str, mat_name: str) -> int:
    uc_surf_name = surf_name.upper()
    uc_mat_name = mat_name.upper()
    return state.HeatBalFiniteDiffManager.numNodesInMaterialLayer(state, uc_surf_name, uc_mat_name)

def request_variable(state: Any, var_type: str, key: str) -> None:
    request = state.OutputProcessor.APIOutputVariableRequest()
    request.varName = var_type
    request.varKey = key
    state.dataOutputProcessor.apiVarRequests.append(request)

def get_variable_handle(state: Any, var_type: str, key: str) -> int:
    type_uc = var_type.upper()
    key_uc = key.upper()
    for i, var in enumerate(state.dataOutputProcessor.outVars):
        if type_uc == var.nameUC and key_uc == var.keyUC:
            return i
    return -1

def get_variable_value(state: Any, handle: int) -> float:
    if 0 <= handle < len(state.dataOutputProcessor.outVars):
        this_output_var = state.dataOutputProcessor.outVars[handle]
        if this_output_var.varType == state.OutputProcessor.VariableType.Real:
            return this_output_var.value
        if this_output_var.varType == state.OutputProcessor.VariableType.Integer:
            return float(this_output_var.value)
        if state.dataGlobal.errorCallback:
            print("ERROR: Variable at handle has type other than Real or Integer, returning zero but caller should take note and likely abort.")
        else:
            state.ShowSevereError(f"Data Exchange API: Error in getVariableValue; received handle: {handle}")
            state.ShowContinueError("The getVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    if state.dataGlobal.errorCallback:
        print("ERROR: Variable handle out of range in getVariableValue, returning zero but caller should take note and likely abort.")
    else:
        state.ShowSevereError(f"Data Exchange API: Index error in getVariableValue; received handle: {handle}")
        state.ShowContinueError("The getVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def get_meter_handle(state: Any, meter_name: str) -> int:
    meter_name_uc = meter_name.upper()
    return state.GetMeterIndex(state, meter_name_uc)

def get_meter_value(state: Any, handle: int) -> float:
    if 0 <= handle < len(state.dataOutputProcessor.meters):
        return state.GetCurrentMeterValue(state, handle)
    
    if state.dataGlobal.errorCallback:
        print("ERROR: Meter handle out of range in getMeterValue, returning zero but caller should take note and likely abort.")
    else:
        state.ShowSevereError(f"Data Exchange API: Index error in getMeterValue; received handle: {handle}")
        state.ShowContinueError("The getMeterValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def get_actuator_handle(state: Any, component_type: str, control_type: str, unique_key: str) -> int:
    handle = 0
    type_uc = component_type.upper()
    key_uc = unique_key.upper()
    control_uc = control_type.upper()
    
    for actuator_loop in range(1, state.dataRuntimeLang.numEMSActuatorsAvailable + 1):
        avail_actuator = state.dataRuntimeLang.EMSActuatorAvailable[actuator_loop - 1]
        handle += 1
        actuator_type_uc = avail_actuator.ComponentTypeName.upper()
        actuator_id_uc = avail_actuator.UniqueIDName.upper()
        actuator_control_uc = avail_actuator.ControlTypeName.upper()
        
        if type_uc == actuator_type_uc and key_uc == actuator_id_uc and control_uc == actuator_control_uc:
            for used_actuator in state.dataRuntimeLang.EMSActuatorUsed:
                if used_actuator.ActuatorVariableNum == handle:
                    used_actuator.wasActuated = True
                    break
            
            if avail_actuator.handleCount > 0:
                found_actuator = False
                for used_actuator in state.dataRuntimeLang.EMSActuatorUsed:
                    if used_actuator.ActuatorVariableNum == handle:
                        state.ShowWarningError(f"Data Exchange API: An EnergyManagementSystem:Actuator seems to be already defined in the EnergyPlus File and named '{used_actuator.Name}'.")
                        state.ShowContinueError(f"Occurred for componentType='{type_uc}', controlType='{control_uc}', uniqueKey='{key_uc}'.")
                        state.ShowContinueError(f"The getActuatorHandle function will still return the handle (= {handle}) but caller should take note that there is a risk of overwriting.")
                        found_actuator = True
                        break
                if not found_actuator:
                    state.ShowWarningError("Data Exchange API: You seem to already have tried to get an Actuator Handle on this one.")
                    state.ShowContinueError(f"Occurred for componentType='{type_uc}', controlType='{control_uc}', uniqueKey='{key_uc}'.")
                    state.ShowContinueError(f"The getActuatorHandle function will still return the handle (= {handle}) but caller should take note that there is a risk of overwriting.")
            
            avail_actuator.handleCount += 1
            return handle
    
    return -1

def reset_actuator(state: Any, handle: int) -> None:
    if 1 <= handle <= state.dataRuntimeLang.numEMSActuatorsAvailable:
        the_actuator = state.dataRuntimeLang.EMSActuatorAvailable[handle - 1]
        the_actuator.Actuated = False
    else:
        if state.dataGlobal.errorCallback:
            print("ERROR: Actuator handle out of range in resetActuator, returning but caller should take note and likely abort.")
        else:
            state.ShowSevereError(f"Data Exchange API: index error in resetActuator; received handle: {handle}")
            state.ShowContinueError("The resetActuator function will return to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True

def set_actuator_value(state: Any, handle: int, value: float) -> None:
    if 1 <= handle <= state.dataRuntimeLang.numEMSActuatorsAvailable:
        the_actuator = state.dataRuntimeLang.EMSActuatorAvailable[handle - 1]
        if the_actuator.RealValue is not None:
            the_actuator.RealValue = value
        elif the_actuator.IntValue is not None:
            the_actuator.IntValue = int(round(value))
        else:
            the_actuator.LogValue = value > 0.99999 and value < 1.00001
        the_actuator.Actuated = True
    else:
        if state.dataGlobal.errorCallback:
            print("ERROR: Actuator handle out of range in setActuatorValue, returning but caller should take note and likely abort.")
        else:
            state.ShowSevereError(f"Data Exchange API: index error in setActuatorValue; received handle: {handle}")
            state.ShowContinueError("The setActuatorValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True

def get_actuator_value(state: Any, handle: int) -> float:
    if 1 <= handle <= state.dataRuntimeLang.numEMSActuatorsAvailable:
        the_actuator = state.dataRuntimeLang.EMSActuatorAvailable[handle - 1]
        if the_actuator.RealValue is not None:
            return the_actuator.RealValue
        if the_actuator.IntValue is not None:
            return float(the_actuator.IntValue)
        if the_actuator.LogValue:
            return 1.0
        return 0.0
    
    if state.dataGlobal.errorCallback:
        print("ERROR: Actuator handle out of range in getActuatorValue, returning zero but caller should take note and likely abort.")
    else:
        state.ShowSevereError(f"Data Exchange API: index error in getActuatorValue; received handle: {handle}")
        state.ShowContinueError("The getActuatorValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def get_internal_variable_handle(state: Any, var_type: str, key: str) -> int:
    handle = 0
    type_uc = var_type.upper()
    key_uc = key.upper()
    
    for avail_variable in state.dataRuntimeLang.EMSInternalVarsAvailable:
        handle += 1
        variable_type_uc = avail_variable.DataTypeName.upper()
        variable_id_uc = avail_variable.UniqueIDName.upper()
        if type_uc == variable_type_uc and key_uc == variable_id_uc:
            return handle
    
    return -1

def get_internal_variable_value(state: Any, handle: int) -> float:
    if 1 <= handle <= state.dataRuntimeLang.numEMSInternalVarsAvailable:
        this_var = state.dataRuntimeLang.EMSInternalVarsAvailable[handle - 1]
        if this_var.PntrVarTypeUsed == state.DataRuntimeLanguage.PtrDataType.Real:
            return this_var.RealValue
        if this_var.PntrVarTypeUsed == state.DataRuntimeLanguage.PtrDataType.Integer:
            return float(this_var.IntValue)
        print("ERROR: Invalid internal variable type here, developer issue., returning zero but caller should take note and likely abort.")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    if state.dataGlobal.errorCallback:
        print("ERROR: Internal variable handle out of range in getInternalVariableValue, returning zero but caller should take note and likely abort.")
    else:
        state.ShowSevereError(f"Data Exchange API: index error in getInternalVariableValue; received handle: {handle}")
        state.ShowContinueError("The getInternalVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def get_ems_global_variable_handle(state: Any, name: str) -> int:
    index = 0
    for erl_var in state.dataRuntimeLang.ErlVariable:
        index += 1
        if not (state.dataRuntimeLang.emsVarBuiltInStart <= index <= state.dataRuntimeLang.emsVarBuiltInEnd):
            if state.Util.SameString(name, erl_var.Name):
                return index
    return 0

def get_ems_global_variable_value(state: Any, handle: int) -> float:
    erl = state.dataRuntimeLang
    inside_built_in_range = erl.emsVarBuiltInStart <= handle <= erl.emsVarBuiltInEnd
    if inside_built_in_range or handle > erl.NumErlVariables:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in getEMSGlobalVariableValue; received handle: {handle}")
        state.ShowContinueError("The getEMSGlobalVariableValue function will return 0 for now to allow the process to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    return erl.ErlVariable[handle - 1].Value.Number

def set_ems_global_variable_value(state: Any, handle: int, value: float) -> None:
    erl = state.dataRuntimeLang
    inside_built_in_range = erl.emsVarBuiltInStart <= handle <= erl.emsVarBuiltInEnd
    if inside_built_in_range or handle > erl.NumErlVariables:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in setEMSGlobalVariableValue; received handle: {handle}")
        state.ShowContinueError("The setEMSGlobalVariableValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
    erl.ErlVariable[handle - 1].Value.Number = value

def get_plugin_global_variable_handle(state: Any, name: str) -> int:
    return state.dataPluginManager.pluginManager.getGlobalVariableHandle(state, name)

def get_plugin_global_variable_value(state: Any, handle: int) -> float:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxGlobalVariableIndex:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in getPluginGlobalVariableValue; received handle: {handle}")
        state.ShowContinueError("The getPluginGlobalVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    return state.dataPluginManager.pluginManager.getGlobalVariableValue(state, handle)

def set_plugin_global_variable_value(state: Any, handle: int, value: float) -> None:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxGlobalVariableIndex:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in setPluginGlobalVariableValue; received handle: {handle}")
        state.ShowContinueError("The getPluginGlobalVariableValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
    state.dataPluginManager.pluginManager.setGlobalVariableValue(state, handle, value)

def get_plugin_trend_variable_handle(state: Any, name: str) -> int:
    return state.PluginManagement.PluginManager.getTrendVariableHandle(state, name)

def get_plugin_trend_variable_value(state: Any, handle: int, time_index: int) -> float:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in getPluginTrendVariableValue; received handle: {handle}")
        state.ShowContinueError("The getPluginTrendVariableValue function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if time_index < 1 or time_index > hist_size:
        state.ShowSevereError(f"Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableValue; received value: {time_index}")
        state.ShowContinueError("The getPluginTrendVariableValue function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableValue(state, handle, time_index)

def get_plugin_trend_variable_average(state: Any, handle: int, count: int) -> float:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in getPluginTrendVariableAverage; received handle: {handle}")
        state.ShowContinueError("The getPluginTrendVariableAverage function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError(f"Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableAverage; received value: {count}")
        state.ShowContinueError("The getPluginTrendVariableAverage function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableAverage(state, handle, count)

def get_plugin_trend_variable_min(state: Any, handle: int, count: int) -> float:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in getPluginTrendVariableMin; received handle: {handle}")
        state.ShowContinueError("The getPluginTrendVariableMin function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError(f"Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableMin; received value: {count}")
        state.ShowContinueError("The getPluginTrendVariableMin function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableMin(state, handle, count)

def get_plugin_trend_variable_max(state: Any, handle: int, count: int) -> float:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in getPluginTrendVariableMax; received handle: {handle}")
        state.ShowContinueError("The getPluginTrendVariableMax function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError(f"Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableMax; received value: {count}")
        state.ShowContinueError("The getPluginTrendVariableMax function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableMax(state, handle, count)

def get_plugin_trend_variable_sum(state: Any, handle: int, count: int) -> float:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in getPluginTrendVariableSum; received handle: {handle}")
        state.ShowContinueError("The getPluginTrendVariableSum function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError(f"Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableSum; received value: {count}")
        state.ShowContinueError("The getPluginTrendVariableSum function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableSum(state, handle, count)

def get_plugin_trend_variable_direction(state: Any, handle: int, count: int) -> float:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError(f"Data Exchange API: Problem -- index error in getPluginTrendVariableDirection; received handle: {handle}")
        state.ShowContinueError("The getPluginTrendVariableDirection function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError(f"Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableDirection; received value: {count}")
        state.ShowContinueError("The getPluginTrendVariableDirection function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableDirection(state, handle, count)

def year(state: Any) -> int:
    return state.dataEnvrn.Year

def calendar_year(state: Any) -> int:
    return state.dataGlobal.CalendarYear

def month(state: Any) -> int:
    return state.dataEnvrn.Month

def day_of_month(state: Any) -> int:
    return state.dataEnvrn.DayOfMonth

def day_of_week(state: Any) -> int:
    return state.dataEnvrn.DayOfWeek

def day_of_year(state: Any) -> int:
    return state.dataEnvrn.DayOfYear

def daylight_savings_time_indicator(state: Any) -> int:
    return state.dataEnvrn.DSTIndicator

def hour(state: Any) -> int:
    return state.dataGlobal.HourOfDay - 1

def current_time(state: Any) -> float:
    if state.dataHVACGlobal.TimeStepSys < state.dataGlobal.TimeStepZone:
        return (state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone +
                state.dataHVACGlobal.SysTimeElapsed + state.dataHVACGlobal.TimeStepSys)
    return state.dataGlobal.CurrentTime

def minutes(state: Any) -> int:
    current_time_val = current_time(state)
    fractional_hours_into_the_day = current_time_val - float(state.dataGlobal.HourOfDay - 1)
    fractional_minutes_into_the_day = round(fractional_hours_into_the_day * 60.0)
    return int(fractional_minutes_into_the_day)

def zone_time_step(state: Any) -> float:
    return state.dataGlobal.TimeStepZone

def system_time_step(state: Any) -> float:
    return state.dataHVACGlobal.TimeStepSys

def num_time_steps_in_hour(state: Any) -> int:
    return state.dataGlobal.TimeStepsInHour

def zone_time_step_num(state: Any) -> int:
    return state.dataGlobal.TimeStep

def holiday_index(state: Any) -> int:
    return state.dataEnvrn.HolidayIndex

def sun_is_up(state: Any) -> int:
    return 1 if state.dataEnvrn.SunIsUp else 0

def is_raining(state: Any) -> int:
    return 1 if state.dataEnvrn.IsRain else 0

def warmup_flag(state: Any) -> int:
    return 1 if state.dataGlobal.WarmupFlag else 0

def current_environment_num(state: Any) -> int:
    return state.dataEnvrn.CurEnvirNum

def kind_of_sim(state: Any) -> int:
    return int(state.dataGlobal.KindOfSim)

def get_construction_handle(state: Any, construction_name: str) -> int:
    handle = 0
    name_uc = construction_name.upper()
    for construct in state.dataConstruction.Construct:
        handle += 1
        if name_uc == construct.Name.upper():
            return handle
    return -1

def actual_time(state: Any) -> int:
    now = datetime.now()
    return now.hour + now.minute + now.second + now.microsecond // 1000000

def actual_date_time(state: Any) -> int:
    now = datetime.now()
    return now.year + now.month + now.day + now.hour + now.minute + now.second + now.microsecond // 1000000

def today_weather_is_rain_at_time(state: Any, hour: int, time_step_num: int) -> int:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return 1 if state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].IsRain else 0
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0

def today_weather_is_snow_at_time(state: Any, hour: int, time_step_num: int) -> int:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return 1 if state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].IsSnow else 0
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0

def today_weather_out_dry_bulb_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].OutDryBulbTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_out_dew_point_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].OutDewPointTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_out_barometric_pressure_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].OutBaroPress
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_out_relative_humidity_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].OutRelHum
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_wind_speed_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].WindSpeed
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_wind_direction_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].WindDir
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_sky_temperature_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].SkyTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_horizontal_ir_sky_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].HorizIRSky
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_beam_solar_radiation_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].BeamSolarRad
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_diffuse_solar_radiation_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].DifSolarRad
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_albedo_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].Albedo
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def today_weather_liquid_precipitation_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].LiquidPrecip
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_is_rain_at_time(state: Any, hour: int, time_step_num: int) -> int:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return 1 if state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].IsRain else 0
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0

def tomorrow_weather_is_snow_at_time(state: Any, hour: int, time_step_num: int) -> int:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return 1 if state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].IsSnow else 0
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0

def tomorrow_weather_out_dry_bulb_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].OutDryBulbTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_out_dew_point_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].OutDewPointTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_out_barometric_pressure_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].OutBaroPress
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_out_relative_humidity_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].OutRelHum
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_wind_speed_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].WindSpeed
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_wind_direction_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].WindDir
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_sky_temperature_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].SkyTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_horizontal_ir_sky_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].HorizIRSky
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_beam_solar_radiation_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].BeamSolarRad
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_diffuse_solar_radiation_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].DifSolarRad
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_albedo_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].Albedo
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def tomorrow_weather_liquid_precipitation_at_time(state: Any, hour: int, time_step_num: int) -> float:
    i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].LiquidPrecip
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

def current_sim_time(state: Any) -> float:
    return (state.dataGlobal.DayOfSim - 1) * 24 + current_time(state)
