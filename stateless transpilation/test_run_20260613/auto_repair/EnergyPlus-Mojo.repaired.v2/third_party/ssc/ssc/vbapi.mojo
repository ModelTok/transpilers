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

from sscapi import (
    ssc_version,
    ssc_build_info,
    ssc_data_create,
    ssc_data_free,
    ssc_data_clear,
    ssc_data_unassign,
    ssc_data_query,
    ssc_data_first,
    ssc_data_next,
    ssc_data_set_string,
    ssc_data_set_number,
    ssc_data_set_array,
    ssc_data_set_matrix,
    ssc_data_set_table,
    ssc_data_get_string,
    ssc_data_get_number,
    ssc_data_get_array,
    ssc_data_get_matrix,
    ssc_data_get_table,
    ssc_module_entry,
    ssc_entry_name,
    ssc_entry_description,
    ssc_entry_version,
    ssc_module_create,
    ssc_module_free,
    ssc_module_var_info,
    ssc_info_var_type,
    ssc_info_data_type,
    ssc_info_name,
    ssc_info_label,
    ssc_info_units,
    ssc_info_meta,
    ssc_info_group,
    ssc_info_required,
    ssc_info_constraints,
    ssc_info_uihint,
    ssc_module_exec_set_print,
    ssc_module_exec_simple,
    ssc_module_exec_simple_nothread,
    ssc_module_exec,
    ssc_module_exec_with_handler,
    ssc_module_log,
    __ssc_segfault,
    ssc_number_t,
    ssc_bool_t,
    ssc_module_t,
    ssc_handler_t,
    ssc_data_t,
)

alias SSCEXPORT = def # Helper: strlen on a pointer to null-terminated bytes
def strlen_cstr(ptr: Pointer[UInt8]) -> Int:
    var count: Int = 0
    var p = ptr
    while p.load[UInt8]() != 0:
        count += 1
        p = p.offset(1)
    return count

# Helper: strncpy from src to dst with max n bytes
def strncpy_cstr(dst: Pointer[UInt8], src: Pointer[UInt8], n: Int):
    var i: Int = 0
    while i < n and src.load[UInt8](i) != 0:
        dst.store[UInt8](i, src.load[UInt8](i))
        i += 1
    # pad remaining with zeros if n > length
    while i < n:
        dst.store[UInt8](i, 0)
        i += 1

# Alias for ssc_number_t as Float64
alias ssc_number_t_alias = Float64

# Callback type for ssc_module_exec_with_handler
alias ssc_handler_callback = fn(
    ssc_module_t,
    ssc_handler_t,
    Int32,
    Float32,
    Float32,
    Pointer[UInt8],
    Pointer[UInt8],
    Pointer[UInt8],
) -> ssc_bool_t

SSCEXPORT def sscvb_version() -> Int64:
    return Int64(ssc_version())

SSCEXPORT def sscvb_build_info(build_info: Pointer[UInt8], len: Int64) -> Int64:
    let info = ssc_build_info()
    if info == Pointer[UInt8]():
        return 0
    let info_len = Int64(strlen_cstr(info) + 1)
    if build_info == Pointer[UInt8]() or len == 0:
        return info_len
    strncpy_cstr(build_info, info, Int(len))
    if len < info_len:
        return len
    else:
        return info_len

SSCEXPORT def sscvb_data_create() -> Pointer[UInt8]:
    return ssc_data_create()

