from fmt.compile import FMT_COMPILE
from fmt.core import format

@_attribute(visibility("default"))
def foo() -> String:
    return format(FMT_COMPILE("foo bar {}"), 4242)