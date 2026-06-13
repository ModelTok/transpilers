from cmath import lround
from format import format
from ObjexxFCL.ArrayS.functions import sum
from ObjexxFCL.time import date_and_time
from EnergyPlus.Construction import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobalConstants import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataRuntimeLanguage import *
from EnergyPlus.DataStringGlobals import *
from EnergyPlus.HeatBalFiniteDiffManager import numNodesInMaterialLayer
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.PluginManager import *
from EnergyPlus.WeatherManager import *
from datatransfer import *
from runtime import *

def getAPIData(state: EnergyPlusState, resultingSize: Pointer[UInt32]) -> Pointer[APIDataEntry]:
    struct LocalAPIDataEntry:
        var what: String
        var name: String
        var type: String
        var key: String
        var unit: String
        def __init__(inout self, _what: String, _name: String, _type: String, _key: String, _unit: String):
            self.what = _what
            self.name = _name
            self.type = _type
            self.key = _key
            self.unit = _unit

    var localDataEntries = List[LocalAPIDataEntry]()
    var thisState = state.__as_ptr[EnergyPlusData]()
    for availActuator in thisState[].dataRuntimeLang[].EMSActuatorAvailable:
        if availActuator.ComponentTypeName == "" and availActuator.UniqueIDName == "" and availActuator.ControlTypeName == "":
            break
        localDataEntries.append(LocalAPIDataEntry("Actuator", availActuator.ComponentTypeName, availActuator.ControlTypeName, availActuator.UniqueIDName, availActuator.Units))
    for availVariable in thisState[].dataRuntimeLang[].EMSInternalVarsAvailable:
        if availVariable.DataTypeName == "" and availVariable.UniqueIDName == "":
            break
        localDataEntries.append(LocalAPIDataEntry("InternalVariable", availVariable.DataTypeName, "", availVariable.UniqueIDName, availVariable.Units))
    for gVarName in thisState[].dataPluginManager[].globalVariableNames:
        localDataEntries.append(LocalAPIDataEntry("PluginGlobalVariable", "", "", gVarName, ""))
    for trend in thisState[].dataPluginManager[].trends:
        localDataEntries.append(LocalAPIDataEntry("PluginTrendVariable,", "", "", trend.name, ""))
    for meter in thisState[].dataOutputProcessor[].meters:
        if meter[].Name == "":
            break
        localDataEntries.append(LocalAPIDataEntry("OutputMeter", "", "", meter[].Name, format("{}", Constant.unitNames[int(meter[].units)])))
    for variable in thisState[].dataOutputProcessor[].outVars:
        if variable[].varType != OutputProcessor.VariableType.Real:
            continue
        if variable[].name == "" and variable[].keyUC == "":
            break
        var unitStr: String
        if variable[].units == Constant.Units.customEMS:
            unitStr = variable[].unitNameCustomEMS
        else:
            unitStr = format("{}", Constant.unitNames[int(variable[].units)])
        localDataEntries.append(LocalAPIDataEntry("OutputVariable", variable[].name, "", variable[].keyUC, unitStr))
    resultingSize[] = len(localDataEntries)
    var data = Pointer[APIDataEntry].alloc(resultingSize[])
    for i in range(resultingSize[]):
        data[i].what = localDataEntries[i].what.c_str()
        data[i].name = localDataEntries[i].name.c_str()
        data[i].key = localDataEntries[i].key.c_str()
        data[i].type = localDataEntries[i].type.c_str()
        data[i].unit = localDataEntries[i].unit.c_str()
    return data

def freeAPIData(data: Pointer[APIDataEntry], arraySize: UInt32):
    for i in range(arraySize):
        data[i].what.free()
        data[i].name.free()
        data[i].key.free()
        data[i].type.free()
        data[i].unit.free()
    data.free()

