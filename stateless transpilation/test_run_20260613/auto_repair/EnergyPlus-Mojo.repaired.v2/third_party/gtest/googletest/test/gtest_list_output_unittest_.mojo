from gtest import Test, TestWithParam, TestFixture, Types, Values, InitGoogleTest, RUN_ALL_TESTS, TEST, TEST_F, TEST_P, INSTANTIATE_TEST_SUITE_P, TYPED_TEST_SUITE, TYPED_TEST, TYPED_TEST_SUITE_P, TYPED_TEST_P, REGISTER_TYPED_TEST_SUITE_P, INSTANTIATE_TYPED_TEST_SUITE_P

def FooTest_Test1(): pass
def FooTest_Test2(): pass

class FooTestFixture(Test):

def FooTestFixture_Test3(): pass
def FooTestFixture_Test4(): pass

class ValueParamTest(TestWithParam[int]):

def ValueParamTest_Test5(): pass
def ValueParamTest_Test6(): pass

INSTANTIATE_TEST_SUITE_P(ValueParam, ValueParamTest, Values(33, 42))

@value
struct TypedTest[T: AnyType](Test):

alias TypedTestTypes = Types[int, bool]
TYPED_TEST_SUITE(TypedTest, TypedTestTypes)

def TypedTest_Test7[T: AnyType](): pass
def TypedTest_Test8[T: AnyType](): pass

@value
struct TypeParameterizedTestSuite[T: AnyType](Test):

TYPED_TEST_SUITE_P(TypeParameterizedTestSuite)

def TypeParameterizedTestSuite_Test9[T: AnyType](): pass
def TypeParameterizedTestSuite_Test10[T: AnyType](): pass

REGISTER_TYPED_TEST_SUITE_P(TypeParameterizedTestSuite, Test9, Test10)

alias TypeParameterizedTestSuiteTypes = Types[int, bool]
INSTANTIATE_TYPED_TEST_SUITE_P(Single, TypeParameterizedTestSuite, TypeParameterizedTestSuiteTypes)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    InitGoogleTest(argc, argv)
    return RUN_ALL_TESTS()