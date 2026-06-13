from ...include.gmock.gmock-cardinalities import Cardinality, CardinalityInterface
from ...include.gmock.internal.gmock-internal-utils import Expect
from ......gtest.include.gtest.gtest import GTEST_API_
from memory.unsafe import INT_MAX
from string import String

@value
struct BetweenCardinalityImpl(CardinalityInterface):
    var min_: Int
    var max_: Int

    def __init__(inout self, min: Int, max: Int):
        self.min_ = min if min >= 0 else 0
        self.max_ = max if max >= self.min_ else self.min_
        var ss = String()
        if min < 0:
            ss = "The invocation lower bound must be >= 0, but is actually " + String(min) + "."
            Expect(false, __FILE__, __LINE__, ss)
        elif max < 0:
            ss = "The invocation upper bound must be >= 0, but is actually " + String(max) + "."
            Expect(false, __FILE__, __LINE__, ss)
        elif min > max:
            ss = "The invocation upper bound (" + String(max) + ") must be >= the invocation lower bound (" + String(min) + ")."
            Expect(false, __FILE__, __LINE__, ss)
        # GTEST_DISALLOW_COPY_AND_ASSIGN_(BetweenCardinalityImpl) not needed in Mojo

    def ConservativeLowerBound(self) -> Int:
        return self.min_

    def ConservativeUpperBound(self) -> Int:
        return self.max_

    def IsSatisfiedByCallCount(self, call_count: Int) -> Bool:
        return self.min_ <= call_count and call_count <= self.max_

    def IsSaturatedByCallCount(self, call_count: Int) -> Bool:
        return call_count >= self.max_

    def DescribeTo(self, os: StringRef):
        var s: String
        if self.min_ == 0:
            if self.max_ == 0:
                s = "never called"
            elif self.max_ == INT_MAX:
                s = "called any number of times"
            else:
                s = "called at most " + FormatTimes(self.max_)
        elif self.min_ == self.max_:
            s = "called " + FormatTimes(self.min_)
        elif self.max_ == INT_MAX:
            s = "called at least " + FormatTimes(self.min_)
        else:
            s = "called between " + String(self.min_) + " and " + String(self.max_) + " times"
        os.write(s)

def FormatTimes(n: Int) -> String:
    if n == 1:
        return "once"
    elif n == 2:
        return "twice"
    else:
        var ss = String()
        ss += String(n)
        ss += " times"
        return ss

def Cardinality.DescribeActualCallCountTo(actual_call_count: Int, os: StringRef):
    if actual_call_count > 0:
        var s = "called " + FormatTimes(actual_call_count)
        os.write(s)
    else:
        os.write("never called")

def AtLeast(n: Int) -> Cardinality:
    return Between(n, INT_MAX)

def AtMost(n: Int) -> Cardinality:
    return Between(0, n)

def AnyNumber() -> Cardinality:
    return AtLeast(0)

def Between(min: Int, max: Int) -> Cardinality:
    return Cardinality(BetweenCardinalityImpl(min, max))

def Exactly(n: Int) -> Cardinality:
    return Between(n, n)