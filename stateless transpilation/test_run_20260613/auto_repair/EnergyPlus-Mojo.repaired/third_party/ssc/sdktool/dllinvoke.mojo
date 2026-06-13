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
from dllinvoke import *
# from sscapi import *
# from lib_util import *
# from vartab import *

# platform detection
alias __WINDOWS__: Bool = False  # set to True for Windows

# --- platform-specific dll helpers ---
if __WINDOWS__:
    @extern
    def LoadLibraryA(name: Pointer[UInt8]) -> Pointer[UInt8]
    @extern
    def GetProcAddress(handle: Pointer[UInt8], name: Pointer[UInt8]) -> Pointer[UInt8]
    @extern
    def FreeLibrary(handle: Pointer[UInt8]) -> Bool

    def dll_open(name: Pointer[UInt8]) -> Pointer[UInt8]:
        return LoadLibraryA(name)
    def dll_close(handle: Pointer[UInt8]):
        _ = FreeLibrary(handle)
    def dll_sym(handle: Pointer[UInt8], name: Pointer[UInt8]) -> Pointer[UInt8]:
        return GetProcAddress(handle, name)
else:
    @extern
    def dlopen(name: Pointer[UInt8], flags: Int32) -> Pointer[UInt8]
    @extern
    def dlclose(handle: Pointer[UInt8]) -> Int32
    @extern
    def dlsym(handle: Pointer[UInt8], symbol: Pointer[UInt8]) -> Pointer[UInt8]

    def dll_open(name: Pointer[UInt8]) -> Pointer[UInt8]:
        return dlopen(name, 2)  # RTLD_NOW
    def dll_close(handle: Pointer[UInt8]):
        _ = dlclose(handle)
    def dll_sym(handle: Pointer[UInt8], name: Pointer[UInt8]) -> Pointer[UInt8]:
        return dlsym(handle, name)

var ssc_access_id: UInt32 = 0
var ssc_handle: Pointer[UInt8] = Pointer[UInt8]()

def sscdll_load(path: Pointer[UInt8]) -> Bool:
    sscdll_unload()
    ssc_handle = dll_open(path)
    ssc_access_id += 1
    if (ssc_handle.is_null()) or (dll_sym(ssc_handle, "ssc_version").is_null()):
        dll_close(ssc_handle)
        ssc_handle = Pointer[UInt8]()
        return False
    else:
        return True

def sscdll_unload():
    if not ssc_handle.is_null():
        ssc_access_id += 1
        dll_close(ssc_handle)
        ssc_handle = Pointer[UInt8]()

def sscdll_isloaded() -> Bool:
    return not ssc_handle.is_null()

# --- dynamically linked implementations ---
# macro CHECK_DLL_LOADED() expanded per function
def ssc_version() -> Int32:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    # CHECK_DLL_LOADED
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_version")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_version"
    # FAIL_ON_LOCATE if needed
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    # call via pointer (assume function type)
    return (cast[fn() -> Int32](f))()

def ssc_build_info() -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_build_info")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_build_info"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn() -> Pointer[UInt8]](f))()

def ssc_data_create() -> ssc_data_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_create")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_create"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn() -> ssc_data_t](f))()

def ssc_data_free(p_data: ssc_data_t):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_free")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_free"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_data_t) -> None](f))(p_data)

def ssc_data_clear(p_data: ssc_data_t):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_clear")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_clear"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_data_t) -> None](f))(p_data)

def ssc_data_unassign(p_data: ssc_data_t, name: Pointer[UInt8]):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_unassign")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_unassign"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_data_t, Pointer[UInt8]) -> None](f))(p_data, name)

def ssc_data_query(p_data: ssc_data_t, name: Pointer[UInt8]) -> Int32:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_query")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_query"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_data_t, Pointer[UInt8]) -> Int32](f))(p_data, name)

def ssc_data_set_string(p_data: ssc_data_t, name: Pointer[UInt8], value: Pointer[UInt8]):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_set_string")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_set_string"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_data_t, Pointer[UInt8], Pointer[UInt8]) -> None](f))(p_data, name, value)

def ssc_data_set_number(p_data: ssc_data_t, name: Pointer[UInt8], value: ssc_number_t):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_set_number")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_set_number"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_data_t, Pointer[UInt8], ssc_number_t) -> None](f))(p_data, name, value)

