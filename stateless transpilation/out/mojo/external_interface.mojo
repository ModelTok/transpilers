# ExternalInterface - EnergyPlus External Interface Module
# Translated from C++ header and implementation
# License: EnergyPlus (see source file)

from collections import InlineArray
from pathlib import Path
from math import *

# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object carrying module data (stub struct)
# - OutputProcessor.VariableType: enum for variable types
# - fs.path: Path-like object
# - Sched module: ExternalInterfaceSetSchedule, GetScheduleNum, GetDayScheduleNum
# - RuntimeLanguageProcessor: FindEMSVariable, isExternalInterfaceErlVariable, ExternalInterfaceSetErlVariable
# - EMSManager: ManageEMS, EMSCallFrom
# - GlobalNames: VerifyUniqueInterObjectName
# - DisplayRoutines: ShowSevereError, ShowWarningError, ShowFatalError, ShowContinueError, DisplayString
# - DataSystemVariables: CheckForActualFilePath
# - DataStringGlobals: pathChar, altpathChar
# - InputProcessor methods
# - FileSystem utilities: fileExists, toString, makeNativePath
# - Util: SameString, makeUPPER, FindItem
# - OutputProcessor: GetVariableKeyCountandType, GetVariableKeys, GetInternalVariableValue, GetInternalVariableValueExternalInterface
# - C External Functions: getmainversionnumber, establishclientsocket, sendclientmessage,
#   checkOperatingSystem, getepvariables, getepvariablesFMU, fmiEPlusGetReal, fmiEPlusSetReal,
#   fmiEPlusDoStep, fmiEPlusInstantiateSlave, fmiEPlusInitializeSlave, fmiEPlusFreeSlave,
#   exchangedoubleswithsocket, exchangedoubleswithsocketFMU, model_ID_GUID, addLibPathCurrentWorkingFolder,
#   getfmiEPlusVersion, fmiEPlusUnpack, getValueReferenceByNameFMUInputVariables,
#   getValueReferenceByNameFMUOutputVariables
# ============================================================================

alias MAX_VAR = 100000
alias MAX_ERR_MSG_LENGTH = 10000

alias INDEX_SCHEDULE = 1
alias INDEX_VARIABLE = 2
alias INDEX_ACTUATOR = 3

alias FMI_OK = 0
alias FMI_WARNING = 1
alias FMI_DISCARD = 2
alias FMI_ERROR = 3
alias FMI_FATAL = 4
alias FMI_PENDING = 5

alias FMI_TRUE = 1
alias FMI_FALSE = 0


struct FmuInputVariableType:
    var Name: String
    var ValueReference: Int

    fn __init__(inout self):
        self.Name = String()
        self.ValueReference = 0


struct CheckFmuInstanceNameType:
    var Name: String

    fn __init__(inout self):
        self.Name = String()


struct EplusOutputVariableType:
    var Name: String
    var VarKey: String
    var RTSValue: Float64
    var ITSValue: Int
    var VarIndex: Int
    var VarType: UInt32
    var VarUnits: String

    fn __init__(inout self):
        self.Name = String()
        self.VarKey = String()
        self.RTSValue = 0.0
        self.ITSValue = 0
        self.VarIndex = 0
        self.VarType = 0
        self.VarUnits = String()


struct FmuOutputVariableScheduleType:
    var Name: String
    var RealVarValue: Float64
    var ValueReference: Int

    fn __init__(inout self):
        self.Name = String()
        self.RealVarValue = 0.0
        self.ValueReference = 0


struct FmuOutputVariableVariableType:
    var Name: String
    var RealVarValue: Float64
    var ValueReference: Int

    fn __init__(inout self):
        self.Name = String()
        self.RealVarValue = 0.0
        self.ValueReference = 0


struct FmuOutputVariableActuatorType:
    var Name: String
    var RealVarValue: Float64
    var ValueReference: Int

    fn __init__(inout self):
        self.Name = String()
        self.RealVarValue = 0.0
        self.ValueReference = 0


struct EplusInputVariableScheduleType:
    var Name: String
    var VarIndex: Int
    var InitialValue: Float64

    fn __init__(inout self):
        self.Name = String()
        self.VarIndex = 0
        self.InitialValue = 0.0


struct EplusInputVariableVariableType:
    var Name: String
    var VarIndex: Int

    fn __init__(inout self):
        self.Name = String()
        self.VarIndex = 0


struct EplusInputVariableActuatorType:
    var Name: String
    var VarIndex: Int

    fn __init__(inout self):
        self.Name = String()
        self.VarIndex = 0


