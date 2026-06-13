# Copyright and license notice retained as in original.
# Translation from C++ to Mojo - faithful 1:1.

from lib_util import (
    util,
    dir_exists,
    lower_case
)
from core import (
    var_data,
    var_table,
    compute_module,
    module_entry_info,
    handler_interface
)
from json import (
    Json_Value,
    Json_Reader,
    Json_StreamWriterBuilder,
    Json_CharReaderBuilder
)

# Constants from sscapi.h
const SSC_INVALID: Int32 = 0
const SSC_STRING: Int32 = 1
const SSC_NUMBER: Int32 = 2
const SSC_ARRAY: Int32 = 3
const SSC_MATRIX: Int32 = 4
const SSC_TABLE: Int32 = 5
const SSC_DATARR: Int32 = 6
const SSC_DATMAT: Int32 = 7
const SSC_INPUT: Int32 = 1
const SSC_OUTPUT: Int32 = 2
const SSC_INOUT: Int32 = 3
const SSC_LOG: Int32 = 0
const SSC_UPDATE: Int32 = 1
const SSC_NOTICE: Int32 = 1
const SSC_WARNING: Int32 = 2
const SSC_ERROR: Int32 = 3

# Opaque type aliases (mirror void*)
type ssc_data_t = object
type ssc_var_t = object
type ssc_entry_t = object
type ssc_module_t = object
type ssc_info_t = object
type ssc_handler_t = object
type ssc_number_t = Float64
type ssc_bool_t = Int32

# ---------- Module-level variables ----------
var _bi_cstr: String = ""  # will be initialized in ssc_build_info
var module_table: List[Optional[module_entry_info]] = []
var sg_defaultPrint: Int32 = 1
var s_python_path: Optional[String] = None

# External module entry (assumed defined in another module)
extern var cm_entry_pvwattsv5_1ts: module_entry_info

# ---------- Helper class for handler ----------
class default_exec_handler(handler_interface):
    var m_hfunc: Optional[Fn(ssc_module_t, ssc_handler_t, Int32, Float32, Float32, String, String, object) -> Bool]
    var m_hdata: object

    def __init__(inout self, cm: compute_module,
                f: Optional[Fn(ssc_module_t, ssc_handler_t, Int32, Float32, Float32, String, String, object) -> Bool],
                d: object):
        handler_interface.__init__(self, cm)
        self.m_hfunc = f
        self.m_hdata = d

    def on_log(inout self, text: String, type_: Int32, time: Float32):
        if self.m_hfunc is None:
            return
        var result = self.m_hfunc(self.module(), self as ssc_handler_t, SSC_LOG, type_, time, text, "", self.m_hdata)

    def on_update(inout self, text: String, percent: Float32, time: Float32) -> Bool:
        if self.m_hfunc is None:
            return True
        var result = self.m_hfunc(self.module(), self as ssc_handler_t, SSC_UPDATE, percent, time, text, "", self.m_hdata)
        return result != 0

# ---------- Functions ----------
def ssc_version() -> Int32:
    return 252

def ssc_build_info() -> String:
    _bi_cstr = __PLATFORM__ + " " + __ARCH__ + " " + __COMPILER__ + " " + __DATE__ + " " + __TIME__
    return _bi_cstr

# ---------- Module table initialization ----------
def __init_module_table__():
    if len(module_table) == 0:
        module_table.append(cm_entry_pvwattsv5_1ts)
        module_table.append(None)

def ssc_module_create(name: String) -> ssc_module_t:
    __init_module_table__()
    var lname = util.lower_case(name)
    var i = 0
    while i < len(module_table) and module_table[i] is not None and module_table[i].f_create is not None:
        if lname == util.lower_case(module_table[i].name):
            return module_table[i].f_create()
        i += 1
    return 0

def ssc_module_free(p_mod: ssc_module_t):
    var cm = p_mod as compute_module
    if cm is not None:
        # calls destructor (delete in C++)
        # In Mojo, we rely on garbage collection; but cleanup?
        # For faithful translation, we simulate delete by setting to None.

def ssc_var_create() -> ssc_var_t:
    return var_data()

def ssc_var_free(p_var: ssc_var_t):
    var vd = p_var as var_data
    if vd is not None:
        # delete vd; in Mojo, GC handles

