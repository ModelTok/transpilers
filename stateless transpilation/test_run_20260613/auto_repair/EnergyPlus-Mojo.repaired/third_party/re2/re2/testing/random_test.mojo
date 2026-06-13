from util.test import TEST, EXPECT_EQ
from util.flags import DEFINE_FLAG, GetFlag
from re2.testing.exhaustive_tester import ExhaustiveTester, RegexpGenerator, Explode, Split

DEFINE_FLAG(int, regexpseed, 404, "Random regexp seed.")
DEFINE_FLAG(int, regexpcount, 100, "How many random regexps to generate.")
DEFINE_FLAG(int, stringseed, 200, "Random string seed.")
DEFINE_FLAG(int, stringcount, 100, "How many random strings to generate.")

def RandomTest(maxatoms: Int, maxops: Int,
              alphabet: List[String],
              ops: List[String],
              maxstrlen: Int,
              stralphabet: List[String],
              wrapper: String):
    if RE2_DEBUG_MODE:
        maxatoms -= 1
        maxops -= 1
        maxstrlen //= 2
    var t = ExhaustiveTester(maxatoms, maxops, alphabet, ops,
                             maxstrlen, stralphabet, wrapper, "")
    t.RandomStrings(GetFlag(FLAGS_stringseed),
                    GetFlag(FLAGS_stringcount))
    t.GenerateRandom(GetFlag(FLAGS_regexpseed),
                     GetFlag(FLAGS_regexpcount))
    printf("%d regexps, %d tests, %d failures [%d/%d str]\n",
           t.regexps(), t.tests(), t.failures(), maxstrlen, len(stralphabet))
    EXPECT_EQ(0, t.failures())

TEST(Random, SmallEgrepLiterals):
    RandomTest(5, 5, Explode("abc."), RegexpGenerator.EgrepOps(),
               15, Explode("abc"),
               "")

TEST(Random, BigEgrepLiterals):
    RandomTest(10, 10, Explode("abc."), RegexpGenerator.EgrepOps(),
               15, Explode("abc"),
               "")

TEST(Random, SmallEgrepCaptures):
    RandomTest(5, 5, Split(" ", "a (b) ."), RegexpGenerator.EgrepOps(),
               15, Explode("abc"),
               "")

TEST(Random, BigEgrepCaptures):
    RandomTest(10, 10, Split(" ", "a (b) ."), RegexpGenerator.EgrepOps(),
               15, Explode("abc"),
               "")

TEST(Random, Complicated):
    var ops = Split(" ",
      "%s%s %s|%s %s* %s*? %s+ %s+? %s? %s?? "
      "%s{0} %s{0,} %s{1} %s{1,} %s{0,1} %s{0,2} %s{1,2} "
      "%s{2} %s{2,} %s{3,4} %s{4,5}")
    var atoms = Split(" ",
      ". (?:^) (?:$) \\a \\f \\n \\r \\t \\v "
      "\\d \\D \\s \\S \\w \\W (?:\\b) (?:\\B) "
      "a (a) b c - \\\\")
    var alphabet = Explode("abc123\001\002\003\t\r\n\v\f\a")
    RandomTest(10, 10, atoms, ops, 20, alphabet, "")