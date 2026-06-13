from gmock import *
from gtest import *

module testing:
    # anonymous namespace
    module:
        # using ::testing::internal::ThreadWithParam;  (assume imported)
        let kMaxTestThreads: Int = 50
        let kRepeat: Int = 50

        struct MockFoo:
            # MOCK_METHOD1(Bar, int(int n));  // NOLINT
            def Bar(self, n: Int) -> Int:
                return mock_method(self, "Bar", n)

            # MOCK_METHOD2(Baz, char(char* s1 , string& s2 ));  // NOLINT
            def Baz(self, s1: String, s2: String) -> Int8:
                return mock_method(self, "Baz", s1, s2)

        def JoinAndDelete[T](t: ThreadWithParam[T]):
            t.Join()
            delete t

        struct Dummy:

        def TestConcurrentMockObjects(dummy: Dummy):
            foo: MockFoo = MockFoo()
            ON_CALL(foo, Bar(_)).WillByDefault(Return(1))
            ON_CALL(foo, Baz(_, _)).WillByDefault(Return('b'))
            ON_CALL(foo, Baz(_, "you")).WillByDefault(Return('a'))
            EXPECT_CALL(foo, Bar(0)).Times(AtMost(3))
            EXPECT_CALL(foo, Baz(_, _))
            EXPECT_CALL(foo, Baz("hi", "you")).WillOnce(Return('z')).WillRepeatedly(DoDefault())
            EXPECT_EQ(1, foo.Bar(0))
            EXPECT_EQ(1, foo.Bar(0))
            EXPECT_EQ('z', foo.Baz("hi", "you"))
            EXPECT_EQ('a', foo.Baz("hi", "you"))
            EXPECT_EQ('b', foo.Baz("hi", "me"))

        struct Helper1Param:
            mock_foo: MockFoo
            count: Int*

        def Helper1(param: Helper1Param):
            for i in range(kRepeat):
                ch: Int8 = param.mock_foo.Baz("a", "b")
                if ch == 'a':
                    (param.count) += 1
                else:
                    EXPECT_EQ('\0', ch)
                EXPECT_EQ('\0', param.mock_foo.Baz("x", "y")) << "Expected failure."
                EXPECT_EQ(1, param.mock_foo.Bar(5))

        def TestConcurrentCallsOnSameObject(dummy: Dummy):
            foo: MockFoo = MockFoo()
            ON_CALL(foo, Bar(_)).WillByDefault(Return(1))
            EXPECT_CALL(foo, Baz(_, "b")).Times(kRepeat).WillRepeatedly(Return('a'))
            EXPECT_CALL(foo, Baz(_, "c"))  # Expected to be unsatisfied.
            count1: Int = 0
            param: Helper1Param = Helper1Param(&foo, &count1)
            t: ThreadWithParam[Helper1Param] = ThreadWithParam[Helper1Param](Helper1, param, None)
            count2: Int = 0
            param2: Helper1Param = Helper1Param(&foo, &count2)
            Helper1(param2)
            JoinAndDelete(t)
            EXPECT_EQ(kRepeat, count1 + count2)

        def Helper2(foo: MockFoo*):
            for i in range(kRepeat):
                foo.Bar(2)
                foo.Bar(3)

        def TestPartiallyOrderedExpectationsWithThreads(dummy: Dummy):
            foo: MockFoo = MockFoo()
            s1: Sequence = Sequence()
            s2: Sequence = Sequence()
            {
                dummy: InSequence = InSequence()
                EXPECT_CALL(foo, Bar(0))
                EXPECT_CALL(foo, Bar(1)).InSequence(s1, s2)
            }
            EXPECT_CALL(foo, Bar(2)).Times(2*kRepeat).InSequence(s1).RetiresOnSaturation()
            EXPECT_CALL(foo, Bar(3)).Times(2*kRepeat).InSequence(s2)
            {
                dummy: InSequence = InSequence()
                EXPECT_CALL(foo, Bar(2)).InSequence(s1, s2)
                EXPECT_CALL(foo, Bar(4))
            }
            foo.Bar(0)
            foo.Bar(1)
            t: ThreadWithParam[MockFoo*] = ThreadWithParam[MockFoo*](Helper2, &foo, None)
            Helper2(&foo)
            JoinAndDelete(t)
            foo.Bar(2)
            foo.Bar(4)

        # TEST(StressTest, CanUseGMockWithThreads)
        def StressTest_CanUseGMockWithThreads():
            test_routines: List[fn(Dummy) -> None] = [
                TestConcurrentMockObjects,
                TestConcurrentCallsOnSameObject,
                TestPartiallyOrderedExpectationsWithThreads,
            ]
            kRoutines: Int = test_routines.length()
            kCopiesOfEachRoutine: Int = kMaxTestThreads / kRoutines
            kTestThreads: Int = kCopiesOfEachRoutine * kRoutines
            threads: ThreadWithParam[Dummy][kTestThreads] = [None] * kTestThreads
            for i in range(kTestThreads):
                threads[i] = ThreadWithParam[Dummy](test_routines[i % kRoutines], Dummy(), None)
                GTEST_LOG_(INFO) << "Thread #" << i << " running . . ."
            for i in range(kTestThreads):
                JoinAndDelete(threads[i])
            info: TestInfo* = UnitTest.GetInstance().current_test_info()
            result: TestResult = info.result()
            kExpectedFailures: Int = (3*kRepeat + 1)*kCopiesOfEachRoutine
            GTEST_CHECK_(kExpectedFailures == result.total_part_count()) << "Expected " << kExpectedFailures << " failures, but got " << result.total_part_count()

        def main(argc: Int, argv: String**) -> Int:
            testing.InitGoogleMock(&argc, argv)
            exit_code: Int = RUN_ALL_TESTS()  # Expected to fail.
            GTEST_CHECK_(exit_code != 0) << "RUN_ALL_TESTS() did not fail as expected"
            print("\nPASS\n")
            return 0