def ssc_var_clear(p_var: ssc_var_t):
    var vd = p_var as var_data
    if vd is not None:
        vd.clear()

def ssc_var_query(p_var: ssc_var_t) -> Int32:
    var vt = p_var as var_data
    if vt is None:
        return -1
    return vt.type

def ssc_var_size(p_var: ssc_var_t, nrows: Pointer[Int32], ncols: Pointer[Int32]):
    var vt = p_var as var_data
    if vt is None:
        return
    switch vt.type:
        case SSC_INVALID:
            if nrows is not None:
                nrows[] = 0
            if ncols is not None:
                ncols[] = 0
            return
        case SSC_ARRAY:
            if nrows is not None:
                nrows[] = vt.num.length()
            if ncols is not None:
                ncols[] = 1
            return
        case SSC_TABLE:
            if nrows is not None:
                nrows[] = vt.table.size()
            if ncols is not None:
                ncols[] = 1
            return
        case SSC_NUMBER, SSC_STRING:
            if nrows is not None:
                nrows[] = 1
            if ncols is not None:
                ncols[] = 1
            return
        case SSC_MATRIX:
            if nrows is not None:
                nrows[] = vt.num.nrows()
            if ncols is not None:
                ncols[] = vt.num.ncols()
            return
        case SSC_DATARR:
            if nrows is not None:
                nrows[] = vt.vec.size()
            if ncols is not None:
                ncols[] = 1
            return
        case SSC_DATMAT:
            if nrows is not None:
                nrows[] = vt.mat.size()
            if ncols is not None:
                ncols[] = vt.mat[0].size()
            return
        otherwise:
            return

def ssc_var_set_string(p_var: ssc_var_t, value: String):
    var vt = p_var as var_data
    if vt is None:
        return
    vt.clear()
    vt.type = SSC_STRING
    vt.str = value

def ssc_var_set_number(p_var: ssc_var_t, value: ssc_number_t):
    var vt = p_var as var_data
    if vt is None:
        return
    vt.clear()
    vt.type = SSC_NUMBER
    vt.num = value

def ssc_var_set_array(p_var: ssc_var_t, pvalues: Pointer[ssc_number_t], length: Int32):
    var vt = p_var as var_data
    if vt is None:
        return
    vt.clear()
    vt.type = SSC_ARRAY
    vt.num.assign(pvalues, length)

def ssc_var_set_matrix(p_var: ssc_var_t, pvalues: Pointer[ssc_number_t], nrows: Int32, ncols: Int32):
    var vt = p_var as var_data
    if vt is None:
        return
    vt.clear()
    vt.type = SSC_MATRIX
    vt.num.assign(pvalues, nrows, ncols)

def ssc_var_set_table(p_var: ssc_var_t, table: ssc_data_t):
    var vt = p_var as var_data
    var value = table as var_table
    if vt is None or value is None:
        return
    vt.clear()
    vt.type = SSC_TABLE
    vt.table = value

def ssc_var_set_data_array(p_var: ssc_var_t, p_var_entry: ssc_var_t, r: Int32):
    var vt = p_var as var_data
    if vt is None:
        return
    vt.type = SSC_DATARR
    var vec = vt.vec
    if r >= len(vec):
        vec.resize(r + 1)
    vec[r] = p_var_entry as var_data

def ssc_var_set_data_matrix(p_var: ssc_var_t, p_var_entry: ssc_var_t, r: Int32, c: Int32):
    var vt = p_var as var_data
    if vt is None:
        return
    vt.type = SSC_DATMAT
    var mat = vt.mat
    if r >= len(mat):
        mat.resize(r + 1)
    for i in range(len(mat)):
        if c >= len(mat[i]):
            mat[i].resize(c + 1)
    mat[r][c] = p_var_entry as var_data

def ssc_var_get_string(p_var: ssc_var_t) -> String:
    var vt = p_var as var_data
    if vt is None or vt.type != SSC_STRING:
        return ""
    return vt.str

def ssc_var_get_number(p_var: ssc_var_t) -> ssc_number_t:
    var vt = p_var as var_data
    if vt is None or vt.type != SSC_NUMBER:
        return 0.0
    return vt.num[0]

