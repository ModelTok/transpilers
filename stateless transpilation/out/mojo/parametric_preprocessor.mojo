import math
import os
from pathlib import Path
from sys import argv, exit

alias TAB_CHAR = '\t'
alias STRING_LENGTH = 200
alias LONG_STRING = 2000
alias OP_STACK_SIZE = 100
alias MAX_ERROR_LENGTH = 300
alias RESET = -999

alias CHAR_NUM = 1
alias CHAR_PERIOD = 2
alias CHAR_E = 3
alias CHAR_AZ = 4
alias CHAR_PLUS = 5
alias CHAR_MINUS = 6
alias CHAR_MULT = 7
alias CHAR_DIV = 8
alias CHAR_EXP = 9
alias CHAR_LEFT_PAREN = 10
alias CHAR_RIGHT_PAREN = 11
alias CHAR_DOUBLE_QUOTE = 12
alias CHAR_EQUAL = 13
alias CHAR_GREAT = 14
alias CHAR_LESS = 15
alias CHAR_TILDE = 16
alias CHAR_SPACE = 17
alias CHAR_DOLLAR = 18
alias CHAR_AMPERSAND = 19
alias CHAR_PIPE = 20
alias CHAR_UNDERSCORE = 21
alias CHAR_OTHER = 100
alias CHAR_NONE = 200

alias TOK_NUM = -1
alias TOK_STR = -2
alias TOK_ID = -3
alias TOK_FUNC = -4
alias TOK_PLUS = -5
alias TOK_MINUS = -6
alias TOK_TIMES = -7
alias TOK_DIV = -8
alias TOK_EXP = -9
alias TOK_RT_PAREN = -10
alias TOK_LT_PAREN = -11
alias TOK_GT = -12
alias TOK_EQ = -13
alias TOK_LT = -14
alias TOK_GE = -15
alias TOK_LE = -16
alias TOK_NE = -17
alias TOK_AND = -18
alias TOK_OR = -19
alias TOK_TILDE = -20
alias TOK_UN_NEG = -21
alias TOK_FUNC_ABS = -22
alias TOK_FUNC_ACOS = -23
alias TOK_FUNC_ASIN = -24
alias TOK_FUNC_ATAN = -25
alias TOK_FUNC_COS = -26
alias TOK_FUNC_EXP = -27
alias TOK_FUNC_INT = -28
alias TOK_FUNC_LEN = -29
alias TOK_FUNC_LOG = -30
alias TOK_FUNC_MOD = -31
alias TOK_FUNC_NOT = -32
alias TOK_FUNC_SIN = -33
alias TOK_FUNC_SQRT = -34
alias TOK_FUNC_TAN = -35
alias TOK_NONE = -98
alias TOK_INVALID = -99

alias PREC_EXP = 6
alias PREC_MULT_DIV = 5
alias PREC_ADD_SUB = 4
alias PREC_COMPARE = 3
alias PREC_AND_OR = 2
alias PREC_LEFT_PAREN = 1
alias PREC_NO_ITEM = 0

alias KS_NONE = -128
alias KS_ASSIGNMENT = -129
alias KS_PARAMETER = -130
alias KS_IF = -131
alias KS_ELSEIF = -132
alias KS_ELSE = -133
alias KS_ENDIF = -134
alias KS_SELECT = -135
alias KS_CASE = -136
alias KS_DEFAULT = -137
alias KS_ENDSELECT = -138
alias KS_DISABLE = -139
alias KS_ENABLE = -140
alias KS_REMARK = -141

alias KO_NONE = 0
alias KO_SET_VALUE_FOR_RUN = 1
alias KO_LOGIC = 2
alias KO_RUN_CONTROL = 3
alias KO_FILE_NAME_SUFFIX = 4

alias SSM_NOT_IN_STRUC = 1
alias SSM_DO_THEN = 2
alias SSM_SKIP_TO_ELSE = 3
alias SSM_DO_ELSE = 4
alias SSM_SKIP_TO_ENDIF = 5
alias SSM_FIND_CASE = 6
alias SSM_DO_CASE = 7
alias SSM_SKIP_TO_END_SELECT = 8

