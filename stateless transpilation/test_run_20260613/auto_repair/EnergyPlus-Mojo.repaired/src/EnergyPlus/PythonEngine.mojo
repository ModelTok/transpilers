# LINK_WITH_PYTHON
# ifdef _DEBUG
#     undef _DEBUG
#     include <Python.h>
#     define _DEBUG
# else
#     include <Python.h>
# endif

from DataStringGlobals import *
from FileSystem import *
from PluginManager import *
from PythonEngine import *
from UtilityRoutines import *

# LINK_WITH_PYTHON
# template <> struct formatter<PyStatus>
# {
#     auto parse(format_parse_context &ctx) -> format_parse_context::iterator
#     {
#         return ctx.begin();
#     }
#     template <FormatContext> auto format(const PyStatus &status, FormatContext &ctx) const
#     {
#         if (PyStatus_Exception(status) == 0) {
#             return ctx.out();
#         }
#         if (PyStatus_IsExit(status) != 0) {
#             return format_to(ctx.out(), "Exited with code {}", status.exitcode);
#         }
#         if (PyStatus_IsError(status) != 0) {
#             auto it = ctx.out();
#             it = format_to(it, "Fatal Python error: ");
#             if (status.func != None) {
#                 it = format_to(it, "{}: ", status.func);
#             }
#             it = format_to(it, "{}", status.err_msg);
#             return it;
#         }
#         return ctx.out();
#     }
# };

# LINK_WITH_PYTHON
def reportPythonError(state: EnergyPlusData):
    var exc_type: PyObject = None
    var exc_value: PyObject = None
    var exc_tb: PyObject = None
    PyErr_Fetch(&exc_type, &exc_value, &exc_tb)
    PyErr_NormalizeException(&exc_type, &exc_value, &exc_tb)
    var str_exc_value: PyObject = PyObject_Repr(exc_value) # Now a unicode object
    var pyStr2: PyObject = PyUnicode_AsEncodedString(str_exc_value, "utf-8", "Error ~")
    Py_DECREF(str_exc_value)
    var strExcValue: String = PyBytes_AsString(pyStr2) # NOLINT(hicpp-signed-bitwise)
    Py_DECREF(pyStr2)
    EnergyPlus.ShowContinueError(state, "Python error description follows: ")
    EnergyPlus.ShowContinueError(state, strExcValue)
    var pModuleName: PyObject = PyUnicode_DecodeFSDefault("traceback")
    var pyth_module: PyObject = PyImport_Import(pModuleName)
    Py_DECREF(pModuleName)
    if pyth_module == None:
        EnergyPlus.ShowContinueError(state, "Cannot find 'traceback' module in reportPythonError(), this is weird")
        return
    var pyth_func: PyObject = PyObject_GetAttrString(pyth_module, "format_exception")
    Py_DECREF(pyth_module) # PyImport_Import returns a new reference, decrement it
    if (pyth_func != None) or (PyCallable_Check(pyth_func) != 0):
        var pyth_val: PyObject = PyObject_CallFunction(pyth_func, "OOO", exc_type, exc_value, exc_tb)
        if (pyth_val == None) or not PyList_Check(pyth_val): # NOLINT(hicpp-signed-bitwise)
            EnergyPlus.ShowContinueError(state, "In reportPythonError(), traceback.format_exception did not return a list.")
            return
        var numVals: Py_ssize_t = PyList_Size(pyth_val)
        if numVals == 0:
            EnergyPlus.ShowContinueError(state, "No traceback available")
            return
        EnergyPlus.ShowContinueError(state, "Python traceback follows: ")
        EnergyPlus.ShowContinueError(state, "```")
        for itemNum in range(numVals):
            var item: PyObject = PyList_GetItem(pyth_val, itemNum)
            if PyUnicode_Check(item): # NOLINT(hicpp-signed-bitwise) -- something inside Python code causes warning
                var traceback_line: String = PyUnicode_AsUTF8(item)
                if not traceback_line.empty() and traceback_line[traceback_line.length() - 1] == '\n':
                    traceback_line.erase(traceback_line.length() - 1)
                EnergyPlus.ShowContinueError(state, " >>> {}".format(traceback_line))
        EnergyPlus.ShowContinueError(state, "```")
        Py_DECREF(pyth_val) # PyObject_CallFunction returns new reference, decrement
    Py_DECREF(pyth_func) # PyObject_GetAttrString returns a new reference, decrement it

