// This file is a faithful 1:1 Mojo translation of the C++ file
// third_party/gtest/googletest/test/googletest-param-test-test.cc.
// It uses hypothetical Mojo bindings for gtest (imported from "gtest").
// No refactoring: structure, names, and test macro calls are preserved as functions.

from gtest import *
from algorithm import sort
from iostream import *
from list import List
from set import Set
from sstream import StringStream
from string import String
from vector import Vector
from src.gtest-internal-inl import UnitTestOptions
from test.googletest-param-test-test import *

alias vector = Vector[Int]  // For compatibility

def PrintValue[T: AnyType](value: T) -> String:
    return testing.PrintToString(value)

def VerifyGenerator[T: AnyType, N: Int](generator: ParamGenerator[T], expected_values: StaticArray[T, N]):
    var it = generator.begin()
    for i in range(N):
        ASSERT_FALSE(it == generator.end()) << "At element " << i << " when accessing via an iterator created with the copy constructor.\n"
        EXPECT_TRUE(expected_values[i] == *it) << "where i is " << i << ", expected_values[i] is " << PrintValue(expected_values[i]) << ", *it is " << PrintValue(*it) << ", and 'it' is an iterator created with the copy constructor.\n"
        ++it
    EXPECT_TRUE(it == generator.end()) << "At the presumed end of sequence when accessing via an iterator created with the copy constructor.\n"
    it = generator.begin()
    for i in range(N):
        ASSERT_FALSE(it == generator.end()) << "At element " << i << " when accessing via an iterator created with the assignment operator.\n"
        EXPECT_TRUE(expected_values[i] == *it) << "where i is " << i << ", expected_values[i] is " << PrintValue(expected_values[i]) << ", *it is " << PrintValue(*it) << ", and 'it' is an iterator created with the copy constructor.\n"
        ++it
    EXPECT_TRUE(it == generator.end()) << "At the presumed end of sequence when accessing via an iterator created with the assignment operator.\n"

def VerifyGeneratorIsEmpty[T: AnyType](generator: ParamGenerator[T]):
    var it = generator.begin()
    EXPECT_TRUE(it == generator.end())
    it = generator.begin()
    EXPECT_TRUE(it == generator.end())

TEST("IteratorTest", "ParamIteratorConformsToForwardIteratorConcept", fn():
    var gen: ParamGenerator[Int] = Range(0, 10)
    var it: ParamGenerator[Int].Iterator = gen.begin()
    var it2: ParamGenerator[Int].Iterator = it
    EXPECT_TRUE(*it == *it2) << "Initialized iterators must point to the element same as its source points to"
    ++it
    EXPECT_FALSE(*it == *it2)
    it2 = it
    EXPECT_TRUE(*it == *it2) << "Assigned iterators must point to the element same as its source points to"
    EXPECT_EQ(&it, &(++it)) << "Result of the prefix operator++ must be refer to the original object"
    var original_value: Int = *it
    EXPECT_EQ(original_value, *(it++))
    it2 = it
    ++it
    ++it2
    EXPECT_TRUE(*it == *it2)
)

TEST("RangeTest", "IntRangeWithDefaultStep", fn():
    var gen: ParamGenerator[Int] = Range(0, 3)
    var expected_values: StaticArray[Int, 3] = StaticArray(0, 1, 2)
    VerifyGenerator(gen, expected_values)
)

TEST("RangeTest", "IntRangeSingleValue", fn():
    var gen: ParamGenerator[Int] = Range(0, 1)
    var expected_values: StaticArray[Int, 1] = StaticArray(0)
    VerifyGenerator(gen, expected_values)
)

TEST("RangeTest", "IntRangeEmpty", fn():
    var gen: ParamGenerator[Int] = Range(0, 0)
    VerifyGeneratorIsEmpty(gen)
)

TEST("RangeTest", "IntRangeWithCustomStep", fn():
    var gen: ParamGenerator[Int] = Range(0, 9, 3)
    var expected_values: StaticArray[Int, 3] = StaticArray(0, 3, 6)
    VerifyGenerator(gen, expected_values)
)

TEST("RangeTest", "IntRangeWithCustomStepOverUpperBound", fn():
    var gen: ParamGenerator[Int] = Range(0, 4, 3)
    var expected_values: StaticArray[Int, 2] = StaticArray(0, 3)
    VerifyGenerator(gen, expected_values)
)

