# EXTERNAL DEPS (to wire in glue):
# - OutputProcessor.VariableType (enum from EnergyPlus.OutputProcessor)
# - EMSManager.EMSCallFrom (enum from EnergyPlus.EMSManager)
# - Schedule (struct from EnergyPlus.ScheduleManager)
# - BaseGlobalStruct (trait/base from EnergyPlus.Data.BaseData)
# - has(s: String, substring: String) -> Bool (from EnergyPlus.UtilityRoutines)
# - is_any_of(char: String, chars: String) -> Bool (from EnergyPlus.UtilityRoutines)
# - ShowSevereError(state: EnergyPlusData, msg: String) (from EnergyPlus.UtilityRoutines)
# - ShowContinueError(state: EnergyPlusData, msg: String) (from EnergyPlus.UtilityRoutines)

from memory import UnsafePointer

alias ERL_KEYWORD_PARAM_INVALID = -1
alias ERL_KEYWORD_PARAM_NONE = 0
alias ERL_KEYWORD_PARAM_RETURN = 1
alias ERL_KEYWORD_PARAM_GOTO = 2
alias ERL_KEYWORD_PARAM_SET = 3
alias ERL_KEYWORD_PARAM_RUN = 4
alias ERL_KEYWORD_PARAM_IF = 5
alias ERL_KEYWORD_PARAM_ELSEIF = 6
alias ERL_KEYWORD_PARAM_ELSE = 7
alias ERL_KEYWORD_PARAM_ENDIF = 8
alias ERL_KEYWORD_PARAM_WHILE = 9
alias ERL_KEYWORD_PARAM_ENDWHILE = 10
alias ERL_KEYWORD_PARAM_NUM = 11

alias VALUE_INVALID = -1
alias VALUE_NULL = 0
alias VALUE_NUMBER = 1
alias VALUE_STRING = 2
alias VALUE_ARRAY = 3
alias VALUE_VARIABLE = 4
alias VALUE_EXPRESSION = 5
alias VALUE_TREND = 6
alias VALUE_ERROR = 7
alias VALUE_NUM = 8

alias PTR_DATA_TYPE_INVALID = -1
alias PTR_DATA_TYPE_REAL = 0
alias PTR_DATA_TYPE_INTEGER = 1
alias PTR_DATA_TYPE_LOGICAL = 2
alias PTR_DATA_TYPE_NUM = 3

