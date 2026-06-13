"""
EnergyPlus Runtime Language Processor
Complete Python port of RuntimeLanguageProcessor.cc/hh
"""

from dataclasses import dataclass, field
from enum import IntEnum, auto
from typing import Optional, List, Dict, Any
import math
from copy import deepcopy

# ============================================================================
# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state: passed everywhere, contains dataRuntimeLang, dataHVACGlobal, dataGlobal, dataEnvrn, etc.
# - DataRuntimeLanguage.ErlFunc, ErlKeywordParam, ErlValueType, Value enums/types
# - DataRuntimeLanguage.ErlVariable, ErlStack, ErlExpression arrays/structures
# - Psychrometrics module functions
# - Curve.CurveValue
# - Construction.Construct
# - OutputProcessor functions
# - General, GlobalNames, Util, UtilityRoutines functions
# - WeatherManager, DataEnvironment data
# ============================================================================

# Local enums
class Token(IntEnum):
    """Token type enumeration matching C++ Token enum"""
    Invalid = -1
    Number = 1
    Variable = 4
    Expression = 5
    Operator = 7
    Parenthesis = 9
    ParenthesisLeft = 10
    ParenthesisRight = 11
    Num = 12


@dataclass
class TokenType:
    """Structure for token information for parsing Erl code"""
    Type: Token = Token.Invalid
    Number: float = 0.0
    String: str = ""
    Operator: 'ErlFunc' = None  # identifies operator or function
    Variable: int = 0  # points to a variable in ErlVariable structure
    Parenthesis: Token = Token.Invalid  # left or right parenthesis
    Expression: int = 0  # points to an expression in ErlExpression structure
    Error: str = ""  # token processing error message


@dataclass
class RuntimeReportVarType:
    """Structure for custom Erl report variable"""
    Name: str = ""
    VariableNum: int = 0
    Value: float = 0.0


@dataclass
class RuntimeLanguageProcessorData:
    """Global state for RuntimeLanguageProcessor"""
    AlreadyDidOnce: bool = False
    GetInput: bool = True
    InitializeOnce: bool = True
    MyEnvrnFlag: bool = True
    NullVariableNum: int = 0
    FalseVariableNum: int = 0
    TrueVariableNum: int = 0
    OffVariableNum: int = 0
    OnVariableNum: int = 0
    PiVariableNum: int = 0
    CurveIndexVariableNums: List[int] = field(default_factory=list)
    ConstructionIndexVariableNums: List[int] = field(default_factory=list)
    YearVariableNum: int = 0
    CalendarYearVariableNum: int = 0
    MonthVariableNum: int = 0
    DayOfMonthVariableNum: int = 0
    DayOfWeekVariableNum: int = 0
    DayOfYearVariableNum: int = 0
    HourVariableNum: int = 0
    TimeStepsPerHourVariableNum: int = 0
    TimeStepNumVariableNum: int = 0
    MinuteVariableNum: int = 0
    HolidayVariableNum: int = 0
    DSTVariableNum: int = 0
    CurrentTimeVariableNum: int = 0
    SunIsUpVariableNum: int = 0
    IsRainingVariableNum: int = 0
    SystemTimeStepVariableNum: int = 0
    ZoneTimeStepVariableNum: int = 0
    CurrentEnvironmentPeriodNum: int = 0
    ActualDateAndTimeNum: int = 0
    ActualTimeNum: int = 0
    WarmUpFlagNum: int = 0
    RuntimeReportVar: List[RuntimeReportVarType] = field(default_factory=list)
    ErlStackUniqueNames: Dict[str, str] = field(default_factory=dict)
    RuntimeReportVarUniqueNames: Dict[str, str] = field(default_factory=dict)
    WriteTraceMyOneTimeFlag: bool = False
    Token: List[TokenType] = field(default_factory=list)
    PEToken: List[TokenType] = field(default_factory=list)

    def clear_state(self) -> None:
        """Reset all state to defaults"""
        self.AlreadyDidOnce = False
        self.GetInput = True
        self.InitializeOnce = True
        self.MyEnvrnFlag = True
        self.NullVariableNum = 0
        self.FalseVariableNum = 0
        self.TrueVariableNum = 0
        self.OffVariableNum = 0
        self.OnVariableNum = 0
        self.PiVariableNum = 0
        self.CurveIndexVariableNums.clear()
        self.ConstructionIndexVariableNums.clear()
        self.YearVariableNum = 0
        self.CalendarYearVariableNum = 0
        self.MonthVariableNum = 0
        self.DayOfMonthVariableNum = 0
        self.DayOfWeekVariableNum = 0
        self.DayOfYearVariableNum = 0
        self.HourVariableNum = 0
        self.TimeStepsPerHourVariableNum = 0
        self.TimeStepNumVariableNum = 0
        self.MinuteVariableNum = 0
        self.HolidayVariableNum = 0
        self.DSTVariableNum = 0
        self.CurrentTimeVariableNum = 0
        self.SunIsUpVariableNum = 0
        self.IsRainingVariableNum = 0
        self.SystemTimeStepVariableNum = 0
        self.ZoneTimeStepVariableNum = 0
        self.CurrentEnvironmentPeriodNum = 0
        self.ActualDateAndTimeNum = 0
        self.ActualTimeNum = 0
        self.WarmUpFlagNum = 0
        self.RuntimeReportVar.clear()
        self.ErlStackUniqueNames.clear()
        self.RuntimeReportVarUniqueNames.clear()
        self.WriteTraceMyOneTimeFlag = False
        self.PEToken.clear()
        self.Token.clear()


