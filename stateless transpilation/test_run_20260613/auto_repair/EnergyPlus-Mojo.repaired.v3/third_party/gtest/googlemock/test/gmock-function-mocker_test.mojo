from gmock.gmock-function-mocker import *
#if GTEST_OS_WINDOWS
# include <objbase.h>
#endif  // GTEST_OS_WINDOWS
from functional import *
from map import *
from string import *
from type_traits import *
from gmock.gmock import *
from gtest.gtest import *
namespace testing:
namespace gmock_function_mocker_test:
using testing._
using testing.A
using testing.An
using testing.AnyNumber
using testing.Const
using testing.DoDefault
using testing.Eq
using testing.Lt
using testing.MockFunction
using testing.Ref
using testing.Return
using testing.ReturnRef
using testing.TypedEq
@value
struct TemplatedCopyable[T: AnyType]:
 var __init__: fn() -> None
 def __init__[U: AnyType](self, other: U) -> None: ...
trait FooInterface:
 def __del__(self): ...
 def VoidReturning(self, x: Int): ...
 def Nullary(self) -> Int: ...
 def Unary(self, x: Int) -> Bool: ...
 def Binary(self, x: Int16, y: Int) -> Int64: ...
 def Decimal(self, b: Bool, c: Int8, d: Int16, e: Int, f: Int64, g: Float32, h: Float64, i: UInt, j: Pointer[Int8], k: String) -> Int: ...
 def TakesNonConstReference(self, n: Int) -> Bool: ...
 def TakesConstReference(self, n: Int) -> String: ...
 def TakesConst(self, x: Int) -> Bool: ...
 def OverloadedOnArgumentNumber(self) -> Int: ...
 def OverloadedOnArgumentNumber(self, n: Int) -> Int: ...
 def OverloadedOnArgumentType(self, n: Int) -> Int: ...
 def OverloadedOnArgumentType(self, c: Int8) -> Int8: ...
 def OverloadedOnConstness(self) -> Int: ...
 def OverloadedOnConstness(self) -> Int8: ...
 def TypeWithHole(self, func: fn() -> Int) -> Int: ...
 def TypeWithComma(self, a_map: Map[Int, String]) -> Int: ...
 def TypeWithTemplatedCopyCtor(self, arg0: TemplatedCopyable[Int]) -> Int: ...
 def ReturnsFunctionPointer1(self, arg0: Int) -> fn(Bool) -> Int: ...
 using fn_ptr = fn(Bool) -> Int
 def ReturnsFunctionPointer2(self, arg0: Int) -> fn_ptr: ...
 def RefQualifiedConstRef(self) -> Int: ...
 def RefQualifiedConstRefRef(self) -> Int: ...
 def RefQualifiedRef(self) -> Int: ...
 def RefQualifiedRefRef(self) -> Int: ...
 def RefQualifiedOverloaded(self) -> Int: ...
 def RefQualifiedOverloaded(self) -> Int: ...
 def RefQualifiedOverloaded(self) -> Int: ...
 def RefQualifiedOverloaded(self) -> Int: ...
#if GTEST_OS_WINDOWS
 STDMETHOD_(Int, CTNullary)() = 0
 STDMETHOD_(Bool, CTUnary)(x: Int) = 0
 STDMETHOD_(Int, CTDecimal)(b: Bool, c: Int8, d: Int16, e: Int, f: Int64, g: Float32, h: Float64, i: UInt, j: Pointer[Int8], k: String) = 0
 STDMETHOD_(Int8, CTConst)(x: Int) = 0
#endif  // GTEST_OS_WINDOWS
#ifdef _MSC_VER
# pragma warning(push)
# pragma warning(disable : 4373)
#endif
struct MockFoo(FooInterface):
 var __init__: fn() -> None
 MOCK_METHOD(void, VoidReturning, (Int n))
 MOCK_METHOD(Int, Nullary, ())
 MOCK_METHOD(Bool, Unary, (Int))
 MOCK_METHOD(Int64, Binary, (Int16, Int))
 MOCK_METHOD(Int, Decimal, (Bool, Int8, Int16, Int, Int64, Float32, Float64, UInt, Pointer[Int8], String str), (override))
 MOCK_METHOD(Bool, TakesNonConstReference, (Int))
 MOCK_METHOD(String, TakesConstReference, (Int))
 MOCK_METHOD(Bool, TakesConst, (Int))
 MOCK_METHOD((Map[Int, String]), ReturnTypeWithComma, (), ())
 MOCK_METHOD((Map[Int, String]), ReturnTypeWithComma, (Int), (const))
 MOCK_METHOD(Int, OverloadedOnArgumentNumber, ())
 MOCK_METHOD(Int, OverloadedOnArgumentNumber, (Int))
 MOCK_METHOD(Int, OverloadedOnArgumentType, (Int))
 MOCK_METHOD(Int8, OverloadedOnArgumentType, (Int8))
 MOCK_METHOD(Int, OverloadedOnConstness, (), (override))
 MOCK_METHOD(Int8, OverloadedOnConstness, (), (override, const))
 MOCK_METHOD(Int, TypeWithHole, (fn() -> Int), ())
 MOCK_METHOD(Int, TypeWithComma, ((Map[Int, String])))
 MOCK_METHOD(Int, TypeWithTemplatedCopyCtor, (TemplatedCopyable[Int]))
 MOCK_METHOD(fn(Bool) -> Int, ReturnsFunctionPointer1, (Int), ())
 MOCK_METHOD(fn_ptr, ReturnsFunctionPointer2, (Int), ())
