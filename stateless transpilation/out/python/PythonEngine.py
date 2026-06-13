from typing import Protocol, Optional, Any
from pathlib import Path
import sys
import traceback
import os


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing plugin manager, global data, string globals (source: EnergyPlus/Data/EnergyPlusData.hh)
# - FileSystem module: getParentDirectoryPath, getAbsolutePath, getProgramPath (source: EnergyPlus/FileSystem utilities)
# - EnergyPlus utilities: ShowFatalError, ShowContinueError, ShowMessage, format (source: EnergyPlus/UtilityRoutines.hh)
# - PluginManagement: programName (source: EnergyPlus/PluginManager.hh)


class DataGlobal(Protocol):
    installRootOverride: bool


class DataStrGlobals(Protocol):
    exeDirectoryPath: Path


class DataPluginManager(Protocol):
    eplusRunningViaPythonAPI: bool


class EnergyPlusData(Protocol):
    dataGlobal: DataGlobal
    dataStrGlobals: DataStrGlobals
    dataPluginManager: DataPluginManager


class FileSystemModule(Protocol):
    @staticmethod
    def getParentDirectoryPath(path: Path) -> Path: ...

    @staticmethod
    def getAbsolutePath(path: Path) -> Path: ...

    @staticmethod
    def getProgramPath() -> Path: ...


class PluginManagementModule(Protocol):
    programName: str


def report_python_error(state: EnergyPlusData, show_continue_error, show_message, format_fn) -> None:
    import sys
    exc_info = sys.exc_info()
    exc_type = exc_info[0]
    exc_value = exc_info[1]
    exc_tb = exc_info[2]

    str_exc_value = repr(exc_value)
    show_continue_error(state, "Python error description follows: ")
    show_continue_error(state, str_exc_value)

    try:
        import traceback as tb_module
        tb_lines = tb_module.format_exception(exc_type, exc_value, exc_tb)

        if len(tb_lines) == 0:
            show_continue_error(state, "No traceback available")
            return

        show_continue_error(state, "Python traceback follows: ")
        show_continue_error(state, "```")

        for line in tb_lines:
            if line and line[-1] == '\n':
                line = line[:-1]
            show_continue_error(state, format_fn(" >>> {}", line))

        show_continue_error(state, "```")
    except Exception:
        show_continue_error(state, "Cannot find 'traceback' module in report_python_error(), this is weird")


def add_to_python_path(
    state: EnergyPlusData,
    include_path: Path,
    user_defined_path: bool,
    show_message,
    format_fn
) -> None:
    if not include_path or str(include_path).strip() == "":
        return

    path_str = str(include_path).replace('\\', '/')
    sys.path.insert(0, path_str)

    if user_defined_path:
        show_message(state, format_fn("Successfully added path \"{}\" to the sys.path in Python", path_str))


def init_python(
    state: EnergyPlusData,
    path_to_python_packages: Path,
    show_fatal_error,
    format_fn
) -> None:
    pass


class PythonEngine:
    def __init__(
        self,
        state: EnergyPlusData,
        file_system: FileSystemModule,
        plugin_mgmt: PluginManagementModule,
        show_fatal_error,
        show_continue_error,
        show_message,
        format_fn
    ):
        self.eplus_running_via_python_api = state.dataPluginManager.eplusRunningViaPythonAPI
        self.m_global_dict: dict[str, Any] = {}
        
        self._show_fatal_error = show_fatal_error
        self._show_continue_error = show_continue_error
        self._show_message = show_message
        self._format_fn = format_fn
        self._file_system = file_system

        program_dir: Path
        if state.dataGlobal.installRootOverride:
            program_dir = state.dataStrGlobals.exeDirectoryPath
        else:
            program_dir = file_system.getParentDirectoryPath(
                file_system.getAbsolutePath(file_system.getProgramPath())
            )

        path_to_python_packages = program_dir / "python_lib"

        init_python(state, path_to_python_packages, show_fatal_error, format_fn)

        add_to_python_path(
            state,
            program_dir / "python_lib/lib-dynload",
            False,
            show_message,
            format_fn
        )

        add_to_python_path(state, program_dir, False, show_message, format_fn)

        self.m_global_dict = {}

    def exec(self, sv: str) -> None:
        command = str(sv)
        try:
            exec(command, self.m_global_dict, self.m_global_dict)
        except Exception as e:
            report_python_error(
                None,
                self._show_continue_error,
                self._show_message,
                self._format_fn
            )
            raise RuntimeError("Error executing Python code")

    def __del__(self) -> None:
        if not self.eplus_running_via_python_api:
            pass

    @staticmethod
    def get_basic_preamble(file_system: FileSystemModule, format_fn) -> str:
        cmd = """import sys
sys.argv.clear()
sys.argv.append("energyplus")
"""
        program_dir = file_system.getParentDirectoryPath(
            file_system.getAbsolutePath(file_system.getProgramPath())
        )
        path_to_python_packages = program_dir / "python_lib"
        s_path_to_python_packages = str(path_to_python_packages).replace('\\', '/')
        cmd += format_fn("sys.path.insert(0, \"{}\")\n", s_path_to_python_packages)
        return cmd

    @staticmethod
    def get_tcl_prepped_preamble(
        file_system: FileSystemModule,
        python_fwd_args: list[str],
        format_fn
    ) -> str:
        cmd = """import sys
sys.argv.clear()
sys.argv.append("energyplus")
"""
        for arg in python_fwd_args:
            cmd += format_fn("sys.argv.append(\"{}\")\n", arg)

        program_dir = file_system.getParentDirectoryPath(
            file_system.getAbsolutePath(file_system.getProgramPath())
        )
        path_to_python_packages = program_dir / "python_lib"
        s_path_to_python_packages = str(path_to_python_packages).replace('\\', '/')
        cmd += format_fn("sys.path.insert(0, \"{}\")\n", s_path_to_python_packages)

        tcl_config_dir = ""
        tk_config_dir = ""
        try:
            for p in path_to_python_packages.iterdir():
                if p.is_dir():
                    dir_name = p.name
                    if dir_name.startswith("tcl") and '.' in dir_name:
                        tcl_config_dir = dir_name
                    if dir_name.startswith("tk") and '.' in dir_name:
                        tk_config_dir = dir_name
                    if tcl_config_dir and tk_config_dir:
                        break
        except Exception:
            pass

        cmd += "from os import environ\n"
        cmd += format_fn("environ['TCL_LIBRARY'] = \"{}/{}\"\n", s_path_to_python_packages, tcl_config_dir)
        cmd += format_fn("environ['TK_LIBRARY'] = \"{}/{}\"\n", s_path_to_python_packages, tk_config_dir)
        return cmd
