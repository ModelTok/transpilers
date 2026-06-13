from ...util.utf import Rune, Runemax
from ...regexp import CharClass, CharClassBuilder

struct CCTest:
    var add: List[(Rune, Rune)]
    var remove: Int
    var final: List[(Rune, Rune)]

var tests: List[CCTest] = [
    CCTest(add=[(10, 20), (-1, -1)], remove=-1, final=[(10, 20), (-1, -1)]),
    CCTest(add=[(10, 20), (20, 30), (-1, -1)], remove=-1, final=[(10, 30), (-1, -1)]),
    CCTest(add=[(10, 20), (30, 40), (20, 30), (-1, -1)], remove=-1, final=[(10, 40), (-1, -1)]),
    CCTest(add=[(0, 50), (20, 30), (-1, -1)], remove=-1, final=[(0, 50), (-1, -1)]),
    CCTest(add=[(10, 11), (13, 14), (16, 17), (19, 20), (22, 23), (-1, -1)], remove=-1, final=[(10, 11), (13, 14), (16, 17), (19, 20), (22, 23), (-1, -1)]),
    CCTest(add=[(13, 14), (10, 11), (22, 23), (19, 20), (16, 17), (-1, -1)], remove=-1, final=[(10, 11), (13, 14), (16, 17), (19, 20), (22, 23), (-1, -1)]),
    CCTest(add=[(13, 14), (10, 11), (22, 23), (19, 20), (16, 17), (-1, -1)], remove=-1, final=[(10, 11), (13, 14), (16, 17), (19, 20), (22, 23), (-1, -1)]),
    CCTest(add=[(13, 14), (10, 11), (22, 23), (19, 20), (16, 17), (5, 25), (-1, -1)], remove=-1, final=[(5, 25), (-1, -1)]),
    CCTest(add=[(13, 14), (10, 11), (22, 23), (19, 20), (16, 17), (12, 21), (-1, -1)], remove=-1, final=[(10, 23), (-1, -1)]),
    CCTest(add=[(0, Runemax), (-1, -1)], remove=-1, final=[(0, Runemax), (-1, -1)]),
    CCTest(add=[(0, 50), (-1, -1)], remove=-1, final=[(0, 50), (-1, -1)]),
    CCTest(add=[(50, Runemax), (-1, -1)], remove=-1, final=[(50, Runemax), (-1, -1)]),
    CCTest(add=[(50, Runemax), (-1, -1)], remove=255, final=[(50, 255), (-1, -1)]),
    CCTest(add=[(50, Runemax), (-1, -1)], remove=65535, final=[(50, 65535), (-1, -1)]),
    CCTest(add=[(50, Runemax), (-1, -1)], remove=Runemax, final=[(50, Runemax), (-1, -1)]),
    CCTest(add=[(50, 60), (250, 260), (350, 360), (-1, -1)], remove=255, final=[(50, 60), (250, 255), (-1, -1)]),
    CCTest(add=[(50, 60), (-1, -1)], remove=255, final=[(50, 60), (-1, -1)]),
    CCTest(add=[(350, 360), (-1, -1)], remove=255, final=[(-1, -1)]),
    CCTest(add=[(-1, -1)], remove=255, final=[(-1, -1)]),
]

def arraysize[AnyType](arr: List[AnyType]) -> Int:
    return len(arr)

def Broke[CharClass: AnyType](desc: String, t: CCTest, cc: CharClass):
    if t is None:
        print(f"\t{desc}:")
    else:
        print()
        print(f"CharClass added: [{desc}]")
        var k: Int = 0
        while k < len(t.add) and t.add[k].lo >= 0:
            print(f" {t.add[k].lo}-{t.add[k].hi}")
            k += 1
        print()
        if t.remove >= 0:
            print(f"Removed > {t.remove}")
        print("\twant:")
        k = 0
        while k < len(t.final) and t.final[k].lo >= 0:
            print(f" {t.final[k].lo}-{t.final[k].hi}")
            k += 1
        print()
        print("\thave:")
    var it = cc.begin()
    while it != cc.end():
        print(f" {it.lo}-{it.hi}")
        it = it.next()
    print()

