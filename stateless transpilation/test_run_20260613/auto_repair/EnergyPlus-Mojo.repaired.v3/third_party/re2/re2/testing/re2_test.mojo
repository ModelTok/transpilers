from third_party.re2.re2.re2 import RE2
from third_party.re2.re2.regexp import RegExp
from third_party.re2.util.test import *
from third_party.re2.util.logging import *
from third_party.re2.util.strutil import *
from math import *
from memory import *
from os import *
from sys import *
from utils import *

# TODO: verify mappings for NULL, None
alias NULL = Pointer[None]()
alias None = Pointer[None]()

# TODO: verify arraysize equivalent
def arraysize(arr: Pointer[Any]) -> Int:
    return arr.unsafe_size()

# TODO: verify StringPrintf equivalent
def StringPrintf(format: String, *args: Any) -> String:
    return format % args

# TODO: verify RE2::Hex, RE2::Octal, RE2::CRadix, RE2::Quiet, RE2::Latin1, etc.
# These are likely enums or static methods in the original C++.

# TODO: verify mmap/munmap/sysconf availability in Mojo

def TestRecursion(size: Int32, pattern: String):
    var domain = String()
    domain.resize(size)
    var patlen = len(pattern)
    for i in range(size):
        domain[i] = pattern[i % patlen]
    var re = RE2("([a-zA-Z0-9]|-)+(\\.([a-zA-Z0-9]|-)+)*(\\.)?", RE2.Quiet)
    RE2.FullMatch(domain, re)

def TestQuoteMeta(unquoted: String, options: RE2.Options = RE2.DefaultOptions):
    var quoted = RE2.QuoteMeta(unquoted)
    var re = RE2(quoted, options)
    assert_true(RE2.FullMatch(unquoted, re), "Unquoted='" + unquoted + "', quoted='" + quoted + "'.")

def NegativeTestQuoteMeta(unquoted: String, should_not_match: String, options: RE2.Options = RE2.DefaultOptions):
    var quoted = RE2.QuoteMeta(unquoted)
    var re = RE2(quoted, options)
    assert_false(RE2.FullMatch(should_not_match, re), "Unquoted='" + unquoted + "', quoted='" + quoted + "'.")

def main():
    # TODO: wrap in test framework equivalent

# TEST(RE2, HexTests)
def test_HexTests():
    # Note: macros not directly supported, tests
    # ASSERT_HEX(short, 2bad)
    var v_short: Int16
    assert_true(RE2.FullMatch("2bad", "([0-9a-fA-F]+)[uUlL]*", RE2.Hex(&v_short)))
    assert_eq(v_short, 0x2bad)
    assert_true(RE2.FullMatch("0x2bad", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_short)))
    assert_eq(v_short, 0x2bad)

    # ASSERT_HEX(unsigned short, 2badU)
    var v_ushort: UInt16
    assert_true(RE2.FullMatch("2badU", "([0-9a-fA-F]+)[uUlL]*", RE2.Hex(&v_ushort)))
    assert_eq(v_ushort, 0x2bad)
    assert_true(RE2.FullMatch("0x2badU", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ushort)))
    assert_eq(v_ushort, 0x2bad)

    # ASSERT_HEX(int, dead)
    var v_int: Int32
    assert_true(RE2.FullMatch("dead", "([0-9a-fA-F]+)[uUlL]*", RE2.Hex(&v_int)))
    assert_eq(v_int, 0xdead)
    assert_true(RE2.FullMatch("0xdead", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_int)))
    assert_eq(v_int, 0xdead)

    # ASSERT_HEX(unsigned int, deadU)
    var v_uint: UInt32
    assert_true(RE2.FullMatch("deadU", "([0-9a-fA-F]+)[uUlL]*", RE2.Hex(&v_uint)))
    assert_eq(v_uint, 0xdead)
    assert_true(RE2.FullMatch("0xdeadU", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_uint)))
    assert_eq(v_uint, 0xdead)

    # ASSERT_HEX(long, 7eadbeefL)
    var v_long: Int64
    assert_true(RE2.FullMatch("7eadbeefL", "([0-9a-fA-F]+)[uUlL]*", RE2.Hex(&v_long)))
    assert_eq(v_long, 0x7eadbeef)
    assert_true(RE2.FullMatch("0x7eadbeefL", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_long)))
    assert_eq(v_long, 0x7eadbeef)

    # ASSERT_HEX(unsigned long, deadbeefUL)
    var v_ulong: UInt64
    assert_true(RE2.FullMatch("deadbeefUL", "([0-9a-fA-F]+)[uUlL]*", RE2.Hex(&v_ulong)))
    assert_eq(v_ulong, 0xdeadbeef)
    assert_true(RE2.FullMatch("0xdeadbeefUL", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ulong)))
    assert_eq(v_ulong, 0xdeadbeef)

    # ASSERT_HEX(long long, 12345678deadbeefLL)
    var v_longlong: Int64
    assert_true(RE2.FullMatch("12345678deadbeefLL", "([0-9a-fA-F]+)[uUlL]*", RE2.Hex(&v_longlong)))
    assert_eq(v_longlong, 0x12345678deadbeef)
    assert_true(RE2.FullMatch("0x12345678deadbeefLL", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_longlong)))
    assert_eq(v_longlong, 0x12345678deadbeef)

    # ASSERT_HEX(unsigned long long, cafebabedeadbeefULL)
    var v_ulonglong: UInt64
    assert_true(RE2.FullMatch("cafebabedeadbeefULL", "([0-9a-fA-F]+)[uUlL]*", RE2.Hex(&v_ulonglong)))
    assert_eq(v_ulonglong, 0xcafebabedeadbeef)
    assert_true(RE2.FullMatch("0xcafebabedeadbeefULL", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ulonglong)))
    assert_eq(v_ulonglong, 0xcafebabedeadbeef)

