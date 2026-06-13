from util.test import TEST
from exhaustive_tester import ExhaustiveTest, RegexpGenerator, Split, Explode

def TEST_EmptyString_Exhaustive():
    ExhaustiveTest(2, 2, Split(" ", "(?:) a"),
                   RegexpGenerator.EgrepOps(),
                   5, Split("", "ab"), "", "")

def TEST_Punctuation_Literals():
    var alphabet: List[String] = Explode("()*+?{}[]\\^$.")
    var escaped: List[String] = alphabet
    for i in range(len(escaped)):
        escaped[i] = "\\" + escaped[i]
    ExhaustiveTest(1, 1, escaped, RegexpGenerator.EgrepOps(),
                   2, alphabet, "", "")

def TEST_LineEnds_Exhaustive():
    ExhaustiveTest(2, 2, Split(" ", "(?:^) (?:$) . a \\n (?:\\A) (?:\\z)"),
                   RegexpGenerator.EgrepOps(),
                   4, Explode("ab\n"), "", "")