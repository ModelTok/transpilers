from datetime import import datetime
import math

struct APIDataEntry:
    var what: String
    var name: String
    var key: String
    var type: String
    var unit: String
    
    fn __init__(inout self, what: String, name: String, type: String, key: String, unit: String):
        self.what = what
        self.name = name
        self.type = type
        self.key = key
        self.unit = unit

fn get_api_data(state: DTypePointer[Int8]) -> List[APIDataEntry]:
    var local_data_entries = List[APIDataEntry]()
    
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
        var unit_str: String
        if variable.units == state.Constant.Units.customEMS:
            unit_str = variable.unitNameCustomEMS
        else:
            unit_str = str(state.Constant.unitNames[int(variable.units)])
        
        local_data_entries.append(APIDataEntry(
            what="OutputVariable",
            name=variable.name,
            type="",
            key=variable.keyUC,
            unit=unit_str
        ))
    
    return local_data_entries

fn list_all_api_data_csv(state: DTypePointer[Int8]) -> String:
    var output = String("**ACTUATORS**\n")
    
    for avail_actuator in state.dataRuntimeLang.EMSActuatorAvailable:
        if (not avail_actuator.ComponentTypeName and not avail_actuator.UniqueIDName and
                not avail_actuator.ControlTypeName):
            break
        output += "Actuator," + avail_actuator.ComponentTypeName + ","
        output += avail_actuator.ControlTypeName + ","
        output += avail_actuator.UniqueIDName + "," + avail_actuator.Units + "\n"
    
    output += "**INTERNAL_VARIABLES**\n"
    for avail_variable in state.dataRuntimeLang.EMSInternalVarsAvailable:
        if not avail_variable.DataTypeName and not avail_variable.UniqueIDName:
            break
        output += "InternalVariable," + avail_variable.DataTypeName + ","
        output += avail_variable.UniqueIDName + "," + avail_variable.Units + "\n"
    
    output += "**PLUGIN_GLOBAL_VARIABLES**\n"
    for g_var_name in state.dataPluginManager.globalVariableNames:
        output += "PluginGlobalVariable," + g_var_name + "\n"
    
    output += "**TRENDS**\n"
    for trend in state.dataPluginManager.trends:
        output += "PluginTrendVariable," + trend.name + "\n"
    
    output += "**METERS**\n"
    for meter in state.dataOutputProcessor.meters:
        if not meter.Name:
            break
        output += "OutputMeter," + meter.Name + ","
        output += str(state.Constant.unitNames[int(meter.units)]) + "\n"
    
    output += "**VARIABLES**\n"
    for variable in state.dataOutputProcessor.outVars:
        if variable.varType != state.OutputProcessor.VariableType.Real:
            continue
        if not variable.name and not variable.keyUC:
            break
        var unit_str: String
        if variable.units == state.Constant.Units.customEMS:
            unit_str = variable.unitNameCustomEMS
        else:
            unit_str = str(state.Constant.unitNames[int(variable.units)])
        output += "OutputVariable," + variable.name + "," + variable.keyUC + "," + unit_str + "\n"
    
    return output

fn api_data_fully_ready(state: DTypePointer[Int8]) -> Int:
    if state.dataPluginManager.fullyReady:
        return 1
    return 0

fn api_error_flag(state: DTypePointer[Int8]) -> Int:
    if state.dataPluginManager.apiErrorFlag:
        return 1
    return 0

fn reset_error_flag(state: DTypePointer[Int8]) -> None:
    state.dataPluginManager.apiErrorFlag = False

fn input_file_path(state: DTypePointer[Int8]) -> String:
    return state.dataStrGlobals.inputFilePath

fn epw_file_path(state: DTypePointer[Int8]) -> String:
    return state.files.inputWeatherFilePath.filePath

fn get_object_names(state: DTypePointer[Int8], object_type: String) -> List[String]:
    var epjson = state.dataInputProcessing.inputProcessor.epJSON
    if object_type not in epjson:
        return List[String]()
    var instances_value = epjson[object_type]
    return List[String](instances_value.keys())

