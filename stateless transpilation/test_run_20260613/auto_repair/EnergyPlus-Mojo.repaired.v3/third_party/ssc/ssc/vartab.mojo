/**
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
*/
from lib_util import *
from vartab import *
from sscapi import *

var var_data_types: StaticTuple[String, 6] = StaticTuple[String, 6](
    "<invalid>", # SSC_INVALID
    "<string>",  # SSC_STRING
    "<number>",  # SSC_NUMBER
    "<array>",   # SSC_ARRAY
    "<matrix>",  # SSC_MATRIX
    "<table>",   # SSC_TABLE
)

@value
struct var_data:
    var type: UInt8
    var num: matrix_t[ssc_number_t]
    var str: String
    var table: var_table
    var vec: List[var_data]
    var mat: List[List[var_data]]

    def __init__(inout self):
        self.type = SSC_INVALID
        self.num = matrix_t[ssc_number_t]()
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, cp: var_data):
        self.copy(cp)

    def __init__(inout self, s: String):
        self.type = SSC_STRING
        self.str = s
        self.num = matrix_t[ssc_number_t]()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, n: ssc_number_t):
        self.type = SSC_NUMBER
        self.num = matrix_t[ssc_number_t]()
        self.num.assign(n)
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, n: Float32):
        self.type = SSC_NUMBER
        self.num = matrix_t[ssc_number_t]()
        self.num.assign(ssc_number_t(n))
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, n: Int):
        self.type = SSC_NUMBER
        self.num = matrix_t[ssc_number_t]()
        self.num.assign(ssc_number_t(n))
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, arr: List[Float64]):
        self.type = SSC_ARRAY
        self.num = matrix_t[ssc_number_t]()
        if len(arr) > 0:
            self.num.assign(pointer[ssc_number_t](arr.data), len(arr))
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, arr: List[Int]):
        self.type = SSC_ARRAY
        self.num = matrix_t[ssc_number_t]()
        self.num.resize(len(arr))
        for i in range(len(arr)):
            self.num[i] = ssc_number_t(arr[i])
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, pvalues: Pointer[ssc_number_t], length: Int):
        self.type = SSC_ARRAY
        self.num = matrix_t[ssc_number_t]()
        self.num.assign(pvalues, length)
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, pvalues: Pointer[ssc_number_t], length: Int):
        self.type = SSC_ARRAY
        self.num = matrix_t[ssc_number_t]()
        self.num.assign(pvalues, length)
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, pvalues: Pointer[ssc_number_t], nr: Int, nc: Int):
        self.type = SSC_MATRIX
        self.num = matrix_t[ssc_number_t]()
        self.num.assign(pvalues, nr, nc)
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, matrix: matrix_t[ssc_number_t]):
        self.type = SSC_MATRIX
        self.num = matrix
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, vt: var_table):
        self.type = SSC_TABLE
        self.table = vt
        self.num = matrix_t[ssc_number_t]()
        self.str = String()
        self.vec = List[var_data]()
        self.mat = List[List[var_data]]()

    def __init__(inout self, vd_vec: List[var_data]):
        self.type = SSC_DATARR
        self.vec = vd_vec
        self.num = matrix_t[ssc_number_t]()
        self.str = String()
        self.table = var_table()
        self.mat = List[List[var_data]]()

    def __init__(inout self, vd_mat: List[List[var_data]]):
        self.type = SSC_DATMAT
        self.mat = vd_mat
        self.num = matrix_t[ssc_number_t]()
        self.str = String()
        self.table = var_table()
        self.vec = List[var_data]()

    def type_name(self) -> Pointer[UInt8]:
        if self.type < 6:
            return var_data_types[self.type].data()
        else:
            return Pointer[UInt8]()

    @staticmethod
    def type_name(type: Int) -> String:
        if type >= 0 and type < 5:
            return var_data_types[type]
        else:
            return ""

    def to_string(self) -> String:
        return var_data.to_string(self)

    @staticmethod
    def to_string(value: var_data) -> String:
        if value.type == SSC_STRING:
            return value.str
        elif value.type == SSC_NUMBER:
            return util.to_string(value.num.value())
        elif value.type == SSC_ARRAY:
            var s = String()
            for i in range(value.num.length()):
                s += util.to_string(Float64(value.num[i]))
                if i < value.num.length() - 1:
                    s += ','
            return s
        elif value.type == SSC_MATRIX:
            var s = String()
            for r in range(value.num.nrows()):
                s += "["
                for c in range(value.num.ncols()):
                    s += util.to_string(Float64(value.num.at(r, c)))
                    if c < value.num.ncols() - 1:
                        s += ' '
                s += "]"
            return s
        return "<invalid>"

    def arr_vector(self) -> List[Float64]:
        if self.type != SSC_ARRAY:
            raise Error("arr_vector error: var_data type not SSC_ARRAY.")
        var v = List[Float64]()
        for i in range(self.num.length()):
            v.append(self.num[i])
        return v

    def matrix_vector(self) -> List[List[Float64]]:
        if self.type != SSC_MATRIX:
            raise Error("arr_matrix error: var_data type not SSC_MATRIX.")
        var v = List[List[Float64]]()
        for i in range(self.num.nrows()):
            var row = List[Float64]()
            for j in range(self.num.ncols()):
                row.append(self.num.at(i, j))
            v.append(row)
        return v

    @staticmethod
    def parse(type: UInt8, buf: String, inout value: var_data) -> Bool:
        if type == SSC_STRING:
            value.type = SSC_STRING
            value.str = buf
            return True
        elif type == SSC_NUMBER:
            var x: Float64
            if util.to_double(buf, x):
                value.type = SSC_NUMBER
                value.num = matrix_t[ssc_number_t]()
                value.num.assign(ssc_number_t(x))
                return True
            else:
                return False
        elif type == SSC_ARRAY:
            var tokens = util.split(buf, " ,\t[]\n")
            value.type = SSC_ARRAY
            value.num.resize_fill(len(tokens), 0.0)
            for i in range(len(tokens)):
                var x: Float64
                if util.to_double(tokens[i], x):
                    value.num[i] = ssc_number_t(x)
                else:
                    return False
            return True
        elif type == SSC_MATRIX:
            var rows = util.split(buf, "[]\n")
            if len(rows) < 1:
                return False
            var cur_row = util.split(rows[0], " ,\t")
            if len(cur_row) < 1:
                return False
            value.type = SSC_MATRIX
            value.num.resize_fill(len(rows), len(cur_row), 0.0)
            for c in range(len(cur_row)):
                var x: Float64
                if util.to_double(cur_row[c], x):
                    value.num.at(0, c) = ssc_number_t(x)
            for r in range(1, len(rows)):
                cur_row = util.split(rows[r], " ,\t")
                for c in range(min(len(cur_row), value.num.ncols())):
                    var x: Float64
                    if util.to_double(cur_row[c], x):
                        value.num.at(r, c) = ssc_number_t(x)
            return True
        return False

    def __copyinit__(inout self, other: var_data):
        self.copy(other)

    def __moveinit__(inout self, owned other: var_data):
        self.type = other.type
        self.num = other.num
        self.str = other.str
        self.table = other.table
        self.vec = other.vec
        self.mat = other.mat

    def copy(inout self, rhs: var_data):
        self.type = rhs.type
        self.num = rhs.num
        self.str = rhs.str
        self.table = rhs.table
        self.vec = List[var_data]()
        for i in rhs.vec:
            self.vec.append(i)
        self.mat = List[List[var_data]]()
        for i in rhs.mat:
            var vt = List[var_data]()
            for j in i:
                vt.append(j)
            self.mat.append(vt)

    def clear(inout self):
        self.type = SSC_INVALID
        self.num.clear()
        self.str.clear()
        self.table.clear()
        self.vec.clear()
        self.mat.clear()

    def __del__(owned self):

