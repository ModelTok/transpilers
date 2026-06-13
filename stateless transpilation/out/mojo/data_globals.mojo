# EXTERNAL DEPS (to wire in glue):
# DataPrecisionGlobals: provides r64 (kind parameter for REAL(8) double precision)

alias Pi = 3.141592653589793
alias PiOvr2 = Pi / 2.0
alias DegToRadians = Pi / 180.0
alias StefanBoltzmann = 5.6697e-8
alias MaxNameLength = 100
alias rTinyValue = 2.220446049250313e-16


fn ShowMessage(
    message: String, unit1: Optional[Int] = None, unit2: Optional[Int] = None
) -> None:
    """Use when you want to create your own message for the error file."""
    pass


fn ShowContinueError(
    message: String, unit1: Optional[Int] = None, unit2: Optional[Int] = None
) -> None:
    """Use when you are "continuing" an error message over several lines."""
    pass


fn ShowFatalError(
    message: String, unit1: Optional[Int] = None, unit2: Optional[Int] = None
) -> None:
    """Use when you want the program to terminate after writing messages to appropriate files."""
    pass


fn ShowSevereError(
    message: String, unit1: Optional[Int] = None, unit2: Optional[Int] = None
) -> None:
    """Use for "severe" error messages. Might have several severe tests and then terminate."""
    pass


fn ShowWarningError(
    message: String, unit1: Optional[Int] = None, unit2: Optional[Int] = None
) -> None:
    """Use for "warning" error messages."""
    pass


fn SetupRealOutputVariable(
    variable_name: String,
    actual_variable: Float64,
    index_type_key: String,
    variable_type_key: String,
    keyed_value: String,
    report_freq: Optional[String] = None,
    resource_type_key: Optional[String] = None,
    end_use_key: Optional[String] = None,
    group_key: Optional[String] = None,
) -> None:
    """Setup a real output variable."""
    pass


fn SetupIntegerOutputVariable(
    variable_name: String,
    int_actual_variable: Int,
    index_type_key: String,
    variable_type_key: String,
    keyed_value: String,
    report_freq: Optional[String] = None,
) -> None:
    """Setup an integer output variable."""
    pass


fn SetupRealOutputVariable_IntKey(
    variable_name: String,
    actual_variable: Float64,
    index_type_key: String,
    variable_type_key: String,
    keyed_value: Int,
    report_freq: Optional[String] = None,
    resource_type_key: Optional[String] = None,
    end_use_key: Optional[String] = None,
    group_key: Optional[String] = None,
) -> None:
    """Setup a real output variable with integer key."""
    pass


fn SetupRealInternalOutputVariable(
    variable_name: String,
    actual_variable: Float64,
    index_type_key: String,
    variable_type_key: String,
    keyed_value: String,
    report_freq: String,
) -> Int:
    """Setup a real internal output variable."""
    pass


fn GetInternalVariableValue(which_var: Int) -> Float64:
    """Get an internal variable value."""
    pass