def ssc_data_set_array(p_data: ssc_data_t, name: Pointer[UInt8], pvalues: Pointer[ssc_number_t], length: Int32):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_set_array")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_set_array"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_data_t, Pointer[UInt8], Pointer[ssc_number_t], Int32) -> None](f))(p_data, name, pvalues, length)

def ssc_data_set_matrix(p_data: ssc_data_t, name: Pointer[UInt8], pvalues: Pointer[ssc_number_t], nrows: Int32, ncols: Int32):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_set_matrix")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_set_matrix"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_data_t, Pointer[UInt8], Pointer[ssc_number_t], Int32, Int32) -> None](f))(p_data, name, pvalues, nrows, ncols)

def ssc_data_set_table(p_data: ssc_data_t, name: Pointer[UInt8], table: ssc_data_t):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_set_table")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_set_table"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_data_t, Pointer[UInt8], ssc_data_t) -> None](f))(p_data, name, table)

def ssc_data_get_string(p_data: ssc_data_t, name: Pointer[UInt8]) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_get_string")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_get_string"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_data_t, Pointer[UInt8]) -> Pointer[UInt8]](f))(p_data, name)

def ssc_data_get_number(p_data: ssc_data_t, name: Pointer[UInt8], value: Pointer[ssc_number_t]) -> ssc_bool_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_get_number")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_get_number"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_data_t, Pointer[UInt8], Pointer[ssc_number_t]) -> ssc_bool_t](f))(p_data, name, value)

def ssc_data_get_array(p_data: ssc_data_t, name: Pointer[UInt8], length: Pointer[Int32]) -> Pointer[ssc_number_t]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_get_array")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_get_array"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_data_t, Pointer[UInt8], Pointer[Int32]) -> Pointer[ssc_number_t]](f))(p_data, name, length)

def ssc_data_get_matrix(p_data: ssc_data_t, name: Pointer[UInt8], nrows: Pointer[Int32], ncols: Pointer[Int32]) -> Pointer[ssc_number_t]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_get_matrix")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_get_matrix"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_data_t, Pointer[UInt8], Pointer[Int32], Pointer[Int32]) -> Pointer[ssc_number_t]](f))(p_data, name, nrows, ncols)

def ssc_data_get_table(p_data: ssc_data_t, name: Pointer[UInt8]) -> ssc_data_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_get_table")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_get_table"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_data_t, Pointer[UInt8]) -> ssc_data_t](f))(p_data, name)

# macro DYNAMICCALL_CONSTCHARSTAR__SSCDATAT() expanded
def ssc_data_first(p_data: ssc_data_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_first")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_first"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_data_t) -> Pointer[UInt8]](f))(p_data)

def ssc_data_next(p_data: ssc_data_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_data_next")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_data_next"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_data_t) -> Pointer[UInt8]](f))(p_data)

def ssc_module_entry(index: Int32) -> ssc_entry_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_entry")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_entry"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(Int32) -> ssc_entry_t](f))(index)

def ssc_entry_name(p_entry: ssc_entry_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_entry_name")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_entry_name"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_entry_t) -> Pointer[UInt8]](f))(p_entry)

def ssc_entry_description(p_entry: ssc_entry_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_entry_description")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_entry_description"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_entry_t) -> Pointer[UInt8]](f))(p_entry)

def ssc_entry_version(p_entry: ssc_entry_t) -> Int32:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_entry_version")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_entry_version"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_entry_t) -> Int32](f))(p_entry)

def ssc_module_create(name: Pointer[UInt8]) -> ssc_module_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_create")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_create"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(Pointer[UInt8]) -> ssc_module_t](f))(name)

def ssc_module_free(p_mod: ssc_module_t):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_free")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_free"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_module_t) -> None](f))(p_mod)

def ssc_module_var_info(p_mod: ssc_module_t, index: Int32) -> ssc_info_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_var_info")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_var_info"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_module_t, Int32) -> ssc_info_t](f))(p_mod, index)

# --- ssc_info_* functions with DYNAMICCALL_INT__SSCINFOT and DYNAMICCALL_CONSTCHARSTAR__SSCINFOT macros ---
def ssc_info_var_type(p_inf: ssc_info_t) -> Int32:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_var_type")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_var_type"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Int32](f))(p_inf)