@value
struct general_error(Exception):
    var err_text: String
    var time: Float32

    def __init__(inout self, s: String, t: Float32 = -1.0):
        self.err_text = s
        self.time = t

@value
struct cast_error(general_error):
    def __init__(inout self, target_type: String, source: var_data, name: String):
        self.err_text = "cast fail: <" + target_type + "> from " + source.type_name() + " for: " + name
        self.time = -1.0

@value
struct var_table:
    var m_hash: Dict[String, var_data]
    var m_iterator: Int

    def __init__(inout self):
        self.m_hash = Dict[String, var_data]()
        self.m_iterator = 0

    def __init__(inout self, rhs: var_table):
        self.m_hash = Dict[String, var_data]()
        self.m_iterator = 0
        self = rhs

    def __copyinit__(inout self, other: var_table):
        self.m_hash = Dict[String, var_data]()
        self.m_iterator = 0
        self = other

    def __moveinit__(inout self, owned other: var_table):
        self.m_hash = other.m_hash
        self.m_iterator = other.m_iterator

    def __del__(owned self):
        self.clear()

    def __iassign__(inout self, rhs: var_table) -> Self:
        self.clear()
        for it in rhs.m_hash.items():
            self.assign_match_case(it.key, it.value)
        return self

    def clear(inout self):
        self.m_hash.clear()

    def is_assigned(inout self, name: String) -> Bool:
        return self.lookup(name) != None

    def unassign(inout self, name: String):
        var lcname = util.lower_case(name)
        if lcname in self.m_hash:
            self.m_hash.pop(lcname)

    def rename(inout self, oldname: String, newname: String) -> Bool:
        return self.rename_match_case(util.lower_case(oldname), util.lower_case(newname))

    def rename_match_case(inout self, oldname: String, newname: String) -> Bool:
        if oldname in self.m_hash:
            var data = self.m_hash[oldname]
            self.m_hash.pop(oldname)
            var lcnewname = newname
            if lcnewname in self.m_hash:
                self.m_hash[lcnewname] = data
            else:
                self.m_hash[lcnewname] = data
            return True
        else:
            return False

    def first(inout self) -> Pointer[UInt8]:
        if len(self.m_hash) > 0:
            self.m_iterator = 0
            return self.m_hash.keys()[0].data()
        else:
            return Pointer[UInt8]()

    def next(inout self) -> Pointer[UInt8]:
        self.m_iterator += 1
        if self.m_iterator < len(self.m_hash):
            return self.m_hash.keys()[self.m_iterator].data()
        return Pointer[UInt8]()

    def key(inout self, pos: Int) -> Pointer[UInt8]:
        if len(self.m_hash) == 0:
            return Pointer[UInt8]()
        if pos < len(self.m_hash):
            return self.m_hash.keys()[pos].data()
        return Pointer[UInt8]()

    def size(self) -> UInt32:
        return UInt32(len(self.m_hash))

    def allocate(inout self, name: String, length: Int) -> Pointer[ssc_number_t]:
        var v = self.assign(name, var_data())
        v.type = SSC_ARRAY
        v.num.resize_fill(length, 0.0)
        return v.num.data()

    def allocate(inout self, name: String, nrows: Int, ncols: Int) -> Pointer[ssc_number_t]:
        var v = self.assign(name, var_data())
        v.type = SSC_MATRIX
        v.num.resize_fill(nrows, ncols, 0.0)
        return v.num.data()

    def allocate_matrix(inout self, name: String, nrows: Int, ncols: Int) -> matrix_t[ssc_number_t]:
        var v = self.assign(name, var_data())
        v.type = SSC_MATRIX
        v.num.resize_fill(nrows, ncols, 0.0)
        return v.num

    def assign(inout self, name: String, val: var_data) -> var_data:
        var v = self.lookup(name)
        if v == None:
            v = var_data()
            self.m_hash[util.lower_case(name)] = v
        v.copy(val)
        return v

    def assign_match_case(inout self, name: String, val: var_data) -> var_data:
        var v = self.lookup(name)
        if v == None:
            v = var_data()
            self.m_hash[name] = v
        v.copy(val)
        return v

    def merge(inout self, rhs: var_table, overwrite_existing: Bool):
        for it in rhs.m_hash.items():
            if self.is_assigned(it.key):
                if overwrite_existing:
                    self.assign_match_case(it.key, it.value)
            else:
                self.assign_match_case(it.key, it.value)

    def lookup(inout self, name: String) -> var_data:
        if name in self.m_hash:
            return self.m_hash[name]
        var lcname = util.lower_case(name)
        if lcname in self.m_hash:
            return self.m_hash[lcname]
        return None

    def lookup_match_case(inout self, name: String) -> var_data:
        if name in self.m_hash:
            return self.m_hash[name]
        return None

    def as_unsigned_long(inout self, name: String) -> Int:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_NUMBER:
            raise cast_error("unsigned long", x, name)
        return Int(x.num)

    def as_integer(inout self, name: String) -> Int:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_NUMBER:
            raise cast_error("integer", x, name)
        return Int(x.num)

    def as_boolean(inout self, name: String) -> Bool:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_NUMBER:
            raise cast_error("boolean", x, name)
        return Bool(Int(x.num != 0.0))

    def as_float(inout self, name: String) -> Float32:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_NUMBER:
            raise cast_error("float", x, name)
        return Float32(x.num)

    def as_number(inout self, name: String) -> ssc_number_t:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_NUMBER:
            raise cast_error("ssc_number_t", x, name)
        return x.num

    def as_double(inout self, name: String) -> Float64:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_NUMBER:
            raise cast_error("double", x, name)
        return Float64(x.num)

    def as_string(inout self, name: String) -> Pointer[UInt8]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_STRING:
            raise cast_error("string", x, name)
        return x.str.data()

    def as_array(inout self, name: String, count: Pointer[Int]) -> Pointer[ssc_number_t]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_ARRAY:
            raise cast_error("array", x, name)
        if count:
            count[0] = x.num.length()
        return x.num.data()

    def as_vector_integer(inout self, name: String) -> List[Int]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_ARRAY:
            raise cast_error("array", x, name)
        var len = x.num.length()
        var v = List[Int](len)
        var p = x.num.data()
        for k in range(len):
            v[k] = Int(p[k])
        return v

    def as_vector_ssc_number_t(inout self, name: String) -> List[ssc_number_t]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_ARRAY:
            raise cast_error("array", x, name)
        var len = x.num.length()
        var v = List[ssc_number_t](len)
        var p = x.num.data()
        for k in range(len):
            v[k] = p[k]
        return v

    def as_vector_double(inout self, name: String) -> List[Float64]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_ARRAY:
            raise cast_error("array", x, name)
        var len = x.num.length()
        var v = List[Float64](len)
        var p = x.num.data()
        for k in range(len):
            v[k] = Float64(p[k])
        return v

    def as_vector_float(inout self, name: String) -> List[Float32]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_ARRAY:
            raise cast_error("array", x, name)
        var len = x.num.length()
        var v = List[Float32](len)
        var p = x.num.data()
        for k in range(len):
            v[k] = Float32(p[k])
        return v

    def as_vector_unsigned_long(inout self, name: String) -> List[Int]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_ARRAY:
            raise cast_error("array", x, name)
        var len = x.num.length()
        var v = List[Int](len)
        var p = x.num.data()
        for k in range(len):
            v[k] = Int(p[k])
        return v

    def as_vector_bool(inout self, name: String) -> List[Bool]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_ARRAY:
            raise cast_error("array", x, name)
        var len = x.num.length()
        var v = List[Bool](len)
        var p = x.num.data()
        for k in range(len):
            v[k] = p[k] != 0.0
        return v

    def as_matrix(inout self, name: String, rows: Pointer[Int], cols: Pointer[Int]) -> Pointer[ssc_number_t]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_MATRIX:
            raise cast_error("matrix", x, name)
        if rows:
            rows[0] = x.num.nrows()
        if cols:
            cols[0] = x.num.ncols()
        return x.num.data()

    def as_matrix(inout self, name: String) -> matrix_t[Float64]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_MATRIX:
            raise cast_error("matrix", x, name)
        var mat = matrix_t[Float64](x.num.nrows(), x.num.ncols(), 0.0)
        for r in range(x.num.nrows()):
            for c in range(x.num.ncols()):
                mat.at(r, c) = Float64(x.num(r, c))
        return mat

    def as_matrix_unsigned_long(inout self, name: String) -> matrix_t[Int]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_MATRIX:
            raise cast_error("matrix", x, name)
        var mat = matrix_t[Int](x.num.nrows(), x.num.ncols(), 0)
        for r in range(x.num.nrows()):
            for c in range(x.num.ncols()):
                mat.at(r, c) = Int(x.num(r, c))
        return mat

    def as_matrix_transpose(inout self, name: String) -> matrix_t[Float64]:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_MATRIX:
            raise cast_error("matrix", x, name)
        var mat = matrix_t[Float64](x.num.ncols(), x.num.nrows(), 0.0)
        for r in range(x.num.nrows()):
            for c in range(x.num.ncols()):
                mat.at(c, r) = Float64(x.num(r, c))
        return mat

    def get_matrix(inout self, name: String, inout mat: matrix_t[ssc_number_t]) -> Bool:
        var x = self.lookup(name)
        if x == None:
            raise general_error(name + " not assigned")
        if x.type != SSC_MATRIX:
            raise cast_error("matrix", x, name)
        var nrows: Int
        var ncols: Int
        var arr = self.as_matrix(name, nrows, ncols)
        if nrows < 1 or ncols < 1:
            return False
        mat.resize_fill(nrows, ncols, 1.0)
        for r in range(nrows):
            for c in range(ncols):
                mat.at(r, c) = arr[r * ncols + c]
        return True

    def get_hash(inout self) -> Dict[String, var_data]:
        return self.m_hash