fn get_num_nodes_in_cond_fd_surface_layer(state: DTypePointer[Int8], surf_name: String, mat_name: String) -> Int:
    var uc_surf_name = surf_name.upper()
    var uc_mat_name = mat_name.upper()
    return state.HeatBalFiniteDiffManager.numNodesInMaterialLayer(state, uc_surf_name, uc_mat_name)

fn request_variable(state: DTypePointer[Int8], var_type: String, key: String) -> None:
    var request = state.OutputProcessor.APIOutputVariableRequest()
    request.varName = var_type
    request.varKey = key
    state.dataOutputProcessor.apiVarRequests.append(request)

fn get_variable_handle(state: DTypePointer[Int8], var_type: String, key: String) -> Int:
    var type_uc = var_type.upper()
    var key_uc = key.upper()
    for i in range(len(state.dataOutputProcessor.outVars)):
        var var_ = state.dataOutputProcessor.outVars[i]
        if type_uc == var_.nameUC and key_uc == var_.keyUC:
            return i
    return -1

fn get_variable_value(state: DTypePointer[Int8], handle: Int) -> Float64:
    if 0 <= handle < len(state.dataOutputProcessor.outVars):
        var this_output_var = state.dataOutputProcessor.outVars[handle]
        if this_output_var.varType == state.OutputProcessor.VariableType.Real:
            return this_output_var.value
        if this_output_var.varType == state.OutputProcessor.VariableType.Integer:
            return Float64(this_output_var.value)
        if state.dataGlobal.errorCallback:
            print("ERROR: Variable at handle has type other than Real or Integer, returning zero but caller should take note and likely abort.")
        else:
            state.ShowSevereError("Data Exchange API: Error in getVariableValue; received handle: " + str(handle))
            state.ShowContinueError("The getVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    if state.dataGlobal.errorCallback:
        print("ERROR: Variable handle out of range in getVariableValue, returning zero but caller should take note and likely abort.")
    else:
        state.ShowSevereError("Data Exchange API: Index error in getVariableValue; received handle: " + str(handle))
        state.ShowContinueError("The getVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn get_meter_handle(state: DTypePointer[Int8], meter_name: String) -> Int:
    var meter_name_uc = meter_name.upper()
    return state.GetMeterIndex(state, meter_name_uc)

fn get_meter_value(state: DTypePointer[Int8], handle: Int) -> Float64:
    if 0 <= handle < len(state.dataOutputProcessor.meters):
        return state.GetCurrentMeterValue(state, handle)
    
    if state.dataGlobal.errorCallback:
        print("ERROR: Meter handle out of range in getMeterValue, returning zero but caller should take note and likely abort.")
    else:
        state.ShowSevereError("Data Exchange API: Index error in getMeterValue; received handle: " + str(handle))
        state.ShowContinueError("The getMeterValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn get_actuator_handle(state: DTypePointer[Int8], component_type: String, control_type: String, unique_key: String) -> Int:
    var handle = 0
    var type_uc = component_type.upper()
    var key_uc = unique_key.upper()
    var control_uc = control_type.upper()
    
    for actuator_loop in range(1, state.dataRuntimeLang.numEMSActuatorsAvailable + 1):
        var avail_actuator = state.dataRuntimeLang.EMSActuatorAvailable[actuator_loop - 1]
        handle += 1
        var actuator_type_uc = avail_actuator.ComponentTypeName.upper()
        var actuator_id_uc = avail_actuator.UniqueIDName.upper()
        var actuator_control_uc = avail_actuator.ControlTypeName.upper()
        
        if type_uc == actuator_type_uc and key_uc == actuator_id_uc and control_uc == actuator_control_uc:
            for used_actuator in state.dataRuntimeLang.EMSActuatorUsed:
                if used_actuator.ActuatorVariableNum == handle:
                    used_actuator.wasActuated = True
                    break
            
            if avail_actuator.handleCount > 0:
                var found_actuator = False
                for used_actuator in state.dataRuntimeLang.EMSActuatorUsed:
                    if used_actuator.ActuatorVariableNum == handle:
                        state.ShowWarningError("Data Exchange API: An EnergyManagementSystem:Actuator seems to be already defined in the EnergyPlus File and named '" + used_actuator.Name + "'.")
                        state.ShowContinueError("Occurred for componentType='" + type_uc + "', controlType='" + control_uc + "', uniqueKey='" + key_uc + "'.")
                        state.ShowContinueError("The getActuatorHandle function will still return the handle (= " + str(handle) + ") but caller should take note that there is a risk of overwriting.")
                        found_actuator = True
                        break
                if not found_actuator:
                    state.ShowWarningError("Data Exchange API: You seem to already have tried to get an Actuator Handle on this one.")
                    state.ShowContinueError("Occurred for componentType='" + type_uc + "', controlType='" + control_uc + "', uniqueKey='" + key_uc + "'.")
                    state.ShowContinueError("The getActuatorHandle function will still return the handle (= " + str(handle) + ") but caller should take note that there is a risk of overwriting.")
            
            avail_actuator.handleCount += 1
            return handle
    
    return -1

fn reset_actuator(state: DTypePointer[Int8], handle: Int) -> None:
    if 1 <= handle <= state.dataRuntimeLang.numEMSActuatorsAvailable:
        var the_actuator = state.dataRuntimeLang.EMSActuatorAvailable[handle - 1]
        the_actuator.Actuated = False
    else:
        if state.dataGlobal.errorCallback:
            print("ERROR: Actuator handle out of range in resetActuator, returning but caller should take note and likely abort.")
        else:
            state.ShowSevereError("Data Exchange API: index error in resetActuator; received handle: " + str(handle))
            state.ShowContinueError("The resetActuator function will return to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True

fn set_actuator_value(state: DTypePointer[Int8], handle: Int, value: Float64) -> None:
    if 1 <= handle <= state.dataRuntimeLang.numEMSActuatorsAvailable:
        var the_actuator = state.dataRuntimeLang.EMSActuatorAvailable[handle - 1]
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
            state.ShowSevereError("Data Exchange API: index error in setActuatorValue; received handle: " + str(handle))
            state.ShowContinueError("The setActuatorValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True

fn get_actuator_value(state: DTypePointer[Int8], handle: Int) -> Float64:
    if 1 <= handle <= state.dataRuntimeLang.numEMSActuatorsAvailable:
        var the_actuator = state.dataRuntimeLang.EMSActuatorAvailable[handle - 1]
        if the_actuator.RealValue is not None:
            return the_actuator.RealValue
        if the_actuator.IntValue is not None:
            return Float64(the_actuator.IntValue)
        if the_actuator.LogValue:
            return 1.0
        return 0.0
    
    if state.dataGlobal.errorCallback:
        print("ERROR: Actuator handle out of range in getActuatorValue, returning zero but caller should take note and likely abort.")
    else:
        state.ShowSevereError("Data Exchange API: index error in getActuatorValue; received handle: " + str(handle))
        state.ShowContinueError("The getActuatorValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn get_internal_variable_handle(state: DTypePointer[Int8], var_type: String, key: String) -> Int:
    var handle = 0
    var type_uc = var_type.upper()
    var key_uc = key.upper()
    
    for avail_variable in state.dataRuntimeLang.EMSInternalVarsAvailable:
        handle += 1
        var variable_type_uc = avail_variable.DataTypeName.upper()
        var variable_id_uc = avail_variable.UniqueIDName.upper()
        if type_uc == variable_type_uc and key_uc == variable_id_uc:
            return handle
    
    return -1

fn get_internal_variable_value(state: DTypePointer[Int8], handle: Int) -> Float64:
    if 1 <= handle <= state.dataRuntimeLang.numEMSInternalVarsAvailable:
        var this_var = state.dataRuntimeLang.EMSInternalVarsAvailable[handle - 1]
        if this_var.PntrVarTypeUsed == state.DataRuntimeLanguage.PtrDataType.Real:
            return this_var.RealValue
        if this_var.PntrVarTypeUsed == state.DataRuntimeLanguage.PtrDataType.Integer:
            return Float64(this_var.IntValue)
        print("ERROR: Invalid internal variable type here, developer issue., returning zero but caller should take note and likely abort.")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    if state.dataGlobal.errorCallback:
        print("ERROR: Internal variable handle out of range in getInternalVariableValue, returning zero but caller should take note and likely abort.")
    else:
        state.ShowSevereError("Data Exchange API: index error in getInternalVariableValue; received handle: " + str(handle))
        state.ShowContinueError("The getInternalVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn get_ems_global_variable_handle(state: DTypePointer[Int8], name: String) -> Int:
    var index = 0
    for erl_var in state.dataRuntimeLang.ErlVariable:
        index += 1
        if not (state.dataRuntimeLang.emsVarBuiltInStart <= index <= state.dataRuntimeLang.emsVarBuiltInEnd):
            if state.Util.SameString(name, erl_var.Name):
                return index
    return 0

fn get_ems_global_variable_value(state: DTypePointer[Int8], handle: Int) -> Float64:
    var erl = state.dataRuntimeLang
    var inside_built_in_range = erl.emsVarBuiltInStart <= handle <= erl.emsVarBuiltInEnd
    if inside_built_in_range or handle > erl.NumErlVariables:
        state.ShowSevereError("Data Exchange API: Problem -- index error in getEMSGlobalVariableValue; received handle: " + str(handle))
        state.ShowContinueError("The getEMSGlobalVariableValue function will return 0 for now to allow the process to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    return erl.ErlVariable[handle - 1].Value.Number

fn set_ems_global_variable_value(state: DTypePointer[Int8], handle: Int, value: Float64) -> None:
    var erl = state.dataRuntimeLang
    var inside_built_in_range = erl.emsVarBuiltInStart <= handle <= erl.emsVarBuiltInEnd
    if inside_built_in_range or handle > erl.NumErlVariables:
        state.ShowSevereError("Data Exchange API: Problem -- index error in setEMSGlobalVariableValue; received handle: " + str(handle))
        state.ShowContinueError("The setEMSGlobalVariableValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
    erl.ErlVariable[handle - 1].Value.Number = value

fn get_plugin_global_variable_handle(state: DTypePointer[Int8], name: String) -> Int:
    return state.dataPluginManager.pluginManager.getGlobalVariableHandle(state, name)

fn get_plugin_global_variable_value(state: DTypePointer[Int8], handle: Int) -> Float64:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxGlobalVariableIndex:
        state.ShowSevereError("Data Exchange API: Problem -- index error in getPluginGlobalVariableValue; received handle: " + str(handle))
        state.ShowContinueError("The getPluginGlobalVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    return state.dataPluginManager.pluginManager.getGlobalVariableValue(state, handle)

fn set_plugin_global_variable_value(state: DTypePointer[Int8], handle: Int, value: Float64) -> None:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxGlobalVariableIndex:
        state.ShowSevereError("Data Exchange API: Problem -- index error in setPluginGlobalVariableValue; received handle: " + str(handle))
        state.ShowContinueError("The getPluginGlobalVariableValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
    state.dataPluginManager.pluginManager.setGlobalVariableValue(state, handle, value)

fn get_plugin_trend_variable_handle(state: DTypePointer[Int8], name: String) -> Int:
    return state.PluginManagement.PluginManager.getTrendVariableHandle(state, name)

fn get_plugin_trend_variable_value(state: DTypePointer[Int8], handle: Int, time_index: Int) -> Float64:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError("Data Exchange API: Problem -- index error in getPluginTrendVariableValue; received handle: " + str(handle))
        state.ShowContinueError("The getPluginTrendVariableValue function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    var hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if time_index < 1 or time_index > hist_size:
        state.ShowSevereError("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableValue; received value: " + str(time_index))
        state.ShowContinueError("The getPluginTrendVariableValue function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableValue(state, handle, time_index)

fn get_plugin_trend_variable_average(state: DTypePointer[Int8], handle: Int, count: Int) -> Float64:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError("Data Exchange API: Problem -- index error in getPluginTrendVariableAverage; received handle: " + str(handle))
        state.ShowContinueError("The getPluginTrendVariableAverage function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    var hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableAverage; received value: " + str(count))
        state.ShowContinueError("The getPluginTrendVariableAverage function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableAverage(state, handle, count)

fn get_plugin_trend_variable_min(state: DTypePointer[Int8], handle: Int, count: Int) -> Float64:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError("Data Exchange API: Problem -- index error in getPluginTrendVariableMin; received handle: " + str(handle))
        state.ShowContinueError("The getPluginTrendVariableMin function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    var hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableMin; received value: " + str(count))
        state.ShowContinueError("The getPluginTrendVariableMin function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableMin(state, handle, count)

fn get_plugin_trend_variable_max(state: DTypePointer[Int8], handle: Int, count: Int) -> Float64:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError("Data Exchange API: Problem -- index error in getPluginTrendVariableMax; received handle: " + str(handle))
        state.ShowContinueError("The getPluginTrendVariableMax function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    var hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableMax; received value: " + str(count))
        state.ShowContinueError("The getPluginTrendVariableMax function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableMax(state, handle, count)

fn get_plugin_trend_variable_sum(state: DTypePointer[Int8], handle: Int, count: Int) -> Float64:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError("Data Exchange API: Problem -- index error in getPluginTrendVariableSum; received handle: " + str(handle))
        state.ShowContinueError("The getPluginTrendVariableSum function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    var hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableSum; received value: " + str(count))
        state.ShowContinueError("The getPluginTrendVariableSum function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableSum(state, handle, count)

fn get_plugin_trend_variable_direction(state: DTypePointer[Int8], handle: Int, count: Int) -> Float64:
    if handle < 0 or handle > state.dataPluginManager.pluginManager.maxTrendVariableIndex:
        state.ShowSevereError("Data Exchange API: Problem -- index error in getPluginTrendVariableDirection; received handle: " + str(handle))
        state.ShowContinueError("The getPluginTrendVariableDirection function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    var hist_size = state.PluginManagement.PluginManager.getTrendVariableHistorySize(state, handle)
    if count < 2 or count > hist_size:
        state.ShowSevereError("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableDirection; received value: " + str(count))
        state.ShowContinueError("The getPluginTrendVariableDirection function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        state.dataPluginManager.apiErrorFlag = True
        return 0.0
    
    return state.PluginManagement.PluginManager.getTrendVariableDirection(state, handle, count)

fn year(state: DTypePointer[Int8]) -> Int:
    return state.dataEnvrn.Year

fn calendar_year(state: DTypePointer[Int8]) -> Int:
    return state.dataGlobal.CalendarYear

fn month(state: DTypePointer[Int8]) -> Int:
    return state.dataEnvrn.Month

fn day_of_month(state: DTypePointer[Int8]) -> Int:
    return state.dataEnvrn.DayOfMonth

fn day_of_week(state: DTypePointer[Int8]) -> Int:
    return state.dataEnvrn.DayOfWeek

fn day_of_year(state: DTypePointer[Int8]) -> Int:
    return state.dataEnvrn.DayOfYear

fn daylight_savings_time_indicator(state: DTypePointer[Int8]) -> Int:
    return state.dataEnvrn.DSTIndicator

fn hour(state: DTypePointer[Int8]) -> Int:
    return state.dataGlobal.HourOfDay - 1

fn current_time(state: DTypePointer[Int8]) -> Float64:
    if state.dataHVACGlobal.TimeStepSys < state.dataGlobal.TimeStepZone:
        return (state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone +
                state.dataHVACGlobal.SysTimeElapsed + state.dataHVACGlobal.TimeStepSys)
    return state.dataGlobal.CurrentTime

fn minutes(state: DTypePointer[Int8]) -> Int:
    var current_time_val = current_time(state)
    var fractional_hours_into_the_day = current_time_val - Float64(state.dataGlobal.HourOfDay - 1)
    var fractional_minutes_into_the_day = round(fractional_hours_into_the_day * 60.0)
    return int(fractional_minutes_into_the_day)

fn zone_time_step(state: DTypePointer[Int8]) -> Float64:
    return state.dataGlobal.TimeStepZone

fn system_time_step(state: DTypePointer[Int8]) -> Float64:
    return state.dataHVACGlobal.TimeStepSys

fn num_time_steps_in_hour(state: DTypePointer[Int8]) -> Int:
    return state.dataGlobal.TimeStepsInHour

fn zone_time_step_num(state: DTypePointer[Int8]) -> Int:
    return state.dataGlobal.TimeStep

fn holiday_index(state: DTypePointer[Int8]) -> Int:
    return state.dataEnvrn.HolidayIndex

fn sun_is_up(state: DTypePointer[Int8]) -> Int:
    return 1 if state.dataEnvrn.SunIsUp else 0

fn is_raining(state: DTypePointer[Int8]) -> Int:
    return 1 if state.dataEnvrn.IsRain else 0

fn warmup_flag(state: DTypePointer[Int8]) -> Int:
    return 1 if state.dataGlobal.WarmupFlag else 0

fn current_environment_num(state: DTypePointer[Int8]) -> Int:
    return state.dataEnvrn.CurEnvirNum

fn kind_of_sim(state: DTypePointer[Int8]) -> Int:
    return int(state.dataGlobal.KindOfSim)

fn get_construction_handle(state: DTypePointer[Int8], construction_name: String) -> Int:
    var handle = 0
    var name_uc = construction_name.upper()
    for construct in state.dataConstruction.Construct:
        handle += 1
        if name_uc == construct.Name.upper():
            return handle
    return -1

fn actual_time(state: DTypePointer[Int8]) -> Int:
    var now = datetime.now()
    return now.hour + now.minute + now.second + now.microsecond // 1000000

fn actual_date_time(state: DTypePointer[Int8]) -> Int:
    var now = datetime.now()
    return now.year + now.month + now.day + now.hour + now.minute + now.second + now.microsecond // 1000000

fn today_weather_is_rain_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Int:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return 1 if state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].IsRain else 0
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0

fn today_weather_is_snow_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Int:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return 1 if state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].IsSnow else 0
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0

fn today_weather_out_dry_bulb_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].OutDryBulbTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_out_dew_point_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].OutDewPointTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_out_barometric_pressure_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].OutBaroPress
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_out_relative_humidity_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].OutRelHum
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_wind_speed_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].WindSpeed
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_wind_direction_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].WindDir
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_sky_temperature_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].SkyTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_horizontal_ir_sky_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].HorizIRSky
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_beam_solar_radiation_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].BeamSolarRad
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_diffuse_solar_radiation_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].DifSolarRad
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_albedo_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].Albedo
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn today_weather_liquid_precipitation_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsToday[time_step_num - 1][i_hour - 1].LiquidPrecip
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_is_rain_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Int:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return 1 if state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].IsRain else 0
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0

fn tomorrow_weather_is_snow_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Int:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return 1 if state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].IsSnow else 0
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0

fn tomorrow_weather_out_dry_bulb_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].OutDryBulbTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_out_dew_point_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].OutDewPointTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_out_barometric_pressure_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].OutBaroPress
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_out_relative_humidity_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].OutRelHum
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_wind_speed_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].WindSpeed
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_wind_direction_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].WindDir
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_sky_temperature_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].SkyTemp
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_horizontal_ir_sky_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].HorizIRSky
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_beam_solar_radiation_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].BeamSolarRad
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_diffuse_solar_radiation_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].DifSolarRad
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_albedo_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].Albedo
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn tomorrow_weather_liquid_precipitation_at_time(state: DTypePointer[Int8], hour: Int, time_step_num: Int) -> Float64:
    var i_hour = hour + 1
    if (0 < i_hour <= 24 and 0 < time_step_num <= state.dataGlobal.TimeStepsInHour):
        return state.dataWeather.wvarsHrTsTomorrow[time_step_num - 1][i_hour - 1].LiquidPrecip
    state.ShowSevereError("Invalid return from weather lookup, check hour and time step argument values are in range.")
    state.dataPluginManager.apiErrorFlag = True
    return 0.0

fn current_sim_time(state: DTypePointer[Int8]) -> Float64:
    return Float64(state.dataGlobal.DayOfSim - 1) * 24.0 + current_time(state)
