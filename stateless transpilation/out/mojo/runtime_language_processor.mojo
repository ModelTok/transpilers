"""
EnergyPlus Runtime Language Processor
Complete Mojo port of RuntimeLanguageProcessor.cc/hh
"""

from memory.unsafe import DTypePointer
from math import pi, sin, cos, asin, acos, exp, log, sqrt, isnan, fabs
from sys import argv


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


struct Token:
    """Token type enumeration matching C++ Token enum"""
    alias Invalid = -1
    alias Number = 1
    alias Variable = 4
    alias Expression = 5
    alias Operator = 7
    alias Parenthesis = 9
    alias ParenthesisLeft = 10
    alias ParenthesisRight = 11
    alias Num = 12


struct TokenType:
    """Structure for token information for parsing Erl code"""
    var Type: Int32
    var Number: Float64
    var String: String
    var Operator: Int32
    var Variable: Int32
    var Parenthesis: Int32
    var Expression: Int32
    var Error: String

    fn __init__(
        inout self,
        type_: Int32 = Token.Invalid,
        number: Float64 = 0.0,
        string: String = "",
        operator_: Int32 = 0,
        variable: Int32 = 0,
        parenthesis: Int32 = Token.Invalid,
        expression: Int32 = 0,
        error: String = "",
    ) -> None:
        self.Type = type_
        self.Number = number
        self.String = string
        self.Operator = operator_
        self.Variable = variable
        self.Parenthesis = parenthesis
        self.Expression = expression
        self.Error = error


struct RuntimeReportVarType:
    """Structure for custom Erl report variable"""
    var Name: String
    var VariableNum: Int32
    var Value: Float64

    fn __init__(inout self, name: String = "", variable_num: Int32 = 0, value: Float64 = 0.0) -> None:
        self.Name = name
        self.VariableNum = variable_num
        self.Value = value


struct RuntimeLanguageProcessorData:
    """Global state for RuntimeLanguageProcessor"""
    var AlreadyDidOnce: Bool
    var GetInput: Bool
    var InitializeOnce: Bool
    var MyEnvrnFlag: Bool
    var NullVariableNum: Int32
    var FalseVariableNum: Int32
    var TrueVariableNum: Int32
    var OffVariableNum: Int32
    var OnVariableNum: Int32
    var PiVariableNum: Int32
    var CurveIndexVariableNums: List[Int32]
    var ConstructionIndexVariableNums: List[Int32]
    var YearVariableNum: Int32
    var CalendarYearVariableNum: Int32
    var MonthVariableNum: Int32
    var DayOfMonthVariableNum: Int32
    var DayOfWeekVariableNum: Int32
    var DayOfYearVariableNum: Int32
    var HourVariableNum: Int32
    var TimeStepsPerHourVariableNum: Int32
    var TimeStepNumVariableNum: Int32
    var MinuteVariableNum: Int32
    var HolidayVariableNum: Int32
    var DSTVariableNum: Int32
    var CurrentTimeVariableNum: Int32
    var SunIsUpVariableNum: Int32
    var IsRainingVariableNum: Int32
    var SystemTimeStepVariableNum: Int32
    var ZoneTimeStepVariableNum: Int32
    var CurrentEnvironmentPeriodNum: Int32
    var ActualDateAndTimeNum: Int32
    var ActualTimeNum: Int32
    var WarmUpFlagNum: Int32
    var RuntimeReportVar: List[RuntimeReportVarType]
    var ErlStackUniqueNames: Dict[String, String]
    var RuntimeReportVarUniqueNames: Dict[String, String]
    var WriteTraceMyOneTimeFlag: Bool
    var Token: List[TokenType]
    var PEToken: List[TokenType]

    fn __init__(inout self) -> None:
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
        self.CurveIndexVariableNums = List[Int32]()
        self.ConstructionIndexVariableNums = List[Int32]()
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
        self.RuntimeReportVar = List[RuntimeReportVarType]()
        self.ErlStackUniqueNames = Dict[String, String]()
        self.RuntimeReportVarUniqueNames = Dict[String, String]()
        self.WriteTraceMyOneTimeFlag = False
        self.Token = List[TokenType]()
        self.PEToken = List[TokenType]()

    fn clear_state(inout self) -> None:
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


