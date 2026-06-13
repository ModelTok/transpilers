from fmt.core import format

static_assert(__cplusplus >= 201402L, "expect C++ 2014 for host compiler")

def make_message_cpp() -> String:
    return format("host compiler \t: __cplusplus == {}", __cplusplus)