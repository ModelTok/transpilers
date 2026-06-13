from fmt.ranges import format, join, enable_if_t, string_view, has_formatter, format_context, format_to, detail
from std.vector import Vector
from std.map import Map
from std.string import String
from std.pair import Pair
from std.tuple import Tuple
from std.integral_constant import IntegralConstant
from gtest.gtest import Test, EXPECT_EQ, EXPECT_STREQ, EXPECT_TRUE, EXPECT_FALSE

alias FMT_GCC_VERSION: Int = 0
alias FMT_MSC_VER: Int = 0
alias FMT_RANGES_TEST_ENABLE_C_STYLE_ARRAY: Bool = (not FMT_GCC_VERSION) or (FMT_GCC_VERSION >= 601)
alias FMT_RANGES_TEST_ENABLE_JOIN: Bool = (not FMT_MSC_VER) or (FMT_MSC_VER > 1910)
alias FMT_RANGES_TEST_ENABLE_FORMAT_STRUCT: Bool = (not FMT_MSC_VER) or (FMT_MSC_VER > 1910)
alias FMT_USE_STRING_VIEW: Bool = True  # assume it's defined

struct ranges_test(Test):
    #if FMT_RANGES_TEST_ENABLE_C_STYLE_ARRAY
    def format_array(self) raises:
        var arr: Int[6] = [1, 2, 3, 5, 7, 11]
        EXPECT_EQ(format("{}", arr), "[1, 2, 3, 5, 7, 11]")

    def format_2d_array(self) raises:
        var arr: Int[3][2] = [[1, 2], [3, 5], [7, 11]]
        EXPECT_EQ(format("{}", arr), "[[1, 2], [3, 5], [7, 11]]")

    def format_array_of_literals(self) raises:
        var arr: [String; 2] = ["1234", "abcd"]
        EXPECT_EQ(format("{}", arr), "[\"1234\", \"abcd\"]")
    #endif

    def format_vector(self) raises:
        var v = Vector[Int](1, 2, 3, 5, 7, 11)
        EXPECT_EQ(format("{}", v), "[1, 2, 3, 5, 7, 11]")

    def format_vector2(self) raises:
        var v = Vector[Vector[Int]](Vector[Int](1, 2), Vector[Int](3, 5), Vector[Int](7, 11))
        EXPECT_EQ(format("{}", v), "[[1, 2], [3, 5], [7, 11]]")

    def format_map(self) raises:
        var m = Map[String, Int]()
        m["one"] = 1
        m["two"] = 2
        EXPECT_EQ(format("{}", m), "[(\"one\", 1), (\"two\", 2)]")

    def format_pair(self) raises:
        var p = Pair[Int, Float](42, 1.5)
        EXPECT_EQ(format("{}", p), "(42, 1.5)")

    def format_tuple(self) raises:
        var t = Tuple[Int, Float, String, Char](42, 1.5, "this is tuple", 'i')
        EXPECT_EQ(format("{}", t), "(42, 1.5, \"this is tuple\", 'i')")
        var empty_t = Tuple[]()
        EXPECT_EQ(format("{}", empty_t), "()")

    #if FMT_RANGES_TEST_ENABLE_FORMAT_STRUCT
    struct tuple_like:
        var i: Int
        var str: String
        def get[asize_t: Int](self) -> enable_if_t[Int, asize_t == 0] raises:
            return self.i
        def get[asize_t: Int](self) -> enable_if_t[string_view, asize_t == 1] raises:
            return self.str

    def get[asize_t: Int](t: tuple_like) -> decltype(t.get[asize_t]()) raises:
        return t.get[asize_t]()

    impl TupleSize[tuple_like]: typealias value = IntegralConstant[Int, 2]
    impl TupleElement[tuple_like, 0]: typealias type = Int
    impl TupleElement[tuple_like, 1]: typealias type = string_view

    def format_struct(self) raises:
        var t = tuple_like {i: 42, str: "foo"}
        EXPECT_EQ(format("{}", t), "(42, \"foo\")")
    #endif

    def format_to(self) raises:
        var buf: String(10)
        var end = format_to(buf, "{}", Vector[Int](1, 2, 3))
        *end = '\0'
        EXPECT_STREQ(buf, "[1, 2, 3]")

    struct path_like:
        def begin(self) -> *path_like:
            ...
        def end(self) -> *path_like:
            ...
        def op_to_string(self) -> String:
            ...

    def path_like_test(self) raises:
        EXPECT_FALSE(has_formatter[path_like, char].value)

    #if FMT_USE_STRING_VIEW
    struct string_like:
        var p: String
        def begin(self) -> *Char:
            return self.p.data()
        def end(self) -> *Char:
            return self.p.data() + self.p.len()
        def op_to_string_view(self) -> string_view:
            return "foo"
        def op_to_stdstring_view(self) -> String:
            return "foo"

    def format_string_like(self) raises:
        EXPECT_EQ(format("{}", string_like()), "foo")
    #endif

    struct non_const_only_range[T: CollectionElement]:
        var vec: Vector[T]
        alias const_iterator = Vector[T].Iterator # not exactly, but approximate

        def __init__[*Args](inout self, *args: *Args):
            self.vec = Vector[T](*args)
        def begin(self) -> const_iterator:
            return self.vec.begin()
        def end(self) -> const_iterator:
            return self.vec.end()

    struct noncopyable_range[T: CollectionElement]:
        var vec: Vector[T]
        alias const_iterator = Vector[T].Iterator

        def __init__[*Args](inout self, *args: *Args):
            self.vec = Vector[T](*args)
        def __copyinit__(self, other: Self) = delete
        def __moveinit__(self, other: Self) = delete
        def begin(self) -> const_iterator:
            return self.vec.begin()
        def end(self) -> const_iterator:
            return self.vec.end()

    def range_test(self) raises:
        var w = noncopyable_range[Int](3, 0)
        EXPECT_EQ(format("{}", w), "[0, 0, 0]")
        EXPECT_EQ(format("{}", noncopyable_range[Int](3, 0)), "[0, 0, 0]")
        var x = non_const_only_range[Int](3, 0)
        EXPECT_EQ(format("{}", x), "[0, 0, 0]")
        EXPECT_EQ(format("{}", non_const_only_range[Int](3, 0)), "[0, 0, 0]")
        var y = Vector[Int](3, 0)
        EXPECT_EQ(format("{}", y), "[0, 0, 0]")
        EXPECT_EQ(format("{}", Vector[Int](3, 0)), "[0, 0, 0]")
        var z = Vector[Int](3, 0)
        EXPECT_EQ(format("{}", z), "[0, 0, 0]")

    #if !FMT_MSC_VER || FMT_MSC_VER >= 1927
    struct unformattable {}

    def unformattable_range_test(self) raises:
        EXPECT_FALSE(has_formatter[Vector[unformattable], format_context].value)
    #endif

    #if FMT_RANGES_TEST_ENABLE_JOIN
    def join_tuple(self) raises:
        var t1 = Tuple[Char, Int, Float]('a', 1, 2.0)
        EXPECT_EQ(format("({})", join(t1, ", ")), "(a, 1, 2)")
        var x = 4
        var t2 = Tuple[Char, Int&]('b', x)
        EXPECT_EQ(format("{}", join(t2, " + ")), "b + 4")
        var t3 = Tuple[]()
        EXPECT_EQ(format("{}", join(t3, "|")), "")
        var t4 = Tuple[Float](4.0)
        EXPECT_EQ(format("{}", join(t4, "/")), "4")
        var t5 = Tuple[Int, Int, Int](-3, 100, 1)
        EXPECT_EQ(format("{:+03}", join(t5, ", ")), "-03, +100, +01")
        var t6 = Tuple[Float, Float, Float](3, 3.14, 3.1415)
        EXPECT_EQ(format("{:5.5f}", join(t6, ", ")), "3.00000, 3.14000, 3.14150")
        var y = -1
        var t7 = Tuple[Int, Int&, const Int&](3, y, y)
        EXPECT_EQ(format("{:03}", join(t7, ", ")), "003, -01, -01")

    def join_initializer_list(self) raises:
        EXPECT_EQ(format("{}", join(List[Int](1, 2, 3), ", ")), "1, 2, 3")
        EXPECT_EQ(format("{}", join(List[String]("fmt", "rocks", "!"), " ")), "fmt rocks !")

    struct zstring_sentinel:

    def op__eq__(p: *Char, s: zstring_sentinel) -> Bool:
        return *p == '\0'
    def op__ne__(p: *Char, s: zstring_sentinel) -> Bool:
        return *p != '\0'

    struct zstring:
        var p: *Char
        def begin(self) -> *Char:
            return self.p
        def end(self) -> zstring_sentinel:
            return zstring_sentinel()

    def join_sentinel(self) raises:
        var hello = zstring {p: "hello"}
        EXPECT_EQ(format("{}", hello), "['h', 'e', 'l', 'l', 'o']")
        EXPECT_EQ(format("{}", join(hello, "_")), "h_e_l_l_o")

    def join_range(self) raises:
        var w = noncopyable_range[Int](3, 0)
        EXPECT_EQ(format("{}", join(w, ",")), "0,0,0")
        EXPECT_EQ(format("{}", join(noncopyable_range[Int](3, 0), ",")), "0,0,0")
        var x = non_const_only_range[Int](3, 0)
        EXPECT_EQ(format("{}", join(x, ",")), "0,0,0")
        EXPECT_EQ(format("{}", join(non_const_only_range[Int](3, 0), ",")), "0,0,0")
        var y = Vector[Int](3, 0)
        EXPECT_EQ(format("{}", join(y, ",")), "0,0,0")
        EXPECT_EQ(format("{}", join(Vector[Int](3, 0), ",")), "0,0,0")
        var z = Vector[Int](3, 0)
        EXPECT_EQ(format("{}", join(z, ",")), "0,0,0")
    #endif

    def is_printable_test(self) raises:
        var is_printable = detail.is_printable
        EXPECT_TRUE(is_printable(0x0323))
        EXPECT_FALSE(is_printable(0x0378))
        EXPECT_FALSE(is_printable(0x110000))

    def escape_string_test(self) raises:
        using vec = Vector[String]
        EXPECT_EQ(format("{}", vec{"\n\r\t\"\\"}), "[\"\\n\\r\\t\\\"\\\\\"]")
        EXPECT_EQ(format("{}", vec{"\x07"}), "[\"\\x07\"]")
        EXPECT_EQ(format("{}", vec{"\x7f"}), "[\"\\x7f\"]")
        EXPECT_EQ(format("{}", vec{"n\xcc\x83"}), "[\"n\xcc\x83\"]")
        if detail.is_utf8():
            EXPECT_EQ(format("{}", vec{"\xcd\xb8"}), "[\"\\u0378\"]")
            EXPECT_EQ(format("{}", vec{"\xf0\xaa\x9b\x9e"}), "[\"\\U0002a6de\"]")
            EXPECT_EQ(format("{}", vec{"\xf4\x8f\xbf\xc0"}), "[\"\\xf4\\x8f\\xbf\\xc0\"]")