from ...gmock import *
from ...gmock import Return

class FooInterface:
    def __del__(self): pass
    def DoThis(self): pass

class MockFoo(FooInterface):
    def __init__(self): pass
    # MOCK_METHOD0(DoThis, void());
    def DoThis(self): pass
    # GTEST_DISALLOW_COPY_AND_ASSIGN_(MockFoo);

@test
def LeakTest_LeakedMockWithExpectCallCausesFailureWhenLeakCheckingIsEnabled():
    var foo = MockFoo()
    EXPECT_CALL(foo, DoThis())
    foo.DoThis()
    exit(0)

@test
def LeakTest_LeakedMockWithOnCallCausesFailureWhenLeakCheckingIsEnabled():
    var foo = MockFoo()
    ON_CALL(foo, DoThis()).WillByDefault(Return())
    exit(0)

@test
def LeakTest_CatchesMultipleLeakedMockObjects():
    var foo1 = MockFoo()
    var foo2 = MockFoo()
    ON_CALL(foo1, DoThis()).WillByDefault(Return())
    EXPECT_CALL(foo2, DoThis())
    foo2.DoThis()
    exit(0)