def addToPythonPath(state: EnergyPlusData, includePath: fs.path, userDefinedPath: Bool):
    if includePath.empty():
        return
    var unicodeIncludePath: PyObject = None
    if std.is_same_v<fs.path.value_type, wchar_t>:
        var ws: std.wstring = includePath.generic_wstring()
        unicodeIncludePath = PyUnicode_FromWideChar(ws.c_str(), static_cast<Py_ssize_t>(ws.size())) # New reference
    else:
        var s: std.string = includePath.generic_string()
        unicodeIncludePath = PyUnicode_FromString(s.c_str()) # New reference
    if unicodeIncludePath == None:
        EnergyPlus.ShowFatalError(state, "ERROR converting the path \"{:g}\" for addition to the sys.path in Python".format(includePath))
    var sysPath: PyObject = PySys_GetObject("path") # Borrowed reference
    var ret: Int = PyList_Insert(sysPath, 0, unicodeIncludePath)
    Py_DECREF(unicodeIncludePath)
    if ret != 0:
        if PyErr_Occurred() != None:
            reportPythonError(state)
        EnergyPlus.ShowFatalError(state, "ERROR adding \"{:g}\" to the sys.path in Python".format(includePath))
    if userDefinedPath:
        EnergyPlus.ShowMessage(state, "Successfully added path \"{:g}\" to the sys.path in Python".format(includePath))

def initPython(state: EnergyPlusData, pathToPythonPackages: fs.path):
    var status: PyStatus
    var preConfig: PyPreConfig
    PyPreConfig_InitPythonConfig(&preConfig)
    preConfig.utf8_mode = 1
    status = Py_PreInitialize(&preConfig)
    if PyStatus_Exception(status) != 0:
        ShowFatalError(state, "Could not pre-initialize Python to speak UTF-8... {}".format(status))
    var config: PyConfig
    PyConfig_InitIsolatedConfig(&config)
    config.isolated = 1
    status = PyConfig_SetBytesString(&config, &config.program_name, PluginManagement.programName)
    if PyStatus_Exception(status) != 0:
        ShowFatalError(state, "Could not initialize program_name on PyConfig... {}".format(status))
    status = PyConfig_Read(&config)
    if PyStatus_Exception(status) != 0:
        ShowFatalError(state, "Could not read back the PyConfig... {}".format(status))
    if std.is_same_v<fs.path.value_type, wchar_t>:
        var ws: std.wstring = pathToPythonPackages.generic_wstring()
        var wcharPath: wchar_t = ws.c_str()
        status = PyConfig_SetString(&config, &config.home, wcharPath)
        if PyStatus_Exception(status) != 0:
            ShowFatalError(state, "Could not set home to {:g} on PyConfig... {}".format(pathToPythonPackages, status))
        status = PyConfig_SetString(&config, &config.base_prefix, wcharPath)
        if PyStatus_Exception(status) != 0:
            ShowFatalError(state, "Could not set base_prefix to {:g} on PyConfig... {}".format(pathToPythonPackages, status))
        config.module_search_paths_set = 1
        status = PyWideStringList_Append(&config.module_search_paths, wcharPath)
        if PyStatus_Exception(status) != 0:
            ShowFatalError(state, "Could not add {:g} to module_search_paths on PyConfig... {}".format(pathToPythonPackages, status))
    else:
        var wcharPath: wchar_t = Py_DecodeLocale(pathToPythonPackages.generic_string().c_str(), None) # This allocates!
        status = PyConfig_SetString(&config, &config.home, wcharPath)
        if PyStatus_Exception(status) != 0:
            ShowFatalError(state, "Could not set home to {:g} on PyConfig... {}".format(pathToPythonPackages, status))
        status = PyConfig_SetString(&config, &config.base_prefix, wcharPath)
        if PyStatus_Exception(status) != 0:
            ShowFatalError(state, "Could not set base_prefix to {:g} on PyConfig... {}".format(pathToPythonPackages, status))
        config.module_search_paths_set = 1
        status = PyWideStringList_Append(&config.module_search_paths, wcharPath)
        if PyStatus_Exception(status) != 0:
            ShowFatalError(state, "Could not add {:g} to module_search_paths on PyConfig... {}".format(pathToPythonPackages, status))
        PyMem_RawFree(wcharPath)
    Py_InitializeFromConfig(&config)