# TEST(RE2, OctalTests)
def test_OctalTests():
    # ASSERT_OCTAL(short, 77777)
    var v_short: Int16
    assert_true(RE2.FullMatch("77777", "([0-7]+)[uUlL]*", RE2.Octal(&v_short)))
    assert_eq(v_short, 0077777)
    assert_true(RE2.FullMatch("077777", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_short)))
    assert_eq(v_short, 0077777)

    # ASSERT_OCTAL(unsigned short, 177777U)
    var v_ushort: UInt16
    assert_true(RE2.FullMatch("177777U", "([0-7]+)[uUlL]*", RE2.Octal(&v_ushort)))
    assert_eq(v_ushort, 0177777)
    assert_true(RE2.FullMatch("0177777U", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ushort)))
    assert_eq(v_ushort, 0177777)

    # ASSERT_OCTAL(int, 17777777777)
    var v_int: Int32
    assert_true(RE2.FullMatch("17777777777", "([0-7]+)[uUlL]*", RE2.Octal(&v_int)))
    assert_eq(v_int, 017777777777)
    assert_true(RE2.FullMatch("017777777777", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_int)))
    assert_eq(v_int, 017777777777)

    # ASSERT_OCTAL(unsigned int, 37777777777U)
    var v_uint: UInt32
    assert_true(RE2.FullMatch("37777777777U", "([0-7]+)[uUlL]*", RE2.Octal(&v_uint)))
    assert_eq(v_uint, 037777777777)
    assert_true(RE2.FullMatch("037777777777U", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_uint)))
    assert_eq(v_uint, 037777777777)

    # ASSERT_OCTAL(long, 17777777777L)
    var v_long: Int64
    assert_true(RE2.FullMatch("17777777777L", "([0-7]+)[uUlL]*", RE2.Octal(&v_long)))
    assert_eq(v_long, 017777777777)
    assert_true(RE2.FullMatch("017777777777L", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_long)))
    assert_eq(v_long, 017777777777)

    # ASSERT_OCTAL(unsigned long, 37777777777UL)
    var v_ulong: UInt64
    assert_true(RE2.FullMatch("37777777777UL", "([0-7]+)[uUlL]*", RE2.Octal(&v_ulong)))
    assert_eq(v_ulong, 037777777777)
    assert_true(RE2.FullMatch("037777777777UL", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ulong)))
    assert_eq(v_ulong, 037777777777)

    # ASSERT_OCTAL(long long, 777777777777777777777LL)
    var v_longlong: Int64
    assert_true(RE2.FullMatch("777777777777777777777LL", "([0-7]+)[uUlL]*", RE2.Octal(&v_longlong)))
    assert_eq(v_longlong, 0777777777777777777777)
    assert_true(RE2.FullMatch("0777777777777777777777LL", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_longlong)))
    assert_eq(v_longlong, 0777777777777777777777)

    # ASSERT_OCTAL(unsigned long long, 1777777777777777777777ULL)
    var v_ulonglong: UInt64
    assert_true(RE2.FullMatch("1777777777777777777777ULL", "([0-7]+)[uUlL]*", RE2.Octal(&v_ulonglong)))
    assert_eq(v_ulonglong, 01777777777777777777777)
    assert_true(RE2.FullMatch("01777777777777777777777ULL", "([0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ulonglong)))
    assert_eq(v_ulonglong, 01777777777777777777777)

# TEST(RE2, DecimalTests)
def test_DecimalTests():
    # ASSERT_DECIMAL(short, -1)
    var v_short: Int16
    assert_true(RE2.FullMatch("-1", "(-?[0-9]+)[uUlL]*", &v_short))
    assert_eq(v_short, -1)
    assert_true(RE2.FullMatch("-1", "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_short)))
    assert_eq(v_short, -1)

    # ASSERT_DECIMAL(unsigned short, 9999)
    var v_ushort: UInt16
    assert_true(RE2.FullMatch("9999", "(-?[0-9]+)[uUlL]*", &v_ushort))
    assert_eq(v_ushort, 9999)
    assert_true(RE2.FullMatch("9999", "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ushort)))
    assert_eq(v_ushort, 9999)

    # ASSERT_DECIMAL(int, -1000)
    var v_int: Int32
    assert_true(RE2.FullMatch("-1000", "(-?[0-9]+)[uUlL]*", &v_int))
    assert_eq(v_int, -1000)
    assert_true(RE2.FullMatch("-1000", "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_int)))
    assert_eq(v_int, -1000)

    # ASSERT_DECIMAL(unsigned int, 12345U)
    var v_uint: UInt32
    assert_true(RE2.FullMatch("12345U", "(-?[0-9]+)[uUlL]*", &v_uint))
    assert_eq(v_uint, 12345)
    assert_true(RE2.FullMatch("12345U", "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_uint)))
    assert_eq(v_uint, 12345)

    # ASSERT_DECIMAL(long, -10000000L)
    var v_long: Int64
    assert_true(RE2.FullMatch("-10000000L", "(-?[0-9]+)[uUlL]*", &v_long))
    assert_eq(v_long, -10000000)
    assert_true(RE2.FullMatch("-10000000L", "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_long)))
    assert_eq(v_long, -10000000)

    # ASSERT_DECIMAL(unsigned long, 3083324652U)
    var v_ulong: UInt64
    assert_true(RE2.FullMatch("3083324652U", "(-?[0-9]+)[uUlL]*", &v_ulong))
    assert_eq(v_ulong, 3083324652)
    assert_true(RE2.FullMatch("3083324652U", "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ulong)))
    assert_eq(v_ulong, 3083324652)

    # ASSERT_DECIMAL(long long, -100000000000000LL)
    var v_longlong: Int64
    assert_true(RE2.FullMatch("-100000000000000LL", "(-?[0-9]+)[uUlL]*", &v_longlong))
    assert_eq(v_longlong, -100000000000000)
    assert_true(RE2.FullMatch("-100000000000000LL", "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_longlong)))
    assert_eq(v_longlong, -100000000000000)

    # ASSERT_DECIMAL(unsigned long long, 1234567890987654321ULL)
    var v_ulonglong: UInt64
    assert_true(RE2.FullMatch("1234567890987654321ULL", "(-?[0-9]+)[uUlL]*", &v_ulonglong))
    assert_eq(v_ulonglong, 1234567890987654321)
    assert_true(RE2.FullMatch("1234567890987654321ULL", "(-?[0-9a-fA-FxX]+)[uUlL]*", RE2.CRadix(&v_ulonglong)))
    assert_eq(v_ulonglong, 1234567890987654321)

# TEST(RE2, Replace)
def test_Replace():
    struct ReplaceTest:
        var regexp: String
        var rewrite: String
        var original: String
        var single: String
        var global: String
        var greplace_count: Int32
    var tests = List[ReplaceTest]()
    tests.append(ReplaceTest("(qu|[b-df-hj-np-tv-z]*)([a-z]+)", "\\2\\1ay", "the quick brown fox jumps over the lazy dogs.", "ethay quick brown fox jumps over the lazy dogs.", "ethay ickquay ownbray oxfay umpsjay overay ethay azylay ogsday.", 9))
    tests.append(ReplaceTest("\\w+", "\\0-NOSPAM", "abcd.efghi@google.com", "abcd-NOSPAM.efghi@google.com", "abcd-NOSPAM.efghi-NOSPAM@google-NOSPAM.com-NOSPAM", 4))
    tests.append(ReplaceTest("^", "(START)", "foo", "(START)foo", "(START)foo", 1))
    tests.append(ReplaceTest("^", "(START)", "", "(START)", "(START)", 1))
    tests.append(ReplaceTest("$", "(END)", "", "(END)", "(END)", 1))
    tests.append(ReplaceTest("b", "bb", "ababababab", "abbabababab", "abbabbabbabbabb", 5))
    tests.append(ReplaceTest("b", "bb", "bbbbbb", "bbbbbbb", "bbbbbbbbbbbb", 6))
    tests.append(ReplaceTest("b+", "bb", "bbbbbb", "bb", "bb", 1))
    tests.append(ReplaceTest("b*", "bb", "bbbbbb", "bb", "bb", 1))
    tests.append(ReplaceTest("b*", "bb", "aaaaa", "bbaaaaa", "bbabbabbabbabbabb", 6))
    tests.append(ReplaceTest("a.*a", "(\\0)", "aba\naba", "(aba)\naba", "(aba)\n(aba)", 2))

    for t in tests:
        var one = String(t.original)
        assert_true(RE2.Replace(one, t.regexp, t.rewrite))
        assert_eq(one, t.single)
        var all_ = String(t.original)
        assert_eq(RE2.GlobalReplace(all_, t.regexp, t.rewrite), t.greplace_count, "Got: " + all_)
        assert_eq(all_, t.global)

# TestCheckRewriteString helper
def TestCheckRewriteString(regexp: String, rewrite: String, expect_ok: Bool):
    var error = String()
    var exp = RE2(regexp)
    var actual_ok = exp.CheckRewriteString(rewrite, error)
    assert_eq(expect_ok, actual_ok, " for " + rewrite + " error: " + error)

# TEST(CheckRewriteString, all)
def test_CheckRewriteString_all():
    TestCheckRewriteString("abc", "foo", True)
    TestCheckRewriteString("abc", "foo\\", False)
    TestCheckRewriteString("abc", "foo\\0bar", True)
    TestCheckRewriteString("a(b)c", "foo", True)
    TestCheckRewriteString("a(b)c", "foo\\0bar", True)
    TestCheckRewriteString("a(b)c", "foo\\1bar", True)
    TestCheckRewriteString("a(b)c", "foo\\2bar", False)
    TestCheckRewriteString("a(b)c", "f\\\\2o\\1o", True)
    TestCheckRewriteString("a(b)(c)", "foo\\12", True)
    TestCheckRewriteString("a(b)(c)", "f\\2o\\1o", True)
    TestCheckRewriteString("a(b)(c)", "f\\oo\\1", False)

# TEST(RE2, Extract)
def test_Extract():
    var s = String()
    assert_true(RE2.Extract("boris@kremvax.ru", "(.*)@([^.]*)", "\\2!\\1", s))
    assert_eq(s, "kremvax!boris")
    assert_true(RE2.Extract("foo", ".*", "'\\0'", s))
    assert_eq(s, "'foo'")
    assert_false(RE2.Extract("baz", "bar", "'\\0'", s))
    assert_eq(s, "'foo'")

# TEST(RE2, MaxSubmatchTooLarge)
def test_MaxSubmatchTooLarge():
    var s = String()
    assert_false(RE2.Extract("foo", "f(o+)", "\\1\\2", s))
    s = "foo"
    assert_false(RE2.Replace(s, "f(o+)", "\\1\\2"))
    s = "foo"
    assert_false(RE2.GlobalReplace(s, "f(o+)", "\\1\\2"))

# TEST(RE2, Consume)
def test_Consume():
    var r = RE2("\\s*(\\w+)")
    var word = String()
    var s = "   aaa b!@#$@#$cccc"
    var input = StringPiece(s)
    assert_true(RE2.Consume(input, r, word))
    assert_eq(word, "aaa", " input: " + str(input))
    assert_true(RE2.Consume(input, r, word))
    assert_eq(word, "b", " input: " + str(input))
    assert_false(RE2.Consume(input, r, word), " input: " + str(input))

# TEST(RE2, ConsumeN)
def test_ConsumeN():
    var s = " one two three 4"
    var input = StringPiece(s)
    var argv = List[RE2.Arg](2)
    var args = List[RE2.Arg]([argv[0], argv[1]])
    assert_true(RE2.ConsumeN(input, "\\s*(\\w+)", args, 0))  # Skips "one".
    var word = String()
    argv[0] = RE2.Arg(&word)
    assert_true(RE2.ConsumeN(input, "\\s*(\\w+)", args, 1))
    assert_eq("two", word)
    var n: Int32
    argv[1] = RE2.Arg(&n)
    assert_true(RE2.ConsumeN(input, "\\s*(\\w+)\\s*(\\d+)", args, 2))
    assert_eq("three", word)
    assert_eq(4, n)

# TEST(RE2, FindAndConsume)
def test_FindAndConsume():
    var r = RE2("(\\w+)")
    var word = String()
    var s = "   aaa b!@#$@#$cccc"
    var input = StringPiece(s)
    assert_true(RE2.FindAndConsume(input, r, word))
    assert_eq(word, "aaa")
    assert_true(RE2.FindAndConsume(input, r, word))
    assert_eq(word, "b")
    assert_true(RE2.FindAndConsume(input, r, word))
    assert_eq(word, "cccc")
    assert_false(RE2.FindAndConsume(input, r, word))
    input = StringPiece("aaa")
    assert_true(RE2.FindAndConsume(input, "aaa"))
    assert_eq(input, StringPiece(""))

# TEST(RE2, FindAndConsumeN)
def test_FindAndConsumeN():
    var s = " one two three 4"
    var input = StringPiece(s)
    var argv = List[RE2.Arg](2)
    var args = List[RE2.Arg]([argv[0], argv[1]])
    assert_true(RE2.FindAndConsumeN(input, "(\\w+)", args, 0))  # Skips "one".
    var word = String()
    argv[0] = RE2.Arg(&word)
    assert_true(RE2.FindAndConsumeN(input, "(\\w+)", args, 1))
    assert_eq("two", word)
    var n: Int32
    argv[1] = RE2.Arg(&n)
    assert_true(RE2.FindAndConsumeN(input, "(\\w+)\\s*(\\d+)", args, 2))
    assert_eq("three", word)
    assert_eq(4, n)

# TEST(RE2, MatchNumberPeculiarity)
def test_MatchNumberPeculiarity():
    var r = RE2("(foo)|(bar)|(baz)")
    var word1 = String()
    var word2 = String()
    var word3 = String()
    assert_true(RE2.PartialMatch("foo", r, word1, word2, word3))
    assert_eq(word1, "foo")
    assert_eq(word2, "")
    assert_eq(word3, "")
    assert_true(RE2.PartialMatch("bar", r, word1, word2, word3))
    assert_eq(word1, "")
    assert_eq(word2, "bar")
    assert_eq(word3, "")
    assert_true(RE2.PartialMatch("baz", r, word1, word2, word3))
    assert_eq(word1, "")
    assert_eq(word2, "")
    assert_eq(word3, "baz")
    assert_false(RE2.PartialMatch("f", r, word1, word2, word3))
    var a = String()
    assert_true(RE2.FullMatch("hello", "(foo)|hello", a))
    assert_eq(a, "")

# TEST(RE2, Match)
def test_Match():
    var re = RE2("((\\w+):([0-9]+))")
    var group = List[StringPiece](4)
    var s = StringPiece("zyzzyva")
    assert_false(re.Match(s, 0, s.size(), RE2.UNANCHORED, group.pointer(), 4))
    s = StringPiece("a chrisr:9000 here")
    assert_true(re.Match(s, 0, s.size(), RE2.UNANCHORED, group.pointer(), 4))
    assert_eq(group[0], StringPiece("chrisr:9000"))
    assert_eq(group[1], StringPiece("chrisr:9000"))
    assert_eq(group[2], StringPiece("chrisr"))
    assert_eq(group[3], StringPiece("9000"))
    var all_ = String()
    var host = String()
    var port: Int32
    assert_true(RE2.PartialMatch("a chrisr:9000 here", re, all_, host, port))
    assert_eq(all_, "chrisr:9000")
    assert_eq(host, "chrisr")
    assert_eq(port, 9000)

# TEST(QuoteMeta, Simple)
def test_QuoteMeta_Simple():
    TestQuoteMeta("foo")
    TestQuoteMeta("foo.bar")
    TestQuoteMeta("foo\\.bar")
    TestQuoteMeta("[1-9]")
    TestQuoteMeta("1.5-2.0?")
    TestQuoteMeta("\\d")
    TestQuoteMeta("Who doesn't like ice cream?")
    TestQuoteMeta("((a|b)c?d*e+[f-h]i)")
    TestQuoteMeta("((?!)xxx).*yyy")
    TestQuoteMeta("([")
    TestQuoteMeta("")

# TEST(QuoteMeta, SimpleNegative)
def test_QuoteMeta_SimpleNegative():
    NegativeTestQuoteMeta("foo", "bar")
    NegativeTestQuoteMeta("...", "bar")
    NegativeTestQuoteMeta("\\.", ".")
    NegativeTestQuoteMeta("\\.", "..")
    NegativeTestQuoteMeta("(a)", "a")
    NegativeTestQuoteMeta("(a|b)", "a")
    NegativeTestQuoteMeta("(a|b)", "(a)")
    NegativeTestQuoteMeta("(a|b)", "a|b")
    NegativeTestQuoteMeta("[0-9]", "0")
    NegativeTestQuoteMeta("[0-9]", "0-9")
    NegativeTestQuoteMeta("[0-9]", "[9]")
    NegativeTestQuoteMeta("((?!)xxx)", "xxx")

# TEST(QuoteMeta, Latin1)
def test_QuoteMeta_Latin1():
    TestQuoteMeta("3\xb2 = 9", RE2.Latin1)

# TEST(QuoteMeta, UTF8)
def test_QuoteMeta_UTF8():
    TestQuoteMeta("Plácido Domingo")
    TestQuoteMeta("xyz")
    TestQuoteMeta("\xc2\xb0")
    TestQuoteMeta("27\xc2\xb0 degrees")
    TestQuoteMeta("\xe2\x80\xb3")
    TestQuoteMeta("\xf0\x9d\x85\x9f")
    TestQuoteMeta("27\xc2\xb0")
    NegativeTestQuoteMeta("27\xc2\xb0", "27\\\xc2\\\xb0")

# TEST(QuoteMeta, HasNull)
def test_QuoteMeta_HasNull():
    var has_null = String()
    has_null += '\0'
    TestQuoteMeta(has_null)
    NegativeTestQuoteMeta(has_null, "")
    has_null += '1'
    TestQuoteMeta(has_null)
    NegativeTestQuoteMeta(has_null, "\1")

# TEST(ProgramSize, BigProgram)
def test_ProgramSize_BigProgram():
    var re_simple = RE2("simple regexp")
    var re_medium = RE2("medium.*regexp")
    var re_complex = RE2("complex.{1,128}regexp")
    assert_gt(re_simple.ProgramSize(), 0)
    assert_gt(re_medium.ProgramSize(), re_simple.ProgramSize())
    assert_gt(re_complex.ProgramSize(), re_medium.ProgramSize())
    assert_gt(re_simple.ReverseProgramSize(), 0)
    assert_gt(re_medium.ReverseProgramSize(), re_simple.ReverseProgramSize())
    assert_gt(re_complex.ReverseProgramSize(), re_medium.ReverseProgramSize())

# TEST(ProgramFanout, BigProgram)
def test_ProgramFanout_BigProgram():
    var re1 = RE2("(?:(?:(?:(?:(?:.)?){1})*)+)")
    var re10 = RE2("(?:(?:(?:(?:(?:.)?){10})*)+)")
    var re100 = RE2("(?:(?:(?:(?:(?:.)?){100})*)+)")
    var re1000 = RE2("(?:(?:(?:(?:(?:.)?){1000})*)+)")
    var histogram = List[Int32]()
    assert_eq(3, re1.ProgramFanout(histogram))
    assert_eq(2, histogram[3])
    assert_eq(6, re10.ProgramFanout(histogram))
    assert_eq(11, histogram[6])
    assert_eq(9, re100.ProgramFanout(histogram))
    assert_eq(101, histogram[9])
    assert_eq(13, re1000.ProgramFanout(histogram))
    assert_eq(1001, histogram[13])
    assert_eq(2, re1.ReverseProgramFanout(histogram))
    assert_eq(2, histogram[2])
    assert_eq(5, re10.ReverseProgramFanout(histogram))
    assert_eq(11, histogram[5])
    assert_eq(9, re100.ReverseProgramFanout(histogram))
    assert_eq(101, histogram[9])
    assert_eq(12, re1000.ReverseProgramFanout(histogram))
    assert_eq(1001, histogram[12])

# TEST(EmptyCharset, Fuzz)
def test_EmptyCharset_Fuzz():
    var empties = List[String]()
    empties.append("[^\\S\\s]")
    empties.append("[^\\S[:space:]]")
    empties.append("[^\\D\\d]")
    empties.append("[^\\D[:digit:]]")
    for i in range(empties.size()):
        assert_false(RE2(empties[i]).Match("abc", 0, 3, RE2.UNANCHORED, NULL, 0))

# TEST(EmptyCharset, BitstateAssumptions)
def test_EmptyCharset_BitstateAssumptions():
    var nop_empties = List[String]()
    nop_empties.append("((((()))))" "[^\\S\\s]?")
    nop_empties.append("((((()))))" "([^\\S\\s])?")
    nop_empties.append("((((()))))" "([^\\S\\s]|[^\\S\\s])?")
    nop_empties.append("((((()))))" "(([^\\S\\s]|[^\\S\\s])|)")
    var group = List[StringPiece](6)
    for i in range(nop_empties.size()):
        assert_true(RE2(nop_empties[i]).Match("", 0, 0, RE2.UNANCHORED, group.pointer(), 6))

# TEST(Capture, NamedGroups)
def test_Capture_NamedGroups():
    {
        var re = RE2("(hello world)")
        assert_eq(re.NumberOfCapturingGroups(), 1)
        let m = re.NamedCapturingGroups()
        assert_eq(m.size(), 0)
    }
    {
        var re = RE2("(?P<A>expr(?P<B>expr)(?P<C>expr))((expr)(?P<D>expr))")
        assert_eq(re.NumberOfCapturingGroups(), 6)
        let m = re.NamedCapturingGroups()
        assert_eq(m.size(), 4)
        assert_eq(m["A"], 1)
        assert_eq(m["B"], 2)
        assert_eq(m["C"], 3)
        assert_eq(m["D"], 6)
    }

# TEST(RE2, CapturedGroupTest)
def test_CapturedGroupTest():
    var re = RE2("directions from (?P<S>.*) to (?P<D>.*)")
    var num_groups = re.NumberOfCapturingGroups()
    assert_eq(2, num_groups)
    var args = List[String](4)
    var arg0 = RE2.Arg(&args[0])
    var arg1 = RE2.Arg(&args[1])
    var arg2 = RE2.Arg(&args[2])
    var arg3 = RE2.Arg(&args[3])
    var matches = List[RE2.Arg]([arg0, arg1, arg2, arg3])
    assert_true(RE2.FullMatchN("directions from mountain view to san jose", re, matches.pointer(), num_groups))
    let named_groups = re.NamedCapturingGroups()
    assert_true("S" in named_groups)
    assert_true("D" in named_groups)
    var source_group_index = named_groups["S"]
    var destination_group_index = named_groups["D"]
    assert_eq(1, source_group_index)
    assert_eq(2, destination_group_index)
    assert_eq("mountain view", args[source_group_index - 1])
    assert_eq("san jose", args[destination_group_index - 1])

# TEST(RE2, FullMatchWithNoArgs)
def test_FullMatchWithNoArgs():
    assert_true(RE2.FullMatch("h", "h"))
    assert_true(RE2.FullMatch("hello", "hello"))
    assert_true(RE2.FullMatch("hello", "h.*o"))
    assert_false(RE2.FullMatch("othello", "h.*o"))
    assert_false(RE2.FullMatch("hello!", "h.*o"))

# TEST(RE2, PartialMatch)
def test_PartialMatch():
    assert_true(RE2.PartialMatch("x", "x"))
    assert_true(RE2.PartialMatch("hello", "h.*o"))
    assert_true(RE2.PartialMatch("othello", "h.*o"))
    assert_true(RE2.PartialMatch("hello!", "h.*o"))
    assert_true(RE2.PartialMatch("x", "((((((((((((((((((((x)))))))))))))))))))))")

# TEST(RE2, PartialMatchN)
def test_PartialMatchN():
    var argv = List[RE2.Arg](2)
    var args = List[RE2.Arg]([argv[0], argv[1]])
    assert_true(RE2.PartialMatchN("hello", "e.*o", args.pointer(), 0))
    assert_false(RE2.PartialMatchN("othello", "a.*o", args.pointer(), 0))
    var i: Int32
    argv[0] = RE2.Arg(&i)
    assert_true(RE2.PartialMatchN("1001 nights", "(\\d+)", args.pointer(), 1))
    assert_eq(1001, i)
    assert_false(RE2.PartialMatchN("three", "(\\d+)", args.pointer(), 1))
    var s = String()
    argv[1] = RE2.Arg(&s)
    assert_true(RE2.PartialMatchN("answer: 42:life", "(\\d+):(\\w+)", args.pointer(), 2))
    assert_eq(42, i)
    assert_eq("life", s)
    assert_false(RE2.PartialMatchN("hi1", "(\\w+)(1)", args.pointer(), 2))

# TEST(RE2, FullMatchZeroArg)
def test_FullMatchZeroArg():
    assert_true(RE2.FullMatch("1001", "\\d+"))

# TEST(RE2, FullMatchOneArg)
def test_FullMatchOneArg():
    var i: Int32
    assert_true(RE2.FullMatch("1001", "(\\d+)", i))
    assert_eq(i, 1001)
    assert_true(RE2.FullMatch("-123", "(-?\\d+)", i))
    assert_eq(i, -123)
    assert_false(RE2.FullMatch("10", "()\\d+", i))
    assert_false(RE2.FullMatch("1234567890123456789012345678901234567890", "(\\d+)", i))

# TEST(RE2, FullMatchIntegerArg)
def test_FullMatchIntegerArg():
    var i: Int32
    assert_true(RE2.FullMatch("1234", "1(\\d*)4", i))
    assert_eq(i, 23)
    assert_true(RE2.FullMatch("1234", "(\\d)\\d+", i))
    assert_eq(i, 1)
    assert_true(RE2.FullMatch("-1234", "(-\\d)\\d+", i))
    assert_eq(i, -1)
    assert_true(RE2.PartialMatch("1234", "(\\d)", i))
    assert_eq(i, 1)
    assert_true(RE2.PartialMatch("-1234", "(-\\d)", i))
    assert_eq(i, -1)

# TEST(RE2, FullMatchStringArg)
def test_FullMatchStringArg():
    var s = String()
    assert_true(RE2.FullMatch("hello", "h(.*)o", s))
    assert_eq(s, "ell")

# TEST(RE2, FullMatchStringPieceArg)
def test_FullMatchStringPieceArg():
    var i: Int32
    var sp = StringPiece()
    assert_true(RE2.FullMatch("ruby:1234", "(\\w+):(\\d+)", sp, i))
    assert_eq(sp.size(), 4)
    assert_true(sp.data() == "ruby")
    assert_eq(i, 1234)

# TEST(RE2, FullMatchMultiArg)
def test_FullMatchMultiArg():
    var i: Int32
    var s = String()
    assert_true(RE2.FullMatch("ruby:1234", "(\\w+):(\\d+)", s, i))
    assert_eq(s, "ruby")
    assert_eq(i, 1234)

# TEST(RE2, FullMatchN)
def test_FullMatchN():
    var argv = List[RE2.Arg](2)
    var args = List[RE2.Arg]([argv[0], argv[1]])
    assert_true(RE2.FullMatchN("hello", "h.*o", args.pointer(), 0))
    assert_false(RE2.FullMatchN("othello", "h.*o", args.pointer(), 0))
    var i: Int32
    argv[0] = RE2.Arg(&i)
    assert_true(RE2.FullMatchN("1001", "(\\d+)", args.pointer(), 1))
    assert_eq(1001, i)
    assert_false(RE2.FullMatchN("three", "(\\d+)", args.pointer(), 1))
    var s = String()
    argv[1] = RE2.Arg(&s)
    assert_true(RE2.FullMatchN("42:life", "(\\d+):(\\w+)", args.pointer(), 2))
    assert_eq(42, i)
    assert_eq("life", s)
    assert_false(RE2.FullMatchN("hi1", "(\\w+)(1)", args.pointer(), 2))

# TEST(RE2, FullMatchIgnoredArg)
def test_FullMatchIgnoredArg():
    var i: Int32
    var s = String()
    assert_true(RE2.FullMatch("ruby:1234", "(\\w+)(:)(\\d+)", s, (void*)NULL, i))
    assert_eq(s, "ruby")
    assert_eq(i, 1234)
    assert_true(RE2.FullMatch("rubz:1235", "(\\w+)(:)(\\d+)", s, None, i))
    assert_eq(s, "rubz")
    assert_eq(i, 1235)

# TEST(RE2, FullMatchTypedNullArg)
def test_FullMatchTypedNullArg():
    var s = String()
    assert_true(RE2.FullMatch("hello", "he(.*)lo", (char*)NULL))
    assert_true(RE2.FullMatch("hello", "h(.*)o", (String*)NULL))
    assert_true(RE2.FullMatch("hello", "h(.*)o", (StringPiece*)NULL))
    assert_true(RE2.FullMatch("1234", "(.*)", (Int32*)NULL))
    assert_true(RE2.FullMatch("1234567890123456", "(.*)", (Int64*)NULL))
    assert_true(RE2.FullMatch("123.4567890123456", "(.*)", (Float64*)NULL))
    assert_true(RE2.FullMatch("123.4567890123456", "(.*)", (Float32*)NULL))
    assert_false(RE2.FullMatch("hello", "h(.*)lo", s, (char*)NULL))
    assert_false(RE2.FullMatch("hello", "(.*)", (Int32*)NULL))
    assert_false(RE2.FullMatch("1234567890123456", "(.*)", (Int32*)NULL))
    assert_false(RE2.FullMatch("hello", "(.*)", (Float64*)NULL))
    assert_false(RE2.FullMatch("hello", "(.*)", (Float32*)NULL))

# TEST(RE2, NULTerminated)
def test_NULTerminated():
    #if defined(_POSIX_MAPPED_FILES) && _POSIX_MAPPED_FILES > 0
    #  char *v;
    #  int x;
    #  long pagesize = sysconf(_SC_PAGE_SIZE);
    #  v = static_cast<char*>(mmap(NULL, 2*pagesize, PROT_READ|PROT_WRITE,
    #                              MAP_ANONYMOUS|MAP_PRIVATE, -1, 0));
    #  ASSERT_TRUE(v != reinterpret_cast<char*>(-1));
    #  LOG(INFO) << "Memory at " << (void*)v;
    #  ASSERT_EQ(munmap(v + pagesize, pagesize), 0) << " error " << errno;
    #  v[pagesize - 1] = '1';
    #  x = 0;
    #  ASSERT_TRUE(RE2::FullMatch(StringPiece(v + pagesize - 1, 1), "(.*)", &x));
    #  ASSERT_EQ(x, 1);
    #endif

# TEST(RE2, FullMatchTypeTests)
def test_FullMatchTypeTests():
    var zeros = ""
    for _ in range(1000):
        zeros += "0"
    {
        var c: Int8
        assert_true(RE2.FullMatch("Hello", "(H)ello", c))
        assert_eq(c, ord('H'))
    }
    {
        var c: UInt8
        assert_true(RE2.FullMatch("Hello", "(H)ello", c))
        assert_eq(c, ord('H'))
    }
    {
        var v: Int16
        assert_true(RE2.FullMatch("100", "(-?\\d+)", v))
        assert_eq(v, 100)
        assert_true(RE2.FullMatch("-100", "(-?\\d+)", v))
        assert_eq(v, -100)
        assert_true(RE2.FullMatch("32767", "(-?\\d+)", v))
        assert_eq(v, 32767)
        assert_true(RE2.FullMatch("-32768", "(-?\\d+)", v))
        assert_eq(v, -32768)
        assert_false(RE2.FullMatch("-32769", "(-?\\d+)", v))
        assert_false(RE2.FullMatch("32768", "(-?\\d+)", v))
    }
    {
        var v: UInt16
        assert_true(RE2.FullMatch("100", "(\\d+)", v))
        assert_eq(v, 100)
        assert_true(RE2.FullMatch("32767", "(\\d+)", v))
        assert_eq(v, 32767)
        assert_true(RE2.FullMatch("65535", "(\\d+)", v))
        assert_eq(v, 65535)
        assert_false(RE2.FullMatch("65536", "(\\d+)", v))
    }
    {
        var v: Int32
        var max: Int32 = 0x7fffffff
        var min: Int32 = -max - 1
        assert_true(RE2.FullMatch("100", "(-?\\d+)", v))
        assert_eq(v, 100)
        assert_true(RE2.FullMatch("-100", "(-?\\d+)", v))
        assert_eq(v, -100)
        assert_true(RE2.FullMatch("2147483647", "(-?\\d+)", v))
        assert_eq(v, max)
        assert_true(RE2.FullMatch("-2147483648", "(-?\\d+)", v))
        assert_eq(v, min)
        assert_false(RE2.FullMatch("-2147483649", "(-?\\d+)", v))
        assert_false(RE2.FullMatch("2147483648", "(-?\\d+)", v))
        assert_true(RE2.FullMatch(zeros + "2147483647", "(-?\\d+)", v))
        assert_eq(v, max)
        assert_true(RE2.FullMatch("-" + zeros + "2147483648", "(-?\\d+)", v))
        assert_eq(v, min)
        assert_false(RE2.FullMatch("-" + zeros + "2147483649", "(-?\\d+)", v))
        assert_true(RE2.FullMatch("0x7fffffff", "(.*)", RE2.CRadix(&v)))
        assert_eq(v, max)
        assert_false(RE2.FullMatch("000x7fffffff", "(.*)", RE2.CRadix(&v)))
    }
    {
        var v: UInt32
        var max: UInt32 = 0xffffffff
        assert_true(RE2.FullMatch("100", "(\\d+)", v))
        assert_eq(v, 100)
        assert_true(RE2.FullMatch("4294967295", "(\\d+)", v))
        assert_eq(v, max)
        assert_false(RE2.FullMatch("4294967296", "(\\d+)", v))
        assert_false(RE2.FullMatch("-1", "(\\d+)", v))
        assert_true(RE2.FullMatch(zeros + "4294967295", "(\\d+)", v))
        assert_eq(v, max)
    }
    {
        var v: Int64
        var max: Int64 = 0x7fffffffffffffff
        var min: Int64 = -max - 1
        var str = String()
        assert_true(RE2.FullMatch("100", "(-?\\d+)", v))
        assert_eq(v, 100)
        assert_true(RE2.FullMatch("-100", "(-?\\d+)", v))
        assert_eq(v, -100)
        str = str(max)
        assert_true(RE2.FullMatch(str, "(-?\\d+)", v))
        assert_eq(v, max)
        str = str(min)
        assert_true(RE2.FullMatch(str, "(-?\\d+)", v))
        assert_eq(v, min)
        str = str(max)
        # ASSERT_NE(str.back(), '9')
        str.back() += 1  # FIXME: this is wrong, should set to next digit
        assert_false(RE2.FullMatch(str, "(-?\\d+)", v))
        str = str(min)
        # ASSERT_NE(str.back(), '9')
        str.back() += 1
        assert_false(RE2.FullMatch(str, "(-?\\d+)", v))
    }
    {
        var v: UInt64
        var v2: Int64
        var max: UInt64 = 0xffffffffffffffff
        var str = String()
        assert_true(RE2.FullMatch("100", "(-?\\d+)", v))
        assert_eq(v, 100)
        assert_true(RE2.FullMatch("-100", "(-?\\d+)", v2))
        assert_eq(v2, -100)
        str = str(max)
        assert_true(RE2.FullMatch(str, "(-?\\d+)", v))
        assert_eq(v, max)
        # ASSERT_NE(str.back(), '9')
        str.back() += 1
        assert_false(RE2.FullMatch(str, "(-?\\d+)", v))
    }

# TEST(RE2, FloatingPointFullMatchTypes)
def test_FloatingPointFullMatchTypes():
    var zeros = ""
    for _ in range(1000):
        zeros += "0"
    {
        var v: Float32
        assert_true(RE2.FullMatch("100", "(.*)", v))
        assert_eq(v, 100.0)
        assert_true(RE2.FullMatch("-100.", "(.*)", v))
        assert_eq(v, -100.0)
        assert_true(RE2.FullMatch("1e23", "(.*)", v))
        assert_eq(v, Float32(1e23))
        assert_true(RE2.FullMatch(" 100", "(.*)", v))
        assert_eq(v, 100.0)
        assert_true(RE2.FullMatch(zeros + "1e23", "(.*)", v))
        assert_eq(v, Float32(1e23))
        #if !defined(_MSC_VER) && !defined(__CYGWIN__) && !defined(__MINGW32__)
        assert_true(RE2.FullMatch("0.1", "(.*)", v))
        assert_eq(v, 0.1)
        assert_true(RE2.FullMatch("6700000000081920.1", "(.*)", v))
        assert_eq(v, 6700000000081920.1)
    }
    {
        var v: Float64
        assert_true(RE2.FullMatch("100", "(.*)", v))
        assert_eq(v, 100.0)
        assert_true(RE2.FullMatch("-100.", "(.*)", v))
        assert_eq(v, -100.0)
        assert_true(RE2.FullMatch("1e23", "(.*)", v))
        assert_eq(v, 1e23)
        assert_true(RE2.FullMatch(zeros + "1e23", "(.*)", v))
        assert_eq(v, Float64(1e23))
        assert_true(RE2.FullMatch("0.1", "(.*)", v))
        assert_eq(v, 0.1)
        assert_true(RE2.FullMatch("1.00000005960464485", "(.*)", v))
        assert_eq(v, 1.0000000596046448)
    }

# TEST(RE2, FullMatchAnchored)
def test_FullMatchAnchored():
    var i: Int32
    assert_false(RE2.FullMatch("x1001", "(\\d+)", i))
    assert_false(RE2.FullMatch("1001x", "(\\d+)", i))
    assert_true(RE2.FullMatch("x1001", "x(\\d+)", i))
    assert_eq(i, 1001)
    assert_true(RE2.FullMatch("1001x", "(\\d+)x", i))
    assert_eq(i, 1001)

# TEST(RE2, FullMatchBraces)
def test_FullMatchBraces():
    assert_true(RE2.FullMatch("0abcd", "[0-9a-f+.-]{5,}"))
    assert_true(RE2.FullMatch("0abcde", "[0-9a-f+.-]{5,}"))
    assert_false(RE2.FullMatch("0abc", "[0-9a-f+.-]{5,}"))

# TEST(RE2, Complicated)
def test_Complicated():
    assert_true(RE2.FullMatch("foo", "foo|bar|[A-Z]"))
    assert_true(RE2.FullMatch("bar", "foo|bar|[A-Z]"))
    assert_true(RE2.FullMatch("X", "foo|bar|[A-Z]"))
    assert_false(RE2.FullMatch("XY", "foo|bar|[A-Z]"))

# TEST(RE2, FullMatchEnd)
def test_FullMatchEnd():
    assert_true(RE2.FullMatch("fo", "fo|foo"))
    assert_true(RE2.FullMatch("foo", "fo|foo"))
    assert_true(RE2.FullMatch("fo", "fo|foo$"))
    assert_true(RE2.FullMatch("foo", "fo|foo$"))
    assert_true(RE2.FullMatch("foo", "foo$"))
    assert_false(RE2.FullMatch("foo$bar", "foo\\$"))
    assert_false(RE2.FullMatch("fox", "fo|bar"))
    if False:
        assert_false(RE2.PartialMatch("foo\n", "foo$"))

# TEST(RE2, FullMatchArgCount)
def test_FullMatchArgCount():
    var a = List[Int32](16)
    # TODO: test body placeholder

# TEST(RE2, Accessors)
def test_Accessors():
    {
        let kPattern = "http://([^/]+)/.*"
        var re = RE2(kPattern)
        assert_eq(kPattern, re.pattern())
    }
    {
        var re = RE2("foo")
        assert_true(re.error().empty())
        assert_true(re.ok())
        assert_eq(re.error_code(), RE2.NoError)
    }

# TEST(RE2, UTF8)
def test_UTF8():
    var utf8_string = String("\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e")
    var utf8_pattern = String(".\xe6\x9c\xac.")
    var re_test1 = RE2(".........", RE2.Latin1)
    assert_true(RE2.FullMatch(utf8_string, re_test1))
    var re_test2 = RE2("...")
    assert_true(RE2.FullMatch(utf8_string, re_test2))
    var s = String()
    var re_test3 = RE2("(.)", RE2.Latin1)
    assert_true(RE2.PartialMatch(utf8_string, re_test3, s))
    assert_eq(s, "\xe6")
    var re_test4 = RE2("(.)")
    assert_true(RE2.PartialMatch(utf8_string, re_test4, s))
    assert_eq(s, "\xe6\x97\xa5")
    var re_test5 = RE2(utf8_string, RE2.Latin1)
    assert_true(RE2.FullMatch(utf8_string, re_test5))
    var re_test6 = RE2(utf8_string)
    assert_true(RE2.FullMatch(utf8_string, re_test6))
    var re_test7 = RE2(utf8_pattern, RE2.Latin1)
    assert_false(RE2.FullMatch(utf8_string, re_test7))
    var re_test8 = RE2(utf8_pattern)
    assert_true(RE2.FullMatch(utf8_string, re_test8))

# TEST(RE2, UngreedyUTF8)
def test_UngreedyUTF8():
    {
        var pattern = "\\w+X"
        var target = "a aX"
        var match_sentence = RE2(pattern, RE2.Latin1)
        var match_sentence_re = RE2(pattern)
        assert_false(RE2.FullMatch(target, match_sentence))
        assert_false(RE2.FullMatch(target, match_sentence_re))
    }
    {
        var pattern = "(?U)\\w+X"
        var target = "a aX"
        var match_sentence = RE2(pattern, RE2.Latin1)
        assert_eq(match_sentence.error(), "")
        var match_sentence_re = RE2(pattern)
        assert_false(RE2.FullMatch(target, match_sentence))
        assert_false(RE2.FullMatch(target, match_sentence_re))
    }

# TEST(RE2, Rejects)
def test_Rejects():
    {
        var re = RE2("a\\1", RE2.Quiet)
        assert_false(re.ok())
    }
    {
        var re = RE2("a[x", RE2.Quiet)
        assert_false(re.ok())
    }
    {
        var re = RE2("a[z-a]", RE2.Quiet)
        assert_false(re.ok())
    }
    {
        var re = RE2("a[[:foobar:]]", RE2.Quiet)
        assert_false(re.ok())
    }
    {
        var re = RE2("a(b", RE2.Quiet)
        assert_false(re.ok())
    }
    {
        var re = RE2("a\\", RE2.Quiet)
        assert_false(re.ok())
    }

# TEST(RE2, NoCrash)
def test_NoCrash():
    {
        var re = RE2("a\\", RE2.Quiet)
        assert_false(re.ok())
        assert_false(RE2.PartialMatch("a\\b", re))
    }
    {
        var re = RE2("(((.{100}){100}){100}){100}", RE2.Quiet)
        assert_false(re.ok())
        assert_false(RE2.PartialMatch("aaa", re))
    }
    {
        var re = RE2(".{512}x", RE2.Quiet)
        assert_true(re.ok())
        var s = String()
        for _ in range(515):
            s += "c"
        s += "x"
        assert_true(RE2.PartialMatch(s, re))
    }

# TEST(RE2, Recursion)
def test_Recursion():
    var bytes: Int32 = 15 * 1024
    TestRecursion(bytes, ".")
    TestRecursion(bytes, "a")
    TestRecursion(bytes, "a.")
    TestRecursion(bytes, "ab.")
    TestRecursion(bytes, "abc.")

# TEST(RE2, BigCountedRepetition)
def test_BigCountedRepetition():
    var opt = RE2.Options()
    opt.set_max_mem(256 << 20)
    var re = RE2(".{512}x", opt)
    assert_true(re.ok())
    var s = String()
    for _ in range(515):
        s += "c"
    s += "x"
    assert_true(RE2.PartialMatch(s, re))

# TEST(RE2, DeepRecursion)
def test_DeepRecursion():
    var comment = "x*"
    var a = ""
    for _ in range(131072):
        a += "a"
    comment += a
    comment += "*x"
    var re = RE2("((?:\\s|xx.*\n|x[*](?:\n|.)*?[*]x)*)")
    assert_true(RE2.FullMatch(comment, re))

# TEST(CaseInsensitive, MatchAndConsume)
def test_CaseInsensitive_MatchAndConsume():
    var text = "A fish named *Wanda*"
    var sp = StringPiece(text)
    var result = StringPiece()
    assert_true(RE2.PartialMatch(text, "(?i)([wand]{5})", result))
    assert_true(RE2.FindAndConsume(sp, "(?i)([wand]{5})", result))

# TEST(RE2, ImplicitConversions)
def test_ImplicitConversions():
    var re_string = String(".")
    var re_stringpiece = StringPiece(".")
    var re_cstring = "."
    assert_true(RE2.PartialMatch("e", re_string))
    assert_true(RE2.PartialMatch("e", re_stringpiece))
    assert_true(RE2.PartialMatch("e", re_cstring))
    assert_true(RE2.PartialMatch("e", "."))

# TEST(RE2, CL8622304)
def test_CL8622304():
    var dir = String()
    assert_true(RE2.FullMatch("D", "([^\\\\])"))
    assert_true(RE2.FullMatch("D", "([^\\\\])", dir))
    var key = String()
    var val = String()
    assert_true(RE2.PartialMatch("bar:1,0x2F,030,4,5;baz:true;fooby:false,true", "(\\w+)(?::((?:[^;\\\\]|\\\\.)*))?;?", key, val))
    assert_eq(key, "bar")
    assert_eq(val, "1,0x2F,030,4,5")

# TEST(RE2, ErrorCodeAndArg)
def test_ErrorCodeAndArg():
    struct ErrorTest:
        var regexp: String
        var error_code: RE2.ErrorCode
        var error_arg: String
    var error_tests = List[ErrorTest]()
    error_tests.append(ErrorTest("ab\\αcd", RE2.ErrorBadEscape, "\\α"))
    error_tests.append(ErrorTest("ef\\x☺01", RE2.ErrorBadEscape, "\\x☺0"))
    error_tests.append(ErrorTest("gh\\x1☺01", RE2.ErrorBadEscape, "\\x1☺"))
    error_tests.append(ErrorTest("ij\\x1", RE2.ErrorBadEscape, "\\x1"))
    error_tests.append(ErrorTest("kl\\x", RE2.ErrorBadEscape, "\\x"))
    error_tests.append(ErrorTest("uv\\x{0000☺}", RE2.ErrorBadEscape, "\\x{0000☺"))
    error_tests.append(ErrorTest("wx\\p{ABC", RE2.ErrorBadCharRange, "\\p{ABC"))
    error_tests.append(ErrorTest("yz(?smiUX:abc)", RE2.ErrorBadPerlOp, "(?smiUX"))
    error_tests.append(ErrorTest("aa(?sm☺i", RE2.ErrorBadPerlOp, "(?sm☺"))
    error_tests.append(ErrorTest("bb[abc", RE2.ErrorMissingBracket, "[abc"))
    error_tests.append(ErrorTest("abc(def", RE2.ErrorMissingParen, "abc(def"))
    error_tests.append(ErrorTest("abc)def", RE2.ErrorUnexpectedParen, "abc)def"))
    error_tests.append(ErrorTest("mn\\x1\377", RE2.ErrorBadUTF8, ""))
    error_tests.append(ErrorTest("op\377qr", RE2.ErrorBadUTF8, ""))
    error_tests.append(ErrorTest("st\\x{00000\377", RE2.ErrorBadUTF8, ""))
    error_tests.append(ErrorTest("zz\\p{\377}", RE2.ErrorBadUTF8, ""))
    error_tests.append(ErrorTest("zz\\x{00\377}", RE2.ErrorBadUTF8, ""))
    error_tests.append(ErrorTest("zz(?P<name\377>abc)", RE2.ErrorBadUTF8, ""))
    for i in range(error_tests.size()):
        var re = RE2(error_tests[i].regexp, RE2.Quiet)
        assert_false(re.ok())
        assert_eq(re.error_code(), error_tests[i].error_code, re.error())
        assert_eq(re.error_arg(), error_tests[i].error_arg, re.error())

# TEST(RE2, NeverNewline)
def test_NeverNewline():
    struct NeverTest:
        var regexp: String
        var text: String
        var match: String
    var never_tests = List[NeverTest]()
    never_tests.append(NeverTest("(.*)", "abc\ndef\nghi\n", "abc"))
    never_tests.append(NeverTest("(?s)(abc.*def)", "abc\ndef\n", ""))
    never_tests.append(NeverTest("(abc(.|\n)*def)", "abc\ndef\n", ""))
    never_tests.append(NeverTest("(abc[^x]*def)", "abc\ndef\n", ""))
    never_tests.append(NeverTest("(abc[^x]*def)", "abczzzdef\ndef\n", "abczzzdef"))
    var opt = RE2.Options()
    opt.set_never_nl(True)
    for i in range(never_tests.size()):
        var t = never_tests[i]
        var re = RE2(t.regexp, opt)
        if t.match == "":
            assert_false(re.PartialMatch(t.text, re))
        else:
            var m = StringPiece()
            assert_true(re.PartialMatch(t.text, re, m))
            assert_eq(m, t.match)

# TEST(RE2, DotNL)
def test_DotNL():
    var opt = RE2.Options()
    opt.set_dot_nl(True)
    assert_true(RE2.PartialMatch("\n", RE2(".", opt)))
    assert_false(RE2.PartialMatch("\n", RE2("(?-s).", opt)))
    opt.set_never_nl(True)
    assert_false(RE2.PartialMatch("\n", RE2(".", opt)))

# TEST(RE2, NeverCapture)
def test_NeverCapture():
    var opt = RE2.Options()
    opt.set_never_capture(True)
    var re = RE2("(r)(e)", opt)
    assert_eq(0, re.NumberOfCapturingGroups())

# TEST(RE2, BitstateCaptureBug)
def test_BitstateCaptureBug():
    var opt = RE2.Options()
    opt.set_max_mem(20000)
    var re = RE2("(_________$)", opt)
    var s = StringPiece("xxxxxxxxxxxxxxxxxxxxxxxxxx_________x")
    assert_false(re.Match(s, 0, s.size(), RE2.UNANCHORED, NULL, 0))

# TEST(RE2, UnicodeClasses)
def test_UnicodeClasses():
    let str = "ABCDEFGHI譚永鋒"
    var a = String()
    var b = String()
    var c = String()
    assert_true(RE2.FullMatch("A", "\\p{L}"))
    assert_true(RE2.FullMatch("A", "\\p{Lu}"))
    assert_false(RE2.FullMatch("A", "\\p{Ll}"))
    assert_false(RE2.FullMatch("A", "\\P{L}"))
    assert_false(RE2.FullMatch("A", "\\P{Lu}"))
    assert_true(RE2.FullMatch("A", "\\P{Ll}"))
    assert_true(RE2.FullMatch("譚", "\\p{L}"))
    assert_false(RE2.FullMatch("譚", "\\p{Lu}"))
    assert_false(RE2.FullMatch("譚", "\\p{Ll}"))
    assert_false(RE2.FullMatch("譚", "\\P{L}"))
    assert_true(RE2.FullMatch("譚", "\\P{Lu}"))
    assert_true(RE2.FullMatch("譚", "\\P{Ll}"))
    assert_true(RE2.FullMatch("永", "\\p{L}"))
    assert_false(RE2.FullMatch("永", "\\p{Lu}"))
    assert_false(RE2.FullMatch("永", "\\p{Ll}"))
    assert_false(RE2.FullMatch("永", "\\P{L}"))
    assert_true(RE2.FullMatch("永", "\\P{Lu}"))
    assert_true(RE2.FullMatch("永", "\\P{Ll}"))
    assert_true(RE2.FullMatch("鋒", "\\p{L}"))
    assert_false(RE2.FullMatch("鋒", "\\p{Lu}"))
    assert_false(RE2.FullMatch("鋒", "\\p{Ll}"))
    assert_false(RE2.FullMatch("鋒", "\\P{L}"))
    assert_true(RE2.FullMatch("鋒", "\\P{Lu}"))
    assert_true(RE2.FullMatch("鋒", "\\P{Ll}"))
    assert_true(RE2.PartialMatch(str, "(.).*?(.).*?(.)", a, b, c))
    assert_eq("A", a)
    assert_eq("B", b)
    assert_eq("C", c)
    assert_true(RE2.PartialMatch(str, "(.).*?([\\p{L}]).*?(.)", a, b, c))
    assert_eq("A", a)
    assert_eq("B", b)
    assert_eq("C", c)
    assert_false(RE2.PartialMatch(str, "\\P{L}"))
    assert_true(RE2.PartialMatch(str, "(.).*?([\\p{Lu}]).*?(.)", a, b, c))
    assert_eq("A", a)
    assert_eq("B", b)
    assert_eq("C", c)
    assert_false(RE2.PartialMatch(str, "[^\\p{Lu}\\p{Lo}]"))
    assert_true(RE2.PartialMatch(str, ".*(.).*?([\\p{Lu}\\p{Lo}]).*?(.)", a, b, c))
    assert_eq("譚", a)
    assert_eq("永", b)
    assert_eq("鋒", c)

# TEST(RE2, LazyRE2)
def test_LazyRE2():
    # Static LazyRE2 not directly portable; use regular constructor

# TEST(RE2, NullVsEmptyString)
def test_NullVsEmptyString():
    var re = RE2(".*")
    assert_true(re.ok())
    var null_sp = StringPiece()
    assert_true(RE2.FullMatch(null_sp, re))
    var empty_sp = StringPiece("")
    assert_true(RE2.FullMatch(empty_sp, re))

# TEST(RE2, NullVsEmptyStringSubmatches)
def test_NullVsEmptyStringSubmatches():
    var re = RE2("()|(foo)")
    assert_true(re.ok())
    var matches = List[StringPiece](4)
    for i in range(matches.size()):
        matches[i].set("bar")
    var null_sp = StringPiece()
    assert_true(re.Match(null_sp, 0, null_sp.size(), RE2.UNANCHORED, matches.pointer(), matches.size()))
    for i in range(matches.size()):
        assert_true(matches[i].data() == NULL)
        assert_true(matches[i].empty())
    for i in range(matches.size()):
        matches[i].set("bar")
    var empty_sp = StringPiece("")
    assert_true(re.Match(empty_sp, 0, empty_sp.size(), RE2.UNANCHORED, matches.pointer(), matches.size()))
    assert_true(matches[0].data() != NULL)
    assert_true(matches[0].empty())
    assert_true(matches[1].data() != NULL)
    assert_true(matches[1].empty())
    assert_true(matches[2].data() == NULL)
    assert_true(matches[2].empty())
    assert_true(matches[3].data() == NULL)
    assert_true(matches[3].empty())

# TEST(RE2, Bug1816809)
def test_Bug1816809():
    var re = RE2("(((((llx((-3)|(4)))(;(llx((-3)|(4))))*))))")
    var piece = StringPiece("llx-3;llx4")
    var x = String()
    assert_true(RE2.Consume(piece, re, x))

# TEST(RE2, Bug3061120)
def test_Bug3061120():
    var re = RE2("(?i)\\W")
    assert_false(RE2.PartialMatch("x", re))
    assert_false(RE2.PartialMatch("k", re))
    assert_false(RE2.PartialMatch("s", re))

# TEST(RE2, CapturingGroupNames)
def test_CapturingGroupNames():
    var re = RE2("((abc)(?P<G2>)|((e+)(?P<G2>.*)(?P<G1>u+)))")
    assert_true(re.ok())
    let have = re.CapturingGroupNames()
    var want = Map[Int32, String]()
    want[3] = "G2"
    want[6] = "G2"
    want[7] = "G1"
    assert_eq(want, have)

# TEST(RE2, RegexpToStringLossOfAnchor)
def test_RegexpToStringLossOfAnchor():
    assert_eq(RE2("^[a-c]at", RE2.POSIX).Regexp().ToString(), "^[a-c]at")
    assert_eq(RE2("^[a-c]at").Regexp().ToString(), "(?-m:^)[a-c]at")
    assert_eq(RE2("ca[t-z]$", RE2.POSIX).Regexp().ToString(), "ca[t-z]$")
    assert_eq(RE2("ca[t-z]$").Regexp().ToString(), "ca[t-z](?-m:$)")

# TEST(RE2, Bug10131674)
def test_Bug10131674():
    var re = RE2("\\140\\440\\174\\271\\150\\656\\106\\201\\004\\332", RE2.Latin1)
    assert_false(re.ok())
    assert_false(RE2.FullMatch("hello world", re))

# TEST(RE2, Bug18391750)
def test_Bug18391750():
    var t = String()
    t += chr(0x28)
    t += chr(0x28)
    t += chr(0xfc)
    t += chr(0xfc)
    t += chr(0x08)
    t += chr(0x08)
    t += chr(0x26)
    t += chr(0x26)
    t += chr(0x28)
    t += chr(0xc2)
    t += chr(0x9b)
    t += chr(0xc5)
    t += chr(0xc5)
    t += chr(0xd4)
    t += chr(0x8f)
    t += chr(0x8f)
    t += chr(0x69)
    t += chr(0x69)
    t += chr(0xe7)
    t += chr(0x29)
    t += chr(0x7b)
    t += chr(0x37)
    t += chr(0x31)
    t += chr(0x31)
    t += chr(0x7d)
    t += chr(0xae)
    t += chr(0x7c)
    t += chr(0x7c)
    t += chr(0xf3)
    t += chr(0x29)
    t += chr(0xae)
    t += chr(0xae)
    t += chr(0x2e)
    t += chr(0x2a)
    t += chr(0x29)
    t += chr(0x00)
    var opt = RE2.Options()
    opt.set_encoding(RE2.Options.EncodingLatin1)
    opt.set_longest_match(True)
    opt.set_dot_nl(True)
    opt.set_case_sensitive(False)
    var re = RE2(t, opt)
    assert_true(re.ok())
    RE2.PartialMatch(t, re)

# TEST(RE2, Bug18458852)
def test_Bug18458852():
    var b = String()
    b += chr(0x28)
    b += chr(0x05)
    b += chr(0x05)
    b += chr(0x41)
    b += chr(0x41)
    b += chr(0x28)
    b += chr(0x24)
    b += chr(0x5b)
    b += chr(0x5e)
    b += chr(0xf5)
    b += chr(0x87)
    b += chr(0x87)
    b += chr(0x90)
    b += chr(0x29)
    b += chr(0x5d)
    b += chr(0x29)
    b += chr(0x29)
    b += chr(0x00)
    var re = RE2(b)
    assert_false(re.ok())

# TEST(RE2, Bug18523943)
def test_Bug18523943():
    var opt = RE2.Options()
    var a = String()
    a += chr(0x29)
    a += chr(0x29)
    a += chr(0x24)
    a += chr(0x00)
    var b = String()
    b += chr(0x28)
    b += chr(0x0a)
    b += chr(0x2a)
    b += chr(0x2a)
    b += chr(0x29)
    b += chr(0x00)
    opt.set_log_errors(False)
    opt.set_encoding(RE2.Options.EncodingLatin1)
    opt.set_posix_syntax(True)
    opt.set_longest_match(True)
    opt.set_literal(False)
    opt.set_never_nl(True)
    var re = RE2(b, opt)
    assert_true(re.ok())
    var s1 = String()
    assert_true(RE2.PartialMatch(a, re, s1))

# TEST(RE2, Bug21371806)
def test_Bug21371806():
    var opt = RE2.Options()
    opt.set_encoding(RE2.Options.EncodingLatin1)
    var re = RE2("g\\p{Zl}]", opt)
    assert_true(re.ok())

# TEST(RE2, Bug26356109)
def test_Bug26356109():
    var re = RE2("a\\C*?c|a\\C*?b")
    assert_true(re.ok())
    var s = "abc"
    var m = StringPiece()
    assert_true(re.Match(s, 0, len(s), RE2.UNANCHORED, m, 1))
    assert_eq(m, s, " (UNANCHORED) got m='" + str(m) + "', want '" + s + "'")
    assert_true(re.Match(s, 0, len(s), RE2.ANCHOR_BOTH, m, 1))
    assert_eq(m, s, " (ANCHOR_BOTH) got m='" + str(m) + "', want '" + s + "'")

# TEST(RE2, Issue104)
def test_Issue104():
    var s = "bc"
    assert_eq(3, RE2.GlobalReplace(s, "a*", "d"))
    assert_eq("dbdcd", s)
    s = "ąć"
    assert_eq(3, RE2.GlobalReplace(s, "Ć*", "Ĉ"))
    assert_eq("ĈąĈćĈ", s)
    s = "人类"
    assert_eq(3, RE2.GlobalReplace(s, "大*", "小"))
    assert_eq("小人小类小", s)

# TEST(RE2, Issue310)
def test_Issue310():
    var s = "aaa"
    var m = StringPiece()
    var star = RE2("(?:|a)*")
    assert_true(star.Match(s, 0, len(s), RE2.UNANCHORED, m, 1))
    assert_eq(m, StringPiece(""), " got m='" + str(m) + "', want ''")
    var plus = RE2("(?:|a)+")
    assert_true(plus.Match(s, 0, len(s), RE2.UNANCHORED, m, 1))
    assert_eq(m, StringPiece(""), " got m='" + str(m) + "', want ''")