alias MSG_ERROR = 1
alias MSG_WARNING = 2

@value
struct OpStackType:
    var tok_operator: Int32 = 0
    var precedence: Int32 = 0
    var func_start: Int32 = 0
    var func_end: Int32 = 0

@value
struct ErrMsgType:
    var msg_text: String = ""
    var msg_kind: Int32 = 0
    var msg_err_num: Int32 = 0
    var msg_context: String = ""

@value
struct FoundExpressionType:
    var text: String = ""
    var line: Int32 = 0
    var start_int_code: Int32 = 0
    var end_int_code: Int32 = 0
    var exp_result: String = ""

@value
struct ObjectLinesType:
    var kind_of_obj: String = ""
    var name_of_obj: String = ""
    var first_line: Int32 = 0
    var last_line: Int32 = 0
    var enabled: Bool = True

@value
struct IdfObjectType:
    var kind_obj: Int32 = 0
    var first_field: Int32 = 0
    var last_field: Int32 = 0

@value
struct CasesType:
    var active: Bool = False
    var dup: Bool = False
    var dup2: Bool = False
    var suffix: String = ""

@value
struct SymbolType:
    var name: String = ""
    var val: String = ""
    var is_real_num: Bool = False
    var val_as_real: Float64 = 0.0
    var is_set_value_for_run: Bool = False
    var is_parameter: Bool = False

@value
struct ParLogLineType:
    var statement_kind: Int32 = 0
    var idf_field_num: Int32 = 0
    var start_int_code: Int32 = 0
    var end_int_code: Int32 = 0
    var assign_param: Int32 = 0
    var symbol_a: Int32 = 0
    var symbol_b: Int32 = 0
    var obj_line: Int32 = 0

@value
struct StrucStackType:
    var mode: Int32 = 0
    var match: String = ""

@value
struct EvalStackType:
    var val: String = ""
    var is_real_num: Bool = False
    var val_as_real: Float64 = 0.0

