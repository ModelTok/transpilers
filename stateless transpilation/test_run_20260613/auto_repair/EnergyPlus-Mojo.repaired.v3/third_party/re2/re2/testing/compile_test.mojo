module re2:

from util.test import TEST, EXPECT_EQ, ASSERT_TRUE
from util.logging import LOG
from ..regexp import Regexp
from ..prog import Prog
from ..stringpiece import StringPiece

struct Test:
    var regexp: String
    var code: String

var tests: List[Test] = List[Test](
    Test("a",
        "3. byte [61-61] 0 -> 4\n"
        "4. match! 0\n"),
    Test("ab",
        "3. byte [61-61] 0 -> 4\n"
        "4. byte [62-62] 0 -> 5\n"
        "5. match! 0\n"),
    Test("a|c",
        "3+ byte [61-61] 0 -> 5\n"
        "4. byte [63-63] 0 -> 5\n"
        "5. match! 0\n"),
    Test("a|b",
        "3. byte [61-62] 0 -> 4\n"
        "4. match! 0\n"),
    Test("[ab]",
        "3. byte [61-62] 0 -> 4\n"
        "4. match! 0\n"),
    Test("a+",
        "3. byte [61-61] 0 -> 4\n"
        "4+ nop -> 3\n"
        "5. match! 0\n"),
    Test("a+?",
        "3. byte [61-61] 0 -> 4\n"
        "4+ match! 0\n"
        "5. nop -> 3\n"),
    Test("a*",
        "3+ byte [61-61] 1 -> 3\n"
        "4. match! 0\n"),
    Test("a*?",
        "3+ match! 0\n"
        "4. byte [61-61] 0 -> 3\n"),
    Test("a?",
        "3+ byte [61-61] 1 -> 5\n"
        "4. nop -> 5\n"
        "5. match! 0\n"),
    Test("a??",
        "3+ nop -> 5\n"
        "4. byte [61-61] 0 -> 5\n"
        "5. match! 0\n"),
    Test("a{4}",
        "3. byte [61-61] 0 -> 4\n"
        "4. byte [61-61] 0 -> 5\n"
        "5. byte [61-61] 0 -> 6\n"
        "6. byte [61-61] 0 -> 7\n"
        "7. match! 0\n"),
    Test("(a)",
        "3. capture 2 -> 4\n"
        "4. byte [61-61] 0 -> 5\n"
        "5. capture 3 -> 6\n"
        "6. match! 0\n"),
    Test("(?:a)",
        "3. byte [61-61] 0 -> 4\n"
        "4. match! 0\n"),
    Test("",
        "3. match! 0\n"),
    Test(".",
        "3+ byte [00-09] 0 -> 5\n"
        "4. byte [0b-ff] 0 -> 5\n"
        "5. match! 0\n"),
    Test("[^ab]",
        "3+ byte [00-09] 0 -> 6\n"
        "4+ byte [0b-60] 0 -> 6\n"
        "5. byte [63-ff] 0 -> 6\n"
        "6. match! 0\n"),
    Test("[Aa]",
        "3. byte/i [61-61] 0 -> 4\n"
        "4. match! 0\n"),
    Test("\\C+",
        "3. byte [00-ff] 0 -> 4\n"
        "4+ altmatch -> 5 | 6\n"
        "5+ nop -> 3\n"
        "6. match! 0\n"),
    Test("\\C*",
        "3+ altmatch -> 4 | 5\n"
        "4+ byte [00-ff] 1 -> 3\n"
        "5. match! 0\n"),
    Test("\\C?",
        "3+ byte [00-ff] 1 -> 5\n"
        "4. nop -> 5\n"
        "5. match! 0\n"),
    Test("[[-`]",
        "3. byte [5b-60] 0 -> 4\n"
        "4. match! 0\n"),
    Test("(?:|a)*",
        "3+ nop -> 7\n"
        "4. nop -> 9\n"
        "5+ nop -> 7\n"
        "6. nop -> 9\n"
        "7+ nop -> 5\n"
        "8. byte [61-61] 0 -> 5\n"
        "9. match! 0\n"),
    Test("(?:|a)+",
        "3+ nop -> 5\n"
        "4. byte [61-61] 0 -> 5\n"
        "5+ nop -> 3\n"
        "6. match! 0\n"),
)

