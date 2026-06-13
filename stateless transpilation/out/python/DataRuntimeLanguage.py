# EXTERNAL DEPS (to wire in glue):
# - OutputProcessor.VariableType (enum from EnergyPlus.OutputProcessor)
# - EMSManager.EMSCallFrom (enum from EnergyPlus.EMSManager)
# - Schedule (class from EnergyPlus.ScheduleManager)
# - BaseGlobalStruct (base class from EnergyPlus.Data.BaseData)
# - has(s: str, substring: str) -> bool (from EnergyPlus.UtilityRoutines)
# - is_any_of(char: str, chars: str) -> bool (from EnergyPlus.UtilityRoutines)
# - ShowSevereError(state: EnergyPlusData, msg: str) (from EnergyPlus.UtilityRoutines)
# - ShowContinueError(state: EnergyPlusData, msg: str) (from EnergyPlus.UtilityRoutines)

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Tuple, Any, Protocol
from abc import ABC

class ErlKeywordParam(IntEnum):
    Invalid = -1
    None_ = 0
    Return = 1
    Goto = 2
    Set = 3
    Run = 4
    If = 5
    ElseIf = 6
    Else = 7
    EndIf = 8
    While = 9
    EndWhile = 10
    Num = 11

class Value(IntEnum):
    Invalid = -1
    Null = 0
    Number = 1
    String = 2
    Array = 3
    Variable = 4
    Expression = 5
    Trend = 6
    Error = 7
    Num = 8

class PtrDataType(IntEnum):
    Invalid = -1
    Real = 0
    Integer = 1
    Logical = 2
    Num = 3

class ErlFunc(IntEnum):
    Invalid = -1
    Null = 0
    Literal = 1
    Negative = 2
    Divide = 3
    Multiply = 4
    Subtract = 5
    Add = 6
    Equal = 7
    NotEqual = 8
    LessOrEqual = 9
    GreaterOrEqual = 10
    LessThan = 11
    GreaterThan = 12
    RaiseToPower = 13
    LogicalAND = 14
    LogicalOR = 15
    Round = 16
    Mod = 17
    Sin = 18
    Cos = 19
    ArcSin = 20
    ArcCos = 21
    DegToRad = 22
    RadToDeg = 23
    Exp = 24
    Ln = 25
    Max = 26
    Min = 27
    ABS = 28
    RandU = 29
    RandG = 30
    RandSeed = 31
    RhoAirFnPbTdbW = 32
    CpAirFnW = 33
    HfgAirFnWTdb = 34
    HgAirFnWTdb = 35
    TdpFnTdbTwbPb = 36
    TdpFnWPb = 37
    HFnTdbW = 38
    HFnTdbRhPb = 39
    TdbFnHW = 40
    RhovFnTdbRh = 41
    RhovFnTdbRhLBnd0C = 42
    RhovFnTdbWPb = 43
    RhFnTdbRhov = 44
    RhFnTdbRhovLBnd0C = 45
    RhFnTdbWPb = 46
    TwbFnTdbWPb = 47
    VFnTdbWPb = 48
    WFnTdpPb = 49
    WFnTdbH = 50
    WFnTdbTwbPb = 51
    WFnTdbRhPb = 52
    PsatFnTemp = 53
    TsatFnHPb = 54
    TsatFnPb = 55
    CpCW = 56
    CpHW = 57
    RhoH2O = 58
    FatalHaltEp = 59
    SevereWarnEp = 60
    WarnEp = 61
    TrendValue = 62
    TrendAverage = 63
    TrendMax = 64
    TrendMin = 65
    TrendDirection = 66
    TrendSum = 67
    CurveValue = 68
    TodayIsRain = 69
    TodayIsSnow = 70
    TodayOutDryBulbTemp = 71
    TodayOutDewPointTemp = 72
    TodayOutBaroPress = 73
    TodayOutRelHum = 74
    TodayWindSpeed = 75
    TodayWindDir = 76
    TodaySkyTemp = 77
    TodayHorizIRSky = 78
    TodayBeamSolarRad = 79
    TodayDifSolarRad = 80
    TodayAlbedo = 81
    TodayLiquidPrecip = 82
    TomorrowIsRain = 83
    TomorrowIsSnow = 84
    TomorrowOutDryBulbTemp = 85
    TomorrowOutDewPointTemp = 86
    TomorrowOutBaroPress = 87
    TomorrowOutRelHum = 88
    TomorrowWindSpeed = 89
    TomorrowWindDir = 90
    TomorrowSkyTemp = 91
    TomorrowHorizIRSky = 92
    TomorrowBeamSolarRad = 93
    TomorrowDifSolarRad = 94
    TomorrowAlbedo = 95
    TomorrowLiquidPrecip = 96
    Num = 97