struct InstanceType:
    var Name: String
    var modelID: String
    var modelGUID: String
    var WorkingFolder: String
    var WorkingFolder_wLib: String
    var fmiVersionNumber: String
    var NumInputVariablesInFMU: Int
    var NumInputVariablesInIDF: Int
    var NumOutputVariablesInFMU: Int
    var NumOutputVariablesInIDF: Int
    var NumOutputVariablesSchedule: Int
    var NumOutputVariablesVariable: Int
    var NumOutputVariablesActuator: Int
    var LenModelID: Int
    var LenModelGUID: Int
    var LenWorkingFolder: Int
    var LenWorkingFolder_wLib: Int
    var fmicomponent: DTypePointer[DType.float64]
    var fmistatus: Int
    var Index: Int
    var fmuInputVariable: DynamicVector[FmuInputVariableType]
    var checkfmuInputVariable: DynamicVector[FmuInputVariableType]
    var eplusOutputVariable: DynamicVector[EplusOutputVariableType]
    var fmuOutputVariableSchedule: DynamicVector[FmuOutputVariableScheduleType]
    var eplusInputVariableSchedule: DynamicVector[EplusInputVariableScheduleType]
    var fmuOutputVariableVariable: DynamicVector[FmuOutputVariableVariableType]
    var eplusInputVariableVariable: DynamicVector[EplusInputVariableVariableType]
    var fmuOutputVariableActuator: DynamicVector[FmuOutputVariableActuatorType]
    var eplusInputVariableActuator: DynamicVector[EplusInputVariableActuatorType]

    fn __init__(inout self):
        self.Name = String()
        self.modelID = String()
        self.modelGUID = String()
        self.WorkingFolder = String()
        self.WorkingFolder_wLib = String()
        self.fmiVersionNumber = String()
        self.NumInputVariablesInFMU = 0
        self.NumInputVariablesInIDF = 0
        self.NumOutputVariablesInFMU = 0
        self.NumOutputVariablesInIDF = 0
        self.NumOutputVariablesSchedule = 0
        self.NumOutputVariablesVariable = 0
        self.NumOutputVariablesActuator = 0
        self.LenModelID = 0
        self.LenModelGUID = 0
        self.LenWorkingFolder = 0
        self.LenWorkingFolder_wLib = 0
        self.fmicomponent = DTypePointer[DType.float64]()
        self.fmistatus = 0
        self.Index = 0
        self.fmuInputVariable = DynamicVector[FmuInputVariableType]()
        self.checkfmuInputVariable = DynamicVector[FmuInputVariableType]()
        self.eplusOutputVariable = DynamicVector[EplusOutputVariableType]()
        self.fmuOutputVariableSchedule = DynamicVector[FmuOutputVariableScheduleType]()
        self.eplusInputVariableSchedule = DynamicVector[EplusInputVariableScheduleType]()
        self.fmuOutputVariableVariable = DynamicVector[FmuOutputVariableVariableType]()
        self.eplusInputVariableVariable = DynamicVector[EplusInputVariableVariableType]()
        self.fmuOutputVariableActuator = DynamicVector[FmuOutputVariableActuatorType]()
        self.eplusInputVariableActuator = DynamicVector[EplusInputVariableActuatorType]()


struct FmuType:
    var Name: String
    var TimeOut: Float64
    var Visible: Int
    var Interactive: Int
    var LoggingOn: Int
    var NumInstances: Int
    var TotNumInputVariablesInIDF: Int
    var TotNumOutputVariablesSchedule: Int
    var TotNumOutputVariablesVariable: Int
    var TotNumOutputVariablesActuator: Int
    var Instance: DynamicVector[InstanceType]

    fn __init__(inout self):
        self.Name = String()
        self.TimeOut = 0.0
        self.Visible = 0
        self.Interactive = 0
        self.LoggingOn = 0
        self.NumInstances = 0
        self.TotNumInputVariablesInIDF = 0
        self.TotNumOutputVariablesSchedule = 0
        self.TotNumOutputVariablesVariable = 0
        self.TotNumOutputVariablesActuator = 0
        self.Instance = DynamicVector[InstanceType]()