struct TestRegexpCompileToProg:
    def Simple():
        var failed: Int = 0
        for i in range(len(tests)):
            let t = tests[i]
            var re = Regexp.Parse(t.regexp, Regexp.PerlX | Regexp.Latin1, None)
            if re is None:
                print("ERROR: Cannot parse: ", t.regexp, file=stderr)
                failed += 1
                continue
            var prog = re.CompileToProg(0)
            if prog is None:
                print("ERROR: Cannot compile: ", t.regexp, file=stderr)
                re.Decref()
                failed += 1
                continue
            # ASSERT_TRUE(re->CompileToProg(1) == NULL)
            var prog2 = re.CompileToProg(1)
            if prog2 is not None:
                print("ERROR: Expected NULL for CompileToProg(1)", file=stderr)
                failed += 1
            var s = prog.Dump()
            if s != t.code:
                print("ERROR: Incorrect compiled code for: ", t.regexp, file=stderr)
                print("Want:\n", t.code, file=stderr)
                print("Got:\n", s, file=stderr)
                failed += 1
            prog.Delete()
            re.Decref()
        if failed != 0:
            print("FAIL: ", failed, " tests failed", file=stderr)
        else:
            print("PASS")

def DumpByteMap(pattern: StringPiece, flags: Regexp.ParseFlags, bytemap: ref String):
    var re = Regexp.Parse(pattern, flags, None)
    # EXPECT_TRUE(re != NULL)
    if re is None:
        print("ERROR: re is NULL", file=stderr)
        return
    # First block
    var prog = re.CompileToProg(0)
    if prog is None:
        print("ERROR: prog is NULL", file=stderr)
        re.Decref()
        return
    bytemap[] = prog.DumpByteMap()
    prog.Delete()
    # Second block
    var prog2 = re.CompileToReverseProg(0)
    if prog2 is None:
        print("ERROR: reverse prog is NULL", file=stderr)
        re.Decref()
        return
    # EXPECT_EQ(*bytemap, prog->DumpByteMap())
    if bytemap[] != prog2.DumpByteMap():
        print("ERROR: byte maps differ", file=stderr)
    prog2.Delete()
    re.Decref()