alias ERL_FUNC_INVALID = -1
alias ERL_FUNC_NULL = 0
alias ERL_FUNC_LITERAL = 1
alias ERL_FUNC_NEGATIVE = 2
alias ERL_FUNC_DIVIDE = 3
alias ERL_FUNC_MULTIPLY = 4
alias ERL_FUNC_SUBTRACT = 5
alias ERL_FUNC_ADD = 6
alias ERL_FUNC_EQUAL = 7
alias ERL_FUNC_NOT_EQUAL = 8
alias ERL_FUNC_LESS_OR_EQUAL = 9
alias ERL_FUNC_GREATER_OR_EQUAL = 10
alias ERL_FUNC_LESS_THAN = 11
alias ERL_FUNC_GREATER_THAN = 12
alias ERL_FUNC_RAISE_TO_POWER = 13
alias ERL_FUNC_LOGICAL_AND = 14
alias ERL_FUNC_LOGICAL_OR = 15
alias ERL_FUNC_ROUND = 16
alias ERL_FUNC_MOD = 17
alias ERL_FUNC_SIN = 18
alias ERL_FUNC_COS = 19
alias ERL_FUNC_ARC_SIN = 20
alias ERL_FUNC_ARC_COS = 21
alias ERL_FUNC_DEG_TO_RAD = 22
alias ERL_FUNC_RAD_TO_DEG = 23
alias ERL_FUNC_EXP = 24
alias ERL_FUNC_LN = 25
alias ERL_FUNC_MAX = 26
alias ERL_FUNC_MIN = 27
alias ERL_FUNC_ABS = 28
alias ERL_FUNC_RAND_U = 29
alias ERL_FUNC_RAND_G = 30
alias ERL_FUNC_RAND_SEED = 31
alias ERL_FUNC_RHO_AIR_FN_PB_TDBW = 32
alias ERL_FUNC_CP_AIR_FN_W = 33
alias ERL_FUNC_HFG_AIR_FN_W_TDB = 34
alias ERL_FUNC_HG_AIR_FN_W_TDB = 35
alias ERL_FUNC_TDP_FN_TDB_TWB_PB = 36
alias ERL_FUNC_TDP_FN_W_PB = 37
alias ERL_FUNC_H_FN_TDB_W = 38
alias ERL_FUNC_H_FN_TDB_RH_PB = 39
alias ERL_FUNC_TDB_FN_H_W = 40
alias ERL_FUNC_RHOV_FN_TDB_RH = 41
alias ERL_FUNC_RHOV_FN_TDB_RH_LBND0C = 42
alias ERL_FUNC_RHOV_FN_TDB_W_PB = 43
alias ERL_FUNC_RH_FN_TDB_RHOV = 44
alias ERL_FUNC_RH_FN_TDB_RHOV_LBND0C = 45
alias ERL_FUNC_RH_FN_TDB_W_PB = 46
alias ERL_FUNC_TWB_FN_TDB_W_PB = 47
alias ERL_FUNC_V_FN_TDB_W_PB = 48
alias ERL_FUNC_W_FN_TDP_PB = 49
alias ERL_FUNC_W_FN_TDB_H = 50
alias ERL_FUNC_W_FN_TDB_TWB_PB = 51
alias ERL_FUNC_W_FN_TDB_RH_PB = 52
alias ERL_FUNC_PSAT_FN_TEMP = 53
alias ERL_FUNC_TSAT_FN_H_PB = 54
alias ERL_FUNC_TSAT_FN_PB = 55
alias ERL_FUNC_CP_CW = 56
alias ERL_FUNC_CP_HW = 57
alias ERL_FUNC_RHO_H2O = 58
alias ERL_FUNC_FATAL_HALT_EP = 59
alias ERL_FUNC_SEVERE_WARN_EP = 60
alias ERL_FUNC_WARN_EP = 61
alias ERL_FUNC_TREND_VALUE = 62
alias ERL_FUNC_TREND_AVERAGE = 63
alias ERL_FUNC_TREND_MAX = 64
alias ERL_FUNC_TREND_MIN = 65
alias ERL_FUNC_TREND_DIRECTION = 66
alias ERL_FUNC_TREND_SUM = 67
alias ERL_FUNC_CURVE_VALUE = 68
alias ERL_FUNC_TODAY_IS_RAIN = 69
alias ERL_FUNC_TODAY_IS_SNOW = 70
alias ERL_FUNC_TODAY_OUT_DRY_BULB_TEMP = 71
alias ERL_FUNC_TODAY_OUT_DEW_POINT_TEMP = 72
alias ERL_FUNC_TODAY_OUT_BARO_PRESS = 73
alias ERL_FUNC_TODAY_OUT_REL_HUM = 74
alias ERL_FUNC_TODAY_WIND_SPEED = 75
alias ERL_FUNC_TODAY_WIND_DIR = 76
alias ERL_FUNC_TODAY_SKY_TEMP = 77
alias ERL_FUNC_TODAY_HORIZ_IR_SKY = 78
alias ERL_FUNC_TODAY_BEAM_SOLAR_RAD = 79
alias ERL_FUNC_TODAY_DIF_SOLAR_RAD = 80
alias ERL_FUNC_TODAY_ALBEDO = 81
alias ERL_FUNC_TODAY_LIQUID_PRECIP = 82
alias ERL_FUNC_TOMORROW_IS_RAIN = 83
alias ERL_FUNC_TOMORROW_IS_SNOW = 84
alias ERL_FUNC_TOMORROW_OUT_DRY_BULB_TEMP = 85
alias ERL_FUNC_TOMORROW_OUT_DEW_POINT_TEMP = 86
alias ERL_FUNC_TOMORROW_OUT_BARO_PRESS = 87
alias ERL_FUNC_TOMORROW_OUT_REL_HUM = 88
alias ERL_FUNC_TOMORROW_WIND_SPEED = 89
alias ERL_FUNC_TOMORROW_WIND_DIR = 90
alias ERL_FUNC_TOMORROW_SKY_TEMP = 91
alias ERL_FUNC_TOMORROW_HORIZ_IR_SKY = 92
alias ERL_FUNC_TOMORROW_BEAM_SOLAR_RAD = 93
alias ERL_FUNC_TOMORROW_DIF_SOLAR_RAD = 94
alias ERL_FUNC_TOMORROW_ALBEDO = 95
alias ERL_FUNC_TOMORROW_LIQUID_PRECIP = 96
alias ERL_FUNC_NUM = 97

