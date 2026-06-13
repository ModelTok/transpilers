
def _noop(): pass

struct Test:
    var fn: fn()
    var name: String

    def __init__(inout self, fn: fn(), name: String):
        self.def = def self.name = name

    def __init__(inout self):
        self.def = _noop
        self.name = ""

var tests = List[Test]()
for _ in range(10000):
    tests.append(Test())
var ntests: Int = 0

def TempDir() -> String:
    return "/tmp/"

def RegisterTest(fn: fn(), name: String):
    var idx = ntests
    tests[idx].def = def tests[idx].name = name
    ntests += 1

def main():
    for i in range(ntests):
        print(tests[i].name)
        tests[i].fn()
    print("PASS")