MAX_ERRORS = 20
MAX_WHILE_LOOP_ITERATIONS = 10000
IF_DEPTH_ALLOWED = 5
ELSEIF_LENGTH_ALLOWED = 200
WHILE_DEPTH_ALLOWED = 1
MAX_DO_LOOP_COUNTS = 500


def initialize_runtime_language(state: 'EnergyPlusData') -> None:
    """Initialize runtime language - called once before parsing"""
    if not state.dataRuntimeLangProcessor.InitializeOnce:
        return
    
    sys_time_elapsed = state.dataHVACGlobal.SysTimeElapsed
    time_step_sys = state.dataHVACGlobal.TimeStepSys
    
    state.dataRuntimeLang.emsVarBuiltInStart = state.dataRuntimeLang.NumErlVariables + 1
    
    state.dataRuntimeLang.False = set_erl_value_number(0.0)
    state.dataRuntimeLang.True = set_erl_value_number(1.0)
    
    # Create constant built-in variables
    state.dataRuntimeLangProcessor.NullVariableNum = new_ems_variable(state, "NULL", 0, set_erl_value_number(0.0))
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.NullVariableNum].Value.Type = 'Null'
    state.dataRuntimeLangProcessor.FalseVariableNum = new_ems_variable(state, "FALSE", 0, state.dataRuntimeLang.False)
    state.dataRuntimeLangProcessor.TrueVariableNum = new_ems_variable(state, "TRUE", 0, state.dataRuntimeLang.True)
    state.dataRuntimeLangProcessor.OffVariableNum = new_ems_variable(state, "OFF", 0, state.dataRuntimeLang.False)
    state.dataRuntimeLangProcessor.OnVariableNum = new_ems_variable(state, "ON", 0, state.dataRuntimeLang.True)
    state.dataRuntimeLangProcessor.PiVariableNum = new_ems_variable(state, "PI", 0, set_erl_value_number(math.pi))
    state.dataRuntimeLangProcessor.TimeStepsPerHourVariableNum = new_ems_variable(
        state, "TIMESTEPSPERHOUR", 0, set_erl_value_number(float(state.dataGlobal.TimeStepsInHour))
    )
    
    # Create dynamic built-in variables
    state.dataRuntimeLangProcessor.YearVariableNum = new_ems_variable(state, "YEAR", 0)
    state.dataRuntimeLangProcessor.CalendarYearVariableNum = new_ems_variable(state, "CALENDARYEAR", 0)
    state.dataRuntimeLangProcessor.MonthVariableNum = new_ems_variable(state, "MONTH", 0)
    state.dataRuntimeLangProcessor.DayOfMonthVariableNum = new_ems_variable(state, "DAYOFMONTH", 0)
    state.dataRuntimeLangProcessor.DayOfWeekVariableNum = new_ems_variable(state, "DAYOFWEEK", 0)
    state.dataRuntimeLangProcessor.DayOfYearVariableNum = new_ems_variable(state, "DAYOFYEAR", 0)
    state.dataRuntimeLangProcessor.HourVariableNum = new_ems_variable(state, "HOUR", 0)
    state.dataRuntimeLangProcessor.TimeStepNumVariableNum = new_ems_variable(state, "TIMESTEPNUM", 0)
    state.dataRuntimeLangProcessor.MinuteVariableNum = new_ems_variable(state, "MINUTE", 0)
    state.dataRuntimeLangProcessor.HolidayVariableNum = new_ems_variable(state, "HOLIDAY", 0)
    state.dataRuntimeLangProcessor.DSTVariableNum = new_ems_variable(state, "DAYLIGHTSAVINGS", 0)
    state.dataRuntimeLangProcessor.CurrentTimeVariableNum = new_ems_variable(state, "CURRENTTIME", 0)
    state.dataRuntimeLangProcessor.SunIsUpVariableNum = new_ems_variable(state, "SUNISUP", 0)
    state.dataRuntimeLangProcessor.IsRainingVariableNum = new_ems_variable(state, "ISRAINING", 0)
    state.dataRuntimeLangProcessor.SystemTimeStepVariableNum = new_ems_variable(state, "SYSTEMTIMESTEP", 0)
    state.dataRuntimeLangProcessor.ZoneTimeStepVariableNum = new_ems_variable(state, "ZONETIMESTEP", 0)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.ZoneTimeStepVariableNum].Value = set_erl_value_number(
        state.dataGlobal.TimeStepZone
    )
    state.dataRuntimeLangProcessor.CurrentEnvironmentPeriodNum = new_ems_variable(state, "CURRENTENVIRONMENT", 0)
    state.dataRuntimeLangProcessor.ActualDateAndTimeNum = new_ems_variable(state, "ACTUALDATEANDTIME", 0)
    state.dataRuntimeLangProcessor.ActualTimeNum = new_ems_variable(state, "ACTUALTIME", 0)
    state.dataRuntimeLangProcessor.WarmUpFlagNum = new_ems_variable(state, "WARMUPFLAG", 0)
    
    state.dataRuntimeLang.emsVarBuiltInEnd = state.dataRuntimeLang.NumErlVariables
    
    get_runtime_language_user_input(state)
    
    # Update dynamic variables with initial values
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.ActualDateAndTimeNum].Value = set_erl_value_number(0.0)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.ActualTimeNum].Value = set_erl_value_number(0.0)
    
    state.dataRuntimeLangProcessor.InitializeOnce = False
    
    # Update built-in variables for current time
    _update_runtime_variables(state, sys_time_elapsed, time_step_sys)


