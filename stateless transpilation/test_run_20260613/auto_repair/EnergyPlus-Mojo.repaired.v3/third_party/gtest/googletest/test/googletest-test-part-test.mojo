from gtest.gtest-test-part import *
from gtest.gtest import *
from testing import Message, Test, TestPartResult, TestPartResultArray

struct TestPartResultTest(Test):
    var r1_: TestPartResult
    var r2_: TestPartResult
    var r3_: TestPartResult
    var r4_: TestPartResult

    def __init__(self):
        self.r1_ = TestPartResult(TestPartResult.kSuccess, "foo/bar.cc", 10, "Success!")
        self.r2_ = TestPartResult(TestPartResult.kNonFatalFailure, "foo/bar.cc", -1, "Failure!")
        self.r3_ = TestPartResult(TestPartResult.kFatalFailure, None, -1, "Failure!")
        self.r4_ = TestPartResult(TestPartResult.kSkip, "foo/bar.cc", 2, "Skipped!")

def ConstructorWorks():
    var fixture = TestPartResultTest()
    var message = Message()
    message << "something is terribly wrong"
    message << static_cast[const char*](testing.internal.kStackTraceMarker)
    message << "some unimportant stack trace"
    var result = TestPartResult(TestPartResult.kNonFatalFailure, "some_file.cc", 42, message.GetString().c_str())
    EXPECT_EQ(TestPartResult.kNonFatalFailure, result.type())
    EXPECT_STREQ("some_file.cc", result.file_name())
    EXPECT_EQ(42, result.line_number())
    EXPECT_STREQ(message.GetString().c_str(), result.message())
    EXPECT_STREQ("something is terribly wrong", result.summary())

def ResultAccessorsWork():
    var success = TestPartResult(TestPartResult.kSuccess, "file.cc", 42, "message")
    EXPECT_TRUE(success.passed())
    EXPECT_FALSE(success.failed())
    EXPECT_FALSE(success.nonfatally_failed())
    EXPECT_FALSE(success.fatally_failed())
    EXPECT_FALSE(success.skipped())
    var nonfatal_failure = TestPartResult(TestPartResult.kNonFatalFailure, "file.cc", 42, "message")
    EXPECT_FALSE(nonfatal_failure.passed())
    EXPECT_TRUE(nonfatal_failure.failed())
    EXPECT_TRUE(nonfatal_failure.nonfatally_failed())
    EXPECT_FALSE(nonfatal_failure.fatally_failed())
    EXPECT_FALSE(nonfatal_failure.skipped())
    var fatal_failure = TestPartResult(TestPartResult.kFatalFailure, "file.cc", 42, "message")
    EXPECT_FALSE(fatal_failure.passed())
    EXPECT_TRUE(fatal_failure.failed())
    EXPECT_FALSE(fatal_failure.nonfatally_failed())
    EXPECT_TRUE(fatal_failure.fatally_failed())
    EXPECT_FALSE(fatal_failure.skipped())
    var skip = TestPartResult(TestPartResult.kSkip, "file.cc", 42, "message")
    EXPECT_FALSE(skip.passed())
    EXPECT_FALSE(skip.failed())
    EXPECT_FALSE(skip.nonfatally_failed())
    EXPECT_FALSE(skip.fatally_failed())
    EXPECT_TRUE(skip.skipped())

def type():
    var fixture = TestPartResultTest()
    EXPECT_EQ(TestPartResult.kSuccess, fixture.r1_.type())
    EXPECT_EQ(TestPartResult.kNonFatalFailure, fixture.r2_.type())
    EXPECT_EQ(TestPartResult.kFatalFailure, fixture.r3_.type())
    EXPECT_EQ(TestPartResult.kSkip, fixture.r4_.type())

def file_name():
    var fixture = TestPartResultTest()
    EXPECT_STREQ("foo/bar.cc", fixture.r1_.file_name())
    EXPECT_STREQ(None, fixture.r3_.file_name())
    EXPECT_STREQ("foo/bar.cc", fixture.r4_.file_name())