#if GTEST_OS_WINDOWS
 MOCK_METHOD(Int, CTNullary, (), (Calltype(STDMETHODCALLTYPE)))
 MOCK_METHOD(Bool, CTUnary, (Int), (Calltype(STDMETHODCALLTYPE)))
 MOCK_METHOD(Int, CTDecimal, (Bool b, Int8 c, Int16 d, Int e, Int64 f, Float32 g, Float64 h, UInt i, Pointer[Int8] j, String k), (Calltype(STDMETHODCALLTYPE)))
 MOCK_METHOD(Int8, CTConst, (Int), (const, Calltype(STDMETHODCALLTYPE)))
 MOCK_METHOD((Map[Int, String]), CTReturnTypeWithComma, (), (Calltype(STDMETHODCALLTYPE)))
#endif  // GTEST_OS_WINDOWS
 MOCK_METHOD(Int, RefQualifiedConstRef, (), (const, ref(&), override))
 MOCK_METHOD(Int, RefQualifiedConstRefRef, (), (const, ref(&&), override))
 MOCK_METHOD(Int, RefQualifiedRef, (), (ref(&), override))
 MOCK_METHOD(Int, RefQualifiedRefRef, (), (ref(&&), override))
 MOCK_METHOD(Int, RefQualifiedOverloaded, (), (const, ref(&), override))
 MOCK_METHOD(Int, RefQualifiedOverloaded, (), (const, ref(&&), override))
 MOCK_METHOD(Int, RefQualifiedOverloaded, (), (ref(&), override))
 MOCK_METHOD(Int, RefQualifiedOverloaded, (), (ref(&&), override))
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(MockFoo)
struct LegacyMockFoo(FooInterface):
 var __init__: fn() -> None
 MOCK_METHOD1(VoidReturning, void(Int n))
 MOCK_METHOD0(Nullary, Int())
 MOCK_METHOD1(Unary, Bool(Int))
 MOCK_METHOD2(Binary, Int64(Int16, Int))
 MOCK_METHOD10(Decimal, Int(Bool, Int8, Int16, Int, Int64, Float32, Float64, UInt, Pointer[Int8], String str))
 MOCK_METHOD1(TakesNonConstReference, Bool(Int))
 MOCK_METHOD1(TakesConstReference, String(Int))
 MOCK_METHOD1(TakesConst, Bool(Int))
 MOCK_METHOD0(ReturnTypeWithComma, Map[Int, String]())
 MOCK_CONST_METHOD1(ReturnTypeWithComma, Map[Int, String](Int))
 MOCK_METHOD0(OverloadedOnArgumentNumber, Int())
 MOCK_METHOD1(OverloadedOnArgumentNumber, Int(Int))
 MOCK_METHOD1(OverloadedOnArgumentType, Int(Int))
 MOCK_METHOD1(OverloadedOnArgumentType, Int8(Int8))
 MOCK_METHOD0(OverloadedOnConstness, Int())
 MOCK_CONST_METHOD0(OverloadedOnConstness, Int8())
 MOCK_METHOD1(TypeWithHole, Int(fn() -> Int))
 MOCK_METHOD1(TypeWithComma, Int(Map[Int, String]))
 MOCK_METHOD1(TypeWithTemplatedCopyCtor, Int(TemplatedCopyable[Int]))
 MOCK_METHOD1(ReturnsFunctionPointer1, fn(Bool) -> Int(Int))
 MOCK_METHOD1(ReturnsFunctionPointer2, fn_ptr(Int))
#if GTEST_OS_WINDOWS
 MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, CTNullary, Int())
 MOCK_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE, CTUnary, Bool(Int))
 MOCK_METHOD10_WITH_CALLTYPE(STDMETHODCALLTYPE, CTDecimal, Int(Bool b, Int8 c, Int16 d, Int e, Int64 f, Float32 g, Float64 h, UInt i, Pointer[Int8] j, String k))
 MOCK_CONST_METHOD1_WITH_CALLTYPE(STDMETHODCALLTYPE, CTConst, Int8(Int))
 MOCK_METHOD0_WITH_CALLTYPE(STDMETHODCALLTYPE, CTReturnTypeWithComma, Map[Int, String]())