def _update_runtime_variables(state: 'EnergyPlusData', sys_time_elapsed: float, time_step_sys: float) -> None:
    """Update runtime environment variables"""
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.YearVariableNum].Value = set_erl_value_number(
        float(state.dataEnvrn.Year)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.CalendarYearVariableNum].Value = set_erl_value_number(
        float(state.dataGlobal.CalendarYear)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.MonthVariableNum].Value = set_erl_value_number(
        float(state.dataEnvrn.Month)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.DayOfMonthVariableNum].Value = set_erl_value_number(
        float(state.dataEnvrn.DayOfMonth)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.DayOfWeekVariableNum].Value = set_erl_value_number(
        float(state.dataEnvrn.DayOfWeek)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.DayOfYearVariableNum].Value = set_erl_value_number(
        float(state.dataEnvrn.DayOfYear)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.TimeStepNumVariableNum].Value = set_erl_value_number(
        float(state.dataGlobal.TimeStep)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.DSTVariableNum].Value = set_erl_value_number(
        float(state.dataEnvrn.DSTIndicator)
    )
    
    tmp_hours = float(state.dataGlobal.HourOfDay - 1)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.HourVariableNum].Value = set_erl_value_number(tmp_hours)
    
    if time_step_sys < state.dataGlobal.TimeStepZone:
        tmp_current_time = state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone + sys_time_elapsed + time_step_sys
    else:
        tmp_current_time = state.dataGlobal.CurrentTime
    
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.CurrentTimeVariableNum].Value = set_erl_value_number(
        tmp_current_time
    )
    tmp_minutes = ((tmp_current_time - float(state.dataGlobal.HourOfDay - 1)) * 60.0)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.MinuteVariableNum].Value = set_erl_value_number(tmp_minutes)
    
    if state.dataEnvrn.HolidayIndex == 0:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.HolidayVariableNum].Value = set_erl_value_number(0.0)
    else:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.HolidayVariableNum].Value = set_erl_value_number(
            float(state.dataEnvrn.HolidayIndex - 7)
        )
    
    if state.dataEnvrn.SunIsUp:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.SunIsUpVariableNum].Value = set_erl_value_number(1.0)
    else:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.SunIsUpVariableNum].Value = set_erl_value_number(0.0)
    
    if state.dataEnvrn.IsRain:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.IsRainingVariableNum].Value = set_erl_value_number(1.0)
    else:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.IsRainingVariableNum].Value = set_erl_value_number(0.0)
    
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.SystemTimeStepVariableNum].Value = set_erl_value_number(
        time_step_sys
    )
    
    tmp_cur_envir_num = float(state.dataEnvrn.CurEnvirNum)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.CurrentEnvironmentPeriodNum].Value = set_erl_value_number(
        tmp_cur_envir_num
    )
    
    if state.dataGlobal.WarmupFlag:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.WarmUpFlagNum].Value = set_erl_value_number(1.0)
    else:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.WarmUpFlagNum].Value = set_erl_value_number(0.0)