SSCEXPORT def sscvb_data_free(p_data: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        ssc_data_free(p_data)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_clear(p_data: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        ssc_data_clear(p_data)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_unassign(p_data: Pointer[UInt8], name: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        ssc_data_unassign(p_data, name)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_query(p_data: Pointer[UInt8], name: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        return Int64(ssc_data_query(p_data, name))
    else:
        return 0

SSCEXPORT def sscvb_data_first(p_data: Pointer[UInt8], var data_first: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        data_first = ssc_data_first(p_data)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_next(p_data: Pointer[UInt8], var data_next: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        data_next = ssc_data_next(p_data)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_set_string(p_data: Pointer[UInt8], name: Pointer[UInt8], value: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        ssc_data_set_string(p_data, name, value)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_set_number(p_data: Pointer[UInt8], name: Pointer[UInt8], value: Float64) -> Int64:
    if p_data != Pointer[UInt8]():
        var val: ssc_number_t_alias = ssc_number_t_alias(value)
        ssc_data_set_number(p_data, name, val)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_set_array(p_data: Pointer[UInt8], name: Pointer[UInt8], pvalues: Pointer[Float64], length: Int64) -> Int64:
    if p_data != Pointer[UInt8]():
        let len: Int = Int(length)
        if len == 0:
            return 0
        let values = Pointer[ssc_number_t_alias].allocate(len)
        for i in range(len):
            values.store(i, ssc_number_t_alias(pvalues.load(i)))
        ssc_data_set_array(p_data, name, values, len)
        values.free()
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_set_matrix(p_data: Pointer[UInt8], name: Pointer[UInt8], pvalues: Pointer[Float64], nrows: Int64, ncols: Int64) -> Int64:
    if p_data != Pointer[UInt8]():
        let rows: Int = Int(nrows)
        let cols: Int = Int(ncols)
        let len: Int = rows * cols
        if len == 0:
            return 0
        let values = Pointer[ssc_number_t_alias].allocate(len)
        for i in range(len):
            values.store(i, ssc_number_t_alias(pvalues.load(i)))
        ssc_data_set_matrix(p_data, name, values, rows, cols)
        values.free()
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_set_table(p_data: Pointer[UInt8], name: Pointer[UInt8], table: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]() and table != Pointer[UInt8]():
        ssc_data_set_table(p_data, name, table)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_get_string(p_data: Pointer[UInt8], name: Pointer[UInt8], value: Pointer[UInt8], len: Int64) -> Int64:
    if p_data != Pointer[UInt8]():
        let val = ssc_data_get_string(p_data, name)
        if val == Pointer[UInt8]():
            return 0
        let val_len: Int64 = Int64(strlen_cstr(val) + 1)
        if value == Pointer[UInt8]() or len == 0:
            return val_len
        strncpy_cstr(value, val, Int(len))
        if len < val_len:
            return len
        else:
            return val_len
    else:
        return 0

SSCEXPORT def sscvb_data_get_number(p_data: Pointer[UInt8], name: Pointer[UInt8], value: Pointer[Float64]) -> Int64:
    if p_data != Pointer[UInt8]():
        var val: ssc_number_t_alias
        ssc_data_get_number(p_data, name, val)
        value.store(0, Float64(val))
        return 1
    else:
        return 0

SSCEXPORT def sscvb_data_get_array(p_data: Pointer[UInt8], name: Pointer[UInt8], pvalue: Pointer[Float64], length: Int64) -> Int64:
    if p_data != Pointer[UInt8]():
        var len: Int = Int(length)
        let values = ssc_data_get_array(p_data, name, len)
        if values == Pointer[ssc_number_t_alias]():
            return Int64(0)
        if length == 0:
            return Int64(len)
        for i in range(len):
            pvalue.store(i, Float64(values.load(i)))
        return Int64(len)
    else:
        return 0

SSCEXPORT def sscvb_data_get_matrix(p_data: Pointer[UInt8], name: Pointer[UInt8], pvalue: Pointer[Float64], nrows: Int64, ncols: Int64) -> Int64:
    if p_data != Pointer[UInt8]():
        var rows: Int = Int(nrows)
        var cols: Int = Int(ncols)
        let values = ssc_data_get_matrix(p_data, name, rows, cols)
        if values == Pointer[ssc_number_t_alias]():
            return Int64(0)
        if nrows == 0:
            return Int64(rows)
        if ncols == 0:
            return Int64(cols)
        let len: Int = rows * cols
        for i in range(len):
            pvalue.store(i, Float64(values.load(i)))
        return Int64(len)
    else:
        return 0

SSCEXPORT def sscvb_data_get_table(p_data: Pointer[UInt8], name: Pointer[UInt8], table: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]() and table != Pointer[UInt8]():
        let tmp: ssc_data_t = ssc_data_get_table(p_data, name)
        return Int64(tmp)
    else:
        return 0

SSCEXPORT def sscvb_module_entry(index: Int64) -> Pointer[UInt8]:
    return ssc_module_entry(Int(index))

SSCEXPORT def sscvb_entry_name(p_entry: Pointer[UInt8], var name: Pointer[UInt8]) -> Int64:
    if p_entry != Pointer[UInt8]():
        name = ssc_entry_name(p_entry)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_entry_description(p_entry: Pointer[UInt8], var description: Pointer[UInt8]) -> Int64:
    if p_entry != Pointer[UInt8]():
        description = ssc_entry_description(p_entry)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_entry_version(p_entry: Pointer[UInt8]) -> Int64:
    if p_entry != Pointer[UInt8]():
        return Int64(ssc_entry_version(p_entry))
    else:
        return 0

SSCEXPORT def sscvb_module_create(name: Pointer[UInt8]) -> Pointer[UInt8]:
    return ssc_module_create(name)

SSCEXPORT def sscvb_module_free(p_mod: Pointer[UInt8]) -> Int64:
    if p_mod != Pointer[UInt8]():
        ssc_module_free(p_mod)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_module_var_info(p_mod: Pointer[UInt8], index: Int64) -> Pointer[UInt8]:
    if p_mod != Pointer[UInt8]():
        return ssc_module_var_info(p_mod, Int(index))
    else:
        return Pointer[UInt8]()

SSCEXPORT def sscvb_info_var_type(p_inf: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        return Int64(ssc_info_var_type(p_inf))
    else:
        return 0

SSCEXPORT def sscvb_info_data_type(p_inf: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        return Int64(ssc_info_data_type(p_inf))
    else:
        return 0

SSCEXPORT def sscvb_info_name(p_inf: Pointer[UInt8], var name: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        name = ssc_info_name(p_inf)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_info_label(p_inf: Pointer[UInt8], var label: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        label = ssc_info_label(p_inf)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_info_units(p_inf: Pointer[UInt8], var units: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        units = ssc_info_units(p_inf)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_info_meta(p_inf: Pointer[UInt8], var meta: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        meta = ssc_info_meta(p_inf)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_info_group(p_inf: Pointer[UInt8], var group: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        group = ssc_info_group(p_inf)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_info_required(p_inf: Pointer[UInt8], var required: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        required = ssc_info_required(p_inf)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_info_constraints(p_inf: Pointer[UInt8], var constraints: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        constraints = ssc_info_constraints(p_inf)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_info_uihint(p_inf: Pointer[UInt8], var uihint: Pointer[UInt8]) -> Int64:
    if p_inf != Pointer[UInt8]():
        uihint = ssc_info_uihint(p_inf)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_module_exec_set_print(print: Int64) -> Int64:
    ssc_module_exec_set_print(Int(print))
    return 1

SSCEXPORT def sscvb_module_exec_simple(name: Pointer[UInt8], p_data: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        return Int64(ssc_module_exec_simple(name, p_data))
    else:
        return 0

SSCEXPORT def sscvb_module_exec_simple_nothread(name: Pointer[UInt8], p_data: Pointer[UInt8], var msg: Pointer[UInt8]) -> Int64:
    if p_data != Pointer[UInt8]():
        msg = ssc_module_exec_simple_nothread(name, p_data)
        return 1
    else:
        return 0

SSCEXPORT def sscvb_module_exec(p_mod: Pointer[UInt8], p_data: Pointer[UInt8]) -> Int64:
    if p_mod != Pointer[UInt8]() and p_data != Pointer[UInt8]():
        return Int64(ssc_module_exec(p_mod, p_data))
    else:
        return 0

SSCEXPORT def sscvb_module_exec_with_handler(
    p_mod: Pointer[UInt8],
    p_data: Pointer[UInt8],
    pf_handler: Int64,
    pf_user_data: Pointer[UInt8],
) -> Int64:
    if p_mod != Pointer[UInt8]() and p_data != Pointer[UInt8]():
        let handler: ssc_handler_callback = reinterpret[ssc_handler_callback](pf_handler)
        return Int64(
            ssc_module_exec_with_handler(
                p_mod,
                p_data,
                handler,
                pf_user_data,
            )
        )
    else:
        return 0

SSCEXPORT def sscvb_module_log(
    p_mod: Pointer[UInt8],
    index: Int64,
    item_type: Pointer[Int64],
    time: Pointer[Float64],
    msg: Pointer[UInt8],
    msg_len: Int64,
) -> Int64:
    var sscmsg_len: Int
    let ndx: Int = Int(index)
    var it: Int
    var ts: Float32
    if p_mod != Pointer[UInt8]():
        let sscmsg = ssc_module_log(p_mod, ndx, it, ts)
        if sscmsg == Pointer[UInt8]():
            return 0
        sscmsg_len = Int(strlen_cstr(sscmsg) + 1)
        if msg == Pointer[UInt8]() or msg_len == 0:
            return Int64(sscmsg_len)
        strncpy_cstr(msg, sscmsg, Int(msg_len))
        time.store(0, Float64(ts))
        item_type.store(0, Int64(it))
        if msg_len < Int64(sscmsg_len):
            return msg_len
        else:
            return Int64(sscmsg_len)
    else:
        return 0

SSCEXPORT def __sscvb_segfault() -> Int64:
    __ssc_segfault()
    return 1