struct TestCompile:
    def Latin1Ranges():
        var bytemap: String
        DumpByteMap(".", Regexp.PerlX | Regexp.Latin1, bytemap)
        # EXPECT_EQ(...)
        var expected = "[00-09] -> 0\n" \
                       "[0a-0a] -> 1\n" \
                       "[0b-ff] -> 0\n"
        if bytemap != expected:
            print("ERROR: Latin1Ranges mismatch", file=stderr)
            print("Want:\n", expected, file=stderr)
            print("Got:\n", bytemap, file=stderr)

    def OtherByteMapTests():
        var bytemap: String
        DumpByteMap("[0-9A-Fa-f]+", Regexp.PerlX | Regexp.Latin1, bytemap)
        var expected = "[00-2f] -> 0\n" \
                       "[30-39] -> 1\n" \
                       "[3a-40] -> 0\n" \
                       "[41-46] -> 1\n" \
                       "[47-60] -> 0\n" \
                       "[61-66] -> 1\n" \
                       "[67-ff] -> 0\n"
        if bytemap != expected:
            print("ERROR: OtherByteMapTests [0-9A-Fa-f]+ mismatch", file=stderr)
            print("Want:\n", expected, file=stderr)
            print("Got:\n", bytemap, file=stderr)

        DumpByteMap("\\b", Regexp.LikePerl | Regexp.Latin1, bytemap)
        expected = "[00-2f] -> 0\n" \
                   "[30-39] -> 1\n" \
                   "[3a-40] -> 0\n" \
                   "[41-5a] -> 1\n" \
                   "[5b-5e] -> 0\n" \
                   "[5f-5f] -> 1\n" \
                   "[60-60] -> 0\n" \
                   "[61-7a] -> 1\n" \
                   "[7b-ff] -> 0\n"
        if bytemap != expected:
            print("ERROR: OtherByteMapTests \\b mismatch", file=stderr)
            print("Want:\n", expected, file=stderr)
            print("Got:\n", bytemap, file=stderr)

        DumpByteMap("[^_]", Regexp.LikePerl | Regexp.Latin1, bytemap)
        expected = "[00-5e] -> 0\n" \
                   "[5f-5f] -> 1\n" \
                   "[60-ff] -> 0\n"
        if bytemap != expected:
            print("ERROR: OtherByteMapTests [^_] mismatch", file=stderr)
            print("Want:\n", expected, file=stderr)
            print("Got:\n", bytemap, file=stderr)

    def UTF8Ranges():
        var bytemap: String
        DumpByteMap(".", Regexp.PerlX, bytemap)
        var expected = "[00-09] -> 0\n" \
                       "[0a-0a] -> 1\n" \
                       "[0b-7f] -> 0\n" \
                       "[80-bf] -> 2\n" \
                       "[c0-c1] -> 1\n" \
                       "[c2-df] -> 3\n" \
                       "[e0-ef] -> 4\n" \
                       "[f0-f4] -> 5\n" \
                       "[f5-ff] -> 1\n"
        if bytemap != expected:
            print("ERROR: UTF8Ranges mismatch", file=stderr)
            print("Want:\n", expected, file=stderr)
            print("Got:\n", bytemap, file=stderr)

    def InsufficientMemory():
        var re = Regexp.Parse(
            "^(?P<name1>[^\\s]+)\\s+(?P<name2>[^\\s]+)\\s+(?P<name3>.+)$",
            Regexp.LikePerl, None)
        # EXPECT_TRUE(re != NULL)
        if re is None:
            print("ERROR: re is NULL", file=stderr)
            return
        var prog = re.CompileToProg(850)
        # EXPECT_TRUE(prog == NULL)
        if prog is not None:
            print("ERROR: Expected NULL prog", file=stderr)
        re.Decref()

def Dump(pattern: StringPiece, flags: Regexp.ParseFlags, forward: ref String, reverse: ref String):
    var re = Regexp.Parse(pattern, flags, None)
    # EXPECT_TRUE(re != NULL)
    if re is None:
        print("ERROR: re is NULL", file=stderr)
        return
    if forward is not None:
        var prog = re.CompileToProg(0)
        # EXPECT_TRUE(prog != NULL)
        if prog is None:
            print("ERROR: forward prog is NULL", file=stderr)
            re.Decref()
            return
        forward[] = prog.Dump()
        prog.Delete()
    if reverse is not None:
        var prog = re.CompileToReverseProg(0)
        # EXPECT_TRUE(prog != NULL)
        if prog is None:
            print("ERROR: reverse prog is NULL", file=stderr)
            re.Decref()
            return
        reverse[] = prog.Dump()
        prog.Delete()
    re.Decref()

