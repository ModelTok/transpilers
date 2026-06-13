from gmock import *
from gtest import *
from builtins import StringRef, Int, Float64, UInt8, Bool, None

from testing import _, AnyNumber, Ge, InSequence, NaggyMock, Ref, Return, Sequence, Value

struct Pair[FirstType, SecondType]:
    var first: FirstType
    var second: SecondType
    def __init__(inout self, first: FirstType, second: SecondType):
        self.first = first
        self.second = second

class MockFoo:
    def __init__(inout self):

    # MOCK_METHOD3(Bar, char(string& s , int i, double x));
    def Bar(inout self, s: StringRef, i: Int, x: Float64) -> UInt8:
        return 0
    # MOCK_METHOD2(Bar2, bool(int x, int y));
    def Bar2(inout self, x: Int, y: Int) -> Bool:
        return False
    # MOCK_METHOD2(Bar3, void(int x, int y));
    def Bar3(inout self, x: Int, y: Int):

    # private:
    # GTEST_DISALLOW_COPY_AND_ASSIGN_(MockFoo);

class GMockOutputTest(Test):
    var foo_: NaggyMock[MockFoo]
    def __init__(inout self):
        self.foo_ = NaggyMock[MockFoo]()

def ExpectedCall(inout self: GMockOutputTest):
    testing.GMOCK_FLAG.verbose = "info"
    EXPECT_CALL(self.foo_, Bar2(0, _))
    self.foo_.Bar2(0, 0)  # Expected call
    testing.GMOCK_FLAG.verbose = "warning"

def ExpectedCallToVoidFunction(inout self: GMockOutputTest):
    testing.GMOCK_FLAG.verbose = "info"
    EXPECT_CALL(self.foo_, Bar3(0, _))
    self.foo_.Bar3(0, 0)  # Expected call
    testing.GMOCK_FLAG.verbose = "warning"

def ExplicitActionsRunOut(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar2(_, _))
        .Times(2)
        .WillOnce(Return(False))
    self.foo_.Bar2(2, 2)
    self.foo_.Bar2(1, 1)  # Explicit actions in EXPECT_CALL run out.

def UnexpectedCall(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar2(0, _))
    self.foo_.Bar2(1, 0)  # Unexpected call
    self.foo_.Bar2(0, 0)  # Expected call

def UnexpectedCallToVoidFunction(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar3(0, _))
    self.foo_.Bar3(1, 0)  # Unexpected call
    self.foo_.Bar3(0, 0)  # Expected call

def ExcessiveCall(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar2(0, _))
    self.foo_.Bar2(0, 0)  # Expected call
    self.foo_.Bar2(0, 1)  # Excessive call

def ExcessiveCallToVoidFunction(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar3(0, _))
    self.foo_.Bar3(0, 0)  # Expected call
    self.foo_.Bar3(0, 1)  # Excessive call

def UninterestingCall(inout self: GMockOutputTest):
    self.foo_.Bar2(0, 1)  # Uninteresting call

def UninterestingCallToVoidFunction(inout self: GMockOutputTest):
    self.foo_.Bar3(0, 1)  # Uninteresting call

def RetiredExpectation(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar2(_, _))
        .RetiresOnSaturation()
    EXPECT_CALL(self.foo_, Bar2(0, 0))
    self.foo_.Bar2(1, 1)
    self.foo_.Bar2(1, 1)  # Matches a retired expectation
    self.foo_.Bar2(0, 0)

def UnsatisfiedPrerequisite(inout self: GMockOutputTest):
    {
        InSequence s
        EXPECT_CALL(self.foo_, Bar(_, 0, _))
        EXPECT_CALL(self.foo_, Bar2(0, 0))
        EXPECT_CALL(self.foo_, Bar2(1, _))
    }
    self.foo_.Bar2(1, 0)  # Has one immediate unsatisfied pre-requisite
    self.foo_.Bar("Hi", 0, 0)
    self.foo_.Bar2(0, 0)
    self.foo_.Bar2(1, 0)

def UnsatisfiedPrerequisites(inout self: GMockOutputTest):
    Sequence s1, s2
    EXPECT_CALL(self.foo_, Bar(_, 0, _))
        .InSequence(s1)
    EXPECT_CALL(self.foo_, Bar2(0, 0))
        .InSequence(s2)
    EXPECT_CALL(self.foo_, Bar2(1, _))
        .InSequence(s1, s2)
    self.foo_.Bar2(1, 0)  # Has two immediate unsatisfied pre-requisites
    self.foo_.Bar("Hi", 0, 0)
    self.foo_.Bar2(0, 0)
    self.foo_.Bar2(1, 0)

def UnsatisfiedWith(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar2(_, _)).With(Ge())

