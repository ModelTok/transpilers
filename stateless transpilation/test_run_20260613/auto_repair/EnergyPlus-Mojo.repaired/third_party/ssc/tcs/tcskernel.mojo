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
from tcstype import *
from sys import *
from math import *
from os import *
from dl import *
from memory import *
from string import String
from vector import DynamicVector
from dict import Dict
from io import StringWriter

alias _CRT_SECURE_NO_WARNINGS = 1

def dll_open(name: String) -> Pointer[None]:
    return dlopen(name, RTLD_NOW)

def dll_close(handle: Pointer[None]):
    dlclose(handle)

def dll_sym(handle: Pointer[None], name: String) -> Pointer[None]:
    return dlsym(handle, name)

def tcsdynamictypes() -> Pointer[Pointer[tcstypeinfo]]:
    # extern "C" tcstypeinfo **tcsdynamictypes();
    # This function is expected to be provided by the dynamic library
    return Pointer[Pointer[tcstypeinfo]]()

var sg_tcsTypeProvider = tcstypeprovider()

@value
struct dyndata:
    var path: String
    var dynlib: Pointer[None]
    var types: Pointer[Pointer[tcstypeinfo]]

@value
struct typedata:
    var type: String
    var info: Pointer[tcstypeinfo]
    var dyn: Pointer[dyndata]

@value
struct connection:
    var target_unit: Int
    var target_index: Int
    var ftol: Float64
    var arridx: Int

@value
struct unit:
    var id: Int
    var name: String
    var type: Pointer[tcstypeinfo]
    var values: DynamicVector[tcsvalue]
    var conn: DynamicVector[DynamicVector[connection]]
    var ncall: Int
    var mustcall: Bool
    var instance: Pointer[None]
    var context: tcscontext

class tcstypeprovider:
    var m_types: DynamicVector[typedata]
    var m_libraries: DynamicVector[dyndata]
    var m_pathList: DynamicVector[String]
    var m_messages: DynamicVector[String]

    def __init__(inout self):
        self.m_types = DynamicVector[typedata]()
        self.m_libraries = DynamicVector[dyndata]()
        self.m_pathList = DynamicVector[String]()
        self.m_messages = DynamicVector[String]()
        var built_in = tcsdynamictypes()
        var i: Int = 0
        while True:
            var ti = built_in[i]
            if ti.is_null():
                break
            self.register_type(ti[].name, ti)
            i += 1

    def __del__(inout self):
        self.unload_libraries()

    def add_search_path(inout self, path: String):
        var it = self.m_pathList.find(path)
        if it == -1:
            self.m_pathList.push_back(path)

    def clear_search_paths(inout self):
        self.m_pathList.clear()

    def register_type(inout self, type: String, ti: Pointer[tcstypeinfo]):
        var x = typedata()
        x.type = type
        x.dyn = Pointer[dyndata]()
        x.info = ti
        self.m_types.push_back(x)

    def types(self) -> DynamicVector[typedata]:
        return self.m_types

    def load_library(inout self, name: String) -> Int:
        var ext: String
        #if defined(_WIN32)
        #    ext = ".dll"
        #elif defined(__MACH__)
        #    ext = ".dylib"
        #else
        ext = ".so"
        #endif
        for it in range(len(self.m_pathList)):
            var path = self.m_pathList[it] + "/" + name + ext
            self.m_messages.push_back("attempting: " + path)
            var pdl: Pointer[None]
            var pf: Pointer[None]
            var ti: Pointer[Pointer[tcstypeinfo]]
            pdl = dll_open(path)
            if not pdl.is_null():
                pf = dll_sym(pdl, "tcsdynamictypes")
                if not pf.is_null():
                    ti = (Pointer[Pointer[tcstypeinfo]](pf))()
                    if not ti.is_null():
                        var d = dyndata()
                        d.path = path
                        d.dynlib = pdl
                        d.types = ti
                        self.m_libraries.push_back(d)
                        var idx: Int = 0
                        while not ti[idx].is_null():
                            var x = typedata()
                            x.type = String(ti[idx][].name)
                            x.dyn = Pointer[dyndata](address_of(self.m_libraries[len(self.m_libraries)-1]))
                            x.info = ti[idx]
                            self.m_types.push_back(x)
                            var ss = StringWriter()
                            ss.write("type ")
                            ss.write(ti[idx][].name)
                            ss.write("\n\tdesc=")
                            ss.write(ti[idx][].description)
                            ss.write("\n\tauth=")
                            ss.write(ti[idx][].author)
                            ss.write("\n\ttime=")
                            ss.write(ti[idx][].timestamp)
                            ss.write("\n\tver=")
                            ss.write(ti[idx][].version)
                            ss.write("\n\treqker=")
                            ss.write(ti[idx][].require_kernel_version)
                            ss.write("\n\tonconv=")
                            ss.write(ti[idx][].call_after_convergence)
                            self.m_messages.push_back(ss.str())
                            idx += 1
                        var ss2 = StringWriter()
                        ss2.write("loaded ")
                        ss2.write(idx)
                        ss2.write(" dynamic type(s) from ")
                        ss2.write(path)
                        self.m_messages.push_back(ss2.str())
                        return idx
                if not pdl.is_null():
                    dll_close(pdl)
        return 0

    def unload_libraries(inout self):
        var idx: Int = 0
        while idx < len(self.m_types):
            if not self.m_types[idx].dyn.is_null():
                self.m_messages.push_back("unregistered type " + self.m_types[idx].type)
                self.m_types.erase(idx)
            else:
                idx += 1
        for it in range(len(self.m_libraries)):
            if not self.m_libraries[it].dynlib.is_null():
                self.m_messages.push_back("unloaded dynamic type library " + self.m_libraries[it].path)
                dll_close(self.m_libraries[it].dynlib)
        self.m_libraries.clear()

    def find_type(self, type: String) -> Pointer[tcstypeinfo]:
        for it in range(len(self.m_types)):
            if self.m_types[it].type == type and not self.m_types[it].info.is_null():
                return self.m_types[it].info
        return Pointer[tcstypeinfo]()