def ssc_info_data_type(p_inf: ssc_info_t) -> Int32:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_data_type")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_data_type"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Int32](f))(p_inf)

def ssc_info_name(p_inf: ssc_info_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_name")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_name"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Pointer[UInt8]](f))(p_inf)

def ssc_info_label(p_inf: ssc_info_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_label")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_label"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Pointer[UInt8]](f))(p_inf)

def ssc_info_units(p_inf: ssc_info_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_units")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_units"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Pointer[UInt8]](f))(p_inf)

def ssc_info_meta(p_inf: ssc_info_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_meta")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_meta"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Pointer[UInt8]](f))(p_inf)

def ssc_info_group(p_inf: ssc_info_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_group")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_group"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Pointer[UInt8]](f))(p_inf)

def ssc_info_required(p_inf: ssc_info_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_required")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_required"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Pointer[UInt8]](f))(p_inf)

def ssc_info_constraints(p_inf: ssc_info_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_constraints")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_constraints"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Pointer[UInt8]](f))(p_inf)

def ssc_info_uihint(p_inf: ssc_info_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_info_uihint")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_info_uihint"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_info_t) -> Pointer[UInt8]](f))(p_inf)

def ssc_module_exec_simple(name: Pointer[UInt8], p_data: ssc_data_t) -> ssc_bool_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_exec_simple")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_exec_simple"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(Pointer[UInt8], ssc_data_t) -> ssc_bool_t](f))(name, p_data)

def ssc_module_exec_simple_nothread(name: Pointer[UInt8], p_data: ssc_data_t) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_exec_simple_nothread")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_exec_simple_nothread"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(Pointer[UInt8], ssc_data_t) -> Pointer[UInt8]](f))(name, p_data)

def ssc_module_exec(p_mod: ssc_module_t, p_data: ssc_data_t) -> ssc_bool_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_exec")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_exec"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_module_t, ssc_data_t) -> ssc_bool_t](f))(p_mod, p_data)

def ssc_module_exec_with_handler(
    p_mod: ssc_module_t,
    p_data: ssc_data_t,
    pf_handler: fn(ssc_module_t, ssc_handler_t, Int32, Float32, Float32, Pointer[UInt8], Pointer[UInt8], Pointer[UInt8]) -> ssc_bool_t,
    pf_user_data: Pointer[UInt8]) -> ssc_bool_t:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_exec_with_handler")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_exec_with_handler"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    # cast to function pointer with matching signature
    return (cast[fn(ssc_module_t, ssc_data_t,
                     fn(ssc_module_t, ssc_handler_t, Int32, Float32, Float32, Pointer[UInt8], Pointer[UInt8], Pointer[UInt8]) -> ssc_bool_t,
                     Pointer[UInt8]) -> ssc_bool_t](f))(p_mod, p_data, pf_handler, pf_user_data)

def ssc_module_extproc_output(p_mod: ssc_handler_t, output_line: Pointer[UInt8]):
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_extproc_output")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_extproc_output"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn(ssc_handler_t, Pointer[UInt8]) -> None](f))(p_mod, output_line)

def ssc_module_log(p_mod: ssc_module_t, index: Int32, item_type: Pointer[Int32], time: Pointer[Float32]) -> Pointer[UInt8]:
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "ssc_module_log")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "ssc_module_log"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    return (cast[fn(ssc_module_t, Int32, Pointer[Int32], Pointer[Float32]) -> Pointer[UInt8]](f))(p_mod, index, item_type, time)

def __ssc_segfault():
    var f: Pointer[UInt8] = Pointer[UInt8]()
    var f_access_id: UInt32 = 0
    if not sscdll_isloaded():
        f = Pointer[UInt8]()
        raise sscdll_error("ssc not loaded", "__ssc_segfault")
    if f_access_id != ssc_access_id:
        f = Pointer[UInt8]()
        f_access_id = ssc_access_id
    var func_name: String = "__ssc_segfault"
    if f.is_null() and (f = dll_sym(ssc_handle, func_name)).is_null():
        f = Pointer[UInt8]()
        raise sscdll_error("lookup address fail", func_name)
    (cast[fn() -> None](f))()

/* include shared ssc code here */
from lib_util import *
from vartab import *
<<<FILE>>>