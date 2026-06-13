from util.test import TEST, EXPECT_LT, EXPECT_EQ, EXPECT_FALSE, ASSERT_TRUE, ASSERT_GE, ASSERT_LE
from util.logging import LOG, VLOG
from util.strutil import CEscape, Split, Explode
from re2.prog import Prog
from re2.re2 import RE2, RE2_Latin1
from re2.regexp import Regexp
from exhaustive_tester import RegexpGenerator
from string_generator import StringGenerator

module re2:

    def TEST_CplusplusStrings_EightBit():
        var s: String = "\x70"
        var t: String = "\xA0"
        EXPECT_LT(s, t)

    struct PrefixTest:
        var regexp: String
        var maxlen: Int
        var min: String
        var max: String

    var tests: List[PrefixTest] = List[
        PrefixTest("", 10, "", ""),
        PrefixTest("Abcdef", 10, "Abcdef", "Abcdef"),
        PrefixTest("abc(def|ghi)", 10, "abcdef", "abcghi"),
        PrefixTest("a+hello", 10, "aa", "ahello"),
        PrefixTest("a*hello", 10, "a", "hello"),
        PrefixTest("def|abc", 10, "abc", "def"),
        PrefixTest("a(b)(c)[d]", 10, "abcd", "abcd"),
        PrefixTest("ab(cab|cat)", 10, "abcab", "abcat"),
        PrefixTest("ab(cab|ca)x", 10, "abcabx", "abcax"),
        PrefixTest("(ab|x)(c|de)", 10, "abc", "xde"),
        PrefixTest("(ab|x)?(c|z)?", 10, "", "z"),
        PrefixTest("[^\\s\\S]", 10, "", ""),
        PrefixTest("(abc)+", 5, "abc", "abcac"),
        PrefixTest("(abc)+", 2, "ab", "ac"),
        PrefixTest("(abc)+", 1, "a", "b"),
        PrefixTest("[a\xC3\xA1]", 4, "a", "\xC3\xA1"),
        PrefixTest("a*", 10, "", "ab"),
        PrefixTest("(?i)Abcdef", 10, "ABCDEF", "abcdef"),
        PrefixTest("(?i)abc(def|ghi)", 10, "ABCDEF", "abcghi"),
        PrefixTest("(?i)a+hello", 10, "AA", "ahello"),
        PrefixTest("(?i)a*hello", 10, "A", "hello"),
        PrefixTest("(?i)def|abc", 10, "ABC", "def"),
        PrefixTest("(?i)a(b)(c)[d]", 10, "ABCD", "abcd"),
        PrefixTest("(?i)ab(cab|cat)", 10, "ABCAB", "abcat"),
        PrefixTest("(?i)ab(cab|ca)x", 10, "ABCABX", "abcax"),
        PrefixTest("(?i)(ab|x)(c|de)", 10, "ABC", "xde"),
        PrefixTest("(?i)(ab|x)?(c|z)?", 10, "", "z"),
        PrefixTest("(?i)[^\\s\\S]", 10, "", ""),
        PrefixTest("(?i)(abc)+", 5, "ABC", "abcac"),
        PrefixTest("(?i)(abc)+", 2, "AB", "ac"),
        PrefixTest("(?i)(abc)+", 1, "A", "b"),
        PrefixTest("(?i)[a\xC3\xA1]", 4, "A", "\xC3\xA1"),
        PrefixTest("(?i)a*", 10, "", "ab"),
        PrefixTest("(?i)A*", 10, "", "ab"),
        PrefixTest("\\AAbcdef", 10, "Abcdef", "Abcdef"),
        PrefixTest("\\Aabc(def|ghi)", 10, "abcdef", "abcghi"),
        PrefixTest("\\Aa+hello", 10, "aa", "ahello"),
        PrefixTest("\\Aa*hello", 10, "a", "hello"),
        PrefixTest("\\Adef|abc", 10, "abc", "def"),
        PrefixTest("\\Aa(b)(c)[d]", 10, "abcd", "abcd"),
        PrefixTest("\\Aab(cab|cat)", 10, "abcab", "abcat"),
        PrefixTest("\\Aab(cab|ca)x", 10, "abcabx", "abcax"),
        PrefixTest("\\A(ab|x)(c|de)", 10, "abc", "xde"),
        PrefixTest("\\A(ab|x)?(c|z)?", 10, "", "z"),
        PrefixTest("\\A[^\\s\\S]", 10, "", ""),
        PrefixTest("\\A(abc)+", 5, "abc", "abcac"),
        PrefixTest("\\A(abc)+", 2, "ab", "ac"),
        PrefixTest("\\A(abc)+", 1, "a", "b"),
        PrefixTest("\\A[a\xC3\xA1]", 4, "a", "\xC3\xA1"),
        PrefixTest("\\Aa*", 10, "", "ab"),
        PrefixTest("(?i)\\AAbcdef", 10, "ABCDEF", "abcdef"),
        PrefixTest("(?i)\\Aabc(def|ghi)", 10, "ABCDEF", "abcghi"),
        PrefixTest("(?i)\\Aa+hello", 10, "AA", "ahello"),
        PrefixTest("(?i)\\Aa*hello", 10, "A", "hello"),
        PrefixTest("(?i)\\Adef|abc", 10, "ABC", "def"),
        PrefixTest("(?i)\\Aa(b)(c)[d]", 10, "ABCD", "abcd"),
        PrefixTest("(?i)\\Aab(cab|cat)", 10, "ABCAB", "abcat"),
        PrefixTest("(?i)\\Aab(cab|ca)x", 10, "ABCABX", "abcax"),
        PrefixTest("(?i)\\A(ab|x)(c|de)", 10, "ABC", "xde"),
        PrefixTest("(?i)\\A(ab|x)?(c|z)?", 10, "", "z"),
        PrefixTest("(?i)\\A[^\\s\\S]", 10, "", ""),
        PrefixTest("(?i)\\A(abc)+", 5, "ABC", "abcac"),
        PrefixTest("(?i)\\A(abc)+", 2, "AB", "ac"),
        PrefixTest("(?i)\\A(abc)+", 1, "A", "b"),
        PrefixTest("(?i)\\A[a\xC3\xA1]", 4, "A", "\xC3\xA1"),
        PrefixTest("(?i)\\Aa*", 10, "", "ab"),
        PrefixTest("(?i)\\AA*", 10, "", "ab"),
    ]

    def TEST_PossibleMatchRange_HandWritten():
        for i in range(len(tests)):
            for j in range(2):
                let t = tests[i]
                var min: String
                var max: String
                if j == 0:
                    LOG(INFO, "Checking regexp=", CEscape(t.regexp))
                    var re: Regexp = Regexp.Parse(t.regexp, Regexp.LikePerl, None)
                    ASSERT_TRUE(re != None)
                    var prog: Prog = re.CompileToProg(0)
                    ASSERT_TRUE(prog != None)
                    ASSERT_TRUE(prog.PossibleMatchRange(&min, &max, t.maxlen), " ", t.regexp)
                    del prog
                    re.Decref()
                else:
                    ASSERT_TRUE(RE2(t.regexp).PossibleMatchRange(&min, &max, t.maxlen))
                EXPECT_EQ(t.min, min, t.regexp)
                EXPECT_EQ(t.max, max, t.regexp)

    def TEST_PossibleMatchRange_Failures():
        var min: String
        var max: String
        EXPECT_FALSE(RE2("abc").PossibleMatchRange(&min, &max, 0))
        EXPECT_FALSE(RE2("[\\s\\S]+", RE2_Latin1).PossibleMatchRange(&min, &max, 10),
                     "min=", CEscape(min), ", max=", CEscape(max))
        EXPECT_FALSE(RE2("[\\0-\xFF]+", RE2_Latin1).PossibleMatchRange(&min, &max, 10),
                     "min=", CEscape(min), ", max=", CEscape(max))
        EXPECT_FALSE(RE2(".+hello", RE2_Latin1).PossibleMatchRange(&min, &max, 10),
                     "min=", CEscape(min), ", max=", CEscape(max))
        EXPECT_FALSE(RE2(".*hello", RE2_Latin1).PossibleMatchRange(&min, &max, 10),
                     "min=", CEscape(min), ", max=", CEscape(max))
        EXPECT_FALSE(RE2(".*", RE2_Latin1).PossibleMatchRange(&min, &max, 10),
                     "min=", CEscape(min), ", max=", CEscape(max))
        EXPECT_FALSE(RE2("\\C*").PossibleMatchRange(&min, &max, 10),
                     "min=", CEscape(min), ", max=", CEscape(max))
        EXPECT_FALSE(RE2("*hello").PossibleMatchRange(&min, &max, 10),
                     "min=", CEscape(min), ", max=", CEscape(max))

    struct PossibleMatchTester(RegexpGenerator):
        var strgen_: StringGenerator
        var regexps_: Int
        var tests_: Int

        def __init__(inout self, maxatoms: Int, maxops: Int, alphabet: List[String], ops: List[String], maxstrlen: Int, stralphabet: List[String]):
            RegexpGenerator.__init__(self, maxatoms, maxops, alphabet, ops)
            self.strgen_ = StringGenerator(maxstrlen, stralphabet)
            self.regexps_ = 0
            self.tests_ = 0

        def regexps(inout self) -> Int:
            return self.regexps_

        def tests(inout self) -> Int:
            return self.tests_

        def HandleRegexp(inout self, regexp: String):
            self.regexps_ += 1
            VLOG(3, CEscape(regexp))
            var re: RE2 = RE2(regexp, RE2_Latin1)
            ASSERT_EQ(re.error(), "")
            var min: String
            var max: String
            if not re.PossibleMatchRange(&min, &max, 10):
                if strstr(regexp.c_str(), "\\C*"):
                    return
                LOG(QFATAL, "PossibleMatchRange failed on: ", CEscape(regexp))
            self.strgen_.Reset()
            while self.strgen_.HasNext():
                let s = self.strgen_.Next()   # StringPiece assumed
                self.tests_ += 1
                if not RE2.FullMatch(s, re):
                    continue
                ASSERT_GE(s, min, " regexp: ", regexp, " max: ", max)
                ASSERT_LE(s, max, " regexp: ", regexp, " min: ", min)

    def TEST_PossibleMatchRange_Exhaustive():
        var natom: Int = 3
        var noperator: Int = 3
        var stringlen: Int = 5
        if RE2_DEBUG_MODE:
            natom = 2
            noperator = 3
            stringlen = 3
        var t = PossibleMatchTester(natom, noperator, Split(" ", "a b [0-9]"),
                                    RegexpGenerator.EgrepOps(),
                                    stringlen, Explode("ab4"))
        t.Generate()
        LOG(INFO, t.regexps(), " regexps, ", t.tests(), " tests")

    # Add a main function to run all tests if needed (optional)
    def main():
        TEST_CplusplusStrings_EightBit()
        TEST_PossibleMatchRange_HandWritten()
        TEST_PossibleMatchRange_Failures()
        TEST_PossibleMatchRange_Exhaustive()