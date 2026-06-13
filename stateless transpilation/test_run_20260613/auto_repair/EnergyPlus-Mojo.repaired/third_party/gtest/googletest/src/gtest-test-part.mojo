from gtest.gtest-test-part import TestPartResult, TestPartResultArray
from gtest.internal.gtest-port import *
from src.gtest-internal-inl import *

namespace testing:
    using internal.GetUnitTestImpl

    def TestPartResult.ExtractSummary(message: StringRef) -> String:
        var stack_trace: StringRef = strstr(message, internal.kStackTraceMarker)
        if stack_trace == None:
            return String(message)
        else:
            return String(message, stack_trace)

    def operator<<(os: ostream, result: TestPartResult) -> ostream:
        os << internal.FormatFileLocation(result.file_name(), result.line_number())
        os << " "
        if result.type() == TestPartResult.kSuccess:
            os << "Success"
        elif result.type() == TestPartResult.kSkip:
            os << "Skipped"
        elif result.type() == TestPartResult.kFatalFailure:
            os << "Fatal failure"
        else:
            os << "Non-fatal failure"
        os << ":\n"
        os << result.message()
        os << endl
        return os

    def TestPartResultArray.Append(result: TestPartResult):
        array_.push_back(result)

    def TestPartResultArray.GetTestPartResult(index: Int) -> TestPartResult:
        if index < 0 or index >= size():
            printf("\nInvalid index (%d) into TestPartResultArray.\n", index)
            internal.posix.Abort()
        return array_[index]

    def TestPartResultArray.size() -> Int:
        return array_.size()

    namespace internal:
        struct HasNewFatalFailureHelper:
            var has_new_fatal_failure_: Bool
            var original_reporter_: TestPartResultReporter

            def __init__(inout self):
                self.has_new_fatal_failure_ = False
                self.original_reporter_ = GetUnitTestImpl().GetTestPartResultReporterForCurrentThread()
                GetUnitTestImpl().SetTestPartResultReporterForCurrentThread(self)

            def __del__(owned self):
                GetUnitTestImpl().SetTestPartResultReporterForCurrentThread(self.original_reporter_)

            def ReportTestPartResult(inout self, result: TestPartResult):
                if result.fatally_failed():
                    self.has_new_fatal_failure_ = True
                self.original_reporter_.ReportTestPartResult(result)