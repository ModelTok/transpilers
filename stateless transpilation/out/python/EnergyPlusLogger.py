# EXTERNAL DEPS (to wire in glue):
# - Courierr (base class providing message_context attribute)
# - EnergyPlusData (state object from EnergyPlus)
# - ShowSevereError(state, message) function from UtilityRoutines
# - ShowWarningError(state, message) function from UtilityRoutines
# - ShowMessage(state, message) function from UtilityRoutines

from enum import IntEnum
from typing import Tuple, Any


class LogLevel(IntEnum):
    INVALID = -1
    DEBUG = 0
    INFO = 1
    WARNING = 2
    ERROR = 3
    NUM = 4


class Courierr:
    """Base class stub for Courierr."""
    def __init__(self):
        self.message_context = None


class EnergyPlusLogger(Courierr):
    def __init__(self, maximum_level_to_log: LogLevel = LogLevel.WARNING):
        super().__init__()
        self.minimum_level = maximum_level_to_log

    def error(self, message: str) -> None:
        if LogLevel.ERROR >= self.minimum_level:
            context_pair: Tuple[Any, str] = self.message_context
            energy_plus_data = context_pair[0]
            context_string = context_pair[1]
            full_message = f"{context_string}: {message}"
            ShowSevereError(energy_plus_data, full_message)

    def warning(self, message: str) -> None:
        if LogLevel.WARNING >= self.minimum_level:
            context_pair: Tuple[Any, str] = self.message_context
            energy_plus_data = context_pair[0]
            context_string = context_pair[1]
            full_message = f"{context_string}: {message}"
            ShowWarningError(energy_plus_data, full_message)

    def info(self, message: str) -> None:
        if LogLevel.INFO >= self.minimum_level:
            context_pair: Tuple[Any, str] = self.message_context
            energy_plus_data = context_pair[0]
            context_string = context_pair[1]
            full_message = f"{context_string}: {message}"
            ShowMessage(energy_plus_data, full_message)

    def debug(self, message: str) -> None:
        if LogLevel.DEBUG >= self.minimum_level:
            self.info(message)


def ShowSevereError(state: Any, message: str) -> None:
    """Stub: to be implemented by caller."""
    pass


def ShowWarningError(state: Any, message: str) -> None:
    """Stub: to be implemented by caller."""
    pass


def ShowMessage(state: Any, message: str) -> None:
    """Stub: to be implemented by caller."""
    pass