struct ExternalInterfaceData:
    var tComm: Float64
    var tStop: Float64
    var tStart: Float64
    var hStep: Float64
    var FlagReIni: Bool
    var FMURootWorkingFolder: String
    var nInKeys: Int

    var FMU: DynamicVector[FmuType]
    var FMUTemp: DynamicVector[FmuType]
    var checkInstanceName: DynamicVector[CheckFmuInstanceNameType]

    var NumExternalInterfaces: Int
    var NumExternalInterfacesBCVTB: Int
    var NumExternalInterfacesFMUImport: Int
    var NumExternalInterfacesFMUExport: Int
    var NumFMUObjects: Int
    var FMUExportActivate: Int
    var haveExternalInterfaceBCVTB: Bool
    var haveExternalInterfaceFMUImport: Bool
    var haveExternalInterfaceFMUExport: Bool
    var simulationStatus: Int

    var keyVarIndexes: DynamicVector[Int]
    var varTypes: DynamicVector[UInt32]
    var varInd: DynamicVector[Int]
    var socketFD: Int
    var ErrorsFound: Bool
    var noMoreValues: Bool

    var varKeys: DynamicVector[String]
    var varNames: DynamicVector[String]
    var inpVarTypes: DynamicVector[Int]
    var inpVarNames: DynamicVector[String]

    var configuredControlPoints: Bool
    var useEMS: Bool

    var firstCall: Bool
    var showContinuationWithoutUpdate: Bool
    var GetInputFlag: Bool
    var InitExternalInterfacefirstCall: Bool
    var FirstCallGetSetDoStep: Bool
    var FirstCallIni: Bool
    var FirstCallDesignDays: Bool
    var FirstCallWUp: Bool
    var FirstCallTStep: Bool
    var fmiEndSimulation: Int

    var socCfgFilPath: String
    var UniqueFMUInputVarNames: DynamicVector[String]

    var nOutVal: Int
    var nInpVar: Int

    fn __init__(inout self):
        self.tComm = 0.0
        self.tStop = 3600.0
        self.tStart = 0.0
        self.hStep = 15.0
        self.FlagReIni = False
        self.FMURootWorkingFolder = String()
        self.nInKeys = 3
        self.FMU = DynamicVector[FmuType]()
        self.FMUTemp = DynamicVector[FmuType]()
        self.checkInstanceName = DynamicVector[CheckFmuInstanceNameType]()
        self.NumExternalInterfaces = 0
        self.NumExternalInterfacesBCVTB = 0
        self.NumExternalInterfacesFMUImport = 0
        self.NumExternalInterfacesFMUExport = 0
        self.NumFMUObjects = 0
        self.FMUExportActivate = 0
        self.haveExternalInterfaceBCVTB = False
        self.haveExternalInterfaceFMUImport = False
        self.haveExternalInterfaceFMUExport = False
        self.simulationStatus = 1
        self.keyVarIndexes = DynamicVector[Int]()
        self.varTypes = DynamicVector[UInt32]()
        self.varInd = DynamicVector[Int]()
        self.socketFD = -1
        self.ErrorsFound = False
        self.noMoreValues = False
        self.varKeys = DynamicVector[String]()
        self.varNames = DynamicVector[String]()
        self.inpVarTypes = DynamicVector[Int]()
        self.inpVarNames = DynamicVector[String]()
        self.configuredControlPoints = False
        self.useEMS = False
        self.firstCall = True
        self.showContinuationWithoutUpdate = True
        self.GetInputFlag = True
        self.InitExternalInterfacefirstCall = True
        self.FirstCallGetSetDoStep = True
        self.FirstCallIni = True
        self.FirstCallDesignDays = True
        self.FirstCallWUp = True
        self.FirstCallTStep = True
        self.fmiEndSimulation = 0
        self.socCfgFilPath = String("socket.cfg")
        self.UniqueFMUInputVarNames = DynamicVector[String]()
        self.nOutVal = 0
        self.nInpVar = 0

    fn clear_state(inout self):
        self.tComm = 0.0
        self.tStop = 3600.0
        self.tStart = 0.0
        self.hStep = 15.0
        self.FlagReIni = False
        self.FMURootWorkingFolder = String()
        self.nInKeys = 3
        self.FMU.clear()
        self.FMUTemp.clear()
        self.checkInstanceName.clear()
        self.NumExternalInterfaces = 0
        self.NumExternalInterfacesBCVTB = 0
        self.NumExternalInterfacesFMUImport = 0
        self.NumExternalInterfacesFMUExport = 0
        self.NumFMUObjects = 0
        self.FMUExportActivate = 0
        self.haveExternalInterfaceBCVTB = False
        self.haveExternalInterfaceFMUImport = False
        self.haveExternalInterfaceFMUExport = False
        self.simulationStatus = 1
        self.keyVarIndexes.clear()
        self.varTypes.clear()
        self.varInd.clear()
        self.socketFD = -1
        self.ErrorsFound = False
        self.noMoreValues = False
        self.varKeys.clear()
        self.varNames.clear()
        self.inpVarTypes.clear()
        self.inpVarNames.clear()
        self.configuredControlPoints = False
        self.useEMS = False
        self.firstCall = True
        self.showContinuationWithoutUpdate = True
        self.GetInputFlag = True
        self.InitExternalInterfacefirstCall = True
        self.FirstCallGetSetDoStep = True
        self.FirstCallIni = True
        self.FirstCallDesignDays = True
        self.FirstCallWUp = True
        self.FirstCallTStep = True
        self.fmiEndSimulation = 0
        self.UniqueFMUInputVarNames.clear()