def vt_get_int(inout vt: var_table, name: String, inout lvalue: Int):
    var vd = vt.lookup(name)
    if vd:
        lvalue = Int(vd.num)
    else:
        raise Error(name + " must be assigned.")

def vt_get_uint(inout vt: var_table, name: String, inout lvalue: Int):
    var vd = vt.lookup(name)
    if vd:
        lvalue = Int(vd.num)
    else:
        raise Error(name + " must be assigned.")

def vt_get_bool(inout vt: var_table, name: String, inout lvalue: Bool):
    var vd = vt.lookup(name)
    if vd:
        lvalue = Bool(vd.num)
    else:
        raise Error(name + " must be assigned.")

def vt_get_number(inout vt: var_table, name: String, inout lvalue: Float64):
    var vd = vt.lookup(name)
    if vd:
        lvalue = vd.num
    else:
        raise Error(name + " must be assigned.")

def vt_get_array_vec(inout vt: var_table, name: String, inout vec_double: List[Float64]):
    var vd = vt.lookup(name)
    if vd:
        if vd.type != SSC_ARRAY:
            raise Error(name + " must be array type.")
        vec_double = vd.arr_vector()
    else:
        raise Error(name + " must be assigned.")

def vt_get_array_vec(inout vt: var_table, name: String, inout vec_int: List[Int]):
    var vd = vt.lookup(name)
    if vd:
        if vd.type != SSC_ARRAY:
            raise Error(name + " must be array type.")
        vec_int.clear()
        for i in vd.arr_vector():
            vec_int.append(Int(i))
    else:
        raise Error(name + " must be assigned.")

def vt_get_matrix(inout vt: var_table, name: String, inout matrix: matrix_t[Float64]):
    var vd = vt.lookup(name)
    if vd:
        if vd.type == SSC_ARRAY:
            var vec_double = vd.arr_vector()
            matrix.resize(len(vec_double))
            for i in range(len(vec_double)):
                matrix.at(i) = vec_double[i]
        elif vd.type != SSC_MATRIX:
            raise Error(name + " must be matrix type.")
        matrix = vd.num
    else:
        raise Error(name + " must be assigned.")

def vt_get_matrix_vec(inout vt: var_table, name: String, inout mat: List[List[Float64]]):
    var vd = vt.lookup(name)
    if vd:
        mat = vd.matrix_vector()
    else:
        raise Error(name + " must be assigned.")