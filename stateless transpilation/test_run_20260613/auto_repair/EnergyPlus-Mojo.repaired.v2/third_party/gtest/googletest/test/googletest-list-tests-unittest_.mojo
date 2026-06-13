from gtest import TEST, TEST_F, TEST_P, TYPED_TEST, TYPED_TEST_SUITE, TYPED_TEST_SUITE_P, TYPED_TEST_P, REGISTER_TYPED_TEST_SUITE_P, INSTANTIATE_TEST_SUITE_P, INSTANTIATE_TYPED_TEST_SUITE_P, Test, TestWithParam, Types, Values, InitGoogleTest, RUN_ALL_TESTS

TEST("Foo", "Bar1", fn() {})
TEST("Foo", "Bar2", fn() {})
TEST("Foo", "DISABLED_Bar3", fn() {})
TEST("Abc", "Xyz", fn() {})
TEST("Abc", "Def", fn() {})
TEST("FooBar", "Baz", fn() {})

class FooTest(Test):

TEST_F("FooTest", "Test1", fn() {})
TEST_F("FooTest", "DISABLED_Test2", fn() {})
TEST_F("FooTest", "Test3", fn() {})
TEST("FooDeathTest", "Test1", fn() {})

class MyType:
    def __init__(inout self, a_value: String):
        self.value_ = a_value
    def value(self) -> String:
        return self.value_
    var value_: String

def PrintTo(x: MyType, os: &OStream):
    os << x.value()

class ValueParamTest(TestWithParam[MyType]):

TEST_P("ValueParamTest", "TestA", fn() {})
TEST_P("ValueParamTest", "TestB", fn() {})

INSTANTIATE_TEST_SUITE_P(
    "MyInstantiation", ValueParamTest,
    testing.Values(MyType("one line"),
                    MyType("two\nlines"),
                    MyType("a very\nloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong line")))  # NOLINT

class VeryLoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooogName:  # NOLINT

class TypedTest[T](Test):

class MyArray[T, kSize: Int]:

alias MyTypes = Types[VeryLoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooogName,  # NOLINT
                       Pointer[Int], MyArray[bool, 42]]

TYPED_TEST_SUITE(TypedTest, MyTypes)
TYPED_TEST("TypedTest", "TestA", fn() {})
TYPED_TEST("TypedTest", "TestB", fn() {})

class TypeParamTest[T](Test):

TYPED_TEST_SUITE_P(TypeParamTest)
TYPED_TEST_P("TypeParamTest", "TestA", fn() {})
TYPED_TEST_P("TypeParamTest", "TestB", fn() {})
REGISTER_TYPED_TEST_SUITE_P(TypeParamTest, "TestA", "TestB")
INSTANTIATE_TYPED_TEST_SUITE_P("My", TypeParamTest, MyTypes)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    InitGoogleTest(argc, argv)
    return RUN_ALL_TESTS()