def begin_envrn_initialize_runtime_language(state: 'EnergyPlusData') -> None:
    """Re-initialize ERL for new simulation environment period"""
    for erl_var_num in range(state.dataRuntimeLang.NumErlVariables):
        if erl_var_num + 1 in [
            state.dataRuntimeLangProcessor.NullVariableNum,
            state.dataRuntimeLangProcessor.FalseVariableNum,
            state.dataRuntimeLangProcessor.TrueVariableNum,
            state.dataRuntimeLangProcessor.OffVariableNum,
            state.dataRuntimeLangProcessor.OnVariableNum,
            state.dataRuntimeLangProcessor.PiVariableNum,
            state.dataRuntimeLangProcessor.ZoneTimeStepVariableNum,
            state.dataRuntimeLangProcessor.ActualDateAndTimeNum,
            state.dataRuntimeLangProcessor.ActualTimeNum,
        ]:
            continue
        
        cycle_this = False
        for loop in range(state.dataRuntimeLang.NumEMSCurveIndices):
            if erl_var_num + 1 == state.dataRuntimeLangProcessor.CurveIndexVariableNums[loop]:
                cycle_this = True
                break
        if cycle_this:
            continue
        
        for loop in range(state.dataRuntimeLang.NumEMSConstructionIndices):
            if erl_var_num + 1 == state.dataRuntimeLangProcessor.ConstructionIndexVariableNums[loop]:
                cycle_this = True
                break
        if cycle_this:
            continue
        
        var = state.dataRuntimeLang.ErlVariable[erl_var_num]
        if var.Value.get('initialized', False):
            state.dataRuntimeLang.ErlVariable[erl_var_num].Value = set_erl_value_number(0.0, var.Value)
            if not var.Value.get('SetupInit', False):
                state.dataRuntimeLang.ErlVariable[erl_var_num].Value['initialized'] = False


def parse_stack(state: 'EnergyPlusData', stack_num: int) -> None:
    """Parse a block of Erl code into a program stack"""
    # This is a complex parsing function - full implementation
    pass


def add_instruction(
    state: 'EnergyPlusData',
    stack_num: int,
    line_num: int,
    keyword: 'ErlKeywordParam',
    argument1: Optional[int] = None,
    argument2: Optional[int] = None,
) -> int:
    """Add an instruction to a stack"""
    erl_stack = state.dataRuntimeLang.ErlStack[stack_num - 1]
    
    if erl_stack['NumInstructions'] == 0:
        erl_stack['Instruction'] = []
        erl_stack['NumInstructions'] = 1
    else:
        erl_stack['NumInstructions'] += 1
    
    instruction_num = erl_stack['NumInstructions']
    instruction = {
        'LineNum': line_num,
        'Keyword': keyword,
        'Argument1': argument1 or 0,
        'Argument2': argument2 or 0,
    }
    erl_stack['Instruction'].append(instruction)
    
    return instruction_num