struct DogAdder:
    var value_: String

    def __init__(inout self, a_value: String):
        self.value_ = a_value

    def __init__(inout self, other: DogAdder):
        self.value_ = other.value_.c_str()

    def __copyinit__(inout self, other: DogAdder):
        self.value_ = other.value_

    def __moveinit__(inout self, owned other: DogAdder):
        self.value_ = other.value_

    def __add__(self, other: DogAdder) -> DogAdder:
        var msg: Message = Message()
        msg << self.value_.c_str() << other.value_.c_str()
        return DogAdder(msg.GetString().c_str())

    def __lt__(self, other: DogAdder) -> Bool:
        return self.value_ < other.value_

    def value(self) -> String:
        return self.value_

TEST("RangeTest", "WorksWithACustomType", fn():
    var gen: ParamGenerator[DogAdder] = Range(DogAdder("cat"), DogAdder("catdogdog"), DogAdder("dog"))
    var it: ParamGenerator[DogAdder].Iterator = gen.begin()
    ASSERT_FALSE(it == gen.end())
    EXPECT_STREQ("cat", it->value().c_str())
    ASSERT_FALSE(++it == gen.end())
    EXPECT_STREQ("catdog", it->value().c_str())
    EXPECT_TRUE(++it == gen.end())
)

struct IntWrapper:
    var value_: Int

    def __init__(inout self, a_value: Int):
        self.value_ = a_value

    def __copyinit__(inout self, other: IntWrapper):
        self.value_ = other.value_

    def __add__(self, other: Int) -> IntWrapper:
        return IntWrapper(self.value_ + other)

    def __lt__(self, other: IntWrapper) -> Bool:
        return self.value_ < other.value_

    def value(self) -> Int:
        return self.value_

TEST("RangeTest", "WorksWithACustomTypeWithDifferentIncrementType", fn():
    var gen: ParamGenerator[IntWrapper] = Range(IntWrapper(0), IntWrapper(2))
    var it: ParamGenerator[IntWrapper].Iterator = gen.begin()
    ASSERT_FALSE(it == gen.end())
    EXPECT_EQ(0, it->value())
    ASSERT_FALSE(++it == gen.end())
    EXPECT_EQ(1, it->value())
    EXPECT_TRUE(++it == gen.end())
)

TEST("ValuesInTest", "ValuesInArray", fn():
    var array: StaticArray[Int, 3] = StaticArray(3, 5, 8)
    var gen: ParamGenerator[Int] = ValuesIn[Int](array)
    VerifyGenerator(gen, array)
)

TEST("ValuesInTest", "ValuesInConstArray", fn():
    var array: StaticArray[Int, 3] = StaticArray(3, 5, 8)
    var gen: ParamGenerator[Int] = ValuesIn[Int](array)
    VerifyGenerator(gen, array)
)

TEST("ValuesInTest", "ValuesInSingleElementArray", fn():
    var array: StaticArray[Int, 1] = StaticArray(42)
    var gen: ParamGenerator[Int] = ValuesIn[Int](array)
    VerifyGenerator(gen, array)
)

TEST("ValuesInTest", "ValuesInVector", fn():
    alias ContainerType = Vector[Int]
    var values: ContainerType = ContainerType()
    values.push_back(3)
    values.push_back(5)
    values.push_back(8)
    var gen: ParamGenerator[Int] = ValuesIn[Int](values)
    var expected_values: StaticArray[Int, 3] = StaticArray(3, 5, 8)
    VerifyGenerator(gen, expected_values)
)

TEST("ValuesInTest", "ValuesInIteratorRange", fn():
    alias ContainerType = Vector[Int]
    var values: ContainerType = ContainerType()
    values.push_back(3)
    values.push_back(5)
    values.push_back(8)
    var gen: ParamGenerator[Int] = ValuesIn[Int](values.begin(), values.end())
    var expected_values: StaticArray[Int, 3] = StaticArray(3, 5, 8)
    VerifyGenerator(gen, expected_values)
)

TEST("ValuesInTest", "ValuesInSingleElementIteratorRange", fn():
    alias ContainerType = Vector[Int]
    var values: ContainerType = ContainerType()
    values.push_back(42)
    var gen: ParamGenerator[Int] = ValuesIn[Int](values.begin(), values.end())
    var expected_values: StaticArray[Int, 1] = StaticArray(42)
    VerifyGenerator(gen, expected_values)
)

TEST("ValuesInTest", "ValuesInEmptyIteratorRange", fn():
    alias ContainerType = Vector[Int]
    var values: ContainerType = ContainerType()
    var gen: ParamGenerator[Int] = ValuesIn[Int](values.begin(), values.end())
    VerifyGeneratorIsEmpty(gen)
)

