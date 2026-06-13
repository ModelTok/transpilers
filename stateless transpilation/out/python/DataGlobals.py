# EXTERNAL DEPS (to wire in glue):
# DataPrecisionGlobals: provides r64 (kind parameter for REAL(8) double precision)

import sys

Pi: float = 3.141592653589793
PiOvr2: float = Pi / 2.0
DegToRadians: float = Pi / 180.0
StefanBoltzmann: float = 5.6697e-8
MaxNameLength: int = 100
rTinyValue: float = sys.float_info.epsilon


def ShowMessage(
    message: str, unit1: int | None = None, unit2: int | None = None
) -> None:
    """Use when you want to create your own message for the error file."""
    pass


def ShowContinueError(
    message: str, unit1: int | None = None, unit2: int | None = None
) -> None:
    """Use when you are "continuing" an error message over several lines."""
    pass


def ShowFatalError(
    message: str, unit1: int | None = None, unit2: int | None = None
) -> None:
    """Use when you want the program to terminate after writing messages to appropriate files."""
    pass


def ShowSevereError(
    message: str, unit1: int | None = None, unit2: int | None = None
) -> None:
    """Use for "severe" error messages. Might have several severe tests and then terminate."""
    pass


def ShowWarningError(
    message: str, unit1: int | None = None, unit2: int | None = None
) -> None:
    """Use for "warning" error messages."""
    pass


def SetupRealOutputVariable(
    variable_name: str,
    actual_variable: float,
    index_type_key: str,
    variable_type_key: str,
    keyed_value: str,
    report_freq: str | None = None,
    resource_type_key: str | None = None,
    end_use_key: str | None = None,
    group_key: str | None = None,
) -> None:
    """Setup a real output variable."""
    pass


def SetupIntegerOutputVariable(
    variable_name: str,
    int_actual_variable: int,
    index_type_key: str,
    variable_type_key: str,
    keyed_value: str,
    report_freq: str | None = None,
) -> None:
    """Setup an integer output variable."""
    pass


def SetupRealOutputVariable_IntKey(
    variable_name: str,
    actual_variable: float,
    index_type_key: str,
    variable_type_key: str,
    keyed_value: int,
    report_freq: str | None = None,
    resource_type_key: str | None = None,
    end_use_key: str | None = None,
    group_key: str | None = None,
) -> None:
    """Setup a real output variable with integer key."""
    pass


def SetupRealInternalOutputVariable(
    variable_name: str,
    actual_variable: float,
    index_type_key: str,
    variable_type_key: str,
    keyed_value: str,
    report_freq: str,
) -> int:
    """Setup a real internal output variable."""
    pass


def GetInternalVariableValue(which_var: int) -> float:
    """Get an internal variable value."""
    pass