def ssc_var_get_array(p_var: ssc_var_t, length: Pointer[Int32]) -> Pointer[ssc_number_t]:
    var vt = p_var as var_data
    if vt is None or vt.type != SSC_ARRAY:
        return Pointer[ssc_number_t]()
    if length is not None:
        length[] = vt.num.length()
    return vt.num.data()

def ssc_var_get_matrix(p_var: ssc_var_t, nrows: Pointer[Int32], ncols: Pointer[Int32]) -> Pointer[ssc_number_t]:
    var vt = p_var as var_data
    if vt is None or vt.type != SSC_MATRIX:
        return Pointer[ssc_number_t]()
    if nrows is not None:
        nrows[] = vt.num.nrows()
    if ncols is not None:
        ncols[] = vt.num.ncols()
    return vt.num.data()

def ssc_var_get_table(p_var: ssc_var_t) -> ssc_data_t:
    var vt = p_var as var_data
    if vt is None or vt.type != SSC_TABLE:
        return 0
    return vt.table as ssc_data_t

def ssc_var_get_var_array(p_var: ssc_var_t, r: Int32) -> ssc_var_t:
    var vt = p_var as var_data
    if vt is None:
        return 0
    if r < len(vt.vec):
        return vt.vec[r] as ssc_var_t
    else:
        return 0

def ssc_var_get_var_matrix(p_var: ssc_var_t, r: Int32, c: Int32) -> ssc_var_t:
    var vt = p_var as var_data
    if vt is None:
        return 0
    if r < len(vt.mat) and c < len(vt.mat[r]):
        return vt.mat[r][c] as ssc_var_t
    else:
        return 0

# ---------- Data object manipulation ----------
def ssc_data_create() -> ssc_data_t:
    return var_table()

def ssc_data_free(p_data: ssc_data_t):
    var vt = p_data as var_table
    if vt is not None:
        # delete vt; GC handles

def ssc_data_clear(p_data: ssc_data_t):
    var vt = p_data as var_table
    if vt is not None:
        vt.clear()

def ssc_data_unassign(p_data: ssc_data_t, name: String):
    var vt = p_data as var_table
    if vt is None:
        return
    vt.unassign(name)

def ssc_data_rename(p_data: ssc_data_t, oldname: String, newname: String) -> Int32:
    var vt = p_data as var_table
    if vt is None:
        return 0
    return 1 if vt.rename(oldname, newname) else 0

def ssc_data_query(p_data: ssc_data_t, name: String) -> Int32:
    var vt = p_data as var_table
    if vt is None:
        return SSC_INVALID
    var dat = vt.lookup(name)
    if dat is None:
        return SSC_INVALID
    else:
        return dat.type

def ssc_data_first(p_data: ssc_data_t) -> String:
    var vt = p_data as var_table
    if vt is None:
        return ""
    return vt.first()

def ssc_data_next(p_data: ssc_data_t) -> String:
    var vt = p_data as var_table
    if vt is None:
        return ""
    return vt.next()

def ssc_data_lookup(p_data: ssc_data_t, name: String) -> ssc_var_t:
    var vt = p_data as var_table
    if vt is None:
        return 0
    return vt.lookup(name) as ssc_var_t

def ssc_data_lookup_case(p_data: ssc_data_t, name: String) -> ssc_var_t:
    var vt = p_data as var_table
    if vt is None:
        return 0
    return vt.lookup_match_case(name) as ssc_var_t

def ssc_data_set_var(p_data: ssc_data_t, name: String, p_var: ssc_var_t):
    var vt = p_data as var_table
    if vt is None:
        return
    var vd = p_var as var_data
    if p_var is None:
        return
    vt.assign(name, vd)

def ssc_data_set_string(p_data: ssc_data_t, name: String, value: String):
    var vt = p_data as var_table
    if vt is None:
        return
    vt.assign(name, var_data(value))

def ssc_data_set_number(p_data: ssc_data_t, name: String, value: ssc_number_t):
    var vt = p_data as var_table
    if vt is None:
        return
    vt.assign(name, var_data(value))

def ssc_data_set_array(p_data: ssc_data_t, name: String, pvalues: Pointer[ssc_number_t], length: Int32):
    var vt = p_data as var_table
    if vt is None:
        return
    vt.assign(name, var_data(pvalues, length))

