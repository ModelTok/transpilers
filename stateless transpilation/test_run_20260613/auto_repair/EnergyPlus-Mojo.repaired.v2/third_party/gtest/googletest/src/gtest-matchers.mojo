from gtest.internal.gtest-internal import *
from gtest.internal.gtest-port import *
from gtest.gtest-matchers import *
from string import String

namespace testing:

    def Matcher[const String&].__init__(inout self, s: const String&):
        self = Eq(s)

    def Matcher[const String&].__init__(inout self, s: const char*):
        self = Eq(String(s))

    def Matcher[String].__init__(inout self, s: const String&):
        self = Eq(s)

    def Matcher[String].__init__(inout self, s: const char*):
        self = Eq(String(s))

    #if GTEST_INTERNAL_HAS_STRING_VIEW
    def Matcher[const internal.StringView&].__init__(inout self, s: const String&):
        self = Eq(s)

    def Matcher[const internal.StringView&].__init__(inout self, s: const char*):
        self = Eq(String(s))

    def Matcher[const internal.StringView&].__init__(inout self, s: internal.StringView):
        self = Eq(String(s))

    def Matcher[internal.StringView].__init__(inout self, s: const String&):
        self = Eq(s)

    def Matcher[internal.StringView].__init__(inout self, s: const char*):
        self = Eq(String(s))

    def Matcher[internal.StringView].__init__(inout self, s: internal.StringView):
        self = Eq(String(s))
    #endif  // GTEST_INTERNAL_HAS_STRING_VIEW

end namespace testing