NUM_POSSIBLE_OPERATORS = 96
MAX_WHILE_LOOP_ITERATIONS = 1000000

ERL_FUNC_NAMES_UC = [
    "",
    "",
    "-",
    "/",
    "*",
    "-",
    "+",
    "==",
    "<>",
    "<=",
    ">=",
    "<",
    ">",
    "^",
    "&&",
    "||",
    "@ROUND",
    "@MOD",
    "@SIN",
    "@COS",
    "@ARCSIN",
    "@ARCCOS",
    "@DEGTORAD",
    "@RADTODEG",
    "@EXP",
    "@LN",
    "@MAX",
    "@MIN",
    "@ABS",
    "@RANDOMUNIFORMU",
    "@RANDOMGAUSSIAN",
    "@SEEDRANDOM",
    "@RHOAIRFNPBTDBW",
    "@CPAIRFNW",
    "@HFGAIRFNWTDB",
    "@HGAIRFNWTDB",
    "@TDPFNTDBTWBPB",
    "@TDPFNWPB",
    "@HFNTDBW",
    "@HFNTDBRHPB",
    "@TDBFNHW",
    "@RHOVFNTDBRH",
    "@RHOVFNTDBRHLBND0C",
    "@RHOVFNTDBWPB",
    "@RHFNTDBRHOV",
    "@RHFNTDBRHOVBND0C",
    "@RHFNTDBWPB",
    "@TWBFNTDBWPB",
    "@VFNTDBWPB",
    "@WFNTDPPB",
    "@WFNTDBH",
    "@WFNTDBTWBPB",
    "@WFNTDBRHPB",
    "@PSATFNTEMP",
    "@TSATFNHPB",
    "@TSATFNPB",
    "@CPCW",
    "@CPHW",
    "@RHOH2O",
    "@FATALHALTEP",
    "@SEVEREWARNEP",
    "@WARNEP",
    "@TRENDVALUE",
    "@TRENDAVERAGE",
    "@TRENDMAX",
    "@TRENDMIN",
    "@TRENDDIRECTION",
    "@TRENDSUM",
    "@CURVEVALUE",
    "@TODAYISRAIN",
    "@TODAYISSNOW",
    "@TODAYOUTDRYBULBTEMP",
    "@TODAYOUTDEWPOINTTEMP",
    "@TODAYOUTBAROPRESS",
    "@TODAYOUTRELHUM",
    "@TODAYWINDSPEED",
    "@TODAYWINDDIR",
    "@TODAYSKYTEMP",
    "@TODAYHORIZRSKY",
    "@TODAYBEAMSOLARRAD",
    "@TODAYDIFSOLARRAD",
    "@TODAYALBEDO",
    "@TODAYLIQUIDPRECIP",
    "@TOMORROWISRAIN",
    "@TOMORROWISSNOW",
    "@TOMORROWOUTDRYBULBTEMP",
    "@TOMORROWOUTDEWPOINTTEMP",
    "@TOMORROWOUTBAROPRESS",
    "@TOMORROWOUTRELHUM",
    "@TOMORROWWINDSPEED",
    "@TOMORROWWINDDIR",
    "@TOMORROWSKYTEMP",
    "@TOMORROWHORIZRSKY",
    "@TOMORROWBEAMSOLARRAD",
    "@TOMORROWDIFSOLARRAD",
    "@TOMORROWALBEDO",
    "@TOMORROWLIQUIDPRECIP",
]

ERL_FUNC_NUM_OPERANDS = [
    0, 1, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 2, 4, 1,
    3, 1, 2, 2, 3, 2, 2, 3, 2, 2, 2, 3, 2, 2, 3, 3,
    3, 2, 2, 3, 4, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 2,
    2, 2, 2, 2, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2,
]

@dataclass
class OutputVarSensorType:
    Name: str = ""
    UniqueKeyName: str = ""
    OutputVarName: str = ""
    CheckedOkay: bool = False
    VariableType: Any = None
    Index: int = 0
    VariableNum: int = 0
    sched: Optional[Any] = None

