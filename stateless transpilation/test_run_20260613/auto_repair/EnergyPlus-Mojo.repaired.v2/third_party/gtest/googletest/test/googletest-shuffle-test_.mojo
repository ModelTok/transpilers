from gtest import *
from memory import GTestEmptyTestEventListener as EmptyTestEventListener, GTestInitGoogleTest as InitGoogleTest, GTestMessage as Message, GTestTest as Test, GTestTestEventListeners as TestEventListeners, GTestTestInfo as TestInfo, GTestUnitTest as UnitTest, GTestTestSuiteName, GTestName, GTestGetInstance, GTestListeners, GTestRelease, GTestDefaultResultPrinter, GTestAppend, GTestRunAllTests

class A(GTestTest):

def test_A_A() raises:

def test_A_B() raises:

def test_ADeathTest_A() raises:

def test_ADeathTest_B() raises:

def test_ADeathTest_C() raises:

def test_B_A() raises:

def test_B_B() raises:

def test_B_C() raises:

def test_B_DISABLED_D() raises:

def test_B_DISABLED_E() raises:

def test_BDeathTest_A() raises:

def test_BDeathTest_B() raises:

def test_C_A() raises:

def test_C_B() raises:

def test_C_C() raises:

def test_C_DISABLED_D() raises:

def test_CDeathTest_A() raises:

def test_DISABLED_D_A() raises:

def test_DISABLED_D_DISABLED_B() raises:

class TestNamePrinter(GTestEmptyTestEventListener):
    def OnTestIterationStart(self, unit_test: GTestUnitTest, iteration: Int32) raises:
        print("----")

    def OnTestStart(self, test_info: GTestTestInfo) raises:
        print(test_info.test_suite_name(), ".", test_info.name())

def main(argc: Int32, argv: Pointer[Pointer[UInt8]]) -> Int32:
    InitGoogleTest(argc, argv)
    var listeners: GTestTestEventListeners = UnitTest.GetInstance().listeners()
    delete listeners.Release(listeners.default_result_printer())
    listeners.Append(TestNamePrinter())
    return RunAllTests()