TEST("ValuesTest", "ValuesWorks", fn():
    var gen: ParamGenerator[Int] = Values(3, 5, 8)
    var expected_values: StaticArray[Int, 3] = StaticArray(3, 5, 8)
    VerifyGenerator(gen, expected_values)
)

TEST("ValuesTest", "ValuesWorksForValuesOfCompatibleTypes", fn():
    var gen: ParamGenerator[Float64] = Values[Float64](3, 5.0, 8.0)
    var expected_values: StaticArray[Float64, 3] = StaticArray(3.0, 5.0, 8.0)
    VerifyGenerator(gen, expected_values)
)

TEST("ValuesTest", "ValuesWorksForMaxLengthList", fn():
    var gen: ParamGenerator[Int] = Values(10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
                                          110, 120, 130, 140, 150, 160, 170, 180, 190, 200,
                                          210, 220, 230, 240, 250, 260, 270, 280, 290, 300,
                                          310, 320, 330, 340, 350, 360, 370, 380, 390, 400,
                                          410, 420, 430, 440, 450, 460, 470, 480, 490, 500)
    var expected_values: StaticArray[Int, 50] = StaticArray(10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
                                                             110, 120, 130, 140, 150, 160, 170, 180, 190, 200,
                                                             210, 220, 230, 240, 250, 260, 270, 280, 290, 300,
                                                             310, 320, 330, 340, 350, 360, 370, 380, 390, 400,
                                                             410, 420, 430, 440, 450, 460, 470, 480, 490, 500)
    VerifyGenerator(gen, expected_values)
)

TEST("ValuesTest", "ValuesWithSingleParameter", fn():
    var gen: ParamGenerator[Int] = Values(42)
    var expected_values: StaticArray[Int, 1] = StaticArray(42)
    VerifyGenerator(gen, expected_values)
)

TEST("BoolTest", "BoolWorks", fn():
    var gen: ParamGenerator[Bool] = Bool()
    var expected_values: StaticArray[Bool, 2] = StaticArray(False, True)
    VerifyGenerator(gen, expected_values)
)

TEST("CombineTest", "CombineWithTwoParameters", fn():
    var foo: String = "foo"
    var bar: String = "bar"
    var gen: ParamGenerator[Tuple[String, Int]] = Combine(Values(foo, bar), Values(3, 4))
    var expected_values: StaticArray[Tuple[String, Int], 4] = StaticArray(
        Tuple(foo, 3), Tuple(foo, 4), Tuple(bar, 3), Tuple(bar, 4)
    )
    VerifyGenerator(gen, expected_values)
)

TEST("CombineTest", "CombineWithThreeParameters", fn():
    var gen: ParamGenerator[Tuple[Int, Int, Int]] = Combine(Values(0, 1), Values(3, 4), Values(5, 6))
    var expected_values: StaticArray[Tuple[Int, Int, Int], 8] = StaticArray(
        Tuple(0, 3, 5), Tuple(0, 3, 6), Tuple(0, 4, 5), Tuple(0, 4, 6),
        Tuple(1, 3, 5), Tuple(1, 3, 6), Tuple(1, 4, 5), Tuple(1, 4, 6)
    )
    VerifyGenerator(gen, expected_values)
)

TEST("CombineTest", "CombineWithFirstParameterSingleValue", fn():
    var gen: ParamGenerator[Tuple[Int, Int]] = Combine(Values(42), Values(0, 1))
    var expected_values: StaticArray[Tuple[Int, Int], 2] = StaticArray(Tuple(42, 0), Tuple(42, 1))
    VerifyGenerator(gen, expected_values)
)

TEST("CombineTest", "CombineWithSecondParameterSingleValue", fn():
    var gen: ParamGenerator[Tuple[Int, Int]] = Combine(Values(0, 1), Values(42))
    var expected_values: StaticArray[Tuple[Int, Int], 2] = StaticArray(Tuple(0, 42), Tuple(1, 42))
    VerifyGenerator(gen, expected_values)
)

TEST("CombineTest", "CombineWithFirstParameterEmptyRange", fn():
    var gen: ParamGenerator[Tuple[Int, Int]] = Combine(Range(0, 0), Values(0, 1))
    VerifyGeneratorIsEmpty(gen)
)

TEST("CombineTest", "CombineWithSecondParameterEmptyRange", fn():
    var gen: ParamGenerator[Tuple[Int, Int]] = Combine(Values(0, 1), Range(1, 1))
    VerifyGeneratorIsEmpty(gen)
)