@dataclass
class InternalVarsAvailableType:
    DataTypeName: str = ""
    UniqueIDName: str = ""
    Units: str = ""
    PntrVarTypeUsed: PtrDataType = PtrDataType.Invalid
    RealValue: Optional[float] = None
    IntValue: Optional[int] = None

@dataclass
class InternalVarsUsedType:
    Name: str = ""
    InternalDataTypeName: str = ""
    UniqueIDName: str = ""
    CheckedOkay: bool = False
    ErlVariableNum: int = 0
    InternVarNum: int = 0

@dataclass
class EMSActuatorAvailableType:
    ComponentTypeName: str = ""
    UniqueIDName: str = ""
    ControlTypeName: str = ""
    Units: str = ""
    handleCount: int = 0
    PntrVarTypeUsed: PtrDataType = PtrDataType.Invalid
    Actuated: Optional[bool] = None
    RealValue: Optional[float] = None
    IntValue: Optional[int] = None
    LogValue: Optional[bool] = None

@dataclass
class ActuatorUsedType:
    Name: str = ""
    ComponentTypeName: str = ""
    UniqueIDName: str = ""
    ControlTypeName: str = ""
    CheckedOkay: bool = False
    ErlVariableNum: int = 0
    ActuatorVariableNum: int = 0
    wasActuated: bool = False

@dataclass
class EMSProgramCallManagementType:
    Name: str = ""
    CallingPoint: Any = None
    NumErlPrograms: int = 0
    ErlProgramARR: List[int] = field(default_factory=list)

@dataclass
class ErlValueType:
    Type: Value = Value.Null
    Number: float = 0.0
    String: str = ""
    Variable: int = 0
    Expression: int = 0
    TrendVariable: bool = False
    TrendVarPointer: int = 0
    Error: str = ""
    initialized: bool = False
    SetupInit: bool = True

@dataclass
class ErlVariableType:
    Name: str = ""
    StackNum: int = 0
    Value: ErlValueType = field(default_factory=ErlValueType)
    ReadOnly: bool = False
    SetByExternalInterface: bool = False
    SetByGlobalVariable: bool = False
    SetByInternalVariable: bool = False

@dataclass
class InstructionType:
    LineNum: int = 0
    Keyword: ErlKeywordParam = ErlKeywordParam.None_
    Argument1: int = 0
    Argument2: int = 0

@dataclass
class ErlStackType:
    Name: str = ""
    NumLines: int = 0
    Line: List[str] = field(default_factory=list)
    NumInstructions: int = 0
    Instruction: List[InstructionType] = field(default_factory=list)
    NumErrors: int = 0
    Error: List[str] = field(default_factory=list)

@dataclass
class ErlExpressionType:
    Operator: ErlFunc = ErlFunc.Invalid
    NumOperands: int = 0
    Operand: List[ErlValueType] = field(default_factory=list)

@dataclass
class Operator:
    symbol: str = ""
    numOperands: int = 0

@dataclass
class TrendVariableType:
    Name: str = ""
    ErlVariablePointer: int = 0
    LogDepth: int = 0
    TrendValARR: List[float] = field(default_factory=list)
    tempTrendARR: List[float] = field(default_factory=list)
    TimeARR: List[float] = field(default_factory=list)

class BaseGlobalStruct(ABC):
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        pass

