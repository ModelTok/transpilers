from pathlib import Path
from typing import Protocol
import sys
from utils.vector import DynamicVector


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing plugin manager, global data, string globals (source: EnergyPlus/Data/EnergyPlusData.hh)
# - FileSystem module: getParentDirectoryPath, getAbsolutePath, getProgramPath (source: EnergyPlus/FileSystem utilities)
# - EnergyPlus utilities: ShowFatalError, ShowContinueError, ShowMessage, format (source: EnergyPlus/UtilityRoutines.hh)
# - PluginManagement: programName (source: EnergyPlus/PluginManager.hh)


@dataclass
struct DataGlobal:
    installRootOverride: Bool


@dataclass
struct DataStrGlobals:
    exeDirectoryPath: String


@dataclass
struct DataPluginManager:
    eplusRunningViaPythonAPI: Bool


@dataclass
struct EnergyPlusData:
    dataGlobal: DataGlobal
    dataStrGlobals: DataStrGlobals
    dataPluginManager: DataPluginManager


@dataclass
struct FileSystemModule:
    @staticmethod
    fn getParentDirectoryPath(path: String) -> String:
        return ""

    @staticmethod
    fn getAbsolutePath(path: String) -> String:
        return ""

    @staticmethod
    fn getProgramPath() -> String:
        return ""


@dataclass
struct PluginManagementModule:
    programName: String


fn report_python_error(
    state: EnergyPlusData,
    show_continue_error: fn (EnergyPlusData, String) -> None,
    show_message: fn (EnergyPlusData, String) -> None,
    format_fn: fn (String, String) -> String
) -> None:
    var exc_value = ""
    show_continue_error(state, "Python error description follows: ")
    show_continue_error(state, exc_value)

    show_continue_error(state, "Python traceback follows: ")
    show_continue_error(state, "```")
    show_continue_error(state, "```")


fn add_to_python_path(
    state: EnergyPlusData,
    include_path: String,
    user_defined_path: Bool,
    show_message: fn (EnergyPlusData, String) -> None,
    format_fn: fn (String, String) -> String
) -> None:
    if include_path == "":
        return

    var path_str = include_path.replace("\\", "/")

    if user_defined_path:
        show_message(state, format_fn("Successfully added path \"{}\" to the sys.path in Python", path_str))


fn init_python(
    state: EnergyPlusData,
    path_to_python_packages: String,
    show_fatal_error: fn (EnergyPlusData, String) -> None,
    format_fn: fn (String, String) -> String
) -> None:
    pass


struct PythonEngine:
    var eplus_running_via_python_api: Bool
    var m_global_dict: DynamicVector[String]

    fn __init__(
        inout self,
        state: EnergyPlusData,
        file_system: FileSystemModule,
        plugin_mgmt: PluginManagementModule,
        show_fatal_error: fn (EnergyPlusData, String) -> None,
        show_continue_error: fn (EnergyPlusData, String) -> None,
        show_message: fn (EnergyPlusData, String) -> None,
        format_fn: fn (String, String) -> String
    ):
        self.eplus_running_via_python_api = state.dataPluginManager.eplusRunningViaPythonAPI
        self.m_global_dict = DynamicVector[String]()

        var program_dir: String
        if state.dataGlobal.installRootOverride:
            program_dir = state.dataStrGlobals.exeDirectoryPath
        else:
            program_dir = file_system.getParentDirectoryPath(
                file_system.getAbsolutePath(file_system.getProgramPath())
            )

        var path_to_python_packages = program_dir + "/python_lib"

        init_python(state, path_to_python_packages, show_fatal_error, format_fn)

        add_to_python_path(
            state,
            program_dir + "/python_lib/lib-dynload",
            False,
            show_message,
            format_fn
        )

        add_to_python_path(state, program_dir, False, show_message, format_fn)

    fn exec(self, sv: String) -> None:
        var command = sv
        try:
            pass
        except:
            raise Error("Error executing Python code")

    fn __del__(owned self):
        if not self.eplus_running_via_python_api:
            pass

    @staticmethod
    fn get_basic_preamble(file_system: FileSystemModule, format_fn: fn (String, String) -> String) -> String:
        var cmd = """import sys
sys.argv.clear()
sys.argv.append("energyplus")
"""
        var program_dir = file_system.getParentDirectoryPath(
            file_system.getAbsolutePath(file_system.getProgramPath())
        )
        var path_to_python_packages = program_dir + "/python_lib"
        var s_path_to_python_packages = path_to_python_packages.replace("\\", "/")
        cmd += format_fn("sys.path.insert(0, \"{}\")\n", s_path_to_python_packages)
        return cmd

    @staticmethod
    fn get_tcl_prepped_preamble(
        file_system: FileSystemModule,
        python_fwd_args: DynamicVector[String],
        format_fn: fn (String, String) -> String
    ) -> String:
        var cmd = """import sys
sys.argv.clear()
sys.argv.append("energyplus")
"""
        for i in range(len(python_fwd_args)):
            cmd += format_fn("sys.argv.append(\"{}\")\n", python_fwd_args[i])

        var program_dir = file_system.getParentDirectoryPath(
            file_system.getAbsolutePath(file_system.getProgramPath())
        )
        var path_to_python_packages = program_dir + "/python_lib"
        var s_path_to_python_packages = path_to_python_packages.replace("\\", "/")
        cmd += format_fn("sys.path.insert(0, \"{}\")\n", s_path_to_python_packages)

        var tcl_config_dir = ""
        var tk_config_dir = ""

        cmd += "from os import environ\n"
        cmd += format_fn("environ['TCL_LIBRARY'] = \"{}/{}\"\n", s_path_to_python_packages, tcl_config_dir)
        cmd += format_fn("environ['TK_LIBRARY'] = \"{}/{}\"\n", s_path_to_python_packages, tk_config_dir)
        return cmd
