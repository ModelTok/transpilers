from fmt import dynamic_format_arg_store, vformat, arg, string_view, format_context, format_parse_context, format_to

struct custom_type:
    var i: Int = 0

namespace fmt:
    struct formatter[custom_type]:
        def parse(self, ctx: format_parse_context) -> StringRef:
            return ctx.begin()
        def format(self, p: custom_type, ctx: FormatContext) -> StringRef:
            return format_to(ctx.out(), "cust={}", p.i)

struct to_stringable:

def to_string_view(s: to_stringable) -> string_view:
    return string_view()

namespace fmt:
    struct formatter[to_stringable]:
        def parse(self, ctx: format_parse_context) -> StringRef:
            return ctx.begin()
        def format(self, s: to_stringable, ctx: FormatContext) -> StringRef:
            return ctx.out()

struct copy_throwable:
    def __init__(self):

    def __copyinit__(self, other: Self):
        raise "deal with it"

namespace fmt:
    struct formatter[copy_throwable]:
        def parse(self, ctx: format_parse_context) -> StringRef:
            return ctx.begin()
        def format(self, c: copy_throwable, ctx: FormatContext) -> StringRef:
            return ctx.out()

def args_test_basic():
    var store = dynamic_format_arg_store[format_context]()
    store.push_back(42)
    store.push_back("abc1")
    store.push_back(1.5)
    assert(vformat("{} and {} and {}", store) == "42 and abc1 and 1.5")

def args_test_strings_and_refs():
    var store = dynamic_format_arg_store[format_context]()
    var str = String("1234567890")
    store.push_back(str)
    store.push_back(&str)
    store.push_back(string_view(str))
    str[0] = 'X'
    var result = vformat("{} and {} and {}", store)
    assert(result == "1234567890 and X234567890 and X234567890")

def args_test_custom_format():
    var store = dynamic_format_arg_store[format_context]()
    var c = custom_type()
    store.push_back(c)
    c.i += 1
    store.push_back(c)
    c.i += 1
    store.push_back(&c)
    c.i += 1
    var result = vformat("{} and {} and {}", store)
    assert(result == "cust=0 and cust=1 and cust=3")

def args_test_to_string_and_formatter():
    var store = dynamic_format_arg_store[format_context]()
    var s = to_stringable()
    store.push_back(s)
    store.push_back(&s)
    vformat("", store)

def args_test_named_int():
    var store = dynamic_format_arg_store[format_context]()
    store.push_back(arg("a1", 42))
    assert(vformat("{a1}", store) == "42")

def args_test_named_strings():
    var store = dynamic_format_arg_store[format_context]()
    var str = String("1234567890")
    store.push_back(arg("a1", str))
    store.push_back(arg("a2", &str))
    str[0] = 'X'
    assert(vformat("{a1} and {a2}", store) == "1234567890 and X234567890")

def args_test_named_arg_by_ref():
    var store = dynamic_format_arg_store[format_context]()
    var band = String("Rolling Stones")
    store.push_back(arg("band", &band))
    band[9] = 'c'
    assert(vformat("{band}", store) == "Rolling Scones")

def args_test_named_custom_format():
    var store = dynamic_format_arg_store[format_context]()
    var c = custom_type()
    store.push_back(arg("c1", c))
    c.i += 1
    store.push_back(arg("c2", c))
    c.i += 1
    store.push_back(arg("c_ref", &c))
    c.i += 1
    var result = vformat("{c1} and {c2} and {c_ref}", store)
    assert(result == "cust=0 and cust=1 and cust=3")

def args_test_clear():
    var store = dynamic_format_arg_store[format_context]()
    store.push_back(42)
    var result = vformat("{}", store)
    assert(result == "42")
    store.push_back(43)
    result = vformat("{} and {}", store)
    assert(result == "42 and 43")
    store.clear()
    store.push_back(44)
    result = vformat("{}", store)
    assert(result == "44")

def args_test_reserve():
    var store = dynamic_format_arg_store[format_context]()
    store.reserve(2, 1)
    store.push_back(1.5)
    store.push_back(arg("a1", 42))
    var result = vformat("{a1} and {}", store)
    assert(result == "42 and 1.5")

def args_test_throw_on_copy():
    var store = dynamic_format_arg_store[format_context]()
    store.push_back(String("foo"))
    try:
        store.push_back(copy_throwable())
    except:

    assert(vformat("{}", store) == "foo")

def args_test_copy_constructor():
    var store = dynamic_format_arg_store[format_context]()
    store.push_back(arg("test1", "value1"))
    store.push_back(arg("test2", "value2"))
    store.push_back(arg("test3", "value3"))
    var store2 = store
    store2.push_back(arg("test4", "value4"))
    var result = vformat("{test1} {test2} {test3} {test4}", store2)
    assert(result == "value1 value2 value3 value4")