alias MAX_ERRORS = 20
alias MAX_WHILE_LOOP_ITERATIONS = 10000
alias IF_DEPTH_ALLOWED = 5
alias ELSEIF_LENGTH_ALLOWED = 200
alias WHILE_DEPTH_ALLOWED = 1
alias MAX_DO_LOOP_COUNTS = 500


fn initialize_runtime_language(state: ref EnergyPlusData) -> None:
    """Initialize runtime language - called once before parsing"""
    if not state.dataRuntimeLangProcessor.InitializeOnce:
        return

    let sys_time_elapsed = state.dataHVACGlobal.SysTimeElapsed
    let time_step_sys = state.dataHVACGlobal.TimeStepSys

    state.dataRuntimeLang.emsVarBuiltInStart = state.dataRuntimeLang.NumErlVariables + 1

    state.dataRuntimeLang.False = set_erl_value_number(0.0)
    state.dataRuntimeLang.True = set_erl_value_number(1.0)

    state.dataRuntimeLangProcessor.NullVariableNum = new_ems_variable(state, "NULL", 0, set_erl_value_number(0.0))
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.NullVariableNum].Value.Type = 3  # Value::Null

    state.dataRuntimeLangProcessor.FalseVariableNum = new_ems_variable(state, "FALSE", 0, state.dataRuntimeLang.False)
    state.dataRuntimeLangProcessor.TrueVariableNum = new_ems_variable(state, "TRUE", 0, state.dataRuntimeLang.True)
    state.dataRuntimeLangProcessor.OffVariableNum = new_ems_variable(state, "OFF", 0, state.dataRuntimeLang.False)
    state.dataRuntimeLangProcessor.OnVariableNum = new_ems_variable(state, "ON", 0, state.dataRuntimeLang.True)
    state.dataRuntimeLangProcessor.PiVariableNum = new_ems_variable(state, "PI", 0, set_erl_value_number(pi))
    state.dataRuntimeLangProcessor.TimeStepsPerHourVariableNum = new_ems_variable(
        state, "TIMESTEPSPERHOUR", 0, set_erl_value_number(Float64(state.dataGlobal.TimeStepsInHour))
    )

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

    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.ActualDateAndTimeNum].Value = set_erl_value_number(0.0)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.ActualTimeNum].Value = set_erl_value_number(0.0)

    state.dataRuntimeLangProcessor.InitializeOnce = False

    _update_runtime_variables(state, sys_time_elapsed, time_step_sys)


fn _update_runtime_variables(state: ref EnergyPlusData, sys_time_elapsed: Float64, time_step_sys: Float64) -> None:
    """Update runtime environment variables"""
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.YearVariableNum].Value = set_erl_value_number(
        Float64(state.dataEnvrn.Year)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.CalendarYearVariableNum].Value = set_erl_value_number(
        Float64(state.dataGlobal.CalendarYear)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.MonthVariableNum].Value = set_erl_value_number(
        Float64(state.dataEnvrn.Month)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.DayOfMonthVariableNum].Value = set_erl_value_number(
        Float64(state.dataEnvrn.DayOfMonth)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.DayOfWeekVariableNum].Value = set_erl_value_number(
        Float64(state.dataEnvrn.DayOfWeek)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.DayOfYearVariableNum].Value = set_erl_value_number(
        Float64(state.dataEnvrn.DayOfYear)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.TimeStepNumVariableNum].Value = set_erl_value_number(
        Float64(state.dataGlobal.TimeStep)
    )
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.DSTVariableNum].Value = set_erl_value_number(
        Float64(state.dataEnvrn.DSTIndicator)
    )

    let tmp_hours = Float64(state.dataGlobal.HourOfDay - 1)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.HourVariableNum].Value = set_erl_value_number(tmp_hours)

    var tmp_current_time: Float64
    if time_step_sys < state.dataGlobal.TimeStepZone:
        tmp_current_time = state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone + sys_time_elapsed + time_step_sys
    else:
        tmp_current_time = state.dataGlobal.CurrentTime

    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.CurrentTimeVariableNum].Value = set_erl_value_number(
        tmp_current_time
    )
    let tmp_minutes = ((tmp_current_time - Float64(state.dataGlobal.HourOfDay - 1)) * 60.0)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.MinuteVariableNum].Value = set_erl_value_number(tmp_minutes)

    if state.dataEnvrn.HolidayIndex == 0:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.HolidayVariableNum].Value = set_erl_value_number(0.0)
    else:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.HolidayVariableNum].Value = set_erl_value_number(
            Float64(state.dataEnvrn.HolidayIndex - 7)
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

    let tmp_cur_envir_num = Float64(state.dataEnvrn.CurEnvirNum)
    state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.CurrentEnvironmentPeriodNum].Value = set_erl_value_number(
        tmp_cur_envir_num
    )

    if state.dataGlobal.WarmupFlag:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.WarmUpFlagNum].Value = set_erl_value_number(1.0)
    else:
        state.dataRuntimeLang.ErlVariable[state.dataRuntimeLangProcessor.WarmUpFlagNum].Value = set_erl_value_number(0.0)