#endif  // GTEST_OS_WINDOWS
 def RefQualifiedConstRef(self) -> Int: return 0
 def RefQualifiedConstRefRef(self) -> Int: return 0
 def RefQualifiedRef(self) -> Int: return 0
 def RefQualifiedRefRef(self) -> Int: return 0
 def RefQualifiedOverloaded(self) -> Int: return 0
 def RefQualifiedOverloaded(self) -> Int: return 0
 def RefQualifiedOverloaded(self) -> Int: return 0
 def RefQualifiedOverloaded(self) -> Int: return 0
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(LegacyMockFoo)
#ifdef _MSC_VER
# pragma warning(pop)
#endif
@value
struct FunctionMockerTest[T: AnyType](testing.Test):
 protected:
 var __init__: fn() -> None
 var foo_: FooInterface
 var mock_foo_: T
using FunctionMockerTestTypes = ::testing.Types[MockFoo, LegacyMockFoo]
TYPED_TEST_SUITE(FunctionMockerTest, FunctionMockerTestTypes)
TYPED_TEST(FunctionMockerTest, MocksVoidFunction):
 EXPECT_CALL(this.mock_foo_, VoidReturning(Lt(100)))
 this.foo_.VoidReturning(0)
TYPED_TEST(FunctionMockerTest, MocksNullaryFunction):
 EXPECT_CALL(this.mock_foo_, Nullary()).WillOnce(DoDefault()).WillOnce(Return(1))
 EXPECT_EQ(0, this.foo_.Nullary())
 EXPECT_EQ(1, this.foo_.Nullary())
TYPED_TEST(FunctionMockerTest, MocksUnaryFunction):
 EXPECT_CALL(this.mock_foo_, Unary(Eq(2))).Times(2).WillOnce(Return(true))
 EXPECT_TRUE(this.foo_.Unary(2))
 EXPECT_FALSE(this.foo_.Unary(2))
TYPED_TEST(FunctionMockerTest, MocksBinaryFunction):
 EXPECT_CALL(this.mock_foo_, Binary(2, _)).WillOnce(Return(3))
 EXPECT_EQ(3, this.foo_.Binary(2, 1))
TYPED_TEST(FunctionMockerTest, MocksDecimalFunction):
 EXPECT_CALL(this.mock_foo_, Decimal(true, 'a', 0, 0, 1, A[Float32](), Lt(100), 5, NULL, "hi")).WillOnce(Return(5))
 EXPECT_EQ(5, this.foo_.Decimal(true, 'a', 0, 0, 1, 0, 0, 5, None, "hi"))
TYPED_TEST(FunctionMockerTest, MocksFunctionWithNonConstReferenceArgument):
 var a: Int = 0
 EXPECT_CALL(this.mock_foo_, TakesNonConstReference(Ref(a))).WillOnce(Return(true))
 EXPECT_TRUE(this.foo_.TakesNonConstReference(a))
TYPED_TEST(FunctionMockerTest, MocksFunctionWithConstReferenceArgument):
 var a: Int = 0
 EXPECT_CALL(this.mock_foo_, TakesConstReference(Ref(a))).WillOnce(Return("Hello"))
 EXPECT_EQ("Hello", this.foo_.TakesConstReference(a))
TYPED_TEST(FunctionMockerTest, MocksFunctionWithConstArgument):
 EXPECT_CALL(this.mock_foo_, TakesConst(Lt(10))).WillOnce(DoDefault())
 EXPECT_FALSE(this.foo_.TakesConst(5))
TYPED_TEST(FunctionMockerTest, MocksFunctionsOverloadedOnArgumentNumber):
 EXPECT_CALL(this.mock_foo_, OverloadedOnArgumentNumber()).WillOnce(Return(1))
 EXPECT_CALL(this.mock_foo_, OverloadedOnArgumentNumber(_)).WillOnce(Return(2))
 EXPECT_EQ(2, this.foo_.OverloadedOnArgumentNumber(1))
 EXPECT_EQ(1, this.foo_.OverloadedOnArgumentNumber())
TYPED_TEST(FunctionMockerTest, MocksFunctionsOverloadedOnArgumentType):
 EXPECT_CALL(this.mock_foo_, OverloadedOnArgumentType(An[Int]())).WillOnce(Return(1))
 EXPECT_CALL(this.mock_foo_, OverloadedOnArgumentType(TypedEq[Int8]('a'))).WillOnce(Return('b'))
 EXPECT_EQ(1, this.foo_.OverloadedOnArgumentType(0))
 EXPECT_EQ('b', this.foo_.OverloadedOnArgumentType('a'))
TYPED_TEST(FunctionMockerTest, MocksFunctionsOverloadedOnConstnessOfThis):
 EXPECT_CALL(this.mock_foo_, OverloadedOnConstness())
 EXPECT_CALL(Const(this.mock_foo_), OverloadedOnConstness()).WillOnce(Return('a'))
 EXPECT_EQ(0, this.foo_.OverloadedOnConstness())
 EXPECT_EQ('a', Const(*this.foo_).OverloadedOnConstness())