TEST("CombineTest", "CombineWithMaxNumberOfParameters", fn():
    var foo: String = "foo"
    var bar: String = "bar"
    var gen: ParamGenerator[Tuple[String, Int, Int, Int, Int, Int, Int, Int, Int, Int]] = Combine(
        Values(foo, bar), Values(1), Values(2), Values(3), Values(4),
        Values(5), Values(6), Values(7), Values(8), Values(9)
    )
    var expected_values: StaticArray[Tuple[String, Int, Int, Int, Int, Int, Int, Int, Int, Int], 2] = StaticArray(
        Tuple(foo, 1, 2, 3, 4, 5, 6, 7, 8, 9),
        Tuple(bar, 1, 2, 3, 4, 5, 6, 7, 8, 9)
    )
    VerifyGenerator(gen, expected_values)
)

struct NonDefaultConstructAssignString:
    var str_: String

    def __init__(inout self, s: String):
        self.str_ = s

    // delete default constructor, copy assignment, but keep copy constructor and destructor
    def __init__(inout self) = delete

    def __copyinit__(inout self, other: NonDefaultConstructAssignString):
        self.str_ = other.str_

    def __del__(owned self):

    def str(self) -> String:
        return self.str_

TEST("CombineTest", "NonDefaultConstructAssign", fn():
    var gen: ParamGenerator[Tuple[Int, NonDefaultConstructAssignString]] = Combine(
        Values(0, 1),
        Values(NonDefaultConstructAssignString("A"), NonDefaultConstructAssignString("B"))
    )
    var it: ParamGenerator[Tuple[Int, NonDefaultConstructAssignString]].Iterator = gen.begin()
    EXPECT_EQ(0, tuple_get[0](*it))
    EXPECT_EQ("A", tuple_get[1](*it).str())
    ++it
    EXPECT_EQ(0, tuple_get[0](*it))
    EXPECT_EQ("B", tuple_get[1](*it).str())
    ++it
    EXPECT_EQ(1, tuple_get[0](*it))
    EXPECT_EQ("A", tuple_get[1](*it).str())
    ++it
    EXPECT_EQ(1, tuple_get[0](*it))
    EXPECT_EQ("B", tuple_get[1](*it).str())
    ++it
    EXPECT_TRUE(it == gen.end())
)

TEST("ParamGeneratorTest", "AssignmentWorks", fn():
    var gen: ParamGenerator[Int] = Values(1, 2)
    let gen2: ParamGenerator[Int] = Values(3, 4)
    gen = gen2
    var expected_values: StaticArray[Int, 2] = StaticArray(3, 4)
    VerifyGenerator(gen, expected_values)
)

// Template class TestGenerationEnvironment
struct TestGenerationEnvironment[kExpectedCalls: Int](Environment):
    var fixture_constructor_count_: Int
    var set_up_count_: Int
    var tear_down_count_: Int
    var test_body_count_: Int

    @staticmethod
    def Instance() -> TestGenerationEnvironment[kExpectedCalls]:
        var instance: TestGenerationEnvironment[kExpectedCalls] = ...  // static instance
        return instance

    def FixtureConstructorExecuted(inout self):
        self.fixture_constructor_count_ += 1

    def SetUpExecuted(inout self):
        self.set_up_count_ += 1

    def TearDownExecuted(inout self):
        self.tear_down_count_ += 1

    def TestBodyExecuted(inout self):
        self.test_body_count_ += 1

    def TearDown(self):
        var perform_check: Bool = False
        for i in range(kExpectedCalls):
            var msg: Message = Message()
            msg << "TestsExpandedAndRun/" << i
            if UnitTestOptions.FilterMatchesTest("TestExpansionModule/MultipleTestGenerationTest", msg.GetString().c_str()):
                perform_check = True
        if perform_check:
            EXPECT_EQ(kExpectedCalls, self.fixture_constructor_count_) << "Fixture constructor of ParamTestGenerationTest test case has not been run as expected."
            EXPECT_EQ(kExpectedCalls, self.set_up_count_) << "Fixture SetUp method of ParamTestGenerationTest test case has not been run as expected."
            EXPECT_EQ(kExpectedCalls, self.tear_down_count_) << "Fixture TearDown method of ParamTestGenerationTest test case has not been run as expected."
            EXPECT_EQ(kExpectedCalls, self.test_body_count_) << "Test in ParamTestGenerationTest test case has not been run as expected."

    def __init__(inout self):
        self.fixture_constructor_count_ = 0
        self.set_up_count_ = 0
        self.tear_down_count_ = 0
        self.test_body_count_ = 0

    // Disallow copy and assign
    def __copyinit__(inout self, other: Self) = delete
    def __moveinit__(inout self, owned other: Self) = delete
    def __assign__(inout self, other: Self) = delete