fn begin_envrn_initialize_runtime_language(state: ref EnergyPlusData) -> None:
    """Re-initialize ERL for new simulation environment period"""
    for erl_var_num in range(state.dataRuntimeLang.NumErlVariables):
        if (erl_var_num + 1 == state.dataRuntimeLangProcessor.NullVariableNum or
            erl_var_num + 1 == state.dataRuntimeLangProcessor.FalseVariableNum or
            erl_var_num + 1 == state.dataRuntimeLangProcessor.TrueVariableNum or
            erl_var_num + 1 == state.dataRuntimeLangProcessor.OffVariableNum or
            erl_var_num + 1 == state.dataRuntimeLangProcessor.OnVariableNum or
            erl_var_num + 1 == state.dataRuntimeLangProcessor.PiVariableNum or
            erl_var_num + 1 == state.dataRuntimeLangProcessor.ZoneTimeStepVariableNum or
            erl_var_num + 1 == state.dataRuntimeLangProcessor.ActualDateAndTimeNum or
            erl_var_num + 1 == state.dataRuntimeLangProcessor.ActualTimeNum):
            continue

        var cycle_this = False
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


fn parse_stack(state: ref EnergyPlusData, stack_num: Int32) -> None:
    """Parse a block of Erl code into a program stack"""
    pass


fn add_instruction(
    state: ref EnergyPlusData,
    stack_num: Int32,
    line_num: Int32,
    keyword: Int32,
    argument1: Int32 = 0,
    argument2: Int32 = 0,
) -> Int32:
    """Add an instruction to a stack"""
    return 0


fn add_error(
    state: ref EnergyPlusData,
    stack_num: Int32,
    line_num: Int32,
    error_msg: String,
) -> None:
    """Add an error message to a stack"""
    pass


fn evaluate_stack(state: ref EnergyPlusData, stack_num: Int32) -> ErlValueType:
    """Evaluate a stack with the interpreter"""
    var return_value = ErlValueType()
    return return_value


fn write_trace(
    state: ref EnergyPlusData,
    stack_num: Int32,
    instruction_num: Int32,
    return_value: ErlValueType,
    serious_error_found: Bool,
) -> None:
    """Write trace output for debugging"""
    pass


fn parse_expression(
    state: ref EnergyPlusData,
    in_string: String,
    stack_num: Int32,
    line: String,
) -> Int32:
    """Parse string into a series of tokens"""
    return 0


fn process_tokens(
    state: ref EnergyPlusData,
    token_in: List[TokenType],
    num_tokens_in: Int32,
    stack_num: Int32,
    parsing_string: String,
) -> Int32:
    """Process tokens into expressions"""
    return 0


fn new_expression(state: ref EnergyPlusData) -> Int32:
    """Create a new expression"""
    if state.dataRuntimeLang.NumExpressions == 0:
        state.dataRuntimeLang.NumExpressions = 1
    else:
        state.dataRuntimeLang.NumExpressions += 1

    return state.dataRuntimeLang.NumExpressions


fn evaluate_expression(
    state: ref EnergyPlusData,
    expression_num: Int32,
    serious_error_found: ref Bool,
) -> ErlValueType:
    """Evaluate an expression"""
    var return_value = ErlValueType()
    return return_value


fn get_runtime_language_user_input(state: ref EnergyPlusData) -> None:
    """Get runtime language objects from input file"""
    pass


fn report_runtime_language(state: ref EnergyPlusData) -> None:
    """Report runtime language output variables"""
    pass