def listAllAPIDataCSV(state: EnergyPlusState) -> Pointer[UInt8]:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var output = String("**ACTUATORS**\n")
    for availActuator in thisState[].dataRuntimeLang[].EMSActuatorAvailable:
        if availActuator.ComponentTypeName == "" and availActuator.UniqueIDName == "" and availActuator.ControlTypeName == "":
            break
        output += "Actuator,"
        output += availActuator.ComponentTypeName + ","
        output += availActuator.ControlTypeName + ","
        output += availActuator.UniqueIDName + ","
        output += availActuator.Units + "\n"
    output += "**INTERNAL_VARIABLES**\n"
    for availVariable in thisState[].dataRuntimeLang[].EMSInternalVarsAvailable:
        if availVariable.DataTypeName == "" and availVariable.UniqueIDName == "":
            break
        output += "InternalVariable,"
        output += availVariable.DataTypeName + ","
        output += availVariable.UniqueIDName + ","
        output += availVariable.Units + "\n"
    output += "**PLUGIN_GLOBAL_VARIABLES**\n"
    for gVarName in thisState[].dataPluginManager[].globalVariableNames:
        output += "PluginGlobalVariable,"
        output += gVarName + "\n"
    output += "**TRENDS**\n"
    for trend in thisState[].dataPluginManager[].trends:
        output += "PluginTrendVariable,"
        output += trend.name + "\n"
    output += "**METERS**\n"
    for meter in thisState[].dataOutputProcessor[].meters:
        if meter[].Name == "":
            break
        output += "OutputMeter" + ","
        output += meter[].Name + ","
        output += format("{}\n", Constant.unitNames[int(meter[].units)])
    output += "**VARIABLES**\n"
    for variable in thisState[].dataOutputProcessor[].outVars:
        if variable[].varType != OutputProcessor.VariableType.Real:
            continue
        if variable[].name == "" and variable[].keyUC == "":
            break
        output += "OutputVariable,"
        output += variable[].name + ","
        output += variable[].keyUC + ","
        var unitStr: String
        if variable[].units == Constant.Units.customEMS:
            unitStr = variable[].unitNameCustomEMS
        else:
            unitStr = Constant.unitNames[int(variable[].units)]
        output += format("{}\n", unitStr)
    var p = Pointer[UInt8].alloc(len(output) + 1)
    for i in range(len(output)):
        p[i] = output[i]
    p[len(output)] = 0
    return p