@dataclass
class RuntimeLanguageData(BaseGlobalStruct):
    emsVarBuiltInStart: int = 0
    emsVarBuiltInEnd: int = 0
    NumProgramCallManagers: int = 0
    NumSensors: int = 0
    numActuatorsUsed: int = 0
    numEMSActuatorsAvailable: int = 0
    maxEMSActuatorsAvailable: int = 0
    NumInternalVariablesUsed: int = 0
    numEMSInternalVarsAvailable: int = 0
    maxEMSInternalVarsAvailable: int = 0
    varsAvailableAllocInc: int = 1000
    NumErlPrograms: int = 0
    NumErlSubroutines: int = 0
    NumUserGlobalVariables: int = 0
    NumErlVariables: int = 0
    NumErlStacks: int = 0
    NumExpressions: int = 0
    NumEMSOutputVariables: int = 0
    NumEMSMeteredOutputVariables: int = 0
    NumErlTrendVariables: int = 0
    NumEMSCurveIndices: int = 0
    NumEMSConstructionIndices: int = 0
    NumExternalInterfaceGlobalVariables: int = 0
    NumExternalInterfaceFunctionalMockupUnitImportGlobalVariables: int = 0
    NumExternalInterfaceFunctionalMockupUnitExportGlobalVariables: int = 0
    NumExternalInterfaceActuatorsUsed: int = 0
    NumExternalInterfaceFunctionalMockupUnitImportActuatorsUsed: int = 0
    NumExternalInterfaceFunctionalMockupUnitExportActuatorsUsed: int = 0
    OutputEDDFile: bool = False
    OutputFullEMSTrace: bool = False
    OutputEMSErrors: bool = False
    OutputEMSActuatorAvailFull: bool = False
    OutputEMSActuatorAvailSmall: bool = False
    OutputEMSInternalVarsFull: bool = False
    OutputEMSInternalVarsSmall: bool = False
    EMSConstructActuatorChecked: List[List[bool]] = field(default_factory=list)
    EMSConstructActuatorIsOkay: List[List[bool]] = field(default_factory=list)
    ErlVariable: List[ErlVariableType] = field(default_factory=list)
    ErlStack: List[ErlStackType] = field(default_factory=list)
    ErlExpression: List[ErlExpressionType] = field(default_factory=list)
    TrendVariable: List[TrendVariableType] = field(default_factory=list)
    Sensor: List[OutputVarSensorType] = field(default_factory=list)
    EMSActuatorAvailable: List[EMSActuatorAvailableType] = field(default_factory=list)
    EMSActuatorUsed: List[ActuatorUsedType] = field(default_factory=list)
    EMSInternalVarsAvailable: List[InternalVarsAvailableType] = field(default_factory=list)
    EMSInternalVarsUsed: List[InternalVarsUsedType] = field(default_factory=list)
    EMSProgramCallManager: List[EMSProgramCallManagementType] = field(default_factory=list)
    Null: ErlValueType = field(default_factory=lambda: ErlValueType(
        Type=Value.Null, Number=0.0, String="", Variable=0, Expression=0,
        TrendVariable=False, TrendVarPointer=0, Error="", initialized=True, SetupInit=True))
    False: ErlValueType = field(default_factory=lambda: ErlValueType(
        Type=Value.Null, Number=0.0, String="", Variable=0, Expression=0,
        TrendVariable=False, TrendVarPointer=0, Error="", initialized=True, SetupInit=True))
    True: ErlValueType = field(default_factory=lambda: ErlValueType(
        Type=Value.Null, Number=0.0, String="", Variable=0, Expression=0,
        TrendVariable=False, TrendVarPointer=0, Error="", initialized=True, SetupInit=True))
    EMSActuatorAvailableMap: Dict[Tuple[str, str, str], int] = field(default_factory=dict)
    
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        self.NumProgramCallManagers = 0
        self.NumSensors = 0
        self.numActuatorsUsed = 0
        self.numEMSActuatorsAvailable = 0
        self.maxEMSActuatorsAvailable = 0
        self.NumInternalVariablesUsed = 0
        self.numEMSInternalVarsAvailable = 0
        self.maxEMSInternalVarsAvailable = 0
        self.varsAvailableAllocInc = 1000
        self.NumErlPrograms = 0
        self.NumErlSubroutines = 0
        self.NumUserGlobalVariables = 0
        self.NumErlVariables = 0
        self.NumErlStacks = 0
        self.NumExpressions = 0
        self.NumEMSOutputVariables = 0
        self.NumEMSMeteredOutputVariables = 0
        self.NumErlTrendVariables = 0
        self.NumEMSCurveIndices = 0
        self.NumEMSConstructionIndices = 0
        self.NumExternalInterfaceGlobalVariables = 0
        self.NumExternalInterfaceFunctionalMockupUnitImportGlobalVariables = 0
        self.NumExternalInterfaceFunctionalMockupUnitExportGlobalVariables = 0
        self.NumExternalInterfaceActuatorsUsed = 0
        self.NumExternalInterfaceFunctionalMockupUnitImportActuatorsUsed = 0
        self.NumExternalInterfaceFunctionalMockupUnitExportActuatorsUsed = 0
        self.OutputEDDFile = False
        self.OutputFullEMSTrace = False
        self.OutputEMSErrors = False
        self.OutputEMSActuatorAvailFull = False
        self.OutputEMSActuatorAvailSmall = False
        self.OutputEMSInternalVarsFull = False
        self.OutputEMSInternalVarsSmall = False
        self.EMSConstructActuatorChecked.clear()
        self.EMSConstructActuatorIsOkay.clear()
        self.ErlVariable.clear()
        self.ErlStack.clear()
        self.ErlExpression.clear()
        self.TrendVariable.clear()
        self.Sensor.clear()
        self.EMSActuatorAvailable.clear()
        self.EMSActuatorUsed.clear()
        self.EMSInternalVarsAvailable.clear()
        self.EMSInternalVarsUsed.clear()
        self.EMSProgramCallManager.clear()
        self.Null = ErlValueType(
            Type=Value.Null, Number=0.0, String="", Variable=0, Expression=0,
            TrendVariable=False, TrendVarPointer=0, Error="", initialized=True, SetupInit=True)
        self.False = ErlValueType(
            Type=Value.Null, Number=0.0, String="", Variable=0, Expression=0,
            TrendVariable=False, TrendVarPointer=0, Error="", initialized=True, SetupInit=True)
        self.True = ErlValueType(
            Type=Value.Null, Number=0.0, String="", Variable=0, Expression=0,
            TrendVariable=False, TrendVarPointer=0, Error="", initialized=True, SetupInit=True)
        self.EMSActuatorAvailableMap.clear()