let test_generation_params: StaticArray[Int, 3] = StaticArray(36, 42, 72)

struct TestGenerationTest(TestWithParam[Int]):
    alias PARAMETER_COUNT = sizeof(test_generation_params) / sizeof(test_generation_params[0])
    alias Environment = TestGenerationEnvironment[PARAMETER_COUNT]

    var current_parameter_: Int
    static var collected_parameters_: Vector[Int]

    def __init__(inout self):
        Environment.Instance().FixtureConstructorExecuted()
        self.current_parameter_ = self.GetParam()

    def SetUp(self):
        Environment.Instance().SetUpExecuted()
        EXPECT_EQ(self.current_parameter_, self.GetParam())

    def TearDown(self):
        Environment.Instance().TearDownExecuted()
        EXPECT_EQ(self.current_parameter_, self.GetParam())

    @staticmethod
    def SetUpTestSuite():
        var all_tests_in_test_case_selected: Bool = True
        for i in range(PARAMETER_COUNT):
            var test_name: Message = Message()
            test_name << "TestsExpandedAndRun/" << i
            if not UnitTestOptions.FilterMatchesTest("TestExpansionModule/MultipleTestGenerationTest", test_name.GetString()):
                all_tests_in_test_case_selected = False
        EXPECT_TRUE(all_tests_in_test_case_selected) << "When running the TestGenerationTest test case all of its tests must be selected by the filter flag for the test case to pass. If not all of them are enabled, we can't reliably conclude that the correct number of tests have been generated."
        collected_parameters_.clear()

    @staticmethod
    def TearDownTestSuite():
        var expected_values: Vector[Int] = Vector[Int]()
        for i in range(PARAMETER_COUNT):
            expected_values.push_back(test_generation_params[i])
        sort(expected_values.begin(), expected_values.end())
        sort(collected_parameters_.begin(), collected_parameters_.end())
        EXPECT_TRUE(collected_parameters_ == expected_values)

// static member definition (outside struct)
var TestGenerationTest.collected_parameters_: Vector[Int] = Vector[Int]()

TEST_P(TestGenerationTest, "TestsExpandedAndRun", fn(self):
    Environment.Instance().TestBodyExecuted()
    EXPECT_EQ(self.current_parameter_, self.GetParam())
    collected_parameters_.push_back(self.GetParam())
)

INSTANTIATE_TEST_SUITE_P("TestExpansionModule", TestGenerationTest, ValuesIn(test_generation_params))

struct GeneratorEvaluationTest(TestWithParam[Int]):
    static var param_value_: Int = 0

    @staticmethod
    def param_value() -> Int:
        return param_value_

    @staticmethod
    def set_param_value(param_value: Int):
        param_value_ = param_value

    // Disallow copy etc.
    def __copyinit__(inout self, other: Self) = delete

var GeneratorEvaluationTest.param_value_: Int = 0

TEST_P(GeneratorEvaluationTest, "GeneratorsEvaluatedInMain", fn(self):
    EXPECT_EQ(1, self.GetParam())
)

INSTANTIATE_TEST_SUITE_P("GenEvalModule", GeneratorEvaluationTest, Values(GeneratorEvaluationTest.param_value()))

extern var extern_gen: ParamGenerator[Int]

struct ExternalGeneratorTest(TestWithParam[Int]):

TEST_P(ExternalGeneratorTest, "ExternalGenerator", fn(self):
    EXPECT_EQ(self.GetParam(), 33)
)

INSTANTIATE_TEST_SUITE_P("ExternalGeneratorModule", ExternalGeneratorTest, extern_gen)

TEST_P(ExternalInstantiationTest, "IsMultipleOf33", fn(self):
    EXPECT_EQ(0, self.GetParam() % 33)
)

struct MultipleInstantiationTest(TestWithParam[Int]):

TEST_P(MultipleInstantiationTest, "AllowsMultipleInstances", fn(self):
)

INSTANTIATE_TEST_SUITE_P("Sequence1", MultipleInstantiationTest, Values(1, 2))
INSTANTIATE_TEST_SUITE_P("Sequence2", MultipleInstantiationTest, Range(3, 5))