def apiDataFullyReady(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if thisState[].dataPluginManager[].fullyReady:
        return 1
    return 0

def apiErrorFlag(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if thisState[].dataPluginManager[].apiErrorFlag:
        return 1
    return 0

def resetErrorFlag(state: EnergyPlusState):
    var thisState = state.__as_ptr[EnergyPlusData]()
    thisState[].dataPluginManager[].apiErrorFlag = False

def inputFilePath(state: EnergyPlusState) -> Pointer[UInt8]:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var path_utf8 = FileSystem.toGenericString(thisState[].dataStrGlobals[].inputFilePath)
    var p = Pointer[UInt8].alloc(len(path_utf8) + 1)
    for i in range(len(path_utf8)):
        p[i] = path_utf8[i]
    p[len(path_utf8)] = 0
    return p

def epwFilePath(state: EnergyPlusState) -> Pointer[UInt8]:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var path_utf8 = FileSystem.toGenericString(thisState[].files.inputWeatherFilePath.filePath)
    var p = Pointer[UInt8].alloc(len(path_utf8) + 1)
    for i in range(len(path_utf8)):
        p[i] = path_utf8[i]
    p[len(path_utf8)] = 0
    return p

def getObjectNames(state: EnergyPlusState, objectType: Pointer[UInt8], resultingSize: Pointer[UInt32]) -> Pointer[Pointer[UInt8]]:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var epjson = thisState[].dataInputProcessing[].inputProcessor[].epJSON
    var instances = epjson.find(objectType)
    if instances == epjson.end():
        resultingSize[] = 0
        return Pointer[Pointer[UInt8]]()
    var instancesValue = instances.value()
    resultingSize[] = instancesValue.size()
    var data = Pointer[Pointer[UInt8]].alloc(resultingSize[])
    var i: UInt32 = 0xFFFFFFFF
    for instance in instancesValue:
        i += 1
        data[i] = instance.key().data()
    return data

def freeObjectNames(objectNames: Pointer[Pointer[UInt8]], arraySize: UInt32):
    _ = arraySize
    objectNames.free()

def getNumNodesInCondFDSurfaceLayer(state: EnergyPlusState, surfName: Pointer[UInt8], matName: Pointer[UInt8]) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var UCsurfName = Util.makeUPPER(surfName)
    var UCmatName = Util.makeUPPER(matName)
    return numNodesInMaterialLayer(thisState[], UCsurfName, UCmatName)

def requestVariable(state: EnergyPlusState, type: Pointer[UInt8], key: Pointer[UInt8]):
    var thisState = state.__as_ptr[EnergyPlusData]()
    var request = OutputProcessor.APIOutputVariableRequest()
    request.varName = type
    request.varKey = key
    thisState[].dataOutputProcessor[].apiVarRequests.append(request)

def getVariableHandle(state: EnergyPlusState, type: Pointer[UInt8], key: Pointer[UInt8]) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var typeUC = Util.makeUPPER(type)
    var keyUC = Util.makeUPPER(key)
    for i in range(len(thisState[].dataOutputProcessor[].outVars)):
        var var = thisState[].dataOutputProcessor[].outVars[i]
        if typeUC == var[].nameUC and keyUC == var[].keyUC:
            return i
    return -1

def getVariableValue(state: EnergyPlusState, handle: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle >= 0 and handle < len(thisState[].dataOutputProcessor[].outVars):
        var thisOutputVar = thisState[].dataOutputProcessor[].outVars[handle]
        if thisOutputVar[].varType == OutputProcessor.VariableType.Real:
            return (thisOutputVar.__as_ptr[OutputProcessor.OutVarReal]())[].Which[]
        if thisOutputVar[].varType == OutputProcessor.VariableType.Integer:
            return Float64((thisOutputVar.__as_ptr[OutputProcessor.OutVarInt]())[].Which[])
        if thisState[].dataGlobal[].errorCallback:
            print("ERROR: Variable at handle has type other than Real or Integer, returning zero but caller should take note and likely abort.")
        else:
            ShowSevereError(thisState[], format("Data Exchange API: Error in getVariableValue; received handle: {}", handle))
            ShowContinueError(thisState[], "The getVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    if thisState[].dataGlobal[].errorCallback:
        print("ERROR: Variable handle out of range in getVariableValue, returning zero but caller should take note and likely abort.")
    else:
        ShowSevereError(thisState[], format("Data Exchange API: Index error in getVariableValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The getVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def getMeterHandle(state: EnergyPlusState, meterName: Pointer[UInt8]) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var meterNameUC = Util.makeUPPER(meterName)
    return GetMeterIndex(thisState[], meterNameUC)

def getMeterValue(state: EnergyPlusState, handle: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle >= 0 and handle < len(thisState[].dataOutputProcessor[].meters):
        return GetCurrentMeterValue(thisState[], handle)
    if thisState[].dataGlobal[].errorCallback:
        print("ERROR: Meter handle out of range in getMeterValue, returning zero but caller should take note and likely abort.")
    else:
        ShowSevereError(thisState[], format("Data Exchange API: Index error in getMeterValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The getMeterValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def getActuatorHandle(state: EnergyPlusState, componentType: Pointer[UInt8], controlType: Pointer[UInt8], uniqueKey: Pointer[UInt8]) -> Int32:
    var handle = 0
    var typeUC = Util.makeUPPER(componentType)
    var keyUC = Util.makeUPPER(uniqueKey)
    var controlUC = Util.makeUPPER(controlType)
    var thisState = state.__as_ptr[EnergyPlusData]()
    for ActuatorLoop in range(1, thisState[].dataRuntimeLang[].numEMSActuatorsAvailable + 1):
        var availActuator = thisState[].dataRuntimeLang[].EMSActuatorAvailable[ActuatorLoop - 1]
        handle += 1
        var actuatorTypeUC = Util.makeUPPER(availActuator.ComponentTypeName)
        var actuatorIDUC = Util.makeUPPER(availActuator.UniqueIDName)
        var actuatorControlUC = Util.makeUPPER(availActuator.ControlTypeName)
        if typeUC == actuatorTypeUC and keyUC == actuatorIDUC and controlUC == actuatorControlUC:
            for usedActuator in thisState[].dataRuntimeLang[].EMSActuatorUsed:
                if usedActuator.ActuatorVariableNum == handle:
                    usedActuator.wasActuated = True
                    break
            if availActuator.handleCount > 0:
                var foundActuator = False
                for usedActuator in thisState[].dataRuntimeLang[].EMSActuatorUsed:
                    if usedActuator.ActuatorVariableNum == handle:
                        ShowWarningError(thisState[], "Data Exchange API: An EnergyManagementSystem:Actuator seems to be already defined in the EnergyPlus File and named '" + usedActuator.Name + "'.")
                        ShowContinueError(thisState[], format("Occurred for componentType='{}', controlType='{}', uniqueKey='{}'.", typeUC, controlUC, keyUC))
                        ShowContinueError(thisState[], format("The getActuatorHandle function will still return the handle (= {}) but caller should take note that there is a risk of overwriting.", handle))
                        foundActuator = True
                        break
                if not foundActuator:
                    ShowWarningError(thisState[], "Data Exchange API: You seem to already have tried to get an Actuator Handle on this one.")
                    ShowContinueError(thisState[], format("Occurred for componentType='{}', controlType='{}', uniqueKey='{}'.", typeUC, controlUC, keyUC))
                    ShowContinueError(thisState[], format("The getActuatorHandle function will still return the handle (= {}) but caller should take note that there is a risk of overwriting.", handle))
            availActuator.handleCount += 1
            return handle
    return -1

def resetActuator(state: EnergyPlusState, handle: Int32):
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle >= 1 and handle <= thisState[].dataRuntimeLang[].numEMSActuatorsAvailable:
        var theActuator = thisState[].dataRuntimeLang[].EMSActuatorAvailable[handle - 1]
        theActuator.Actuated[] = False
    else:
        if thisState[].dataGlobal[].errorCallback:
            print("ERROR: Actuator handle out of range in resetActuator, returning but caller should take note and likely abort.")
        else:
            ShowSevereError(thisState[], format("Data Exchange API: index error in resetActuator; received handle: {}", handle))
            ShowContinueError(thisState[], "The resetActuator function will return to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True

def setActuatorValue(state: EnergyPlusState, handle: Int32, value: Float64):
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle >= 1 and handle <= thisState[].dataRuntimeLang[].numEMSActuatorsAvailable:
        var theActuator = thisState[].dataRuntimeLang[].EMSActuatorAvailable[handle - 1]
        if theActuator.RealValue != None:
            theActuator.RealValue[] = value
        elif theActuator.IntValue != None:
            theActuator.IntValue[] = lround(value)
        else:
            theActuator.LogValue[] = value > 0.99999 and value < 1.00001
        theActuator.Actuated[] = True
    else:
        if thisState[].dataGlobal[].errorCallback:
            print("ERROR: Actuator handle out of range in setActuatorValue, returning but caller should take note and likely abort.")
        else:
            ShowSevereError(thisState[], format("Data Exchange API: index error in setActuatorValue; received handle: {}", handle))
            ShowContinueError(thisState[], "The setActuatorValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True

def getActuatorValue(state: EnergyPlusState, handle: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle >= 1 and handle <= thisState[].dataRuntimeLang[].numEMSActuatorsAvailable:
        var theActuator = thisState[].dataRuntimeLang[].EMSActuatorAvailable[handle - 1]
        if theActuator.RealValue != None:
            return theActuator.RealValue[]
        if theActuator.IntValue != None:
            return Float64(theActuator.IntValue[])
        if theActuator.LogValue[]:
            return 1.0
        return 0.0
    if thisState[].dataGlobal[].errorCallback:
        print("ERROR: Actuator handle out of range in getActuatorValue, returning zero but caller should take note and likely abort.")
    else:
        ShowSevereError(thisState[], format("Data Exchange API: index error in getActuatorValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The getActuatorValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def getInternalVariableHandle(state: EnergyPlusState, type: Pointer[UInt8], key: Pointer[UInt8]) -> Int32:
    var handle = 0
    var typeUC = Util.makeUPPER(type)
    var keyUC = Util.makeUPPER(key)
    var thisState = state.__as_ptr[EnergyPlusData]()
    for availVariable in thisState[].dataRuntimeLang[].EMSInternalVarsAvailable:
        handle += 1
        var variableTypeUC = Util.makeUPPER(availVariable.DataTypeName)
        var variableIDUC = Util.makeUPPER(availVariable.UniqueIDName)
        if typeUC == variableTypeUC and keyUC == variableIDUC:
            return handle
    return -1

def getInternalVariableValue(state: EnergyPlusState, handle: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle >= 1 and handle <= thisState[].dataRuntimeLang[].numEMSInternalVarsAvailable:
        var thisVar = thisState[].dataRuntimeLang[].EMSInternalVarsAvailable[handle - 1]
        if thisVar.PntrVarTypeUsed == DataRuntimeLanguage.PtrDataType.Real:
            return thisVar.RealValue[]
        if thisVar.PntrVarTypeUsed == DataRuntimeLanguage.PtrDataType.Integer:
            return Float64(thisVar.IntValue[])
        print("ERROR: Invalid internal variable type here, developer issue., returning zero but caller should take note and likely abort.")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    if thisState[].dataGlobal[].errorCallback:
        print("ERROR: Internal variable handle out of range in getInternalVariableValue, returning zero but caller should take note and likely abort.")
    else:
        ShowSevereError(thisState[], format("Data Exchange API: index error in getInternalVariableValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The getInternalVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def getEMSGlobalVariableHandle(state: EnergyPlusState, name: Pointer[UInt8]) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var index = 0
    for erlVar in thisState[].dataRuntimeLang[].ErlVariable:
        index += 1
        if index < thisState[].dataRuntimeLang[].emsVarBuiltInStart or index > thisState[].dataRuntimeLang[].emsVarBuiltInEnd:
            if Util.SameString(name, erlVar.Name):
                return index
    return 0

def getEMSGlobalVariableValue(state: EnergyPlusState, handle: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var erl = thisState[].dataRuntimeLang
    var insideBuiltInRange = handle >= erl[].emsVarBuiltInStart and handle <= erl[].emsVarBuiltInEnd
    if insideBuiltInRange or handle > thisState[].dataRuntimeLang[].NumErlVariables:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in getEMSGlobalVariableValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The getEMSGlobalVariableValue function will return 0 for now to allow the process to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    return erl[].ErlVariable[handle - 1].Value.Number

def setEMSGlobalVariableValue(state: EnergyPlusState, handle: Int32, value: Float64):
    var thisState = state.__as_ptr[EnergyPlusData]()
    var erl = thisState[].dataRuntimeLang
    var insideBuiltInRange = handle >= erl[].emsVarBuiltInStart and handle <= erl[].emsVarBuiltInEnd
    if insideBuiltInRange or handle > erl[].NumErlVariables:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in setEMSGlobalVariableValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The setEMSGlobalVariableValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
    erl[].ErlVariable[handle - 1].Value.Number = value

def getPluginGlobalVariableHandle(state: EnergyPlusState, name: Pointer[UInt8]) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataPluginManager[].pluginManager[].getGlobalVariableHandle(thisState[], name)

def getPluginGlobalVariableValue(state: EnergyPlusState, handle: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle < 0 or handle > thisState[].dataPluginManager[].pluginManager[].maxGlobalVariableIndex:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in getPluginGlobalVariableValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The getPluginGlobalVariableValue function will return 0 for now to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    return thisState[].dataPluginManager[].pluginManager[].getGlobalVariableValue(thisState[], handle)

def setPluginGlobalVariableValue(state: EnergyPlusState, handle: Int32, value: Float64):
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle < 0 or handle > thisState[].dataPluginManager[].pluginManager[].maxGlobalVariableIndex:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in setPluginGlobalVariableValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The getPluginGlobalVariableValue function will return to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
    thisState[].dataPluginManager[].pluginManager[].setGlobalVariableValue(thisState[], handle, value)

def getPluginTrendVariableHandle(state: EnergyPlusState, name: Pointer[UInt8]) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return PluginManagement.PluginManager.getTrendVariableHandle(thisState[], name)

def getPluginTrendVariableValue(state: EnergyPlusState, handle: Int32, timeIndex: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle < 0 or handle > thisState[].dataPluginManager[].pluginManager[].maxTrendVariableIndex:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in getPluginTrendVariableValue; received handle: {}", handle))
        ShowContinueError(thisState[], "The getPluginTrendVariableValue function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    if timeIndex < 1 or timeIndex > PluginManagement.PluginManager.getTrendVariableHistorySize(thisState[], handle):
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableValue; received value: {}", timeIndex))
        ShowContinueError(thisState[], "The getPluginTrendVariableValue function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    return PluginManagement.PluginManager.getTrendVariableValue(thisState[], handle, timeIndex)

def getPluginTrendVariableAverage(state: EnergyPlusState, handle: Int32, count: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle < 0 or handle > thisState[].dataPluginManager[].pluginManager[].maxTrendVariableIndex:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in getPluginTrendVariableAverage; received handle: {}", handle))
        ShowContinueError(thisState[], "The getPluginTrendVariableAverage function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    if count < 2 or count > PluginManagement.PluginManager.getTrendVariableHistorySize(thisState[], handle):
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableAverage; received value: {}", count))
        ShowContinueError(thisState[], "The getPluginTrendVariableAverage function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    return PluginManagement.PluginManager.getTrendVariableAverage(thisState[], handle, count)

def getPluginTrendVariableMin(state: EnergyPlusState, handle: Int32, count: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle < 0 or handle > thisState[].dataPluginManager[].pluginManager[].maxTrendVariableIndex:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in getPluginTrendVariableMin; received handle: {}", handle))
        ShowContinueError(thisState[], "The getPluginTrendVariableMin function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    if count < 2 or count > PluginManagement.PluginManager.getTrendVariableHistorySize(thisState[], handle):
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableMin; received value: {}", count))
        ShowContinueError(thisState[], "The getPluginTrendVariableMin function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    return PluginManagement.PluginManager.getTrendVariableMin(thisState[], handle, count)

def getPluginTrendVariableMax(state: EnergyPlusState, handle: Int32, count: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle < 0 or handle > thisState[].dataPluginManager[].pluginManager[].maxTrendVariableIndex:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in getPluginTrendVariableMax; received handle: {}", handle))
        ShowContinueError(thisState[], "The getPluginTrendVariableMax function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    if count < 2 or count > PluginManagement.PluginManager.getTrendVariableHistorySize(thisState[], handle):
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableMax; received value: {}", count))
        ShowContinueError(thisState[], "The getPluginTrendVariableMax function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    return PluginManagement.PluginManager.getTrendVariableMax(thisState[], handle, count)

def getPluginTrendVariableSum(state: EnergyPlusState, handle: Int32, count: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle < 0 or handle > thisState[].dataPluginManager[].pluginManager[].maxTrendVariableIndex:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in getPluginTrendVariableSum; received handle: {}", handle))
        ShowContinueError(thisState[], "The getPluginTrendVariableSum function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    if count < 2 or count > PluginManagement.PluginManager.getTrendVariableHistorySize(thisState[], handle):
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableSum; received value: {}", count))
        ShowContinueError(thisState[], "The getPluginTrendVariableSum function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    return PluginManagement.PluginManager.getTrendVariableSum(thisState[], handle, count)

def getPluginTrendVariableDirection(state: EnergyPlusState, handle: Int32, count: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if handle < 0 or handle > thisState[].dataPluginManager[].pluginManager[].maxTrendVariableIndex:
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- index error in getPluginTrendVariableDirection; received handle: {}", handle))
        ShowContinueError(thisState[], "The getPluginTrendVariableDirection function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    if count < 2 or count > PluginManagement.PluginManager.getTrendVariableHistorySize(thisState[], handle):
        ShowSevereError(thisState[], format("Data Exchange API: Problem -- trend history count argument out of range in getPluginTrendVariableDirection; received value: {}", count))
        ShowContinueError(thisState[], "The getPluginTrendVariableDirection function will return 0 to allow the plugin to finish, then EnergyPlus will abort")
        thisState[].dataPluginManager[].apiErrorFlag = True
        return 0.0
    return PluginManagement.PluginManager.getTrendVariableDirection(thisState[], handle, count)

def year(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataEnvrn[].Year

def calendarYear(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataGlobal[].CalendarYear

def month(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataEnvrn[].Month

def dayOfMonth(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataEnvrn[].DayOfMonth

def dayOfWeek(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataEnvrn[].DayOfWeek

def dayOfYear(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataEnvrn[].DayOfYear

def daylightSavingsTimeIndicator(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataEnvrn[].DSTIndicator

def hour(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataGlobal[].HourOfDay - 1

def currentTime(state: EnergyPlusState) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    if thisState[].dataHVACGlobal[].TimeStepSys < thisState[].dataGlobal[].TimeStepZone:
        return thisState[].dataGlobal[].CurrentTime - thisState[].dataGlobal[].TimeStepZone + thisState[].dataHVACGlobal[].SysTimeElapsed + thisState[].dataHVACGlobal[].TimeStepSys
    return thisState[].dataGlobal[].CurrentTime

def minutes(state: EnergyPlusState) -> Int32:
    var currentTimeVal = currentTime(state)
    var thisState = state.__as_ptr[EnergyPlusData]()
    var fractionalHoursIntoTheDay = currentTimeVal - Float64(thisState[].dataGlobal[].HourOfDay - 1)
    var fractionalMinutesIntoTheDay = round(fractionalHoursIntoTheDay * 60.0)
    return Int32(fractionalMinutesIntoTheDay)

def numTimeStepsInHour(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataGlobal[].TimeStepsInHour

def zoneTimeStepNum(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataGlobal[].TimeStep

def holidayIndex(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataEnvrn[].HolidayIndex

def sunIsUp(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return Int32(thisState[].dataEnvrn[].SunIsUp)

def isRaining(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return Int32(thisState[].dataEnvrn[].IsRain)

def warmupFlag(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return Int32(thisState[].dataGlobal[].WarmupFlag)

def zoneTimeStep(state: EnergyPlusState) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataGlobal[].TimeStepZone

def systemTimeStep(state: EnergyPlusState) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataHVACGlobal[].TimeStepSys

def currentEnvironmentNum(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return thisState[].dataEnvrn[].CurEnvirNum

def kindOfSim(state: EnergyPlusState) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return Int32(thisState[].dataGlobal[].KindOfSim)

def getConstructionHandle(state: EnergyPlusState, constructionName: Pointer[UInt8]) -> Int32:
    var handle = 0
    var nameUC = Util.makeUPPER(constructionName)
    var thisState = state.__as_ptr[EnergyPlusData]()
    for construct in thisState[].dataConstruction[].Construct:
        handle += 1
        if nameUC == Util.makeUPPER(construct.Name):
            return handle
    return -1

def actualTime(state: EnergyPlusState) -> Int32:
    var datestring = String()
    var datevalues = Array1D_int(8)
    date_and_time(datestring, _, _, datevalues)
    return sum(datevalues[4:8])

def actualDateTime(state: EnergyPlusState) -> Int32:
    var datestring = String()
    var datevalues = Array1D_int(8)
    date_and_time(datestring, _, _, datevalues)
    return sum(datevalues)

def todayWeatherIsRainAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return Int32(thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].IsRain)
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0

def todayWeatherIsSnowAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return Int32(thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].IsSnow)
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0

def todayWeatherOutDryBulbAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].OutDryBulbTemp
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherOutDewPointAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].OutDewPointTemp
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherOutBarometricPressureAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].OutBaroPress
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherOutRelativeHumidityAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].OutRelHum
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherWindSpeedAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].WindSpeed
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherWindDirectionAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].WindDir
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherSkyTemperatureAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].SkyTemp
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherHorizontalIRSkyAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].HorizIRSky
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherBeamSolarRadiationAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].BeamSolarRad
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherDiffuseSolarRadiationAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].DifSolarRad
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherAlbedoAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].Albedo
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def todayWeatherLiquidPrecipitationAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsToday[timeStepNum - 1][iHour - 1].LiquidPrecip
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherIsRainAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return Int32(thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].IsRain)
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0

def tomorrowWeatherIsSnowAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Int32:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return Int32(thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].IsSnow)
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0

def tomorrowWeatherOutDryBulbAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].OutDryBulbTemp
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherOutDewPointAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].OutDewPointTemp
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherOutBarometricPressureAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].OutBaroPress
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherOutRelativeHumidityAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].OutRelHum
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherWindSpeedAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].WindSpeed
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherWindDirectionAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].WindDir
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherSkyTemperatureAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].SkyTemp
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherHorizontalIRSkyAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].HorizIRSky
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherBeamSolarRadiationAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].BeamSolarRad
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherDiffuseSolarRadiationAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].DifSolarRad
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherAlbedoAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].Albedo
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def tomorrowWeatherLiquidPrecipitationAtTime(state: EnergyPlusState, hour: Int32, timeStepNum: Int32) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    var iHour = hour + 1
    if (iHour > 0) and (iHour <= Constant.iHoursInDay) and (timeStepNum > 0) and (timeStepNum <= thisState[].dataGlobal[].TimeStepsInHour):
        return thisState[].dataWeather[].wvarsHrTsTomorrow[timeStepNum - 1][iHour - 1].LiquidPrecip
    ShowSevereError(thisState[], "Invalid return from weather lookup, check hour and time step argument values are in range.")
    thisState[].dataPluginManager[].apiErrorFlag = True
    return 0.0

def currentSimTime(state: EnergyPlusState) -> Float64:
    var thisState = state.__as_ptr[EnergyPlusData]()
    return (thisState[].dataGlobal[].DayOfSim - 1) * Constant.iHoursInDay + currentTime(state)