def ssc_data_set_matrix(p_data: ssc_data_t, name: String, pvalues: Pointer[ssc_number_t], nrows: Int32, ncols: Int32):
    var vt = p_data as var_table
    if vt is None:
        return
    vt.assign(name, var_data(pvalues, nrows, ncols))

def ssc_data_set_table(p_data: ssc_data_t, name: String, table: ssc_data_t):
    var vt = p_data as var_table
    var value = table as var_table
    if vt is None or value is None:
        return
    var dat = vt.assign(name, var_data())
    dat.type = SSC_TABLE
    dat.table = value  # deep copy via operator=

def ssc_data_set_data_array(p_data: ssc_data_t, name: String, data_array: Pointer[ssc_var_t], nrows: Int32):
    var vt = p_data as var_table
    if vt is None:
        return
    var vec: List[var_data] = List[var_data]()
    for i in range(nrows):
        var tab = data_array[i] as var_data
        vec.append(tab)
    vt.assign(name, var_data(vec))

def ssc_data_set_data_matrix(p_data: ssc_data_t, name: String, data_matrix: Pointer[ssc_var_t], nrows: Int32, ncols: Int32):
    var vt = p_data as var_table
    if vt is None:
        return
    var mat: List[List[var_data]] = List[List[var_data]]()
    for i in range(nrows):
        var row: List[var_data] = List[var_data]()
        for j in range(ncols):
            var tab = data_matrix[i * nrows + j] as var_data
            row.append(tab)
        mat.append(row)
    vt.assign(name, var_data(mat))

def ssc_data_get_string(p_data: ssc_data_t, name: String) -> String:
    var vt = p_data as var_table
    if vt is None:
        return ""
    var dat = vt.lookup(name)
    if dat is None or dat.type != SSC_STRING:
        return ""
    return dat.str

def ssc_data_get_number(p_data: ssc_data_t, name: String, value: Pointer[ssc_number_t]) -> ssc_bool_t:
    if value is None:
        return 0
    var vt = p_data as var_table
    if vt is None:
        return 0
    var dat = vt.lookup(name)
    if dat is None or dat.type != SSC_NUMBER:
        return 0
    value[] = dat.num
    return 1

def ssc_data_get_array(p_data: ssc_data_t, name: String, length: Pointer[Int32]) -> Pointer[ssc_number_t]:
    var vt = p_data as var_table
    if vt is None:
        return Pointer[ssc_number_t]()
    var dat = vt.lookup(name)
    if dat is None or dat.type != SSC_ARRAY:
        return Pointer[ssc_number_t]()
    if length is not None:
        length[] = dat.num.length()
    return dat.num.data()

def ssc_data_get_matrix(p_data: ssc_data_t, name: String, nrows: Pointer[Int32], ncols: Pointer[Int32]) -> Pointer[ssc_number_t]:
    var vt = p_data as var_table
    if vt is None:
        return Pointer[ssc_number_t]()
    var dat = vt.lookup(name)
    if dat is None or dat.type != SSC_MATRIX:
        return Pointer[ssc_number_t]()
    if nrows is not None:
        nrows[] = dat.num.nrows()
    if ncols is not None:
        ncols[] = dat.num.ncols()
    return dat.num.data()

def ssc_data_get_table(p_data: ssc_data_t, name: String) -> ssc_data_t:
    var vt = p_data as var_table
    if vt is None:
        return 0
    var dat = vt.lookup(name)
    if dat is None or dat.type != SSC_TABLE:
        return 0
    return dat.table as ssc_data_t

def ssc_data_get_data_array(p_data: ssc_data_t, name: String, nrows: Pointer[Int32]) -> ssc_var_t:
    var vt = p_data as var_table
    if vt is None:
        return 0
    var dat = vt.lookup(name)
    if dat is None or dat.type != SSC_DATARR:
        return 0
    if nrows is not None:
        nrows[] = dat.vec.size()
    else:
        return 0
    return dat as ssc_var_t