TYPED_TEST(FunctionMockerTest, MocksReturnTypeWithComma):
 var a_map: Map[Int, String] = Map[Int, String]()
 EXPECT_CALL(this.mock_foo_, ReturnTypeWithComma()).WillOnce(Return(a_map))
 EXPECT_CALL(this.mock_foo_, ReturnTypeWithComma(42)).WillOnce(Return(a_map))
 EXPECT_EQ(a_map, this.mock_foo_.ReturnTypeWithComma())
 EXPECT_EQ(a_map, this.mock_foo_.ReturnTypeWithComma(42))
TYPED_TEST(FunctionMockerTest, MocksTypeWithTemplatedCopyCtor):
 EXPECT_CALL(this.mock_foo_, TypeWithTemplatedCopyCtor(_)).WillOnce(Return(true))
 EXPECT_TRUE(this.foo_.TypeWithTemplatedCopyCtor(TemplatedCopyable[Int]()))
#if GTEST_OS_WINDOWS
TYPED_TEST(FunctionMockerTest, MocksNullaryFunctionWithCallType):
 EXPECT_CALL(this.mock_foo_, CTNullary()).WillOnce(Return(-1)).WillOnce(Return(0))
 EXPECT_EQ(-1, this.foo_.CTNullary())
 EXPECT_EQ(0, this.foo_.CTNullary())
TYPED_TEST(FunctionMockerTest, MocksUnaryFunctionWithCallType):
 EXPECT_CALL(this.mock_foo_, CTUnary(Eq(2))).Times(2).WillOnce(Return(true)).WillOnce(Return(false))
 EXPECT_TRUE(this.foo_.CTUnary(2))
 EXPECT_FALSE(this.foo_.CTUnary(2))
TYPED_TEST(FunctionMockerTest, MocksDecimalFunctionWithCallType):
 EXPECT_CALL(this.mock_foo_, CTDecimal(true, 'a', 0, 0, 1, A[Float32](), Lt(100), 5, NULL, "hi")).WillOnce(Return(10))
 EXPECT_EQ(10, this.foo_.CTDecimal(true, 'a', 0, 0, 1, 0, 0, 5, NULL, "hi"))
TYPED_TEST(FunctionMockerTest, MocksFunctionsConstFunctionWithCallType):
 EXPECT_CALL(Const(this.mock_foo_), CTConst(_)).WillOnce(Return('a'))
 EXPECT_EQ('a', Const(*this.foo_).CTConst(0))
TYPED_TEST(FunctionMockerTest, MocksReturnTypeWithCommaAndCallType):
 var a_map: Map[Int, String] = Map[Int, String]()
 EXPECT_CALL(this.mock_foo_, CTReturnTypeWithComma()).WillOnce(Return(a_map))
 EXPECT_EQ(a_map, this.mock_foo_.CTReturnTypeWithComma())
#endif  // GTEST_OS_WINDOWS
TEST(FunctionMockerTest, RefQualified):
 var mock_foo: MockFoo = MockFoo()
 EXPECT_CALL(mock_foo, RefQualifiedConstRef).WillOnce(Return(1))
 EXPECT_CALL(std.move(mock_foo), RefQualifiedConstRefRef).WillOnce(Return(2))
 EXPECT_CALL(mock_foo, RefQualifiedRef).WillOnce(Return(3))
 EXPECT_CALL(std.move(mock_foo), RefQualifiedRefRef).WillOnce(Return(4))
 EXPECT_CALL((MockFoo)(mock_foo), RefQualifiedOverloaded()).WillOnce(Return(5))
 EXPECT_CALL((MockFoo)(mock_foo), RefQualifiedOverloaded()).WillOnce(Return(6))
 EXPECT_CALL((MockFoo)(mock_foo), RefQualifiedOverloaded()).WillOnce(Return(7))
 EXPECT_CALL((MockFoo)(mock_foo), RefQualifiedOverloaded()).WillOnce(Return(8))
 EXPECT_EQ(mock_foo.RefQualifiedConstRef(), 1)
 EXPECT_EQ(std.move(mock_foo).RefQualifiedConstRefRef(), 2)
 EXPECT_EQ(mock_foo.RefQualifiedRef(), 3)
 EXPECT_EQ(std.move(mock_foo).RefQualifiedRefRef(), 4)
 EXPECT_EQ(std.cref(mock_foo).get().RefQualifiedOverloaded(), 5)
 EXPECT_EQ(std.move(std.cref(mock_foo).get()).RefQualifiedOverloaded(), 6)
 EXPECT_EQ(mock_foo.RefQualifiedOverloaded(), 7)
 EXPECT_EQ(std.move(mock_foo).RefQualifiedOverloaded(), 8)
