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

# EXTERNAL DEPS (to wire in glue):
# ShowMessage - external messaging function
# ShowContinueError - external messaging function
# ShowContinueErrorTimeStamp - external messaging function
# ShowFatalError - external messaging function
# ShowSevereError - external messaging function
# ShowWarningError - external messaging function

# MODULE PARAMETER DEFINITIONS
alias Pi = 3.141592653589793
alias PiOvr2 = Pi / 2.0
alias DegToRadians = Pi / 180.0
alias SecInHour = 3600.0
alias MaxNameLength = 500
alias KelvinConv = 273.15
alias InitConvTemp = 5.05
alias AutoCalculate = -99999.0
alias StefanBoltzmann = 5.6697e-8

# MODULE VARIABLE DECLARATIONS
var BigNumber: Float64 = 0.0
var DBigNumber: Float64 = 0.0


fn ShowMessage(
    message: String,
    unit1: Optional[Int32] = None,
    unit2: Optional[Int32] = None
) -> None:
    """Use when you want to create your own message for the error file."""
    pass


fn ShowContinueError(
    message: String,
    unit1: Optional[Int32] = None,
    unit2: Optional[Int32] = None
) -> None:
    """Use when you are "continuing" an error message over several lines."""
    pass


fn ShowContinueErrorTimeStamp(
    message: String,
    unit1: Optional[Int32] = None,
    unit2: Optional[Int32] = None
) -> None:
    """Use when you are "continuing" an error message and want to show the environment, day and time."""
    pass


fn ShowFatalError(
    message: String,
    unit1: Optional[Int32] = None,
    unit2: Optional[Int32] = None
) -> None:
    """Use when you want the program to terminate after writing messages to appropriate files."""
    pass


fn ShowSevereError(
    message: String,
    unit1: Optional[Int32] = None,
    unit2: Optional[Int32] = None
) -> None:
    """Use for "severe" error messages. Might have several severe tests and then terminate."""
    pass


fn ShowWarningError(
    message: String,
    unit1: Optional[Int32] = None,
    unit2: Optional[Int32] = None
) -> None:
    """Use for "warning" error messages."""
    pass