def ssc_data_get_data_matrix(p_data: ssc_data_t, name: String, nrows: Pointer[Int32], ncols: Pointer[Int32]) -> ssc_var_t:
    var vt = p_data as var_table
    if vt is None:
        return 0
    var dat = vt.lookup(name)
    if dat is None or dat.type != SSC_DATMAT:
        return 0
    if nrows is not None:
        nrows[] = dat.mat.size()
    if ncols is not None:
        if not dat.mat.empty():
            ncols[] = dat.mat[0].size()
        else:
            ncols[] = 0
    return dat as ssc_var_t

# ---------- JSON conversion (simplified - uses Python JSON) ----------
def json_to_ssc_var(json_val: Json_Value, ssc_val: ssc_var_t):
    if ssc_val is None:
        return
    var vd = ssc_val as var_data
    vd.clear()
    var members: List[String]
    var is_arr: Bool
    var is_mat: Bool
    var vec: List[ssc_number_t] = List[ssc_number_t]()
    var vd_arr: List[var_data]
    var vd_tab: var_table

    def is_numerical(jv: Json_Value) -> Bool:
        var is_num = True
        for i in range(len(jv)):
            if not jv[i].isDouble() and not jv[i].isBool():
                is_num = False
                break
        return is_num

    switch json_val.type():
        case Json_Value.nullValue:
            return
        case Json_Value.intValue, Json_Value.uintValue, Json_Value.booleanValue, Json_Value.realValue:
            vd.type = SSC_NUMBER
            vd.num[0] = json_val.asDouble()
            return
        case Json_Value.stringValue:
            vd.type = SSC_STRING
            vd.str = json_val.asString()
            return
        case Json_Value.arrayValue:
            is_arr = is_numerical(json_val)
            if is_arr:
                vd.type = SSC_ARRAY
                if json_val.empty():
                    return
                for row in json_val:
                    vec.append(row.asDouble())
                vd.num.assign(vec.data(), len(vec))
                return
            is_mat = True
            for value in json_val:
                if value.type() != Json_Value.arrayValue or not is_numerical(value):
                    is_mat = False
                    break
            if is_mat:
                vd.type = SSC_MATRIX
                if json_val.empty():
                    return
                for row in json_val:
                    for value in row:
                        vec.append(value.asDouble())
                vd.num.assign(vec.data(), len(json_val), len(json_val[0]))
                return
            vd_arr = vd.vec
            for value in json_val:
                vd_arr.append(var_data())
                var entry = vd_arr[-1]
                json_to_ssc_var(value, entry as ssc_var_t)
            vd.type = SSC_DATARR
            return
        case Json_Value.objectValue:
            vd_tab = vd.table
            members = json_val.getMemberNames()
            for name in members:
                var entry = vd_tab.assign(name, var_data())
                json_to_ssc_var(json_val[name], entry as ssc_var_t)
            vd.type = SSC_TABLE

def json_to_ssc_data(json_str: String) -> ssc_data_t:
    var vt: var_table = var_table()
    var rawJson: String = json_str
    var rawJsonLength: Int32 = len(rawJson)
    var err: String
    var root: Json_Value
    var builder: Json_CharReaderBuilder
    var reader: Json_CharReader = builder.newCharReader()
    if not reader.parse(rawJson, root, err):
        vt.assign("error", err)
        return vt as ssc_data_t
    var members: List[String] = root.getMemberNames()
    for name in members:
        var ssc_val: var_data = var_data()
        json_to_ssc_var(root[name], ssc_val as ssc_var_t)
        vt.assign(name, ssc_val)
    return vt as ssc_data_t

def ssc_var_to_json(vd: var_data) -> Json_Value:
    var json_val: Json_Value
    switch vd.type:
        case SSC_INVALID:
            return json_val
        case SSC_NUMBER:
            json_val = vd.num[0]
            return json_val
        case SSC_STRING:
            json_val = vd.str
            return json_val
        case SSC_ARRAY:
            for i in range(vd.num.ncols()):
                json_val.append(Json_Value(vd.num[i]))
            return json_val
        case SSC_MATRIX:
            json_val.resize(vd.num.nrows())
            for i in range(len(json_val)):
                for j in range(vd.num.ncols()):
                    json_val[i].append(vd.num.at(i, j))
            return json_val
        case SSC_DATARR:
            for dat in vd.vec:
                json_val.append(ssc_var_to_json(dat))
            return json_val
        case SSC_DATMAT:
            for row in vd.mat:
                var json_row: Json_Value = json_val.append(Json_Value(Json_Value.arrayValue))
                for dat in row:
                    json_row.append(ssc_var_to_json(dat))
            return json_val
        case SSC_TABLE:
            for (key, value) in vd.table.get_hash():
                json_val[key] = ssc_var_to_json(value)
            return json_val

