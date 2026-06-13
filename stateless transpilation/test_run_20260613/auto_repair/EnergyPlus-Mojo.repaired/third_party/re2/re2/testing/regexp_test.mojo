from re2.regexp import Regexp, RegexpStatus
from std import Map, String, List

# namespace re2

def TEST_Regexp_BigRef():
    var re: Regexp
    re = Regexp.Parse("x", Regexp.NoParseFlags, None)
    for i in range(100000):
        re.Incref()
    for i in range(100000):
        re.Decref()
    assert re.Ref() == 1
    re.Decref()

def TEST_Regexp_BigConcat():
    var x: Regexp
    x = Regexp.Parse("x", Regexp.NoParseFlags, None)
    var v = List[Regexp](90000, x)  # ToString bails out at 100000
    for i in range(v.size):
        x.Incref()
    assert x.Ref() == 1 + v.size, f"{x.Ref()}"
    var re: Regexp = Regexp.Concat(v.data(), v.size, Regexp.NoParseFlags)
    assert re.ToString() == String('x') * v.size
    re.Decref()
    assert x.Ref() == 1, f"{x.Ref()}"
    x.Decref()

def TEST_Regexp_NamedCaptures():
    var x: Regexp
    var status: RegexpStatus
    x = Regexp.Parse(
        "(?P<g1>a+)|(e)(?P<g2>w*)+(?P<g1>b+)", Regexp.PerlX, &status)
    assert status.ok()
    assert x.NumCaptures() == 4
    var have: Map[String, Int] = x.NamedCaptures()
    assert have != None
    assert have.size() == 2  # there are only two named groups in
    var want = Map[String, Int]()
    want["g1"] = 1
    want["g2"] = 3
    assert want == have
    x.Decref()
    del have

def TEST_Regexp_CaptureNames():
    var x: Regexp
    var status: RegexpStatus
    x = Regexp.Parse(
        "(?P<g1>a+)|(e)(?P<g2>w*)+(?P<g1>b+)", Regexp.PerlX, &status)
    assert status.ok()
    assert x.NumCaptures() == 4
    var have: Map[Int, String] = x.CaptureNames()
    assert have != None
    assert have.size() == 3
    var want = Map[Int, String]()
    want[1] = "g1"
    want[3] = "g2"
    want[4] = "g1"
    assert want == have
    x.Decref()
    del have