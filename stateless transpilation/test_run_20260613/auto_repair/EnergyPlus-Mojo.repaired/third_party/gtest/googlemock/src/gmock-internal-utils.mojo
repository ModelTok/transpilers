package testing.internal:

from sys import stdout
from threading import Mutex
from ...gmock.internal.gmock-internal-utils import FailureReporterInterface, Strings
from ...gmock.internal.gmock-port import GMOCK_FLAG, kInfoVerbosity, kErrorVerbosity, kWarning
from ......googletest.include.gtest.gtest import AssertHelper, TestPartResult, Message, GetCurrentOsStackTraceExceptTop, UnitTest, internal as gtest_internal
from ......googletest.include.gtest.internal.gtest-port import posix
from ...gmock.gmock import WithoutMatchers

public func JoinAsTuple(fields: Strings) -> String:
    if fields.size() == 0:
        return ""
    elif fields.size() == 1:
        return fields[0]
    else:
        var result = "(" + fields[0]
        for i in range(1, fields.size()):
            result += ", "
            result += fields[i]
        result += ")"
        return result

public func ConvertIdentifierNameToWords(id_name: String) -> String:
    def IsUpper(c: UInt8) -> Bool:
        return c >= 65 and c <= 90  # 'A' to 'Z'
    def IsAlpha(c: UInt8) -> Bool:
        return (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
    def IsLower(c: UInt8) -> Bool:
        return c >= 97 and c <= 122  # 'a' to 'z'
    def IsDigit(c: UInt8) -> Bool:
        return c >= 48 and c <= 57  # '0' to '9'
    def IsAlNum(c: UInt8) -> Bool:
        return IsAlpha(c) or IsDigit(c)

    var result = String()
    var prev_char: UInt8 = 0
    var idx: Int = 0
    while idx < len(id_name):
        let c = id_name[idx]
        idx += 1
        let starts_new_word = IsUpper(c) or (not IsAlpha(prev_char) and IsLower(c)) or (not IsDigit(prev_char) and IsDigit(c))
        if IsAlNum(c):
            if starts_new_word and result != "":
                result += " "
            # ToLower
            if IsUpper(c):
                result += chr(c + 32)  # Convert to lowercase ASCII
            else:
                result += chr(c)
        prev_char = c
    return result

class GoogleTestFailureReporter(FailureReporterInterface):
    def ReportFailure(owned self, type: FailureType, file: String, line: Int, message: String):
        var helper = AssertHelper(
            TestPartResult.kFatalFailure if type == kFatal else TestPartResult.kNonFatalFailure,
            file,
            line,
            message
        )
        helper = Message()
        if type == kFatal:
            posix.Abort()

public func GetFailureReporter() -> FailureReporterInterface:
    var failure_reporter = GoogleTestFailureReporter()
    return failure_reporter

var g_log_mutex = Mutex()

public func LogIsVisible(severity: LogSeverity) -> Bool:
    if GMOCK_FLAG("verbose") == kInfoVerbosity:
        return True
    elif GMOCK_FLAG("verbose") == kErrorVerbosity:
        return False
    else:
        return severity == kWarning

public func Log(severity: LogSeverity, message: String, stack_frames_to_skip: Int):
    if not LogIsVisible(severity):
        return
    with g_log_mutex:
        if severity == kWarning:
            stdout.write("\nGMOCK WARNING:")
        if message == "" or message[0] != '\n':
            stdout.write("\n")
        stdout.write(message)
        if stack_frames_to_skip >= 0:
            var actual_to_skip: Int
            #ifdef NDEBUG
            actual_to_skip = 0
            #else
            #actual_to_skip = stack_frames_to_skip + 1
            #endif
            # For faithful translation, assuming NDEBUG is not defined
            actual_to_skip = stack_frames_to_skip + 1
            if message != "" and message[len(message)-1] != '\n':
                stdout.write("\n")
            stdout.write("Stack trace:\n")
            stdout.write(GetCurrentOsStackTraceExceptTop(UnitTest.GetInstance(), actual_to_skip))
        stdout.flush()

public func GetWithoutMatchers() -> WithoutMatchers:
    return WithoutMatchers()

public func IllegalDoDefault(file: String, line: Int):
    gtest_internal.Assert(
        False,
        file,
        line,
        "You are using DoDefault() inside a composite action like "
        "DoAll() or WithArgs().  This is not supported for technical "
        "reasons.  Please instead spell out the default action, or "
        "assign the default action to an Action variable and use "
        "the variable in various places."
    )