alias NUM_POSSIBLE_OPERATORS = 96
alias MAX_WHILE_LOOP_ITERATIONS = 1000000

fn get_erl_func_names_uc() -> InlineArray[StringLiteral, 97]:
    return InlineArray[StringLiteral, 97](
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
    )

fn get_erl_func_num_operands() -> InlineArray[Int32, 97]:
    return InlineArray[Int32, 97](
        0, 1, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 2, 4, 1,
        3, 1, 2, 2, 3, 2, 2, 3, 2, 2, 2, 3, 2, 2, 3, 3,
        3, 2, 2, 3, 4, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 2,
        2, 2, 2, 2, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2,
    )

struct OutputVarSensorType:
    var name: String
    var unique_key_name: String
    var output_var_name: String
    var checked_okay: Bool
    var variable_type: Int32
    var index: Int32
    var variable_num: Int32
    var sched: UnsafePointer[UInt8]
    
    fn __init__(
        inout self,
        name: String = "",
        unique_key_name: String = "",
        output_var_name: String = "",
        checked_okay: Bool = False,
        variable_type: Int32 = -1,
        index: Int32 = 0,
        variable_num: Int32 = 0,
        sched: UnsafePointer[UInt8] = UnsafePointer[UInt8](),
    ):
        self.name = name
        self.unique_key_name = unique_key_name
        self.output_var_name = output_var_name
        self.checked_okay = checked_okay
        self.variable_type = variable_type
        self.index = index
        self.variable_num = variable_num
        self.sched = sched

struct InternalVarsAvailableType:
    var data_type_name: String
    var unique_id_name: String
    var units: String
    var pntr_var_type_used: Int32
    var real_value: UnsafePointer[Float64]
    var int_value: UnsafePointer[Int32]
    
    fn __init__(
        inout self,
        data_type_name: String = "",
        unique_id_name: String = "",
        units: String = "",
        pntr_var_type_used: Int32 = PTR_DATA_TYPE_INVALID,
        real_value: UnsafePointer[Float64] = UnsafePointer[Float64](),
        int_value: UnsafePointer[Int32] = UnsafePointer[Int32](),
    ):
        self.data_type_name = data_type_name
        self.unique_id_name = unique_id_name
        self.units = units
        self.pntr_var_type_used = pntr_var_type_used
        self.real_value = real_value
        self.int_value = int_value

struct InternalVarsUsedType:
    var name: String
    var internal_data_type_name: String
    var unique_id_name: String
    var checked_okay: Bool
    var erl_variable_num: Int32
    var intern_var_num: Int32
    
    fn __init__(
        inout self,
        name: String = "",
        internal_data_type_name: String = "",
        unique_id_name: String = "",
        checked_okay: Bool = False,
        erl_variable_num: Int32 = 0,
        intern_var_num: Int32 = 0,
    ):
        self.name = name
        self.internal_data_type_name = internal_data_type_name
        self.unique_id_name = unique_id_name
        self.checked_okay = checked_okay
        self.erl_variable_num = erl_variable_num
        self.intern_var_num = intern_var_num

