fn display_string(string: String) -> None:
    """Display a string with a leading space."""
    print(" " + string.rstrip())


fn display_number_and_string(number: Int, string: String) -> None:
    """Display a number and string combined."""
    var num_string = str(number).lstrip()
    var combined = string.rstrip() + num_string
    print(" " + combined)


struct _DisplaySimDaysProgressState:
    var percent: Int = 0


var _display_sim_days_progress_state: _DisplaySimDaysProgressState = _DisplaySimDaysProgressState()


fn display_sim_days_progress(current_sim_day: Int, total_sim_days: Int) -> None:
    """Calculate and store simulation progress percentage."""
    if total_sim_days > 0:
        _display_sim_days_progress_state.percent = min(
            round((current_sim_day as Float / total_sim_days as Float) * 100.0) as Int,
            100
        )
    else:
        _display_sim_days_progress_state.percent = 0
