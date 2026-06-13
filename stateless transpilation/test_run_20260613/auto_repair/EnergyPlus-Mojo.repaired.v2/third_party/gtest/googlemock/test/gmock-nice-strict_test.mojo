from gmock.gmock-nice-strict import *
from string import String
from utility import *
from gmock.gmock import *
from gtest.gtest-spi import *
from gtest.gtest import *

class Mock:
    def __init__(self):

    # MOCK_METHOD0(DoThis, void());
    def DoThis(self):

    # private:
    # GTEST_DISALLOW_COPY_AND_ASSIGN_(Mock);

namespace testing:
    namespace gmock_nice_strict_test:
        # using testing::GMOCK_FLAG(verbose);
        # using testing::HasSubstr;
        # using testing::NaggyMock;
        # using testing::NiceMock;
        # using testing::StrictMock;
        #if GTEST_HAS_STREAM_REDIRECTION
        # using testing::internal::CaptureStdout;
        # using testing::internal::GetCapturedStdout;
        #endif

        class NotDefaultConstructible:
            def __init__(self, i: Int):

        class CallsMockMethodInDestructor:
            def __del__(self):
                self.OnDestroy()
            # MOCK_METHOD(void, OnDestroy, ());
            def OnDestroy(self):

        class Foo:
            def __del__(self):

            # void DoThis() = 0;
            abstract def DoThis(self)
            # int DoThat(bool flag) = 0;
            abstract def DoThat(self, flag: Bool) -> Int

        class MockFoo(Foo):
            def __init__(self):

            def Delete(self):
                # delete this;

            # MOCK_METHOD0(DoThis, void());
            def DoThis(self):

            # MOCK_METHOD1(DoThat, int(bool flag));
            def DoThat(self, flag: Bool) -> Int:
                return 0
            # MOCK_METHOD0(ReturnNonDefaultConstructible, NotDefaultConstructible());
            def ReturnNonDefaultConstructible(self) -> NotDefaultConstructible:
                return NotDefaultConstructible(0)
            # private:
            # GTEST_DISALLOW_COPY_AND_ASSIGN_(MockFoo);

        class MockBar:
            def __init__(self, s: String):
                self.str_ = s
            def __init__(self, a1: String, a2: String, a3: String, a4: String, a5: Int, a6: Int,
                        a7: String, a8: String, a9: Bool, a10: Bool):
                self.str_ = String() + a1 + a2 + a3 + a4 + chr(a5) + chr(a6) + a7 + a8 + (if a9: 'T' else 'F') + (if a10: 'T' else 'F')
            def __del__(self):

            def str(self) -> String:
                return self.str_
            # MOCK_METHOD0(This, int());
            def This(self) -> Int:
                return 0
            # MOCK_METHOD2(That, string(int, bool));
            def That(self, i: Int, b: Bool) -> String:
                return ""
            # private:
            var str_: String
            # GTEST_DISALLOW_COPY_AND_ASSIGN_(MockBar);

        class MockBaz:
            class MoveOnly:
                def __init__(self):

                # MoveOnly(const MoveOnly&) = delete;
                # MoveOnly& operator=(const MoveOnly&) = delete;
                # MoveOnly(MoveOnly&&) = default;
                # MoveOnly& operator=(MoveOnly&&) = default;
            def __init__(self, move_only: MoveOnly):

        #if GTEST_HAS_STREAM_REDIRECTION
        def test_RawMockTest_WarningForUninterestingCall():
            let saved_flag: String = GMOCK_FLAG(verbose)
            GMOCK_FLAG(verbose) = "warning"
            var raw_foo: MockFoo = MockFoo()
            CaptureStdout()
            raw_foo.DoThis()
            raw_foo.DoThat(true)
            EXPECT_THAT(GetCapturedStdout(),
                        HasSubstr("Uninteresting mock function call"))
            GMOCK_FLAG(verbose) = saved_flag

        def test_RawMockTest_WarningForUninterestingCallAfterDeath():
            let saved_flag: String = GMOCK_FLAG(verbose)
            GMOCK_FLAG(verbose) = "warning"
            var raw_foo: MockFoo = new MockFoo()
            ON_CALL(*raw_foo, DoThis())
                .WillByDefault(Invoke(raw_foo, &MockFoo::Delete))
            CaptureStdout()
            raw_foo->DoThis()
            EXPECT_THAT(GetCapturedStdout(),
                        HasSubstr("Uninteresting mock function call"))
            GMOCK_FLAG(verbose) = saved_flag

        def test_RawMockTest_InfoForUninterestingCall():
            var raw_foo: MockFoo = MockFoo()
            let saved_flag: String = GMOCK_FLAG(verbose)
            GMOCK_FLAG(verbose) = "info"
            CaptureStdout()
            raw_foo.DoThis()
            EXPECT_THAT(GetCapturedStdout(),
                        HasSubstr("Uninteresting mock function call"))
            GMOCK_FLAG(verbose) = saved_flag

        def test_RawMockTest_IsNaggy_IsNice_IsStrict():
            var raw_foo: MockFoo = MockFoo()
            EXPECT_TRUE(Mock.IsNaggy(&raw_foo))
            EXPECT_FALSE(Mock.IsNice(&raw_foo))
            EXPECT_FALSE(Mock.IsStrict(&raw_foo))

        def test_NiceMockTest_NoWarningForUninterestingCall():
            var nice_foo: NiceMock[MockFoo] = NiceMock[MockFoo]()
            CaptureStdout()
            nice_foo.DoThis()
            nice_foo.DoThat(true)
            EXPECT_EQ("", GetCapturedStdout())

        def test_NiceMockTest_NoWarningForUninterestingCallAfterDeath():
            var nice_foo: NiceMock[MockFoo] = new NiceMock[MockFoo]()
            ON_CALL(*nice_foo, DoThis())
                .WillByDefault(Invoke(nice_foo, &MockFoo::Delete))
            CaptureStdout()
            nice_foo->DoThis()
            EXPECT_EQ("", GetCapturedStdout())

        def test_NiceMockTest_InfoForUninterestingCall():
            var nice_foo: NiceMock[MockFoo] = NiceMock[MockFoo]()
            let saved_flag: String = GMOCK_FLAG(verbose)
            GMOCK_FLAG(verbose) = "info"
            CaptureStdout()
            nice_foo.DoThis()
            EXPECT_THAT(GetCapturedStdout(),
                        HasSubstr("Uninteresting mock function call"))
            GMOCK_FLAG(verbose) = saved_flag
        #endif  // GTEST_HAS_STREAM_REDIRECTION

        def test_NiceMockTest_AllowsExpectedCall():
            var nice_foo: NiceMock[MockFoo] = NiceMock[MockFoo]()
            EXPECT_CALL(nice_foo, DoThis())
            nice_foo.DoThis()

        def test_NiceMockTest_ThrowsExceptionForUnknownReturnTypes():
            var nice_foo: NiceMock[MockFoo] = NiceMock[MockFoo]()
            #if GTEST_HAS_EXCEPTIONS
            try:
                nice_foo.ReturnNonDefaultConstructible()
                FAIL()
            except Error as ex:
                EXPECT_THAT(ex.message, HasSubstr("ReturnNonDefaultConstructible"))
            #else
            EXPECT_DEATH_IF_SUPPORTED({ nice_foo.ReturnNonDefaultConstructible(); }, "")
            #endif

        def test_NiceMockTest_UnexpectedCallFails():
            var nice_foo: NiceMock[MockFoo] = NiceMock[MockFoo]()
            EXPECT_CALL(nice_foo, DoThis()).Times(0)
            EXPECT_NONFATAL_FAILURE(nice_foo.DoThis(), "called more times than expected")

        def test_NiceMockTest_NonDefaultConstructor():
            var nice_bar: NiceMock[MockBar] = NiceMock[MockBar]("hi")
            EXPECT_EQ("hi", nice_bar.str())
            nice_bar.This()
            nice_bar.That(5, true)

        def test_NiceMockTest_NonDefaultConstructor10():
            var nice_bar: NiceMock[MockBar] = NiceMock[MockBar]('a', 'b', "c", "d", 'e', 'f',
                                                                 "g", "h", true, false)
            EXPECT_EQ("abcdefghTF", nice_bar.str())
            nice_bar.This()
            nice_bar.That(5, true)

        def test_NiceMockTest_AllowLeak():
            var leaked: NiceMock[MockFoo] = new NiceMock[MockFoo]()
            Mock.AllowLeak(leaked)
            EXPECT_CALL(*leaked, DoThis())
            leaked->DoThis()

        def test_NiceMockTest_MoveOnlyConstructor():
            var nice_baz: NiceMock[MockBaz] = NiceMock[MockBaz](MockBaz.MoveOnly{})

        def test_NiceMockTest_AcceptsClassNamedMock():
            var nice: NiceMock[::Mock] = NiceMock[::Mock]()
            EXPECT_CALL(nice, DoThis())
            nice.DoThis()

        def test_NiceMockTest_IsNiceInDestructor():
            {
                var nice_on_destroy: NiceMock[CallsMockMethodInDestructor] = NiceMock[CallsMockMethodInDestructor]()
            }

        def test_NiceMockTest_IsNaggy_IsNice_IsStrict():
            var nice_foo: NiceMock[MockFoo] = NiceMock[MockFoo]()
            EXPECT_FALSE(Mock.IsNaggy(&nice_foo))
            EXPECT_TRUE(Mock.IsNice(&nice_foo))
            EXPECT_FALSE(Mock.IsStrict(&nice_foo))

        #if GTEST_HAS_STREAM_REDIRECTION
        def test_NaggyMockTest_WarningForUninterestingCall():
            let saved_flag: String = GMOCK_FLAG(verbose)
            GMOCK_FLAG(verbose) = "warning"
            var naggy_foo: NaggyMock[MockFoo] = NaggyMock[MockFoo]()
            CaptureStdout()
            naggy_foo.DoThis()
            naggy_foo.DoThat(true)
            EXPECT_THAT(GetCapturedStdout(),
                        HasSubstr("Uninteresting mock function call"))
            GMOCK_FLAG(verbose) = saved_flag

        def test_NaggyMockTest_WarningForUninterestingCallAfterDeath():
            let saved_flag: String = GMOCK_FLAG(verbose)
            GMOCK_FLAG(verbose) = "warning"
            var naggy_foo: NaggyMock[MockFoo] = new NaggyMock[MockFoo]()
            ON_CALL(*naggy_foo, DoThis())
                .WillByDefault(Invoke(naggy_foo, &MockFoo::Delete))
            CaptureStdout()
            naggy_foo->DoThis()
            EXPECT_THAT(GetCapturedStdout(),
                        HasSubstr("Uninteresting mock function call"))
            GMOCK_FLAG(verbose) = saved_flag
        #endif  // GTEST_HAS_STREAM_REDIRECTION

        def test_NaggyMockTest_AllowsExpectedCall():
            var naggy_foo: NaggyMock[MockFoo] = NaggyMock[MockFoo]()
            EXPECT_CALL(naggy_foo, DoThis())
            naggy_foo.DoThis()

        def test_NaggyMockTest_UnexpectedCallFails():
            var naggy_foo: NaggyMock[MockFoo] = NaggyMock[MockFoo]()
            EXPECT_CALL(naggy_foo, DoThis()).Times(0)
            EXPECT_NONFATAL_FAILURE(naggy_foo.DoThis(),
                                    "called more times than expected")

        def test_NaggyMockTest_NonDefaultConstructor():
            var naggy_bar: NaggyMock[MockBar] = NaggyMock[MockBar]("hi")
            EXPECT_EQ("hi", naggy_bar.str())
            naggy_bar.This()
            naggy_bar.That(5, true)

        def test_NaggyMockTest_NonDefaultConstructor10():
            var naggy_bar: NaggyMock[MockBar] = NaggyMock[MockBar]('0', '1', "2", "3", '4', '5',
                                                                     "6", "7", true, false)
            EXPECT_EQ("01234567TF", naggy_bar.str())
            naggy_bar.This()
            naggy_bar.That(5, true)

        def test_NaggyMockTest_AllowLeak():
            var leaked: NaggyMock[MockFoo] = new NaggyMock[MockFoo]()
            Mock.AllowLeak(leaked)
            EXPECT_CALL(*leaked, DoThis())
            leaked->DoThis()

        def test_NaggyMockTest_MoveOnlyConstructor():
            var naggy_baz: NaggyMock[MockBaz] = NaggyMock[MockBaz](MockBaz.MoveOnly{})

        def test_NaggyMockTest_AcceptsClassNamedMock():
            var naggy: NaggyMock[::Mock] = NaggyMock[::Mock]()
            EXPECT_CALL(naggy, DoThis())
            naggy.DoThis()

        def test_NaggyMockTest_IsNaggyInDestructor():
            let saved_flag: String = GMOCK_FLAG(verbose)
            GMOCK_FLAG(verbose) = "warning"
            CaptureStdout()
            {
                var naggy_on_destroy: NaggyMock[CallsMockMethodInDestructor] = NaggyMock[CallsMockMethodInDestructor]()
            }
            EXPECT_THAT(GetCapturedStdout(),
                        HasSubstr("Uninteresting mock function call"))
            GMOCK_FLAG(verbose) = saved_flag

        def test_NaggyMockTest_IsNaggy_IsNice_IsStrict():
            var naggy_foo: NaggyMock[MockFoo] = NaggyMock[MockFoo]()
            EXPECT_TRUE(Mock.IsNaggy(&naggy_foo))
            EXPECT_FALSE(Mock.IsNice(&naggy_foo))
            EXPECT_FALSE(Mock.IsStrict(&naggy_foo))

        def test_StrictMockTest_AllowsExpectedCall():
            var strict_foo: StrictMock[MockFoo] = StrictMock[MockFoo]()
            EXPECT_CALL(strict_foo, DoThis())
            strict_foo.DoThis()

        def test_StrictMockTest_UnexpectedCallFails():
            var strict_foo: StrictMock[MockFoo] = StrictMock[MockFoo]()
            EXPECT_CALL(strict_foo, DoThis()).Times(0)
            EXPECT_NONFATAL_FAILURE(strict_foo.DoThis(),
                                    "called more times than expected")

        def test_StrictMockTest_UninterestingCallFails():
            var strict_foo: StrictMock[MockFoo] = StrictMock[MockFoo]()
            EXPECT_NONFATAL_FAILURE(strict_foo.DoThis(),
                                    "Uninteresting mock function call")

        def test_StrictMockTest_UninterestingCallFailsAfterDeath():
            var strict_foo: StrictMock[MockFoo] = new StrictMock[MockFoo]()
            ON_CALL(*strict_foo, DoThis())
                .WillByDefault(Invoke(strict_foo, &MockFoo::Delete))
            EXPECT_NONFATAL_FAILURE(strict_foo->DoThis(),
                                    "Uninteresting mock function call")

        def test_StrictMockTest_NonDefaultConstructor():
            var strict_bar: StrictMock[MockBar] = StrictMock[MockBar]("hi")
            EXPECT_EQ("hi", strict_bar.str())
            EXPECT_NONFATAL_FAILURE(strict_bar.That(5, true),
                                    "Uninteresting mock function call")

        def test_StrictMockTest_NonDefaultConstructor10():
            var strict_bar: StrictMock[MockBar] = StrictMock[MockBar]('a', 'b', "c", "d", 'e', 'f',
                                                                       "g", "h", true, false)
            EXPECT_EQ("abcdefghTF", strict_bar.str())
            EXPECT_NONFATAL_FAILURE(strict_bar.That(5, true),
                                    "Uninteresting mock function call")

        def test_StrictMockTest_AllowLeak():
            var leaked: StrictMock[MockFoo] = new StrictMock[MockFoo]()
            Mock.AllowLeak(leaked)
            EXPECT_CALL(*leaked, DoThis())
            leaked->DoThis()

        def test_StrictMockTest_MoveOnlyConstructor():
            var strict_baz: StrictMock[MockBaz] = StrictMock[MockBaz](MockBaz.MoveOnly{})

        def test_StrictMockTest_AcceptsClassNamedMock():
            var strict: StrictMock[::Mock] = StrictMock[::Mock]()
            EXPECT_CALL(strict, DoThis())
            strict.DoThis()

        def test_StrictMockTest_IsStrictInDestructor():
            EXPECT_NONFATAL_FAILURE(
                {
                    var strict_on_destroy: StrictMock[CallsMockMethodInDestructor] = StrictMock[CallsMockMethodInDestructor]()
                },
                "Uninteresting mock function call")

        def test_StrictMockTest_IsNaggy_IsNice_IsStrict():
            var strict_foo: StrictMock[MockFoo] = StrictMock[MockFoo]()
            EXPECT_FALSE(Mock.IsNaggy(&strict_foo))
            EXPECT_FALSE(Mock.IsNice(&strict_foo))
            EXPECT_TRUE(Mock.IsStrict(&strict_foo))