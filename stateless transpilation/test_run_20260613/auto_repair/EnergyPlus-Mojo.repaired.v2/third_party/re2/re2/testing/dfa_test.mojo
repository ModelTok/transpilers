from regexp_generator import RegexpGenerator
from string_generator import StringGenerator
from third_party.re2.re2.prog import Prog
from third_party.re2.re2.re2 import RE2
from third_party.re2.re2.regexp import Regexp
from third_party.re2.util.test import Test
from third_party.re2.util.flags import Flags
from third_party.re2.util.logging import Logging
from third_party.re2.util.malloc_counter import MallocCounter
from third_party.re2.util.strutil import StrUtil
from regexp_generator import RegexpGenerator
from string_generator import StringGenerator
from sys import int_type as int64_t
from sys import uint_type as uint64_t
from sys import size_t
from sys import pointer as NULL
from sys import addressof as address_of
from string import String as string
from string import StringPiece
from thread import Thread as thread
from vector import DynamicVector as vector
from util.hooks import hooks

static bool UsingMallocCounter = False

def DEFINE_FLAG(int, size, 8, "log2(number of DFA nodes)")
def DEFINE_FLAG(int, repeat, 2, "Repetition count.")
def DEFINE_FLAG(int, threads, 4, "number of threads")

namespace re2:

static var state_cache_resets: int = 0
static var search_failures: int = 0

struct SetHooks:
  def __init__(inout self):
    hooks.SetDFAStateCacheResetHook(lambda (hooks.DFAStateCacheReset): state_cache_resets = state_cache_resets + 1)
    hooks.SetDFASearchFailureHook(lambda (hooks.DFASearchFailure): search_failures = search_failures + 1)

var set_hooks = SetHooks()

static def DoBuild(prog: Prog):
  ASSERT_TRUE(prog.BuildEntireDFA(Prog.kFirstMatch, NULL))

TEST(Multithreaded, BuildEntireDFA):
  var s: string = "a"
  for i in range(0, GetFlag(FLAGS_size)):
    s = s + "[ab]"
  s = s + "b"
  var re: Regexp = Regexp.Parse(s, Regexp.LikePerl, NULL)
  ASSERT_TRUE(re != NULL)
  {
    var prog: Prog = re.CompileToProg(0)
    ASSERT_TRUE(prog != NULL)
    var t: thread = thread(DoBuild, prog)
    t.join()
    delete prog
  }
  for i in range(0, GetFlag(FLAGS_repeat)):
    var prog: Prog = re.CompileToProg(0)
    ASSERT_TRUE(prog != NULL)
    var threads: vector[thread]
    for j in range(0, GetFlag(FLAGS_threads)):
      threads.emplace_back(DoBuild, prog)
    for j in range(0, GetFlag(FLAGS_threads)):
      threads[j].join()
    prog.BuildEntireDFA(Prog.kFirstMatch, NULL)
    delete prog
  re.Decref()

TEST(SingleThreaded, BuildEntireDFA):
  var re: Regexp = Regexp.Parse("a[ab]{30}b", Regexp.LikePerl, NULL)
  ASSERT_TRUE(re != NULL)
  for i in range(17, 24):
    var limit: int64_t = int64_t{1}<<i
    var usage: int64_t
    {
      var m: testing.MallocCounter = testing.MallocCounter(testing.MallocCounter.THIS_THREAD_ONLY)
      var prog: Prog = re.CompileToProg(limit)
      ASSERT_TRUE(prog != NULL)
      prog.BuildEntireDFA(Prog.kFirstMatch, NULL)
      prog.BuildEntireDFA(Prog.kLongestMatch, NULL)
      usage = m.HeapGrowth()
      delete prog
    }
    if UsingMallocCounter:
      ASSERT_GT(usage, limit*9/10)
      ASSERT_LT(usage, limit*11/10)
  re.Decref()