TEST_P(InstantiationInMultipleTranslationUnitsTest, "IsMultipleOf42", fn(self):
    EXPECT_EQ(0, self.GetParam() % 42)
)

INSTANTIATE_TEST_SUITE_P("Sequence1", InstantiationInMultipleTranslationUnitsTest, Values(42, 42 * 2))

struct SeparateInstanceTest(TestWithParam[Int]):
    var count_: Int
    static var global_count_: Int = 0

    def __init__(inout self):
        self.count_ = 0

    @staticmethod
    def TearDownTestSuite():
        EXPECT_GE(global_count_, 2) << "If some (but not all) SeparateInstanceTest tests have been filtered out this test will fail. Make sure that all GeneratorEvaluationTest are selected or de-selected together by the test filter."

    // Disallow copy
    def __copyinit__(inout self, other: Self) = delete

var SeparateInstanceTest.global_count_: Int = 0

TEST_P(SeparateInstanceTest, "TestsRunInSeparateInstances", fn(self):
    EXPECT_EQ(0, self.count_++)
    global_count_++
)

INSTANTIATE_TEST_SUITE_P("FourElemSequence", SeparateInstanceTest, Range(1, 4))

struct NamingTest(TestWithParam[Int]):

TEST_P(NamingTest, "TestsReportCorrectNamesAndParameters", fn(self):
    let test_info: TestInfo = UnitTest.GetInstance().current_test_info()
    EXPECT_STREQ("ZeroToFiveSequence/NamingTest", test_info.test_suite_name())
    var index_stream: Message = Message()
    index_stream << "TestsReportCorrectNamesAndParameters/" << self.GetParam()
    EXPECT_STREQ(index_stream.GetString().c_str(), test_info.name())
    EXPECT_EQ(PrintToString(self.GetParam()), test_info.value_param())
)

INSTANTIATE_TEST_SUITE_P("ZeroToFiveSequence", NamingTest, Range(0, 5))

struct MacroNamingTest(TestWithParam[Int]):

// Macro prefix
alias PREFIX_WITH_FOO = fn(test_name: String) -> String:
    return "Foo" + test_name

alias PREFIX_WITH_MACRO = fn(test_name: String) -> String:
    return "Macro" + test_name

TEST_P(PREFIX_WITH_MACRO("NamingTest"), PREFIX_WITH_FOO("SomeTestName"), fn(self):
    let test_info: TestInfo = UnitTest.GetInstance().current_test_info()
    EXPECT_STREQ("FortyTwo/MacroNamingTest", test_info.test_suite_name())
    EXPECT_STREQ("FooSomeTestName/0", test_info.name())
)

INSTANTIATE_TEST_SUITE_P("FortyTwo", MacroNamingTest, Values(42))

struct MacroNamingTestNonParametrized(::testing::Test):

TEST_F(PREFIX_WITH_MACRO("NamingTestNonParametrized"), PREFIX_WITH_FOO("SomeTestName"), fn():
    let test_info: TestInfo = UnitTest.GetInstance().current_test_info()
    EXPECT_STREQ("MacroNamingTestNonParametrized", test_info.test_suite_name())
    EXPECT_STREQ("FooSomeTestName", test_info.name())
)

TEST("MacroNameing", "LookupNames", fn():
    var know_suite_names: Set[String] = Set[String]()
    var know_test_names: Set[String] = Set[String]()
    var ins: testing.UnitTest = testing.UnitTest.GetInstance()
    var ts: Int = 0
    var suite: TestSuite = ins.GetTestSuite(ts)
    while suite is not None:
        know_suite_names.insert(suite.name())
        var ti: Int = 0
        var info: TestInfo = suite.GetTestInfo(ti)
        while info is not None:
            know_test_names.insert(suite.name() + "." + info.name())
            ti += 1
            info = suite.GetTestInfo(ti)
        ts += 1
        suite = ins.GetTestSuite(ts)
    EXPECT_NE(know_suite_names.find("FortyTwo/MacroNamingTest"), know_suite_names.end())
    EXPECT_NE(know_suite_names.find("MacroNamingTestNonParametrized"), know_suite_names.end())
    EXPECT_NE(know_test_names.find("FortyTwo/MacroNamingTest.FooSomeTestName/0"), know_test_names.end())
    EXPECT_NE(know_test_names.find("MacroNamingTestNonParametrized.FooSomeTestName"), know_test_names.end())
)

struct CustomFunctorNamingTest(TestWithParam[String]):