def _parse_number_list(inout p: Pointer[UInt8], inout vals: DynamicVector[Float64]):
    var buf = DynamicVector[UInt8]()
    buf.resize(256)
    while True:
        while p[0] != 0 and (p[0] == 32 or p[0] == 9 or p[0] == 44):
            p += 1
        var pb: Int = 0
        var idx: Int = 0
        while p[0] != 0 and (isdigit(p[0]) or p[0] == 43 or p[0] == 45 or p[0] == 46 or p[0] == 101 or p[0] == 69) and idx < 254:
            buf[pb] = p[0]
            pb += 1
            p += 1
            idx += 1
        buf[pb] = 0
        vals.push_back(atof(String(buf.data(), pb)))
        while p[0] != 0 and (p[0] == 32 or p[0] == 9):
            p += 1
        if p[0] != 44:
            return

def tcsvalue_free(inout v: tcsvalue):
    if v.type == TCS_ARRAY:
        delete v.data.array.values
    elif v.type == TCS_MATRIX:
        delete v.data.matrix.values
    elif v.type == TCS_STRING:
        delete v.data.cstr
    v.type = TCS_INVALID

def tcsvalue_parse_array(inout v: tcsvalue, s: String) -> Bool:
    if len(s) == 0:
        return False
    var vals = DynamicVector[Float64]()
    var p = s.data()
    _parse_number_list(p, vals)
    if len(vals) == 0:
        return False
    tcsvalue_free(v)
    v.type = TCS_ARRAY
    v.data.array.values = Pointer[Float64](alloc[Float64](len(vals)))
    v.data.array.length = UInt32(len(vals))
    for i in range(len(vals)):
        v.data.array.values[i] = vals[i]
    return True

def tcsvalue_parse_matrix(inout v: tcsvalue, s: String) -> Bool:
    if len(s) == 0:
        return False
    var mat = DynamicVector[DynamicVector[Float64]]()
    var p = s.data()
    var maxcol: Int = 0
    while p[0] == 91:
        p += 1
        var row = DynamicVector[Float64]()
        _parse_number_list(p, row)
        mat.push_back(row)
        if len(row) > maxcol:
            maxcol = len(row)
        while p[0] != 0 and (p[0] == 32 or p[0] == 9):
            p += 1
        if p[0] != 93:
            return False
        p += 1
        while p[0] != 0 and (p[0] == 32 or p[0] == 9):
            p += 1
    if len(mat) == 0 or maxcol == 0:
        return False
    var len_total = len(mat) * maxcol
    tcsvalue_free(v)
    v.type = TCS_MATRIX
    v.data.matrix.values = Pointer[Float64](alloc[Float64](len_total))
    v.data.matrix.nrows = Int32(len(mat))
    v.data.matrix.ncols = Int32(maxcol)
    for i in range(len_total):
        v.data.matrix.values[i] = 0.0
    for r in range(len(mat)):
        for c in range(maxcol):
            if c < len(mat[r]):
                TCS_MATRIX_INDEX(v, r, c) = mat[r][c]
    return True

def tcsvalue_set_number(inout v: tcsvalue, d: Float64):
    tcsvalue_free(v)
    v.type = TCS_NUMBER
    v.data.value = d