struct MockB:
 var __init__: fn() -> None
 MOCK_METHOD(void, DoB, ())
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(MockB)
struct LegacyMockB:
 var __init__: fn() -> None
 MOCK_METHOD0(DoB, void())
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(LegacyMockB)
@value
struct ExpectCallTest[T: AnyType](::testing.Test): {}
using ExpectCallTestTypes = ::testing.Types[MockB, LegacyMockB]
TYPED_TEST_SUITE(ExpectCallTest, ExpectCallTestTypes)
TYPED_TEST(ExpectCallTest, UnmentionedFunctionCanBeCalledAnyNumberOfTimes):
 { var b: TypeParam = TypeParam() }
 {
  var b: TypeParam = TypeParam()
  b.DoB()
 }
 {
  var b: TypeParam = TypeParam()
  b.DoB()
  b.DoB()
 }
trait StackInterface[T: AnyType]:
 def __del__(self): ...
 def Push(self, value: T): ...
 def Pop(self): ...
 def GetSize(self) -> Int: ...
 def GetTop(self) -> T: ...
@value
struct MockStack[T: AnyType](StackInterface[T]):
 var __init__: fn() -> None
 MOCK_METHOD(void, Push, (T elem), ())
 MOCK_METHOD(void, Pop, (), (final))
 MOCK_METHOD(Int, GetSize, (), (const, override))
 MOCK_METHOD(T, GetTop, (), (const))
 MOCK_METHOD((Map[Int, Int]), ReturnTypeWithComma, (), ())
 MOCK_METHOD((Map[Int, Int]), ReturnTypeWithComma, (Int), (const))
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(MockStack)
@value
struct LegacyMockStack[T: AnyType](StackInterface[T]):
 var __init__: fn() -> None
 MOCK_METHOD1_T(Push, void(T elem))
 MOCK_METHOD0_T(Pop, void())
 MOCK_CONST_METHOD0_T(GetSize, Int())
 MOCK_CONST_METHOD0_T(GetTop, T())
 MOCK_METHOD0_T(ReturnTypeWithComma, Map[Int, Int]())
 MOCK_CONST_METHOD1_T(ReturnTypeWithComma, Map[Int, Int](Int))
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(LegacyMockStack)
@value
struct TemplateMockTest[T: AnyType](::testing.Test): {}
using TemplateMockTestTypes = ::testing.Types[MockStack[Int], LegacyMockStack[Int]]
TYPED_TEST_SUITE(TemplateMockTest, TemplateMockTestTypes)
TYPED_TEST(TemplateMockTest, Works):
 var mock: TypeParam = TypeParam()
 EXPECT_CALL(mock, GetSize()).WillOnce(Return(0)).WillOnce(Return(1)).WillOnce(Return(0))
 EXPECT_CALL(mock, Push(_))
 var n: Int = 5
 EXPECT_CALL(mock, GetTop()).WillOnce(ReturnRef(n))
 EXPECT_CALL(mock, Pop()).Times(AnyNumber())
 EXPECT_EQ(0, mock.GetSize())
 mock.Push(5)
 EXPECT_EQ(1, mock.GetSize())
 EXPECT_EQ(5, mock.GetTop())
 mock.Pop()
 EXPECT_EQ(0, mock.GetSize())
TYPED_TEST(TemplateMockTest, MethodWithCommaInReturnTypeWorks):
 var mock: TypeParam = TypeParam()
 var a_map: Map[Int, Int] = Map[Int, Int]()
 EXPECT_CALL(mock, ReturnTypeWithComma()).WillOnce(Return(a_map))
 EXPECT_CALL(mock, ReturnTypeWithComma(1)).WillOnce(Return(a_map))
 EXPECT_EQ(a_map, mock.ReturnTypeWithComma())
 EXPECT_EQ(a_map, mock.ReturnTypeWithComma(1))
#if GTEST_OS_WINDOWS
trait StackInterfaceWithCallType[T: AnyType]:
 def __del__(self): ...
 STDMETHOD_(void, Push)(value: T) = 0
 STDMETHOD_(void, Pop)() = 0
 STDMETHOD_(Int, GetSize)() = 0
 STDMETHOD_(T, GetTop)() = 0