fn external_interface_exchange_variables(inout state: ExternalInterfaceData) -> None:
    if state.GetInputFlag:
        get_external_interface_input(inout state)
        state.GetInputFlag = False

    if state.haveExternalInterfaceBCVTB or state.haveExternalInterfaceFMUExport:
        init_external_interface(inout state)


fn get_external_interface_input(inout state: ExternalInterfaceData) -> None:
    pass


fn stop_external_interface_if_error(inout state: ExternalInterfaceData) -> None:
    pass


fn close_socket(inout state: ExternalInterfaceData, flag_to_write_to_socket: Int) -> None:
    pass


fn parse_string(string: String, inout ele: DynamicVector[String], n_ele: Int) -> None:
    var i_end: Int = 0
    for i in range(n_ele):
        var i_sta = i_end
        var i_col = string.find(';', i_sta)
        if i_col != -1:
            i_end = i_col + 1
        else:
            i_end = len(string)
        if i < len(ele):
            ele[i] = string[i_sta:i_end - 1].upper()


fn init_external_interface(inout state: ExternalInterfaceData) -> None:
    pass


fn get_set_variables_and_do_step_fmu_import(inout state: ExternalInterfaceData) -> None:
    pass


fn instantiate_initialize_fmu_import(inout state: ExternalInterfaceData) -> None:
    pass


fn initialize_fmu(inout state: ExternalInterfaceData) -> None:
    pass


fn terminate_reset_free_fmu_import(inout state: ExternalInterfaceData, fmi_end_simulation: Int) -> None:
    pass


fn init_external_interface_fmu_import(inout state: ExternalInterfaceData) -> None:
    pass


fn trim(string: String) -> String:
    var first: Int = 0
    var last: Int = len(string) - 1
    for i in range(len(string)):
        if string[i] != ' ':
            first = i
            break
    for i in range(len(string) - 1, -1, -1):
        if string[i] != ' ':
            last = i
            break
    if first <= last:
        return string[first:last + 1]
    return String()


fn get_cur_sim_start_time_seconds(inout state: ExternalInterfaceData) -> Float64:
    var simtime: Float64 = 0.0
    var month: Int = 1

    if month == 1:
        simtime = 0
    elif month == 2:
        simtime = 31
    elif month == 3:
        simtime = 59
    elif month == 4:
        simtime = 90
    elif month == 5:
        simtime = 120
    elif month == 6:
        simtime = 151
    elif month == 7:
        simtime = 181
    elif month == 8:
        simtime = 212
    elif month == 9:
        simtime = 243
    elif month == 10:
        simtime = 273
    elif month == 11:
        simtime = 304
    elif month == 12:
        simtime = 334
    else:
        simtime = 0

    simtime = 24 * (simtime + 0)
    simtime = 60 * (simtime + 0)
    simtime = 60 * simtime

    return simtime


fn calc_external_interface_fmu_import(inout state: ExternalInterfaceData) -> None:
    pass


fn validate_run_control(inout state: ExternalInterfaceData) -> None:
    pass


fn calc_external_interface(inout state: ExternalInterfaceData) -> None:
    pass


fn get_report_variable_key(
    inout state: ExternalInterfaceData,
    var_keys: DynamicVector[String],
    number_of_keys: Int,
    var_names: DynamicVector[String],
    inout key_var_indexes: DynamicVector[Int],
    inout var_types: DynamicVector[UInt32]
) -> None:
    pass


fn warn_if_external_interface_objects_are_used(inout state: ExternalInterfaceData, object_word: String) -> None:
    pass


fn verify_external_interface_object(inout state: ExternalInterfaceData) -> None:
    pass


fn get_char_array_from_string(original_string: String) -> DynamicVector[Int]:
    var result = DynamicVector[Int]()
    for i in range(len(original_string)):
        result.push_back(ord(original_string[i]))
    return result


fn get_string_from_char_array(original_char_array: DynamicVector[Int]) -> String:
    var result = String()
    for i in range(len(original_char_array)):
        if original_char_array[i] != 0:
            result += chr(original_char_array[i])
    return result
