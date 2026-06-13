from gtest.gtest-typed-test import *
from gtest.gtest import *

namespace testing:
    namespace internal:
        def SkipSpaces(str: Pointer[UInt8]) -> Pointer[UInt8]:
            while IsSpace(str[]):
                str += 1
            return str

        def SplitIntoTestNames(src: Pointer[UInt8]) -> List[String]:
            var name_vec = List[String]()
            src = SkipSpaces(src)
            while src != None:
                name_vec.append(StripTrailingSpaces(GetPrefixUntilComma(src)))
                src = SkipComma(src)
            return name_vec

        def TypedTestSuitePState.VerifyRegisteredTestNames(
            self, test_suite_name: Pointer[UInt8], file: Pointer[UInt8], line: Int,
            registered_tests: Pointer[UInt8]) -> Pointer[UInt8]:
            RegisterTypeParameterizedTestSuite(test_suite_name, CodeLocation(file, line))
            alias RegisteredTestIter = RegisteredTestsMap.Iterator
            self.registered_ = True
            var name_vec = SplitIntoTestNames(registered_tests)
            var errors = Message()
            var tests = Set[String]()
            for name_it in name_vec:
                var name = name_it[]
                if tests.count(name) != 0:
                    errors << "Test " << name << " is listed more than once.\n"
                    continue
                if self.registered_tests_.count(name) != 0:
                    tests.insert(name)
                else:
                    errors << "No test named " << name << " can be found in this test suite.\n"
            for it in self.registered_tests_:
                if tests.count(it.first) == 0:
                    errors << "You forgot to list test " << it.first << ".\n"
            var errors_str = errors.GetString()
            if errors_str != "":
                fprintf(stderr, "%s %s", FormatFileLocation(file, line).c_str(), errors_str.c_str())
                fflush(stderr)
                posix.Abort()
            return registered_tests