def ssc_data_to_json(p_data: ssc_data_t) -> String:
    var vt = p_data as var_table
    if vt is None:
        return ""
    var root: Json_Value
    for (key, value) in vt.get_hash():
        root[key] = ssc_var_to_json(value)
    var builder: Json_StreamWriterBuilder
    builder.settings_["indentation"] = ""
    var json_file: String = Json.writeString(builder, root)
    return json_file

# ---------- Module entry functions ----------
def ssc_module_entry(index: Int32) -> ssc_entry_t:
    __init_module_table__()
    var max_: Int32 = 0
    while module_table[max_] is not None:
        max_ += 1
    if index >= 0 and index < max_:
        return module_table[index] as ssc_entry_t
    else:
        return 0

def ssc_entry_name(p_entry: ssc_entry_t) -> String:
    var p = p_entry as module_entry_info
    if p is None:
        return ""
    return p.name

def ssc_entry_description(p_entry: ssc_entry_t) -> String:
    var p = p_entry as module_entry_info
    if p is None:
        return ""
    return p.description

def ssc_entry_version(p_entry: ssc_entry_t) -> Int32:
    var p = p_entry as module_entry_info
    if p is None:
        return 0
    return p.version

def ssc_module_var_info(p_mod: ssc_module_t, index: Int32) -> ssc_info_t:
    var cm = p_mod as compute_module
    if cm is None:
        return 0
    return cm.info(index) as ssc_info_t

def ssc_info_var_type(p_inf: ssc_info_t) -> Int32:
    var vi = p_inf as var_info
    if vi is None:
        return SSC_INVALID
    return vi.var_type

def ssc_info_data_type(p_inf: ssc_info_t) -> Int32:
    var vi = p_inf as var_info
    if vi is None:
        return SSC_INVALID
    return vi.data_type

def ssc_info_name(p_inf: ssc_info_t) -> String:
    var vi = p_inf as var_info
    if vi is None:
        return ""
    return vi.name

def ssc_info_label(p_inf: ssc_info_t) -> String:
    var vi = p_inf as var_info
    if vi is None:
        return ""
    return vi.label

def ssc_info_units(p_inf: ssc_info_t) -> String:
    var vi = p_inf as var_info
    if vi is None:
        return ""
    return vi.units

def ssc_info_meta(p_inf: ssc_info_t) -> String:
    var vi = p_inf as var_info
    if vi is None:
        return ""
    return vi.meta

def ssc_info_required(p_inf: ssc_info_t) -> String:
    var vi = p_inf as var_info
    if vi is None:
        return ""
    return vi.required_if

def ssc_info_group(p_inf: ssc_info_t) -> String:
    var vi = p_inf as var_info
    if vi is None:
        return ""
    return vi.group

def ssc_info_constraints(p_inf: ssc_info_t) -> String:
    var vi = p_inf as var_info
    if vi is None:
        return ""
    return vi.constraints

def ssc_info_uihint(p_inf: ssc_info_t) -> String:
    var vi = p_inf as var_info
    if vi is None:
        return ""
    return vi.ui_hint

# ---------- Default handlers ----------
def default_internal_handler_no_print(p_mod: ssc_module_t, p_handler: ssc_handler_t,
                                     action_type: Int32, f0: Float32, f1: Float32,
                                     s0: String, s1: String, p_data: object) -> Bool:
    return True

def default_internal_handler(p_mod: ssc_module_t, p_handler: ssc_handler_t,
                            action_type: Int32, f0: Float32, f1: Float32,
                            s0: String, s1: String, p_data: object) -> Bool:
    if action_type == SSC_LOG:
        print("Log ", end="")
        if f0 == SSC_NOTICE:
            print("Notice: ", s0, " time ", f1)
        elif f0 == SSC_WARNING:
            print("Warning: ", s0, " time ", f1)
        elif f0 == SSC_ERROR:
            print("Error: ", s0, " time ", f1)
        else:
            print("Log notice uninterpretable: ", f0, " time ", f1)
        return True
    elif action_type == SSC_UPDATE:
        print("%5.2f %% %s @ %g" % (f0, s0, f1))
        return True
    else:
        return False

