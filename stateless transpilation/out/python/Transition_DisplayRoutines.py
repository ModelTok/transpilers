def display_string(string: str) -> None:
    """Display a string with a leading space."""
    print(f" {string.rstrip()}")


def display_number_and_string(number: int, string: str) -> None:
    """Display a number and string combined."""
    num_string = str(number).lstrip()
    combined = f"{string.rstrip()}{num_string}"
    print(f" {combined}")


def display_sim_days_progress(current_sim_day: int, total_sim_days: int) -> None:
    """Calculate and store simulation progress percentage."""
    if not hasattr(display_sim_days_progress, 'percent'):
        display_sim_days_progress.percent = 0
    
    if total_sim_days > 0:
        display_sim_days_progress.percent = min(
            round((current_sim_day / total_sim_days) * 100.0), 100
        )
    else:
        display_sim_days_progress.percent = 0