@value
struct MockStackWithCallType[T: AnyType](StackInterfaceWithCallType[T]):
 var __init__: fn() -> None
 MOCK_METHOD(void, Push, (T elem), (Calltype(STDMETHODCALLTYPE), override))
 MOCK_METHOD(void, Pop, (), (Calltype(STDMETHODCALLTYPE), override))
 MOCK_METHOD(Int, GetSize, (), (Calltype(STDMETHODCALLTYPE), override, const))
 MOCK_METHOD(T, GetTop, (), (Calltype(STDMETHODCALLTYPE), override, const))
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(MockStackWithCallType)
@value
struct LegacyMockStackWithCallType[T: AnyType](StackInterfaceWithCallType[T]):
 var __init__: fn() -> None
 MOCK_METHOD1_T_WITH_CALLTYPE(STDMETHODCALLTYPE, Push, void(T elem))
 MOCK_METHOD0_T_WITH_CALLTYPE(STDMETHODCALLTYPE, Pop, void())
 MOCK_CONST_METHOD0_T_WITH_CALLTYPE(STDMETHODCALLTYPE, GetSize, Int())
 MOCK_CONST_METHOD0_T_WITH_CALLTYPE(STDMETHODCALLTYPE, GetTop, T())
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(LegacyMockStackWithCallType)
@value
struct TemplateMockTestWithCallType[T: AnyType](::testing.Test): {}
using TemplateMockTestWithCallTypeTypes = ::testing.Types[MockStackWithCallType[Int], LegacyMockStackWithCallType[Int]]
TYPED_TEST_SUITE(TemplateMockTestWithCallType, TemplateMockTestWithCallTypeTypes)
TYPED_TEST(TemplateMockTestWithCallType, Works):
 var mock: TypeParam = TypeParam()
 EXPECT_CALL(mock, GetSize()).WillOnce(Return(0)).WillOnce(Return(1)).WillOnce(Return(0))
 EXPECT_CALL(mock, Push(_))
 var n: Int = 5
 EXPECT_CALL(mock, GetTop()).WillOnce(ReturnRef(n))
 EXPECT_CALL(mock, Pop()).Times(AnyNumber())
 EXPECT_EQ(0, mock.GetSize())
 mock.Push(5)
 EXPECT_EQ(1, mock.GetSize())
 EXPECT_EQ(5, mock.GetTop())
 mock.Pop()
 EXPECT_EQ(0, mock.GetSize())
#endif  // GTEST_OS_WINDOWS
#define MY_MOCK_METHODS1_                       \
  MOCK_METHOD(void, Overloaded, ());            \
  MOCK_METHOD(Int, Overloaded, (Int), (const)); \
  MOCK_METHOD(Bool, Overloaded, (Bool f, Int n))
#define LEGACY_MY_MOCK_METHODS1_              \
  MOCK_METHOD0(Overloaded, void());           \
  MOCK_CONST_METHOD1(Overloaded, Int(Int n)); \
  MOCK_METHOD2(Overloaded, Bool(Bool f, Int n))
struct MockOverloadedOnArgNumber:
 var __init__: fn() -> None
 MY_MOCK_METHODS1_
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(MockOverloadedOnArgNumber)
struct LegacyMockOverloadedOnArgNumber:
 var __init__: fn() -> None
 LEGACY_MY_MOCK_METHODS1_
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(LegacyMockOverloadedOnArgNumber)
@value
struct OverloadedMockMethodTest[T: AnyType](::testing.Test): {}
using OverloadedMockMethodTestTypes = ::testing.Types[MockOverloadedOnArgNumber, LegacyMockOverloadedOnArgNumber]
TYPED_TEST_SUITE(OverloadedMockMethodTest, OverloadedMockMethodTestTypes)
TYPED_TEST(OverloadedMockMethodTest, CanOverloadOnArgNumberInMacroBody):
 var mock: TypeParam = TypeParam()
 EXPECT_CALL(mock, Overloaded())
 EXPECT_CALL(mock, Overloaded(1)).WillOnce(Return(2))
 EXPECT_CALL(mock, Overloaded(true, 1)).WillOnce(Return(true))
 mock.Overloaded()
 EXPECT_EQ(2, mock.Overloaded(1))
 EXPECT_TRUE(mock.Overloaded(true, 1))
#define MY_MOCK_METHODS2_ \
    MOCK_CONST_METHOD1(Overloaded, Int(Int n)); \
    MOCK_METHOD1(Overloaded, Int(Int n))
struct MockOverloadedOnConstness:
 var __init__: fn() -> None
 MY_MOCK_METHODS2_
 private:
 GTEST_DISALLOW_COPY_AND_ASSIGN_(MockOverloadedOnConstness)
TEST(MockMethodOverloadedMockMethodTest, CanOverloadOnConstnessInMacroBody):
 var mock: MockOverloadedOnConstness = MockOverloadedOnConstness()
 var const_mock: MockOverloadedOnConstness = mock
 EXPECT_CALL(mock, Overloaded(1)).WillOnce(Return(2))
 EXPECT_CALL(*const_mock, Overloaded(1)).WillOnce(Return(3))
 EXPECT_EQ(2, mock.Overloaded(1))
 EXPECT_EQ(3, const_mock.Overloaded(1))
TEST(MockMethodMockFunctionTest, WorksForVoidNullary):
 var foo: MockFunction[fn() -> None] = MockFunction[fn() -> None]()
 EXPECT_CALL(foo, Call())
 foo.Call()
TEST(MockMethodMockFunctionTest, WorksForNonVoidNullary):
 var foo: MockFunction[fn() -> Int] = MockFunction[fn() -> Int]()
 EXPECT_CALL(foo, Call()).WillOnce(Return(1)).WillOnce(Return(2))
 EXPECT_EQ(1, foo.Call())
 EXPECT_EQ(2, foo.Call())
TEST(MockMethodMockFunctionTest, WorksForVoidUnary):
 var foo: MockFunction[fn(Int) -> None] = MockFunction[fn(Int) -> None]()
 EXPECT_CALL(foo, Call(1))
 foo.Call(1)