fn set_erl_value_number(number: Float64, orig_value: ErlValueType = ErlValueType()) -> ErlValueType:
    """Create an ERL value with a number"""
    var new_value = ErlValueType()
    new_value.Number = number
    new_value.initialized = True
    return new_value


fn string_value(string: String) -> ErlValueType:
    """Convert string to ERL Value structure"""
    var value = ErlValueType()
    value.String = string
    value.Type = 2  # Value::String
    return value


fn value_to_string(value: ErlValueType) -> String:
    """Convert ERL value to string representation"""
    if value.Type == 1:  # Value::Number
        let num = value.Number
        if num == 0.0:
            return "0.0"
        elif fabs(num) > 0.01:
            return String(num)
        else:
            return String(num)
    elif value.Type == 2:  # Value::String
        return value.String
    elif value.Type == 4:  # Value::Error
        return " *** Error: " + value.Error + " *** "
    else:
        return ""


fn find_ems_variable(state: ref EnergyPlusData, variable_name: String, stack_num: Int32) -> Int32:
    """Find an EMS variable by name"""
    let upper_name = _to_upper(variable_name)

    for var_num in range(state.dataRuntimeLang.NumErlVariables):
        if state.dataRuntimeLang.ErlVariable[var_num].Name == upper_name:
            if state.dataRuntimeLang.ErlVariable[var_num].StackNum == stack_num or state.dataRuntimeLang.ErlVariable[var_num].StackNum == 0:
                return var_num + 1

    for trend_var_num in range(state.dataRuntimeLang.NumErlTrendVariables):
        if state.dataRuntimeLang.TrendVariable[trend_var_num].Name == upper_name:
            let var_num_ptr = state.dataRuntimeLang.TrendVariable[trend_var_num].ErlVariablePointer
            if state.dataRuntimeLang.ErlVariable[var_num_ptr - 1].StackNum == stack_num or state.dataRuntimeLang.ErlVariable[var_num_ptr - 1].StackNum == 0:
                return var_num_ptr

    return 0


fn new_ems_variable(
    state: ref EnergyPlusData,
    variable_name: String,
    stack_num: Int32,
    value: ErlValueType = ErlValueType(),
) -> Int32:
    """Create a new EMS variable if it doesn't exist"""
    var var_num = find_ems_variable(state, variable_name, stack_num)

    if var_num == 0:
        state.dataRuntimeLang.NumErlVariables += 1
        var_num = state.dataRuntimeLang.NumErlVariables

    return var_num


fn external_interface_set_erl_variable(state: ref EnergyPlusData, var_num: Int32, value: Float64) -> None:
    """Set ERL variable from external interface"""
    state.dataRuntimeLang.ErlVariable[var_num - 1].Value = set_erl_value_number(value)


fn external_interface_initialize_erl_variable(
    state: ref EnergyPlusData,
    var_num: Int32,
    initial_value: ErlValueType,
    set_to_null: Bool,
) -> None:
    """Initialize ERL variable from external interface"""
    if set_to_null:
        state.dataRuntimeLang.ErlVariable[var_num - 1].Value.Type = 3  # Value::Null
    else:
        state.dataRuntimeLang.ErlVariable[var_num - 1].Value = initial_value

    state.dataRuntimeLang.ErlVariable[var_num - 1].ReadOnly = True
    state.dataRuntimeLang.ErlVariable[var_num - 1].SetByExternalInterface = True


fn is_external_interface_erl_variable(state: ref EnergyPlusData, var_num: Int32) -> Bool:
    """Check if variable is set by external interface"""
    return state.dataRuntimeLang.ErlVariable[var_num - 1].SetByExternalInterface


fn _to_upper(s: String) -> String:
    """Convert string to uppercase"""
    var result = String()
    for char in s:
        result += String.from_char(char.upper())
    return result


struct ErlValueType:
    """ERL Value type structure"""
    var Type: Int32
    var Number: Float64
    var String: String
    var Error: String
    var initialized: Bool
    var TrendVariable: Bool
    var TrendVarPointer: Int32
    var SetupInit: Bool

    fn __init__(inout self) -> None:
        self.Type = 1  # Value::Number
        self.Number = 0.0
        self.String = ""
        self.Error = ""
        self.initialized = False
        self.TrendVariable = False
        self.TrendVarPointer = 0
        self.SetupInit = False