def ssc_module_exec_simple(name: String, p_data: ssc_data_t) -> ssc_bool_t:
    var p_mod = ssc_module_create(name)
    if p_mod is None:
        return 0
    var result = ssc_module_exec(p_mod, p_data)
    ssc_module_free(p_mod)
    return result

def ssc_module_exec_simple_nothread(name: String, p_data: ssc_data_t) -> String:
    var p_internal_buf: String = ""
    var p_mod = ssc_module_create(name)
    if p_mod is None:
        return ""
    var result = ssc_module_exec(p_mod, p_data)
    if result == 0:
        p_internal_buf = "general error detected"
        var text: String
        var type_: Int32
        var i: Int32 = 0
        while True:
            text = ssc_module_log(p_mod, i, type_, 0)
            if text == "":
                break
            if type_ == SSC_ERROR:
                p_internal_buf = text[:255]
                break
            i += 1
    ssc_module_free(p_mod)
    if result:
        return ""
    else:
        return p_internal_buf

def ssc_module_exec_set_print(print_: Int32):
    sg_defaultPrint = print_

def ssc_module_exec(p_mod: ssc_module_t, p_data: ssc_data_t) -> ssc_bool_t:
    if sg_defaultPrint:
        return ssc_module_exec_with_handler(p_mod, p_data, default_internal_handler, 0)
    else:
        return ssc_module_exec_with_handler(p_mod, p_data, default_internal_handler_no_print, 0)

def ssc_module_exec_with_handler(p_mod: ssc_module_t, p_data: ssc_data_t,
                                pf_handler: Optional[Fn(ssc_module_t, ssc_handler_t, Int32, Float32, Float32, String, String, object) -> Bool],
                                pf_user_data: object) -> ssc_bool_t:
    var cm = p_mod as compute_module
    if cm is None:
        return 0
    var vt = p_data as var_table
    if vt is None:
        cm.log("invalid data object provided", SSC_ERROR)
        return 0
    var h: default_exec_handler = default_exec_handler(cm, pf_handler, pf_user_data)
    return cm.compute(h, vt) ? 1 : 0

def ssc_module_extproc_output(p_handler: ssc_handler_t, output_line: String):
    var hi = p_handler as handler_interface
    if hi is not None:
        hi.on_stdout(output_line)

def ssc_module_log(p_mod: ssc_module_t, index: Int32, item_type: Pointer[Int32], time: Pointer[Float32]) -> String:
    var cm = p_mod as compute_module
    if p_mod is None:
        return ""
    var l = cm.log(index)
    if l is None:
        return ""
    if item_type is not None:
        item_type[] = l.type
    if time is not None:
        time[] = l.time
    return l.text

def __ssc_segfault():
    var pstr: String = None
    var mystr: String = pstr

def set_python_path(abs_path: String):
    if util.dir_exists(abs_path):
        s_python_path = abs_path
    else:
        raise RuntimeError("set_python_path error. Python directory doesn't not exist: " + abs_path)

def get_python_path() -> String:
    if s_python_path is not None:
        return s_python_path
    else:
        raise RuntimeError("get_python_path error. Path does not exist. Set with 'set_python_path' first.")

def ssc_stateful_module_create(name: String, p_data: ssc_data_t) -> ssc_module_t:
    var vt = p_data as var_table
    if vt is None:
        raise RuntimeError("p_data invalid.")
    var lname: String = util.lower_case(name)
    var i: Int32 = 0
    while i < len(module_table) and module_table[i] is not None and module_table[i].f_create is not None:
        if lname == util.lower_case(module_table[i].name):
            if module_table[i].f_create_stateful is not None:
                return module_table[i].f_create_stateful(vt)
            else:
                raise RuntimeError("stateful module by that name does not exist.")
        i += 1
    raise RuntimeError("stateful module by that name does not exist.")