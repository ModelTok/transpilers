from util.test import TEST
from exhaustive_tester import ExhaustiveTest, Split, Explode

def test_Repetition_Simple():
    var ops: List[String] = Split(" ",
        "%s{0} %s{0,} %s{1} %s{1,} %s{0,1} %s{0,2} "
        "%s{1,2} %s{2} %s{2,} %s{3,4} %s{4,5} "
        "%s* %s+ %s? %s*? %s+? %s??")
    ExhaustiveTest(3, 2, Explode("abc."), ops,
                   6, Explode("ab"), "(?:%s)", "")
    ExhaustiveTest(3, 2, Explode("abc."), ops,
                   40, Explode("a"), "(?:%s)", "")

def test_Repetition_Capturing():
    var ops: List[String] = Split(" ",
        "%s{0} %s{0,} %s{1} %s{1,} %s{0,1} %s{0,2} "
        "%s{1,2} %s{2} %s{2,} %s{3,4} %s{4,5} "
        "%s* %s+ %s? %s*? %s+? %s??")
    ExhaustiveTest(3, 2, Split(" ", "a (a) b"), ops,
                   7, Explode("ab"), "(?:%s)", "")
    ExhaustiveTest(3, 2, Split(" ", "a (a)"), ops,
                   50, Explode("a"), "(?:%s)", "")