struct EMSActuatorAvailableType:
    var component_type_name: String
    var unique_id_name: String
    var control_type_name: String
    var units: String
    var handle_count: Int32
    var pntr_var_type_used: Int32
    var actuated: UnsafePointer[Bool]
    var real_value: UnsafePointer[Float64]
    var int_value: UnsafePointer[Int32]
    var log_value: UnsafePointer[Bool]
    
    fn __init__(
        inout self,
        component_type_name: String = "",
        unique_id_name: String = "",
        control_type_name: String = "",
        units: String = "",
        handle_count: Int32 = 0,
        pntr_var_type_used: Int32 = PTR_DATA_TYPE_INVALID,
        actuated: UnsafePointer[Bool] = UnsafePointer[Bool](),
        real_value: UnsafePointer[Float64] = UnsafePointer[Float64](),
        int_value: UnsafePointer[Int32] = UnsafePointer[Int32](),
        log_value: UnsafePointer[Bool] = UnsafePointer[Bool](),
    ):
        self.component_type_name = component_type_name
        self.unique_id_name = unique_id_name
        self.control_type_name = control_type_name
        self.units = units
        self.handle_count = handle_count
        self.pntr_var_type_used = pntr_var_type_used
        self.actuated = actuated
        self.real_value = real_value
        self.int_value = int_value
        self.log_value = log_value

struct ActuatorUsedType:
    var name: String
    var component_type_name: String
    var unique_id_name: String
    var control_type_name: String
    var checked_okay: Bool
    var erl_variable_num: Int32
    var actuator_variable_num: Int32
    var was_actuated: Bool
    
    fn __init__(
        inout self,
        name: String = "",
        component_type_name: String = "",
        unique_id_name: String = "",
        control_type_name: String = "",
        checked_okay: Bool = False,
        erl_variable_num: Int32 = 0,
        actuator_variable_num: Int32 = 0,
        was_actuated: Bool = False,
    ):
        self.name = name
        self.component_type_name = component_type_name
        self.unique_id_name = unique_id_name
        self.control_type_name = control_type_name
        self.checked_okay = checked_okay
        self.erl_variable_num = erl_variable_num
        self.actuator_variable_num = actuator_variable_num
        self.was_actuated = was_actuated

struct EMSProgramCallManagementType:
    var name: String
    var calling_point: Int32
    var num_erl_programs: Int32
    var erl_program_arr: List[Int32]
    
    fn __init__(
        inout self,
        name: String = "",
        calling_point: Int32 = -1,
        num_erl_programs: Int32 = 0,
    ):
        self.name = name
        self.calling_point = calling_point
        self.num_erl_programs = num_erl_programs
        self.erl_program_arr = List[Int32]()

struct ErlValueType:
    var type: Int32
    var number: Float64
    var string: String
    var variable: Int32
    var expression: Int32
    var trend_variable: Bool
    var trend_var_pointer: Int32
    var error: String
    var initialized: Bool
    var setup_init: Bool
    
    fn __init__(
        inout self,
        type: Int32 = VALUE_NULL,
        number: Float64 = 0.0,
        string: String = "",
        variable: Int32 = 0,
        expression: Int32 = 0,
        trend_variable: Bool = False,
        trend_var_pointer: Int32 = 0,
        error: String = "",
        initialized: Bool = False,
        setup_init: Bool = True,
    ):
        self.type = type
        self.number = number
        self.string = string
        self.variable = variable
        self.expression = expression
        self.trend_variable = trend_variable
        self.trend_var_pointer = trend_var_pointer
        self.error = error
        self.initialized = initialized
        self.setup_init = setup_init

struct ErlVariableType:
    var name: String
    var stack_num: Int32
    var value: ErlValueType
    var read_only: Bool
    var set_by_external_interface: Bool
    var set_by_global_variable: Bool
    var set_by_internal_variable: Bool
    
    fn __init__(inout self):
        self.name = ""
        self.stack_num = 0
        self.value = ErlValueType()
        self.read_only = False
        self.set_by_external_interface = False
        self.set_by_global_variable = False
        self.set_by_internal_variable = False

struct InstructionType:
    var line_num: Int32
    var keyword: Int32
    var argument1: Int32
    var argument2: Int32
    
    fn __init__(
        inout self,
        line_num: Int32 = 0,
        keyword: Int32 = ERL_KEYWORD_PARAM_NONE,
        argument1: Int32 = 0,
        argument2: Int32 = 0,
    ):
        self.line_num = line_num
        self.keyword = keyword
        self.argument1 = argument1
        self.argument2 = argument2

