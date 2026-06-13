from util.test import TEST, ASSERT_TRUE, ASSERT_EQ, ASSERT_FALSE, EXPECT_TRUE, EXPECT_EQ
from util.logging import arraysize
from ..prog import Prog
from ..regexp import Regexp

struct PrefixTest:
    var regexp: String
    var return_value: Bool
    var prefix: String
    var foldcase: Bool
    var suffix: String

    def __init__(inout self, regexp: String, return_value: Bool, prefix: String = "", foldcase: Bool = False, suffix: String = ""):
        self.regexp = regexp
        self.return_value = return_value
        self.prefix = prefix
        self.foldcase = foldcase
        self.suffix = suffix

var tests: StaticArray[PrefixTest, 14] = StaticArray[PrefixTest, 14](
    PrefixTest("", False),
    PrefixTest("(?m)^", False),
    PrefixTest("(?-m)^", False),
    PrefixTest("abc", False),
    PrefixTest("^a*", False),
    PrefixTest("^(abc)", False),
    PrefixTest("^abc$", True, "abc", False, "(?-m:$)"),
    PrefixTest("^abc", True, "abc", False, ""),
    PrefixTest("^(?i)abc", True, "abc", True, ""),
    PrefixTest("^abcd*", True, "abc", False, "d*"),
    PrefixTest("^[Aa][Bb]cd*", True, "ab", True, "cd*"),
    PrefixTest("^ab[Cc]d*", True, "ab", False, "[Cc]d*"),
    PrefixTest("^☺abc", True, "☺abc", False, ""),
)

def test_RequiredPrefix_SimpleTests():
    for i in range(arraysize(tests)):
        var t = tests[i]
        for j in range(2):
            var flags = Regexp.LikePerl
            if j == 0:
                flags = flags | Regexp.Latin1
            var re = Regexp.Parse(t.regexp, flags, None)
            ASSERT_TRUE(re != None) << " " << t.regexp
            var p: String
            var f: Bool
            var s: Regexp
            ASSERT_EQ(t.return_value, re.RequiredPrefix(&p, &f, &s)) << " " << t.regexp << " " << (j == 0 ? "latin1" : "utf8") << " " << re.Dump()
            if t.return_value:
                ASSERT_EQ(p, String(t.prefix)) << " " << t.regexp << " " << (j == 0 ? "latin1" : "utf8")
                ASSERT_EQ(f, t.foldcase) << " " << t.regexp << " " << (j == 0 ? "latin1" : "utf8")
                ASSERT_EQ(s.ToString(), String(t.suffix)) << " " << t.regexp << " " << (j == 0 ? "latin1" : "utf8")
                s.Decref()
            re.Decref()

var for_accel_tests: StaticArray[PrefixTest, 18] = StaticArray[PrefixTest, 18](
    PrefixTest("", False),
    PrefixTest("(?m)^", False),
    PrefixTest("(?-m)^", False),
    PrefixTest("^abc", False),
    PrefixTest("a*", False),
    PrefixTest("(a?)def", False),
    PrefixTest("(ab?)def", True, "a", False),
    PrefixTest("(abc?)def", True, "ab", False),
    PrefixTest("(()a)def", False),
    PrefixTest("((a)b)def", True, "a", False),
    PrefixTest("((ab)c)def", True, "ab", False),
    PrefixTest("abc$", True, "abc", False),
    PrefixTest("abc", True, "abc", False),
    PrefixTest("(?i)abc", True, "abc", True),
    PrefixTest("abcd*", True, "abc", False),
    PrefixTest("[Aa][Bb]cd*", True, "ab", True),
    PrefixTest("ab[Cc]d*", True, "ab", False),
    PrefixTest("☺abc", True, "☺abc", False),
)

def test_RequiredPrefixForAccel_SimpleTests():
    for i in range(arraysize(for_accel_tests)):
        var t = for_accel_tests[i]
        for j in range(2):
            var flags = Regexp.LikePerl
            if j == 0:
                flags = flags | Regexp.Latin1
            var re = Regexp.Parse(t.regexp, flags, None)
            ASSERT_TRUE(re != None) << " " << t.regexp
            var p: String
            var f: Bool
            ASSERT_EQ(t.return_value, re.RequiredPrefixForAccel(&p, &f)) << " " << t.regexp << " " << (j == 0 ? "latin1" : "utf8") << " " << re.Dump()
            if t.return_value:
                ASSERT_EQ(p, String(t.prefix)) << " " << t.regexp << " " << (j == 0 ? "latin1" : "utf8")
                ASSERT_EQ(f, t.foldcase) << " " << t.regexp << " " << (j == 0 ? "latin1" : "utf8")
            re.Decref()

def test_RequiredPrefixForAccel_CaseFoldingForKAndS():
    var re: Regexp
    var p: String
    var f: Bool
    re = Regexp.Parse("(?i)KLM", Regexp.LikePerl | Regexp.Latin1, None)
    ASSERT_TRUE(re != None)
    ASSERT_TRUE(re.RequiredPrefixForAccel(&p, &f))
    ASSERT_EQ(p, "klm")
    ASSERT_EQ(f, True)
    re.Decref()
    re = Regexp.Parse("(?i)STU", Regexp.LikePerl | Regexp.Latin1, None)
    ASSERT_TRUE(re != None)
    ASSERT_TRUE(re.RequiredPrefixForAccel(&p, &f))
    ASSERT_EQ(p, "stu")
    ASSERT_EQ(f, True)
    re.Decref()
    re = Regexp.Parse("(?i)KLM", Regexp.LikePerl, None)
    ASSERT_TRUE(re != None)
    ASSERT_FALSE(re.RequiredPrefixForAccel(&p, &f))
    re.Decref()
    re = Regexp.Parse("(?i)STU", Regexp.LikePerl, None)
    ASSERT_TRUE(re != None)
    ASSERT_FALSE(re.RequiredPrefixForAccel(&p, &f))
    re.Decref()

var prefix_accel_tests: StaticArray[String, 2] = StaticArray[String, 2](
    "aababc\\d+",
    "(?i)AABABC\\d+",
)

def test_PrefixAccel_SimpleTests():
    for i in range(arraysize(prefix_accel_tests)):
        var pattern = prefix_accel_tests[i]
        var re = Regexp.Parse(pattern, Regexp.LikePerl, None)
        ASSERT_TRUE(re != None)
        var prog = re.CompileToProg(0)
        ASSERT_TRUE(prog != None)
        ASSERT_TRUE(prog.can_prefix_accel())
        for j in range(100):
            var text = String(j, 'a')
            var p = prog.PrefixAccel(text.data(), text.size())
            EXPECT_TRUE(p == None)
            text.append("aababc")
            for k in range(100):
                text.append(k, 'a')
                p = prog.PrefixAccel(text.data(), text.size())
                EXPECT_EQ(j, p - text.data())
        delete prog
        re.Decref()