struct TestCompile:
    def Bug26705922():
        var forward: String
        var reverse: String
        Dump("[\\x{10000}\\x{10010}]", Regexp.LikePerl, forward, reverse)
        var expected_forward = "3. byte [f0-f0] 0 -> 4\n" \
                               "4. byte [90-90] 0 -> 5\n" \
                               "5. byte [80-80] 0 -> 6\n" \
                               "6+ byte [80-80] 0 -> 8\n" \
                               "7. byte [90-90] 0 -> 8\n" \
                               "8. match! 0\n"
        if forward != expected_forward:
            print("ERROR: Bug26705922 forward mismatch", file=stderr)
            print("Want:\n", expected_forward, file=stderr)
            print("Got:\n", forward, file=stderr)
        var expected_reverse = "3+ byte [80-80] 0 -> 5\n" \
                               "4. byte [90-90] 0 -> 5\n" \
                               "5. byte [80-80] 0 -> 6\n" \
                               "6. byte [90-90] 0 -> 7\n" \
                               "7. byte [f0-f0] 0 -> 8\n" \
                               "8. match! 0\n"
        if reverse != expected_reverse:
            print("ERROR: Bug26705922 reverse mismatch", file=stderr)
            print("Want:\n", expected_reverse, file=stderr)
            print("Got:\n", reverse, file=stderr)

        Dump("[\\x{8000}-\\x{10FFF}]", Regexp.LikePerl, forward, reverse)
        expected_forward = "3+ byte [e8-ef] 0 -> 5\n" \
                           "4. byte [f0-f0] 0 -> 8\n" \
                           "5. byte [80-bf] 0 -> 6\n" \
                           "6. byte [80-bf] 0 -> 7\n" \
                           "7. match! 0\n" \
                           "8. byte [90-90] 0 -> 5\n"
        if forward != expected_forward:
            print("ERROR: Bug26705922 second forward mismatch", file=stderr)
            print("Want:\n", expected_forward, file=stderr)
            print("Got:\n", forward, file=stderr)
        expected_reverse = "3. byte [80-bf] 0 -> 4\n" \
                           "4. byte [80-bf] 0 -> 5\n" \
                           "5+ byte [e8-ef] 0 -> 7\n" \
                           "6. byte [90-90] 0 -> 8\n" \
                           "7. match! 0\n" \
                           "8. byte [f0-f0] 0 -> 7\n"
        if reverse != expected_reverse:
            print("ERROR: Bug26705922 second reverse mismatch", file=stderr)
            print("Want:\n", expected_reverse, file=stderr)
            print("Got:\n", reverse, file=stderr)

        Dump("[\\x{80}-\\x{10FFFF}]", Regexp.LikePerl, forward, reverse)
        expected_forward = "3+ byte [c2-df] 0 -> 6\n" \
                           "4+ byte [e0-ef] 0 -> 8\n" \
                           "5. byte [f0-f4] 0 -> 9\n" \
                           "6. byte [80-bf] 0 -> 7\n" \
                           "7. match! 0\n" \
                           "8. byte [80-bf] 0 -> 6\n" \
                           "9. byte [80-bf] 0 -> 8\n"
        if forward != expected_forward:
            print("ERROR: Bug26705922 third forward mismatch", file=stderr)
            print("Want:\n", expected_forward, file=stderr)
            print("Got:\n", forward, file=stderr)
        expected_reverse = "3. byte [80-bf] 0 -> 4\n" \
                           "4+ byte [c2-df] 0 -> 6\n" \
                           "5. byte [80-bf] 0 -> 7\n" \
                           "6. match! 0\n" \
                           "7+ byte [e0-ef] 0 -> 6\n" \
                           "8. byte [80-bf] 0 -> 9\n" \
                           "9. byte [f0-f4] 0 -> 6\n"
        if reverse != expected_reverse:
            print("ERROR: Bug26705922 third reverse mismatch", file=stderr)
            print("Want:\n", expected_reverse, file=stderr)
            print("Got:\n", reverse, file=stderr)

    def Bug35237384():
        var forward: String
        Dump("a**{3,}", Regexp.Latin1 | Regexp.NeverCapture, forward, None)
        var expected_forward = "3+ byte [61-61] 1 -> 3\n" \
                               "4. nop -> 5\n" \
                               "5+ byte [61-61] 1 -> 5\n" \
                               "6. nop -> 7\n" \
                               "7+ byte [61-61] 1 -> 7\n" \
                               "8. match! 0\n"
        if forward != expected_forward:
            print("ERROR: Bug35237384 first forward mismatch", file=stderr)
            print("Want:\n", expected_forward, file=stderr)
            print("Got:\n", forward, file=stderr)

        Dump("(a*|b*)*{3,}", Regexp.Latin1 | Regexp.NeverCapture, forward, None)
        expected_forward = "3+ nop -> 28\n" \
                           "4. nop -> 30\n" \
                           "5+ byte [61-61] 1 -> 5\n" \
                           "6. nop -> 32\n" \
                           "7+ byte [61-61] 1 -> 7\n" \
                           "8. nop -> 26\n" \
                           "9+ byte [61-61] 1 -> 9\n" \
                           "10. nop -> 20\n" \
                           "11+ byte [62-62] 1 -> 11\n" \
                           "12. nop -> 20\n" \
                           "13+ byte [62-62] 1 -> 13\n" \
                           "14. nop -> 26\n" \
                           "15+ byte [62-62] 1 -> 15\n" \
                           "16. nop -> 32\n" \
                           "17+ nop -> 9\n" \
                           "18. nop -> 11\n" \
                           "19. match! 0\n" \
                           "20+ nop -> 17\n" \
                           "21. nop -> 19\n" \
                           "22+ nop -> 7\n" \
                           "23. nop -> 13\n" \
                           "24+ nop -> 17\n" \
                           "25. nop -> 19\n" \
                           "26+ nop -> 22\n" \
                           "27. nop -> 24\n" \
                           "28+ nop -> 5\n" \
                           "29. nop -> 15\n" \
                           "30+ nop -> 22\n" \
                           "31. nop -> 24\n" \
                           "32+ nop -> 28\n" \
                           "33. nop -> 30\n"
        if forward != expected_forward:
            print("ERROR: Bug35237384 second forward mismatch", file=stderr)
            print("Want:\n", expected_forward, file=stderr)
            print("Got:\n", forward, file=stderr)

        Dump("((|S.+)+|(|S.+)+|){2}", Regexp.Latin1 | Regexp.NeverCapture, forward, None)
        expected_forward = "3+ nop -> 36\n" \
                           "4+ nop -> 31\n" \
                           "5. nop -> 33\n" \
                           "6+ byte [00-09] 0 -> 8\n" \
                           "7. byte [0b-ff] 0 -> 8\n" \
                           "8+ nop -> 6\n" \
                           "9+ nop -> 29\n" \
                           "10. nop -> 28\n" \
                           "11+ byte [00-09] 0 -> 13\n" \
                           "12. byte [0b-ff] 0 -> 13\n" \
                           "13+ nop -> 11\n" \
                           "14+ nop -> 26\n" \
                           "15. nop -> 28\n" \
                           "16+ byte [00-09] 0 -> 18\n" \
                           "17. byte [0b-ff] 0 -> 18\n" \
                           "18+ nop -> 16\n" \
                           "19+ nop -> 36\n" \
                           "20. nop -> 33\n" \
                           "21+ byte [00-09] 0 -> 23\n" \
                           "22. byte [0b-ff] 0 -> 23\n" \
                           "23+ nop -> 21\n" \
                           "24+ nop -> 31\n" \
                           "25. nop -> 33\n" \
                           "26+ nop -> 28\n" \
                           "27. byte [53-53] 0 -> 11\n" \
                           "28. match! 0\n" \
                           "29+ nop -> 28\n" \
                           "30. byte [53-53] 0 -> 6\n" \
                           "31+ nop -> 33\n" \
                           "32. byte [53-53] 0 -> 21\n" \
                           "33+ nop -> 29\n" \
                           "34+ nop -> 26\n" \
                           "35. nop -> 28\n" \
                           "36+ nop -> 33\n" \
                           "37. byte [53-53] 0 -> 16\n"
        if forward != expected_forward:
            print("ERROR: Bug35237384 third forward mismatch", file=stderr)
            print("Want:\n", expected_forward, file=stderr)
            print("Got:\n", forward, file=stderr)

def main():
    TestRegexpCompileToProg.Simple()
    TestCompile.Latin1Ranges()
    TestCompile.OtherByteMapTests()
    TestCompile.UTF8Ranges()
    TestCompile.InsufficientMemory()
    TestCompile.Bug26705922()
    TestCompile.Bug35237384()