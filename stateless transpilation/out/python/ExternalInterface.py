# ExternalInterface - EnergyPlus External Interface Module
# Translated from C++ header and implementation
# License: EnergyPlus (see source file)

from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from pathlib import Path
from enum import IntEnum

# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object carrying module data (stub Protocol/dataclass)
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

# Module constants
MAX_VAR = 100000
MAX_ERR_MSG_LENGTH = 10000

INDEX_SCHEDULE = 1
INDEX_VARIABLE = 2
INDEX_ACTUATOR = 3

FMI_OK = 0
FMI_WARNING = 1
FMI_DISCARD = 2
FMI_ERROR = 3
FMI_FATAL = 4
FMI_PENDING = 5

FMI_TRUE = 1
FMI_FALSE = 0


@dataclass
class FmuInputVariableType:
    Name: str = ""
    ValueReference: int = 0


@dataclass
class CheckFmuInstanceNameType:
    Name: str = ""


@dataclass
class EplusOutputVariableType:
    Name: str = ""
    VarKey: str = ""
    RTSValue: float = 0.0
    ITSValue: int = 0
    VarIndex: int = 0
    VarType: Optional[Any] = None
    VarUnits: str = ""


@dataclass
class FmuOutputVariableScheduleType:
    Name: str = ""
    RealVarValue: float = 0.0
    ValueReference: int = 0


@dataclass
class FmuOutputVariableVariableType:
    Name: str = ""
    RealVarValue: float = 0.0
    ValueReference: int = 0


@dataclass
class FmuOutputVariableActuatorType:
    Name: str = ""
    RealVarValue: float = 0.0
    ValueReference: int = 0


@dataclass
class EplusInputVariableScheduleType:
    Name: str = ""
    VarIndex: int = 0
    InitialValue: Optional[float] = None


@dataclass
class EplusInputVariableVariableType:
    Name: str = ""
    VarIndex: int = 0


@dataclass
class EplusInputVariableActuatorType:
    Name: str = ""
    VarIndex: int = 0


@dataclass
class InstanceType:
    Name: str = ""
    modelID: str = ""
    modelGUID: str = ""
    WorkingFolder: Path = field(default_factory=Path)
    WorkingFolder_wLib: Path = field(default_factory=Path)
    fmiVersionNumber: str = ""
    NumInputVariablesInFMU: int = 0
    NumInputVariablesInIDF: int = 0
    NumOutputVariablesInFMU: int = 0
    NumOutputVariablesInIDF: int = 0
    NumOutputVariablesSchedule: int = 0
    NumOutputVariablesVariable: int = 0
    NumOutputVariablesActuator: int = 0
    LenModelID: int = 0
    LenModelGUID: int = 0
    LenWorkingFolder: int = 0
    LenWorkingFolder_wLib: int = 0
    fmicomponent: Optional[Any] = None
    fmistatus: int = 0
    Index: int = 0
    fmuInputVariable: List[FmuInputVariableType] = field(default_factory=list)
    checkfmuInputVariable: List[FmuInputVariableType] = field(default_factory=list)
    eplusOutputVariable: List[EplusOutputVariableType] = field(default_factory=list)
    fmuOutputVariableSchedule: List[FmuOutputVariableScheduleType] = field(default_factory=list)
    eplusInputVariableSchedule: List[EplusInputVariableScheduleType] = field(default_factory=list)
    fmuOutputVariableVariable: List[FmuOutputVariableVariableType] = field(default_factory=list)
    eplusInputVariableVariable: List[EplusInputVariableVariableType] = field(default_factory=list)
    fmuOutputVariableActuator: List[FmuOutputVariableActuatorType] = field(default_factory=list)
    eplusInputVariableActuator: List[EplusInputVariableActuatorType] = field(default_factory=list)


@dataclass
class FmuType:
    Name: str = ""
    TimeOut: float = 0.0
    Visible: int = 0
    Interactive: int = 0
    LoggingOn: int = 0
    NumInstances: int = 0
    TotNumInputVariablesInIDF: int = 0
    TotNumOutputVariablesSchedule: int = 0
    TotNumOutputVariablesVariable: int = 0
    TotNumOutputVariablesActuator: int = 0
    Instance: List[InstanceType] = field(default_factory=list)