TEST(SingleThreaded, SearchDFA):
  Prog.TESTING_ONLY_set_dfa_should_bail_when_slow(False)
  state_cache_resets = 0
  search_failures = 0
  const var n: int = 18
  var re: Regexp = Regexp.Parse(StringPrintf("0[01]{%d}$", n), Regexp.LikePerl, NULL)
  ASSERT_TRUE(re != NULL)
  var no_match: string = DeBruijnString(n)
  var match: string = no_match + "0"
  var usage: int64_t
  var peak_usage: int64_t
  {
    var m: testing.MallocCounter = testing.MallocCounter(testing.MallocCounter.THIS_THREAD_ONLY)
    var prog: Prog = re.CompileToProg(1<<n)
    ASSERT_TRUE(prog != NULL)
    for i in range(0, 10):
      var matched: bool = False
      var failed: bool = False
      matched = prog.SearchDFA(match, StringPiece(), Prog.kUnanchored, Prog.kFirstMatch, NULL, &failed, NULL)
      ASSERT_FALSE(failed)
      ASSERT_TRUE(matched)
      matched = prog.SearchDFA(no_match, StringPiece(), Prog.kUnanchored, Prog.kFirstMatch, NULL, &failed, NULL)
      ASSERT_FALSE(failed)
      ASSERT_FALSE(matched)
    usage = m.HeapGrowth()
    peak_usage = m.PeakHeapGrowth()
    delete prog
  }
  if UsingMallocCounter:
    ASSERT_LT(usage, 1<<n)
    ASSERT_LT(peak_usage, 1<<n)
  re.Decref()
  Prog.TESTING_ONLY_set_dfa_should_bail_when_slow(True)
  ASSERT_GT(state_cache_resets, 0)
  ASSERT_EQ(search_failures, 0)

static def DoSearch(prog: Prog, match: StringPiece, no_match: StringPiece):
  for i in range(0, 2):
    var matched: bool = False
    var failed: bool = False
    matched = prog.SearchDFA(match, StringPiece(), Prog.kUnanchored, Prog.kFirstMatch, NULL, &failed, NULL)
    ASSERT_FALSE(failed)
    ASSERT_TRUE(matched)
    matched = prog.SearchDFA(no_match, StringPiece(), Prog.kUnanchored, Prog.kFirstMatch, NULL, &failed, NULL)
    ASSERT_FALSE(failed)
    ASSERT_FALSE(matched)

TEST(Multithreaded, SearchDFA):
  Prog.TESTING_ONLY_set_dfa_should_bail_when_slow(False)
  state_cache_resets = 0
  search_failures = 0
  const var n: int = 18
  var re: Regexp = Regexp.Parse(StringPrintf("0[01]{%d}$", n), Regexp.LikePerl, NULL)
  ASSERT_TRUE(re != NULL)
  var no_match: string = DeBruijnString(n)
  var match: string = no_match + "0"
  {
    var prog: Prog = re.CompileToProg(1<<n)
    ASSERT_TRUE(prog != NULL)
    var t: thread = thread(DoSearch, prog, match, no_match)
    t.join()
    delete prog
  }
  for i in range(0, GetFlag(FLAGS_repeat)):
    var prog: Prog = re.CompileToProg(1<<n)
    ASSERT_TRUE(prog != NULL)
    var threads: vector[thread]
    for j in range(0, GetFlag(FLAGS_threads)):
      threads.emplace_back(DoSearch, prog, match, no_match)
    for j in range(0, GetFlag(FLAGS_threads)):
      threads[j].join()
    delete prog
  re.Decref()
  Prog.TESTING_ONLY_set_dfa_should_bail_when_slow(True)
  ASSERT_GT(state_cache_resets, 0)
  ASSERT_EQ(search_failures, 0)

struct ReverseTest:
  var regexp: pointer[char8]
  var text: pointer[char8]
  var match: bool

