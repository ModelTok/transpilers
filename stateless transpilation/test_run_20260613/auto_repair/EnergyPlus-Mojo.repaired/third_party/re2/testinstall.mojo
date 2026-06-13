from sys import printf
from re2 import FilteredRE2, RE2

def main() -> Int:
    var f = FilteredRE2()
    var id: Int = 0
    f.Add("a.*b.*c", RE2.DefaultOptions, id)
    var v = List[String]()
    f.Compile(v)
    var ids = List[Int]()
    f.FirstMatch("abbccc", ids)
    var n: Int = 0
    if RE2.FullMatch("axbyc", "a.*b.*c") and RE2.PartialMatch("foo123bar", "(\\d+)", n) and n == 123:
        printf("PASS\n")
        return 0
    printf("FAIL\n")
    return 2