@dataclass
class ExternalInterfaceData:
    tComm: float = 0.0
    tStop: float = 3600.0
    tStart: float = 0.0
    hStep: float = 15.0
    FlagReIni: bool = False
    FMURootWorkingFolder: Path = field(default_factory=Path)
    nInKeys: int = 3

    FMU: List[FmuType] = field(default_factory=list)
    FMUTemp: List[FmuType] = field(default_factory=list)
    checkInstanceName: List[CheckFmuInstanceNameType] = field(default_factory=list)

    NumExternalInterfaces: int = 0
    NumExternalInterfacesBCVTB: int = 0
    NumExternalInterfacesFMUImport: int = 0
    NumExternalInterfacesFMUExport: int = 0
    NumFMUObjects: int = 0
    FMUExportActivate: int = 0
    haveExternalInterfaceBCVTB: bool = False
    haveExternalInterfaceFMUImport: bool = False
    haveExternalInterfaceFMUExport: bool = False
    simulationStatus: int = 1

    keyVarIndexes: List[int] = field(default_factory=list)
    varTypes: List[Any] = field(default_factory=list)
    varInd: List[int] = field(default_factory=list)
    socketFD: int = -1
    ErrorsFound: bool = False
    noMoreValues: bool = False

    varKeys: List[str] = field(default_factory=list)
    varNames: List[str] = field(default_factory=list)
    inpVarTypes: List[int] = field(default_factory=list)
    inpVarNames: List[str] = field(default_factory=list)

    configuredControlPoints: bool = False
    useEMS: bool = False

    firstCall: bool = True
    showContinuationWithoutUpdate: bool = True
    GetInputFlag: bool = True
    InitExternalInterfacefirstCall: bool = True
    FirstCallGetSetDoStep: bool = True
    FirstCallIni: bool = True
    FirstCallDesignDays: bool = True
    FirstCallWUp: bool = True
    FirstCallTStep: bool = True
    fmiEndSimulation: int = 0

    socCfgFilPath: Path = field(default_factory=lambda: Path("socket.cfg"))
    UniqueFMUInputVarNames: Dict[str, str] = field(default_factory=dict)

    nOutVal: int = 0
    nInpVar: int = 0

    def clear_state(self):
        self.tComm = 0.0
        self.tStop = 3600.0
        self.tStart = 0.0
        self.hStep = 15.0
        self.FlagReIni = False
        self.FMURootWorkingFolder = Path()
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


def external_interface_exchange_variables(state: ExternalInterfaceData) -> None:
    if state.GetInputFlag:
        get_external_interface_input(state)
        state.GetInputFlag = False

    if state.haveExternalInterfaceBCVTB or state.haveExternalInterfaceFMUExport:
        init_external_interface(state)


def get_external_interface_input(state: ExternalInterfaceData) -> None:
    pass


def stop_external_interface_if_error(state: ExternalInterfaceData) -> None:
    pass


def close_socket(state: ExternalInterfaceData, flag_to_write_to_socket: int) -> None:
    pass


def parse_string(string: str, ele: List[str], n_ele: int) -> None:
    i_end = 0
    for i in range(n_ele):
        i_sta = i_end
        i_col = string.find(';', i_sta)
        if i_col != -1:
            i_end = i_col + 1
        else:
            i_end = len(string)
        if i < len(ele):
            ele[i] = string[i_sta:i_end - 1].upper()


def init_external_interface(state: ExternalInterfaceData) -> None:
    pass


def get_set_variables_and_do_step_fmu_import(state: ExternalInterfaceData) -> None:
    pass


def instantiate_initialize_fmu_import(state: ExternalInterfaceData) -> None:
    pass


def initialize_fmu(state: ExternalInterfaceData) -> None:
    pass


def terminate_reset_free_fmu_import(state: ExternalInterfaceData, fmi_end_simulation: int) -> None:
    pass


def init_external_interface_fmu_import(state: ExternalInterfaceData) -> None:
    pass


def trim(string: str) -> str:
    first = 0
    for i, c in enumerate(string):
        if c != ' ':
            first = i
            break
    last = len(string) - 1
    for i in range(len(string) - 1, -1, -1):
        if string[i] != ' ':
            last = i
            break
    if first <= last:
        return string[first:last + 1]
    return ""


def get_cur_sim_start_time_seconds(state: ExternalInterfaceData) -> float:
    simtime = 0.0

    month = 1
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


def calc_external_interface_fmu_import(state: ExternalInterfaceData) -> None:
    pass


def validate_run_control(state: ExternalInterfaceData) -> None:
    pass


def calc_external_interface(state: ExternalInterfaceData) -> None:
    pass


def get_report_variable_key(
    state: ExternalInterfaceData,
    var_keys: List[str],
    number_of_keys: int,
    var_names: List[str],
    key_var_indexes: List[int],
    var_types: List[Any]
) -> None:
    pass


def warn_if_external_interface_objects_are_used(state: ExternalInterfaceData, object_word: str) -> None:
    pass


def verify_external_interface_object(state: ExternalInterfaceData) -> None:
    pass


def get_char_array_from_string(original_string: str) -> List[int]:
    return [ord(c) for c in original_string]


def get_string_from_char_array(original_char_array: List[int]) -> str:
    return ''.join(chr(c) for c in original_char_array if c != 0)
