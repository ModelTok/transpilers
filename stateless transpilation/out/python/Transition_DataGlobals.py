"""
EnergyPlus Data-Only Module: DataGlobals

This data-only module is a repository for all variables which are considered
to be "global" in nature in EnergyPlus.

AUTHOR: Rick Strand
DATE WRITTEN: January 1997
MODIFIED: May 1997 (RKS) Added Weather Variables
MODIFIED: December 1997 (RKS,DF,LKL) Split into DataGlobals and DataEnvironment
MODIFIED: February 1999 (FW) Added NextHour, WGTNEXT, WGTNOW
MODIFIED: September 1999 (LKL) Rename WGTNEXT,WGTNOW for clarity
"""

from typing import Optional

# EXTERNAL DEPS (to wire in glue):
# ShowMessage - external messaging function
# ShowContinueError - external messaging function
# ShowContinueErrorTimeStamp - external messaging function
# ShowFatalError - external messaging function
# ShowSevereError - external messaging function
# ShowWarningError - external messaging function

# MODULE PARAMETER DEFINITIONS
Pi: float = 3.141592653589793
PiOvr2: float = Pi / 2.0
DegToRadians: float = Pi / 180.0
SecInHour: float = 3600.0
MaxNameLength: int = 500
KelvinConv: float = 273.15
InitConvTemp: float = 5.05
AutoCalculate: float = -99999.0
StefanBoltzmann: float = 5.6697e-8

# MODULE VARIABLE DECLARATIONS
BigNumber: float = 0.0
DBigNumber: float = 0.0


def ShowMessage(
    message: str,
    unit1: Optional[int] = None,
    unit2: Optional[int] = None
) -> None:
    """Use when you want to create your own message for the error file."""
    pass


def ShowContinueError(
    message: str,
    unit1: Optional[int] = None,
    unit2: Optional[int] = None
) -> None:
    """Use when you are "continuing" an error message over several lines."""
    pass


def ShowContinueErrorTimeStamp(
    message: str,
    unit1: Optional[int] = None,
    unit2: Optional[int] = None
) -> None:
    """Use when you are "continuing" an error message and want to show the environment, day and time."""
    pass


def ShowFatalError(
    message: str,
    unit1: Optional[int] = None,
    unit2: Optional[int] = None
) -> None:
    """Use when you want the program to terminate after writing messages to appropriate files."""
    pass


def ShowSevereError(
    message: str,
    unit1: Optional[int] = None,
    unit2: Optional[int] = None
) -> None:
    """Use for "severe" error messages. Might have several severe tests and then terminate."""
    pass


def ShowWarningError(
    message: str,
    unit1: Optional[int] = None,
    unit2: Optional[int] = None
) -> None:
    """Use for "warning" error messages."""
    pass