TEST(MockMethodMockFunctionTest, WorksForNonVoidBinary):
 var foo: MockFunction[fn(Bool, Int) -> Int] = MockFunction[fn(Bool, Int) -> Int]()
 EXPECT_CALL(foo, Call(false, 42)).WillOnce(Return(1)).WillOnce(Return(2))
 EXPECT_CALL(foo, Call(true, Ge(100))).WillOnce(Return(3))
 EXPECT_EQ(1, foo.Call(false, 42))
 EXPECT_EQ(2, foo.Call(false, 42))
 EXPECT_EQ(3, foo.Call(true, 120))
TEST(MockMethodMockFunctionTest, WorksFor10Arguments):
 var foo: MockFunction[fn(Bool a0, Int8 a1, Int a2, Int a3, Int a4, Int a5, Int a6, Int8 a7, Int a8, Bool a9) -> Int] = MockFunction[fn(Bool a0, Int8 a1, Int a2, Int a3, Int a4, Int a5, Int a6, Int8 a7, Int a8, Bool a9) -> Int]()
 EXPECT_CALL(foo, Call(_, 'a', _, _, _, _, _, _, _, _)).WillOnce(Return(1)).WillOnce(Return(2))
 EXPECT_EQ(1, foo.Call(false, 'a', 0, 0, 0, 0, 0, 'b', 0, true))
 EXPECT_EQ(2, foo.Call(true, 'a', 0, 0, 0, 0, 0, 'b', 1, false))
TEST(MockMethodMockFunctionTest, AsStdFunction):
 var foo: MockFunction[fn(Int) -> Int] = MockFunction[fn(Int) -> Int]()
 var call: fn(fn(Int) -> Int, Int) -> Int = lambda f: fn(Int) -> Int, i: Int: return f(i)
 EXPECT_CALL(foo, Call(1)).WillOnce(Return(-1))
 EXPECT_CALL(foo, Call(2)).WillOnce(Return(-2))
 EXPECT_EQ(-1, call(foo.AsStdFunction(), 1))
 EXPECT_EQ(-2, call(foo.AsStdFunction(), 2))
TEST(MockMethodMockFunctionTest, AsStdFunctionReturnsReference):
 var foo: MockFunction[fn() -> Int] = MockFunction[fn() -> Int]()
 var value: Int = 1
 EXPECT_CALL(foo, Call()).WillOnce(ReturnRef(value))
 var ref: Int = foo.AsStdFunction()()
 EXPECT_EQ(1, ref)
 value = 2
 EXPECT_EQ(2, ref)
TEST(MockMethodMockFunctionTest, AsStdFunctionWithReferenceParameter):
 var foo: MockFunction[fn(Int) -> Int] = MockFunction[fn(Int) -> Int]()
 var call: fn(fn(Int) -> Int, Int) -> Int = lambda f: fn(Int) -> Int, i: Int: return f(i)
 var i: Int = 42
 EXPECT_CALL(foo, Call(i)).WillOnce(Return(-1))
 EXPECT_EQ(-1, call(foo.AsStdFunction(), i))
namespace:
@value
struct IsMockFunctionTemplateArgumentDeducedTo[Expected: AnyType, F: AnyType]:
 @staticmethod
 def __call__(arg0: internal.MockFunction[F]) -> Bool:
  return std.is_same[F, Expected].value
end namespace
@value
struct MockMethodMockFunctionSignatureTest[F: AnyType](Test): {}
using MockMethodMockFunctionSignatureTypes = Types[fn() -> None, fn() -> Int, fn(Int) -> None, fn(Int) -> Int, fn(Bool, Int) -> Int, fn(Bool, Int8, Int, Int, Int, Int, Int, Int8, Int, Bool) -> Int]
TYPED_TEST_SUITE(MockMethodMockFunctionSignatureTest, MockMethodMockFunctionSignatureTypes)
TYPED_TEST(MockMethodMockFunctionSignatureTest, IsMockFunctionTemplateArgumentDeducedForRawSignature):
 using Argument = TypeParam
 var foo: MockFunction[Argument] = MockFunction[Argument]()
 EXPECT_TRUE(IsMockFunctionTemplateArgumentDeducedTo[TypeParam](foo))
TYPED_TEST(MockMethodMockFunctionSignatureTest, IsMockFunctionTemplateArgumentDeducedForStdFunction):
 using Argument = fn(TypeParam) -> ...
 var foo: MockFunction[Argument] = MockFunction[Argument]()
 EXPECT_TRUE(IsMockFunctionTemplateArgumentDeducedTo[TypeParam](foo))
TYPED_TEST(MockMethodMockFunctionSignatureTest, IsMockFunctionCallMethodSignatureTheSameForRawSignatureAndStdFunction):
 using ForRawSignature = decltype(&MockFunction[TypeParam].Call)
 using ForStdFunction = decltype(&MockFunction[fn(TypeParam) -> ...].Call)
 EXPECT_TRUE((std.is_same[ForRawSignature, ForStdFunction].value))