struct ErlStackType:
    var name: String
    var num_lines: Int32
    var line: List[String]
    var num_instructions: Int32
    var instruction: List[InstructionType]
    var num_errors: Int32
    var error: List[String]
    
    fn __init__(inout self):
        self.name = ""
        self.num_lines = 0
        self.line = List[String]()
        self.num_instructions = 0
        self.instruction = List[InstructionType]()
        self.num_errors = 0
        self.error = List[String]()

struct ErlExpressionType:
    var operator: Int32
    var num_operands: Int32
    var operand: List[ErlValueType]
    
    fn __init__(inout self):
        self.operator = ERL_FUNC_INVALID
        self.num_operands = 0
        self.operand = List[ErlValueType]()

struct Operator:
    var symbol: String
    var num_operands: Int32
    
    fn __init__(
        inout self,
        symbol: String = "",
        num_operands: Int32 = 0,
    ):
        self.symbol = symbol
        self.num_operands = num_operands

struct TrendVariableType:
    var name: String
    var erl_variable_pointer: Int32
    var log_depth: Int32
    var trend_val_arr: List[Float64]
    var temp_trend_arr: List[Float64]
    var time_arr: List[Float64]
    
    fn __init__(inout self):
        self.name = ""
        self.erl_variable_pointer = 0
        self.log_depth = 0
        self.trend_val_arr = List[Float64]()
        self.temp_trend_arr = List[Float64]()
        self.time_arr = List[Float64]()

