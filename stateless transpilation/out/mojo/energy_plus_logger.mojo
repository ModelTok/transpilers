# EXTERNAL DEPS (to wire in glue):
# - Courierr (base struct/trait providing message_context field)
# - EnergyPlusData (state struct from EnergyPlus)
# - ShowSevereError(state, message) function from UtilityRoutines
# - ShowWarningError(state, message) function from UtilityRoutines
# - ShowMessage(state, message) function from UtilityRoutines

from collections import Pair


alias Int8 = Int8
alias Int32 = Int32


struct LogLevel:
    alias INVALID = -1
    alias DEBUG = 0
    alias INFO = 1
    alias WARNING = 2
    alias ERROR = 3
    alias NUM = 4


struct EnergyPlusData:
    pass


struct ContextPair:
    var energy_plus_data: EnergyPlusData
    var context_string: String


struct Courierr:
    var message_context: UnsafePointer[ContextPair]

    fn __init__(inout self):
        self.message_context = UnsafePointer[ContextPair]()


struct EnergyPlusLogger(Courierr):
    var minimum_level: Int8

    fn __init__(inout self, maximum_level_to_log: Int8 = LogLevel.WARNING):
        self.message_context = UnsafePointer[ContextPair]()
        self.minimum_level = maximum_level_to_log

    fn error(self, message: String) -> None:
        if LogLevel.ERROR >= self.minimum_level:
            var context_pair = self.message_context.load()
            var full_message = context_pair.context_string + ": " + message
            ShowSevereError(context_pair.energy_plus_data, full_message)

    fn warning(self, message: String) -> None:
        if LogLevel.WARNING >= self.minimum_level:
            var context_pair = self.message_context.load()
            var full_message = context_pair.context_string + ": " + message
            ShowWarningError(context_pair.energy_plus_data, full_message)

    fn info(self, message: String) -> None:
        if LogLevel.INFO >= self.minimum_level:
            var context_pair = self.message_context.load()
            var full_message = context_pair.context_string + ": " + message
            ShowMessage(context_pair.energy_plus_data, full_message)

    fn debug(self, message: String) -> None:
        if LogLevel.DEBUG >= self.minimum_level:
            self.info(message)


fn ShowSevereError(state: EnergyPlusData, message: String) -> None:
    pass


fn ShowWarningError(state: EnergyPlusData, message: String) -> None:
    pass


fn ShowMessage(state: EnergyPlusData, message: String) -> None:
    pass