struct ParametricPreprocessor:
    var verbose_debug: Bool
    var input_file_path_name: String
    var file_path_only: String
    var output_file_name_root: String
    var output_file_name: String
    var error_condition: Bool
    var error_context: String
    
    var err_msgs: List[ErrMsgType]
    var num_err_msgs: Int32
    
    var found_expression: List[FoundExpressionType]
    var num_found_expression: Int32
    
    var object_lines: List[ObjectLinesType]
    var num_object_lines: Int32
    
    var idf_object: List[IdfObjectType]
    var num_idf_object: Int32
    
    var idf_field: List[String]
    var num_idf_field: Int32
    
    var cases: List[CasesType]
    var num_cases: Int32
    
    var val_for_run: List[List[String]]
    
    var int_code: List[Int32]
    var num_int_code: Int32
    
    var symbol: List[SymbolType]
    var num_symbol: Int32
    var last_symbol_set_value_for_run: Int32
    var last_symbol_parameter: Int32
    
    var par_log_line: List[ParLogLineType]
    var num_par_log_line: Int32
    
    var struc_stack: List[StrucStackType]
    var top_struc_stack: Int32
    
    var eval_stack: List[EvalStackType]
    var top_eval_stack: Int32
    
    var op_stack: List[OpStackType]
    var op_stack_top: Int32
    
    var get_next_disabled_object_lines_index: Int32
    var get_next_found_expression_index: Int32

    fn __init__(inout self):
        self.verbose_debug = False
        self.input_file_path_name = ""
        self.file_path_only = ""
        self.output_file_name_root = ""
        self.output_file_name = ""
        self.error_condition = False
        self.error_context = ""
        
        self.err_msgs = List[ErrMsgType]()
        self.num_err_msgs = 0
        
        self.found_expression = List[FoundExpressionType]()
        self.num_found_expression = 0
        
        self.object_lines = List[ObjectLinesType]()
        self.num_object_lines = 0
        
        self.idf_object = List[IdfObjectType]()
        self.num_idf_object = 0
        
        self.idf_field = List[String]()
        self.num_idf_field = 0
        
        self.cases = List[CasesType]()
        self.num_cases = 0
        
        self.val_for_run = List[List[String]]()
        
        self.int_code = List[Int32]()
        self.num_int_code = 0
        
        self.symbol = List[SymbolType]()
        self.num_symbol = 0
        self.last_symbol_set_value_for_run = 0
        self.last_symbol_parameter = 0
        
        self.par_log_line = List[ParLogLineType]()
        self.num_par_log_line = 0
        
        self.struc_stack = List[StrucStackType]()
        self.top_struc_stack = 0
        
        self.eval_stack = List[EvalStackType]()
        self.top_eval_stack = 0
        
        self.op_stack = List[OpStackType](capacity=OP_STACK_SIZE)
        for _ in range(OP_STACK_SIZE):
            self.op_stack.append(OpStackType())
        self.op_stack_top = 0
        
        self.get_next_disabled_object_lines_index = 1
        self.get_next_found_expression_index = 1

    fn classify_char(self, single_char: String) -> Int32:
        if len(single_char) == 0:
            return CHAR_NONE
        let c = ord(single_char)
        if 48 <= c <= 57:
            return CHAR_NUM
        elif c == 46:
            return CHAR_PERIOD
        elif c == 68 or c == 69 or c == 100 or c == 101:
            return CHAR_E
        elif (65 <= c <= 67) or (70 <= c <= 90) or (97 <= c <= 99) or (102 <= c <= 122):
            return CHAR_AZ
        elif c == 43:
            return CHAR_PLUS
        elif c == 45:
            return CHAR_MINUS
        elif c == 42:
            return CHAR_MULT
        elif c == 47:
            return CHAR_DIV
        elif c == 94:
            return CHAR_EXP
        elif c == 40:
            return CHAR_LEFT_PAREN
        elif c == 41:
            return CHAR_RIGHT_PAREN
        elif c == 34:
            return CHAR_DOUBLE_QUOTE
        elif c == 61:
            return CHAR_EQUAL
        elif c == 62:
            return CHAR_GREAT
        elif c == 60:
            return CHAR_LESS
        elif c == 126:
            return CHAR_TILDE
        elif c == 32:
            return CHAR_SPACE
        elif c == 36:
            return CHAR_DOLLAR
        elif c == 38:
            return CHAR_AMPERSAND
        elif c == 95:
            return CHAR_UNDERSCORE
        elif c == 124:
            return CHAR_PIPE
        else:
            return CHAR_OTHER

    fn is_str_eq(self, arg1: String, arg2: String) -> Bool:
        return arg1.upper() == arg2.upper()

    fn string_to_real(self, string_in: String) -> Float64:
        let s = string_in.strip()
        if len(s) == 0:
            return 0.0
        return atof(s.cstr())

    fn real_to_string(self, real_in: Float64) -> String:
        if (real_in < 0.00001 and real_in > -0.00001) or (real_in > 100000 or real_in < -100000):
            return String.format_float(real_in, 6, 'E')
        else:
            return String.format_float(real_in, 6, 'f').rstrip("0").rstrip(".")

    fn int_to_str(self, int_in: Int32) -> String:
        return str(int_in)

    fn int_to_str6(self, int_in: Int32) -> String:
        if 0 <= int_in <= 999999:
            return String.format_int(int_in, 6, '0')
        return "Invalid"

    fn path_only(self, file_with_path_in: String) -> String:
        let slash_pos1 = file_with_path_in.rfind("\\")
        let slash_pos2 = file_with_path_in.rfind("/")
        let slash_pos = max(slash_pos1, slash_pos2)
        if slash_pos >= 0:
            return file_with_path_in[0:slash_pos + 1]
        return ""

    fn no_extension(self, string_in: String) -> String:
        let dot_pos = string_in.rfind(".")
        if dot_pos >= 0:
            return string_in[0:dot_pos]
        return string_in

    fn add_to_err_msg(inout self, text_of_error: String, kind_of_error: Int32, error_number: Int32):
        self.num_err_msgs += 1
        if self.num_err_msgs > len(self.err_msgs):
            self.err_msgs.append(ErrMsgType())
        var msg = self.err_msgs[self.num_err_msgs - 1]
        msg.msg_text = text_of_error
        msg.msg_kind = kind_of_error
        msg.msg_err_num = error_number
        msg.msg_context = self.error_context
        
        print("-------------------------------------------------------------------------")
        if kind_of_error == MSG_ERROR:
            print("   ERROR:")
        else:
            print("   WARNING:")
        print("      " + text_of_error)
        print("      Number " + str(error_number))
        if len(self.error_context) > 0:
            print("   CONTEXT:" + self.error_context)
        self.error_context = ""
        if kind_of_error == MSG_ERROR:
            self.error_condition = True

    fn open_error_file(inout self):
        if self.verbose_debug:
            print(" Started OpenErrorFile")
        let error_file_with_path = self.output_file_name_root + ".err"

    fn open_files_first_pass(inout self):
        if self.verbose_debug:
            print(" Started OpenFilesFirstPass")
        if self.error_condition:
            return

    fn close_files_first_pass(inout self):
        if self.verbose_debug:
            print(" Started CloseFilesFirstPass")

    fn initial_read(inout self):
        if self.verbose_debug:
            print(" Started InitialRead")
        if self.error_condition:
            return

    fn add_new_object(inout self, kind_of_object: Int32):
        self.num_idf_object += 1
        if self.num_idf_object > len(self.idf_object):
            self.idf_object.append(IdfObjectType())
        var obj = self.idf_object[self.num_idf_object - 1]
        obj.kind_obj = kind_of_object
        obj.first_field = self.num_idf_field + 1
        obj.last_field = self.num_idf_field + 1

    fn add_field(inout self, field_in: String):
        self.num_idf_field += 1
        if self.num_idf_field > len(self.idf_field):
            self.idf_field.append("")
        self.idf_field[self.num_idf_field - 1] = field_in.strip()
        if self.num_idf_object > 0:
            self.idf_object[self.num_idf_object - 1].last_field = self.num_idf_field

    fn add_object_line_reference(inout self, obj_kind: String, obj_name: String, line_start: Int32, line_end: Int32):
        self.num_object_lines += 1
        if self.num_object_lines > len(self.object_lines):
            self.object_lines.append(ObjectLinesType())
        var ol = self.object_lines[self.num_object_lines - 1]
        ol.kind_of_obj = obj_kind
        ol.name_of_obj = obj_name
        ol.first_line = line_start
        ol.last_line = line_end
        ol.enabled = True

    fn add_new_expression(inout self, exp_string: String, line_of_file: Int32) -> Int32:
        self.num_found_expression += 1
        if self.num_found_expression > len(self.found_expression):
            self.found_expression.append(FoundExpressionType())
        var fe = self.found_expression[self.num_found_expression - 1]
        fe.text = exp_string
        fe.line = line_of_file
        return self.num_found_expression

    fn determine_number_of_cases(inout self):
        if self.verbose_debug:
            print(" Started DetermineNumberOfCases")
        if self.error_condition:
            return
        self.num_cases = 0
        for i in range(self.num_idf_object):
            let cur_num_fields = self.idf_object[i].last_field - self.idf_object[i].first_field + 1
            let cur_num_poss_cases = cur_num_fields - 1
            if self.idf_object[i].kind_obj in (KO_SET_VALUE_FOR_RUN, KO_RUN_CONTROL, KO_FILE_NAME_SUFFIX):
                if cur_num_poss_cases > self.num_cases:
                    self.num_cases = cur_num_poss_cases
            elif self.idf_object[i].kind_obj == KO_LOGIC:
                if self.num_cases == 0:
                    self.num_cases = 1
        if self.num_cases == 0:
            if self.num_found_expression >= 1:
                self.num_cases = 1

    fn set_cases(inout self):
        if self.verbose_debug:
            print(" Started SetCases")
        if self.error_condition:
            return
        for k in range(self.num_cases):
            self.cases[k].active = True
            self.cases[k].suffix = self.int_to_str6(k + 1)

    fn gather_parameter_symbols(inout self):
        if self.verbose_debug:
            print(" Started GatherParameterSymbols")
        if self.error_condition:
            return

    fn add_parameter_symbol(inout self, par_in: String, if_set_value_for_run: Bool = False) -> Bool:
        let cur_par = par_in.strip()
        if not cur_par.startswith("$"):
            return False
        for i in range(1, len(cur_par)):
            let c_class = self.classify_char(cur_par[i:i+1])
            if c_class not in (CHAR_NUM, CHAR_AZ, CHAR_E, CHAR_UNDERSCORE):
                return False
        
        self.num_symbol += 1
        if self.num_symbol > len(self.symbol):
            self.symbol.append(SymbolType())
        var sym = self.symbol[self.num_symbol - 1]
        sym.name = cur_par
        sym.is_parameter = True
        if if_set_value_for_run:
            self.last_symbol_set_value_for_run = self.num_symbol
            sym.is_set_value_for_run = True
        self.last_symbol_parameter = self.num_symbol
        return True

    fn add_constant_symbol(inout self, constant_in: String, constant_real_in: Float64 = 0.0):
        self.num_symbol += 1
        if self.num_symbol > len(self.symbol):
            self.symbol.append(SymbolType())
        var sym = self.symbol[self.num_symbol - 1]
        sym.name = ""
        sym.val = constant_in
        sym.val_as_real = constant_real_in
        sym.is_real_num = True

    fn lookup_parameter_symbol(self, symbol_name_in: String) -> Int32:
        for i in range(self.last_symbol_parameter):
            if self.is_str_eq(symbol_name_in, self.symbol[i].name):
                return i as Int32 + 1
        return 0

    fn read_set_value_objects(inout self):
        if self.verbose_debug:
            print(" Started ReadSetValueObjects")
        if self.error_condition:
            return

    fn translate_parametric_logic(inout self):
        if self.verbose_debug:
            print(" Started TranslateParametricLogic")
        if self.error_condition:
            return

    fn translate_embedded_expressions(inout self):
        if self.verbose_debug:
            print(" Started TranslateEmbeddedExpressions")
        if self.error_condition:
            return

    fn set_value_for_case(inout self, case_in: Int32):
        if self.verbose_debug:
            print(" Started SetValueForCase: " + str(case_in))
        if self.error_condition:
            return
        for i in range(self.last_symbol_parameter):
            self.symbol[i].val = self.val_for_run[i][case_in - 1]
            self.symbol[i].is_real_num = False

    fn compute_parametric_logic(inout self):
        if self.verbose_debug:
            print(" Started ComputeParametricLogic")
        if self.error_condition:
            return

    fn compute_embedded_expressions(inout self):
        if self.verbose_debug:
            print(" Started ComputeEmbeddedExpressions")
        if self.error_condition:
            return

    fn open_file_second_pass(inout self, case_in: Int32):
        if self.verbose_debug:
            print(" Started OpenFileSecondPass")
        if self.error_condition:
            return

    fn substitute_values(inout self):
        if self.verbose_debug:
            print(" Started SubstituteValues")
        if self.error_condition:
            return

    fn close_file_second_pass(inout self):
        if self.verbose_debug:
            print(" Started CloseFileSecondPass")

    fn write_errors_and_close_file(inout self):
        pass

    fn get_next_disabled_object_lines(inout self, line_count_in: Int32) -> Tuple[Int32, Int32, Int32]:
        return (0, 0, 0)

    fn get_next_found_expression(inout self, line_count_in: Int32) -> Tuple[Int32, Int32]:
        return (0, 0)

    fn evaluate_expression(inout self, first_int_code_in: Int32, last_int_code_in: Int32) -> Tuple[String, Float64, Bool]:
        return ("", 0.0, False)

    fn push_symbol_on_eval_stack(inout self, symbol_ref_in: Int32):
        if 1 <= symbol_ref_in <= self.num_symbol:
            if self.top_eval_stack + 1 > len(self.eval_stack):
                self.eval_stack.append(EvalStackType())
            self.top_eval_stack += 1
            self.eval_stack[self.top_eval_stack - 1].val = self.symbol[symbol_ref_in - 1].val
            self.eval_stack[self.top_eval_stack - 1].is_real_num = self.symbol[symbol_ref_in - 1].is_real_num
            self.eval_stack[self.top_eval_stack - 1].val_as_real = self.symbol[symbol_ref_in - 1].val_as_real

    fn pop_eval_real(inout self) -> Float64:
        if self.top_eval_stack >= 1:
            if self.eval_stack[self.top_eval_stack - 1].is_real_num:
                let result = self.eval_stack[self.top_eval_stack - 1].val_as_real
                self.top_eval_stack -= 1
                return result
            else:
                self.add_to_err_msg("Real value expected but not found on evaluation stack.", MSG_WARNING, 0)
                self.top_eval_stack -= 1
                return 0.0
        return 0.0

    fn push_eval_real(inout self, real_in: Float64):
        if self.top_eval_stack + 1 > len(self.eval_stack):
            self.eval_stack.append(EvalStackType())
        self.top_eval_stack += 1
        self.eval_stack[self.top_eval_stack - 1].val = self.real_to_string(real_in)
        self.eval_stack[self.top_eval_stack - 1].is_real_num = True
        self.eval_stack[self.top_eval_stack - 1].val_as_real = real_in

    fn pop_eval_logical(inout self) -> Bool:
        if self.top_eval_stack >= 1:
            var result: Bool
            if self.eval_stack[self.top_eval_stack - 1].is_real_num:
                result = self.eval_stack[self.top_eval_stack - 1].val_as_real != 0.0
            else:
                result = self.eval_stack[self.top_eval_stack - 1].val.upper().startswith("T")
            self.top_eval_stack -= 1
            return result
        else:
            self.add_to_err_msg("Logical value expected but not found on evaluation stack.", MSG_WARNING, 0)
            return False

    fn push_eval_logical(inout self, logical_in: Bool):
        if self.top_eval_stack + 1 > len(self.eval_stack):
            self.eval_stack.append(EvalStackType())
        self.top_eval_stack += 1
        if logical_in:
            self.eval_stack[self.top_eval_stack - 1].val = "True"
            self.eval_stack[self.top_eval_stack - 1].is_real_num = False
            self.eval_stack[self.top_eval_stack - 1].val_as_real = 1.0
        else:
            self.eval_stack[self.top_eval_stack - 1].val = "False"
            self.eval_stack[self.top_eval_stack - 1].is_real_num = False
            self.eval_stack[self.top_eval_stack - 1].val_as_real = 0.0

    fn pop_eval_string(inout self) -> String:
        if self.top_eval_stack >= 1:
            let result = self.eval_stack[self.top_eval_stack - 1].val
            self.top_eval_stack -= 1
            return result
        return ""

    fn is_eval_stack_top_real(self, num_vals_in: Int32) -> Bool:
        if 1 <= num_vals_in <= self.top_eval_stack:
            let first_item = self.top_eval_stack - num_vals_in
            for i in range(first_item, self.top_eval_stack):
                if not self.eval_stack[i].is_real_num:
                    return False
            return True
        else:
            return False

    fn is_result_true(self, result_in: String) -> Bool:
        return result_in.upper().startswith("T")

    fn push_struc_stack(inout self, mode_in: Int32, match_in: String = ""):
        if self.top_struc_stack + 1 > len(self.struc_stack):
            self.struc_stack.append(StrucStackType())
        self.top_struc_stack += 1
        self.struc_stack[self.top_struc_stack - 1].mode = mode_in
        if len(match_in) > 0:
            self.struc_stack[self.top_struc_stack - 1].match = match_in

    fn pop_struc_stack(inout self) -> Int32:
        if self.top_struc_stack >= 1:
            let result = self.struc_stack[self.top_struc_stack - 1].mode
            self.top_struc_stack -= 1
            return result
        return 0

    fn current_struc_stack_top(self) -> Int32:
        if self.top_struc_stack >= 1:
            return self.struc_stack[self.top_struc_stack - 1].mode
        return 0

    fn replace_top_struc_stack(inout self, mode_in: Int32, match_in: String = ""):
        if self.top_struc_stack >= 1:
            self.struc_stack[self.top_struc_stack - 1].mode = mode_in
            if len(match_in) > 0:
                self.struc_stack[self.top_struc_stack - 1].match = match_in

    fn does_top_match(self, arg_in: String) -> Bool:
        if self.top_struc_stack >= 1:
            return self.is_str_eq(arg_in, self.struc_stack[self.top_struc_stack - 1].match)
        return False

    fn get_object_reference(inout self, name_of_object_symbol_ref_in: Int32, kind_of_object_symbol_ref_in: Int32) -> Int32:
        return 0

    fn expression_to_rpn(inout self, expression_in: String):
        self.error_context = expression_in

    fn add_int_code(inout self, int_code_in: Int32):
        self.num_int_code += 1
        if self.num_int_code > len(self.int_code):
            self.int_code.append(0)
        self.int_code[self.num_int_code - 1] = int_code_in

    fn push_op_stack(inout self, op_tok: Int32, prec: Int32, start_func: Int32, end_func: Int32):
        self.op_stack_top += 1
        if self.op_stack_top <= OP_STACK_SIZE:
            self.op_stack[self.op_stack_top - 1].tok_operator = op_tok
            self.op_stack[self.op_stack_top - 1].precedence = prec
            self.op_stack[self.op_stack_top - 1].func_start = start_func
            self.op_stack[self.op_stack_top - 1].func_end = end_func

    fn pop_op_stack(inout self) -> Int32:
        if self.op_stack_top >= 1:
            let result = self.op_stack[self.op_stack_top - 1].tok_operator
            self.op_stack_top -= 1
            return result
        return 0

    fn check_top_prec(self) -> Int32:
        if self.op_stack_top >= 1:
            return self.op_stack[self.op_stack_top - 1].precedence
        return PREC_NO_ITEM

    fn check_top_is_func(self) -> Bool:
        if self.op_stack_top >= 1:
            let op = self.op_stack[self.op_stack_top - 1].tok_operator
            return TOK_FUNC_ABS >= op and op >= TOK_FUNC_TAN
        return False

    fn classify_precedence(self, token_in: Int32) -> Int32:
        if token_in == TOK_EXP:
            return PREC_EXP
        elif token_in in (TOK_TIMES, TOK_DIV):
            return PREC_MULT_DIV
        elif token_in in (TOK_PLUS, TOK_MINUS):
            return PREC_ADD_SUB
        elif token_in in (TOK_GT, TOK_EQ, TOK_LT, TOK_GE, TOK_LE, TOK_NE):
            return PREC_COMPARE
        elif token_in in (TOK_AND, TOK_OR):
            return PREC_AND_OR
        elif token_in == TOK_RT_PAREN:
            return PREC_LEFT_PAREN
        else:
            return PREC_NO_ITEM

    fn run(inout self):
        print("ParametricPreprocessor Started.")
        if len(argv) > 1:
            self.input_file_path_name = argv[1]
        
        self.file_path_only = self.path_only(self.input_file_path_name)
        self.output_file_name_root = self.no_extension(self.input_file_path_name)
        
        self.open_error_file()
        self.open_files_first_pass()
        self.initial_read()
        self.close_files_first_pass()
        self.determine_number_of_cases()
        
        for _ in range(self.num_cases):
            self.cases.append(CasesType())
        
        self.set_cases()
        self.gather_parameter_symbols()
        
        for _ in range(self.last_symbol_parameter):
            var row = List[String]()
            for _ in range(self.num_cases):
                row.append("")
            self.val_for_run.append(row)
        
        self.read_set_value_objects()
        self.translate_parametric_logic()
        self.translate_embedded_expressions()
        
        for i in range(1, self.num_cases + 1):
            if i - 1 < len(self.cases) and self.cases[i - 1].active:
                self.set_value_for_case(i)
                self.compute_parametric_logic()
                self.compute_embedded_expressions()
                self.open_file_second_pass(i)
                self.substitute_values()
                self.close_file_second_pass()
        
        self.write_errors_and_close_file()
        print("ParametricPreprocessor Finished.")

fn main():
    var pp = ParametricPreprocessor()
    pp.run()
