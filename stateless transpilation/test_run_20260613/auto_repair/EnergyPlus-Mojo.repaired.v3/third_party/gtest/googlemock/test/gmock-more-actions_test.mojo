from gmock.gmock-more-actions import *
from gmock.gmock import *
from gtest.gtest-spi import *
from gtest.gtest import *
import functional
import memory
import sstream
import string

namespace testing:
    namespace gmock_more_actions_test:
        using ::plus = plus
        using ::string = string
        using testing::Action = Action
        using testing::DeleteArg = DeleteArg
        using testing::Invoke = Invoke
        using testing::ReturnArg = ReturnArg
        using testing::ReturnPointee = ReturnPointee
        using testing::SaveArg = SaveArg
        using testing::SaveArgPointee = SaveArgPointee
        using testing::SetArgReferee = SetArgReferee
        using testing::Unused = Unused
        using testing::WithArg = WithArg
        using testing::WithoutArgs = WithoutArgs

        def Short(n: short) -> short:
            return n

        def Char(ch: char) -> char:
            return ch

        def Nullary() -> int:
            return 1

        var g_done: bool = False

        def Unary(x: int) -> bool:
            return x < 0

        def ByConstRef(s: const string&) -> bool:
            return s == "Hi"

        var g_double: const double = 0.0

        def ReferencesGlobalDouble(x: const double&) -> bool:
            return &x == &g_double

        struct UnaryFunctor:
            def __call__(self, x: bool) -> int:
                return 1 if x else -1

        def Binary(input: const char*, n: short) -> const char*:
            return input + n

        def Ternary(x: int, y: char, z: short) -> int:
            return x + y + z

        def SumOf4(a: int, b: int, c: int, d: int) -> int:
            return a + b + c + d

        def SumOfFirst2(a: int, b: int, Unused: Unused, Unused: Unused) -> int:
            return a + b

        def SumOf5(a: int, b: int, c: int, d: int, e: int) -> int:
            return a + b + c + d + e

        struct SumOf5Functor:
            def __call__(self, a: int, b: int, c: int, d: int, e: int) -> int:
                return a + b + c + d + e

        def SumOf6(a: int, b: int, c: int, d: int, e: int, f: int) -> int:
            return a + b + c + d + e + f

        struct SumOf6Functor:
            def __call__(self, a: int, b: int, c: int, d: int, e: int, f: int) -> int:
                return a + b + c + d + e + f

        def Concat7(s1: const char*, s2: const char*, s3: const char*,
                    s4: const char*, s5: const char*, s6: const char*,
                    s7: const char*) -> string:
            return string(s1) + s2 + s3 + s4 + s5 + s6 + s7

        def Concat8(s1: const char*, s2: const char*, s3: const char*,
                    s4: const char*, s5: const char*, s6: const char*,
                    s7: const char*, s8: const char*) -> string:
            return string(s1) + s2 + s3 + s4 + s5 + s6 + s7 + s8

        def Concat9(s1: const char*, s2: const char*, s3: const char*,
                    s4: const char*, s5: const char*, s6: const char*,
                    s7: const char*, s8: const char*, s9: const char*) -> string:
            return string(s1) + s2 + s3 + s4 + s5 + s6 + s7 + s8 + s9

        def Concat10(s1: const char*, s2: const char*, s3: const char*,
                     s4: const char*, s5: const char*, s6: const char*,
                     s7: const char*, s8: const char*, s9: const char*,
                     s10: const char*) -> string:
            return string(s1) + s2 + s3 + s4 + s5 + s6 + s7 + s8 + s9 + s10

        class Foo:
            def __init__(self):
                self.value_ = 123

            def Nullary(self) -> int:
                return self.value_

            def Unary(self, x: long) -> short:
                return static_cast[short](self.value_ + x)

            def Binary(self, str: const string&, c: char) -> string:
                return str + c

            def Ternary(self, x: int, y: bool, z: char) -> int:
                return self.value_ + x + y * z

            def SumOf4(self, a: int, b: int, c: int, d: int) -> int:
                return a + b + c + d + self.value_

            def SumOfLast2(self, Unused: Unused, Unused: Unused, a: int, b: int) -> int:
                return a + b

            def SumOf5(self, a: int, b: int, c: int, d: int, e: int) -> int:
                return a + b + c + d + e

            def SumOf6(self, a: int, b: int, c: int, d: int, e: int, f: int) -> int:
                return a + b + c + d + e + f

            def Concat7(self, s1: const char*, s2: const char*, s3: const char*,
                        s4: const char*, s5: const char*, s6: const char*,
                        s7: const char*) -> string:
                return string(s1) + s2 + s3 + s4 + s5 + s6 + s7

            def Concat8(self, s1: const char*, s2: const char*, s3: const char*,
                        s4: const char*, s5: const char*, s6: const char*,
                        s7: const char*, s8: const char*) -> string:
                return string(s1) + s2 + s3 + s4 + s5 + s6 + s7 + s8

            def Concat9(self, s1: const char*, s2: const char*, s3: const char*,
                        s4: const char*, s5: const char*, s6: const char*,
                        s7: const char*, s8: const char*, s9: const char*) -> string:
                return string(s1) + s2 + s3 + s4 + s5 + s6 + s7 + s8 + s9

            def Concat10(self, s1: const char*, s2: const char*, s3: const char*,
                         s4: const char*, s5: const char*, s6: const char*,
                         s7: const char*, s8: const char*, s9: const char*,
                         s10: const char*) -> string:
                return string(s1) + s2 + s3 + s4 + s5 + s6 + s7 + s8 + s9 + s10

            var value_: int

        @TEST
        def InvokeTest_Nullary():
            var a: Action[int()] = Invoke(Nullary)
            EXPECT_EQ(1, a.Perform(make_tuple()))

        @TEST
        def InvokeTest_Unary():
            var a: Action[bool(int)] = Invoke(Unary)
            EXPECT_FALSE(a.Perform(make_tuple(1)))
            EXPECT_TRUE(a.Perform(make_tuple(-1)))

        @TEST
        def InvokeTest_Binary():
            var a: Action[const char*(const char*, short)] = Invoke(Binary)
            var p: const char* = "Hello"
            EXPECT_EQ(p + 2, a.Perform(make_tuple(p, Short(2))))

        @TEST
        def InvokeTest_Ternary():
            var a: Action[int(int, char, short)] = Invoke(Ternary)
            EXPECT_EQ(6, a.Perform(make_tuple(1, '\2', Short(3))))

        @TEST
        def InvokeTest_FunctionThatTakes4Arguments():
            var a: Action[int(int, int, int, int)] = Invoke(SumOf4)
            EXPECT_EQ(1234, a.Perform(make_tuple(1000, 200, 30, 4)))

        @TEST
        def InvokeTest_FunctionThatTakes5Arguments():
            var a: Action[int(int, int, int, int, int)] = Invoke(SumOf5)
            EXPECT_EQ(12345, a.Perform(make_tuple(10000, 2000, 300, 40, 5)))

        @TEST
        def InvokeTest_FunctionThatTakes6Arguments():
            var a: Action[int(int, int, int, int, int, int)] = Invoke(SumOf6)
            EXPECT_EQ(123456,
                      a.Perform(make_tuple(100000, 20000, 3000, 400, 50, 6)))

        def CharPtr(s: const char*) -> const char*:
            return s

        @TEST
        def InvokeTest_FunctionThatTakes7Arguments():
            var a: Action[string(const char*, const char*, const char*, const char*,
                                       const char*, const char*, const char*)] = Invoke(Concat7)
            EXPECT_EQ("1234567",
                      a.Perform(make_tuple(CharPtr("1"), CharPtr("2"), CharPtr("3"),
                                                CharPtr("4"), CharPtr("5"), CharPtr("6"),
                                                CharPtr("7"))))

        @TEST
        def InvokeTest_FunctionThatTakes8Arguments():
            var a: Action[string(const char*, const char*, const char*, const char*,
                                       const char*, const char*, const char*, const char*)] = Invoke(Concat8)
            EXPECT_EQ("12345678",
                      a.Perform(make_tuple(CharPtr("1"), CharPtr("2"), CharPtr("3"),
                                                CharPtr("4"), CharPtr("5"), CharPtr("6"),
                                                CharPtr("7"), CharPtr("8"))))

        @TEST
        def InvokeTest_FunctionThatTakes9Arguments():
            var a: Action[string(const char*, const char*, const char*, const char*,
                                       const char*, const char*, const char*, const char*,
                                       const char*)] = Invoke(Concat9)
            EXPECT_EQ("123456789", a.Perform(make_tuple(
                                       CharPtr("1"), CharPtr("2"), CharPtr("3"),
                                       CharPtr("4"), CharPtr("5"), CharPtr("6"),
                                       CharPtr("7"), CharPtr("8"), CharPtr("9"))))

        @TEST
        def InvokeTest_FunctionThatTakes10Arguments():
            var a: Action[string(const char*, const char*, const char*, const char*,
                                       const char*, const char*, const char*, const char*,
                                       const char*, const char*)] = Invoke(Concat10)
            EXPECT_EQ("1234567890",
                      a.Perform(make_tuple(CharPtr("1"), CharPtr("2"), CharPtr("3"),
                                                CharPtr("4"), CharPtr("5"), CharPtr("6"),
                                                CharPtr("7"), CharPtr("8"), CharPtr("9"),
                                                CharPtr("0"))))

        @TEST
        def InvokeTest_FunctionWithUnusedParameters():
            var a1: Action[int(int, int, double, const string&)] = Invoke(SumOfFirst2)
            var dummy: tuple[int, int, double, string] = make_tuple(10, 2, 5.6, string("hi"))
            EXPECT_EQ(12, a1.Perform(dummy))
            var a2: Action[int(int, int, bool, int*)] = Invoke(SumOfFirst2)
            EXPECT_EQ(23, a2.Perform(make_tuple(20, 3, True, static_cast[int*](None))))

        @TEST
        def InvokeTest_MethodWithUnusedParameters():
            var foo: Foo
            var a1: Action[int(string, bool, int, int)] = Invoke(&foo, &Foo.SumOfLast2)
            EXPECT_EQ(12, a1.Perform(make_tuple(CharPtr("hi"), True, 10, 2)))
            var a2: Action[int(char, double, int, int)] = Invoke(&foo, &Foo.SumOfLast2)
            EXPECT_EQ(23, a2.Perform(make_tuple('a', 2.5, 20, 3)))

        @TEST
        def InvokeTest_Functor():
            var a: Action[long(long, int)] = Invoke(plus[long]())
            EXPECT_EQ(3, a.Perform(make_tuple(1, 2)))

        @TEST
        def InvokeTest_FunctionWithCompatibleType():
            var a: Action[long(int, short, char, bool)] = Invoke(SumOf4)
            EXPECT_EQ(4321, a.Perform(make_tuple(4000, Short(300), Char(20), True)))

        @TEST
        def InvokeMethodTest_Nullary():
            var foo: Foo
            var a: Action[int()] = Invoke(&foo, &Foo.Nullary)
            EXPECT_EQ(123, a.Perform(make_tuple()))

        @TEST
        def InvokeMethodTest_Unary():
            var foo: Foo
            var a: Action[short(long)] = Invoke(&foo, &Foo.Unary)
            EXPECT_EQ(4123, a.Perform(make_tuple(4000)))

        @TEST
        def InvokeMethodTest_Binary():
            var foo: Foo
            var a: Action[string(const string&, char)] = Invoke(&foo, &Foo.Binary)
            var s: string = string("Hell")
            var dummy: tuple[string, char] = make_tuple(s, 'o')
            EXPECT_EQ("Hello", a.Perform(dummy))

        @TEST
        def InvokeMethodTest_Ternary():
            var foo: Foo
            var a: Action[int(int, bool, char)] = Invoke(&foo, &Foo.Ternary)
            EXPECT_EQ(1124, a.Perform(make_tuple(1000, True, Char(1))))

        @TEST
        def InvokeMethodTest_MethodThatTakes4Arguments():
            var foo: Foo
            var a: Action[int(int, int, int, int)] = Invoke(&foo, &Foo.SumOf4)
            EXPECT_EQ(1357, a.Perform(make_tuple(1000, 200, 30, 4)))

        @TEST
        def InvokeMethodTest_MethodThatTakes5Arguments():
            var foo: Foo
            var a: Action[int(int, int, int, int, int)] = Invoke(&foo, &Foo.SumOf5)
            EXPECT_EQ(12345, a.Perform(make_tuple(10000, 2000, 300, 40, 5)))

        @TEST
        def InvokeMethodTest_MethodThatTakes6Arguments():
            var foo: Foo
            var a: Action[int(int, int, int, int, int, int)] = Invoke(&foo, &Foo.SumOf6)
            EXPECT_EQ(123456,
                      a.Perform(make_tuple(100000, 20000, 3000, 400, 50, 6)))

        @TEST
        def InvokeMethodTest_MethodThatTakes7Arguments():
            var foo: Foo
            var a: Action[string(const char*, const char*, const char*, const char*,
                                       const char*, const char*, const char*)] = Invoke(&foo, &Foo.Concat7)
            EXPECT_EQ("1234567",
                      a.Perform(make_tuple(CharPtr("1"), CharPtr("2"), CharPtr("3"),
                                                CharPtr("4"), CharPtr("5"), CharPtr("6"),
                                                CharPtr("7"))))

        @TEST
        def InvokeMethodTest_MethodThatTakes8Arguments():
            var foo: Foo
            var a: Action[string(const char*, const char*, const char*, const char*,
                                       const char*, const char*, const char*, const char*)] = Invoke(&foo, &Foo.Concat8)
            EXPECT_EQ("12345678",
                      a.Perform(make_tuple(CharPtr("1"), CharPtr("2"), CharPtr("3"),
                                                CharPtr("4"), CharPtr("5"), CharPtr("6"),
                                                CharPtr("7"), CharPtr("8"))))

        @TEST
        def InvokeMethodTest_MethodThatTakes9Arguments():
            var foo: Foo
            var a: Action[string(const char*, const char*, const char*, const char*,
                                       const char*, const char*, const char*, const char*,
                                       const char*)] = Invoke(&foo, &Foo.Concat9)
            EXPECT_EQ("123456789", a.Perform(make_tuple(
                                       CharPtr("1"), CharPtr("2"), CharPtr("3"),
                                       CharPtr("4"), CharPtr("5"), CharPtr("6"),
                                       CharPtr("7"), CharPtr("8"), CharPtr("9"))))

        @TEST
        def InvokeMethodTest_MethodThatTakes10Arguments():
            var foo: Foo
            var a: Action[string(const char*, const char*, const char*, const char*,
                                       const char*, const char*, const char*, const char*,
                                       const char*, const char*)] = Invoke(&foo, &Foo.Concat10)
            EXPECT_EQ("1234567890",
                      a.Perform(make_tuple(CharPtr("1"), CharPtr("2"), CharPtr("3"),
                                                CharPtr("4"), CharPtr("5"), CharPtr("6"),
                                                CharPtr("7"), CharPtr("8"), CharPtr("9"),
                                                CharPtr("0"))))

        @TEST
        def InvokeMethodTest_MethodWithCompatibleType():
            var foo: Foo
            var a: Action[long(int, short, char, bool)] = Invoke(&foo, &Foo.SumOf4)
            EXPECT_EQ(4444, a.Perform(make_tuple(4000, Short(300), Char(20), True)))

        @TEST
        def WithoutArgsTest_NoArg():
            var a: Action[int(int n)] = WithoutArgs(Invoke(Nullary))
            EXPECT_EQ(1, a.Perform(make_tuple(2)))

        @TEST
        def WithArgTest_OneArg():
            var b: Action[bool(double x, int n)] = WithArg[1](Invoke(Unary))
            EXPECT_TRUE(b.Perform(make_tuple(1.5, -1)))
            EXPECT_FALSE(b.Perform(make_tuple(1.5, 1)))

        @TEST
        def ReturnArgActionTest_WorksForOneArgIntArg0():
            var a: const Action[int(int)] = ReturnArg[0]()
            EXPECT_EQ(5, a.Perform(make_tuple(5)))

        @TEST
        def ReturnArgActionTest_WorksForMultiArgBoolArg0():
            var a: const Action[bool(bool, bool, bool)] = ReturnArg[0]()
            EXPECT_TRUE(a.Perform(make_tuple(True, False, False)))

        @TEST
        def ReturnArgActionTest_WorksForMultiArgStringArg2():
            var a: const Action[string(int, int, string, int)] = ReturnArg[2]()
            EXPECT_EQ("seven", a.Perform(make_tuple(5, 6, string("seven"), 8)))

        @TEST
        def SaveArgActionTest_WorksForSameType():
            var result: int = 0
            var a1: const Action[void(int n)] = SaveArg[0](&result)
            a1.Perform(make_tuple(5))
            EXPECT_EQ(5, result)

        @TEST
        def SaveArgActionTest_WorksForCompatibleType():
            var result: int = 0
            var a1: const Action[void(bool, char)] = SaveArg[1](&result)
            a1.Perform(make_tuple(True, 'a'))
            EXPECT_EQ('a', result)

        @TEST
        def SaveArgPointeeActionTest_WorksForSameType():
            var result: int = 0
            var value: const int = 5
            var a1: const Action[void(const int*)] = SaveArgPointee[0](&result)
            a1.Perform(make_tuple(&value))
            EXPECT_EQ(5, result)

        @TEST
        def SaveArgPointeeActionTest_WorksForCompatibleType():
            var result: int = 0
            var value: char = 'a'
            var a1: const Action[void(bool, char*)] = SaveArgPointee[1](&result)
            a1.Perform(make_tuple(True, &value))
            EXPECT_EQ('a', result)

        @TEST
        def SetArgRefereeActionTest_WorksForSameType():
            var value: int = 0
            var a1: const Action[void(int&)] = SetArgReferee[0](1)
            a1.Perform(tuple[int&](value))
            EXPECT_EQ(1, value)

        @TEST
        def SetArgRefereeActionTest_WorksForCompatibleType():
            var value: int = 0
            var a1: const Action[void(int, int&)] = SetArgReferee[1]('a')
            a1.Perform(tuple[int, int&](0, value))
            EXPECT_EQ('a', value)

        @TEST
        def SetArgRefereeActionTest_WorksWithExtraArguments():
            var value: int = 0
            var a1: const Action[void(bool, int, int&, const char*)] = SetArgReferee[2]('a')
            a1.Perform(tuple[bool, int, int&, const char*](True, 0, value, "hi"))
            EXPECT_EQ('a', value)

        class DeletionTester:
            def __init__(self, is_deleted: bool*):
                self.is_deleted_ = is_deleted
                self.is_deleted_[0] = False

            def __del__(self):
                self.is_deleted_[0] = True

            var is_deleted_: bool*

        @TEST
        def DeleteArgActionTest_OneArg():
            var is_deleted: bool = False
            var t: DeletionTester* = new DeletionTester(&is_deleted)
            var a1: const Action[void(DeletionTester*)] = DeleteArg[0]()
            EXPECT_FALSE(is_deleted)
            a1.Perform(make_tuple(t))
            EXPECT_TRUE(is_deleted)

        @TEST
        def DeleteArgActionTest_TenArgs():
            var is_deleted: bool = False
            var t: DeletionTester* = new DeletionTester(&is_deleted)
            var a1: const Action[void(bool, int, int, const char*, bool,
                                      int, int, int, int, DeletionTester*)] = DeleteArg[9]()
            EXPECT_FALSE(is_deleted)
            a1.Perform(make_tuple(True, 5, 6, CharPtr("hi"), False, 7, 8, 9, 10, t))
            EXPECT_TRUE(is_deleted)

        @TEST
        def ThrowActionTest_ThrowsGivenExceptionInVoidFunction():
            var a: const Action[void(int n)] = Throw('a')
            EXPECT_THROW(a.Perform(make_tuple(0)), char)

        class MyException:

        @TEST
        def ThrowActionTest_ThrowsGivenExceptionInNonVoidFunction():
            var a: const Action[double(char ch)] = Throw(MyException())
            EXPECT_THROW(a.Perform(make_tuple('0')), MyException)

        @TEST
        def ThrowActionTest_ThrowsGivenExceptionInNullaryFunction():
            var a: const Action[double()] = Throw(MyException())
            EXPECT_THROW(a.Perform(make_tuple()), MyException)

        class Object:
            def __del__(self):

            def Func(self):

        class MockObject(Object):
            def __del__(self):

            MOCK_METHOD(void, Func, (), (override))

        @TEST
        def ThrowActionTest_Times0():
            EXPECT_NONFATAL_FAILURE(
                lambda: (
                    try:
                        var m: MockObject
                        ON_CALL(m, Func()).WillByDefault(lambda: raise "something")
                        EXPECT_CALL(m, Func()).Times(0)
                        m.Func()
                    except:

                )(),
                "")

        @TEST
        def SetArrayArgumentTest_SetsTheNthArray():
            using MyFunction = void(bool, int*, char*)
            var numbers: int[3] = [1, 2, 3]
            var a: Action[MyFunction] = SetArrayArgument[1](numbers, numbers + 3)
            var n: int[4] = [0, 0, 0, 0]
            var pn: int* = n
            var ch: char[4] = ['\0', '\0', '\0', '\0']
            var pch: char* = ch
            a.Perform(make_tuple(True, pn, pch))
            EXPECT_EQ(1, n[0])
            EXPECT_EQ(2, n[1])
            EXPECT_EQ(3, n[2])
            EXPECT_EQ(0, n[3])
            EXPECT_EQ('\0', ch[0])
            EXPECT_EQ('\0', ch[1])
            EXPECT_EQ('\0', ch[2])
            EXPECT_EQ('\0', ch[3])
            var letters: string = "abc"
            a = SetArrayArgument[2](letters.begin(), letters.end())
            fill_n(n, 4, 0)
            fill_n(ch, 4, '\0')
            a.Perform(make_tuple(True, pn, pch))
            EXPECT_EQ(0, n[0])
            EXPECT_EQ(0, n[1])
            EXPECT_EQ(0, n[2])
            EXPECT_EQ(0, n[3])
            EXPECT_EQ('a', ch[0])
            EXPECT_EQ('b', ch[1])
            EXPECT_EQ('c', ch[2])
            EXPECT_EQ('\0', ch[3])

        @TEST
        def SetArrayArgumentTest_SetsTheNthArrayWithEmptyRange():
            using MyFunction = void(bool, int*)
            var numbers: int[3] = [1, 2, 3]
            var a: Action[MyFunction] = SetArrayArgument[1](numbers, numbers)
            var n: int[4] = [0, 0, 0, 0]
            var pn: int* = n
            a.Perform(make_tuple(True, pn))
            EXPECT_EQ(0, n[0])
            EXPECT_EQ(0, n[1])
            EXPECT_EQ(0, n[2])
            EXPECT_EQ(0, n[3])

        @TEST
        def SetArrayArgumentTest_SetsTheNthArrayWithConvertibleType():
            using MyFunction = void(bool, int*)
            var chars: char[3] = [97, 98, 99]
            var a: Action[MyFunction] = SetArrayArgument[1](chars, chars + 3)
            var codes: int[4] = [111, 222, 333, 444]
            var pcodes: int* = codes
            a.Perform(make_tuple(True, pcodes))
            EXPECT_EQ(97, codes[0])
            EXPECT_EQ(98, codes[1])
            EXPECT_EQ(99, codes[2])
            EXPECT_EQ(444, codes[3])

        @TEST
        def SetArrayArgumentTest_SetsTheNthArrayWithIteratorArgument():
            using MyFunction = void(bool, back_insert_iterator[string])
            var letters: string = "abc"
            var a: Action[MyFunction] = SetArrayArgument[1](letters.begin(), letters.end())
            var s: string
            a.Perform(make_tuple(True, back_inserter(s)))
            EXPECT_EQ(letters, s)

        @TEST
        def ReturnPointeeTest_Works():
            var n: int = 42
            var a: const Action[int()] = ReturnPointee(&n)
            EXPECT_EQ(42, a.Perform(make_tuple()))
            n = 43
            EXPECT_EQ(43, a.Perform(make_tuple()))

        @TEST
        def InvokeArgumentTest_Function0():
            var a: Action[int(int, int (*)())] = InvokeArgument[1]()
            EXPECT_EQ(1, a.Perform(make_tuple(2, &Nullary)))

        @TEST
        def InvokeArgumentTest_Functor1():
            var a: Action[int(UnaryFunctor)] = InvokeArgument[0](True)
            EXPECT_EQ(1, a.Perform(make_tuple(UnaryFunctor())))

        @TEST
        def InvokeArgumentTest_Function5():
            var a: Action[int(int (*)(int, int, int, int, int))] = InvokeArgument[0](10000, 2000, 300, 40, 5)
            EXPECT_EQ(12345, a.Perform(make_tuple(&SumOf5)))

        @TEST
        def InvokeArgumentTest_Functor5():
            var a: Action[int(SumOf5Functor)] = InvokeArgument[0](10000, 2000, 300, 40, 5)
            EXPECT_EQ(12345, a.Perform(make_tuple(SumOf5Functor())))

        @TEST
        def InvokeArgumentTest_Function6():
            var a: Action[int(int (*)(int, int, int, int, int, int))] = InvokeArgument[0](100000, 20000, 3000, 400, 50, 6)
            EXPECT_EQ(123456, a.Perform(make_tuple(&SumOf6)))

        @TEST
        def InvokeArgumentTest_Functor6():
            var a: Action[int(SumOf6Functor)] = InvokeArgument[0](100000, 20000, 3000, 400, 50, 6)
            EXPECT_EQ(123456, a.Perform(make_tuple(SumOf6Functor())))

        @TEST
        def InvokeArgumentTest_Function7():
            var a: Action[string(string(*)(const char*, const char*, const char*,
                                                      const char*, const char*, const char*,
                                                      const char*))] = InvokeArgument[0]("1", "2", "3", "4", "5", "6", "7")
            EXPECT_EQ("1234567", a.Perform(make_tuple(&Concat7)))

        @TEST
        def InvokeArgumentTest_Function8():
            var a: Action[string(string(*)(const char*, const char*, const char*,
                                                      const char*, const char*, const char*,
                                                      const char*, const char*))] = InvokeArgument[0]("1", "2", "3", "4", "5", "6", "7", "8")
            EXPECT_EQ("12345678", a.Perform(make_tuple(&Concat8)))

        @TEST
        def InvokeArgumentTest_Function9():
            var a: Action[string(string(*)(const char*, const char*, const char*,
                                                      const char*, const char*, const char*,
                                                      const char*, const char*, const char*))] = InvokeArgument[0]("1", "2", "3", "4", "5", "6", "7", "8", "9")
            EXPECT_EQ("123456789", a.Perform(make_tuple(&Concat9)))

        @TEST
        def InvokeArgumentTest_Function10():
            var a: Action[string(string(*)(
                const char*, const char*, const char*, const char*, const char*,
                const char*, const char*, const char*, const char*, const char*))] = InvokeArgument[0]("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
            EXPECT_EQ("1234567890", a.Perform(make_tuple(&Concat10)))

        @TEST
        def InvokeArgumentTest_ByPointerFunction():
            var a: Action[const char*(const char* (*)(char* input , short n))] = InvokeArgument[0](static_cast[const char*]("Hi"), Short(1))
            EXPECT_STREQ("i", a.Perform(make_tuple(&Binary)))

        @TEST
        def InvokeArgumentTest_FunctionWithCStringLiteral():
            var a: Action[const char*(const char* (*)(char* input , short n))] = InvokeArgument[0]("Hi", Short(1))
            EXPECT_STREQ("i", a.Perform(make_tuple(&Binary)))

        @TEST
        def InvokeArgumentTest_ByConstReferenceFunction():
            var a: Action[bool(bool (*function)(string& s ))] = InvokeArgument[0](string("Hi"))
            EXPECT_TRUE(a.Perform(make_tuple(&ByConstRef)))

        @TEST
        def InvokeArgumentTest_ByExplicitConstReferenceFunction():
            var a: Action[bool(bool (*)(double& x ))] = InvokeArgument[0](ByRef(g_double))
            EXPECT_TRUE(a.Perform(make_tuple(&ReferencesGlobalDouble)))
            var x: double = 0.0
            a = InvokeArgument[0](ByRef(x))
            EXPECT_FALSE(a.Perform(make_tuple(&ReferencesGlobalDouble)))

        @TEST
        def DoAllTest_TwoActions():
            var n: int = 0
            var a: Action[int(int*)] = DoAll(SetArgPointee[0](1), Return(2))
            EXPECT_EQ(2, a.Perform(make_tuple(&n)))
            EXPECT_EQ(1, n)

        @TEST
        def DoAllTest_ThreeActions():
            var m: int = 0
            var n: int = 0
            var a: Action[int(int*, int*)] = DoAll(SetArgPointee[0](1), SetArgPointee[1](2), Return(3))
            EXPECT_EQ(3, a.Perform(make_tuple(&m, &n)))
            EXPECT_EQ(1, m)
            EXPECT_EQ(2, n)

        @TEST
        def DoAllTest_FourActions():
            var m: int = 0
            var n: int = 0
            var ch: char = '\0'
            var a: Action[int(int*, int*, char*)] = DoAll(SetArgPointee[0](1), SetArgPointee[1](2), SetArgPointee[2]('a'), Return(3))
            EXPECT_EQ(3, a.Perform(make_tuple(&m, &n, &ch)))
            EXPECT_EQ(1, m)
            EXPECT_EQ(2, n)
            EXPECT_EQ('a', ch)

        @TEST
        def DoAllTest_FiveActions():
            var m: int = 0
            var n: int = 0
            var a: char = '\0'
            var b: char = '\0'
            var action: Action[int(int*, int*, char*, char*)] = DoAll(SetArgPointee[0](1), SetArgPointee[1](2), SetArgPointee[2]('a'), SetArgPointee[3]('b'), Return(3))
            EXPECT_EQ(3, action.Perform(make_tuple(&m, &n, &a, &b)))
            EXPECT_EQ(1, m)
            EXPECT_EQ(2, n)
            EXPECT_EQ('a', a)
            EXPECT_EQ('b', b)

        @TEST
        def DoAllTest_SixActions():
            var m: int = 0
            var n: int = 0
            var a: char = '\0'
            var b: char = '\0'
            var c: char = '\0'
            var action: Action[int(int*, int*, char*, char*, char*)] = DoAll(SetArgPointee[0](1), SetArgPointee[1](2), SetArgPointee[2]('a'), SetArgPointee[3]('b'), SetArgPointee[4]('c'), Return(3))
            EXPECT_EQ(3, action.Perform(make_tuple(&m, &n, &a, &b, &c)))
            EXPECT_EQ(1, m)
            EXPECT_EQ(2, n)
            EXPECT_EQ('a', a)
            EXPECT_EQ('b', b)
            EXPECT_EQ('c', c)

        @TEST
        def DoAllTest_SevenActions():
            var m: int = 0
            var n: int = 0
            var a: char = '\0'
            var b: char = '\0'
            var c: char = '\0'
            var d: char = '\0'
            var action: Action[int(int*, int*, char*, char*, char*, char*)] = DoAll(SetArgPointee[0](1), SetArgPointee[1](2), SetArgPointee[2]('a'), SetArgPointee[3]('b'), SetArgPointee[4]('c'), SetArgPointee[5]('d'), Return(3))
            EXPECT_EQ(3, action.Perform(make_tuple(&m, &n, &a, &b, &c, &d)))
            EXPECT_EQ(1, m)
            EXPECT_EQ(2, n)
            EXPECT_EQ('a', a)
            EXPECT_EQ('b', b)
            EXPECT_EQ('c', c)
            EXPECT_EQ('d', d)

        @TEST
        def DoAllTest_EightActions():
            var m: int = 0
            var n: int = 0
            var a: char = '\0'
            var b: char = '\0'
            var c: char = '\0'
            var d: char = '\0'
            var e: char = '\0'
            var action: Action[int(int*, int*, char*, char*, char*, char*, char*)] = DoAll(SetArgPointee[0](1), SetArgPointee[1](2), SetArgPointee[2]('a'), SetArgPointee[3]('b'), SetArgPointee[4]('c'), SetArgPointee[5]('d'), SetArgPointee[6]('e'), Return(3))
            EXPECT_EQ(3, action.Perform(make_tuple(&m, &n, &a, &b, &c, &d, &e)))
            EXPECT_EQ(1, m)
            EXPECT_EQ(2, n)
            EXPECT_EQ('a', a)
            EXPECT_EQ('b', b)
            EXPECT_EQ('c', c)
            EXPECT_EQ('d', d)
            EXPECT_EQ('e', e)

        @TEST
        def DoAllTest_NineActions():
            var m: int = 0
            var n: int = 0
            var a: char = '\0'
            var b: char = '\0'
            var c: char = '\0'
            var d: char = '\0'
            var e: char = '\0'
            var f: char = '\0'
            var action: Action[int(int*, int*, char*, char*, char*, char*, char*, char*)] = DoAll(SetArgPointee[0](1), SetArgPointee[1](2), SetArgPointee[2]('a'), SetArgPointee[3]('b'), SetArgPointee[4]('c'), SetArgPointee[5]('d'), SetArgPointee[6]('e'), SetArgPointee[7]('f'), Return(3))
            EXPECT_EQ(3, action.Perform(make_tuple(&m, &n, &a, &b, &c, &d, &e, &f)))
            EXPECT_EQ(1, m)
            EXPECT_EQ(2, n)
            EXPECT_EQ('a', a)
            EXPECT_EQ('b', b)
            EXPECT_EQ('c', c)
            EXPECT_EQ('d', d)
            EXPECT_EQ('e', e)
            EXPECT_EQ('f', f)

        @TEST
        def DoAllTest_TenActions():
            var m: int = 0
            var n: int = 0
            var a: char = '\0'
            var b: char = '\0'
            var c: char = '\0'
            var d: char = '\0'
            var e: char = '\0'
            var f: char = '\0'
            var g: char = '\0'
            var action: Action[int(int*, int*, char*, char*, char*, char*, char*, char*, char*)] = DoAll(SetArgPointee[0](1), SetArgPointee[1](2), SetArgPointee[2]('a'), SetArgPointee[3]('b'), SetArgPointee[4]('c'), SetArgPointee[5]('d'), SetArgPointee[6]('e'), SetArgPointee[7]('f'), SetArgPointee[8]('g'), Return(3))
            EXPECT_EQ(3, action.Perform(make_tuple(&m, &n, &a, &b, &c, &d, &e, &f, &g)))
            EXPECT_EQ(1, m)
            EXPECT_EQ(2, n)
            EXPECT_EQ('a', a)
            EXPECT_EQ('b', b)
            EXPECT_EQ('c', c)
            EXPECT_EQ('d', d)
            EXPECT_EQ('e', e)
            EXPECT_EQ('f', f)
            EXPECT_EQ('g', g)

        @TEST
        def DoAllTest_NoArgs():
            var ran_first: bool = False
            var a: Action[bool()] = DoAll(lambda: (ran_first = True), lambda: ran_first)
            EXPECT_TRUE(a.Perform({}))

        @TEST
        def DoAllTest_MoveOnlyArgs():
            var ran_first: bool = False
            var a: Action[int(unique_ptr[int])] = DoAll(InvokeWithoutArgs(lambda: (ran_first = True)), lambda p: p[0])
            EXPECT_EQ(7, a.Perform(make_tuple(unique_ptr[int](new int(7)))))
            EXPECT_TRUE(ran_first)

        @TEST
        def DoAllTest_ImplicitlyConvertsActionArguments():
            var ran_first: bool = False
            var first: Action[void(vector[int])] = lambda: (ran_first = True)
            var a: Action[int(vector[int])] = DoAll(first, lambda arg: arg.front())
            EXPECT_EQ(7, a.Perform(make_tuple(vector[int]{7})))
            EXPECT_TRUE(ran_first)

        ACTION(Return5):
            return 5

        @TEST
        def ActionMacroTest_WorksWhenNotReferencingArguments():
            var a1: Action[double()] = Return5()
            EXPECT_DOUBLE_EQ(5.0, a1.Perform(make_tuple()))
            var a2: Action[int(double, bool)] = Return5()
            EXPECT_EQ(5, a2.Perform(make_tuple(1.0, True)))

        ACTION(IncrementArg1):
            arg1[0] += 1

        @TEST
        def ActionMacroTest_WorksWhenReturningVoid():
            var a1: Action[void(int, int*)] = IncrementArg1()
            var n: int = 0
            a1.Perform(make_tuple(5, &n))
            EXPECT_EQ(1, n)

        ACTION(IncrementArg2):
            StaticAssertTypeEq[int*, arg2_type]()
            var temp: arg2_type = arg2
            temp[0] += 1

        @TEST
        def ActionMacroTest_CanReferenceArgumentType():
            var a1: Action[void(int, bool, int*)] = IncrementArg2()
            var n: int = 0
            a1.Perform(make_tuple(5, False, &n))
            EXPECT_EQ(1, n)

        ACTION(Sum2):
            StaticAssertTypeEq[tuple[int, char, int*], args_type]()
            var args_copy: args_type = args
            return get[0](args_copy) + get[1](args_copy)

        @TEST
        def ActionMacroTest_CanReferenceArgumentTuple():
            var a1: Action[int(int, char, int*)] = Sum2()
            var dummy: int = 0
            EXPECT_EQ(11, a1.Perform(make_tuple(5, Char(6), &dummy)))

        namespace:
            def Dummy(flag: bool) -> int:
                return 1 if flag else 0

        ACTION(InvokeDummy):
            StaticAssertTypeEq[int(bool), function_type]()
            var fp: function_type* = &Dummy
            return fp(True)

        @TEST
        def ActionMacroTest_CanReferenceMockFunctionType():
            var a1: Action[int(bool)] = InvokeDummy()
            EXPECT_EQ(1, a1.Perform(make_tuple(True)))
            EXPECT_EQ(1, a1.Perform(make_tuple(False)))

        ACTION(InvokeDummy2):
            StaticAssertTypeEq[int, return_type]()
            var result: return_type = Dummy(True)
            return result

        @TEST
        def ActionMacroTest_CanReferenceMockFunctionReturnType():
            var a1: Action[int(bool)] = InvokeDummy2()
            EXPECT_EQ(1, a1.Perform(make_tuple(True)))
            EXPECT_EQ(1, a1.Perform(make_tuple(False)))

        ACTION(ReturnAddrOfConstBoolReferenceArg):
            StaticAssertTypeEq[const bool&, arg1_type]()
            return &arg1

        @TEST
        def ActionMacroTest_WorksForConstReferenceArg():
            var a: Action[const bool*(int, const bool&)] = ReturnAddrOfConstBoolReferenceArg()
            var b: const bool = False
            EXPECT_EQ(&b, a.Perform(tuple[int, const bool&](0, b)))

        ACTION(ReturnAddrOfIntReferenceArg):
            StaticAssertTypeEq[int&, arg0_type]()
            return &arg0

        @TEST
        def ActionMacroTest_WorksForNonConstReferenceArg():
            var a: Action[int*(int&, bool, int)] = ReturnAddrOfIntReferenceArg()
            var n: int = 0
            EXPECT_EQ(&n, a.Perform(tuple[int&, bool, int](n, True, 1)))

        namespace action_test:
            ACTION(Sum):
                return arg0 + arg1

        @TEST
        def ActionMacroTest_WorksInNamespace():
            var a1: Action[int(int, int)] = action_test.Sum()
            EXPECT_EQ(3, a1.Perform(make_tuple(1, 2)))

        ACTION(PlusTwo):
            return arg0 + 2

        @TEST
        def ActionMacroTest_WorksForDifferentArgumentNumbers():
            var a1: Action[int(int)] = PlusTwo()
            EXPECT_EQ(4, a1.Perform(make_tuple(2)))
            var a2: Action[double(float, void*)] = PlusTwo()
            var dummy: int
            EXPECT_DOUBLE_EQ(6.0, a2.Perform(make_tuple(4.0, &dummy)))

        ACTION_P(Plus, n):
            return arg0 + n

        @TEST
        def ActionPMacroTest_DefinesParameterizedAction():
            var a1: Action[int(int m, bool t)] = Plus(9)
            EXPECT_EQ(10, a1.Perform(make_tuple(1, True)))

        ACTION_P(TypedPlus, n):
            var t1: arg0_type = arg0
            var t2: n_type = n
            return t1 + t2

        @TEST
        def ActionPMacroTest_CanReferenceArgumentAndParameterTypes():
            var a1: Action[int(char m, bool t)] = TypedPlus(9)
            EXPECT_EQ(10, a1.Perform(make_tuple(Char(1), True)))

        @TEST
        def ActionPMacroTest_WorksInCompatibleMockFunction():
            var a1: Action[string(string& s )] = Plus("tail")
            var re: const string = "re"
            var dummy: tuple[const string] = make_tuple(re)
            EXPECT_EQ("retail", a1.Perform(dummy))

        ACTION(OverloadedAction):
            return arg1 if arg0 else "hello"

        ACTION_P(OverloadedAction, default_value):
            return arg1 if arg0 else default_value

        ACTION_P2(OverloadedAction, true_value, false_value):
            return true_value if arg0 else false_value

        @TEST
        def ActionMacroTest_CanDefineOverloadedActions():
            using MyAction = Action[const char*(bool, const char*)]
            var a1: const MyAction = OverloadedAction()
            EXPECT_STREQ("hello", a1.Perform(make_tuple(False, CharPtr("world"))))
            EXPECT_STREQ("world", a1.Perform(make_tuple(True, CharPtr("world"))))
            var a2: const MyAction = OverloadedAction("hi")
            EXPECT_STREQ("hi", a2.Perform(make_tuple(False, CharPtr("world"))))
            EXPECT_STREQ("world", a2.Perform(make_tuple(True, CharPtr("world"))))
            var a3: const MyAction = OverloadedAction("hi", "you")
            EXPECT_STREQ("hi", a3.Perform(make_tuple(True, CharPtr("world"))))
            EXPECT_STREQ("you", a3.Perform(make_tuple(False, CharPtr("world"))))

        ACTION_P3(Plus, m, n, k):
            return arg0 + m + n + k

        @TEST
        def ActionPnMacroTest_WorksFor3Parameters():
            var a1: Action[double(int m, bool t)] = Plus(100, 20, 3.4)
            EXPECT_DOUBLE_EQ(3123.4, a1.Perform(make_tuple(3000, True)))
            var a2: Action[string(string& s )] = Plus("tail", "-", ">")
            var re: const string = "re"
            var dummy: tuple[const string] = make_tuple(re)
            EXPECT_EQ("retail->", a2.Perform(dummy))

        ACTION_P4(Plus, p0, p1, p2, p3):
            return arg0 + p0 + p1 + p2 + p3

        @TEST
        def ActionPnMacroTest_WorksFor4Parameters():
            var a1: Action[int(int)] = Plus(1, 2, 3, 4)
            EXPECT_EQ(10 + 1 + 2 + 3 + 4, a1.Perform(make_tuple(10)))

        ACTION_P5(Plus, p0, p1, p2, p3, p4):
            return arg0 + p0 + p1 + p2 + p3 + p4

        @TEST
        def ActionPnMacroTest_WorksFor5Parameters():
            var a1: Action[int(int)] = Plus(1, 2, 3, 4, 5)
            EXPECT_EQ(10 + 1 + 2 + 3 + 4 + 5, a1.Perform(make_tuple(10)))

        ACTION_P6(Plus, p0, p1, p2, p3, p4, p5):
            return arg0 + p0 + p1 + p2 + p3 + p4 + p5

        @TEST
        def ActionPnMacroTest_WorksFor6Parameters():
            var a1: Action[int(int)] = Plus(1, 2, 3, 4, 5, 6)
            EXPECT_EQ(10 + 1 + 2 + 3 + 4 + 5 + 6, a1.Perform(make_tuple(10)))

        ACTION_P7(Plus, p0, p1, p2, p3, p4, p5, p6):
            return arg0 + p0 + p1 + p2 + p3 + p4 + p5 + p6

        @TEST
        def ActionPnMacroTest_WorksFor7Parameters():
            var a1: Action[int(int)] = Plus(1, 2, 3, 4, 5, 6, 7)
            EXPECT_EQ(10 + 1 + 2 + 3 + 4 + 5 + 6 + 7, a1.Perform(make_tuple(10)))

        ACTION_P8(Plus, p0, p1, p2, p3, p4, p5, p6, p7):
            return arg0 + p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7

        @TEST
        def ActionPnMacroTest_WorksFor8Parameters():
            var a1: Action[int(int)] = Plus(1, 2, 3, 4, 5, 6, 7, 8)
            EXPECT_EQ(10 + 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8,
                      a1.Perform(make_tuple(10)))

        ACTION_P9(Plus, p0, p1, p2, p3, p4, p5, p6, p7, p8):
            return arg0 + p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8

        @TEST
        def ActionPnMacroTest_WorksFor9Parameters():
            var a1: Action[int(int)] = Plus(1, 2, 3, 4, 5, 6, 7, 8, 9)
            EXPECT_EQ(10 + 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9,
                      a1.Perform(make_tuple(10)))

        ACTION_P10(Plus, p0, p1, p2, p3, p4, p5, p6, p7, p8, last_param):
            var t0: arg0_type = arg0
            var t9: last_param_type = last_param
            return t0 + p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8 + t9

        @TEST
        def ActionPnMacroTest_WorksFor10Parameters():
            var a1: Action[int(int)] = Plus(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
            EXPECT_EQ(10 + 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10,
                      a1.Perform(make_tuple(10)))

        ACTION_P2(PadArgument, prefix, suffix):
            var prefix_str: string = string(prefix)
            var suffix_char: char = static_cast[char](suffix)
            return prefix_str + arg0 + suffix_char

        @TEST
        def ActionPnMacroTest_SimpleTypePromotion():
            var no_promo: Action[string(const char*)] = PadArgument(string("foo"), 'r')
            var promo: Action[string(const char*)] = PadArgument("foo", static_cast[int]('r'))
            EXPECT_EQ("foobar", no_promo.Perform(make_tuple(CharPtr("ba"))))
            EXPECT_EQ("foobar", promo.Perform(make_tuple(CharPtr("ba"))))

        ACTION_P3(ConcatImpl, a, b, c):
            var ss: stringstream
            ss << a << b << c
            return ss.str()

        def Concat[T1: AnyType, T2: AnyType](a: const string&, b: T1, c: T2) -> ConcatImplActionP3[string, T1, T2]:
            GTEST_INTENTIONAL_CONST_COND_PUSH_()
            if True:
                GTEST_INTENTIONAL_CONST_COND_POP_()
                return ConcatImpl(a, b, c)
            else:
                return ConcatImpl[string, T1, T2](a, b, c)

        def Concat[T1: AnyType, T2: AnyType](a: T1, b: int, c: T2) -> ConcatImplActionP3[T1, int, T2]:
            return ConcatImpl(a, b, c)

        @TEST
        def ActionPnMacroTest_CanPartiallyRestrictParameterTypes():
            var a1: Action[const string()] = Concat("Hello", "1", 2)
            EXPECT_EQ("Hello12", a1.Perform(make_tuple()))
            a1 = Concat(1, 2, 3)
            EXPECT_EQ("123", a1.Perform(make_tuple()))

        ACTION(DoFoo):

        ACTION_P(DoFoo, p):

        ACTION_P2(DoFoo, p0, p1):

        @TEST
        def ActionPnMacroTest_TypesAreCorrect():
            var a0: DoFooAction = DoFoo()
            var a1: DoFooActionP[int] = DoFoo(1)
            var a2: DoFooActionP2[int, char] = DoFoo(1, '2')
            var a3: PlusActionP3[int, int, char] = Plus(1, 2, '3')
            var a4: PlusActionP4[int, int, int, char] = Plus(1, 2, 3, '4')
            var a5: PlusActionP5[int, int, int, int, char] = Plus(1, 2, 3, 4, '5')
            var a6: PlusActionP6[int, int, int, int, int, char] = Plus(1, 2, 3, 4, 5, '6')
            var a7: PlusActionP7[int, int, int, int, int, int, char] = Plus(1, 2, 3, 4, 5, 6, '7')
            var a8: PlusActionP8[int, int, int, int, int, int, int, char] = Plus(1, 2, 3, 4, 5, 6, 7, '8')
            var a9: PlusActionP9[int, int, int, int, int, int, int, int, char] = Plus(1, 2, 3, 4, 5, 6, 7, 8, '9')
            var a10: PlusActionP10[int, int, int, int, int, int, int, int, int, char] = Plus(1, 2, 3, 4, 5, 6, 7, 8, 9, '0')
            _ = a0
            _ = a1
            _ = a2
            _ = a3
            _ = a4
            _ = a5
            _ = a6
            _ = a7
            _ = a8
            _ = a9
            _ = a10

        ACTION_P(Plus1, x):
            return x

        ACTION_P2(Plus2, x, y):
            return x + y

        ACTION_P3(Plus3, x, y, z):
            return x + y + z

        ACTION_P10(Plus10, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9):
            return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9

        @TEST
        def ActionPnMacroTest_CanExplicitlyInstantiateWithReferenceTypes():
            var x: int = 1
            var y: int = 2
            var z: int = 3
            var empty: const tuple[] = make_tuple()
            var a: Action[int()] = Plus1[int&](x)
            EXPECT_EQ(1, a.Perform(empty))
            a = Plus2[const int&, int&](x, y)
            EXPECT_EQ(3, a.Perform(empty))
            a = Plus3[int&, const int&, int&](x, y, z)
            EXPECT_EQ(6, a.Perform(empty))
            var n: int[10] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            a = Plus10[const int&, int&, const int&, int&, const int&, int&, const int&,
                       int&, const int&, int&](n[0], n[1], n[2], n[3], n[4], n[5], n[6],
                                               n[7], n[8], n[9])
            EXPECT_EQ(55, a.Perform(empty))

        class TenArgConstructorClass:
            def __init__(self, a1: int, a2: int, a3: int, a4: int, a5: int, a6: int, a7: int,
                         a8: int, a9: int, a10: int):
                self.value_ = a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10
            var value_: int

        ACTION_TEMPLATE(CreateNew, HAS_1_TEMPLATE_PARAMS(typename, T),
                        AND_0_VALUE_PARAMS()):
            return new T

        @TEST
        def ActionTemplateTest_WorksWithoutValueParam():
            var a: const Action[int*()] = CreateNew[int]()
            var p: int* = a.Perform(make_tuple())
            delete p

        ACTION_TEMPLATE(CreateNew, HAS_1_TEMPLATE_PARAMS(typename, T),
                        AND_1_VALUE_PARAMS(a0)):
            return new T(a0)

        @TEST
        def ActionTemplateTest_WorksWithValueParams():
            var a: const Action[int*()] = CreateNew[int](42)
            var p: int* = a.Perform(make_tuple())
            EXPECT_EQ(42, p[0])
            delete p

        ACTION_TEMPLATE(MyDeleteArg, HAS_1_TEMPLATE_PARAMS(int, k),
                        AND_0_VALUE_PARAMS()):
            delete get[k](args)

        class BoolResetter:
            def __init__(self, value: bool*):
                self.value_ = value
            def __del__(self):
                self.value_[0] = False
            var value_: bool*

        @TEST
        def ActionTemplateTest_WorksForIntegralTemplateParams():
            var a: const Action[void(int*, BoolResetter*)] = MyDeleteArg[1]()
            var n: int = 0
            var b: bool = True
            var resetter: auto* = new BoolResetter(&b)
            a.Perform(make_tuple(&n, resetter))
            EXPECT_FALSE(b)

        ACTION_TEMPLATE(ReturnSmartPointer,
                        HAS_1_TEMPLATE_PARAMS(template [Pointee] class, Pointer),
                        AND_1_VALUE_PARAMS(pointee)):
            return Pointer[pointee_type](new pointee_type(pointee))

        @TEST
        def ActionTemplateTest_WorksForTemplateTemplateParameters():
            var a: const Action[shared_ptr[int]()] = ReturnSmartPointer[shared_ptr](42)
            var p: shared_ptr[int] = a.Perform(make_tuple())
            EXPECT_EQ(42, p[0])

        struct GiantTemplate[T1: AnyType, T2: AnyType, T3: AnyType, k4: int, k5: bool,
                              k6: unsigned int, T7: AnyType, T8: AnyType, T9: AnyType]:
            def __init__(self, a_value: int):
                self.value = a_value
            var value: int

        ACTION_TEMPLATE(ReturnGiant,
                        HAS_10_TEMPLATE_PARAMS(typename, T1, typename, T2, typename, T3,
                                               int, k4, bool, k5, unsigned int, k6,
                                               class, T7, class, T8, class, T9,
                                               template [T] class, T10),
                        AND_1_VALUE_PARAMS(value)):
            return GiantTemplate[T10[T1], T2, T3, k4, k5, k6, T7, T8, T9](value)

        @TEST
        def ActionTemplateTest_WorksFor10TemplateParameters():
            using Giant = GiantTemplate[shared_ptr[int], bool, double, 5, True, 6,
                                        char, unsigned, int]
            var a: const Action[Giant()] = ReturnGiant[int, bool, double, 5, True, 6, char,
                                                      unsigned, int, shared_ptr](42)
            var giant: Giant = a.Perform(make_tuple())
            EXPECT_EQ(42, giant.value)

        ACTION_TEMPLATE(ReturnSum, HAS_1_TEMPLATE_PARAMS(typename, Number),
                        AND_10_VALUE_PARAMS(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)):
            return static_cast[Number](v1) + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10

        @TEST
        def ActionTemplateTest_WorksFor10ValueParameters():
            var a: const Action[int()] = ReturnSum[int](1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
            EXPECT_EQ(55, a.Perform(make_tuple()))

        ACTION(ReturnSum):
            return 0

        ACTION_P(ReturnSum, x):
            return x

        ACTION_TEMPLATE(ReturnSum, HAS_1_TEMPLATE_PARAMS(typename, Number),
                        AND_2_VALUE_PARAMS(v1, v2)):
            return static_cast[Number](v1) + v2

        ACTION_TEMPLATE(ReturnSum, HAS_1_TEMPLATE_PARAMS(typename, Number),
                        AND_3_VALUE_PARAMS(v1, v2, v3)):
            return static_cast[Number](v1) + v2 + v3

        ACTION_TEMPLATE(ReturnSum, HAS_2_TEMPLATE_PARAMS(typename, Number, int, k),
                        AND_4_VALUE_PARAMS(v1, v2, v3, v4)):
            return static_cast[Number](v1) + v2 + v3 + v4 + k

        @TEST
        def ActionTemplateTest_CanBeOverloadedOnNumberOfValueParameters():
            var a0: const Action[int()] = ReturnSum()
            var a1: const Action[int()] = ReturnSum(1)
            var a2: const Action[int()] = ReturnSum[int](1, 2)
            var a3: const Action[int()] = ReturnSum[int](1, 2, 3)
            var a4: const Action[int()] = ReturnSum[int, 10000](2000, 300, 40, 5)
            EXPECT_EQ(0, a0.Perform(make_tuple()))
            EXPECT_EQ(1, a1.Perform(make_tuple()))
            EXPECT_EQ(3, a2.Perform(make_tuple()))
            EXPECT_EQ(6, a3.Perform(make_tuple()))
            EXPECT_EQ(12345, a4.Perform(make_tuple()))