var reverse_tests: StaticArray[ReverseTest, 4] = [
  ReverseTest { "\\A(a|b)", "abc", True },
  ReverseTest { "(a|b)\\z", "cba", True },
  ReverseTest { "\\A(a|b)", "cba", False },
  ReverseTest { "(a|b)\\z", "abc", False },
]

TEST(DFA, ReverseMatch):
  var nfail: int = 0
  for i in range(0, arraysize(reverse_tests)):
    var t: ReverseTest = reverse_tests[i]
    var re: Regexp = Regexp.Parse(t.regexp, Regexp.LikePerl, NULL)
    ASSERT_TRUE(re != NULL)
    var prog: Prog = re.CompileToReverseProg(0)
    ASSERT_TRUE(prog != NULL)
    var failed: bool = False
    var matched: bool = prog.SearchDFA(t.text, StringPiece(), Prog.kUnanchored, Prog.kFirstMatch, NULL, &failed, NULL)
    if matched != t.match:
      LOG(ERROR) << t.regexp << " on " << t.text << ": want " << t.match
      nfail += 1
    delete prog
    re.Decref()
  EXPECT_EQ(nfail, 0)

struct CallbackTest:
  var regexp: pointer[char8]
  var dump: pointer[char8]

var callback_tests: StaticArray[CallbackTest, 10] = [
  CallbackTest { "\\Aa\\z", "[-1,1,-1] [-1,-1,2] [[-1,-1,-1]]" },
  CallbackTest { "\\Aab\\z", "[-1,1,-1,-1] [-1,-1,2,-1] [-1,-1,-1,3] [[-1,-1,-1,-1]]" },
  CallbackTest { "\\Aa*b\\z", "[-1,0,1,-1] [-1,-1,-1,2] [[-1,-1,-1,-1]]" },
  CallbackTest { "\\Aa+b\\z", "[-1,1,-1,-1] [-1,1,2,-1] [-1,-1,-1,3] [[-1,-1,-1,-1]]" },
  CallbackTest { "\\Aa?b\\z", "[-1,1,2,-1] [-1,-1,2,-1] [-1,-1,-1,3] [[-1,-1,-1,-1]]" },
  CallbackTest { "\\Aa\\C*\\z", "[-1,1,-1] [1,1,2] [[-1,-1,-1]]" },
  CallbackTest { "\\Aa\\C*", "[-1,1,-1] [2,2,3] [[2,2,2]] [[-1,-1,-1]]" },
  CallbackTest { "a\\C*", "[0,1,-1] [2,2,3] [[2,2,2]] [[-1,-1,-1]]" },
  CallbackTest { "\\C*", "[1,2] [[1,1]] [[-1,-1]]" },
  CallbackTest { "a", "[0,1,-1] [2,2,2] [[-1,-1,-1]]"},
]

TEST(DFA, Callback):
  var nfail: int = 0
  for i in range(0, arraysize(callback_tests)):
    var t: CallbackTest = callback_tests[i]
    var re: Regexp = Regexp.Parse(t.regexp, Regexp.LikePerl, NULL)
    ASSERT_TRUE(re != NULL)
    var prog: Prog = re.CompileToProg(0)
    ASSERT_TRUE(prog != NULL)
    var dump: string = ""
    prog.BuildEntireDFA(Prog.kLongestMatch, lambda (next: pointer[int], match: bool):
      ASSERT_TRUE(next != NULL)
      if not dump.empty():
        dump = dump + " "
      if match:
        dump = dump + "[["
      else:
        dump = dump + "["
      for b in range(0, prog.bytemap_range() + 1):
        dump = dump + StringPrintf("%d,", next[b])
      dump.pop_back()
      if match:
        dump = dump + "]]"
      else:
        dump = dump + "]"
    )
    if dump != t.dump:
      LOG(ERROR) << t.regexp << " bytemap:\n" << prog.DumpByteMap()
      LOG(ERROR) << t.regexp << " dump:\ngot " << dump << "\nwant " << t.dump
      nfail += 1
    delete prog
    re.Decref()
  EXPECT_EQ(nfail, 0)