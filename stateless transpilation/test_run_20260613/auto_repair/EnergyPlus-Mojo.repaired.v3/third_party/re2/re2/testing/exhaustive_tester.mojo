from ...util.util import BeginPtr, EndPtr
from ...util.strutil import StringPrintf, Split
from ...util.test import EXPECT_EQ
from . import RE2, StringPiece
from regexp_generator import RegexpGenerator
from string_generator import StringGenerator
from tester import Tester

# LOGGING macro
let LOGGING: Int = 0

# DEFINE_FLAG emulation
var FLAGS_show_regexps: Bool = False
var FLAGS_max_bad_regexp_inputs: Int = 1

def GetFlag[T](flag: T) -> T:
    return flag

# LOG emulation
def LOG(level: String, message: String):
    if level == "FATAL":
        print(message, file=stderr)
        exit(1)
    else:
        print(message, file=stderr)

# RE2_DEBUG_MODE from header
# if !defined(NDEBUG)
#   bool RE2_DEBUG_MODE = true;
# elif __has_feature(address_sanitizer) || __has_feature(memory_sanitizer) || __has_feature(thread_sanitizer)
#   bool RE2_DEBUG_MODE = true;
# else
#   bool RE2_DEBUG_MODE = false;
# endif
let RE2_DEBUG_MODE: Bool = True

# arraysize macro
def arraysize[T](arr: List[T]) -> Int:
    return len(arr)

# static functions
def escape(sp: StringPiece) -> String:
    var buf = String()
    buf += "\""
    for i in range(sp.size()):
        if len(buf) + 5 >= 512:
            LOG("FATAL", "ExhaustiveTester escape: too long")
        if sp[i] == '\\' or sp[i] == '\"':
            buf += "\\"
            buf += sp[i]
        elif sp[i] == '\n':
            buf += "\\"
            buf += "n"
        else:
            buf += sp[i]
    buf += "\""
    return buf

def PrintResult(re: RE2, input: StringPiece, anchor: RE2.Anchor, m: Array[StringPiece], n: Int):
    if not re.Match(input, 0, input.size(), anchor, m, n):
        print("-", end="")
        return
    for i in range(n):
        if i > 0:
            print(" ", end="")
        if m[i].data() == None:
            print("-", end="")
        else:
            var begin = BeginPtr(m[i]) - BeginPtr(input)
            var end = EndPtr(m[i]) - BeginPtr(input)
            print(f"{begin}-{end}", end="")

class ExhaustiveTester(RegexpGenerator):
    var strgen_: StringGenerator
    var wrapper_: String
    var topwrapper_: String
    var regexps_: Int
    var tests_: Int
    var failures_: Int
    var randomstrings_: Bool
    var stringseed_: Int32
    var stringcount_: Int

    def __init__(inout self, maxatoms: Int, maxops: Int, alphabet: List[String], ops: List[String],
                maxstrlen: Int, stralphabet: List[String], wrapper: String, topwrapper: String):
        RegexpGenerator.__init__(self, maxatoms, maxops, alphabet, ops)
        self.strgen_ = StringGenerator(maxstrlen, stralphabet)
        self.wrapper_ = wrapper
        self.topwrapper_ = topwrapper
        self.regexps_ = 0
        self.tests_ = 0
        self.failures_ = 0
        self.randomstrings_ = False
        self.stringseed_ = 0
        self.stringcount_ = 0

    def regexps(inout self) -> Int:
        return self.regexps_

    def tests(inout self) -> Int:
        return self.tests_

    def failures(inout self) -> Int:
        return self.failures_

    def HandleRegexp(inout self, const_regexp: String):
        self.regexps_ += 1
        var regexp = const_regexp
        if not self.topwrapper_.empty():
            regexp = StringPrintf(self.topwrapper_.c_str(), regexp.c_str())
        if GetFlag(FLAGS_show_regexps):
            print(regexp, end="\r")
            stdout.flush()
        if LOGGING:
            if self.randomstrings_:
                LOG("ERROR", "Cannot log with random strings.")
            if self.regexps_ == 1:  # first
                print("strings")
                self.strgen_.Reset()
                while self.strgen_.HasNext():
                    print(escape(self.strgen_.Next()))
                print("regexps")
            print(escape(regexp))
            var re = RE2(regexp)
            var longest = RE2.Options()
            longest.set_longest_match(True)
            var relongest = RE2(regexp, longest)
            var ngroup = re.NumberOfCapturingGroups() + 1
            var group = Array[StringPiece](ngroup)
            self.strgen_.Reset()
            while self.strgen_.HasNext():
                var input = self.strgen_.Next()
                PrintResult(re, input, RE2.ANCHOR_BOTH, group, ngroup)
                print(";", end="")
                PrintResult(re, input, RE2.UNANCHORED, group, ngroup)
                print(";", end="")
                PrintResult(relongest, input, RE2.ANCHOR_BOTH, group, ngroup)
                print(";", end="")
                PrintResult(relongest, input, RE2.UNANCHORED, group, ngroup)
                print()
            return
        var tester = Tester(regexp)
        if tester.error():
            return
        self.strgen_.Reset()
        self.strgen_.GenerateNULL()
        if self.randomstrings_:
            self.strgen_.Random(self.stringseed_, self.stringcount_)
        var bad_inputs = 0
        while self.strgen_.HasNext():
            self.tests_ += 1
            if not tester.TestInput(self.strgen_.Next()):
                self.failures_ += 1
                bad_inputs += 1
                if bad_inputs >= GetFlag(FLAGS_max_bad_regexp_inputs):
                    break

    def RandomStrings(inout self, seed: Int32, count: Int32):
        self.randomstrings_ = True
        self.stringseed_ = seed
        self.stringcount_ = count

def ExhaustiveTest(maxatoms: Int, maxops: Int,
                  alphabet: List[String], ops: List[String],
                  maxstrlen: Int, stralphabet: List[String],
                  wrapper: String, topwrapper: String):
    if RE2_DEBUG_MODE:
        if maxatoms > 1:
            maxatoms -= 1
        if maxops > 1:
            maxops -= 1
        if maxstrlen > 1:
            maxstrlen -= 1
    var t = ExhaustiveTester(maxatoms, maxops, alphabet, ops,
                             maxstrlen, stralphabet, wrapper,
                             topwrapper)
    t.Generate()
    if not LOGGING:
        print(f"{t.regexps()} regexps, {t.tests()} tests, {t.failures()} failures [{maxstrlen}/{len(stralphabet)} str]")
    EXPECT_EQ(0, t.failures())

def EgrepTest(maxatoms: Int, maxops: Int, alphabet: String,
             maxstrlen: Int, stralphabet: String,
             wrapper: String):
    var tops = List[String]("", "^(?:%s)", "(?:%s)$", "^(?:%s)$")
    for i in range(arraysize(tops)):
        ExhaustiveTest(maxatoms, maxops,
                       Split("", alphabet),
                       RegexpGenerator.EgrepOps(),
                       maxstrlen,
                       Split("", stralphabet),
                       wrapper,
                       tops[i])