TEST_P(CustomFunctorNamingTest, "CustomTestNames", fn(self):
)

struct CustomParamNameFunctor:
    def __call__(self, inf: TestParamInfo[String]) -> String:
        return inf.param

INSTANTIATE_TEST_SUITE_P("CustomParamNameFunctor", CustomFunctorNamingTest, Values(String("FunctorName")), CustomParamNameFunctor())
INSTANTIATE_TEST_SUITE_P("AllAllowedCharacters", CustomFunctorNamingTest, Values("abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "01234567890_"), CustomParamNameFunctor())

def CustomParamNameFunction(inf: TestParamInfo[String]) -> String:
    return inf.param

struct CustomFunctionNamingTest(TestWithParam[String]):

TEST_P(CustomFunctionNamingTest, "CustomTestNames", fn(self):
)

INSTANTIATE_TEST_SUITE_P("CustomParamNameFunction", CustomFunctionNamingTest, Values(String("FunctionName")), CustomParamNameFunction)
INSTANTIATE_TEST_SUITE_P("CustomParamNameFunctionP", CustomFunctionNamingTest, Values(String("FunctionNameP")), &CustomParamNameFunction)

struct CustomLambdaNamingTest(TestWithParam[String]):

TEST_P(CustomLambdaNamingTest, "CustomTestNames", fn(self):
)

INSTANTIATE_TEST_SUITE_P("CustomParamNameLambda", CustomLambdaNamingTest, Values(String("LambdaName")), fn(inf: TestParamInfo[String]) -> String:
    return inf.param
)

TEST("CustomNamingTest", "CheckNameRegistry", fn():
    var unit_test: UnitTest = UnitTest.GetInstance()
    var test_names: Set[String] = Set[String]()
    for suite_num in range(unit_test.total_test_suite_count()):
        var test_suite: TestSuite = unit_test.GetTestSuite(suite_num)
        for test_num in range(test_suite.total_test_count()):
            var test_info: TestInfo = test_suite.GetTestInfo(test_num)
            test_names.insert(String(test_info.name()))
    EXPECT_EQ(1, test_names.count("CustomTestNames/FunctorName"))
    EXPECT_EQ(1, test_names.count("CustomTestNames/FunctionName"))
    EXPECT_EQ(1, test_names.count("CustomTestNames/FunctionNameP"))
    EXPECT_EQ(1, test_names.count("CustomTestNames/LambdaName"))
)

struct CustomIntegerNamingTest(TestWithParam[Int]):

TEST_P(CustomIntegerNamingTest, "TestsReportCorrectNames", fn(self):
    let test_info: TestInfo = UnitTest.GetInstance().current_test_info()
    var test_name_stream: Message = Message()
    test_name_stream << "TestsReportCorrectNames/" << self.GetParam()
    EXPECT_STREQ(test_name_stream.GetString().c_str(), test_info.name())
)

INSTANTIATE_TEST_SUITE_P("PrintToString", CustomIntegerNamingTest, Range(0, 5), PrintToStringParamName())

struct CustomStruct:
    var x: Int

    def __init__(value: Int):
        self.x = value

def __lshift__(stream: StringStream, val: CustomStruct) -> StringStream:
    stream << val.x
    return stream

struct CustomStructNamingTest(TestWithParam[CustomStruct]):

TEST_P(CustomStructNamingTest, "TestsReportCorrectNames", fn(self):
    let test_info: TestInfo = UnitTest.GetInstance().current_test_info()
    var test_name_stream: Message = Message()
    test_name_stream << "TestsReportCorrectNames/" << self.GetParam()
    EXPECT_STREQ(test_name_stream.GetString().c_str(), test_info.name())
)

INSTANTIATE_TEST_SUITE_P("PrintToString", CustomStructNamingTest, Values(CustomStruct(0), CustomStruct(1)), PrintToStringParamName())

struct StatefulNamingFunctor:
    var sum: Int

    def __init__(inout self):
        self.sum = 0

    def __call__(self, info: TestParamInfo[Int]) -> String:
        var value: Int = info.param + self.sum
        self.sum += info.param
        return PrintToString(value)

struct StatefulNamingTest(TestWithParam[Int]):
    var sum_: Int

    def __init__(inout self):
        self.sum_ = 0

    // Disallow copy
    def __copyinit__(inout self, other: Self) = delete

TEST_P(StatefulNamingTest, "TestsReportCorrectNames", fn(self):
    let test_info: TestInfo = UnitTest.GetInstance().current_test_info()
    self.sum_ += self.GetParam()
    var test_name_stream: Message = Message()
    test_name_stream << "TestsReportCorrectNames/" << self.sum_
    EXPECT_STREQ(test_name_stream.GetString().c_str(), test_info.name())
)

INSTANTIATE_TEST_SUITE_P("StatefulNamingFunctor", StatefulNamingTest, Range(0, 5), StatefulNamingFunctor())

struct Unstreamable:
    var value_: Int

    def __init__(value: Int):
        self.value_ = value

    def dummy_value(self) -> Int:
        return self.value_

struct CommentTest(TestWithParam[Unstreamable]):

TEST_P(CommentTest, "TestsCorrectlyReportUnstreamableParams", fn(self):
    let test_info: TestInfo = UnitTest.GetInstance().current_test_info()
    EXPECT_EQ(PrintToString(self.GetParam()), test_info.value_param())
)

INSTANTIATE_TEST_SUITE_P("InstantiationWithComments", CommentTest, Values(Unstreamable(1)))

struct NonParameterizedBaseTest(Test):
    var n_: Int

    def __init__(inout self):
        self.n_ = 17

struct ParameterizedDerivedTest(NonParameterizedBaseTest, WithParamInterface[Int]):
    var count_: Int
    static var global_count_: Int = 0

    def __init__(inout self):
        NonParameterizedBaseTest.__init__(self)
        self.count_ = 0

    // Disallow copy
    def __copyinit__(inout self, other: Self) = delete

var ParameterizedDerivedTest.global_count_: Int = 0

TEST_F(NonParameterizedBaseTest, "FixtureIsInitialized", fn():
    EXPECT_EQ(17, n_)
)

TEST_P(ParameterizedDerivedTest, "SeesSequence", fn(self):
    EXPECT_EQ(17, self.n_)
    EXPECT_EQ(0, self.count_++)
    EXPECT_EQ(self.GetParam(), global_count_++)
)

struct ParameterizedDeathTest(TestWithParam[Int]):

TEST_F(ParameterizedDeathTest, "GetParamDiesFromTestF", fn():
    EXPECT_DEATH_IF_SUPPORTED(GetParam(), ".* value-parameterized test .*")
)

INSTANTIATE_TEST_SUITE_P("RangeZeroToFive", ParameterizedDerivedTest, Range(0, 5))

enum MyEnums:
    ENUM1 = 1
    ENUM2 = 3
    ENUM3 = 8

struct MyEnumTest(TestWithParam[MyEnums]):

TEST_P(MyEnumTest, "ChecksParamMoreThanZero", fn(self):
    EXPECT_GE(10, self.GetParam())
)

INSTANTIATE_TEST_SUITE_P("MyEnumTests", MyEnumTest, Values(ENUM1, ENUM2, MyEnums(0)))

namespace works_here:
    struct NotUsedTest(TestWithParam[Int]):

    struct NotUsedTypeTest[T: AnyType](Test):

    TYPED_TEST_SUITE_P(NotUsedTypeTest)

    struct NotInstantiatedTest(TestWithParam[Int]):

    GTEST_ALLOW_UNINSTANTIATED_PARAMETERIZED_TEST(NotInstantiatedTest)

    TEST_P(NotInstantiatedTest, "Used", fn(self):
    )

    alias OtherName = NotInstantiatedTest
    GTEST_ALLOW_UNINSTANTIATED_PARAMETERIZED_TEST(OtherName)

    TEST_P(OtherName, "Used", fn(self):
    )

    struct NotInstantiatedTypeTest[T: AnyType](Test):

    TYPED_TEST_SUITE_P(NotInstantiatedTypeTest)
    GTEST_ALLOW_UNINSTANTIATED_PARAMETERIZED_TEST(NotInstantiatedTypeTest)
    TYPED_TEST_P(NotInstantiatedTypeTest, "Used", fn():
    )
    REGISTER_TYPED_TEST_SUITE_P(NotInstantiatedTypeTest, "Used")

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    AddGlobalTestEnvironment(TestGenerationEnvironment[3].Instance())
    let argc: Int = argc
    var argv: Pointer[Pointer[UInt8]] = argv
    var gen_eval_test_env: GeneratorEvaluationTest.Environment = ...
    GeneratorEvaluationTest.set_param_value(1)
    InitGoogleTest(&argc, &argv)
    GeneratorEvaluationTest.set_param_value(2)
    return RUN_ALL_TESTS()
<<<FILE>>>