"""
Module: DataGlobals
EnergyPlus Data-Only Module for global constants and shared interface declarations.
Original Fortran module converted to Mojo.
"""

# EXTERNAL DEPS (to wire in glue):
# - DataPrecisionGlobals: provides r64 type (double precision floating point)
# - External procedures from other modules: ShowMessage, ShowContinueError,
#   ShowFatalError, ShowSevereError, ShowWarningError, SetupOutputVariable variants,
#   SetupRealInternalOutputVariable, GetInternalVariableValue

# Type alias for 64-bit precision (from DataPrecisionGlobals)
alias r64 = Float64

# Constants
alias Pi: r64 = 3.141592653589793  # Pi 3.1415926535897932384626435
alias PiOvr2: r64 = Pi / 2.0  # Pi/2
alias DegToRadians: r64 = Pi / 180.0  # Conversion for Degrees to Radians
alias StefanBoltzmann: r64 = 5.6697e-8  # Stefan-Boltzmann constant in W/(m2*K4)
alias MaxNameLength: Int = 100  # Maximum Name Length in Characters
alias rTinyValue: r64 = 2.220446049250313e-16  # Tiny value (machine epsilon for Float64)

# External procedure declarations

fn ShowMessage(Message: String, Unit1: Optional[Int] = None, Unit2: Optional[Int] = None) -> None:
    """Use when you want to create your own message for the error file."""
    pass

fn ShowContinueError(Message: String, Unit1: Optional[Int] = None, Unit2: Optional[Int] = None) -> None:
    """Use when you are 'continuing' an error message over several lines."""
    pass

fn ShowFatalError(Message: String, Unit1: Optional[Int] = None, Unit2: Optional[Int] = None) -> None:
    """Use when you want the program to terminate after writing messages to appropriate files."""
    pass

fn ShowSevereError(Message: String, Unit1: Optional[Int] = None, Unit2: Optional[Int] = None) -> None:
    """Use for 'severe' error messages. Might have several severe tests and then terminate."""
    pass

fn ShowWarningError(Message: String, Unit1: Optional[Int] = None, Unit2: Optional[Int] = None) -> None:
    """Use for 'warning' error messages."""
    pass

fn SetupRealOutputVariable(
    VariableName: String,
    ActualVariable: r64,
    IndexTypeKey: String,
    VariableTypeKey: String,
    KeyedValue: String,
    ReportFreq: Optional[String] = None,
    ResourceTypeKey: Optional[String] = None,
    EndUseKey: Optional[String] = None,
    GroupKey: Optional[String] = None
) -> None:
    """Setup a real output variable."""
    pass

fn SetupIntegerOutputVariable(
    VariableName: String,
    IntActualVariable: Int,
    IndexTypeKey: String,
    VariableTypeKey: String,
    KeyedValue: String,
    ReportFreq: Optional[String] = None
) -> None:
    """Setup an integer output variable."""
    pass

fn SetupRealOutputVariable_IntKey(
    VariableName: String,
    ActualVariable: r64,
    IndexTypeKey: String,
    VariableTypeKey: String,
    KeyedValue: Int,
    ReportFreq: Optional[String] = None,
    ResourceTypeKey: Optional[String] = None,
    EndUseKey: Optional[String] = None,
    GroupKey: Optional[String] = None
) -> None:
    """Setup a real output variable with integer key."""
    pass

fn SetupRealInternalOutputVariable(
    VariableName: String,
    ActualVariable: r64,
    IndexTypeKey: String,
    VariableTypeKey: String,
    KeyedValue: String,
    ReportFreq: String
) -> Int:
    """Setup a real internal output variable and return variable index."""
    return 0

fn GetInternalVariableValue(WhichVar: Int) -> r64:
    """Get the value of an internal variable by its report number."""
    return 0.0