struct RuntimeLanguageData:
    var ems_var_built_in_start: Int32
    var ems_var_built_in_end: Int32
    var num_program_call_managers: Int32
    var num_sensors: Int32
    var num_actuators_used: Int32
    var num_ems_actuators_available: Int32
    var max_ems_actuators_available: Int32
    var num_internal_variables_used: Int32
    var num_ems_internal_vars_available: Int32
    var max_ems_internal_vars_available: Int32
    var vars_available_alloc_inc: Int32
    var num_erl_programs: Int32
    var num_erl_subroutines: Int32
    var num_user_global_variables: Int32
    var num_erl_variables: Int32
    var num_erl_stacks: Int32
    var num_expressions: Int32
    var num_ems_output_variables: Int32
    var num_ems_metered_output_variables: Int32
    var num_erl_trend_variables: Int32
    var num_ems_curve_indices: Int32
    var num_ems_construction_indices: Int32
    var num_external_interface_global_variables: Int32
    var num_external_interface_fmu_import_global_variables: Int32
    var num_external_interface_fmu_export_global_variables: Int32
    var num_external_interface_actuators_used: Int32
    var num_external_interface_fmu_import_actuators_used: Int32
    var num_external_interface_fmu_export_actuators_used: Int32
    var output_edd_file: Bool
    var output_full_ems_trace: Bool
    var output_ems_errors: Bool
    var output_ems_actuator_avail_full: Bool
    var output_ems_actuator_avail_small: Bool
    var output_ems_internal_vars_full: Bool
    var output_ems_internal_vars_small: Bool
    var ems_construct_actuator_checked: List[List[Bool]]
    var ems_construct_actuator_is_okay: List[List[Bool]]
    var erl_variable: List[ErlVariableType]
    var erl_stack: List[ErlStackType]
    var erl_expression: List[ErlExpressionType]
    var trend_variable: List[TrendVariableType]
    var sensor: List[OutputVarSensorType]
    var ems_actuator_available: List[EMSActuatorAvailableType]
    var ems_actuator_used: List[ActuatorUsedType]
    var ems_internal_vars_available: List[InternalVarsAvailableType]
    var ems_internal_vars_used: List[InternalVarsUsedType]
    var ems_program_call_manager: List[EMSProgramCallManagementType]
    var null_value: ErlValueType
    var false_value: ErlValueType
    var true_value: ErlValueType
    var ems_actuator_available_map: Dict[String, Int32]
    
    fn __init__(inout self):
        self.ems_var_built_in_start = 0
        self.ems_var_built_in_end = 0
        self.num_program_call_managers = 0
        self.num_sensors = 0
        self.num_actuators_used = 0
        self.num_ems_actuators_available = 0
        self.max_ems_actuators_available = 0
        self.num_internal_variables_used = 0
        self.num_ems_internal_vars_available = 0
        self.max_ems_internal_vars_available = 0
        self.vars_available_alloc_inc = 1000
        self.num_erl_programs = 0
        self.num_erl_subroutines = 0
        self.num_user_global_variables = 0
        self.num_erl_variables = 0
        self.num_erl_stacks = 0
        self.num_expressions = 0
        self.num_ems_output_variables = 0
        self.num_ems_metered_output_variables = 0
        self.num_erl_trend_variables = 0
        self.num_ems_curve_indices = 0
        self.num_ems_construction_indices = 0
        self.num_external_interface_global_variables = 0
        self.num_external_interface_fmu_import_global_variables = 0
        self.num_external_interface_fmu_export_global_variables = 0
        self.num_external_interface_actuators_used = 0
        self.num_external_interface_fmu_import_actuators_used = 0
        self.num_external_interface_fmu_export_actuators_used = 0
        self.output_edd_file = False
        self.output_full_ems_trace = False
        self.output_ems_errors = False
        self.output_ems_actuator_avail_full = False
        self.output_ems_actuator_avail_small = False
        self.output_ems_internal_vars_full = False
        self.output_ems_internal_vars_small = False
        self.ems_construct_actuator_checked = List[List[Bool]]()
        self.ems_construct_actuator_is_okay = List[List[Bool]]()
        self.erl_variable = List[ErlVariableType]()
        self.erl_stack = List[ErlStackType]()
        self.erl_expression = List[ErlExpressionType]()
        self.trend_variable = List[TrendVariableType]()
        self.sensor = List[OutputVarSensorType]()
        self.ems_actuator_available = List[EMSActuatorAvailableType]()
        self.ems_actuator_used = List[ActuatorUsedType]()
        self.ems_internal_vars_available = List[InternalVarsAvailableType]()
        self.ems_internal_vars_used = List[InternalVarsUsedType]()
        self.ems_program_call_manager = List[EMSProgramCallManagementType]()
        self.null_value = ErlValueType(type=VALUE_NULL, initialized=True, setup_init=True)
        self.false_value = ErlValueType(type=VALUE_NULL, initialized=True, setup_init=True)
        self.true_value = ErlValueType(type=VALUE_NULL, initialized=True, setup_init=True)
        self.ems_actuator_available_map = Dict[String, Int32]()
    
    fn clear_state(inout self) -> None:
        self.num_program_call_managers = 0
        self.num_sensors = 0
        self.num_actuators_used = 0
        self.num_ems_actuators_available = 0
        self.max_ems_actuators_available = 0
        self.num_internal_variables_used = 0
        self.num_ems_internal_vars_available = 0
        self.max_ems_internal_vars_available = 0
        self.vars_available_alloc_inc = 1000
        self.num_erl_programs = 0
        self.num_erl_subroutines = 0
        self.num_user_global_variables = 0
        self.num_erl_variables = 0
        self.num_erl_stacks = 0
        self.num_expressions = 0
        self.num_ems_output_variables = 0
        self.num_ems_metered_output_variables = 0
        self.num_erl_trend_variables = 0
        self.num_ems_curve_indices = 0
        self.num_ems_construction_indices = 0
        self.num_external_interface_global_variables = 0
        self.num_external_interface_fmu_import_global_variables = 0
        self.num_external_interface_fmu_export_global_variables = 0
        self.num_external_interface_actuators_used = 0
        self.num_external_interface_fmu_import_actuators_used = 0
        self.num_external_interface_fmu_export_actuators_used = 0
        self.output_edd_file = False
        self.output_full_ems_trace = False
        self.output_ems_errors = False
        self.output_ems_actuator_avail_full = False
        self.output_ems_actuator_avail_small = False
        self.output_ems_internal_vars_full = False
        self.output_ems_internal_vars_small = False
        self.ems_construct_actuator_checked = List[List[Bool]]()
        self.ems_construct_actuator_is_okay = List[List[Bool]]()
        self.erl_variable = List[ErlVariableType]()
        self.erl_stack = List[ErlStackType]()
        self.erl_expression = List[ErlExpressionType]()
        self.trend_variable = List[TrendVariableType]()
        self.sensor = List[OutputVarSensorType]()
        self.ems_actuator_available = List[EMSActuatorAvailableType]()
        self.ems_actuator_used = List[ActuatorUsedType]()
        self.ems_internal_vars_available = List[InternalVarsAvailableType]()
        self.ems_internal_vars_used = List[InternalVarsUsedType]()
        self.ems_program_call_manager = List[EMSProgramCallManagementType]()
        self.null_value = ErlValueType(type=VALUE_NULL, initialized=True, setup_init=True)
        self.false_value = ErlValueType(type=VALUE_NULL, initialized=True, setup_init=True)
        self.true_value = ErlValueType(type=VALUE_NULL, initialized=True, setup_init=True)
        self.ems_actuator_available_map = Dict[String, Int32]()

