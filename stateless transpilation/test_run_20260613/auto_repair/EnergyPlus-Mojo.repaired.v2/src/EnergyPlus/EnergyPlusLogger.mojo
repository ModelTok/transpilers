from Courierr import Courierr
from UtilityRoutines import ShowSevereError, ShowWarningError, ShowMessage
from EnergyPlus.DataGlobals import EnergyPlusData
@value
struct Log_level:
    var value: Int32
    def __init__(inout self, val: Int32):
        self.value = val
    @staticmethod
    def Invalid() -> Self:
        return Self(-1)
    @staticmethod
    def Debug() -> Self:
        return Self(0)
    @staticmethod
    def Info() -> Self:
        return Self(1)
    @staticmethod
    def Warning() -> Self:
        return Self(2)
    @staticmethod
    def Error() -> Self:
        return Self(3)
    @staticmethod
    def Num() -> Self:
        return Self(4)
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
class EnergyPlusLogger(Courierr):
    var minimum_level: Log_level
    def __init__(inout self, minimum_level_to_log: Log_level = Log_level.Warning()):
        Courierr.__init__(self)
        self.minimum_level = minimum_level_to_log
    def error(inout self, message: String):
        if Log_level.Error() >= self.minimum_level:
            var contextPair: Pointer[Tuple[Pointer[EnergyPlusData], String]] = Pointer[Tuple[Pointer[EnergyPlusData], String]](self.message_context)
            var fullMessage: String = "{}: {}".format(contextPair[][1], message)
            ShowSevereError(contextPair[][0][], fullMessage)
    def warning(inout self, message: String):
        if Log_level.Warning() >= self.minimum_level:
            var contextPair: Pointer[Tuple[Pointer[EnergyPlusData], String]] = Pointer[Tuple[Pointer[EnergyPlusData], String]](self.message_context)
            var fullMessage: String = "{}: {}".format(contextPair[][1], message)
            ShowWarningError(contextPair[][0][], fullMessage)
    def info(inout self, message: String):
        if Log_level.Info() >= self.minimum_level:
            var contextPair: Pointer[Tuple[Pointer[EnergyPlusData], String]] = Pointer[Tuple[Pointer[EnergyPlusData], String]](self.message_context)
            var fullMessage: String = "{}: {}".format(contextPair[][1], message)
            ShowMessage(contextPair[][0][], fullMessage)
    def debug(inout self, message: String):
        if Log_level.Debug() >= self.minimum_level:
            self.info(message)