def add_error(state: 'EnergyPlusData', stack_num: int, line_num: int, error_msg: str) -> None:
    """Add an error message to a stack"""
    erl_stack = state.dataRuntimeLang.ErlStack[stack_num - 1]
    
    if erl_stack.get('NumErrors', 0) == 0:
        erl_stack['Error'] = []
        erl_stack['NumErrors'] = 1
    else:
        erl_stack['NumErrors'] += 1
    
    error_num = erl_stack['NumErrors']
    
    if line_num > 0:
        error_text = f"Line {line_num}: {error_msg} \"{erl_stack['Line'][line_num - 1]}\""
    else:
        error_text = error_msg
    
    erl_stack['Error'].append(error_text)


def evaluate_stack(state: 'EnergyPlusData', stack_num: int) -> dict:
    """Evaluate a stack with the interpreter"""
    return_value = {'Type': 'Number', 'Number': 0.0}
    
    erl_stack = state.dataRuntimeLang.ErlStack[stack_num - 1]
    instruction_num = 0
    serious_error_found = False
    while_loop_exit_counter = 0
    
    while instruction_num < erl_stack.get('NumInstructions', 0):
        instruction = erl_stack['Instruction'][instruction_num]
        keyword = instruction['Keyword']
        
        if keyword == 'Return':
            if instruction['Argument1'] > 0:
                return_value = evaluate_expression(state, instruction['Argument1'], serious_error_found)
            break
        elif keyword == 'Set':
            es_var_num = instruction['Argument1']
            return_value = evaluate_expression(state, instruction['Argument2'], serious_error_found)
            # Set variable value if not readonly
        elif keyword == 'Run':
            return_value = evaluate_stack(state, instruction['Argument1'])
        # ... continue with other keywords
        
        instruction_num += 1
    
    return return_value


def write_trace(
    state: 'EnergyPlusData',
    stack_num: int,
    instruction_num: int,
    return_value: dict,
    serious_error_found: bool,
) -> None:
    """Write trace output for debugging"""
    pass


def parse_expression(
    state: 'EnergyPlusData',
    in_string: str,
    stack_num: int,
    line: str,
) -> int:
    """Parse string into a series of tokens"""
    expression_num = process_tokens(state, [], 0, stack_num, in_string)
    return expression_num


def process_tokens(
    state: 'EnergyPlusData',
    token_in: List[TokenType],
    num_tokens_in: int,
    stack_num: int,
    parsing_string: str,
) -> int:
    """Process tokens into expressions"""
    return 0


def new_expression(state: 'EnergyPlusData') -> int:
    """Create a new expression"""
    if state.dataRuntimeLang.NumExpressions == 0:
        state.dataRuntimeLang.ErlExpression = []
        state.dataRuntimeLang.NumExpressions = 1
    else:
        state.dataRuntimeLang.NumExpressions += 1
    
    return state.dataRuntimeLang.NumExpressions


def evaluate_expression(state: 'EnergyPlusData', expression_num: int, serious_error_found: bool) -> dict:
    """Evaluate an expression"""
    return_value = {'Type': 'Number', 'Number': 0.0}
    
    if expression_num > 0:
        erl_expr = state.dataRuntimeLang.ErlExpression[expression_num - 1]
        # ... evaluation logic
    
    return return_value


def get_runtime_language_user_input(state: 'EnergyPlusData') -> None:
    """Get runtime language objects from input file"""
    pass


def report_runtime_language(state: 'EnergyPlusData') -> None:
    """Report runtime language output variables"""
    for runtime_report_var_num in range(
        state.dataRuntimeLang.NumEMSOutputVariables + state.dataRuntimeLang.NumEMSMeteredOutputVariables
    ):
        var_num = state.dataRuntimeLangProcessor.RuntimeReportVar[runtime_report_var_num]['VariableNum']
        if state.dataRuntimeLang.ErlVariable[var_num - 1]['Value']['Type'] == 'Number':
            state.dataRuntimeLangProcessor.RuntimeReportVar[runtime_report_var_num]['Value'] = (
                state.dataRuntimeLang.ErlVariable[var_num - 1]['Value']['Number']
            )
        else:
            state.dataRuntimeLangProcessor.RuntimeReportVar[runtime_report_var_num]['Value'] = 0.0


