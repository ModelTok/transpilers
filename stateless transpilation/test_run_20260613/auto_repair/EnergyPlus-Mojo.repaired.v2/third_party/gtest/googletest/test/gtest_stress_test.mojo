from gtest.gtest import *
from src.gtest-internal-inl import Notification, ThreadWithParam, TestPropertyKeyIs

@parameter
if GTEST_IS_THREADSAFE:
    let kThreadCount: Int = 50

    def IdToKey(id: Int, suffix: String) -> String:
        var key = Message()
        key << "key_" << id << "_" << suffix
        return key.GetString()

    def IdToString(id: Int) -> String:
        var id_message = Message()
        id_message << id
        return id_message.GetString()

    def ExpectKeyAndValueWereRecordedForId(
        properties: List[TestProperty], id: Int, suffix: String):
        let matches_key = TestPropertyKeyIs(IdToKey(id, suffix))
        var found = False
        var prop: TestProperty? = None
        for p in properties:
            if matches_key(p):
                prop = p
                found = True
                break
        ASSERT_TRUE(found) << "expecting " << suffix << " value for id " << id
        EXPECT_STREQ(IdToString(id), prop.value())

    def ManyAsserts(id: Int):
        GTEST_LOG_INFO("Thread #", id, " running...")
        SCOPED_TRACE(Message() << "Thread #" << id)
        for i in range(kThreadCount):
            SCOPED_TRACE(Message() << "Iteration #" << i)
            EXPECT_TRUE(True)
            ASSERT_FALSE(False) << "This shouldn't fail."
            EXPECT_STREQ("a", "a")
            ASSERT_LE(5, 6)
            EXPECT_EQ(i, i) << "This shouldn't fail."
            Test.RecordProperty(IdToKey(id, "string"), IdToString(id))
            Test.RecordProperty(IdToKey(id, "int"), id)
            Test.RecordProperty("shared_key", IdToString(id))
            EXPECT_LT(i, 0) << "This should always fail."

    def CheckTestFailureCount(expected_failures: Int):
        let info = UnitTest.GetInstance().current_test_info()
        let result = info.result()
        GTEST_CHECK(expected_failures == result.total_part_count()) << "Logged " << result.total_part_count() << " failures " << " vs. " << expected_failures << " expected"

    TEST("StressTest", "CanUseScopedTraceAndAssertionsInManyThreads", fn():
        var threads: List[ThreadWithParam[Int]] = List[ThreadWithParam[Int]]()
        var threads_can_start = Notification()
        for i in range(kThreadCount):
            threads.append(ThreadWithParam[Int](ManyAsserts, i, &threads_can_start))
        threads_can_start.Notify()
        for i in range(kThreadCount):
            threads[i].Join()
        let info = UnitTest.GetInstance().current_test_info()
        let result = info.result()
        var properties: List[TestProperty] = List[TestProperty]()
        for i in range(result.test_property_count()):
            properties.append(result.GetTestProperty(i))
        EXPECT_EQ(kThreadCount * 2 + 1, result.test_property_count()) << "String and int values recorded on each thread, as well as one shared_key"
        for i in range(kThreadCount):
            ExpectKeyAndValueWereRecordedForId(properties, i, "string")
            ExpectKeyAndValueWereRecordedForId(properties, i, "int")
        CheckTestFailureCount(kThreadCount * kThreadCount)
    )

    def FailingThread(is_fatal: Bool):
        if is_fatal:
            FAIL() << "Fatal failure in some other thread. (This failure is expected.)"
        else:
            ADD_FAILURE() << "Non-fatal failure in some other thread. (This failure is expected.)"

    def GenerateFatalFailureInAnotherThread(is_fatal: Bool):
        var thread = ThreadWithParam[Bool](FailingThread, is_fatal, None)
        thread.Join()

    TEST("NoFatalFailureTest", "ExpectNoFatalFailureIgnoresFailuresInOtherThreads", fn():
        EXPECT_NO_FATAL_FAILURE(GenerateFatalFailureInAnotherThread(True))
        CheckTestFailureCount(1)
    )

    def AssertNoFatalFailureIgnoresFailuresInOtherThreads():
        ASSERT_NO_FATAL_FAILURE(GenerateFatalFailureInAnotherThread(True))

    TEST("NoFatalFailureTest", "AssertNoFatalFailureIgnoresFailuresInOtherThreads", fn():
        AssertNoFatalFailureIgnoresFailuresInOtherThreads()
        CheckTestFailureCount(1)
    )

    TEST("FatalFailureTest", "ExpectFatalFailureIgnoresFailuresInOtherThreads", fn():
        EXPECT_FATAL_FAILURE(GenerateFatalFailureInAnotherThread(True), "expected")
        CheckTestFailureCount(2)
    )

    TEST("FatalFailureOnAllThreadsTest", "ExpectFatalFailureOnAllThreads", fn():
        EXPECT_FATAL_FAILURE_ON_ALL_THREADS(GenerateFatalFailureInAnotherThread(True), "expected")
        CheckTestFailureCount(0)
        ADD_FAILURE() << "This is an expected non-fatal failure."
    )

    TEST("NonFatalFailureTest", "ExpectNonFatalFailureIgnoresFailuresInOtherThreads", fn():
        EXPECT_NONFATAL_FAILURE(GenerateFatalFailureInAnotherThread(False), "expected")
        CheckTestFailureCount(2)
    )

    TEST("NonFatalFailureOnAllThreadsTest", "ExpectNonFatalFailureOnAllThreads", fn():
        EXPECT_NONFATAL_FAILURE_ON_ALL_THREADS(GenerateFatalFailureInAnotherThread(False), "expected")
        CheckTestFailureCount(0)
        ADD_FAILURE() << "This is an expected non-fatal failure."
    )

    def main(argc: Int, argv: Pointer[Pointer[UInt8]]?) -> Int:
        testing.InitGoogleTest(&argc, argv)
        let result = RUN_ALL_TESTS()
        GTEST_CHECK(result == 1) << "RUN_ALL_TESTS() did not fail as expected"
        print("\nPASS\n")
        return 0
else:
    TEST("StressTest", "DISABLED_ThreadSafetyTestsAreSkippedWhenGoogleTestIsNotThreadSafe", fn():

    )

    def main(argc: Int, argv: Pointer[Pointer[UInt8]]?) -> Int:
        testing.InitGoogleTest(&argc, argv)
        return RUN_ALL_TESTS()