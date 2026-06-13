"""
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""

from core.h import (
    var_info, var_info_invalid, compute_module, handler_interface,
    check_error, constraint_error, exec_error, mismatch_error, timestep_error,
    general_error, SSC_INVALID, SSC_INPUT, SSC_OUTPUT, SSC_INOUT,
    SSC_STRING, SSC_NUMBER, SSC_ARRAY, SSC_MATRIX, SSC_TABLE,
    SSC_NOTICE, SSC_ERROR, ssc_number_t, ssc_data_t, unordered_map,
    module_entry_info
)
from vartab import var_table, var_data
from sscapi import ssc_data_t
from ssc_equations import ssc_equation_table, ssc_equation_ptr
from util import util

# var_info_invalid definition (extern in header)
let var_info_invalid: var_info = {0, 0, None, None, None, None, None, None, None, None}

compute_module.compute_module(
    self
):
    self.m_handler = None
    self.m_vartab = None
    self.m_infomap = None
    # nothing to do

compute_module.~compute_module(
    self
):
    if self.m_infomap:
        del self.m_infomap

compute_module.compute(
    self,
    handler: handler_interface,
    data: var_table
) -> bool:
    self.m_handler = None
    self.m_vartab = None
    if not handler:
        self.log("no request handler assigned to computation engine", SSC_ERROR)
        return False
    self.m_handler = handler
    if not data:
        self.log("no data object assigned to computation engine", SSC_ERROR)
        return False
    self.m_vartab = data
    if len(self.m_varlist) == 0:
        self.log("no variables defined for computation engine", SSC_ERROR)
        return False
    try: # catch any 'general_error' that can be thrown during precheck, exec, and postcheck
        if not self.evaluate():
            return False
        self.exec()
    except general_error as e:
        self.log(e.err_text, SSC_ERROR, e.time)
        return False
    except e: # catch exception
        self.log("compute fail(" + self.name + "): " + str(e), SSC_ERROR, -1)
        return False
    return True

compute_module.evaluate(
    self
) -> bool:
    var table_indices: List[Int] = List[Int]()
    var table_length: Int = len(ssc_equation_table)  # using len instead of sizeof
    for i in range(table_length):
        if ssc_equation_table[i].cmod == None:
            continue
        row_compute_module_name: String = util.lower_case(ssc_equation_table[i].cmod)
        match: Int = self.name.find(row_compute_module_name)
        if match != -1 and ssc_equation_table[i].auto_eval:
            table_indices.push_back(i)
    if len(table_indices) == 0:
        return True
    def CallSscEquations: fn(self: compute_module, table_indices: List[Int]) -> bool = fn(self, table_indices):
        for table_row in table_indices:
            ssc_equation: ssc_equation_ptr = ssc_equation_table[table_row].func
            var_table_data: ssc_data_t = self.m_vartab  # cast not needed in Mojo
            try:
                ssc_equation(var_table_data)
            except e:
                time: Float32 = -1.0
                self.log(str(e), SSC_ERROR, time)
                return False
        return True
    CallSscEquations(self, table_indices)
    const kMaxIterations: Int = 100
    const kMaxConvergenceTol: Float64 = 0.001
    var iteration: Int = 0
    var convergence_error: Float64 = Float64(Inf)
    var squared_error: Float64 = 0.0
    var n_differences: Int = 0
    def NumberSquaredError(a: Float64, b: Float64):
        const kEpsilon: Float64 = 1e-12  # numeric_limits<double>::epsilon() approximate
        if abs(a - b) > kEpsilon:
            squared_error += pow(a - b, 2)
            n_differences += 1
    def ArraySquaredError(a: Pointer[Float64], b: Pointer[Float64], n: Int):
        for i in range(n):
            NumberSquaredError(a[i], b[i])
    def TableSquaredError(a: var_table, b: var_table) -> bool:
        var it: Iterator[str]? = a.first()
        while it:
            variable_name: String = it.value()
            variable_data: var_data = a.lookup(variable_name)
            with variable_data.type:
                case SSC_STRING:
                    string_cur: String = a.as_string(variable_name)
                    string_prev: String = b.as_string(variable_name)
                    if string_cur != string_prev:
                        time: Float32 = -1.0
                        self.log("Changing string variables in ssc_equations is not allowed.", SSC_ERROR, time)
                        return False
                case SSC_NUMBER:
                    number_cur: Float64 = a.as_double(variable_name)
                    number_prev: Float64 = b.as_double(variable_name)
                    NumberSquaredError(number_cur, number_prev)
                case SSC_ARRAY:
                    n_elements_cur: Int = 0
                    n_elements_prev: Int = 0
                    array_cur: Pointer[Float64] = a.as_array(variable_name, &n_elements_cur)
                    array_prev: Pointer[Float64] = b.as_array(variable_name, &n_elements_prev)
                    if n_elements_cur != n_elements_prev:
                        time: Float32 = -1.0
                        self.log("Changing array variable length in ssc_equations is not allowed.", SSC_ERROR, time)
                        return False
                    ArraySquaredError(array_cur, array_prev, n_elements_cur)
                case SSC_MATRIX:
                    matrix_cur: util.matrix_t[Float64] = a.as_matrix(variable_name)
                    matrix_prev: util.matrix_t[Float64] = b.as_matrix(variable_name)
                    if matrix_cur.nrows() != matrix_prev.nrows() or matrix_cur.ncols() != matrix_prev.ncols():
                        time: Float32 = -1.0
                        self.log("Changing matrix variable dimensions in ssc_equations is not allowed.", SSC_ERROR, time)
                        return False
                    ArraySquaredError(matrix_cur.data(), matrix_prev.data(), matrix_cur.ncells())
                case SSC_TABLE:
                    tab: var_table = variable_data.table
                    if not b.is_assigned(variable_name):
                        time: Float32 = -1.0
                        self.log("Removing or adding table variables in ssc_equations is not allowed.", SSC_ERROR, time)
                        return False
                    tab_prev: var_table = b.lookup(variable_name).table
                    if tab.size() != tab_prev.size():
                        time: Float32 = -1.0
                        self.log("Changing table variable dimensions in ssc_equations is not allowed.", SSC_ERROR, time)
                        return False
                    if not TableSquaredError(tab, tab_prev):
                        return False
                default:
                    time: Float32 = -1.0
                    self.log(variable_name + " of data type " + var_data.type_name(variable_data.type) +
                        " is not supported for ssc_equations", SSC_ERROR, time)
                    return False
            it = a.next()
        return True
    var var_table_prev_iter: var_table = var_table()
    var_table_prev_iter = *self.m_vartab
    while True:
        squared_error = 0.0
        n_differences = 0
        iteration += 1
        CallSscEquations(self, table_indices)
        TableSquaredError(self, self.m_vartab, &var_table_prev_iter)
        if n_differences == 0:
            convergence_error = 0.0
        else:
            convergence_error = sqrt(squared_error / Float64(n_differences))
        var_table_prev_iter = *self.m_vartab
        if convergence_error > kMaxConvergenceTol and iteration < kMaxIterations:
            break
    if convergence_error > kMaxConvergenceTol:
        err_text: String = "Inputs did not converge per their relational equations."
        time: Float32 = -1.0
        self.log(err_text, SSC_ERROR, time)
        return False
    return True

compute_module.verify(
    self,
    phase: String,
    check_var_type: Int
) -> bool:
    for vi in self.m_varlist:
        if vi.var_type == check_var_type or vi.var_type == SSC_INOUT:
            if self.check_required(vi.name):
                dat: var_data = self.lookup(vi.name)
                if not dat:
                    self.log(phase + ": variable '" + vi.name + "' (" + vi.label + ") required but not assigned")
                    return False
                elif dat.type != vi.data_type:
                    self.log(phase + ": variable '" + vi.name + "' (" + var_data.type_name(dat.type) + ") of wrong type, " + var_data.type_name(vi.data_type) + " required.")
                    return False
                fail_text: String = ""
                if not self.check_constraints(vi.name, &fail_text):
                    self.log(fail_text, SSC_ERROR)
                    return False
    return True

compute_module.add_var_info(
    self,
    vi: Pointer[var_info]
):
    i: Int = 0
    while vi[i].data_type != SSC_INVALID and vi[i].name != None:
        self.m_varlist.push_back(&vi[i])
        i += 1

compute_module.remove_var_info(
    self,
    vi: Pointer[var_info]
):
    i: Int = 0
    while vi[i].data_type != SSC_INVALID and vi[i].name != None:
        # erase-remove idiom
        self.m_varlist.erase(
            std.remove(self.m_varlist.begin(), self.m_varlist.end(), &vi[i])
        )
        i += 1

compute_module.build_info_map(
    self
):
    if self.m_infomap:
        del self.m_infomap
    self.m_infomap = unordered_map[String, var_info]()
    for vi in self.m_varlist:
        self.m_infomap[vi.name] = vi

compute_module.update(
    self,
    current_action: String,
    percent_done: Float32,
    time: Float32 = -1.0
) -> bool:
    if self.m_handler:
        return self.m_handler.on_update(current_action, percent_done, time)
    else:
        return True

compute_module.log(
    self,
    msg: String,
    type_: Int = SSC_NOTICE,
    time: Float32 = -1.0
):
    if self.m_handler:
        self.m_handler.on_log(msg, type_, time)
    self.m_loglist.push_back(log_item(type_, msg, time))

compute_module.clear_log(
    self
):
    self.m_loglist.clear()

compute_module.extproc(
    self,
    command: String,
    workdir: String
) -> bool:
    # if (m_handler) return m_handler->on_exec( command, workdir);
    # else return false;
    return False

compute_module.log_item.log(
    self: compute_module,
    index: Int
) -> compute_module.log_item:
    if index >= 0 and index < len(self.m_loglist):
        return self.m_loglist[index]
    else:
        return None

compute_module.info(
    self: compute_module,
    index: Int
) -> var_info:
    if index >= 0 and index < len(self.m_varlist):
        return self.m_varlist[index]
    else:
        return None

compute_module.info(
    self: compute_module,
    name: String
) -> var_info:
    if self.m_infomap:
        pos = self.m_infomap.get(name)
        if pos:
            return *pos
    for vi in self.m_varlist:
        if vi.name == name:
            return *vi
    raise general_error("variable information lookup fail: '" + name + "'")

compute_module.is_ssc_array_output(
    self: compute_module,
    name: String
) -> bool:
    if self.m_infomap:
        pos = self.m_infomap.get(name)
        if pos:
            if ((pos.var_type == SSC_OUTPUT) or (pos.var_type == SSC_INOUT)) and (pos.data_type == SSC_ARRAY):
                return True
    for vi in self.m_varlist:
        if ((vi.var_type == SSC_OUTPUT) or (vi.var_type == SSC_INOUT)) and vi.data_type == SSC_ARRAY:
            if util.lower_case(vi.name) == util.lower_case(name):
                return True
    return False

compute_module.lookup(
    self: compute_module,
    name: String
) -> var_data:
    if not self.m_vartab:
        raise general_error("invalid data container object reference")
    return self.m_vartab.lookup(name)

compute_module.assign(
    self: compute_module,
    name: String,
    value: var_data
) -> var_data:
    if not self.m_vartab:
        raise general_error("invalid data container object reference")
    return self.m_vartab.assign(name, value)

compute_module.unassign(
    self: compute_module,
    name: String
):
    if not self.m_vartab:
        raise general_error("invalid data container object reference")
    return self.m_vartab.unassign(name)

compute_module.allocate(
    self: compute_module,
    name: String,
    length: Int
) -> Pointer[Float64]:
    v: var_data = self.assign(name, var_data())
    v.type = SSC_ARRAY
    v.num.resize_fill(length, 0.0)
    return v.num.data()

compute_module.allocate(
    self: compute_module,
    name: String,
    nrows: Int,
    ncols: Int
) -> Pointer[Float64]:
    v: var_data = self.assign(name, var_data())
    v.type = SSC_MATRIX
    v.num.resize_fill(nrows, ncols, 0.0)
    return v.num.data()

compute_module.allocate_matrix(
    self: compute_module,
    name: String,
    nrows: Int,
    ncols: Int
) -> util.matrix_t[Float64]:
    v: var_data = self.assign(name, var_data())
    v.type = SSC_MATRIX
    v.num.resize_fill(nrows, ncols, 0.0)
    return v.num

compute_module.value(
    self: compute_module,
    name: String
) -> var_data:
    v: var_data = self.lookup(name)
    if not v:
        raise general_error("ssc variable does not exist: '" + name + "'")
    return *v

compute_module.is_assigned(
    self: compute_module,
    name: String
) -> bool:
    if self.m_vartab:
        return self.m_vartab.is_assigned(name)
    else:
        return False

compute_module.as_integer(
    self: compute_module,
    name: String
) -> Int:
    if self.m_vartab:
        return self.m_vartab.as_integer(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_unsigned_long(
    self: compute_module,
    name: String
) -> Int:
    if self.m_vartab:
        return self.m_vartab.as_unsigned_long(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_boolean(
    self: compute_module,
    name: String
) -> bool:
    if self.m_vartab:
        return self.m_vartab.as_boolean(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_float(
    self: compute_module,
    name: String
) -> Float32:
    if self.m_vartab:
        return self.m_vartab.as_float(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_number(
    self: compute_module,
    name: String
) -> Float64:
    if self.m_vartab:
        return self.m_vartab.as_number(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_double(
    self: compute_module,
    name: String
) -> Float64:
    if self.m_vartab:
        return self.m_vartab.as_double(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_string(
    self: compute_module,
    name: String
) -> String:
    if self.m_vartab:
        return self.m_vartab.as_string(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_array(
    self: compute_module,
    name: String,
    count: Pointer[Int]
) -> Pointer[Float64]:
    if self.m_vartab:
        return self.m_vartab.as_array(name, count)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_vector_integer(
    self: compute_module,
    name: String
) -> List[Int]:
    if self.m_vartab:
        return self.m_vartab.as_vector_integer(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_vector_ssc_number_t(
    self: compute_module,
    name: String
) -> List[Float64]:
    if self.m_vartab:
        return self.m_vartab.as_vector_ssc_number_t(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_vector_double(
    self: compute_module,
    name: String
) -> List[Float64]:
    if self.m_vartab:
        return self.m_vartab.as_vector_double(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_vector_float(
    self: compute_module,
    name: String
) -> List[Float32]:
    if self.m_vartab:
        return self.m_vartab.as_vector_float(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_vector_unsigned_long(
    self: compute_module,
    name: String
) -> List[Int]:
    if self.m_vartab:
        return self.m_vartab.as_vector_unsigned_long(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_vector_bool(
    self: compute_module,
    name: String
) -> List[bool]:
    if self.m_vartab:
        return self.m_vartab.as_vector_bool(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_matrix(
    self: compute_module,
    name: String,
    rows: Pointer[Int],
    cols: Pointer[Int]
) -> Pointer[Float64]:
    if self.m_vartab:
        return self.m_vartab.as_matrix(name, rows, cols)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_matrix(
    self: compute_module,
    name: String
) -> util.matrix_t[Float64]:
    if self.m_vartab:
        return self.m_vartab.as_matrix(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_matrix_unsigned_long(
    self: compute_module,
    name: String
) -> util.matrix_t[Int]:
    if self.m_vartab:
        return self.m_vartab.as_matrix_unsigned_long(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.as_matrix_transpose(
    self: compute_module,
    name: String
) -> util.matrix_t[Float64]:
    if self.m_vartab:
        return self.m_vartab.as_matrix_transpose(name)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.get_matrix(
    self: compute_module,
    name: String,
    mat: util.matrix_t[Float64]
) -> bool:
    if self.m_vartab:
        return self.m_vartab.get_matrix(name, mat)
    else:
        raise general_error("compute_module error: var_table does not exist.")

compute_module.get_operand_value(
    self: compute_module,
    input: String,
    cur_var_name: String
) -> Float64:
    if len(input) < 1:
        raise check_error(cur_var_name, "input is null to get_operand_value", input)
    if input[0].isalpha():
        v: var_data = self.lookup(input)
        if not v:
            raise check_error(cur_var_name, "unassigned referenced", input)
        if v.type != SSC_NUMBER:
            raise check_error(cur_var_name, "number type required", input)
        return v.num
    else:
        x: Float64 = 0.0
        if not util.to_double(input, &x):
            raise check_error(cur_var_name, "number conversion", input)
        return Float64(x)

compute_module.check_required(
    self: compute_module,
    name: String
) -> bool:
    inf: var_info = self.info(name)
    if inf.required_if == None or len(inf.required_if) == 0:
        return False
    reqexpr: String = inf.required_if
    if reqexpr == "*":
        return True
    elif reqexpr == "?":
        return False
    elif len(reqexpr) > 2 and reqexpr[0] == '?' and reqexpr[1] == '=':
        v: var_data = self.lookup(name)
        if not v:
            v = self.assign(name, self.m_null_value)
            if not var_data.parse(inf.data_type, reqexpr[2:], *v):
                raise check_error(name, "could not parse default value in required_if spec (" +
                                  var_data.type_name(inf.data_type) + ")", reqexpr)
        return True
    else:
        pos: Int = -1
        expr_list: List[String] = util.split(util.lower_case(reqexpr), "&|", True, True)
        cur_result: Int = -1
        cur_cond_oper: Char = 0
        for expr in expr_list:
            if expr == "&":
                if cur_result == 0:
                    break
                cur_cond_oper = '&'
                continue
            elif expr == "|":
                if cur_result > 0:
                    break
                cur_cond_oper = '|'
                continue
            else:
                expr_result: Int = 0
                op: Char = 0
                if '=' in expr:
                    pos = expr.find('=')
                    op = '='
                elif '~' in expr:
                    pos = expr.find('~')
                    op = '~'
                elif '<' in expr:
                    pos = expr.find('<')
                    op = '<'
                elif '>' in expr:
                    pos = expr.find('>')
                    op = '>'
                elif ':' in expr:
                    pos = expr.find(':')
                    op = ':'
                if not op:
                    raise check_error(name, "invalid operator", expr)
                lhs: String = expr[:pos]
                rhs: String = expr[pos+1:]
                if len(lhs) < 1 or len(rhs) < 1:
                    raise check_error(name, "null lhs or rhs in subexpr", expr)
                if op == ':':
                    # handle built-in test operators
                    if lhs == "na":
                        expr_result = 1 if self.lookup(rhs) == None else 0
                    elif lhs == "a":
                        expr_result = 1 if self.lookup(rhs) != None else 0
                    elif lhs == "abt":
                        v = self.lookup(rhs)
                        if v != None and v.type == SSC_NUMBER and int(v.num) != 0:
                            return 1
                        else:
                            return 0
                    elif lhs == "abf":
                        v = self.lookup(rhs)
                        if v != None and v.type == SSC_NUMBER and int(v.num) == 0:
                            return 1
                        else:
                            return 0
                    elif lhs == "naof":
                        v = self.lookup(rhs)
                        if v == None:
                            return 1
                        if v.type == SSC_NUMBER and int(v.num) == 0:
                            return 1
                        return 0
                    else:
                        raise check_error(name, "invalid built-in test", expr)
                else:
                    lhs_val: Float64 = self.get_operand_value(lhs, name)
                    rhs_val: Float64 = self.get_operand_value(rhs, name)
                    if op == '=':
                        expr_result = 1 if lhs_val == rhs_val else 0
                    elif op == '~':
                        expr_result = 1 if lhs_val != rhs_val else 0
                    elif op == '<':
                        expr_result = 1 if lhs_val < rhs_val else 0
                    elif op == '>':
                        expr_result = 1 if lhs_val > rhs_val else 0
                    else:
                        raise check_error(name, "invalid numerical operator", expr)
                if cur_result < 0:
                    cur_result = expr_result
                elif cur_cond_oper == '&':
                    cur_result = 1 if (cur_result and expr_result) else 0
                elif cur_cond_oper == '|':
                    cur_result = 1 if (cur_result or expr_result) else 0
                else:
                    raise check_error(name, "invalid evaluation sequence", reqexpr)
        return cur_result != 0

compute_module.check_constraints(
    self: compute_module,
    name: String,
    fail_text: Pointer[String]
) -> bool:
    # define fail_constraint as a local closure
    def fail_constraint(str_: String) -> bool:
        fail_text.set("fail(" + name + ", " + expr + "): " + str_)
        return False
    inf: var_info = self.info(name)
    if inf.constraints == None:
        return True
    dat: var_data = self.value(name)
    exprlist: List[String] = util.split(inf.constraints, ",")
    for expr in exprlist:
        pos: Int = -1
        expr_low: String = util.lower_case(expr)
        if expr_low == "tmyepw":
            if dat.type != SSC_STRING or len(dat.str) <= 4:
                return fail_constraint("string data type required with length greater than 4 chars: " + dat.str)
            ext: String = util.lower_case(dat.str[len(dat.str)-3:])
            if ext not in ["tm2", "tm3", "epw", "csv"]:
                return fail_constraint("file extension was not tm2,tm3,epw,csv: " + ext)
        elif expr_low == "local_file":
            if dat.type != SSC_STRING:
                return fail_constraint("string data type required")
            # ifstream
            try:
                f_in = open(dat.str, "r")
                f_in.close()
            except:
                return fail_constraint("could not open for read: '" + dat.str + "'")
        elif expr_low == "mxh_schedule":
            if dat.type != SSC_STRING:
                return fail_constraint("string data type required")
            if len(dat.str) != 288:
                return fail_constraint("288 characters required (24x12) but " + str(len(dat.str)) + " found")
            for i in range(len(dat.str)):
                if dat.str[i] < '0' or dat.str[i] > '9':
                    return fail_constraint(util.format("invalid character %c at %d", dat.str[i], i))
        elif expr_low == "boolean":
            if dat.type != SSC_NUMBER:
                return fail_constraint("number data type required")
            val: Int = int(dat.num)
            if val != 0 and val != 1:
                return fail_constraint("value was not 0 nor 1")
        elif expr_low == "integer":
            if dat.type != SSC_NUMBER:
                return fail_constraint("number data type required")
            if Float64(int(dat.num)) != dat.num:
                return fail_constraint("number could not be interpreted as an integer: " + str(dat.num))
        elif expr_low == "tousched":
            if dat.type != SSC_STRING:
                return fail_constraint("string data type required")
            if len(dat.str) != 288:
                return fail_constraint("288 character string required (12x24 values)")
            for i in range(len(dat.str)):
                if util.schedule_char_to_int(dat.str[i]) == 0:
                    return fail_constraint("all digits must be between 1 and 9, inclusive")
        elif expr_low == "positive":
            if dat.type != SSC_NUMBER:
                raise constraint_error(name, "cannot test for positive with non-numeric type", expr)
            if dat.num <= 0.0:
                return fail_constraint(str(dat.num))
        elif expr_low == "percent":
            if dat.type != SSC_NUMBER:
                raise constraint_error(name, "cannot test for percent (%) constraint with non-numeric type", expr)
            if dat.num < 0.0 or dat.num > 100.0:
                return fail_constraint(str(dat.num))
        elif expr_low == "factor":
            if dat.type != SSC_NUMBER:
                raise constraint_error(name, "cannot test for factor (0..1) constraint with non-numeric type", expr)
            if dat.num < 0.0 or dat.num > 1.0:
                return fail_constraint(str(dat.num))
        elif expr_low == "ts_m":
            if dat.type != SSC_NUMBER:
                return fail_constraint("number data type required")
            val: Int = int(dat.num)
            if val not in [1, 5, 10, 15, 30, 60]:
                return fail_constraint("time step must be 1,5,10,15,30,60 minutes")
        elif '=' in expr_low:
            pos = expr_low.find('=')
            test: String = expr_low[:pos]
            rhs: String = expr_low[pos+1:]
            if test == "min":
                if dat.type != SSC_NUMBER:
                    raise constraint_error(name, "cannot test for min with non-numeric type", expr)
                minval: Float64 = 0.0
                if not util.to_double(rhs, &minval):
                    raise constraint_error(name, "test for min requires a number value", expr)
                if dat.num < Float64(minval):
                    return fail_constraint(str(dat.num))
            elif test == "max":
                if dat.type != SSC_NUMBER:
                    raise constraint_error(name, "cannot test for max with non-numeric type", expr)
                maxval: Float64 = 0.0
                if not util.to_double(rhs, &maxval):
                    raise constraint_error(name, "test for max requires a numeric value", expr)
                if dat.num > Float64(maxval):
                    return fail_constraint(str(dat.num))
            elif test == "length":
                if dat.type != SSC_ARRAY:
                    raise constraint_error(name, "cannot test for length with non-array type", expr)
                lenval: Int = 0
                if not util.to_integer(rhs, &lenval):
                    raise constraint_error(name, "test for length requires an integer value", expr)
                len_: Int = lenval
                if len(dat.num) != len_:
                    return fail_constraint(str(len(dat.num)))
            elif test == "length_equal":
                if dat.type != SSC_ARRAY:
                    raise constraint_error(name, "cannot test for length_equal with non-array type", expr)
                other: var_data = self.lookup(rhs)
                if not other:
                    raise constraint_error(name, "length_equal cannot find variable to test against", expr)
                if other.type == SSC_ARRAY:
                    if len(dat.num) != len(other.num):
                        return fail_constraint(str(len(other.num)))
                elif other.type == SSC_NUMBER:
                    if len(dat.num) != Int(other.num):
                        return fail_constraint(str(Int(other.num)))
                else:
                    raise constraint_error(name, "length_equal must specify a number or array variable to test against", expr)
            elif test == "length_multiple_of":
                if dat.type != SSC_ARRAY:
                    raise constraint_error(name, "cannot test for length_multiple_of with non-array type", expr)
                lenval: Int = 0
                if not util.to_integer(rhs, &lenval) or lenval < 1:
                    raise constraint_error(name, "test for length_multiple_of requires a positive integer value", expr)
                len_: Int = lenval
                multiplier: Int = len(dat.num) / len_
                if len(dat.num) < len_ or len_ * multiplier != len(dat.num):
                    return fail_constraint(str(len(dat.num)))
            elif test == "rows":
                if dat.type != SSC_MATRIX:
                    raise constraint_error(name, "cannot test for rows with non-matrix type", expr)
                nrows: Int = 0
                if not util.to_integer(rhs, &nrows) or nrows < 1:
                    raise constraint_error(name, "test for rows requires a positive integer value", expr)
                if dat.num.nrows() != nrows:
                    return fail_constraint(str(dat.num.nrows()))
            elif test == "cols":
                if dat.type != SSC_MATRIX:
                    raise constraint_error(name, "cannot test for cols with non-matrix type", expr)
                ncols: Int = 0
                if not util.to_integer(rhs, &ncols) or ncols < 1:
                    raise constraint_error(name, "test for cols requires a positive integer value", expr)
                if dat.num.ncols() != ncols:
                    return fail_constraint(str(dat.num.ncols()))
        else:
            raise constraint_error(name, "invalid test or expression", expr)
    return True

compute_module.check_timestep_seconds(
    self: compute_module,
    t_start: Float64,
    t_end: Float64,
    t_step: Float64
) -> Int:
    if t_start < 0.0:
        raise timestep_error(t_start, t_end, t_step, "start time must be 0 or greater")
    if t_end <= t_start:
        raise timestep_error(t_start, t_end, t_step, "end time must be greater than start time")
    if t_end > 8760.0 * 3600.0:
        raise timestep_error(t_start, t_end, t_step, "end time cannot be greater than 8760*3600")
    if t_step < 1.0:
        raise timestep_error(t_start, t_end, t_step, "time step must be greater or equal to than 1 sec")
    if t_step > 3600.0:
        raise timestep_error(t_start, t_end, t_step, "the maximum allowed time step is 3600 sec")
    duration: Float64 = t_end - t_start
    steps: Int = Int(ceil(duration / t_step))
    # time step notes: ...
    max0: Int = Int(steps * t_step)
    max1: Int = Int(duration)
    if max0 != max1:
        raise timestep_error(t_start, t_end, t_step,
                             util.format("invalid time step, must represent an integer number of minutes steps(%u != %u)", max0, max1))
    return steps

compute_module.accumulate_monthly(
    self: compute_module,
    ts_var: String,
    monthly_var: String,
    scale: Float64 = 1.0
) -> Pointer[Float64]:
    count: Int = 0
    ts: Pointer[Float64] = self.as_array(ts_var, &count)
    step_per_hour: Int = count / 8760
    if not ts or step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != count:
        raise exec_error("generic",
                         "Failed to accumulate time series (hourly or subhourly): " + ts_var + " to monthly: " + monthly_var)
    monthly: Pointer[Float64] = self.allocate(monthly_var, 12)
    c: Int = 0
    for m in range(12):
        monthly[m] = 0.0
        for d in range(util.nday[m]):
            for h in range(24):
                for j in range(step_per_hour):
                    monthly[m] += ts[c]
                    c += 1
        monthly[m] *= Float64(scale)
    return monthly

compute_module.accumulate_monthly_for_year(
    self: compute_module,
    ts_var: String,
    monthly_var: String,
    scale: Float64,
    step_per_hour: Int,
    year: Int
) -> Pointer[Float64]:
    count: Int = 0
    ts: Pointer[Float64] = self.as_array(ts_var, &count)
    annual_values: Int = step_per_hour * 8760
    if not ts or step_per_hour < 1 or step_per_hour > 60 or year * step_per_hour * 8760 > count:
        raise exec_error("generic",
                         "Failed to accumulate time series (hourly or subhourly): " + ts_var + " to monthly: " + monthly_var)
    monthly: Pointer[Float64] = self.allocate(monthly_var, 12)
    c: Int = (year - 1) * annual_values
    for m in range(12):
        monthly[m] = 0.0
        for d in range(util.nday[m]):
            for h in range(24):
                for j in range(step_per_hour):
                    monthly[m] += ts[c]
                    c += 1
        monthly[m] *= Float64(scale)
    return monthly

compute_module.accumulate_annual(
    self: compute_module,
    ts_var: String,
    annual_var: String,
    scale: Float64 = 1.0
) -> Float64:
    count: Int = 0
    ts: Pointer[Float64] = self.as_array(ts_var, &count)
    step_per_hour: Int = count / 8760
    if not ts or step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != count:
        raise exec_error("generic",
                         "Failed to accumulate time series (hourly or subhourly): " + ts_var + " to annual: " + annual_var)
    annual: Float64 = 0.0
    for i in range(count):
        annual += ts[i]
    self.assign(annual_var, var_data(Float64(annual * scale)))
    return Float64(annual * scale)

compute_module.accumulate_annual_for_year(
    self: compute_module,
    ts_var: String,
    annual_var: String,
    scale: Float64,
    step_per_hour: Int,
    year: Int,
    steps: Int = 8760
) -> Float64:
    count: Int = 0
    ts: Pointer[Float64] = self.as_array(ts_var, &count)
    annual_values: Int = step_per_hour * steps
    if not ts or step_per_hour < 1 or step_per_hour > 60 or year * step_per_hour * steps > count:
        raise exec_error("generic",
                         "Failed to accumulate time series (hourly or subhourly): " + ts_var + " to annual: " + annual_var)
    istart: Int = (year - 1) * annual_values
    iend: Int = year * annual_values
    sum_: Float64 = 0.0
    for i in range(istart, iend):
        sum_ += ts[i]
    self.assign(annual_var, var_data(Float64(sum_ * scale)))
    return Float64(sum_ * scale)

# End of file