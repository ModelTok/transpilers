from util.test import TEST
from util.logging import LOG
from ..prog import Prog
from ..regexp import Regexp

struct PCRETest:
  var regexp: String
  var should_match: Bool

var tests: List[PCRETest] = List[PCRETest](
  PCRETest("abc", True),
  PCRETest("(a|b)c", True),
  PCRETest("(a*|b)c", True),
  PCRETest("(a|b*)c", True),
  PCRETest("a(b|c)d", True),
  PCRETest("a(()|())c", True),
  PCRETest("ab*c", True),
  PCRETest("ab+c", True),
  PCRETest("a(b*|c*)d", True),
  PCRETest("\\W", True),
  PCRETest("\\W{1,2}", True),
  PCRETest("\\d", True),
  PCRETest("(a*)*", False),
  PCRETest("x(a*)*y", False),
  PCRETest("(a*)+", False),
  PCRETest("(a+)*", True),
  PCRETest("(a+)+", True),
  PCRETest("(a+)+", True),
  PCRETest("\\b", True),
  PCRETest("\\v", False),
  PCRETest("\\d", True),
  PCRETest("\\A", True),
  PCRETest("\\z", True),
  PCRETest("(?m)^", False),
  PCRETest("(?m)$", True),
  PCRETest("(?-m)^", True),
  PCRETest("(?-m)$", False),  // In PCRE, == \Z
  PCRETest("(?m)\\A", True),
  PCRETest("(?m)\\z", True),
  PCRETest("(?-m)\\A", True),
  PCRETest("(?-m)\\z", True),
)

@TEST
def test_MimicsPCRE_SimpleTests():
  for i in range(len(tests)):
    let t = tests[i]
    for j in range(2):
      var flags = Regexp.LikePerl
      if j == 0:
        flags = flags | Regexp.Latin1
      var re = Regexp.Parse(t.regexp, flags, None)
      assert(re != None, " " + t.regexp)
      assert(t.should_match == re.MimicsPCRE(),
        " " + t.regexp + " " + (if j == 0: "latin1" else: "utf"))
      re.Decref()