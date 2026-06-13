/// Mojo translation of jsontest.h + jsontest.cpp
/// Faithful 1:1 conversion with minimal adaptation for Mojo language.

from io import StringWriter
from sys import exit, abort
from builtins import str as _str

# --- Constants ---
alias JSONCPP_USING_SECURE_MEMORY = False
alias JSON_USE_EXCEPTION = True

# --- Helper to mimic setprecision and hexfloat ---
def format_value[T](value: T) -> String:
    """Try to produce a hex-float-like representation, fallback to str."""
    # In Mojo, we can use StringFormat or simply str, but keep original intent.
    return _str(value)

# --- Namespace JsonTest (using a struct as namespace) ---
struct JsonTest:

    # --- Failure ---
    struct Failure:
        var file_: String
        var line_: UInt32
        var expr_: String
        var message_: String
        var nestingLevel_: UInt32

    # --- PredicateContext ---
    struct PredicateContext:
        using Id = UInt32
        var id_: Id
        var file_: String
        var line_: UInt32
        var expr_: String
        var next_: Pointer[PredicateContext]  # None handled by nil
        var failure_: Pointer[Failure]

    # --- TestResult ---
    struct TestResult:
        var predicateId_: PredicateContext.Id = 1
        var predicateStackTail_: Pointer[PredicateContext]
        var failures_: Deque[Failure]
        var name_: String
        var rootPredicateNode_: PredicateContext
        var lastUsedPredicateId_: PredicateContext.Id = 0
        var messageTarget_: Pointer[Failure]

        def __init__(mut self):
            self.rootPredicateNode_.id_ = 0
            self.rootPredicateNode_.next_ = nil[Pointer[PredicateContext]]()
            self.predicateStackTail_ = Pointer.address_of(self.rootPredicateNode_)
            self.failures_ = Deque[Failure]()

        def setTestName(mut self, name: String):
            self.name_ = name

        def addFailure(mut self, file: String, line: UInt32, expr: String = "") -> TestResult:
            var nestingLevel: UInt32 = 0
            var lastNode: Pointer[PredicateContext] = self.rootPredicateNode_.next_
            while lastNode and lastNode.value:
                if lastNode.load().id_ > self.lastUsedPredicateId_:
                    self.lastUsedPredicateId_ = lastNode.load().id_
                    self.addFailureInfo(lastNode.load().file_, lastNode.load().line_, lastNode.load().expr_, nestingLevel)
                    # lastNode.load().failure_ = Pointer.address_of(self.failures_.back())
                nestingLevel += 1
                lastNode = lastNode.load().next_
            self.addFailureInfo(file, line, expr, nestingLevel)
            self.messageTarget_ = Pointer.address_of(self.failures_.back())
            return self

        def addFailureInfo(mut self, file: String, line: UInt32, expr: String, nestingLevel: UInt32):
            var failure = Failure()
            failure.file_ = file
            failure.line_ = line
            if len(expr) > 0:
                failure.expr_ = expr
            failure.nestingLevel_ = nestingLevel
            self.failures_.push_back(failure)

        def popPredicateContext(mut self) -> TestResult:
            var lastNode: Pointer[PredicateContext] = Pointer.address_of(self.rootPredicateNode_)
            while lastNode.load().next_ and lastNode.load().next_.load().next_:
                lastNode = lastNode.load().next_
            var tail: Pointer[PredicateContext] = lastNode.load().next_
            if tail and tail.load().failure_:
                self.messageTarget_ = tail.load().failure_
            self.predicateStackTail_ = lastNode
            lastNode.store().next_ = nil[Pointer[PredicateContext]]()
            return self

        def failed(self) -> Bool:
            return not self.failures_.empty()

        def printFailure(self, printTestName: Bool):
            if self.failures_.empty():
                return
            if printTestName:
                print("* Detail of {0} test failure:".format(self.name_))
            for failure in self.failures_:
                var indent = " " * (failure.nestingLevel_ * 2)
                if len(failure.file_) > 0:
                    print("{0}{1}({2}): ".format(indent, failure.file_, failure.line_), end="")
                if len(failure.expr_) > 0:
                    print("{0}".format(failure.expr_))
                elif len(failure.file_) > 0:
                    print()
                if len(failure.message_) > 0:
                    var reindented = self.indentText(failure.message_, indent + "  ")
                    print("{0}".format(reindented))

        def indentText(self, text: String, indent: String) -> String:
            var reindented = ""
            var lastIndex: Int = 0
            while lastIndex < len(text):
                var nextIndex = text.find("\n", lastIndex)
                if nextIndex == -1:
                    nextIndex = len(text) - 1
                reindented += indent
                reindented += text[lastIndex:nextIndex+1]
                lastIndex = nextIndex + 1
            return reindented

        def addToLastFailure(mut self, message: String) -> TestResult:
            if self.messageTarget_:
                self.messageTarget_.load().message_ += message
            return self

        def __lt__(mut self, value: Int64) -> TestResult:
            return self.addToLastFailure(valueToString(value))

        def __lt__(mut self, value: UInt64) -> TestResult:
            return self.addToLastFailure(valueToString(value))

        def __lt__(mut self, value: Bool) -> TestResult:
            return self.addToLastFailure("true" if value else "false")

    # --- TestCase ---
    struct TestCase:
        var result_: Pointer[TestResult] = nil[Pointer[TestResult]]()

        def __init__():

        def run(mut self, result: TestResult):
            self.result_ = Pointer.address_of(result)
            self.runTestCase()

        def testName(self) -> String:
            # abstract: should be overridden
            return ""

        def runTestCase(self):
            # abstract: should be overridden

    # --- Runner ---
    struct Runner:
        using TestCaseFactory = fn() -> TestCase
        var tests_: Deque[TestCaseFactory]

        def __init__():
            self.tests_ = Deque[TestCaseFactory]()

        def add(mut self, factory: TestCaseFactory) -> Runner:
            self.tests_.push_back(factory)
            return self

        def testCount(self) -> Int:
            return len(self.tests_)

        def testNameAt(self, index: Int) -> String:
            var test = self.tests_[index]()
            var name = test.testName()
            # test is local, no delete needed
            return name

        def runTestAt(self, index: Int, result: TestResult):
            var test = self.tests_[index]()
            result.setTestName(test.testName())
            print("Testing {0}: ".format(test.testName()), end="")
            stdout.flush()
            if JSON_USE_EXCEPTION:
                try:
                    test.run(result)
                except e:
                    result.addFailure(__file__, __line__, "Unexpected exception caught:")
                    result << e.what()
            else:
                test.run(result)
            var status = "FAILED" if result.failed() else "OK"
            print("{0}".format(status))
            stdout.flush()

        def runAllTest(self, printSummary: Bool) -> Bool:
            var count = self.testCount()
            var failures = Deque[TestResult]()
            for index in range(count):
                var result = TestResult()
                self.runTestAt(index, result)
                if result.failed():
                    failures.push_back(result)
            if failures.empty():
                if printSummary:
                    print("All {0} tests passed".format(count))
                return True
            else:
                for result in failures:
                    result.printFailure(count > 1)
                if printSummary:
                    var failedCount = len(failures)
                    var passedCount = count - failedCount
                    print("{0}/{1} tests passed ({2} failure(s))".format(passedCount, count, failedCount))
                return False

        def testIndex(self, testName: String, indexOut: Pointer[Int]) -> Bool:
            var count = self.testCount()
            for index in range(count):
                if self.testNameAt(index) == testName:
                    indexOut.store(index)
                    return True
            return False

        def listTests(self):
            var count = self.testCount()
            for index in range(count):
                print("{0}".format(self.testNameAt(index)))

        def runCommandLine(self, argc: Int, argv: Pointer[String]) -> Int:
            var subrunner = Runner()
            var index = 1
            while index < argc:
                var opt = argv.load(index)
                if opt == "--list-tests":
                    self.listTests()
                    return 0
                elif opt == "--test-auto":
                    self.preventDialogOnCrash()
                elif opt == "--test":
                    index += 1
                    if index < argc:
                        var testNameIndex: Int = 0
                        if self.testIndex(argv.load(index), Pointer.address_of(testNameIndex)):
                            subrunner.add(self.tests_[testNameIndex])
                        else:
                            printe("Test '{0}' does not exist!".format(argv.load(index)))
                            return 2
                    else:
                        self.printUsage(argv.load(0))
                        return 2
                else:
                    self.printUsage(argv.load(0))
                    return 2
                index += 1
            var succeeded: Bool
            if subrunner.testCount() > 0:
                succeeded = subrunner.runAllTest(subrunner.testCount() > 1)
            else:
                succeeded = self.runAllTest(True)
            return 0 if succeeded else 1

        def preventDialogOnCrash():
            # Windows-specific crash prevention, not implemented

        def printUsage(appName: String):
            print("Usage: {0} [options]".format(appName))
            print()
            print("If --test is not specified, then all the test cases be run.")
            print()
            print("Valid options:")
            print("--list-tests: print the name of all test cases on the standard")
            print("              output and exit.")
            print("--test TESTNAME: executes the test case with the specified name.")
            print("                 May be repeated.")
            print("--test-auto: prevent dialog prompting for debugging on crash.")

    # --- Helper functions (free functions in C++, placed as static within struct) ---
    static def ToJsonString(toConvert: String) -> String:
        return toConvert

    static def ToJsonString(toConvert: String) -> String:
        return toConvert

    # For secure memory version (disabled)
    # static def ToJsonString(in: String) -> String:
    #     return String(in.data(), in.data() + in.length())

    static def valueToString(value: Int64) -> String:
        return _str(value)

    static def valueToString(value: UInt64) -> String:
        return _str(value)

    static def checkEqual[T, U](result: TestResult, expected: T, actual: U, file: String, line: UInt32, expr: String) -> TestResult:
        if (expected as U) != actual:
            result.addFailure(file, line, expr)
            result << "Expected: " + (expected as U) + "\n"
            result << "Actual  : " + actual
        return result

    static def checkStringEqual(result: TestResult, expected: String, actual: String, file: String, line: UInt32, expr: String) -> TestResult:
        if expected != actual:
            result.addFailure(file, line, expr)
            result << "Expected: '" + expected + "'\n"
            result << "Actual  : '" + actual + "'"
        return result

    # --- Macro replacements (functions for use in test cases) ---
    # Note: These are designed to be used inside TestCase.runTestCase() where result_ is available.
    # They mimic the original macros as closely as possible.
    # For JSONTEST_ASSERT: call as self.JSONTEST_ASSERT(expr)
    # For others, similar.
    def JSONTEST_ASSERT(self: TestCase, expr: Bool):
        if not expr:
            self.result_.load().addFailure(__file__, __line__, "expr")

    def JSONTEST_ASSERT_PRED(self: TestCase, pred: Bool):
        # Simplified version: cannot fully capture the context chain without macros.
        # We approximate by just calling JSONTEST_ASSERT.
        self.JSONTEST_ASSERT(pred)

    def JSONTEST_ASSERT_EQUAL[T, U](self: TestCase, expected: T, actual: U):
        JsonTest.checkEqual(self.result_.load(), expected, actual, __file__, __line__, "expected == actual")

    def JSONTEST_ASSERT_STRING_EQUAL(self: TestCase, expected: String, actual: String):
        JsonTest.checkStringEqual(self.result_.load(), JsonTest.ToJsonString(expected), JsonTest.ToJsonString(actual), __file__, __line__, "expected == actual")

    def JSONTEST_ASSERT_THROWS(self: TestCase, body: fn() -> None):
        var threw = False
        try:
            body()
        except:
            threw = True
        if not threw:
            self.result_.load().addFailure(__file__, __line__, "expected exception thrown")

    # The following macros are for defining test classes. In Mojo, we cannot reproduce them exactly.
    # We define helper functions to register test factories instead.
    # For JSONTEST_FIXTURE and friends, the user should define their own structs inheriting from JsonTest.TestCase.
    # The factory function and registration can be done manually.
    # We leave them as comments indicating the intended usage.
    # 
    # #define JSONTEST_FIXTURE(FixtureType, name)
    # #define JSONTEST_FIXTURE_FACTORY(FixtureType, name)
    # #define JSONTEST_REGISTER_FIXTURE(runner, FixtureType, name)
    # #define JSONTEST_FIXTURE_V2(FixtureType, name, collections)

# --- End of JsonTest struct ---

# --- Free function: ToJsonString const char* overload (handled by polymorphism) ---
def ToJsonString(toConvert: String) -> String:
    return toConvert

# --- Export for use in other modules ---
# The struct JsonTest contains everything needed.
# Example: from jsontest import JsonTest
# Then use JsonTest.TestResult, JsonTest.TestCase, etc.
<<<FILE>>>