def line_number():
    var fixture = TestPartResultTest()
    EXPECT_EQ(10, fixture.r1_.line_number())
    EXPECT_EQ(-1, fixture.r2_.line_number())
    EXPECT_EQ(2, fixture.r4_.line_number())

def message():
    var fixture = TestPartResultTest()
    EXPECT_STREQ("Success!", fixture.r1_.message())
    EXPECT_STREQ("Skipped!", fixture.r4_.message())

def Passed():
    var fixture = TestPartResultTest()
    EXPECT_TRUE(fixture.r1_.passed())
    EXPECT_FALSE(fixture.r2_.passed())
    EXPECT_FALSE(fixture.r3_.passed())
    EXPECT_FALSE(fixture.r4_.passed())

def Failed():
    var fixture = TestPartResultTest()
    EXPECT_FALSE(fixture.r1_.failed())
    EXPECT_TRUE(fixture.r2_.failed())
    EXPECT_TRUE(fixture.r3_.failed())
    EXPECT_FALSE(fixture.r4_.failed())

def Skipped():
    var fixture = TestPartResultTest()
    EXPECT_FALSE(fixture.r1_.skipped())
    EXPECT_FALSE(fixture.r2_.skipped())
    EXPECT_FALSE(fixture.r3_.skipped())
    EXPECT_TRUE(fixture.r4_.skipped())

def FatallyFailed():
    var fixture = TestPartResultTest()
    EXPECT_FALSE(fixture.r1_.fatally_failed())
    EXPECT_FALSE(fixture.r2_.fatally_failed())
    EXPECT_TRUE(fixture.r3_.fatally_failed())
    EXPECT_FALSE(fixture.r4_.fatally_failed())

def NonfatallyFailed():
    var fixture = TestPartResultTest()
    EXPECT_FALSE(fixture.r1_.nonfatally_failed())
    EXPECT_TRUE(fixture.r2_.nonfatally_failed())
    EXPECT_FALSE(fixture.r3_.nonfatally_failed())
    EXPECT_FALSE(fixture.r4_.nonfatally_failed())

struct TestPartResultArrayTest(Test):
    var r1_: TestPartResult
    var r2_: TestPartResult

    def __init__(self):
        self.r1_ = TestPartResult(TestPartResult.kNonFatalFailure, "foo/bar.cc", -1, "Failure 1")
        self.r2_ = TestPartResult(TestPartResult.kFatalFailure, "foo/bar.cc", -1, "Failure 2")

def InitialSizeIsZero():
    var results = TestPartResultArray()
    EXPECT_EQ(0, results.size())

def ContainsGivenResultAfterAppend():
    var fixture = TestPartResultArrayTest()
    var results = TestPartResultArray()
    results.Append(fixture.r1_)
    EXPECT_EQ(1, results.size())
    EXPECT_STREQ("Failure 1", results.GetTestPartResult(0).message())

def ContainsGivenResultsAfterTwoAppends():
    var fixture = TestPartResultArrayTest()
    var results = TestPartResultArray()
    results.Append(fixture.r1_)
    results.Append(fixture.r2_)
    EXPECT_EQ(2, results.size())
    EXPECT_STREQ("Failure 1", results.GetTestPartResult(0).message())
    EXPECT_STREQ("Failure 2", results.GetTestPartResult(1).message())

# typedef TestPartResultArrayTest TestPartResultArrayDeathTest;
alias TestPartResultArrayDeathTest = TestPartResultArrayTest

def DiesWhenIndexIsOutOfBound():
    var fixture = TestPartResultArrayDeathTest()
    var results = TestPartResultArray()
    results.Append(fixture.r1_)
    EXPECT_DEATH_IF_SUPPORTED(results.GetTestPartResult(-1), "")
    EXPECT_DEATH_IF_SUPPORTED(results.GetTestPartResult(1), "")