def ShouldContain(t: CCTest, x: Int) -> Bool:
    var j: Int = 0
    while j < len(t.final) and t.final[j].lo >= 0:
        if t.final[j].lo <= x and x <= t.final[j].hi:
            return True
        j += 1
    return False

def Negate(cc: CharClass) -> CharClass:
    return cc.Negate()

def Delete(cc: CharClass):
    cc.Delete()

def Negate(cc: CharClassBuilder) -> CharClassBuilder:
    var ncc: CharClassBuilder = cc.Copy()
    ncc.Negate()
    return ncc

def Delete(cc: CharClassBuilder):
    # delete cc  (no-op in Mojo)

def CorrectCC[CharClass: AnyType](cc: CharClass, t: CCTest, desc: String) -> Bool:
    var it = cc.begin()
    var size: Int = 0
    var j: Int = 0
    while j < len(t.final) and t.final[j].lo >= 0:
        if it == cc.end() or it.lo != t.final[j].lo or it.hi != t.final[j].hi:
            Broke(desc, t, cc)
            return False
        size += it.hi - it.lo + 1
        it = it.next()
        j += 1
    if it != cc.end():
        Broke(desc, t, cc)
        return False
    if cc.size() != size:
        Broke(desc, t, cc)
        print(f"wrong size: want {size} have {cc.size()}")
        return False
    var jj: Int = 0
    while jj < 101:
        if jj == 100:
            jj = Runemax
        if ShouldContain(t, jj) != cc.Contains(jj):
            Broke(desc, t, cc)
            print(f"want contains({jj})={ShouldContain(t, jj)}, got {cc.Contains(jj)}")
            return False
        jj += 1
    var ncc: CharClass = Negate(cc)
    jj = 0
    while jj < 101:
        if jj == 100:
            jj = Runemax
        if ShouldContain(t, jj) == ncc.Contains(jj):
            Broke(desc, t, cc)
            Broke("ncc", None, ncc)
            print(f"want ncc contains({jj})!={ShouldContain(t, jj)}, got {ncc.Contains(jj)}")
            Delete(ncc)
            return False
        if ncc.size() != Runemax + 1 - cc.size():
            Broke(desc, t, cc)
            Broke("ncc", None, ncc)
            print(f"ncc size should be {Runemax + 1 - cc.size()} is {ncc.size()}")
            Delete(ncc)
            return False
        jj += 1
    Delete(ncc)
    return True

def TestCharClassBuilder_Adds():
    var nfail: Int = 0
    var i: Int = 0
    while i < arraysize(tests):
        var ccb: CharClassBuilder = CharClassBuilder()
        var t: CCTest = tests[i]
        var j: Int = 0
        while j < len(t.add) and t.add[j].lo >= 0:
            ccb.AddRange(t.add[j].lo, t.add[j].hi)
            j += 1
        if t.remove >= 0:
            ccb.RemoveAbove(t.remove)
        if not CorrectCC(ccb, t, "before copy (CharClassBuilder)"):
            nfail += 1
        var cc: CharClass = ccb.GetCharClass()
        if not CorrectCC(cc, t, "before copy (CharClass)"):
            nfail += 1
        cc.Delete()
        var ccb1: CharClassBuilder = ccb.Copy()
        if not CorrectCC(ccb1, t, "after copy (CharClassBuilder)"):
            nfail += 1
        cc = ccb.GetCharClass()
        if not CorrectCC(cc, t, "after copy (CharClass)"):
            nfail += 1
        cc.Delete()
        Delete(ccb1)
        i += 1
    # EXPECT_EQ(nfail, 0)
    if nfail != 0:
        print(f"FAIL: nfail = {nfail}")
    else:
        print("PASS")

TestCharClassBuilder_Adds()