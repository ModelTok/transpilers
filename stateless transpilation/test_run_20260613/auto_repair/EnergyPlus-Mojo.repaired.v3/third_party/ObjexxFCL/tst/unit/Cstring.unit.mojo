from ...Cstring import Cstring
from builtins import str, len

# helper to mimic strlen on Cstring (implicit conversion to const char*)
def cstrlen(s: Cstring) -> Int:
    return len(str(s))

def Construction():
    # Default constructor and assignment
    var s = Cstring()
    assert(s.empty(), "s empty")
    assert(s.length() == 0, "s length 0")
    assert(s.size() == 0, "s size 0")
    assert(cstrlen(s) == 0, "cstrlen(s) 0")
    s = "Dog"
    assert(s == "Dog", "s == Dog")
    assert(s != "Cat", "s != Cat")
    assert(String("Dog") == s, "String(Dog) == s")
    assert(s.length() == 3, "s length 3")
    assert(cstrlen(s) == 3, "cstrlen(s) 3")

    # C string and Copy constructors and assignment
    var s2 = Cstring("Fish")
    var t = Cstring(s2)
    assert(s2 == "Fish", "s2 == Fish")
    assert(s2 == t, "s2 == t")
    assert(t == s2, "t == s2")
    s2 = "Hook"
    t = s2
    assert(s2 == "Hook", "s2 == Hook")
    assert(s2 == t, "s2 == t")
    assert(t == s2, "t == s2")
    var u = Cstring(s2, 3)
    assert(u == "Hoo", "u == Hoo")
    assert(u.length() == 3, "u length 3")

    # string constructors and assignment
    var s3 = Cstring(String("Fish"))
    assert(s3 == "Fish", "s3 == Fish")
    s3 = String("Freshwater")
    assert(s3 == "Freshwater", "s3 == Freshwater")
    assert(not s3.empty(), "s3 not empty")
    assert(not s3.is_blank(), "s3 not blank")
    assert(s3.not_blank(), "s3 not_blank")
    assert(s3.has('t'), "s3 has 't'")
    assert(not s3.has('T'), "s3 not has 'T'")

    # char constructors and assignment
    var s4 = Cstring('x')
    assert(s4 == 'x', "s4 == 'x'")
    s4 = 'z'
    assert(s4 == 'z', "s4 == 'z'")

    # Length constructors and assignment
    var s5 = Cstring(5)
    assert(s5.length() == 5, "s5 length 5")
    assert(s5 == "     ", "s5 == 5 spaces")
    assert(s5.is_blank(), "s5 is_blank")
    assert(not s5.not_blank(), "s5 not not_blank")

def Assignment():
    var s = Cstring("Fish")
    assert(s == "Fish", "s == Fish")
    s = "Cat"
    assert(s == "Cat", "s == Cat")
    assert(s + "Fish" == "CatFish", "s + Fish")
    s += "Fish"
    assert(s == "CatFish", "s after += Fish")

def CaseChange():
    var s = Cstring("Fish")
    s.lowercase()
    assert(s == "fish", "s lowercase == fish")
    s.uppercase()
    assert(s == "FISH", "s uppercase == FISH")
    assert(equali(s, "fiSh"), "equali(s, fiSh)")
    assert(s.lowercased() == "fish", "s.lowercased() == fish")
    assert(s.uppercased() == "FISH", "s.uppercased() == FISH")

def JustifyTrim():
    var s = Cstring("  Fish ")
    assert(s.len_trim() == 6, "s.len_trim() == 6")
    s.ljustify()
    assert(s == "Fish   ", "s ljustify == Fish   ")
    s.rjustify()
    assert(s == "   Fish", "s rjustify ==    Fish")
    s.ljustify()
    assert(s.rjustified() == "   Fish", "s.rjustified() ==    Fish")
    s = "Bozo \t "
    assert(s.len_trim() == 6, "s.len_trim() == 6")
    assert(s.trimmed() == "Bozo \t", "s.trimmed() == Bozo \\t")
    assert(s == "Bozo", "s == Bozo")

def Centering():
    var s = Cstring("Fish  ")
    assert(s.centered() == " Fish ", "s.centered() ==  Fish ")
    var centered = s.center()
    assert(centered == " Fish ", "s.center() return ==  Fish ")
    assert(s == " Fish ", "s after center ==  Fish ")
    s = "   Dog "
    assert(s.centered() == "  Dog  ", "s.centered() ==   Dog  ")
    var centered2 = s.center()
    assert(centered2 == "  Dog  ", "s.center() return ==   Dog  ")
    assert(s == "  Dog  ", "s after center ==   Dog  ")

def Subscripting():
    var s = Cstring("Cat")
    assert(s[0] == 'C', "s[0] == C")
    assert(s[1] == 'a', "s[1] == a")
    assert(s[2] == 't', "s[2] == t")
    s[0] = 'B'
    assert(s == "Bat", "s after subscript assign == Bat")

def Concatenation():
    var s = Cstring("Cat")
    var t = Cstring("Fish")
    assert(s + t == "CatFish", "s + t == CatFish")
    s += t
    assert(s == "CatFish", "s += t == CatFish")
    s += 'X'
    assert(s == "CatFishX", "s += 'X' == CatFishX")
    s += String("Ray")
    assert(s == "CatFishXRay", "s += String(Ray) == CatFishXRay")

def main():
    Construction()
    Assignment()
    CaseChange()
    JustifyTrim()
    Centering()
    Subscripting()
    Concatenation()