def UnsatisfiedExpectation(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar(_, _, _))
    EXPECT_CALL(self.foo_, Bar2(0, _))
        .Times(2)
    self.foo_.Bar2(0, 1)

def MismatchArguments(inout self: GMockOutputTest):
    let s: StringRef = "Hi"
    EXPECT_CALL(self.foo_, Bar(Ref(s), _, Ge(0)))
    self.foo_.Bar("Ho", 0, -0.1)  # Mismatch arguments
    self.foo_.Bar(s, 0, 0)

def MismatchWith(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar2(Ge(2), Ge(1)))
        .With(Ge())
    self.foo_.Bar2(2, 3)  # Mismatch With()
    self.foo_.Bar2(2, 1)

def MismatchArgumentsAndWith(inout self: GMockOutputTest):
    EXPECT_CALL(self.foo_, Bar2(Ge(2), Ge(1)))
        .With(Ge())
    self.foo_.Bar2(1, 3)  # Mismatch arguments and mismatch With()
    self.foo_.Bar2(2, 1)

def UnexpectedCallWithDefaultAction(inout self: GMockOutputTest):
    ON_CALL(self.foo_, Bar2(_, _))
        .WillByDefault(Return(True))   # Default action #1
    ON_CALL(self.foo_, Bar2(1, _))
        .WillByDefault(Return(False))  # Default action #2
    EXPECT_CALL(self.foo_, Bar2(2, 2))
    self.foo_.Bar2(1, 0)  # Unexpected call, takes default action #2.
    self.foo_.Bar2(0, 0)  # Unexpected call, takes default action #1.
    self.foo_.Bar2(2, 2)  # Expected call.

def ExcessiveCallWithDefaultAction(inout self: GMockOutputTest):
    ON_CALL(self.foo_, Bar2(_, _))
        .WillByDefault(Return(True))   # Default action #1
    ON_CALL(self.foo_, Bar2(1, _))
        .WillByDefault(Return(False))  # Default action #2
    EXPECT_CALL(self.foo_, Bar2(2, 2))
    EXPECT_CALL(self.foo_, Bar2(1, 1))
    self.foo_.Bar2(2, 2)  # Expected call.
    self.foo_.Bar2(2, 2)  # Excessive call, takes default action #1.
    self.foo_.Bar2(1, 1)  # Expected call.
    self.foo_.Bar2(1, 1)  # Excessive call, takes default action #2.

def UninterestingCallWithDefaultAction(inout self: GMockOutputTest):
    ON_CALL(self.foo_, Bar2(_, _))
        .WillByDefault(Return(True))   # Default action #1
    ON_CALL(self.foo_, Bar2(1, _))
        .WillByDefault(Return(False))  # Default action #2
    self.foo_.Bar2(2, 2)  # Uninteresting call, takes default action #1.
    self.foo_.Bar2(1, 1)  # Uninteresting call, takes default action #2.

def ExplicitActionsRunOutWithDefaultAction(inout self: GMockOutputTest):
    ON_CALL(self.foo_, Bar2(_, _))
        .WillByDefault(Return(True))   # Default action #1
    EXPECT_CALL(self.foo_, Bar2(_, _))
        .Times(2)
        .WillOnce(Return(False))
    self.foo_.Bar2(2, 2)
    self.foo_.Bar2(1, 1)  # Explicit actions in EXPECT_CALL run out.

def CatchesLeakedMocks(inout self: GMockOutputTest):
    var foo1 = MockFoo()
    var foo2 = MockFoo()
    ON_CALL(foo1, Bar(_, _, _)).WillByDefault(Return('a'))
    EXPECT_CALL(foo2, Bar2(_, _))
    EXPECT_CALL(foo2, Bar2(1, _))
    EXPECT_CALL(foo2, Bar3(_, _)).Times(AnyNumber())
    foo2.Bar2(2, 1)
    foo2.Bar2(1, 1)

# MATCHER_P2(IsPair, first, second, "") {
#   return Value(arg.first, first) && Value(arg.second, second);
# }
def IsPair(first: Matcher, second: Matcher) -> Matcher:
    # Placeholder: actual matcher logic would go here
    return Matcher()

def PrintsMatcher(inout self: GMockOutputTest):
    let m1: Matcher = Ge(48)
    EXPECT_THAT(Pair[Int, Bool](42, True), IsPair(m1, True))

def TestCatchesLeakedMocksInAdHocTests():
    var foo = MockFoo()
    EXPECT_CALL(foo, Bar2(_, _))
    foo.Bar2(2, 1)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    testing.InitGoogleMock(argc, argv)
    testing.GMOCK_FLAG.catch_leaked_mocks = True
    testing.GMOCK_FLAG.verbose = "warning"
    TestCatchesLeakedMocksInAdHocTests()
    return RUN_ALL_TESTS()