@value
struct AlternateCallable[F: AnyType]: {}
TYPED_TEST(MockMethodMockFunctionSignatureTest, IsMockFunctionTemplateArgumentDeducedForAlternateCallable):
 using Argument = AlternateCallable[TypeParam]
 var foo: MockFunction[Argument] = MockFunction[Argument]()
 EXPECT_TRUE(IsMockFunctionTemplateArgumentDeducedTo[TypeParam](foo))
TYPED_TEST(MockMethodMockFunctionSignatureTest, IsMockFunctionCallMethodSignatureTheSameForAlternateCallable):
 using ForRawSignature = decltype(&MockFunction[TypeParam].Call)
 using ForStdFunction = decltype(&MockFunction[fn(TypeParam) -> ...].Call)
 EXPECT_TRUE((std.is_same[ForRawSignature, ForStdFunction].value))
struct MockMethodSizes0:
 MOCK_METHOD(void, func, ())
struct MockMethodSizes1:
 MOCK_METHOD(void, func, (Int))
struct MockMethodSizes2:
 MOCK_METHOD(void, func, (Int, Int))
struct MockMethodSizes3:
 MOCK_METHOD(void, func, (Int, Int, Int))
struct MockMethodSizes4:
 MOCK_METHOD(void, func, (Int, Int, Int, Int))
struct LegacyMockMethodSizes0:
 MOCK_METHOD0(func, void())
struct LegacyMockMethodSizes1:
 MOCK_METHOD1(func, void(Int))
struct LegacyMockMethodSizes2:
 MOCK_METHOD2(func, void(Int, Int))
struct LegacyMockMethodSizes3:
 MOCK_METHOD3(func, void(Int, Int, Int))
struct LegacyMockMethodSizes4:
 MOCK_METHOD4(func, void(Int, Int, Int, Int))
TEST(MockMethodMockFunctionTest, MockMethodSizeOverhead):
 EXPECT_EQ(sizeof(MockMethodSizes0), sizeof(MockMethodSizes1))
 EXPECT_EQ(sizeof(MockMethodSizes0), sizeof(MockMethodSizes2))
 EXPECT_EQ(sizeof(MockMethodSizes0), sizeof(MockMethodSizes3))
 EXPECT_EQ(sizeof(MockMethodSizes0), sizeof(MockMethodSizes4))
 EXPECT_EQ(sizeof(LegacyMockMethodSizes0), sizeof(LegacyMockMethodSizes1))
 EXPECT_EQ(sizeof(LegacyMockMethodSizes0), sizeof(LegacyMockMethodSizes2))
 EXPECT_EQ(sizeof(LegacyMockMethodSizes0), sizeof(LegacyMockMethodSizes3))
 EXPECT_EQ(sizeof(LegacyMockMethodSizes0), sizeof(LegacyMockMethodSizes4))
 EXPECT_EQ(sizeof(LegacyMockMethodSizes0), sizeof(MockMethodSizes0))
def hasTwoParams(arg0: Int, arg1: Int): ...
def MaybeThrows(): ...
def DoesntThrow() noexcept: ...
struct MockMethodNoexceptSpecifier:
 MOCK_METHOD(void, func1, (), (noexcept))
 MOCK_METHOD(void, func2, (), (noexcept(true)))
 MOCK_METHOD(void, func3, (), (noexcept(false)))
 MOCK_METHOD(void, func4, (), (noexcept(noexcept(MaybeThrows()))))
 MOCK_METHOD(void, func5, (), (noexcept(noexcept(DoesntThrow()))))
 MOCK_METHOD(void, func6, (), (noexcept(noexcept(DoesntThrow())), const))
 MOCK_METHOD(void, func7, (), (const, noexcept(noexcept(DoesntThrow()))))
 MOCK_METHOD(void, func8, (), (noexcept(noexcept(hasTwoParams(1, 2))), const))
TEST(MockMethodMockFunctionTest, NoexceptSpecifierPreserved):
 EXPECT_TRUE(noexcept(MockMethodNoexceptSpecifier().func1()))
 EXPECT_TRUE(noexcept(MockMethodNoexceptSpecifier().func2()))
 EXPECT_FALSE(noexcept(MockMethodNoexceptSpecifier().func3()))
 EXPECT_FALSE(noexcept(MockMethodNoexceptSpecifier().func4()))
 EXPECT_TRUE(noexcept(MockMethodNoexceptSpecifier().func5()))
 EXPECT_TRUE(noexcept(MockMethodNoexceptSpecifier().func6()))
 EXPECT_TRUE(noexcept(MockMethodNoexceptSpecifier().func7()))
 EXPECT_EQ(noexcept(MockMethodNoexceptSpecifier().func8()), noexcept(hasTwoParams(1, 2)))
end namespace gmock_function_mocker_test
end namespace testing