def PythonEngine.__init__(self, state: EnergyPlusData):
    self.eplusRunningViaPythonAPI = state.dataPluginManager.eplusRunningViaPythonAPI
    var programDir: fs.path
    if state.dataGlobal.installRootOverride:
        programDir = state.dataStrGlobals.exeDirectoryPath
    else:
        programDir = FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(FileSystem.getProgramPath()))
    var pathToPythonPackages: fs.path = programDir / "python_lib"
    initPython(state, pathToPythonPackages)
    addToPythonPath(state, programDir / "python_lib/lib-dynload", False)
    addToPythonPath(state, programDir, False)
    var m: PyObject = PyImport_AddModule("__main__")
    if m == None:
        raise std.runtime_error("Unable to add module __main__ for python script execution")
    self.m_globalDict = PyModule_GetDict(m)

def PythonEngine.exec(self, sv: StringView):
    var command: String = String(sv)
    var v: PyObject = PyRun_String(command.c_str(), Py_file_input, self.m_globalDict, self.m_globalDict)
    if v == None:
        PyErr_Print()
        raise std.runtime_error("Error executing Python code")
    Py_DECREF(v)

def PythonEngine.__del__(self):
    if not self.eplusRunningViaPythonAPI:
        var alreadyInitialized: Bool = (Py_IsInitialized() != 0)
        if alreadyInitialized:
            if Py_FinalizeEx() < 0:
                exit(120)

def PythonEngine.getBasicPreamble() -> String:
    var cmd: String = """import sys
sys.argv.clear()
sys.argv.append("energyplus")
"""
    var programDir: fs.path = FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(FileSystem.getProgramPath()))
    var pathToPythonPackages: fs.path = programDir / "python_lib"
    var sPathToPythonPackages: String = String(pathToPythonPackages.string())
    sPathToPythonPackages.replace('\\', '/')
    cmd += "sys.path.insert(0, \"{}\")\n".format(sPathToPythonPackages)
    return cmd

def PythonEngine.getTclPreppedPreamble(python_fwd_args: List[String]) -> String:
    var cmd: String = """import sys
sys.argv.clear()
sys.argv.append("energyplus")
"""
    for arg in python_fwd_args:
        cmd += "sys.argv.append(\"{}\")\n".format(arg)
    var programDir: fs.path = FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(FileSystem.getProgramPath()))
    var pathToPythonPackages: fs.path = programDir / "python_lib"
    var sPathToPythonPackages: String = String(pathToPythonPackages.string())
    sPathToPythonPackages.replace('\\', '/')
    cmd += "sys.path.insert(0, \"{}\")\n".format(sPathToPythonPackages)
    var tclConfigDir: String
    var tkConfigDir: String
    for p in std.filesystem.directory_iterator(pathToPythonPackages):
        if p.is_directory():
            var dirName: String = p.path().filename().string()
            if dirName.starts_with("tcl") and dirName.find('.') != -1:
                tclConfigDir = dirName
            if dirName.starts_with("tk") and dirName.find('.') != -1:
                tkConfigDir = dirName
            if not tclConfigDir.empty() and not tkConfigDir.empty():
                break
    cmd += "from os import environ\n"
    cmd += "environ['TCL_LIBRARY'] = \"{}/{}\"\n".format(sPathToPythonPackages, tclConfigDir)
    cmd += "environ['TK_LIBRARY'] = \"{}/{}\"\n".format(sPathToPythonPackages, tkConfigDir)
    return cmd

# else // NOT LINK_WITH_PYTHON
#     PythonEngine::PythonEngine(EnergyPlus::EnergyPlusData &state)
#     {
#         ShowFatalError(state, "EnergyPlus is not linked with python");
#     }
#     PythonEngine::~PythonEngine()
#     {
#     }
#     void PythonEngine::exec(string_view)
#     {
#     }
# endif // LINK_WITH_PYTHON