"""
Module: DataGlobals
EnergyPlus Data-Only Module for global constants and shared interface declarations.
Original Fortran module converted to Python.
"""

import sys
from typing import Optional

# EXTERNAL DEPS (to wire in glue):
# - DataPrecisionGlobals: provides r64 type (double precision floating point)
# - External procedures from other modules: ShowMessage, ShowContinueError, 
#   ShowFatalError, ShowSevereError, ShowWarningError, SetupOutputVariable variants,
#   SetupRealInternalOutputVariable, GetInternalVariableValue

# Type alias for 64-bit precision (from DataPrecisionGlobals)
r64 = float

# Constants
Pi: r64 = 3.141592653589793  # Pi 3.1415926535897932384626435
PiOvr2: r64 = Pi / 2.0  # Pi/2
DegToRadians: r64 = Pi / 180.0  # Conversion for Degrees to Radians
StefanBoltzmann: r64 = 5.6697e-8  # Stefan-Boltzmann constant in W/(m2*K4)
MaxNameLength: int = 100  # Maximum Name Length in Characters
rTinyValue: r64 = sys.float_info.epsilon  # Tiny value to replace use of TINY(x)

# External procedure declarations

def ShowMessage(Message: str, Unit1: Optional[int] = None, Unit2: Optional[int] = None) -> None:
    """Use when you want to create your own message for the error file."""
    ...

def ShowContinueError(Message: str, Unit1: Optional[int] = None, Unit2: Optional[int] = None) -> None:
    """Use when you are 'continuing' an error message over several lines."""
    ...

def ShowFatalError(Message: str, Unit1: Optional[int] = None, Unit2: Optional[int] = None) -> None:
    """Use when you want the program to terminate after writing messages to appropriate files."""
    ...

def ShowSevereError(Message: str, Unit1: Optional[int] = None, Unit2: Optional[int] = None) -> None:
    """Use for 'severe' error messages. Might have several severe tests and then terminate."""
    ...

def ShowWarningError(Message: str, Unit1: Optional[int] = None, Unit2: Optional[int] = None) -> None:
    """Use for 'warning' error messages."""
    ...

def SetupRealOutputVariable(
    VariableName: str,
    ActualVariable: r64,
    IndexTypeKey: str,
    VariableTypeKey: str,
    KeyedValue: str,
    ReportFreq: Optional[str] = None,
    ResourceTypeKey: Optional[str] = None,
    EndUseKey: Optional[str] = None,
    GroupKey: Optional[str] = None
) -> None:
    """Setup a real output variable."""
    ...

def SetupIntegerOutputVariable(
    VariableName: str,
    IntActualVariable: int,
    IndexTypeKey: str,
    VariableTypeKey: str,
    KeyedValue: str,
    ReportFreq: Optional[str] = None
) -> None:
    """Setup an integer output variable."""
    ...

def SetupRealOutputVariable_IntKey(
    VariableName: str,
    ActualVariable: r64,
    IndexTypeKey: str,
    VariableTypeKey: str,
    KeyedValue: int,
    ReportFreq: Optional[str] = None,
    ResourceTypeKey: Optional[str] = None,
    EndUseKey: Optional[str] = None,
    GroupKey: Optional[str] = None
) -> None:
    """Setup a real output variable with integer key."""
    ...

def SetupRealInternalOutputVariable(
    VariableName: str,
    ActualVariable: r64,
    IndexTypeKey: str,
    VariableTypeKey: str,
    KeyedValue: str,
    ReportFreq: str
) -> int:
    """Setup a real internal output variable and return variable index."""
    ...

def GetInternalVariableValue(WhichVar: int) -> r64:
    """Get the value of an internal variable by its report number."""
    ...