def tcsvalue_set_array(inout v: tcsvalue, p: Pointer[Float64], len: Int):
    if p.is_null() or len < 1:
        return
    tcsvalue_free(v)
    v.type = TCS_ARRAY
    v.data.array.values = Pointer[Float64](alloc[Float64](len))
    v.data.array.length = UInt32(len)
    for i in range(len):
        v.data.array.values[i] = p[i]

def tcsvalue_set_matrix(inout v: tcsvalue, p: Pointer[Float64], nr: Int, nc: Int):
    if p.is_null() or nr * nc < 1:
        return
    tcsvalue_free(v)
    v.type = TCS_MATRIX
    var len_total = nr * nc
    v.data.matrix.values = Pointer[Float64](alloc[Float64](len_total))
    v.data.matrix.nrows = Int32(nr)
    v.data.matrix.ncols = Int32(nc)
    for i in range(nr * nc):
        v.data.matrix.values[i] = p[i]

def tcsvalue_set_string(inout v: tcsvalue, s: String):
    tcsvalue_free(v)
    v.type = TCS_STRING
    if len(s) == 0:
        v.data.cstr = Pointer[UInt8](alloc[UInt8](1))
        v.data.cstr[0] = 0
        return
    v.data.cstr = Pointer[UInt8](alloc[UInt8](len(s) + 1))
    for i in range(len(s)):
        v.data.cstr[i] = s[i]
    v.data.cstr[len(s)] = 0

def tcsvalue_as_string(v: tcsvalue) -> String:
    var ibuf = DynamicVector[UInt8]()
    ibuf.resize(128)
    var buf: String
    var j: Int
    var k: Int
    if v.type == TCS_NUMBER:
        mysnprintf(ibuf.data(), 126, "%lg", v.data.value)
        return String(ibuf.data())
    elif v.type == TCS_STRING:
        return "'" + String(v.data.cstr) + "'"
    elif v.type == TCS_ARRAY:
        buf = "[ "
        for j in range(v.data.array.length):
            mysnprintf(ibuf.data(), 126, "%lg%c", v.data.array.values[j], (j < v.data.array.length - 1) ? 44 : 32)
            buf += String(ibuf.data())
        buf += "]"
        return buf
    elif v.type == TCS_MATRIX:
        mysnprintf(ibuf.data(), 126, "{ %dx%d ", v.data.matrix.nrows, v.data.matrix.ncols)
        buf = String(ibuf.data())
        for j in range(v.data.matrix.nrows):
            buf += " ["
            for k in range(v.data.matrix.ncols):
                mysnprintf(ibuf.data(), 126, "%lg%c", TCS_MATRIX_INDEX(v, j, k), (k < v.data.matrix.ncols - 1) ? 44 : 32)
                buf += String(ibuf.data())
            buf += "]"
        buf += " }"
        return buf
    return "<invalid>"

def _message(t: Pointer[_tcscontext], msgtype: Int, message: String):
    var k = Pointer[tcskernel](t[].kernel_internal)
    var uid = t[].unit_internal
    k[].message(uid, msgtype, message)

def _progress(t: Pointer[_tcscontext], percent: Float32, message: String) -> Bool:
    var k = Pointer[tcskernel](t[].kernel_internal)
    return k[].progress(percent, message)

def _get_value(t: Pointer[_tcscontext], idx: Int) -> Pointer[tcsvalue]:
    var u = Pointer[unit](t[].unit_internal)
    if u.is_null() or idx < 0 or idx >= len(u[].values):
        return Pointer[tcsvalue]()
    else:
        return address_of(u[].values[idx])

def _get_num_values(t: Pointer[_tcscontext]) -> Int:
    var u = Pointer[unit](t[].unit_internal)
    if u.is_null():
        return 0
    return len(u[].values)