def validate_ems_variable_name(
    state: Any,
    c_module_object: str,
    c_field_value: str,
    c_field_name: str,
) -> Tuple[bool, bool]:
    err_flag = False
    errors_found = False
    
    invalid_start_characters = "0123456789"
    
    if has(c_field_value, ' '):
        ShowSevereError(state, f"{c_module_object}=\"{c_field_value}\", Invalid variable name entered.")
        ShowContinueError(state, f"...{c_field_name}; Names used as EMS variables cannot contain spaces")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, '-'):
        ShowSevereError(state, f"{c_module_object}=\"{c_field_value}\", Invalid variable name entered.")
        ShowContinueError(state, f"...{c_field_name}; Names used as EMS variables cannot contain \"-\" characters.")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, '+'):
        ShowSevereError(state, f"{c_module_object}=\"{c_field_value}\", Invalid variable name entered.")
        ShowContinueError(state, f"...{c_field_name}; Names used as EMS variables cannot contain \"+\" characters.")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, '.'):
        ShowSevereError(state, f"{c_module_object}=\"{c_field_value}\", Invalid variable name entered.")
        ShowContinueError(state, f"...{c_field_name}; Names used as EMS variables cannot contain \".\" characters.")
        err_flag = True
        errors_found = True
    
    if c_field_value and is_any_of(c_field_value[0], invalid_start_characters):
        ShowSevereError(state, f"{c_module_object}=\"{c_field_value}\", Invalid variable name entered.")
        ShowContinueError(state, f"...{c_field_name}; Names used as EMS variables cannot start with numeric characters.")
        err_flag = True
        errors_found = True
    
    return err_flag, errors_found

def validate_ems_program_name(
    state: Any,
    c_module_object: str,
    c_field_value: str,
    c_field_name: str,
    c_sub_type: str,
) -> Tuple[bool, bool]:
    err_flag = False
    errors_found = False
    
    if has(c_field_value, ' '):
        ShowSevereError(state, f"{c_module_object}=\"{c_field_value}\", Invalid variable name entered.")
        ShowContinueError(state, f"...{c_field_name}; Names used for EMS {c_sub_type} cannot contain spaces")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, '-'):
        ShowSevereError(state, f"{c_module_object}=\"{c_field_value}\", Invalid variable name entered.")
        ShowContinueError(state, f"...{c_field_name}; Names used for EMS {c_sub_type} cannot contain \"-\" characters.")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, '+'):
        ShowSevereError(state, f"{c_module_object}=\"{c_field_value}\", Invalid variable name entered.")
        ShowContinueError(state, f"...{c_field_name}; Names used for EMS {c_sub_type} cannot contain \"+\" characters.")
        err_flag = True
        errors_found = True
    
    return err_flag, errors_found

def has(s: str, substring: str) -> bool:
    return substring in s

def is_any_of(char: str, chars: str) -> bool:
    return char in chars

def ShowSevereError(state: Any, msg: str) -> None:
    pass

def ShowContinueError(state: Any, msg: str) -> None:
    pass
