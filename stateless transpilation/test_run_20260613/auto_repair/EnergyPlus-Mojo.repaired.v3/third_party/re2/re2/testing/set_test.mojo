from . import RE2

# namespace re2 {

def Set_Unanchored():
    let s = RE2.Set(RE2.DefaultOptions, RE2.UNANCHORED)
    assert s.Add("foo", None) == 0
    assert s.Add("(", None) == -1
    assert s.Add("bar", None) == 1
    assert s.Compile() == True
    assert s.Match("foobar", None) == True
    assert s.Match("fooba", None) == True
    assert s.Match("oobar", None) == True
    var v = List[Int]()
    assert s.Match("foobar", v) == True
    assert len(v) == 2
    assert v[0] == 0
    assert v[1] == 1
    assert s.Match("fooba", v) == True
    assert len(v) == 1
    assert v[0] == 0
    assert s.Match("oobar", v) == True
    assert len(v) == 1
    assert v[0] == 1

def Set_UnanchoredFactored():
    let s = RE2.Set(RE2.DefaultOptions, RE2.UNANCHORED)
    assert s.Add("foo", None) == 0
    assert s.Add("(", None) == -1
    assert s.Add("foobar", None) == 1
    assert s.Compile() == True
    assert s.Match("foobar", None) == True
    assert s.Match("obarfoobaroo", None) == True
    assert s.Match("fooba", None) == True
    assert s.Match("oobar", None) == False
    var v = List[Int]()
    assert s.Match("foobar", v) == True
    assert len(v) == 2
    assert v[0] == 0
    assert v[1] == 1
    assert s.Match("obarfoobaroo", v) == True
    assert len(v) == 2
    assert v[0] == 0
    assert v[1] == 1
    assert s.Match("fooba", v) == True
    assert len(v) == 1
    assert v[0] == 0
    assert s.Match("oobar", v) == False
    assert len(v) == 0

def Set_UnanchoredDollar():
    let s = RE2.Set(RE2.DefaultOptions, RE2.UNANCHORED)
    assert s.Add("foo$", None) == 0
    assert s.Compile() == True
    assert s.Match("foo", None) == True
    assert s.Match("foobar", None) == False
    var v = List[Int]()
    assert s.Match("foo", v) == True
    assert len(v) == 1
    assert v[0] == 0
    assert s.Match("foobar", v) == False
    assert len(v) == 0

def Set_UnanchoredWordBoundary():
    let s = RE2.Set(RE2.DefaultOptions, RE2.UNANCHORED)
    assert s.Add("foo\\b", None) == 0
    assert s.Compile() == True
    assert s.Match("foo", None) == True
    assert s.Match("foobar", None) == False
    assert s.Match("foo bar", None) == True
    var v = List[Int]()
    assert s.Match("foo", v) == True
    assert len(v) == 1
    assert v[0] == 0
    assert s.Match("foobar", v) == False
    assert len(v) == 0
    assert s.Match("foo bar", v) == True
    assert len(v) == 1
    assert v[0] == 0

def Set_Anchored():
    let s = RE2.Set(RE2.DefaultOptions, RE2.ANCHOR_BOTH)
    assert s.Add("foo", None) == 0
    assert s.Add("(", None) == -1
    assert s.Add("bar", None) == 1
    assert s.Compile() == True
    assert s.Match("foobar", None) == False
    assert s.Match("fooba", None) == False
    assert s.Match("oobar", None) == False
    assert s.Match("foo", None) == True
    assert s.Match("bar", None) == True
    var v = List[Int]()
    assert s.Match("foobar", v) == False
    assert len(v) == 0
    assert s.Match("fooba", v) == False
    assert len(v) == 0
    assert s.Match("oobar", v) == False
    assert len(v) == 0
    assert s.Match("foo", v) == True
    assert len(v) == 1
    assert v[0] == 0
    assert s.Match("bar", v) == True
    assert len(v) == 1
    assert v[0] == 1

def Set_EmptyUnanchored():
    let s = RE2.Set(RE2.DefaultOptions, RE2.UNANCHORED)
    assert s.Compile() == True
    assert s.Match("", None) == False
    assert s.Match("foobar", None) == False
    var v = List[Int]()
    assert s.Match("", v) == False
    assert len(v) == 0
    assert s.Match("foobar", v) == False
    assert len(v) == 0

def Set_EmptyAnchored():
    let s = RE2.Set(RE2.DefaultOptions, RE2.ANCHOR_BOTH)
    assert s.Compile() == True
    assert s.Match("", None) == False
    assert s.Match("foobar", None) == False
    var v = List[Int]()
    assert s.Match("", v) == False
    assert len(v) == 0
    assert s.Match("foobar", v) == False
    assert len(v) == 0

def Set_Prefix():
    let s = RE2.Set(RE2.DefaultOptions, RE2.ANCHOR_BOTH)
    assert s.Add("/prefix/\\d*", None) == 0
    assert s.Compile() == True
    assert s.Match("/prefix", None) == False
    assert s.Match("/prefix/", None) == True
    assert s.Match("/prefix/42", None) == True
    var v = List[Int]()
    assert s.Match("/prefix", v) == False
    assert len(v) == 0
    assert s.Match("/prefix/", v) == True
    assert len(v) == 1
    assert v[0] == 0
    assert s.Match("/prefix/42", v) == True
    assert len(v) == 1
    assert v[0] == 0

def Set_MoveSemantics():
    let s1 = RE2.Set(RE2.DefaultOptions, RE2.UNANCHORED)
    assert s1.Add("foo\\d+", None) == 0
    assert s1.Compile() == True
    assert s1.Match("abc foo1 xyz", None) == True
    assert s1.Match("abc bar2 xyz", None) == False
    var s2 = s1
    assert s2.Match("abc foo1 xyz", None) == True
    assert s2.Match("abc bar2 xyz", None) == False
    assert s1.Add("bar\\d+", None) == 0
    assert s1.Compile() == True
    assert s1.Match("abc foo1 xyz", None) == False
    assert s1.Match("abc bar2 xyz", None) == True
    s1 = s2
    assert s1.Match("abc foo1 xyz", None) == True
    assert s1.Match("abc bar2 xyz", None) == False

# }  // namespace re2