class tcskernel:
    var m_proceedAnyway: Bool
    var m_maxIterations: Int
    var m_currentTime: Float64
    var m_timeStep: Float64
    var m_startTime: Float64
    var m_endTime: Float64
    var m_units: DynamicVector[unit]
    var m_provider: Pointer[tcstypeprovider]

    def __init__(inout self, prov: Pointer[tcstypeprovider]):
        self.m_provider = prov
        self.m_proceedAnyway = True
        self.m_maxIterations = 100
        self.m_currentTime = 0.0
        self.m_timeStep = 0.0
        self.m_startTime = 0.0
        self.m_endTime = 0.0
        self.m_units = DynamicVector[unit]()

    def __del__(inout self):

    def version(self) -> Int:
        return TCS_KERNEL_VERSION

    def set_max_iterations(inout self, iter: Int, proceed: Bool):
        if iter >= 1:
            self.m_maxIterations = iter
        self.m_proceedAnyway = proceed

    def current_time(self) -> Float64:
        return self.m_currentTime

    def time_step(self) -> Float64:
        return self.m_timeStep

    def message(inout self, unit: Int, msgtype: Int, text: String):
        var tbuf = DynamicVector[UInt8]()
        tbuf.resize(128)
        if unit >= 0 and unit < len(self.m_units):
            my_snprintf(tbuf.data(), 128, "time %.2lf { %s %d }:\n", self.current_time(), self.m_units[unit].name, unit)
        else:
            my_snprintf(tbuf.data(), 128, "time %.2lf { invalid unit %d }:\n", self.current_time(), unit)
        self.message(String(tbuf.data()) + text, msgtype)

    def message(inout self, text: String, msgtype: Int):
        var preface = "Notice: "
        if msgtype == TCS_WARNING:
            preface = "Warning: "
        elif msgtype == TCS_ERROR:
            preface = "Error: "
        print(text)

    def progress(self, percent: Float32, status: String) -> Bool:
        print(percent, "% ", status)
        return True

    def converged(self, time: Float64) -> Bool:
        return True

    def set_unit_name(inout self, id: Int, name: String):
        if id >= 0 and id < len(self.m_units):
            self.m_units[id].name = name

    def set_unit_value(inout self, id: Int, idx: Int, val: Float64):
        if id >= 0 and id < len(self.m_units) and idx >= 0 and idx < len(self.m_units[id].values):
            tcsvalue_set_number(self.m_units[id].values[idx], val)

    def set_unit_value(inout self, id: Int, idx: Int, p: Pointer[Float64], len: Int):
        if id >= 0 and id < len(self.m_units) and idx >= 0 and idx < len(self.m_units[id].values):
            tcsvalue_set_array(self.m_units[id].values[idx], p, len)

    def set_unit_value(inout self, id: Int, idx: Int, p: Pointer[Float64], nr: Int, nc: Int):
        if id >= 0 and id < len(self.m_units) and idx >= 0 and idx < len(self.m_units[id].values):
            tcsvalue_set_matrix(self.m_units[id].values[idx], p, nr, nc)

    def set_unit_value(inout self, id: Int, idx: Int, s: String):
        if id >= 0 and id < len(self.m_units) and idx >= 0 and idx < len(self.m_units[id].values):
            tcsvalue_set_string(self.m_units[id].values[idx], s)

    def set_unit_value(inout self, id: Int, name: String, val: Float64):
        self.set_unit_value(id, self.find_var(id, name), val)

    def set_unit_value(inout self, id: Int, name: String, p: Pointer[Float64], len: Int):
        self.set_unit_value(id, self.find_var(id, name), p, len)

    def set_unit_value(inout self, id: Int, name: String, p: Pointer[Float64], nr: Int, nc: Int):
        self.set_unit_value(id, self.find_var(id, name), p, nr, nc)

    def set_unit_value(inout self, id: Int, name: String, s: String):
        self.set_unit_value(id, self.find_var(id, name), s)

    def get_unit_value_number(self, id: Int, name: String) -> Float64:
        var idx = self.find_var(id, name)
        if id >= 0 and id < len(self.m_units) and idx >= 0 and idx < len(self.m_units[id].values):
            if self.m_units[id].values[idx].type == TCS_NUMBER:
                return self.m_units[id].values[idx].data.value
        return Float64.nan

    def get_unit_value_string(self, id: Int, name: String) -> String:
        var idx = self.find_var(id, name)
        if id >= 0 and id < len(self.m_units) and idx >= 0 and idx < len(self.m_units[id].values):
            if self.m_units[id].values[idx].type == TCS_STRING:
                return String(self.m_units[id].values[idx].data.cstr)
        return ""

    def get_unit_value(self, id: Int, name: String, len: Pointer[Int]) -> Pointer[Float64]:
        var idx = self.find_var(id, name)
        if id >= 0 and id < len(self.m_units) and idx >= 0 and idx < len(self.m_units[id].values):
            if self.m_units[id].values[idx].type == TCS_ARRAY:
                len[0] = Int(self.m_units[id].values[idx].data.array.length)
                return self.m_units[id].values[idx].data.array.values
        return Pointer[Float64]()

    def get_unit_value(self, id: Int, name: String, nr: Pointer[Int], nc: Pointer[Int]) -> Pointer[Float64]:
        var idx = self.find_var(id, name)
        if id >= 0 and id < len(self.m_units) and idx >= 0 and idx < len(self.m_units[id].values):
            if self.m_units[id].values[idx].type == TCS_MATRIX:
                nr[0] = Int(self.m_units[id].values[idx].data.matrix.nrows)
                nc[0] = Int(self.m_units[id].values[idx].data.matrix.ncols)
                return self.m_units[id].values[idx].data.matrix.values
        return Pointer[Float64]()

    def parse_unit_value(v: Pointer[tcsvalue], type: Int, value: String) -> Bool:
        if type == TCS_STRING:
            tcsvalue_set_string(v[0], value)
            return True
        elif type == TCS_NUMBER:
            tcsvalue_set_number(v[0], atof(value))
            return True
        elif type == TCS_ARRAY:
            return tcsvalue_parse_array(v[0], value)
        elif type == TCS_MATRIX:
            return tcsvalue_parse_matrix(v[0], value)
        else:
            return False

    def parse_unit_value(inout self, id: Int, name: String, value: String) -> Bool:
        if id < 0 or id >= len(self.m_units):
            return False
        var idx = self.find_var(id, name)
        if idx < 0 or idx >= len(self.m_units[id].values):
            return False
        var inf = self.m_units[id].type[0].variables[idx]
        var v = self.m_units[id].values[idx]
        return tcskernel.parse_unit_value(address_of(v), inf.data_type, value)

    def copy(inout self, tk: tcskernel) -> Int:
        self.clear_units()
        for it in range(len(tk.m_units)):
            var u = tk.m_units[it]
            var id = self.add_unit(u.type[0].name, u.name)
            if id < 0:
                return -1
            if len(self.m_units[id].values) != len(u.values):
                return -2
            for k in range(len(u.values)):
                var lhs = address_of(self.m_units[id].values[k])
                var rhs = address_of(u.values[k])
                if rhs[0].type == TCS_STRING:
                    tcsvalue_set_string(lhs[0], String(rhs[0].data.cstr))
                elif rhs[0].type == TCS_NUMBER:
                    tcsvalue_set_number(lhs[0], rhs[0].data.value)
                elif rhs[0].type == TCS_ARRAY:
                    tcsvalue_set_array(lhs[0], rhs[0].data.array.values, Int(rhs[0].data.array.length))
                elif rhs[0].type == TCS_MATRIX:
                    tcsvalue_set_matrix(lhs[0], rhs[0].data.matrix.values, Int(rhs[0].data.matrix.nrows), Int(rhs[0].data.matrix.ncols))
        for id in range(len(self.m_units)):
            var u = tk.m_units[id]
            for j in range(len(u.conn)):
                var cc = u.conn[j]
                for k in range(len(cc)):
                    self.connect(Int(id), Int(j), cc[k].target_unit, cc[k].target_index, cc[k].ftol, cc[k].arridx)
        return 0

    def add_unit(inout self, type: String, name: String) -> Int:
        if self.m_provider.is_null():
            return -2
        var t = self.m_provider[0].find_type(type)
        if t.is_null():
            self.message(TCS_ERROR, "could not add unit of type '%s': type information not found.", type)
            return -1
        var u = unit()
        u.id = len(self.m_units)
        u.name = name
        u.type = t
        u.instance = Pointer[None]()
        u.context.kernel_internal = Pointer[None](address_of(self))
        u.context.unit_internal = u.id
        u.context.message = _message
        u.context.progress = _progress
        u.context.get_value = _get_value
        u.context.get_num_values = _get_num_values
        u.context.tcsvalue_set_number = tcsvalue_set_number
        u.context.tcsvalue_set_array = tcsvalue_set_array
        u.context.tcsvalue_set_matrix = tcsvalue_set_matrix
        u.context.tcsvalue_set_string = tcsvalue_set_string
        self.m_units.push_back(u)
        var id = len(self.m_units) - 1
        var vi = t[0].variables
        var idx: Int = 0
        while vi[idx].var_type != TCS_INVALID:
            idx += 1
        var nvars = idx
        self.m_units[id].values.resize(nvars)
        self.m_units[id].conn.resize(nvars)
        idx = 0
        while vi[idx].var_type != TCS_INVALID:
            var v = address_of(self.m_units[id].values[idx])
            v[0].type = TCS_INVALID
            if vi[idx].data_type == TCS_NUMBER:
                v[0].type = TCS_NUMBER
                v[0].data.value = 0.0
                if not vi[idx].default_value.is_null():
                    tcsvalue_set_number(v[0], atof(String(vi[idx].default_value)))
            elif vi[idx].data_type == TCS_ARRAY:
                v[0].type = TCS_ARRAY
                v[0].data.array.values = Pointer[Float64](alloc[Float64](1))
                v[0].data.array.values[0] = 0.0
                v[0].data.array.length = 1
                if not vi[idx].default_value.is_null() and len(String(vi[idx].default_value)) > 0:
                    tcsvalue_parse_array(v[0], String(vi[idx].default_value))
            elif vi[idx].data_type == TCS_MATRIX:
                v[0].type = TCS_MATRIX
                v[0].data.matrix.values = Pointer[Float64](alloc[Float64](1))
                v[0].data.matrix.values[0] = 0.0
                v[0].data.matrix.nrows = 1
                v[0].data.matrix.ncols = 1
                if not vi[idx].default_value.is_null() and len(String(vi[idx].default_value)) > 0:
                    tcsvalue_parse_matrix(v[0], String(vi[idx].default_value))
            elif vi[idx].data_type == TCS_STRING:
                if not vi[idx].default_value.is_null():
                    tcsvalue_set_string(v[0], String(vi[idx].default_value))
                else:
                    tcsvalue_set_string(v[0], "")
            idx += 1
        return self.m_units[id].id

    def clear_units(inout self):
        self.m_units.clear()

    def connect(inout self, unit1: Int, output: Int, unit2: Int, input: Int, tol: Float64 = 0.1, arridx: Int = -1) -> Bool:
        if unit1 < 0 or unit1 > len(self.m_units) or unit2 < 0 or unit2 > len(self.m_units) or output < 0 or input < 0:
            return False
        var u1 = self.m_units[unit1]
        var u2 = self.m_units[unit2]
        if output >= len(u1.values):
            return False
        if output >= len(u1.conn):
            return False
        if input >= len(u2.values):
            return False
        var list = u1.conn[output]
        for i in range(len(list)):
            if list[i].target_unit == unit2 and list[i].target_index == input:
                return True
        var c = connection()
        c.target_unit = unit2
        c.target_index = input
        c.ftol = tol
        c.arridx = arridx
        u1.conn[output].push_back(c)
        return True

    def find_var(self, unit: Int, name: String) -> Int:
        if unit < 0 or unit >= len(self.m_units):
            return -1
        var varlist = self.m_units[unit].type[0].variables
        var idx: Int = 0
        while varlist[idx].var_type != TCS_INVALID and not varlist[idx].name.is_null():
            if strcmp(varlist[idx].name, name) == 0:
                return idx
            idx += 1
        self.message(TCS_NOTICE, "could not locate variable '%s' in unit %d (%s), type %s", name, unit, self.m_units[unit].name, self.m_units[unit].type[0].name)
        return -1

    def connect(inout self, unit1: Int, var1: String, unit2: Int, var2: String, tol: Float64 = 0.1, arridx: Int = -1) -> Bool:
        return self.connect(unit1, self.find_var(unit1, var1), unit2, self.find_var(unit2, var2), tol, arridx)

    def check_tolerance(val1: Float64, val2: Float64, ftol: Float64) -> Bool:
        if val1 == val2:
            return True
        if ftol <= 0.0:
            if fabs(val1 - val2) > fabs(ftol):
                return False
        else:
            var denom = val1
            if denom == 0.0:
                denom = val2
            if denom == 0.0:
                denom = 1.0
            if fabs((val1 - val2) / denom) > fabs(ftol / 100.0):
                return False
        return True

    def create_instances(inout self):
        for i in range(len(self.m_units)):
            self.m_units[i].instance = self.m_units[i].type[0].create_instance(address_of(self.m_units[i].context), self.m_units[i].type)

    def free_instances(inout self):
        for i in range(len(self.m_units)):
            self.m_units[i].type[0].free_instance(self.m_units[i].instance)
            self.m_units[i].instance = Pointer[None]()

    def solve(inout self, time: Float64, step: Float64) -> Int:
        for i in range(len(self.m_units)):
            self.m_units[i].ncall = 0
            self.m_units[i].mustcall = True
        var iterations: Int = 0
        var converged: Bool = False
        while not converged:
            if iterations >= self.m_maxIterations:
                self.message(TCS_NOTICE, "kernel exceeded maximum iterations of %d, at time %lf", self.m_maxIterations, time)
                if self.m_proceedAnyway:
                    return iterations
                else:
                    return -1
            for i in range(len(self.m_units)):
                if not self.m_units[i].mustcall:
                    continue
                if self.m_units[i].type[0].invoke(address_of(self.m_units[i].context), self.m_units[i].instance, TCS_INVOKE, address_of(self.m_units[i].values[0]), UInt32(len(self.m_units[i].values)), time, step, self.m_units[i].ncall) < 0:
                    self.message(TCS_ERROR, "unit %d (%s) type '%s' failed at time %.2lf", i, self.m_units[i].name, self.m_units[i].type[0].name, time)
                    return -2
                self.m_units[i].mustcall = False
                self.m_units[i].ncall += 1
                for j in range(len(self.m_units[i].values)):
                    var val1 = address_of(self.m_units[i].values[j])
                    for k in range(len(self.m_units[i].conn[j])):
                        var c = self.m_units[i].conn[j][k]
                        var val2 = address_of(self.m_units[c.target_unit].values[c.target_index])
                        if val1[0].type == TCS_NUMBER and val2[0].type == TCS_NUMBER:
                            if not tcskernel.check_tolerance(val1[0].data.value, val2[0].data.value, c.ftol):
                                val2[0].data.value = val1[0].data.value
                                self.m_units[c.target_unit].mustcall = True
                        elif val1[0].type == TCS_ARRAY and val2[0].type == TCS_NUMBER and c.arridx >= 0 and c.arridx < Int(val1[0].data.array.length):
                            if not tcskernel.check_tolerance(val1[0].data.array.values[c.arridx], val2[0].data.value, c.ftol):
                                val2[0].data.value = val1[0].data.array.values[c.arridx]
                                self.m_units[c.target_unit].mustcall = True
                        elif val1[0].type == TCS_ARRAY and val2[0].type == TCS_ARRAY and val1[0].data.array.length == val2[0].data.array.length:
                            var len_arr = Int(val1[0].data.array.length)
                            var pass = True
                            for m in range(len_arr):
                                pass = pass and tcskernel.check_tolerance(val1[0].data.array.values[m], val2[0].data.array.values[m], c.ftol)
                            if not pass:
                                for m in range(len_arr):
                                    val2[0].data.array.values[m] = val1[0].data.array.values[m]
                                self.m_units[c.target_unit].mustcall = True
                        elif val1[0].type == TCS_MATRIX and val2[0].type == TCS_MATRIX and val1[0].data.matrix.nrows == val2[0].data.matrix.nrows and val1[0].data.matrix.ncols == val2[0].data.matrix.ncols:
                            var len_mat = Int(val1[0].data.matrix.nrows) * Int(val1[0].data.matrix.ncols)
                            var pass = True
                            for m in range(len_mat):
                                pass = pass and tcskernel.check_tolerance(val1[0].data.matrix.values[m], val2[0].data.matrix.values[m], c.ftol)
                            if not pass:
                                for m in range(len_mat):
                                    val2[0].data.matrix.values[m] = val1[0].data.matrix.values[m]
                                self.m_units[c.target_unit].mustcall = True
                        else:
                            self.message(TCS_ERROR, "kernel could not check connection between [%d,%d] and [%d,%d]: type mismatch, dimension mismatch, or invalid type connection", i, j, c.target_unit, c.target_index)
                            return -3
            converged = True
            for i in range(len(self.m_units)):
                if self.m_units[i].mustcall:
                    converged = False
        return iterations

    def message(inout self, msgtype: Int, fmt: String, *args: ...):
        var buf = DynamicVector[UInt8]()
        buf.resize(2048)
        var ap = args
        # vsnprintf equivalent not directly available; simplified
        var result = StringWriter()
        result.write(fmt)
        for arg in args:
            result.write(arg)
        buf = result.str().data()
        buf[2047] = 0
        self.message(String(buf.data()), msgtype)

    def simulate(inout self, start: Float64, end: Float64, step: Float64) -> Int:
        if end <= start or step <= 0.0:
            self.message(TCS_ERROR, "invalid time sequence specified (start: %lf end: %lf step: %lf)", start, end, step)
            return -1
        self.m_startTime = start
        self.m_endTime = end
        self.m_timeStep = step
        self.create_instances()
        for i in range(len(self.m_units)):
            if self.m_units[i].type[0].invoke(address_of(self.m_units[i].context), self.m_units[i].instance, TCS_INIT, address_of(self.m_units[i].values[0]), UInt32(len(self.m_units[i].values)), -1.0, step, -1) < 0:
                self.message(TCS_ERROR, "unit %d (%s) type '%s' failed at initialization", i, self.m_units[i].name, self.m_units[i].type[0].name)
                self.free_instances()
                return -1
        for i in range(len(self.m_units)):
            for j in range(len(self.m_units[i].values)):
                var val1 = address_of(self.m_units[i].values[j])
                for k in range(len(self.m_units[i].conn[j])):
                    var c = self.m_units[i].conn[j][k]
                    var val2 = address_of(self.m_units[c.target_unit].values[c.target_index])
                    if val2[0].type == TCS_NUMBER and val2[0].data.value == -999.0:
                        if val1[0].type == TCS_NUMBER and val2[0].type == TCS_NUMBER:
                            if not tcskernel.check_tolerance(val1[0].data.value, val2[0].data.value, c.ftol):
                                val2[0].data.value = val1[0].data.value
                                self.m_units[c.target_unit].mustcall = True
                        elif val1[0].type == TCS_ARRAY and val2[0].type == TCS_NUMBER and c.arridx >= 0 and c.arridx < Int(val1[0].data.array.length):
                            if not tcskernel.check_tolerance(val1[0].data.array.values[c.arridx], val2[0].data.value, c.ftol):
                                val2[0].data.value = val1[0].data.array.values[c.arridx]
                                self.m_units[c.target_unit].mustcall = True
                        elif val1[0].type == TCS_ARRAY and val2[0].type == TCS_ARRAY and val1[0].data.array.length == val2[0].data.array.length:
                            var len_arr = Int(val1[0].data.array.length)
                            var pass = True
                            for m in range(len_arr):
                                pass = pass and tcskernel.check_tolerance(val1[0].data.array.values[m], val2[0].data.array.values[m], c.ftol)
                            if not pass:
                                for m in range(len_arr):
                                    val2[0].data.array.values[m] = val1[0].data.array.values[m]
                                self.m_units[c.target_unit].mustcall = True
                        elif val1[0].type == TCS_MATRIX and val2[0].type == TCS_MATRIX and val1[0].data.matrix.nrows == val2[0].data.matrix.nrows and val1[0].data.matrix.ncols == val2[0].data.matrix.ncols:
                            var len_mat = Int(val1[0].data.matrix.nrows) * Int(val1[0].data.matrix.ncols)
                            var pass = True
                            for m in range(len_mat):
                                pass = pass and tcskernel.check_tolerance(val1[0].data.matrix.values[m], val2[0].data.matrix.values[m], c.ftol)
                            if not pass:
                                for m in range(len_mat):
                                    val2[0].data.matrix.values[m] = val1[0].data.matrix.values[m]
                                self.m_units[c.target_unit].mustcall = True
                        else:
                            self.message(TCS_ERROR, "kernel could not check connection between [%d,%d] and [%d,%d]: type mismatch, dimension mismatch, or invalid type connection", i, j, c.target_unit, c.target_index)
                            return -3
        self.m_currentTime = self.m_startTime
        while self.m_currentTime <= self.m_endTime:
            var code = self.solve(self.m_currentTime, self.m_timeStep)
            if code < 0:
                self.free_instances()
                return code - 10
            for i in range(len(self.m_units)):
                if self.m_units[i].type[0].call_after_convergence > 0:
                    if self.m_units[i].type[0].invoke(address_of(self.m_units[i].context), self.m_units[i].instance, TCS_CONVERGED, address_of(self.m_units[i].values[0]), UInt32(len(self.m_units[i].values)), self.m_currentTime, self.m_timeStep, -2) < 0:
                        self.free_instances()
                        self.message(TCS_ERROR, "unit %d (%s) type '%s' failed at post-convergence at time %lf", i, self.m_units[i].name, self.m_units[i].type[0].name, self.m_currentTime)
                        return -3
            if not self.converged(self.m_currentTime):
                self.message(TCS_NOTICE, "simulation aborted at time %.2lf", self.m_currentTime)
                break
            self.m_currentTime += self.m_timeStep
        self.free_instances()
        return 0

    def netlist(self) -> String:
        var buf = StringWriter()
        for i in range(len(self.m_units)):
            buf.write("unit: ")
            buf.write(i)
            buf.write(" ")
            buf.write(self.m_units[i].type[0].name)
            buf.write(" '")
            buf.write(self.m_units[i].name)
            buf.write("'\n")
            for j in range(len(self.m_units[i].values)):
                var io = "in"
                if self.m_units[i].type[0].variables[j].var_type == TCS_OUTPUT:
                    io = "out"
                elif self.m_units[i].type[0].variables[j].var_type == TCS_PARAM:
                    io = "param"
                elif self.m_units[i].type[0].variables[j].var_type == TCS_DEBUG:
                    io = "debug"
                buf.write("\tvar[")
                buf.write(j)
                buf.write("] ")
                buf.write(io)
                buf.write(": ")
                buf.write(self.m_units[i].type[0].variables[j].name)
                buf.write("=")
                buf.write(tcsvalue_as_string(self.m_units[i].values[j]))
                buf.write("\n")
            for j in range(len(self.m_units[i].conn)):
                for k in range(len(self.m_units[i].conn[j])):
                    var c = self.m_units[i].conn[j][k]
                    buf.write("\tconn: ")
                    buf.write(self.m_units[i].type[0].variables[j].name)
                    buf.write(" --> [")
                    buf.write(c.target_unit)
                    buf.write(".")
                    buf.write(self.m_units[c.target_unit].type[0].variables[c.target_index].name)
                    buf.write("] tol ")
                    buf.write(c.ftol)
                    buf.write(" arr ")
                    buf.write(c.arridx)
                    buf.write("\n")
            buf.write("\n")
        return buf.str()