from gtest.internal.gtest-port import *
from gtest.gtest import *
from gtest.gtest-spi import *
from src.gtest-internal-inl import *
from memory import *
from list import *
from vector import *
from pair import make_pair, pair
from stdlib import *

# GTEST_OS_MAC is not defined in Mojo, so we skip the time.h include
# #if GTEST_OS_MAC
# # include <time.h>
# #endif  // GTEST_OS_MAC

# using make_pair;
# using pair;

namespace testing:
    namespace internal:
        @TEST
        def IsXDigitTest_WorksForNarrowAscii():
            EXPECT_TRUE(IsXDigit('0'))
            EXPECT_TRUE(IsXDigit('9'))
            EXPECT_TRUE(IsXDigit('A'))
            EXPECT_TRUE(IsXDigit('F'))
            EXPECT_TRUE(IsXDigit('a'))
            EXPECT_TRUE(IsXDigit('f'))
            EXPECT_FALSE(IsXDigit('-'))
            EXPECT_FALSE(IsXDigit('g'))
            EXPECT_FALSE(IsXDigit('G'))

        @TEST
        def IsXDigitTest_ReturnsFalseForNarrowNonAscii():
            EXPECT_FALSE(IsXDigit(static_cast[char]('\x80')))
            EXPECT_FALSE(IsXDigit(static_cast[char]('0' | '\x80')))

        @TEST
        def IsXDigitTest_WorksForWideAscii():
            EXPECT_TRUE(IsXDigit(L'0'))
            EXPECT_TRUE(IsXDigit(L'9'))
            EXPECT_TRUE(IsXDigit(L'A'))
            EXPECT_TRUE(IsXDigit(L'F'))
            EXPECT_TRUE(IsXDigit(L'a'))
            EXPECT_TRUE(IsXDigit(L'f'))
            EXPECT_FALSE(IsXDigit(L'-'))
            EXPECT_FALSE(IsXDigit(L'g'))
            EXPECT_FALSE(IsXDigit(L'G'))

        @TEST
        def IsXDigitTest_ReturnsFalseForWideNonAscii():
            EXPECT_FALSE(IsXDigit(static_cast[wchar_t](0x80)))
            EXPECT_FALSE(IsXDigit(static_cast[wchar_t](L'0' | 0x80)))
            EXPECT_FALSE(IsXDigit(static_cast[wchar_t](L'0' | 0x100)))

        class Base:
            def __init__(inout self):
                self.member_ = 0

            def __init__(inout self, n: Int):
                self.member_ = n

            def __copyinit__(inout self, other: Self):
                self.member_ = other.member_

            def __del__(owned self):

            def member(inout self) -> Int:
                return self.member_

            var member_: Int

        class Derived(Base):
            def __init__(inout self, n: Int):
                Base.__init__(self, n)

        @TEST
        def ImplicitCastTest_ConvertsPointers():
            var derived = Derived(0)
            EXPECT_TRUE(&derived == ImplicitCast_[Base](&derived))

        @TEST
        def ImplicitCastTest_CanUseInheritance():
            var derived = Derived(1)
            var base = ImplicitCast_[Base](derived)
            EXPECT_EQ(derived.member(), base.member())

        class Castable:
            def __init__(inout self, converted: Bool):
                self.converted_ = converted

            def __cast__(inout self, _: Base) -> Base:
                self.converted_ = True
                return Base()

            var converted_: Bool

        @TEST
        def ImplicitCastTest_CanUseNonConstCastOperator():
            var converted = False
            var castable = Castable(&converted)
            var base = ImplicitCast_[Base](castable)
            EXPECT_TRUE(converted)

        class ConstCastable:
            def __init__(inout self, converted: Bool):
                self.converted_ = converted

            def __cast__(self, _: Base) -> Base:
                self.converted_ = True
                return Base()

            var converted_: Bool

        @TEST
        def ImplicitCastTest_CanUseConstCastOperatorOnConstValues():
            var converted = False
            var const_castable = ConstCastable(&converted)
            var base = ImplicitCast_[Base](const_castable)
            EXPECT_TRUE(converted)

        class ConstAndNonConstCastable:
            def __init__(inout self, converted: Bool, const_converted: Bool):
                self.converted_ = converted
                self.const_converted_ = const_converted

            def __cast__(inout self, _: Base) -> Base:
                self.converted_ = True
                return Base()

            def __cast__(self, _: Base) -> Base:
                self.const_converted_ = True
                return Base()

            var converted_: Bool
            var const_converted_: Bool

        @TEST
        def ImplicitCastTest_CanSelectBetweenConstAndNonConstCasrAppropriately():
            var converted = False
            var const_converted = False
            var castable = ConstAndNonConstCastable(&converted, &const_converted)
            var base = ImplicitCast_[Base](castable)
            EXPECT_TRUE(converted)
            EXPECT_FALSE(const_converted)
            converted = False
            const_converted = False
            var const_castable = ConstAndNonConstCastable(&converted, &const_converted)
            base = ImplicitCast_[Base](const_castable)
            EXPECT_FALSE(converted)
            EXPECT_TRUE(const_converted)

        class To:
            def __init__(inout self, converted: Bool):
                converted = True

        @TEST
        def ImplicitCastTest_CanUseImplicitConstructor():
            var converted = False
            var to = ImplicitCast_[To](&converted)
            _ = to
            EXPECT_TRUE(converted)

        # #ifdef __GNUC__
        # #pragma GCC diagnostic push
        # #pragma GCC diagnostic ignored "-Wdangling-else"
        # #pragma GCC diagnostic ignored "-Wempty-body"
        # #pragma GCC diagnostic ignored "-Wpragmas"
        # #endif

        @TEST
        def GtestCheckSyntaxTest_BehavesLikeASingleStatement():
            if AlwaysFalse():
                GTEST_CHECK_(False) << "This should never be executed; " \
                                       "It's a compilation test only."
            if AlwaysTrue():
                GTEST_CHECK_(True)
            else:
                pass  # NOLINT
            if AlwaysFalse():
                pass  # NOLINT
            else:
                GTEST_CHECK_(True) << ""

        # #ifdef __GNUC__
        # #pragma GCC diagnostic pop
        # #endif

        @TEST
        def GtestCheckSyntaxTest_WorksWithSwitch():
            var _switch_val = 0
            if _switch_val == 1:

            else:
                GTEST_CHECK_(True)
            if _switch_val == 0:
                GTEST_CHECK_(True) << "Check failed in switch case"

        @TEST
        def FormatFileLocationTest_FormatsFileLocation():
            EXPECT_PRED_FORMAT2(IsSubstring, "foo.cc", FormatFileLocation("foo.cc", 42))
            EXPECT_PRED_FORMAT2(IsSubstring, "42", FormatFileLocation("foo.cc", 42))

        @TEST
        def FormatFileLocationTest_FormatsUnknownFile():
            EXPECT_PRED_FORMAT2(IsSubstring, "unknown file",
                                FormatFileLocation(None, 42))
            EXPECT_PRED_FORMAT2(IsSubstring, "42", FormatFileLocation(None, 42))

        @TEST
        def FormatFileLocationTest_FormatsUknownLine():
            EXPECT_EQ("foo.cc:", FormatFileLocation("foo.cc", -1))

        @TEST
        def FormatFileLocationTest_FormatsUknownFileAndLine():
            EXPECT_EQ("unknown file:", FormatFileLocation(None, -1))

        @TEST
        def FormatCompilerIndependentFileLocationTest_FormatsFileLocation():
            EXPECT_EQ("foo.cc:42", FormatCompilerIndependentFileLocation("foo.cc", 42))

        @TEST
        def FormatCompilerIndependentFileLocationTest_FormatsUknownFile():
            EXPECT_EQ("unknown file:42",
                      FormatCompilerIndependentFileLocation(None, 42))

        @TEST
        def FormatCompilerIndependentFileLocationTest_FormatsUknownLine():
            EXPECT_EQ("foo.cc", FormatCompilerIndependentFileLocation("foo.cc", -1))

        @TEST
        def FormatCompilerIndependentFileLocationTest_FormatsUknownFileAndLine():
            EXPECT_EQ("unknown file", FormatCompilerIndependentFileLocation(None, -1))

        # #if GTEST_OS_LINUX || GTEST_OS_MAC || GTEST_OS_QNX || GTEST_OS_FUCHSIA || \
        #     GTEST_OS_DRAGONFLY || GTEST_OS_FREEBSD || GTEST_OS_GNU_KFREEBSD || \
        #     GTEST_OS_NETBSD || GTEST_OS_OPENBSD
        # void* ThreadFunc(void* data) {
        #   internal::Mutex* mutex = static_cast<internal::Mutex*>(data);
        #   mutex->Lock();
        #   mutex->Unlock();
        #   return None;
        # }
        # TEST(GetThreadCountTest, ReturnsCorrectValue) {
        #   size_t starting_count = GetThreadCount();
        #   pthread_t       thread_id;
        #   internal::Mutex mutex;
        #   {
        #     internal::MutexLock lock(&mutex);
        #     pthread_attr_t  attr;
        #     ASSERT_EQ(0, pthread_attr_init(&attr));
        #     ASSERT_EQ(0, pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE));
        #     int status = pthread_create(&thread_id, &attr, &ThreadFunc, &mutex);
        #     ASSERT_EQ(0, pthread_attr_destroy(&attr));
        #     ASSERT_EQ(0, status);
        #     EXPECT_EQ(starting_count + 1, GetThreadCount());
        #   }
        #   void* dummy;
        #   ASSERT_EQ(0, pthread_join(thread_id, &dummy));
        #   for (int i = 0; i < 5; ++i) {
        #     if (GetThreadCount() == starting_count)
        #       break;
        #     SleepMilliseconds(100);
        #   }
        #   EXPECT_EQ(starting_count, GetThreadCount());
        # }
        # #else
        @TEST
        def GetThreadCountTest_ReturnsZeroWhenUnableToCountThreads():
            EXPECT_EQ(0, GetThreadCount())
        # #endif  // GTEST_OS_LINUX || GTEST_OS_MAC || GTEST_OS_QNX || GTEST_OS_FUCHSIA

        @TEST
        def GtestCheckDeathTest_DiesWithCorrectOutputOnFailure():
            var a_false_condition = False
            var regex = "googletest-port-test\\.cc:\\d+.*a_false_condition.*Extra info.*"
            EXPECT_DEATH_IF_SUPPORTED(GTEST_CHECK_(a_false_condition) << "Extra info",
                                      regex)

        # #if GTEST_HAS_DEATH_TEST
        @TEST
        def GtestCheckDeathTest_LivesSilentlyOnSuccess():
            EXPECT_EXIT({
                GTEST_CHECK_(True) << "Extra info"
                ::std.cerr << "Success\n"
                exit(0)
            },
            ExitedWithCode(0), "Success")
        # #endif  // GTEST_HAS_DEATH_TEST

        @TEST
        def RegexEngineSelectionTest_SelectsCorrectRegexEngine():
            # #if !GTEST_USES_PCRE
            # # if GTEST_HAS_POSIX_RE
            #   EXPECT_TRUE(GTEST_USES_POSIX_RE);
            # # else
            #   EXPECT_TRUE(GTEST_USES_SIMPLE_RE);
            # # endif
            # #endif  // !GTEST_USES_PCRE

        # #if GTEST_USES_POSIX_RE
        # template <Str>
        # class RETest : public ::testing::Test {};
        # typedef testing::Types< ::string, const char*> StringTypes;
        # TYPED_TEST_SUITE(RETest, StringTypes);
        # TYPED_TEST(RETest, ImplicitConstructorWorks) {
        #   const RE empty(TypeParam(""));
        #   EXPECT_STREQ("", empty.pattern());
        #   const RE simple(TypeParam("hello"));
        #   EXPECT_STREQ("hello", simple.pattern());
        #   const RE normal(TypeParam(".*(\\w+)"));
        #   EXPECT_STREQ(".*(\\w+)", normal.pattern());
        # }
        # TYPED_TEST(RETest, RejectsInvalidRegex) {
        #   EXPECT_NONFATAL_FAILURE({
        #     const RE invalid(TypeParam("?"));
        #   }, "\"?\" is not a valid POSIX Extended regular expression.");
        # }
        # TYPED_TEST(RETest, FullMatchWorks) {
        #   const RE empty(TypeParam(""));
        #   EXPECT_TRUE(RE::FullMatch(TypeParam(""), empty));
        #   EXPECT_FALSE(RE::FullMatch(TypeParam("a"), empty));
        #   const RE re(TypeParam("a.*z"));
        #   EXPECT_TRUE(RE::FullMatch(TypeParam("az"), re));
        #   EXPECT_TRUE(RE::FullMatch(TypeParam("axyz"), re));
        #   EXPECT_FALSE(RE::FullMatch(TypeParam("baz"), re));
        #   EXPECT_FALSE(RE::FullMatch(TypeParam("azy"), re));
        # }
        # TYPED_TEST(RETest, PartialMatchWorks) {
        #   const RE empty(TypeParam(""));
        #   EXPECT_TRUE(RE::PartialMatch(TypeParam(""), empty));
        #   EXPECT_TRUE(RE::PartialMatch(TypeParam("a"), empty));
        #   const RE re(TypeParam("a.*z"));
        #   EXPECT_TRUE(RE::PartialMatch(TypeParam("az"), re));
        #   EXPECT_TRUE(RE::PartialMatch(TypeParam("axyz"), re));
        #   EXPECT_TRUE(RE::PartialMatch(TypeParam("baz"), re));
        #   EXPECT_TRUE(RE::PartialMatch(TypeParam("azy"), re));
        #   EXPECT_FALSE(RE::PartialMatch(TypeParam("zza"), re));
        # }
        # #elif GTEST_USES_SIMPLE_RE

        @TEST
        def IsInSetTest_NulCharIsNotInAnySet():
            EXPECT_FALSE(IsInSet('\0', ""))
            EXPECT_FALSE(IsInSet('\0', "\0"))
            EXPECT_FALSE(IsInSet('\0', "a"))

        @TEST
        def IsInSetTest_WorksForNonNulChars():
            EXPECT_FALSE(IsInSet('a', "Ab"))
            EXPECT_FALSE(IsInSet('c', ""))
            EXPECT_TRUE(IsInSet('b', "bcd"))
            EXPECT_TRUE(IsInSet('b', "ab"))

        @TEST
        def IsAsciiDigitTest_IsFalseForNonDigit():
            EXPECT_FALSE(IsAsciiDigit('\0'))
            EXPECT_FALSE(IsAsciiDigit(' '))
            EXPECT_FALSE(IsAsciiDigit('+'))
            EXPECT_FALSE(IsAsciiDigit('-'))
            EXPECT_FALSE(IsAsciiDigit('.'))
            EXPECT_FALSE(IsAsciiDigit('a'))

        @TEST
        def IsAsciiDigitTest_IsTrueForDigit():
            EXPECT_TRUE(IsAsciiDigit('0'))
            EXPECT_TRUE(IsAsciiDigit('1'))
            EXPECT_TRUE(IsAsciiDigit('5'))
            EXPECT_TRUE(IsAsciiDigit('9'))

        @TEST
        def IsAsciiPunctTest_IsFalseForNonPunct():
            EXPECT_FALSE(IsAsciiPunct('\0'))
            EXPECT_FALSE(IsAsciiPunct(' '))
            EXPECT_FALSE(IsAsciiPunct('\n'))
            EXPECT_FALSE(IsAsciiPunct('a'))
            EXPECT_FALSE(IsAsciiPunct('0'))

        @TEST
        def IsAsciiPunctTest_IsTrueForPunct():
            var p = "^-!\"#$%&'()*+,./:;<=>?@[\\]_`{|}~"
            for i in range(len(p)):
                EXPECT_PRED1(IsAsciiPunct, p[i])

        @TEST
        def IsRepeatTest_IsFalseForNonRepeatChar():
            EXPECT_FALSE(IsRepeat('\0'))
            EXPECT_FALSE(IsRepeat(' '))
            EXPECT_FALSE(IsRepeat('a'))
            EXPECT_FALSE(IsRepeat('1'))
            EXPECT_FALSE(IsRepeat('-'))

        @TEST
        def IsRepeatTest_IsTrueForRepeatChar():
            EXPECT_TRUE(IsRepeat('?'))
            EXPECT_TRUE(IsRepeat('*'))
            EXPECT_TRUE(IsRepeat('+'))

        @TEST
        def IsAsciiWhiteSpaceTest_IsFalseForNonWhiteSpace():
            EXPECT_FALSE(IsAsciiWhiteSpace('\0'))
            EXPECT_FALSE(IsAsciiWhiteSpace('a'))
            EXPECT_FALSE(IsAsciiWhiteSpace('1'))
            EXPECT_FALSE(IsAsciiWhiteSpace('+'))
            EXPECT_FALSE(IsAsciiWhiteSpace('_'))

        @TEST
        def IsAsciiWhiteSpaceTest_IsTrueForWhiteSpace():
            EXPECT_TRUE(IsAsciiWhiteSpace(' '))
            EXPECT_TRUE(IsAsciiWhiteSpace('\n'))
            EXPECT_TRUE(IsAsciiWhiteSpace('\r'))
            EXPECT_TRUE(IsAsciiWhiteSpace('\t'))
            EXPECT_TRUE(IsAsciiWhiteSpace('\v'))
            EXPECT_TRUE(IsAsciiWhiteSpace('\f'))

        @TEST
        def IsAsciiWordCharTest_IsFalseForNonWordChar():
            EXPECT_FALSE(IsAsciiWordChar('\0'))
            EXPECT_FALSE(IsAsciiWordChar('+'))
            EXPECT_FALSE(IsAsciiWordChar('.'))
            EXPECT_FALSE(IsAsciiWordChar(' '))
            EXPECT_FALSE(IsAsciiWordChar('\n'))

        @TEST
        def IsAsciiWordCharTest_IsTrueForLetter():
            EXPECT_TRUE(IsAsciiWordChar('a'))
            EXPECT_TRUE(IsAsciiWordChar('b'))
            EXPECT_TRUE(IsAsciiWordChar('A'))
            EXPECT_TRUE(IsAsciiWordChar('Z'))

        @TEST
        def IsAsciiWordCharTest_IsTrueForDigit():
            EXPECT_TRUE(IsAsciiWordChar('0'))
            EXPECT_TRUE(IsAsciiWordChar('1'))
            EXPECT_TRUE(IsAsciiWordChar('7'))
            EXPECT_TRUE(IsAsciiWordChar('9'))

        @TEST
        def IsAsciiWordCharTest_IsTrueForUnderscore():
            EXPECT_TRUE(IsAsciiWordChar('_'))

        @TEST
        def IsValidEscapeTest_IsFalseForNonPrintable():
            EXPECT_FALSE(IsValidEscape('\0'))
            EXPECT_FALSE(IsValidEscape('\007'))

        @TEST
        def IsValidEscapeTest_IsFalseForDigit():
            EXPECT_FALSE(IsValidEscape('0'))
            EXPECT_FALSE(IsValidEscape('9'))

        @TEST
        def IsValidEscapeTest_IsFalseForWhiteSpace():
            EXPECT_FALSE(IsValidEscape(' '))
            EXPECT_FALSE(IsValidEscape('\n'))

        @TEST
        def IsValidEscapeTest_IsFalseForSomeLetter():
            EXPECT_FALSE(IsValidEscape('a'))
            EXPECT_FALSE(IsValidEscape('Z'))

        @TEST
        def IsValidEscapeTest_IsTrueForPunct():
            EXPECT_TRUE(IsValidEscape('.'))
            EXPECT_TRUE(IsValidEscape('-'))
            EXPECT_TRUE(IsValidEscape('^'))
            EXPECT_TRUE(IsValidEscape('$'))
            EXPECT_TRUE(IsValidEscape('('))
            EXPECT_TRUE(IsValidEscape(']'))
            EXPECT_TRUE(IsValidEscape('{'))
            EXPECT_TRUE(IsValidEscape('|'))

        @TEST
        def IsValidEscapeTest_IsTrueForSomeLetter():
            EXPECT_TRUE(IsValidEscape('d'))
            EXPECT_TRUE(IsValidEscape('D'))
            EXPECT_TRUE(IsValidEscape('s'))
            EXPECT_TRUE(IsValidEscape('S'))
            EXPECT_TRUE(IsValidEscape('w'))
            EXPECT_TRUE(IsValidEscape('W'))

        @TEST
        def AtomMatchesCharTest_EscapedPunct():
            EXPECT_FALSE(AtomMatchesChar(True, '\\', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, '\\', ' '))
            EXPECT_FALSE(AtomMatchesChar(True, '_', '.'))
            EXPECT_FALSE(AtomMatchesChar(True, '.', 'a'))
            EXPECT_TRUE(AtomMatchesChar(True, '\\', '\\'))
            EXPECT_TRUE(AtomMatchesChar(True, '_', '_'))
            EXPECT_TRUE(AtomMatchesChar(True, '+', '+'))
            EXPECT_TRUE(AtomMatchesChar(True, '.', '.'))

        @TEST
        def AtomMatchesCharTest_Escaped_d():
            EXPECT_FALSE(AtomMatchesChar(True, 'd', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, 'd', 'a'))
            EXPECT_FALSE(AtomMatchesChar(True, 'd', '.'))
            EXPECT_TRUE(AtomMatchesChar(True, 'd', '0'))
            EXPECT_TRUE(AtomMatchesChar(True, 'd', '9'))

        @TEST
        def AtomMatchesCharTest_Escaped_D():
            EXPECT_FALSE(AtomMatchesChar(True, 'D', '0'))
            EXPECT_FALSE(AtomMatchesChar(True, 'D', '9'))
            EXPECT_TRUE(AtomMatchesChar(True, 'D', '\0'))
            EXPECT_TRUE(AtomMatchesChar(True, 'D', 'a'))
            EXPECT_TRUE(AtomMatchesChar(True, 'D', '-'))

        @TEST
        def AtomMatchesCharTest_Escaped_s():
            EXPECT_FALSE(AtomMatchesChar(True, 's', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, 's', 'a'))
            EXPECT_FALSE(AtomMatchesChar(True, 's', '.'))
            EXPECT_FALSE(AtomMatchesChar(True, 's', '9'))
            EXPECT_TRUE(AtomMatchesChar(True, 's', ' '))
            EXPECT_TRUE(AtomMatchesChar(True, 's', '\n'))
            EXPECT_TRUE(AtomMatchesChar(True, 's', '\t'))

        @TEST
        def AtomMatchesCharTest_Escaped_S():
            EXPECT_FALSE(AtomMatchesChar(True, 'S', ' '))
            EXPECT_FALSE(AtomMatchesChar(True, 'S', '\r'))
            EXPECT_TRUE(AtomMatchesChar(True, 'S', '\0'))
            EXPECT_TRUE(AtomMatchesChar(True, 'S', 'a'))
            EXPECT_TRUE(AtomMatchesChar(True, 'S', '9'))

        @TEST
        def AtomMatchesCharTest_Escaped_w():
            EXPECT_FALSE(AtomMatchesChar(True, 'w', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, 'w', '+'))
            EXPECT_FALSE(AtomMatchesChar(True, 'w', ' '))
            EXPECT_FALSE(AtomMatchesChar(True, 'w', '\n'))
            EXPECT_TRUE(AtomMatchesChar(True, 'w', '0'))
            EXPECT_TRUE(AtomMatchesChar(True, 'w', 'b'))
            EXPECT_TRUE(AtomMatchesChar(True, 'w', 'C'))
            EXPECT_TRUE(AtomMatchesChar(True, 'w', '_'))

        @TEST
        def AtomMatchesCharTest_Escaped_W():
            EXPECT_FALSE(AtomMatchesChar(True, 'W', 'A'))
            EXPECT_FALSE(AtomMatchesChar(True, 'W', 'b'))
            EXPECT_FALSE(AtomMatchesChar(True, 'W', '9'))
            EXPECT_FALSE(AtomMatchesChar(True, 'W', '_'))
            EXPECT_TRUE(AtomMatchesChar(True, 'W', '\0'))
            EXPECT_TRUE(AtomMatchesChar(True, 'W', '*'))
            EXPECT_TRUE(AtomMatchesChar(True, 'W', '\n'))

        @TEST
        def AtomMatchesCharTest_EscapedWhiteSpace():
            EXPECT_FALSE(AtomMatchesChar(True, 'f', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, 'f', '\n'))
            EXPECT_FALSE(AtomMatchesChar(True, 'n', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, 'n', '\r'))
            EXPECT_FALSE(AtomMatchesChar(True, 'r', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, 'r', 'a'))
            EXPECT_FALSE(AtomMatchesChar(True, 't', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, 't', 't'))
            EXPECT_FALSE(AtomMatchesChar(True, 'v', '\0'))
            EXPECT_FALSE(AtomMatchesChar(True, 'v', '\f'))
            EXPECT_TRUE(AtomMatchesChar(True, 'f', '\f'))
            EXPECT_TRUE(AtomMatchesChar(True, 'n', '\n'))
            EXPECT_TRUE(AtomMatchesChar(True, 'r', '\r'))
            EXPECT_TRUE(AtomMatchesChar(True, 't', '\t'))
            EXPECT_TRUE(AtomMatchesChar(True, 'v', '\v'))

        @TEST
        def AtomMatchesCharTest_UnescapedDot():
            EXPECT_FALSE(AtomMatchesChar(False, '.', '\n'))
            EXPECT_TRUE(AtomMatchesChar(False, '.', '\0'))
            EXPECT_TRUE(AtomMatchesChar(False, '.', '.'))
            EXPECT_TRUE(AtomMatchesChar(False, '.', 'a'))
            EXPECT_TRUE(AtomMatchesChar(False, '.', ' '))

        @TEST
        def AtomMatchesCharTest_UnescapedChar():
            EXPECT_FALSE(AtomMatchesChar(False, 'a', '\0'))
            EXPECT_FALSE(AtomMatchesChar(False, 'a', 'b'))
            EXPECT_FALSE(AtomMatchesChar(False, '$', 'a'))
            EXPECT_TRUE(AtomMatchesChar(False, '$', '$'))
            EXPECT_TRUE(AtomMatchesChar(False, '5', '5'))
            EXPECT_TRUE(AtomMatchesChar(False, 'Z', 'Z'))

        @TEST
        def ValidateRegexTest_GeneratesFailureAndReturnsFalseForInvalid():
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex(None)),
                                    "NULL is not a valid simple regular expression")
            EXPECT_NONFATAL_FAILURE(
                ASSERT_FALSE(ValidateRegex("a\\")),
                "Syntax error at index 1 in simple regular expression \"a\\\": ")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("a\\")),
                                    "'\\' cannot appear at the end")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("\\n\\")),
                                    "'\\' cannot appear at the end")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("\\s\\hb")),
                                    "invalid escape sequence \"\\h\"")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("^^")),
                                    "'^' can only appear at the beginning")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex(".*^b")),
                                    "'^' can only appear at the beginning")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("$$")),
                                    "'$' can only appear at the end")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("^$a")),
                                    "'$' can only appear at the end")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("a(b")),
                                    "'(' is unsupported")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("ab)")),
                                    "')' is unsupported")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("[ab")),
                                    "'[' is unsupported")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("a{2")),
                                    "'{' is unsupported")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("?")),
                                    "'?' can only follow a repeatable token")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("^*")),
                                    "'*' can only follow a repeatable token")
            EXPECT_NONFATAL_FAILURE(ASSERT_FALSE(ValidateRegex("5*+")),
                                    "'+' can only follow a repeatable token")

        @TEST
        def ValidateRegexTest_ReturnsTrueForValid():
            EXPECT_TRUE(ValidateRegex(""))
            EXPECT_TRUE(ValidateRegex("a"))
            EXPECT_TRUE(ValidateRegex(".*"))
            EXPECT_TRUE(ValidateRegex("^a_+"))
            EXPECT_TRUE(ValidateRegex("^a\\t\\&?"))
            EXPECT_TRUE(ValidateRegex("09*$"))
            EXPECT_TRUE(ValidateRegex("^Z$"))
            EXPECT_TRUE(ValidateRegex("a\\^Z\\$\\(\\)\\|\\[\\]\\{\\}"))

        @TEST
        def MatchRepetitionAndRegexAtHeadTest_WorksForZeroOrOne():
            EXPECT_FALSE(MatchRepetitionAndRegexAtHead(False, 'a', '?', "a", "ba"))
            EXPECT_FALSE(MatchRepetitionAndRegexAtHead(False, 'a', '?', "b", "aab"))
            EXPECT_TRUE(MatchRepetitionAndRegexAtHead(False, 'a', '?', "b", "ba"))
            EXPECT_TRUE(MatchRepetitionAndRegexAtHead(False, 'a', '?', "b", "ab"))
            EXPECT_TRUE(MatchRepetitionAndRegexAtHead(False, '#', '?', ".", "##"))

        @TEST
        def MatchRepetitionAndRegexAtHeadTest_WorksForZeroOrMany():
            EXPECT_FALSE(MatchRepetitionAndRegexAtHead(False, '.', '*', "a$", "baab"))
            EXPECT_TRUE(MatchRepetitionAndRegexAtHead(False, '.', '*', "b", "bc"))
            EXPECT_TRUE(MatchRepetitionAndRegexAtHead(False, '.', '*', "b", "abc"))
            EXPECT_TRUE(MatchRepetitionAndRegexAtHead(True, 'w', '*', "-", "ab_1-g"))

        @TEST
        def MatchRepetitionAndRegexAtHeadTest_WorksForOneOrMany():
            EXPECT_FALSE(MatchRepetitionAndRegexAtHead(False, '.', '+', "a$", "baab"))
            EXPECT_FALSE(MatchRepetitionAndRegexAtHead(False, '.', '+', "b", "bc"))
            EXPECT_TRUE(MatchRepetitionAndRegexAtHead(False, '.', '+', "b", "abc"))
            EXPECT_TRUE(MatchRepetitionAndRegexAtHead(True, 'w', '+', "-", "ab_1-g"))

        @TEST
        def MatchRegexAtHeadTest_ReturnsTrueForEmptyRegex():
            EXPECT_TRUE(MatchRegexAtHead("", ""))
            EXPECT_TRUE(MatchRegexAtHead("", "ab"))

        @TEST
        def MatchRegexAtHeadTest_WorksWhenDollarIsInRegex():
            EXPECT_FALSE(MatchRegexAtHead("$", "a"))
            EXPECT_TRUE(MatchRegexAtHead("$", ""))
            EXPECT_TRUE(MatchRegexAtHead("a$", "a"))

        @TEST
        def MatchRegexAtHeadTest_WorksWhenRegexStartsWithEscapeSequence():
            EXPECT_FALSE(MatchRegexAtHead("\\w", "+"))
            EXPECT_FALSE(MatchRegexAtHead("\\W", "ab"))
            EXPECT_TRUE(MatchRegexAtHead("\\sa", "\nab"))
            EXPECT_TRUE(MatchRegexAtHead("\\d", "1a"))

        @TEST
        def MatchRegexAtHeadTest_WorksWhenRegexStartsWithRepetition():
            EXPECT_FALSE(MatchRegexAtHead(".+a", "abc"))
            EXPECT_FALSE(MatchRegexAtHead("a?b", "aab"))
            EXPECT_TRUE(MatchRegexAtHead(".*a", "bc12-ab"))
            EXPECT_TRUE(MatchRegexAtHead("a?b", "b"))
            EXPECT_TRUE(MatchRegexAtHead("a?b", "ab"))

        @TEST
        def MatchRegexAtHeadTest_WorksWhenRegexStartsWithRepetionOfEscapeSequence():
            EXPECT_FALSE(MatchRegexAtHead("\\.+a", "abc"))
            EXPECT_FALSE(MatchRegexAtHead("\\s?b", "  b"))
            EXPECT_TRUE(MatchRegexAtHead("\\(*a", "((((ab"))
            EXPECT_TRUE(MatchRegexAtHead("\\^?b", "^b"))
            EXPECT_TRUE(MatchRegexAtHead("\\\\?b", "b"))
            EXPECT_TRUE(MatchRegexAtHead("\\\\?b", "\\b"))

        @TEST
        def MatchRegexAtHeadTest_MatchesSequentially():
            EXPECT_FALSE(MatchRegexAtHead("ab.*c", "acabc"))
            EXPECT_TRUE(MatchRegexAtHead("ab.*c", "ab-fsc"))

        @TEST
        def MatchRegexAnywhereTest_ReturnsFalseWhenStringIsNull():
            EXPECT_FALSE(MatchRegexAnywhere("", None))

        @TEST
        def MatchRegexAnywhereTest_WorksWhenRegexStartsWithCaret():
            EXPECT_FALSE(MatchRegexAnywhere("^a", "ba"))
            EXPECT_FALSE(MatchRegexAnywhere("^$", "a"))
            EXPECT_TRUE(MatchRegexAnywhere("^a", "ab"))
            EXPECT_TRUE(MatchRegexAnywhere("^", "ab"))
            EXPECT_TRUE(MatchRegexAnywhere("^$", ""))

        @TEST
        def MatchRegexAnywhereTest_ReturnsFalseWhenNoMatch():
            EXPECT_FALSE(MatchRegexAnywhere("a", "bcde123"))
            EXPECT_FALSE(MatchRegexAnywhere("a.+a", "--aa88888888"))

        @TEST
        def MatchRegexAnywhereTest_ReturnsTrueWhenMatchingPrefix():
            EXPECT_TRUE(MatchRegexAnywhere("\\w+", "ab1_ - 5"))
            EXPECT_TRUE(MatchRegexAnywhere(".*=", "="))
            EXPECT_TRUE(MatchRegexAnywhere("x.*ab?.*bc", "xaaabc"))

        @TEST
        def MatchRegexAnywhereTest_ReturnsTrueWhenMatchingNonPrefix():
            EXPECT_TRUE(MatchRegexAnywhere("\\w+", "$$$ ab1_ - 5"))
            EXPECT_TRUE(MatchRegexAnywhere("\\.+=", "=  ...="))

        @TEST
        def RETest_ImplicitConstructorWorks():
            var empty = RE("")
            EXPECT_STREQ("", empty.pattern())
            var simple = RE("hello")
            EXPECT_STREQ("hello", simple.pattern())

        @TEST
        def RETest_RejectsInvalidRegex():
            EXPECT_NONFATAL_FAILURE({
                var normal = RE(None)
            }, "NULL is not a valid simple regular expression")
            EXPECT_NONFATAL_FAILURE({
                var normal = RE(".*(\\w+")
            }, "'(' is unsupported")
            EXPECT_NONFATAL_FAILURE({
                var invalid = RE("^?")
            }, "'?' can only follow a repeatable token")

        @TEST
        def RETest_FullMatchWorks():
            var empty = RE("")
            EXPECT_TRUE(RE.FullMatch("", empty))
            EXPECT_FALSE(RE.FullMatch("a", empty))
            var re1 = RE("a")
            EXPECT_TRUE(RE.FullMatch("a", re1))
            var re = RE("a.*z")
            EXPECT_TRUE(RE.FullMatch("az", re))
            EXPECT_TRUE(RE.FullMatch("axyz", re))
            EXPECT_FALSE(RE.FullMatch("baz", re))
            EXPECT_FALSE(RE.FullMatch("azy", re))

        @TEST
        def RETest_PartialMatchWorks():
            var empty = RE("")
            EXPECT_TRUE(RE.PartialMatch("", empty))
            EXPECT_TRUE(RE.PartialMatch("a", empty))
            var re = RE("a.*z")
            EXPECT_TRUE(RE.PartialMatch("az", re))
            EXPECT_TRUE(RE.PartialMatch("axyz", re))
            EXPECT_TRUE(RE.PartialMatch("baz", re))
            EXPECT_TRUE(RE.PartialMatch("azy", re))
            EXPECT_FALSE(RE.PartialMatch("zza", re))

        # #endif  // GTEST_USES_POSIX_RE

        # #if !GTEST_OS_WINDOWS_MOBILE
        @TEST
        def CaptureTest_CapturesStdout():
            CaptureStdout()
            printf("abc")
            EXPECT_STREQ("abc", GetCapturedStdout().c_str())
            CaptureStdout()
            printf("def%cghi", '\0')
            EXPECT_EQ(String("def\0ghi", 7), String(GetCapturedStdout()))

        @TEST
        def CaptureTest_CapturesStderr():
            CaptureStderr()
            fprintf(stderr, "jkl")
            EXPECT_STREQ("jkl", GetCapturedStderr().c_str())
            CaptureStderr()
            fprintf(stderr, "jkl%cmno", '\0')
            EXPECT_EQ(String("jkl\0mno", 7), String(GetCapturedStderr()))

        @TEST
        def CaptureTest_CapturesStdoutAndStderr():
            CaptureStdout()
            CaptureStderr()
            printf("pqr")
            fprintf(stderr, "stu")
            EXPECT_STREQ("pqr", GetCapturedStdout().c_str())
            EXPECT_STREQ("stu", GetCapturedStderr().c_str())

        @TEST
        def CaptureDeathTest_CannotReenterStdoutCapture():
            CaptureStdout()
            EXPECT_DEATH_IF_SUPPORTED(CaptureStdout(),
                                      "Only one stdout capturer can exist at a time")
            GetCapturedStdout()
        # #endif  // !GTEST_OS_WINDOWS_MOBILE

        @TEST
        def ThreadLocalTest_DefaultConstructorInitializesToDefaultValues():
            var t1 = ThreadLocal[Int]()
            EXPECT_EQ(0, t1.get())
            var t2 = ThreadLocal[Pointer[None]]()
            EXPECT_TRUE(t2.get() == None)

        @TEST
        def ThreadLocalTest_SingleParamConstructorInitializesToParam():
            var t1 = ThreadLocal[Int](123)
            EXPECT_EQ(123, t1.get())
            var i = 0
            var t2 = ThreadLocal[Pointer[Int]](&i)
            EXPECT_EQ(&i, t2.get())

        class NoDefaultContructor:
            def __init__(inout self, s: String):

            def __copyinit__(inout self, other: Self):

        @TEST
        def ThreadLocalTest_ValueDefaultContructorIsNotRequiredForParamVersion():
            var bar = ThreadLocal[NoDefaultContructor](NoDefaultContructor("foo"))
            bar.pointer()

        @TEST
        def ThreadLocalTest_GetAndPointerReturnSameValue():
            var thread_local_string = ThreadLocal[String]()
            EXPECT_EQ(thread_local_string.pointer(), &(thread_local_string.get()))
            thread_local_string.set("foo")
            EXPECT_EQ(thread_local_string.pointer(), &(thread_local_string.get()))

        @TEST
        def ThreadLocalTest_PointerAndConstPointerReturnSameValue():
            var thread_local_string = ThreadLocal[String]()
            var const_thread_local_string = thread_local_string
            EXPECT_EQ(thread_local_string.pointer(), const_thread_local_string.pointer())
            thread_local_string.set("foo")
            EXPECT_EQ(thread_local_string.pointer(), const_thread_local_string.pointer())

        # #if GTEST_IS_THREADSAFE
        def AddTwo(param: Pointer[Int]):
            param = param + 2

        @TEST
        def ThreadWithParamTest_ConstructorExecutesThreadFunc():
            var i = 40
            var thread = ThreadWithParam[Pointer[Int]](&AddTwo, &i, None)
            thread.Join()
            EXPECT_EQ(42, i)

        @TEST
        def MutexDeathTest_AssertHeldShouldAssertWhenNotLocked():
            EXPECT_DEATH_IF_SUPPORTED({
                var m = Mutex()
                {
                    var lock = MutexLock(&m)
                }
                m.AssertHeld()
            },
            "thread .*hold")

        @TEST
        def MutexTest_AssertHeldShouldNotAssertWhenLocked():
            var m = Mutex()
            var lock = MutexLock(&m)
            m.AssertHeld()

        class AtomicCounterWithMutex:
            def __init__(inout self, mutex: Mutex):
                self.value_ = 0
                self.mutex_ = mutex
                self.random_ = Random(42)

            def Increment(inout self):
                var lock = MutexLock(self.mutex_)
                var temp = self.value_
                {
                    # #if GTEST_HAS_PTHREAD
                    #   pthread_mutex_t memory_barrier_mutex;
                    #   GTEST_CHECK_POSIX_SUCCESS_(
                    #       pthread_mutex_init(&memory_barrier_mutex, None));
                    #   GTEST_CHECK_POSIX_SUCCESS_(pthread_mutex_lock(&memory_barrier_mutex));
                    #   SleepMilliseconds(static_cast<int>(random_.Generate(30)));
                    #   GTEST_CHECK_POSIX_SUCCESS_(pthread_mutex_unlock(&memory_barrier_mutex));
                    #   GTEST_CHECK_POSIX_SUCCESS_(pthread_mutex_destroy(&memory_barrier_mutex));
                    # #elif GTEST_OS_WINDOWS
                    #   volatile LONG dummy = 0;
                    #   ::InterlockedIncrement(&dummy);
                    #   SleepMilliseconds(static_cast<int>(random_.Generate(30)));
                    #   ::InterlockedIncrement(&dummy);
                    # #else
                    # # error "Memory barrier not implemented on this platform."
                    # #endif  // GTEST_HAS_PTHREAD

                }
                self.value_ = temp + 1

            def value(self) -> Int:
                return self.value_

            var value_: Int
            var mutex_: Mutex
            var random_: Random

        def CountingThreadFunc(param: pair[AtomicCounterWithMutex, Int]):
            for i in range(param.second):
                param.first.Increment()

        @TEST
        def MutexTest_OnlyOneThreadCanLockAtATime():
            var mutex = Mutex()
            var locked_counter = AtomicCounterWithMutex(&mutex)
            alias ThreadType = ThreadWithParam[pair[AtomicCounterWithMutex, Int]]
            var kCycleCount = 20
            var kThreadCount = 7
            var counting_threads = Pointer[ThreadType].alloc(kThreadCount)
            var threads_can_start = Notification()
            for i in range(kThreadCount):
                counting_threads[i] = ThreadType(&CountingThreadFunc,
                                                 make_pair(&locked_counter,
                                                           kCycleCount),
                                                 &threads_can_start)
            threads_can_start.Notify()
            for i in range(kThreadCount):
                counting_threads[i].Join()
            EXPECT_EQ(kCycleCount * kThreadCount, locked_counter.value())

        def RunFromThread[T](func: fn(T) -> None, param: T):
            var thread = ThreadWithParam[T](func, param, None)
            thread.Join()

        def RetrieveThreadLocalValue(param: pair[ThreadLocal[String], String]):
            param.second = param.first.get()

        @TEST
        def ThreadLocalTest_ParameterizedConstructorSetsDefault():
            var thread_local_string = ThreadLocal[String]("foo")
            EXPECT_STREQ("foo", thread_local_string.get().c_str())
            thread_local_string.set("bar")
            EXPECT_STREQ("bar", thread_local_string.get().c_str())
            var result = String("")
            RunFromThread(&RetrieveThreadLocalValue,
                          make_pair(&thread_local_string, &result))
            EXPECT_STREQ("foo", result.c_str())

        class DestructorCall:
            def __init__(inout self):
                self.invoked_ = False
                # #if GTEST_OS_WINDOWS
                #   wait_event_.Reset(::CreateEvent(NULL, TRUE, FALSE, NULL));
                #   GTEST_CHECK_(wait_event_.Get() != NULL);
                # #endif

            def CheckDestroyed(self) -> Bool:
                # #if GTEST_OS_WINDOWS
                #   if (::WaitForSingleObject(wait_event_.Get(), 1000) != WAIT_OBJECT_0)
                #     return false;
                # #endif
                return self.invoked_

            def ReportDestroyed(inout self):
                self.invoked_ = True
                # #if GTEST_OS_WINDOWS
                #   ::SetEvent(wait_event_.Get());
                # #endif

            @staticmethod
            def List() -> List[DestructorCall]:
                return DestructorCall.list_

            @staticmethod
            def ResetList():
                for i in range(len(DestructorCall.list_)):
                    del DestructorCall.list_[i]
                DestructorCall.list_.clear()

            var invoked_: Bool
            # #if GTEST_OS_WINDOWS
            #   AutoHandle wait_event_;
            # #endif
            @staticmethod
            var list_: List[DestructorCall]

        DestructorCall.list_ = List[DestructorCall]()

        class DestructorTracker:
            def __init__(inout self):
                self.index_ = DestructorTracker.GetNewIndex()

            def __copyinit__(inout self, other: Self):
                self.index_ = DestructorTracker.GetNewIndex()

            def __del__(owned self):
                DestructorCall.List()[self.index_].ReportDestroyed()

            @staticmethod
            def GetNewIndex() -> Int:
                DestructorCall.List().push_back(DestructorCall())
                return len(DestructorCall.List()) - 1

            var index_: Int

        alias ThreadParam = ThreadLocal[DestructorTracker]

        def CallThreadLocalGet(thread_local_param: ThreadParam):
            thread_local_param.get()

        @TEST
        def ThreadLocalTest_DestroysManagedObjectForOwnThreadWhenDying():
            DestructorCall.ResetList()
            {
                var thread_local_tracker = ThreadLocal[DestructorTracker]()
                ASSERT_EQ(0, len(DestructorCall.List()))
                thread_local_tracker.get()
                ASSERT_EQ(1, len(DestructorCall.List()))
                ASSERT_FALSE(DestructorCall.List()[0].CheckDestroyed())
            }
            ASSERT_EQ(1, len(DestructorCall.List()))
            EXPECT_TRUE(DestructorCall.List()[0].CheckDestroyed())
            DestructorCall.ResetList()

        @TEST
        def ThreadLocalTest_DestroysManagedObjectAtThreadExit():
            DestructorCall.ResetList()
            {
                var thread_local_tracker = ThreadLocal[DestructorTracker]()
                ASSERT_EQ(0, len(DestructorCall.List()))
                var thread = ThreadWithParam[ThreadParam](&CallThreadLocalGet,
                                                          &thread_local_tracker, None)
                thread.Join()
                ASSERT_EQ(1, len(DestructorCall.List()))
            }
            ASSERT_EQ(1, len(DestructorCall.List()))
            EXPECT_TRUE(DestructorCall.List()[0].CheckDestroyed())
            DestructorCall.ResetList()

        @TEST
        def ThreadLocalTest_ThreadLocalMutationsAffectOnlyCurrentThread():
            var thread_local_string = ThreadLocal[String]()
            thread_local_string.set("Foo")
            EXPECT_STREQ("Foo", thread_local_string.get().c_str())
            var result = String("")
            RunFromThread(&RetrieveThreadLocalValue,
                          make_pair(&thread_local_string, &result))
            EXPECT_TRUE(result.empty())

        # #endif  // GTEST_IS_THREADSAFE

        # #if GTEST_OS_WINDOWS
        # TEST(WindowsTypesTest, HANDLEIsVoidStar) {
        #   StaticAssertTypeEq<HANDLE, void*>();
        # }
        # #if GTEST_OS_WINDOWS_MINGW && !defined(__MINGW64_VERSION_MAJOR)
        # TEST(WindowsTypesTest, _CRITICAL_SECTIONIs_CRITICAL_SECTION) {
        #   StaticAssertTypeEq<CRITICAL_SECTION, _CRITICAL_SECTION>();
        # }
        # #else
        # TEST(WindowsTypesTest, CRITICAL_SECTIONIs_RTL_CRITICAL_SECTION) {
        #   StaticAssertTypeEq<CRITICAL_SECTION, _RTL_CRITICAL_SECTION>();
        # }
        # #endif
        # #endif  // GTEST_OS_WINDOWS