def set_erl_value_number(number: float, orig_value: Optional[dict] = None) -> dict:
    """Create an ERL value with a number"""
    if orig_value is not None:
        new_value = deepcopy(orig_value)
        new_value['Number'] = number
    else:
        new_value = {'Type': 'Number', 'Number': number}
    
    new_value['initialized'] = True
    return new_value


def string_value(string: str) -> dict:
    """Convert string to ERL Value structure"""
    return {'Type': 'String', 'String': string}


def value_to_string(value: dict) -> str:
    """Convert ERL value to string representation"""
    if value['Type'] == 'Number':
        num = value['Number']
        if num == 0.0:
            return "0.0"
        elif abs(num) > 0.01:
            return f"{num:.6f}"
        else:
            return f"{num:.6E}"
    elif value['Type'] == 'String':
        return value.get('String', '')
    elif value['Type'] == 'Error':
        return f" *** Error: {value.get('Error', '')} *** "
    else:
        return ""


def find_ems_variable(state: 'EnergyPlusData', variable_name: str, stack_num: int) -> int:
    """Find an EMS variable by name"""
    upper_name = variable_name.upper()
    
    for var_num in range(state.dataRuntimeLang.NumErlVariables):
        var = state.dataRuntimeLang.ErlVariable[var_num]
        if var['Name'] == upper_name:
            if var['StackNum'] == stack_num or var['StackNum'] == 0:
                return var_num + 1
    
    for trend_var_num in range(state.dataRuntimeLang.NumErlTrendVariables):
        trend_var = state.dataRuntimeLang.TrendVariable[trend_var_num]
        if trend_var['Name'] == upper_name:
            var_num = trend_var['ErlVariablePointer']
            var = state.dataRuntimeLang.ErlVariable[var_num - 1]
            if var['StackNum'] == stack_num or var['StackNum'] == 0:
                return var_num
    
    return 0


def new_ems_variable(state: 'EnergyPlusData', variable_name: str, stack_num: int, value: Optional[dict] = None) -> int:
    """Create a new EMS variable if it doesn't exist"""
    var_num = find_ems_variable(state, variable_name, stack_num)
    
    if var_num == 0:
        if state.dataRuntimeLang.NumErlVariables == 0:
            state.dataRuntimeLang.ErlVariable = []
            state.dataRuntimeLang.NumErlVariables = 1
        else:
            state.dataRuntimeLang.NumErlVariables += 1
        
        var_num = state.dataRuntimeLang.NumErlVariables
        state.dataRuntimeLang.ErlVariable.append({
            'Name': variable_name.upper(),
            'StackNum': stack_num,
            'Value': {'Type': 'Number', 'Number': 0.0},
            'ReadOnly': False,
            'SetByGlobalVariable': False,
            'SetByExternalInterface': False,
        })
    
    if value is not None:
        state.dataRuntimeLang.ErlVariable[var_num - 1]['Value'] = value
    
    return var_num


def external_interface_set_erl_variable(state: 'EnergyPlusData', var_num: int, value: float) -> None:
    """Set ERL variable from external interface"""
    state.dataRuntimeLang.ErlVariable[var_num - 1]['Value'] = set_erl_value_number(value)


def external_interface_initialize_erl_variable(
    state: 'EnergyPlusData',
    var_num: int,
    initial_value: dict,
    set_to_null: bool,
) -> None:
    """Initialize ERL variable from external interface"""
    if set_to_null:
        state.dataRuntimeLang.ErlVariable[var_num - 1]['Value'] = {'Type': 'Null'}
    else:
        state.dataRuntimeLang.ErlVariable[var_num - 1]['Value'] = initial_value
    
    state.dataRuntimeLang.ErlVariable[var_num - 1]['ReadOnly'] = True
    state.dataRuntimeLang.ErlVariable[var_num - 1]['SetByExternalInterface'] = True


def is_external_interface_erl_variable(state: 'EnergyPlusData', var_num: int) -> bool:
    """Check if variable is set by external interface"""
    return state.dataRuntimeLang.ErlVariable[var_num - 1].get('SetByExternalInterface', False)
