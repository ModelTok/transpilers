from util.test import Test, ASSERT_TRUE, EXPECT_EQ
from util.logging import LOG
from ..regexp import Regexp, RegexpStatus, RegexpParseFlags
import String

# Translate C++ namespace re2 { ... } to module-level code
# Keep all names exactly as in source

struct Test:
    var regexp: String
    var parse: String
    var flags: Regexp.ParseFlags

# Helper to compute arraysize (number of elements)
def arraysize[T](arr: List[T]) -> Int:
    return len(arr)

# Define a copy of TestZeroFlags and kTestFlags as per C++
alias TestZeroFlags = Regexp.WasDollar
alias kTestFlags = Regexp.MatchNL | Regexp.PerilX | Regexp.PerlClasses | Regexp.UnicodeGroups

var tests: List[Test] = List[Test](
    Test("a", "lit{a}", 0),
    Test("a.", "cat{lit{a}dot{}}", 0),
    Test("a.b", "cat{lit{a}dot{}lit{b}}", 0),
    Test("ab", "str{ab}", 0),
    Test("a.b.c", "cat{lit{a}dot{}lit{b}dot{}lit{c}}", 0),
    Test("abc", "str{abc}", 0),
    Test("a|^", "alt{lit{a}bol{}}", 0),
    Test("a|b", "cc{0x61-0x62}", 0),
    Test("(a)", "cap{lit{a}}", 0),
    Test("(a)|b", "alt{cap{lit{a}}lit{b}}", 0),
    Test("a*", "star{lit{a}}", 0),
    Test("a+", "plus{lit{a}}", 0),
    Test("a?", "que{lit{a}}", 0),
    Test("a{2}", "rep{2,2 lit{a}}", 0),
    Test("a{2,3}", "rep{2,3 lit{a}}", 0),
    Test("a{2,}", "rep{2,-1 lit{a}}", 0),
    Test("a*?", "nstar{lit{a}}", 0),
    Test("a+?", "nplus{lit{a}}", 0),
    Test("a??", "nque{lit{a}}", 0),
    Test("a{2}?", "nrep{2,2 lit{a}}", 0),
    Test("a{2,3}?", "nrep{2,3 lit{a}}", 0),
    Test("a{2,}?", "nrep{2,-1 lit{a}}", 0),
    Test("", "emp{}", 0),
    Test("|", "alt{emp{}emp{}}", 0),
    Test("|x|", "alt{emp{}lit{x}emp{}}", 0),
    Test(".", "dot{}", 0),
    Test("^", "bol{}", 0),
    Test("$", "eol{}", 0),
    Test("\\|", "lit{|}", 0),
    Test("\\(", "lit{(}", 0),
    Test("\\)", "lit{)}", 0),
    Test("\\*", "lit{*}", 0),
    Test("\\+", "lit{+}", 0),
    Test("\\?", "lit{?}", 0),
    Test("{", "lit{{}", 0),
    Test("}", "lit{}}", 0),
    Test("\\.", "lit{.}", 0),
    Test("\\^", "lit{^}", 0),
    Test("\\$", "lit{$}", 0),
    Test("\\\\", "lit{\\}", 0),
    Test("[ace]", "cc{0x61 0x63 0x65}", 0),
    Test("[abc]", "cc{0x61-0x63}", 0),
    Test("[a-z]", "cc{0x61-0x7a}", 0),
    Test("[a]", "lit{a}", 0),
    Test("\\-", "lit{-}", 0),
    Test("-", "lit{-}", 0),
    Test("\\_", "lit{_}", 0),
    Test("[[:lower:]]", "cc{0x61-0x7a}", 0),
    Test("[a-z]", "cc{0x61-0x7a}", 0),
    Test("[^[:lower:]]", "cc{0-0x60 0x7b-0x10ffff}", 0),
    Test("[[:^lower:]]", "cc{0-0x60 0x7b-0x10ffff}", 0),
    Test("(?i)[[:lower:]]", "cc{0x41-0x5a 0x61-0x7a 0x17f 0x212a}", 0),
    Test("(?i)[a-z]", "cc{0x41-0x5a 0x61-0x7a 0x17f 0x212a}", 0),
    Test("(?i)[^[:lower:]]", "cc{0-0x40 0x5b-0x60 0x7b-0x17e 0x180-0x2129 0x212b-0x10ffff}", 0),
    Test("(?i)[[:^lower:]]", "cc{0-0x40 0x5b-0x60 0x7b-0x17e 0x180-0x2129 0x212b-0x10ffff}", 0),
    Test("\\d", "cc{0x30-0x39}", 0),
    Test("\\D", "cc{0-0x2f 0x3a-0x10ffff}", 0),
    Test("\\s", "cc{0x9-0xa 0xc-0xd 0x20}", 0),
    Test("\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}", 0),
    Test("\\w", "cc{0x30-0x39 0x41-0x5a 0x5f 0x61-0x7a}", 0),
    Test("\\W", "cc{0-0x2f 0x3a-0x40 0x5b-0x5e 0x60 0x7b-0x10ffff}", 0),
    Test("(?i)\\w", "cc{0x30-0x39 0x41-0x5a 0x5f 0x61-0x7a 0x17f 0x212a}", 0),
    Test("(?i)\\W", "cc{0-0x2f 0x3a-0x40 0x5b-0x5e 0x60 0x7b-0x17e 0x180-0x2129 0x212b-0x10ffff}", 0),
    Test("[^\\\\]", "cc{0-0x5b 0x5d-0x10ffff}", 0),
    Test("\\C", "byte{}", 0),
    Test("\\p{Braille}", "cc{0x2800-0x28ff}", 0),
    Test("\\P{Braille}", "cc{0-0x27ff 0x2900-0x10ffff}", 0),
    Test("\\p{^Braille}", "cc{0-0x27ff 0x2900-0x10ffff}", 0),
    Test("\\P{^Braille}", "cc{0x2800-0x28ff}", 0),
    Test("a{,2}", "str{a{,2}}", 0),
    Test("\\.\\^\\$\\\\", "str{.^$\\}", 0),
    Test("[a-zABC]", "cc{0x41-0x43 0x61-0x7a}", 0),
    Test("[^a]", "cc{0-0x60 0x62-0x10ffff}", 0),
    Test("[\xce\xb1-\xce\xb5\xe2\x98\xba]", "cc{0x3b1-0x3b5 0x263a}", 0),  // utf-8
    Test("a*{", "cat{star{lit{a}}lit{{}}", 0),
    Test("(?:ab)*", "star{str{ab}}", 0),
    Test("(ab)*", "star{cap{str{ab}}}", 0),
    Test("ab|cd", "alt{str{ab}str{cd}}", 0),
    Test("a(b|c)d", "cat{lit{a}cap{cc{0x62-0x63}}lit{d}}", 0),
    Test("(?:(?:a)*)*", "star{lit{a}}", 0),
    Test("(?:(?:a)+)+", "plus{lit{a}}", 0),
    Test("(?:(?:a)?)?", "que{lit{a}}", 0),
    Test("(?:(?:a)*)+", "star{lit{a}}", 0),
    Test("(?:(?:a)*)?", "star{lit{a}}", 0),
    Test("(?:(?:a)+)*", "star{lit{a}}", 0),
    Test("(?:(?:a)+)?", "star{lit{a}}", 0),
    Test("(?:(?:a)?)*", "star{lit{a}}", 0),
    Test("(?:(?:a)?)+", "star{lit{a}}", 0),
    Test("(?:a)", "lit{a}", 0),
    Test("(?:ab)(?:cd)", "str{abcd}", 0),
    Test("(?:a|b)|(?:c|d)", "cc{0x61-0x64}", 0),
    Test("a|c", "cc{0x61 0x63}", 0),
    Test("a|[cd]", "cc{0x61 0x63-0x64}", 0),
    Test("a|.", "dot{}", 0),
    Test("[ab]|c", "cc{0x61-0x63}", 0),
    Test("[ab]|[cd]", "cc{0x61-0x64}", 0),
    Test("[ab]|.", "dot{}", 0),
    Test(".|c", "dot{}", 0),
    Test(".|[cd]", "dot{}", 0),
    Test(".|.", "dot{}", 0),
    Test("\\Q+|*?{[\\E", "str{+|*?{[}", 0),
    Test("\\Q+\\E+", "plus{lit{+}}", 0),
    Test("\\Q\\\\E", "lit{\\}", 0),
    Test("\\Q\\\\\\E", "str{\\\\}", 0),
    Test("\\Qa\\E*", "star{lit{a}}", 0),
    Test("\\Qab\\E*", "cat{lit{a}star{lit{b}}}", 0),
    Test("\\Qabc\\E*", "cat{str{ab}star{lit{c}}}", 0),
    Test("(?m)^", "bol{}", 0),
    Test("(?m)$", "eol{}", 0),
    Test("(?-m)^", "bot{}", 0),
    Test("(?-m)$", "eot{}", 0),
    Test("(?m)\\A", "bot{}", 0),
    Test("(?m)\\z", "eot{\\z}", 0),
    Test("(?-m)\\A", "bot{}", 0),
    Test("(?-m)\\z", "eot{\\z}", 0),
    Test("(?P<name>a)", "cap{name:lit{a}}", 0),
    Test("(?P<中文>a)", "cap{中文:lit{a}}", 0),
    Test("[Aa]", "litfold{a}", 0),
    Test("abcde", "str{abcde}", 0),
    Test("[Aa][Bb]cd", "cat{strfold{ab}str{cd}}", 0),
    Test("[^ ]", "cc{0-0x9 0xb-0x1f 0x21-0x10ffff}", TestZeroFlags),
    Test("[^ ]", "cc{0-0x9 0xb-0x1f 0x21-0x10ffff}", Regexp.FoldCase),
    Test("[^ ]", "cc{0-0x9 0xb-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ ]", "cc{0-0x9 0xb-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^ \f]", "cc{0-0x9 0xb 0xd-0x1f 0x21-0x10ffff}", TestZeroFlags),
    Test("[^ \f]", "cc{0-0x9 0xb 0xd-0x1f 0x21-0x10ffff}", Regexp.FoldCase),
    Test("[^ \f]", "cc{0-0x9 0xb 0xd-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ \f]", "cc{0-0x9 0xb 0xd-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^ \r]", "cc{0-0x9 0xb-0xc 0xe-0x1f 0x21-0x10ffff}", TestZeroFlags),
    Test("[^ \r]", "cc{0-0x9 0xb-0xc 0xe-0x1f 0x21-0x10ffff}", Regexp.FoldCase),
    Test("[^ \r]", "cc{0-0x9 0xb-0xc 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ \r]", "cc{0-0x9 0xb-0xc 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^ \v]", "cc{0-0x9 0xc-0x1f 0x21-0x10ffff}", TestZeroFlags),
    Test("[^ \v]", "cc{0-0x9 0xc-0x1f 0x21-0x10ffff}", Regexp.FoldCase),
    Test("[^ \v]", "cc{0-0x9 0xc-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ \v]", "cc{0-0x9 0xc-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^ \t]", "cc{0-0x8 0xb-0x1f 0x21-0x10ffff}", TestZeroFlags),
    Test("[^ \t]", "cc{0-0x8 0xb-0x1f 0x21-0x10ffff}", Regexp.FoldCase),
    Test("[^ \t]", "cc{0-0x8 0xb-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ \t]", "cc{0-0x8 0xb-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^ \r\f\v]", "cc{0-0x9 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ \r\f\v]", "cc{0-0x9 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^ \r\f\t\v]", "cc{0-0x8 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ \r\f\t\v]", "cc{0-0x8 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^ \r\n\f\t\v]", "cc{0-0x8 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ \r\n\f\t\v]", "cc{0-0x8 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^ \r\n\f\t]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL),
    Test("[^ \r\n\f\t]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}", Regexp.NeverNL | Regexp.FoldCase),
    Test("[^\t-\n\f-\r ]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
        Regexp.PerlClasses),
    Test("[^\t-\n\f-\r ]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
        Regexp.PerlClasses | Regexp.FoldCase),
    Test("[^\t-\n\f-\r ]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
        Regexp.PerlClasses | Regexp.NeverNL),
    Test("[^\t-\n\f-\r ]", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
        Regexp.PerlClasses | Regexp.NeverNL | Regexp.FoldCase),
    Test("\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
        Regexp.PerlClasses),
    Test("\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
        Regexp.PerlClasses | Regexp.FoldCase),
    Test("\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
        Regexp.PerlClasses | Regexp.NeverNL),
    Test("\\S", "cc{0-0x8 0xb 0xe-0x1f 0x21-0x10ffff}",
        Regexp.PerlClasses | Regexp.NeverNL | Regexp.FoldCase),
    Test("[\\s\\S]", "cc{0-0x10ffff}", 0)
)

# Equivalent of RegexpEqualTestingOnly
def RegexpEqualTestingOnly(a: Regexp, b: Regexp) -> Bool:
    return Regexp.Equal(a, b)

# TestParse function
def TestParse(tests: List[Test], ntests: Int, flags: Regexp.ParseFlags, title: String):
    var re: List[Regexp] = List[Regexp](capacity=ntests)
    for i in range(ntests):
        var status: RegexpStatus = RegexpStatus()
        var f: Regexp.ParseFlags = flags
        if tests[i].flags != 0:
            f = tests[i].flags & ~TestZeroFlags
        re[i] = Regexp.Parse(tests[i].regexp, f, &status)
        ASSERT_TRUE(re[i] != None) << " " << tests[i].regexp << " " << status.Text()
        var s: String = re[i].Dump()
        EXPECT_EQ(String(tests[i].parse), s) \
            << "Regexp: " << tests[i].regexp \
            << "\nparse: " << String(tests[i].parse) \
            << " s: " << s << " flag=" << f
    for i in range(ntests):
        for j in range(ntests):
            EXPECT_EQ(String(tests[i].parse) == String(tests[j].parse),
                      RegexpEqualTestingOnly(re[i], re[j]))
                << "Regexp: " << tests[i].regexp << " " << tests[j].regexp
    for i in range(ntests):
        re[i].Decref()

# TEST(TestParse, SimpleRegexps)
@test
def TestParse_SimpleRegexps():
    TestParse(tests, arraysize(tests), kTestFlags, "simple")

# foldcase_tests array
var foldcase_tests: List[Test] = List[Test](
    Test("AbCdE", "strfold{abcde}", 0),
    Test("[Aa]", "litfold{a}", 0),
    Test("a", "litfold{a}", 0),
    Test("A[F-g]", "cat{litfold{a}cc{0x41-0x7a 0x17f 0x212a}}", 0),  // [Aa][A-z...]
    Test("[[:upper:]]", "cc{0x41-0x5a 0x61-0x7a 0x17f 0x212a}", 0),
    Test("[[:lower:]]", "cc{0x41-0x5a 0x61-0x7a 0x17f 0x212a}", 0)
)

@test
def TestParse_FoldCase():
    TestParse(foldcase_tests, arraysize(foldcase_tests), Regexp.FoldCase, "foldcase")

# literal_tests
var literal_tests: List[Test] = List[Test](
    Test("(|)^$.[*+?]{5,10},\\", "str{(|)^$.[*+?]{5,10},\\}", 0)
)

@test
def TestParse_Literal():
    TestParse(literal_tests, arraysize(literal_tests), Regexp.Literal, "literal")

# matchnl_tests
var matchnl_tests: List[Test] = List[Test](
    Test(".", "dot{}", 0),
    Test("\n", "lit{\n}", 0),
    Test("[^a]", "cc{0-0x60 0x62-0x10ffff}", 0),
    Test("[a\\n]", "cc{0xa 0x61}", 0)
)

@test
def TestParse_MatchNL():
    TestParse(matchnl_tests, arraysize(matchnl_tests), Regexp.MatchNL, "with MatchNL")

# nomatchnl_tests
var nomatchnl_tests: List[Test] = List[Test](
    Test(".", "cc{0-0x9 0xb-0x10ffff}", 0),
    Test("\n", "lit{\n}", 0),
    Test("[^a]", "cc{0-0x9 0xb-0x60 0x62-0x10ffff}", 0),
    Test("[a\\n]", "cc{0xa 0x61}", 0)
)

@test
def TestParse_NoMatchNL():
    TestParse(nomatchnl_tests, arraysize(nomatchnl_tests), Regexp.NoParseFlags, "without MatchNL")

# prefix_tests
var prefix_tests: List[Test] = List[Test](
    Test("abc|abd", "cat{str{ab}cc{0x63-0x64}}", 0),
    Test("a(?:b)c|abd", "cat{str{ab}cc{0x63-0x64}}", 0),
    Test("abc|abd|aef|bcx|bcy",
        "alt{cat{lit{a}alt{cat{lit{b}cc{0x63-0x64}}str{ef}}}"
        "cat{str{bc}cc{0x78-0x79}}}", 0),
    Test("abc|x|abd", "alt{str{abc}lit{x}str{abd}}", 0),
    Test("(?i)abc|ABD", "cat{strfold{ab}cc{0x43-0x44 0x63-0x64}}", 0),
    Test("[ab]c|[ab]d", "cat{cc{0x61-0x62}cc{0x63-0x64}}", 0),
    Test(".c|.d", "cat{cc{0-0x9 0xb-0x10ffff}cc{0x63-0x64}}", 0),
    Test("\\Cc|\\Cd", "cat{byte{}cc{0x63-0x64}}", 0),
    Test("x{2}|x{2}[0-9]",
        "cat{rep{2,2 lit{x}}alt{emp{}cc{0x30-0x39}}}", 0),
    Test("x{2}y|x{2}[0-9]y",
        "cat{rep{2,2 lit{x}}alt{lit{y}cat{cc{0x30-0x39}lit{y}}}}", 0),
    Test("n|r|rs",
        "alt{lit{n}cat{lit{r}alt{emp{}lit{s}}}}", 0),
    Test("n|rs|r",
        "alt{lit{n}cat{lit{r}alt{lit{s}emp{}}}}", 0),
    Test("r|rs|n",
        "alt{cat{lit{r}alt{emp{}lit{s}}}lit{n}}", 0),
    Test("rs|r|n",
        "alt{cat{lit{r}alt{lit{s}emp{}}}lit{n}}", 0),
    Test("a\\C*?c|a\\C*?b",
        "cat{lit{a}alt{cat{nstar{byte{}}lit{c}}cat{nstar{byte{}}lit{b}}}}", 0),
    Test("^/a/bc|^/a/de",
        "cat{bol{}cat{str{/a/}alt{str{bc}str{de}}}}", 0),
    Test("a|aa|aaa|aaaa|aaaaa|aaaaaa|aaaaaaa|aaaaaaaa|aaaaaaaaa|aaaaaaaaaa",
        "cat{lit{a}alt{emp{}" "cat{lit{a}alt{emp{}" "cat{lit{a}alt{emp{}"
        "cat{lit{a}alt{emp{}" "cat{lit{a}alt{emp{}" "cat{lit{a}alt{emp{}"
        "cat{lit{a}alt{emp{}" "cat{lit{a}alt{emp{}" "cat{lit{a}alt{emp{}"
        "lit{a}}}}}}}}}}}}}}}}}}}" , 0),
    Test("a|aardvark|aardvarks|abaci|aback|abacus|abacuses|abaft|abalone|abalones",
        "cat{lit{a}alt{emp{}cat{str{ardvark}alt{emp{}lit{s}}}"
        "cat{str{ba}alt{cat{lit{c}alt{cc{0x69 0x6b}cat{str{us}alt{emp{}str{es}}}}}"
        "str{ft}cat{str{lone}alt{emp{}lit{s}}}}}}}" , 0)
)

@test
def TestParse_Prefix():
    TestParse(prefix_tests, arraysize(prefix_tests), Regexp.PerlX, "prefix")

# nested_tests
var nested_tests: List[Test] = List[Test](
    Test("((((((((((x{2}){2}){2}){2}){2}){2}){2}){2}){2}))",
        "cap{cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 lit{x}}}}}}}}}}}}}}}}}}}}", 0),
    Test("((((((((((x{1}){2}){2}){2}){2}){2}){2}){2}){2}){2})",
        "cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{1,1 lit{x}}}}}}}}}}}}}}}}}}}}}" , 0),
    Test("((((((((((x{0}){2}){2}){2}){2}){2}){2}){2}){2}){2})",
        "cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 cap{rep{0,0 lit{x}}}}}}}}}}}}}}}}}}}}}" , 0),
    Test("((((((x{2}){2}){2}){5}){5}){5})",
        "cap{rep{5,5 cap{rep{5,5 cap{rep{5,5 cap{rep{2,2 cap{rep{2,2 cap{rep{2,2 lit{x}}}}}}}}}}}}}" , 0)
)

@test
def TestParse_Nested():
    TestParse(nested_tests, arraysize(nested_tests), Regexp.PerlX, "nested")

# badtests, only_perl, only_posix arrays
var badtests: List[String] = List[String](
    "(",
    ")",
    "(a",
    "(a|b|",
    "(a|b",
    "[a-z",
    "([a-z)",
    "x{1001}",
    "\xff",      // Invalid UTF-8
    "[\xff]",
    "[\\\xff]",
    "\\\xff",
    "(?P<name>a",
    "(?P<name>",
    "(?P<name",
    "(?P<x y>a)",
    "(?P<>a)",
    "[a-Z]",
    "(?i)[a-Z]",
    "a{100000}",
    "a{100000,}",
    "((((((((((x{2}){2}){2}){2}){2}){2}){2}){2}){2}){2})",
    "(((x{7}){11}){13})",
    "\\Q\\E*"
)

var only_perl: List[String] = List[String](
    "[a-b-c]",
    "\\Qabc\\E",
    "\\Q*+?{[\\E",
    "\\Q\\\\E",
    "\\Q\\\\\\E",
    "\\Q\\\\\\\\E",
    "\\Q\\\\\\\\\\E",
    "(?:a)",
    "(?P<name>a)"
)

var only_posix: List[String] = List[String](
    "a++",
    "a**",
    "a?*",
    "a+*",
    "a{1}*"
)

@test
def TestParse_InvalidRegexps():
    for i in range(arraysize(badtests)):
        ASSERT_TRUE(Regexp.Parse(badtests[i], Regexp.PerlX, None) == None) \
            << " " << badtests[i]
        ASSERT_TRUE(Regexp.Parse(badtests[i], Regexp.NoParseFlags, None) == None) \
            << " " << badtests[i]
    for i in range(arraysize(only_posix)):
        ASSERT_TRUE(Regexp.Parse(only_posix[i], Regexp.PerlX, None) == None) \
            << " " << only_posix[i]
        var re: Regexp = Regexp.Parse(only_posix[i], Regexp.NoParseFlags, None)
        ASSERT_TRUE(re != None) << " " << only_posix[i]
        re.Decref()
    for i in range(arraysize(only_perl)):
        ASSERT_TRUE(Regexp.Parse(only_perl[i], Regexp.NoParseFlags, None) == None) \
            << " " << only_perl[i]
        var re: Regexp = Regexp.Parse(only_perl[i], Regexp.PerlX, None)
        ASSERT_TRUE(re != None) << " " << only_perl[i]
        re.Decref()

@test
def TestToString_EquivalentParse():
    for i in range(arraysize(tests)):
        var status: RegexpStatus = RegexpStatus()
        var f: Regexp.ParseFlags = kTestFlags
        if tests[i].flags != 0:
            f = tests[i].flags & ~TestZeroFlags
        var re: Regexp = Regexp.Parse(tests[i].regexp, f, &status)
        ASSERT_TRUE(re != None) << " " << tests[i].regexp << " " << status.Text()
        var s: String = re.Dump()
        EXPECT_EQ(String(tests[i].parse), s) \
            << "Regexp: " << tests[i].regexp \
            << "\nparse: " << String(tests[i].parse) \
            << " s: " << s << " flag=" << f
        var t: String = re.ToString()
        if t != tests[i].regexp:
            var nre: Regexp = Regexp.Parse(t, Regexp.MatchNL | Regexp.PerlX, &status)
            ASSERT_TRUE(nre != None) << " reparse " << t << " " << status.Text()
            var ss: String = nre.Dump()
            var tt: String = nre.ToString()
            if s != ss or t != tt:
                LOG(INFO) << "ToString(" << tests[i].regexp << ") = " << t
            EXPECT_EQ(s, ss)
            EXPECT_EQ(t, tt)
            nre.Decref()
        re.Decref()

@test
def NamedCaptures_ErrorArgs():
    var status: RegexpStatus = RegexpStatus()
    var re: Regexp
    re = Regexp.Parse("test(?P<name", Regexp.LikePerl, &status)
    EXPECT_TRUE(re == None)
    EXPECT_EQ(status.code(), kRegexpBadNamedCapture)
    EXPECT_EQ(status.error_arg(), "(?P<name")
    re = Regexp.Parse("test(?P<space bar>z)", Regexp.LikePerl, &status)
    EXPECT_TRUE(re == None)
    EXPECT_EQ(status.code(), kRegexpBadNamedCapture)
    EXPECT_EQ(status.error_arg(), "(?P<space bar>")