from util.test import TEST
from util.utf import UTFmax, runetochar, Rune, Runemax
from exhaustive_tester import ExhaustiveTest, Split, Explode, RegexpGenerator
from memory import Pointer
from string import String
from vector import DynamicVector

def UTF8(r: Rune) -> String:
    var buf = Pointer[UInt8].alloc(UTFmax + 1)
    var len = runetochar(buf, r)
    buf[len] = 0
    var result = String(buf.bitcast[Int8](), len)
    buf.free()
    return result

def InterestingUTF8() -> DynamicVector[String]:
    var init = False
    var v = DynamicVector[String]()
    if init:
        return v
    init = True
    for i in range(1, 256):
        v.push_back(UTF8(i))
    for j in range(0, 8):
        v.push_back(UTF8(256 + j))
    var i = 512
    while i < Runemax:
        for j in range(-8, 8):
            v.push_back(UTF8(i + j))
        i <<= 1
    for j in range(-8, 1):
        v.push_back(UTF8(Runemax + j))
    return v

@TEST
def CharacterClasses_Exhaustive():
    var atoms = Split(" ",
        "[a] [b] [ab] [^bc] [b-d] [^b-d] []a] [-a] [a-] [^-a] [a-b-c] a b .")
    ExhaustiveTest(2, 1, atoms, RegexpGenerator.EgrepOps(),
                   5, Explode("ab"), "", "")

@TEST
def CharacterClasses_ExhaustiveAB():
    var atoms = Split(" ",
        "[a] [b] [ab] [^bc] [b-d] [^b-d] []a] [-a] [a-] [^-a] [a-b-c] a b .")
    ExhaustiveTest(2, 1, atoms, RegexpGenerator.EgrepOps(),
                   5, Explode("ab"), "a%sb", "")

@TEST
def InterestingUTF8_SingleOps():
    var atoms = Split(" ",
        ". ^ $ \\a \\f \\n \\r \\t \\v \\d \\D \\s \\S \\w \\W \\b \\B "
        "[[:alnum:]] [[:alpha:]] [[:blank:]] [[:cntrl:]] [[:digit:]] "
        "[[:graph:]] [[:lower:]] [[:print:]] [[:punct:]] [[:space:]] "
        "[[:upper:]] [[:xdigit:]] [\\s\\S] [\\d\\D] [^\\w\\W] [^\\d\\D]")
    var ops = DynamicVector[String]()  # no ops
    ExhaustiveTest(1, 0, atoms, ops,
                   1, InterestingUTF8(), "", "")

@TEST
def InterestingUTF8_AB():
    var atoms = Split(" ",
        ". ^ $ \\a \\f \\n \\r \\t \\v \\d \\D \\s \\S \\w \\W \\b \\B "
        "[[:alnum:]] [[:alpha:]] [[:blank:]] [[:cntrl:]] [[:digit:]] "
        "[[:graph:]] [[:lower:]] [[:print:]] [[:punct:]] [[:space:]] "
        "[[:upper:]] [[:xdigit:]] [\\s\\S] [\\d\\D] [^\\w\\W] [^\\d\\D]")
    var ops = DynamicVector[String]()  # no ops
    var alpha = InterestingUTF8()
    for i in range(alpha.size):
        alpha[i] = "a" + alpha[i] + "b"
    ExhaustiveTest(1, 0, atoms, ops,
                   1, alpha, "a%sb", "")