@always_inline
fn has(s: String, substring: String) -> Bool:
    return substring in s

@always_inline
fn is_any_of(char: String, chars: String) -> Bool:
    return char in chars

fn show_severe_error(state: UnsafePointer[UInt8], msg: String) -> None:
    pass

fn show_continue_error(state: UnsafePointer[UInt8], msg: String) -> None:
    pass

fn validate_ems_variable_name(
    state: UnsafePointer[UInt8],
    c_module_object: String,
    c_field_value: String,
    c_field_name: String,
) -> Tuple[Bool, Bool]:
    var err_flag: Bool = False
    var errors_found: Bool = False
    var invalid_start_characters: String = "0123456789"
    
    if has(c_field_value, " "):
        show_severe_error(state, c_module_object + "=\"" + c_field_value + "\", Invalid variable name entered.")
        show_continue_error(state, "..." + c_field_name + "; Names used as EMS variables cannot contain spaces")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, "-"):
        show_severe_error(state, c_module_object + "=\"" + c_field_value + "\", Invalid variable name entered.")
        show_continue_error(state, "..." + c_field_name + "; Names used as EMS variables cannot contain \"-\" characters.")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, "+"):
        show_severe_error(state, c_module_object + "=\"" + c_field_value + "\", Invalid variable name entered.")
        show_continue_error(state, "..." + c_field_name + "; Names used as EMS variables cannot contain \"+\" characters.")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, "."):
        show_severe_error(state, c_module_object + "=\"" + c_field_value + "\", Invalid variable name entered.")
        show_continue_error(state, "..." + c_field_name + "; Names used as EMS variables cannot contain \".\" characters.")
        err_flag = True
        errors_found = True
    
    if len(c_field_value) > 0 and is_any_of(c_field_value[0], invalid_start_characters):
        show_severe_error(state, c_module_object + "=\"" + c_field_value + "\", Invalid variable name entered.")
        show_continue_error(state, "..." + c_field_name + "; Names used as EMS variables cannot start with numeric characters.")
        err_flag = True
        errors_found = True
    
    return (err_flag, errors_found)

fn validate_ems_program_name(
    state: UnsafePointer[UInt8],
    c_module_object: String,
    c_field_value: String,
    c_field_name: String,
    c_sub_type: String,
) -> Tuple[Bool, Bool]:
    var err_flag: Bool = False
    var errors_found: Bool = False
    
    if has(c_field_value, " "):
        show_severe_error(state, c_module_object + "=\"" + c_field_value + "\", Invalid variable name entered.")
        show_continue_error(state, "..." + c_field_name + "; Names used for EMS " + c_sub_type + " cannot contain spaces")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, "-"):
        show_severe_error(state, c_module_object + "=\"" + c_field_value + "\", Invalid variable name entered.")
        show_continue_error(state, "..." + c_field_name + "; Names used for EMS " + c_sub_type + " cannot contain \"-\" characters.")
        err_flag = True
        errors_found = True
    
    if has(c_field_value, "+"):
        show_severe_error(state, c_module_object + "=\"" + c_field_value + "\", Invalid variable name entered.")
        show_continue_error(state, "..." + c_field_name + "; Names used for EMS " + c_sub_type + " cannot contain \"+\" characters.")
        err_flag = True
        errors_found = True
    
    return (err_flag, errors_found)
