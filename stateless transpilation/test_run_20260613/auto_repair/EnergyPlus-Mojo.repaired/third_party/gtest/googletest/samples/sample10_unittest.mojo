from memory import allocate, free as malloc, free as free_fn
from sys import args, exit, print

# Simulated gtest types
class TestInfo:

class EmptyTestEventListener:
    def OnTestStart(self, test_info: TestInfo):

    def OnTestEnd(self, test_info: TestInfo):

class TestEventListeners:
    var listeners: List[EmptyTestEventListener]

    def __init__(self):
        self.listeners = List[EmptyTestEventListener]()

    def Append(self, listener: EmptyTestEventListener):
        self.listeners.append(listener)

class UnitTest:
    var _listeners: TestEventListeners

    def __init__(self):
        self._listeners = TestEventListeners()

    @staticmethod
    def GetInstance() -> Self:
        return _unit_test_instance

    def listeners(self) -> TestEventListeners:
        return self._listeners

var _unit_test_instance = UnitTest()

# Water class with allocation tracking
class Water:
    var allocated_: Int = 0

    def __new__(cls: SelfType) -> Self:
        cls.allocated_ += 1
        return super().__new__(cls)

    def __del__(self):
        Water.allocated_ -= 1

    @staticmethod
    def allocated() -> Int:
        return Water.allocated_

# LeakChecker class
class LeakChecker(EmptyTestEventListener):
    var initially_allocated_: Int

    def OnTestStart(self, test_info: TestInfo):
        self.initially_allocated_ = Water.allocated()

    def OnTestEnd(self, test_info: TestInfo):
        var difference = Water.allocated() - self.initially_allocated_
        # EXPECT_LE(difference, 0) equivalent
        assert(difference <= 0, "Leaked " + String(difference) + " unit(s) of Water!")

# Test functions (mimicking TEST macro)
def ListenersTest_DoesNotLeak():
    var water = Water()
    del water

def ListenersTest_LeaksWater():
    var water = Water()
    # EXPECT_TRUE(water != None)
    assert(water != None)

def main() -> Int:
    var argc = len(args)
    var argv = args
    var check_for_leaks = False
    if argc > 1 and argv[1] == "--check_for_leaks":
        check_for_leaks = True
    else:
        print("Run this program with --check_for_leaks to enable custom leak checking in the tests.")
    if check_for_leaks:
        var listeners = UnitTest.GetInstance().listeners()
        listeners.Append(LeakChecker())
    # Run all tests (simplified)
    ListenersTest_DoesNotLeak()
    ListenersTest_LeaksWater()
    return 0